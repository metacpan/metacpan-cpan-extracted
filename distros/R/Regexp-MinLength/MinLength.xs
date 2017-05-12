#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_nolen
#include "ppport.h"

#include "regcomp.h"
#include "const-c.inc"
#if (PERL_VERSION < 11)
#define RETURNVALUE re->minlen
#else
#define RETURNVALUE re->sv_any->minlen
#endif

MODULE = Regexp::MinLength		PACKAGE = Regexp::MinLength	PREFIX = Regexp::MinLength_

INCLUDE: const-xs.inc
PROTOTYPES: DISABLE

int
MinLength(rv)
	SV *rv;
	
	PREINIT:
	const SV * const pattern = rv;
	char *ptr;
#if (PERL_VERSION < 11)
	regexp *re;
#else
	REGEXP *re;
#endif
	int ret;
	int len;
	PMOP *pm;
	U32 flags;


	CODE:

	re = pregcomp(rv,0);
	if (!re) {
		croak("Cannot compile regexp");
	}

	ret = RETURNVALUE;

	RETVAL = ret;
	OUTPUT:
	RETVAL


MODULE = Regexp::MinLength		PACKAGE = Regexp::MinLength
