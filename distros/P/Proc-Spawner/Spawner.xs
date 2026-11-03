#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <spawn.h>
#include <signal.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <sched.h>
/* The posix_spawn extensions (glibc's, and some other libcs') are functions, so Makefile.PL finds them by
   compiling a call to each: -DHAVE_ADDCHDIR_NP and so on.  An option this build lacks is dropped or fails
   with ENOTSUP, as the caller's UNSUPPORTED hash or %Proc::Spawner::UNSUPPORTED says. */
#ifdef HAVE_PIDFD_SPAWN
#  include <sys/pidfd.h>
#endif
extern char **environ;

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
        v[i] = e ? SvPV_nolen(*e) : (char *)"";
    }
    v[n] = NULL;
    return v;
}

static int
sigset_from(pTHX_ SV *ref, sigset_t *set)
{
    AV *av; SSize_t i;
    if (!SvROK(ref) || SvTYPE(SvRV(ref)) != SVt_PVAV) croak("Proc::Spawner::spawn: signal list must be an array reference");
    av = (AV *)SvRV(ref);
    sigemptyset(set);
    for (i = 0; i < av_count(av); i++) {
        SV **e = av_fetch(av, i, 0);
        if (e && sigaddset(set, (int)SvIV(*e)) != 0) return errno;
    }
    return 0;
}

/* PROTOTYPE for decision D1, option A (page "Child Exit Wake-up"): a C handler for SIGCHLD
   that only writes one byte to a file descriptor; no Perl code runs inside the signal.
   The fd should be non-blocking, so that a full pipe cannot hang the handler. */
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
__posix_spawn(file, argv, envp, actions, attr, unsupported = &PL_sv_undef)
    const char *file
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
    sigset_t set;
  PPCODE:
    ENTER; SAVETMPS;
    av = strv(aTHX_ argv, "argv");
    ev = SvOK(envp) ? strv(aTHX_ envp, "envp") : environ;
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
            rc = posix_spawn_file_actions_addopen(&fa, SvIV(ARG(1)), SvPV_nolen(ARG(2)), SvIV(ARG(3)), n == 5 ? SvIV(ARG(4)) : 0666);
        else if (strEQ(op, "chdir") && n == 2)
#ifdef HAVE_ADDCHDIR_NP
            rc = posix_spawn_file_actions_addchdir_np(&fa, SvPV_nolen(ARG(1)));
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
