/*
 * vec.c - SIMD-accelerated numeric vectors for Perl
 *
 * Portable implementation with compile-time SIMD detection:
 * - ARM NEON (Apple Silicon, ARM64)
 * - x86 AVX/AVX2
 * - x86 SSE2
 * - Scalar fallback
 *
 * Custom ops for direct method optimization (bypasses method dispatch)
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "include/nvec_compat.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <limits.h>

/* ============================================
   Custom Op Declarations
   ============================================ */

/* XOP structures for custom ops */
static XOP vec_sum_xop;
static XOP vec_mean_xop;
static XOP vec_len_xop;
static XOP vec_min_xop;
static XOP vec_max_xop;
static XOP vec_dot_xop;
static XOP vec_norm_xop;
static XOP vec_get_xop;
static XOP vec_set_xop;
static XOP vec_add_xop;
static XOP vec_sub_xop;
static XOP vec_mul_xop;
static XOP vec_div_xop;
static XOP vec_scale_xop;
static XOP vec_add_inplace_xop;
static XOP vec_scale_inplace_xop;
static XOP vec_neg_xop;
static XOP vec_abs_xop;
static XOP vec_sqrt_xop;
static XOP vec_copy_xop;
static XOP vec_variance_xop;
static XOP vec_std_xop;
static XOP vec_normalize_xop;
/* More math ops */
static XOP vec_exp_xop;
static XOP vec_log_xop;
static XOP vec_sin_xop;
static XOP vec_cos_xop;
static XOP vec_tan_xop;
static XOP vec_floor_xop;
static XOP vec_ceil_xop;
static XOP vec_round_xop;
static XOP vec_asin_xop;
static XOP vec_acos_xop;
static XOP vec_atan_xop;
static XOP vec_sinh_xop;
static XOP vec_cosh_xop;
static XOP vec_tanh_xop;
static XOP vec_log10_xop;
static XOP vec_log2_xop;
static XOP vec_sign_xop;
static XOP vec_cumsum_xop;
static XOP vec_cumprod_xop;
static XOP vec_diff_xop;
static XOP vec_reverse_xop;
static XOP vec_isnan_xop;
static XOP vec_isinf_xop;
static XOP vec_isfinite_xop;
/* In-place ops */
static XOP vec_sub_inplace_xop;
static XOP vec_mul_inplace_xop;
static XOP vec_div_inplace_xop;
/* Comparison ops */
static XOP vec_eq_xop;
static XOP vec_ne_xop;
static XOP vec_lt_xop;
static XOP vec_le_xop;
static XOP vec_gt_xop;
static XOP vec_ge_xop;
/* Boolean reductions */
static XOP vec_all_xop;
static XOP vec_any_xop;
static XOP vec_count_xop;
/* Arg ops */
static XOP vec_argmax_xop;
static XOP vec_argmin_xop;
/* More math */
static XOP vec_pow_xop;
static XOP vec_product_xop;
/* Linear algebra */
static XOP vec_distance_xop;
static XOP vec_cosine_similarity_xop;
static XOP vec_axpy_xop;
/* Utility */
static XOP vec_clip_xop;
static XOP vec_concat_xop;
static XOP vec_sort_xop;
static XOP vec_where_xop;
static XOP vec_slice_xop;
static XOP vec_median_xop;
static XOP vec_argsort_xop;
/* Scalar ops */
static XOP vec_add_scalar_xop;
static XOP vec_add_scalar_inplace_xop;
static XOP vec_clamp_inplace_xop;
static XOP vec_fma_inplace_xop;
/* Constructors */
static XOP vec_new_xop;
static XOP vec_ones_xop;
static XOP vec_zeros_xop;
static XOP vec_fill_xop;
static XOP vec_fill_range_xop;
static XOP vec_linspace_xop;
static XOP vec_range_xop;
static XOP vec_random_xop;
/* Utility */
static XOP vec_to_array_xop;
static XOP vec_simd_info_xop;

/* ============================================
   Portability: Math function fallbacks
   ============================================ */

/* log2 - not available in C89 */
#ifndef log2
#define log2(x) (log(x) / 0.693147180559945309417)  /* log(2) */
#endif

/* isnan/isinf/isfinite - C99 macros, provide fallbacks */
#ifndef isnan
#define isnan(x) ((x) != (x))
#endif

#ifndef isinf
#define isinf(x) (!isnan(x) && isnan((x) - (x)))
#endif

#ifndef isfinite
#define isfinite(x) (!isnan(x) && !isinf(x))
#endif

/* Safe maximum vector size (prevent overflow on 32-bit IV) */
#define VEC_MAX_SIZE ((IV)(((UV)1 << (sizeof(IV)*8 - 1)) - 1))

/* ============================================
   SIMD Detection and Includes
   ============================================ */

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
    #define VEC_USE_NEON 1
    #include <arm_neon.h>
    #define VEC_SIMD_NAME "NEON"
    #define VEC_ALIGN 16
    #define VEC_LANES 2  /* float64x2 = 2 doubles */
#elif defined(__AVX2__)
    #define VEC_USE_AVX2 1
    #include <immintrin.h>
    #define VEC_SIMD_NAME "AVX2"
    #define VEC_ALIGN 32
    #define VEC_LANES 4  /* __m256d = 4 doubles */
#elif defined(__AVX__)
    #define VEC_USE_AVX 1
    #include <immintrin.h>
    #define VEC_SIMD_NAME "AVX"
    #define VEC_ALIGN 32
    #define VEC_LANES 4
#elif defined(__SSE2__) || defined(_M_X64) || defined(_M_AMD64)
    #define VEC_USE_SSE2 1
    #include <emmintrin.h>
    #define VEC_SIMD_NAME "SSE2"
    #define VEC_ALIGN 16
    #define VEC_LANES 2  /* __m128d = 2 doubles */
#else
    #define VEC_USE_SCALAR 1
    #define VEC_SIMD_NAME "Scalar"
    #define VEC_ALIGN 8
    #define VEC_LANES 1
#endif

/* ============================================
   Vec Structure
   ============================================ */

typedef struct {
    double *data;       /* Aligned data buffer */
    IV len;             /* Number of elements */
    IV capacity;        /* Allocated capacity */
    U32 flags;          /* VEC_FLAG_* */
} Vec;

#define VEC_FLAG_READONLY 0x01

/* Magic vtable for vec objects */
static int vec_mg_free(pTHX_ SV *sv, MAGIC *mg);
static int vec_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param);

/* Forward declaration for helper function */
static int sv_is_nvec(pTHX_ SV *sv);

static const MGVTBL vec_vtbl = {
    NULL,           /* get */
    NULL,           /* set */
    NULL,           /* len */
    NULL,           /* clear */
    vec_mg_free,    /* free */
    NULL,           /* copy */
    vec_mg_dup,     /* dup */
    NULL            /* local */
};

/* ============================================
   Aligned Memory Allocation
   ============================================ */

static void* vec_alloc_aligned(size_t size) {
    void *ptr = NULL;
#if defined(_WIN32) || defined(_WIN64)
    ptr = _aligned_malloc(size, VEC_ALIGN);
#elif defined(__APPLE__) || _POSIX_C_SOURCE >= 200112L
    if (posix_memalign(&ptr, VEC_ALIGN, size) != 0) {
        ptr = NULL;
    }
#else
    /* Fallback: over-allocate and align manually */
    void *raw = malloc(size + VEC_ALIGN + sizeof(void*));
    if (raw) {
        void **aligned = (void**)(((size_t)raw + sizeof(void*) + VEC_ALIGN - 1) & ~(VEC_ALIGN - 1));
        aligned[-1] = raw;
        ptr = aligned;
    }
#endif
    return ptr;
}

static void vec_free_aligned(void *ptr) {
    if (!ptr) return;
#if defined(_WIN32) || defined(_WIN64)
    _aligned_free(ptr);
#elif defined(__APPLE__) || _POSIX_C_SOURCE >= 200112L
    free(ptr);
#else
    void *raw = ((void**)ptr)[-1];
    free(raw);
#endif
}

/* ============================================
   Vec Lifecycle
   ============================================ */

static Vec* vec_create(pTHX_ IV capacity) {
    Vec *v;
    
    /* Validate capacity to prevent overflow */
    if (capacity < 0) {
        croak("vec: negative capacity %ld", (long)capacity);
    }
    if (capacity > VEC_MAX_SIZE / (IV)sizeof(double)) {
        croak("vec: capacity %ld exceeds maximum safe size", (long)capacity);
    }
    
    Newxz(v, 1, Vec);
    if (capacity > 0) {
        v->data = (double*)vec_alloc_aligned((size_t)capacity * sizeof(double));
        if (!v->data) {
            Safefree(v);
            croak("vec: failed to allocate %ld elements", (long)capacity);
        }
    }
    v->len = 0;
    v->capacity = capacity;
    v->flags = 0;
    return v;
}

static void vec_destroy(pTHX_ Vec *v) {
    if (v) {
        if (v->data) vec_free_aligned(v->data);
        Safefree(v);
    }
}

static int vec_mg_free(pTHX_ SV *sv, MAGIC *mg) {
    Vec *v = (Vec*)mg->mg_ptr;
    vec_destroy(aTHX_ v);
    return 0;
}

static int vec_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    PERL_UNUSED_ARG(param);
    /* For threads: would need to deep-copy */
    return 0;
}

/* ============================================
   Vec Object Wrapping
   ============================================ */

static SV* vec_wrap(pTHX_ Vec *v) {
    SV *rv;
    SV *sv = newSV(0);
    
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &vec_vtbl, (char*)v, 0);
    rv = newRV_noinc(sv);
    sv_bless(rv, gv_stashpv("Numeric::Vector", GV_ADD));
    
    return rv;
}

static Vec* vec_from_sv(pTHX_ SV *sv) {
    MAGIC *mg;
    
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Numeric::Vector")) {
        croak("Not a Numeric::Vector object");
    }
    
    sv = SvRV(sv);
    mg = mg_findext(sv, PERL_MAGIC_ext, &vec_vtbl);
    if (!mg) {
        croak("Corrupted vec object");
    }
    
    return (Vec*)mg->mg_ptr;
}

/* ============================================
   SIMD Implementations - ADD
   ============================================ */

static void vec_add_impl(double *c, const double *a, const double *b, IV n) {
    IV i = 0;
    
#if VEC_USE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vst1q_f64(c + i, vaddq_f64(va, vb));
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_load_pd(a + i);
        __m256d vb = _mm256_load_pd(b + i);
        _mm256_store_pd(c + i, _mm256_add_pd(va, vb));
    }
#elif VEC_USE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_load_pd(a + i);
        __m128d vb = _mm_load_pd(b + i);
        _mm_store_pd(c + i, _mm_add_pd(va, vb));
    }
#endif
    
    /* Scalar tail */
    for (; i < n; i++) {
        c[i] = a[i] + b[i];
    }
}

/* ============================================
   SIMD Implementations - SUB
   ============================================ */

static void vec_sub_impl(double *c, const double *a, const double *b, IV n) {
    IV i = 0;
    
#if VEC_USE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vst1q_f64(c + i, vsubq_f64(va, vb));
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_load_pd(a + i);
        __m256d vb = _mm256_load_pd(b + i);
        _mm256_store_pd(c + i, _mm256_sub_pd(va, vb));
    }
#elif VEC_USE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_load_pd(a + i);
        __m128d vb = _mm_load_pd(b + i);
        _mm_store_pd(c + i, _mm_sub_pd(va, vb));
    }
#endif
    
    for (; i < n; i++) {
        c[i] = a[i] - b[i];
    }
}

/* ============================================
   SIMD Implementations - MUL
   ============================================ */

static void vec_mul_impl(double *c, const double *a, const double *b, IV n) {
    IV i = 0;
    
#if VEC_USE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vst1q_f64(c + i, vmulq_f64(va, vb));
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_load_pd(a + i);
        __m256d vb = _mm256_load_pd(b + i);
        _mm256_store_pd(c + i, _mm256_mul_pd(va, vb));
    }
#elif VEC_USE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_load_pd(a + i);
        __m128d vb = _mm_load_pd(b + i);
        _mm_store_pd(c + i, _mm_mul_pd(va, vb));
    }
#endif
    
    for (; i < n; i++) {
        c[i] = a[i] * b[i];
    }
}

/* ============================================
   SIMD Implementations - DIV
   ============================================ */

static void vec_div_impl(double *c, const double *a, const double *b, IV n) {
    IV i = 0;
    
#if VEC_USE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vst1q_f64(c + i, vdivq_f64(va, vb));
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_load_pd(a + i);
        __m256d vb = _mm256_load_pd(b + i);
        _mm256_store_pd(c + i, _mm256_div_pd(va, vb));
    }
#elif VEC_USE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_load_pd(a + i);
        __m128d vb = _mm_load_pd(b + i);
        _mm_store_pd(c + i, _mm_div_pd(va, vb));
    }
#endif
    
    for (; i < n; i++) {
        c[i] = a[i] / b[i];
    }
}

/* ============================================
   SIMD Implementations - SCALE
   ============================================ */

static void vec_scale_impl(double *c, const double *a, double s, IV n) {
    IV i = 0;
    
#if VEC_USE_NEON
    float64x2_t vs = vdupq_n_f64(s);
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        vst1q_f64(c + i, vmulq_f64(va, vs));
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    __m256d vs = _mm256_set1_pd(s);
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_load_pd(a + i);
        _mm256_store_pd(c + i, _mm256_mul_pd(va, vs));
    }
#elif VEC_USE_SSE2
    __m128d vs = _mm_set1_pd(s);
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_load_pd(a + i);
        _mm_store_pd(c + i, _mm_mul_pd(va, vs));
    }
#endif
    
    for (; i < n; i++) {
        c[i] = a[i] * s;
    }
}

/* ============================================
   SIMD Implementations - SUM
   ============================================ */

static double vec_sum_impl(const double *a, IV n) {
    double sum = 0.0;
    IV i = 0;
    
#if VEC_USE_NEON
    float64x2_t vsum = vdupq_n_f64(0.0);
    for (; i + 2 <= n; i += 2) {
        vsum = vaddq_f64(vsum, vld1q_f64(a + i));
    }
    sum = vgetq_lane_f64(vsum, 0) + vgetq_lane_f64(vsum, 1);
#elif VEC_USE_AVX || VEC_USE_AVX2
    __m256d vsum = _mm256_setzero_pd();
    for (; i + 4 <= n; i += 4) {
        vsum = _mm256_add_pd(vsum, _mm256_load_pd(a + i));
    }
    /* Horizontal sum of 4 doubles */
    __m128d low = _mm256_castpd256_pd128(vsum);
    __m128d high = _mm256_extractf128_pd(vsum, 1);
    __m128d sum128 = _mm_add_pd(low, high);
    sum128 = _mm_hadd_pd(sum128, sum128);
    sum = _mm_cvtsd_f64(sum128);
#elif VEC_USE_SSE2
    __m128d vsum = _mm_setzero_pd();
    for (; i + 2 <= n; i += 2) {
        vsum = _mm_add_pd(vsum, _mm_load_pd(a + i));
    }
    /* Horizontal sum */
    __m128d high = _mm_unpackhi_pd(vsum, vsum);
    vsum = _mm_add_sd(vsum, high);
    sum = _mm_cvtsd_f64(vsum);
#endif
    
    /* Scalar tail */
    for (; i < n; i++) {
        sum += a[i];
    }
    
    return sum;
}

/* ============================================
   SIMD Implementations - DOT PRODUCT
   ============================================ */

static double vec_dot_impl(const double *a, const double *b, IV n) {
    double dot = 0.0;
    IV i = 0;
    
#if VEC_USE_NEON
    float64x2_t vdot = vdupq_n_f64(0.0);
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vdot = vfmaq_f64(vdot, va, vb);  /* FMA: vdot += va * vb */
    }
    dot = vgetq_lane_f64(vdot, 0) + vgetq_lane_f64(vdot, 1);
#elif VEC_USE_AVX || VEC_USE_AVX2
    __m256d vdot = _mm256_setzero_pd();
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_load_pd(a + i);
        __m256d vb = _mm256_load_pd(b + i);
        #ifdef __FMA__
        vdot = _mm256_fmadd_pd(va, vb, vdot);
        #else
        vdot = _mm256_add_pd(vdot, _mm256_mul_pd(va, vb));
        #endif
    }
    __m128d low = _mm256_castpd256_pd128(vdot);
    __m128d high = _mm256_extractf128_pd(vdot, 1);
    __m128d sum128 = _mm_add_pd(low, high);
    sum128 = _mm_hadd_pd(sum128, sum128);
    dot = _mm_cvtsd_f64(sum128);
#elif VEC_USE_SSE2
    __m128d vdot = _mm_setzero_pd();
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_load_pd(a + i);
        __m128d vb = _mm_load_pd(b + i);
        vdot = _mm_add_pd(vdot, _mm_mul_pd(va, vb));
    }
    __m128d high = _mm_unpackhi_pd(vdot, vdot);
    vdot = _mm_add_sd(vdot, high);
    dot = _mm_cvtsd_f64(vdot);
#endif
    
    for (; i < n; i++) {
        dot += a[i] * b[i];
    }
    
    return dot;
}

/* ============================================
   Scalar Implementations
   ============================================ */

static double vec_min_impl(const double *a, IV n) {
    double m, m1;
    IV i;

    if (n == 0) return 0.0;
    m = a[0];
    i = 1;

#if VEC_USE_NEON
    if (n >= 3) {
        float64x2_t vmin = vld1q_f64(a);
        for (i = 2; i + 2 <= n; i += 2) {
            float64x2_t va = vld1q_f64(a + i);
            vmin = vminq_f64(vmin, va);
        }
        m = vgetq_lane_f64(vmin, 0);
        m1 = vgetq_lane_f64(vmin, 1);
        if (m1 < m) m = m1;
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    if (n >= 5) {
        __m256d vmin = _mm256_load_pd(a);
        __m128d low, high, min2;
        for (i = 4; i + 4 <= n; i += 4) {
            __m256d va = _mm256_load_pd(a + i);
            vmin = _mm256_min_pd(vmin, va);
        }
        /* Extract min from 4 lanes */
        low = _mm256_castpd256_pd128(vmin);
        high = _mm256_extractf128_pd(vmin, 1);
        min2 = _mm_min_pd(low, high);
        m = _mm_cvtsd_f64(min2);
        m1 = _mm_cvtsd_f64(_mm_unpackhi_pd(min2, min2));
        if (m1 < m) m = m1;
    }
#elif VEC_USE_SSE2
    if (n >= 3) {
        __m128d vmin = _mm_load_pd(a);
        for (i = 2; i + 2 <= n; i += 2) {
            __m128d va = _mm_load_pd(a + i);
            vmin = _mm_min_pd(vmin, va);
        }
        m = _mm_cvtsd_f64(vmin);
        m1 = _mm_cvtsd_f64(_mm_unpackhi_pd(vmin, vmin));
        if (m1 < m) m = m1;
    }
#endif

    /* Scalar tail */
    for (; i < n; i++) {
        if (a[i] < m) m = a[i];
    }
    return m;
}

static double vec_max_impl(const double *a, IV n) {
    double m, m1;
    IV i;

    if (n == 0) return 0.0;
    m = a[0];
    i = 1;

#if VEC_USE_NEON
    if (n >= 3) {
        float64x2_t vmax = vld1q_f64(a);
        for (i = 2; i + 2 <= n; i += 2) {
            float64x2_t va = vld1q_f64(a + i);
            vmax = vmaxq_f64(vmax, va);
        }
        m = vgetq_lane_f64(vmax, 0);
        m1 = vgetq_lane_f64(vmax, 1);
        if (m1 > m) m = m1;
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    if (n >= 5) {
        __m256d vmax = _mm256_load_pd(a);
        __m128d low, high, max2;
        for (i = 4; i + 4 <= n; i += 4) {
            __m256d va = _mm256_load_pd(a + i);
            vmax = _mm256_max_pd(vmax, va);
        }
        low = _mm256_castpd256_pd128(vmax);
        high = _mm256_extractf128_pd(vmax, 1);
        max2 = _mm_max_pd(low, high);
        m = _mm_cvtsd_f64(max2);
        m1 = _mm_cvtsd_f64(_mm_unpackhi_pd(max2, max2));
        if (m1 > m) m = m1;
    }
#elif VEC_USE_SSE2
    if (n >= 3) {
        __m128d vmax = _mm_load_pd(a);
        for (i = 2; i + 2 <= n; i += 2) {
            __m128d va = _mm_load_pd(a + i);
            vmax = _mm_max_pd(vmax, va);
        }
        m = _mm_cvtsd_f64(vmax);
        m1 = _mm_cvtsd_f64(_mm_unpackhi_pd(vmax, vmax));
        if (m1 > m) m = m1;
    }
#endif

    /* Scalar tail */
    for (; i < n; i++) {
        if (a[i] > m) m = a[i];
    }
    return m;
}

static IV vec_argmin_impl(const double *a, IV n) {
    IV idx, i;
    double m;
    if (n == 0) return -1;
    idx = 0;
    m = a[0];
    for (i = 1; i < n; i++) {
        if (a[i] < m) { m = a[i]; idx = i; }
    }
    return idx;
}

static IV vec_argmax_impl(const double *a, IV n) {
    IV idx, i;
    double m;
    if (n == 0) return -1;
    idx = 0;
    m = a[0];
    for (i = 1; i < n; i++) {
        if (a[i] > m) { m = a[i]; idx = i; }
    }
    return idx;
}

/* ============================================
   Custom Op Functions (pp_*)
   These bypass method dispatch for maximum performance
   ============================================ */

/* Helper to extract Vec from stack item */
#define VEC_FROM_STACK(sp, n) vec_from_sv(aTHX_ *(sp - (n)))

/* Macro: generate a pp_* function that applies a scalar expression element-wise.
 * expr_ may use x_ for the current element value. */
#define DEFINE_UNARY_PP(name_, expr_)                                   \
static OP* pp_vec_##name_(pTHX) {                                       \
    dSP;                                                                \
    Vec *a, *c;                                                         \
    IV i;                                                               \
    a = vec_from_sv(aTHX_ TOPs); POPs;                                 \
    c = vec_create(aTHX_ a->len);                                       \
    c->len = a->len;                                                    \
    for (i = 0; i < a->len; i++) {                                      \
        double x_ = a->data[i]; c->data[i] = (expr_);                  \
    }                                                                   \
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));                              \
    RETURN;                                                             \
}

/* Macro: generate a pp_* function for element-wise comparison, returning 0.0/1.0. */
#define DEFINE_CMP_PP(name_, op_)                                       \
static OP* pp_vec_##name_(pTHX) {                                       \
    dSP;                                                                \
    Vec *a, *b, *c;                                                     \
    IV len, i;                                                          \
    b = vec_from_sv(aTHX_ POPs);                                       \
    a = vec_from_sv(aTHX_ TOPs); POPs;                                 \
    len = a->len < b->len ? a->len : b->len;                            \
    c = vec_create(aTHX_ len);                                          \
    c->len = len;                                                       \
    for (i = 0; i < len; i++)                                           \
        c->data[i] = (a->data[i] op_ b->data[i]) ? 1.0 : 0.0;        \
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));                              \
    RETURN;                                                             \
}

/* pp_vec_sum: $v->sum() as a custom op */
static OP* pp_vec_sum(pTHX) {
    dSP;
    Vec *v;
    double result;

    v = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = vec_sum_impl(v->data, v->len);
    mPUSHn(result);
    RETURN;
}

/* pp_vec_mean: $v->mean() as a custom op */
static OP* pp_vec_mean(pTHX) {
    dSP;
    Vec *v;
    double result;

    v = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = v->len > 0 ? vec_sum_impl(v->data, v->len) / v->len : 0.0;
    mPUSHn(result);
    RETURN;
}

/* pp_vec_len: $v->len() as a custom op */
static OP* pp_vec_len(pTHX) {
    dSP;
    Vec *v;

    v = vec_from_sv(aTHX_ TOPs);
    POPs;
    mPUSHi(v->len);
    RETURN;
}

/* pp_vec_min: $v->min() as a custom op */
static OP* pp_vec_min(pTHX) {
    dSP;
    Vec *v;
    double result;

    v = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = vec_min_impl(v->data, v->len);
    mPUSHn(result);
    RETURN;
}

/* pp_vec_max: $v->max() as a custom op */
static OP* pp_vec_max(pTHX) {
    dSP;
    Vec *v;
    double result;

    v = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = vec_max_impl(v->data, v->len);
    mPUSHn(result);
    RETURN;
}

/* pp_vec_norm: $v->norm() as a custom op */
static OP* pp_vec_norm(pTHX) {
    dSP;
    Vec *v;
    double result;

    v = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = sqrt(vec_dot_impl(v->data, v->data, v->len));
    mPUSHn(result);
    RETURN;
}

/* pp_vec_get: $v->get($i) as a custom op - index in op_targ */
static OP* pp_vec_get(pTHX) {
    dSP;
    Vec *v;
    IV idx;

    idx = SvIV(TOPs);
    POPs;
    v = vec_from_sv(aTHX_ TOPs);
    POPs;
    if (idx < 0 || idx >= v->len) {
        croak("Numeric::Vector::get: index %ld out of bounds (len=%ld)", (long)idx, (long)v->len);
    }
    mPUSHn(v->data[idx]);
    RETURN;
}

/* pp_vec_dot: $a->dot($b) as a custom op */
static OP* pp_vec_dot(pTHX) {
    dSP;
    Vec *a, *b;
    double result;

    b = vec_from_sv(aTHX_ TOPs);
    POPs;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    if (a->len != b->len) {
        croak("Numeric::Vector::dot: vectors must have same length");
    }
    result = vec_dot_impl(a->data, b->data, a->len);
    mPUSHn(result);
    RETURN;
}

/* pp_vec_add: $a->add($b) as a custom op */
static OP* pp_vec_add(pTHX) {
    dSP;
    Vec *a, *b, *c;

    b = vec_from_sv(aTHX_ TOPs);
    POPs;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    if (a->len != b->len) {
        croak("Numeric::Vector::add: vectors must have same length");
    }
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_add_impl(c->data, a->data, b->data, a->len);
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* pp_vec_sub: $a->sub($b) as a custom op */
static OP* pp_vec_sub(pTHX) {
    dSP;
    Vec *a, *b, *c;

    b = vec_from_sv(aTHX_ TOPs);
    POPs;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    if (a->len != b->len) {
        croak("Numeric::Vector::sub: vectors must have same length");
    }
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_sub_impl(c->data, a->data, b->data, a->len);
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* pp_vec_mul: $a->mul($b) as a custom op */
static OP* pp_vec_mul(pTHX) {
    dSP;
    Vec *a, *b, *c;

    b = vec_from_sv(aTHX_ TOPs);
    POPs;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    if (a->len != b->len) {
        croak("Numeric::Vector::mul: vectors must have same length");
    }
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_mul_impl(c->data, a->data, b->data, a->len);
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* pp_vec_div: $a->div($b) as a custom op */
static OP* pp_vec_div(pTHX) {
    dSP;
    Vec *a, *b, *c;

    b = vec_from_sv(aTHX_ TOPs);
    POPs;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    if (a->len != b->len) {
        croak("Numeric::Vector::div: vectors must have same length");
    }
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_div_impl(c->data, a->data, b->data, a->len);
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* pp_vec_scale: $v->scale($s) as a custom op */
static OP* pp_vec_scale(pTHX) {
    dSP;
    Vec *a, *c;
    double s;

    s = SvNV(TOPs);
    POPs;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_scale_impl(c->data, a->data, s, a->len);
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* pp_vec_add_inplace: $a->add_inplace($b) as a custom op */
static OP* pp_vec_add_inplace(pTHX) {
    dSP;
    Vec *a, *b;

    b = vec_from_sv(aTHX_ TOPs);
    POPs;
    a = vec_from_sv(aTHX_ TOPs);
    /* Don't pop - return self */
    if (a->len != b->len) {
        croak("Numeric::Vector::add_inplace: vectors must have same length");
    }
    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::add_inplace: vector is read-only");
    }
    vec_add_impl(a->data, a->data, b->data, a->len);
    RETURN;
}

/* pp_vec_scale_inplace: $v->scale_inplace($s) as a custom op */
static OP* pp_vec_scale_inplace(pTHX) {
    dSP;
    Vec *a;
    double s;

    s = SvNV(TOPs);
    POPs;
    a = vec_from_sv(aTHX_ TOPs);
    /* Don't pop - return self */
    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::scale_inplace: vector is read-only");
    }
    vec_scale_impl(a->data, a->data, s, a->len);
    RETURN;
}

/* pp_vec_neg: $v->neg() as a custom op */
static OP* pp_vec_neg(pTHX) {
    dSP;
    Vec *a, *c;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_scale_impl(c->data, a->data, -1.0, a->len);
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

DEFINE_UNARY_PP(abs,  fabs(x_))
DEFINE_UNARY_PP(sqrt, sqrt(x_))

/* pp_vec_copy: $v->copy() as a custom op */
static OP* pp_vec_copy(pTHX) {
    dSP;
    Vec *a, *c;

    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    memcpy(c->data, a->data, a->len * sizeof(double));
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* Shared Welford single-pass variance computation.
 * Numerically stable; reads data once (better cache behaviour on large vectors). */
static double vec_welford_variance(const double *data, IV n) {
    double mean = 0.0, M2 = 0.0, delta;
    IV i;
    if (n <= 0) return 0.0;
    for (i = 0; i < n; i++) {
        delta = data[i] - mean;
        mean += delta / (i + 1);
        M2   += delta * (data[i] - mean);
    }
    return M2 / n;
}

/* pp_vec_variance: $v->variance() as a custom op */
static OP* pp_vec_variance(pTHX) {
    dSP;
    Vec *v;
    v = vec_from_sv(aTHX_ TOPs);
    POPs;
    mPUSHn(vec_welford_variance(v->data, v->len));
    RETURN;
}

/* pp_vec_std: $v->std() as a custom op */
static OP* pp_vec_std(pTHX) {
    dSP;
    Vec *v;
    v = vec_from_sv(aTHX_ TOPs);
    POPs;
    mPUSHn(sqrt(vec_welford_variance(v->data, v->len)));
    RETURN;
}

/* pp_vec_normalize: $v->normalize() as a custom op */
static OP* pp_vec_normalize(pTHX) {
    dSP;
    Vec *a, *c;
    double norm, inv;
    IV i;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    norm = sqrt(vec_dot_impl(a->data, a->data, a->len));
    if (norm > 0) {
        inv = 1.0 / norm;
        for (i = 0; i < a->len; i++) c->data[i] = a->data[i] * inv;
    } else {
        memset(c->data, 0, a->len * sizeof(double));
    }
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* Element-wise math ops generated via DEFINE_UNARY_PP */
DEFINE_UNARY_PP(exp,   exp(x_))
DEFINE_UNARY_PP(log,   log(x_))
DEFINE_UNARY_PP(sin,   sin(x_))
DEFINE_UNARY_PP(cos,   cos(x_))
DEFINE_UNARY_PP(tan,   tan(x_))
DEFINE_UNARY_PP(floor, floor(x_))
DEFINE_UNARY_PP(ceil,  ceil(x_))
DEFINE_UNARY_PP(round, floor(x_ + 0.5))
DEFINE_UNARY_PP(asin,  asin(x_))
DEFINE_UNARY_PP(acos,  acos(x_))
DEFINE_UNARY_PP(atan,  atan(x_))
DEFINE_UNARY_PP(sinh,  sinh(x_))
DEFINE_UNARY_PP(cosh,  cosh(x_))
DEFINE_UNARY_PP(tanh,  tanh(x_))
DEFINE_UNARY_PP(log10, log10(x_))
DEFINE_UNARY_PP(log2,  log2(x_))
DEFINE_UNARY_PP(sign,  ((x_) > 0 ? 1.0 : (x_) < 0 ? -1.0 : 0.0))

/* pp_vec_cumsum: cumulative sum */
static OP* pp_vec_cumsum(pTHX) {
    dSP;
    Vec *a, *c;
    double sum;
    IV i;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    sum = 0.0;
    for (i = 0; i < a->len; i++) {
        sum += a->data[i];
        c->data[i] = sum;
    }
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* pp_vec_cumprod: cumulative product */
static OP* pp_vec_cumprod(pTHX) {
    dSP;
    Vec *a, *c;
    double prod;
    IV i;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    prod = 1.0;
    for (i = 0; i < a->len; i++) {
        prod *= a->data[i];
        c->data[i] = prod;
    }
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* pp_vec_diff: first difference */
static OP* pp_vec_diff(pTHX) {
    dSP;
    Vec *a, *c;
    IV i;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    if (a->len < 2) {
        c = vec_create(aTHX_ 0);
        c->len = 0;
        PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
        RETURN;
    }
    c = vec_create(aTHX_ a->len - 1);
    c->len = a->len - 1;
    for (i = 0; i < a->len - 1; i++) {
        c->data[i] = a->data[i + 1] - a->data[i];
    }
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* pp_vec_reverse: reverse vector */
static OP* pp_vec_reverse(pTHX) {
    dSP;
    Vec *a, *c;
    IV i;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = a->data[a->len - 1 - i];
    }
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* Element-wise predicate ops generated via DEFINE_UNARY_PP */
DEFINE_UNARY_PP(isnan,    isnan(x_)    ? 1.0 : 0.0)
DEFINE_UNARY_PP(isinf,    isinf(x_)    ? 1.0 : 0.0)
DEFINE_UNARY_PP(isfinite, isfinite(x_) ? 1.0 : 0.0)

/* pp_vec_sub_inplace: $a -= $b */
static OP* pp_vec_sub_inplace(pTHX) {
    dSP;
    Vec *b = vec_from_sv(aTHX_ POPs);
    Vec *a = vec_from_sv(aTHX_ TOPs);
    vec_sub_impl(a->data, a->data, b->data, a->len < b->len ? a->len : b->len);
    RETURN;
}

/* pp_vec_mul_inplace: $a *= $b */
static OP* pp_vec_mul_inplace(pTHX) {
    dSP;
    Vec *b = vec_from_sv(aTHX_ POPs);
    Vec *a = vec_from_sv(aTHX_ TOPs);
    vec_mul_impl(a->data, a->data, b->data, a->len < b->len ? a->len : b->len);
    RETURN;
}

/* pp_vec_div_inplace: $a /= $b */
static OP* pp_vec_div_inplace(pTHX) {
    dSP;
    Vec *b = vec_from_sv(aTHX_ POPs);
    Vec *a = vec_from_sv(aTHX_ TOPs);
    vec_div_impl(a->data, a->data, b->data, a->len < b->len ? a->len : b->len);
    RETURN;
}

/* Element-wise comparison ops generated via DEFINE_CMP_PP */
DEFINE_CMP_PP(eq, ==)
DEFINE_CMP_PP(ne, !=)
DEFINE_CMP_PP(lt, <)
DEFINE_CMP_PP(le, <=)

DEFINE_CMP_PP(gt, >)
DEFINE_CMP_PP(ge, >=)

/* pp_vec_all: all elements non-zero */
static OP* pp_vec_all(pTHX) {
    dSP;
    Vec *a;
    int result;
    IV i;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = 1;
    for (i = 0; i < a->len; i++) {
        if (a->data[i] == 0.0) { result = 0; break; }
    }
    PUSHs(sv_2mortal(result ? &PL_sv_yes : &PL_sv_no));
    RETURN;
}

/* pp_vec_any: any element non-zero */
static OP* pp_vec_any(pTHX) {
    dSP;
    Vec *a;
    int result;
    IV i;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = 0;
    for (i = 0; i < a->len; i++) {
        if (a->data[i] != 0.0) { result = 1; break; }
    }
    PUSHs(sv_2mortal(result ? &PL_sv_yes : &PL_sv_no));
    RETURN;
}

/* pp_vec_count: count non-zero elements */
static OP* pp_vec_count(pTHX) {
    dSP;
    Vec *a;
    IV count, i;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    count = 0;
    for (i = 0; i < a->len; i++) {
        if (a->data[i] != 0.0) count++;
    }
    PUSHs(sv_2mortal(newSViv(count)));
    RETURN;
}

/* pp_vec_argmax: index of max element */
static OP* pp_vec_argmax(pTHX) {
    dSP;
    Vec *a;
    IV idx, i;
    double max;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    if (a->len == 0) { PUSHs(&PL_sv_undef); RETURN; }
    idx = 0;
    max = a->data[0];
    for (i = 1; i < a->len; i++) {
        if (a->data[i] > max) { max = a->data[i]; idx = i; }
    }
    PUSHs(sv_2mortal(newSViv(idx)));
    RETURN;
}

/* pp_vec_argmin: index of min element */
static OP* pp_vec_argmin(pTHX) {
    dSP;
    Vec *a;
    IV idx, i;
    double min;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    if (a->len == 0) { PUSHs(&PL_sv_undef); RETURN; }
    idx = 0;
    min = a->data[0];
    for (i = 1; i < a->len; i++) {
        if (a->data[i] < min) { min = a->data[i]; idx = i; }
    }
    PUSHs(sv_2mortal(newSViv(idx)));
    RETURN;
}

/* pp_vec_pow: element-wise power */
static OP* pp_vec_pow(pTHX) {
    dSP;
    Vec *a, *c;
    double p;
    IV i;
    p = SvNV(POPs);
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) c->data[i] = pow(a->data[i], p);
    PUSHs(sv_2mortal(vec_wrap(aTHX_ c)));
    RETURN;
}

/* pp_vec_product: product of all elements */
static OP* pp_vec_product(pTHX) {
    dSP;
    Vec *a;
    double prod;
    IV i;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    prod = 1.0;
    for (i = 0; i < a->len; i++) prod *= a->data[i];
    PUSHs(sv_2mortal(newSVnv(prod)));
    RETURN;
}

/* pp_vec_distance: Euclidean distance */
static OP* pp_vec_distance(pTHX) {
    dSP;
    Vec *a, *b;
    IV len, i;
    double sum, d;
    b = vec_from_sv(aTHX_ POPs);
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    len = a->len < b->len ? a->len : b->len;
    sum = 0.0;
    for (i = 0; i < len; i++) {
        d = a->data[i] - b->data[i];
        sum += d * d;
    }
    PUSHs(sv_2mortal(newSVnv(sqrt(sum))));
    RETURN;
}

/* pp_vec_cosine_similarity: cosine similarity */
static OP* pp_vec_cosine_similarity(pTHX) {
    dSP;
    Vec *a, *b;
    IV len;
    double dot, na, nb, result;
    b = vec_from_sv(aTHX_ POPs);
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    len = a->len < b->len ? a->len : b->len;
    dot = vec_dot_impl(a->data, b->data, len);
    na = sqrt(vec_dot_impl(a->data, a->data, len));
    nb = sqrt(vec_dot_impl(b->data, b->data, len));
    result = (na > 0 && nb > 0) ? dot / (na * nb) : 0.0;
    PUSHs(sv_2mortal(newSVnv(result)));
    RETURN;
}

/* pp functions for remaining ops */
static OP* pp_vec_axpy(pTHX) {
    dSP;
    Vec *x, *y, *self, *result;
    double alpha;
    IV len, i;

    y = vec_from_sv(aTHX_ POPs);
    x = vec_from_sv(aTHX_ POPs);
    alpha = POPn;
    self = vec_from_sv(aTHX_ TOPs);
    POPs;
    len = self->len;
    if (x->len < len) len = x->len;
    if (y->len < len) len = y->len;
    result = vec_create(aTHX_ len);
    result->len = len;
    for (i = 0; i < len; i++) {
        result->data[i] = alpha * x->data[i] + y->data[i];
    }
    PUSHs(vec_wrap(aTHX_ result));
    RETURN;
}

static OP* pp_vec_add_scalar(pTHX) {
    dSP;
    Vec *a, *result;
    double scalar;
    IV i;

    scalar = POPn;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = vec_create(aTHX_ a->len);
    result->len = a->len;
    for (i = 0; i < a->len; i++) {
        result->data[i] = a->data[i] + scalar;
    }
    PUSHs(vec_wrap(aTHX_ result));
    RETURN;
}

static OP* pp_vec_add_scalar_inplace(pTHX) {
    dSP;
    SV *self_sv;
    Vec *a;
    double scalar;
    IV i;

    scalar = POPn;
    self_sv = TOPs;
    a = vec_from_sv(aTHX_ self_sv);
    for (i = 0; i < a->len; i++) {
        a->data[i] += scalar;
    }
    RETURN;
}

static OP* pp_vec_clip(pTHX) {
    dSP;
    Vec *a, *result;
    double max_val, min_val, v;
    IV i;

    max_val = POPn;
    min_val = POPn;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = vec_create(aTHX_ a->len);
    result->len = a->len;
    for (i = 0; i < a->len; i++) {
        v = a->data[i];
        if (v < min_val) v = min_val;
        if (v > max_val) v = max_val;
        result->data[i] = v;
    }
    PUSHs(vec_wrap(aTHX_ result));
    RETURN;
}

static OP* pp_vec_clamp_inplace(pTHX) {
    dSP;
    SV *self_sv;
    Vec *a;
    double max_val, min_val, v;
    IV i;

    max_val = POPn;
    min_val = POPn;
    self_sv = TOPs;
    a = vec_from_sv(aTHX_ self_sv);
    for (i = 0; i < a->len; i++) {
        v = a->data[i];
        if (v < min_val) v = min_val;
        if (v > max_val) v = max_val;
        a->data[i] = v;
    }
    RETURN;
}

static OP* pp_vec_fma_inplace(pTHX) {
    dSP;
    double addend = POPn;
    double multiplier = POPn;
    SV *self_sv = TOPs;
    Vec *a = vec_from_sv(aTHX_ self_sv);
    IV i;
    for (i = 0; i < a->len; i++) {
        a->data[i] = a->data[i] * multiplier + addend;
    }
    RETURN;
}

static OP* pp_vec_concat(pTHX) {
    dSP;
    Vec *a, *b, *result;
    IV new_len;

    b = vec_from_sv(aTHX_ POPs);
    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    new_len = a->len + b->len;
    result = vec_create(aTHX_ new_len);
    result->len = new_len;
    memcpy(result->data, a->data, a->len * sizeof(double));
    memcpy(result->data + a->len, b->data, b->len * sizeof(double));
    PUSHs(vec_wrap(aTHX_ result));
    RETURN;
}

static int double_cmp(const void *a, const void *b) {
    double da = *(const double*)a;
    double db = *(const double*)b;
    if (da < db) return -1;
    if (da > db) return 1;
    return 0;
}

/* Comparator for argsort - struct for (index, value) pairs */
typedef struct { IV idx; double val; } IdxVal;

static int idxval_cmp(const void *x, const void *y) {
    double vx = ((const IdxVal*)x)->val;
    double vy = ((const IdxVal*)y)->val;
    if (vx < vy) return -1;
    if (vx > vy) return 1;
    return 0;
}

static OP* pp_vec_sort(pTHX) {
    dSP;
    Vec *a, *result;

    a = vec_from_sv(aTHX_ TOPs);
    POPs;
    result = vec_create(aTHX_ a->len);
    result->len = a->len;
    memcpy(result->data, a->data, a->len * sizeof(double));
    qsort(result->data, result->len, sizeof(double), double_cmp);
    PUSHs(vec_wrap(aTHX_ result));
    RETURN;
}

static OP* pp_vec_argsort(pTHX) {
    dSP;
    Vec *a, *result;
    IdxVal *pairs;
    IV i;

    a = vec_from_sv(aTHX_ TOPs);
    POPs;

    /* Create pairs of (index, value) using IdxVal defined above */
    Newx(pairs, a->len, IdxVal);
    for (i = 0; i < a->len; i++) {
        pairs[i].idx = i;
        pairs[i].val = a->data[i];
    }

    /* Sort by value using idxval_cmp defined above */
    qsort(pairs, a->len, sizeof(IdxVal), idxval_cmp);

    /* Extract indices */
    result = vec_create(aTHX_ a->len);
    result->len = a->len;
    for (i = 0; i < a->len; i++) {
        result->data[i] = (double)pairs[i].idx;
    }
    Safefree(pairs);
    PUSHs(vec_wrap(aTHX_ result));
    RETURN;
}

static OP* pp_vec_median(pTHX) {
    dSP;
    Vec *a;
    double *sorted;
    double result;

    a = vec_from_sv(aTHX_ TOPs);
    POPs;

    if (a->len == 0) {
        PUSHs(sv_2mortal(newSVnv(0.0)));
        RETURN;
    }

    /* Copy and sort */
    Newx(sorted, a->len, double);
    memcpy(sorted, a->data, a->len * sizeof(double));
    qsort(sorted, a->len, sizeof(double), double_cmp);

    if (a->len % 2 == 1) {
        result = sorted[a->len / 2];
    } else {
        result = (sorted[a->len / 2 - 1] + sorted[a->len / 2]) / 2.0;
    }
    Safefree(sorted);
    PUSHs(sv_2mortal(newSVnv(result)));
    RETURN;
}

static OP* pp_vec_slice(pTHX) {
    dSP;
    Vec *a, *empty, *result;
    IV end, start, new_len;

    end = POPi;
    start = POPi;
    a = vec_from_sv(aTHX_ TOPs);
    POPs;

    if (start < 0) start = 0;
    if (end > a->len) end = a->len;
    if (start >= end) {
        empty = vec_create(aTHX_ 0);
        empty->len = 0;
        PUSHs(vec_wrap(aTHX_ empty));
        RETURN;
    }

    new_len = end - start;
    result = vec_create(aTHX_ new_len);
    result->len = new_len;
    memcpy(result->data, a->data + start, new_len * sizeof(double));
    PUSHs(vec_wrap(aTHX_ result));
    RETURN;
}

static OP* pp_vec_where(pTHX) {
    dSP;
    Vec *if_false, *if_true, *cond, *result;
    IV len, i;

    if_false = vec_from_sv(aTHX_ POPs);
    if_true = vec_from_sv(aTHX_ POPs);
    cond = vec_from_sv(aTHX_ TOPs);
    POPs;

    len = cond->len;
    if (if_true->len < len) len = if_true->len;
    if (if_false->len < len) len = if_false->len;

    result = vec_create(aTHX_ len);
    result->len = len;
    for (i = 0; i < len; i++) {
        result->data[i] = cond->data[i] != 0.0 ? if_true->data[i] : if_false->data[i];
    }
    PUSHs(vec_wrap(aTHX_ result));
    RETURN;
}

/* Constructor pp functions */
static OP* pp_vec_new(pTHX) {
    dSP;
    SV *aref;
    AV *av;
    Vec *v;
    IV len, i;
    SV **elem;

    aref = TOPs;
    POPs;

    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Numeric::Vector::new: argument must be an arrayref");
    }

    av = (AV*)SvRV(aref);
    len = av_len(av) + 1;
    v = vec_create(aTHX_ len);
    v->len = len;

    for (i = 0; i < len; i++) {
        elem = av_fetch(av, i, 0);
        v->data[i] = elem ? SvNV(*elem) : 0.0;
    }
    PUSHs(vec_wrap(aTHX_ v));
    RETURN;
}

static OP* pp_vec_ones(pTHX) {
    dSP;
    Vec *v;
    IV len, i;

    len = POPi;
    v = vec_create(aTHX_ len);
    v->len = len;
    for (i = 0; i < len; i++) {
        v->data[i] = 1.0;
    }
    PUSHs(vec_wrap(aTHX_ v));
    RETURN;
}

static OP* pp_vec_zeros(pTHX) {
    dSP;
    Vec *v;
    IV len;

    len = POPi;
    v = vec_create(aTHX_ len);
    v->len = len;
    memset(v->data, 0, len * sizeof(double));
    PUSHs(vec_wrap(aTHX_ v));
    RETURN;
}

static OP* pp_vec_fill(pTHX) {
    dSP;
    Vec *v;
    double val;
    IV len, i;

    val = POPn;
    len = POPi;
    v = vec_create(aTHX_ len);
    v->len = len;
    for (i = 0; i < len; i++) {
        v->data[i] = val;
    }
    PUSHs(vec_wrap(aTHX_ v));
    RETURN;
}

static OP* pp_vec_fill_range(pTHX) {
    dSP;
    Vec *v;
    double step, start, val;
    IV len, i;

    step = POPn;
    start = POPn;
    len = POPi;
    v = vec_create(aTHX_ len);
    v->len = len;
    val = start;
    for (i = 0; i < len; i++) {
        v->data[i] = val;
        val += step;
    }
    PUSHs(vec_wrap(aTHX_ v));
    RETURN;
}

static OP* pp_vec_linspace(pTHX) {
    dSP;
    Vec *v;
    IV count, i;
    double end, start, step;

    count = POPi;
    end = POPn;
    start = POPn;

    if (count < 2) count = 2;
    v = vec_create(aTHX_ count);
    v->len = count;
    step = (end - start) / (count - 1);
    for (i = 0; i < count; i++) {
        v->data[i] = start + i * step;
    }
    PUSHs(vec_wrap(aTHX_ v));
    RETURN;
}

static OP* pp_vec_range(pTHX) {
    dSP;
    Vec *v;
    IV end, start, len, i;

    end = POPi;
    start = POPi;

    len = end > start ? end - start : 0;
    v = vec_create(aTHX_ len);
    v->len = len;
    for (i = 0; i < len; i++) {
        v->data[i] = (double)(start + i);
    }
    PUSHs(vec_wrap(aTHX_ v));
    RETURN;
}

static OP* pp_vec_random(pTHX) {
    dSP;
    Vec *v;
    IV len, i;

    len = POPi;
    v = vec_create(aTHX_ len);
    v->len = len;
    for (i = 0; i < len; i++) {
        v->data[i] = (double)rand() / RAND_MAX;
    }
    PUSHs(vec_wrap(aTHX_ v));
    RETURN;
}

/* Element access pp functions */
static OP* pp_vec_set(pTHX) {
    dSP;
    SV *self_sv;
    Vec *v;
    double val;
    IV idx;

    val = POPn;
    idx = POPi;
    self_sv = TOPs;
    v = vec_from_sv(aTHX_ self_sv);

    if (idx < 0 || idx >= v->len) {
        croak("Numeric::Vector::set: index %ld out of bounds (len=%ld)", (long)idx, (long)v->len);
    }
    v->data[idx] = val;
    RETURN;
}

/* Utility pp functions */
static OP* pp_vec_to_array(pTHX) {
    dSP;
    Vec *v;
    AV *av;
    IV i;

    v = vec_from_sv(aTHX_ TOPs);
    POPs;

    av = newAV();
    av_extend(av, v->len - 1);
    for (i = 0; i < v->len; i++) {
        av_push(av, newSVnv(v->data[i]));
    }
    PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
    RETURN;
}

static OP* pp_vec_simd_info(pTHX) {
    dSP;
    HV *hv;

    /* Pop self (not used) */
    POPs;

    hv = newHV();
    hv_store(hv, "implementation", 14, newSVpv(VEC_SIMD_NAME, 0), 0);
    hv_store(hv, "lanes", 5, newSViv(VEC_LANES), 0);
    hv_store(hv, "alignment", 9, newSViv(VEC_ALIGN), 0);
    PUSHs(sv_2mortal(newRV_noinc((SV*)hv)));
    RETURN;
}

/* ============================================
   Call Checkers - Optimize method calls to custom ops
   ============================================ */

/* Generic call checker for unary methods (0-arg after self) */
static OP* vec_unary_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*pp_func)(pTHX)) {
    OP *pushop, *selfop, *nextop, *cvop, *newop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    /* Get the argument list */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) return entersubop;

    selfop = OpSIBLING(pushop);
    if (!selfop) return entersubop;

    /* Check if next sibling is the method call (no extra args) */
    nextop = OpSIBLING(selfop);
    if (!nextop) return entersubop;

    /* Should be just self and the method CV */
    if (OpSIBLING(nextop)) {
        /* More args - might be cv op, check if it's the last */
        cvop = OpSIBLING(nextop);
        if (cvop && OpSIBLING(cvop)) return entersubop; /* Too many args */
    }

    /* Detach self from the list */
    OpMORESIB_set(pushop, nextop);
    OpLASTSIB_set(selfop, NULL);

    /* Create custom op */
    newop = newUNOP(OP_CUSTOM, 0, selfop);
    newop->op_ppaddr = pp_func;

    op_free(entersubop);
    return newop;
}

/* Specific call checkers for each method */
static OP* vec_sum_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_sum);
}

static OP* vec_mean_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_mean);
}

static OP* vec_len_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_len);
}

static OP* vec_min_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_min);
}

static OP* vec_max_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_max);
}

static OP* vec_norm_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_norm);
}

static OP* vec_neg_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_neg);
}

static OP* vec_abs_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_abs);
}

static OP* vec_sqrt_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_sqrt);
}

static OP* vec_copy_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_copy);
}

static OP* vec_variance_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_variance);
}

static OP* vec_std_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_std);
}

static OP* vec_normalize_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_normalize);
}

/* Generic call checker for binary methods (1-arg after self) */
static OP* vec_binary_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*pp_func)(pTHX)) {
    OP *pushop, *selfop, *argop, *cvop, *newop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    /* Get the argument list: pushmark -> self -> arg -> cv */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) return entersubop;

    selfop = OpSIBLING(pushop);
    if (!selfop || !OpHAS_SIBLING(selfop)) return entersubop;

    argop = OpSIBLING(selfop);
    if (!argop || !OpHAS_SIBLING(argop)) return entersubop;

    cvop = OpSIBLING(argop);
    if (!cvop) return entersubop;

    /* Should be exactly 2 args + cv */
    if (OpSIBLING(cvop)) return entersubop;  /* Too many args */

    /* Detach self and arg from the list */
    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(selfop, NULL);
    OpLASTSIB_set(argop, NULL);

    /* Build: arg on top of self */
    OpMORESIB_set(selfop, argop);

    /* Create custom BINOP-like with both args */
    newop = newUNOP(OP_CUSTOM, 0, selfop);
    newop->op_ppaddr = pp_func;

    op_free(entersubop);
    return newop;
}

/* Binary call checkers */
static OP* vec_add_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_add);
}

static OP* vec_sub_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_sub);
}

static OP* vec_mul_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_mul);
}

static OP* vec_div_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_div);
}

static OP* vec_scale_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_scale);
}

static OP* vec_dot_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_dot);
}

/* More unary call checkers for math functions */
static OP* vec_exp_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_exp);
}

static OP* vec_log_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_log);
}

static OP* vec_sin_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_sin);
}

static OP* vec_cos_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_cos);
}

static OP* vec_tan_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_tan);
}

static OP* vec_floor_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_floor);
}

static OP* vec_ceil_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_ceil);
}

static OP* vec_round_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_round);
}

static OP* vec_asin_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_asin);
}

static OP* vec_acos_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_acos);
}

static OP* vec_atan_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_atan);
}

static OP* vec_sinh_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_sinh);
}

static OP* vec_cosh_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_cosh);
}

static OP* vec_tanh_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_tanh);
}

static OP* vec_log10_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_log10);
}

static OP* vec_log2_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_log2);
}

static OP* vec_sign_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_sign);
}

static OP* vec_cumsum_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_cumsum);
}

static OP* vec_cumprod_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_cumprod);
}

static OP* vec_diff_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_diff);
}

static OP* vec_reverse_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_reverse);
}

static OP* vec_isnan_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_isnan);
}

static OP* vec_isinf_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_isinf);
}

static OP* vec_isfinite_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_isfinite);
}

/* In-place binary call checkers */
static OP* vec_add_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_add_inplace);
}

static OP* vec_sub_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_sub_inplace);
}

static OP* vec_mul_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_mul_inplace);
}

static OP* vec_div_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_div_inplace);
}

static OP* vec_scale_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_scale_inplace);
}

/* Comparison call checkers */
static OP* vec_eq_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_eq);
}

static OP* vec_ne_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_ne);
}

static OP* vec_lt_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_lt);
}

static OP* vec_le_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_le);
}

static OP* vec_gt_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_gt);
}

static OP* vec_ge_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_ge);
}

/* Boolean reduction call checkers (unary) */
static OP* vec_all_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_all);
}

static OP* vec_any_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_any);
}

static OP* vec_count_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_count);
}

/* Arg ops call checkers (unary) */
static OP* vec_argmax_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_argmax);
}

static OP* vec_argmin_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_argmin);
}

/* Math call checkers */
static OP* vec_pow_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_pow);
}

static OP* vec_product_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_product);
}

/* Linear algebra call checkers */
static OP* vec_distance_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_distance);
}

static OP* vec_cosine_similarity_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_cosine_similarity);
}

/* Ternary call checker for axpy(alpha, x, y) */
static OP* vec_ternary_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*pp_func)(pTHX)) {
    OP *pushop, *selfop, *arg1op, *arg2op, *arg3op, *nextop, *listop, *newop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) return entersubop;

    selfop = OpSIBLING(pushop);
    if (!selfop) return entersubop;

    arg1op = OpSIBLING(selfop);
    if (!arg1op) return entersubop;

    arg2op = OpSIBLING(arg1op);
    if (!arg2op) return entersubop;

    arg3op = OpSIBLING(arg2op);
    if (!arg3op) return entersubop;

    nextop = OpSIBLING(arg3op);
    if (!nextop) return entersubop;

    if (OpSIBLING(nextop)) return entersubop;

    OpMORESIB_set(pushop, nextop);
    OpLASTSIB_set(selfop, NULL);
    OpMORESIB_set(selfop, arg1op);
    OpMORESIB_set(arg1op, arg2op);
    OpMORESIB_set(arg2op, arg3op);
    OpLASTSIB_set(arg3op, NULL);

    listop = op_prepend_elem(OP_LIST, selfop, NULL);
    listop = op_append_elem(OP_LIST, listop, arg1op);
    listop = op_append_elem(OP_LIST, listop, arg2op);
    listop = op_append_elem(OP_LIST, listop, arg3op);

    newop = newUNOP(OP_CUSTOM, 0, listop);
    newop->op_ppaddr = pp_func;

    op_free(entersubop);
    return newop;
}

static OP* vec_axpy_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_axpy);
}

static OP* vec_add_scalar_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_add_scalar);
}

static OP* vec_add_scalar_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_add_scalar_inplace);
}

static OP* vec_clip_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_clip);
}

static OP* vec_clamp_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_clamp_inplace);
}

static OP* vec_fma_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_fma_inplace);
}

static OP* vec_concat_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_concat);
}

static OP* vec_sort_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_sort);
}

static OP* vec_argsort_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_argsort);
}

static OP* vec_median_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_median);
}

static OP* vec_slice_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_slice);
}

static OP* vec_where_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_where);
}

/* Constructor call checkers - use unary for single arg constructors */
static OP* vec_new_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_new);
}

static OP* vec_ones_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_ones);
}

static OP* vec_zeros_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_zeros);
}

static OP* vec_random_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_random);
}

static OP* vec_fill_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_fill);
}

static OP* vec_fill_range_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_fill_range);
}

static OP* vec_linspace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_linspace);
}

static OP* vec_range_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_range);
}

/* Element access call checkers */
static OP* vec_get_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_get);
}

static OP* vec_set_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_set);
}

/* Utility call checkers */
static OP* vec_to_array_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_to_array);
}

static OP* vec_simd_info_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return vec_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_vec_simd_info);
}

/* ============================================
   XS Functions - Constructors
   ============================================ */

XS_INTERNAL(xs_vec_new) {
    dXSARGS;
    SV *aref;
    AV *av;
    IV len, i;
    Vec *v;
    SV **svp;
    if (items != 1) croak("Usage: vec::new(\\@array)");
    
    aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Numeric::Vector::new: argument must be an arrayref");
    }
    
    av = (AV*)SvRV(aref);
    len = av_len(av) + 1;
    
    v = vec_create(aTHX_ len);
    v->len = len;
    
    for (i = 0; i < len; i++) {
        svp = av_fetch(av, i, 0);
        v->data[i] = svp ? SvNV(*svp) : 0.0;
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ v));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_zeros) {
    dXSARGS;
    IV n;
    Vec *v;
    if (items != 1) croak("Usage: vec::zeros($n)");
    
    n = SvIV(ST(0));
    if (n < 0) croak("Numeric::Vector::zeros: size must be non-negative");
    
    v = vec_create(aTHX_ n);
    v->len = n;
    memset(v->data, 0, n * sizeof(double));
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ v));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_ones) {
    dXSARGS;
    IV n, i;
    Vec *v;
    if (items != 1) croak("Usage: vec::ones($n)");
    
    n = SvIV(ST(0));
    if (n < 0) croak("Numeric::Vector::ones: size must be non-negative");
    
    v = vec_create(aTHX_ n);
    v->len = n;
    for (i = 0; i < n; i++) {
        v->data[i] = 1.0;
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ v));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_fill) {
    dXSARGS;
    IV n, i;
    double val;
    Vec *v;
    if (items != 2) croak("Usage: vec::fill($n, $value)");
    
    n = SvIV(ST(0));
    val = SvNV(ST(1));
    if (n < 0) croak("Numeric::Vector::fill: size must be non-negative");
    
    v = vec_create(aTHX_ n);
    v->len = n;
    for (i = 0; i < n; i++) {
        v->data[i] = val;
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ v));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_range) {
    dXSARGS;
    IV start, end, n, i;
    Vec *v;
    if (items != 2) croak("Usage: vec::range($start, $end)");
    
    start = SvIV(ST(0));
    end = SvIV(ST(1));
    n = end - start;
    if (n < 0) n = 0;
    
    v = vec_create(aTHX_ n);
    v->len = n;
    for (i = 0; i < n; i++) {
        v->data[i] = (double)(start + i);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ v));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_linspace) {
    dXSARGS;
    double start, end, step;
    IV n, i;
    Vec *v;
    if (items != 3) croak("Usage: vec::linspace($start, $end, $n)");
    
    start = SvNV(ST(0));
    end = SvNV(ST(1));
    n = SvIV(ST(2));
    if (n < 0) croak("Numeric::Vector::linspace: count must be non-negative");
    
    v = vec_create(aTHX_ n);
    v->len = n;
    
    if (n == 1) {
        v->data[0] = start;
    } else if (n > 1) {
        step = (end - start) / (n - 1);
        for (i = 0; i < n; i++) {
            v->data[i] = start + i * step;
        }
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ v));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Element Access
   ============================================ */

XS_INTERNAL(xs_vec_get) {
    dXSARGS;
    Vec *v;
    IV idx;
    if (items != 2) croak("Usage: $v->get($index)");
    
    v = vec_from_sv(aTHX_ ST(0));
    idx = SvIV(ST(1));
    
    if (idx < 0 || idx >= v->len) {
        croak("Numeric::Vector::get: index %ld out of bounds (len=%ld)", (long)idx, (long)v->len);
    }
    
    ST(0) = sv_2mortal(newSVnv(v->data[idx]));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_set) {
    dXSARGS;
    Vec *v;
    IV idx;
    double val;
    if (items != 3) croak("Usage: $v->set($index, $value)");
    
    v = vec_from_sv(aTHX_ ST(0));
    idx = SvIV(ST(1));
    val = SvNV(ST(2));
    
    if (idx < 0 || idx >= v->len) {
        croak("Numeric::Vector::set: index %ld out of bounds (len=%ld)", (long)idx, (long)v->len);
    }
    if (v->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::set: vector is read-only");
    }
    
    v->data[idx] = val;
    ST(0) = ST(0);  /* Return self */
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_len) {
    dXSARGS;
    Vec *v;
    if (items != 1) croak("Usage: $v->len()");
    
    v = vec_from_sv(aTHX_ ST(0));
    XSRETURN_IV(v->len);
}

XS_INTERNAL(xs_vec_to_array) {
    dXSARGS;
    Vec *v;
    AV *av;
    IV i;
    if (items != 1) croak("Usage: $v->to_array()");
    
    v = vec_from_sv(aTHX_ ST(0));
    av = newAV();
    av_extend(av, v->len - 1);
    
    for (i = 0; i < v->len; i++) {
        av_push(av, newSVnv(v->data[i]));
    }
    
    ST(0) = sv_2mortal(newRV_noinc((SV*)av));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Arithmetic
   ============================================ */

XS_INTERNAL(xs_vec_add) {
    dXSARGS;
    Vec *a, *b, *c;
    if (items != 2) croak("Usage: $a->add($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::add: vectors must have same length (%ld vs %ld)", 
              (long)a->len, (long)b->len);
    }
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_add_impl(c->data, a->data, b->data, a->len);
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_sub) {
    dXSARGS;
    Vec *a, *b, *c;
    if (items != 2) croak("Usage: $a->sub($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::sub: vectors must have same length");
    }
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_sub_impl(c->data, a->data, b->data, a->len);
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_mul) {
    dXSARGS;
    Vec *a, *b, *c;
    if (items != 2) croak("Usage: $a->mul($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::mul: vectors must have same length");
    }
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_mul_impl(c->data, a->data, b->data, a->len);
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_div) {
    dXSARGS;
    Vec *a, *b, *c;
    if (items != 2) croak("Usage: $a->div($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::div: vectors must have same length");
    }
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_div_impl(c->data, a->data, b->data, a->len);
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_scale) {
    dXSARGS;
    Vec *a, *c;
    double s;
    if (items != 2) croak("Usage: $v->scale($scalar)");
    
    a = vec_from_sv(aTHX_ ST(0));
    s = SvNV(ST(1));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_scale_impl(c->data, a->data, s, a->len);
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_add_scalar) {
    dXSARGS;
    Vec *a, *c;
    double s;
    IV i;
    if (items != 2) croak("Usage: $v->add_scalar($scalar)");
    
    a = vec_from_sv(aTHX_ ST(0));
    s = SvNV(ST(1));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = a->data[i] + s;
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_neg) {
    dXSARGS;
    Vec *a, *c;
    if (items != 1) croak("Usage: $v->neg()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    vec_scale_impl(c->data, a->data, -1.0, a->len);
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_abs) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->abs()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = fabs(a->data[i]);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_sqrt) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->sqrt()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = sqrt(a->data[i]);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_pow) {
    dXSARGS;
    Vec *a, *c;
    double exp_val;
    IV i;
    if (items != 2) croak("Usage: $v->pow($exp)");
    
    a = vec_from_sv(aTHX_ ST(0));
    exp_val = SvNV(ST(1));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = pow(a->data[i], exp_val);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_exp) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->exp()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = exp(a->data[i]);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_log) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->log()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = log(a->data[i]);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_sin) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->sin()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = sin(a->data[i]);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_cos) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->cos()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = cos(a->data[i]);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_tan) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->tan()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = tan(a->data[i]);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_floor) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->floor()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = floor(a->data[i]);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_ceil) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->ceil()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = ceil(a->data[i]);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_round) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->round()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = floor(a->data[i] + 0.5);
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Comparison (return vec of 0/1)
   ============================================ */

XS_INTERNAL(xs_vec_eq) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 2) croak("Usage: $a->eq($b)");

    a = vec_from_sv(aTHX_ ST(0));
    c = vec_create(aTHX_ a->len);
    c->len = a->len;

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) {
            croak("Numeric::Vector::eq: vectors must have same length");
        }
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] == b->data[i]) ? 1.0 : 0.0;
        }
    } else {
        double s = SvNV(ST(1));
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] == s) ? 1.0 : 0.0;
        }
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_ne) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 2) croak("Usage: $a->ne($b)");

    a = vec_from_sv(aTHX_ ST(0));
    c = vec_create(aTHX_ a->len);
    c->len = a->len;

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) {
            croak("Numeric::Vector::ne: vectors must have same length");
        }
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] != b->data[i]) ? 1.0 : 0.0;
        }
    } else {
        double s = SvNV(ST(1));
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] != s) ? 1.0 : 0.0;
        }
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_lt) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 2) croak("Usage: $a->lt($b)");

    a = vec_from_sv(aTHX_ ST(0));
    c = vec_create(aTHX_ a->len);
    c->len = a->len;

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) {
            croak("Numeric::Vector::lt: vectors must have same length");
        }
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] < b->data[i]) ? 1.0 : 0.0;
        }
    } else {
        double s = SvNV(ST(1));
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] < s) ? 1.0 : 0.0;
        }
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_le) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 2) croak("Usage: $a->le($b)");

    a = vec_from_sv(aTHX_ ST(0));
    c = vec_create(aTHX_ a->len);
    c->len = a->len;

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) {
            croak("Numeric::Vector::le: vectors must have same length");
        }
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] <= b->data[i]) ? 1.0 : 0.0;
        }
    } else {
        double s = SvNV(ST(1));
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] <= s) ? 1.0 : 0.0;
        }
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_gt) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 2) croak("Usage: $a->gt($b)");

    a = vec_from_sv(aTHX_ ST(0));
    c = vec_create(aTHX_ a->len);
    c->len = a->len;

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) {
            croak("Numeric::Vector::gt: vectors must have same length");
        }
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] > b->data[i]) ? 1.0 : 0.0;
        }
    } else {
        double s = SvNV(ST(1));
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] > s) ? 1.0 : 0.0;
        }
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_ge) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 2) croak("Usage: $a->ge($b)");

    a = vec_from_sv(aTHX_ ST(0));
    c = vec_create(aTHX_ a->len);
    c->len = a->len;

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) {
            croak("Numeric::Vector::ge: vectors must have same length");
        }
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] >= b->data[i]) ? 1.0 : 0.0;
        }
    } else {
        double s = SvNV(ST(1));
        for (i = 0; i < a->len; i++) {
            c->data[i] = (a->data[i] >= s) ? 1.0 : 0.0;
        }
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Selection and Utility
   ============================================ */

XS_INTERNAL(xs_vec_reverse) {
    dXSARGS;
    Vec *a, *c;
    IV i;
    if (items != 1) croak("Usage: $v->reverse()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    for (i = 0; i < a->len; i++) {
        c->data[i] = a->data[a->len - 1 - i];
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_concat) {
    dXSARGS;
    Vec *a, *b, *c;
    if (items != 2) croak("Usage: $a->concat($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    c = vec_create(aTHX_ a->len + b->len);
    c->len = a->len + b->len;
    memcpy(c->data, a->data, a->len * sizeof(double));
    memcpy(c->data + a->len, b->data, b->len * sizeof(double));
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_any) {
    dXSARGS;
    Vec *v;
    IV i;
    if (items != 1) croak("Usage: $v->any()");
    
    v = vec_from_sv(aTHX_ ST(0));
    
    for (i = 0; i < v->len; i++) {
        if (v->data[i] != 0.0) {
            ST(0) = &PL_sv_yes;
            XSRETURN(1);
        }
    }
    ST(0) = &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_all) {
    dXSARGS;
    Vec *v;
    IV i;
    if (items != 1) croak("Usage: $v->all()");
    
    v = vec_from_sv(aTHX_ ST(0));
    
    for (i = 0; i < v->len; i++) {
        if (v->data[i] == 0.0) {
            ST(0) = &PL_sv_no;
            XSRETURN(1);
        }
    }
    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_count) {
    dXSARGS;
    Vec *v;
    IV count, i;
    if (items != 1) croak("Usage: $v->count()  # count non-zero elements");
    
    v = vec_from_sv(aTHX_ ST(0));
    count = 0;
    
    for (i = 0; i < v->len; i++) {
        if (v->data[i] != 0.0) count++;
    }
    
    ST(0) = sv_2mortal(newSViv(count));
    XSRETURN(1);
}

/* Apply mask: select elements where mask is non-zero */
XS_INTERNAL(xs_vec_where) {
    dXSARGS;
    Vec *v, *mask, *c;
    IV count, i, j;
    if (items != 2) croak("Usage: $v->where($mask)");
    
    v = vec_from_sv(aTHX_ ST(0));
    mask = vec_from_sv(aTHX_ ST(1));
    
    if (v->len != mask->len) {
        croak("Numeric::Vector::where: vectors must have same length");
    }
    
    /* Count non-zero mask elements */
    count = 0;
    for (i = 0; i < mask->len; i++) {
        if (mask->data[i] != 0.0) count++;
    }
    
    c = vec_create(aTHX_ count);
    c->len = count;
    j = 0;
    for (i = 0; i < v->len; i++) {
        if (mask->data[i] != 0.0) {
            c->data[j++] = v->data[i];
        }
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

/* Random vec with values in [0, 1) */
XS_INTERNAL(xs_vec_random) {
    dXSARGS;
    IV n, i;
    Vec *v;
    if (items != 1) croak("Usage: vec::random($n)");
    
    n = SvIV(ST(0));
    if (n < 0) croak("Numeric::Vector::random: size must be non-negative");
    
    v = vec_create(aTHX_ n);
    v->len = n;
    for (i = 0; i < n; i++) {
        v->data[i] = (double)rand() / RAND_MAX;
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ v));
    XSRETURN(1);
}

/* ============================================
   XS Functions - In-place Operations
   ============================================ */

XS_INTERNAL(xs_vec_add_inplace) {
    dXSARGS;
    Vec *a, *b;
    if (items != 2) croak("Usage: $a->add_inplace($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::add_inplace: vectors must have same length");
    }
    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::add_inplace: vector is read-only");
    }
    
    vec_add_impl(a->data, a->data, b->data, a->len);
    
    ST(0) = ST(0);  /* Return self */
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_scale_inplace) {
    dXSARGS;
    Vec *a;
    double s;

    if (items != 2) croak("Usage: $v->scale_inplace($scalar)");

    a = vec_from_sv(aTHX_ ST(0));
    s = SvNV(ST(1));

    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::scale_inplace: vector is read-only");
    }

    vec_scale_impl(a->data, a->data, s, a->len);

    ST(0) = ST(0);
    XSRETURN(1);
}

/* SIMD add scalar in place */
XS_INTERNAL(xs_vec_add_scalar_inplace) {
    dXSARGS;
    Vec *a;
    double s;
    IV i;

    if (items != 2) croak("Usage: $v->add_scalar_inplace($scalar)");

    a = vec_from_sv(aTHX_ ST(0));
    s = SvNV(ST(1));

    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::add_scalar_inplace: vector is read-only");
    }

    i = 0;
#if defined(VEC_USE_NEON)
    {
        float64x2_t vs = vdupq_n_f64(s);
        for (; i + VEC_LANES <= a->len; i += VEC_LANES) {
            float64x2_t va = vld1q_f64(&a->data[i]);
            vst1q_f64(&a->data[i], vaddq_f64(va, vs));
        }
    }
#elif defined(VEC_USE_AVX) || defined(VEC_USE_AVX2)
    {
        __m256d vs = _mm256_set1_pd(s);
        for (; i + VEC_LANES <= a->len; i += VEC_LANES) {
            __m256d va = _mm256_load_pd(&a->data[i]);
            _mm256_store_pd(&a->data[i], _mm256_add_pd(va, vs));
        }
    }
#elif defined(VEC_USE_SSE2)
    {
        __m128d vs = _mm_set1_pd(s);
        for (; i + VEC_LANES <= a->len; i += VEC_LANES) {
            __m128d va = _mm_load_pd(&a->data[i]);
            _mm_store_pd(&a->data[i], _mm_add_pd(va, vs));
        }
    }
#endif
    for (; i < a->len; i++) {
        a->data[i] += s;
    }

    ST(0) = ST(0);
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_clamp_inplace) {
    dXSARGS;
    Vec *a;
    double minv, maxv;
    IV i;
    if (items != 3) croak("Usage: $v->clamp_inplace($min, $max)");
    
    a = vec_from_sv(aTHX_ ST(0));
    minv = SvNV(ST(1));
    maxv = SvNV(ST(2));
    
    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::clamp_inplace: vector is read-only");
    }
    
    for (i = 0; i < a->len; i++) {
        if (a->data[i] < minv) a->data[i] = minv;
        else if (a->data[i] > maxv) a->data[i] = maxv;
    }
    
    ST(0) = ST(0);
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_sub_inplace) {
    dXSARGS;
    Vec *a, *b;
    if (items != 2) croak("Usage: $a->sub_inplace($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::sub_inplace: vectors must have same length");
    }
    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::sub_inplace: vector is read-only");
    }
    
    vec_sub_impl(a->data, a->data, b->data, a->len);
    
    ST(0) = ST(0);
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_mul_inplace) {
    dXSARGS;
    Vec *a, *b;
    if (items != 2) croak("Usage: $a->mul_inplace($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::mul_inplace: vectors must have same length");
    }
    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::mul_inplace: vector is read-only");
    }
    
    vec_mul_impl(a->data, a->data, b->data, a->len);
    
    ST(0) = ST(0);
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_div_inplace) {
    dXSARGS;
    Vec *a, *b;
    if (items != 2) croak("Usage: $a->div_inplace($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::div_inplace: vectors must have same length");
    }
    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::div_inplace: vector is read-only");
    }
    
    vec_div_impl(a->data, a->data, b->data, a->len);
    
    ST(0) = ST(0);
    XSRETURN(1);
}

/* ============================================
   XS Functions - Slicing and Copy
   ============================================ */

XS_INTERNAL(xs_vec_slice) {
    dXSARGS;
    Vec *a, *c;
    IV start, len;
    if (items != 3) croak("Usage: $v->slice($start, $len)");
    
    a = vec_from_sv(aTHX_ ST(0));
    start = SvIV(ST(1));
    len = SvIV(ST(2));
    
    if (start < 0) start = a->len + start;
    if (start < 0 || start >= a->len) {
        croak("Numeric::Vector::slice: start index out of bounds");
    }
    if (len < 0 || start + len > a->len) {
        croak("Numeric::Vector::slice: slice extends beyond vector");
    }
    
    c = vec_create(aTHX_ len);
    c->len = len;
    memcpy(c->data, a->data + start, len * sizeof(double));
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_copy) {
    dXSARGS;
    Vec *a, *c;
    if (items != 1) croak("Usage: $v->copy()");
    
    a = vec_from_sv(aTHX_ ST(0));
    
    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    memcpy(c->data, a->data, a->len * sizeof(double));
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

/* Fill a range with a value (useful for masking) */
XS_INTERNAL(xs_vec_fill_range) {
    dXSARGS;
    Vec *a;
    IV start, len, i;
    double val;
    if (items != 4) croak("Usage: $v->fill_range($start, $len, $value)");
    
    a = vec_from_sv(aTHX_ ST(0));
    start = SvIV(ST(1));
    len = SvIV(ST(2));
    val = SvNV(ST(3));
    
    if (a->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::fill_range: vector is read-only");
    }
    if (start < 0) start = a->len + start;
    if (start < 0 || start >= a->len) {
        croak("Numeric::Vector::fill_range: start index out of bounds");
    }
    if (len < 0 || start + len > a->len) {
        croak("Numeric::Vector::fill_range: range extends beyond vector");
    }
    
    for (i = start; i < start + len; i++) {
        a->data[i] = val;
    }
    
    ST(0) = ST(0);
    XSRETURN(1);
}

/* ============================================
   XS Functions - FMA (Fused Multiply-Add)
   ============================================ */

/* c = a * b + c (in-place on c) */
XS_INTERNAL(xs_vec_fma_inplace) {
    Vec *c, *a, *b;
    IV n, i;
    dXSARGS;
    if (items != 3) croak("Usage: $c->fma_inplace($a, $b)  # c = a*b + c");

    c = vec_from_sv(aTHX_ ST(0));
    a = vec_from_sv(aTHX_ ST(1));
    b = vec_from_sv(aTHX_ ST(2));

    if (a->len != b->len || a->len != c->len) {
        croak("Numeric::Vector::fma_inplace: vectors must have same length");
    }
    if (c->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::fma_inplace: vector is read-only");
    }

    n = a->len;
    i = 0;
    
#if VEC_USE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a->data + i);
        float64x2_t vb = vld1q_f64(b->data + i);
        float64x2_t vc = vld1q_f64(c->data + i);
        vst1q_f64(c->data + i, vfmaq_f64(vc, va, vb));
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_load_pd(a->data + i);
        __m256d vb = _mm256_load_pd(b->data + i);
        __m256d vc = _mm256_load_pd(c->data + i);
        #ifdef __FMA__
        _mm256_store_pd(c->data + i, _mm256_fmadd_pd(va, vb, vc));
        #else
        _mm256_store_pd(c->data + i, _mm256_add_pd(_mm256_mul_pd(va, vb), vc));
        #endif
    }
#elif VEC_USE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_load_pd(a->data + i);
        __m128d vb = _mm_load_pd(b->data + i);
        __m128d vc = _mm_load_pd(c->data + i);
        _mm_store_pd(c->data + i, _mm_add_pd(_mm_mul_pd(va, vb), vc));
    }
#endif
    
    for (; i < n; i++) {
        c->data[i] = a->data[i] * b->data[i] + c->data[i];
    }
    
    ST(0) = ST(0);
    XSRETURN(1);
}

/* axpy: y = a*x + y (BLAS-style) */
XS_INTERNAL(xs_vec_axpy) {
    dXSARGS;
    Vec *y, *x;
    double a;
    IV n, i;
    if (items != 3) croak("Usage: $y->axpy($a, $x)  # y = a*x + y");
    
    y = vec_from_sv(aTHX_ ST(0));
    a = SvNV(ST(1));
    x = vec_from_sv(aTHX_ ST(2));
    
    if (x->len != y->len) {
        croak("Numeric::Vector::axpy: vectors must have same length");
    }
    if (y->flags & VEC_FLAG_READONLY) {
        croak("Numeric::Vector::axpy: vector is read-only");
    }
    
    n = x->len;
    i = 0;
    
#if VEC_USE_NEON
    {
    float64x2_t va = vdupq_n_f64(a);
    for (; i + 2 <= n; i += 2) {
        float64x2_t vx = vld1q_f64(x->data + i);
        float64x2_t vy = vld1q_f64(y->data + i);
        vst1q_f64(y->data + i, vfmaq_f64(vy, va, vx));
    }
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    {
    __m256d va = _mm256_set1_pd(a);
    for (; i + 4 <= n; i += 4) {
        __m256d vx = _mm256_load_pd(x->data + i);
        __m256d vy = _mm256_load_pd(y->data + i);
        #ifdef __FMA__
        _mm256_store_pd(y->data + i, _mm256_fmadd_pd(va, vx, vy));
        #else
        _mm256_store_pd(y->data + i, _mm256_add_pd(_mm256_mul_pd(va, vx), vy));
        #endif
    }
    }
#elif VEC_USE_SSE2
    {
    __m128d va = _mm_set1_pd(a);
    for (; i + 2 <= n; i += 2) {
        __m128d vx = _mm_load_pd(x->data + i);
        __m128d vy = _mm_load_pd(y->data + i);
        _mm_store_pd(y->data + i, _mm_add_pd(_mm_mul_pd(va, vx), vy));
    }
    }
#endif
    
    for (; i < n; i++) {
        y->data[i] = a * x->data[i] + y->data[i];
    }
    
    ST(0) = ST(0);
    XSRETURN(1);
}

/* ============================================
   XS Functions - Reductions
   ============================================ */

XS_INTERNAL(xs_vec_sum) {
    dXSARGS;
    Vec *v;
    double sum;
    if (items != 1) croak("Usage: $v->sum()");
    
    v = vec_from_sv(aTHX_ ST(0));
    sum = vec_sum_impl(v->data, v->len);
    
    ST(0) = sv_2mortal(newSVnv(sum));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_product) {
    dXSARGS;
    Vec *v;
    double prod;
    IV i;
    if (items != 1) croak("Usage: $v->product()");
    
    v = vec_from_sv(aTHX_ ST(0));
    prod = 1.0;
    for (i = 0; i < v->len; i++) {
        prod *= v->data[i];
    }
    
    ST(0) = sv_2mortal(newSVnv(prod));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_mean) {
    dXSARGS;
    Vec *v;
    double sum;
    if (items != 1) croak("Usage: $v->mean()");
    
    v = vec_from_sv(aTHX_ ST(0));
    if (v->len == 0) {
        ST(0) = sv_2mortal(newSVnv(0.0));
    } else {
        sum = vec_sum_impl(v->data, v->len);
        ST(0) = sv_2mortal(newSVnv(sum / v->len));
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_variance) {
    dXSARGS;
    Vec *v;
    double mean, sum_sq;
    IV i;
    if (items != 1) croak("Usage: $v->variance()");
    
    v = vec_from_sv(aTHX_ ST(0));
    if (v->len < 2) {
        ST(0) = sv_2mortal(newSVnv(0.0));
        XSRETURN(1);
    }
    
    /* Two-pass algorithm for numerical stability */
    mean = vec_sum_impl(v->data, v->len) / v->len;
    sum_sq = 0.0;
    i = 0;
    
#if VEC_USE_NEON
    {
    float64x2_t vmean = vdupq_n_f64(mean);
    float64x2_t vsum = vdupq_n_f64(0.0);
    for (; i + 2 <= v->len; i += 2) {
        float64x2_t vd = vsubq_f64(vld1q_f64(v->data + i), vmean);
        vsum = vfmaq_f64(vsum, vd, vd);
    }
    sum_sq = vgetq_lane_f64(vsum, 0) + vgetq_lane_f64(vsum, 1);
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    {
    __m256d vmean = _mm256_set1_pd(mean);
    __m256d vsum = _mm256_setzero_pd();
    __m128d low, high, sum128;
    for (; i + 4 <= v->len; i += 4) {
        __m256d vd = _mm256_sub_pd(_mm256_load_pd(v->data + i), vmean);
        #ifdef __FMA__
        vsum = _mm256_fmadd_pd(vd, vd, vsum);
        #else
        vsum = _mm256_add_pd(vsum, _mm256_mul_pd(vd, vd));
        #endif
    }
    low = _mm256_castpd256_pd128(vsum);
    high = _mm256_extractf128_pd(vsum, 1);
    sum128 = _mm_add_pd(low, high);
    sum128 = _mm_hadd_pd(sum128, sum128);
    sum_sq = _mm_cvtsd_f64(sum128);
    }
#elif VEC_USE_SSE2
    {
    __m128d vmean = _mm_set1_pd(mean);
    __m128d vsum = _mm_setzero_pd();
    __m128d high;
    for (; i + 2 <= v->len; i += 2) {
        __m128d vd = _mm_sub_pd(_mm_load_pd(v->data + i), vmean);
        vsum = _mm_add_pd(vsum, _mm_mul_pd(vd, vd));
    }
    high = _mm_unpackhi_pd(vsum, vsum);
    vsum = _mm_add_sd(vsum, high);
    sum_sq = _mm_cvtsd_f64(vsum);
    }
#endif

    for (; i < v->len; i++) {
        double d = v->data[i] - mean;
        sum_sq += d * d;
    }
    
    ST(0) = sv_2mortal(newSVnv(sum_sq / (v->len - 1)));  /* Sample variance */
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_std) {
    Vec *v;
    double mean, sum_sq;
    IV i;
    dXSARGS;
    if (items != 1) croak("Usage: $v->std()");

    v = vec_from_sv(aTHX_ ST(0));
    if (v->len < 2) {
        ST(0) = sv_2mortal(newSVnv(0.0));
        XSRETURN(1);
    }

    mean = vec_sum_impl(v->data, v->len) / v->len;
    sum_sq = 0.0;
    i = 0;

#if VEC_USE_NEON
    {
        float64x2_t vmean = vdupq_n_f64(mean);
        float64x2_t vsum = vdupq_n_f64(0.0);
        for (; i + 2 <= v->len; i += 2) {
            float64x2_t vd = vsubq_f64(vld1q_f64(v->data + i), vmean);
            vsum = vfmaq_f64(vsum, vd, vd);
        }
        sum_sq = vgetq_lane_f64(vsum, 0) + vgetq_lane_f64(vsum, 1);
    }
#elif VEC_USE_AVX || VEC_USE_AVX2
    {
        __m256d vmean = _mm256_set1_pd(mean);
        __m256d vsum = _mm256_setzero_pd();
        __m128d low, high, sum128;
        for (; i + 4 <= v->len; i += 4) {
            __m256d vd = _mm256_sub_pd(_mm256_load_pd(v->data + i), vmean);
            #ifdef __FMA__
            vsum = _mm256_fmadd_pd(vd, vd, vsum);
            #else
            vsum = _mm256_add_pd(vsum, _mm256_mul_pd(vd, vd));
            #endif
        }
        low = _mm256_castpd256_pd128(vsum);
        high = _mm256_extractf128_pd(vsum, 1);
        sum128 = _mm_add_pd(low, high);
        sum128 = _mm_hadd_pd(sum128, sum128);
        sum_sq = _mm_cvtsd_f64(sum128);
    }
#elif VEC_USE_SSE2
    {
        __m128d vmean = _mm_set1_pd(mean);
        __m128d vsum = _mm_setzero_pd();
        __m128d high;
        for (; i + 2 <= v->len; i += 2) {
            __m128d vd = _mm_sub_pd(_mm_load_pd(v->data + i), vmean);
            vsum = _mm_add_pd(vsum, _mm_mul_pd(vd, vd));
        }
        high = _mm_unpackhi_pd(vsum, vsum);
        vsum = _mm_add_sd(vsum, high);
        sum_sq = _mm_cvtsd_f64(vsum);
    }
#endif
    
    for (; i < v->len; i++) {
        double d = v->data[i] - mean;
        sum_sq += d * d;
    }
    
    ST(0) = sv_2mortal(newSVnv(sqrt(sum_sq / (v->len - 1))));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_min) {
    Vec *v;
    dXSARGS;
    if (items != 1) croak("Usage: $v->min()");

    v = vec_from_sv(aTHX_ ST(0));
    if (v->len == 0) {
        XSRETURN_UNDEF;
    }
    ST(0) = sv_2mortal(newSVnv(vec_min_impl(v->data, v->len)));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_max) {
    Vec *v;
    dXSARGS;
    if (items != 1) croak("Usage: $v->max()");

    v = vec_from_sv(aTHX_ ST(0));
    if (v->len == 0) {
        XSRETURN_UNDEF;
    }
    ST(0) = sv_2mortal(newSVnv(vec_max_impl(v->data, v->len)));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_argmin) {
    Vec *v;
    dXSARGS;
    if (items != 1) croak("Usage: $v->argmin()");

    v = vec_from_sv(aTHX_ ST(0));
    XSRETURN_IV(vec_argmin_impl(v->data, v->len));
}

XS_INTERNAL(xs_vec_argmax) {
    Vec *v;
    dXSARGS;
    if (items != 1) croak("Usage: $v->argmax()");

    v = vec_from_sv(aTHX_ ST(0));
    XSRETURN_IV(vec_argmax_impl(v->data, v->len));
}

XS_INTERNAL(xs_vec_dot) {
    Vec *a, *b;
    double dot;
    dXSARGS;
    if (items != 2) croak("Usage: $a->dot($b)");

    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));

    if (a->len != b->len) {
        croak("Numeric::Vector::dot: vectors must have same length");
    }

    dot = vec_dot_impl(a->data, b->data, a->len);
    ST(0) = sv_2mortal(newSVnv(dot));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_norm) {
    Vec *v;
    double dot;
    dXSARGS;
    if (items != 1) croak("Usage: $v->norm()");

    v = vec_from_sv(aTHX_ ST(0));
    dot = vec_dot_impl(v->data, v->data, v->len);

    ST(0) = sv_2mortal(newSVnv(sqrt(dot)));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Linear Algebra
   ============================================ */

XS_INTERNAL(xs_vec_normalize) {
    Vec *a, *c;
    double norm;
    dXSARGS;
    if (items != 1) croak("Usage: $v->normalize()");

    a = vec_from_sv(aTHX_ ST(0));
    norm = sqrt(vec_dot_impl(a->data, a->data, a->len));

    c = vec_create(aTHX_ a->len);
    c->len = a->len;
    
    if (norm > 0) {
        vec_scale_impl(c->data, a->data, 1.0 / norm, a->len);
    } else {
        memset(c->data, 0, a->len * sizeof(double));
    }
    
    ST(0) = sv_2mortal(vec_wrap(aTHX_ c));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_distance) {
    dXSARGS;
    Vec *a, *b;
    double sum, d;
    IV i;
    if (items != 2) croak("Usage: $a->distance($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::distance: vectors must have same length");
    }
    
    sum = 0.0;
    for (i = 0; i < a->len; i++) {
        d = a->data[i] - b->data[i];
        sum += d * d;
    }
    
    ST(0) = sv_2mortal(newSVnv(sqrt(sum)));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_cosine_similarity) {
    dXSARGS;
    Vec *a, *b;
    double dot, norm_a, norm_b, denom;
    if (items != 2) croak("Usage: $a->cosine_similarity($b)");
    
    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));
    
    if (a->len != b->len) {
        croak("Numeric::Vector::cosine_similarity: vectors must have same length");
    }
    
    dot = vec_dot_impl(a->data, b->data, a->len);
    norm_a = sqrt(vec_dot_impl(a->data, a->data, a->len));
    norm_b = sqrt(vec_dot_impl(b->data, b->data, b->len));
    
    denom = norm_a * norm_b;
    if (denom == 0) {
        ST(0) = sv_2mortal(newSVnv(0.0));
    } else {
        ST(0) = sv_2mortal(newSVnv(dot / denom));
    }
    XSRETURN(1);
}

/* ============================================
   XS Functions - More Math
   ============================================ */

XS_INTERNAL(xs_vec_asin) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->asin()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) result->data[i] = asin(v->data[i]);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_acos) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->acos()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) result->data[i] = acos(v->data[i]);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_atan) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->atan()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) result->data[i] = atan(v->data[i]);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_sinh) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->sinh()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) result->data[i] = sinh(v->data[i]);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_cosh) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->cosh()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) result->data[i] = cosh(v->data[i]);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_tanh) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->tanh()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) result->data[i] = tanh(v->data[i]);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_log10) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->log10()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) result->data[i] = log10(v->data[i]);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_log2) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->log2()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) result->data[i] = log2(v->data[i]);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_sign) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    double x;
    if (items != 1) croak("Usage: $v->sign()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) {
        x = v->data[i];
        result->data[i] = (x > 0.0) ? 1.0 : (x < 0.0) ? -1.0 : 0.0;
    }
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_clip) {
    dXSARGS;
    Vec *v, *result;
    double min_val, max_val, x;
    IV i;
    if (items != 3) croak("Usage: $v->clip($min, $max)");
    v = vec_from_sv(aTHX_ ST(0));
    min_val = SvNV(ST(1));
    max_val = SvNV(ST(2));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) {
        x = v->data[i];
        if (x < min_val) x = min_val;
        if (x > max_val) x = max_val;
        result->data[i] = x;
    }
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Cumulative/Scan
   ============================================ */

XS_INTERNAL(xs_vec_cumsum) {
    dXSARGS;
    Vec *v, *result;
    double sum;
    IV i;
    if (items != 1) croak("Usage: $v->cumsum()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    sum = 0.0;
    for (i = 0; i < v->len; i++) {
        sum += v->data[i];
        result->data[i] = sum;
    }
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_cumprod) {
    dXSARGS;
    Vec *v, *result;
    double prod;
    IV i;
    if (items != 1) croak("Usage: $v->cumprod()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    prod = 1.0;
    for (i = 0; i < v->len; i++) {
        prod *= v->data[i];
        result->data[i] = prod;
    }
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_diff) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->diff()");
    v = vec_from_sv(aTHX_ ST(0));
    if (v->len < 2) {
        result = vec_create(aTHX_ 0);
        ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
        XSRETURN(1);
    }
    result = vec_create(aTHX_ v->len - 1);
    result->len = v->len - 1;
    for (i = 0; i < v->len - 1; i++) {
        result->data[i] = v->data[i + 1] - v->data[i];
    }
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Sorting
   ============================================ */

static int compare_doubles(const void *a, const void *b) {
    double da = *(const double *)a;
    double db = *(const double *)b;
    return (da > db) - (da < db);
}

XS_INTERNAL(xs_vec_sort) {
    dXSARGS;
    Vec *v, *result;
    if (items != 1) croak("Usage: $v->sort()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    memcpy(result->data, v->data, v->len * sizeof(double));
    qsort(result->data, result->len, sizeof(double), compare_doubles);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

typedef struct { double val; IV idx; } IndexedDouble;

static int compare_indexed(const void *a, const void *b) {
    double da = ((const IndexedDouble *)a)->val;
    double db = ((const IndexedDouble *)b)->val;
    return (da > db) - (da < db);
}

XS_INTERNAL(xs_vec_argsort) {
    dXSARGS;
    Vec *v, *result;
    IndexedDouble *indexed;
    IV i;
    if (items != 1) croak("Usage: $v->argsort()");
    v = vec_from_sv(aTHX_ ST(0));
    
    indexed = (IndexedDouble *)malloc(v->len * sizeof(IndexedDouble));
    if (!indexed) croak("Out of memory");
    
    for (i = 0; i < v->len; i++) {
        indexed[i].val = v->data[i];
        indexed[i].idx = i;
    }
    
    qsort(indexed, v->len, sizeof(IndexedDouble), compare_indexed);
    
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) {
        result->data[i] = (double)indexed[i].idx;
    }
    
    free(indexed);
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Statistics
   ============================================ */

XS_INTERNAL(xs_vec_median) {
    dXSARGS;
    Vec *v;
    double *sorted, median;
    if (items != 1) croak("Usage: $v->median()");
    v = vec_from_sv(aTHX_ ST(0));
    if (v->len == 0) {
        ST(0) = sv_2mortal(newSVnv(0.0));
        XSRETURN(1);
    }
    
    sorted = (double *)malloc(v->len * sizeof(double));
    if (!sorted) croak("Out of memory");
    memcpy(sorted, v->data, v->len * sizeof(double));
    qsort(sorted, v->len, sizeof(double), compare_doubles);
    
    if (v->len % 2 == 1) {
        median = sorted[v->len / 2];
    } else {
        median = (sorted[v->len / 2 - 1] + sorted[v->len / 2]) / 2.0;
    }
    
    free(sorted);
    ST(0) = sv_2mortal(newSVnv(median));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Checking
   ============================================ */

XS_INTERNAL(xs_vec_isnan) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->isnan()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) {
        result->data[i] = isnan(v->data[i]) ? 1.0 : 0.0;
    }
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_isinf) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->isinf()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) {
        result->data[i] = isinf(v->data[i]) ? 1.0 : 0.0;
    }
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

XS_INTERNAL(xs_vec_isfinite) {
    dXSARGS;
    Vec *v, *result;
    IV i;
    if (items != 1) croak("Usage: $v->isfinite()");
    v = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ v->len);
    result->len = v->len;
    for (i = 0; i < v->len; i++) {
        result->data[i] = isfinite(v->data[i]) ? 1.0 : 0.0;
    }
    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* ============================================
   XS Functions - Info
   ============================================ */

XS_INTERNAL(xs_vec_simd_info) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    ST(0) = sv_2mortal(newSVpv(VEC_SIMD_NAME, 0));
    XSRETURN(1);
}

/* ============================================
   Exported C API (for other XS modules)
   ============================================ */

PERL_CALLCONV Vec* vec_xs_create(pTHX_ IV capacity) {
    return vec_create(aTHX_ capacity);
}

PERL_CALLCONV void vec_xs_destroy(pTHX_ Vec *v) {
    vec_destroy(aTHX_ v);
}

PERL_CALLCONV Vec* vec_xs_from_sv(pTHX_ SV *sv) {
    return vec_from_sv(aTHX_ sv);
}

PERL_CALLCONV SV* vec_xs_wrap(pTHX_ Vec *v) {
    return vec_wrap(aTHX_ v);
}

PERL_CALLCONV double* vec_xs_data(Vec *v) {
    return v->data;
}

PERL_CALLCONV IV vec_xs_len(Vec *v) {
    return v->len;
}

PERL_CALLCONV void vec_xs_add_impl(double *c, const double *a, const double *b, IV n) {
    vec_add_impl(c, a, b, n);
}

PERL_CALLCONV void vec_xs_sub_impl(double *c, const double *a, const double *b, IV n) {
    vec_sub_impl(c, a, b, n);
}

PERL_CALLCONV void vec_xs_mul_impl(double *c, const double *a, const double *b, IV n) {
    vec_mul_impl(c, a, b, n);
}

PERL_CALLCONV void vec_xs_div_impl(double *c, const double *a, const double *b, IV n) {
    vec_div_impl(c, a, b, n);
}

PERL_CALLCONV void vec_xs_scale_impl(double *c, const double *a, double s, IV n) {
    vec_scale_impl(c, a, s, n);
}

PERL_CALLCONV void vec_xs_add_inplace_impl(double *a, const double *b, IV n) {
    /* Add in-place: a[i] += b[i] */
    vec_add_impl(a, a, b, n);
}

PERL_CALLCONV void vec_xs_scale_inplace_impl(double *a, double s, IV n) {
    /* Scale in-place: a[i] *= s */
    vec_scale_impl(a, a, s, n);
}

/* Add scalar to vector: c[i] = a[i] + s */
static void vec_add_scalar_impl(double *c, const double *a, double s, IV n) {
    IV i;
    for (i = 0; i < n; i++) {
        c[i] = a[i] + s;
    }
}

PERL_CALLCONV double vec_xs_sum_impl(const double *a, IV n) {
    return vec_sum_impl(a, n);
}

PERL_CALLCONV double vec_xs_dot_impl(const double *a, const double *b, IV n) {
    return vec_dot_impl(a, b, n);
}

PERL_CALLCONV const char* vec_xs_simd_name(void) {
    return VEC_SIMD_NAME;
}

/* ============================================
   Overload Handlers
   ============================================ */

/* Helper to check if SV is an Numeric::Vector */
static int sv_is_nvec(pTHX_ SV *sv) {
    if (!SvROK(sv)) return 0;
    return sv_derived_from(sv, "Numeric::Vector");
}

/* Overload: + (add) */
XS_INTERNAL(xs_overload_add) {
    dXSARGS;
    Vec *a;
    Vec *result;

    if (items < 2) croak("Usage: Numeric::Vector + operand");

    a = vec_from_sv(aTHX_ ST(0));

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) croak("Vectors must have same length");
        result = vec_create(aTHX_ a->len);
        result->len = a->len;
        vec_add_impl(result->data, a->data, b->data, a->len);
    } else {
        double s = SvNV(ST(1));
        result = vec_create(aTHX_ a->len);
        result->len = a->len;
        vec_add_scalar_impl(result->data, a->data, s, a->len);
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* Overload: - (subtract) */
XS_INTERNAL(xs_overload_sub) {
    dXSARGS;
    Vec *a;
    Vec *result;
    int swap;

    if (items < 2) croak("Usage: Numeric::Vector - operand");

    a = vec_from_sv(aTHX_ ST(0));
    swap = (items > 2 && SvTRUE(ST(2)));

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) croak("Vectors must have same length");
        result = vec_create(aTHX_ a->len);
        result->len = a->len;
        if (swap) {
            vec_sub_impl(result->data, b->data, a->data, a->len);
        } else {
            vec_sub_impl(result->data, a->data, b->data, a->len);
        }
    } else {
        double s = SvNV(ST(1));
        result = vec_create(aTHX_ a->len);
        result->len = a->len;
        if (swap) {
            IV i;
            for (i = 0; i < a->len; i++) {
                result->data[i] = s - a->data[i];
            }
        } else {
            vec_add_scalar_impl(result->data, a->data, -s, a->len);
        }
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* Overload: * (multiply) */
XS_INTERNAL(xs_overload_mul) {
    dXSARGS;
    Vec *a;
    Vec *result;

    if (items < 2) croak("Usage: Numeric::Vector * operand");

    a = vec_from_sv(aTHX_ ST(0));

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) croak("Vectors must have same length");
        result = vec_create(aTHX_ a->len);
        result->len = a->len;
        vec_mul_impl(result->data, a->data, b->data, a->len);
    } else {
        double s = SvNV(ST(1));
        result = vec_create(aTHX_ a->len);
        result->len = a->len;
        vec_scale_impl(result->data, a->data, s, a->len);
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* Overload: / (divide) */
XS_INTERNAL(xs_overload_div) {
    dXSARGS;
    Vec *a;
    Vec *result;
    int swap;

    if (items < 2) croak("Usage: Numeric::Vector / operand");

    a = vec_from_sv(aTHX_ ST(0));
    swap = (items > 2 && SvTRUE(ST(2)));

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) croak("Vectors must have same length");
        result = vec_create(aTHX_ a->len);
        result->len = a->len;
        if (swap) {
            vec_div_impl(result->data, b->data, a->data, a->len);
        } else {
            vec_div_impl(result->data, a->data, b->data, a->len);
        }
    } else {
        double s = SvNV(ST(1));
        result = vec_create(aTHX_ a->len);
        result->len = a->len;
        if (swap) {
            IV i;
            for (i = 0; i < a->len; i++) {
                result->data[i] = s / a->data[i];
            }
        } else {
            vec_scale_impl(result->data, a->data, 1.0 / s, a->len);
        }
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* Overload: += (add assign) */
XS_INTERNAL(xs_overload_add_assign) {
    dXSARGS;
    Vec *a;

    if (items < 2) croak("Usage: Numeric::Vector += operand");

    a = vec_from_sv(aTHX_ ST(0));

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) croak("Vectors must have same length");
        vec_add_impl(a->data, a->data, b->data, a->len);
    } else {
        double s = SvNV(ST(1));
        vec_add_scalar_impl(a->data, a->data, s, a->len);
    }

    XSRETURN(1);
}

/* Overload: -= (subtract assign) */
XS_INTERNAL(xs_overload_sub_assign) {
    dXSARGS;
    Vec *a;

    if (items < 2) croak("Usage: Numeric::Vector -= operand");

    a = vec_from_sv(aTHX_ ST(0));

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) croak("Vectors must have same length");
        vec_sub_impl(a->data, a->data, b->data, a->len);
    } else {
        double s = SvNV(ST(1));
        vec_add_scalar_impl(a->data, a->data, -s, a->len);
    }

    XSRETURN(1);
}

/* Overload: *= (multiply assign) */
XS_INTERNAL(xs_overload_mul_assign) {
    dXSARGS;
    Vec *a;

    if (items < 2) croak("Usage: Numeric::Vector *= operand");

    a = vec_from_sv(aTHX_ ST(0));

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) croak("Vectors must have same length");
        vec_mul_impl(a->data, a->data, b->data, a->len);
    } else {
        double s = SvNV(ST(1));
        vec_scale_impl(a->data, a->data, s, a->len);
    }

    XSRETURN(1);
}

/* Overload: /= (divide assign) */
XS_INTERNAL(xs_overload_div_assign) {
    dXSARGS;
    Vec *a;

    if (items < 2) croak("Usage: Numeric::Vector /= operand");

    a = vec_from_sv(aTHX_ ST(0));

    if (sv_is_nvec(aTHX_ ST(1))) {
        Vec *b = vec_from_sv(aTHX_ ST(1));
        if (a->len != b->len) croak("Vectors must have same length");
        vec_div_impl(a->data, a->data, b->data, a->len);
    } else {
        double s = SvNV(ST(1));
        vec_scale_impl(a->data, a->data, 1.0 / s, a->len);
    }

    XSRETURN(1);
}

/* Overload: neg (unary minus) */
XS_INTERNAL(xs_overload_neg) {
    dXSARGS;
    Vec *a;
    Vec *result;
    IV i;
    PERL_UNUSED_ARG(items);

    a = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ a->len);
    result->len = a->len;

    for (i = 0; i < a->len; i++) {
        result->data[i] = -a->data[i];
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* Overload: abs */
XS_INTERNAL(xs_overload_abs) {
    dXSARGS;
    Vec *a;
    Vec *result;
    IV i;
    PERL_UNUSED_ARG(items);

    a = vec_from_sv(aTHX_ ST(0));
    result = vec_create(aTHX_ a->len);
    result->len = a->len;

    for (i = 0; i < a->len; i++) {
        result->data[i] = fabs(a->data[i]);
    }

    ST(0) = sv_2mortal(vec_wrap(aTHX_ result));
    XSRETURN(1);
}

/* Overload: "" (stringify) */
XS_INTERNAL(xs_overload_stringify) {
    dXSARGS;
    Vec *v;
    SV *result;
    IV len;
    IV i;
    PERL_UNUSED_ARG(items);

    v = vec_from_sv(aTHX_ ST(0));
    len = v->len;

    /* Cast double to NV for NVgf format compatibility (handles quadmath builds) */
    if (len <= 10) {
        result = newSVpvs("Numeric::Vector[");
        for (i = 0; i < len; i++) {
            if (i > 0) sv_catpvs(result, ", ");
            sv_catpvf(result, "%" NVgf, (NV)v->data[i]);
        }
        sv_catpvs(result, "]");
    } else {
        result = newSVpvs("Numeric::Vector[");
        for (i = 0; i < 5; i++) {
            if (i > 0) sv_catpvs(result, ", ");
            sv_catpvf(result, "%" NVgf, (NV)v->data[i]);
        }
        sv_catpvs(result, ", ..., ");
        for (i = len - 3; i < len; i++) {
            if (i > len - 3) sv_catpvs(result, ", ");
            sv_catpvf(result, "%" NVgf, (NV)v->data[i]);
        }
        sv_catpvf(result, "] (len=%" IVdf ")", len);
    }

    ST(0) = sv_2mortal(result);
    XSRETURN(1);
}

/* Overload: == (equality) */
XS_INTERNAL(xs_overload_eq) {
    dXSARGS;
    Vec *a;
    Vec *b;
    IV i;

    if (items < 2) croak("Usage: Numeric::Vector == operand");

    if (!sv_is_nvec(aTHX_ ST(1))) {
        ST(0) = &PL_sv_no;
        XSRETURN(1);
    }

    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));

    if (a->len != b->len) {
        ST(0) = &PL_sv_no;
        XSRETURN(1);
    }

    for (i = 0; i < a->len; i++) {
        if (a->data[i] != b->data[i]) {
            ST(0) = &PL_sv_no;
            XSRETURN(1);
        }
    }

    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}

/* Overload: != (not equal) */
XS_INTERNAL(xs_overload_ne) {
    dXSARGS;
    Vec *a;
    Vec *b;
    IV i;

    if (items < 2) croak("Usage: Numeric::Vector != operand");

    if (!sv_is_nvec(aTHX_ ST(1))) {
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
    }

    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));

    if (a->len != b->len) {
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
    }

    for (i = 0; i < a->len; i++) {
        if (a->data[i] != b->data[i]) {
            ST(0) = &PL_sv_yes;
            XSRETURN(1);
        }
    }

    ST(0) = &PL_sv_no;
    XSRETURN(1);
}

/* Overload: eq (string equality) - same as == for Numeric::Vector */
XS_INTERNAL(xs_overload_streq) {
    dXSARGS;
    Vec *a;
    Vec *b;
    IV i;

    if (items < 2) croak("Usage: Numeric::Vector eq operand");

    if (!sv_is_nvec(aTHX_ ST(1))) {
        ST(0) = &PL_sv_no;
        XSRETURN(1);
    }

    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));

    if (a->len != b->len) {
        ST(0) = &PL_sv_no;
        XSRETURN(1);
    }

    for (i = 0; i < a->len; i++) {
        if (a->data[i] != b->data[i]) {
            ST(0) = &PL_sv_no;
            XSRETURN(1);
        }
    }

    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}

/* Overload: ne (string inequality) - same as != for Numeric::Vector */
XS_INTERNAL(xs_overload_strne) {
    dXSARGS;
    Vec *a;
    Vec *b;
    IV i;

    if (items < 2) croak("Usage: Numeric::Vector ne operand");

    if (!sv_is_nvec(aTHX_ ST(1))) {
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
    }

    a = vec_from_sv(aTHX_ ST(0));
    b = vec_from_sv(aTHX_ ST(1));

    if (a->len != b->len) {
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
    }

    for (i = 0; i < a->len; i++) {
        if (a->data[i] != b->data[i]) {
            ST(0) = &PL_sv_yes;
            XSRETURN(1);
        }
    }

    ST(0) = &PL_sv_no;
    XSRETURN(1);
}

/* Overload: bool */
XS_INTERNAL(xs_overload_bool) {
    dXSARGS;
    Vec *v;
    PERL_UNUSED_ARG(items);

    v = vec_from_sv(aTHX_ ST(0));
    ST(0) = (v->len > 0) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* ============================================
   _nvec_install($caller_pkg, @names)

   XS worker called by Numeric::Vector::import (defined in Vector.pm).
   ST(0) = caller package name (string), ST(1..n) = function names.
   Installs nvec_$name into $caller_pkg for each requested name.
   ============================================ */

XS_INTERNAL(xs_nvec_install) {
    dXSARGS;
    const char *caller_pkg;
    HV         *caller_stash;
    I32         i;

    if (items < 2)
        XSRETURN_EMPTY;

    caller_pkg   = SvPV_nolen(ST(0));
    caller_stash = gv_stashpv(caller_pkg, GV_ADD);

    for (i = 1; i < items; i++) {
        const char *name = SvPV_nolen(ST(i));
        char src_name[512];
        char dst_name[512];
        CV  *src_cv;
        GV  *gv;

        if ((size_t)snprintf(src_name, sizeof(src_name),
                             "Numeric::Vector::%s", name) >= sizeof(src_name))
            croak("Numeric::Vector::import: name too long: '%s'", name);

        src_cv = get_cv(src_name, 0);
        if (!src_cv)
            croak("Numeric::Vector::import: unknown function '%s'", name);

        if ((size_t)snprintf(dst_name, sizeof(dst_name),
                             "%s::nvec_%s", caller_pkg, name) >= sizeof(dst_name))
            croak("Numeric::Vector::import: destination name too long");

        gv = gv_fetchpv(dst_name, GV_ADD, SVt_PVCV);
        GvMULTI_on(gv);  /* suppress "used only once" warning */
        if (GvCV(gv) && GvCV(gv) != src_cv)
            warn("Subroutine nvec_%s redefined", name);

        GvCV_set(gv, src_cv);
        SvREFCNT_inc_simple_void_NN((SV*)src_cv);
        GvCVGEN(gv) = 0;
        mro_method_changed_in(caller_stash);
    }

    XSRETURN_EMPTY;
}

/* ============================================
   BOOT
   ============================================ */

XS_EXTERNAL(boot_Numeric__Vector);
XS_EXTERNAL(boot_Numeric__Vector) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    
    /* Import helper — called by the Perl-level import() in Vector.pm */
    newXS("Numeric::Vector::_nvec_install", xs_nvec_install, __FILE__);

    /* Constructors */
    newXS("Numeric::Vector::new", xs_vec_new, __FILE__);
    newXS("Numeric::Vector::zeros", xs_vec_zeros, __FILE__);
    newXS("Numeric::Vector::ones", xs_vec_ones, __FILE__);
    newXS("Numeric::Vector::fill", xs_vec_fill, __FILE__);
    newXS("Numeric::Vector::range", xs_vec_range, __FILE__);
    newXS("Numeric::Vector::linspace", xs_vec_linspace, __FILE__);
    newXS("Numeric::Vector::random", xs_vec_random, __FILE__);
    
    /* Element access */
    newXS("Numeric::Vector::get", xs_vec_get, __FILE__);
    newXS("Numeric::Vector::set", xs_vec_set, __FILE__);
    newXS("Numeric::Vector::len", xs_vec_len, __FILE__);
    newXS("Numeric::Vector::to_array", xs_vec_to_array, __FILE__);
    
    /* Arithmetic */
    newXS("Numeric::Vector::add", xs_vec_add, __FILE__);
    newXS("Numeric::Vector::sub", xs_vec_sub, __FILE__);
    newXS("Numeric::Vector::mul", xs_vec_mul, __FILE__);
    newXS("Numeric::Vector::div", xs_vec_div, __FILE__);
    newXS("Numeric::Vector::scale", xs_vec_scale, __FILE__);
    newXS("Numeric::Vector::add_scalar", xs_vec_add_scalar, __FILE__);
    newXS("Numeric::Vector::neg", xs_vec_neg, __FILE__);
    newXS("Numeric::Vector::abs", xs_vec_abs, __FILE__);
    newXS("Numeric::Vector::sqrt", xs_vec_sqrt, __FILE__);
    newXS("Numeric::Vector::pow", xs_vec_pow, __FILE__);
    newXS("Numeric::Vector::exp", xs_vec_exp, __FILE__);
    newXS("Numeric::Vector::log", xs_vec_log, __FILE__);
    newXS("Numeric::Vector::sin", xs_vec_sin, __FILE__);
    newXS("Numeric::Vector::cos", xs_vec_cos, __FILE__);
    newXS("Numeric::Vector::tan", xs_vec_tan, __FILE__);
    newXS("Numeric::Vector::floor", xs_vec_floor, __FILE__);
    newXS("Numeric::Vector::ceil", xs_vec_ceil, __FILE__);
    newXS("Numeric::Vector::round", xs_vec_round, __FILE__);
    newXS("Numeric::Vector::asin", xs_vec_asin, __FILE__);
    newXS("Numeric::Vector::acos", xs_vec_acos, __FILE__);
    newXS("Numeric::Vector::atan", xs_vec_atan, __FILE__);
    newXS("Numeric::Vector::sinh", xs_vec_sinh, __FILE__);
    newXS("Numeric::Vector::cosh", xs_vec_cosh, __FILE__);
    newXS("Numeric::Vector::tanh", xs_vec_tanh, __FILE__);
    newXS("Numeric::Vector::log10", xs_vec_log10, __FILE__);
    newXS("Numeric::Vector::log2", xs_vec_log2, __FILE__);
    newXS("Numeric::Vector::sign", xs_vec_sign, __FILE__);
    newXS("Numeric::Vector::clip", xs_vec_clip, __FILE__);
    
    /* Comparison (return vec of 0/1) */
    newXS("Numeric::Vector::eq", xs_vec_eq, __FILE__);
    newXS("Numeric::Vector::ne", xs_vec_ne, __FILE__);
    newXS("Numeric::Vector::lt", xs_vec_lt, __FILE__);
    newXS("Numeric::Vector::le", xs_vec_le, __FILE__);
    newXS("Numeric::Vector::gt", xs_vec_gt, __FILE__);
    newXS("Numeric::Vector::ge", xs_vec_ge, __FILE__);
    
    /* Selection/Utility */
    newXS("Numeric::Vector::reverse", xs_vec_reverse, __FILE__);
    newXS("Numeric::Vector::concat", xs_vec_concat, __FILE__);
    newXS("Numeric::Vector::any", xs_vec_any, __FILE__);
    newXS("Numeric::Vector::all", xs_vec_all, __FILE__);
    newXS("Numeric::Vector::count", xs_vec_count, __FILE__);
    newXS("Numeric::Vector::where", xs_vec_where, __FILE__);
    newXS("Numeric::Vector::cumsum", xs_vec_cumsum, __FILE__);
    newXS("Numeric::Vector::cumprod", xs_vec_cumprod, __FILE__);
    newXS("Numeric::Vector::diff", xs_vec_diff, __FILE__);
    newXS("Numeric::Vector::sort", xs_vec_sort, __FILE__);
    newXS("Numeric::Vector::argsort", xs_vec_argsort, __FILE__);
    newXS("Numeric::Vector::isnan", xs_vec_isnan, __FILE__);
    newXS("Numeric::Vector::isinf", xs_vec_isinf, __FILE__);
    newXS("Numeric::Vector::isfinite", xs_vec_isfinite, __FILE__);
    
    /* In-place */
    newXS("Numeric::Vector::add_inplace", xs_vec_add_inplace, __FILE__);
    newXS("Numeric::Vector::sub_inplace", xs_vec_sub_inplace, __FILE__);
    newXS("Numeric::Vector::mul_inplace", xs_vec_mul_inplace, __FILE__);
    newXS("Numeric::Vector::div_inplace", xs_vec_div_inplace, __FILE__);
    newXS("Numeric::Vector::scale_inplace", xs_vec_scale_inplace, __FILE__);
    newXS("Numeric::Vector::add_scalar_inplace", xs_vec_add_scalar_inplace, __FILE__);
    newXS("Numeric::Vector::clamp_inplace", xs_vec_clamp_inplace, __FILE__);
    newXS("Numeric::Vector::fma_inplace", xs_vec_fma_inplace, __FILE__);
    newXS("Numeric::Vector::axpy", xs_vec_axpy, __FILE__);
    
    /* Slicing/Copy */
    newXS("Numeric::Vector::slice", xs_vec_slice, __FILE__);
    newXS("Numeric::Vector::copy", xs_vec_copy, __FILE__);
    newXS("Numeric::Vector::fill_range", xs_vec_fill_range, __FILE__);
    
    /* Reductions */
    newXS("Numeric::Vector::sum", xs_vec_sum, __FILE__);
    newXS("Numeric::Vector::product", xs_vec_product, __FILE__);
    newXS("Numeric::Vector::mean", xs_vec_mean, __FILE__);
    newXS("Numeric::Vector::variance", xs_vec_variance, __FILE__);
    newXS("Numeric::Vector::std", xs_vec_std, __FILE__);
    newXS("Numeric::Vector::median", xs_vec_median, __FILE__);
    newXS("Numeric::Vector::min", xs_vec_min, __FILE__);
    newXS("Numeric::Vector::max", xs_vec_max, __FILE__);
    newXS("Numeric::Vector::argmin", xs_vec_argmin, __FILE__);
    newXS("Numeric::Vector::argmax", xs_vec_argmax, __FILE__);
    newXS("Numeric::Vector::dot", xs_vec_dot, __FILE__);
    newXS("Numeric::Vector::norm", xs_vec_norm, __FILE__);
    
    /* Linear algebra */
    newXS("Numeric::Vector::normalize", xs_vec_normalize, __FILE__);
    newXS("Numeric::Vector::distance", xs_vec_distance, __FILE__);
    newXS("Numeric::Vector::cosine_similarity", xs_vec_cosine_similarity, __FILE__);
    
    /* Info */
    newXS("Numeric::Vector::simd_info", xs_vec_simd_info, __FILE__);
    
    /* ============================================
       Register Custom Ops
       ============================================ */
    
    XopENTRY_set(&vec_sum_xop, xop_name, "vec_sum");
    XopENTRY_set(&vec_sum_xop, xop_desc, "vec sum reduction");
    Perl_custom_op_register(aTHX_ pp_vec_sum, &vec_sum_xop);
    
    XopENTRY_set(&vec_mean_xop, xop_name, "vec_mean");
    XopENTRY_set(&vec_mean_xop, xop_desc, "vec mean reduction");
    Perl_custom_op_register(aTHX_ pp_vec_mean, &vec_mean_xop);
    
    XopENTRY_set(&vec_len_xop, xop_name, "vec_len");
    XopENTRY_set(&vec_len_xop, xop_desc, "vec length");
    Perl_custom_op_register(aTHX_ pp_vec_len, &vec_len_xop);
    
    XopENTRY_set(&vec_min_xop, xop_name, "vec_min");
    XopENTRY_set(&vec_min_xop, xop_desc, "vec min reduction");
    Perl_custom_op_register(aTHX_ pp_vec_min, &vec_min_xop);
    
    XopENTRY_set(&vec_max_xop, xop_name, "vec_max");
    XopENTRY_set(&vec_max_xop, xop_desc, "vec max reduction");
    Perl_custom_op_register(aTHX_ pp_vec_max, &vec_max_xop);
    
    XopENTRY_set(&vec_dot_xop, xop_name, "vec_dot");
    XopENTRY_set(&vec_dot_xop, xop_desc, "vec dot product");
    Perl_custom_op_register(aTHX_ pp_vec_dot, &vec_dot_xop);
    
    XopENTRY_set(&vec_norm_xop, xop_name, "vec_norm");
    XopENTRY_set(&vec_norm_xop, xop_desc, "vec L2 norm");
    Perl_custom_op_register(aTHX_ pp_vec_norm, &vec_norm_xop);
    
    XopENTRY_set(&vec_add_xop, xop_name, "vec_add");
    XopENTRY_set(&vec_add_xop, xop_desc, "vec addition");
    Perl_custom_op_register(aTHX_ pp_vec_add, &vec_add_xop);
    
    XopENTRY_set(&vec_sub_xop, xop_name, "vec_sub");
    XopENTRY_set(&vec_sub_xop, xop_desc, "vec subtraction");
    Perl_custom_op_register(aTHX_ pp_vec_sub, &vec_sub_xop);
    
    XopENTRY_set(&vec_mul_xop, xop_name, "vec_mul");
    XopENTRY_set(&vec_mul_xop, xop_desc, "vec multiplication");
    Perl_custom_op_register(aTHX_ pp_vec_mul, &vec_mul_xop);
    
    XopENTRY_set(&vec_div_xop, xop_name, "vec_div");
    XopENTRY_set(&vec_div_xop, xop_desc, "vec division");
    Perl_custom_op_register(aTHX_ pp_vec_div, &vec_div_xop);
    
    XopENTRY_set(&vec_scale_xop, xop_name, "vec_scale");
    XopENTRY_set(&vec_scale_xop, xop_desc, "vec scalar multiplication");
    Perl_custom_op_register(aTHX_ pp_vec_scale, &vec_scale_xop);
    
    XopENTRY_set(&vec_neg_xop, xop_name, "vec_neg");
    XopENTRY_set(&vec_neg_xop, xop_desc, "vec negation");
    Perl_custom_op_register(aTHX_ pp_vec_neg, &vec_neg_xop);
    
    XopENTRY_set(&vec_abs_xop, xop_name, "vec_abs");
    XopENTRY_set(&vec_abs_xop, xop_desc, "vec absolute value");
    Perl_custom_op_register(aTHX_ pp_vec_abs, &vec_abs_xop);
    
    XopENTRY_set(&vec_sqrt_xop, xop_name, "vec_sqrt");
    XopENTRY_set(&vec_sqrt_xop, xop_desc, "vec square root");
    Perl_custom_op_register(aTHX_ pp_vec_sqrt, &vec_sqrt_xop);
    
    XopENTRY_set(&vec_copy_xop, xop_name, "vec_copy");
    XopENTRY_set(&vec_copy_xop, xop_desc, "vec copy");
    Perl_custom_op_register(aTHX_ pp_vec_copy, &vec_copy_xop);
    
    XopENTRY_set(&vec_variance_xop, xop_name, "vec_variance");
    XopENTRY_set(&vec_variance_xop, xop_desc, "vec variance");
    Perl_custom_op_register(aTHX_ pp_vec_variance, &vec_variance_xop);
    
    XopENTRY_set(&vec_std_xop, xop_name, "vec_std");
    XopENTRY_set(&vec_std_xop, xop_desc, "vec standard deviation");
    Perl_custom_op_register(aTHX_ pp_vec_std, &vec_std_xop);
    
    XopENTRY_set(&vec_normalize_xop, xop_name, "vec_normalize");
    XopENTRY_set(&vec_normalize_xop, xop_desc, "vec normalize");
    Perl_custom_op_register(aTHX_ pp_vec_normalize, &vec_normalize_xop);
    
    /* More math ops */
    XopENTRY_set(&vec_exp_xop, xop_name, "vec_exp");
    XopENTRY_set(&vec_exp_xop, xop_desc, "vec exp");
    Perl_custom_op_register(aTHX_ pp_vec_exp, &vec_exp_xop);
    
    XopENTRY_set(&vec_log_xop, xop_name, "vec_log");
    XopENTRY_set(&vec_log_xop, xop_desc, "vec log");
    Perl_custom_op_register(aTHX_ pp_vec_log, &vec_log_xop);
    
    XopENTRY_set(&vec_sin_xop, xop_name, "vec_sin");
    XopENTRY_set(&vec_sin_xop, xop_desc, "vec sin");
    Perl_custom_op_register(aTHX_ pp_vec_sin, &vec_sin_xop);
    
    XopENTRY_set(&vec_cos_xop, xop_name, "vec_cos");
    XopENTRY_set(&vec_cos_xop, xop_desc, "vec cos");
    Perl_custom_op_register(aTHX_ pp_vec_cos, &vec_cos_xop);
    
    XopENTRY_set(&vec_tan_xop, xop_name, "vec_tan");
    XopENTRY_set(&vec_tan_xop, xop_desc, "vec tan");
    Perl_custom_op_register(aTHX_ pp_vec_tan, &vec_tan_xop);
    
    XopENTRY_set(&vec_floor_xop, xop_name, "vec_floor");
    XopENTRY_set(&vec_floor_xop, xop_desc, "vec floor");
    Perl_custom_op_register(aTHX_ pp_vec_floor, &vec_floor_xop);
    
    XopENTRY_set(&vec_ceil_xop, xop_name, "vec_ceil");
    XopENTRY_set(&vec_ceil_xop, xop_desc, "vec ceil");
    Perl_custom_op_register(aTHX_ pp_vec_ceil, &vec_ceil_xop);
    
    XopENTRY_set(&vec_round_xop, xop_name, "vec_round");
    XopENTRY_set(&vec_round_xop, xop_desc, "vec round");
    Perl_custom_op_register(aTHX_ pp_vec_round, &vec_round_xop);
    
    XopENTRY_set(&vec_asin_xop, xop_name, "vec_asin");
    XopENTRY_set(&vec_asin_xop, xop_desc, "vec asin");
    Perl_custom_op_register(aTHX_ pp_vec_asin, &vec_asin_xop);
    
    XopENTRY_set(&vec_acos_xop, xop_name, "vec_acos");
    XopENTRY_set(&vec_acos_xop, xop_desc, "vec acos");
    Perl_custom_op_register(aTHX_ pp_vec_acos, &vec_acos_xop);
    
    XopENTRY_set(&vec_atan_xop, xop_name, "vec_atan");
    XopENTRY_set(&vec_atan_xop, xop_desc, "vec atan");
    Perl_custom_op_register(aTHX_ pp_vec_atan, &vec_atan_xop);
    
    XopENTRY_set(&vec_sinh_xop, xop_name, "vec_sinh");
    XopENTRY_set(&vec_sinh_xop, xop_desc, "vec sinh");
    Perl_custom_op_register(aTHX_ pp_vec_sinh, &vec_sinh_xop);
    
    XopENTRY_set(&vec_cosh_xop, xop_name, "vec_cosh");
    XopENTRY_set(&vec_cosh_xop, xop_desc, "vec cosh");
    Perl_custom_op_register(aTHX_ pp_vec_cosh, &vec_cosh_xop);
    
    XopENTRY_set(&vec_tanh_xop, xop_name, "vec_tanh");
    XopENTRY_set(&vec_tanh_xop, xop_desc, "vec tanh");
    Perl_custom_op_register(aTHX_ pp_vec_tanh, &vec_tanh_xop);
    
    XopENTRY_set(&vec_log10_xop, xop_name, "vec_log10");
    XopENTRY_set(&vec_log10_xop, xop_desc, "vec log10");
    Perl_custom_op_register(aTHX_ pp_vec_log10, &vec_log10_xop);
    
    XopENTRY_set(&vec_log2_xop, xop_name, "vec_log2");
    XopENTRY_set(&vec_log2_xop, xop_desc, "vec log2");
    Perl_custom_op_register(aTHX_ pp_vec_log2, &vec_log2_xop);
    
    XopENTRY_set(&vec_sign_xop, xop_name, "vec_sign");
    XopENTRY_set(&vec_sign_xop, xop_desc, "vec sign");
    Perl_custom_op_register(aTHX_ pp_vec_sign, &vec_sign_xop);
    
    XopENTRY_set(&vec_cumsum_xop, xop_name, "vec_cumsum");
    XopENTRY_set(&vec_cumsum_xop, xop_desc, "vec cumsum");
    Perl_custom_op_register(aTHX_ pp_vec_cumsum, &vec_cumsum_xop);
    
    XopENTRY_set(&vec_cumprod_xop, xop_name, "vec_cumprod");
    XopENTRY_set(&vec_cumprod_xop, xop_desc, "vec cumprod");
    Perl_custom_op_register(aTHX_ pp_vec_cumprod, &vec_cumprod_xop);
    
    XopENTRY_set(&vec_diff_xop, xop_name, "vec_diff");
    XopENTRY_set(&vec_diff_xop, xop_desc, "vec diff");
    Perl_custom_op_register(aTHX_ pp_vec_diff, &vec_diff_xop);
    
    XopENTRY_set(&vec_reverse_xop, xop_name, "vec_reverse");
    XopENTRY_set(&vec_reverse_xop, xop_desc, "vec reverse");
    Perl_custom_op_register(aTHX_ pp_vec_reverse, &vec_reverse_xop);
    
    XopENTRY_set(&vec_isnan_xop, xop_name, "vec_isnan");
    XopENTRY_set(&vec_isnan_xop, xop_desc, "vec isnan");
    Perl_custom_op_register(aTHX_ pp_vec_isnan, &vec_isnan_xop);
    
    XopENTRY_set(&vec_isinf_xop, xop_name, "vec_isinf");
    XopENTRY_set(&vec_isinf_xop, xop_desc, "vec isinf");
    Perl_custom_op_register(aTHX_ pp_vec_isinf, &vec_isinf_xop);
    
    XopENTRY_set(&vec_isfinite_xop, xop_name, "vec_isfinite");
    XopENTRY_set(&vec_isfinite_xop, xop_desc, "vec isfinite");
    Perl_custom_op_register(aTHX_ pp_vec_isfinite, &vec_isfinite_xop);
    
    /* In-place ops */
    XopENTRY_set(&vec_add_inplace_xop, xop_name, "vec_add_inplace");
    XopENTRY_set(&vec_add_inplace_xop, xop_desc, "vec add inplace");
    Perl_custom_op_register(aTHX_ pp_vec_add_inplace, &vec_add_inplace_xop);
    
    XopENTRY_set(&vec_sub_inplace_xop, xop_name, "vec_sub_inplace");
    XopENTRY_set(&vec_sub_inplace_xop, xop_desc, "vec sub inplace");
    Perl_custom_op_register(aTHX_ pp_vec_sub_inplace, &vec_sub_inplace_xop);
    
    XopENTRY_set(&vec_mul_inplace_xop, xop_name, "vec_mul_inplace");
    XopENTRY_set(&vec_mul_inplace_xop, xop_desc, "vec mul inplace");
    Perl_custom_op_register(aTHX_ pp_vec_mul_inplace, &vec_mul_inplace_xop);
    
    XopENTRY_set(&vec_div_inplace_xop, xop_name, "vec_div_inplace");
    XopENTRY_set(&vec_div_inplace_xop, xop_desc, "vec div inplace");
    Perl_custom_op_register(aTHX_ pp_vec_div_inplace, &vec_div_inplace_xop);
    
    XopENTRY_set(&vec_scale_inplace_xop, xop_name, "vec_scale_inplace");
    XopENTRY_set(&vec_scale_inplace_xop, xop_desc, "vec scale inplace");
    Perl_custom_op_register(aTHX_ pp_vec_scale_inplace, &vec_scale_inplace_xop);
    
    /* Comparison ops */
    XopENTRY_set(&vec_eq_xop, xop_name, "vec_eq");
    XopENTRY_set(&vec_eq_xop, xop_desc, "vec eq");
    Perl_custom_op_register(aTHX_ pp_vec_eq, &vec_eq_xop);
    
    XopENTRY_set(&vec_ne_xop, xop_name, "vec_ne");
    XopENTRY_set(&vec_ne_xop, xop_desc, "vec ne");
    Perl_custom_op_register(aTHX_ pp_vec_ne, &vec_ne_xop);
    
    XopENTRY_set(&vec_lt_xop, xop_name, "vec_lt");
    XopENTRY_set(&vec_lt_xop, xop_desc, "vec lt");
    Perl_custom_op_register(aTHX_ pp_vec_lt, &vec_lt_xop);
    
    XopENTRY_set(&vec_le_xop, xop_name, "vec_le");
    XopENTRY_set(&vec_le_xop, xop_desc, "vec le");
    Perl_custom_op_register(aTHX_ pp_vec_le, &vec_le_xop);
    
    XopENTRY_set(&vec_gt_xop, xop_name, "vec_gt");
    XopENTRY_set(&vec_gt_xop, xop_desc, "vec gt");
    Perl_custom_op_register(aTHX_ pp_vec_gt, &vec_gt_xop);
    
    XopENTRY_set(&vec_ge_xop, xop_name, "vec_ge");
    XopENTRY_set(&vec_ge_xop, xop_desc, "vec ge");
    Perl_custom_op_register(aTHX_ pp_vec_ge, &vec_ge_xop);
    
    /* Boolean reductions */
    XopENTRY_set(&vec_all_xop, xop_name, "vec_all");
    XopENTRY_set(&vec_all_xop, xop_desc, "vec all");
    Perl_custom_op_register(aTHX_ pp_vec_all, &vec_all_xop);
    
    XopENTRY_set(&vec_any_xop, xop_name, "vec_any");
    XopENTRY_set(&vec_any_xop, xop_desc, "vec any");
    Perl_custom_op_register(aTHX_ pp_vec_any, &vec_any_xop);
    
    XopENTRY_set(&vec_count_xop, xop_name, "vec_count");
    XopENTRY_set(&vec_count_xop, xop_desc, "vec count");
    Perl_custom_op_register(aTHX_ pp_vec_count, &vec_count_xop);
    
    /* Arg ops */
    XopENTRY_set(&vec_argmax_xop, xop_name, "vec_argmax");
    XopENTRY_set(&vec_argmax_xop, xop_desc, "vec argmax");
    Perl_custom_op_register(aTHX_ pp_vec_argmax, &vec_argmax_xop);
    
    XopENTRY_set(&vec_argmin_xop, xop_name, "vec_argmin");
    XopENTRY_set(&vec_argmin_xop, xop_desc, "vec argmin");
    Perl_custom_op_register(aTHX_ pp_vec_argmin, &vec_argmin_xop);
    
    /* More math */
    XopENTRY_set(&vec_pow_xop, xop_name, "vec_pow");
    XopENTRY_set(&vec_pow_xop, xop_desc, "vec pow");
    Perl_custom_op_register(aTHX_ pp_vec_pow, &vec_pow_xop);
    
    XopENTRY_set(&vec_product_xop, xop_name, "vec_product");
    XopENTRY_set(&vec_product_xop, xop_desc, "vec product");
    Perl_custom_op_register(aTHX_ pp_vec_product, &vec_product_xop);
    
    /* Linear algebra */
    XopENTRY_set(&vec_distance_xop, xop_name, "vec_distance");
    XopENTRY_set(&vec_distance_xop, xop_desc, "vec distance");
    Perl_custom_op_register(aTHX_ pp_vec_distance, &vec_distance_xop);
    
    XopENTRY_set(&vec_cosine_similarity_xop, xop_name, "vec_cosine_similarity");
    XopENTRY_set(&vec_cosine_similarity_xop, xop_desc, "vec cosine similarity");
    Perl_custom_op_register(aTHX_ pp_vec_cosine_similarity, &vec_cosine_similarity_xop);
    
    /* Remaining ops - axpy, add_scalar, clip, etc. */
    XopENTRY_set(&vec_axpy_xop, xop_name, "vec_axpy");
    XopENTRY_set(&vec_axpy_xop, xop_desc, "vec axpy");
    Perl_custom_op_register(aTHX_ pp_vec_axpy, &vec_axpy_xop);
    
    XopENTRY_set(&vec_add_scalar_xop, xop_name, "vec_add_scalar");
    XopENTRY_set(&vec_add_scalar_xop, xop_desc, "vec add scalar");
    Perl_custom_op_register(aTHX_ pp_vec_add_scalar, &vec_add_scalar_xop);
    
    XopENTRY_set(&vec_add_scalar_inplace_xop, xop_name, "vec_add_scalar_inplace");
    XopENTRY_set(&vec_add_scalar_inplace_xop, xop_desc, "vec add scalar inplace");
    Perl_custom_op_register(aTHX_ pp_vec_add_scalar_inplace, &vec_add_scalar_inplace_xop);
    
    XopENTRY_set(&vec_clip_xop, xop_name, "vec_clip");
    XopENTRY_set(&vec_clip_xop, xop_desc, "vec clip");
    Perl_custom_op_register(aTHX_ pp_vec_clip, &vec_clip_xop);
    
    XopENTRY_set(&vec_clamp_inplace_xop, xop_name, "vec_clamp_inplace");
    XopENTRY_set(&vec_clamp_inplace_xop, xop_desc, "vec clamp inplace");
    Perl_custom_op_register(aTHX_ pp_vec_clamp_inplace, &vec_clamp_inplace_xop);
    
    XopENTRY_set(&vec_fma_inplace_xop, xop_name, "vec_fma_inplace");
    XopENTRY_set(&vec_fma_inplace_xop, xop_desc, "vec fma inplace");
    Perl_custom_op_register(aTHX_ pp_vec_fma_inplace, &vec_fma_inplace_xop);
    
    XopENTRY_set(&vec_concat_xop, xop_name, "vec_concat");
    XopENTRY_set(&vec_concat_xop, xop_desc, "vec concat");
    Perl_custom_op_register(aTHX_ pp_vec_concat, &vec_concat_xop);
    
    XopENTRY_set(&vec_sort_xop, xop_name, "vec_sort");
    XopENTRY_set(&vec_sort_xop, xop_desc, "vec sort");
    Perl_custom_op_register(aTHX_ pp_vec_sort, &vec_sort_xop);
    
    XopENTRY_set(&vec_argsort_xop, xop_name, "vec_argsort");
    XopENTRY_set(&vec_argsort_xop, xop_desc, "vec argsort");
    Perl_custom_op_register(aTHX_ pp_vec_argsort, &vec_argsort_xop);
    
    XopENTRY_set(&vec_median_xop, xop_name, "vec_median");
    XopENTRY_set(&vec_median_xop, xop_desc, "vec median");
    Perl_custom_op_register(aTHX_ pp_vec_median, &vec_median_xop);
    
    XopENTRY_set(&vec_slice_xop, xop_name, "vec_slice");
    XopENTRY_set(&vec_slice_xop, xop_desc, "vec slice");
    Perl_custom_op_register(aTHX_ pp_vec_slice, &vec_slice_xop);
    
    XopENTRY_set(&vec_where_xop, xop_name, "vec_where");
    XopENTRY_set(&vec_where_xop, xop_desc, "vec where");
    Perl_custom_op_register(aTHX_ pp_vec_where, &vec_where_xop);
    
    /* Constructor custom ops */
    XopENTRY_set(&vec_new_xop, xop_name, "vec_new");
    XopENTRY_set(&vec_new_xop, xop_desc, "vec new");
    Perl_custom_op_register(aTHX_ pp_vec_new, &vec_new_xop);
    
    XopENTRY_set(&vec_ones_xop, xop_name, "vec_ones");
    XopENTRY_set(&vec_ones_xop, xop_desc, "vec ones");
    Perl_custom_op_register(aTHX_ pp_vec_ones, &vec_ones_xop);
    
    XopENTRY_set(&vec_zeros_xop, xop_name, "vec_zeros");
    XopENTRY_set(&vec_zeros_xop, xop_desc, "vec zeros");
    Perl_custom_op_register(aTHX_ pp_vec_zeros, &vec_zeros_xop);
    
    XopENTRY_set(&vec_fill_xop, xop_name, "vec_fill");
    XopENTRY_set(&vec_fill_xop, xop_desc, "vec fill");
    Perl_custom_op_register(aTHX_ pp_vec_fill, &vec_fill_xop);
    
    XopENTRY_set(&vec_fill_range_xop, xop_name, "vec_fill_range");
    XopENTRY_set(&vec_fill_range_xop, xop_desc, "vec fill range");
    Perl_custom_op_register(aTHX_ pp_vec_fill_range, &vec_fill_range_xop);
    
    XopENTRY_set(&vec_linspace_xop, xop_name, "vec_linspace");
    XopENTRY_set(&vec_linspace_xop, xop_desc, "vec linspace");
    Perl_custom_op_register(aTHX_ pp_vec_linspace, &vec_linspace_xop);
    
    XopENTRY_set(&vec_range_xop, xop_name, "vec_range");
    XopENTRY_set(&vec_range_xop, xop_desc, "vec range");
    Perl_custom_op_register(aTHX_ pp_vec_range, &vec_range_xop);
    
    XopENTRY_set(&vec_random_xop, xop_name, "vec_random");
    XopENTRY_set(&vec_random_xop, xop_desc, "vec random");
    Perl_custom_op_register(aTHX_ pp_vec_random, &vec_random_xop);
    
    /* Element access custom ops */
    XopENTRY_set(&vec_get_xop, xop_name, "vec_get");
    XopENTRY_set(&vec_get_xop, xop_desc, "vec get");
    Perl_custom_op_register(aTHX_ pp_vec_get, &vec_get_xop);
    
    XopENTRY_set(&vec_set_xop, xop_name, "vec_set");
    XopENTRY_set(&vec_set_xop, xop_desc, "vec set");
    Perl_custom_op_register(aTHX_ pp_vec_set, &vec_set_xop);
    
    /* Utility custom ops */
    XopENTRY_set(&vec_to_array_xop, xop_name, "vec_to_array");
    XopENTRY_set(&vec_to_array_xop, xop_desc, "vec to array");
    Perl_custom_op_register(aTHX_ pp_vec_to_array, &vec_to_array_xop);
    
    XopENTRY_set(&vec_simd_info_xop, xop_name, "vec_simd_info");
    XopENTRY_set(&vec_simd_info_xop, xop_desc, "vec simd info");
    Perl_custom_op_register(aTHX_ pp_vec_simd_info, &vec_simd_info_xop);
    
    /* ============================================
       Install Call Checkers for Optimization
       ============================================ */
    {
        CV *cv;
        
        /* Unary call checkers */
        cv = get_cv("Numeric::Vector::sum", 0);
        if (cv) cv_set_call_checker(cv, vec_sum_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::mean", 0);
        if (cv) cv_set_call_checker(cv, vec_mean_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::len", 0);
        if (cv) cv_set_call_checker(cv, vec_len_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::min", 0);
        if (cv) cv_set_call_checker(cv, vec_min_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::max", 0);
        if (cv) cv_set_call_checker(cv, vec_max_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::norm", 0);
        if (cv) cv_set_call_checker(cv, vec_norm_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::neg", 0);
        if (cv) cv_set_call_checker(cv, vec_neg_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::abs", 0);
        if (cv) cv_set_call_checker(cv, vec_abs_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::sqrt", 0);
        if (cv) cv_set_call_checker(cv, vec_sqrt_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::copy", 0);
        if (cv) cv_set_call_checker(cv, vec_copy_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::variance", 0);
        if (cv) cv_set_call_checker(cv, vec_variance_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::std", 0);
        if (cv) cv_set_call_checker(cv, vec_std_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::normalize", 0);
        if (cv) cv_set_call_checker(cv, vec_normalize_call_checker, (SV*)cv);
        
        /* Binary call checkers */
        cv = get_cv("Numeric::Vector::add", 0);
        if (cv) cv_set_call_checker(cv, vec_add_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::sub", 0);
        if (cv) cv_set_call_checker(cv, vec_sub_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::mul", 0);
        if (cv) cv_set_call_checker(cv, vec_mul_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::div", 0);
        if (cv) cv_set_call_checker(cv, vec_div_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::scale", 0);
        if (cv) cv_set_call_checker(cv, vec_scale_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::dot", 0);
        if (cv) cv_set_call_checker(cv, vec_dot_call_checker, (SV*)cv);
        
        /* More math call checkers */
        cv = get_cv("Numeric::Vector::exp", 0);
        if (cv) cv_set_call_checker(cv, vec_exp_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::log", 0);
        if (cv) cv_set_call_checker(cv, vec_log_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::sin", 0);
        if (cv) cv_set_call_checker(cv, vec_sin_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::cos", 0);
        if (cv) cv_set_call_checker(cv, vec_cos_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::tan", 0);
        if (cv) cv_set_call_checker(cv, vec_tan_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::floor", 0);
        if (cv) cv_set_call_checker(cv, vec_floor_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::ceil", 0);
        if (cv) cv_set_call_checker(cv, vec_ceil_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::round", 0);
        if (cv) cv_set_call_checker(cv, vec_round_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::asin", 0);
        if (cv) cv_set_call_checker(cv, vec_asin_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::acos", 0);
        if (cv) cv_set_call_checker(cv, vec_acos_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::atan", 0);
        if (cv) cv_set_call_checker(cv, vec_atan_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::sinh", 0);
        if (cv) cv_set_call_checker(cv, vec_sinh_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::cosh", 0);
        if (cv) cv_set_call_checker(cv, vec_cosh_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::tanh", 0);
        if (cv) cv_set_call_checker(cv, vec_tanh_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::log10", 0);
        if (cv) cv_set_call_checker(cv, vec_log10_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::log2", 0);
        if (cv) cv_set_call_checker(cv, vec_log2_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::sign", 0);
        if (cv) cv_set_call_checker(cv, vec_sign_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::cumsum", 0);
        if (cv) cv_set_call_checker(cv, vec_cumsum_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::cumprod", 0);
        if (cv) cv_set_call_checker(cv, vec_cumprod_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::diff", 0);
        if (cv) cv_set_call_checker(cv, vec_diff_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::reverse", 0);
        if (cv) cv_set_call_checker(cv, vec_reverse_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::isnan", 0);
        if (cv) cv_set_call_checker(cv, vec_isnan_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::isinf", 0);
        if (cv) cv_set_call_checker(cv, vec_isinf_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::isfinite", 0);
        if (cv) cv_set_call_checker(cv, vec_isfinite_call_checker, (SV*)cv);
        
        /* In-place call checkers */
        cv = get_cv("Numeric::Vector::add_inplace", 0);
        if (cv) cv_set_call_checker(cv, vec_add_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::sub_inplace", 0);
        if (cv) cv_set_call_checker(cv, vec_sub_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::mul_inplace", 0);
        if (cv) cv_set_call_checker(cv, vec_mul_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::div_inplace", 0);
        if (cv) cv_set_call_checker(cv, vec_div_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::scale_inplace", 0);
        if (cv) cv_set_call_checker(cv, vec_scale_inplace_call_checker, (SV*)cv);
        
        /* Comparison call checkers */
        cv = get_cv("Numeric::Vector::eq", 0);
        if (cv) cv_set_call_checker(cv, vec_eq_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::ne", 0);
        if (cv) cv_set_call_checker(cv, vec_ne_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::lt", 0);
        if (cv) cv_set_call_checker(cv, vec_lt_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::le", 0);
        if (cv) cv_set_call_checker(cv, vec_le_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::gt", 0);
        if (cv) cv_set_call_checker(cv, vec_gt_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::ge", 0);
        if (cv) cv_set_call_checker(cv, vec_ge_call_checker, (SV*)cv);
        
        /* Boolean reduction call checkers */
        cv = get_cv("Numeric::Vector::all", 0);
        if (cv) cv_set_call_checker(cv, vec_all_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::any", 0);
        if (cv) cv_set_call_checker(cv, vec_any_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::count", 0);
        if (cv) cv_set_call_checker(cv, vec_count_call_checker, (SV*)cv);
        
        /* Arg ops call checkers */
        cv = get_cv("Numeric::Vector::argmax", 0);
        if (cv) cv_set_call_checker(cv, vec_argmax_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::argmin", 0);
        if (cv) cv_set_call_checker(cv, vec_argmin_call_checker, (SV*)cv);
        
        /* Math call checkers */
        cv = get_cv("Numeric::Vector::pow", 0);
        if (cv) cv_set_call_checker(cv, vec_pow_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::product", 0);
        if (cv) cv_set_call_checker(cv, vec_product_call_checker, (SV*)cv);
        
        /* Linear algebra call checkers */
        cv = get_cv("Numeric::Vector::distance", 0);
        if (cv) cv_set_call_checker(cv, vec_distance_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::cosine_similarity", 0);
        if (cv) cv_set_call_checker(cv, vec_cosine_similarity_call_checker, (SV*)cv);
        
        /* Remaining call checkers */
        cv = get_cv("Numeric::Vector::axpy", 0);
        if (cv) cv_set_call_checker(cv, vec_axpy_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::add_scalar", 0);
        if (cv) cv_set_call_checker(cv, vec_add_scalar_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::add_scalar_inplace", 0);
        if (cv) cv_set_call_checker(cv, vec_add_scalar_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::clip", 0);
        if (cv) cv_set_call_checker(cv, vec_clip_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::clamp_inplace", 0);
        if (cv) cv_set_call_checker(cv, vec_clamp_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::fma_inplace", 0);
        if (cv) cv_set_call_checker(cv, vec_fma_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::concat", 0);
        if (cv) cv_set_call_checker(cv, vec_concat_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::sort", 0);
        if (cv) cv_set_call_checker(cv, vec_sort_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::argsort", 0);
        if (cv) cv_set_call_checker(cv, vec_argsort_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::median", 0);
        if (cv) cv_set_call_checker(cv, vec_median_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::slice", 0);
        if (cv) cv_set_call_checker(cv, vec_slice_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::where", 0);
        if (cv) cv_set_call_checker(cv, vec_where_call_checker, (SV*)cv);
        
        /* Constructor call checkers */
        cv = get_cv("Numeric::Vector::new", 0);
        if (cv) cv_set_call_checker(cv, vec_new_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::ones", 0);
        if (cv) cv_set_call_checker(cv, vec_ones_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::zeros", 0);
        if (cv) cv_set_call_checker(cv, vec_zeros_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::fill", 0);
        if (cv) cv_set_call_checker(cv, vec_fill_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::fill_range", 0);
        if (cv) cv_set_call_checker(cv, vec_fill_range_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::linspace", 0);
        if (cv) cv_set_call_checker(cv, vec_linspace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::range", 0);
        if (cv) cv_set_call_checker(cv, vec_range_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::random", 0);
        if (cv) cv_set_call_checker(cv, vec_random_call_checker, (SV*)cv);
        
        /* Element access call checkers */
        cv = get_cv("Numeric::Vector::get", 0);
        if (cv) cv_set_call_checker(cv, vec_get_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Vector::set", 0);
        if (cv) cv_set_call_checker(cv, vec_set_call_checker, (SV*)cv);
        
        /* Utility call checkers */
        cv = get_cv("Numeric::Vector::to_array", 0);
        if (cv) cv_set_call_checker(cv, vec_to_array_call_checker, (SV*)cv);

        cv = get_cv("Numeric::Vector::simd_info", 0);
        if (cv) cv_set_call_checker(cv, vec_simd_info_call_checker, (SV*)cv);
    }

    /* ============================================
       Register Overloaded Operators
       ============================================ */
    {
        HV *stash = gv_stashpv("Numeric::Vector", GV_ADD);
        SV *fallback = newSViv(1);

        /* Set fallback to 1 (autogenerate) */
        (void)hv_store(stash, "()", 2, fallback, 0);

        /* Binary operators */
        newXS("Numeric::Vector::(+", xs_overload_add, __FILE__);
        newXS("Numeric::Vector::(-", xs_overload_sub, __FILE__);
        newXS("Numeric::Vector::(*", xs_overload_mul, __FILE__);
        newXS("Numeric::Vector::(/", xs_overload_div, __FILE__);

        /* Assignment operators */
        newXS("Numeric::Vector::(+=", xs_overload_add_assign, __FILE__);
        newXS("Numeric::Vector::(-=", xs_overload_sub_assign, __FILE__);
        newXS("Numeric::Vector::(*=", xs_overload_mul_assign, __FILE__);
        newXS("Numeric::Vector::(/=", xs_overload_div_assign, __FILE__);

        /* Unary operators */
        newXS("Numeric::Vector::(neg", xs_overload_neg, __FILE__);
        newXS("Numeric::Vector::(abs", xs_overload_abs, __FILE__);

        /* Stringify and comparison */
        newXS("Numeric::Vector::(\"\"", xs_overload_stringify, __FILE__);
        newXS("Numeric::Vector::(==", xs_overload_eq, __FILE__);
        newXS("Numeric::Vector::(!=", xs_overload_ne, __FILE__);
        newXS("Numeric::Vector::(eq", xs_overload_streq, __FILE__);
        newXS("Numeric::Vector::(ne", xs_overload_strne, __FILE__);
        newXS("Numeric::Vector::(bool", xs_overload_bool, __FILE__);

        /* Mark the stash as overloaded */
        Gv_AMupdate_compat(stash, FALSE);
    }
}
