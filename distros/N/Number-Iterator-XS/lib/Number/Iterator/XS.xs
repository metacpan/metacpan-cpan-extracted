#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <string.h>

MODULE = Number::Iterator::XS  PACKAGE = Number::Iterator::XS
PROTOTYPES: ENABLE
FALLBACK: TRUE 

SV *
new(...)
        CODE:
                HV * hash = newHV();;
                SV * class = newSVsv(ST(0));
		for (int i = 1; i < items; i += 2) {
			char * key = SvPV_nolen(ST(i));
			*hv_store(hash, key, strlen(key), newSVsv(ST(i + 1)), 0);
		}
		if (SvTYPE(class) != SVt_PV) {
			char * name = HvNAME(SvSTASH(SvRV(class)));
			class = newSVpv(name, strlen(name));
		}
        	RETVAL = sv_bless(newRV_noinc((SV*)hash), gv_stashsv(class, 0));
        OUTPUT:
                RETVAL

SV * 
iterate(self, ...)
	SV * self
	OVERLOAD: ++
	CODE:
		HV * hash = (HV*)SvRV(self);
		if (hv_exists(hash, "iterate", 7)) {
			SV * cb = *hv_fetch(hash, "iterate", 7, 0);
			dSP;
                        PUSHMARK(SP);
                        XPUSHs(self);
                        PUTBACK;
                        call_sv(cb, G_SCALAR);
		} else {
			double value = hv_exists(hash, "value", 5) ? SvNV(*hv_fetch(hash, "value", 5, 0)) : 0.;
			double interval = hv_exists(hash, "interval", 8) ? SvNV(*hv_fetch(hash, "interval", 8, 0)) : 1.;
			*hv_store(hash, "value", 5, newSVnv(value + interval), 0);
		}
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL


SV * 
deiterate(self, ...)
	SV * self
	OVERLOAD: --
	CODE:
		HV * hash = (HV*)SvRV(self);
		if (hv_exists(hash, "deiterate", 9)) {
			SV * cb = *hv_fetch(hash, "deiterate", 9, 0);
			dSP;
                        PUSHMARK(SP);
                        XPUSHs(self);
                        PUTBACK;
                        call_sv(cb, G_SCALAR);
		} else {
			double value = hv_exists(hash, "value", 5) ? SvNV(*hv_fetch(hash, "value", 5, 0)) : 0;
			double interval = hv_exists(hash, "interval", 8) ? SvNV(*hv_fetch(hash, "interval", 8, 0)) : 1;
			*hv_store(hash, "value", 5, newSVnv(value - interval), 0);
		}
		RETVAL = newSVsv(self);;
	OUTPUT:
		RETVAL

SV * 
value(self, ...)
	SV * self
	OVERLOAD: \"\"
	CODE:
		HV * hash = (HV*)SvRV(self);
		if (items > 1 && SvTYPE(ST(1)) == SVt_NV) {
			*hv_store(hash, "value", 5, newSVsv(ST(1)), 0);
		}
		RETVAL = hv_exists(hash, "value", 5) ? newSVsv(*hv_fetch(hash, "value", 5, 0)) : newSViv(0);
	OUTPUT:
		RETVAL

SV * 
interval(self, ...)
	SV * self
	CODE:
		HV * hash = (HV*)SvRV(self);
		if (items > 1 && SvTYPE(ST(1)) == SVt_NV) {
			*hv_store(hash, "interval", 8, newSVsv(ST(1)), 0);
		}
		RETVAL = hv_exists(hash, "interval", 8) ? newSVsv(*hv_fetch(hash, "interval", 8, 0)) : newSViv(1);
	OUTPUT:
		RETVAL
