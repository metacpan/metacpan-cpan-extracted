/*
 * nvec_api.h - C-level API for Numeric::Vector module
 *
 * Include this header in your XS module to use Numeric::Vector's SIMD-accelerated
 * vector operations directly from C, bypassing Perl method dispatch.
 *
 * Usage in your .xs file:
 *
 *   #include "nvec_api.h"
 *
 *   // Create a Numeric::Vector and work with it directly
 *   Vec *v = vec_xs_create(aTHX_ 1000);
 *   double *data = vec_xs_data(v);
 *   for (IV i = 0; i < 1000; i++) data[i] = i * 0.5;
 *   v->len = 1000;
 *
 *   // Use SIMD operations on raw buffers
 *   double result = vec_xs_sum_impl(data, 1000);
 *
 *   // Wrap as Perl object when returning
 *   SV *sv = vec_xs_wrap(aTHX_ v);
 *   RETVAL = sv;
 *
 *   // Or extract from an existing Perl Numeric::Vector object
 *   Vec *v2 = vec_xs_from_sv(aTHX_ some_sv);
 *   double *buf = vec_xs_data(v2);
 *
 * Performance:
 *   - Direct C calls: ~5 cycles (function pointer)
 *   - SIMD operations: hardware-accelerated (NEON/AVX2/SSE2)
 *   - No Perl method dispatch overhead
 */

#ifndef NVEC_API_H
#define NVEC_API_H

#include "EXTERN.h"
#include "perl.h"

/* ============================================
   Vec Structure (matches Numeric::Vector.c internal)
   ============================================ */

#define VEC_FLAG_READONLY 0x01

typedef struct {
    double *data;       /* Aligned data buffer */
    IV len;             /* Number of elements */
    IV capacity;        /* Allocated capacity */
    U32 flags;          /* VEC_FLAG_* */
} Vec;

/* ============================================
   Object Lifecycle
   ============================================ */

/*
 * Create a new Vec with given capacity.
 * The returned Vec has len=0, caller should set len after populating.
 */
PERL_CALLCONV Vec* vec_xs_create(pTHX_ IV capacity);

/*
 * Destroy a Vec and free its memory.
 * Only call this if you created the Vec yourself and won't wrap it.
 */
PERL_CALLCONV void vec_xs_destroy(pTHX_ Vec *v);

/*
 * Extract Vec* from a Perl SV (must be a blessed Numeric::Vector object).
 * The returned pointer is valid as long as the SV lives.
 */
PERL_CALLCONV Vec* vec_xs_from_sv(pTHX_ SV *sv);

/*
 * Wrap a Vec* as a Perl blessed object.
 * Ownership transfers to Perl - do not call vec_xs_destroy after this.
 */
PERL_CALLCONV SV* vec_xs_wrap(pTHX_ Vec *v);

/* ============================================
   Direct Data Access
   ============================================ */

/*
 * Get pointer to raw data buffer.
 * Buffer is aligned for SIMD operations.
 */
PERL_CALLCONV double* vec_xs_data(Vec *v);

/*
 * Get number of elements.
 */
PERL_CALLCONV IV vec_xs_len(Vec *v);

/* ============================================
   SIMD Operations - Work on Raw Buffers
   These are the fastest path - pure C with SIMD.
   ============================================ */

/* Arithmetic: c[i] = a[i] op b[i] */
PERL_CALLCONV void vec_xs_add_impl(double *c, const double *a, const double *b, IV n);
PERL_CALLCONV void vec_xs_sub_impl(double *c, const double *a, const double *b, IV n);
PERL_CALLCONV void vec_xs_mul_impl(double *c, const double *a, const double *b, IV n);
PERL_CALLCONV void vec_xs_div_impl(double *c, const double *a, const double *b, IV n);

/* Scale: c[i] = a[i] * scalar */
PERL_CALLCONV void vec_xs_scale_impl(double *c, const double *a, double s, IV n);

/* In-place: a[i] op= b[i] or a[i] op= scalar */
PERL_CALLCONV void vec_xs_add_inplace_impl(double *a, const double *b, IV n);
PERL_CALLCONV void vec_xs_scale_inplace_impl(double *a, double s, IV n);

/* Reductions */
PERL_CALLCONV double vec_xs_sum_impl(const double *a, IV n);
PERL_CALLCONV double vec_xs_dot_impl(const double *a, const double *b, IV n);

/* ============================================
   SIMD Info
   ============================================ */

/*
 * Get SIMD implementation name: "NEON", "AVX2", "AVX", "SSE2", or "Scalar"
 */
PERL_CALLCONV const char* vec_xs_simd_name(void);

#endif /* NVEC_API_H */
