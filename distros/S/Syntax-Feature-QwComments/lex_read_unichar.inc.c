// Apply a fix for a bug that's fixed in 5.16.
#if PERL_VERSION < 16
STATIC I32 lex_read_unichar( pTHX_ U32 flags ) {
#define lex_read_unichar( a ) lex_read_unichar( aTHX_ a )
      I32 c;
      if ( flags & ~(LEX_KEEP_PREVIOUS) )
          Perl_croak( aTHX_ "Lexing code internal error (%s)", "lex_read_unichar" );

      c = lex_peek_unichar( flags );
      if ( c != -1 ) {
         if ( c == '\n' )
            CopLINE_inc( PL_curcop );

         if ( lex_bufutf8() )
            PL_parser->bufptr += UTF8SKIP( PL_parser->bufptr );
         else
            ++( PL_parser->bufptr );
      }

      return c;
   }
#endif
