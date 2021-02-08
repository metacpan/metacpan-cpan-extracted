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

#ifndef cx_pushblock
#  include "cx_pushblock.c.inc"
#endif

#include "perl-backcompat.c.inc"

#include "perl-additions.c.inc"

static XOP xop_pushfinally;

static void invoke_finally(pTHX_ void *arg)
{
  OP *start = (OP *)arg;
  I32 was_cxstack_ix = cxstack_ix;

  cx_pushblock(CXt_BLOCK, G_VOID, PL_stack_sp, PL_savestack_ix);
  ENTER;
  SAVETMPS;

  SAVEOP();
  PL_op = start;

  CALLRUNOPS(aTHX);

  FREETMPS;
  LEAVE;

  {
    PERL_CONTEXT *cx = CX_CUR();

    /* restore stack height */
    PL_stack_sp = PL_stack_base + cx->blk_oldsp;
  }

  dounwind(was_cxstack_ix);
}

static OP *pp_pushfinally(pTHX)
{
  OP *finally = cLOGOP->op_other;

  SAVEDESTRUCTOR_X(&invoke_finally, finally);

  return PL_op->op_next;
}

static int finally_keyword(pTHX_ OP **op)
{
  lex_read_space(0);

  if(lex_peek_unichar(0) != '{')
    croak("Expected FINALLY to be followed by '{'");

  I32 save_ix = block_start(0);
  OP *body = parse_block(0);
  body = block_end(save_ix, body);

  lex_read_space(0);

  *op = newLOGOP_CUSTOM(&pp_pushfinally, 0,
    newOP(OP_NULL, 0), body);

  /* unlink the terminating condition of 'body' */
  body->op_next = NULL;

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
  XopENTRY_set(&xop_pushfinally, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_pushfinally, &xop_pushfinally);

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
