#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#define sv_defined(sv) (sv && (SvIOK(sv) || SvNOK(sv) || SvPOK(sv) || SvROK(sv)))

MODULE = PerlX::ArraySkip::XS		PACKAGE = PerlX::ArraySkip::XS

INCLUDE: const-xs.inc

void
arrayskip (...)
PROTOTYPE: @
PPCODE:
{
	int i;
	
	if (items == 0)
	{
		XSRETURN(0);
	}
	
	for (i = 1; i <= items; i++)
	{
		PUSHs(ST(i));
	}
	
	XSRETURN(items - 1);
}

