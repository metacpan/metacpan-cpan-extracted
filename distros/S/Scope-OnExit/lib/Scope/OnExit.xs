#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef SAVEDESTRUCTOR_X
#define SAVEDESTRUCTOR_X SAVEDESTRUCTOR
static void scope_exit(void* block) {
	dTHX;
#else
static void scope_exit(pTHX_ void* block) {
#endif
	dSP;
	PUSHMARK(SP);
	call_sv(block, G_VOID | G_DISCARD | G_NOARGS | G_EVAL | G_KEEPERR);
	SvREFCNT_dec(block);
}

MODULE = Scope::OnExit        PACKAGE = Scope::OnExit

void
on_scope_exit(block)
	CV* block;
	PROTOTYPE: &
	CODE:
		LEAVE;
		SvREFCNT_inc(block);
		SAVEDESTRUCTOR_X(scope_exit, block);
		ENTER;
