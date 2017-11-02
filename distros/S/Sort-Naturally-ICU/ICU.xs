#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <unicode/ustring.h>
#include <unicode/ucol.h>
#include "src/nsort.h"

#include "const-c.inc"

UCollator *collator = 0;

static I32
S_sv_ncmp(pTHX_ SV *a, SV *b)
{
    const char *ia = (const char *) SvPVbyte_nolen(a);
    const char *ib = (const char *) SvPVbyte_nolen(b);
    return _ncmp(ia, ib, 0, collator);
}

static I32
S_sv_ncmp_reverse(pTHX_ SV *a, SV *b)
{
    const char *ia = (const char *) SvPVbyte_nolen(a);
    const char *ib = (const char *) SvPVbyte_nolen(b);
    return _ncmp(ia, ib, 1, collator);
}

static I32
S_sv_ncoll(pTHX_ SV *a, SV *b)
{
    const char *ia = (const char *) SvPVbyte_nolen(a);
    const char *ib = (const char *) SvPVbyte_nolen(b);
    return _ncmp(ia, ib, 0, collator);
}

static I32
S_sv_ncoll_reverse(pTHX_ SV *a, SV *b)
{
    const char *ia = (const char *) SvPVbyte_nolen(a);
    const char *ib = (const char *) SvPVbyte_nolen(b);
    return _ncmp(ia, ib, 1, collator);
}

MODULE = Sort::Naturally::ICU		PACKAGE = Sort::Naturally::ICU

INCLUDE: const-xs.inc

int
ncmp(arg_a, arg_b)
        const char *    arg_a
        const char *    arg_b
    CODE:
        RETVAL = _ncmp(arg_a, arg_b, 0, 0);
    OUTPUT:
        RETVAL

void
nsort(...)
    PROTOTYPE: @
    CODE:
        if (!items) {
            XSRETURN_UNDEF;
        }
        AV * array = newAV();
        int i;
        for (i=0; i<items; i++) {
            av_push(array, ST(i));
        }
        sortsv(AvARRAY(array), items, S_sv_ncmp);
        for (i=0; i<items; i++) {
            ST(i) = av_shift(array);
        }
        av_undef(array);
        SvREFCNT_dec(array);
        XSRETURN(items);

void
_sorted(array_ref, reverse, locale)
        SV *            array_ref
        int             reverse
        const char *    locale
    CODE:
        if (!SvROK(array_ref) || SvTYPE(SvRV(array_ref)) != SVt_PVAV) {
            croak("Not an ARRAY ref");
        }
        AV * array = (AV *) SvRV(array_ref);
        int array_len = av_len(array) + 1;
        if (locale != NULL && strlen(locale)) {
            UErrorCode errorCode = U_ZERO_ERROR;
            collator = ucol_open(locale, &errorCode);
            if (U_SUCCESS(errorCode)) {
                if (reverse) {
                    sortsv(AvARRAY(array), array_len, S_sv_ncoll_reverse);
                } else {
                    sortsv(AvARRAY(array), array_len, S_sv_ncoll);
                }
                ucol_close(collator);
            }
            else if (U_FAILURE(errorCode)) {
                fprintf(stderr, "failure: %s", u_errorName(errorCode));
            }
        } else {
            if (reverse) {
                sortsv(AvARRAY(array), array_len, S_sv_ncmp_reverse);
            } else {
                sortsv(AvARRAY(array), array_len, S_sv_ncmp);
            }
        }
