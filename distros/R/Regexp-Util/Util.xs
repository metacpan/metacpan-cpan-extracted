#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#define sv_defined(sv) (sv && (SvIOK(sv) || SvNOK(sv) || SvPOK(sv) || SvROK(sv)))

#ifndef SvRXOK

#define SvRXOK(sv) _is_regexp(aTHX_ sv)

STATIC int
_is_regexp (pTHX_ SV* sv) {
	SV* tmpsv;
	
	if (SvMAGICAL(sv))
	{
		mg_get(sv);
	}
	
	if (SvROK(sv)
	&& (tmpsv = (SV*) SvRV(sv))
	&& SvTYPE(tmpsv) == SVt_PVMG 
	&& (mg_find(tmpsv, PERL_MAGIC_qr)))
	{
		return TRUE;
	}
	
	return FALSE;
}

#endif

MODULE = Regexp::Util	PACKAGE = Regexp::Util

INCLUDE: const-xs.inc

bool
is_regexp (ref)
	SV *ref
CODE:
	RETVAL = SvRXOK(ref);
OUTPUT:
	RETVAL

bool
regexp_seen_evals (ref)
	SV *ref
CODE:
	REGEXP *re;
	re = SvRX(ref);
	RETVAL = RX_EXTFLAGS(re) & RXf_EVAL_SEEN;
OUTPUT:
	RETVAL

int
_regexp_engine_id (ref)
	SV *ref
CODE:
	REGEXP *re;
	const regexp_engine *e;
	re = SvRX(ref);
	e  = RX_ENGINE(re);
	RETVAL = (int)e;
OUTPUT:
	RETVAL
