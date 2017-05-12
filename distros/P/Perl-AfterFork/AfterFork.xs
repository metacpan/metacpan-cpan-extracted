#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* glibc is caching getpid(2)'s result. Hence it's not possible to */
/* use syscall(&SYS_fork) or syscall(&SYS_clone) from perl level */
/* and then adjust perl's notion of $$ by simply fetch the result of */
/* glibc's getpid()-function because it yields the parent's pid even */
/* for the child. Hence we are using syscall(SYS_getpid) here if possible */

# ifdef HAS_SYSCALL
#   include <sys/types.h>
#   include <sys/syscall.h>
#   include <unistd.h>
# endif

MODULE = Perl::AfterFork		PACKAGE = Perl::AfterFork

void
reinit_pid()
  PROTOTYPE:
  PPCODE:
    {
      GV *tmpgv;
      if ((tmpgv = gv_fetchpv("$", TRUE, SVt_PV))) {
	SvREADONLY_off(GvSV(tmpgv));
# ifdef HAS_SYSCALL
	sv_setiv(GvSV(tmpgv), (IV)syscall(SYS_getpid));
# else
	sv_setiv(GvSV(tmpgv), (IV)getpid());
# endif
	SvREADONLY_on(GvSV(tmpgv));
	XSRETURN_YES;
      } else {
	XSRETURN_NO;
      }
    }

void
reinit_ppid()
  PROTOTYPE:
  PPCODE:
    {
      PL_ppid = (IV)getppid();
      XSRETURN_YES;
    }

void
reinit_pidstatus()
  PROTOTYPE:
  PPCODE:
    {
      hv_clear(PL_pidstatus);	/* no kids, so don't wait for 'em */
      XSRETURN_YES;
    }

void
reinit()
  PROTOTYPE:
  PPCODE:
    {
      GV *tmpgv;

      PL_ppid = (IV)getppid();
      hv_clear(PL_pidstatus);	/* no kids, so don't wait for 'em */

      if ((tmpgv = gv_fetchpv("$", TRUE, SVt_PV))) {
	SvREADONLY_off(GvSV(tmpgv));
# ifdef HAS_SYSCALL
	sv_setiv(GvSV(tmpgv), (IV)syscall(SYS_getpid));
# else
	sv_setiv(GvSV(tmpgv), (IV)getpid());
# endif
	SvREADONLY_on(GvSV(tmpgv));
	XSRETURN_YES;
      } else {
	XSRETURN_NO;
      }
      XSRETURN_YES;
    }

## Local Variables: ##
## mode: c ##
## End: ##
