#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#ifdef _FILE_OFFSET_BITS
#undef _FILE_OFFSET_BITS
#endif

#include "arch/functions.h"
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/swap.h>
#include <vm/anon.h>

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
		const long long pagetotal = sysconf (_SC_PHYS_PAGES);
		const long long pagesize = sysconf (_SC_PAGESIZE);
		double ret = (pagetotal *pagesize);
		RETVAL = ret;
	OUTPUT:
		RETVAL

double
freemem()
	PROTOTYPE: DISABLE
	CODE:
		const long long pagesize = sysconf (_SC_PAGESIZE);
		const long long pageavail = sysconf (_SC_AVPHYS_PAGES);
		double ret= (pageavail * pagesize);
		RETVAL = ret;
	OUTPUT:
		RETVAL

double
totalswap()
	PROTOTYPE: DISABLE
	CODE:
		struct anoninfo	swapinfo;
		const long long pagesize = sysconf(_SC_PAGESIZE);
		double ret= 0;
		if (swapctl(SC_AINFO, &swapinfo) != -1)
			ret = swapinfo.ani_max * pagesize;
		RETVAL = ret;
	OUTPUT:
		RETVAL

double
freeswap()
	PROTOTYPE: DISABLE
	CODE:
		struct anoninfo	swapinfo;
		const long long pagesize = sysconf(_SC_PAGESIZE);
		double ret= 0;
		if (swapctl(SC_AINFO, &swapinfo) != -1)
			ret = (swapinfo.ani_max  - swapinfo.ani_resv) * pagesize;
		RETVAL = ret;
	OUTPUT:
		RETVAL

# vim:et:ts=2:sts=2:sw=2
