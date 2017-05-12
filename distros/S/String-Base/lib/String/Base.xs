#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef newSVpvs_share
# define newSVpvs_share(STR) newSVpvn_share(""STR"", sizeof(STR)-1, 0)
#endif /* !newSVpvs_share */

#ifndef SvSHARED_HASH
# define SvSHARED_HASH(SV) SvUVX(SV)
#endif /* !SvSHARED_HASH */

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

#ifndef pad_alloc
# define pad_alloc(optype, tmptype) Perl_pad_alloc(aTHX_ optype, tmptype)
#endif /* !pad_alloc */

static SV *base_hint_key_sv;
static U32 base_hint_key_hash;
static OP *(*nxck_substr)(pTHX_ OP *o);
static OP *(*nxck_index)(pTHX_ OP *o);
static OP *(*nxck_rindex)(pTHX_ OP *o);
static OP *(*nxck_pos)(pTHX_ OP *o);

#define current_base() THX_current_base(aTHX)
static IV THX_current_base(pTHX)
{
	HE *base_ent = hv_fetch_ent(GvHV(PL_hintgv), base_hint_key_sv, 0,
					base_hint_key_hash);
	return base_ent ? SvIV(HeVAL(base_ent)) : 0;
}

static OP *myck_substr(pTHX_ OP *op)
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
		sop = pop->op_sibling;
		if(!sop) goto bad_ops;
		iop = sop->op_sibling;
		if(!iop) goto bad_ops;
		rest = iop->op_sibling;
		iop->op_sibling = NULL;
		iop = newBINOP(OP_I_SUBTRACT, 0,
				op_contextualize(iop, G_SCALAR),
				newSVOP(OP_CONST, 0, newSViv(base)));
		iop->op_sibling = rest;
		sop->op_sibling = iop;
	}
	return nxck_substr(aTHX_ op);
}

static OP *myck_index(pTHX_ OP *op)
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
		hop = pop->op_sibling;
		if(!hop) goto bad_ops;
		nop = hop->op_sibling;
		if(!nop) goto bad_ops;
		iop = nop->op_sibling;
		if(iop) {
			OP *rest = iop->op_sibling;
			iop->op_sibling = NULL;
			iop = newBINOP(OP_I_SUBTRACT, 0,
					op_contextualize(iop, G_SCALAR),
					newSVOP(OP_CONST, 0, newSViv(base)));
			iop->op_sibling = rest;
			nop->op_sibling = iop;
		}
		op = (op->op_type == OP_INDEX ? nxck_index : nxck_rindex)
			(aTHX_ op);
		if((PL_opargs[op->op_type] & OA_TARGET) && !op->op_targ)
			op->op_targ = pad_alloc(op->op_type, SVs_PADTMP);
		return newBINOP(OP_I_ADD, 0, op_contextualize(op, G_SCALAR),
				newSVOP(OP_CONST, 0, newSViv(base)));
	} else {
		return nxck_substr(aTHX_ op);
	}
}

static OP *pp_dup(pTHX)
{
	dSP;
	SV *val = TOPs;
	XPUSHs(val);
	PUTBACK;
	return PL_op->op_next;
}

#define gen_dup_op(argop) THX_gen_dup_op(aTHX_ argop)
static OP *THX_gen_dup_op(pTHX_ OP *argop)
{
	OP *dupop;
	NewOpSz(0, dupop, sizeof(UNOP));
	dupop->op_type = OP_RAND;
	dupop->op_ppaddr = pp_dup;
	cUNOPx(dupop)->op_flags = OPf_KIDS;
	cUNOPx(dupop)->op_first = argop;
	return dupop;
}

#define gen_foldsafe_null_op() THX_gen_foldsafe_null_op(aTHX)
static OP *THX_gen_foldsafe_null_op(pTHX)
{
	OP *op = newOP(OP_PUSHMARK, 0);
	op->op_type = OP_RAND;
	op->op_ppaddr = PL_ppaddr[OP_NULL];
	return op;
}

static OP *myck_pos(pTHX_ OP *op)
{
	IV base;
	if((base = current_base()) != 0) {
		op = nxck_pos(aTHX_ op);
		if((PL_opargs[op->op_type] & OA_TARGET) && !op->op_targ)
			op->op_targ = pad_alloc(op->op_type, SVs_PADTMP);
		return newCONDOP(0,
			newUNOP(OP_DEFINED, 0,
				gen_dup_op(op_contextualize(op, G_SCALAR))),
			newBINOP(OP_I_ADD, 0, gen_foldsafe_null_op(),
				newSVOP(OP_CONST, 0, newSViv(base))),
			newOP(OP_NULL, 0));
	} else {
		return nxck_pos(aTHX_ op);
	}
}

MODULE = String::Base PACKAGE = String::Base

PROTOTYPES: DISABLE

BOOT:
	base_hint_key_sv = newSVpvs_share("String::Base/base");
	base_hint_key_hash = SvSHARED_HASH(base_hint_key_sv);
	nxck_substr = PL_check[OP_SUBSTR]; PL_check[OP_SUBSTR] = myck_substr;
	nxck_index = PL_check[OP_INDEX]; PL_check[OP_INDEX] = myck_index;
	nxck_rindex = PL_check[OP_RINDEX]; PL_check[OP_RINDEX] = myck_index;
	nxck_pos = PL_check[OP_POS]; PL_check[OP_POS] = myck_pos;

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
