#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <string.h>

double PRECISION = 0;
double OFFSET = 0.5555555;

static SV * new (double num) {
        dTHX;
	AV * n = newAV();
	av_push(n, newSVnv(num));
	AV * e = newAV();
	av_push(e, newSVnv(num));
	av_push(n, newRV_noinc((SV*)e));
        return sv_bless(newRV_noinc((SV*)n), gv_stashsv(newSVpv("Number::Equation::XS", 20), 0));
}

static double precise (double num) {
 	if (PRECISION) {
		num = num >= 0
			? PRECISION * floor(( num + ( OFFSET * PRECISION )) / PRECISION)
			: PRECISION * ceil(( num - OFFSET * PRECISION) / PRECISION);
	}
	return num;
}

MODULE = Number::Equation::XS  PACKAGE = Number::Equation::XS
PROTOTYPES: ENABLE
FALLBACK: TRUE

SV * new (...)
	CODE:
		double num = SvNV(ST(1));
		if (ST(2) && SvOK(ST(2)) && (SvTYPE(ST(2)) == SVt_NV || SvTYPE(ST(2)) == SVt_IV)) {
			PRECISION = SvNV(ST(2));
		}
		if (ST(3) && SvOK(ST(3)) && SvTYPE(ST(3)) == SVt_NV) {
			OFFSET = SvNV(ST(3));
		}
		RETVAL = new(num);
	OUTPUT:
		RETVAL


SV * stringify (self, ...)
	SV * self
	OVERLOAD: \"\"
	CODE: 
		AV * s = (AV*)SvRV(self);
		double val = SvNV(*av_fetch(s, 0, 0));
		RETVAL = newSVnv(precise(val));
	OUTPUT:
		RETVAL


SV * add (self, num, ...)
	SV * self
	SV * num
	OVERLOAD: +
	CODE:
		AV * s = (AV*)SvRV(self);
		AV * last = (AV*)SvRV(*av_fetch(s, -1, 0));
		av_push(last, newSVpv("+", 1));
		av_push(last, newSVsv(num));
		double val = SvNV(*av_fetch(s, 0, 0));
		val = val + SvNV(num);
		av_store(s, 0, newSVnv(val));
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL

SV * mult (self, num, ...)
	SV * self
	SV * num
	OVERLOAD: *
	CODE:
		AV * s = (AV*)SvRV(self);
		AV * last = (AV*)SvRV(*av_fetch(s, -1, 0));
		av_push(last, newSVpv("*", 1));
		av_push(last, newSVsv(num));
		double val = SvNV(*av_fetch(s, 0, 0));
		val = val * SvNV(num);
		av_store(s, 0, newSVnv(val));
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL

SV * subt (self, num, ...)
	SV * self
	SV * num
	OVERLOAD: -
	CODE:
		AV * s = (AV*)SvRV(self);
		double val = SvNV(*av_fetch(s, 0, 0));
		if (ST(2) && SvOK(ST(2)) && SvIV(ST(2)) > 0) {
			av_unshift(s, 1);
			AV * n = newAV();
			av_push(n, newSVsv(num));
			av_push(n, newSVpv("-", 1));
			av_store(s, 1, newRV_noinc((SV*)n));
			val = SvNV(num) - val;	
		} else {
			AV * last = (AV*)SvRV(*av_fetch(s, -1, 0));
			av_push(last, newSVpv("-", 1));
			av_push(last, newSVsv(num));
			val = val - SvNV(num);
		}
		av_store(s, 0, newSVnv(val));
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL

SV * div (self, num, ...)
	SV * self
	SV * num
	OVERLOAD: /
	CODE:
		AV * s = (AV*)SvRV(self);
		double val = SvNV(*av_fetch(s, 0, 0));
		if (ST(2) && SvOK(ST(2)) && SvIV(ST(2)) > 0) {
			av_unshift(s, 1);
			AV * n = newAV();
			av_push(n, newSVsv(num));
			av_push(n, newSVpv("/", 1));
			av_store(s, 1, newRV_noinc((SV*)n));
			val = SvNV(num) / val;	
		} else {
			AV * last = (AV*)SvRV(*av_fetch(s, -1, 0));
			av_push(last, newSVpv("/", 1));
			av_push(last, newSVsv(num));
			val = val / SvNV(num);
		}
		av_store(s, 0, newSVnv(val));
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL


SV * mod (self, num, ...)
	SV * self
	SV * num
	OVERLOAD: %
	CODE:
		AV * s = (AV*)SvRV(self);
		long val = SvIV(*av_fetch(s, 0, 0));
		if (ST(2) && SvOK(ST(2)) && SvIV(ST(2)) > 0) {
			av_unshift(s, 1);
			AV * n = newAV();
			av_push(n, newSVsv(num));
			av_push(n, newSVpv("%", 1));
			av_store(s, 1, newRV_noinc((SV*)n));
			val = SvIV(num) % val;	
		} else {
			AV * last = (AV*)SvRV(*av_fetch(s, -1, 0));
			av_push(last, newSVpv("%", 1));
			av_push(last, newSVsv(num));
			val = val % SvIV(num);
		}
		av_store(s, 0, newSVnv(val));
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL

SV * exp (self, num, ...)
	SV * self
	SV * num
	OVERLOAD: **
	CODE:
		AV * s = (AV*)SvRV(self);
		double val = SvNV(*av_fetch(s, 0, 0));
		if (ST(2) && SvOK(ST(2)) && SvIV(ST(2)) > 0) {
			av_unshift(s, 1);
			AV * n = newAV();
			av_push(n, newSVsv(num));
			av_push(n, newSVpv("**", 2));
			av_store(s, 1, newRV_noinc((SV*)n));
			val = pow(SvNV(num), val);	
		} else {
			AV * last = (AV*)SvRV(*av_fetch(s, -1, 0));
			av_push(last, newSVpv("**", 2));
			av_push(last, newSVsv(num));
			val = pow(val, SvNV(num));
		}
		av_store(s, 0, newSVnv(val));
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL


SV * equation (self, ...)
	SV * self
	CODE:
		AV * s = (AV*)SvRV(self);
		char * query = malloc(sizeof(char)*5432);
		int closing = 0;
		int l = av_len(s);
		for (int i = 1; i <= l; i++) {
			AV * equation = (AV*)SvRV(*av_fetch(s, i, 0));
			int el = av_len(equation) + 1;
			for (int x = 0; x < el / 2; x++) {
				strcat(query, "(");
			}
			strcat(query, SvPV_nolen(*av_fetch(equation, 0, 0)));
			for (int x = 1; x <= el - 1; x++) {
				char * operator = SvPV_nolen(*av_fetch(equation, x++, 0));
				char * val = x <= el - 1 ? SvPV_nolen(*av_fetch(equation, x, 0)) : "";
				strcat(query, " ");
				strcat(query, operator);
				strcat(query, " ");
				if (val != "") {
					strcat(query, val);
					strcat(query, ")");
				} else {
					closing++;
				}
			}
		}

		for (int x = 0; x < closing; x++) {
			strcat(query, ")");
		}

		if (PRECISION) {
			strcat(query, " ≈ ");
		} else {
			strcat(query, " = ");
		}

		double p = precise(SvNV(*av_fetch(s, 0, 0)));
		SV * fun = newSVnv(p);	

		strcat(query, SvPV_nolen(fun));

		RETVAL = newSVpv(query, strlen(query));
	OUTPUT:
		RETVAL
