#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "newUNOP_CUSTOM.c.inc"
#include "sv_numeq.c.inc"
#include "sv_streq.c.inc"

static bool assert_enabled = TRUE;

#define sv_catsv_unqq(sv, val)  S_sv_catsv_unqq(aTHX_ sv, val)
static void S_sv_catsv_unqq(pTHX_ SV *sv, SV *val)
{
  if(!SvOK(val)) {
    sv_catpvs(sv, "undef");
    return;
  }

#ifdef SvIsBOOL
  if(SvIsBOOL(val)) {
    SvTRUE(val) ? sv_catpvs(sv, "true") : sv_catpvs(sv, "false");
    return;
  }
#endif

  if(!SvPOK(val)) {
    sv_catsv(sv, val);
    return;
  }

#ifdef SVf_QUOTEDPREFIX
  sv_catpvf(sv, "%" SVf_QUOTEDPREFIX, SVfARG(val));
#else
  sv_catpvf(sv, "\"%" SVf "\"", SVfARG(val));
#endif
}

static XOP xop_assert;
static OP *pp_assert(pTHX)
{
  dSP;
  SV *val = POPs;

  if(SvTRUE(val))
    RETURN;

  SV *msg = sv_2mortal(newSVpvs("Assertion failed ("));
  sv_catsv_unqq(msg, val);
  sv_catpvs(msg, ")");
  croak_sv(msg);
}

enum BinopType {
    BINOP_NONE,
    BINOP_NUM_EQ,
    BINOP_NUM_NE,
    BINOP_STR_EQ,
    BINOP_STR_NE,
};

static enum BinopType classify_binop(int type)
{
  switch(type) {
    case OP_EQ:  return BINOP_NUM_EQ;
    case OP_NE:  return BINOP_NUM_NE;
    case OP_SEQ: return BINOP_STR_EQ;
    case OP_SNE: return BINOP_STR_NE;
  }
  return BINOP_NONE;
}

static XOP xop_assertbin;
static OP *pp_assertbin(pTHX)
{
  dSP;
  SV *rhs = POPs;
  SV *lhs = POPs;
  enum BinopType binoptype = PL_op->op_private;

  const char *op_str;

  switch(binoptype) {
    case BINOP_NUM_EQ:
      if(sv_numeq(lhs, rhs))
        goto ok;

      op_str = "==";
      break;

    case BINOP_NUM_NE:
      if(!sv_numeq(lhs, rhs))
        goto ok;

      op_str = "!=";
      break;

    case BINOP_STR_EQ:
      if(sv_streq(lhs, rhs))
        goto ok;

      op_str = "eq";
      break;

    case BINOP_STR_NE:
      if(!sv_streq(lhs, rhs))
          goto ok;

      op_str = "ne";
      break;

    default:
      croak("ARGH unreachable");
  }

  SV *msg = sv_2mortal(newSVpvs("Assertion failed ("));

  sv_catsv_unqq(msg, lhs);
  sv_catpvf(msg, " %s ", op_str);
  sv_catsv_unqq(msg, rhs);
  sv_catpvs(msg, ")");
  croak_sv(msg);

ok:
  RETURN;
}

static int build_assert(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
    OP *argop = arg0->op;
    if (assert_enabled) {
        enum BinopType binoptype = classify_binop(argop->op_type);
        if (binoptype) {
            argop->op_type = OP_CUSTOM;
            argop->op_ppaddr = &pp_assertbin;
            argop->op_private = binoptype;
            *out = argop;
        }
        else {
            *out = newUNOP_CUSTOM(&pp_assert, 0, argop);
        }
    }
    else {
        // do nothing.
        op_free(argop);
        *out = newOP(OP_NULL, 0);
    }

    return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_assert = {
  .permit_hintkey = "Syntax::Keyword::Assert/assert",
  .piece1 = XPK_TERMEXPR_SCALARCTX,
  .build1 = &build_assert,
};

MODULE = Syntax::Keyword::Assert    PACKAGE = Syntax::Keyword::Assert

BOOT:
  boot_xs_parse_keyword(0.36);

  XopENTRY_set(&xop_assert, xop_name, "assert");
  XopENTRY_set(&xop_assert, xop_desc, "assert");
  XopENTRY_set(&xop_assert, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_assert, &xop_assert);

  XopENTRY_set(&xop_assertbin, xop_name, "assertbin");
  XopENTRY_set(&xop_assertbin, xop_desc, "assert(binary)");
  XopENTRY_set(&xop_assertbin, xop_class, OA_BINOP);
  Perl_custom_op_register(aTHX_ &pp_assertbin, &xop_assertbin);

  register_xs_parse_keyword("assert", &hooks_assert, NULL);

  {
    const char *enabledstr = getenv("PERL_ASSERT_ENABLED");
    if(enabledstr) {
      SV *sv = newSVpvn(enabledstr, strlen(enabledstr));
      if(!SvTRUE(sv))
        assert_enabled = FALSE;
    }
  }

