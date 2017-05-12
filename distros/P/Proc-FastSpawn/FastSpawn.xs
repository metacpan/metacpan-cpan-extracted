/* GetProcessId is XP and up, which means in all supported versions */
/* but older SDK's might need this */
#define _WIN32_WINNT NTDDI_WINXP

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>

#ifdef WIN32

  /* perl probably did this already */
  #include <windows.h>

#else

  #include <errno.h>
  #include <fcntl.h>
  #include <unistd.h>

  /* openbsd seems to have a buggy vfork (what would you expect), */
  /* while others might implement vfork as fork in older versions, which is fine */
  #if __linux || __FreeBSD__ || __NetBSD__ || __sun
    #define USE_VFORK 1
  #endif

  #if !USE_VFORK
    #if _POSIX_SPAWN >= 200809L
      #define USE_SPAWN 1
      #include <spawn.h>
    #else
      #define vfork() fork()
    #endif
  #endif

#endif

static char *const *
array_to_cvec (SV *sv)
{
  AV *av;
  int n, i;
  char **cvec;

  if (!SvROK (sv) || SvTYPE (SvRV (sv)) != SVt_PVAV)
    croak ("expected a reference to an array of argument/environment strings");

  av = (AV *)SvRV (sv);
  n = av_len (av) + 1;
  cvec = (char **)SvPVX (sv_2mortal (NEWSV (0, sizeof (char *) * (n + 1))));

  for (i = 0; i < n; ++i)
    cvec [i] = SvPVbyte_nolen (*av_fetch (av, i, 1));

  cvec [n] = 0;

  return cvec;
}

MODULE = Proc::FastSpawn		PACKAGE = Proc::FastSpawn

PROTOTYPES: ENABLE

BOOT:
#ifndef WIN32
        cv_undef (get_cv ("Proc::FastSpawn::_quote", 0));
#endif

long
spawn (const char *path, SV *argv, SV *envp = &PL_sv_undef)
	ALIAS:
        spawnp = 1
        INIT:
{
#ifdef WIN32
        if (w32_num_children >= MAXIMUM_WAIT_OBJECTS)
          {
            errno = EAGAIN;
            XSRETURN_UNDEF;
          }

        argv = sv_2mortal (newSVsv (argv));
        PUSHMARK (SP);
        XPUSHs (argv);
        PUTBACK;
        call_pv ("Proc::FastSpawn::_quote", G_VOID | G_DISCARD);
        SPAGAIN;
#endif
}
	CODE:
{
	extern char **environ;
	char *const *cargv =               array_to_cvec (argv);
	char *const *cenvp = SvOK (envp) ? array_to_cvec (envp) : environ;
        intptr_t pid;

        fflush (0);
#ifdef WIN32
        pid = (ix ? _spawnvpe : _spawnve) (_P_NOWAIT, path, cargv, cenvp);

        if (pid == -1)
          XSRETURN_UNDEF;

        /* do it like perl, dadadoop dadadoop */
        w32_child_handles [w32_num_children] = (HANDLE)pid;
        pid = GetProcessId ((HANDLE)pid); /* get the real pid, unfortunately, requires wxp or newer */
        w32_child_pids [w32_num_children] = pid;
        ++w32_num_children;
#elif USE_SPAWN
        {
          pid_t xpid;

          errno = (ix ? posix_spawnp : posix_spawn) (&xpid, path, 0, 0, cargv, cenvp);

          if (errno)
            XSRETURN_UNDEF;

          pid = xpid;
        }
#else
        pid = (ix ? fork : vfork) ();

        if (pid < 0)
          XSRETURN_UNDEF;

        if (pid == 0)
          {
            if (ix)
              {
                environ = (char **)cenvp;
                execvp (path, cargv);
              }
            else
              execve (path, cargv, cenvp);

            _exit (127);
          }
#endif

        RETVAL = pid;
}
	OUTPUT: RETVAL

void
fd_inherit (int fd, int on = 1)
	CODE:
#ifdef WIN32
        SetHandleInformation ((HANDLE)_get_osfhandle (fd), HANDLE_FLAG_INHERIT, on ? HANDLE_FLAG_INHERIT : 0);
#else
        fcntl (fd, F_SETFD, on ? 0 : FD_CLOEXEC);
#endif

