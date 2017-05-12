#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#include "arch/functions.h"
#include <sys/param.h>
#include <sys/pstat.h>

void
availkeys()
  PREINIT:
  PPCODE:
                XPUSHs(sv_2mortal(newSVpv(_totalmem, strlen(_totalmem))));
                XPUSHs(sv_2mortal(newSVpv(_freemem, strlen(_freemem))));
                XPUSHs(sv_2mortal(newSVpv(_totalswap, strlen(_totalswap))));
                XPUSHs(sv_2mortal(newSVpv(_freeswap, strlen(_freeswap))));

double
totalmem()
	PROTOTYPE: DISABLE	
	CODE:
    		struct pst_static pst_s;
		double pages = 0;
		double pagesize = 0;
    		if (pstat_getstatic (&pst_s, sizeof (struct pst_static), 1, 0) >= 0)
      		{
			pages = pst_s.physical_memory;
			pagesize = pst_s.page_size;
		}
		RETVAL = (pages * pagesize);
	OUTPUT:
		RETVAL

double
freemem()
	PROTOTYPE: DISABLE
	CODE:
		struct pst_static pst_s;
		struct pst_dynamic pst_d;
		double pages = 0;
		double pagesize = 0;
		if (pstat_getstatic (&pst_s, sizeof (struct pst_static), 1, 0) >=0 && pstat_getdynamic (&pst_d, sizeof (struct pst_dynamic), 1, 0) >=0)
      		{
			pages = pst_d.psd_free;
			pagesize = pst_s.page_size;
		}
		RETVAL = (pages * pagesize);
	OUTPUT:	
		RETVAL

double
totalswap()
  PROTOTYPE: DISABLE
  CODE:
    double ret= 0;
    struct pst_swapinfo pss;
    int i;

    for (i = 0; pstat_getswap(&pss, sizeof(pss), (size_t)1, i); i++) {
      ret += pss.pss_nblksenabled;
    }
    RETVAL = ret * 1024;
  OUTPUT:
    RETVAL

double
freeswap()
  PROTOTYPE: DISABLE
  CODE:
    double ret= 0;
    struct pst_swapinfo pss;
    int i;

    for (i = 0; pstat_getswap(&pss, sizeof(pss), (size_t)1, i); i++) {
      ret += pss.pss_nfpgs;
    }
    RETVAL = ret * 4 * 1024;
  OUTPUT:
    RETVAL

# vim:et:ts=2:sts=2:sw=2
