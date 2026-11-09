#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <signal.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
/* av_count() is perl 5.33.1 and later (X36, RT #182809: perl 5.30.3); the same as perl's own there. */
#ifndef av_count
#  define av_count(av) ((Size_t)(AvFILL(av) + 1))
#endif
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
#  define HAVE_POSIX_SPAWN 1
typedef win_sigset_t ps_sigset_t;
#  define ps_sigemptyset win_sigemptyset
#  define ps_sigaddset win_sigaddset
#else
#  ifdef HAVE_POSIX_SPAWN   /* Makefile.PL: without it, the primitive is __spawn_nowait (fork and exec; decision M2) */
#    include <spawn.h>
#  endif
#  include <sys/types.h>
#  include <sys/time.h>
#  include <sys/wait.h>
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

/* Settings POSIX's posix_spawn has no option for: rlimit, sigignore, nice (the user, 2026-11-06, decision M1).  They are
   set in this process right around the call, in C (nothing is allocated and no Perl code runs in between), and put
   back right after; the child inherits them.  One that could not be put back is unsupported (dropped or failed, as
   UNSUPPORTED says): a lower hard limit, or a higher nice value, without the privilege to undo it; a CPU limit this
   process has used up already (it would get SIGXCPU); ignoring SIGCHLD (this process's other children ending
   meanwhile would be reaped by the kernel, their statuses lost).  Every signal is blocked meanwhile (Linux keeps a
   blocked signal pending even while it is ignored); the child gets the mask from before.  On Windows: unsupported. */
#define AR_MAX 32
#ifndef _WIN32
#  ifdef __linux__
#    include <linux/capability.h>
#  endif
#  ifndef CAP_SYS_NICE
#    define CAP_SYS_NICE 23
#  endif
#  ifndef CAP_SYS_RESOURCE
#    define CAP_SYS_RESOURCE 24
#  endif
typedef struct {
    int on;                                                     /* anything to do */
    int nrl, rl_res[AR_MAX], rl_done; struct rlimit rl_new[AR_MAX], rl_old[AR_MAX];
    int nsig, sig[AR_MAX], sig_done; struct sigaction sig_old[AR_MAX];
    int nice_on, nice_new, nice_old, nice_done;
    sigset_t mask_old; int blocked;
} around_t;

static int
has_cap(int cap)   /* may this process do what needs the capability (CAP_SYS_NICE, CAP_SYS_RESOURCE)? */
{
#  ifdef __linux__
    struct __user_cap_header_struct h; struct __user_cap_data_struct d[2];
    memset(&h, 0, sizeof h); memset(d, 0, sizeof d);
    h.version = _LINUX_CAPABILITY_VERSION_3; h.pid = 0;
    if (syscall(SYS_capget, &h, d) == 0) return (d[cap / 32].effective >> (cap % 32)) & 1;
#  endif
    return geteuid() == 0;
}

static int
cpu_used_up(int res, rlim_t lim)   /* a CPU limit this process has used up already (it would get SIGXCPU meanwhile) */
{
#  ifdef RLIMIT_CPU
    struct rusage u;
    if (res != RLIMIT_CPU || lim == RLIM_INFINITY || getrusage(RUSAGE_SELF, &u) != 0) return 0;
    return lim <= (rlim_t)(u.ru_utime.tv_sec + u.ru_stime.tv_sec) + 1;
#  else
    return 0;
#  endif
}

static rlim_t
rl_value(pTHX_ SV **sv, rlim_t keep)   /* undef: keep ours; 'unlimited' or 'infinity': RLIM_INFINITY */
{
    if (!sv || !SvOK(*sv)) return keep;
    if (looks_like_number(*sv)) return (rlim_t)SvUV(*sv);
    if (strEQ(SvPV_nolen(*sv), "unlimited") || strEQ(SvPV_nolen(*sv), "infinity")) return RLIM_INFINITY;
    croak("Proc::Spawner::spawn: rlimit value '%s' is not a number", SvPV_nolen(*sv));
}

static int
around_parse(pTHX_ HV *at, SV *uns, around_t *ar)   /* 0, or an errno; croaks on malformed input (before anything is allocated) */
{
    SV **v; SSize_t i; int rc;
    memset(ar, 0, sizeof *ar);
    if (!at) return 0;
    if ((v = hv_fetchs(at, "rlimit", 0)) && SvOK(*v)) {   /* [[RESOURCE, SOFT, HARD], ...] */
        AV *l;
        if (!SvROK(*v) || SvTYPE(SvRV(*v)) != SVt_PVAV) croak("Proc::Spawner::spawn: rlimit must be an array reference");
        l = (AV *)SvRV(*v);
        for (i = 0; i < av_count(l); i++) {
            SV **e = av_fetch(l, i, 0); AV *r; struct rlimit o, n; int res;
            if (!e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVAV || av_count((AV *)SvRV(*e)) < 2 || av_count((AV *)SvRV(*e)) > 3)
                croak("Proc::Spawner::spawn: rlimit entry %ld must be [RESOURCE, SOFT, HARD]", (long)i);
            r = (AV *)SvRV(*e); res = (int)SvIV(*av_fetch(r, 0, 0));
            if (getrlimit(res, &o) != 0) return errno;
            n.rlim_cur = rl_value(aTHX_ av_fetch(r, 1, 0), o.rlim_cur);
            n.rlim_max = rl_value(aTHX_ av_fetch(r, 2, 0), o.rlim_max);
            if (n.rlim_cur == o.rlim_cur && n.rlim_max == o.rlim_max) continue;
            if (n.rlim_cur > n.rlim_max) return EINVAL;
            if ((n.rlim_max < o.rlim_max && !has_cap(CAP_SYS_RESOURCE))   /* a lower hard limit: no way back */
                || cpu_used_up(res, n.rlim_cur)) {
                if ((rc = missing(aTHX_ uns, "rlimit"))) return rc;
                continue;
            }
            if (ar->nrl == AR_MAX) return EINVAL;
            ar->rl_res[ar->nrl] = res; ar->rl_new[ar->nrl] = n; ar->rl_old[ar->nrl] = o; ar->nrl++;
        }
    }
    if ((v = hv_fetchs(at, "sigignore", 0)) && SvOK(*v)) {   /* [SIGNUMS] */
        AV *l; SV **d; ps_sigset_t def; int have_def = 0;
        if (!SvROK(*v) || SvTYPE(SvRV(*v)) != SVt_PVAV) croak("Proc::Spawner::spawn: sigignore must be an array reference");
        if ((d = hv_fetchs(at, "sigdefault", 0)) && SvOK(*d)) { if ((rc = sigset_from(aTHX_ *d, &def))) return rc; have_def = 1; }
        l = (AV *)SvRV(*v);
        for (i = 0; i < av_count(l); i++) {
            SV **e = av_fetch(l, i, 0); int s = e ? (int)SvIV(*e) : 0;
            if (s <= 0 || s >= NSIG || s == SIGKILL || s == SIGSTOP || (have_def && sigismember(&def, s) == 1)) return EINVAL;
            if (s == SIGCHLD) { if ((rc = missing(aTHX_ uns, "sigignore"))) return rc; continue; }
            if (ar->nsig == AR_MAX) return EINVAL;
            ar->sig[ar->nsig++] = s;
        }
    }
    if ((v = hv_fetchs(at, "nice", 0)) && SvOK(*v) && SvIV(*v)) {   /* an increment, as nice(1) */
        int inc = (int)SvIV(*v), old, nw;
        errno = 0; old = getpriority(PRIO_PROCESS, 0);
        if (old == -1 && errno) return errno;
        nw = inc > 39 ? 19 : inc < -39 ? -20 : old + inc; if (nw > 19) nw = 19; if (nw < -20) nw = -20;
        if (nw > old) {   /* putting it back lowers it: CAP_SYS_NICE, or RLIMIT_NICE allows it */
            int ok = has_cap(CAP_SYS_NICE);
#  ifdef RLIMIT_NICE
            struct rlimit r;
            if (!ok && getrlimit(RLIMIT_NICE, &r) == 0 && (r.rlim_cur == RLIM_INFINITY || 20 - (long)r.rlim_cur <= old)) ok = 1;
#  endif
            if (!ok) { if ((rc = missing(aTHX_ uns, "nice"))) return rc; nw = old; }
        }
        if (nw != old) { ar->nice_on = 1; ar->nice_new = nw; ar->nice_old = old; }
    }
    ar->on = ar->nrl || ar->nsig || ar->nice_on;
    return 0;
}

static int
around_begin(around_t *ar)   /* 0, or an errno (around_end puts back what was done) */
{
    sigset_t all; int k;
    if (!ar->on) return 0;
    sigfillset(&all);
    if (sigprocmask(SIG_BLOCK, &all, &ar->mask_old) != 0) return errno;
    ar->blocked = 1;
    for (k = 0; k < ar->nsig; k++) {
        struct sigaction ign;
        memset(&ign, 0, sizeof ign); ign.sa_handler = SIG_IGN; sigemptyset(&ign.sa_mask);
        if (sigaction(ar->sig[k], &ign, &ar->sig_old[k]) != 0) return errno;
        ar->sig_done = k + 1;
    }
    if (ar->nice_on) { if (setpriority(PRIO_PROCESS, 0, ar->nice_new) != 0) return errno; ar->nice_done = 1; }
    for (k = 0; k < ar->nrl; k++) { if (setrlimit(ar->rl_res[k], &ar->rl_new[k]) != 0) return errno; ar->rl_done = k + 1; }
    return 0;
}

static void
around_end(pTHX_ around_t *ar)   /* errno is kept */
{
    int e = errno, bad = 0;
    while (ar->rl_done > 0) { int k = --ar->rl_done; if (setrlimit(ar->rl_res[k], &ar->rl_old[k]) != 0) bad = 1; }
    if (ar->nice_done) { if (setpriority(PRIO_PROCESS, 0, ar->nice_old) != 0) bad = 1; ar->nice_done = 0; }
    while (ar->sig_done > 0) { int k = --ar->sig_done; if (sigaction(ar->sig[k], &ar->sig_old[k], NULL) != 0) bad = 1; }
    if (ar->blocked) { sigprocmask(SIG_SETMASK, &ar->mask_old, NULL); ar->blocked = 0; }
    if (bad) warn("Proc::Spawner: a setting changed around the call could not be put back");
    errno = e;
}
#else   /* Windows: none of them */
typedef struct { int on; } around_t;
static int
around_parse(pTHX_ HV *at, SV *uns, around_t *ar)
{
    SV **v; int rc;
    ar->on = 0;
    if (!at) return 0;
    if ((v = hv_fetchs(at, "rlimit", 0)) && SvOK(*v) && (rc = missing(aTHX_ uns, "rlimit"))) return rc;
    if ((v = hv_fetchs(at, "sigignore", 0)) && SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVAV && av_count((AV *)SvRV(*v))
        && (rc = missing(aTHX_ uns, "sigignore"))) return rc;
    if ((v = hv_fetchs(at, "nice", 0)) && SvOK(*v) && SvIV(*v) && (rc = missing(aTHX_ uns, "nice"))) return rc;
    return 0;
}
static int around_begin(around_t *ar) { PERL_UNUSED_ARG(ar); return 0; }
static void around_end(pTHX_ around_t *ar) { PERL_UNUSED_ARG(ar); }
#endif

MODULE = Proc::Spawner		PACKAGE = Proc::Spawner

PROTOTYPES: DISABLE

#ifdef HAVE_POSIX_SPAWN

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
    around_t ar;
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
    rc = around_parse(aTHX_ at, unsupported, &ar);   /* rlimit, sigignore, nice (M1) */
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
    win_spawn_showwindow = w32_use_showwindow ? (int)w32_showwindow : -1;   /* Win32::SetChildShowWindow (post-0.09) */
    {   /* Perl's own idea of the directory (PerlEnv_get_childdir, as Perl's spawn; with pseudo-forks it can differ from
           the process's): first, so that the caller's chdir actions start from it */
        char *d = PerlEnv_get_childdir();
        if (d) { char *u = win_acp_to_utf8(d); if (!rc) rc = posix_spawn_file_actions_addchdir_np(&fa, u ? u : d); win_free(u); PerlEnv_free_childdir(d); }
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
#ifndef _WIN32
        if (!rc && ar.on && !(flags & POSIX_SPAWN_SETSIGMASK)) {   /* every signal is blocked around the call: the child gets the mask from before */
            sigset_t cur;
            sigprocmask(SIG_BLOCK, NULL, &cur);
            if (!(rc = posix_spawnattr_setsigmask(&sa, &cur))) flags |= POSIX_SPAWN_SETSIGMASK;
        }
#endif
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
#ifdef _WIN32
        if (!rc && (v = hv_fetchs(at, "win_priority", 0)) && SvOK(*v)) {   /* W4: a priority class, exact */
            static const struct { const char *n; DWORD f; } pc[] = { { "idle", IDLE_PRIORITY_CLASS },
                { "below_normal", BELOW_NORMAL_PRIORITY_CLASS }, { "normal", NORMAL_PRIORITY_CLASS },
                { "above_normal", ABOVE_NORMAL_PRIORITY_CLASS }, { "high", HIGH_PRIORITY_CLASS }, { "realtime", REALTIME_PRIORITY_CLASS } };
            const char *s = SvPV_nolen(*v); int k;
            for (rc = EINVAL, k = 0; k < 6; k++) if (strEQ(s, pc[k].n)) { sa.priority_class = pc[k].f; rc = 0; }
        }
        if (!rc && (v = hv_fetchs(at, "win_job", 0)) && SvOK(*v)) {   /* W4: limits of a job of the child's own, exact */
            if (!SvROK(*v) || SvTYPE(SvRV(*v)) != SVt_PVHV) rc = EINVAL;
            else {
                HV *j = (HV *)SvRV(*v); HE *e; win_job_limits_t *l = &sa.job;
                hv_iterinit(j);
                while (!rc && (e = hv_iternext(j))) {
                    const char *k = HePV(e, PL_na); SV *x = HeVAL(e);
                    if (!SvOK(x)) continue;
                    if (strEQ(k, "ProcessMemoryLimit")) { l->ProcessMemoryLimit = (SIZE_T)SvNV(x); l->flags |= JOB_OBJECT_LIMIT_PROCESS_MEMORY; }
                    else if (strEQ(k, "JobMemoryLimit")) { l->JobMemoryLimit = (SIZE_T)SvNV(x); l->flags |= JOB_OBJECT_LIMIT_JOB_MEMORY; }
                    else if (strEQ(k, "PerProcessUserTimeLimit")) { l->PerProcessUserTimeLimit = (LONGLONG)SvNV(x); l->flags |= JOB_OBJECT_LIMIT_PROCESS_TIME; }
                    else if (strEQ(k, "PerJobUserTimeLimit")) { l->PerJobUserTimeLimit = (LONGLONG)SvNV(x); l->flags |= JOB_OBJECT_LIMIT_JOB_TIME; }
                    else if (strEQ(k, "ActiveProcessLimit")) { l->ActiveProcessLimit = (DWORD)SvUV(x); l->flags |= JOB_OBJECT_LIMIT_ACTIVE_PROCESS; }
                    else rc = EINVAL;
                }
            }
        }
#endif
        if (!rc) rc = posix_spawnattr_setflags(&sa, flags);
    }
    if (!rc && !(rc = around_begin(&ar))) {   /* nothing is allocated from here to around_end */
#ifdef HAVE_PIDFD_SPAWN
        if (want_pidfd) {   /* glibc 2.39: a pidfd instead of a pid; the pid is asked from it */
            rc = (search ? pidfd_spawnp : pidfd_spawn)(&pidfd, file, &fa, &sa, av, ev);
            if (!rc && (pid = pidfd_getpid(pidfd)) < 0) pid = 0;
        }
        else
#endif
        rc = (search ? posix_spawnp : posix_spawn)(&pid, file, &fa, &sa, av, ev);
    }
    around_end(aTHX_ &ar);
    posix_spawn_file_actions_destroy(&fa);
    posix_spawnattr_destroy(&sa);
    FREETMPS; LEAVE;
    if (rc) {
        SETERRNO(rc, 0);
        XSRETURN_EMPTY;
    }
    mXPUSHi(pid);
    if (want_pidfd) mXPUSHi(pidfd);

#else

void
__posix_spawn(...)
  PPCODE:
    /* no posix_spawn in this libc (Makefile.PL): Proc::Spawner::spawn uses __spawn_nowait */
    PERL_UNUSED_VAR(items);
    SETERRNO(ENOSYS, 0);
    XSRETURN_EMPTY;

#endif

#ifndef _WIN32

void
__spawn_nowait(file_sv, argv, envp, attr = &PL_sv_undef, unsupported = &PL_sv_undef)
    SV *file_sv
    SV *argv
    SV *envp
    SV *attr
    SV *unsupported
  PREINIT:
    char **av, **ev;
    const char *file;
    around_t ar;
    HV *at = NULL;
    int rc, p[2] = { -1, -1 }, e = 0;
    pid_t pid = -1;
    ssize_t got;
  PPCODE:
    /* The primitive without posix_spawn (decision M2), as Run 0.06's spawn_nowait: fork and exec with nothing in
       between but the signal mask put back; the parent has done everything else around the call.  Of the
       attributes only rlimit, sigignore and nice (M1).  The pid, or the empty list with $! (exec's errno too,
       through a close-on-exec pipe). */
    ENTER; SAVETMPS;
    file = SvPV_nolen(file_sv);
    av = strv(aTHX_ argv, "argv");
    ev = SvOK(envp) ? strv(aTHX_ envp, "envp") : environ;
    if (SvOK(unsupported) && (!SvROK(unsupported) || SvTYPE(SvRV(unsupported)) != SVt_PVHV)) croak("Proc::Spawner::spawn: unsupported must be a hash reference");
    if (SvOK(attr)) {
        if (!SvROK(attr) || SvTYPE(SvRV(attr)) != SVt_PVHV) croak("Proc::Spawner::spawn: attr must be a hash reference");
        at = (HV *)SvRV(attr);
    }
    rc = around_parse(aTHX_ at, unsupported, &ar);
    if (!rc && pipe(p) != 0) rc = errno;
    if (!rc) { fcntl(p[0], F_SETFD, FD_CLOEXEC); fcntl(p[1], F_SETFD, FD_CLOEXEC); rc = around_begin(&ar); }
    if (!rc) {
        pid = fork();
        if (pid == 0) {   /* async-signal-safe calls only */
            if (ar.blocked) sigprocmask(SIG_SETMASK, &ar.mask_old, NULL);
            execve(file, av, ev);
            e = errno; got = write(p[1], &e, sizeof e); (void)got;
            _exit(127);
        }
        if (pid < 0) rc = errno;
    }
    around_end(aTHX_ &ar);
    if (p[1] >= 0) close(p[1]);
    if (!rc) {
        do got = read(p[0], &e, sizeof e); while (got < 0 && errno == EINTR);
        if (got == (ssize_t)sizeof e) { int st; while (waitpid(pid, &st, 0) < 0 && errno == EINTR) ; rc = e ? e : EINVAL; }
    }
    if (p[0] >= 0) close(p[0]);
    FREETMPS; LEAVE;
    if (rc) {
        SETERRNO(rc, 0);
        XSRETURN_EMPTY;
    }
    mXPUSHi(pid);

void
__rlimits()
  PPCODE:
    /* The resources this system has, as NAME => NUMBER pairs (rlimit) */
#  define RL(n) mXPUSHs(newSVpvs(#n)); mXPUSHi(RLIMIT_##n);
#  ifdef RLIMIT_CPU
    RL(CPU)
#  endif
#  ifdef RLIMIT_FSIZE
    RL(FSIZE)
#  endif
#  ifdef RLIMIT_DATA
    RL(DATA)
#  endif
#  ifdef RLIMIT_STACK
    RL(STACK)
#  endif
#  ifdef RLIMIT_CORE
    RL(CORE)
#  endif
#  ifdef RLIMIT_RSS
    RL(RSS)
#  endif
#  ifdef RLIMIT_NPROC
    RL(NPROC)
#  endif
#  ifdef RLIMIT_NOFILE
    RL(NOFILE)
#  endif
#  ifdef RLIMIT_MEMLOCK
    RL(MEMLOCK)
#  endif
#  ifdef RLIMIT_AS
    RL(AS)
#  endif
#  ifdef RLIMIT_LOCKS
    RL(LOCKS)
#  endif
#  ifdef RLIMIT_SIGPENDING
    RL(SIGPENDING)
#  endif
#  ifdef RLIMIT_MSGQUEUE
    RL(MSGQUEUE)
#  endif
#  ifdef RLIMIT_NICE
    RL(NICE)
#  endif
#  ifdef RLIMIT_RTPRIO
    RL(RTPRIO)
#  endif
#  ifdef RLIMIT_RTTIME
    RL(RTTIME)
#  endif
#  undef RL

void
__getrlimit(res)
    int res
  PPCODE:
    /* (SOFT, HARD), 'unlimited' for RLIM_INFINITY; the empty list with $! */
    struct rlimit r;
    if (getrlimit(res, &r) != 0) XSRETURN_EMPTY;
    if (r.rlim_cur == RLIM_INFINITY) mXPUSHs(newSVpvs("unlimited")); else mXPUSHu((UV)r.rlim_cur);
    if (r.rlim_max == RLIM_INFINITY) mXPUSHs(newSVpvs("unlimited")); else mXPUSHu((UV)r.rlim_max);

#endif

void
__native()
  PPCODE:
    /* The settings this build's primitive does natively (the rest Proc::Spawner emulates, or reports); "posix_spawn"
       if there is one (else the primitive is __spawn_nowait). */
#ifndef _WIN32
    mXPUSHs(newSVpvs("rlimit")); mXPUSHs(newSVpvs("sigignore")); mXPUSHs(newSVpvs("nice"));   /* around the call, in C (M1) */
#endif
#ifdef HAVE_POSIX_SPAWN
    mXPUSHs(newSVpvs("posix_spawn"));
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
    {   /* no F_DUPFD: dup until the copy is high enough, then close the ones below; not inherited (post-0.08, for
           the emulation around Perl's own spawn, M2) */
        int low[256], n = 0, d = -1, e;
        while ((d = _dup(fd)) >= 0 && d < min && n < 256) low[n++] = d;
        e = errno;
        if (d >= 0 && d < min) { _close(d); d = -1; e = EMFILE; }
        while (n > 0) _close(low[--n]);
        if (d >= 0) { intptr_t h = _get_osfhandle(d); if (h != -1) SetHandleInformation((HANDLE)h, HANDLE_FLAG_INHERIT, 0); }
        else errno = e;
        RETVAL = d;
    }
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

const char *
__win_priority_class()
  CODE:
    /* this process's priority class, by the names win_priority takes (W4: nice is mapped from it) */
    switch (GetPriorityClass(GetCurrentProcess())) {
    case IDLE_PRIORITY_CLASS: RETVAL = "idle"; break;
    case BELOW_NORMAL_PRIORITY_CLASS: RETVAL = "below_normal"; break;
    case ABOVE_NORMAL_PRIORITY_CLASS: RETVAL = "above_normal"; break;
    case HIGH_PRIORITY_CLASS: RETVAL = "high"; break;
    case REALTIME_PRIORITY_CLASS: RETVAL = "realtime"; break;
    default: RETVAL = "normal";
    }
  OUTPUT:
    RETVAL

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
