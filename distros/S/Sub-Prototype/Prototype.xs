#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sub::Prototype  PACKAGE = Sub::Prototype

void
set_prototype (code, prototype)
		CV *code
		char *prototype
	CODE:
		sv_setpv ((SV *)code, prototype);
