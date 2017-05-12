#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_my_strlcat
#define NEED_my_strlcpy
#define NEED_sv_2pv_flags
#include "ppport.h"

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
STATIC void
S_posix_spawn_failed (pTHX_ const char *cmd) {
    const int e = errno;
    assert(cmd);
    if (ckWARN(WARN_EXEC))
        Perl_warner(aTHX_ packWARN(WARN_EXEC), "Can't spawn \"%s\": %s",
                    cmd, Strerror(e));
}

void
do_posix_spawn_free (pTHX) {
    dVAR;
    Safefree(PL_Argv);
    PL_Argv = NULL;
    Safefree(PL_Cmd);
    PL_Cmd = NULL;
}

/* borrowed from Perl's doio.c: Perl_do_aexec5 */
Pid_t
do_posix_spawn3 (pTHX_ SV *really, register SV **mark, register SV **sp) {
    dVAR;
    Pid_t pid;

    assert(mark); assert(sp);

    if (sp > mark) {
        const char **a;
        const char *tmps = NULL;
        Newx(PL_Argv, sp - mark + 1, const char*);
        a = PL_Argv;

        while (++mark <= sp) {
            if (*mark)
                *a++ = SvPV_nolen_const(*mark);
            else
                *a++ = "";
        }
        *a = NULL;
        if (really)
            tmps = SvPV_nolen_const(really);
        /* will posix_spawn use PATH? */
        if ((!really && *PL_Argv[0] != '/') || (really && *tmps != '/'))
            /* testing IFS here is overkill, probably */
            TAINT_ENV();
        /* PERL_FPU_PRE_EXEC */
        if (really && *tmps)
            pid = do_posix_spawn(tmps, EXEC_ARGV_CAST(PL_Argv));
        else
            pid = do_posix_spawn(PL_Argv[0], EXEC_ARGV_CAST(PL_Argv));
        /* PERL_FPU_POST_EXEC */
        if (errno)
            S_posix_spawn_failed(aTHX_ (really ? tmps : PL_Argv[0]));
    }
    do_posix_spawn_free(aTHX);
    return pid;
}

Pid_t
do_posix_spawn_shell (const char *path, char *name, char *flags,
    char *cmd)
{
    Pid_t pid;
    const char *argv[] = { name, flags, cmd, NULL };
    pid = do_posix_spawn(path, (char **)argv);
    return pid;
}

/* borrowed from Perl's doio.c: Perl_do_exec3 */
Pid_t
do_posix_spawn1 (pTHX_ const char *incmd) {
    dVAR;
    Pid_t pid;
    register const char **a;
    register char *s;
    char *buf;
    char *cmd;
    /* Make a copy so we can change it */
    const Size_t cmdlen = strlen(incmd) + 1;

    assert(incmd);

    Newx(buf, cmdlen, char);
    cmd = buf;
    memcpy(cmd, incmd, cmdlen);

    while (*cmd && isSPACE(*cmd))
        cmd++;

    /* save an extra exec if possible */

    #ifdef CSH
    {
        #define PERL_FLAGS_MAX 10
        char flags[PERL_FLAGS_MAX];
        if (strnEQ(cmd, PL_cshname, PL_cshlen) &&
            strnEQ(cmd+PL_cshlen, " -c", 3)) {
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
                  /* PERL_FPU_PRE_EXEC */
                  pid = do_posix_spawn_shell(PL_cshname, "csh", flags, ncmd);
                  /* PERL_FPU_POST_EXEC */
                  if (errno) {
                    *s = '\'';
                    S_posix_spawn_failed(aTHX_ PL_cshname);
                    Safefree(buf);
                  }
                  return pid;
              }
          }
        }
    }
    #endif /* CSH */

    /* see if there are shell metacharacters in it */

    if (*cmd == '.' && isSPACE(cmd[1]))
        goto doshell;

    if (strnEQ(cmd, "exec", 4) && isSPACE(cmd[4]))
        goto doshell;

    s = cmd;
    while (isALNUM(*s))
        s++;    /* catch VAR=val gizmo */
    if (*s == '=')
        goto doshell;

    for (s = cmd; *s; s++) {
        if (*s != ' ' && !isALPHA(*s) &&
            strchr("$&*(){}[]'\";\\|?<>~`\n", *s)) {
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
                if (!*t && (PerlLIO_dup2(1, 2) != -1)) {
                    s[-2] = '\0';
                    break;
                }
            }
          doshell:
            /* PERL_FPU_PRE_EXEC */
            pid = do_posix_spawn_shell(PL_sh_path, "sh", "-c", cmd);
            /* PERL_FPU_POST_EXEC */
            if (errno) {
                S_posix_spawn_failed(aTHX_ PL_sh_path);
                Safefree(buf);
            }
            return pid;
        }
    }

    Newx(PL_Argv, (s - cmd) / 2 + 2, const char*);
    PL_Cmd = savepvn(cmd, s-cmd);
    a = PL_Argv;
    for (s = PL_Cmd; *s;) {
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
    if (PL_Argv[0]) {
        /* PERL_FPU_PRE_EXEC */
        pid = do_posix_spawn(PL_Argv[0], EXEC_ARGV_CAST(PL_Argv));
        /* PERL_FPU_POST_EXEC */
         /* for system V NIH syndrome */
        if (errno == ENOEXEC) {
            do_posix_spawn_free(aTHX);
            goto doshell;
        }
        if (errno)
            S_posix_spawn_failed(aTHX_ PL_Argv[0]);
    }
    do_posix_spawn_free(aTHX);
    Safefree(buf);
    return pid;
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
