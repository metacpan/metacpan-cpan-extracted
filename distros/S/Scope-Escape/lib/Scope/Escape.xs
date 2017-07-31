#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "callchecker0.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef cBOOL
# define cBOOL(x) ((bool)!!(x))
#endif /* !cBOOL */

#ifndef CvISXSUB
# define CvISXSUB(cv) (cBOOL(CvXSUB(cv)))
#endif /* !CvISXSUB */

#ifndef CvISXSUB_on
# define CvISXSUB_on(cv) ((void) (cv))
#endif /* !CvISXSUB_on */

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

#ifndef gv_stashpvs
# define gv_stashpvs(name, flags) gv_stashpvn(""name"", sizeof(name)-1, flags)
#endif /* !gv_stashpvs */

#if PERL_VERSION_GE(5,19,4)
typedef SSize_t array_ix_t;
#else /* <5.19.4 */
typedef I32 array_ix_t;
#endif /* <5.19.4 */

#ifndef newSV_type
# define newSV_type(type) THX_newSV_type(aTHX_ type)
static SV *THX_newSV_type(pTHX_ svtype type)
{
	SV *sv = newSV(0);
	(void) SvUPGRADE(sv, type);
	return sv;
}
#endif /* !newSV_type */

#ifndef SvRV_set
# define SvRV_set(rv, tgt) (SvRV(rv) = (tgt))
#endif /* !SvRV_set */

#ifndef mg_findext
# define mg_findext(sv, type, vtbl) THX_mg_findext(aTHX_ sv, type, vtbl)
static MAGIC *THX_mg_findext(pTHX_ SV *sv, int type, MGVTBL const *vtbl)
{
	MAGIC *mg;
	if(sv)
		for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
			if(mg->mg_type == type && mg->mg_virtual == vtbl)
				return mg;
	return NULL;
}
#endif /* !mg_findext */

#ifndef G_WANT
# define G_WANT (G_SCALAR|G_ARRAY|G_VOID)
#endif /* !G_WANT */

#ifdef CXt_LOOP
# define case_CXt_LOOP_ case CXt_LOOP:
#elif defined(CXt_LOOP_FOR)
# define case_CXt_LOOP_ \
		case CXt_LOOP_FOR: case CXt_LOOP_PLAIN: \
		case CXt_LOOP_LAZYSV: case CXt_LOOP_LAZYIV:
#else /* !CXt_LOOP && !CXt_LOOP_FOR */
# define case_CXt_LOOP_ \
		case CXt_LOOP_ARY: case CXt_LOOP_LAZYSV: case CXt_LOOP_LAZYIV: \
		case CXt_LOOP_LIST: case CXt_LOOP_PLAIN:
#endif /* !CXt_LOOP && !CXt_LOOP_FOR */

#ifdef CXt_GIVEN
# define case_OP_LEAVEGIVEN_ case OP_LEAVEGIVEN:
# define case_CXt_GIVEN_ case CXt_GIVEN:
#else /* !CXt_GIVEN */
# define case_OP_LEAVEGIVEN_ /* nothing */
# define case_CXt_GIVEN_ /* nothing */
#endif /* !CXt_GIVEN */

#ifdef CXt_WHEN
# define case_OP_LEAVEWHEN_ case OP_LEAVEWHEN:
# define case_CXt_WHEN_ case CXt_WHEN:
#else /* !CXt_WHEN */
# define case_OP_LEAVEWHEN_ /* nothing */
# define case_CXt_WHEN_ /* nothing */
#endif /* !CXt_WHEN */

#if !PERL_VERSION_GE(5,10,1)
typedef unsigned Optype;
#endif /* <5.10.1 */

#define BLK_LOOP_HAS_MY_OP PERL_VERSION_GE(5,9,5)

#if BLK_LOOP_HAS_MY_OP
# define blk_loop_redo_op blk_loop.my_op->op_redoop
# define blk_loop_next_op blk_loop.my_op->op_nextop
# define blk_loop_last_op blk_loop.my_op->op_lastop
#else /* !BLK_LOOP_HAS_MY_OP */
# define blk_loop_redo_op blk_loop.redo_op
# define blk_loop_next_op blk_loop.next_op
# define blk_loop_last_op blk_loop.last_op
#endif /* !BLK_LOOP_HAS_MY_OP */

#ifndef OpMORESIB_set
# define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
# define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
# define OpMAYBESIB_set(o, sib, parent) ((o)->op_sibling = (sib))
#endif /* !OpMORESIB_set */
#ifndef OpSIBLING
# define OpHAS_SIBLING(o) (cBOOL((o)->op_sibling))
# define OpSIBLING(o) (0 + (o)->op_sibling)
#endif /* !OpSIBLING */

#if PERL_VERSION_GE(5,9,5)
# define Op_pmreplroot op_pmreplrootu.op_pmreplroot
#else /* <5.9.5 */
# define Op_pmreplroot op_pmreplroot
#endif /* <5.9.5 */

#define CATCHER_USES_RESTART_JMPENV PERL_VERSION_GE(5,13,1)

#define CATCHER_USES_GHOST_JMPENV \
	(!CATCHER_USES_RESTART_JMPENV && \
	 (PERL_VERSION_GE(5,9,3) || \
	  (!PERL_VERSION_GE(5,9,0) && PERL_VERSION_GE(5,8,9))))

#define CATCHER_USES_CURSTACKINFO \
	(!CATCHER_USES_RESTART_JMPENV && !CATCHER_USES_GHOST_JMPENV)

#if CATCHER_USES_GHOST_JMPENV && !PERL_VERSION_GE(5,11,0) && !defined(cxinc)
# define cxinc() Perl_cxinc(aTHX)
#endif /* CATCHER_USES_GHOST_JMPENV && <5.11.0 && !cxinc */

/*
 * continuation structure
 *
 * An escape continuation is reified as a CV.  The CV is of the XSUB
 * type, and the underlying XSUB is THX_xsfunc_go(), which implements
 * control transfer through the continuation.  A magic structure (with
 * vtable contsub_mgvtbl) is attached to the CV.  The mg_obj of the magic
 * structure contains an SV whose PV points to a struct continuation_guts.
 *
 * Optionally, the CV can be blessed into Scope::Escape::Continuation,
 * which provides a method interface.  The method code doesn't actually
 * care whether the CV is blessed.  If the user wants it both ways,
 * there can be two CVs pointing at the same struct continuation_guts,
 * with differing blessedness.  To avoid unnecessary cloning, they each
 * have a weak reference to the other, held in the mg_ptr slot.  In that
 * case mg_len is set to HEf_SVKEY, to arrange for the weak ref SV to be
 * freed when the CV is freed.  When no such weak ref has been set up,
 * mg_ptr is NULL and mg_len is zero.
 *
 * The struct continuation_guts is mainly concerned with describing the
 * context that it is intended to continue from.  It also has a validity
 * flag, which is automatically cleared in some situations, to cleanly
 * detect invalid transfers.  There is a chain of all the continuations
 * relevant to the currently stacked scopes, as part of this scheme.
 *
 * The leaveop member of the structure is expected to point to the op
 * that would normally be used for local return from the target context.
 * The proper leaveop for an escape continuation constructor op is
 * determined at compile time, by tree walking (in a custom peephole
 * optimiser), and stashed in a hidden field of the op structure,
 * from where it is copied to each continuation structure that the
 * op generates.
 */

static OP null_end_op;

struct continuation_guts {
	struct continuation_guts *next;
	JMPENV *jmpenv;
	PERL_SI *stackinfo;
	OP *leaveop;
	I32 cxstackix;
	I32 savestackix;
	bool may_be_valid;
};

static struct continuation_guts *top_contgut;

#define check_cont_leaveop(contgut) THX_check_cont_leaveop(aTHX_ contgut)
static void THX_check_cont_leaveop(pTHX_ struct continuation_guts *contgut)
{
	PERL_CONTEXT *tgtcx =
		&contgut->stackinfo->si_cxstack[contgut->cxstackix];
	OP *leaveop = contgut->leaveop;
	Optype leaveop_type;
	if(!leaveop) croak("broken continuation: no leaveop\n");
	leaveop_type = leaveop->op_type;
	switch(CxTYPE(tgtcx)) {
		case CXt_NULL: {
			if(leaveop != &null_end_op)
				goto bad_leaveop_type;
			return;
		} break;
		case CXt_SUB: {
			if(leaveop_type != OP_LEAVESUB &&
					leaveop_type != OP_LEAVESUBLV)
				goto bad_leaveop_type;
		} break;
		case CXt_EVAL: {
			if(leaveop_type != OP_LEAVEEVAL &&
					leaveop_type != OP_LEAVETRY)
				goto bad_leaveop_type;
		} break;
		case CXt_FORMAT: {
			if(leaveop_type != OP_LEAVEWRITE)
				goto bad_leaveop_type;
		} break;
		case CXt_BLOCK: {
			if(leaveop_type != OP_LEAVE) {
				bad_leaveop_type:
				croak("broken continuation: "
					"wrong type of leaveop for context\n");
			}
		} break;
		case_CXt_LOOP_ {
			if(tgtcx->blk_loop_next_op ==
					tgtcx->blk_loop_last_op) {
				if(leaveop_type != OP_LEAVELOOP)
					goto bad_leaveop_type;
				if(leaveop != tgtcx->blk_loop_last_op) {
#if BLK_LOOP_HAS_MY_OP
					wrong_loop:
#endif /* BLK_LOOP_HAS_MY_OP */
					croak("broken continuation: "
						"leaveop points at "
						"wrong loop\n");
				}
			} else {
				if(leaveop_type != OP_UNSTACK)
					goto bad_leaveop_type;
#if BLK_LOOP_HAS_MY_OP
				if(leaveop->op_next != tgtcx->blk_loop.my_op
								->op_next)
					goto wrong_loop;
#endif /* BLK_LOOP_HAS_MY_OP */
			}
		} break;
		default: {
			croak("broken continuation: unhandled context type\n");
		} break;
	}
}

static MGVTBL const contsub_mgvtbl;

static void THX_xsfunc_go(pTHX_ CV *contsub);

#define contsub_from_contref(contref) THX_contsub_from_contref(aTHX_ contref)
static CV *THX_contsub_from_contref(pTHX_ SV *contref)
{
	CV *contsub;
	if(!(SvROK(contref) && (contsub = (CV*)SvRV(contref)) &&
			SvTYPE((SV*)contsub) == SVt_PVCV &&
			CvISXSUB(contsub) && CvXSUB(contsub) == THX_xsfunc_go))
		croak("Scope::Escape::Continuation method invoked on wrong "
			"type of object");
	return contsub;
}

#define contgutsv_from_contsub(contsub) \
	THX_contgutsv_from_contsub(aTHX_ contsub)
static SV *THX_contgutsv_from_contsub(pTHX_ CV *contsub)
{
	return mg_findext((SV*)contsub, PERL_MAGIC_ext,
		(MGVTBL*)&contsub_mgvtbl)->mg_obj;
}

#define contgut_from_contsub(contsub) THX_contgut_from_contsub(aTHX_ contsub)
static struct continuation_guts *THX_contgut_from_contsub(pTHX_ CV *contsub)
{
	return (struct continuation_guts *)
		SvPVX(contgutsv_from_contsub(contsub));
}

#define contgut_from_contref(contref) THX_contgut_from_contref(aTHX_ contref)
static struct continuation_guts *THX_contgut_from_contref(pTHX_ SV *contref)
{
	return contgut_from_contsub(contsub_from_contref(contref));
}

static HV *stash_esccont;

#define make_contref_from_contgutsv(contgutsv, blessp) \
	THX_make_contref_from_contgutsv(aTHX_ contgutsv, blessp)
static SV *THX_make_contref_from_contgutsv(pTHX_ SV *contgutsv, bool blessp)
{
	CV *contsub = (CV*)newSV_type(SVt_PVCV);
	SV *contref = sv_2mortal(newRV_noinc((SV*)contsub));
	sv_magicext((SV*)contsub, contgutsv, PERL_MAGIC_ext,
		(MGVTBL*)&contsub_mgvtbl, NULL, 0);
	CvISXSUB_on(contsub);
	CvXSUB(contsub) = THX_xsfunc_go;
	if(blessp) sv_bless(contref, stash_esccont);
	return contref;
}

#define make_contref_from_contsub(contsub, blessp) \
	THX_make_contref_from_contsub(aTHX_ contsub, blessp)
static SV *THX_make_contref_from_contsub(pTHX_ CV *contsub, bool blessp)
{
	SV *wr, *hr;
	CV *othersub;
	MAGIC *mg;
	if(cBOOL(SvOBJECT((SV*)contsub)) == cBOOL(blessp))
		return sv_2mortal(newRV_inc((SV*)contsub));
	mg = mg_findext((SV*)contsub, PERL_MAGIC_ext, (MGVTBL*)&contsub_mgvtbl);
	wr = mg->mg_len ? (SV*)mg->mg_ptr : NULL;
	if(wr && SvROK(wr))
		return sv_2mortal(newRV_inc(SvRV(wr)));
	hr = make_contref_from_contgutsv(mg->mg_obj, blessp);
	othersub = (CV*)SvRV(hr);
	if(wr) {
		SvRV_set(wr, SvREFCNT_inc((SV*)othersub));
		SvROK_on(wr);
	} else {
		wr = newRV_inc((SV*)othersub);
		mg->mg_ptr = (char*)wr;
		mg->mg_len = HEf_SVKEY;
	}
	sv_rvweaken(wr);
	mg = mg_findext((SV*)othersub, PERL_MAGIC_ext,
		(MGVTBL*)&contsub_mgvtbl);
	wr = newRV_inc((SV*)contsub);
	sv_rvweaken(wr);
	mg->mg_ptr = (char*)wr;
	mg->mg_len = HEf_SVKEY;
	return hr;
}

/*
 * how Perl context unwinding works
 *
 * Perl has several stacks that work in parallel, but unwinding on them
 * doesn't proceed strictly in lockstep.  Generally, a non-local control
 * transfer (normal function return, eval-based exception catching,
 * or escape continuation usage) proceeds thus:
 *
 * a. Frames are popped from the context stack (cxstack).  These record
 *    the intensional dynamic frames, and in some situations are split
 *    across multiple stacks (the boundaries between which are significant
 *    for some purposes).  Almost no objects are destroyed in this phase.
 *
 * b. Things are restored from the save stack.  These include destroying
 *    objects and restoring the values of various variables.  The extent
 *    of restoration is determined by the new top of the context stack.
 *
 * c. Actual control transfer occurs.  In simple cases, this merely
 *    involves a PP function returning a pointer to the right op for
 *    the new context.  In more complex cases, a C-level longjmp()
 *    is required to get to the right level to jump to the next op.
 *    (A chain of setjmp() environments is established to allow arbitrary
 *    C-level cleanup at this stage.)
 *
 * d. At some point after control transfer, temporary values that were
 *    in use at the time of the unwinding are freed.  This is not part
 *    of the transfer itself, but occurs when the newly executing code
 *    finds it convenient.  The extent of temporary freeing is controlled
 *    by a variable managed on the save stack.
 *
 * With specific reference to the escape continuations supplied by this
 * module, the target of a continuation is ultimately specified by a
 * frame on the context stack.  Transfer through an escape continuation
 * constitutes returning from such a frame.
 */

/*
 * how C context unwinding works in Perl
 *
 * Within most pure Perl code, Perl context nesting is not reflected
 * on the C stack.  Instead, the C stack is based on a run loop, which
 * repeatedly runs the pp function for the current Perl op (PL_op) and
 * moves on to the op returned by the pp function.  Perl function calls
 * and suchlike are reflected on the Perl context stack, while the C
 * stack always unwinds (by normal return) to the run loop between ops.
 * However, if C code (such as an XS function body) calls Perl code,
 * it must set up a nested run loop.  Some other situations, such as
 * the special arrangements for calling sort comparators, also involve
 * nested run loops.
 *
 * When a non-local control transfer occurs in Perl, mainly due to die,
 * the C stack must be unwound to the correct run loop.  Nominally,
 * each run loop function has performed a setjmp().  Thus the die can
 * perform a longjmp() to get back to it, and when setjmp() returns
 * indicating that a die to this run loop is in progress the run loop
 * resumes at the op indicated by PL_restartop.
 *
 * Actually, many run loops don't bother setting up a setjmp() target
 * themselves, because it's unlikely to be required.  Instead a flag
 * is set indicating that the run loop has omitted to do this.  When an
 * op such as entertry is executed, that means a non-local jump to the
 * current run loop might be required, if the flag is set then the pp
 * function chains a run loop (docatch()) that does perform a setjmp().
 * This run loop takes over the entire job of the lazy run loop.
 *
 * When a longjmp() is performed, it does not go directly to the real
 * target run loop.  It is permitted for C code to rely on being able
 * to perform cleanup during C stack unwinding.  To this end, all the
 * available setjmp() environments are chained, stackwise, and longjmp()
 * is only ever performed to the top entry on the stack.  A setjmp()
 * environment that is not the proper target of the non-local jump is
 * expected to perform its cleanup (if any) and then rejump to the next
 * environment on the stack.  Thus the proper targeting of non-local
 * jumps depends crucially on the way setjmp() environments detect
 * whether they are the intended target and on how they rejump.
 *
 * The reason for a longjmp() is encoded in the small integer code that
 * is passed through the jump and returned by setjmp().  0 means that
 * setjmp() is returning for the first time and no jump has occurred.
 * 1 is never generated, but apparently reserved to indicate that setjmp()
 * failed.  2 means that a Perl-level exit was invoked.  3 means that
 * a Perl-level die was invoked.  4 and higher are never generated.
 *
 * Many setjmp() environments make assumptions about which kinds of
 * non-local jump can occur.  Unassigned jump codes are assumed to never
 * occur, and so are liable to cause misbehaviour.  The exit code can
 * result in exit-specific processing.  This means that the only jump code
 * that can sensibly be used for the escape continuations of this module
 * is the die code.  Unfortunately, even there assumptions are made that
 * don't work with escape continuations.  The docatch() run loop checks
 * whether it is the right target by looking at the CXt_EVAL frame that
 * was (presumably) just popped off the Perl context stack.  Some other
 * run loops assume that they must be the right target, because they
 * know the nominal behaviour of the CXt_EVAL frame they are concerned
 * with and assume that unwinding cannot occur past it.  As a result,
 * it is generally not feasible to unwind past a CXt_EVAL frame.
 */

/*
 * continuation validity
 *
 * Continuations in Perl (as supplied by the core and by this module)
 * are not first-class.  The lifetime (Common Lisp: "extent") during
 * which it is valid to transfer through a continuation is limited.
 * A continuation's validity trivially ends when its target frame is
 * unwound (for any reason, local or non-local).  A continuation also
 * becomes invalid (Common Lisp: "is abandoned") in some other situations.
 *
 * Following Common Lisp semantics, at the beginning of unwinding,
 * all continuations for intermediate stack frames (higher on the
 * context stack than the target frame) are invalidated.  In principle,
 * this abandonment logic could apply to continuations for all forms of
 * non-local control transfer, whether reified or not.  However, it only
 * definitely applies to the escape continuations supplied by this module,
 * which are explicitly trying to supply Common Lisp semantics.  It does
 * apply regardless of the type of control transfer that caused unwinding.
 *
 * The continuations of this module attempt to track their validity,
 * and report errors if invalid transfers are attempted.  (Common Lisp
 * leaves the behaviour of an invalid transfer undefined.)  In principle,
 * perfect validity tracking could be achieved by clearing the validity
 * flag when the corresponding frame is popped from the context stack,
 * mainly by dounwind(), because this stage occurs before any cleanup
 * code is run corresponding to the unwinding in progress.  However,
 * Perl provides no way to hook this event.  (Of course, if it provided
 * for running arbitrary code here, the invalidation would have to happen
 * even earlier.  Only a restricted hook facility would do.)
 *
 * When a continuation's target frame is unwinding, an entry on the save
 * stack marks the continuation as invalid.  This is too late to detect
 * all invalid transfers, but it detects all attempted transfers from
 * outer contexts, and is a useful base for other invalidity checking
 * to work from.  It means that the remaining logic only needs to detect
 * invalid transfers that occur during unwinding that passes the target
 * frame.
 *
 * When unwinding is caused by this module, intermediate continuations
 * are marked as invalid by following a chain of the continuations whose
 * targets have not yet been unwound.  This takes place before unwinding
 * the context stack.  The chain is maintained in stack form: each
 * newly-created continuation is pushed onto the stack, and it is popped
 * when the appropriate part of the save stack is unwound (by which time
 * the continuation is marked as invalid anyway due to the foregoing).
 *
 * When unwinding only extends within a single context stack and the only
 * code run on unwinding is destructors, it is reasonably easy to detect
 * continuation invalidity.  Most core control-transfer ops are limited to
 * a single stack: return, last, next, redo, goto, continue, and break.
 * (Thus one cannot goto out of a sort expression, though one can goto
 * out of a map expression.)  In this case, the context stack in question
 * will remain in its unwound state while all the save-stack-initiated
 * code runs: all destructor code will run on a different stack.  So an
 * invalid continuation use in this situation is detected by checking that
 * the target context stack is high enough to contain the target frame.
 *
 * When unwinding crosses context stacks, it is a problem.  Of the
 * core's ops, this only occurs with die.  There is also a problem if
 * code run on unwinding might invoke more unwinding but does not use
 * a separate stack.  This occurs with Scope::Upper::reap.
 *
 * A continuation that is causing unwinding keeps itself valid until the
 * last moment, by deferring unwinding its target context.  It unwinds
 * higher contexts, then unwinds the save stack to the point it was
 * at when the continuation was created.  During that unwinding, the
 * continuation is still usable.  The last part of save stack unwinding
 * marks the continuation as invalid.  After that, the C-level non-local
 * jump is performed, and the appropriate leave op performs the last
 * part of unwinding.
 */

static bool sanity_checking_enabled;

#define CONTSTAT_INACCESSIBLE G_EVAL    /* can't transfer right now */

#define cont_status(contgut, wantflags) \
	THX_cont_status(aTHX_ contgut, wantflags)
static I32 THX_cont_status(pTHX_
	struct continuation_guts *contgut, I32 wantflags)
{
	PERL_SI *tgtstki, *si;
	I32 tgtcxix;
	PERL_CONTEXT *tgtcx;
	I32 flags = 0;
	if(!contgut->may_be_valid) {
		invalid:
		croak("attempt to use invalid continuation");
	}
	tgtstki = contgut->stackinfo;
	tgtcxix = contgut->cxstackix;
	for(si = PL_curstackinfo; ; si = si->si_prev) {
		I32 i = si->si_cxix, tgti;
		if(!si) {
			contgut->may_be_valid = 0;
			goto invalid;
		}
		if(si == tgtstki) {
			if(i < tgtcxix) {
				contgut->may_be_valid = 0;
				goto invalid;
			}
			tgti = tgtcxix;
		} else {
			tgti = -1;
		}
		if(wantflags & CONTSTAT_INACCESSIBLE) {
			for(; i != tgti; i--) {
				if(CxTYPE(&si->si_cxstack[i]) == CXt_EVAL)
					flags |= CONTSTAT_INACCESSIBLE;
			}
		}
		if(si == tgtstki) break;
	}
	tgtcx = &tgtstki->si_cxstack[tgtcxix];
	if(wantflags & G_WANT) {
		switch(CxTYPE(tgtcx)) {
			case CXt_NULL: {
				flags |= G_SCALAR;
			} break;
			case CXt_FORMAT: {
				flags |= G_VOID;
			} break;
			case_CXt_LOOP_ {
				flags |= tgtcx->blk_loop_next_op ==
						tgtcx->blk_loop_last_op ?
					tgtcx->blk_gimme : G_VOID;
			} break;
			default: {
				flags |= tgtcx->blk_gimme;
			} break;
		}
	}
	return flags;
}

static void THX_xsfunc_go(pTHX_ CV *contsub)
{
	struct continuation_guts *contgut, *cg;
	PERL_SI *tgtstki;
	I32 tgtcxix, status;
	PERL_CONTEXT *tgtcx;
	SV *retval;
	contgut = contgut_from_contsub(contsub);
	status = cont_status(contgut, CONTSTAT_INACCESSIBLE|G_WANT);
	if(status & CONTSTAT_INACCESSIBLE)
		croak("attempt to transfer past impervious stack frame");
	for(cg = top_contgut; cg != contgut; cg = cg->next)
		cg->may_be_valid = 0;
	switch(status & G_WANT) {
		default: {
			retval = &PL_sv_undef;
		} break;
		case G_SCALAR: {
			dSP; dMARK;
			if(MARK == SP) {
				retval = &PL_sv_undef;
			} else {
				retval = TOPs;
				SvREFCNT_inc(retval);
				sv_2mortal(retval);
			}
		} break;
		case G_ARRAY: {
			dSP; dMARK;
			SV **rets = MARK+1;
			array_ix_t retc = SP - MARK, i;
			AV *retav = newAV();
			retval = (SV*)retav;
			sv_2mortal(retval);
			av_fill(retav, retc-1);
			Copy(rets, AvARRAY(retav), retc, SV*);
			for(i = retc; i--; ) SvREFCNT_inc(rets[i]);
		} break;
	}
	tgtstki = contgut->stackinfo;
	while(PL_curstackinfo != tgtstki) {
		dounwind(-1);
		POPSTACK;
	}
	tgtcxix = contgut->cxstackix;
	tgtcx = &cxstack[tgtcxix];
	dounwind(tgtcxix);
#ifdef cx_topblock
	cx_topblock(tgtcx);
#else /* !cx_topblock */
	TOPBLOCK(tgtcx);
	leave_scope(contgut->savestackix);
#endif /* !cx_topblock */
	PL_curcop = tgtcx->blk_oldcop;
	switch(status & G_WANT) {
		default: {
			/* put nothing on stack */
		} break;
		case G_SCALAR: {
			dSP;
			XPUSHs(retval);
			PUTBACK;
		} break;
		case G_ARRAY: {
			dSP;
			AV *retav = (AV*)retval;
			array_ix_t retc = av_len(retav) + 1;
			EXTEND(SP, retc);
			Copy(AvARRAY(retav), SP+1, retc, SV*);
			SP += retc;
			PUTBACK;
		} break;
	}
	PL_restartop = contgut->leaveop;
#if PERL_VERSION_GE(5,17,2) && !PERL_VERSION_GE(5,17,3)
	if(PL_restartop->op_type == OP_LEAVEWRITE) {
		/*
		 * For Perl 5.17.2 only, leavewrite has dodgy stack
		 * handling in which it pops an extra item from the stack.
		 * We work around it by pushing a dummy item for it
		 * to pop.
		 */
		dSP;
		XPUSHs(&PL_sv_undef);
		PUTBACK;
	}
#endif /* >=5.17.2 && <5.17.3 */
#if CATCHER_USES_GHOST_JMPENV
	{
		/*
		 * Add fake CXt_EVAL context, appearing to have been just
		 * unwound, for the benefit of docatch().  The catcher
		 * there checks cur_top_env of the just-unwound eval
		 * frame to determine whether it is the correct target
		 * for the longjmp().
		 */
		PERL_CONTEXT *evalcx;
		CXINC;
		evalcx = &cxstack[cxstack_ix];
		evalcx->cx_type = CXt_EVAL;
		evalcx->blk_eval.cur_top_env = contgut->jmpenv;
		cxstack_ix--;
	}
#endif /* CATCHER_USES_GHOST_JMPENV */
#if CATCHER_USES_RESTART_JMPENV
	PL_restartjmpenv = contgut->jmpenv;
#endif /* CATCHER_USES_RESTART_JMPENV */
	JMPENV_JUMP(3);
}

#define pp_current_escape_continuation_caught() \
	THX_pp_current_escape_continuation_caught(aTHX)
static OP *THX_pp_current_escape_continuation_caught(pTHX)
{
	SV *contref, *contgutsv;
	struct continuation_guts *contgut;
	contgutsv = newSV_type(SVt_PV);
	SAVEFREESV(contgutsv);
	Newx(contgut, 1, struct continuation_guts);
	SvPV_set(contgutsv, (char *)contgut);
	SvLEN_set(contgutsv, sizeof(struct continuation_guts));
	contgut->jmpenv = PL_top_env;
	contgut->stackinfo = PL_curstackinfo;
	contgut->leaveop = cUNOPx(PL_op)->op_first;
	contgut->cxstackix = cxstack_ix;
	contgut->savestackix = PL_savestack_ix;
	SAVEVPTR(top_contgut);
	contgut->next = top_contgut;
	top_contgut = contgut;
	contgut->may_be_valid = 0;
	SAVEBOOL(contgut->may_be_valid);
	contgut->may_be_valid = 1;
	if(sanity_checking_enabled) check_cont_leaveop(contgut);
	contref = make_contref_from_contgutsv(contgutsv,
			PL_op->op_private & 1);
	{
		dSP;
		XPUSHs(contref);
		PUTBACK;
	}
	return PL_op->op_next;
}

#define docatch_for_pp_current_escape_continuation() \
	THX_docatch_for_pp_current_escape_continuation(aTHX)
static OP *THX_docatch_for_pp_current_escape_continuation(pTHX)
{
	/* the logic here must (mostly) match docatch() */
	OP *curop = PL_op;
#if CATCHER_USES_CURSTACKINFO
	PERL_SI *cursi = PL_curstackinfo;
#endif /* CATCHER_USES_CURSTACKINFO */
	dJMPENV;
	int ret;
	JMPENV_PUSH(ret);
	switch(ret) {
		case 0: {
			PL_op = pp_current_escape_continuation_caught();
			runops:
			CALLRUNOPS(aTHX);
			JMPENV_POP;
			PL_op = curop;
			return NULL;
		} /* not reached */
		case 3: {
#if CATCHER_USES_GHOST_JMPENV
			PERL_CONTEXT *evalcx = &cxstack[cxstack_ix+1];
			assert(CxTYPE(evalcx) == CXt_EVAL);
#endif /* CATCHER_USES_GHOST_JMPENV */
			if(PL_restartop
#if CATCHER_USES_CURSTACKINFO
				&& PL_curstackinfo == cursi
#endif /* CATCHER_USES_CURSTACKINFO */
#if CATCHER_USES_GHOST_JMPENV
				&& evalcx->blk_eval.cur_top_env == PL_top_env
#endif /* CATCHER_USES_GHOST_JMPENV */
#if CATCHER_USES_RESTART_JMPENV
				&& PL_restartjmpenv == PL_top_env
#endif /* CATCHER_USES_RESTART_JMPENV */
			) {
#if CATCHER_USES_RESTART_JMPENV
				PL_restartjmpenv = NULL;
#endif /* CATCHER_USES_RESTART_JMPENV */
				PL_op = PL_restartop;
				PL_restartop = NULL;
				goto runops;
			}
		} /* fall through */
		default: {
			JMPENV_POP;
			PL_op = curop;
			JMPENV_JUMP(ret);
		} /* not reached */
	}
}

static OP *THX_pp_current_escape_continuation(pTHX)
{
	if(CATCH_GET) {
		return docatch_for_pp_current_escape_continuation();
	} else {
		return pp_current_escape_continuation_caught();
	}
}

#define newOP_current_escape_continuation(blessp) \
		THX_newOP_current_escape_continuation(aTHX_ blessp)
static OP *THX_newOP_current_escape_continuation(pTHX_ bool blessp)
{
	OP *op;
	NewOpSz(0, op, sizeof(UNOP));
	op->op_type = OP_CUSTOM;
	op->op_ppaddr = THX_pp_current_escape_continuation;
	if(blessp) op->op_private |= 1;
	op->op_next = op;
	PL_hints |= HINT_BLOCK_SCOPE;
	return op;
}

#define fixup_escape_target(target, op) \
	THX_fixup_escape_target(aTHX_ target, op)
static void THX_fixup_escape_target(pTHX_ OP *target, OP *op)
{
	OP *special_kid = NULL;
	if(op->op_ppaddr == THX_pp_current_escape_continuation) {
		cUNOPx(op)->op_first = target;
		return;
	}
	switch(op->op_type) {
		case OP_LEAVESUB:
		case OP_LEAVESUBLV:
		case OP_LEAVE:
		case_OP_LEAVEGIVEN_
		case_OP_LEAVEWHEN_
		case OP_LEAVEWRITE:
		case OP_LEAVEEVAL:
		case OP_LEAVETRY: {
			target = op;
		} break;
		case OP_LEAVELOOP: {
			LOOP *enterloop = cLOOPx(cBINOPx(op)->op_first);
			if(enterloop->op_nextop == enterloop->op_lastop) {
				target = op;
			} else {
				target = cBINOPx(op)->op_last;
				while(target->op_type == OP_NULL)
					target = cUNOPx(target)->op_first;
				if(target->op_type != OP_LINESEQ)
					target = OpSIBLING(
						cLOGOPx(target)->op_first);
				target = cLISTOPx(target)->op_last;
			}
		} break;
		case OP_SUBST: {
			OP *rcop = cPMOPx(op)->Op_pmreplroot;
			if(rcop) fixup_escape_target(target, rcop);
		} break;
		case OP_SORT: {
			if((op->op_flags & (OPf_STACKED|OPf_SPECIAL)) ==
					(OPf_STACKED|OPf_SPECIAL)) {
				special_kid = OpSIBLING(cLISTOPx(op)->op_first);
				fixup_escape_target(&null_end_op,
					cUNOPx(special_kid)->op_first);
			}
		} break;
	}
	if(op->op_flags & OPf_KIDS) {
		for(op = cUNOPx(op)->op_first; op; op = OpSIBLING(op)) {
			if(op != special_kid)
				fixup_escape_target(target, op);
		}
	}
}

/*
 * continuation target fixup
 *
 * To populate the leaveop member of the continuation structure, we want
 * to examine the op tree at the end of compilation.  We don't want to
 * do it immediately when ops are built, because they're liable to get
 * moved around: this is a fixup to perform when the tree is finalised.
 * The only way to perform such a fixup is via the peephole optimiser
 * hook, but unfortunately that doesn't get a pointer to the root op,
 * but only a pointer to the start of the execution chain.  Thus we have
 * the problem of getting from the start op to the root op.
 *
 * Normally the tree structure has a leavesub op at the root, and there's
 * a sequence of statements a couple of levels down, with the starting
 * point being a nextstate at the beginning of that sequence.  To get
 * to the root, we walk along the sibling chain to get to the end of
 * the statement sequence, then walk the execution chain to go up the
 * couple of levels to the root.  Note that any execution-order loops
 * will be among ops nested inside statements, so walking the sibling
 * chain skips past them.
 *
 * However, we can also be given a fake op sequence for a nominal
 * CV wrapping code embedded in a regexp via /(?{})/.  In that case,
 * following the above algorithm does lead to an apparent execution-order
 * loop.  (Not a real loop; it's among ops that never get executed.)
 * We detect the loop and abort the attempt to fixup in that case.
 * This means that we can't (yet) generate continuations inside re
 * eval code.  It's not clear what that would mean at the top level
 * inside /(?{})/, but it would be meaningful at lower levels, so we'd
 * like to fix that in the future.
 */

static void (*THX_next_peep)(pTHX_ OP*);

static void THX_my_peep(pTHX_ OP *first)
{
	if(first) {
		OP *root = first, *slow;
		while(OpHAS_SIBLING(root)) root = OpSIBLING(root);
		slow = root;
		while(root->op_next) {
			root = root->op_next;
			if(!root->op_next) break;
			if(root == slow) goto skip_fixup;
			slow = slow->op_next;
			root = root->op_next;
		}
		fixup_escape_target(root, root);
	}
	skip_fixup:
	THX_next_peep(aTHX_ first);
}

static OP *THX_ck_entersub_curesc(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
	entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);
	op_free(entersubop);
	return newOP_current_escape_continuation(CvXSUBANY((CV*)ckobj).any_i32);
}

MODULE = Scope::Escape PACKAGE = Scope::Escape

PROTOTYPES: DISABLE

BOOT:
{
	CV *curescfunc_cv, *curesccont_cv;
	null_end_op.op_type = OP_NULL;
	null_end_op.op_ppaddr = PL_ppaddr[OP_NULL];
	stash_esccont = gv_stashpvs("Scope::Escape::Continuation", 1);
	THX_next_peep = PL_peepp;
	PL_peepp = THX_my_peep;
	curescfunc_cv = get_cv("Scope::Escape::current_escape_function", 0);
	curesccont_cv = get_cv("Scope::Escape::current_escape_continuation", 0);
	CvXSUBANY(curescfunc_cv).any_i32 = 0;
	CvXSUBANY(curesccont_cv).any_i32 = 1;
	cv_set_call_checker(curescfunc_cv, THX_ck_entersub_curesc,
		(SV*)curescfunc_cv);
	cv_set_call_checker(curesccont_cv, THX_ck_entersub_curesc,
		(SV*)curesccont_cv);
}

void
current_escape_function(...)
PROTOTYPE:
CODE:
	PERL_UNUSED_VAR(items);
	croak("current_escape_function called as a function");

void
current_escape_continuation(...)
PROTOTYPE:
CODE:
	PERL_UNUSED_VAR(items);
	croak("current_escape_continuation called as a function");

void
_set_sanity_checking(bool new_state)
PROTOTYPE: $
CODE:
	sanity_checking_enabled = new_state;

void
_fake_short_cxstack()
PROTOTYPE:
CODE:
#if CATCHER_USES_GHOST_JMPENV
	cxstack_max = cxstack_ix;
#endif /* CATCHER_USES_GHOST_JMPENV */

MODULE = Scope::Escape PACKAGE = Scope::Escape::Continuation

void
go(SV *contref, ...)
PROTOTYPE: $@
PPCODE:
	PUSHMARK(SP+1);
	/* the modified SP is intentionally lost here */
	THX_xsfunc_go(aTHX_ contsub_from_contref(contref));
	/* does not return */

SV *
wantarray(SV *contref)
PROTOTYPE: $
CODE:
	switch(cont_status(contgut_from_contref(contref), G_WANT) & G_WANT) {
		default:       RETVAL = &PL_sv_undef; break;
		case G_SCALAR: RETVAL = &PL_sv_no;    break;
		case G_ARRAY:  RETVAL = &PL_sv_yes;   break;
	}
OUTPUT:
	RETVAL

bool
is_accessible(SV *contref)
PROTOTYPE: $
CODE:
	RETVAL = !(cont_status(contgut_from_contref(contref),
				CONTSTAT_INACCESSIBLE) &
			CONTSTAT_INACCESSIBLE);
OUTPUT:
	RETVAL

bool
may_be_valid(SV *contref)
PROTOTYPE: $
CODE:
	RETVAL = contgut_from_contref(contref)->may_be_valid;
OUTPUT:
	RETVAL

void
invalidate(SV *contref)
PROTOTYPE: $
CODE:
	contgut_from_contref(contref)->may_be_valid = 0;

SV *
as_function(SV *contref)
PROTOTYPE: $
CODE:
	RETVAL = make_contref_from_contsub(contsub_from_contref(contref), 0);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
as_continuation(SV *contref)
PROTOTYPE: $
CODE:
	RETVAL = make_contref_from_contsub(contsub_from_contref(contref), 1);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL
