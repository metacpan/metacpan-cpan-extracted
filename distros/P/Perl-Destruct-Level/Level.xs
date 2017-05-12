#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Perl::Destruct::Level	PACKAGE = Perl::Destruct::Level	PREFIX = pdl_

PROTOTYPES: DISABLE

void
pdl_set_destruct_level(dl)
    U8 dl
    CODE:
	PL_perl_destruct_level = dl;

U8
pdl_get_destruct_level()
    CODE:
	RETVAL = PL_perl_destruct_level;
    OUTPUT: RETVAL
