#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

MODULE = Syntax::Kamelon		PACKAGE = Syntax::Kamelon		

INCLUDE: const-xs.inc

TYPEMAP: <<HERE
TYPEMAP
Syntax::Kamelon T_PTROBJ
HERE

PROTOTYPES: ENABLE


SV *
new_kam (char * class, ...)
CODE:
       /* Create a hash */
        HV* hash = newHV();

        /* Create a reference to the hash */
        SV* const self = newRV_noinc( (SV *)hash );

        /* bless into the proper package */
        RETVAL = sv_bless( self, gv_stashpv( class, 0 ) );
OUTPUT:
        RETVAL


void
DESTROY(self)
	SV * self;
	CODE:
		free(self);


# Local variables:
# mode: c
# End:
