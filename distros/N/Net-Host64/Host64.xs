#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

/*
   Easy Host-Net 64

   multi-platfrom 64-bit versions of functions
   to convert between network and host byte orders

   https://github.com/ericherman/libehnet64/
*/
#include "ehnet64.h"

/* C functions */

MODULE = Net::Host64		PACKAGE = Net::Host64

BOOT:
{
    PERL_MATH_INT64_LOAD_OR_CROAK;
}

# XS code

PROTOTYPES: ENABLED

uint64_t
phton64(uint64_t host64)
    CODE:
	uint64_t rv = hton64(host64);
	RETVAL = rv;
    OUTPUT: RETVAL


uint64_t
pntoh64(uint64_t net64)
    CODE:
	uint64_t rv = ntoh64(net64);
	RETVAL = rv;
    OUTPUT: RETVAL
