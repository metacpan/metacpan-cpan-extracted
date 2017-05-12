#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#include <sys/sysinfo.h>
#include <sys/table.h>
#include <machine/hal_sysinfo.h>
#include <mach.h>

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
		long totalmem;
		int pos = -1;
		double ret = 0;

		if (getsysinfo(GSI_PHYSMEM, (caddr_t)&totalmem, sizeof(totalmem), &pos, NULL, NULL)>0) {
			ret = totalmem * 1024;
		}
		RETVAL = ret;
	OUTPUT:
		RETVAL

double
freemem()
	PROTOTYPE: DISABLE
	CODE:
		struct vm_statistics vm_stat;
		double ret = 0;

		if (vm_statistics(current_task(), &vm_stat) == 0) {
			ret = vm_stat.free_count * vm_stat.pagesize;
		}

		RETVAL = ret;
	OUTPUT:	
		RETVAL

double
totalswap()
	PROTOTYPE: DISABLE
	CODE:
		int i=0;
		double ret = 0;
		struct tbl_swapinfo swbuf;
		while(table(TBL_SWAPINFO,i,&swbuf,1,sizeof(struct tbl_swapinfo))>0) {
			ret += swbuf.size;
			i++;
		}
		RETVAL = ret;
	OUTPUT:	
		RETVAL

double
freeswap()
	PROTOTYPE: DISABLE
	CODE:
		int i=0;
		double ret = 0;
		struct tbl_swapinfo swbuf;
		while(table(TBL_SWAPINFO,i,&swbuf,1,sizeof(struct tbl_swapinfo))>0) {
			ret  += swbuf.free;
			i++;
		}
		RETVAL = ret;
	OUTPUT:	
		RETVAL

# vim:et:ts=2:sts=2:sw=2
