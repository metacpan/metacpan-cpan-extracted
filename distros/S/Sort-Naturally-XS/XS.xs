#define PERL_NO_GET_CONTEXT
#include "locale.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "src/nsort.h"

#include "const-c.inc"

static I32
S_sv_ncmp(pTHX_ SV *a, SV *b)
{
    const char *ia = (const char *) SvPVbyte_nolen(a);
    const char *ib = (const char *) SvPVbyte_nolen(b);
    return _ncmp(ia, ib, 0, 0);
}

static I32
S_sv_ncmp_reverse(pTHX_ SV *a, SV *b)
{
    const char *ia = (const char *) SvPVbyte_nolen(a);
    const char *ib = (const char *) SvPVbyte_nolen(b);
    return _ncmp(ia, ib, 1, 0);
}

static I32
S_sv_ncoll(pTHX_ SV *a, SV *b)
{
    const char *ia = (const char *) SvPVbyte_nolen(a);
    const char *ib = (const char *) SvPVbyte_nolen(b);
    return _ncmp(ia, ib, 0, 1);
}

static I32
S_sv_ncoll_reverse(pTHX_ SV *a, SV *b)
{
    const char *ia = (const char *) SvPVbyte_nolen(a);
    const char *ib = (const char *) SvPVbyte_nolen(b);
    return _ncmp(ia, ib, 1, 1);
}

MODULE = Sort::Naturally::XS		PACKAGE = Sort::Naturally::XS		

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
            const char * old_locale = setlocale(LC_ALL, locale);
            if (reverse) {
                sortsv(AvARRAY(array), array_len, S_sv_ncoll_reverse);
            } else {
                sortsv(AvARRAY(array), array_len, S_sv_ncoll);
            }
            setlocale(LC_ALL, old_locale);
        } else {
            if (reverse) {
                sortsv(AvARRAY(array), array_len, S_sv_ncmp_reverse);
            } else {
                sortsv(AvARRAY(array), array_len, S_sv_ncmp);
            }
        }
