/* win_spawn.h -- posix_spawn for Windows, on CreateProcessW (EXPERIMENTAL; post-0.06, not yet built into the module).
 *
 * Plain C, no Perl: Spawner.xs includes it under _WIN32 and #defines the posix_spawn names to these, so the XSUB
 * __posix_spawn stays one source.  Design: doc/pspawn-spawner.md, section 8 (the user's rule: what Windows does
 * fully and natively is done; the rest fails with ENOTSUP, so Proc::Spawner drops or fails it as UNSUPPORTED says).
 * Nothing here depends on the architecture (x86, x64, ARM64): handles are sizeof(HANDLE) wide everywhere.
 *
 *   the child's fds 0-2     STARTUPINFO (STARTF_USESTDHANDLES), as Perl's own do_spawnvp_handles() in win32/win32.c
 *   fds 3 and up            the C runtime's table in lpReserved2 (count, flag bytes, handles): read only by children
 *                           built on that runtime (W1-W3)
 *   which handles at all    the explicit list PROC_THREAD_ATTRIBUTE_HANDLE_LIST, of inheritable copies made for the
 *                           call (the parent's own handles keep their flags): so close and closefrom are exact
 *   the file actions        run in order on a table of the child's fds, starting from the parent's fds 0-2 (an fd of
 *                           3 or more that no action names is not inherited); open: by the parent, relative to the
 *                           child's directory, /dev/null (any case) being NUL as in Perl's open; chdir, fchdir:
 *                           lpCurrentDirectory
 *   argv                    one command line, quoted as the Microsoft C runtime parses it back (CommandLineToArgvW)
 *   envp                    a UTF-16 block (CREATE_UNICODE_ENVIRONMENT); NULL: the parent's
 *   strings                 UTF-8 (paths, argv, envp), turned into UTF-16; another code page per call
 *                           (win_attr_setcodepage: CP_ACP for Perl's own byte strings)
 *   the program             a relative name is taken from the child's directory (after chdir, as glibc does), tried
 *                           as given, then with each PATHEXT extension; posix_spawnp: through PATH (';') instead
 *   SETPGROUP with 0        CREATE_NEW_PROCESS_GROUP; RESETIDS, SETSIGDEF: nothing to do
 *   refused (ENOTSUP)       a non-empty SETSIGMASK, SETPGROUP with a group, SETSID, SETSCHEDULER, SETSCHEDPARAM
 *   the result              *pid: the process id; the process handle is kept (win_spawn_handle), so the exit code
 *                           stays until the caller has it (win_spawn_forget then closes it); or given to the caller's
 *                           own table (the hook keep)
 * A .bat or .cmd file: run by the system's cmd.exe, its arguments quoted for cmd as Rust's standard library does since
 * BatBadBut (CVE-2024-24576); an argument that cannot be passed safely (CR, LF) is refused: EINVAL.
 *
 * Everything is per call (post-0.12: so that Perl's core can use this file, with several interpreters in one
 * process): Windows' own choices (WIN_OPT_*, wShowWindow, the job that ends the children with the parent) are
 * attributes, set by win_attr_set*; and where the file would use the process's own state, a caller may plug in its
 * own (win_spawn_hooks_t, win_attr_sethooks): the child table, the environment and the current directory (Perl's
 * pseudo-processes have their own), an fd's handle, a Windows error as an errno.  The allocator is chosen when the
 * file is included (WIN_SPAWN_MALLOC).  No attributes (sa NULL), no hooks: the defaults, as before.
 */
#ifndef WIN_SPAWN_H
#define WIN_SPAWN_H

#ifdef __GNUC__   /* (not every includer uses every function) */
#  pragma GCC diagnostic push
#  pragma GCC diagnostic ignored "-Wunused-function"
#  pragma GCC diagnostic ignored "-Wunused-variable"
#endif

#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <sys/types.h>

/* The allocator, one for everything this file allocates and frees, safe in any thread: by default the process heap.
   (Included after perl.h, PERL_IMPLICIT_SYS, malloc and free are Perl's macros for the interpreter's allocator, and
   _strdup's memory is the C runtime's; so neither is used here.)  An includer may define all three macros first (Perl's
   core: its own).  What this file returns (win_acp_to_utf8) is freed with win_free. */
#ifndef WIN_SPAWN_MALLOC
#  define WIN_SPAWN_MALLOC(n)     HeapAlloc(GetProcessHeap(), 0, (n))
#  define WIN_SPAWN_REALLOC(p, n) HeapReAlloc(GetProcessHeap(), 0, (p), (n))
#  define WIN_SPAWN_FREE(p)       HeapFree(GetProcessHeap(), 0, (p))
#endif
static void *win_malloc(size_t n) { return WIN_SPAWN_MALLOC(n ? n : 1); }
static void *win_calloc(size_t n, size_t m)
{ size_t t = n * m; void *p; if (m && t / m != n) return NULL; if ((p = win_malloc(t))) memset(p, 0, t ? t : 1); return p; }
static void *win_realloc(void *p, size_t n) { return p ? WIN_SPAWN_REALLOC(p, n ? n : 1) : win_malloc(n); }
static void win_free(void *p) { if (p) WIN_SPAWN_FREE(p); }
static char *win_strdup(const char *s) { size_t n = strlen(s) + 1; char *d = (char *)win_malloc(n); if (d) memcpy(d, s, n); return d; }
static wchar_t *win_wcsdup(const wchar_t *s) { size_t n = wcslen(s) + 1; wchar_t *d = (wchar_t *)win_malloc(n * sizeof *d); if (d) wmemcpy(d, s, n); return d; }

#ifndef ENOTSUP
#define ENOTSUP 129   /* as the Microsoft C runtime numbers it */
#endif

typedef unsigned long long win_sigset_t;   /* bit N-1: signal N */
static int win_sigemptyset(win_sigset_t *s) { *s = 0; return 0; }
static int win_sigaddset(win_sigset_t *s, int n) { if (n <= 0 || n > 64) { errno = EINVAL; return -1; } *s |= 1ULL << (n - 1); return 0; }

enum { WIN_FA_DUP2, WIN_FA_CLOSE, WIN_FA_OPEN, WIN_FA_CHDIR, WIN_FA_FCHDIR, WIN_FA_CLOSEFROM };
struct win_fa_one { int op, fd, newfd, oflag, mode; char *path; };
typedef struct { int n, cap; struct win_fa_one *a; } win_file_actions_t;

#define WIN_SPAWN_RESETIDS      0x01
#define WIN_SPAWN_SETPGROUP     0x02
#define WIN_SPAWN_SETSIGDEF     0x04
#define WIN_SPAWN_SETSIGMASK    0x08
#define WIN_SPAWN_SETSCHEDPARAM 0x10
#define WIN_SPAWN_SETSCHEDULER  0x20
#define WIN_SPAWN_SETSID        0x80
struct win_sched_param { int sched_priority; };
typedef struct {   /* job limits of the child's own job (W4, post-0.09), by the names of JOBOBJECT_*_LIMIT_INFORMATION */
    DWORD flags;                            /* JOB_OBJECT_LIMIT_PROCESS_MEMORY, ..._JOB_MEMORY, ..._PROCESS_TIME, ..._JOB_TIME, ..._ACTIVE_PROCESS */
    SIZE_T ProcessMemoryLimit, JobMemoryLimit;   /* bytes of committed memory */
    LONGLONG PerProcessUserTimeLimit, PerJobUserTimeLimit;   /* user-mode time, 100-ns units */
    DWORD ActiveProcessLimit;
} win_job_limits_t;
/* Windows' own choices, per call (attribute options; Proc::Spawner: %Proc::Spawner::WINDOWS):
 *   WIN_OPT_NEW_GROUP         CREATE_NEW_PROCESS_GROUP: Ctrl-C at the console reaches the parent, not the children
 *                             (the user, 2026-11-05: the parent is to be killed, and it is to kill its children);
 *                             Windows turns Ctrl-C off in the new group (a child may turn it back on: perl.exe does)
 *   WIN_OPT_KILL_WITH_PARENT  the child in a job object that kills it when the parent ends (JOB_OBJECT_LIMIT_KILL_ON_JOB_
 *                             CLOSE: the job's only handle is the parent's, closed by Windows however the parent ends);
 *                             started suspended, put in the job, then resumed, so nothing it starts escapes.  The job:
 *                             the attribute kill_job, or this file's own, made at the first child that needs it.  Not in
 *                             WIN_OPT_DEFAULT since post-0.12 (the user, 2026-11-14, W6: as Perl's own spawn, which
 *                             makes no job: children outlive their parent, as on POSIX)
 *   WIN_OPT_NEW_CONSOLE       a child with none of fds 0-2 gets a console of its own (CREATE_NEW_CONSOLE), as Perl's
 *                             spawn does; without it, it shares ours with no standard handles
 *   (post-0.12, for Perl's core, from the patch that takes this file into Perl; see win_quote_argv:)
 *   WIN_OPT_CMD_RAW           cmd.exe with exactly one word after its /c: that word is a command line for cmd.exe,
 *                             passed as it is in one pair of quotes
 *   WIN_OPT_ARGV_RAW          the caller has made the command line: argv's words joined by blanks as they are (no
 *                             batch-file path: CreateProcessW starts cmd.exe for a batch file itself)
 *   WIN_OPT_KEEP_QUOTED       a word that begins and ends with '"' is taken as quoted by the caller, copied as it is */
#define WIN_OPT_NEW_GROUP        0x01
#define WIN_OPT_KILL_WITH_PARENT 0x02
#define WIN_OPT_NEW_CONSOLE      0x04
#define WIN_OPT_CMD_RAW          0x08
#define WIN_OPT_ARGV_RAW         0x10
#define WIN_OPT_KEEP_QUOTED      0x20
#define WIN_OPT_DEFAULT          (WIN_OPT_NEW_GROUP | WIN_OPT_NEW_CONSOLE)   /* (W6: no WIN_OPT_KILL_WITH_PARENT) */

/* Hooks (post-0.12): where the caller has its own idea of what this file would take from the process.  A NULL member,
 * or no hooks: this file's own way.  Strings in the call's code page, valid until the call returns.  (No member is
 * named getenv, environ or getcwd: Perl's headers make those macros.)
 *   keep           the child is started: its process handle and its own job (the win_job limits, else NULL) are the
 *                  hook's from then on (the exit code stays while the process handle is open; closing the job ends the
 *                  child if WIN_OPT_KILL_WITH_PARENT was set: close it after the child's end).  Non-zero, an errno: the
 *                  hook took nothing, the child is ended, the call fails with it.  Default: this file's table
 *                  (win_spawn_handle, win_spawn_forget).  Perl's core: its own table, which its waitpid, kill, $? use
 *   var            the caller's value of PATH (posix_spawnp) or PATHEXT, NULL: unset.  Default: the process's
 *   env            the caller's environment, the child's when envp is NULL; NULL: the process's.  Default: the process's
 *   cwd            the caller's current directory: the child's (until a chdir action) and the base of every relative
 *                  path; NULL: the process's.  Default: the process's
 *                  (Perl's pseudo-processes, the children of its fork emulation, have their own environment and directory)
 *   fd_handle      an fd's handle; -1 or -2: none.  Default: _get_osfhandle
 *   errno_of       a Windows error (GetLastError) as an errno.  Default: win_errno */
typedef struct win_spawn_hooks {
    void *ctx;   /* passed to each */
    int (*keep)(void *ctx, pid_t pid, HANDLE process, HANDLE job);
    const char *(*var)(void *ctx, const char *name);
    char *const *(*env)(void *ctx);
    const char *(*cwd)(void *ctx);
    intptr_t (*fd_handle)(void *ctx, int fd);
    int (*errno_of)(void *ctx, DWORD error);
} win_spawn_hooks_t;

typedef struct { short flags; win_sigset_t mask, def; pid_t pgroup; int policy; struct win_sched_param sp;
                 DWORD priority_class;      /* IDLE_PRIORITY_CLASS ...: a creation flag, or 0 (W4) */
                 win_job_limits_t job;
                 /* (post-0.12: per call what was the file's, process-wide) */
                 int options;               /* WIN_OPT_*; win_attr_init: WIN_OPT_DEFAULT */
                 int showwindow;            /* the child's wShowWindow (STARTF_USESHOWWINDOW), or -1: not set (Perl's
                                               Win32::SetChildShowWindow, as Perl's own spawn uses it) */
                 HANDLE kill_job;           /* the job of WIN_OPT_KILL_WITH_PARENT; NULL: this file's own */
                 UINT codepage;             /* of every string of the call; win_attr_init: CP_UTF8 */
                 const win_spawn_hooks_t *hooks; } win_spawnattr_t;

#define WIN_MAXFD 256   /* the child's fds this table can describe */

/* ------------------------------------------------------------------ the file actions and the attributes */
static int win_fa_add(win_file_actions_t *fa, struct win_fa_one x, const char *path)
{
    if (fa->n == fa->cap) {
        int cap = fa->cap ? 2 * fa->cap : 8;
        struct win_fa_one *a = (struct win_fa_one *)win_realloc(fa->a, cap * sizeof *a);
        if (!a) return ENOMEM;
        fa->a = a; fa->cap = cap;
    }
    x.path = NULL;
    if (path && !(x.path = win_strdup(path))) return ENOMEM;
    fa->a[fa->n++] = x;
    return 0;
}
static int win_fa_init(win_file_actions_t *fa) { fa->n = fa->cap = 0; fa->a = NULL; return 0; }
static int win_fa_destroy(win_file_actions_t *fa)
{
    int i; for (i = 0; i < fa->n; i++) win_free(fa->a[i].path);
    win_free(fa->a); fa->a = NULL; fa->n = fa->cap = 0; return 0;
}
static int win_fa_fdok(int fd) { return fd >= 0 && fd < WIN_MAXFD; }
static int win_fa_adddup2(win_file_actions_t *fa, int fd, int newfd)
{ struct win_fa_one x = { WIN_FA_DUP2, fd, newfd, 0, 0, NULL }; return win_fa_fdok(fd) && win_fa_fdok(newfd) ? win_fa_add(fa, x, NULL) : EBADF; }
static int win_fa_addclose(win_file_actions_t *fa, int fd)
{ struct win_fa_one x = { WIN_FA_CLOSE, fd, 0, 0, 0, NULL }; return win_fa_fdok(fd) ? win_fa_add(fa, x, NULL) : EBADF; }
static int win_fa_addopen(win_file_actions_t *fa, int fd, const char *path, int oflag, int mode)
{ struct win_fa_one x = { WIN_FA_OPEN, fd, 0, oflag, mode, NULL }; return win_fa_fdok(fd) ? win_fa_add(fa, x, path) : EBADF; }
static int win_fa_addchdir(win_file_actions_t *fa, const char *path)
{ struct win_fa_one x = { WIN_FA_CHDIR, 0, 0, 0, 0, NULL }; return win_fa_add(fa, x, path); }
static int win_fa_addfchdir(win_file_actions_t *fa, int fd)
{ struct win_fa_one x = { WIN_FA_FCHDIR, fd, 0, 0, 0, NULL }; return fd >= 0 ? win_fa_add(fa, x, NULL) : EBADF; }
static int win_fa_addclosefrom(win_file_actions_t *fa, int fd)
{ struct win_fa_one x = { WIN_FA_CLOSEFROM, fd, 0, 0, 0, NULL }; return fd >= 0 ? win_fa_add(fa, x, NULL) : EBADF; }

static int win_attr_init(win_spawnattr_t *sa)
{ memset(sa, 0, sizeof *sa); sa->options = WIN_OPT_DEFAULT; sa->showwindow = -1; sa->codepage = CP_UTF8; return 0; }
static int win_attr_destroy(win_spawnattr_t *sa) { (void)sa; return 0; }
static int win_attr_setflags(win_spawnattr_t *sa, short f) { sa->flags = f; return 0; }
static int win_attr_setsigmask(win_spawnattr_t *sa, const win_sigset_t *s) { sa->mask = *s; return 0; }
static int win_attr_setsigdefault(win_spawnattr_t *sa, const win_sigset_t *s) { sa->def = *s; return 0; }
static int win_attr_setpgroup(win_spawnattr_t *sa, pid_t g) { sa->pgroup = g; return 0; }
static int win_attr_setschedpolicy(win_spawnattr_t *sa, int p) { sa->policy = p; return 0; }
static int win_attr_setschedparam(win_spawnattr_t *sa, const struct win_sched_param *p) { sa->sp = *p; return 0; }
static int win_attr_setoptions(win_spawnattr_t *sa, int o) { sa->options = o; return 0; }
static int win_attr_setshowwindow(win_spawnattr_t *sa, int s) { sa->showwindow = s; return 0; }
static int win_attr_setkilljob(win_spawnattr_t *sa, HANDLE j) { sa->kill_job = j; return 0; }
static int win_attr_setcodepage(win_spawnattr_t *sa, UINT cp) { sa->codepage = cp; return 0; }
static int win_attr_sethooks(win_spawnattr_t *sa, const win_spawn_hooks_t *h) { sa->hooks = h; return 0; }

/* ------------------------------------------------------------------ helpers */
static wchar_t *win_wide(const char *s, UINT cp)   /* a string in code page cp (CP_UTF8, ...) as a new UTF-16 string, or
                                                      NULL (errno set) */
{
    int n = MultiByteToWideChar(cp, 0, s, -1, NULL, 0);
    wchar_t *w;
    if (n <= 0) { errno = EINVAL; return NULL; }
    if (!(w = (wchar_t *)win_malloc(n * sizeof *w))) { errno = ENOMEM; return NULL; }
    MultiByteToWideChar(cp, 0, s, -1, w, n);
    return w;
}
static int win_errno(DWORD e)
{
    switch (e) {
    case ERROR_FILE_NOT_FOUND: case ERROR_PATH_NOT_FOUND: case ERROR_INVALID_DRIVE: case ERROR_BAD_NETPATH: return ENOENT;
    case ERROR_ACCESS_DENIED: case ERROR_SHARING_VIOLATION: return EACCES;
    case ERROR_BAD_EXE_FORMAT: case ERROR_EXE_MACHINE_TYPE_MISMATCH: return ENOEXEC;
    case ERROR_NOT_ENOUGH_MEMORY: case ERROR_OUTOFMEMORY: return ENOMEM;
    case ERROR_FILE_EXISTS: case ERROR_ALREADY_EXISTS: return EEXIST;
    case ERROR_INVALID_HANDLE: return EBADF;
    case ERROR_FILENAME_EXCED_RANGE: return ENAMETOOLONG;
    default: return EINVAL;
    }
}
static int win_err(const win_spawn_hooks_t *h, DWORD e) { return h && h->errno_of ? h->errno_of(h->ctx, e) : win_errno(e); }
static intptr_t win_osf(const win_spawn_hooks_t *h, int fd) { return h && h->fd_handle ? h->fd_handle(h->ctx, fd) : _get_osfhandle(fd); }
static wchar_t *win_getenv(const win_spawn_hooks_t *h, UINT cp, const char *name)   /* the caller's value of a variable as a
    new UTF-16 string; NULL: unset or empty (or no memory) */
{
    wchar_t *v = NULL, *w; DWORD n;
    if (h && h->var) { const char *s = h->var(h->ctx, name); v = s ? win_wide(s, cp) : NULL; }
    else if ((w = win_wide(name, CP_UTF8))) {
        if ((n = GetEnvironmentVariableW(w, NULL, 0)) && (v = (wchar_t *)win_malloc(n * sizeof *v)) && GetEnvironmentVariableW(w, v, n) >= n) {
            win_free(v); v = NULL; }   /* (changed meanwhile) */
        win_free(w);
    }
    if (v && !*v) { win_free(v); v = NULL; }
    return v;
}
static int win_absolute(const wchar_t *p)
{ return (p[0] && p[1] == L':' && (p[2] == L'\\' || p[2] == L'/')) || ((p[0] == L'\\' || p[0] == L'/') && (p[1] == L'\\' || p[1] == L'/')); }
static wchar_t *win_join(const wchar_t *dir, const wchar_t *path)   /* path relative to dir (NULL: our own), as a full path */
{
    wchar_t *cat, *full; DWORD n; size_t dl, pl = wcslen(path);
    wchar_t here[MAX_PATH + 1];
    if (!dir) { if (!(n = GetCurrentDirectoryW(MAX_PATH + 1, here)) || n > MAX_PATH) return NULL; dir = here; }
    if (win_absolute(path) || (path[0] == L'\\' || path[0] == L'/')) {   /* absolute, or rooted on dir's drive */
        if (win_absolute(path) || !dir[0] || dir[1] != L':') dl = 0; else dl = 2;
    }
    else if (path[0] && path[1] == L':') {   /* "D:name" (post-0.12; was joined as "dir\D:name"): relative to dir if dir is
        on that drive, else to the process's directory there */
        if (dir[0] && dir[1] == L':' && towupper(dir[0]) == towupper(path[0])) { path += 2; pl -= 2; dl = wcslen(dir); }
        else dl = 0;
    }
    else dl = wcslen(dir);
    if (!(cat = (wchar_t *)win_malloc((dl + pl + 2) * sizeof *cat))) return NULL;
    wmemcpy(cat, dir, dl); cat[dl] = 0;
    if (dl > 2 || (dl && !(path[0] == L'\\' || path[0] == L'/'))) { if (cat[dl - 1] != L'\\' && cat[dl - 1] != L'/') wcscat(cat, L"\\"); }
    wcscat(cat, path);
    n = GetFullPathNameW(cat, 0, NULL, NULL);
    if (!n || !(full = (wchar_t *)win_malloc(n * sizeof *full)) || !GetFullPathNameW(cat, n, full, NULL)) { win_free(cat); return NULL; }
    win_free(cat);
    return full;
}
static int win_is_cmd(const wchar_t *app)   /* is the program cmd.exe? */
{
    const wchar_t *b = app, *q;
    if (!app) return 0;
    for (q = app; *q; q++) if (*q == L'\\' || *q == L'/' || *q == L':') b = q + 1;
    return !_wcsicmp(b, L"cmd.exe") || !_wcsicmp(b, L"cmd");
}
static int win_is_slash_c(const wchar_t *a)   /* cmd.exe's /c, alone or last of several options (/x/d/c) */
{ size_t al = wcslen(a); return al >= 2 && a[0] == L'/' && !_wcsicmp(a + al - 2, L"/c"); }
static wchar_t *win_quote_argv(char *const argv[], const wchar_t *app, UINT cp, int options)   /* argv as one command line,
                                                                                    as CommandLineToArgvW reads it back */
{   /* cmd.exe: after its /c (or /x/c ...) with two or more words following, the rest gets one more pair of quotes,
       which cmd strips (its own rules, "cmd /?"), as Perl's create_command_line() in win32/win32.c does.
       (post-0.12, from the patch that takes this file into Perl's core, which sets them; Proc::Spawner does not:)
       WIN_OPT_CMD_RAW: with exactly one word after cmd.exe's /c, that word is a command line for cmd.exe: passed as
       it is, in one pair of quotes (cmd.exe does not know the C runtime's backslash escapes).
       WIN_OPT_ARGV_RAW: the caller has made the command line itself: argv's words (as a rule one, the whole command
       line) are joined with single blanks as they are.
       WIN_OPT_KEEP_QUOTED: a word that begins and ends with '"' is taken as quoted by the caller and copied as it is
       (what Perl's create_command_line() does, and scripts written for it rely on); inside the pair of quotes after
       cmd.exe's /c too. */
    size_t cap = 3, len = 0; int i, wrap = 0, cmd = win_is_cmd(app); wchar_t *cl, **w; int argc = 0;
    int raw = (options & WIN_OPT_ARGV_RAW) != 0, rawc = (options & WIN_OPT_CMD_RAW) != 0, keepq = (options & WIN_OPT_KEEP_QUOTED) != 0;
    while (argv && argv[argc]) argc++;
    if (!(w = (wchar_t **)win_calloc(argc + 1, sizeof *w))) return NULL;
    for (i = 0; i < argc; i++) { if (!(w[i] = win_wide(argv[i], cp))) goto fail; cap += 3 + 2 * wcslen(w[i]); }
    if (!(cl = (wchar_t *)win_malloc(cap * sizeof *cl))) goto fail;
    for (i = 0; i < argc; i++) {
        const wchar_t *a = w[i]; int quote = !*a || wcspbrk(a, L" \t\n\v\"") != NULL; size_t bs = 0, al = wcslen(a);
        if (i) cl[len++] = L' ';
        if (raw) { wcscpy(cl + len, a); len += al; continue; }
        if (i && wrap == 1) { cl[len++] = L'"'; wrap = 2; }
        if (keepq && al >= 2 && a[0] == L'"' && a[al - 1] == L'"') { wcscpy(cl + len, a); len += al; continue; }
        if (cmd && !wrap && i && win_is_slash_c(a) && i + 2 < argc) {
            wcscpy(cl + len, a); len += al; wrap = 1; continue; }
        if (cmd && rawc && !wrap && i >= 2 && i + 1 == argc && win_is_slash_c(w[i - 1])) {
            cl[len++] = L'"'; wcscpy(cl + len, a); len += al; cl[len++] = L'"'; continue; }
        if (!quote) { wcscpy(cl + len, a); len += wcslen(a); continue; }
        cl[len++] = L'"';
        for (; *a; a++) {
            if (*a == L'\\') { bs++; continue; }
            if (*a == L'"') { while (bs) { cl[len++] = L'\\'; cl[len++] = L'\\'; bs--; } cl[len++] = L'\\'; cl[len++] = L'"'; continue; }
            while (bs) { cl[len++] = L'\\'; bs--; }
            cl[len++] = *a;
        }
        while (bs) { cl[len++] = L'\\'; cl[len++] = L'\\'; bs--; }   /* before the closing quote: doubled */
        cl[len++] = L'"';
    }
    if (wrap == 2) cl[len++] = L'"';
    cl[len] = 0;
    for (i = 0; i < argc; i++) win_free(w[i]);
    win_free(w);
    return cl;
fail:
    for (i = 0; i < argc; i++) win_free(w[i]);
    win_free(w); return NULL;
}
struct win_env_one { wchar_t *s; int at; };   /* an entry of the block, and where the caller gave it */
static int win_env_namecmp(const wchar_t *x, const wchar_t *y)   /* by name, ignoring case, as Windows keeps the block */
{
    const wchar_t *xe = wcschr(x + (*x == L'='), L'='), *ye = wcschr(y + (*y == L'='), L'=');
    int xl = xe ? (int)(xe - x) : (int)wcslen(x), yl = ye ? (int)(ye - y) : (int)wcslen(y);
    int c = CompareStringOrdinal(x, xl, y, yl, TRUE);
    return c == CSTR_LESS_THAN ? -1 : c == CSTR_GREATER_THAN ? 1 : 0;
}
static int win_env_cmp(const void *a, const void *b)   /* by name, then by the caller's order */
{
    const struct win_env_one *x = (const struct win_env_one *)a, *y = (const struct win_env_one *)b;
    int c = win_env_namecmp(x->s, y->s);
    return c ? c : x->at < y->at ? -1 : x->at > y->at;
}
static int win_is_batch(const wchar_t *app)
{ size_t l = app ? wcslen(app) : 0; return l > 4 && (!_wcsicmp(app + l - 4, L".bat") || !_wcsicmp(app + l - 4, L".cmd")); }
static wchar_t *win_bat_command_line(const wchar_t *script, char *const argv[], UINT cp, int *err)
{   /* A .bat or .cmd file: cmd.exe /e:ON /v:OFF /d /c ""SCRIPT" ARGS", each argument quoted for cmd.exe as the Rust
       standard library does it since the BatBadBut advisory (CVE-2024-24576; library/std, windows/args.rs,
       make_bat_command_line and append_bat_arg): quoted unless it has only letters, digits and #$*+-./:?@\_, a '"'
       doubled, a '%' written %%cd:~,% (cmd expands that to nothing, so no %NAME% is expanded), and a trailing '\'
       makes it quoted.  What cannot be passed so is refused, EINVAL: a CR or LF (cmd ends the line there), a script
       path with a '"' or ending in '\'.  argv[0] is not passed (the script is %0). */
    size_t cap = 64 + wcslen(script), len; int i; wchar_t *cl, **w; int argc = 0;
    while (argv && argv[argc]) argc++;
    if (wcschr(script, L'"') || script[wcslen(script) - 1] == L'\\') { *err = EINVAL; return NULL; }
    if (!(w = (wchar_t **)win_calloc(argc + 1, sizeof *w))) { *err = ENOMEM; return NULL; }
    for (i = 1; i < argc; i++) {
        if (!(w[i] = win_wide(argv[i], cp))) { *err = errno; goto fail; }
        if (wcspbrk(w[i], L"\r\n")) { *err = EINVAL; goto fail; }
        cap += 4 + 9 * wcslen(w[i]);   /* at worst every character a '%' (9 wide) */
    }
    if (!(cl = (wchar_t *)win_malloc(cap * sizeof *cl))) { *err = ENOMEM; goto fail; }
    wcscpy(cl, L"cmd.exe /e:ON /v:OFF /d /c \"\""); wcscat(cl, script); wcscat(cl, L"\""); len = wcslen(cl);
    for (i = 1; i < argc; i++) {
        const wchar_t *a = w[i], *p; size_t bs = 0, al = wcslen(a); int quote = !al || a[al - 1] == L'\\';
        for (p = a; *p; p++)
            if (*p < 0x80 ? !(iswalnum(*p) || wcschr(L"#$*+-./:?@\\_", *p)) : iswcntrl(*p)) quote = 1;
        cl[len++] = L' ';
        if (quote) cl[len++] = L'"';
        for (p = a; *p; p++) {
            if (*p == L'\\') { bs++; cl[len++] = *p; continue; }
            if (*p == L'"') { size_t k; for (k = 0; k < bs; k++) cl[len++] = L'\\'; cl[len++] = L'"'; }   /* 2n backslashes, '""' */
            else if (*p == L'%') { wcscpy(cl + len, L"%%cd:~,"); len += 7; }
            bs = 0; cl[len++] = *p;
        }
        if (quote) { size_t k; for (k = 0; k < bs; k++) cl[len++] = L'\\'; cl[len++] = L'"'; }
    }
    cl[len++] = L'"'; cl[len] = 0;
    for (i = 0; i < argc; i++) win_free(w[i]);
    win_free(w); *err = 0;
    return cl;
fail:
    for (i = 0; i < argc; i++) win_free(w[i]);
    win_free(w); return NULL;
}
static wchar_t *win_env_block(char *const envp[], UINT cp)   /* "K=V\0...\0\0" in UTF-16, sorted by name, ignoring case */
{   /* The parent's hidden "=C:=C:\dir" entries (each drive's current directory) are kept, as a NULL environment would.
       A name given twice (in any case): the first entry only, as getenv finds it (post-0.12, X58: the sort put either
       first; Windows' own lookup then took that one, a C runtime's environ the last) */
    int n = 0, i, k = 0, m, own = 0; struct win_env_one *e; wchar_t *b, *p, *par = GetEnvironmentStringsW(), *q; size_t len = 2;
    for (i = 0; envp[i]; i++) { n++; if (envp[i][0] == '=') own = 1; }
    if (par && !own) for (q = par; *q; q += wcslen(q) + 1) if (q[0] == L'=' && q[1] && q[2] == L':' && q[3] == L'=') n++;
    if (!(e = (struct win_env_one *)win_calloc(n + 1, sizeof *e))) { if (par) FreeEnvironmentStringsW(par); return NULL; }
    for (i = 0; envp[i]; i++) { e[k].at = k; if (!(e[k++].s = win_wide(envp[i], cp))) goto fail; }
    if (par && !own) for (q = par; *q; q += wcslen(q) + 1)
        if (q[0] == L'=' && q[1] && q[2] == L':' && q[3] == L'=') { e[k].at = k; if (!(e[k++].s = win_wcsdup(q))) goto fail; }
    qsort(e, k, sizeof *e, win_env_cmp);
    for (i = m = 0; i < k; i++)   /* the first of each name */
        if (m && !win_env_namecmp(e[m - 1].s, e[i].s)) win_free(e[i].s); else e[m++] = e[i];
    k = m;
    for (i = 0; i < k; i++) len += wcslen(e[i].s) + 1;
    if (!(b = (wchar_t *)win_malloc(len * sizeof *b))) goto fail;
    for (p = b, i = 0; i < k; i++) { wcscpy(p, e[i].s); p += wcslen(e[i].s) + 1; }
    *p++ = 0; if (!k) *p = 0;   /* an empty environment still ends in two NULs */
    for (i = 0; i < k; i++) win_free(e[i].s);
    win_free(e); if (par) FreeEnvironmentStringsW(par);
    return b;
fail:
    for (i = 0; i < k; i++) win_free(e[i].s);
    win_free(e); if (par) FreeEnvironmentStringsW(par);
    return NULL;
}
static char *win_acp_to_utf8(const char *s)   /* a byte string in the ANSI code page (as Perl's own CreateProcess
                                                takes it) as a new UTF-8 string, or NULL */
{
    int n = MultiByteToWideChar(CP_ACP, 0, s, -1, NULL, 0), m; wchar_t *w; char *u;
    if (n <= 0 || !(w = (wchar_t *)win_malloc(n * sizeof *w))) return NULL;
    MultiByteToWideChar(CP_ACP, 0, s, -1, w, n);
    m = WideCharToMultiByte(CP_UTF8, 0, w, -1, NULL, 0, NULL, NULL);
    if (m <= 0 || !(u = (char *)win_malloc(m))) { win_free(w); return NULL; }
    WideCharToMultiByte(CP_UTF8, 0, w, -1, u, m, NULL, NULL); win_free(w);
    return u;
}
static wchar_t *win_path_tok(wchar_t **p)   /* the next PATH entry: ';'-separated, a "quoted;part" kept whole */
{
    wchar_t *t = *p, *in, *out;
    if (!t || !*t) return NULL;
    for (in = out = t; *in && *in != L';'; ) {
        if (*in == L'"') { in++; while (*in && *in != L'"') *out++ = *in++; if (*in) in++; }
        else *out++ = *in++;
    }
    *p = *in ? in + 1 : NULL; *out = 0;
    return t;
}
static int win_has_ext(const wchar_t *p)
{
    const wchar_t *base = p, *q;
    for (q = p; *q; q++) if (*q == L'\\' || *q == L'/' || *q == L':') base = q + 1;
    return wcschr(base, L'.') != NULL;
}
static wchar_t *win_try(const wchar_t *p, const wchar_t *pathext)   /* p, or p with a PATHEXT extension (pathext: its
                                                                          value, NULL: unset), if that is a file: a new string */
{
    wchar_t *r; const wchar_t *e, *end; DWORD a; size_t pl = wcslen(p), el;
    if (win_has_ext(p)) { a = GetFileAttributesW(p); return a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY) ? win_wcsdup(p) : NULL; }
    /* no extension: PATHEXT's first (prog.exe before a file "prog", say an MSYS script, which CreateProcess cannot run),
       then the bare name, as Perl's qualified_path() tries .exe first */
    for (e = pathext ? pathext : L".COM;.EXE"; e; e = end ? end + 1 : NULL) {
        end = wcschr(e, L';'); el = end ? (size_t)(end - e) : wcslen(e);
        if (!el) continue;
        if (!(r = (wchar_t *)win_malloc((pl + el + 1) * sizeof *r))) return NULL;
        wmemcpy(r, p, pl); wmemcpy(r + pl, e, el); r[pl + el] = 0;
        a = GetFileAttributesW(r);
        if (a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY)) return r;
        win_free(r);
    }
    a = GetFileAttributesW(p);
    return a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY) ? win_wcsdup(p) : NULL;
}
static wchar_t *win_try_in(const wchar_t *dir, const wchar_t *p, const wchar_t *pathext)   /* win_try of p relative to dir
                                                                                             (NULL: the process's) */
{ wchar_t *f = win_join(dir, p), *r = f ? win_try(f, pathext) : NULL; win_free(f); return r; }
static wchar_t *win_search(const wchar_t *name, const wchar_t *cwd, wchar_t *path, const wchar_t *pathext)
{   /* posix_spawnp: a name with a directory part as it is, else each entry of path (PATH's value, cut up here; NULL:
       unset), as given and with PATHEXT.  (post-0.12, X57: PATH and PATHEXT the caller's, the hook var; a relative
       name or PATH entry from the child's directory, cwd, as glibc's posix_spawnp after a chdir action, not from the
       process's) */
    wchar_t *d, *ctx = path, *r = NULL, *cand;
    if (wcspbrk(name, L"\\/:")) return win_try_in(cwd, name, pathext);
    while (!r && (d = win_path_tok(&ctx))) {
        size_t dl = wcslen(d);
        if (!dl) continue;
        if (!(cand = (wchar_t *)win_malloc((dl + wcslen(name) + 2) * sizeof *cand))) break;
        wcscpy(cand, d); if (d[dl - 1] != L'\\' && d[dl - 1] != L'/') wcscat(cand, L"\\"); wcscat(cand, name);
        r = win_try_in(cwd, cand, pathext); win_free(cand);
    }
    return r;
}

/* The job of WIN_OPT_KILL_WITH_PARENT unless the call names one (the attribute kill_job): made at the first child that
   needs it, one for the process (post-0.12: also when two threads start the first children at once) */
static void *volatile win_job;
static HANDLE win_kill_job(void)
{
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION li; HANDLE j;
    if (win_job) return (HANDLE)win_job;
    if (!(j = CreateJobObjectW(NULL, NULL))) return NULL;
    memset(&li, 0, sizeof li);
    li.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    if (!SetInformationJobObject(j, JobObjectExtendedLimitInformation, &li, sizeof li)) { CloseHandle(j); return NULL; }
    if (InterlockedCompareExchangePointer((void *volatile *)&win_job, j, NULL)) CloseHandle(j);   /* another thread's came first */
    return (HANDLE)win_job;
}

/* the process handles of our children, by pid, until the caller has their exit code; the table grows as needed
   (post-0.09: it was 1024 entries, after which a handle was closed at once and the exit code could be lost); the
   default of the hook keep; one for the process, under a lock (post-0.12) */
typedef struct { pid_t pid; HANDLE h, job; } win_kid_t;   /* job: the child's own job (limits, W4), or NULL */
static win_kid_t *win_kids; static int win_nkids; static SRWLOCK win_kids_lock = SRWLOCK_INIT;
static void win_keep(pid_t pid, HANDLE h, HANDLE job)
{
    int i, n; win_kid_t *k;
    AcquireSRWLockExclusive(&win_kids_lock);
    for (i = 0; i < win_nkids; i++) if (!win_kids[i].h) { win_kids[i].pid = pid; win_kids[i].h = h; win_kids[i].job = job; goto done; }
    n = win_nkids ? 2 * win_nkids : 64;
    if (!(k = (win_kid_t *)win_realloc(win_kids, n * sizeof *k))) { CloseHandle(h); if (job) CloseHandle(job); goto done; }   /* no memory */
    memset(k + win_nkids, 0, (n - win_nkids) * sizeof *k);
    k[win_nkids].pid = pid; k[win_nkids].h = h; k[win_nkids].job = job; win_kids = k; win_nkids = n;
done:
    ReleaseSRWLockExclusive(&win_kids_lock);
}
static HANDLE win_spawn_handle(pid_t pid)
{
    int i; HANDLE h = NULL;
    AcquireSRWLockShared(&win_kids_lock);
    for (i = 0; i < win_nkids; i++) if (win_kids[i].h && win_kids[i].pid == pid) { h = win_kids[i].h; break; }
    ReleaseSRWLockShared(&win_kids_lock);
    return h;
}
static void win_spawn_forget(pid_t pid)
{
    int i;
    AcquireSRWLockExclusive(&win_kids_lock);
    for (i = 0; i < win_nkids; i++) if (win_kids[i].h && win_kids[i].pid == pid) {
        CloseHandle(win_kids[i].h); win_kids[i].h = NULL; if (win_kids[i].job) { CloseHandle(win_kids[i].job); win_kids[i].job = NULL; } }
    ReleaseSRWLockExclusive(&win_kids_lock);
}
static HANDLE win_child_job(const win_job_limits_t *l, int kill_on_close)   /* a job with these limits, or NULL */
{
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION li; HANDLE j = CreateJobObjectW(NULL, NULL);
    if (!j) return NULL;
    memset(&li, 0, sizeof li);
    li.BasicLimitInformation.LimitFlags = l->flags | (kill_on_close ? JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE : 0);
    li.ProcessMemoryLimit = l->ProcessMemoryLimit; li.JobMemoryLimit = l->JobMemoryLimit;
    li.BasicLimitInformation.PerProcessUserTimeLimit.QuadPart = l->PerProcessUserTimeLimit;
    li.BasicLimitInformation.PerJobUserTimeLimit.QuadPart = l->PerJobUserTimeLimit;
    li.BasicLimitInformation.ActiveProcessLimit = l->ActiveProcessLimit;
    if (!SetInformationJobObject(j, JobObjectExtendedLimitInformation, &li, sizeof li)) { DWORD e = GetLastError(); CloseHandle(j); SetLastError(e); return NULL; }
    return j;
}

static int win_cd(wchar_t **cwd, wchar_t *w)   /* *cwd becomes w (taken), relative to *cwd (NULL: ours): 0, or an errno */
{
    wchar_t *n = win_join(*cwd, w); DWORD a;
    win_free(w);
    if (!n) return ENOMEM;
    a = GetFileAttributesW(n);
    if (a == INVALID_FILE_ATTRIBUTES || !(a & FILE_ATTRIBUTE_DIRECTORY)) { win_free(n); return a == INVALID_FILE_ATTRIBUTES ? ENOENT : ENOTDIR; }
    win_free(*cwd); *cwd = n;
    return 0;
}

/* ------------------------------------------------------------------ the call */
static int win_spawn(pid_t *pid, const char *file, int search, const win_file_actions_t *fa, const win_spawnattr_t *sa,
                     char *const argv[], char *const envp[])
{
    HANDLE fd[WIN_MAXFD], dup[WIN_MAXFD], opened[WIN_MAXFD], self = GetCurrentProcess();
    int nopened = 0, i, j, top = -1, ndup = 0, rc = 0, console = 0;
    wchar_t *cwd = NULL, *wfile = NULL, *app = NULL, *cl = NULL, *env = NULL;
    STARTUPINFOEXW si; PROCESS_INFORMATION pi; SIZE_T asz = 0; DWORD cf = EXTENDED_STARTUPINFO_PRESENT | CREATE_UNICODE_ENVIRONMENT;
    BYTE *crt = NULL; HANDLE list[WIN_MAXFD];
    win_spawnattr_t none; const win_spawn_hooks_t *hk; UINT cp; int opt;
    if (!sa) { win_attr_init(&none); sa = &none; }   /* no attributes: the defaults */
    hk = sa->hooks; cp = sa->codepage; opt = sa->options;
    memset(&si, 0, sizeof si); si.StartupInfo.cb = sizeof si;
    if ((sa->flags & WIN_SPAWN_SETSIGMASK) && sa->mask) return ENOTSUP;
    if ((sa->flags & WIN_SPAWN_SETPGROUP) && sa->pgroup) return ENOTSUP;
    if (sa->flags & (WIN_SPAWN_SETSID | WIN_SPAWN_SETSCHEDULER | WIN_SPAWN_SETSCHEDPARAM)) return ENOTSUP;
    if (sa->flags & WIN_SPAWN_SETPGROUP) cf |= CREATE_NEW_PROCESS_GROUP;
    if (opt & WIN_OPT_NEW_GROUP) cf |= CREATE_NEW_PROCESS_GROUP;
    for (i = 0; i < WIN_MAXFD; i++) fd[i] = NULL;
    for (i = 0; i < 3; i++) {   /* the parent's 0-2 */
        intptr_t o = win_osf(hk, i);
        if (o != -1 && o != -2) fd[i] = (HANDLE)o;
    }
    if (hk && hk->cwd) {   /* the caller's directory, as if by a first chdir action (an absolute path: not relative to ours) */
        const char *d = hk->cwd(hk->ctx); wchar_t *w;
        if (d) { if (!(w = win_wide(d, cp))) rc = errno; else rc = win_cd(&cwd, w); }
    }
    for (j = 0; fa && j < fa->n && !rc; j++) {   /* the file actions, in order, on the child's table */
        const struct win_fa_one *x = &fa->a[j];
        switch (x->op) {
        case WIN_FA_DUP2: {   /* the source: the child's fd so far; one of 3 or more no action named yet: the parent's */
            HANDLE h = fd[x->fd];
            if (!h && x->fd >= 3) { intptr_t p = win_osf(hk, x->fd); if (p != -1 && p != -2) h = (HANDLE)p; }
            if (!h) rc = EBADF; else fd[x->newfd] = h;
            break; }
        case WIN_FA_CLOSE: fd[x->fd] = NULL; break;
        case WIN_FA_CLOSEFROM: for (i = x->fd; i < WIN_MAXFD; i++) fd[i] = NULL; break;
        case WIN_FA_CHDIR: case WIN_FA_FCHDIR: {
            wchar_t *w;
            if (x->op == WIN_FA_CHDIR) { if (!(w = win_wide(x->path, cp))) { rc = errno; break; } }
            else {
                intptr_t p = win_osf(hk, x->fd); DWORD len;
                if (p == -1 || p == -2) { rc = EBADF; break; }
                len = GetFinalPathNameByHandleW((HANDLE)p, NULL, 0, FILE_NAME_NORMALIZED);
                if (!len || !(w = (wchar_t *)win_malloc((len + 1) * sizeof *w))) { rc = len ? ENOMEM : win_err(hk, GetLastError()); break; }
                GetFinalPathNameByHandleW((HANDLE)p, w, len + 1, FILE_NAME_NORMALIZED);
                if (!wcsncmp(w, L"\\\\?\\", 4) && w[5] == L':') memmove(w, w + 4, (wcslen(w) - 3) * sizeof *w);
            }
            rc = win_cd(&cwd, w);
            break; }
        case WIN_FA_OPEN: {
            wchar_t *w = win_wide(x->path, cp), *n; DWORD acc, disp, attr = FILE_ATTRIBUTE_NORMAL; HANDLE h;
            SECURITY_ATTRIBUTES sec = { sizeof sec, NULL, FALSE };
            if (!w) { rc = errno; break; }
            /* /dev/null, in any case, is NUL, as Perl's own open makes it (win32_open in win32/win32.c) */
            n = _stricmp(x->path, "/dev/null") == 0 ? win_wcsdup(L"NUL") : win_join(cwd, w); win_free(w);
            if (!n) { rc = ENOMEM; break; }
            switch (x->oflag & (O_RDONLY | O_WRONLY | O_RDWR)) {
            case O_WRONLY: acc = GENERIC_WRITE; break;
            case O_RDWR: acc = GENERIC_READ | GENERIC_WRITE; break;
            default: acc = GENERIC_READ;
            }
            if (x->oflag & O_APPEND) acc = (acc & ~GENERIC_WRITE) | FILE_APPEND_DATA | SYNCHRONIZE | FILE_READ_ATTRIBUTES;
            disp = (x->oflag & O_CREAT) ? ((x->oflag & O_EXCL) ? CREATE_NEW : (x->oflag & O_TRUNC) ? CREATE_ALWAYS : OPEN_ALWAYS)
                 : (x->oflag & O_TRUNC) ? TRUNCATE_EXISTING : OPEN_EXISTING;
            if ((x->oflag & O_CREAT) && !(x->mode & 0200)) attr = FILE_ATTRIBUTE_READONLY;
            h = CreateFileW(n, acc, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, &sec, disp, attr, NULL);
            win_free(n);
            if (h == INVALID_HANDLE_VALUE) { rc = win_err(hk, GetLastError()); break; }
            opened[nopened++] = h; fd[x->fd] = h;
            break; }
        default: rc = EINVAL;
        }
    }
    if (!rc && !(wfile = win_wide(file, cp))) rc = errno;
    if (!rc) {   /* the program: its full name, with its extension */
        wchar_t *pathext = win_getenv(hk, cp, "PATHEXT");
        if (search) { wchar_t *path = win_getenv(hk, cp, "PATH"); app = win_search(wfile, cwd, path, pathext); win_free(path); }
        else app = win_try_in(cwd, wfile, pathext);
        win_free(pathext);
        if (!app) rc = ENOENT;
    }
    if (!rc && win_is_batch(app) && !(opt & WIN_OPT_ARGV_RAW)) {   /* run by cmd.exe from the system directory (not one found
        on PATH); with WIN_OPT_ARGV_RAW the caller's own command line goes to CreateProcessW, which starts cmd.exe itself */
        wchar_t sys[MAX_PATH + 16]; UINT n = GetSystemDirectoryW(sys, MAX_PATH);
        if (!(cl = win_bat_command_line(app, argv, cp, &rc)) && !rc) rc = ENOMEM;
        if (!rc) { if (!n || n > MAX_PATH) rc = ENOENT; else { wcscat(sys, L"\\cmd.exe"); win_free(app); if (!(app = win_wcsdup(sys))) rc = ENOMEM; } }
    }
    else if (!rc && !(cl = win_quote_argv(argv, app, cp, opt))) rc = ENOMEM;
    if (!rc && wcslen(cl) > 32766) rc = E2BIG;   /* CreateProcessW's limit for the command line */
    if (!rc && !envp && hk && hk->env) envp = hk->env(hk->ctx);   /* the caller's environment (NULL: the process's) */
    if (!rc && envp && !(env = win_env_block(envp, cp))) rc = ENOMEM;
    for (i = 0; !rc && i < WIN_MAXFD; i++) {   /* inheritable copies, one per handle, made for this call */
        dup[i] = NULL;
        if (!fd[i]) continue;
        for (j = 0; j < i; j++) if (fd[j] == fd[i]) { dup[i] = dup[j]; break; }
        if (!dup[i]) {
            if (!DuplicateHandle(self, fd[i], self, &dup[i], 0, TRUE, DUPLICATE_SAME_ACCESS)) { rc = win_err(hk, GetLastError()); dup[i] = NULL; break; }
            if (((ULONG_PTR)dup[i] & 3) != 3) list[ndup++] = dup[i];   /* (a Windows 7 console pseudo-handle cannot be
                in the list; it reaches the child through STARTUPINFO) */
            else { HANDLE c = dup[i]; CloseHandle(c); dup[i] = fd[i]; console = 1; }
        }
        top = i;
    }
    if (!rc) {
        si.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
        if (sa->showwindow >= 0) { si.StartupInfo.dwFlags |= STARTF_USESHOWWINDOW; si.StartupInfo.wShowWindow = (WORD)sa->showwindow; }
        if (!dup[0] && !dup[1] && !dup[2] && (opt & WIN_OPT_NEW_CONSOLE)) cf |= CREATE_NEW_CONSOLE;
        si.StartupInfo.hStdInput = dup[0] ? dup[0] : INVALID_HANDLE_VALUE;
        si.StartupInfo.hStdOutput = dup[1] ? dup[1] : INVALID_HANDLE_VALUE;
        si.StartupInfo.hStdError = dup[2] ? dup[2] : INVALID_HANDLE_VALUE;
        if (top >= 3) {   /* the C runtime's table: int count, then count flag bytes, then count handles */
            int count = top + 1; size_t sz = sizeof(int) + count * (1 + sizeof(HANDLE));
            if (!(crt = (BYTE *)win_calloc(1, sz))) rc = ENOMEM;
            else {
                memcpy(crt, &count, sizeof(int));
                for (i = 0; i < count; i++) {
                    HANDLE h = dup[i] ? dup[i] : INVALID_HANDLE_VALUE; BYTE f = 0;
                    if (dup[i]) { DWORD t = GetFileType(dup[i]); f = 0x01 | (t == FILE_TYPE_PIPE ? 0x08 : t == FILE_TYPE_CHAR ? 0x40 : 0); }   /* FOPEN, FPIPE, FDEV */
                    crt[sizeof(int) + i] = f;
                    memcpy(crt + sizeof(int) + count + i * sizeof(HANDLE), &h, sizeof(HANDLE));
                }
                si.StartupInfo.cbReserved2 = (WORD)sz; si.StartupInfo.lpReserved2 = crt;
                if (sz > 65535) rc = E2BIG;
            }
        }
    }
    if (!rc && ndup) {   /* only these handles */
        InitializeProcThreadAttributeList(NULL, 1, 0, &asz);
        if (!(si.lpAttributeList = (LPPROC_THREAD_ATTRIBUTE_LIST)win_malloc(asz))
            || !InitializeProcThreadAttributeList(si.lpAttributeList, 1, 0, &asz)) { win_free(si.lpAttributeList); si.lpAttributeList = NULL; rc = ENOMEM; }
        else if (!UpdateProcThreadAttribute(si.lpAttributeList, 0, PROC_THREAD_ATTRIBUTE_HANDLE_LIST, list, ndup * sizeof(HANDLE), NULL, NULL))
            rc = win_err(hk, GetLastError());
    }
    if (!rc) {
        int kill = (opt & WIN_OPT_KILL_WITH_PARENT) != 0;
        HANDLE job = !kill ? NULL : sa->kill_job ? sa->kill_job : win_kill_job(), own = NULL;
        if (sa->job.flags && !(own = win_child_job(&sa->job, kill))) rc = win_err(hk, GetLastError());
        DWORD prio = sa->priority_class;   /* (W4: set on the suspended child; Wine ignores the creation flag) */
        if (!rc && (job || own || prio)) cf |= CREATE_SUSPENDED;
        if (!rc && !CreateProcessW(app, cl, NULL, NULL, ndup > 0 || console, cf, env, cwd, &si.StartupInfo, &pi)) rc = win_err(hk, GetLastError());
        else if (!rc) {
            if (job) AssignProcessToJobObject(job, pi.hProcess);   /* (a job not nestable here, before Windows 8 when we
                are in a job already: the child runs outside it) */
            if (own && !AssignProcessToJobObject(own, pi.hProcess)) {   /* its limits: a job of its own, nested (Windows 8) */
                rc = win_err(hk, GetLastError()); TerminateProcess(pi.hProcess, 255); CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
                CloseHandle(own); own = NULL;
            }
            else if (prio && !SetPriorityClass(pi.hProcess, prio)) {
                rc = win_err(hk, GetLastError()); TerminateProcess(pi.hProcess, 255); CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
                if (own) { CloseHandle(own); own = NULL; }
            }
            else {   /* the handles to the child table: this file's, or the caller's (the hook keep), before it runs */
                int suspended = job || own || prio;
                if (hk && hk->keep) rc = hk->keep(hk->ctx, (pid_t)pi.dwProcessId, pi.hProcess, own);
                else win_keep((pid_t)pi.dwProcessId, pi.hProcess, own);
                if (rc) { TerminateProcess(pi.hProcess, 255); CloseHandle(pi.hProcess); }   /* (own: closed below) */
                else { own = NULL; if (suspended) ResumeThread(pi.hThread); *pid = (pid_t)pi.dwProcessId; }
                CloseHandle(pi.hThread);
            }
        }
        if (own) CloseHandle(own);
    }
    if (si.lpAttributeList) { DeleteProcThreadAttributeList(si.lpAttributeList); win_free(si.lpAttributeList); }
    for (i = 0; i < ndup; i++) CloseHandle(list[i]);
    for (i = 0; i < nopened; i++) CloseHandle(opened[i]);
    win_free(crt); win_free(env); win_free(cl); win_free(app); win_free(wfile); win_free(cwd);
    return rc;
}
static int win_posix_spawn(pid_t *pid, const char *file, const win_file_actions_t *fa, const win_spawnattr_t *sa,
                           char *const argv[], char *const envp[])
{ return win_spawn(pid, file, 0, fa, sa, argv, envp); }
static int win_posix_spawnp(pid_t *pid, const char *file, const win_file_actions_t *fa, const win_spawnattr_t *sa,
                            char *const argv[], char *const envp[])
{ return win_spawn(pid, file, 1, fa, sa, argv, envp); }

#ifdef __GNUC__
#  pragma GCC diagnostic pop
#endif

#endif /* WIN_SPAWN_H */
