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
# ifdef newSVpvn_share
#  define newSVpvs_share(STR) newSVpvn_share(""STR"", sizeof(STR)-1, 0)
# else /* !newSVpvn_share */
#  define newSVpvs_share(STR) newSVpvn(""STR"", sizeof(STR)-1)
#  define SvSHARED_HASH(SV) 0
# endif /* !newSVpvn_share */
#endif /* !newSVpvs_share */

#ifndef SvSHARED_HASH
# define SvSHARED_HASH(SV) SvUVX(SV)
#endif /* !SvSHARED_HASH */

#ifndef SVfARG
# define SVfARG(p) ((void*)(p))
#endif /* !SVfARG */

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

#ifndef qerror
# define qerror(m) Perl_qerror(aTHX_ m)
#endif /* !qerror */

#if PERL_VERSION_GE(5,9,5)
# define PL_parser_exists PL_parser
# define PL_expect (PL_parser->expect)
#else /* <5.9.5 */
# define PL_parser_exists 1
#endif /* <5.9.5 */

static SV *hint_key_sv;
static U32 hint_key_hash;
static OP *(*THX_nxck_rv2cv)(pTHX_ OP *o);

#define in_strictdecl() THX_in_strictdecl(aTHX)
static bool THX_in_strictdecl(pTHX)
{
	HE *ent = hv_fetch_ent(GvHV(PL_hintgv), hint_key_sv, 0, hint_key_hash);
	return ent && SvTRUE(HeVAL(ent));
}

static OP *THX_myck_rv2cv(pTHX_ OP *op)
{
	OP *aop;
	GV *gv;
	op = THX_nxck_rv2cv(aTHX_ op);
	if(op->op_type == OP_RV2CV && (op->op_flags & OPf_KIDS) &&
			(aop = cUNOPx(op)->op_first) && aop->op_type == OP_GV &&
			PL_parser_exists && PL_expect == XOPERATOR &&
			in_strictdecl() && (gv = cGVOPx_gv(aop)) &&
			(!PERL_VERSION_GE(5,21,4) || SvTYPE(gv) == SVt_PVGV) &&
			!GvCVu(gv)) {
		SV *name = sv_newmortal();
		gv_efullname3(name, gv, NULL);
		qerror(mess("Undeclared subroutine &%"SVf"", SVfARG(name)));
	}
	return op;
}

MODULE = Sub::StrictDecl PACKAGE = Sub::StrictDecl

PROTOTYPES: DISABLE

BOOT:

	hint_key_sv = newSVpvs_share("Sub::StrictDecl/strict");
	hint_key_hash = SvSHARED_HASH(hint_key_sv);
	wrap_op_checker(OP_RV2CV, THX_myck_rv2cv, &THX_nxck_rv2cv);

void
import(SV *classname)
PREINIT:
	SV *val;
	HE *he;
CODE:
	PERL_UNUSED_VAR(classname);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	val = newSVsv(&PL_sv_yes);
	he = hv_store_ent(GvHV(PL_hintgv), hint_key_sv, val, hint_key_hash);
	if(he) {
		val = HeVAL(he);
		SvSETMAGIC(val);
	} else {
		SvREFCNT_dec(val);
	}

void
unimport(SV *classname)
CODE:
	PERL_UNUSED_VAR(classname);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	(void) hv_delete_ent(GvHV(PL_hintgv), hint_key_sv, G_DISCARD,
		hint_key_hash);
