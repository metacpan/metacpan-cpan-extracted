#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "engine.h"


MODULE = Regexp::Compare		PACKAGE = Regexp::Compare

PROTOTYPES: ENABLE

BOOT:
rc_init();

SV *
_is_less_or_equal(rs1, rs2)
        SV *rs1;
        SV *rs2;
        CODE:
        {
	REGEXP *r1 = 0, *r2 = 0;
	int rv;

	ENTER;

	r1 = rc_regcomp(rs1);
	SAVEDESTRUCTOR(rc_regfree, r1);

	r2 = rc_regcomp(rs2);
	SAVEDESTRUCTOR(rc_regfree, r2);

	rv = rc_compare(r1, r2);

	LEAVE;

	if (rv < 0)
	{
		if (!rc_error)
		{
			rc_error = "???";
		}

		croak("Regexp::Compare: %s", rc_error);
	}

        RETVAL = newSViv(rv);
        }
        OUTPUT:
        RETVAL
