#ifndef PQ_COMPAT_H
#define PQ_COMPAT_H

/* Perl-version portability shims for the C core, so Punk::Queue builds on
 * every perl it claims (5.10.0+). Include after EXTERN.h / perl.h / XSUB.h
 * and before any other pq_ header, so the definitions are in scope
 * everywhere below.
 *
 * Each shim is the standard definition of the thing it stands in for; on a
 * perl new enough to have the real one, none of this is compiled. */

/* XS_INTERNAL / XS_EXTERNAL (and XSPROTO) arrived in perl's XSUB.h at 5.16. */
#ifndef XSPROTO
#  define XSPROTO(name) void name(pTHX_ CV *cv)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) STATIC XSPROTO(name)
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XSPROTO(name)
#endif

/* croak_sv is 5.13.1. */
#if PERL_REVISION == 5 && PERL_VERSION < 14
#  define croak_sv(sv) Perl_croak(aTHX_ "%" SVf, SVfARG(sv))
#endif

/* isWORDCHAR is the 5.14 spelling of what older perls call isALNUM. Both
 * mean [0-9A-Za-z_] here: every caller is testing a single ASCII byte. */
#ifndef isWORDCHAR
#  define isWORDCHAR(c) isALNUM(c)
#endif

/* mPUSHs / mXPUSHs are 5.10.1, one point release above the floor. */
#ifndef mPUSHs
#  define mPUSHs(s) PUSHs(sv_2mortal(s))
#endif
#ifndef mXPUSHs
#  define mXPUSHs(s) XPUSHs(sv_2mortal(s))
#endif

/* The dist version, recorded on worker rows so `punk-queue workers` can
 * spot a mixed-version fleet. Kept in step with $Punk::Queue::VERSION. */
#define PQ_VERSION_STRING "0.01"

/* ---- allocation ------------------------------------------------------- *
 * Everything in include/ and xs/ allocates through these, never through
 * raw malloc/calloc/realloc: they croak (noreturn) on exhaustion rather
 * than handing back NULL for a caller to forget to check. This is
 * Hyperman's hm_xmalloc convention, and it is also what keeps cppcheck's
 * nullPointerOutOfMemory clean.
 *
 * The set is deliberately complete even where phase 1 uses only part of
 * it: a missing pq_xcalloc is an invitation to reach for a raw calloc, and
 * the whole value of the convention is that there is nothing to decide.
 * Hence the unused marker rather than three fewer functions. */

static void *pq_xmalloc(pTHX_ size_t n) {
    void *p = safemalloc(n ? n : 1);
    if (!p) croak("Punk::Queue: out of memory allocating %lu bytes",
                  (unsigned long)n);
    return p;
}

static void *pq_xcalloc(pTHX_ size_t n, size_t sz) PERL_UNUSED_DECL;
static void *pq_xcalloc(pTHX_ size_t n, size_t sz) {
    void *p = safecalloc(n ? n : 1, sz ? sz : 1);
    if (!p) croak("Punk::Queue: out of memory allocating %lu bytes",
                  (unsigned long)(n * sz));
    return p;
}

static void *pq_xrealloc(pTHX_ void *old, size_t n) PERL_UNUSED_DECL;
static void *pq_xrealloc(pTHX_ void *old, size_t n) {
    void *p = saferealloc(old, n ? n : 1);
    if (!p) croak("Punk::Queue: out of memory reallocating %lu bytes",
                  (unsigned long)n);
    return p;
}

#endif /* PQ_COMPAT_H */
