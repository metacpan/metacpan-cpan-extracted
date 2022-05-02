#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
/* From handy.h since 5.027006 */
#ifndef strBEGINs
#define strBEGINs(s1,s2) (strncmp(s1,"" s2 "", sizeof(s2)-1) == 0)
#endif
/* From embed.h, but only defined #ifdef PERL_CORE */
#ifndef rsignal_save
#define rsignal_save(a,b,c) Perl_rsignal_save(aTHX_ a,b,c)
#define rsignal_restore(a,b) Perl_rsignal_restore(aTHX_ a,b)
#endif

#include <spawn.h>

extern char **environ;


Pid_t
do_posix_spawn (const char *cmd, char **argv) {
    Pid_t pid;
    posix_spawnattr_t attr;
    short flags = 0;

    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, flags);
    errno = posix_spawnp(&pid, cmd, NULL, &attr, argv, environ);
    posix_spawnattr_destroy(&attr);

    return errno ? 0 : pid;
}


/* borrowed from Perl's doio.c: S_exec_failed */
static void
S_posix_spawn_failed (pTHX_ const char *cmd)
{
    const int e = errno;
    /* PERL_ARGS_ASSERT_EXEC_FAILED */
    assert(cmd);

    if (ckWARN(WARN_EXEC))
        Perl_warner(aTHX_ packWARN(WARN_EXEC), "Can't spawn \"%s\": %s",
                    cmd, Strerror(e));
}


/* borrowed from Perl's doio.c: Perl_do_aexec5 */
Pid_t
do_posix_spawn3 (pTHX_ SV *really, SV **mark, SV **sp)
{
    /* PERL_ARGS_ASSERT_DO_AEXEC5; */
    assert(mark); assert(sp);
    assert(sp >= mark);
    ENTER;
    {
        Pid_t pid = 0;
        const char **argv, **a;
        const char *tmps = NULL;
        Newx(argv, sp - mark + 1, const char*);
        SAVEFREEPV(argv);
        a = argv;

        while (++mark <= sp) {
            if (*mark) {
                char *arg = savepv(SvPV_nolen_const(*mark));
                SAVEFREEPV(arg);
                *a++ = arg;
            } else
                *a++ = "";
        }
        *a = NULL;
        if (really) {
            tmps = savepv(SvPV_nolen_const(really));
            SAVEFREEPV(tmps);
        }
        if ((!really && argv[0] && *argv[0] != '/') ||
            (really && *tmps != '/'))		/* will posix_spawn use PATH? */
            TAINT_ENV();		/* testing IFS here is overkill, probably */
        PERL_FPU_PRE_EXEC
        if (really && *tmps) {
            pid = do_posix_spawn(tmps,EXEC_ARGV_CAST(argv));
            return pid;
        } else if (argv[0]) {
            pid = do_posix_spawn(argv[0],EXEC_ARGV_CAST(argv));
            return pid;
        } else {
            SETERRNO(ENOENT,RMS_FNF);
        }
        PERL_FPU_POST_EXEC
        S_posix_spawn_failed(aTHX_ (really ? tmps : argv[0] ? argv[0] : ""));
    }
    LEAVE;
    return FALSE;
}


Pid_t
do_posix_spawn_shell (const char *path, char *name, char *flags, char *cmd)
{
    Pid_t pid;
    const char *argv[] = { name, flags, cmd, NULL };
    pid = do_posix_spawn(path, (char **)argv);
    return pid;
}


/* borrowed from Perl's doio.c: Perl_do_exec3 */
Pid_t
do_posix_spawn1 (pTHX_ const char *incmd)
{
    Pid_t pid = 0;
    const char **argv, **a;
    char *s;
    char *buf;
    char *cmd;
    /* Make a copy so we can change it */
    const Size_t cmdlen = strlen(incmd) + 1;

    /* PERL_ARGS_ASSERT_DO_EXEC3; */
    assert(incmd);

    ENTER;
    Newx(buf, cmdlen, char);
    SAVEFREEPV(buf);
    cmd = buf;
    memcpy(cmd, incmd, cmdlen);

    while (*cmd && isSPACE(*cmd))
        cmd++;

    /* save an extra exec if possible */

#ifdef CSH
    {
        #define PERL_FLAGS_MAX 10
        char flags[PERL_FLAGS_MAX];
        if (strnEQ(cmd,PL_cshname,PL_cshlen) &&
            strBEGINs(cmd+PL_cshlen," -c")) {
          my_strlcpy(flags, "-c", PERL_FLAGS_MAX);
          s = cmd+PL_cshlen+3;
          if (*s == 'f') {
              s++;
              my_strlcat(flags, "f", PERL_FLAGS_MAX - 2);
          }
          if (*s == ' ')
              s++;
          if (*s++ == '\'') {
              char * const ncmd = s;

              while (*s)
                  s++;
              if (s[-1] == '\n')
                  *--s = '\0';
              if (s[-1] == '\'') {
                  *--s = '\0';
                  PERL_FPU_PRE_EXEC
                  pid = do_posix_spawn_shell(PL_cshname, "csh", flags, ncmd);
                  PERL_FPU_POST_EXEC
                  if (pid) return pid;
                  *s = '\'';
                  S_posix_spawn_failed(aTHX_ PL_cshname);
                  goto leave;
              }
          }
        }
    }
#endif /* CSH */

    /* see if there are shell metacharacters in it */

    if (*cmd == '.' && isSPACE(cmd[1]))
        goto doshell;

    if (strBEGINs(cmd,"exec") && isSPACE(cmd[4]))
        goto doshell;

    s = cmd;
    while (isWORDCHAR(*s))
        s++;	/* catch VAR=val gizmo */
    if (*s == '=')
        goto doshell;

    for (s = cmd; *s; s++) {
        if (*s != ' ' && !isALPHA(*s) &&
            memCHRs("$&*(){}[]'\";\\|?<>~`\n",*s)) {
            if (*s == '\n' && !s[1]) {
                *s = '\0';
                break;
            }
            /* handle the 2>&1 construct at the end */
            if (*s == '>' && s[1] == '&' && s[2] == '1'
                && s > cmd + 1 && s[-1] == '2' && isSPACE(s[-2])
                && (!s[3] || isSPACE(s[3])))
            {
                const char *t = s + 3;

                while (*t && isSPACE(*t))
                    ++t;
                if (!*t && (PerlLIO_dup2(1,2) != -1)) {
                    s[-2] = '\0';
                    break;
                }
            }
          doshell:
            PERL_FPU_PRE_EXEC
            pid = do_posix_spawn_shell(PL_sh_path, "sh", "-c", cmd);
            PERL_FPU_POST_EXEC
            if (pid) return pid;
            S_posix_spawn_failed(aTHX_ PL_sh_path);
            goto leave;
        }
    }

    Newx(argv, (s - cmd) / 2 + 2, const char*);
    SAVEFREEPV(argv);
    cmd = savepvn(cmd, s-cmd);
    SAVEFREEPV(cmd);
    a = argv;
    for (s = cmd; *s;) {
        while (isSPACE(*s))
            s++;
        if (*s)
            *(a++) = s;
        while (*s && !isSPACE(*s))
            s++;
        if (*s)
            *s++ = '\0';
    }
    *a = NULL;
    if (argv[0]) {
        PERL_FPU_PRE_EXEC
        pid = do_posix_spawn(argv[0],EXEC_ARGV_CAST(argv));
        PERL_FPU_POST_EXEC
        if (pid) return pid;
        if (errno == ENOEXEC)		/* for system V NIH syndrome */
            goto doshell;
        S_posix_spawn_failed(aTHX_ argv[0]);
    }
leave:
    LEAVE;
    return FALSE;
}



/* borrowed from Perl's pp_sys.c: pp_exec */
XS(XS_POSIX__RT__Spawn_spawn); /* prototype to pass -Wmissing-prototypes */
XS(XS_POSIX__RT__Spawn_spawn) {
    dVAR; dSP; dMARK; dORIGMARK; dTARGET;
    Pid_t pid;

    if (PL_tainting) {
        TAINT_ENV();
        while (++MARK <= SP) {
            /* stringify for taint check */
            (void)SvPV_nolen_const(*MARK);
            if (PL_tainted)
                break;
        }
        MARK = ORIGMARK;
        TAINT_PROPER("spawn");
    }

    PERL_FLUSHALL_FOR_CHILD;

    /* indirect object syntax */
    if (0 && PL_op->op_flags & OPf_STACKED) {
        SV * const really = *++MARK;
        pid = do_posix_spawn3(aTHX_ really, MARK, SP);
    }
    else if (SP - MARK != 1)
        pid = do_posix_spawn3(aTHX_ NULL, MARK, SP);
    else {
        pid = do_posix_spawn1(aTHX_ SvPV_nolen(sv_mortalcopy(*SP)));
    }

    SP = ORIGMARK;
    XPUSHi(pid);
    PUTBACK;
    return;
}

MODULE = POSIX::RT::Spawn    PACKAGE = POSIX::RT::Spawn

PROTOTYPES: DISABLE

BOOT:
    newXS("POSIX::RT::Spawn::spawn", XS_POSIX__RT__Spawn_spawn, __FILE__);
