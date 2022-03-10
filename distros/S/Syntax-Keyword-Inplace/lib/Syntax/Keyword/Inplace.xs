/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"

enum {
  OPpDUP_MOVEMARK = (1<<0),
};

static XOP xop_dup;
static OP *pp_dup(pTHX)
{
  dSP;
  SV *sv = TOPs;

  if(PL_op->op_flags & OPf_REF)
    XPUSHs(sv);
  else
    XPUSHs(sv_mortalcopy(sv));

  if(PL_op->op_private & OPpDUP_MOVEMARK)
    (*PL_markstack_ptr)++;

  RETURN;
}

#define newDUPOP(flags)  S_newDUPOP(aTHX_ flags)
static OP *S_newDUPOP(pTHX_ U32 flags)
{
  OP *o = newUNOP(OP_CUSTOM, flags, NULL);
  o->op_ppaddr = &pp_dup;
  return o;
}

static bool arg_is_acceptable(OP *argop)
{
  switch(argop->op_type) {
    case OP_PADSV:
    case OP_RV2SV:
    case OP_HELEM:
    case OP_AELEM:
      return TRUE;
  }

  return FALSE;
}

static OP *build_inplace_coreop(pTHX_ OP *op)
{
  /* Turn EXPR... -> OP into  EXPR... -> DUP -> OP -> SASSIGN */
  /* The tree shape of this will be horrible */

  OP *expr = cUNOPx(op)->op_first;

  if(!arg_is_acceptable(expr))
    croak("Cannot use %s as an argument to an inplace operator", PL_op_name[expr->op_type]);

  /* Thread the DUP op in without it appearing structurally */
  OP *dupop = newDUPOP(OPf_REF);

  dupop->op_next = expr->op_next;
  expr->op_next = dupop;

  /* This really weird OP_SASSIGN is a binop with only one child. Don't worry.
   * At runtime it will still see two SVs because of the DUP; but they'll be
   * in the wrong order so we'll have to swap them */
  OP *assignop = newBINOP(OP_SASSIGN, (OPpASSIGN_BACKWARDS << 8), op, newOP(OP_NULL, 0));

  assignop->op_next = op->op_next;
  op->op_next = assignop;

  return assignop;
}

static OP *build_inplace_entersub(pTHX_ OP *op)
{
  OP *args = cUNOPx(op)->op_first;

  if(!args->op_type && args->op_targ == OP_LIST)
    args = cLISTOPx(args)->op_first;

  assert(args->op_type == OP_PUSHMARK);

  OP *arg = OpSIBLING(args);

  /* If this op has a single argument then OpSIBLING of arg will be set,
   * but OpSIBLING of that will be NULL
   */

  if(!OpSIBLING(arg))
    croak("Cannot use a function call with no arguments as an inplace operator");
  if(OpSIBLING(OpSIBLING(arg)))
    croak("Cannot use a function call with more than one argument as an inplace operator");

  if(!arg_is_acceptable(arg))
    croak("Cannot use %s as an argument to an inplace operator", PL_op_name[arg->op_type]);

  OP *start = LINKLIST(op);
  op->op_next = start;

  /* Thread the DUP op in without it appearing structurally */
  OP *dupop = newDUPOP(OPf_REF | (OPpDUP_MOVEMARK << 8));

  dupop->op_next = arg->op_next;
  arg->op_next = dupop;

  /* This really weird OP_SASSIGN is a binop with only one child. Don't worry.
   * At runtime it will still see two SVs because of the DUP; but they'll be
   * in the wrong order so we'll have to swap them */
  OP *assignop = newBINOP(OP_SASSIGN, (OPpASSIGN_BACKWARDS << 8), op, newOP(OP_NULL, 0));

  assignop->op_next = op->op_next;
  op->op_next = assignop;

  return assignop;
}

static int build_inplace(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  OP *op = arg0->op;
  OPCODE optype = op->op_type;

#if 0
  warn("Initial optree:\n");
  op_dump(op);
#endif

  /* Any retscalar + unop is fine */
  if((PL_opargs[optype] & OA_RETSCALAR) &&
      ((PL_opargs[optype] & OA_CLASS_MASK) == OA_UNOP))
    *out = build_inplace_coreop(aTHX_ op);
  /* Any retscalar baseop_or_unop is fine provided it has a kid */
  else if((PL_opargs[optype] & OA_RETSCALAR) &&
      ((PL_opargs[optype] & OA_CLASS_MASK) == OA_BASEOP_OR_UNOP)) {
    if(!(op->op_flags & OPf_KIDS))
      croak("Cannot use %s as an inplace operator without an expression", PL_op_name[optype]);
    *out = build_inplace_coreop(aTHX_ op);
  }
  /* We'll possibly allow entersub but only of a single argument */
  else if(optype == OP_ENTERSUB)
    *out = build_inplace_entersub(aTHX_ op);
  else
    croak("Cannot use %s as an inplace operator", PL_op_name[optype]);

#if 0
  warn("Final optree\n");
  op_dump(*out);
#endif

  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_inplace = {
  .permit_hintkey = "Syntax::Keyword::Inplace/inplace",
  .piece1 = XPK_TERMEXPR,
  .build1 = &build_inplace,
};

MODULE = Syntax::Keyword::Inplace    PACKAGE = Syntax::Keyword::Inplace

BOOT:
  boot_xs_parse_keyword(0.13);

  XopENTRY_set(&xop_dup, xop_name, "dup");
  XopENTRY_set(&xop_dup, xop_desc, "duplicate");
  XopENTRY_set(&xop_dup, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_dup, &xop_dup);

  register_xs_parse_keyword("inplace", &hooks_inplace, NULL);
