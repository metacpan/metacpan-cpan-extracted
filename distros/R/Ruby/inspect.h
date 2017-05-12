#ifndef PERL_INSPECT_H
#define PERL_INSPECT_H

/*
	$Id: inspect.h,v 1.6 2004/04/11 05:04:46 jigoro Exp $
*/

#include "EXTERN.h"
#include "perl.h"

SV* 		Perl_sv_inspect(pTHX_ SV* sv);
const char*	Perl_sv_inspect_cstr(pTHX_ SV* sv);

#define sv_inspect(sv)      Perl_sv_inspect(aTHX_ sv)
#define sv_inspect_cstr(sv) Perl_sv_inspect_cstr(aTHX_ sv)

#endif /* PELR_INSPECT_H */
