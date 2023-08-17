#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#define sv_defined(sv) (sv && (SvIOK(sv) || SvNOK(sv) || SvPOK(sv) || SvROK(sv)))

static bool test_pp_matches( pTHX_ SV *a, SV *b )
{
  dSP;
  dTARG;

  SvGETMAGIC( a );
  SvGETMAGIC( b );

  if ( ! sv_defined( b ) ) {
     return( sv_defined( a ) ? FALSE : TRUE );
  }

  else if ( ! SvROK( b ) ) {
    return( sv_eq( a, b ) ? TRUE : FALSE );
  }

  else if ( sv_isobject( b ) && sv_derived_from( b, "Type::Tiny" ) ) {
    int count;
    SV *ret;
    bool ret_truth;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(b);
    XPUSHs(a);
    PUTBACK;
    count = call_method( "check", G_SCALAR );
    SPAGAIN;
    ret = POPs;
    ret_truth = SvTRUE( ret );
    PUTBACK;
    FREETMPS;
    LEAVE;

    return( ret_truth );
  }

  else {
    int count;
    bool r;
    ENTER;
    SAVETMPS;
    PUSHMARK( SP );
    XPUSHs( a );
    XPUSHs( b );
    PUTBACK;
    count = call_pv( "match::simple::match", G_SCALAR );
    SPAGAIN;
    r = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return( r != 0 ? TRUE : FALSE );
  }

  // Shouldn't happen
  return FALSE;
}

static OP *pp_matches( pTHX )
{
  dSP;
  dTARG;
  SV *b = TOPs, *a = TOPm1s;
  POPs;
  SETs( test_pp_matches( aTHX_ a, b ) ? &PL_sv_yes : &PL_sv_no );
  RETURN;
}

static OP *pp_mismatches( pTHX )
{
  dSP;
  dTARG;
  SV *b = TOPs, *a = TOPm1s;
  POPs;
  SETs( test_pp_matches( aTHX_ a, b ) ? &PL_sv_no : &PL_sv_yes );
  RETURN;
}

static const struct XSParseInfixHooks hooks_matches = {
  .cls               = XPI_CLS_MATCH_MISC,
  .permit_hintkey    = "Syntax::Operator::Matches/matches",
  .ppaddr            = &pp_matches,
};

static const struct XSParseInfixHooks hooks_mismatches = {
  .cls               = XPI_CLS_MATCH_MISC,
  .permit_hintkey    = "Syntax::Operator::Matches/mismatches",
  .ppaddr            = &pp_mismatches,
};

MODULE = Syntax::Operator::Matches    PACKAGE = Syntax::Operator::Matches

BOOT:
  boot_xs_parse_infix( 0.26 );
  register_xs_parse_infix( "matches",    &hooks_matches,    NULL );
  register_xs_parse_infix( "mismatches", &hooks_mismatches, NULL );
