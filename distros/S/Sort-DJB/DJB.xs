#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <inttypes.h>
#include <string.h>
#include "djbsort_src/djbsort.h"

/* ---- int32 helpers ---- */

static int32_t *
av_to_int32(pTHX_ AV *av, SSize_t *n_out)
{
    SSize_t n = av_len(av) + 1;
    int32_t *buf;
    SSize_t i;
    *n_out = n;
    if (n == 0) return NULL;
    Newx(buf, n, int32_t);
    for (i = 0; i < n; i++) {
        SV **svp = av_fetch(av, i, 0);
        buf[i] = (int32_t)SvIV(svp ? *svp : &PL_sv_undef);
    }
    return buf;
}

static AV *
int32_to_av(pTHX_ int32_t *buf, SSize_t n)
{
    AV *av = newAV();
    SSize_t i;
    av_extend(av, n - 1);
    for (i = 0; i < n; i++)
        av_store(av, i, newSViv((IV)buf[i]));
    return av;
}

/* ---- uint32 helpers ---- */

static uint32_t *
av_to_uint32(pTHX_ AV *av, SSize_t *n_out)
{
    SSize_t n = av_len(av) + 1;
    uint32_t *buf;
    SSize_t i;
    *n_out = n;
    if (n == 0) return NULL;
    Newx(buf, n, uint32_t);
    for (i = 0; i < n; i++) {
        SV **svp = av_fetch(av, i, 0);
        buf[i] = (uint32_t)SvUV(svp ? *svp : &PL_sv_undef);
    }
    return buf;
}

static AV *
uint32_to_av(pTHX_ uint32_t *buf, SSize_t n)
{
    AV *av = newAV();
    SSize_t i;
    av_extend(av, n - 1);
    for (i = 0; i < n; i++)
        av_store(av, i, newSVuv((UV)buf[i]));
    return av;
}

/* ---- int64 helpers ---- */

static int64_t *
av_to_int64(pTHX_ AV *av, SSize_t *n_out)
{
    SSize_t n = av_len(av) + 1;
    int64_t *buf;
    SSize_t i;
    *n_out = n;
    if (n == 0) return NULL;
    Newx(buf, n, int64_t);
    for (i = 0; i < n; i++) {
        SV **svp = av_fetch(av, i, 0);
        buf[i] = (int64_t)SvIV(svp ? *svp : &PL_sv_undef);
    }
    return buf;
}

static AV *
int64_to_av(pTHX_ int64_t *buf, SSize_t n)
{
    AV *av = newAV();
    SSize_t i;
    av_extend(av, n - 1);
    for (i = 0; i < n; i++)
        av_store(av, i, newSViv((IV)buf[i]));
    return av;
}

/* ---- uint64 helpers ---- */

static uint64_t *
av_to_uint64(pTHX_ AV *av, SSize_t *n_out)
{
    SSize_t n = av_len(av) + 1;
    uint64_t *buf;
    SSize_t i;
    *n_out = n;
    if (n == 0) return NULL;
    Newx(buf, n, uint64_t);
    for (i = 0; i < n; i++) {
        SV **svp = av_fetch(av, i, 0);
        buf[i] = (uint64_t)SvUV(svp ? *svp : &PL_sv_undef);
    }
    return buf;
}

static AV *
uint64_to_av(pTHX_ uint64_t *buf, SSize_t n)
{
    AV *av = newAV();
    SSize_t i;
    av_extend(av, n - 1);
    for (i = 0; i < n; i++)
        av_store(av, i, newSVuv((UV)buf[i]));
    return av;
}

/* ---- float32 helpers ---- */

static float *
av_to_float32(pTHX_ AV *av, SSize_t *n_out)
{
    SSize_t n = av_len(av) + 1;
    float *buf;
    SSize_t i;
    *n_out = n;
    if (n == 0) return NULL;
    Newx(buf, n, float);
    for (i = 0; i < n; i++) {
        SV **svp = av_fetch(av, i, 0);
        buf[i] = (float)SvNV(svp ? *svp : &PL_sv_undef);
    }
    return buf;
}

static AV *
float32_to_av(pTHX_ float *buf, SSize_t n)
{
    AV *av = newAV();
    SSize_t i;
    av_extend(av, n - 1);
    for (i = 0; i < n; i++)
        av_store(av, i, newSVnv((NV)buf[i]));
    return av;
}

/* ---- float64 helpers ---- */

static double *
av_to_float64(pTHX_ AV *av, SSize_t *n_out)
{
    SSize_t n = av_len(av) + 1;
    double *buf;
    SSize_t i;
    *n_out = n;
    if (n == 0) return NULL;
    Newx(buf, n, double);
    for (i = 0; i < n; i++) {
        SV **svp = av_fetch(av, i, 0);
        buf[i] = (double)SvNV(svp ? *svp : &PL_sv_undef);
    }
    return buf;
}

static AV *
float64_to_av(pTHX_ double *buf, SSize_t n)
{
    AV *av = newAV();
    SSize_t i;
    av_extend(av, n - 1);
    for (i = 0; i < n; i++)
        av_store(av, i, newSVnv((NV)buf[i]));
    return av;
}

/* Common sort body used by all sort functions */
#define SORT_BODY(croak_name, av_ref, c_type, c_func, av_to_fn, to_av_fn) \
    {                                                                       \
        AV *av;                                                             \
        SSize_t n;                                                          \
        c_type *buf;                                                        \
        AV *result;                                                         \
        if (!SvROK(av_ref) || SvTYPE(SvRV(av_ref)) != SVt_PVAV)            \
            croak(croak_name ": argument must be an array reference");      \
        av = (AV *)SvRV(av_ref);                                            \
        buf = av_to_fn(aTHX_ av, &n);                                      \
        if (n > 0) {                                                        \
            c_func(buf, (long long)n);                                      \
            result = to_av_fn(aTHX_ buf, n);                                \
            Safefree(buf);                                                  \
        } else {                                                            \
            result = newAV();                                               \
        }                                                                   \
        mXPUSHs(newRV_noinc((SV *)result));                                 \
        XSRETURN(1);                                                        \
    }

MODULE = Sort::DJB    PACKAGE = Sort::DJB

PROTOTYPES: DISABLE

const char *
version()
    CODE:
        RETVAL = djbsort_version();
    OUTPUT:
        RETVAL

const char *
arch()
    CODE:
        RETVAL = djbsort_arch();
    OUTPUT:
        RETVAL

const char *
int32_implementation()
    CODE:
        RETVAL = djbsort_int32_implementation();
    OUTPUT:
        RETVAL

const char *
int32_compiler()
    CODE:
        RETVAL = djbsort_int32_compiler();
    OUTPUT:
        RETVAL

const char *
int64_implementation()
    CODE:
        RETVAL = djbsort_int64_implementation();
    OUTPUT:
        RETVAL

const char *
int64_compiler()
    CODE:
        RETVAL = djbsort_int64_compiler();
    OUTPUT:
        RETVAL

void
sort_int32(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_int32", av_ref, int32_t, djbsort_int32, av_to_int32, int32_to_av)

void
sort_int32down(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_int32down", av_ref, int32_t, djbsort_int32down, av_to_int32, int32_to_av)

void
sort_uint32(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_uint32", av_ref, uint32_t, djbsort_uint32, av_to_uint32, uint32_to_av)

void
sort_uint32down(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_uint32down", av_ref, uint32_t, djbsort_uint32down, av_to_uint32, uint32_to_av)

void
sort_int64(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_int64", av_ref, int64_t, djbsort_int64, av_to_int64, int64_to_av)

void
sort_int64down(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_int64down", av_ref, int64_t, djbsort_int64down, av_to_int64, int64_to_av)

void
sort_uint64(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_uint64", av_ref, uint64_t, djbsort_uint64, av_to_uint64, uint64_to_av)

void
sort_uint64down(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_uint64down", av_ref, uint64_t, djbsort_uint64down, av_to_uint64, uint64_to_av)

void
sort_float32(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_float32", av_ref, float, djbsort_float32, av_to_float32, float32_to_av)

void
sort_float32down(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_float32down", av_ref, float, djbsort_float32down, av_to_float32, float32_to_av)

void
sort_float64(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_float64", av_ref, double, djbsort_float64, av_to_float64, float64_to_av)

void
sort_float64down(av_ref)
        SV *av_ref
    PPCODE:
        SORT_BODY("sort_float64down", av_ref, double, djbsort_float64down, av_to_float64, float64_to_av)
