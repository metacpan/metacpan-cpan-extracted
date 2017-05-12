/*
	peephook.h - Helper header file to hook the peephole optimizer (PL_peepp)

	VERSION 0.02

	requires:
		MY_CXT_VARS
		my_peep_enabled(pTHX_ pMY_CXT_ OP*)
		my_peep(pTHX_ pMY_CXT_ COP*, OP*)
*/

#ifndef XS_PEEP_HOOK_H
#define XS_PEEP_HOOK_H

#include "ppport.h"
#include "ptr_table.h"

#define MY_CXT_KEY PACKAGE "::_guts" XS_VERSION
typedef struct{
	peep_t old_peepp;
	PTR_TBL_t* seen;

#ifdef MY_CXT_VARS
	MY_CXT_VARS
#endif
} my_cxt_t;
START_MY_CXT


#define PEEPHOOK_CONTEXT          \
		peep_t old_peepp; \
		PTR_TBL_t* seen;  \

static void my_peep(pTHX_ pMY_CXT_ COP* cop PERL_UNUSED_DECL, OP* o PERL_UNUSED_DECL);

static int  my_peep_enabled(pTHX_ pMY_CXT_ OP* o PERL_UNUSED_DECL);

static void
xs_peephook_dispatcher(pTHX_ pMY_CXT_ COP* cop, OP* o){
	dVAR;
	COP* const oldcop = cop;

	assert(MY_CXT.seen != NULL);

	for(; o; o = o->op_next){
		if(ptr_table_fetch(MY_CXT.seen, o)){
			break;
		}
		ptr_table_store(MY_CXT.seen, o, (void*)TRUE);

		my_peep(aTHX_ aMY_CXT_ cop, o);

		switch(o->op_type){
		case OP_NEXTSTATE:
		case OP_DBSTATE:
			cop = cCOPo; /* for context info */
			break;

		case OP_MAPWHILE:
		case OP_GREPWHILE:
		case OP_AND:
		case OP_OR:
#ifdef pp_dor
		case OP_DOR:
#endif
		case OP_ANDASSIGN:
		case OP_ORASSIGN:
#ifdef pp_dorassign
		case OP_DORASSIGN:
#endif
		case OP_COND_EXPR:
		case OP_RANGE:
#ifdef pp_once
		case OP_ONCE:
#endif
			xs_peephook_dispatcher(aTHX_ aMY_CXT_ cop, cLOGOPo->op_other);
			break;
		case OP_ENTERLOOP:
		case OP_ENTERITER:
			xs_peephook_dispatcher(aTHX_ aMY_CXT_ cop, cLOOPo->op_redoop);
			xs_peephook_dispatcher(aTHX_ aMY_CXT_ cop, cLOOPo->op_nextop);
			xs_peephook_dispatcher(aTHX_ aMY_CXT_ cop, cLOOPo->op_lastop);
			break;
		case OP_SUBST:
#if PERL_BCDVERSION >= 0x5010000
			xs_peephook_dispatcher(aTHX_ aMY_CXT_ cop, cPMOPo->op_pmstashstartu.op_pmreplstart);
#else
			xs_peephook_dispatcher(aTHX_ aMY_CXT_ cop, cPMOPo->op_pmreplstart);
#endif
			break;

		default:
			NOOP;
		}
	}

	cop = oldcop;
}

static void
xs_peephook_peep(pTHX_ OP* const o){
	dVAR;
	dMY_CXT;

	assert(o);

	if(my_peep_enabled(aTHX_ aMY_CXT_ o)){
		assert(MY_CXT.seen == NULL);
		MY_CXT.seen = ptr_table_new();

		xs_peephook_dispatcher(aTHX_ aMY_CXT_ PL_curcop, o);

		ptr_table_free(MY_CXT.seen);
		MY_CXT.seen = NULL;
	}

	MY_CXT.old_peepp(aTHX_ o);
}

#define PEEPHOOK_REGISTER() STMT_START {     \
		MY_CXT.old_peepp = PL_peepp; \
		PL_peepp = xs_peephook_peep; \
	} STMT_END

#endif /* XS_PEEP_HOOK_H */
