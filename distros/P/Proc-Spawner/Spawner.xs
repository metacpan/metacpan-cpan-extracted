#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <signal.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#ifdef _WIN32
/* Windows (EXPERIMENTAL, post-0.06, not yet built): posix_spawn on CreateProcessW, in win_spawn.h; these names make the
   XSUB below one source for both.  What Windows does natively: doc/pspawn-spawner.md, section 8. */
#  include "win_spawn.h"
#  define posix_spawn_file_actions_t win_file_actions_t
#  define posix_spawnattr_t win_spawnattr_t
#  define posix_spawn win_posix_spawn
#  define posix_spawnp win_posix_spawnp
#  define posix_spawn_file_actions_init win_fa_init
#  define posix_spawn_file_actions_destroy win_fa_destroy
#  define posix_spawn_file_actions_adddup2 win_fa_adddup2
#  define posix_spawn_file_actions_addclose win_fa_addclose
#  define posix_spawn_file_actions_addopen win_fa_addopen
#  define posix_spawn_file_actions_addchdir_np win_fa_addchdir
#  define posix_spawn_file_actions_addfchdir_np win_fa_addfchdir
#  define posix_spawn_file_actions_addclosefrom_np win_fa_addclosefrom
#  define posix_spawnattr_init win_attr_init
#  define posix_spawnattr_destroy win_attr_destroy
#  define posix_spawnattr_setflags win_attr_setflags
#  define posix_spawnattr_setsigmask win_attr_setsigmask
#  define posix_spawnattr_setsigdefault win_attr_setsigdefault
#  define posix_spawnattr_setpgroup win_attr_setpgroup
#  define POSIX_SPAWN_RESETIDS WIN_SPAWN_RESETIDS
#  define POSIX_SPAWN_SETPGROUP WIN_SPAWN_SETPGROUP
#  define POSIX_SPAWN_SETSIGDEF WIN_SPAWN_SETSIGDEF
#  define POSIX_SPAWN_SETSIGMASK WIN_SPAWN_SETSIGMASK
#  define HAVE_ADDCHDIR_NP 1
#  define HAVE_ADDFCHDIR_NP 1
#  define HAVE_ADDCLOSEFROM_NP 1
typedef win_sigset_t ps_sigset_t;
#  define ps_sigemptyset win_sigemptyset
#  define ps_sigaddset win_sigaddset
#else
#  include <spawn.h>
#  include <unistd.h>
#  include <sched.h>
#  include <sys/resource.h>
#  include <sys/syscall.h>
typedef sigset_t ps_sigset_t;
#  define ps_sigemptyset sigemptyset
#  define ps_sigaddset sigaddset
#endif
/* The posix_spawn extensions (glibc's, and some other libcs') are functions, so Makefile.PL finds them by
   compiling a call to each: -DHAVE_ADDCHDIR_NP and so on.  An option this build lacks is dropped or fails
   with ENOTSUP, as the caller's UNSUPPORTED hash or %Proc::Spawner::UNSUPPORTED says. */
#ifdef HAVE_PIDFD_SPAWN
#  include <sys/pidfd.h>
#endif
#ifndef _WIN32
extern char **environ;
#endif

/* A string for the spawn call.  On Windows: UTF-8 for win_spawn.h, from a byte string in the ANSI code page (as Perl's
   own CreateProcessA takes it) unless Perl has it as UTF-8 already; the copy is mortal. */
#ifdef _WIN32
static const char *
spawn_str(pTHX_ SV *sv)
{
    const char *p = SvPV_nolen(sv); char *u; SV *m;
    if (SvUTF8(sv) || !(u = win_acp_to_utf8(p))) return p;
    m = sv_2mortal(newSVpv(u, 0)); win_free(u);
    return SvPVX(m);
}
#  define SPAWN_STR(sv) spawn_str(aTHX_ (sv))
static char **
win_childenv(pTHX)   /* Perl's environment for a child (PerlEnv_get_childenv, as Perl's own spawn: with pseudo-forks it
                        can differ from the process's), as a mortal UTF-8 vector; NULL: the process's own */
{
    char *b = (char *)PerlEnv_get_childenv(), *p, **v; SSize_t n = 0, i = 0;
    if (!b) return NULL;
    for (p = b; *p; p += strlen(p) + 1) n++;
    Newx(v, n + 1, char *); SAVEFREEPV(v);
    for (p = b; *p; p += strlen(p) + 1) {
        char *u = win_acp_to_utf8(p); SV *m = sv_2mortal(newSVpv(u ? u : p, 0)); win_free(u); v[i++] = SvPVX(m);
    }
    v[n] = NULL; PerlEnv_free_childenv(b);
    return v;
}
#else
#  define SPAWN_STR(sv) SvPV_nolen(sv)
#endif

/* A NULL-terminated char* vector from an array ref; freed with the scope. */
static char **
strv(pTHX_ SV *ref, const char *what)
{
    AV *av; SSize_t n, i; char **v;
    if (!SvROK(ref) || SvTYPE(SvRV(ref)) != SVt_PVAV)
        croak("Proc::Spawner::spawn: %s must be an array reference", what);
    av = (AV *)SvRV(ref);
    n = av_count(av);
    Newx(v, n + 1, char *);
    SAVEFREEPV(v);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        v[i] = e ? (char *)SPAWN_STR(*e) : (char *)"";
    }
    v[n] = NULL;
    return v;
}

static int
sigset_from(pTHX_ SV *ref, ps_sigset_t *set)
{
    AV *av; SSize_t i;
    if (!SvROK(ref) || SvTYPE(SvRV(ref)) != SVt_PVAV) croak("Proc::Spawner::spawn: signal list must be an array reference");
    av = (AV *)SvRV(ref);
    ps_sigemptyset(set);
    for (i = 0; i < av_count(av); i++) {
        SV **e = av_fetch(av, i, 0);
        if (e && ps_sigaddset(set, (int)SvIV(*e)) != 0) return errno;
    }
    return 0;
}

/* PROTOTYPE for decision D1, option A (page "Child Exit Wake-up"): a C handler for SIGCHLD
   that only writes one byte to a file descriptor; no Perl code runs inside the signal.
   The fd should be non-blocking, so that a full pipe cannot hang the handler. */
#ifndef _WIN32   /* no SIGCHLD on Windows: Proc::Spawner falls back (chld_to_fd is not defined there) */
static volatile sig_atomic_t chld_fd = -1;
static struct sigaction chld_old;
static int chld_installed = 0;
static void
chld_handler(int sig)
{
    int saved = errno;
    (void)sig;
    if (chld_fd >= 0) { ssize_t r = write(chld_fd, "x", 1); (void)r; }
    errno = saved;
}
#endif

static int
missing(pTHX_ SV *uns, const char *name)   /* 0 if the option is to be dropped, else ENOTSUP */
{
    SV **v = NULL; HV *g;
    if (SvOK(uns)) v = hv_fetch((HV *)SvRV(uns), name, strlen(name), 0);
    if (!v && (g = get_hv("Proc::Spawner::UNSUPPORTED", 0)) && !(v = hv_fetch(g, name, strlen(name), 0)))
        v = hv_fetchs(g, "*", 0);
    return v && SvOK(*v) && strEQ(SvPV_nolen(*v), "drop") ? 0 : ENOTSUP;
}

MODULE = Proc::Spawner		PACKAGE = Proc::Spawner

PROTOTYPES: DISABLE

void
__posix_spawn(file_sv, argv, envp, actions, attr, unsupported = &PL_sv_undef)
    SV *file_sv
    SV *argv
    SV *envp
    SV *actions
    SV *attr
    SV *unsupported
  PREINIT:
    posix_spawn_file_actions_t fa;
    posix_spawnattr_t sa;
    char **av, **ev;
    int rc = 0, search = 0, want_pidfd = 0, pidfd = -1;
    short flags = 0;
    pid_t pid = 0;
    AV *acts;
    SSize_t i;
    HV *at = NULL;
    SV **v;
    ps_sigset_t set;
    const char *file;
  PPCODE:
    ENTER; SAVETMPS;
    file = SPAWN_STR(file_sv);
    av = strv(aTHX_ argv, "argv");
#ifdef _WIN32
    ev = SvOK(envp) ? strv(aTHX_ envp, "envp") : win_childenv(aTHX);   /* NULL: CreateProcessW gives the child ours */
#else
    ev = SvOK(envp) ? strv(aTHX_ envp, "envp") : environ;
#endif
    /* unsupported: { OPTION => 'drop' | 'fail' }, for the options this build lacks (see missing()) */
    if (SvOK(unsupported) && (!SvROK(unsupported) || SvTYPE(SvRV(unsupported)) != SVt_PVHV)) croak("Proc::Spawner::spawn: unsupported must be a hash reference");
    if (!SvROK(actions) || SvTYPE(SvRV(actions)) != SVt_PVAV) croak("Proc::Spawner::spawn: actions must be an array reference");
    acts = (AV *)SvRV(actions);
    if (SvOK(attr)) {
        if (!SvROK(attr) || SvTYPE(SvRV(attr)) != SVt_PVHV) croak("Proc::Spawner::spawn: attr must be a hash reference");
        at = (HV *)SvRV(attr);
    }
    for (i = 0; i < av_count(acts); i++) {   /* check everything that may croak before allocating */
        SV **e = av_fetch(acts, i, 0);
        if (!e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVAV) croak("Proc::Spawner::spawn: action %ld is not an array reference", (long)i);
    }
    if (at) {
        if ((v = hv_fetchs(at, "sigdefault", 0)) && (!SvROK(*v) || SvTYPE(SvRV(*v)) != SVt_PVAV)) croak("Proc::Spawner::spawn: sigdefault must be an array reference");
        if ((v = hv_fetchs(at, "sigmask", 0)) && (!SvROK(*v) || SvTYPE(SvRV(*v)) != SVt_PVAV)) croak("Proc::Spawner::spawn: sigmask must be an array reference");
    }
    posix_spawn_file_actions_init(&fa);
    posix_spawnattr_init(&sa);
#ifdef _WIN32
    {   /* the caller's choices: %Proc::Spawner::WINDOWS (win_spawn.h, WIN_OPT_*) */
        HV *w = get_hv("Proc::Spawner::WINDOWS", 0); SV **o;
        static const struct { const char *k; I32 l; int bit; } opt[] = {
            { "new_group", 9, WIN_OPT_NEW_GROUP }, { "kill_with_parent", 16, WIN_OPT_KILL_WITH_PARENT }, { "new_console", 11, WIN_OPT_NEW_CONSOLE } };
        int k;
        for (k = 0; w && k < 3; k++)
            if ((o = hv_fetch(w, opt[k].k, opt[k].l, 0)))
                win_spawn_options = SvTRUE(*o) ? (win_spawn_options | opt[k].bit) : (win_spawn_options & ~opt[k].bit);
    }
    {   /* Perl's own idea of the directory (PerlEnv_get_childdir, as Perl's spawn; with pseudo-forks it can differ from
           the process's): first, so that the caller's chdir actions start from it */
        char *d = PerlEnv_get_childdir();
        if (d) { char *u = win_acp_to_utf8(d); rc = posix_spawn_file_actions_addchdir_np(&fa, u ? u : d); win_free(u); PerlEnv_free_childdir(d); }
    }
#endif
    for (i = 0; !rc && i < av_count(acts); i++) {
        SV **e = av_fetch(acts, i, 0);
        AV *a; const char *op; SSize_t n;
        if (!e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVAV) croak("Proc::Spawner::spawn: action %ld is not an array reference", (long)i);
        a = (AV *)SvRV(*e); n = av_count(a);
#define ARG(k) (k < n && av_fetch(a, k, 0) ? *av_fetch(a, k, 0) : &PL_sv_undef)
        op = SvPV_nolen(ARG(0));
        if (strEQ(op, "dup2") && n == 3)
            rc = posix_spawn_file_actions_adddup2(&fa, SvIV(ARG(1)), SvIV(ARG(2)));
        else if (strEQ(op, "close") && n == 2)
            rc = posix_spawn_file_actions_addclose(&fa, SvIV(ARG(1)));
        else if (strEQ(op, "open") && (n == 4 || n == 5))
            rc = posix_spawn_file_actions_addopen(&fa, SvIV(ARG(1)), SPAWN_STR(ARG(2)), SvIV(ARG(3)), n == 5 ? SvIV(ARG(4)) : 0666);
        else if (strEQ(op, "chdir") && n == 2)
#ifdef HAVE_ADDCHDIR_NP
            rc = posix_spawn_file_actions_addchdir_np(&fa, SPAWN_STR(ARG(1)));
#else
            rc = missing(aTHX_ unsupported, "chdir");
#endif
        else if (strEQ(op, "fchdir") && n == 2)
#ifdef HAVE_ADDFCHDIR_NP
            rc = posix_spawn_file_actions_addfchdir_np(&fa, SvIV(ARG(1)));
#else
            rc = missing(aTHX_ unsupported, "fchdir");
#endif
        else if (strEQ(op, "closefrom") && n == 2)
#ifdef HAVE_ADDCLOSEFROM_NP
            rc = posix_spawn_file_actions_addclosefrom_np(&fa, SvIV(ARG(1)));
#else
            rc = missing(aTHX_ unsupported, "closefrom");
#endif
        else if (strEQ(op, "tcsetpgrp") && n == 2)
#ifdef HAVE_ADDTCSETPGRP_NP
            rc = posix_spawn_file_actions_addtcsetpgrp_np(&fa, SvIV(ARG(1)));
#else
            rc = missing(aTHX_ unsupported, "tcsetpgrp");
#endif
        else
            rc = EINVAL;   /* unknown action or wrong count: no croak here, things are allocated */
#undef ARG
    }
    if (!rc && at) {
        if ((v = hv_fetchs(at, "search", 0)) && SvTRUE(*v)) search = 1;
        if ((v = hv_fetchs(at, "sigdefault", 0))) {
            if (!(rc = sigset_from(aTHX_ *v, &set)) && !(rc = posix_spawnattr_setsigdefault(&sa, &set)))
                flags |= POSIX_SPAWN_SETSIGDEF;
        }
        if (!rc && (v = hv_fetchs(at, "sigmask", 0))) {
            if (!(rc = sigset_from(aTHX_ *v, &set)) && !(rc = posix_spawnattr_setsigmask(&sa, &set)))
                flags |= POSIX_SPAWN_SETSIGMASK;
        }
        if (!rc && (v = hv_fetchs(at, "pgroup", 0)) && SvOK(*v)) {
            if (!(rc = posix_spawnattr_setpgroup(&sa, (pid_t)SvIV(*v))))
                flags |= POSIX_SPAWN_SETPGROUP;
        }
        if ((v = hv_fetchs(at, "resetids", 0)) && SvTRUE(*v)) flags |= POSIX_SPAWN_RESETIDS;
#ifdef POSIX_SPAWN_SETSID
        if ((v = hv_fetchs(at, "setsid", 0)) && SvTRUE(*v)) flags |= POSIX_SPAWN_SETSID;
#else
        if (!rc && (v = hv_fetchs(at, "setsid", 0)) && SvTRUE(*v)) rc = missing(aTHX_ unsupported, "setsid");
#endif
#ifdef _WIN32
        if (!rc && (v = hv_fetchs(at, "sched", 0)) && SvOK(*v)) rc = missing(aTHX_ unsupported, "sched");
#else
        if (!rc && (v = hv_fetchs(at, "sched", 0)) && SvOK(*v)) {   /* [POLICY, PRIORITY] */
            AV *s = SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVAV ? (AV *)SvRV(*v) : NULL;
            struct sched_param sp;
            if (!s || av_count(s) != 2) rc = EINVAL;
            else {
                sp.sched_priority = (int)SvIV(*av_fetch(s, 1, 0));
                if (!(rc = posix_spawnattr_setschedpolicy(&sa, (int)SvIV(*av_fetch(s, 0, 0))))
                    && !(rc = posix_spawnattr_setschedparam(&sa, &sp)))
                    flags |= POSIX_SPAWN_SETSCHEDULER | POSIX_SPAWN_SETSCHEDPARAM;
            }
        }
#endif
        if (!rc && (v = hv_fetchs(at, "cgroup", 0)) && SvOK(*v)) {   /* an fd of a cgroup v2 directory */
#ifdef HAVE_SETCGROUP_NP
            if (!(rc = posix_spawnattr_setcgroup_np(&sa, (int)SvIV(*v))))
                flags |= POSIX_SPAWN_SETCGROUP;
#else
            rc = missing(aTHX_ unsupported, "cgroup");
#endif
        }
        if (!rc && (v = hv_fetchs(at, "pidfd", 0)) && SvTRUE(*v))
#ifdef HAVE_PIDFD_SPAWN
            want_pidfd = 1;
#else
            rc = missing(aTHX_ unsupported, "pidfd");   /* dropped: only the pid is returned */
#endif
        if (!rc) rc = posix_spawnattr_setflags(&sa, flags);
    }
#ifdef HAVE_PIDFD_SPAWN
    if (!rc && want_pidfd) {   /* glibc 2.39: a pidfd instead of a pid; the pid is asked from it */
        rc = (search ? pidfd_spawnp : pidfd_spawn)(&pidfd, file, &fa, &sa, av, ev);
        if (!rc && (pid = pidfd_getpid(pidfd)) < 0) pid = 0;
    }
    else
#endif
    if (!rc)
        rc = (search ? posix_spawnp : posix_spawn)(&pid, file, &fa, &sa, av, ev);
    posix_spawn_file_actions_destroy(&fa);
    posix_spawnattr_destroy(&sa);
    FREETMPS; LEAVE;
    if (rc) {
        SETERRNO(rc, 0);
        XSRETURN_EMPTY;
    }
    mXPUSHi(pid);
    if (want_pidfd) mXPUSHi(pidfd);

void
__native()
  PPCODE:
    /* The settings this build's posix_spawn does natively (the rest Proc::Spawner emulates, or reports). */
    mXPUSHs(newSVpvs("dup2")); mXPUSHs(newSVpvs("close")); mXPUSHs(newSVpvs("open"));
    mXPUSHs(newSVpvs("sigmask")); mXPUSHs(newSVpvs("sigdefault")); mXPUSHs(newSVpvs("pgroup"));
    mXPUSHs(newSVpvs("resetids")); mXPUSHs(newSVpvs("search"));
#ifndef _WIN32
    mXPUSHs(newSVpvs("sched"));   /* Windows: pgroup only as 0, sigmask only empty (win_spawn.h refuses the rest) */
#endif
#ifdef HAVE_ADDCHDIR_NP
    mXPUSHs(newSVpvs("chdir"));
#endif
#ifdef HAVE_ADDFCHDIR_NP
    mXPUSHs(newSVpvs("fchdir"));
#endif
#ifdef HAVE_ADDCLOSEFROM_NP
    mXPUSHs(newSVpvs("closefrom"));
#endif
#ifdef HAVE_ADDTCSETPGRP_NP
    mXPUSHs(newSVpvs("tcsetpgrp"));
#endif
#ifdef POSIX_SPAWN_SETSID
    mXPUSHs(newSVpvs("setsid"));
#endif
#ifdef HAVE_SETCGROUP_NP
    mXPUSHs(newSVpvs("cgroup"));
#endif
#ifdef HAVE_PIDFD_SPAWN
    mXPUSHs(newSVpvs("pidfd"));
#endif

int
__set_cloexec(fd, on)
    int fd
    int on
  CODE:
    /* Set or clear FD_CLOEXEC; the old setting (1 or 0), or -1 if fd is not open. */
    {
#ifdef _WIN32   /* close-on-exec is a handle that is not inherited */
      intptr_t h = _get_osfhandle(fd); DWORD f;
      if (h == -1 || h == -2 || !GetHandleInformation((HANDLE)h, &f)) RETVAL = -1;
      else { RETVAL = (f & HANDLE_FLAG_INHERIT) ? 0 : 1; SetHandleInformation((HANDLE)h, HANDLE_FLAG_INHERIT, on ? 0 : HANDLE_FLAG_INHERIT); }
#else
      int f = fcntl(fd, F_GETFD);
      if (f < 0) RETVAL = -1;
      else { RETVAL = (f & FD_CLOEXEC) ? 1 : 0; fcntl(fd, F_SETFD, on ? (f | FD_CLOEXEC) : (f & ~FD_CLOEXEC)); }
#endif
    }
  OUTPUT:
    RETVAL

int
__dup_high(fd, min)
    int fd
    int min
  CODE:
    /* A close-on-exec copy of fd numbered min or above (F_DUPFD_CLOEXEC), or -1 with $!. */
#ifdef _WIN32
    PERL_UNUSED_VAR(fd); PERL_UNUSED_VAR(min); errno = ENOSYS; RETVAL = -1;   /* the emulation is for POSIX libcs */
#else
    RETVAL = fcntl(fd, F_DUPFD_CLOEXEC, min);
#endif
  OUTPUT:
    RETVAL

int
__fchdir(fd)
    int fd
  CODE:
#ifdef _WIN32
    PERL_UNUSED_VAR(fd); errno = ENOSYS; RETVAL = 0;
#else
    RETVAL = fchdir(fd) == 0;
#endif
  OUTPUT:
    RETVAL

int
__pidfd_open(pid)
    int pid
  CODE:
    /* A pidfd for a child already started (the emulation of pidfd => 1), or -1 with $! (ENOSYS without it). */
#if defined(SYS_pidfd_open) && !defined(_WIN32)
    RETVAL = (int)syscall(SYS_pidfd_open, (pid_t)pid, 0);
#else
    PERL_UNUSED_VAR(pid); errno = ENOSYS; RETVAL = -1;
#endif
  OUTPUT:
    RETVAL

int
__fd_limit()
  CODE:
    /* One more than the highest fd number this process may have (the soft RLIMIT_NOFILE, at most 65536). */
#ifdef _WIN32
    RETVAL = _getmaxstdio();
#else
    {
      struct rlimit r;
      RETVAL = getrlimit(RLIMIT_NOFILE, &r) == 0 && r.rlim_cur != RLIM_INFINITY && r.rlim_cur < 65536 ? (int)r.rlim_cur : 65536;
    }
#endif
  OUTPUT:
    RETVAL

int
__fd_cloexec(fd)
    int fd
  CODE:
    /* Is fd open, and close-on-exec?  1: close-on-exec, 0: inherited by a child, -1: not open.  Portable
       (fcntl F_GETFD); Perl itself could ask only through a handle, which would close the fd later. */
    {
#ifdef _WIN32
      intptr_t h = _get_osfhandle(fd); DWORD f;
      RETVAL = h == -1 || h == -2 || !GetHandleInformation((HANDLE)h, &f) ? -1 : (f & HANDLE_FLAG_INHERIT) ? 0 : 1;
#else
      int f = fcntl(fd, F_GETFD);
      RETVAL = f < 0 ? -1 : (f & FD_CLOEXEC) ? 1 : 0;
#endif
    }
  OUTPUT:
    RETVAL

int
fpe_at_exec()
  CODE:
    /* What Perl's own exec gives SIGFPE: Perl may ignore SIGFPE for itself at startup and then restores
       the saved startup disposition around exec (perl.h: PERL_FPU_INIT, PERL_FPU_PRE_EXEC).
       1: ignored, 0: default, -1: this Perl does not touch SIGFPE (it reads as any other signal). */
#if !defined(HAS_FPSETMASK) && defined(SIGFPE) && defined(SIG_IGN)
    RETVAL = PL_sigfpe_saved == (Sighandler_t)SIG_IGN ? 1 : 0;
#else
    RETVAL = -1;
#endif
  OUTPUT:
    RETVAL

#ifdef _WIN32

IV
__win_spawn_handle(pid)
    IV pid
  CODE:
    /* The process handle of a child started here (kept until __win_spawn_forget), or 0: for its exit code. */
    RETVAL = PTR2IV(win_spawn_handle((pid_t)pid));
  OUTPUT:
    RETVAL

void
__win_spawn_forget(pid)
    IV pid
  CODE:
    win_spawn_forget((pid_t)pid);

#else

int
chld_to_fd(fd)
    int fd
  CODE:
    /* Install the C handler (SA_RESTART); keep the previous action for chld_restore. 1 or 0 with $!. */
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = chld_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART | SA_NOCLDSTOP;
    chld_fd = fd;
    RETVAL = sigaction(SIGCHLD, &sa, chld_installed ? NULL : &chld_old) == 0;
    if (RETVAL) chld_installed = 1;
  OUTPUT:
    RETVAL

int
chld_restore()
  CODE:
    RETVAL = 1;
    if (chld_installed) { RETVAL = sigaction(SIGCHLD, &chld_old, NULL) == 0; chld_installed = 0; chld_fd = -1; }
  OUTPUT:
    RETVAL

#endif
