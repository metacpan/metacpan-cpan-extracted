#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "lex_read_unichar.inc.c"
#include "wrap_keyword_plugin.inc.c"


STATIC SV *hint_key_sv;


#define is_syntax_enabled() SvTRUE( cop_hints_fetch_sv( PL_curcop, hint_key_sv, 0, 0 ) )


STATIC void croak_missing_terminator( pTHX_ I32 edelim ) {
#define croak_missing_terminator( a ) croak_missing_terminator( aTHX_ a )
   char buf[ 3 ];
   char quote;

   if ( edelim == -1 )
      Perl_croak( aTHX_ "qw not terminated anywhere before EOF" );

   if ( edelim >= 0x80 )
      /* Suboptimal output format */
      Perl_croak( aTHX_ "Can't find qw terminator U+%"UVXf" anywhere before EOF", (UV)edelim );

   if ( isCNTRL( edelim ) ) {
      buf[ 0 ] = '^';
      buf[ 1 ] = (char)toCTRL( edelim );
      buf[ 2 ] = '\0';
      quote = '"';
   } else {
      buf[ 0 ] = (char)edelim;
      buf[ 1 ] = '\0';
      quote = edelim == '"' ? '\'' : '"';
   }

   Perl_croak( aTHX_ "Can't find qw terminator %c%s%c anywhere before EOF", quote, buf, quote );
}


/* sv is assumed to contain a string (and nothing else). */
/* sv is assumed to have no magic. */
STATIC void append_char_to_word( pTHX_ SV *word_sv, UV c ) {
#define append_char_to_word( a, b ) append_char_to_word( aTHX_ a, b )
   char buf[ UTF8_MAXBYTES + 1 ];  /* I wonder why the "+ 1". */
   STRLEN len;
   if ( SvUTF8( word_sv ) || c > 255 ) {
      len = (char*)uvchr_to_utf8( (U8*)buf, c ) - buf;
      sv_utf8_upgrade_flags_grow( word_sv, 0, len+1 );
   } else {
      len = 1;
      buf[ 0 ] = (char)c;
   }

   sv_catpvn_nomg( word_sv, buf, len );
}


/* sv is assumed to contain a string (and nothing else). */
/* sv is assumed to have no magic. */
/* The sv's length is reduced to zero length and the UTF8 flag is turned off. */
STATIC void append_word_to_list( pTHX_ OP **list_op_ptr, SV *word_sv ) {
#define append_word_to_list( a, b ) append_word_to_list( aTHX_ a, b )
   STRLEN len = SvCUR( word_sv );
   if ( len ) {
      SV* sv_copy = newSV( len );
      sv_copypv( sv_copy, word_sv );
      *list_op_ptr = op_append_elem( OP_LIST, *list_op_ptr, newSVOP( OP_CONST, 0, sv_copy ) );

      SvCUR_set( word_sv, 0 );
      SvUTF8_off( word_sv );
   }
}


STATIC OP* parse_qw( pTHX ) {
#define parse_qw() parse_qw( aTHX )
   I32 sdelim;
   I32 edelim;
   IV depth;
   OP *list_op = NULL;
   SV *word_sv = newSVpvn( "", 0 );
   int warned_comma = !ckWARN( WARN_QW );

   lex_read_space( 0 );

   sdelim = lex_read_unichar( 0 );
   if ( sdelim == -1 )
      croak_missing_terminator( -1 );

   { // Find corresponding closing delimiter.
      char *p;
      if ( sdelim && ( p = strchr( "([{< )]}> )]}>", sdelim ) ) )
         edelim = *( p + 5 );
      else
         edelim = sdelim;
   }

   depth = 1;
   for (;;) {
      I32 c = lex_peek_unichar( 0 );

   REDO:
      if ( c == -1 )
         croak_missing_terminator( edelim );

      if ( c == edelim ) {
         lex_read_unichar( 0 );
         if ( --depth ) {
            append_char_to_word( word_sv, c );
         } else {
            append_word_to_list( &list_op, word_sv );
            break;
         }
      }
      else if ( c == sdelim ) {
         lex_read_unichar( 0 );
         ++depth;
         append_char_to_word( word_sv, c );
      }
      else if ( c == '\\' ) {
         lex_read_unichar( 0 );
         c = lex_peek_unichar( 0 );
         if ( c != sdelim && c != edelim && c != '\\' && c != '#' ) {
            append_char_to_word( word_sv, '\\' );
            goto REDO;
         }

         lex_read_unichar( 0 );
         append_char_to_word( word_sv, c );
      }
      else if ( c == '#' || isSPACE( c ) ) {
         append_word_to_list( &list_op, word_sv );
         lex_read_space( 0 );
      }
      else {
         if ( c == ',' && !warned_comma ) {
            Perl_warner( aTHX_ packWARN( WARN_QW ), "Possible attempt to separate words with commas" );
            ++warned_comma;
         }

         lex_read_unichar( 0 );
         append_char_to_word( word_sv, c );
      }
   }

   SvREFCNT_dec( word_sv );

   if ( !list_op )
      list_op = newNULLLIST();

   list_op->op_flags |= OPf_PARENS;
   return list_op;
}


STATIC Perl_keyword_plugin_t next_keyword_plugin = NULL;
#define next_keyword_plugin( a, b, c ) next_keyword_plugin( aTHX_ a, b, c )


STATIC int my_keyword_plugin( pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr ) {
   if ( is_syntax_enabled() ) {
      if ( memEQs( keyword_ptr, keyword_len, "qw" ) ) {
         *op_ptr = parse_qw();
         return KEYWORD_PLUGIN_EXPR;
      }
   }

   return next_keyword_plugin( keyword_ptr, keyword_len, op_ptr );
}


/* ======================================== */

MODULE = Syntax::Feature::QwComments   PACKAGE = Syntax::Feature::QwComments


void
hint_key()
   PPCODE:
      SvREFCNT_inc( hint_key_sv );
      XPUSHs( hint_key_sv );
      XSRETURN( 1 );


BOOT:
{
   wrap_keyword_plugin( my_keyword_plugin, &next_keyword_plugin );

   hint_key_sv = newSVpvs( "Syntax::Feature::QwComments::qw" );
   SvREADONLY_on( hint_key_sv );
}
