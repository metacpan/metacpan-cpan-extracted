#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define	SI_NOT	0x01
#define SI_REV	0x02


MODULE = String::Index		PACKAGE = String::Index		


int
cindex(SV *str, SV *cc, ...)
PROTOTYPE: $$;$
ALIAS:
  ncindex = 1
  crindex = 2
  ncrindex = 3
CODE:
{
    STRLEN s_len;
    STRLEN c_len;
    char *s = SvPV(str,s_len);
    char *c = SvPV(cc,c_len);
    int seen_null = 0;
    int p = (items == 3 ? (int)SvIV(ST(2)) : 0); 
    int i;
    
    /* see if there is an INTERNAL null in the char str */
    for (i = 0; i < c_len; ) {
	if (c[i] == '\0' && (seen_null = 1)) c[i] = c[--c_len];
	else ++i;
    }
    c[c_len] = '\0';

    if (ix & SI_REV) {
	s += (p ? p : s_len - 1);
	for (i = p ? p : (s_len - 1); i >= 0; --i, --s)
	    if ((*s ? strchr(c, *s) > 0 : seen_null) != (ix & SI_NOT)) break;
    }
    else {
	s += p;
	for (i = p; i < s_len; ++i, ++s)
	    if ((*s ? strchr(c, *s) > 0 : seen_null) != (ix & SI_NOT)) break;
    }

    RETVAL = (i == ((ix & SI_REV) ? -1 : s_len) ? -1 : i);
}
OUTPUT:
    RETVAL
