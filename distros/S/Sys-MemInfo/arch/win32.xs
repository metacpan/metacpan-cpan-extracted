#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "embed.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#include "arch/functions.h"
#include <stdio.h>
#include <windows.h>

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
#ifdef OLDWIN
		MEMORYSTATUS stat;
#else
		MEMORYSTATUSEX stat;
		double ret = 0;
#endif
		memset(&stat, 0, sizeof(stat));
#ifdef OLDWIN
		GlobalMemoryStatus (&stat);
		RETVAL = (double ) stat.dwTotalPhys;
#else
		stat.dwLength = sizeof (stat);
		if (GlobalMemoryStatusEx (&stat))
			ret = (double ) stat.ullTotalPhys;		
		RETVAL = ret;
#endif		
	OUTPUT:
		RETVAL

double
freemem()
	PROTOTYPE: DISABLE
	CODE:
#ifdef OLDWIN
		MEMORYSTATUS stat;
#else
		MEMORYSTATUSEX stat;
		double ret = 0;
#endif
		memset(&stat, 0, sizeof(stat));
#ifdef OLDWIN
		GlobalMemoryStatus (&stat);
		RETVAL = (double ) stat.dwAvailPhys;
#else
		stat.dwLength = sizeof (stat);
		GlobalMemoryStatusEx (&stat);
		RETVAL = (double ) stat.ullAvailPhys;
#endif		
	OUTPUT:
		RETVAL

double
totalswap()
	PROTOTYPE: DISABLE
	CODE:
#ifdef OLDWIN
		MEMORYSTATUS stat;
#else
		MEMORYSTATUSEX stat;
		double ret = 0;
#endif		
		memset(&stat, 0, sizeof(stat));
#ifdef OLDWIN
		GlobalMemoryStatus (&stat);
		RETVAL = (double ) stat.dwTotalPageFile;
#else
		stat.dwLength = sizeof (stat);
		if (GlobalMemoryStatusEx (&stat))
			ret = (double ) stat.ullTotalPageFile;
		RETVAL = ret;
#endif		
	OUTPUT:
		RETVAL

double
freeswap()
	PROTOTYPE: DISABLE
	CODE:
#ifdef OLDWIN
		MEMORYSTATUS stat;
#else
		MEMORYSTATUSEX stat;
		double ret = 0;
#endif		
		memset(&stat, 0, sizeof(stat));
#ifdef OLDWIN
		GlobalMemoryStatus (&stat);
		RETVAL = (double ) stat.dwAvailPageFile;
#else
		stat.dwLength = sizeof (stat);
		if (GlobalMemoryStatusEx (&stat))
			ret = (double ) stat.ullAvailPageFile;
		RETVAL = ret;
#endif		
	OUTPUT:
		RETVAL
