#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Scalar::String PACKAGE = Scalar::String

PROTOTYPES: DISABLE

bool
sclstr_is_upgraded(SV *value)
PROTOTYPE: $
CODE:
	RETVAL = !!SvUTF8(value);
OUTPUT:
	RETVAL

bool
sclstr_is_downgraded(SV *value)
PROTOTYPE: $
CODE:
	RETVAL = !SvUTF8(value);
OUTPUT:
	RETVAL

void
sclstr_upgrade_inplace(SV *value)
PROTOTYPE: $
CODE:
	sv_utf8_upgrade(value);
	SvUTF8_on(value);

SV *
sclstr_upgraded(SV *value)
PROTOTYPE: $
CODE:
	if(SvUTF8(value)) {
		RETVAL = SvREFCNT_inc(value);
	} else {
		RETVAL = newSVsv(value);
		sv_utf8_upgrade(RETVAL);
		SvUTF8_on(RETVAL);
	}
OUTPUT:
	RETVAL

void
sclstr_downgrade_inplace(SV *value, bool fail_ok = 0)
PROTOTYPE: $;$
CODE:
	sv_utf8_downgrade(value, fail_ok);

SV *
sclstr_downgraded(SV *value, bool fail_ok = 0)
PROTOTYPE: $;$
CODE:
	if(!SvUTF8(value)) {
		RETVAL = SvREFCNT_inc(value);
	} else {
		RETVAL = sv_mortalcopy(value);
		sv_utf8_downgrade(RETVAL, fail_ok);
		SvREFCNT_inc(RETVAL);
	}
OUTPUT:
	RETVAL
