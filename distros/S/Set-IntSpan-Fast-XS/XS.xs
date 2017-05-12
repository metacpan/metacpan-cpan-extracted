/* XS.xs */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>

static IV
_av_fetch_iv( AV * ar, I32 pos ) {
  SV **valp = av_fetch( ar, pos, 0 );
  if ( NULL == valp ) {
    Perl_croak( aTHX_ "PANIC: undef in array" );
  }
  return SvIV( *valp );
}

static void
_av_store_iv( AV * ar, I32 pos, IV val ) {
  av_store( ar, pos, newSViv( val ) );
}

static void
_av_push_iv( AV * ar, IV val ) {
  av_push( ar, newSViv( val ) );
}

static IV
__find_pos( AV * self, IV val, IV low ) {
  IV high = ( IV ) av_len( self ) + 1;

  while ( low < high ) {
    IV mid = ( low + high ) / 2;
    IV mid_val = _av_fetch_iv( self, mid );
    if ( val < mid_val ) {
      high = mid;
    }
    else if ( val > mid_val ) {
      low = mid + 1;
    }
    else {
      return mid;
    }
  }
  return low;
}

static AV *
__merge( AV * self, AV * s1, AV * s2 ) {
  I32 l1 = av_len( s1 ) + 1;
  I32 l2 = av_len( s2 ) + 1;

  IV lo, hi, last;
  I32 p1 = 0, p2 = 0, po = 0;
  AV *out = newAV(  );

  while ( p1 < l1 || p2 < l2 ) {
    if ( p1 < l1 && p2 < l2 ) {
      IV lo1 = _av_fetch_iv( s1, p1 );
      IV lo2 = _av_fetch_iv( s2, p2 );
      if ( lo1 < lo2 ) {
        lo = lo1;
        hi = _av_fetch_iv( s1, p1 + 1 );
        p1 += 2;
      }
      else {
        lo = lo2;
        hi = _av_fetch_iv( s2, p2 + 1 );
        p2 += 2;
      }
    }
    else if ( p1 < l1 ) {
      lo = _av_fetch_iv( s1, p1 );
      hi = _av_fetch_iv( s1, p1 + 1 );
      p1 += 2;
    }
    else {
      lo = _av_fetch_iv( s2, p2 );
      hi = _av_fetch_iv( s2, p2 + 1 );
      p2 += 2;
    }

    if ( po ) {
      last = _av_fetch_iv( out, po - 1 );
      if ( lo <= last ) {
        _av_store_iv( out, po - 1, last > hi ? last : hi );
        continue;
      }
    }

    _av_push_iv( out, lo );
    _av_push_iv( out, hi );
    po += 2;
  }

  return out;
}

/* *INDENT-OFF* */

MODULE = Set::IntSpan::Fast::XS PACKAGE = Set::IntSpan::Fast::XS
PROTOTYPES: ENABLE

int
_find_pos(self, val, low = 0)
AV *self;
IV val = SvIV(ST(1));
IV low = ( items == 3 ) ? SvIV( ST( 2 ) ) : 0;
PPCODE:
{
    XSRETURN_IV( __find_pos(self, val, low ) );
}

AV * 
_merge(self, s1, s2)
AV *self;
AV *s1;
AV *s2;
CODE:
    RETVAL = __merge(self, s1, s2);
    sv_2mortal((SV*) RETVAL);
OUTPUT:
    RETVAL
