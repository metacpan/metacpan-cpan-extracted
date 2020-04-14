#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

MODULE = Sys::CpuLoad		PACKAGE = Sys::CpuLoad

void
getloadavg()
    PREINIT:
        double loadavg[3];
        int    nelem;
    PPCODE:
#if defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__) || defined(__APPLE__) || defined(__linux__) || defined(__sun) || defined(__DragonFly__)
        nelem = getloadavg(loadavg, 3);
#else
        nelem = -1;
#endif
        if (nelem != -1) {
          EXTEND(SP, 3);
          PUSHs(sv_2mortal(newSVnv(loadavg[0])));
          PUSHs(sv_2mortal(newSVnv(loadavg[1])));
          PUSHs(sv_2mortal(newSVnv(loadavg[2])));
        }
        else {
          XSRETURN_UNDEF;
        }
