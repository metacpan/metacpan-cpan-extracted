#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef SvSTASH_set
# define SvSTASH_set(sv, stash) (SvSTASH(sv) = (stash))
#endif /* !SvSTASH_set */

#ifndef OpREFCNT
# define OpREFCNT(o) OpREFCNT_dec(OpREFCNT_inc(o))
#endif /* !OpREFCNT */

#ifndef CvISXSUB
# define CvISXSUB(cv) !!CvXSUB(cv)
#endif /* !CvISXSUB */

#ifndef CvISXSUB_on
# define CvISXSUB_on(cv) ((void) (cv))
#endif /* !CvISXSUB_on */

#ifndef CVf_BUILTIN_ATTRS
# define CVf_BUILTIN_ATTRS (CVf_METHOD|CVf_LOCKED|CVf_LVALUE)
#endif /* !CVf_BUILTIN_ATTRS */

#ifndef CvGV_set
# define CvGV_set(cv, val) (CvGV(cv) = val)
#endif /*!CvGV_set */

#ifndef CvSTASH_set
# if PERL_VERSION_GE(5,13,3)
#  ifndef sv_del_backref
#   define sv_del_backref(t,s) Perl_sv_del_backref(aTHX_ t,s)
#  endif /* !sv_del_backref */
#  ifndef sv_add_backref
#   define sv_add_backref(t,s) Perl_sv_add_backref(aTHX_ t,s)
PERL_CALLCONV void Perl_sv_add_backref(pTHX_ SV *t, SV *s);
#  endif /* !sv_add_backref */
#  define CvSTASH_set(cv, newst) THX_cvstash_set(aTHX_ cv, newst)
static void THX_cvstash_set(pTHX_ CV *cv, HV *newst)
{
	HV *oldst = CvSTASH(cv);
	if(oldst) sv_del_backref((SV*)oldst, (SV*)cv);
	CvSTASH(cv) = newst;
	if(newst) sv_add_backref((SV*)newst, (SV*)cv);
}
# else /* <5.13.3 */
#  define CvSTASH_set(cv, newst) (CvSTASH(cv) = (newst))
# endif /* <5.13.3 */
#endif /* !CvSTASH_set */

#ifdef PadlistARRAY
# define QUSE_PADLIST_STRUCT 1
#else /* !PadlistARRAY */
# define QUSE_PADLIST_STRUCT 0
typedef AV PADNAMELIST;
# define PadlistARRAY(pl) ((PAD**)AvARRAY(pl))
# define PadlistNAMES(pl) (PadlistARRAY(pl)[0])
# define PadlistMAX(pl) AvFILLp(pl)
#endif /* !PadlistARRAY */

#ifndef newSV_type
# define newSV_type(type) THX_newSV_type(aTHX_ type)
static SV *THX_newSV_type(pTHX_ svtype type)
{
	SV *sv = newSV(0);
	(void) SvUPGRADE(sv, type);
	return sv;
}
#endif /* !newSV_type */

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

#ifndef ptr_table_new

struct q_ptr_tbl_ent {
	struct q_ptr_tbl_ent *next;
	void *from, *to;
};

# undef PTR_TBL_t
# define PTR_TBL_t struct q_ptr_tbl_ent *

# define ptr_table_new() THX_ptr_table_new(aTHX)
static PTR_TBL_t *THX_ptr_table_new(pTHX)
{
	PTR_TBL_t *tbl;
	Newx(tbl, 1, PTR_TBL_t);
	*tbl = NULL;
	return tbl;
}

# define ptr_table_free(tbl) THX_ptr_table_free(aTHX_ tbl)
static void THX_ptr_table_free(pTHX_ PTR_TBL_t *tbl)
{
	struct q_ptr_tbl_ent *ent = *tbl;
	Safefree(tbl);
	while(ent) {
		struct q_ptr_tbl_ent *nent = ent->next;
		Safefree(ent);
		ent = nent;
	}
}

# define ptr_table_store(tbl, from, to) THX_ptr_table_store(aTHX_ tbl, from, to)
static void THX_ptr_table_store(pTHX_ PTR_TBL_t *tbl, void *from, void *to)
{
	struct q_ptr_tbl_ent *ent;
	Newx(ent, 1, struct q_ptr_tbl_ent);
	ent->next = *tbl;
	ent->from = from;
	ent->to = to;
	*tbl = ent;
}

# define ptr_table_fetch(tbl, from) THX_ptr_table_fetch(aTHX_ tbl, from)
static void *THX_ptr_table_fetch(pTHX_ PTR_TBL_t *tbl, void *from)
{
	struct q_ptr_tbl_ent *ent;
	for(ent = *tbl; ent; ent = ent->next) {
		if(ent->from == from) return ent->to;
	}
	return NULL;
}

#endif /* !ptr_table_new */

#if defined(pp_dor) || PERL_VERSION_GE(5,9,0)
# define case_OP_DOR_ case OP_DOR:
# define case_OP_DORASSIGN_ case OP_DORASSIGN:
#else /* !pp_dor && <5.9.0 */
# define case_OP_DOR_
# define case_OP_DORASSIGN_
#endif /* !pp_dor && <5.9.0 */
#if PERL_VERSION_GE(5,9,3)
# define case_OP_ENTERWHEN_ case OP_ENTERWHEN:
#else /* <5.9.3 */
# define case_OP_ENTERWHEN_
#endif /* <5.9.3 */
#if PERL_VERSION_GE(5,10,0)
# define case_OP_ONCE_ case OP_ONCE:
#else /* <5.10.0 */
# define case_OP_ONCE_
#endif /* <5.10.0 */

#define canonise_retvalues(gimme) THX_canonise_retvalues(aTHX_ gimme)
static void THX_canonise_retvalues(pTHX_ I32 gimme)
{
	dSP; dMARK;
	PUSHMARK(MARK);
	if(gimme == G_SCALAR && SP != MARK+1) {
		if(SP > MARK+1) {
			SV *lastval = TOPs;
			SP = MARK;
			PUSHs(lastval);
		} else {
			XPUSHs(&PL_sv_undef);
		}
		PUTBACK;
	} else if(gimme == G_VOID && SP != MARK) {
		SP = MARK;
		PUTBACK;
	}
}

#define new_padlist_for_filter() THX_new_padlist_for_filter(aTHX)
static PADLIST *THX_new_padlist_for_filter(pTHX)
{
	PADLIST *padlist;
	PAD *pad;
	PADNAMELIST *padname;
	pad = newAV();
	av_store(pad, 0, &PL_sv_undef);
#if QUSE_PADLIST_STRUCT
	Newxz(padlist, 1, PADLIST);
	Newx(PadlistARRAY(padlist), 4, PAD *);
#else /* !QUSE_PADLIST_STRUCT */
	padlist = newAV();
# if !PERL_VERSION_GE(5,15,3)
	AvREAL_off(padlist);
# endif /* <5.15.3 */
	av_extend(padlist, 3);
#endif /* !QUSE_PADLIST_STRUCT */
	padname = newAV();
#ifdef AvPAD_NAMELIST_on
	AvPAD_NAMELIST_on(padname);
#endif /* AvPAD_NAMELIST_on */
	PadlistNAMES(padlist) = padname;
	PadlistARRAY(padlist)[1] = pad;
	PadlistMAX(padlist) = 3;
	return padlist;
}

static void xsfunc_runfilter(pTHX_ CV *wrappersub)
{
	I32 gimme = GIMME_V;
	PADLIST *padlist = CvPADLIST(wrappersub);
	CV *innersub = (CV*)PadlistARRAY(padlist)[2];
	CV *filtersub = (CV*)PadlistARRAY(padlist)[3];
	dMARK; dORIGMARK;
	PUSHMARK(MARK);
	CvXSUB(innersub)(aTHX_ innersub);
	PUSHMARK(ORIGMARK);
	canonise_retvalues(gimme);
	call_sv((SV*)filtersub, gimme);
}

#define swap_cvs(a, b) THX_swap_cvs(aTHX_ a, b)
static void THX_swap_cvs(pTHX_ CV *a, CV *b)
{
	CV x = *a, y = *b;
	SvREFCNT((SV*)&x) = SvREFCNT((SV*)b);
	SvREFCNT((SV*)&y) = SvREFCNT((SV*)a);
	*b = x; *a = y;
#ifdef CVf_CVGV_RC
	{
		U32 xf = (CvFLAGS(a) ^ CvFLAGS(b)) & CVf_CVGV_RC;
		CvFLAGS(a) ^= xf;
		CvFLAGS(b) ^= xf;
	}
#endif /* !CVf_CVGV_RC */
}

#define apply_retfilter_to_xsub(target, filter) \
	THX_apply_retfilter_to_xsub(aTHX_ target, filter)
static void THX_apply_retfilter_to_xsub(pTHX_ CV *target, CV *filter)
{
	CV *wrapper = (CV*)newSV_type(SVt_PVCV);
	PADLIST *padlist = CvPADLIST(wrapper) = new_padlist_for_filter();
	PadlistARRAY(padlist)[2] = (PAD*)wrapper;
	PadlistARRAY(padlist)[3] = (PAD*)SvREFCNT_inc((SV*)filter);
	if(SvPOK(target))
		sv_setpvn((SV*)wrapper, SvPVX(target), SvCUR(target));
	if(SvOBJECT(target)) {
		HV *st = SvSTASH(target);
		SvOBJECT_on(wrapper);
		if(st) SvSTASH_set(wrapper, (HV*)SvREFCNT_inc((SV*)st));
		PL_sv_objcount++;
	}
	CvFILE(wrapper) = CvFILE(target);
	CvSTASH_set(wrapper, CvSTASH(target));
	CvGV_set(wrapper, CvGV(target));
	CvFLAGS(wrapper) |=
		CvFLAGS(target) & (CVf_BUILTIN_ATTRS|CVf_ANON|CVf_NODEBUG);
	CvISXSUB_on(wrapper);
	CvXSUB(wrapper) = xsfunc_runfilter;
	swap_cvs(target, wrapper);
}

#define sub_gimme() THX_sub_gimme(aTHX)
static I32 THX_sub_gimme(pTHX)
{
	int cxix = cxstack_ix;
	PERL_CONTEXT *cxs = cxstack;
	while(1) {
		switch(CxTYPE(&cxs[cxix])) {
			case CXt_SUB: case CXt_EVAL: case CXt_FORMAT: {
				return cxs[cxix].blk_gimme;
			}
		}
		if(!cxix--) return G_VOID;
	}
}

#define current_gimme() THX_current_gimme(aTHX)
static I32 THX_current_gimme(pTHX)
{
	return cxstack[cxstack_ix].blk_gimme;
}

static OP *pp_canonise_retvalues_for_sub(pTHX)
{
	canonise_retvalues(sub_gimme());
	return PL_op->op_next;
}

static OP *pp_canonise_retvalues_for_block(pTHX)
{
	canonise_retvalues(current_gimme());
	return PL_op->op_next;
}

static OP *pp_copymark(pTHX)
{
	dMARK;
	PUSHMARK(MARK);
	PUSHMARK(MARK);
	return PL_op->op_next;
}

static OP *pp_blockmark(pTHX)
{
	PUSHMARK(PL_stack_base + cxstack[cxstack_ix].blk_oldsp);
	return PL_op->op_next;
}

#define link_op(parent, child) THX_link_op(aTHX_ parent, child)
static void THX_link_op(pTHX_ OP *parent, OP *child)
{
	child->op_sibling = parent->op_flags & OPf_KIDS ?
				cUNOPx(parent)->op_first : NULL;
	cUNOPx(parent)->op_first = child;
	parent->op_flags |= OPf_KIDS;
}

#define gen_filter_call(f) THX_gen_filter_call(aTHX_ f)
static OP *THX_gen_filter_call(pTHX_ CV *filter)
{
	OP *cvop, *callop;
	cvop = newSVOP(OP_CONST, 0, SvREFCNT_inc((SV*)filter));
	NewOpSz(0, callop, sizeof(UNOP));
	callop->op_type = OP_ENTERSUB;
	callop->op_ppaddr = PL_ppaddr[OP_ENTERSUB];
	cUNOPx(callop)->op_first = cvop;
	callop->op_flags = OPf_STACKED | OPf_KIDS;
	cvop->op_next = callop;
	return callop;
}

#define apply_retfilter_to_psub_gen_calls(op, filter, root, opmap) \
	THX_apply_retfilter_to_psub_gen_calls(aTHX_ op, filter, root, opmap)
static void THX_apply_retfilter_to_psub_gen_calls(pTHX_ OP *op, CV *filter,
	OP *root, PTR_TBL_t *opmap)
{
	switch(op->op_type) {
		case OP_LEAVESUB: case OP_LEAVESUBLV: {
			OP *canoniseop = newOP(OP_PUSHMARK, 0);
			OP *callop = gen_filter_call(filter);
			OP *cvop = cUNOPx(callop)->op_first;
			canoniseop->op_ppaddr =
				pp_canonise_retvalues_for_block;
			link_op(callop, canoniseop);
			link_op(op, callop);
			canoniseop->op_next = cvop;
			callop->op_next = op;
			ptr_table_store(opmap, op, canoniseop);
			ptr_table_store(opmap, callop, callop);
		} break;
		case OP_RETURN: {
			OP *copymarkop = newOP(OP_PUSHMARK, 0);
			OP *canoniseop = newOP(OP_PUSHMARK, 0);
			OP *callop = gen_filter_call(filter);
			OP *cvop = cUNOPx(callop)->op_first;
			copymarkop->op_ppaddr = pp_copymark;
			canoniseop->op_ppaddr = pp_canonise_retvalues_for_sub;
			link_op(callop, canoniseop);
			link_op(callop, copymarkop);
			link_op(op, callop);
			copymarkop->op_next = canoniseop;
			canoniseop->op_next = cvop;
			callop->op_next = op;
			ptr_table_store(opmap, op, copymarkop);
			ptr_table_store(opmap, callop, callop);
		} break;
		case OP_LEAVETRY: {
			/*
			 * a return op nested inside an eval{} returns from
			 * the eval, not from the sub, so should not be
			 * modified here.
			 */
			return;
		} break;
	}
	if(op->op_flags & OPf_KIDS) {
		OP *kid;
		for(kid = cUNOPx(op)->op_first; kid; kid = kid->op_sibling) {
			apply_retfilter_to_psub_gen_calls(kid, filter,
								root, opmap);
		}
	}
}

#define apply_retfilter_to_psub_relink_ops(op, opmap) \
	THX_apply_retfilter_to_psub_relink_ops(aTHX_ op, opmap)
static void THX_apply_retfilter_to_psub_relink_ops(pTHX_
	OP *op, PTR_TBL_t *opmap)
{
	if(ptr_table_fetch(opmap, op) != op) {
		OP *newop;
		if((newop = ptr_table_fetch(opmap, op->op_next)))
			op->op_next = newop;
		switch(op->op_type) {
			case OP_AND:
			case OP_ANDASSIGN:
			case OP_COND_EXPR:
			case_OP_DOR_
			case_OP_DORASSIGN_
			case_OP_ENTERWHEN_
			case OP_GREPWHILE:
			case OP_MAPWHILE:
			case_OP_ONCE_
			case OP_OR:
			case OP_ORASSIGN:
			case OP_RANGE:
			{
				if((newop = ptr_table_fetch(opmap,
						cLOGOPx(op)->op_other)))
					cLOGOPx(op)->op_other = newop;
			} break;
		}
	}
	if(op->op_flags & OPf_KIDS) {
		OP *kid;
		for(kid = cUNOPx(op)->op_first; kid; kid = kid->op_sibling) {
			apply_retfilter_to_psub_relink_ops(kid, opmap);
		}
	}
}

#define apply_retfilter_to_psub(target, filter) \
	THX_apply_retfilter_to_psub(aTHX_ target, filter)
static void THX_apply_retfilter_to_psub(pTHX_ CV *target, CV *filter)
{
	OP *root, *blockmarkop;
	PTR_TBL_t *opmap;
	if(CvDEPTH(target)) croak("can't modify active subroutine");
	root = CvROOT(target);
	OP_REFCNT_LOCK;
	if(OpREFCNT(root) > 1) {
		OP_REFCNT_UNLOCK;
		croak("can't modify shared code%s",
			CvCLONED(target) ?
				" (closure sharing with its prototype?)"
			: CvCLONE(target) ?
				" (closure prototype sharing with closures?)"
			: "");
	}
	blockmarkop = newOP(OP_PUSHMARK, 0);
	blockmarkop->op_ppaddr = pp_blockmark;
	blockmarkop->op_next = CvSTART(target);
	link_op(root, blockmarkop);
	CvSTART(target) = blockmarkop;
	opmap = ptr_table_new();
	apply_retfilter_to_psub_gen_calls(root, filter, root, opmap);
	apply_retfilter_to_psub_relink_ops(root, opmap);
	OP_REFCNT_UNLOCK;
	ptr_table_free(opmap);
}

MODULE = Sub::Filter PACKAGE = Sub::Filter

PROTOTYPES: DISABLE

void
mutate_sub_filter_return(CV *target, CV *filter)
PROTOTYPE: $$
CODE:
	if(!CvROOT(target) && !CvXSUB(target))
		croak("can't apply return filter to undefined subroutine");
	if(CvISXSUB(target)) {
		apply_retfilter_to_xsub(target, filter);
	} else {
		apply_retfilter_to_psub(target, filter);
	}

void
_test_xs(...)
PROTOTYPE: @
PREINIT:
	AV *av;
	I32 i, len;
PPCODE:
	av = get_av("Sub::Filter::got_in", 1);
	av_clear(av);
	for(i = 0; i != items; i++)
		av_store(av, i, SvREFCNT_inc(ST(i)));
	av = get_av("Sub::Filter::want_out", 1);
	len = av_len(av) + 1;
	for(i = 0; i != len; i++)
		XPUSHs(sv_2mortal(SvREFCNT_inc(*av_fetch(av, i, 0))));
