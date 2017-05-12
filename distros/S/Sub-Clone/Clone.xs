#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#include "ppport.h"

STATIC SV * clone_sub (pTHX_ CV *proto) {
	CV *cv = Perl_cv_clone(aTHX_ proto);
	SV *clone = newRV_noinc((SV *)cv);
    AV* const protopadlist = CvPADLIST(proto);
    const AV* const protopad_name = (AV*)*av_fetch(protopadlist, 0, FALSE);
    const AV* const protopad = (AV*)*av_fetch(protopadlist, 1, FALSE);
    SV** const pname = AvARRAY(protopad_name);
    SV** const ppad = AvARRAY(protopad);
    const I32 fname = AvFILLp(protopad_name);
	AV *new_pad = (AV *)*av_fetch(CvPADLIST(cv), 1, 0);
	I32 ix;

	/* alias all the captured vars, they were recaptured by cv_clone */
	for (ix = fname; ix > 0; ix--) {
		SV* const namesv = pname[ix];
		if (namesv && namesv != &PL_sv_undef) { /* lexical */
			if (SvFAKE(namesv)) {   /* lexical from outside? */
				av_store(new_pad, ix, SvREFCNT_inc(ppad[ix]));
			}
		}
	}

	if ( SvOBJECT(proto) )
		sv_bless(clone, SvSTASH(proto));

	return clone;
}

MODULE = Sub::Clone	PACKAGE = Sub::Clone

I32
is_cloned(sv)
	INPUT:
		SV *sv
	PROTOTYPE: $
	PREINIT:
		CV *cv = ( ( SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV ) ? (CV *)SvRV(sv) : NULL );
	CODE:
		if ( !cv ) croak("Not a code reference");
		RETVAL = CvCLONED(cv);
	OUTPUT: RETVAL

SV *
clone_sub(sv)
	INPUT:
		SV *sv
	PROTOTYPE: $
	PREINIT:
		CV *cv = ( ( SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV ) ? (CV *)SvRV(sv) : NULL );
	CODE:
		if ( !cv ) croak("Not a code reference");
		RETVAL = clone_sub(aTHX_ cv);
	OUTPUT: RETVAL

SV *
clone_if_immortal(sv)
	INPUT:
		SV *sv
	PROTOTYPE: $
	PREINIT:
		CV *cv = ( ( SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV ) ? (CV *)SvRV(sv) : NULL );
	CODE:
		if ( !cv ) croak("Not a code reference");
		RETVAL = CvCLONED(cv) ? newRV_inc((SV *)cv) : clone_sub(aTHX_ cv);
	OUTPUT: RETVAL

