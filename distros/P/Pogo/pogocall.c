/* pogocall.c - 1999 Sey */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "pogocall.h"

callresult _pogo_call_sv(void* func, void* argref) {
	SV *	codesv;
	SV *	argvref;
	AV *	av;
	I32		j, ac, outs;
	callresult	result, tmp;
	dSP;
	codesv = (SV*)func;
	argvref = (SV*)argref;
	ENTER;
	PUSHMARK(sp);
	if( argvref ) {
		if( !SvROK(argvref) || SvTYPE(SvRV(argvref)) != SVt_PVAV )
			croak("array reference required");
		av = (AV*)SvRV(argvref);
		ac = av_len(av);
		for( j = 0; j <= ac; j++ ) {
			XPUSHs(*(av_fetch(av,j,0)));
		}
	}
	PUTBACK;
	outs = perl_call_sv(codesv, GIMME);
	SPAGAIN;
	result = (callresult)malloc(sizeof(void*) * (outs + 1));
	tmp = result + outs;
	*tmp = NULL;
	for( j = 0; j < outs; j++ ) {
		SV* tmpv = POPs;
		SvREFCNT_inc(tmpv);
		*(--tmp) = (void*)tmpv;
	}
	PUTBACK;
	LEAVE;
	return result;
}
