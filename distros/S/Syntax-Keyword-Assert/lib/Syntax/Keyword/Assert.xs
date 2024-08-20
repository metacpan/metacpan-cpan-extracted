#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

static bool is_strict(pTHX_)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    call_pv("Syntax::Keyword::Assert::STRICT", G_SCALAR);
    SPAGAIN;

    bool ok = SvTRUEx(POPs);

    PUTBACK;

    FREETMPS;
    LEAVE;

    return ok;
}

static OP *make_xcroak(pTHX_ OP *msg)
{
    OP *xcroak;
    xcroak = newCVREF(
        OPf_WANT_SCALAR,
        newSVOP(OP_CONST, 0, newSVpvs("Syntax::Keyword::Assert::_croak"))
    );
    xcroak = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, msg, xcroak));
    return xcroak;
}

static int build_assert(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
    if (is_strict(aTHX_)) {
        // build the following code:
        //
        //   Syntax::Keyword::Assert::_croak "Assertion failed"
        //      unless do { $a == 1 }
        //
        OP *block = arg0->op;
        OP *msg = newSVOP(OP_CONST, 0, newSVpvs("Assertion failed"));

        *out = newLOGOP(OP_AND, 0,
            newUNOP(OP_NOT, 0, block),
            make_xcroak(aTHX_ msg)
        );
    }
    else {
        // do nothing.
        *out = newOP(OP_NULL, 0);
    }

    return KEYWORD_PLUGIN_STMT;
}

static const struct XSParseKeywordHooks hooks_assert = {
  .permit_hintkey = "Syntax::Keyword::Assert/assert",
  .piece1 = XPK_BLOCK,
  .build1 = &build_assert,
};

MODULE = Syntax::Keyword::Assert    PACKAGE = Syntax::Keyword::Assert

BOOT:
  boot_xs_parse_keyword(0.36);
  register_xs_parse_keyword("assert", &hooks_assert, NULL);
