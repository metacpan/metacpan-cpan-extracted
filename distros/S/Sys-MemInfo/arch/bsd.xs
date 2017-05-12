#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#include "arch/functions.h"
#include <stdio.h>
#include <sys/param.h>
#include <sys/sysctl.h>

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
		unsigned long long ret = 0;
		size_t len = sizeof (ret);
#ifdef NETBSD
		static int mib[2] = { CTL_HW, HW_PHYSMEM64 };
#else
		static int mib[2] = { CTL_HW, HW_PHYSMEM };
#endif

		if (sysctl (mib, 2, &ret, &len, NULL, 0) != -1) {
      			RETVAL = (double) (ret);
    		} else {
			RETVAL = 0;
		}
	OUTPUT:
		RETVAL
		

double
freemem()
	PROTOTYPE: DISABLE
	CODE:
		double ret= 0;
		struct uvmexp uvmexp;
		size_t len = sizeof(uvmexp);
		int mib[2] = { CTL_VM, VM_UVMEXP };

		if (sysctl(mib, 2, &uvmexp, &len, NULL, 0) != -1) {
			ret = uvmexp.free;
 			ret *= uvmexp.pagesize;
		}

		RETVAL = ret;
	OUTPUT:
		RETVAL

double
totalswap()
	PROTOTYPE: DISABLE
	CODE:
		double ret= 0;
		struct uvmexp uvmexp;
		size_t len = sizeof(uvmexp);
		int mib[2] = { CTL_VM, VM_UVMEXP };

		if (sysctl(mib, 2, &uvmexp, &len, NULL, 0) != -1) {
			ret = uvmexp.swpages;
 			ret *= uvmexp.pagesize;
		}

		RETVAL = ret;
	OUTPUT:
		RETVAL

double
freeswap()
	PROTOTYPE: DISABLE
	CODE:
		double ret= 0;
		struct uvmexp uvmexp;
		size_t len = sizeof(uvmexp);
		int mib[2] = { CTL_VM, VM_UVMEXP };

		if (sysctl(mib, 2, &uvmexp, &len, NULL, 0) != -1) {
			ret = (uvmexp.swpages - uvmexp.swpginuse);
			ret *= uvmexp.pagesize;
		}

		RETVAL = ret;
	OUTPUT:
		RETVAL

# vim:et:ts=2:sts=2:sw=2
