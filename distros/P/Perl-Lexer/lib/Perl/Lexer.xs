#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"
#include "gen/token_info_map.h"

#define XS_STATE(type, x)     (INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x)))
#ifndef OP_CLASS
#define OP_CLASS(o) PL_opargs[o->op_type] & OA_CLASS_MASK
#endif

/* Stolen from ext/B/B.c.
 * I hope Perl5 provide make_op_object() as public API!
 */
static const char *b_op_class_name(pTHX_ OP *o) {
    switch (OP_CLASS(o)) {
    case OA_BASEOP:
        return "B::OP";
    case OA_UNOP:
        return "B::UNOP";
    case OA_BINOP:
        return "B::BINOP";
    case OA_LOGOP:
        return "B::LOGOP";
    case OA_LISTOP:
        return "B::LISTOP";
    case OA_PMOP:
        return "B::PMOP";
    case OA_SVOP:
        return "B::SVOP";
    case OA_PVOP_OR_SVOP:
        /* See ext/B/B.xs for more details. */
        if (o->op_type == OP_CUSTOM && (o->op_private & (OPpTRANS_TO_UTF|OPpTRANS_FROM_UTF))) {
#if  defined(USE_ITHREADS)
            return "B::PADOP";
#else
            return "B::SVOP";
#endif
        } else {
            return "B::PVOP";
        }
    case OA_LOOP:
        return "B::LOOP";
    case OA_COP:
        return "B::COP";
    case OA_BASEOP_OR_UNOP:
        /* See ext/B/B.xs for more details. */
        return (o->op_flags & OPf_KIDS) ? "B::UNOP" : "B::OP";
    case OA_FILESTATOP:
        return ((o->op_flags & OPf_KIDS) ? "B::UNOP" :
#ifdef USE_ITHREADS
                (o->op_flags & OPf_REF) ? "B::PADOP" : "B::OP"
#else
                        (o->op_flags & OPf_REF) ? "B::SVOP" : "B::OP"
#endif
        );
    case OA_LOOPEXOP:
        if (o->op_flags & OPf_STACKED)
            return "B::UNOP";
        else if (o->op_flags & OPf_SPECIAL)
            return "B::OP";
        else
            return "B::PVOP";
    };
    warn("can't determine class of operator %s, assuming BASEOP\n",
        OP_NAME(o));
    return "B::OP";
}

MODULE = Perl::Lexer    PACKAGE = Perl::Lexer

PROTOTYPES: DISABLE

BOOT:
    HV* stash = gv_stashpv("Perl::Lexer", TRUE);
    newCONSTSUB(stash, "TOKENTYPE_NONE",  newSViv(TOKENTYPE_NONE));
    newCONSTSUB(stash, "TOKENTYPE_IVAL",  newSViv(TOKENTYPE_IVAL));
    newCONSTSUB(stash, "TOKENTYPE_OPNUM", newSViv(TOKENTYPE_OPNUM));
    newCONSTSUB(stash, "TOKENTYPE_PVAL",  newSViv(TOKENTYPE_PVAL));
    newCONSTSUB(stash, "TOKENTYPE_OPVAL", newSViv(TOKENTYPE_OPVAL));

void
scan_fh(self, rsfp)
    SV* self;
    PerlIO *rsfp;
CODE:
{
    ENTER;
    SAVESPTR(PL_compcv);
    PL_compcv = PL_main_cv;
    Perl_lex_start(aTHX_ NULL, rsfp, 0);
    AV *result = newAV();
    while (1) {
        int token = Perl_yylex(aTHX);
        if (token == 0) {
            break;
        }
        /* PerlIO_printf(PerlIO_stderr(), "token: %d\n", token); */

        int i=0;
        while (debug_tokens[i].token != 0) {
            if (debug_tokens[i].token == token) {
                AV * row = newAV();
                av_push(row, newSViv(token));
                switch (debug_tokens[i].type) {
                case TOKENTYPE_NONE:
                    break;
                case TOKENTYPE_IVAL:
                case TOKENTYPE_OPNUM: /* pl_yylval.ival contains an opcode number */
                    av_push(row, newSViv(PL_parser->yylval.ival));
                    break;
                case TOKENTYPE_PVAL:
                    av_push(row, newSVpv(PL_parser->yylval.pval, 0));
                    break;
                case TOKENTYPE_OPVAL: {
                    OP *op = PL_parser->yylval.opval;
                    if (op != NULL) {
                        SV *rv = newRV_noinc(newSViv(PTR2IV(op)));
                        sv_bless(rv, gv_stashpv(b_op_class_name(aTHX_ op), 1));
                        SvREADONLY_on(rv);
                        av_push(row, rv);
                    }
                    break;
                }
                }
                SV *token_obj = newRV_noinc((SV*)row);
                sv_bless(token_obj, gv_stashpv("Perl::Lexer::Token", 1));
                SvREADONLY_on(token_obj);
                av_push(result, token_obj);
                break;
            }
            ++i;
        }
    }
    LEAVE;
    ST(0) = newRV_noinc((SV*)result);
}

MODULE = Perl::Lexer    PACKAGE = Perl::Lexer::Token

SV*
_yylval_svop(svop_sv)
    SV* svop_sv;
CODE:
{
    SVOP*o = (SVOP*)SvIV(SvRV(svop_sv));
    RETVAL = o->op_sv;
}
OUTPUT:
    RETVAL

void
_name(token)
    IV token;
PPCODE:
{
    int i=0;
    while (debug_tokens[i].token != 0) {
        if (debug_tokens[i].token == token) {
            XSRETURN_PV(debug_tokens[i].name);
        }
        ++i;
    }
    XSRETURN_NO;
}

void
_type(token)
    IV token;
PPCODE:
{
    int i=0;
    while (debug_tokens[i].token != 0) {
        if (debug_tokens[i].token == token) {
            XSRETURN_IV(debug_tokens[i].type);
        }
        ++i;
    }
    XSRETURN_NO;
}

