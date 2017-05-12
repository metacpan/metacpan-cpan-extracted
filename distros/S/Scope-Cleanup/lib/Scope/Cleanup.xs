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

#define Q_MUST_PRESERVE_GHOST_CONTEXT (!PERL_VERSION_GE(5,13,7))

static void run_cleanup(pTHX_ void *cleanup_code_ref)
{
#if Q_MUST_PRESERVE_GHOST_CONTEXT
	bool have_ghost_context;
	PERL_CONTEXT ghost_context;
	have_ghost_context = cxstack_ix < cxstack_max;
	if(have_ghost_context) ghost_context = cxstack[cxstack_ix+1];
#endif /* Q_MUST_PRESERVE_GHOST_CONTEXT */
	ENTER;
	SAVETMPS;
	{
		dSP;
		PUSHMARK(SP);
	}
	call_sv((SV*)cleanup_code_ref, G_VOID|G_DISCARD);
#if Q_MUST_PRESERVE_GHOST_CONTEXT
	if(have_ghost_context) cxstack[cxstack_ix+1] = ghost_context;
#endif /* Q_MUST_PRESERVE_GHOST_CONTEXT */
	FREETMPS;
	LEAVE;
}

static OP *pp_establish_cleanup(pTHX)
{
	dSP;
	SV *cleanup_code_ref;
	cleanup_code_ref = newSVsv(POPs);
	SAVEFREESV(cleanup_code_ref);
	SAVEDESTRUCTOR_X(run_cleanup, cleanup_code_ref);
	if(GIMME_V != G_VOID) PUSHs(&PL_sv_undef);
	RETURN;
}

#define gen_establish_cleanup_op(argop) \
		THX_gen_establish_cleanup_op(aTHX_ argop)
static OP *THX_gen_establish_cleanup_op(pTHX_ OP *argop)
{
	OP *estop;
	NewOpSz(0, estop, sizeof(UNOP));
	estop->op_type = OP_RAND;
	estop->op_ppaddr = pp_establish_cleanup;
	cUNOPx(estop)->op_flags = OPf_KIDS;
	cUNOPx(estop)->op_first = argop;
	PL_hints |= HINT_BLOCK_SCOPE;
	return estop;
}

static OP *myck_entersub_establish_cleanup(pTHX_ OP *entersubop,
	GV *namegv, SV *protosv)
{
	OP *pushop, *argop;
	entersubop = ck_entersub_args_proto(entersubop, namegv, protosv);
	pushop = cUNOPx(entersubop)->op_first;
	if(!pushop->op_sibling) pushop = cUNOPx(pushop)->op_first;
	argop = pushop->op_sibling;
	if(!argop) return entersubop;
	pushop->op_sibling = argop->op_sibling;
	argop->op_sibling = NULL;
	op_free(entersubop);
	return gen_establish_cleanup_op(argop);
}

MODULE = Scope::Cleanup PACKAGE = Scope::Cleanup

PROTOTYPES: DISABLE

BOOT:
{
	CV *estc_cv = get_cv("Scope::Cleanup::establish_cleanup", 0);
	cv_set_call_checker(estc_cv, myck_entersub_establish_cleanup,
		(SV*)estc_cv);
}

void
establish_cleanup(...)
PROTOTYPE: $
CODE:
	PERL_UNUSED_VAR(items);
	croak("establish_cleanup called as a function");
