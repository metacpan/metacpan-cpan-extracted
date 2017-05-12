#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#include "arch/functions.h"
#include <stdio.h>
#include <sys/param.h>
#include <sys/sysctl.h>
#include <vm/vm_param.h>

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
		static int mib[2] = { CTL_HW, HW_PHYSMEM };

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
		unsigned long fmem = 0;
		double ret = 0;
		size_t len = sizeof (fmem);
		static int pagesize = 0;
		
		if (!pagesize) pagesize = getpagesize();

    		if (sysctlbyname("vm.stats.vm.v_free_count", &fmem, &len, NULL, 0) != -1) {
			ret = (double) (fmem);
			ret *= pagesize;
		} 
		RETVAL = ret;
	OUTPUT:
		RETVAL

double
totalswap()
	PROTOTYPE: DISABLE
	CODE:
		unsigned long long ret= 0;
#ifdef FREEBSD5
		struct xswdev xsw;
		int mib[3], n = 0;
                static int pagesize = 0;
		size_t mibsize = sizeof mib / sizeof mib[0], size;

		if (!pagesize) pagesize = getpagesize();

		if (0 == sysctlnametomib("vm.swap_info", mib, &mibsize)) {
			while (1) {
				mib[mibsize] = n++;
				size = sizeof xsw;
				if (-1 == sysctl(mib, mibsize + 1, &xsw, &size, NULL, 0))
					break;
				if (xsw.xsw_version != XSWDEV_VERSION)
					break;
  				ret += (unsigned long long) xsw.xsw_nblks;
			}
		}
                ret *= pagesize;
#else
		struct kvm_swap swapinfo;
		kvm_t *kvmd;
#endif
		RETVAL = (double) ret;
	OUTPUT:
		RETVAL

double
freeswap()
	PROTOTYPE: DISABLE
	CODE:
		unsigned long long ret= 0;
		unsigned long long used = 0;
#ifdef FREEBSD5
		struct xswdev xsw;
		int mib[3], n = 0;
                static int pagesize = 0;
		size_t mibsize = sizeof mib / sizeof mib[0], size;

		if (!pagesize) pagesize = getpagesize();

		if (0 == sysctlnametomib("vm.swap_info", mib, &mibsize)) {
			while (1) {
				mib[mibsize] = n++;
				size = sizeof xsw;
				if (-1 == sysctl(mib, mibsize + 1, &xsw, &size, NULL, 0))
					break;
				if (xsw.xsw_version != XSWDEV_VERSION)
					break;
  				ret += (unsigned long long) xsw.xsw_nblks;
  				used += (unsigned long long) xsw.xsw_used;
			}
		}
                ret = (ret - used) * pagesize;
#else
		struct kvm_swap swapinfo;
		kvm_t *kvmd;
#endif
		RETVAL = (double) ret;
	OUTPUT:
		RETVAL

# vim:et:ts=2:sts=2:sw=2
