#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = SetDualVar		PACKAGE = SetDualVar


void
SetDualVar(variable,string,numeric)
	SV *	variable
	SV *	string
	SV *	numeric
	CODE:
	{
		SvPV(string,na);
		if(!SvPOKp(string) || (!SvNOKp(numeric) && !SvIOKp(numeric)) ) {
			croak("Usage: SetDualVar variable,string,numeric");
		}
		
		sv_setsv(variable,string);
		if(SvNOKp(numeric)) {
			sv_setnv(variable,SvNV(numeric));
		} else {
			sv_setiv(variable,SvIV(numeric));
		}
		SvPOK_on(variable);
	}

