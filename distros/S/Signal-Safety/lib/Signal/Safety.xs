#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int safety_get(pTHX_ SV* sv, MAGIC* magic) {
	sv_setiv(sv, PL_signals & PERL_SIGNALS_UNSAFE_FLAG ? 0 : 1);
	return 0;
}

int safety_set(pTHX_ SV* sv, MAGIC* magic) {
	if (SvIV(sv))
		PL_signals &= ~PERL_SIGNALS_UNSAFE_FLAG;
	else
		PL_signals |= PERL_SIGNALS_UNSAFE_FLAG;
	return 0;
}

const MGVTBL safety_table = { safety_get, safety_set };

MODULE = Signal::Safety				PACKAGE = Signal::Safety

BOOT:
	{
		SV* safety = get_sv("Signal::Safety", GV_ADD | GV_ADDMULTI);
		sv_magicext(safety, NULL, PERL_MAGIC_ext, &safety_table, NULL, 0);
	}
