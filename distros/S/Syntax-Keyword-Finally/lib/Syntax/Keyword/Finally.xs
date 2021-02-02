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

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

#include "perl-backcompat.c.inc"

#include "perl-additions.c.inc"

static XOP xop_pushfinally;

static void invoke_finally(pTHX_ void *arg)
{
  CV *finally = arg;
  dSP;

  PUSHMARK(SP);
  call_sv((SV *)finally, G_DISCARD|G_EVAL|G_KEEPERR);

  SvREFCNT_dec(finally);
}

static OP *pp_pushfinally(pTHX)
{
  CV *finally = (CV *)cSVOP->op_sv;

  /* finally is a closure protosub; we have to clone it into a real sub.
   * If we do this now then captured lexicals still work even around
   * Future::AsyncAwait (see RT122796)
   * */
  SAVEDESTRUCTOR_X(&invoke_finally, (SV *)cv_clone(finally));
  return PL_op->op_next;
}

#define newPUSHFINALLYOP(finally)  MY_newPUSHFINALLYOP(aTHX_ finally)
static OP *MY_newPUSHFINALLYOP(pTHX_ CV *finally)
{
  OP *op = newSVOP_CUSTOM(0, (SV *)finally);
  op->op_ppaddr = &pp_pushfinally;
  return (OP *)op;
}

static int finally_keyword(pTHX_ OP **op)
{
  lex_read_space(0);

  if(lex_peek_unichar(0) != '{')
    croak("Expected try to be followed by '{'");

  I32 floor_ix = start_subparse(FALSE, CVf_ANON);
  SAVEFREESV(PL_compcv);

  I32 save_ix = block_start(0);
  OP *body = parse_block(0);
  SvREFCNT_inc(PL_compcv);
  body = block_end(save_ix, body);

  lex_read_space(0);

  *op = newPUSHFINALLYOP(newATTRSUB(floor_ix, NULL, NULL, NULL, body));

  return KEYWORD_PLUGIN_STMT;
}

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op)
{
  HV *hints;
  if(PL_parser && PL_parser->error_count)
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);

  if(!(hints = GvHV(PL_hintgv)))
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);

  if(kwlen == 7 && strEQ(kw, "FINALLY") &&
      hv_fetchs(hints, "Syntax::Keyword::Finally/finally", 0))
    return finally_keyword(aTHX_ op);

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);
}

MODULE = Syntax::Keyword::Finally    PACKAGE = Syntax::Keyword::Finally

BOOT:
  XopENTRY_set(&xop_pushfinally, xop_name, "pushfinally");
  XopENTRY_set(&xop_pushfinally, xop_desc,
    "arrange for a CV to be invoked at scope exit");
  XopENTRY_set(&xop_pushfinally, xop_class, OA_SVOP);
  Perl_custom_op_register(aTHX_ &pp_pushfinally, &xop_pushfinally);

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
