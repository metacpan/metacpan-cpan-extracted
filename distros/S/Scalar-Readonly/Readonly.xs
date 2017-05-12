#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = Scalar::Readonly		PACKAGE = Scalar::Readonly

int
readonly(sv)
    SV *sv
    CODE:
        RETVAL = !!SvREADONLY(sv);
    OUTPUT:
        RETVAL

void
readonly_on(sv)
    SV *sv
    CODE:
        SvREADONLY_on(sv);

void	
readonly_off(sv)
    SV *sv
	CODE:
		SvREADONLY_off(sv);
	
