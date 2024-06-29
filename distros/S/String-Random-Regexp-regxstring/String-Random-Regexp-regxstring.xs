// Function name mangling!!!!!!!!!!!
// use this so that function names in object files are as
// specified in the proto

/* don't forget that we are using a C++ compiler and so these
  need to be protected else ... function-name mangling ooouuouuuuoouu :
*/

/*
our $VERSION = '0.02';
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>

/* helper func to check if SV contains undef */
int _SV_contains_undef(SV *ansv){ SvGETMAGIC(ansv); return(!SvOK(ansv)); }

#ifdef __cplusplus
} // extern "C" {
#endif

#include "harness.h"

MODULE = String::Random::Regexp::regxstring		PACKAGE = String::Random::Regexp::regxstring

PROTOTYPES: ENABLE

AV *
generate_random_strings_xs(SV *regx_SV, int N, ... /*optional int debug*/)

    PROTOTYPE: @

    PREINIT:
	STRLEN regxstr_len;
	int debug = 0; // default value for optional parameter, see above
    INIT:
	// TODO: try using croak
	if( _SV_contains_undef(regx_SV) ){ fprintf(stderr, "generate_random_strings_xs() : error, input regexp string can not be undefined.\n"); XSRETURN_UNDEF; }
	if( N < 1 ){ fprintf(stderr, "generate_random_strings_xs() : error, the number of strings to return must be a positive integer (and not %d).\n", N); XSRETURN_UNDEF; }
    CODE:
	if( items > 2 ){
		// we have the optional parameter
		debug = SvIV(ST(2));
	}

	char *regxstr = SvUTF8(regx_SV)
		? SvPVutf8(regx_SV, regxstr_len)
		: SvPVbyte(regx_SV, regxstr_len)
	;
	/* this is in harness.cpp */
	char **results = regxstring_generate_random_strings_from_regex(
		regxstr,
		N,
		debug
	);

        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        for(int i=0;i<N;i++){
            av_push(RETVAL, newSVpvn_flags(results[i], strlen(results[i]), SVf_UTF8));
        }
	// end of program

	OUTPUT:
		RETVAL
