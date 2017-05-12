#define PERL_NO_GET_CONTEXT 1
#ifdef WIN32
#  define NO_XSLOCKS
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#if (PERL_REVISION == 5 && PERL_VERSION < 14)
#include "callchecker0.h"
#endif

#if (PERL_REVISION == 5 && PERL_VERSION >= 10)
#  define GOT_CUR_TOP_ENV
#  ifndef PL_restartjmpenv
#    define PL_restartjmpenv    cxstack[cxstack_ix+1].blk_eval.cur_top_env
#  endif
#endif

#ifdef USE_ITHREADS
#  if (PERL_VERSION < 8) || (PERL_VERSION == 8 && PERL_SUBVERSION < 9)
#    define tTHX PerlInterpreter*
#  endif
#endif

#ifndef sv_dup_inc
#  define sv_dup_inc(s,t) SvREFCNT_inc(sv_dup(s,t))
#endif

#ifndef MUTABLE_AV
#  define MUTABLE_AV(p)   ((AV *)(void *)(p))
#endif

#ifndef PadlistARRAY
#  define PadlistARRAY(pad)  AvARRAY(pad)
#endif

#ifndef save_op
#  define save_op()     save_pushptr((void *)(PL_op), SAVEt_OP)
#endif

#ifndef save_pushptr
#  define save_pushptr(a,b) THX_save_pushptr(aTHX_ a, b)
void
THX_save_pushptr(pTHX_ void *const ptr, const int type)
{
    dVAR;
    SSCHECK(2);
    SSPUSHPTR(ptr);
    SSPUSHINT(type);
}
#endif

#ifndef cxinc
#  define cxinc()       THX_cxinc(aTHX)
/* Taken from scope.c */
I32
THX_cxinc(pTHX)
{
    dVAR;
    const IV old_max = cxstack_max;
    cxstack_max = cxstack_max + 1;
    Renew(cxstack, cxstack_max + 1, PERL_CONTEXT);
    /* Without any kind of initialising deep enough recursion
     * will end up reading uninitialised PERL_CONTEXTs. */
    PoisonNew(cxstack + old_max + 1, cxstack_max - old_max, PERL_CONTEXT);
    return cxstack_ix + 1;
}
#endif

#ifndef find_runcv
/* Perl 5.8.8 */
#define find_runcv(d) THX_find_runcv(aTHX_ d)
/* Taken from pp_ctl.c in 5.8.8 */
CV*
THX_find_runcv(pTHX_ U32 *db_seqp)
{
    PERL_SI      *si;

    if (db_seqp)
        *db_seqp = PL_curcop->cop_seq;
    for (si = PL_curstackinfo; si; si = si->si_prev) {
        I32 ix;
        for (ix = si->si_cxix; ix >= 0; ix--) {
            const PERL_CONTEXT *cx = &(si->si_cxstack[ix]);
            if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
                CV * const cv = cx->blk_sub.cv;
                /* skip DB:: code */
                if (db_seqp && PL_debstash && CvSTASH(cv) == PL_debstash) {
                    *db_seqp = cx->blk_oldcop->cop_seq;
                    continue;
                }
                return cv;
            }
            else if (CxTYPE(cx) == CXt_EVAL && !CxTRYBLOCK(cx))
                return PL_compcv;
        }
    }
    return PL_main_cv;
}
#endif /* find_runcv */

#ifndef LINKLIST
#    define LINKLIST(o) ((o)->op_next ? (o)->op_next : op_linklist((OP*)o))
#  ifndef op_linklist
#    define op_linklist(o) THX_linklist(aTHX_ o)
OP *
THX_linklist(pTHX_ OP *o)
{
    OP *first;

    if (o->op_next)
        return o->op_next;

    /* establish postfix order */
    first = cUNOPo->op_first;
    if (first) {
        OP *kid;
        o->op_next = LINKLIST(first);
        kid = first;
        for (;;) {
            if (kid->op_sibling) {
                kid->op_next = LINKLIST(kid->op_sibling);
                kid = kid->op_sibling;
            } else {
                kid->op_next = o;
                break;
            }
        }
    }
    else
        o->op_next = o;

    return o->op_next;
}
#  endif
#endif

#ifndef op_contextualize
#  define scalar(op) Perl_scalar(aTHX_ op)
#  define list(op) Perl_list(aTHX_ op)
#  define scalarvoid(op) Perl_scalarvoid(aTHX_ op)
# define op_contextualize(op, c) THX_op_contextualize(aTHX_ op, c)
OP *
THX_op_contextualize(pTHX_ OP *o, I32 context)
{
    switch (context) {
        case G_SCALAR: return scalar(o);
        case G_ARRAY:  return list(o);
        case G_VOID:   return scalarvoid(o);
        default:
            Perl_croak(aTHX_ "panic: op_contextualize bad context %ld",
                       (long) context);
            return o;
    }
}
#endif

#ifndef finalize_optree
#  define finalize_optree(o) THX_finalize_optree(aTHX_ o)
#  define finalize_op(o)     THX_finalize_op(aTHX_ o)

#if !defined(PAD_SETSV) || (defined(DEBUGGING) && !defined(pad_setsv))
/* Under DEBUGGING, PAD_SETSV is defined as pad_setsv(),
 * that's not part of the API.
 */
#  undef PAD_SETSV
#  define PAD_SETSV(ix, sv) PL_curpad[ix] = (sv)
#endif

#ifndef pad_alloc
 
#define pad_alloc(optype, tmptype) THX_pad_alloc(aTHX_ optype, tmptype)
 
STATIC PADOFFSET
THX_pad_alloc(pTHX_ I32 optype, U32 tmptype) {
    dVAR;
    SV *sv;
    I32 retval;
 
    PERL_UNUSED_ARG(optype);
    ASSERT_CURPAD_ACTIVE("pad_alloc");
 
    if (AvARRAY(PL_comppad) != PL_curpad)
        Perl_croak(aTHX_ "panic: pad_alloc");
    PL_pad_reset_pending = FALSE;
    if (tmptype & SVs_PADMY) {
        sv = *av_fetch(PL_comppad, AvFILLp(PL_comppad) + 1, TRUE);
        retval = AvFILLp(PL_comppad);
    }
    else {
        SV * const * const names = AvARRAY(PL_comppad_name);
        const SSize_t names_fill = AvFILLp(PL_comppad_name);
        for (;;) {
            if (++PL_padix <= names_fill &&
                (sv = names[PL_padix]) && sv != &PL_sv_undef)
                continue;
            sv = *av_fetch(PL_comppad, PL_padix, TRUE);
            if (!(SvFLAGS(sv) & (SVs_PADTMP | SVs_PADMY)) &&
                !IS_PADGV(sv) && !IS_PADCONST(sv))
                break;
        }
        retval = PL_padix;
    }
    SvFLAGS(sv) |= tmptype;
    PL_curpad = AvARRAY(PL_comppad);
 
#ifdef DEBUG_LEAKING_SCALARS
    sv->sv_debug_optype = optype;
    sv->sv_debug_inpad = 1;
#endif
    return (PADOFFSET)retval;
}
 
#endif

/* Lifted from op.c */
STATIC void
THX_finalize_op(pTHX_ OP* o)
{
    switch (o->op_type) {
    case OP_CONST:
#ifdef USE_ITHREADS
# ifdef OP_HINTSEVAL
    case OP_HINTSEVAL:
# endif
    case OP_METHOD_NAMED:
	/* Relocate sv to the pad for thread safety.
	 * Despite being a "constant", the SV is written to,
	 * for reference counts, sv_upgrade() etc. */
	if (cSVOPo->op_sv) {
	    const PADOFFSET ix = pad_alloc(OP_CONST, SVf_READONLY);
	    if (o->op_type != OP_METHOD_NAMED
		&& cSVOPo->op_sv == &PL_sv_undef) {
		/* PL_sv_undef is hack - it's unsafe to store it in the
		   AV that is the pad, because av_fetch treats values of
		   PL_sv_undef as a "free" AV entry and will merrily
		   replace them with a new SV, causing pad_alloc to think
		   that this pad slot is free. (When, clearly, it is not)
		*/
		SvOK_off(PAD_SVl(ix));
		SvPADTMP_on(PAD_SVl(ix));
		SvREADONLY_on(PAD_SVl(ix));
	    }
	    else {
		SvREFCNT_dec(PAD_SVl(ix));
		PAD_SETSV(ix, cSVOPo->op_sv);
		/* XXX I don't know how this isn't readonly already. */
		if (!SvIsCOW(PAD_SVl(ix))) SvREADONLY_on(PAD_SVl(ix));
	    }
	    cSVOPo->op_sv = NULL;
	    o->op_targ = ix;
	}
#endif
	break;
    case OP_HELEM: {
	SV *lexname;
	SV **svp, *sv;
	const char *key = NULL;
	STRLEN keylen;

	if (((BINOP*)o)->op_last->op_type != OP_CONST)
	    break;

	svp = cSVOPx_svp(((BINOP*)o)->op_last);
	if ((!SvIsCOW_shared_hash(sv = *svp))
	    && SvTYPE(sv) < SVt_PVMG && SvOK(sv) && !SvROK(sv)) {
	    key = SvPV_const(sv, keylen);
	    lexname = newSVpvn_share(key,
		SvUTF8(sv) ? -(I32)keylen : (I32)keylen,
		0);
		if (sv)
	        SvREFCNT_dec(sv);
	    *svp = lexname;
	}
	break;
    }
#if (PERL_REVISION == 5 && PERL_VERSION >= 10)
    case OP_SUBST: {
      if (cPMOPo->op_pmreplrootu.op_pmreplroot)
        finalize_op(cPMOPo->op_pmreplrootu.op_pmreplroot);
      break;
    }
#endif
    default:
        break;
    }

    if (o->op_flags & OPf_KIDS) {
        OP *kid;
        for (kid = cUNOPo->op_first; kid; kid = kid->op_sibling)
            finalize_op(kid);
    }
}

void
THX_finalize_optree(pTHX_ OP* o)
{
    ENTER;
    SAVEVPTR(PL_curcop);

    finalize_op(o);

    LEAVE;
}

#endif /* Perl_finalize_optree */

#define MY_CXT_KEY "Params::Lazy::_guts" XS_VERSION

#define hintkey     "Params::Lazy/no_caller_args"
#define hintkey_len  (sizeof(hintkey)-1)

typedef struct {
#ifdef USE_ITHREADS
 tTHX owner; /* The interpeter that owns the two below */
#endif                 /* These are the 'original' values for */
 SV*  orig_defav;      /* @_ */
 AV*  orig_comppad;    /* PL_comppad */
 COP* orig_curcop;     /* PL_curcop */
 I32  orig_cxstack_ix; /* cxstack_ix */
} my_cxt_t;

START_MY_CXT

typedef struct {
 OP *delayed;
#ifdef USE_ITHREADS
 AV *comppad;
 AV *comppad_name;
#endif
} delay_ctx;

STATIC int magic_free(pTHX_ SV *sv, MAGIC *mg)
{
  delay_ctx *ctx = (void *)mg->mg_ptr;
  OP* o = (OP*)ctx->delayed;
  PADOFFSET refcnt;

  PERL_UNUSED_ARG(sv);

  OP_REFCNT_LOCK;
  refcnt = OpREFCNT_dec(o);
  OP_REFCNT_UNLOCK;
  
  if (!refcnt) {
    /* o's refcount is 0, which means that no threads are 
     * running and we can free both the OP and the struct.
     */
#ifdef USE_ITHREADS
    /* XXX TODO this works. It probably shouldn't. */
    ENTER;
    SAVECOMPPAD();
    SAVESPTR(PL_comppad_name);
    PL_comppad_name = ctx->comppad_name;
    PL_comppad = ctx->comppad;
    PL_curpad  = AvARRAY(PL_comppad);
#endif
    op_free(o);
#ifdef USE_ITHREADS
    LEAVE;
#endif
    Safefree(ctx);
  }
  
  return 1;
}

#ifdef USE_ITHREADS
/* We need to up the op's refcount so that its only freed
 * when the main thread exits, assuming no threads were
 * left running.
 * No need to actually dup the struct or ctx->comppad, since
 * they are only used on the main thread.
 */
STATIC int magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *params)
{
  delay_ctx *ctx = (void *)mg->mg_ptr;
  OP* o = (OP*)ctx->delayed;
  
  PERL_UNUSED_ARG(params);
  
  OP_REFCNT_LOCK;
  (void)OpREFCNT_inc(o);
  OP_REFCNT_UNLOCK;
  
  return 0;
}
#endif

 
static MGVTBL vtbl = {
  NULL, /* get */
  NULL, /* set */
  NULL, /* len */
  NULL, /* clear */
  &magic_free,
#ifdef MGf_COPY
  NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
  &magic_dup,
# else
  NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
  NULL /* local */
#endif
};

#ifdef CXp_MULTICALL
#  define CX_BLOCK_FLAG CXp_MULTICALL
#else
#  define CX_BLOCK_FLAG CXp_TRYBLOCK
#endif

STATIC void
S_do_force(pTHX_ SV* sv, bool use_caller_args)
{
    dMY_CXT;
    dSP;
    dJMPENV;
    delay_ctx *ctx;
    const I32 gimme = GIMME_V;
    I32 i, oldscope;
    /* cx is the context the delayed expression will
     * be run in, delayer_cx is the context where the
     * expression was delayed.
     */
    PERL_CONTEXT *cx, *delayer_cx;
#ifndef GOT_CUR_TOP_ENV
    JMPENV *cur_top_env;
#endif
    IV retvals, before;
    int ret = 0;
    /* PL_curstack and PL_stack_sp in the delayed OPs */
    AV *delayed_curstack = NULL;
    SV **delayed_sp = NULL;
#ifndef CXp_SUB_RE
     /* XXX We play these CvDEPTH games in <5.18 to deal
      * with XS code calling Perl_croak() directly,
      * because the croak won't see the CXt_SUB of the
      * delayer's cx, and thus won't decrease its CvDEPTH
      */
    CV *runcv      = find_runcv(NULL);
    I32 orig_depth = CvDEPTH(runcv);
#endif

    if ( SvROK(sv) && SvMAGICAL(SvRV(sv)) ) {
        ctx  = (void *)SvMAGIC(SvRV(sv))->mg_ptr;
    }
    else {
        croak("force() requires a delayed argument");
    }
    
    SAVEOP();
    SAVECOMPPAD();
    save_pushptr((void *)PL_curcop, SAVEt_OP);

    if ( MY_CXT.orig_curcop ) {
        PL_curcop = MY_CXT.orig_curcop;
    }
    
    /* This is likely reading PoisonNew() crap when the
     * delayed argument is run in a different thread than
     * the one it was delayed in.  Probably harmless.
     */
    delayer_cx = &cxstack[MY_CXT.orig_cxstack_ix+1];

    SAVEINT(delayer_cx->cx_type);
    
#ifdef CXp_SUB_RE
    /* In >5.18, we can have find_runcv skip the delayer by
     * pretending to be a (?{}) sub.
     */
    delayer_cx->cx_type |= CXp_SUB_RE;
#else
    /* Tradeoff for older perls; makes
     * 'delay sub {$lexical}' work, but means we have to do
     * the runloop ourselves so we can manually restore the
     * value in a case-by-case basis to make a couple of
     * operations work properly; Those
     * include top-level caller(), and anything that
     * does a JMPENV, like exit, die, or goto.
     */
    delayer_cx->cx_type &= ~CXt_SUB;
#endif

#if (PERL_REVISION == 5 && PERL_VERSION >= 10)
    PUSHSTACKi(PERLSI_SORT);
#else
    PUSHSTACK;
#endif

    /* The SAVECOMPPAD and SAVEOP will restore these */
    PL_op      = ctx->delayed;
    
    if (MY_CXT.orig_comppad) {
        PL_comppad = MY_CXT.orig_comppad;
    }
    else {
        /* Untested, shouldn't happen? */
        Perl_croak(aTHX_ "Cannot restore the context for the delayed expression");
    }

    PL_curpad  = AvARRAY(PL_comppad);

    PUSHMARK(PL_stack_sp);
    
    before     = (IV)(PL_stack_sp-PL_stack_base);

    oldscope   = PL_scopestack_ix;
#ifndef GOT_CUR_TOP_ENV
    cur_top_env = PL_top_env;
#endif

    /* Disallow "delay goto &sub" and similar by pretending
     * to be a MULTICALL sub, or an eval block on 5.8.
     * This is required because of a possible regression in
     * perls 5.18 and newer, which caused it to segfault
     * because it wouldn't recognize us as outside of a sub.
     * "Possible" because it's more likely that it was never
     * supposed to work.
     */
    PUSHBLOCK(cx, CX_BLOCK_FLAG, PL_stack_sp);
    
    CX_CURPAD_SAVE(cx->blk_sub);
    
    /* Set up the proper @_ if requested */
    if (use_caller_args && MY_CXT.orig_defav) {
        AV *replaceav = MUTABLE_AV(SvRV(MY_CXT.orig_defav));
        SAVESPTR(GvAV(PL_defgv));
        SAVESPTR(CX_CURPAD_SV(cx->blk_sub, 0));
#ifdef CXp_HASARGS
        cx->cx_type         |= CXp_HASARGS;
#else
        cx->blk_sub.hasargs  = 1;
#endif
        cx->blk_sub.argarray = replaceav;
        GvAV(PL_defgv)       = replaceav;
        CX_CURPAD_SV(cx->blk_sub, 0) = (SV*)replaceav;
    }
    
    /* Call the deferred ops */
    /* Unfortunately we can't just do a CALLRUNOPS, since we must
     * handle the case of the delayed op being an eval, or a
     * pseudo-block with an eval inside, and that eval dying.
     */
    JMPENV_PUSH(ret);

    switch (ret) {
        case 0:
            {
            redo_body:
#ifdef CXp_SUB_RE
            CALLRUNOPS(aTHX);
#else
            /* See comments in the previous CXp_SUB_RE ifdef to see why
             * we do this.
             */
            while ((PL_op = PL_op->op_ppaddr(aTHX))) {
                /* XXX Is this missing anything? Is it necessary for exec? */
                switch ( PL_op->op_type ) {
                 case OP_GOTO:
                 case OP_DIE:
                 case OP_EXIT:
                 case OP_EXEC:
                 case OP_CALLER:
                    /* These ops need to know that the
                     * delayer is a subroutine, so restore
                     * cx_type.
                     */
                    delayer_cx->cx_type |= CXt_SUB;
                    break;
                 default:
                    /* Can't use SAVEINT() for the above, as
                     * caller() doesn't create a scope
                     * to automatically restore the value,
                     * so instead we manually unset this
                     * for every other op.
                     */
                    delayer_cx->cx_type &= ~CXt_SUB;
                    break;
                }
            }
#endif
            break;
            }
        case 3:
            /* If there's a PL_restartop, then this eval can handle
             * things on their own.
             */
            if (PL_restartop &&
#ifdef GOT_CUR_TOP_ENV
                PL_restartjmpenv == PL_top_env
#else
                cur_top_env      == PL_top_env
#endif
            ) {
#ifdef GOT_CUR_TOP_ENV
                PL_restartjmpenv = NULL;
#endif
                PL_op = PL_restartop;
                PL_restartop = 0;
                goto redo_body;
            }
            /* if there isn't, and the scopestack is out of sync,
             * then we need to intervene.
             */
            if ( PL_scopestack_ix >= oldscope ) {
                /* lazy eval { die }, lazy do { eval { die } } */
                /* Leave the eval */
                /* XXX TODO this doesn't quite work on 5.8 */
                LEAVE;
                break;
            }
#ifndef CXp_SUB_RE
            /* Something called Perl_croak() */
            /* XXX this likely needs a more precise test */
            if (   orig_depth > 0
                && orig_depth == CvDEPTH(runcv)) {
                CvDEPTH(runcv)--;
            }
#endif
            /* Fallthrough */
        default:
            /* Default behavior */
            JMPENV_POP;
            JMPENV_JUMP(ret);
    }
    JMPENV_POP;

    retvals = (IV)(PL_stack_sp-PL_stack_base);

    /* Keep a pointer to PL_curstack, and increase the
     * refcount so that it doesn't get freed in the
     * POPSTACK below.
     * Also keep a pointer to PL_stack_sp so we can copy
     * the values at the end.
     */
    if ( retvals && gimme != G_VOID ) {
        delayed_curstack = MUTABLE_AV(SvREFCNT_inc_simple_NN(PL_curstack));
        delayed_sp = PL_stack_sp;

        /* This has two uses.  First, it stops these from
         * being freed early after the FREETMPS/POPSTACK;
         * second, this is the ref we mortalize later,
         * with the mPUSHs
         */
        for (i = retvals; i > before; i--) {
            SvREFCNT_inc_simple_void_NN(*(PL_stack_sp-i+1));
        }
    }

    /* Lightweight POPBLOCK */
    cxstack_ix--;
    
    (void)POPMARK;
    POPSTACK;

    if ( gimme != G_VOID ) {
        if ( retvals ) {
            EXTEND(PL_stack_sp, retvals);
            
            for (i = retvals; i-- > before;) {
                *++PL_stack_sp = sv_2mortal(*(delayed_sp-i));
#ifdef USE_ITHREADS
                /* Makes this work:
                 * threads->create(sub { map { force $f } 1..5 })
                 * Since the map would reuse the same temp variable
                 */
                SvTEMP_off(*PL_stack_sp);
#endif
            }
            SvREFCNT_dec(delayed_curstack);
        }
        /* We don't have any return value, but in scalar context
         * we must return something, so push an undef to the stack.
         */
        else if ( gimme == G_SCALAR ) {
            EXTEND(PL_stack_sp, 1);
            *++PL_stack_sp = &PL_sv_undef;
        }
    }
    
}

/* pp_delay gets called *before* the entersub of a function with
 * delayed arguments, so it has the "original" @_ in scope.
 * This kludge allows us DTRT for a localized @_:
 *     local @_ = qw(foo bar); say delay shift @_;
 * will output "foo" and modify the correct @_.  Similarly,
 *     local *_ = \@foo; say delay shift;
 * will modify @foo as well as @_.
 *
 * The original cxstack and PL_comppad are also in scope,
 * and we need to save them to get some other things working
 * properly, like
 *     my $foo; sub { delay $foo .= "string" }->()
 */
STATIC OP*
S_pp_delay(pTHX)
{
    dMY_CXT;
    
    /* TODO these needs to be stored in the delayed argument
     * itself, not in the sub. See the skipped tests in
     * t/12-caller-args.t which would work if we did that
     */
    
    /* Save the original arguments */
    if ( PL_op->op_private ) {
        AV *defav  = GvAVn(PL_defgv);
        SAVESPTR(MY_CXT.orig_defav);
        
        if ( AvREAL(defav) ) {
            /* If @_ was localized */
            MY_CXT.orig_defav = newRV_noinc((SV*)GvAV(PL_defgv));
        }
        else if ( cxstack[cxstack_ix].blk_sub.argarray ) {
            MY_CXT.orig_defav = newRV_noinc(SvREFCNT_inc_simple_NN((SV*)cxstack[cxstack_ix].blk_sub.argarray));
        }
        else {
            MY_CXT.orig_defav = NULL;
        }
    }
    
    /* We use this to restore the context the ops were
     * originally running in */
    MY_CXT.orig_cxstack_ix = cxstack_ix;
    MY_CXT.orig_curcop     = PL_curcop;
    MY_CXT.orig_comppad    = PL_comppad;

    return NORMAL;
}

#ifndef cBOOL
#define cBOOL(cbool) ((cbool) ? (bool)1 : (bool)0)
#endif

STATIC OP*
S_pp_force(pTHX)
{
    SV *sv;
    bool use_caller_args = cBOOL(PL_op->op_private);
    PL_stack_sp--; /* The force() GV */
    sv = *PL_stack_sp--;
    
    ENTER;
    S_do_force(aTHX_ sv, use_caller_args);
    LEAVE;
    
    return NORMAL;
}

/* Returns true if we are to use the caller's args, false 
 * otherwise.
 */
STATIC bool
use_caller_args_hint(pTHX)
#define use_caller_args_hint() use_caller_args_hint(aTHX)
{
 dVAR;
 SV **val
  = hv_fetch(GvHV(PL_hintgv), hintkey, hintkey_len, FALSE);
 if (!val)
  return TRUE;

 if (!*val || !SvOK(*val)) return TRUE;

 /* If there's a value and it's true, then we *don't* want
  * to use the caller's args.
  */
 return !cBOOL(SvTRUE(*val));
}

STATIC OP *
replace_with_delayed(pTHX_ OP* aop) {
    MAGIC *mg;
    OP* new_op;
    OP* const kid = aop;
    OP* const sib = kid->op_sibling;
    SV* magic_sv  = newSVpvs("STATEMENT");
    OP *listop;
    delay_ctx *ctx;

    Newx(ctx, 1, delay_ctx);

    /* Disconnect the op we're delaying, then wrap it in
     * a OP_LIST
     */
    kid->op_sibling = 0;

    /* Make GIMME in the deferred op be OPf_WANT_LIST */
    op_contextualize(kid, G_ARRAY);
    
    listop = newLISTOP(OP_LIST, 0, kid, (OP*)NULL);
    LINKLIST(listop);

    /* Stop it from looping */
    cUNOPx(kid)->op_next = (OP*)NULL;

#ifdef PL_rpeepp
    /* XXX Might be overkill to call the peephole optimizer here? */
    PL_rpeepp(aTHX_ kid);
#endif
    
    /* XXX TODO: Calling this twice, once before the LINKLIST
     * and once after, solves a bug; namely, that "delay 1..10"
     * would fail an assertion, because calling list() on an
     * OP_LIST would call lintkids(), which in turn calls
     * gen_constant_list for this sort of expression, and
     * without the first list(), it confuses the range
     * with a flip-flop.
     * Obviously this is suboptimal and probably works by sheer
     * luck, so, FIXME
     */
    op_contextualize(listop, G_ARRAY);
    
    ctx->delayed = (OP*)listop;

    /* Make the delayed op thread-safe */
    finalize_optree(ctx->delayed);

    OP_REFCNT_LOCK;
    (void)OpREFCNT_set(ctx->delayed, 1);
    OP_REFCNT_UNLOCK;
    
#ifdef USE_ITHREADS
    ctx->comppad      = PL_comppad;
    ctx->comppad_name = PL_comppad_name;
#endif

    /* Magicalize the scalar, */
    mg = sv_magicext(magic_sv, (SV*)NULL, PERL_MAGIC_ext, &vtbl, (const char *)ctx, 0);

#ifdef USE_ITHREADS
    /* Enable dup magic */
    mg->mg_flags |= MGf_DUP;
#endif

    /* Then put that SV place of the OPs we removed, but wrap
     * as a ref.
     */
    new_op = (OP*)newSVOP(OP_CONST, 0, newRV_noinc(magic_sv));
    new_op->op_sibling = sib;
    return new_op;
}

static OP *
S_ck_force(pTHX_ OP *entersubop, GV *namegv, SV *cv)
{
    OP *aop, *prev, *first = NULL;
    UNOP *newop;

    ck_entersub_args_proto(entersubop, namegv, cv);

    aop = cUNOPx(entersubop)->op_first;
    if (!aop->op_sibling)
       aop = cUNOPx(aop)->op_first;
    prev = aop;
    aop = aop->op_sibling;
    first = aop;
    prev->op_sibling = first->op_sibling;
    first->op_flags &= ~OPf_MOD;
    aop = aop->op_sibling;
    
    if ( !aop ) {
        /* Not enough arguments for force() */
        return entersubop;
    }
    
    /* aop now points to the cvop */
    prev->op_sibling = aop->op_sibling;
    aop->op_sibling = NULL;
    first->op_sibling = aop;

    NewOp(1234, newop, 1, UNOP);
    newop->op_type    = OP_CUSTOM;
    newop->op_ppaddr  = S_pp_force;
    newop->op_first   = first;
    newop->op_private = use_caller_args_hint();
    newop->op_flags   = entersubop->op_flags;

    op_free(entersubop);

    return (OP *)newop;
}

STATIC OP *
THX_ck_delay(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    SV *proto            = newSVsv(ckobj);
    STRLEN protolen, len = 0;
    char * protopv       = SvPV(proto, protolen);
    OP *aop, *prev;

    PERL_UNUSED_ARG(namegv);
    
    aop = cUNOPx(entersubop)->op_first;
    
    if (!aop->op_sibling)
        aop = cUNOPx(aop)->op_first;
    
    prev = aop;
    
    for (aop = aop->op_sibling; aop->op_sibling; aop = aop->op_sibling) {
        if ( len < protolen ) {
            switch ( protopv[len] ) {
                case ':':
                    if ( aop->op_type == OP_REFGEN ) {
                        protopv[len] = '&';
                        break;
                    }
                    /* Fallthrough */
                case '^':
                {
                    aop = replace_with_delayed(aTHX_ aop);
                    prev->op_sibling = aop;
                    protopv[len] = '$';
                    break;
                }
            }
        }
        prev = aop;
        len++;
    }
    
    return ck_entersub_args_proto(entersubop, namegv, proto);
}

/* First applies the delay magic to the entersubop, then
 * adds one extra op to be run before the entersub itself
 * but after the arguments for it are in the stack
 */
STATIC OP *
THX_ck_delay_caller_args(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    OP* op = THX_ck_delay(aTHX_ entersubop, namegv, ckobj);
    UNOP *newop;
    OP *aop;
    
    aop = cUNOPx(op)->op_first;
    
    if (!aop->op_sibling)
        aop = cUNOPx(aop)->op_first;
    
    for (aop = aop->op_sibling; aop->op_sibling; aop = aop->op_sibling) {
    }
    
    NewOp(1234, newop, 1, UNOP);
    newop->op_type    = OP_CUSTOM;
    newop->op_ppaddr  = S_pp_delay;
    newop->op_private = use_caller_args_hint();
    
    aop->op_sibling = (OP*)newop;
    return op;
}

#ifdef USE_ITHREADS
STATIC SV*
clone_sv(pTHX_ SV* sv, tTHX owner)
#define clone_sv(s,v) clone_sv(aTHX_ (s), (v))
{
    CLONE_PARAMS param;
    param.stashes    = NULL;
    param.flags      = 0;
    param.proto_perl = owner;

    return sv_dup_inc(sv, &param);
}

#define clone_av(s,v) MUTABLE_AV(clone_sv((SV*)(s), (v)))
#endif /* USE_ITHREADS */

#ifdef XopENTRY_set
static XOP my_xop, my_wrapop;
#endif

MODULE = Params::Lazy		PACKAGE = Params::Lazy		

PROTOTYPES: ENABLE

void
cv_set_call_checker_delay(CV *cv, SV *proto)
CODE:
    cv_set_call_checker(cv, THX_ck_delay_caller_args, proto);

void
force(sv)
PROTOTYPE: $
PPCODE:
    SV *sv = *PL_stack_sp--;
    S_do_force(aTHX_ sv, use_caller_args_hint());
    SP = PL_stack_sp;

#ifdef USE_ITHREADS

void
CLONE(...)
INIT:
    SV *defav_clone = NULL;
    AV *comppad_clone = NULL;
CODE:
{
    PERL_UNUSED_ARG(items);
    {
        dMY_CXT;
        tTHX owner = MY_CXT.owner;
        
        if ( MY_CXT.orig_defav ) {
            SV *defavref = MY_CXT.orig_defav;
            AV *defav    = MUTABLE_AV(SvRV(defavref));
            defav_clone  = newRV_noinc((SV*)clone_av(defav, owner));
        }
        if ( MY_CXT.orig_comppad ) {
            comppad_clone = clone_av(MY_CXT.orig_comppad, owner);
        }
        /* not needed?
        if ( MY_CXT.orig_curcop ) {
            curcop_clone = (COP*)any_dup(MY_CXT.orig_curcop, owner);
        }
        */
    }
    {
        MY_CXT_CLONE;
        MY_CXT.orig_defav = defav_clone;
        MY_CXT.orig_comppad = comppad_clone;
        MY_CXT.owner      = aTHX;
    }
}

#endif /* USE_ITHREADS */


BOOT:
{
    CV * const cv = get_cvn_flags("Params::Lazy::force", 19, 0);
    MY_CXT_INIT;
    MY_CXT.orig_defav = NULL;
    MY_CXT.orig_comppad = NULL;
    MY_CXT.orig_curcop  = NULL;
    MY_CXT.orig_cxstack_ix = 0;
#ifdef USE_ITHREADS
    MY_CXT.owner = aTHX;
#endif
    cv_set_call_checker(cv, S_ck_force, (SV *)cv);
#ifdef XopENTRY_set
    XopENTRY_set(&my_xop, xop_name, "force");
    XopENTRY_set(&my_xop, xop_desc, "force");
    XopENTRY_set(&my_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ S_pp_force, &my_xop);
    
    XopENTRY_set(&my_wrapop, xop_name, "delay");
    XopENTRY_set(&my_wrapop, xop_desc, "delay");
    XopENTRY_set(&my_wrapop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ S_pp_delay, &my_wrapop);
#endif /* XopENTRY_set */
}

