#include "inspect.h"

SV*
Perl_sv_inspect(pTHX_ SV* sv)
{
	dSP;

	if(sv == NULL){
		return sv_2mortal(newSVpvn("NULL", 4));
	}

	SvGETMAGIC(sv);

	switch(SvTYPE(sv)){
		case SVt_PVHV:
		case SVt_PVAV:
		case SVt_PVCV:
		case SVt_PVIO:
			sv = sv_2mortal(newRV_inc(sv));
		default:
			NOOP;
	}

	PUSHMARK(SP);
	XPUSHs(sv);
	PUTBACK;
	call_pv("Ruby::rb_inspect", G_SCALAR);
	SPAGAIN;
	sv = POPs;
	PUTBACK;

	return sv;
}

/* for debug */
const char*
Perl_sv_inspect_cstr(pTHX_ SV* sv)
{
	sv = sv_inspect(sv);
	return SvPV_nolen(sv);
}
