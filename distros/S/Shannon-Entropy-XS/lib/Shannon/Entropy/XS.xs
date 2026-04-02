#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

int makehist (unsigned char * str, int * hist, int len) {
	int chars[256];
	int histlen = 0;
	for (int i = 0; i < 256; i++) chars[i]=-1;
	for (int i = 0; i < len; i++) {
		if(chars[(int)str[i]] == -1){
			chars[(int)str[i]] = histlen;
			histlen++;
		}
		hist[chars[(int)str[i]]]++;
	}
	return histlen;
}

double entropy (char * str) {
	int len = strlen(str);
	int * hist = (int*)calloc(len,sizeof(int));
	int histlen = makehist(str, hist, len);
	double out = 0;
	for (int i = 0; i < histlen; i++) {
		out -= (double)hist[i] / len * log2((double)hist[i] / len);
	}
	return out;
}

#if PERL_VERSION >= 14
static XOP shannon_xop;

static OP *
shannon_entropy_op(pTHX) {
	dSP;
	SV *sv;
	int evap_step = -1;
	I32 ax = TOPMARK + 1;
	I32 items = (SP - PL_stack_base - TOPMARK) - 1;
	if (items < 1)
		croak("entropy requires at least 1 argument");
	sv = PL_stack_base[ax];
	sv = newSVnv(entropy(SvPV_nolen(sv)));
	SP = PL_stack_base + POPMARK;
	EXTEND(SP, 1);
	PUSHs(sv);
	PUTBACK;
	return NORMAL;
}

static OP *
shannon_ck_entropy(pTHX_ OP *entersubop, GV *namegv, SV *protosv) {
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(protosv);
	entersubop->op_ppaddr = shannon_entropy_op;
	return entersubop;
}
#endif

MODULE = Shannon::Entropy::XS  PACKAGE = Shannon::Entropy::XS
PROTOTYPES: ENABLE

SV *
entropy(string)
	SV * string;
	CODE:
		RETVAL = newSVnv(entropy(SvPV_nolen(string)));
	OUTPUT:
		RETVAL

BOOT:
	{
		/* Register custom op - XOP API requires 5.14+ */
#if PERL_VERSION >= 14
		XopENTRY_set(&shannon_xop, xop_name, "shannon");
		XopENTRY_set(&shannon_xop, xop_desc, "shannon entropy");
		XopENTRY_set(&shannon_xop, xop_class, OA_BASEOP);
		Perl_custom_op_register(aTHX_ shannon_entropy_op, &shannon_xop);
		CV* shannon_entropy_cv = get_cv("Shannon::Entropy::XS::entropy", 0);
		cv_set_call_checker(shannon_entropy_cv, shannon_ck_entropy, (SV *)shannon_entropy_cv);
#endif
	}


