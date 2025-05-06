#ifndef __CPP__INCLUDED__Perl__HelperFunctions_cpp
#define __CPP__INCLUDED__Perl__HelperFunctions_cpp 0.006_000

#include <Perl/HelperFunctions.h>  // -> NULL

// <<< HELPER FUNCTION DEFINITIONS >>
int PerlTypes_SvBOKp(SV* input_sv) { return(SvBOKp(input_sv)); }
int PerlTypes_SvUIOKp(SV* input_sv) { return(SvUIOKp(input_sv)); }
int PerlTypes_SvIOKp(SV* input_sv) { return(SvIOKp(input_sv)); }
int PerlTypes_SvNOKp(SV* input_sv) { return(SvNOKp(input_sv)); }
int PerlTypes_SvCOKp(SV* input_sv) { return(SvCOKp(input_sv)); }
int PerlTypes_SvPOKp(SV* input_sv) { return(SvPOKp(input_sv)); }
int PerlTypes_SvAROKp(SV* input_avref) { return(SvAROKp(input_avref)); }
int PerlTypes_SvHROKp(SV* input_hvref) { return(SvHROKp(input_hvref)); }

SV * PerlTypes_AV_ELEMENT(pTHX_ AV * av, SSize_t index) {
	SV ** svp = av_fetch(av,index,0);
	if(svp != NULL)
//		return *svp;  // POTENTIAL ERROR? SEE DEV NOTE CORRELATION #rp501 BELOW
		return(*svp);
	else
        /* DEV NOTE, CORRELATION #rp501 COMPILER REFACTOR: use return() with parentheses to avoid false error message when running `perl t/04_type_scalar.t`...
            [[[ BEGIN 'use Inline' STAGE for 'Perl/HelperFunctions.cpp' ]]]
            No typemap for type return. Skipping return sv_newmortal()
            [[[ END   'use Inline' STAGE for 'Perl/HelperFunctions.cpp' ]]]
        */
//		return sv_newmortal();  // ERROR, SEE DEV NOTE CORRELATION #rp501 ABOVE
		return(sv_newmortal());
}

// NEED ANSWER: what in the hades does this property init function even do?  why do we need it???
// use this to avoid "panic: attempt to copy freed scalar..."
void PerlTypes_object_property_init(SV* initee)
{
	dSP;
	PUSHMARK(SP);
	XPUSHs(initee);
	PUTBACK;
	call_pv("Dumper", G_SCALAR);
//	printf("in HelperFunctions::PerlTypes_object_property_init(), have initee->flags =\n0x%x\n", initee->sv_flags);
}

#endif
