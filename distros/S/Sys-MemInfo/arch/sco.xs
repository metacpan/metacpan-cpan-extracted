#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#include <stdio.h>
#include <unistd.h>
#include <sys/sysi86.h>

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
		const long long pages = sysconf (_SC_USEABLE_MEMORY);
		const long long pagesize = sysconf (_SC_PAGESIZE);
		RETVAL = (pages * pagesize);
	OUTPUT:
		RETVAL

double
freemem()
	PROTOTYPE: DISABLE
	CODE:
		const long pagesize = sysconf (_SC_PAGESIZE);
		long freepages = 0;
		long l1=0;
		long l2=0;
		double ret = 0;
		int kmem;
		if (getksym("mem_freepages", &l1, &l2) != -1) {

			if ((kmem = open("/dev/kmem", O_RDONLY)) != -1 && lseek(kmem, l1, SEEK_SET)  != -1 &&
				read(kmem, &freepages, sizeof(freepages)) == -1) {
				ret = (freepages * pagesize);
			}
			close(kmem);
		}
		RETVAL = ret;
	OUTPUT:
		RETVAL

double
freeswap()
	PROTOTYPE: DISABLE
	CODE:
		double ret = 0;
		RETVAL = ret;
	OUTPUT:
		RETVAL

double
totalswap()
	PROTOTYPE: DISABLE
	CODE:
		double ret = 0;
		RETVAL = ret;
	OUTPUT:
		RETVAL

# vim:et:ts=2:sts=2:sw=2
