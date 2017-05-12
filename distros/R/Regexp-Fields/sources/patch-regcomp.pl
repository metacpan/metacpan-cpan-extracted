
patch <<'__', after => qr(with the POSIX routines of the same names);
#ifdef RE_FIELDS
#  define PERL_EXT
#  define PERL_EXT_RE_BUILD
#  ifdef PERL_EXT_RE_DEBUG
#    undef PERL_EXT_RE_DEBUG
#  endif
#endif
__
 
patch <<'__', before => qr(Allow for side effects in s);
#ifdef RE_FIELDS
#  include "rx_lend.h"
#endif
__
 
patch <<'__', after => qr(r->data = 0), 0;
#ifdef RE_FIELDS
    rx_regcomp_start(aTHX _aREXC);
#endif
__
 
patch <<'__', before => qr((RExC_seen|PL_regseen)\Q |= REG_SEEN_LOOKBEHIND);
#ifdef RE_FIELDS
		if (isALPHA(*RExC_parse)) {
		    char *name = RExC_parse;
		    while (isALNUM(*RExC_parse))
			RExC_parse++;

		    if (*RExC_parse == '\0') {
			RExC_parse = name;
			vFAIL("Sequence (?<name>... not terminated");
		    }
		    if (*RExC_parse != '>') {
			RExC_parse = name;
			vFAIL("Illegal character in (?<name>");
		    }

		    if (!SIZE_ONLY)
			rx_regcomp_parse(aTHX_ aREXC_ name, RExC_parse-name);

		    nextchar(aREXC);
		    while (*RExC_parse && isSPACE(*RExC_parse))
			RExC_parse++;
		    paren = 1;
		    goto plain_parens;
		}
#endif
__
 
patch <<'__', before => qr(parno = (PL_reg|RExC_)npar);
#ifdef RE_FIELDS
	plain_parens:
#endif
__
 
patch <<'__', before => qr(\Qif (!r || (--r->refcnt > 0)));
#ifdef RE_FIELDS
    rx_regfree(aTHX_ r);
#endif
__

1;
