#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::MemInfo PACKAGE = Sys::MemInfo

#include "arch/functions.h"
#include <stdio.h>
#include <mach/mach_host.h>
#include <mach/host_info.h>

void
availkeys()
	PREINIT:
	PPCODE:
                XPUSHs(sv_2mortal(newSVpv(_totalmem, strlen(_totalmem))));
                XPUSHs(sv_2mortal(newSVpv(_freemem, strlen(_freemem))));

double
totalmem()
	PROTOTYPE: DISABLE
	CODE:
		static int page_size = 0;
		vm_statistics_data_t vm_info;
		mach_msg_type_number_t info_count = HOST_VM_INFO_COUNT;
		unsigned long long ret = 0;

	        if (!page_size) page_size = getpagesize();
		if (KERN_SUCCESS == host_statistics(mach_host_self (), HOST_VM_INFO, (host_info_t)&vm_info, &info_count)) {
			ret= (vm_info.active_count + vm_info.inactive_count +
        	        	vm_info.free_count + vm_info.wire_count) * page_size;
        	}
      		RETVAL = (double) (ret);
	OUTPUT:
		RETVAL
		

double
freemem()
	PROTOTYPE: DISABLE
	CODE:
		static int page_size = 0;
		vm_statistics_data_t vm_info;
		mach_msg_type_number_t info_count = HOST_VM_INFO_COUNT;
		unsigned long long ret = 0;

	        if (!page_size) page_size = getpagesize();
		if (KERN_SUCCESS == host_statistics(mach_host_self (), HOST_VM_INFO, (host_info_t)&vm_info, &info_count)) {
			ret = vm_info.free_count * page_size;
        	}
      		RETVAL = (double) (ret);
	OUTPUT:
		RETVAL

# vim:et:ts=2:sts=2:sw=2
