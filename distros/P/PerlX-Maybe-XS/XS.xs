#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#define sv_defined(sv) (sv && (SvIOK(sv) || SvNOK(sv) || SvPOK(sv) || SvROK(sv)))

MODULE = PerlX::Maybe::XS		PACKAGE = PerlX::Maybe::XS		

INCLUDE: const-xs.inc

void
maybe (x, y, ...)
	SV *x
	SV *y
PROTOTYPE: $$@
PPCODE:
{
	int i;
	
	if (sv_defined(x) && sv_defined(y))
	{
		// return ($x, $y, @rest);
		for (i = 0; i <= items; i++)
		{
			PUSHs(ST(i));
		}
		XSRETURN(items);
	}
	else
	{
		// return @rest
		for (i = 2; i <= items; i++)
		{
			PUSHs(ST(i));
		}
		XSRETURN(items - 2);
	}
}

void
provided (chk, x, y, ...)
	SV *chk
	SV *x
	SV *y
PROTOTYPE: $$$@
PPCODE:
{
	int i;
	
	if (SvTRUE(chk))
	{
		// return ($x, $y, @rest);
		for (i = 1; i <= items; i++)
		{
			PUSHs(ST(i));
		}
		XSRETURN(items - 1);
	}
	else
	{
		// return @rest
		for (i = 3; i <= items; i++)
		{
			PUSHs(ST(i));
		}
		XSRETURN(items - 3);
	}
}
