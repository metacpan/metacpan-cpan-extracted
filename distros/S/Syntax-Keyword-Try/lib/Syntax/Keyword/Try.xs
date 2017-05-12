#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Before perl 5.22 these were not visible */

#ifndef clone_cv
#define cv_clone(a)            Perl_cv_clone(aTHX_ a)
#endif

#ifndef block_end
#define block_end(a,b)         Perl_block_end(aTHX_ a,b)
#endif

#ifndef block_start
#define block_start(a)         Perl_block_start(aTHX_ a)
#endif

#ifndef OpSIBLING
#define OpSIBLING(op)          (op->op_sibling)
#endif

#ifndef OpMORESIB_set
#define OpMORESIB_set(op,sib)  ((op)->op_sibling = (sib))
#endif

/*
 * A modified version of pp_return for returning from inside a try block.
 * To do this, we unwind the context stack to just past the CXt_EVAL and then
 * chain to the regular OP_RETURN func
 */
static OP *pp_returnintry(pTHX)
{
  I32 cxix;
  for (cxix = cxstack_ix; cxix; cxix--) {
    if(CxTYPE(&cxstack[cxix]) == CXt_SUB)
      break;
  }
  if(!cxix)
    croak("Unable to find an CXt_SUB to pop back to");

  dounwind(cxix);

  return PL_ppaddr[OP_RETURN](aTHX);
}

/*
 * A custom SVOP that takes a CV and arranges for it to be invoked on scope
 * leave
 */
static XOP xop_pushfinally;

static void invoke_finally(pTHX_ void *arg)
{
  CV *finally = arg;
  dSP;

  if(CvCLONE(finally))
    /* finally is a closure protosub; we have to clone it into a real sub */
    finally = (CV *)sv_2mortal((SV *)cv_clone(finally));

  PUSHMARK(SP);
  call_sv((SV *)finally, G_DISCARD|G_EVAL|G_KEEPERR);
}

static OP *pp_pushfinally(pTHX)
{
  SAVEDESTRUCTOR_X(&invoke_finally, cSVOP->op_sv);
  return PL_op->op_next;
}

#define newPUSHFINALLYOP(finally)  MY_newPUSHFINALLYOP(aTHX_ finally)
static OP *MY_newPUSHFINALLYOP(pTHX_ CV *finally)
{
  OP *op = newSVOP(OP_CUSTOM, 0, (SV *)finally);
  op->op_ppaddr = &pp_pushfinally;
  return op;
}

#define newLOCALISEOP(gv)  MY_newLOCALISEOP(aTHX_ gv)
static OP *MY_newLOCALISEOP(pTHX_ GV *gv)
{
  OP *op = newGVOP(OP_GVSV, 0, gv);
  op->op_private |= OPpLVAL_INTRO;
  return op;
}

#define lex_consume(s)  MY_lex_consume(aTHX_ s)
static int MY_lex_consume(pTHX_ char *s)
{
  /* I want strprefix() */
  size_t i;
  for(i = 0; s[i]; i++) {
    if(s[i] != PL_parser->bufptr[i])
      return 0;
  }

  lex_read_to(PL_parser->bufptr + i);
  return i;
}

#define newSTATEOP_nowarnings()  MY_newSTATEOP_nowarnings(aTHX)
static OP *MY_newSTATEOP_nowarnings(pTHX)
{
  OP *op = newSTATEOP(0, NULL, NULL);
  STRLEN *warnings = ((COP *)op)->cop_warnings;
  char *warning_bits;

  if(warnings == pWARN_NONE)
    return op;

  if(warnings == pWARN_STD)
    /* TODO: understand what STD vs ALL means */
    warning_bits = WARN_ALLstring;
  else if(warnings == pWARN_ALL)
    warning_bits = WARN_ALLstring;
  else
    warning_bits = (char *)(warnings + 1);

  warnings = Perl_new_warnings_bitfield(aTHX_ warnings, warning_bits, WARNsize);
  ((COP *)op)->cop_warnings = warnings;

  warning_bits = (char *)(warnings + 1);
  warning_bits[Off(2*WARN_EXITING)] &= ~Bit(2*WARN_EXITING);

  return op;
}

#define parse_scoped_block(flags)  MY_parse_scoped_block(aTHX_ flags)
static OP *MY_parse_scoped_block(pTHX_ int flags)
{
  OP *ret;
  I32 save_ix = block_start(TRUE);
  ret = parse_block(flags);
  return block_end(save_ix, ret);
}

static void rethread_op(OP *op, OP *old, OP *new)
{
  if(op->op_next == old)
    op->op_next = new;

  switch(OP_CLASS(op)) {
    case OA_LOGOP:
      if(cLOGOPx(op)->op_other == old)
        cLOGOPx(op)->op_other = new;
      break;
  }

  if(op->op_flags & OPf_KIDS) {
    OP *kid;
    for(kid = cUNOPx(op)->op_first; kid; kid = OpSIBLING(kid))
      rethread_op(kid, old, new);
  }
}

#define walk_optree_try_in_eval(op_ptr, root)  MY_walk_optree_try_in_eval(aTHX_ op_ptr, root)
static void MY_walk_optree_try_in_eval(pTHX_ OP **op_ptr, OP *root);
static void MY_walk_optree_try_in_eval(pTHX_ OP **op_ptr, OP *root)
{
  OP *op = *op_ptr;

  switch(op->op_type) {
    /* Fix 'return' to unwind the CXt_EVAL block that implements try{} first */
    case OP_RETURN:
      op->op_ppaddr = &pp_returnintry;
      break;

    /* wrap  no warnings 'exiting' around loop controls */
    case OP_NEXT:
    case OP_LAST:
    case OP_REDO:
      {
        OP *stateop;

        if(OpSIBLING(op))
          croak("ARGH: Unsure how to handle OP_(NEXT|LAST|REDO) with a sibling");

        *op_ptr = newLISTOP(OP_SCOPE, 0,
          stateop = newSTATEOP_nowarnings(),
          op);

        (*op_ptr)->op_next = stateop;
        stateop->op_next = op;
      }
      break;

    /* Don't enter inside nested eval{} blocks */
    case OP_LEAVETRY:
      return;
  }

  if(op->op_flags & OPf_KIDS) {
    OP *kid, *next, *prev = NULL;
    for(kid = cUNOPx(op)->op_first; kid; kid = next) {
      OP *newkid = kid;
      next = OpSIBLING(kid);

      walk_optree_try_in_eval(&newkid, root);

      if(newkid != kid) {
        rethread_op(root, kid, newkid);

        if(prev) {
          OpMORESIB_set(prev, newkid);
        }
        else
          cUNOPx(op)->op_first = newkid;

        OpMORESIB_set(newkid, next);
      }

      prev = kid;
    }
  }
}

static int try_keyword(pTHX_ OP **op)
{
  OP *try = NULL, *catch = NULL;
  CV *finally = NULL;

  lex_read_space(0);

  if(lex_peek_unichar(0) != '{')
    croak("Expected try be followed by '{'");

  try = parse_scoped_block(0);
  lex_read_space(0);

  if(lex_consume("catch")) {
    lex_read_space(0);
    catch = parse_scoped_block(0);
    lex_read_space(0);
  }

  if(lex_consume("finally")) {
    lex_read_space(0);

    I32 floor_ix = start_subparse(FALSE, CVf_ANON);
    SAVEFREESV(PL_compcv);

    I32 save_ix = block_start(0);
    OP *body = parse_block(0);
    SvREFCNT_inc(PL_compcv);
    body = block_end(save_ix, body);

    finally = newATTRSUB(floor_ix, NULL, NULL, NULL, body);

    lex_read_space(0);
  }

  if(!catch && !finally) {
    op_free(try);
    croak("Expected try {} to be followed by either catch {} or finally {}");
  }

  OP *ret = try;

  /* If there's a catch block, make
   *   $RET = eval { $TRY; 1 } or do { $CATCH }
   */

  if(catch) {
    /* Walk the block for OP_RETURN ops, so we can apply a hack to them to
     * make
     *   try { return }
     * return from the containing sub, not just the eval block
     */
    walk_optree_try_in_eval(&try, try);

    ret = newLOGOP(OP_OR, 0,
      newUNOP(OP_ENTERTRY, 0,
        op_append_elem(OP_LINESEQ,
          try,
          newSVOP(OP_CONST, 0, &PL_sv_yes)
        )
      ),
      newLISTOP(OP_SCOPE, 0, catch, NULL)
    );

    /* localise $@ beforehand */
    ret = op_prepend_elem(OP_LINESEQ, newLOCALISEOP(PL_errgv), ret);
  }

  /* If there's a finally, make
   *   $RET = OP_PUSHFINALLY($FINALLY); $RET
   */
  if(finally) {
     ret = op_prepend_elem(OP_LINESEQ, newPUSHFINALLYOP(finally), ret);
  }

  /* If there's either catch or finally, block-wrap the result
   */
  if(catch || finally) {
    ret = newLISTOP(OP_LEAVE, 0,
      op_prepend_elem(OP_LINESEQ, newOP(OP_ENTER, 0), ret),
      NULL);
  }

  *op = ret;
  return KEYWORD_PLUGIN_STMT;
}

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op)
{
  if(PL_parser && PL_parser->error_count)
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);

  HV *hints;
  if(!(hints = GvHV(PL_hintgv)))
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);

  if(kwlen == 3 && strEQ(kw, "try") &&
      hv_fetchs(hints, "Syntax::Keyword::Try/try", 0))
    return try_keyword(aTHX_ op);

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);
}

MODULE = Syntax::Keyword::Try    PACKAGE = Syntax::Keyword::Try

BOOT:
  next_keyword_plugin = PL_keyword_plugin;
  PL_keyword_plugin = &my_keyword_plugin;

  XopENTRY_set(&xop_pushfinally, xop_name, "pushfinally");
  XopENTRY_set(&xop_pushfinally, xop_desc,
    "arrange for a CV to be invoked at scope exit");
  XopENTRY_set(&xop_pushfinally, xop_class, OA_SVOP);
  Perl_custom_op_register(aTHX_ &pp_pushfinally, &xop_pushfinally);
