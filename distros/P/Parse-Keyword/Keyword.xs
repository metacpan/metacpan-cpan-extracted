#include "EXTERN.h"
#include "perl.h"
#include "callparser1.h"
#include "XSUB.h"

#ifndef cv_clone
#define cv_clone(a) Perl_cv_clone(aTHX_ a)
#endif

static SV *parser_fn(OP *(fn)(pTHX_ U32), bool named)
{
    I32 floor;
    CV *code;
    U8 errors;

    ENTER;

    PL_curcop = &PL_compiling;
    SAVEVPTR(PL_op);
    SAVEI8(PL_parser->error_count);
    PL_parser->error_count = 0;

    floor = start_subparse(0, named ? 0 : CVf_ANON);
    code = newATTRSUB(floor, NULL, NULL, NULL, fn(aTHX_ 0));

    errors = PL_parser->error_count;

    LEAVE;

    if (errors) {
        ++PL_parser->error_count;
        return newSV(0);
    }
    else {
        if (CvCLONE(code)) {
            code = cv_clone(code);
        }

        return newRV_inc((SV*)code);
    }
}

static OP *parser_callback(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
    dSP;
    SV *args_generator;
    SV *statement = NULL;
    I32 count;

    /* call the parser callback
     * it should take no arguments and return a coderef which, when called,
     * produces the arguments to the keyword function
     * the optree we want to generate is for something like
     *   mykeyword($code->())
     * where $code is the thing returned by the parser function
     */

    PUSHMARK(SP);
    mXPUSHp(GvNAME(namegv), GvNAMELEN(namegv));
    PUTBACK;
    count = call_sv(psobj, G_ARRAY);
    SPAGAIN;
    if (count > 1) {
        statement = POPs;
    }
    args_generator = SvREFCNT_inc(POPs);
    PUTBACK;

    if (!SvROK(args_generator) || SvTYPE(SvRV(args_generator)) != SVt_PVCV) {
        croak("The parser function for %s must return a coderef, not %"SVf,
              GvNAME(namegv), args_generator);
    }

    if (SvTRUE(statement)) {
        *flagsp |= CALLPARSER_STATEMENT;
    }

    return newUNOP(OP_ENTERSUB, OPf_STACKED,
                   newCVREF(0, newSVOP(OP_CONST, 0, args_generator)));
}

/* TODO:
 *   - "parse a variable name"
 *   - "parse a quoted string"
 *   - "create a new lexical variable" (maybe?)
 */

MODULE = Parse::Keyword  PACKAGE = Parse::Keyword

PROTOTYPES: DISABLE

void
install_keyword_handler(keyword, handler)
    SV *keyword
    SV *handler
  CODE:
    cv_set_call_parser((CV*)SvRV(keyword), parser_callback, handler);

SV *
lex_peek(len = 1)
    UV len
  CODE:
    PL_curcop = &PL_compiling;

    /* XXX before 5.19.2, lex_next_chunk when we aren't at the end of a line
     * just breaks things entirely (the parser no longer sees the text that is
     * read in). this is (i think inadvertently) fixed in 5.19.2 (21791330a),
     * but it still screws up the line numbers of everything that follows. so,
     * the workaround is just to not call lex_next_chunk unless we're at the
     * end of a line. this is a bit limiting, but should rarely come up in
     * practice.
    */
    /*
    while (PL_parser->bufend - PL_parser->bufptr < len) {
        if (!lex_next_chunk(0)) {
            break;
        }
    }
    */
    if (PL_parser->bufptr == PL_parser->bufend) {
        lex_next_chunk(0);
    }
    if (PL_parser->bufend - PL_parser->bufptr < len) {
        len = PL_parser->bufend - PL_parser->bufptr;
    }

    RETVAL = newSVpvn(PL_parser->bufptr, len); /* XXX unicode? */
  OUTPUT:
    RETVAL

void
lex_read(len = 1)
    UV len
  CODE:
    PL_curcop = &PL_compiling;
    lex_read_to(PL_parser->bufptr + len);

void
lex_read_space()
  CODE:
    PL_curcop = &PL_compiling;
    lex_read_space(0);

void
lex_stuff(str)
    SV *str
  CODE:
    PL_curcop = &PL_compiling;
    lex_stuff_sv(str, 0);

SV *
parse_block(named = FALSE)
    bool named
  CODE:
    RETVAL = parser_fn(Perl_parse_block, named);
  OUTPUT:
    RETVAL

SV *
parse_stmtseq(named = FALSE)
    bool named
  CODE:
    RETVAL = parser_fn(Perl_parse_stmtseq, named);
  OUTPUT:
    RETVAL

SV *
parse_fullstmt(named = FALSE)
    bool named
  CODE:
    RETVAL = parser_fn(Perl_parse_fullstmt, named);
  OUTPUT:
    RETVAL

SV *
parse_barestmt(named = FALSE)
    bool named
  CODE:
    RETVAL = parser_fn(Perl_parse_barestmt, named);
  OUTPUT:
    RETVAL

SV *
parse_fullexpr(named = FALSE)
    bool named
  CODE:
    RETVAL = parser_fn(Perl_parse_fullexpr, named);
  OUTPUT:
    RETVAL

SV *
parse_listexpr(named = FALSE)
    bool named
  CODE:
    RETVAL = parser_fn(Perl_parse_listexpr, named);
  OUTPUT:
    RETVAL

SV *
parse_termexpr(named = FALSE)
    bool named
  CODE:
    RETVAL = parser_fn(Perl_parse_termexpr, named);
  OUTPUT:
    RETVAL

SV *
parse_arithexpr(named = FALSE)
    bool named
  CODE:
    RETVAL = parser_fn(Perl_parse_arithexpr, named);
  OUTPUT:
    RETVAL

SV *
compiling_package()
  CODE:
    RETVAL = newSVsv(PL_curstname);
  OUTPUT:
    RETVAL
