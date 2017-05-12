/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = Sort::Key::LargeInt		PACKAGE = Sort::Key::LargeInt		

void
encode_largeint(li=NULL)
    SV *li
PPCODE:
    if (!li) 
        li = DEFSV;
    {
	STRLEN len;
	const char *li_pv = SvPV(li, len);
	STRLEN i;
	int neg = 0;
	const char *from;
	const char *start;
	const char *top = li_pv + len;
	STRLEN digits;
	STRLEN chunks;
	STRLEN retlen;
	SV *ret;
	char *ret_pv;
	char *to;

	start = li_pv;

	/* look for sign */
	if (len) {
	    if (*start == '-') {
		start++;
		neg = 1;
	    }
	    else if (*start == '+') {
		start++;
	    }
	}

	/* discard zeros at the left */
	for (; start < top && (*start == '0' || *start == '_'); start++);

	/* count the number of digits in order to preallocate the returned SV buffer */
	for (digits = 0, from = start; from < top; from++) {
	    if (*from >= '0' && *from <= '9')
		digits++;
	    else if (*from != '_')
		break;
	}

	/* calculate target length */
	chunks = (digits + 8 ) / 9;
	retlen = chunks / 127 + 1 + chunks * 4 + 1;

	ret = sv_2mortal(newSV(retlen));
	SvPOK_on(ret);
	to = ret_pv = SvPV_nolen(ret);
	
	/* store number length prefix with sign */
	for (i = chunks; i >= 127; i -= 127)
	    *(to++) = (neg ? 1 : 255);
	*(to++) = (neg ? 128 - i : 128 + i);

	/* compress number */
	from = start;
	while (digits) {
	    int digits_in_chunk = (digits - 1) % 9 + 1;
	    U32 acu = 0;
	    for (i = 0; i < digits_in_chunk; i++, from++) {
		while (*from == '_') from++;
		acu *= 10;
		acu += (*from - '0');
		/* fprintf(stderr, "acu: %d\n", acu); */
	    }
	    if (neg)
		acu = 1000000000 - acu;
	    else
		acu += 1000000000;

	    *(to++) = (acu >> 24) & 255;
	    *(to++) = (acu >> 16) & 255;
	    *(to++) = (acu >> 8) & 255;
	    *(to++) = acu & 255;

	    digits -= digits_in_chunk;	    
	}

	/* adjust return SV */
	*to = '\0';
	SvCUR_set(ret, to - ret_pv);

	if (SvCUR(ret) != retlen - 1) 
	    Perl_croak(aTHX_ "internal error, possible memory corruption (num: %s, cur: %d, exp: %d)",
		       li_pv, SvCUR(ret), retlen - 1);

	EXTEND(SP, 1);
	ST(0) = ret;
	XSRETURN(1);
    }

