#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#include "arch/functions.h"
#include <stdio.h>
#include <unistd.h>
#include <sys/sysmp.h>
#include <sys/stat.h>
#include <sys/swap.h>


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
		static int pagesize = 0;
		struct rminfo rmi;
		double ret = 0;

		if (!pagesize) pagesize=getpagesize();
		if (sysmp(MP_SAGET, MPSA_RMINFO, &rmi, sizeof(rmi)) != -1) {
			ret = (double) rmi.physmem;
			ret *= pagesize;
                }
		RETVAL = ret;
	OUTPUT:
		RETVAL

double
freemem()
	PROTOTYPE: DISABLE
	CODE:
		static int pagesize = 0;
		struct rminfo rmi;
		double ret = 0;

		if (!pagesize) pagesize=getpagesize();
		if (sysmp(MP_SAGET, MPSA_RMINFO, &rmi, sizeof(rmi)) != -1) {
			ret = (double) rmi.freemem;
			ret *= pagesize;
                }
		RETVAL = ret;
	OUTPUT:	
		RETVAL

double
totalswap()
	PROTOTYPE: DISABLE
	CODE:
		off_t swinfo;
		double ret= 0;

		if (0 == swapctl(SC_GETSWAPTOT, &swinfo)) {
			ret = (double) (swinfo);
			ret *= 512;
		}

		RETVAL = ret;
	OUTPUT:
		RETVAL

double
freeswap()
	PROTOTYPE: DISABLE
	CODE:
		off_t swinfo;
		double ret= 0;

		if (0 == swapctl(SC_GETFREESWAP, &swinfo)) {
			ret = (double) (swinfo);
			ret *= 512;
		}

		RETVAL = ret;
	OUTPUT:
		RETVAL

# vim:et:ts=2:sts=2:sw=2
