#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <math.h>

#if PERL_VERSION >= 14
static XOP entropy_xop;
#endif

static int makehist(const unsigned char *str, int *hist, int len) {
	int chars[256];
	int histlen = 0, i;
	for (i = 0; i < 256; i++) chars[i] = -1;
	for (i = 0; i < len; i++) {
		int c = (int)str[i];
		if (chars[c] == -1) {
			chars[c] = histlen;
			histlen++;
		}
		hist[chars[c]]++;
	}
	return histlen;
}

static double entropy(const char *str) {
	int len = strlen(str);
	int hist[256] = {0};  /* Max 256 unique chars, stack allocated */
	int histlen, i;
	double out = 0.0;
	if (len == 0) return 0.0;
	histlen = makehist((const unsigned char *)str, hist, len);
	for (i = 0; i < histlen; i++) {
		double p = (double)hist[i] / len;
		out -= p * log2(p);
	}
	return out;
}

#if PERL_VERSION >= 14

static OP* pp_entropy(pTHX) {
	dSP;
	SV *sv = TOPs;
	STRLEN len;
	const char *str = SvPV(sv, len);
	double result = entropy(str);
	POPs;
	mPUSHn(result);
	RETURN;
}

static OP* entropy_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
	OP *pushop, *argop, *nextop, *newop;
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(ckobj);
	pushop = cLISTOPx(entersubop)->op_first;
	if (!pushop) return entersubop;
	if (pushop->op_type == OP_NULL && cLISTOPx(pushop)->op_first) {
		pushop = cLISTOPx(pushop)->op_first;
	}
	argop = OpSIBLING(pushop);
	if (!argop) return entersubop;
	nextop = OpSIBLING(argop);
	if (!nextop) return entersubop;
	if (OpSIBLING(nextop)) return entersubop;
	OpMORESIB_set(pushop, nextop);
	OpLASTSIB_set(argop, NULL);
	newop = newUNOP(OP_CUSTOM, 0, argop);
	newop->op_ppaddr = pp_entropy;
	op_free(entersubop);
	return newop;
}

#endif

MODULE = Shannon::Entropy::XS  PACKAGE = Shannon::Entropy::XS
PROTOTYPES: ENABLE

double
entropy(string)
	SV *string
	CODE:
		STRLEN len;
		const char *str = SvPV(string, len);
		RETVAL = entropy(str);
	OUTPUT:
		RETVAL

BOOT:
#if PERL_VERSION >= 14
{
	CV *entropy_cv;
	XopENTRY_set(&entropy_xop, xop_name, "entropy");
	XopENTRY_set(&entropy_xop, xop_desc, "Shannon entropy calculation");
	Perl_custom_op_register(aTHX_ pp_entropy, &entropy_xop);
	entropy_cv = get_cv("Shannon::Entropy::XS::entropy", 0);
	if (entropy_cv) {
		cv_set_call_checker(entropy_cv, entropy_call_checker, (SV *)entropy_cv);
	}
}
#endif
