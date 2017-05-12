#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = Regexp::Keep		PACKAGE = Regexp::Keep		
PROTOTYPES: ENABLE


void
KEEP()
    PROTOTYPE:
    CODE:
	PL_regstartp[0] = PL_reginput - PL_bostr;
