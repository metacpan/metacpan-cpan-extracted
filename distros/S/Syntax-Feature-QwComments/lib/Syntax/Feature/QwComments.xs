#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "../../../callparser1.h"


/* Apply a fix for a bug that's fixed in 5.16. */
#if PERL_VERSION < 16
#undef lex_read_unichar

static I32 lex_read_unichar(pTHX_ U32 flags) {
#define lex_read_unichar(a) lex_read_unichar(aTHX_ a)
      I32 c;
      if (flags & ~(LEX_KEEP_PREVIOUS))
          Perl_croak(aTHX_ "Lexing code internal error (%s)", "lex_read_unichar");

      c = lex_peek_unichar(flags);
      if (c != -1) {
         if (c == '\n')
            CopLINE_inc(PL_curcop);

         if (lex_bufutf8())
            PL_parser->bufptr += UTF8SKIP(PL_parser->bufptr);
         else
            ++(PL_parser->bufptr);
      }

      return c;
   }
#endif


STATIC OP* remove_sub_call(pTHX_ OP* entersubop) {
#define remove_sub_call(a) remove_sub_call(aTHX_ a)
   OP* pushop;
   OP* realop;

   pushop = cUNOPx(entersubop)->op_first;
   if (!pushop->op_sibling)
      pushop = cUNOPx(pushop)->op_first;

   realop = pushop->op_sibling;
   if (!realop || !realop->op_sibling)
      return entersubop;

   pushop->op_sibling = realop->op_sibling;
   realop->op_sibling = NULL;
   op_free(entersubop);
   return realop;
}


STATIC void croak_missing_terminator(pTHX_ I32 edelim) {
#define croak_missing_terminator(a) croak_missing_terminator(aTHX_ a)
   char buf[3];
   char quote;

   if (edelim == -1)
      Perl_croak(aTHX_ "qw not terminated anywhere before EOF");

   if (edelim >= 0x80)
      /* Suboptimal output format */
      Perl_croak(aTHX_ "Can't find qw terminator U+%"UVXf" anywhere before EOF", (UV)edelim);

   if (isCNTRL(edelim)) {
      buf[0] = '^';
      buf[1] = (char)toCTRL(edelim);
      buf[2] = '\0';
      quote = '"';
   } else {
      buf[0] = (char)edelim;
      buf[1] = '\0';
      quote = edelim == '"' ? '\'' : '"';
   }

   Perl_croak(aTHX_ "Can't find qw terminator %c%s%c anywhere before EOF", quote, buf, quote);
}


/* sv is assumed to contain a string (and nothing else). */
/* sv is assumed to have no magic. */
STATIC void append_char_to_word(pTHX_ SV* word_sv, UV c) {
#define append_char_to_word(a,b) append_char_to_word(aTHX_ a,b)
   char buf[UTF8_MAXBYTES+1];  /* I wonder why the "+ 1". */
   STRLEN len;
   if (SvUTF8(word_sv) || c > 255) {
      len = (char*)uvuni_to_utf8((U8*)buf, c) - buf;
      sv_utf8_upgrade_flags_grow(word_sv, 0, len+1);
   } else {
      len = 1;
      buf[0] = (char)c;
   }

   sv_catpvn_nomg(word_sv, buf, len);
}


/* sv is assumed to contain a string (and nothing else). */
/* sv is assumed to have no magic. */
/* The sv's length is reduced to zero length and the UTF8 flag is turned off. */
STATIC void append_word_to_list(pTHX_ OP** list_op_ptr, SV* word_sv) {
#define append_word_to_list(a,b) append_word_to_list(aTHX_ a,b)
   STRLEN len = SvCUR(word_sv);
   if (len) {
      SV* sv_copy = newSV(len);
      sv_copypv(sv_copy, word_sv);
      *list_op_ptr = op_append_elem(OP_LIST, *list_op_ptr, newSVOP(OP_CONST, 0, sv_copy));

      SvCUR_set(word_sv, 0);
      SvUTF8_off(word_sv);
   }
}


STATIC OP* parse_qw(pTHX_ GV* namegv, SV* psobj, U32* flagsp) {
#define parse_qw(a,b,c) parse_qw(aTHX_ a,b,c)
   I32 sdelim;
   I32 edelim;
   IV depth;
   OP* list_op = NULL;
   SV* word_sv = newSVpvn("", 0);
   int warned_comma = !ckWARN(WARN_QW);

   PERL_UNUSED_ARG(namegv);
   PERL_UNUSED_ARG(psobj);
   PERL_UNUSED_ARG(flagsp);

   lex_read_space(0);

   sdelim = lex_read_unichar(0);
   if (sdelim == -1)
      croak_missing_terminator(-1);

   { /* Find corresponding closing delimiter */
      char* p;
      if (sdelim && (p = strchr("([{< )]}> )]}>", sdelim)))
         edelim = *(p + 5);
      else
         edelim = sdelim;
   }

   depth = 1;
   for (;;) {
      I32 c = lex_peek_unichar(0);
      
   REDO:
      if (c == -1)
         croak_missing_terminator(edelim);
      if (c == edelim) {
         lex_read_unichar(0);
         if (--depth) {
            append_char_to_word(word_sv, c);
         } else {
            append_word_to_list(&list_op, word_sv);
            break;
         }
      }
      else if (c == sdelim) {
         lex_read_unichar(0);
         ++depth;
         append_char_to_word(word_sv, c);
      }
      else if (c == '\\') {
         lex_read_unichar(0);
         c = lex_peek_unichar(0);
         if (c != sdelim && c != edelim && c != '\\' && c != '#') {
            append_char_to_word(word_sv, '\\');
            goto REDO;
         }

         lex_read_unichar(0);
         append_char_to_word(word_sv, c);
      }
      else if (c == '#' || isSPACE(c)) {
         append_word_to_list(&list_op, word_sv);
         lex_read_space(0);
      }
      else {
         if (c == ',' && !warned_comma) {
            Perl_warner(aTHX_ packWARN(WARN_QW), "Possible attempt to separate words with commas");
            ++warned_comma;
         }
         lex_read_unichar(0);
         append_char_to_word(word_sv, c);
      }
   }

   SvREFCNT_dec(word_sv);

   if (!list_op)
      list_op = newNULLLIST();

   list_op->op_flags |= OPf_PARENS;
   return list_op;
}


STATIC OP* ck_qw(pTHX_ OP* o, GV* namegv, SV* ckobj) {
#define check_qw(a,b,c) check_qw(aTHX_ a,b,c)
   PERL_UNUSED_ARG(namegv);
   PERL_UNUSED_ARG(ckobj);
   return remove_sub_call(o);
}


/* ======================================== */

MODULE = Syntax::Feature::QwComments   PACKAGE = Syntax::Feature::QwComments

BOOT:
{
   CV* const qwcv = get_cvn_flags("Syntax::Feature::QwComments::replacement_qw", 43, GV_ADD);
   cv_set_call_parser(qwcv, parse_qw, &PL_sv_undef);
   cv_set_call_checker(qwcv, ck_qw, &PL_sv_undef);
}
