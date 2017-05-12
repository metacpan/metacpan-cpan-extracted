#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdlib.h>
#include <sys/time.h>
#include <time.h>

I32 round_robin( pTHX_ IV uf_index, SV *scalar ) { 
	MAGIC *magic = mg_find( scalar, PERL_MAGIC_ext );
	SV *arrayref = magic->mg_obj;
	AV *array    = (AV*)SvRV(arrayref);

	SV *next_value = (SV*)av_shift(array);
	av_push( array, next_value );
	sv_setsv( scalar, next_value );
}

I32 next_value( pTHX_ IV uf_index, SV *scalar ) { 
	MAGIC *magic = mg_find( scalar, PERL_MAGIC_ext );
	SV *arrayref = magic->mg_obj;
	AV *array    = (AV*)SvRV(arrayref);

	if ( av_len(array) == -1 ) {
		sv_setsv( scalar, &PL_sv_undef );
	}
	else {
		SV *next_value = (SV*)av_shift(array);
		sv_setsv( scalar, next_value );
	}
}

MODULE = Scalar::Array PACKAGE = Scalar::Array

void
round_robin(SV *scalar)
	CODE:
		struct ufuncs uvar;
		uvar.uf_val   = &round_robin;
		uvar.uf_set   = NULL;
		uvar.uf_index = 0;

		AV *array    = (AV*)SvRV(scalar);
		SV *arrayref = newRV_inc((SV*)array);

		sv_magic( scalar, 0, PERL_MAGIC_uvar, (char*)&uvar, sizeof(uvar) );
		sv_magic( scalar, arrayref, PERL_MAGIC_ext, 0, 0 );
		
void
shrink(SV *scalar)
	CODE:
		struct ufuncs uvar;
		uvar.uf_val   = &next_value;
		uvar.uf_set   = NULL;
		uvar.uf_index = 0;

		AV *array    = (AV*)SvRV(scalar);
		SV *arrayref = newRV_inc((SV*)array);

		sv_magic( scalar, 0, PERL_MAGIC_uvar, (char*)&uvar, sizeof(uvar) );
		sv_magic( scalar, arrayref, PERL_MAGIC_ext, 0, 0 );

SV*
sa_length(SV *scalar)
	CODE:
		MAGIC *magic = mg_find( scalar, PERL_MAGIC_ext );
		SV *arrayref = magic->mg_obj;
		AV *array    = (AV*)SvRV(arrayref);
		RETVAL = newSViv(av_len(array));

	OUTPUT:
		RETVAL
