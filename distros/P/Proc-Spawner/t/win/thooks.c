/* thooks.exe: win_spawn.h alone (post-0.12): attributes per call, the hooks, the code page, the quoting options.
   Run by t/win_spawn.t, from a directory of its own with clchild.exe (t/win/clchild.c) beside it; prints a line
   "ok - WHAT" or "NOT OK - WHAT" per check, then "N ok, M not ok"; exit status 0 if all are ok.
   Built with win_spawn.h's directory on the include path. */
#if defined(_MSC_VER) && !defined(pid_t)
typedef int pid_t;   /* (MSVC has none; Perl's headers give it, but none are included here) */
#endif
#include "win_spawn.h"
#include <stdio.h>
static int n_ok, n_fail;
static void ok(int c, const char *what) { printf("%s - %s\n", c ? "ok" : "NOT OK", what); if (c) n_ok++; else n_fail++; }
static wchar_t here[1024], child[1100], out[1100], sub[1100];
static char child8[1100], out8[1100], sub8[1100], dir8[1100];
static char *u8(const wchar_t *w) { static char b[4][2048]; static int k; k = (k + 1) % 4; WideCharToMultiByte(CP_UTF8, 0, w, -1, b[k], 2048, NULL, NULL); return b[k]; }
static char *slurp(void) { static char b[8192]; FILE *f = fopen(out8, "rb"); size_t n = f ? fread(b, 1, sizeof b - 1, f) : 0; b[n] = 0; if (f) fclose(f); return b; }
static int has(const char *s) { return strstr(slurp(), s) != NULL; }
/* hooks */
static int kept; static HANDLE kept_h, kept_job; static int keep_rc;
static int h_keep(void *c, pid_t pid, HANDLE p, HANDLE j) { (void)c; (void)pid; if (keep_rc) return keep_rc; kept++; kept_h = p; kept_job = j; return 0; }
static const char *h_path, *h_pathext; static int n_var;
static const char *h_var(void *c, const char *n) { (void)c; n_var++; return !strcmp(n, "PATH") ? h_path : !strcmp(n, "PATHEXT") ? h_pathext : NULL; }
static char *h_envv[4]; static char *const *h_env(void *c) { (void)c; return h_envv; }
static const char *h_cwdv; static const char *h_cwd(void *c) { (void)c; return h_cwdv; }
static int n_fd; static intptr_t h_fd(void *c, int fd) { (void)c; n_fd++; return _get_osfhandle(fd); }
static int n_err; static int h_err(void *c, DWORD e) { (void)c; n_err++; return e == ERROR_BAD_EXE_FORMAT ? 99 : win_errno(e); }
static int run(const char *file, int search, win_spawnattr_t *sa, char **argv, char **envp, pid_t *pid)
{   /* the child's fd 1 into out.txt */
    win_file_actions_t fa; int rc; DeleteFileW(out); win_fa_init(&fa);
    win_fa_addopen(&fa, 1, out8, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    rc = search ? win_posix_spawnp(pid, file, &fa, sa, argv, envp) : win_posix_spawn(pid, file, &fa, sa, argv, envp);
    win_fa_destroy(&fa); return rc;
}
static DWORD wait_h(HANDLE h) { DWORD c = 1234; WaitForSingleObject(h, 10000); GetExitCodeProcess(h, &c); return c; }
static DWORD wait_pid(pid_t pid) { HANDLE h = win_spawn_handle(pid); DWORD c = h ? wait_h(h) : 4321; win_spawn_forget(pid); return c; }
static int cl_is(char *const argv[], const wchar_t *app, int opt, const wchar_t *want)
{ wchar_t *c = win_quote_argv(argv, app, CP_UTF8, opt); int r = c && !wcscmp(c, want); if (!r) printf("#   got <%s> want <%s>\n", c ? u8(c) : "(null)", u8(want)); win_free(c); return r; }
int main(void)
{
    pid_t pid = 0; int rc; win_spawnattr_t sa; win_spawn_hooks_t hk; char *av[6];
    GetCurrentDirectoryW(1024, here);
    swprintf(child, 1100, L"%ls\\clchild.exe", here); swprintf(out, 1100, L"%ls\\out.txt", here); swprintf(sub, 1100, L"%ls\\sub", here);
    CreateDirectoryW(sub, NULL);
    strcpy(child8, u8(child)); strcpy(out8, u8(out)); strcpy(sub8, u8(sub)); strcpy(dir8, u8(here));
    av[0] = "clchild"; av[1] = "7"; av[2] = NULL;

    /* 1. no attributes: the defaults, the file's own table */
    rc = run(child8, 0, NULL, av, NULL, &pid); ok(!rc && win_spawn_handle(pid) != NULL, "no attributes: started, its handle in the file's table");
    ok(wait_pid(pid) == 7, "the exit code through the table"); ok(has("show=0,"), "no wShowWindow by default");
    /* 2. per call: showwindow, a job of the caller's; by default no job (W6) */
    { HANDLE j = CreateJobObjectW(NULL, NULL); BOOL in = FALSE;
      ok(!(WIN_OPT_DEFAULT & WIN_OPT_KILL_WITH_PARENT), "WIN_OPT_KILL_WITH_PARENT not in the defaults (W6)");
      win_attr_init(&sa); win_attr_setkilljob(&sa, j); av[2] = "1500"; av[3] = NULL;
      rc = run(child8, 0, &sa, av, NULL, &pid); IsProcessInJob(win_spawn_handle(pid), j, &in);
      ok(!rc && !in, "by default the child in no job of ours (W6)"); wait_pid(pid);
      win_attr_setoptions(&sa, WIN_OPT_DEFAULT | WIN_OPT_KILL_WITH_PARENT); win_attr_setshowwindow(&sa, 3);
      av[2] = "1500"; av[3] = NULL;
      rc = run(child8, 0, &sa, av, NULL, &pid); IsProcessInJob(win_spawn_handle(pid), j, &in);
      ok(!rc && in, "the attribute kill_job: the child in the caller's job"); wait_pid(pid); ok(has("show=1,3"), "the attribute showwindow: 3");
      win_attr_setoptions(&sa, WIN_OPT_DEFAULT); in = TRUE;
      rc = run(child8, 0, &sa, av, NULL, &pid); IsProcessInJob(win_spawn_handle(pid), j, &in);
      ok(!rc && !in, "without WIN_OPT_KILL_WITH_PARENT: not in the job"); wait_pid(pid);
      win_attr_init(&sa); win_attr_setoptions(&sa, WIN_OPT_DEFAULT | WIN_OPT_KILL_WITH_PARENT);
      rc = run(child8, 0, &sa, av, NULL, &pid); IsProcessInJob(win_spawn_handle(pid), j, &in);
      ok(!rc && !in, "a new attribute set: the file's own job again"); wait_pid(pid); ok(has("show=0,"), "showwindow per call: unset again");
      av[2] = NULL; CloseHandle(j); }
    /* 3. the hook keep */
    memset(&hk, 0, sizeof hk); hk.keep = h_keep; win_attr_init(&sa); win_attr_sethooks(&sa, &hk);
    rc = run(child8, 0, &sa, av, NULL, &pid);
    ok(!rc && kept == 1 && kept_h && !kept_job && !win_spawn_handle(pid), "keep: the handle to the hook, not to the table");
    ok(wait_h(kept_h) == 7, "keep: the exit code through the hook's handle"); CloseHandle(kept_h);
    sa.job.flags = JOB_OBJECT_LIMIT_ACTIVE_PROCESS; sa.job.ActiveProcessLimit = 4; av[2] = "1000"; av[3] = NULL;
    win_attr_setoptions(&sa, WIN_OPT_DEFAULT | WIN_OPT_KILL_WITH_PARENT);   /* (its job then ends it when closed) */
    rc = run(child8, 0, &sa, av, NULL, &pid);
    ok(!rc && kept == 2 && kept_job != NULL, "keep: the child's own job (win_job limits) to the hook too");
    ok(wait_h(kept_h) == 7, "keep with a job of its own: the child lives on after the call (its job not closed)");
    CloseHandle(kept_h); CloseHandle(kept_job); av[2] = NULL; sa.job.flags = 0; win_attr_setoptions(&sa, WIN_OPT_DEFAULT);
    keep_rc = EAGAIN; rc = run(child8, 0, &sa, av, NULL, &pid); keep_rc = 0;
    ok(rc == EAGAIN && !win_spawn_handle(pid), "keep failing: the call fails with its errno");
    /* 4. the hooks var, cwd, env */
    memset(&hk, 0, sizeof hk); win_attr_init(&sa); win_attr_sethooks(&sa, &hk);
    hk.var = h_var; h_path = "C:\\nonexistent;"; h_pathext = ".COM;.EXE";
    { char p[2300]; snprintf(p, sizeof p, "C:\\nonexistent;%s", dir8); rc = run("clchild", 1, &sa, av, NULL, &pid);
      ok(rc == ENOENT, "var: PATH the hook's (without our directory: not found)");
      h_path = p; rc = run("clchild", 1, &sa, av, NULL, &pid); ok(!rc && n_var >= 2, "var: PATH the hook's (with it: found)"); if (!rc) wait_pid(pid);
      h_pathext = ".XYZ"; rc = run("clchild", 1, &sa, av, NULL, &pid); ok(rc == ENOENT, "var: PATHEXT the hook's (.XYZ only: clchild.exe not tried)"); }
    hk.var = NULL; hk.cwd = h_cwd; h_cwdv = sub8;
    rc = run(child8, 0, &sa, av, NULL, &pid); if (!rc) wait_pid(pid);
    { char w[1200]; snprintf(w, sizeof w, "cwd=%s", sub8); ok(!rc && has(w), "cwd: the child's directory the hook's"); }
    h_cwdv = dir8; rc = run("clchild.exe", 0, &sa, av, NULL, &pid); ok(!rc, "cwd: a relative program name from the hook's directory"); if (!rc) wait_pid(pid);
    h_cwdv = sub8; rc = run("..\\clchild", 1, &sa, av, NULL, &pid); ok(!rc, "cwd: posix_spawnp, a name with a directory part, from the hook's directory"); if (!rc) wait_pid(pid);
    { char p[1200]; hk.var = h_var; h_pathext = NULL; snprintf(p, sizeof p, ".."); h_path = p;
      rc = run("clchild", 1, &sa, av, NULL, &pid); ok(!rc, "cwd: a relative PATH entry from the hook's directory"); if (!rc) wait_pid(pid); hk.var = NULL; }
    hk.cwd = NULL; hk.env = h_env; h_envv[0] = "FOO=from the hook"; h_envv[1] = NULL;
    rc = run(child8, 0, &sa, av, NULL, &pid); if (!rc) wait_pid(pid); ok(!rc && has("FOO=from the hook"), "env: envp NULL, the hook's environment");
    { char *e[] = { "FOO=given", NULL }; rc = run(child8, 0, &sa, av, e, &pid); if (!rc) wait_pid(pid); ok(!rc && has("FOO=given"), "env: envp given wins"); }
    { char *e[] = { "FOO=first", "foo=second", "FOO=third", NULL }; rc = run(child8, 0, &sa, av, e, &pid); if (!rc) wait_pid(pid); ok(!rc && has("FOO=first\r"), "a name given thrice: the first (X58)"); }
    hk.env = NULL; hk.fd_handle = h_fd; hk.errno_of = h_err;
    rc = run(child8, 0, &sa, av, NULL, &pid); if (!rc) wait_pid(pid); ok(!rc && n_fd >= 3, "fd_handle: asked for the fds 0-2");
    { FILE *f = fopen("bad.exe", "w"); fputs("not a program", f); fclose(f);
      rc = run("bad.exe", 0, &sa, av, NULL, &pid); ok(rc == 99 && n_err >= 1, "errno_of: CreateProcessW's error through the hook"); }
    /* 5. the code page */
    { char e1[] = "FOO=caf\xe9"; char *e[] = { e1, NULL }; char a1[] = "x\xe9"; char *a[] = { "clchild", a1, NULL };
      win_attr_init(&sa); win_attr_setcodepage(&sa, 1252);
      rc = run(child8, 0, &sa, a, e, &pid); if (!rc) wait_pid(pid);
      ok(!rc && has("FOO=caf\xc3\xa9") && has(" x\xc3\xa9"), "code page 1252: argv and envp as Windows-1252"); }
    /* 6. the command line: as before, and the options of Perl's core */
    { const wchar_t *cmd = L"C:\\windows\\system32\\cmd.exe", *prog = L"C:\\p.exe";
      char *a1[] = { "p", "a b", "q\"x", "", "t\\", NULL };            ok(cl_is(a1, prog, 0, L"p \"a b\" \"q\\\"x\" \"\" t\\"), "default quoting unchanged");
      char *a2[] = { "cmd", "/c", "dir", "x y", NULL };                ok(cl_is(a2, cmd, 0, L"cmd /c \"dir \"x y\"\""), "cmd /c with two words: wrapped, unchanged");
      char *a3[] = { "cmd", "/c", "echo \"a b\" & x", NULL };          ok(cl_is(a3, cmd, 0, L"cmd /c \"echo \\\"a b\\\" & x\""), "cmd /c with one word, default: C runtime quoting");
                                                                       ok(cl_is(a3, cmd, WIN_OPT_CMD_RAW, L"cmd /c \"echo \"a b\" & x\""), "WIN_OPT_CMD_RAW: the word as it is, in quotes");
                                                                       ok(cl_is(a3, prog, WIN_OPT_CMD_RAW, L"cmd /c \"echo \\\"a b\\\" & x\""), "WIN_OPT_CMD_RAW: only for cmd.exe");
      char *a4[] = { "p", "a \"b\" c", NULL };                         ok(cl_is(a4, prog, WIN_OPT_ARGV_RAW, L"p a \"b\" c"), "WIN_OPT_ARGV_RAW: joined as they are");
      char *a5[] = { "p", "\"x y\"", "z w", NULL };                    ok(cl_is(a5, prog, WIN_OPT_KEEP_QUOTED, L"p \"x y\" \"z w\""), "WIN_OPT_KEEP_QUOTED: a quoted word as it is");
                                                                       ok(cl_is(a5, prog, 0, L"p \"\\\"x y\\\"\" \"z w\""), "without it: escaped");
      char *a6[] = { "cmd", "/c", "\"a b\"", "c", NULL };              ok(cl_is(a6, cmd, WIN_OPT_KEEP_QUOTED, L"cmd /c \"\"a b\" c\""), "WIN_OPT_KEEP_QUOTED inside cmd /c's quotes (opening quote first)");
    }
    /* 7. the environment block, and drive-relative names */
    { char *e[] = { "B=1", "a=first", "A=second", "=X:=X:\\", NULL }; wchar_t *b = win_env_block(e, CP_UTF8), *p; int na = 0, first = 0;
      for (p = b; p && *p; p += wcslen(p) + 1) if (!_wcsnicmp(p, L"a=", 2)) { na++; first = !wcscmp(p, L"a=first"); }
      ok(b && na == 1 && first, "env block: a name twice (in any case): the first"); win_free(b); }
    { wchar_t *j = win_join(L"C:\\a\\b", L"C:x"); ok(j && !wcscmp(j, L"C:\\a\\b\\x"), "win_join: C:x relative to a directory on C:"); if (j) printf("#   %s\n", u8(j)); win_free(j); }
    printf("%d ok, %d not ok\n", n_ok, n_fail);
    return n_fail != 0;
}
