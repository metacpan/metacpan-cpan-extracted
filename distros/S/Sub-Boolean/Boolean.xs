#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
 
MODULE = Sub::Boolean               PACKAGE = Sub::Boolean

void
falsey (...)
CODE:
	XSRETURN_NO;

void
truthy (...)
CODE:
	XSRETURN_YES;

void
undef (...)
CODE:
	XSRETURN_UNDEF;

void
empty (...)
CODE:
	XSRETURN_EMPTY;

SV*
make_false (...)
ALIAS:
	make_true = 1
	make_undef = 2
	make_empty = 3
CODE:
	CV* cv;
	if ( items == 0 ) {
		switch (ix) {
			case 0:
				cv = newXS(NULL, XS_Sub__Boolean_falsey, __FILE__);
				break;
			case 1:
				cv = newXS(NULL, XS_Sub__Boolean_truthy, __FILE__);
				break;
			case 2:
				cv = newXS(NULL, XS_Sub__Boolean_undef, __FILE__);
				break;
			case 3:
				cv = newXS(NULL, XS_Sub__Boolean_empty, __FILE__);
				break;
		}
	}
	else {
		char* name = (char *)SvPVbyte_nolen(ST(0));
		switch (ix) {
			case 0:
				cv = newXS(name, XS_Sub__Boolean_falsey, __FILE__);
				break;
			case 1:
				cv = newXS(name, XS_Sub__Boolean_truthy, __FILE__);
				break;
			case 2:
				cv = newXS(name, XS_Sub__Boolean_undef, __FILE__);
				break;
			case 3:
				cv = newXS(name, XS_Sub__Boolean_empty, __FILE__);
				break;
		}
		XSRETURN_EMPTY;
	}
	RETVAL = newRV((SV*)cv);
OUTPUT:
	RETVAL
