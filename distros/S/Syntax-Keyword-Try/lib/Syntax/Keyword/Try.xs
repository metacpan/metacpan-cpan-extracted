/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2016-2021 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"

#if HAVE_PERL_VERSION(5,32,0)
#  define HAVE_OP_ISA
#endif

#if HAVE_PERL_VERSION(5,26,0)
#  define HAVE_OP_SIBPARENT
#endif

#if HAVE_PERL_VERSION(5,19,4)
typedef SSize_t array_ix_t;
#else /* <5.19.4 */
typedef I32 array_ix_t;
#endif /* <5.19.4 */

#include "perl-additions.c.inc"
#include "optree-additions.c.inc"
#include "op_sibling_splice.c.inc"
#include "newOP_CUSTOM.c.inc"

static OP *pp_entertrycatch(pTHX);
static OP *pp_catch(pTHX);

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

    if(CxTYPE(&cxstack[cxix]) == CXt_EVAL && CxTRYBLOCK(&cxstack[cxix])) {
      /* If this CXt_EVAL frame came from our own ENTERTRYCATCH, then the
       * retop should point at an OP_CUSTOM and its first grand-child will be
       * our custom modified ENTERTRY. We can skip over it and continue in
       * this case.
       */
      OP *retop = cxstack[cxix].blk_eval.retop;
      OP *leave, *enter;
      if(retop->op_type == OP_CUSTOM && retop->op_ppaddr == &pp_catch &&
         (leave = cLOGOPx(retop)->op_first) && leave->op_type == OP_LEAVETRY &&
         (enter = cLOGOPx(leave)->op_first) && enter->op_type == OP_ENTERTRY &&
         enter->op_ppaddr == &pp_entertrycatch) {
        continue;
      }
      /* We have to stop at any other kind of CXt_EVAL */
      break;
    }
  }
  if(!cxix)
    croak("Unable to find an CXt_SUB to pop back to");

  I32 gimme = cxstack[cxix].blk_gimme;
  SV *retval;

  /* chunks of this code inspired by
   *   ZEFRAM/Scope-Escape-0.005/lib/Scope/Escape.xs
   */
  switch(gimme) {
    case G_VOID:
      (void)POPMARK;
      break;

    case G_SCALAR: {
      dSP;
      dMARK;
      retval = (MARK == SP) ? &PL_sv_undef : TOPs;
      SvREFCNT_inc(retval);
      sv_2mortal(retval);
      break;
    }

    case G_LIST: {
      dSP;
      dMARK;
      SV **retvals = MARK+1;
      array_ix_t retcount = SP-MARK;
      array_ix_t i;
      AV *retav = newAV();
      retval = (SV *)retav;
      sv_2mortal(retval);
      av_fill(retav, retcount-1);
      Copy(retvals, AvARRAY(retav), retcount, SV *);
      for(i = 0; i < retcount; i++)
        SvREFCNT_inc(retvals[i]);
      break;
    }
  }

  dounwind(cxix);

  /* Now put the value back */
  switch(gimme) {
    case G_VOID: {
      dSP;
      PUSHMARK(SP);
      break;
    }

    case G_SCALAR: {
      dSP;
      PUSHMARK(SP);
      XPUSHs(retval);
      PUTBACK;
      break;
    }

    case G_LIST: {
      dSP;
      PUSHMARK(SP);
      AV *retav = (AV *)retval;
      array_ix_t retcount = av_len(retav) + 1; /* because av_len means top index */
      EXTEND(SP, retcount);
      Copy(AvARRAY(retav), SP+1, retcount, SV *);
      SP += retcount;
      PUTBACK;
      break;
    }
  }

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

#define newLOCALISEOP(gv)  MY_newLOCALISEOP(aTHX_ gv)
static OP *MY_newLOCALISEOP(pTHX_ GV *gv)
{
  OP *op = newGVOP(OP_GVSV, 0, gv);
  op->op_private |= OPpLVAL_INTRO;
  return op;
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
  warning_bits[(2*WARN_EXITING) / 8] &= ~(1 << (2*WARN_EXITING % 8));

  return op;
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

    case OA_LISTOP:
      if(cLISTOPx(op)->op_last == old)
        cLISTOPx(op)->op_last = new;
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
#ifdef HAVE_OP_SIBPARENT
        OP *parent = OpHAS_SIBLING(op) ? NULL : op->op_sibparent;
#endif

        OP *stateop = newSTATEOP_nowarnings();

        OP *scope = newLISTOP(OP_SCOPE, 0,
          stateop, op);
#ifdef HAVE_OP_SIBPARENT
        if(parent)
          OpLASTSIB_set(scope, parent);
        else
          OpLASTSIB_set(scope, NULL);
#else
        op->op_sibling = NULL;
#endif

        /* Rethread */
        scope->op_next = stateop;
        stateop->op_next = op;

        *op_ptr = scope;
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

        if(next)
          OpMORESIB_set(newkid, next);
      }

      prev = kid;
    }
  }
}

static OP *pp_entertrycatch(pTHX)
{
  /* Localise the errgv */
  save_scalar(PL_errgv);

  return PL_ppaddr[OP_ENTERTRY](aTHX);
}

static XOP xop_catch;

static OP *pp_catch(pTHX)
{
  /* If an error didn't happen, then ERRSV will be both not true and not a
   * reference. If it's a reference, then an error definitely happened
   */
  if(SvROK(ERRSV) || SvTRUE(ERRSV))
    return cLOGOP->op_other;
  else
    return cLOGOP->op_next;
}

#define newENTERTRYCATCHOP(flags, try, catch)  MY_newENTERTRYCATCHOP(aTHX_ flags, try, catch)
static OP *MY_newENTERTRYCATCHOP(pTHX_ U32 flags, OP *try, OP *catch)
{
  OP *enter, *entertry, *ret;

  /* Walk the block for OP_RETURN ops, so we can apply a hack to them to
   * make
   *   try { return }
   * return from the containing sub, not just the eval block
   */
  walk_optree_try_in_eval(&try, try);

  enter = newUNOP(OP_ENTERTRY, 0, try);
  /* despite calling newUNOP(OP_ENTERTRY,...) the returned root node is the
   * OP_LEAVETRY, whose first child is the ENTERTRY we wanted
   */
  entertry = ((UNOP *)enter)->op_first;
  entertry->op_ppaddr = &pp_entertrycatch;

  /* If we call newLOGOP_CUSTOM it will op_contextualize the enter block into
   * G_SCALAR. This is not what we want
   */
  {
    LOGOP *logop;

    OP *first = enter, *other = newLISTOP(OP_SCOPE, 0, catch, NULL);

    NewOp(1101, logop, 1, LOGOP);

    logop->op_type = OP_CUSTOM;
    logop->op_ppaddr = &pp_catch;
    logop->op_first = first;
    logop->op_flags = OPf_KIDS;
    logop->op_other = LINKLIST(other);

    logop->op_next = LINKLIST(first);
    enter->op_next = (OP *)logop;
#if HAVE_PERL_VERSION(5, 22, 0)
    op_sibling_splice((OP *)logop, first, 0, other);
#else
    first->op_sibling = other;
#endif

    ret = newUNOP(OP_NULL, 0, (OP *)logop);
    other->op_next = ret;
  }

  return ret;
}

#ifndef HAVE_OP_ISA
static XOP xop_isa;

/* Totally stolen from perl 5.32.0's pp.c */
#define sv_isa_sv(sv, namesv)  S_sv_isa_sv(aTHX_ sv, namesv)
static bool S_sv_isa_sv(pTHX_ SV *sv, SV *namesv)
{
  if(!SvROK(sv) || !SvOBJECT(SvRV(sv)))
    return FALSE;

  /* TODO: ->isa invocation */

#if HAVE_PERL_VERSION(5,16,0)
  return sv_derived_from_sv(sv, namesv, 0);
#else
  return sv_derived_from(sv, SvPV_nolen(namesv));
#endif
}

static OP *pp_isa(pTHX)
{
  dSP;

  SV *left, *right;

  right = POPs;
  left  = TOPs;

  SETs(boolSV(sv_isa_sv(left, right)));
  RETURN;
}
#endif

static int build_try(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  U32 argi = 0;

  OP *try = args[argi++]->op;

  OP *ret = NULL;
  HV *hints = GvHV(PL_hintgv);

  bool require_var = hints && hv_fetchs(hints, "Syntax::Keyword::Try/require_var", 0);

  U32 ncatches = args[argi++]->i;

  AV *condcatch = NULL;
  OP *catch = NULL;
  while(ncatches--) {
    bool has_catchvar = args[argi++]->i;
    PADOFFSET catchvar = has_catchvar ? args[argi++]->padix : 0;
    int catchtype = has_catchvar ? args[argi++]->i : -1;

    bool warned = FALSE;

    OP *condop = NULL;

    switch(catchtype) {
      case -1: /* no type */
        break;

      case 0: /* isa */
      {
        OP *type = args[argi++]->op;
#ifdef HAVE_OP_ISA
        condop = newBINOP(OP_ISA, 0,
          newPADxVOP(OP_PADSV, catchvar, 0, 0), type);
#else
        /* Allow a bareword on RHS of `isa` */
        if(type->op_type == OP_CONST)
          type->op_private &= ~(OPpCONST_BARE|OPpCONST_STRICT);

        condop = newBINOP_CUSTOM(&pp_isa, 0,
          newPADxVOP(OP_PADSV, catchvar, 0, 0), type);
#endif
        break;
      }

      case 1: /* =~ */
      {
        OP *regexp = args[argi++]->op;

        if(regexp->op_type != OP_MATCH || cPMOPx(regexp)->op_first)
          croak("Expected a regexp match");
#if HAVE_PERL_VERSION(5,22,0)
        /* Perl 5.22+ uses op_targ on OP_MATCH directly */
        regexp->op_targ = catchvar;
#else
        /* Older perls need a stacked OP_PADSV op */
        cPMOPx(regexp)->op_first = newPADxVOP(OP_PADSV, catchvar, 0, 0);
        regexp->op_flags |= OPf_KIDS|OPf_STACKED;
#endif
        condop = regexp;
        break;
      }

      default:
        croak("TODO\n");
    }

#ifdef WARN_EXPERIMENTAL
    if(condop && !warned &&
      (!hints || !hv_fetchs(hints, "Syntax::Keyword::Try/experimental(typed)", 0))) {
      warned = true;
      Perl_ck_warner(aTHX_ packWARN(WARN_EXPERIMENTAL),
        "typed catch syntax is experimental and may be changed or removed without notice");
    }
#endif

    OP *body = args[argi++]->op;

    if(require_var && !has_catchvar)
      croak("Expected (VAR) for catch");

    if(catch)
      croak("Already have a default catch {} block");

    OP *assignop = NULL;
    if(catchvar) {
      /* my $var = $@ */
      assignop = newBINOP(OP_SASSIGN, 0,
        newGVOP(OP_GVSV, 0, PL_errgv), newPADxVOP(OP_PADSV, catchvar, OPf_MOD, OPpLVAL_INTRO));
    }

    if(condop) {
      if(!condcatch)
        condcatch = newAV();

      av_push(condcatch, (SV *)op_append_elem(OP_LINESEQ, assignop, condop));
      av_push(condcatch, (SV *)body);
      /* catch remains NULL for now */
    }
    else if(assignop) {
      catch = op_prepend_elem(OP_LINESEQ,
        assignop, body);
    }
    else
      catch = body;
  }

  if(condcatch) {
    I32 i;

    if(!catch)
      /* A default fallthrough */
      /*   die $@ */
      catch = newLISTOP(OP_DIE, 0,
        newOP(OP_PUSHMARK, 0), newGVOP(OP_GVSV, 0, PL_errgv));

    for(i = AvFILL(condcatch)-1; i >= 0; i -= 2) {
      OP *body   = (OP *)av_pop(condcatch),
         *condop = (OP *)av_pop(condcatch);

      catch = newCONDOP(0, condop, op_scope(body), catch);
    }

    SvREFCNT_dec(condcatch);
  }

  bool no_finally = hints && hv_fetchs(hints, "Syntax::Keyword::Try/no_finally", 0);

  U32 has_finally = args[argi++]->i;
  CV *finally = has_finally ? args[argi++]->cv : NULL;

  if(no_finally && finally)
    croak("finally {} is not permitted here");

  if(!catch && !finally) {
    op_free(try);
    croak(no_finally
      ? "Expected try {} to be followed by catch {}"
      : "Expected try {} to be followed by either catch {} or finally {}");
  }

  ret = try;

  if(catch) {
    ret = newENTERTRYCATCHOP(0, try, catch);
  }

  /* If there's a finally, make
   *   $RET = OP_PUSHFINALLY($FINALLY); $RET
   */
  if(finally) {
    ret = op_prepend_elem(OP_LINESEQ,
      newSVOP_CUSTOM(&pp_pushfinally, 0, (SV *)finally),
      ret);
  }

  ret = op_append_list(OP_LEAVE,
    newOP(OP_ENTER, 0),
    ret);

  *out = ret;
  return KEYWORD_PLUGIN_STMT;
}

static struct XSParseKeywordHooks hooks_try = {
  .permit_hintkey = "Syntax::Keyword::Try/try",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_BLOCK,
    XPK_REPEATED(
      XPK_LITERAL("catch"),
      XPK_PREFIXED_BLOCK(
        /* optionally ($var), ($var isa Type) or ($var =~ m/.../) */
        XPK_PARENSCOPE_OPT(
          XPK_LEXVAR_MY(XPK_LEXVAR_SCALAR),
          XPK_CHOICE(
            XPK_SEQUENCE(XPK_LITERAL("isa"), XPK_TERMEXPR),
            XPK_SEQUENCE(XPK_LITERAL("=~"), XPK_TERMEXPR)
          )
        )
      )
    ),
    XPK_OPTIONAL(
      XPK_LITERAL("finally"), XPK_ANONSUB
    ),
    {0},
  },
  .build = &build_try,
};

MODULE = Syntax::Keyword::Try    PACKAGE = Syntax::Keyword::Try

BOOT:
  XopENTRY_set(&xop_catch, xop_name, "catch");
  XopENTRY_set(&xop_catch, xop_desc,
    "optionally invoke the catch block if required");
  XopENTRY_set(&xop_catch, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_catch, &xop_catch);

  XopENTRY_set(&xop_pushfinally, xop_name, "pushfinally");
  XopENTRY_set(&xop_pushfinally, xop_desc,
    "arrange for a CV to be invoked at scope exit");
  XopENTRY_set(&xop_pushfinally, xop_class, OA_SVOP);
  Perl_custom_op_register(aTHX_ &pp_pushfinally, &xop_pushfinally);
#ifndef HAVE_OP_ISA
  XopENTRY_set(&xop_isa, xop_name, "isa");
  XopENTRY_set(&xop_isa, xop_desc,
    "check if a value is an object of the given class");
  XopENTRY_set(&xop_isa, xop_class, OA_BINOP);
  Perl_custom_op_register(aTHX_ &pp_isa, &xop_isa);
#endif

  boot_xs_parse_keyword(0.06);

  register_xs_parse_keyword("try", &hooks_try, NULL);
