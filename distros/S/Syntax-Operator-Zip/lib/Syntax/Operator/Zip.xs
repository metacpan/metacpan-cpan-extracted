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

#include "XSParseInfix.h"

static OP *pp_zip(pTHX)
{
  dSP;
  U32 rhs_mark = POPMARK;
  U32 lhs_mark = POPMARK;

  U32 rhs_count = SP - (PL_stack_base + rhs_mark);
  U32 lhs_count = rhs_mark - lhs_mark;

  SP = PL_stack_base + lhs_mark;

  if(GIMME_V == G_VOID)
    return NORMAL;
  if(GIMME_V == G_SCALAR) {
    int count = 0;
    if(lhs_count > count)
      count = lhs_count;
    if(rhs_count > count)
      count = rhs_count;
    EXTEND(SP, 1);
    mPUSHi(count);
    RETURN;
  }

  /* known G_LIST */

  /* No need to EXTEND because we know the stack will be big enough */
  PUSHMARK(SP);

  SV **lhs = PL_stack_base + lhs_mark + 1;
  SV **rhs = PL_stack_base + rhs_mark + 1;
  SV **lhs_stop = lhs + lhs_count;
  SV **rhs_stop = rhs + rhs_count;

  while(lhs < lhs_stop || rhs < rhs_stop) {
    AV *av = newAV();

    if(lhs < lhs_stop)
      av_push(av, newSVsv(*lhs++));
    else
      av_push(av, &PL_sv_undef);

    if(rhs < rhs_stop)
      av_push(av, newSVsv(*rhs++));
    else
      av_push(av, &PL_sv_undef);

    mPUSHs(newRV_noinc((SV *)av));
  }

  RETURN;
}

struct XSParseInfixHooks infix_zip = {
  .lhs_flags = XPI_OPERAND_TERM_LIST|XPI_OPERAND_ONLY_LOOK,
  .rhs_flags = XPI_OPERAND_TERM_LIST|XPI_OPERAND_ONLY_LOOK,
  .permit_hintkey = "Syntax::Operator::Zip/Z",
  .cls = 0,

  .wrapper_func_name = "Syntax::Operator::Zip::zip",

  .ppaddr = &pp_zip,
};

static OP *pp_mesh(pTHX)
{
  dSP;
  U32 rhs_mark = POPMARK;
  U32 lhs_mark = POPMARK;

  U32 rhs_count = SP - (PL_stack_base + rhs_mark);
  U32 lhs_count = rhs_mark - lhs_mark;

  int count = 0;
  if(lhs_count > count)
    count = lhs_count;
  if(rhs_count > count)
    count = rhs_count;

  SP = PL_stack_base + lhs_mark;

  if(GIMME_V == G_VOID)
    return NORMAL;
  if(GIMME_V == G_SCALAR) {
    EXTEND(SP, 1);
    mPUSHi(count * 2);
    RETURN;
  }

  /* known G_LIST */
  EXTEND(SP, count * 2);
  PUSHMARK(SP);

  SV **lhs = PL_stack_base + lhs_mark + 1;
  SV **rhs = PL_stack_base + rhs_mark + 1;

  /* We can't easily do this inplace so we'll have to store the LHS values
   * in a temporary array
   */
  AV *tmpav = newAV();
  SAVEFREESV(tmpav);
  av_extend(tmpav, lhs_count - 1);

  Copy(lhs, AvARRAY(tmpav), lhs_count, SV *);

  lhs = AvARRAY(tmpav);

  /* If the LHS list was too small, we'll have to move up the RHS list so we
   * don't trash it too early
   */
  if(lhs_count < rhs_count) {
    U32 offset = rhs_count - lhs_count;
    Move(rhs, rhs + offset, rhs_count, SV *);
    rhs += offset;
  }

  SV **lhs_stop = lhs + lhs_count;
  SV **rhs_stop = rhs + rhs_count;

  while(lhs < lhs_stop || rhs < rhs_stop) {
    if(lhs < lhs_stop)
      mPUSHs(newSVsv(*lhs++));
    else
      PUSHs(&PL_sv_undef);

    if(rhs < rhs_stop)
      mPUSHs(newSVsv(*rhs++));
    else
      PUSHs(&PL_sv_undef);
  }

  RETURN;
}

struct XSParseInfixHooks infix_mesh = {
  .lhs_flags = XPI_OPERAND_TERM_LIST|XPI_OPERAND_ONLY_LOOK,
  .rhs_flags = XPI_OPERAND_TERM_LIST|XPI_OPERAND_ONLY_LOOK,
  .permit_hintkey = "Syntax::Operator::Zip/Z",
  .cls = 0,

  .wrapper_func_name = "Syntax::Operator::Zip::mesh",

  .ppaddr = &pp_mesh,
};

MODULE = Syntax::Operator::Zip    PACKAGE = Syntax::Operator::Zip

BOOT:
  boot_xs_parse_infix(0.18);

  register_xs_parse_infix("Z", &infix_zip, NULL);
  register_xs_parse_infix("M", &infix_mesh, NULL);
