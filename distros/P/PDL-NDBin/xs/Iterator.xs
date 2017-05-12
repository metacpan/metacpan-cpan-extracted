#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

MODULE = PDL::NDBin::Iterator	PACKAGE = PDL::NDBin::Iterator

SV *
advance( HV *self )
  PREINIT:
	AV  *av_active   = NULL;
	SV  *bin         = NULL,
	    *var         = NULL;
	SV **svp         = NULL,
	   **selection   = NULL,
	   **unflattened = NULL,
	   **want        = NULL;
	IV   nbins       = -1,
	     nvars       = -1;
	IV  *active      = NULL;
	IV   b = -1, v, i;
  CODE:
	RETVAL = &PL_sv_undef;
	if( (svp = hv_fetch(self, "bin", 3, FALSE)) ) bin = *svp;
	else croak( "advance: need bin" );
	if( (svp = hv_fetch(self, "nbins", 5, FALSE)) ) nbins = SvIV( *svp );
	else croak( "advance: need nbins" );
	if( SvIV(bin) >= nbins ) goto done;
	if( (svp = hv_fetch(self, "var", 3, FALSE)) ) var = *svp;
	else croak( "advance: need var" );
	if( (svp = hv_fetch(self, "nvars", 5, FALSE)) ) nvars = SvIV( *svp );
	else croak( "advance: need nvars" );
	if( (svp = hv_fetch(self, "active", 6, FALSE)) ) {
		if( SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV ) {
			av_active = (AV *) SvRV( *svp );
		}
		else croak( "advance: active is of wrong type" );
	}
	else croak( "advance: need active" );
	selection = hv_fetch(self, "selection", 9, FALSE);
	unflattened = hv_fetch(self, "unflattened", 11, FALSE);
	want = hv_fetch(self, "want", 4, FALSE);
	/* copy SVs to native data types */
	b = SvIV( bin );
	v = SvIV( var );
	Newx( active, nvars, IV );
	for( i = 0; i < nvars; i++ ) {
		if( (svp = av_fetch(av_active, (I32) i, FALSE)) ) {
			active[i] = SvIV( *svp );
		}
		else croak( "advance: need state" );
	}
	for( ;; ) {
		/* invalidate cached data */
		if( selection ) {
			SvREFCNT_dec( *selection );
			*selection = newSVsv( &PL_sv_undef );
			selection = NULL;
		}
		if( ++v >= nvars ) {
			v = 0;
			if( ++b >= nbins ) goto done;
			/* invalidate cached data */
			if( want ) {
				SvREFCNT_dec( *want );
				*want = newSVsv( &PL_sv_undef );
				want = NULL;
			}
			if( unflattened ) {
				SvREFCNT_dec( *unflattened );
				*unflattened = newSVsv( &PL_sv_undef );
				unflattened = NULL;
			}
		}
		if( active[v] ) break;
	}
	RETVAL = &PL_sv_yes;
    done:
	/* copy native data types back to SVs */
	if( b >= 0 ) sv_setiv( bin, b );
	if( var ) sv_setiv( var, v );
	if( active ) Safefree( active );
  OUTPUT:
	RETVAL
