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

#ifndef OpMORESIB_set
# define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
# define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
# define OpMAYBESIB_set(o, sib, parent) ((o)->op_sibling = (sib))
#endif /* !OpMORESIB_set */
#ifndef OpSIBLING
# define OpHAS_SIBLING(o) (cBOOL((o)->op_sibling))
# define OpSIBLING(o) (0 + (o)->op_sibling)
#endif /* !OpSIBLING */

#define Q_MUST_PRESERVE_GHOST_CONTEXT (!PERL_VERSION_GE(5,13,7))

static void THX_run_cleanup(pTHX_ void *cleanup_code_ref)
{
	dSP;
#if Q_MUST_PRESERVE_GHOST_CONTEXT
	bool have_ghost_context;
	PERL_CONTEXT ghost_context;
	have_ghost_context = cxstack_ix < cxstack_max;
	if(have_ghost_context) ghost_context = cxstack[cxstack_ix+1];
#endif /* Q_MUST_PRESERVE_GHOST_CONTEXT */
	PUSHSTACK;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	call_sv((SV*)cleanup_code_ref, G_VOID|G_DISCARD);
	SPAGAIN;
	FREETMPS;
	LEAVE;
	POPSTACK;
#if Q_MUST_PRESERVE_GHOST_CONTEXT
	if(have_ghost_context) cxstack[cxstack_ix+1] = ghost_context;
#endif /* Q_MUST_PRESERVE_GHOST_CONTEXT */
}

static OP *THX_pp_establish_cleanup(pTHX)
{
	dSP;
	SV *cleanup_code_ref;
	cleanup_code_ref = newSVsv(POPs);
	SAVEFREESV(cleanup_code_ref);
	SAVEDESTRUCTOR_X(THX_run_cleanup, cleanup_code_ref);
	if(GIMME_V != G_VOID) PUSHs(&PL_sv_undef);
	RETURN;
}

#define newUNOP_establish_cleanup(argop) \
		THX_newUNOP_establish_cleanup(aTHX_ argop)
static OP *THX_newUNOP_establish_cleanup(pTHX_ OP *argop)
{
	OP *estop;
	NewOpSz(0, estop, sizeof(UNOP));
	estop->op_type = OP_CUSTOM;
	estop->op_ppaddr = THX_pp_establish_cleanup;
	cUNOPx(estop)->op_flags = OPf_KIDS;
	cUNOPx(estop)->op_first = argop;
	OpLASTSIB_set(argop, estop);
	PL_hints |= HINT_BLOCK_SCOPE;
	return estop;
}

static OP *THX_ck_entersub_establish_cleanup(pTHX_ OP *entersubop,
	GV *namegv, SV *protosv)
{
	OP *pushop, *argop, *cvop;
	entersubop = ck_entersub_args_proto(entersubop, namegv, protosv);
	pushop = cUNOPx(entersubop)->op_first;
	if(!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
	argop = OpSIBLING(pushop);
	if(!argop || !(cvop = OpSIBLING(argop)) || OpHAS_SIBLING(cvop))
		return entersubop;
	OpMORESIB_set(pushop, cvop);
	OpLASTSIB_set(argop, NULL);
	op_free(entersubop);
	return newUNOP_establish_cleanup(argop);
}

MODULE = Scope::Cleanup PACKAGE = Scope::Cleanup

PROTOTYPES: DISABLE

BOOT:
{
	CV *estc_cv = get_cv("Scope::Cleanup::establish_cleanup", 0);
	cv_set_call_checker(estc_cv, THX_ck_entersub_establish_cleanup,
		(SV*)estc_cv);
}

void
establish_cleanup(...)
PROTOTYPE: $
CODE:
	PERL_UNUSED_VAR(items);
	croak("establish_cleanup called as a function");
