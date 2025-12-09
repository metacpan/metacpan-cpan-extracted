#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "newUNOP_CUSTOM.c.inc"
#include "newBINOP_CUSTOM.c.inc"
#include "sv_numeq.c.inc"
#include "sv_numcmp.c.inc"
#include "sv_streq.c.inc"
#include "sv_isa.c.inc"

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

/* Called after msgop is evaluated to croak with the message */
static XOP xop_assert_croak;
static OP *pp_assert_croak(pTHX)
{
  dSP;
  SV *custom_msg = POPs;
  croak_sv(custom_msg);
}

enum BinopType {
    BINOP_NONE,
    BINOP_NUM_EQ,
    BINOP_NUM_NE,
    BINOP_NUM_LT,
    BINOP_NUM_GT,
    BINOP_NUM_LE,
    BINOP_NUM_GE,
    BINOP_STR_EQ,
    BINOP_STR_NE,
    BINOP_STR_LT,
    BINOP_STR_GT,
    BINOP_STR_LE,
    BINOP_STR_GE,
    BINOP_ISA,
};

static enum BinopType classify_binop(int type)
{
  switch(type) {
    case OP_EQ:  return BINOP_NUM_EQ;
    case OP_NE:  return BINOP_NUM_NE;
    case OP_LT:  return BINOP_NUM_LT;
    case OP_GT:  return BINOP_NUM_GT;
    case OP_LE:  return BINOP_NUM_LE;
    case OP_GE:  return BINOP_NUM_GE;
    case OP_SEQ: return BINOP_STR_EQ;
    case OP_SNE: return BINOP_STR_NE;
    case OP_SLT: return BINOP_STR_LT;
    case OP_SGT: return BINOP_STR_GT;
    case OP_SLE: return BINOP_STR_LE;
    case OP_SGE: return BINOP_STR_GE;
    case OP_ISA: return BINOP_ISA;
  }
  return BINOP_NONE;
}

/* Check if binary assertion passes. Returns true if assertion succeeds. */
static bool S_assertbin_check(pTHX_ enum BinopType binoptype, SV *lhs, SV *rhs)
{
  switch(binoptype) {
    case BINOP_NUM_EQ: return sv_numeq(lhs, rhs);
    case BINOP_NUM_NE: return !sv_numeq(lhs, rhs);
    case BINOP_NUM_LT: return sv_numcmp(lhs, rhs) == -1;
    case BINOP_NUM_GT: return sv_numcmp(lhs, rhs) == 1;
    case BINOP_NUM_LE: return sv_numcmp(lhs, rhs) != 1;
    case BINOP_NUM_GE: return sv_numcmp(lhs, rhs) != -1;
    case BINOP_STR_EQ: return sv_streq(lhs, rhs);
    case BINOP_STR_NE: return !sv_streq(lhs, rhs);
    case BINOP_STR_LT: return sv_cmp(lhs, rhs) == -1;
    case BINOP_STR_GT: return sv_cmp(lhs, rhs) == 1;
    case BINOP_STR_LE: return sv_cmp(lhs, rhs) != 1;
    case BINOP_STR_GE: return sv_cmp(lhs, rhs) != -1;
    case BINOP_ISA:    return sv_isa_sv(lhs, rhs);
    default:           return FALSE; /* unreachable */
  }
}
#define assertbin_check(binoptype, lhs, rhs) S_assertbin_check(aTHX_ binoptype, lhs, rhs)

/* Get operator string for error message */
static const char *binop_to_str(enum BinopType binoptype)
{
  switch(binoptype) {
    case BINOP_NUM_EQ: return "==";
    case BINOP_NUM_NE: return "!=";
    case BINOP_NUM_LT: return "<";
    case BINOP_NUM_GT: return ">";
    case BINOP_NUM_LE: return "<=";
    case BINOP_NUM_GE: return ">=";
    case BINOP_STR_EQ: return "eq";
    case BINOP_STR_NE: return "ne";
    case BINOP_STR_LT: return "lt";
    case BINOP_STR_GT: return "gt";
    case BINOP_STR_LE: return "le";
    case BINOP_STR_GE: return "ge";
    case BINOP_ISA:    return "isa";
    default:           return "??"; /* unreachable */
  }
}

static XOP xop_assertbin;
static OP *pp_assertbin(pTHX)
{
  dSP;
  SV *rhs = POPs;
  SV *lhs = POPs;
  enum BinopType binoptype = PL_op->op_private;

  if(assertbin_check(binoptype, lhs, rhs))
    RETURN;

  SV *msg = sv_2mortal(newSVpvs("Assertion failed ("));
  sv_catsv_unqq(msg, lhs);
  sv_catpvf(msg, " %s ", binop_to_str(binoptype));
  sv_catsv_unqq(msg, rhs);
  sv_catpvs(msg, ")");
  croak_sv(msg);
}


static int build_assert(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
    // assert(EXPR, EXPR)
    //
    //  assert($x == 1)
    //  assert($x == 1, "x is not 1");
    //
    // first EXPR is the condition, second is the message.
    // error message is optional.
    // if the condition is false, the message is printed and the program dies.
    OP *condop = args[0]->op;
    OP *msgop  = args[2] ? args[2]->op : NULL;

    if (assert_enabled) {
        if (msgop) {
            // With custom message: lazy evaluation using OP_OR
            // assert(cond, msg) becomes: cond || do { croak(msg) }
            //
            // OP_OR: if condop is true, short-circuit; if false, evaluate other
            // We use op_scope to isolate the other branch's op_next chain

            OP *croakop     = newUNOP_CUSTOM(&pp_assert_croak, 0, msgop);
            OP *scopedblock = op_scope(croakop);

            *out = newLOGOP(OP_OR, 0, condop, scopedblock);
        }
        else {
            // Without custom message: check if binary operator for better error
            enum BinopType binoptype = classify_binop(condop->op_type);
            if (binoptype) {
                // Binary operator: use pp_assertbin for detailed error message
                condop->op_type = OP_CUSTOM;
                condop->op_ppaddr = &pp_assertbin;
                condop->op_private = binoptype;

                *out = condop;
            }
            else {
                // Other expressions: use pp_assert
                *out = newUNOP_CUSTOM(&pp_assert, 0, condop);
            }
        }
    }
    else {
        // do nothing.
        op_free(condop);
        if (msgop) {
            op_free(msgop);
        }
        *out = newOP(OP_NULL, 0);
    }

    return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_assert = {
  .permit_hintkey = "Syntax::Keyword::Assert/assert",
  .pieces = (const struct XSParseKeywordPieceType[]) {
    XPK_ARGS(
      XPK_TERMEXPR_SCALARCTX,
      XPK_OPTIONAL(XPK_COMMA),
      XPK_TERMEXPR_SCALARCTX_OPT
    ),
    {0}
  },
  .build = &build_assert,
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

  XopENTRY_set(&xop_assert_croak, xop_name, "assert_croak");
  XopENTRY_set(&xop_assert_croak, xop_desc, "assert croak with message");
  XopENTRY_set(&xop_assert_croak, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_assert_croak, &xop_assert_croak);

  register_xs_parse_keyword("assert", &hooks_assert, NULL);

  {
    const char *enabledstr = getenv("PERL_ASSERT_ENABLED");
    if(enabledstr) {
      SV *sv = newSVpvn(enabledstr, strlen(enabledstr));
      if(!SvTRUE(sv))
        assert_enabled = FALSE;
      SvREFCNT_dec(sv);
    }
  }

