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

static XOP xop_pushdefer;

static void invoke_defer(pTHX_ void *arg)
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

  /* It's too late to stop this forbidden condition, but at least we can print
   * why it happened and panic about it in a more controlled way than just
   * causing a segfault.
   */
  if(cxstack_ix != was_cxstack_ix + 1) {
    croak("panic: A non-local control flow operation exited a defer block");
  }

  {
    PERL_CONTEXT *cx = CX_CUR();

    /* restore stack height */
    PL_stack_sp = PL_stack_base + cx->blk_oldsp;
  }

  dounwind(was_cxstack_ix);
}

static OP *pp_pushdefer(pTHX)
{
  OP *defer = cLOGOP->op_other;

  SAVEDESTRUCTOR_X(&invoke_defer, defer);

  return PL_op->op_next;
}

static OP *pp_return_in_defer(pTHX)
{
  croak("Can't \"%s\" out of a defer block", PL_op_name[PL_op->op_type]);
}

static OP *pp_loopex_in_defer(pTHX)
{
  /* TODO: This might be safe, depending on the target.
   * Detect and allow the OK ones */
  croak("Can't \"%s\" out of a defer block", PL_op_name[PL_op->op_type]);
}

static OP *pp_goto_in_defer(pTHX)
{
  /* TODO: This might be safe, depending on the target.
   * Detect and allow the OK ones */
  croak("Can't \"%s\" out of a defer block", PL_op_name[PL_op->op_type]);
}

static void forbid_ops(OP *body);
static void forbid_ops(OP *body)
{
  if(body->op_type == OP_RETURN)
    body->op_ppaddr = &pp_return_in_defer;
  else if(body->op_type == OP_NEXT || body->op_type == OP_LAST || body->op_type == OP_REDO)
    body->op_ppaddr = &pp_loopex_in_defer;
  else if(body->op_type == OP_GOTO)
    body->op_ppaddr = &pp_goto_in_defer;

  if(!(body->op_flags & OPf_KIDS))
    return;

  OP *kid = cUNOPx(body)->op_first;
  while(kid) {
    forbid_ops(kid);
    kid = OpSIBLING(kid);
  }
}

static int defer_keyword(pTHX_ OP **op)
{
  lex_read_space(0);

  if(lex_peek_unichar(0) != '{')
    croak("Expected defer to be followed by '{'");

  I32 save_ix = block_start(0);
  OP *body = parse_block(0);
  body = block_end(save_ix, body);

  forbid_ops(body);

  lex_read_space(0);

  *op = newLOGOP_CUSTOM(&pp_pushdefer, 0,
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

  if(kwlen == 5 && strEQ(kw, "defer") &&
      hv_fetchs(hints, "Syntax::Keyword::Defer/defer", 0))
    return defer_keyword(aTHX_ op);

  if(kwlen == 7 && strEQ(kw, "FINALLY") &&
      hv_fetchs(hints, "Syntax::Keyword::Defer/finally", 0))
    /* FINALLY is really the same as defer */
    return defer_keyword(aTHX_ op);

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);
}

MODULE = Syntax::Keyword::Defer    PACKAGE = Syntax::Keyword::Defer

BOOT:
  XopENTRY_set(&xop_pushdefer, xop_name, "pushdefer");
  XopENTRY_set(&xop_pushdefer, xop_desc,
    "arrange for a CV to be invoked at scope exit");
  XopENTRY_set(&xop_pushdefer, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_pushdefer, &xop_pushdefer);

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
