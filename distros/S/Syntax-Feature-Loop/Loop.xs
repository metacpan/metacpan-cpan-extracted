#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "wrap_keyword_plugin.inc.c"


STATIC SV *hint_key_sv;


#define is_syntax_enabled() SvTRUE( cop_hints_fetch_sv( PL_curcop, hint_key_sv, 0, 0 ) )


STATIC OP *parse_loop( pTHX ) {
#define parse_loop() parse_loop( aTHX )
   OP *exprop  = newSVOP( OP_CONST, 0, &PL_sv_yes );
   OP *blockop = parse_block( 0 );
   OP *loopop  = newWHILEOP( 0, 1, NULL, exprop, blockop, NULL, 0 );
   return loopop;
}


STATIC Perl_keyword_plugin_t next_keyword_plugin = NULL;
#define next_keyword_plugin( a, b, c ) next_keyword_plugin( aTHX_ a, b, c )


STATIC int my_keyword_plugin( pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr ) {
   if ( is_syntax_enabled() ) {
      if ( memEQs( keyword_ptr, keyword_len, "loop" ) ) {
         *op_ptr = parse_loop();
         return KEYWORD_PLUGIN_STMT;
      }
   }

   return next_keyword_plugin( keyword_ptr, keyword_len, op_ptr );
}


/* ======================================== */

MODULE = Syntax::Feature::Loop   PACKAGE = Syntax::Feature::Loop


void
hint_key()
   PPCODE:
      SvREFCNT_inc( hint_key_sv );
      XPUSHs( hint_key_sv );
      XSRETURN( 1 );


BOOT:
{
   wrap_keyword_plugin( my_keyword_plugin, &next_keyword_plugin );

   hint_key_sv = newSVpvs( "Syntax::Feature::Loop::loop" );
   SvREADONLY_on( hint_key_sv );
}
