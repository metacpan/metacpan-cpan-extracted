#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/mman.h>

#define	IVCONST(s, c)	newCONSTSUB(s, #c, newSViv((int)c));

MODULE = Sys::Mlockall  PACKAGE = Sys::Mlockall

BOOT:
{
	HV *stash;

	stash = gv_stashpv("Sys::Mlockall", TRUE);

	/*
	 * Global constants
	 */
	IVCONST(stash, MCL_CURRENT);
	IVCONST(stash, MCL_FUTURE);
}

int
mlockall(int flags)

int
munlockall()

