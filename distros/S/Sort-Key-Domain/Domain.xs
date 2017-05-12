#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>

static SV*
mkkey_domain(pTHX_ SV *domain) {
    STRLEN len, remaining;
    const char *from, *dot;
    SV *key;
    char *to_start, *to;

    from = SvPV_const(domain, len);
    if (len && (from[len - 1] == '.')) len--;

    key = sv_2mortal(newSV(len));
    SvPOK_only(key);
    SvCUR_set(key, len);

    to_start = SvPVX(key);
    to = to_start + len + 1; /* yes, just after the \0 */
    remaining = len;
    while (dot = memchr(from, '.', remaining)) {
        STRLEN token_len = dot + 1 - from;
        to -= token_len;
        memcpy(to, from, token_len);
        remaining -= token_len;
        from += token_len;
    }
    memcpy(to_start, from, remaining);
    to_start[remaining] = '.';
    to_start[len] = '\0';
    if (SvUTF8(domain))
        SvUTF8_on(key);
    return key;
}

MODULE = Sort::Key::Domain		PACKAGE = Sort::Key::Domain		
PROTOTYPES: DISABLE

void
mkkey_domain(domain = NULL)
    SV *domain
PPCODE:
    if (!domain)
        domain = DEFSV;
    EXTEND(SP, 1);
    ST(0) = mkkey_domain(aTHX_ domain);
    XSRETURN(1);
