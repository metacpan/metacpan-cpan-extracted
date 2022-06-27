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

#include "newOP_CUSTOM.c.inc"

#include "XSParseInfix.h"

enum Inop_Operator {
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

static OP *newop_in_str(pTHX_ U32 flags, OP *lhs, OP *rhs, void *hookdata)
{
  OP *ret = newBINOP_CUSTOM(&pp_in, 0, lhs, rhs);
  ret->op_private = INOP_STRING;

  return ret;
}

static OP *newop_in_num(pTHX_ U32 flags, OP *lhs, OP *rhs, void *hookdata)
{
  OP *ret = newBINOP_CUSTOM(&pp_in, 0, lhs, rhs);
  ret->op_private = INOP_NUMBER;

  return ret;
}

struct XSParseInfixHooks infix_elem_str = {
  .rhs_flags = XPI_OPERAND_TERM_LIST,
  .permit_hintkey = "Syntax::Operator::Elem/elem",
  .cls = 0,

  .wrapper_func_name = "Syntax::Operator::Elem::elem_str",

  .new_op = &newop_in_str,
};

struct XSParseInfixHooks infix_elem_num = {
  .rhs_flags = XPI_OPERAND_LIST,
  .permit_hintkey = "Syntax::Operator::Elem/elem",
  .cls = 0,

  .wrapper_func_name = "Syntax::Operator::Elem::elem_num",

  .new_op = &newop_in_num,
};

MODULE = Syntax::Operator::In    PACKAGE = Syntax::Operator::In

BOOT:
  boot_xs_parse_infix(0.16);

  register_xs_parse_infix("elem", &infix_elem_str, NULL);
  register_xs_parse_infix("∈",    &infix_elem_num, NULL);
