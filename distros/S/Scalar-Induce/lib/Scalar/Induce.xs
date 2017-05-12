#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

MODULE = Scalar::Induce								PACKAGE = Scalar::Induce

PROTOTYPES: DISABLED

void
induce(block, var)
	CV* block;
	SV* var;
	PROTOTYPE: &$
	PPCODE:
		SAVESPTR(DEFSV);
		DEFSV = sv_mortalcopy(var);
		while (SvOK(DEFSV)) {
			PUSHMARK(SP);
			call_sv((SV*)block, G_ARRAY | G_NOARGS);
			SPAGAIN;
		}

void
void(...)
	CODE:

