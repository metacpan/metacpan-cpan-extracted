/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "perl-backcompat.c.inc"

#include "newOP_CUSTOM.c.inc"
#include "BINOP_ANY.c.inc"

#include "XSParseInfix.h"

enum Inop_Operator {
  INOP_CUSTOM,
  INOP_NUMBER,
  INOP_STRING,
};

static OP *pp_in(pTHX)
{
  dSP;
  dMARK;
  SV **svp;
  enum Inop_Operator type = PL_op->op_private;

  OP cmpop;
  switch(type) {
    case INOP_CUSTOM:
      ANY *op_any = cBINOP_ANY->op_any;
      cmpop.op_type = OP_CUSTOM;
      cmpop.op_flags = 0;
      cmpop.op_ppaddr = op_any[0].any_ptr;
      break;

    case INOP_NUMBER:
      cmpop.op_type = OP_EQ;
      cmpop.op_flags = 0;
      cmpop.op_ppaddr = PL_ppaddr[OP_EQ];
      break;

    case INOP_STRING:
      cmpop.op_type = OP_SEQ;
      cmpop.op_flags = 0;
      cmpop.op_ppaddr = PL_ppaddr[OP_SEQ];
      break;
  }

  SV *lhs = *MARK;
  SV **listend = SP;

  SP = MARK - 1;
  PUTBACK;

  ENTER;
  SAVEVPTR(PL_op);
  PL_op = &cmpop;
  EXTEND(SP, 2);

  for(svp = MARK + 1; svp <= listend; svp++) {
    SV *rhs = *svp;

    PUSHs(lhs);
    PUSHs(rhs);
    PUTBACK;

    (*cmpop.op_ppaddr)(aTHX);

    SPAGAIN;

    SV *ret = POPs;

    if(SvTRUE(ret)) {
      LEAVE;

      PUSHs(&PL_sv_yes);
      RETURN;
    }
  }

  LEAVE;

  PUSHs(&PL_sv_no);
  RETURN;
}

#ifndef isIDCONT_utf8_safe
/* It doesn't really matter that this is not "safe", because the function is
 * only ever called on perls new enough to have PL_infix_plugin, and in that
 * case they'll have the _safe version anyway
 */
#  define isIDCONT_utf8_safe(s, e)  isIDCONT_utf8(s)
#endif

static void parse_in(pTHX_ U32 flags, SV **parsedata, void *hookdata)
{
  if(lex_peek_unichar(0) != '<')
    croak("Expected '<'");
  lex_read_unichar(0);

  lex_read_space(0);

  struct XSParseInfixInfo *info;
  if(!parse_infix(XPI_SELECT_EQUALITY, &info))
    croak("Expected an equality test operator");

  /* parsedata will be an AV containing
   *  [0] IV = enum Inop_Operator
   *  [1] UV = PTR to pp_addr if CUSTOM
   */
  AV *parsedata_av = newAV();
  *parsedata = newRV_noinc((SV *)parsedata_av);

  /* See if we got one of the core ones */
  if(info->opcode == OP_EQ) {
    av_push(parsedata_av, newSViv(INOP_NUMBER));
  }
  else if(info->opcode == OP_SEQ) {
    av_push(parsedata_av, newSViv(INOP_STRING));
  }
  else if(info->opcode == OP_CUSTOM) {
    if(info->hooks->new_op)
      croak("TODO: handle custom op using the new_op function for '%s'", info->opname);

    av_push(parsedata_av, newSViv(INOP_CUSTOM));
    av_push(parsedata_av, newSVuv(PTR2UV(info->hooks->ppaddr)));
  }
  else
    croak("Expected an equality test operator name but found '%s'", info->opname);

  if(lex_peek_unichar(0) != '>')
    croak("Expected '>'");
  lex_read_unichar(0);
}

static OP *newop_in(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata)
{
  AV *parsedata_av = AV_FROM_REF(*parsedata);

  enum Inop_Operator operator = SvIV(AvARRAY(parsedata_av)[0]);

  OP *ret;
  switch(operator) {
    case INOP_CUSTOM:
      ret = newBINOP_ANY_CUSTOM(&pp_in, 0, lhs, rhs, 1);
      cBINOP_ANYx(ret)->op_any[0].any_ptr = INT2PTR(void *, SvUV(AvARRAY(parsedata_av)[1]));
      ret->op_private = INOP_CUSTOM;
      break;

    case INOP_NUMBER:
    case INOP_STRING:
      ret = newBINOP_CUSTOM(&pp_in, 0, lhs, rhs);
      ret->op_private = operator;
      break;
  }

  return ret;
}

static OP *newop_in_str(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata)
{
  OP *ret = newBINOP_CUSTOM(&pp_in, 0, lhs, rhs);
  ret->op_private = INOP_STRING;

  return ret;
}

static OP *newop_in_num(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata)
{
  OP *ret = newBINOP_CUSTOM(&pp_in, 0, lhs, rhs);
  ret->op_private = INOP_NUMBER;

  return ret;
}

struct XSParseInfixHooks infix_in = {
  .cls            = XPI_CLS_MATCH_MISC,
  .rhs_flags      = XPI_OPERAND_LIST,
  .permit_hintkey = "Syntax::Operator::In/in",

  .parse = &parse_in,
  .new_op = &newop_in,
};

struct XSParseInfixHooks infix_elem_str = {
  .cls            = XPI_CLS_MATCH_MISC,
  .rhs_flags      = XPI_OPERAND_LIST,
  .permit_hintkey = "Syntax::Operator::Elem/elem",

  .wrapper_func_name = "Syntax::Operator::Elem::elem_str",

  .new_op = &newop_in_str,
};

struct XSParseInfixHooks infix_elem_num = {
  .cls            = XPI_CLS_MATCH_MISC,
  .rhs_flags      = XPI_OPERAND_LIST,
  .permit_hintkey = "Syntax::Operator::Elem/elem",

  .wrapper_func_name = "Syntax::Operator::Elem::elem_num",

  .new_op = &newop_in_num,
};

MODULE = Syntax::Operator::In    PACKAGE = Syntax::Operator::In

BOOT:
  boot_xs_parse_infix(0.27);

  register_xs_parse_infix("in", &infix_in, NULL);

  register_xs_parse_infix("elem", &infix_elem_str, NULL);
  register_xs_parse_infix("∈",    &infix_elem_num, NULL);
