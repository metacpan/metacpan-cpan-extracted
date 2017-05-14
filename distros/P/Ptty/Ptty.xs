#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "config.h"
#include "os_stuff.h"

/* Copyright (c) 1993
 *      Juergen Weigert (jnweiger@immd4.informatik.uni-erlangen.de)
 *      Michael Schroeder (mlschroe@immd4.informatik.uni-erlangen.de)
 * Copyright (c) 1987 Oliver Laumann
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program (see the file COPYING); if not, write to the
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 ****************************************************************
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>

#if !defined(sun) 
#include <sys/ioctl.h>
#endif

#if defined(sun) && defined(LOCKPTY) && !defined(TIOCEXCL)
#include <sys/ttold.h>
#endif

#ifdef ISC
# include <sys/tty.h>
# include <sys/sioctl.h>
# include <sys/pty.h>
#endif

#ifdef sgi
# include <sys/sysmacros.h>
#endif /* sgi */

#ifdef SVR4
# include <sys/stropts.h>
#endif

/*
 * if no PTYRANGE[01] is in the config file, we pick a default
 */
#ifndef PTYRANGE0
# define PTYRANGE0 "pqr"
#endif
#ifndef PTYRANGE1
# define PTYRANGE1 "0123456789abcdef"
#endif

static Uid_t eff_uid;

/* used for opening a new pty-pair: */
static char PtyName[32], TtyName[32];

#if !(defined(sequent) || defined(_SEQUENT_) || defined(SVR4))
# ifdef hpux
static char PtyProto[] = "/dev/ptym/ptyXY";
static char TtyProto[] = "/dev/pty/ttyXY";
# else
static char PtyProto[] = "/dev/ptyXY";
static char TtyProto[] = "/dev/ttyXY";
# endif /* hpux */
#endif

static void initpty _((int));

/***************************************************************/

static void
initpty(f)
int f;
{
#ifdef POSIX
  tcflush(f, TCIOFLUSH);
#else
# ifdef TIOCFLUSH
  (void) ioctl(f, TIOCFLUSH, (char *) 0);
# endif
#endif
#ifdef LOCKPTY
  (void) ioctl(f, TIOCEXCL, (char *) 0);
#endif
}

/*
 *    Signal handling
 */

#ifdef POSIX
sigret_t (*xsignal(sig, func)) _(SIGPROTOARG)
int sig;
sigret_t (*func) _(SIGPROTOARG);
{
  struct sigaction osa, sa;
  sa.sa_handler = func;
  (void)sigemptyset(&sa.sa_mask);
  sa.sa_flags = 0;
  if (sigaction(sig, &sa, &osa))
    return (sigret_t (*)_(SIGPROTOARG))-1;
  return osa.sa_handler;
}

#else
# ifdef hpux
/*
 * hpux has berkeley signal semantics if we use sigvector,
 * but not, if we use signal, so we define our own signal() routine.
 */
void (*xsignal(sig, func)) _(SIGPROTOARG)
int sig;
void (*func) _(SIGPROTOARG);
{
  struct sigvec osv, sv;

  sv.sv_handler = func;
  sv.sv_mask = sigmask(sig);
  sv.sv_flags = SV_BSDSIG;
  if (sigvector(sig, &sv, &osv) < 0)
    return (void (*)_(SIGPROTOARG))(BADSIG);
  return (osv.sv_handler);
}
# endif	/* hpux */
#endif	/* POSIX */

/***************************************************************/

#if defined(OSX) && !defined(PTY_DONE)
#define PTY_DONE
int
OpenPTY(ttyn)
SV *ttyn;
{
  register int f;
  if ((f = open_controlling_pty(TtyName)) < 0)
    return -1;
  initpty(f);
  sv_setpv(ttyn,TtyName);
  return f;
#endif

/***************************************************************/

#if (defined(sequent) || defined(_SEQUENT_)) && !defined(PTY_DONE)
#define PTY_DONE
int
OpenPTY(ttyn)
SV *ttyn;
{
  char *m, *s;
  register int f;

  if ((f = getpseudotty(&s, &m)) < 0)
    return -1;
#ifdef _SEQUENT_
  fvhangup(s);
#endif
  strncpy(PtyName, m, sizeof(PtyName));
  strncpy(TtyName, s, sizeof(TtyName));
  initpty(f);
  sv_setpv(ttyn,TtyName);
  return f;
}
#endif

/***************************************************************/

#if defined(__sgi) && !defined(PTY_DONE)
#define PTY_DONE
int
OpenPTY(ttyn)
SV *ttyn;
{
  int f;
  char *name; 
  sigret_t (*sigcld)_(SIGPROTOARG);

  /*
   * SIGCHLD set to SIG_DFL for _getpty() because it may fork() and
   * exec() /usr/adm/mkpts
   */
  sigcld = signal(SIGCHLD, SIG_DFL);
  name = _getpty(&f, O_RDWR | O_NONBLOCK, 0600, 0);
  signal(SIGCHLD, sigcld);

  if (name == 0)
    return -1;
  initpty(f);
  sv_setpv(ttyn,name);
  return f;
}
#endif

/***************************************************************/

#if defined(MIPS) && defined(HAVE_DEV_PTC) && !defined(PTY_DONE)
#define PTY_DONE
int
OpenPTY(ttyn)
SV *ttyn;
{
  register int f;
  struct stat buf;
   
  strcpy(PtyName, "/dev/ptc");
  if ((f = open(PtyName, O_RDWR | O_NONBLOCK)) < 0)
    return -1;
  if (fstat(f, &buf) < 0)
    {
      close(f);
      return -1;
    }
  sprintf(TtyName, "/dev/ttyq%d", minor(buf.st_rdev));
  initpty(f);
  sv_setpv(ttyn,TtyName);
  return f;
}
#endif

/***************************************************************/

#if defined(SVR4) && !defined(PTY_DONE)
#define PTY_DONE
int
OpenPTY(ttyn)
SV *ttyn;
{
  register int f;
  char *m, *ptsname();
  int unlockpt _((int)), grantpt _((int));
  sigret_t (*sigcld)_(SIGPROTOARG);

  if ((f = open("/dev/ptmx", O_RDWR)) == -1)
    return -1;

  /*
   * SIGCHLD set to SIG_DFL for grantpt() because it fork()s and
   * exec()s pt_chmod
   */
  sigcld = signal(SIGCHLD, SIG_DFL);
  if ((m = ptsname(f)) == NULL || grantpt(f) || unlockpt(f))
    {
      signal(SIGCHLD, sigcld);
      close(f);
      return -1;
    } 
  signal(SIGCHLD, sigcld);
  strncpy(TtyName, m, sizeof(TtyName));
  initpty(f);
  sv_setpv(ttyn,TtyName);
  return f;
}
#endif

/***************************************************************/

#if defined(_AIX) && defined(HAVE_DEV_PTC) && !defined(PTY_DONE)
#define PTY_DONE

#ifdef _IBMR2
int aixhack = -1;
#endif

int
OpenPTY(ttyn)
SV *ttyn;
{
  register int f;

  /* a dumb looking loop replaced by mycrofts code: */
  strcpy (PtyName, "/dev/ptc");
  if ((f = open (PtyName, O_RDWR)) < 0)
    return -1;
  strncpy(TtyName, ttyname(f), sizeof(TtyName));
  if (eff_uid && access(TtyName, R_OK | W_OK))
    {
      close(f);
      return -1;
    }
  initpty(f);
# ifdef _IBMR2
  if (aixhack >= 0)
    close(aixhack);
  if ((aixhack = open(TtyName, O_RDWR | O_NOCTTY)) < 0)
    {
      close(f);
      return -1;
    }
# endif
  sv_setpv(ttyn,TtyName);
  return f;
}
#endif

/***************************************************************/

#ifndef PTY_DONE
int
OpenPTY(ttyn)
SV *ttyn;
{
  register char *p, *q, *l, *d;
  register int f;

  strcpy(PtyName, PtyProto);
  strcpy(TtyName, TtyProto);
  for (p = PtyName; *p != 'X'; p++)
    ;
  for (q = TtyName; *q != 'X'; q++)
    ;
  for (l = PTYRANGE0; (*p = *l) != '\0'; l++)
    {
      for (d = PTYRANGE1; (p[1] = *d) != '\0'; d++)
	{
	  if ((f = open(PtyName, O_RDWR)) == -1)
	    continue;
	  q[0] = *l;
	  q[1] = *d;
	  if (eff_uid && access(TtyName, R_OK | W_OK))
	    {
	      close(f);
	      continue;
	    }
#if defined(sun) && defined(TIOCGPGRP) && !defined(SUNOS3)
	  /* Hack to ensure that the slave side of the pty is
	   * unused. May not work in anything other than SunOS4.1
	   */
	    {
	      int pgrp;

	      /* tcgetpgrp does not work (uses TIOCGETPGRP)! */
	      if (ioctl(f, TIOCGPGRP, (char *)&pgrp) != -1 || errno != EIO)
		{
		  close(f);
		  continue;
		}
	    }
#endif
	  initpty(f);
	  sv_setpv(ttyn,TtyName);
	  return f;
	}
    }
  return -1;
}
#endif

int
InitSlave(f,ttyn)
FILE *f;
char *ttyn;
{
 int fd = fileno(f);
#if defined(SVR4) && !defined(sgi)
 if (ioctl(fd, I_PUSH, "ptem"))
  croak("Cannot I_PUSH ptem %s %s", ttyn, strerror(errno));
 if (ioctl(fd, I_PUSH, "ldterm"))
  croak("Cannot I_PUSH ldterm %s %s", ttyn, strerror(errno));
 if (ioctl(fd, I_PUSH, "ttcompat"))
  croak("Cannot I_PUSH ttcompat %s %s", ttyn, strerror(errno));
#endif
 return 1;
}
                            

MODULE = Ptty	PACKAGE = Ptty

int
InitSlave(f,ttyn)
FILE *	f
char *	ttyn

int
OpenPTY(ttyn)
SV *	ttyn

BOOT:
 {
  eff_uid = geteuid();
 }
