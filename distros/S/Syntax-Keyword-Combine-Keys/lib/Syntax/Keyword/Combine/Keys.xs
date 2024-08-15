#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
 
#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"

I32 list_length, itter;
AV *real_evil; /* but it works... */

enum {
	FIRST_EMPTY_NO      = (1<<0),
	FIRST_RET_YES       = (1<<3),
};
 
#define allocLOGOP_CUSTOM(func, flags, first, other)  MY_allocLOGOP_CUSTOM(aTHX_ func, flags, first, other)
static LOGOP *MY_allocLOGOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *other)
{
	LOGOP *logop;
	NewOp(1101, logop, 1, LOGOP);

	logop->op_type = OP_CUSTOM;
	logop->op_ppaddr = func;
	logop->op_flags = OPf_KIDS | (U8)(flags);
	logop->op_first = first;
	logop->op_other = other;

	return logop;
}
 
static OP *build_keys(pTHX_ OP *block, OP *list, OP *(*keys)(pTHX), OP *(*loop)(pTHX), U8 op_private) {
	OP *blockstart = LINKLIST(block);

	block = newUNOP(OP_NULL, 0, block);
	block->op_next = block;

	OP *startop = list;
	if(startop->op_type != OP_LIST)
	startop = newLISTOP(OP_LIST, 0, startop, NULL);
	op_sibling_splice(startop, cLISTOPx(startop)->op_first, 0, block);
	startop->op_type = OP_CUSTOM;
	startop->op_ppaddr = keys;

	LOGOP *whileop = allocLOGOP_CUSTOM(loop, 0, startop, blockstart);
	whileop->op_private = startop->op_private = op_private;

	OpLASTSIB_set(startop, (OP *)whileop);

	whileop->op_next = LINKLIST(startop);
	startop->op_next = (OP *)whileop;
	cUNOPx(block)->op_first->op_next = (OP *)whileop;

	optimize_optree(block);
	PL_rpeepp(aTHX_ blockstart);
	finalize_optree(block);

	return (OP *)whileop;
}

static OP *pp_keys(pTHX)
{
	dSP;
	HV *dedupe = get_hv("HASH", GV_ADD);
	hv_undef(dedupe);
	AV* keys = newAV();
	int i, len;
	SV *pk, *pv;
	while (TOPs) {
		pv = POPs;
		pk = POPs;
		if (pk && SvOK(pk) && !hv_exists_ent(dedupe, pk, 0)) {
			hv_store_ent(dedupe, sv_mortalcopy(pk), sv_mortalcopy(pv), 0);
			av_push(keys, newSVsv(pk));
		}
	}
	SAVESPTR(dedupe);
	PUSHMARK(sp);
	len = av_len(keys) + 1;
	sortsv(AvARRAY(keys), len, Perl_sv_cmp_locale);
	for (i = 0; i < len; i++) PUSHs(sv_mortalcopy(av_shift(keys)));
	PUTBACK;
	list_length = PL_stack_sp - (PL_stack_base + *PL_markstack_ptr--);
	itter = 1;
	real_evil = newAV(); 
	SAVESPTR(real_evil);
	SAVEI32(itter);
	SAVEI32(list_length);

	PL_stack_sp = PL_stack_base + TOPMARK + 1;
	PUSHMARK(PL_stack_sp);

	SAVE_DEFSV;
	SV *src = PL_stack_base[-1];
	if(SvPADTMP(src)) {
		src = PL_stack_base[-1] = sv_mortalcopy(src);
		PL_tmps_floor++;
	}
	SvTEMP_off(src);
	DEFSV_set(src);
	PUTBACK;
	
	return (cLOGOPx(PL_op->op_next))->op_other;
}
 

static OP *pp_loop(pTHX)
{
	dSP;
	dPOPss;
	int len, i, loop;
	AV *returned = newAV();
	loop = 1;
	while (loop) {
		av_push(returned, sv_mortalcopy(sv));
		sv = POPs; 
		if ( sv_cmp(sv, PL_stack_base[list_length - 2]) == 0 && sv_cmp(TOPs, PL_stack_base[list_length - 2]) != 0 )  {
			PUSHs(sv);
			loop = 0;
		}
	}

	len = av_len(returned) + 1;
 	for (i = 0; i < len; i++) av_push(real_evil, av_pop(returned));	

	if (itter < list_length) {
		SV *src = PL_stack_base[itter - 1];
		SvTEMP_off(src);
		DEFSV_set(src);
		if(SvPADTMP(src)) {
			src = PL_stack_base[itter - 1] = sv_mortalcopy(src);
			PL_tmps_floor++;
		}
		SAVE_DEFSV;
		PUTBACK;
		itter++;
		return cLOGOP->op_other;
	}

	HV *dedupe = get_hv("HASH", GV_ADD);
	hv_undef(dedupe);
	PUSHMARK(sp);
	len = av_len(real_evil) + 1;
	for (i = 0; i < len; i++) PUSHs(newSVsv(av_shift(real_evil)));	
	SAVETMPS;
	PUTBACK;

	return PL_op->op_next;
}
 
static int build_ckeys(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
	*out = build_keys(aTHX_ args[0]->op, args[1]->op,
		&pp_keys, &pp_loop, SvIV((SV *)hookdata));
	return KEYWORD_PLUGIN_EXPR;
}
 
static const struct XSParseKeywordPieceType pieces_blocklist[] = {
	XPK_BLOCK_LISTCTX,
	XPK_LISTEXPR_LISTCTX,
	{0},
};
 
static const struct XSParseKeywordHooks hooks_ckeys = {
	.permit_hintkey = "Syntax::Keyword::Combine::Keys/ckeys",
	.pieces = pieces_blocklist,
	.build = &build_ckeys,
};
 
MODULE = Syntax::Keyword::Combine::Keys    PACKAGE = Syntax::Keyword::Combine::Keys
 
BOOT:
	boot_xs_parse_keyword(0.08);

	register_xs_parse_keyword("ckeys", &hooks_ckeys,
		newSViv(FIRST_EMPTY_NO |FIRST_RET_YES));
