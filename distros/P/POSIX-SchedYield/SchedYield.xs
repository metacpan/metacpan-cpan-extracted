#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef SV * POSIX_SchedYield;

MODULE = POSIX::SchedYield		PACKAGE = POSIX::SchedYield		

int
sched_yield()
     CODE:
         RETVAL= ( sched_yield() == 0 ? 1 : 0 );
     OUTPUT:
         RETVAL
