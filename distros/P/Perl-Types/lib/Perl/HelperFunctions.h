#ifndef __CPP__INCLUDED__Perl__HelperFunctions_h
#define __CPP__INCLUDED__Perl__HelperFunctions_h 0.006_000

#include <perltypes_mode.h> // for definitions of __PERL__TYPES or __CPP__TYPES

// [[[ DEBUG DEFINES ]]]
#define PERL_DEBUG 1  // NEED FIX: access actual environmental variable PERL_DEBUG!
#define PERL_DEBUG2 1
#define PERL_DEBUG3 1  // NEED FIX: these debug statements cause memory leaks by increasing the refcounts of data_i, data_i_plus_1, and swap

// [[[ HELPER MACROS ]]]
// DEV NOTE, CORRELATION #rp026: can't figure out how to get GMPInteger.cpp to include HelperFunctions.cpp without redefining errors
#define SvBOKp(input_bv) (SvIOK(input_bv) && ((SvIV(input_bv) == 0) || (SvIV(input_bv) == 1)))  // NEED ADDRESS: is this a good enough semi-fake check for boolean?
#define SvUIOKp(input_uiv) (SvIOK(input_uiv) && (SvIV(input_uiv) >= 0))  // NEED ADDRESS: is this a good enough semi-fake check for nonsigned_integer?
#define SvCOKp(input_cv) (SvPOK(input_cv) && (strlen((char*) SvPV_nolen(input_cv)) == 1))  // NEED ADDRESS: is this a good enough semi-fake check for character?
#define SvAROKp(input_avref) (SvROK(input_avref) && (SvTYPE(SvRV(input_avref)) == SVt_PVAV))  // DEV NOTE: look P5P, I invented macros that should probably be in the P5 core!
#define SvHROKp(input_hvref) (SvROK(input_hvref) && (SvTYPE(SvRV(input_hvref)) == SVt_PVHV))
#define AV_ELEMENT(av,index) PerlTypes_AV_ELEMENT(aTHX_ av, index)
#define SV_REFERENCE_COUNT(sv) (SvREFCNT(sv))
#define class(sv) HvNAME(SvSTASH(SvRV(sv)))  // NEED ADDRESS: does this actually match the functionality of PERLOPS class() which is a wrapper around blessed()?

// MS Windows OS, need not() macro in MSVC
#ifdef _MSC_VER
#  include <iso646.h>
#endif

// [[[ HELPER FUNCTION DECLARATIONS ]]]
int PerlTypes_SvBOKp(SV* input_sv);
int PerlTypes_SvUIOKp(SV* input_sv);
int PerlTypes_SvIOKp(SV* input_sv);
int PerlTypes_SvNOKp(SV* input_sv);
int PerlTypes_SvCOKp(SV* input_sv);
int PerlTypes_SvPOKp(SV* input_sv);
int PerlTypes_SvAROKp(SV* input_avref);
int PerlTypes_SvHROKp(SV* input_hvref);

void PerlTypes_object_property_init(SV* initee); // NEED ANSWER: what in the hades does this property init function even do?  why do we need it???

// [[[ OPERATIONS & DATA TYPES REPORTER ]]]
# ifdef __PERL__TYPES
SV* Perl__HelperFunctions__MODE_ID() { return(newSViv(1)); }  // CPPOPS_PERLTYPES is 1
# elif defined __CPP__TYPES
int Perl__HelperFunctions__MODE_ID() { return 2; }  // CPPOPS_CPPTYPES is 2
# else
Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!
# endif

#endif
