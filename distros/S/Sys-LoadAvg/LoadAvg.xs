#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#if defined (__SVR4) && defined (__sun)
#include <sys/loadavg.h>
#else
#include <stdlib.h>
#endif

MODULE = Sys::LoadAvg		PACKAGE = Sys::LoadAvg		

void
loadavg()
  PROTOTYPE:
  PREINIT:
    double loadavg[2];
    int retval; 
    int i;
  PPCODE:
    retval = getloadavg(loadavg, 3);
    EXTEND(SP, 3);
    for (i=0; i<3; i++) {
        if (i < retval) {
            PUSHs(sv_2mortal(newSVnv(loadavg[i])));
        } else {
            PUSHs(sv_2mortal(newSV(0)));
        }
    }

