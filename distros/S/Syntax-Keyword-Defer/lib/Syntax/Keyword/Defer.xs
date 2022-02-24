/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"

#ifndef cx_pushblock
#  include "cx_pushblock.c.inc"
#endif

#include "perl-additions.c.inc"
#include "forbid_outofblock_ops.c.inc"
#include "newOP_CUSTOM.c.inc"

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

static int build_defer(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  OP *body = arg0->op;

  forbid_outofblock_ops(body, "a defer block");

  *out = newLOGOP_CUSTOM(&pp_pushdefer, 0,
    newOP(OP_NULL, 0), body);

  /* unlink the terminating condition of 'body' */
  body->op_next = NULL;

  return KEYWORD_PLUGIN_STMT;
}

static const struct XSParseKeywordHooks hooks_defer = {
  .permit_hintkey = "Syntax::Keyword::Defer/defer",
  .piece1 = XPK_BLOCK,
  .build1 = &build_defer,
};

static const struct XSParseKeywordHooks hooks_finally = {
  .permit_hintkey = "Syntax::Keyword::Defer/finally",
  .piece1 = XPK_BLOCK,
  .build1 = &build_defer,
};

MODULE = Syntax::Keyword::Defer    PACKAGE = Syntax::Keyword::Defer

BOOT:
  XopENTRY_set(&xop_pushdefer, xop_name, "pushdefer");
  XopENTRY_set(&xop_pushdefer, xop_desc,
    "arrange for a CV to be invoked at scope exit");
  XopENTRY_set(&xop_pushdefer, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_pushdefer, &xop_pushdefer);

  boot_xs_parse_keyword(0.13);

  register_xs_parse_keyword("defer", &hooks_defer, NULL);
  register_xs_parse_keyword("FINALLY", &hooks_finally, NULL);
