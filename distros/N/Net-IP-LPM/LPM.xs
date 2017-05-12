#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"
#include "lpm_lib.h"

MODULE = Net::IP::LPM		PACKAGE = Net::IP::LPM

INCLUDE: const-xs.inc



int 
lpm_init()


int 
lpm_add_raw(handle, prefix, prefix_len, value)
	int handle
	SV *prefix
	int prefix_len
	SV *value


SV * 
lpm_lookup_raw(handle, addr)
	int handle
	SV *addr


SV * 
lpm_info(handle)
	int handle


SV * 
lpm_dump(handle)
	int handle


void 
lpm_finish(handle)
	int handle


void 
lpm_destroy(handle)
	int handle


