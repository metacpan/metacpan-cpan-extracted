#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = String::CP1251 PACKAGE = String::CP1251

void
lc(source)
	SV * source;
PROTOTYPE: $
CODE:
{
	dXSTARG;
	STRLEN len;
	U8 *d;
	const U8 *end;

	if(!SvPOK(source) || !(len=SvCUR(source))){		// TODO: add unicode check
		// TODO: return something instead data itself?
		XSRETURN(1);
	}

	SvUPGRADE(TARG, SVt_PV);
	d=SvGROW(TARG, len+1);
	Copy(SvPV_nolen(source), d, len, U8);
	d[len]='\0';
	SvCUR_set(TARG, len);
	SvPOK_on(TARG);
	ST(0)=TARG;

	end = d + len;
	for (; d < end; d++){
		if((*d>=65 && *d<=90) || (*d>=192 && *d<=223))	/* Latin letters + 32 Cyrillic from A to YA */
			*d+=32;
		else if(*d==168) *d=184;							/* Cyrillic YO */
	}

	XSRETURN(1);
}

void
uc(source)
	SV * source;
PROTOTYPE: $
CODE:
{
	dXSTARG;
	STRLEN len;
	U8 *d;
	const U8 *end;

	if(!SvPOK(source) || !(len=SvCUR(source))){		// TODO: add unicode check
		// TODO: return something instead data itself?
		XSRETURN(1);
	}

	SvUPGRADE(TARG, SVt_PV);
	d=SvGROW(TARG, len+1);
	Copy(SvPV_nolen(source), d, len, U8);
	d[len]='\0';
	SvCUR_set(TARG, len);
	SvPOK_on(TARG);
	ST(0)=TARG;

	end = d + len;
	for (; d < end; d++){
		if((*d>=97 && *d<=122) || (*d>=224 /*&& *d<=255*/))	/* Latin letters + 32 Cyrillic from a to ya, last comparsion is always true for U8 */
			*d-=32;
		else if(*d==184) *d=168;							/* Cyrillic yo */
	}

	XSRETURN(1);
}