/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "XSParseInfix.h"

#if !HAVE_PERL_VERSION(5, 16, 0)
#  define true  TRUE
#  define false FALSE
#endif

static OP *pp_zip(pTHX)
{
  dSP;
  int nlists = (PL_op->op_flags & OPf_STACKED) ? POPu : PL_op->op_private;

  /* Most invocations will only have 2 lists. We'll account for up to 4 as
   * local variables; anything bigger we'll allocate temporary SV buffers
   */
  U32 counts4[4];
  SV **svp4[4];

  U32 maxcount = 0;
  U32 *counts = nlists <= 4 ? counts4 : (U32 *)SvPVX(sv_2mortal(newSV(nlists * sizeof(U32))));
  for(int i = nlists; i > 0; i--) {
    U32 mark = POPMARK;
    U32 count = SP - (PL_stack_base + mark);
    counts[i-1] = count;
    if(count > maxcount)
      maxcount = count;

    SP = PL_stack_base + mark;
  }

  if(GIMME_V == G_VOID)
    return NORMAL;
  if(GIMME_V == G_SCALAR) {
    EXTEND(SP, 1);
    mPUSHi(maxcount);
    RETURN;
  }

  /* known G_LIST */

  /* No need to EXTEND because we know the stack will be big enough */
  PUSHMARK(SP);

  if(!maxcount)
    RETURN;

  SV ***svp = nlists <= 4 ? svp4 : (SV ***)SvPVX(sv_2mortal(newSV(nlists * sizeof(SV **))));
  svp[0] = SP + 1;
  for(int i = 1; i < nlists; i++)
    svp[i] = svp[i-1] + counts[i-1];

  bool more = true;
  do {
    more = false;
    AV *av = newAV();
    for(int i = 0; i < nlists; i++) {
      if(counts[i]) {
        av_push(av, newSVsv(*(svp[i])));
        svp[i]++, counts[i]--;

        if(counts[i])
          more = true;
      }
      else
        av_push(av, &PL_sv_undef);
    }
    mPUSHs(newRV_noinc((SV *)av));
  } while(more);

  RETURN;
}

static const struct XSParseInfixHooks infix_zip = {
  /* Parse this at ADD precedence, so that (LIST)xCOUNT can be used on RHS */
  .cls       = XPI_CLS_ADD_MISC,
  .flags     = XPI_FLAG_LISTASSOC,
  .lhs_flags = XPI_OPERAND_TERM_LIST|XPI_OPERAND_ONLY_LOOK,
  .rhs_flags = XPI_OPERAND_TERM_LIST|XPI_OPERAND_ONLY_LOOK,
  .permit_hintkey = "Syntax::Operator::Zip/Z",

  .wrapper_func_name = "Syntax::Operator::Zip::zip",

  .ppaddr = &pp_zip,
};

static OP *pp_mesh(pTHX)
{
  dSP;
  int nlists = (PL_op->op_flags & OPf_STACKED) ? POPu : PL_op->op_private;

  /* Most invocations will only have 2 lists. We'll account for up to 4 as
   * local variables; anything bigger we'll allocate temporary SV buffers
   */
  U32 counts4[4];
  SV **svp4[4];

  U32 maxcount = 0;
  U32 *counts = nlists <= 4 ? counts4 : (U32 *)SvPVX(sv_2mortal(newSV(nlists * sizeof(U32))));
  for(int i = nlists; i > 0; i--) {
    U32 mark = POPMARK;
    U32 count = SP - (PL_stack_base + mark);
    counts[i-1] = count;
    if(count > maxcount)
      maxcount = count;

    SP = PL_stack_base + mark;
  }

  U32 retcount = maxcount * nlists;

  if(GIMME_V == G_VOID)
    return NORMAL;
  if(GIMME_V == G_SCALAR) {
    EXTEND(SP, 1);
    mPUSHi(retcount);
    RETURN;
  }

  /* known G_LIST */
  EXTEND(SP, retcount);
  PUSHMARK(SP);

  if(!retcount)
    RETURN;

  SV ***svp = nlists <= 4 ? svp4 : (SV ***)SvPVX(sv_2mortal(newSV(nlists * sizeof(SV **))));
  svp[0] = SP + 1;
  for(int i = 1; i < nlists; i++)
    svp[i] = svp[i-1] + counts[i-1];

  /* We can't easily do this inplace so we'll have to store the result in a
   * temporary array
   */
  AV *tmpav = newAV();
  sv_2mortal((SV *)tmpav);
  av_extend(tmpav, retcount - 1);

  SV **result = AvARRAY(tmpav);

  bool more = true;
  do {
    more = false;
    for(int i = 0; i < nlists; i++) {
      if(counts[i]) {
        *result = sv_mortalcopy(*(svp[i]));
        svp[i]++, counts[i]--;

        if(counts[i])
          more = true;
      }
      else
        *result = &PL_sv_undef;
      result++;
    }
  } while(more);

  result = AvARRAY(tmpav);
  for(U32 i = 0; i < retcount; i++)
    PUSHs(*result++);

  AvREAL_off(tmpav); // AV shouldn't own the SVs
  RETURN;
}

static const struct XSParseInfixHooks infix_mesh = {
  .cls       = XPI_CLS_ADD_MISC,
  .flags     = XPI_FLAG_LISTASSOC,
  .lhs_flags = XPI_OPERAND_TERM_LIST|XPI_OPERAND_ONLY_LOOK,
  .rhs_flags = XPI_OPERAND_TERM_LIST|XPI_OPERAND_ONLY_LOOK,
  .permit_hintkey = "Syntax::Operator::Zip/M",

  .wrapper_func_name = "Syntax::Operator::Zip::mesh",

  .ppaddr = &pp_mesh,
};

MODULE = Syntax::Operator::Zip    PACKAGE = Syntax::Operator::Zip

BOOT:
  boot_xs_parse_infix(0.40);

  register_xs_parse_infix("Z", &infix_zip, NULL);
  register_xs_parse_infix("M", &infix_mesh, NULL);
