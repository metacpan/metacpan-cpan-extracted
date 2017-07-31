#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef cBOOL
# define cBOOL(x) ((bool)!!(x))
#endif /* !cBOOL */

#ifndef C_ARRAY_LENGTH
# define C_ARRAY_LENGTH(a) (sizeof(a)/sizeof(*(a)))
#endif /* !C_ARRAY_LENGTH */

#ifndef newSVpvs_share
# define newSVpvs_share(STR) newSVpvn_share(""STR"", sizeof(STR)-1, 0)
#endif /* !newSVpvs_share */

#ifndef SvSHARED_HASH
# define SvSHARED_HASH(SV) SvUVX(SV)
#endif /* !SvSHARED_HASH */

#ifndef OpMORESIB_set
# define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
# define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
# define OpMAYBESIB_set(o, sib, parent) ((o)->op_sibling = (sib))
#endif /* !OpMORESIB_set */
#ifndef OpSIBLING
# define OpHAS_SIBLING(o) (cBOOL((o)->op_sibling))
# define OpSIBLING(o) (0 + (o)->op_sibling)
#endif /* !OpSIBLING */

#ifndef op_contextualize
# define scalar(op) Perl_scalar(aTHX_ op)
# define list(op) Perl_list(aTHX_ op)
# define scalarvoid(op) Perl_scalarvoid(aTHX_ op)
# define op_contextualize(op, c) THX_op_contextualize(aTHX_ op, c)
static OP *THX_op_contextualize(pTHX_ OP *o, I32 context)
{
	switch (context) {
		case G_SCALAR: return scalar(o);
		case G_ARRAY:  return list(o);
		case G_VOID:   return scalarvoid(o);
		default:
			croak("panic: op_contextualize bad context");
			return o;
	}
}
#endif /* !op_contextualize */

#if !PERL_VERSION_GE(5,9,3)
typedef OP *(*Perl_check_t)(pTHX_ OP *);
#endif /* <5.9.3 */

#if !PERL_VERSION_GE(5,10,1)
typedef unsigned Optype;
#endif /* <5.10.1 */

#ifndef wrap_op_checker
# define wrap_op_checker(c,n,o) THX_wrap_op_checker(aTHX_ c,n,o)
static void THX_wrap_op_checker(pTHX_ Optype opcode,
	Perl_check_t new_checker, Perl_check_t *old_checker_p)
{
	if(*old_checker_p) return;
	OP_REFCNT_LOCK;
	if(!*old_checker_p) {
		*old_checker_p = PL_check[opcode];
		PL_check[opcode] = new_checker;
	}
	OP_REFCNT_UNLOCK;
}
#endif /* !wrap_op_checker */

#ifndef pad_alloc
# define pad_alloc(optype, tmptype) Perl_pad_alloc(aTHX_ optype, tmptype)
#endif /* !pad_alloc */

static SV *base_hint_key_sv;
static U32 base_hint_key_hash;
static OP *(*THX_nxck_substr)(pTHX_ OP *o);
static OP *(*THX_nxck_index)(pTHX_ OP *o);
static OP *(*THX_nxck_rindex)(pTHX_ OP *o);
static OP *(*THX_nxck_pos)(pTHX_ OP *o);

#define current_base() THX_current_base(aTHX)
static IV THX_current_base(pTHX)
{
	HE *base_ent = hv_fetch_ent(GvHV(PL_hintgv), base_hint_key_sv, 0,
					base_hint_key_hash);
	return base_ent ? SvIV(HeVAL(base_ent)) : 0;
}

static OP *THX_myck_substr(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		OP *pop, *sop, *iop, *rest;
		if(!(op->op_flags & OPf_KIDS)) {
			bad_ops:
			croak("strange op tree prevents applying string base");
		}
		pop = cLISTOPx(op)->op_first;
		if(!(pop->op_type == OP_PUSHMARK ||
				(pop->op_type == OP_NULL &&
					pop->op_targ == OP_PUSHMARK)))
			goto bad_ops;
		sop = OpSIBLING(pop);
		if(!sop) goto bad_ops;
		iop = OpSIBLING(sop);
		if(!iop) goto bad_ops;
		rest = OpSIBLING(iop);
		OpMAYBESIB_set(sop, rest, op);
		OpLASTSIB_set(iop, NULL);
		if(!rest) cLISTOPx(op)->op_last = sop;
		iop = newBINOP(OP_I_SUBTRACT, 0,
				op_contextualize(iop, G_SCALAR),
				newSVOP(OP_CONST, 0, newSViv(base)));
		OpMAYBESIB_set(iop, rest, op);
		OpMORESIB_set(sop, iop);
		if(!rest) cLISTOPx(op)->op_last = iop;
	}
	return THX_nxck_substr(aTHX_ op);
}

static OP *THX_myck_index(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		OP *pop, *hop, *nop, *iop;
		if(!(op->op_flags & OPf_KIDS)) {
			bad_ops:
			croak("strange op tree prevents applying string base");
		}
		pop = cLISTOPx(op)->op_first;
		if(!(pop->op_type == OP_PUSHMARK ||
				(pop->op_type == OP_NULL &&
					pop->op_targ == OP_PUSHMARK)))
			goto bad_ops;
		hop = OpSIBLING(pop);
		if(!hop) goto bad_ops;
		nop = OpSIBLING(hop);
		if(!nop) goto bad_ops;
		iop = OpSIBLING(nop);
		if(iop) {
			OP *rest = OpSIBLING(iop);
			OpMAYBESIB_set(nop, rest, op);
			OpLASTSIB_set(iop, NULL);
			if(!rest) cLISTOPx(op)->op_last = nop;
			iop = newBINOP(OP_I_SUBTRACT, 0,
					op_contextualize(iop, G_SCALAR),
					newSVOP(OP_CONST, 0, newSViv(base)));
			OpMAYBESIB_set(iop, rest, op);
			OpMORESIB_set(nop, iop);
			if(!rest) cLISTOPx(op)->op_last = iop;
		}
		op = (op->op_type == OP_INDEX ? THX_nxck_index :
						THX_nxck_rindex)
			(aTHX_ op);
		if((PL_opargs[op->op_type] & OA_TARGET) && !op->op_targ)
			op->op_targ = pad_alloc(op->op_type, SVs_PADTMP);
		return newBINOP(OP_I_ADD, 0, op_contextualize(op, G_SCALAR),
				newSVOP(OP_CONST, 0, newSViv(base)));
	} else {
		return (op->op_type == OP_INDEX ? THX_nxck_index :
						THX_nxck_rindex)
			(aTHX_ op);
	}
}

static OP *THX_pp_dup(pTHX)
{
	dSP;
	SV *val = TOPs;
	XPUSHs(val);
	PUTBACK;
	return PL_op->op_next;
}

#define newUNOP_dup(argop) THX_newUNOP_dup(aTHX_ argop)
static OP *THX_newUNOP_dup(pTHX_ OP *argop)
{
	OP *dupop;
	NewOpSz(0, dupop, sizeof(UNOP));
#ifdef XopENTRY_set
	dupop->op_type = OP_CUSTOM;
#else /* !XopENTRY_set */
	dupop->op_type = OP_RAND;
#endif /* !XopENTRY_set */
	dupop->op_ppaddr = THX_pp_dup;
	cUNOPx(dupop)->op_flags = OPf_KIDS;
	cUNOPx(dupop)->op_first = argop;
	OpLASTSIB_set(argop, dupop);
	return dupop;
}

static OP *THX_pp_foldsafe_null(pTHX)
{
	return PL_op->op_next;
}

#ifdef XopENTRY_set
static void THX_cpeep_foldsafe_null(pTHX_ OP *o, OP *oldop)
{
	PERL_UNUSED_ARG(oldop);
# if PERL_VERSION_GE(5,19,10)
	op_null(o);
# else /* <5.19.10 */
	PERL_UNUSED_ARG(o);
# endif /* <5.19.10 */
}
#endif /* XopENTRY_set */

#define newOP_foldsafe_null() THX_newOP_foldsafe_null(aTHX)
static OP *THX_newOP_foldsafe_null(pTHX)
{
	OP *op;
	NewOpSz(0, op, sizeof(OP));
#ifdef XopENTRY_set
	op->op_type = OP_CUSTOM;
#else /* !XopENTRY_set */
	op->op_type = OP_RAND;
#endif /* !XopENTRY_set */
	op->op_ppaddr = THX_pp_foldsafe_null;
	op->op_next = op;
	return op;
}

static OP *THX_myck_pos(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		op = THX_nxck_pos(aTHX_ op);
		if((PL_opargs[op->op_type] & OA_TARGET) && !op->op_targ)
			op->op_targ = pad_alloc(op->op_type, SVs_PADTMP);
		return newCONDOP(0,
			newUNOP(OP_DEFINED, 0,
				newUNOP_dup(op_contextualize(op, G_SCALAR))),
			newBINOP(OP_I_ADD, 0, newOP_foldsafe_null(),
				newSVOP(OP_CONST, 0, newSViv(base))),
			newOP(OP_NULL, 0));
	} else {
		return THX_nxck_pos(aTHX_ op);
	}
}

MODULE = String::Base PACKAGE = String::Base

PROTOTYPES: DISABLE

BOOT:
{
#ifdef XopENTRY_set
	struct {
		char const *name, *desc;
		U32 class;
		Perl_cpeep_t THX_cpeep;
		Perl_ppaddr_t THX_pp;
	} const ops_to_register[] = {
		{ "dup", "duplicate", OA_UNOP, (Perl_cpeep_t)0, THX_pp_dup },
		{ "foldsafe_null", "non-foldable null", OA_BASEOP,
			THX_cpeep_foldsafe_null, THX_pp_foldsafe_null },
	}, *otr;
	int i;
	for(i = C_ARRAY_LENGTH(ops_to_register); i--; ) {
		XOP *xop;
		Newxz(xop, 1, XOP);
		otr = &ops_to_register[i];
		XopENTRY_set(xop, xop_name, otr->name);
		XopENTRY_set(xop, xop_desc, otr->desc);
		XopENTRY_set(xop, xop_class, otr->class);
		if(otr->THX_cpeep) XopENTRY_set(xop, xop_peep, otr->THX_cpeep);
		Perl_custom_op_register(aTHX_ otr->THX_pp, xop);
	}
#endif /* XopENTRY_set */
}

BOOT:
{
	base_hint_key_sv = newSVpvs_share("String::Base/base");
	base_hint_key_hash = SvSHARED_HASH(base_hint_key_sv);
	wrap_op_checker(OP_SUBSTR, THX_myck_substr, &THX_nxck_substr);
	wrap_op_checker(OP_INDEX, THX_myck_index, &THX_nxck_index);
	wrap_op_checker(OP_RINDEX, THX_myck_index, &THX_nxck_rindex);
	wrap_op_checker(OP_POS, THX_myck_pos, &THX_nxck_pos);
}

void
import(SV *classname, IV base)
CODE:
	PERL_UNUSED_VAR(classname);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	if(base == 0) {
		(void) hv_delete_ent(GvHV(PL_hintgv), base_hint_key_sv,
				G_DISCARD, base_hint_key_hash);
	} else {
		SV *base_sv = newSViv(base);
		HE *he = hv_store_ent(GvHV(PL_hintgv), base_hint_key_sv,
				base_sv, base_hint_key_hash);
		if(he) {
			SV *val = HeVAL(he);
			SvSETMAGIC(val);
		} else {
			SvREFCNT_dec(base_sv);
		}
	}

void
unimport(SV *classname)
CODE:
	PERL_UNUSED_VAR(classname);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	(void) hv_delete_ent(GvHV(PL_hintgv), base_hint_key_sv,
			G_DISCARD, base_hint_key_hash);
