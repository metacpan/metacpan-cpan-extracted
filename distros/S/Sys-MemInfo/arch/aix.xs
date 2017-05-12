#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#include "arch/functions.h"
#include <stdio.h>
#include <unistd.h>
#include <libperfstat.h>

void
availkeys()
	PREINIT:
	PPCODE:
                XPUSHs(sv_2mortal(newSVpv(_totalmem, strlen(_totalmem))));
                XPUSHs(sv_2mortal(newSVpv(_freemem, strlen(_freemem))));
                XPUSHs(sv_2mortal(newSVpv(_totalswap, strlen(_totalswap))));
                XPUSHs(sv_2mortal(newSVpv(_freeswap, strlen(_freeswap))));

u_longlong_t
totalmem()
	PROTOTYPE: DISABLE
        CODE:
		perfstat_memory_total_t meminfo;
		u_longlong_t totalmem = 0;
		if (perfstat_memory_total (NULL, &meminfo, sizeof(perfstat_memory_total_t), 1)!=-1)
			totalmem = meminfo.real_total * 4;
		RETVAL = totalmem;
        OUTPUT:
		RETVAL


u_longlong_t
freemem()
	PROTOTYPE: DISABLE
	CODE:
		perfstat_memory_total_t meminfo;
		u_longlong_t freemem = 0;
		if (perfstat_memory_total (NULL, &meminfo, sizeof(perfstat_memory_total_t), 1)!=-1)
			freemem = meminfo.real_free * 4;
		RETVAL = freemem;
	OUTPUT:
		RETVAL

double
totalswap()
	PROTOTYPE: DISABLE
	CODE:
		perfstat_memory_total_t meminfo;
		u_longlong_t totalswap = 0;
		if (perfstat_memory_total (NULL, &meminfo, sizeof(perfstat_memory_total_t), 1)!=-1)
			totalswap = meminfo.pgsp_total * 4;
		RETVAL = totalswap;
	OUTPUT:
		RETVAL

double
freeswap()
	PROTOTYPE: DISABLE
	CODE:
		perfstat_memory_total_t meminfo;
		u_longlong_t freeswap = 0;
		if (perfstat_memory_total (NULL, &meminfo, sizeof(perfstat_memory_total_t), 1)!=-1)
			freeswap = meminfo.pgsp_free * 4;
		RETVAL = freeswap;
	OUTPUT:
		RETVAL

# vim:et:ts=2:sts=2:sw=2
