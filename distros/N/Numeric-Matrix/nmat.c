/*
 * nmat.c - 2D Matrix operations for Perl
 *
 * Features:
 * - Row-major double-precision matrices
 * - SIMD-accelerated element-wise operations (NEON, AVX2, SSE2)
 * - BLAS integration for GEMM (macOS Accelerate, OpenBLAS)
 * - Fused ops for ML (softmax, layer_norm, GELU, SiLU)
 * - Custom ops with call checkers for method dispatch optimization
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "include/nmat_compat.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>

/* ============================================
   Custom Op Declarations
   ============================================ */

static XOP mat_rows_xop;
static XOP mat_cols_xop;
static XOP mat_shape_xop;
static XOP mat_get_xop;
static XOP mat_set_xop;
static XOP mat_add_xop;
static XOP mat_sub_xop;
static XOP mat_mul_xop;
static XOP mat_div_xop;
static XOP mat_scale_xop;
static XOP mat_sum_xop;
static XOP mat_norm_xop;
static XOP mat_max_xop;
static XOP mat_min_xop;
static XOP mat_transpose_xop;
static XOP mat_matmul_xop;
static XOP mat_clone_xop;
static XOP mat_zeros_like_xop;
static XOP mat_neg_xop;
static XOP mat_abs_xop;
static XOP mat_sqrt_xop;
static XOP mat_exp_xop;
static XOP mat_log_xop;
static XOP mat_softmax_rows_inplace_xop;
static XOP mat_silu_inplace_xop;
static XOP mat_gelu_inplace_xop;
/* Inplace ops */
static XOP mat_add_inplace_xop;
static XOP mat_sub_inplace_xop;
static XOP mat_mul_inplace_xop;
static XOP mat_div_inplace_xop;
static XOP mat_scale_inplace_xop;
static XOP mat_add_scalar_xop;
static XOP mat_add_scalar_inplace_xop;
static XOP mat_add_scaled_inplace_xop;
/* Row/col ops */
static XOP mat_row_xop;
static XOP mat_set_row_xop;
static XOP mat_slice_rows_xop;
static XOP mat_row_sum_xop;
static XOP mat_col_sum_xop;
static XOP mat_add_vec_rows_xop;
static XOP mat_mul_vec_rows_xop;
/* Norm ops */
static XOP mat_rms_norm_xop;
static XOP mat_layer_norm_xop;
static XOP mat_layer_norm_bwd_xop;
/* Serialization */
static XOP mat_to_array_xop;
static XOP mat_to_vector_xop;

/* ============================================
   Matrix Structure
   ============================================ */

typedef struct {
    double *data;   /* Row-major: data[r * cols + c] */
    IV      rows;
    IV      cols;
} Mat;

/* ============================================
   Magic vtable for Perl GC
   ============================================ */

static int mat_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    Mat *mat = (Mat *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (mat) {
        if (mat->data) {
            nmat_aligned_free(mat->data);
        }
        Safefree(mat);
    }
    return 0;
}

static MGVTBL mat_magic_vtbl = {
    NULL,           /* get */
    NULL,           /* set */
    NULL,           /* len */
    NULL,           /* clear */
    mat_magic_free, /* free */
    NULL,           /* copy */
    NULL,           /* dup */
    NULL            /* local */
};

#define MAT_MAGIC_TYPE PERL_MAGIC_ext

/* ============================================
   Mat allocation / destruction
   ============================================ */

static Mat* mat_create(pTHX_ IV rows, IV cols) {
    Mat *mat;
    size_t size;
    
    if (rows <= 0 || cols <= 0) {
        croak("Numeric::Matrix: rows and cols must be positive");
    }
    
    Newx(mat, 1, Mat);
    mat->rows = rows;
    mat->cols = cols;
    
    size = (size_t)rows * (size_t)cols * sizeof(double);
    mat->data = (double *)nmat_aligned_alloc(NMAT_ALIGNMENT, size);
    if (!mat->data) {
        Safefree(mat);
        croak("Numeric::Matrix: failed to allocate %zu bytes", size);
    }
    
    /* Zero-initialize */
    memset(mat->data, 0, size);
    
    return mat;
}

static SV* mat_wrap(pTHX_ Mat *mat) {
    SV *rv;
    SV *sv = newSV(0);
    
    sv_magicext(sv, NULL, MAT_MAGIC_TYPE, &mat_magic_vtbl, (char*)mat, 0);
    rv = newRV_noinc(sv);
    sv_bless(rv, gv_stashpv("Numeric::Matrix", GV_ADD));
    
    return rv;
}

static Mat* mat_from_sv(pTHX_ SV *sv) {
    MAGIC *mg;
    SV *inner;
    
    if (!sv || !SvROK(sv)) {
        croak("Numeric::Matrix: not a reference");
    }
    
    inner = SvRV(sv);
    mg = mg_findext(inner, MAT_MAGIC_TYPE, &mat_magic_vtbl);
    if (!mg) {
        croak("Numeric::Matrix: invalid matrix object");
    }
    
    return (Mat *)mg->mg_ptr;
}

/* ============================================
   Random number generation (Box-Muller)
   ============================================ */

static double mat_randn(void) {
    static int have_spare = 0;
    static double spare;
    double u, v, s;
    
    if (have_spare) {
        have_spare = 0;
        return spare;
    }
    
    do {
        u = (double)rand() / RAND_MAX * 2.0 - 1.0;
        v = (double)rand() / RAND_MAX * 2.0 - 1.0;
        s = u * u + v * v;
    } while (s >= 1.0 || s == 0.0);
    
    s = sqrt(-2.0 * log(s) / s);
    spare = v * s;
    have_spare = 1;
    return u * s;
}

/* ============================================
   SIMD helpers - Element-wise binary ops
   ============================================ */

/* Add */
static void mat_add_data(double *out, const double *a, const double *b, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vst1q_f64(out + i, vaddq_f64(va, vb));
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        __m256d vb = _mm256_loadu_pd(b + i);
        _mm256_storeu_pd(out + i, _mm256_add_pd(va, vb));
    }
#elif NMAT_HAVE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        __m128d vb = _mm_loadu_pd(b + i);
        _mm_storeu_pd(out + i, _mm_add_pd(va, vb));
    }
#endif
    
    for (; i < n; i++) {
        out[i] = a[i] + b[i];
    }
}

/* Sub */
static void mat_sub_data(double *out, const double *a, const double *b, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vst1q_f64(out + i, vsubq_f64(va, vb));
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        __m256d vb = _mm256_loadu_pd(b + i);
        _mm256_storeu_pd(out + i, _mm256_sub_pd(va, vb));
    }
#elif NMAT_HAVE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        __m128d vb = _mm_loadu_pd(b + i);
        _mm_storeu_pd(out + i, _mm_sub_pd(va, vb));
    }
#endif
    
    for (; i < n; i++) {
        out[i] = a[i] - b[i];
    }
}

/* Mul (element-wise) */
static void mat_mul_data(double *out, const double *a, const double *b, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vst1q_f64(out + i, vmulq_f64(va, vb));
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        __m256d vb = _mm256_loadu_pd(b + i);
        _mm256_storeu_pd(out + i, _mm256_mul_pd(va, vb));
    }
#elif NMAT_HAVE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        __m128d vb = _mm_loadu_pd(b + i);
        _mm_storeu_pd(out + i, _mm_mul_pd(va, vb));
    }
#endif
    
    for (; i < n; i++) {
        out[i] = a[i] * b[i];
    }
}

/* Div (element-wise) */
static void mat_div_data(double *out, const double *a, const double *b, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vst1q_f64(out + i, vdivq_f64(va, vb));
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        __m256d vb = _mm256_loadu_pd(b + i);
        _mm256_storeu_pd(out + i, _mm256_div_pd(va, vb));
    }
#elif NMAT_HAVE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        __m128d vb = _mm_loadu_pd(b + i);
        _mm_storeu_pd(out + i, _mm_div_pd(va, vb));
    }
#endif
    
    for (; i < n; i++) {
        out[i] = a[i] / b[i];
    }
}

/* Scale */
static void mat_scale_data(double *out, const double *a, double s, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    float64x2_t vs = vdupq_n_f64(s);
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        vst1q_f64(out + i, vmulq_f64(va, vs));
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    __m256d vs = _mm256_set1_pd(s);
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        _mm256_storeu_pd(out + i, _mm256_mul_pd(va, vs));
    }
#elif NMAT_HAVE_SSE2
    __m128d vs = _mm_set1_pd(s);
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        _mm_storeu_pd(out + i, _mm_mul_pd(va, vs));
    }
#endif
    
    for (; i < n; i++) {
        out[i] = a[i] * s;
    }
}

/* Add scalar */
static void mat_add_scalar_data(double *out, const double *a, double s, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    float64x2_t vs = vdupq_n_f64(s);
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        vst1q_f64(out + i, vaddq_f64(va, vs));
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    __m256d vs = _mm256_set1_pd(s);
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        _mm256_storeu_pd(out + i, _mm256_add_pd(va, vs));
    }
#elif NMAT_HAVE_SSE2
    __m128d vs = _mm_set1_pd(s);
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        _mm_storeu_pd(out + i, _mm_add_pd(va, vs));
    }
#endif
    
    for (; i < n; i++) {
        out[i] = a[i] + s;
    }
}

/* Add scaled: out += s * b */
static void mat_add_scaled_data(double *out, const double *b, double s, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    float64x2_t vs = vdupq_n_f64(s);
    for (; i + 2 <= n; i += 2) {
        float64x2_t vo = vld1q_f64(out + i);
        float64x2_t vb = vld1q_f64(b + i);
        vst1q_f64(out + i, vfmaq_f64(vo, vb, vs));
    }
#elif NMAT_HAVE_AVX2
    __m256d vs = _mm256_set1_pd(s);
    for (; i + 4 <= n; i += 4) {
        __m256d vo = _mm256_loadu_pd(out + i);
        __m256d vb = _mm256_loadu_pd(b + i);
        _mm256_storeu_pd(out + i, _mm256_fmadd_pd(vb, vs, vo));
    }
#elif NMAT_HAVE_AVX
    __m256d vs = _mm256_set1_pd(s);
    for (; i + 4 <= n; i += 4) {
        __m256d vo = _mm256_loadu_pd(out + i);
        __m256d vb = _mm256_loadu_pd(b + i);
        _mm256_storeu_pd(out + i, _mm256_add_pd(vo, _mm256_mul_pd(vb, vs)));
    }
#elif NMAT_HAVE_SSE2
    __m128d vs = _mm_set1_pd(s);
    for (; i + 2 <= n; i += 2) {
        __m128d vo = _mm_loadu_pd(out + i);
        __m128d vb = _mm_loadu_pd(b + i);
        _mm_storeu_pd(out + i, _mm_add_pd(vo, _mm_mul_pd(vb, vs)));
    }
#endif
    
    for (; i < n; i++) {
        out[i] += s * b[i];
    }
}

/* ============================================
   Unary ops
   ============================================ */

static void mat_sqrt_data(double *out, const double *a, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        vst1q_f64(out + i, vsqrtq_f64(va));
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        _mm256_storeu_pd(out + i, _mm256_sqrt_pd(va));
    }
#elif NMAT_HAVE_SSE2
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        _mm_storeu_pd(out + i, _mm_sqrt_pd(va));
    }
#endif
    
    for (; i < n; i++) {
        out[i] = sqrt(a[i]);
    }
}

static void mat_neg_data(double *out, const double *a, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        vst1q_f64(out + i, vnegq_f64(va));
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    __m256d vzero = _mm256_setzero_pd();
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        _mm256_storeu_pd(out + i, _mm256_sub_pd(vzero, va));
    }
#elif NMAT_HAVE_SSE2
    __m128d vzero = _mm_setzero_pd();
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        _mm_storeu_pd(out + i, _mm_sub_pd(vzero, va));
    }
#endif
    
    for (; i < n; i++) {
        out[i] = -a[i];
    }
}

static void mat_abs_data(double *out, const double *a, size_t n) {
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        vst1q_f64(out + i, vabsq_f64(va));
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    /* Clear sign bit: AND with 0x7FFFFFFFFFFFFFFF */
    __m256d mask = _mm256_castsi256_pd(_mm256_set1_epi64x(0x7FFFFFFFFFFFFFFFLL));
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        _mm256_storeu_pd(out + i, _mm256_and_pd(va, mask));
    }
#elif NMAT_HAVE_SSE2
    __m128d mask = _mm_castsi128_pd(_mm_set1_epi64x(0x7FFFFFFFFFFFFFFFLL));
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        _mm_storeu_pd(out + i, _mm_and_pd(va, mask));
    }
#endif
    
    for (; i < n; i++) {
        out[i] = fabs(a[i]);
    }
}

static void mat_exp_data(double *out, const double *a, size_t n) {
    /* No SIMD exp - use scalar */
    { size_t i;
    for (i = 0; i < n; i++) {
        out[i] = exp(a[i]);
    }
    }
}

static void mat_log_data(double *out, const double *a, size_t n) {
    /* No SIMD log - use scalar */
    { size_t i;
    for (i = 0; i < n; i++) {
        out[i] = log(a[i]);
    }
    }
}

/* ============================================
   Reductions
   ============================================ */

static double mat_sum_data(const double *a, size_t n) {
    double sum = 0.0;
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    float64x2_t vsum = vdupq_n_f64(0.0);
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        vsum = vaddq_f64(vsum, va);
    }
    sum = vgetq_lane_f64(vsum, 0) + vgetq_lane_f64(vsum, 1);
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    __m256d vsum = _mm256_setzero_pd();
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        vsum = _mm256_add_pd(vsum, va);
    }
    __m128d lo = _mm256_castpd256_pd128(vsum);
    __m128d hi = _mm256_extractf128_pd(vsum, 1);
    __m128d sum128 = _mm_add_pd(lo, hi);
    sum = _mm_cvtsd_f64(sum128) + _mm_cvtsd_f64(_mm_unpackhi_pd(sum128, sum128));
#elif NMAT_HAVE_SSE2
    __m128d vsum = _mm_setzero_pd();
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        vsum = _mm_add_pd(vsum, va);
    }
    sum = _mm_cvtsd_f64(vsum) + _mm_cvtsd_f64(_mm_unpackhi_pd(vsum, vsum));
#endif
    
    for (; i < n; i++) {
        sum += a[i];
    }
    
    return sum;
}

/* Dot product of two vectors */
static double mat_dot_data(const double *a, const double *b, size_t n) {
    double sum = 0.0;
    size_t i = 0;
    
#if NMAT_HAVE_NEON
    float64x2_t vsum = vdupq_n_f64(0.0);
    for (; i + 2 <= n; i += 2) {
        float64x2_t va = vld1q_f64(a + i);
        float64x2_t vb = vld1q_f64(b + i);
        vsum = vfmaq_f64(vsum, va, vb);
    }
    sum = vgetq_lane_f64(vsum, 0) + vgetq_lane_f64(vsum, 1);
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    __m256d vsum = _mm256_setzero_pd();
    for (; i + 4 <= n; i += 4) {
        __m256d va = _mm256_loadu_pd(a + i);
        __m256d vb = _mm256_loadu_pd(b + i);
        vsum = _mm256_fmadd_pd(va, vb, vsum);
    }
    __m128d lo = _mm256_castpd256_pd128(vsum);
    __m128d hi = _mm256_extractf128_pd(vsum, 1);
    __m128d sum128 = _mm_add_pd(lo, hi);
    sum = _mm_cvtsd_f64(sum128) + _mm_cvtsd_f64(_mm_unpackhi_pd(sum128, sum128));
#elif NMAT_HAVE_SSE2
    __m128d vsum = _mm_setzero_pd();
    for (; i + 2 <= n; i += 2) {
        __m128d va = _mm_loadu_pd(a + i);
        __m128d vb = _mm_loadu_pd(b + i);
        vsum = _mm_add_pd(vsum, _mm_mul_pd(va, vb));
    }
    sum = _mm_cvtsd_f64(vsum) + _mm_cvtsd_f64(_mm_unpackhi_pd(vsum, vsum));
#endif
    
    for (; i < n; i++) {
        sum += a[i] * b[i];
    }
    
    return sum;
}

static double mat_max_data(const double *a, size_t n) {
    if (n == 0) return -DBL_MAX;
    
    double maxv = a[0];
    { size_t i;
    for (i = 1; i < n; i++) {
        if (a[i] > maxv) maxv = a[i];
    }
    }
    return maxv;
}

static double mat_min_data(const double *a, size_t n) {
    if (n == 0) return DBL_MAX;
    
    double minv = a[0];
    { size_t i;
    for (i = 1; i < n; i++) {
        if (a[i] < minv) minv = a[i];
    }
    }
    return minv;
}

/* ============================================
   GEMM - Matrix Multiply
   ============================================ */

#if NMAT_HAVE_BLAS

/* Use BLAS dgemm */
static void mat_matmul_blas(const Mat *A, const Mat *B, Mat *C) {
    /* C = 1.0 * A * B + 0.0 * C */
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                (int)A->rows, (int)B->cols, (int)A->cols,
                1.0, A->data, (int)A->cols,
                B->data, (int)B->cols,
                0.0, C->data, (int)C->cols);
}

#else

/* Tiled scalar fallback */
#define TILE_SIZE 32

static void mat_matmul_tiled(const Mat *A, const Mat *B, Mat *C) {
    IV M = A->rows;
    IV K = A->cols;
    IV N = B->cols;
    IV i, j, k, ii, jj, kk;
    
    /* Zero C */
    memset(C->data, 0, (size_t)M * (size_t)N * sizeof(double));
    
    for (ii = 0; ii < M; ii += TILE_SIZE) {
        IV i_end = (ii + TILE_SIZE < M) ? ii + TILE_SIZE : M;
        for (kk = 0; kk < K; kk += TILE_SIZE) {
            IV k_end = (kk + TILE_SIZE < K) ? kk + TILE_SIZE : K;
            for (jj = 0; jj < N; jj += TILE_SIZE) {
                IV j_end = (jj + TILE_SIZE < N) ? jj + TILE_SIZE : N;
                
                for (i = ii; i < i_end; i++) {
                    for (k = kk; k < k_end; k++) {
                        double a_ik = A->data[i * K + k];
                        for (j = jj; j < j_end; j++) {
                            C->data[i * N + j] += a_ik * B->data[k * N + j];
                        }
                    }
                }
            }
        }
    }
}

#endif /* NMAT_HAVE_BLAS */

/* ============================================
   Fused Ops
   ============================================ */

/* Softmax per row (numerically stable) */
#if NMAT_HAVE_BLAS && defined(__APPLE__)
/* Optimized using vDSP and vMath from Accelerate */
static void mat_softmax_rows_inplace(Mat *mat) {
    IV rows = mat->rows;
    IV cols = mat->cols;
    vDSP_Length vcols = (vDSP_Length)cols;
    
    { IV r;
    for (r = 0; r < rows; r++) {
        double *row = mat->data + r * cols;
        double maxv, sum, neg_max;
        int n = (int)cols;
        
        /* Find max for numerical stability */
        vDSP_maxvD(row, 1, &maxv, vcols);
        
        /* Subtract max: row[i] -= maxv */
        neg_max = -maxv;
        vDSP_vsaddD(row, 1, &neg_max, row, 1, vcols);
        
        /* Vectorized exp */
        vvexp(row, row, &n);
        
        /* Sum */
        vDSP_sveD(row, 1, &sum, vcols);
        
        /* Normalize: row[i] /= sum */
        vDSP_vsdivD(row, 1, &sum, row, 1, vcols);
    }
    }
}
#else
/* Scalar fallback */
static void mat_softmax_rows_inplace(Mat *mat) {
    IV rows = mat->rows;
    IV cols = mat->cols;
    
    { IV r;
    for (r = 0; r < rows; r++) {
        double *row = mat->data + r * cols;
        
        /* Find max for numerical stability */
        double maxv = row[0];
        { IV c;
        for (c = 1; c < cols; c++) {
            if (row[c] > maxv) maxv = row[c];
        }
        }
        
        /* exp(x - max) and sum */
        double sum = 0.0;
        { IV c;
        for (c = 0; c < cols; c++) {
            row[c] = exp(row[c] - maxv);
            sum += row[c];
        }
        }
        
        /* Normalize */
        double inv_sum = 1.0 / sum;
        { IV c;
        for (c = 0; c < cols; c++) {
            row[c] *= inv_sum;
        }
        }
    }
    }
}
#endif

/* SiLU: x * sigmoid(x) */
/* SiLU: x * sigmoid(x) = x / (1 + exp(-x)) */
static void mat_silu_inplace(Mat *mat) {
    size_t n = (size_t)mat->rows * (size_t)mat->cols;
    double *data = mat->data;
    
#if NMAT_HAVE_BLAS && defined(__APPLE__)
    /* SiLU = x * sigmoid(x) = x / (1 + exp(-x))
     * Compute: neg_x = -x, exp_neg_x = exp(-x), 
     *          denom = 1 + exp(-x), result = x / denom */
    double *temp;
    Newx(temp, n, double);
    int len = (int)n;
    
    /* temp = -x */
    double neg_one = -1.0;
    vDSP_vsmulD(data, 1, &neg_one, temp, 1, (vDSP_Length)n);
    
    /* temp = exp(-x) */
    vvexp(temp, temp, &len);
    
    /* temp = 1 + exp(-x) */
    double one = 1.0;
    vDSP_vsaddD(temp, 1, &one, temp, 1, (vDSP_Length)n);
    
    /* data = x / (1 + exp(-x)) */
    vDSP_vdivD(temp, 1, data, 1, data, 1, (vDSP_Length)n);
    
    Safefree(temp);
#else
    { size_t i;
    for (i = 0; i < n; i++) {
        double x = data[i];
        data[i] = x / (1.0 + exp(-x));
    }
    }
#endif
}

/* GELU: x * 0.5 * (1 + tanh(sqrt(2/pi) * (x + 0.044715 * x^3))) */
static void mat_gelu_inplace(Mat *mat) {
    size_t n = (size_t)mat->rows * (size_t)mat->cols;
    double *data = mat->data;
    const double sqrt_2_over_pi = 0.7978845608028654;
    const double coeff = 0.044715;
    
#if NMAT_HAVE_BLAS && defined(__APPLE__)
    double *temp, *x3;
    Newx(temp, n, double);
    Newx(x3, n, double);
    int len = (int)n;
    
    /* x3 = x * x * x */
    vDSP_vsqD(data, 1, x3, 1, (vDSP_Length)n);      /* x3 = x^2 */
    vDSP_vmulD(x3, 1, data, 1, x3, 1, (vDSP_Length)n);  /* x3 = x^3 */
    
    /* temp = 0.044715 * x^3 */
    vDSP_vsmulD(x3, 1, &coeff, temp, 1, (vDSP_Length)n);
    
    /* temp = x + 0.044715 * x^3 */
    vDSP_vaddD(data, 1, temp, 1, temp, 1, (vDSP_Length)n);
    
    /* temp = sqrt(2/pi) * (x + 0.044715 * x^3) */
    vDSP_vsmulD(temp, 1, &sqrt_2_over_pi, temp, 1, (vDSP_Length)n);
    
    /* temp = tanh(...) */
    vvtanh(temp, temp, &len);
    
    /* temp = 1 + tanh(...) */
    double one = 1.0;
    vDSP_vsaddD(temp, 1, &one, temp, 1, (vDSP_Length)n);
    
    /* temp = 0.5 * (1 + tanh(...)) */
    double half = 0.5;
    vDSP_vsmulD(temp, 1, &half, temp, 1, (vDSP_Length)n);
    
    /* data = x * 0.5 * (1 + tanh(...)) */
    vDSP_vmulD(data, 1, temp, 1, data, 1, (vDSP_Length)n);
    
    Safefree(temp);
    Safefree(x3);
#else
    { size_t i;
    for (i = 0; i < n; i++) {
        double x = data[i];
        double x3 = x * x * x;
        data[i] = 0.5 * x * (1.0 + tanh(sqrt_2_over_pi * (x + coeff * x3)));
    }
    }
#endif
}

/* RMS Norm: x / sqrt(mean(x^2) + eps) * gamma */
static Mat* mat_rms_norm(pTHX_ const Mat *X, const double *gamma) {
    Mat *Y = mat_create(aTHX_ X->rows, X->cols);
    IV rows = X->rows;
    IV cols = X->cols;
    const double eps = 1e-5;
    
#if NMAT_HAVE_BLAS && defined(__APPLE__)
    /* Use vDSP for sum of squares */
    vDSP_Length vcols = (vDSP_Length)cols;
    
    { IV r;
    for (r = 0; r < rows; r++) {
        const double *xrow = X->data + r * cols;
        double *yrow = Y->data + r * cols;
        
        /* Compute sum of squares using vDSP */
        double sum_sq;
        vDSP_svesqD(xrow, 1, &sum_sq, vcols);
        
        double rms = sqrt(sum_sq / (double)cols + eps);
        double inv_rms = 1.0 / rms;
        
        /* Normalize: yrow = xrow * inv_rms */
        vDSP_vsmulD(xrow, 1, &inv_rms, yrow, 1, vcols);
        
        /* Scale by gamma: yrow = yrow * gamma */
        vDSP_vmulD(yrow, 1, gamma, 1, yrow, 1, vcols);
    }
    }
#else
    { IV r;
    for (r = 0; r < rows; r++) {
        const double *xrow = X->data + r * cols;
        double *yrow = Y->data + r * cols;
        
        /* Compute RMS */
        double sum_sq = mat_dot_data(xrow, xrow, cols);
        double rms = sqrt(sum_sq / (double)cols + eps);
        double inv_rms = 1.0 / rms;
        
        /* Normalize and scale */
        { IV c;
        for (c = 0; c < cols; c++) {
            yrow[c] = xrow[c] * inv_rms * gamma[c];
        }
        }
    }
    }
#endif
    
    return Y;
}

/* Layer Norm: (x - mean) / std * gamma + beta */
static void mat_layer_norm(pTHX_ const Mat *X, const double *gamma, const double *beta,
                           Mat **Y_out, double **mean_out, double **inv_std_out) {
    IV rows = X->rows;
    IV cols = X->cols;
    const double eps = 1e-5;
    
    Mat *Y = mat_create(aTHX_ rows, cols);
    double *mean, *inv_std;
    Newx(mean, rows, double);
    Newx(inv_std, rows, double);
    
#if NMAT_HAVE_BLAS && defined(__APPLE__)
    vDSP_Length vcols = (vDSP_Length)cols;
    double *temp;
    Newx(temp, cols, double);
    
    { IV r;
    for (r = 0; r < rows; r++) {
        const double *xrow = X->data + r * cols;
        double *yrow = Y->data + r * cols;
        
        /* Compute mean using vDSP */
        vDSP_meanvD(xrow, 1, &mean[r], vcols);
        
        /* Compute variance: temp = (x - mean)^2 */
        double neg_mean = -mean[r];
        vDSP_vsaddD(xrow, 1, &neg_mean, temp, 1, vcols);  /* temp = x - mean */
        vDSP_vsqD(temp, 1, temp, 1, vcols);               /* temp = temp^2 */
        
        double var;
        vDSP_sveD(temp, 1, &var, vcols);
        var /= (double)cols;
        inv_std[r] = 1.0 / sqrt(var + eps);
        
        /* Normalize: yrow = (x - mean) * inv_std */
        vDSP_vsaddD(xrow, 1, &neg_mean, yrow, 1, vcols);
        vDSP_vsmulD(yrow, 1, &inv_std[r], yrow, 1, vcols);
        
        /* Scale and shift: yrow = yrow * gamma + beta */
        vDSP_vmulD(yrow, 1, gamma, 1, yrow, 1, vcols);
        vDSP_vaddD(yrow, 1, beta, 1, yrow, 1, vcols);
    }
    }
    
    Safefree(temp);
#else
    { IV r;
    for (r = 0; r < rows; r++) {
        const double *xrow = X->data + r * cols;
        double *yrow = Y->data + r * cols;
        
        /* Compute mean */
        double sum = mat_sum_data(xrow, cols);
        mean[r] = sum / (double)cols;
        
        /* Compute variance */
        double var = 0.0;
        { IV c;
        for (c = 0; c < cols; c++) {
            double d = xrow[c] - mean[r];
            var += d * d;
        }
        }
        var /= (double)cols;
        inv_std[r] = 1.0 / sqrt(var + eps);
        
        /* Normalize and scale */
        { IV c;
        for (c = 0; c < cols; c++) {
            yrow[c] = (xrow[c] - mean[r]) * inv_std[r] * gamma[c] + beta[c];
        }
        }
    }
    }
#endif
    
    *Y_out = Y;
    *mean_out = mean;
    *inv_std_out = inv_std;
}

/* Layer Norm Backward */
static void mat_layer_norm_bwd(pTHX_ const Mat *dY, const Mat *X, 
                               const double *mean, const double *inv_std, const double *gamma,
                               Mat **dX_out, double **dgamma_out, double **dbeta_out) {
    IV rows = X->rows;
    IV cols = X->cols;
    
    Mat *dX = mat_create(aTHX_ rows, cols);
    double *dgamma, *dbeta;
    Newxz(dgamma, cols, double);
    Newxz(dbeta, cols, double);
    
    /* Pass 1: compute dgamma and dbeta */
    { IV r;
    for (r = 0; r < rows; r++) {
        const double *xrow = X->data + r * cols;
        const double *dyrow = dY->data + r * cols;
        { IV c;
        for (c = 0; c < cols; c++) {
            double x_norm = (xrow[c] - mean[r]) * inv_std[r];
            dgamma[c] += dyrow[c] * x_norm;
            dbeta[c] += dyrow[c];
        }
        }
    }
    }
    
    /* Pass 2: compute dX */
    { IV r;
    for (r = 0; r < rows; r++) {
        const double *xrow = X->data + r * cols;
        const double *dyrow = dY->data + r * cols;
        double *dxrow = dX->data + r * cols;
        
        /* Compute sums needed for dX */
        double sum_dy = 0.0, sum_dy_xhat = 0.0;
        { IV c;
        for (c = 0; c < cols; c++) {
            double x_norm = (xrow[c] - mean[r]) * inv_std[r];
            sum_dy += dyrow[c] * gamma[c];
            sum_dy_xhat += dyrow[c] * gamma[c] * x_norm;
        }
        }
        
        double inv_n = 1.0 / (double)cols;
        { IV c;
        for (c = 0; c < cols; c++) {
            double x_norm = (xrow[c] - mean[r]) * inv_std[r];
            dxrow[c] = inv_std[r] * (gamma[c] * dyrow[c] - inv_n * (sum_dy + x_norm * sum_dy_xhat));
        }
        }
    }
    }
    
    *dX_out = dX;
    *dgamma_out = dgamma;
    *dbeta_out = dbeta;
}

/* Row sum -> returns array of doubles */
static double* mat_row_sum(pTHX_ const Mat *A) {
    double *sums;
    Newx(sums, A->rows, double);
    
#if NMAT_HAVE_BLAS && defined(__APPLE__)
    vDSP_Length vcols = (vDSP_Length)A->cols;
    { IV r;
    for (r = 0; r < A->rows; r++) {
        const double *row = A->data + r * A->cols;
        vDSP_sveD(row, 1, &sums[r], vcols);
    }
    }
#else
    { IV r;
    for (r = 0; r < A->rows; r++) {
        const double *row = A->data + r * A->cols;
        sums[r] = mat_sum_data(row, A->cols);
    }
    }
#endif
    return sums;
}

/* Col sum -> returns array of doubles */
static double* mat_col_sum(pTHX_ const Mat *A) {
    double *sums;
    Newxz(sums, A->cols, double);
    
#if NMAT_HAVE_NEON
    /* Process 2 doubles at a time with NEON */
    size_t vec_len = A->cols & ~1UL;
    
    { IV r;
    for (r = 0; r < A->rows; r++) {
        const double *row = A->data + r * A->cols;
        size_t c = 0;
        for (; c < vec_len; c += 2) {
            float64x2_t va = vld1q_f64(row + c);
            float64x2_t vs = vld1q_f64(sums + c);
            vst1q_f64(sums + c, vaddq_f64(va, vs));
        }
        for (; c < (size_t)A->cols; c++) {
            sums[c] += row[c];
        }
    }
    }
#elif NMAT_HAVE_AVX2 || NMAT_HAVE_AVX
    size_t vec_len = A->cols & ~3UL;
    
    { IV r;
    for (r = 0; r < A->rows; r++) {
        const double *row = A->data + r * A->cols;
        size_t c = 0;
        for (; c < vec_len; c += 4) {
            __m256d va = _mm256_loadu_pd(row + c);
            __m256d vs = _mm256_loadu_pd(sums + c);
            _mm256_storeu_pd(sums + c, _mm256_add_pd(va, vs));
        }
        for (; c < (size_t)A->cols; c++) {
            sums[c] += row[c];
        }
    }
    }
#elif NMAT_HAVE_SSE2
    size_t vec_len = A->cols & ~1UL;
    
    { IV r;
    for (r = 0; r < A->rows; r++) {
        const double *row = A->data + r * A->cols;
        size_t c = 0;
        for (; c < vec_len; c += 2) {
            __m128d va = _mm_loadu_pd(row + c);
            __m128d vs = _mm_loadu_pd(sums + c);
            _mm_storeu_pd(sums + c, _mm_add_pd(va, vs));
        }
        for (; c < (size_t)A->cols; c++) {
            sums[c] += row[c];
        }
    }
    }
#else
    { IV r;
    for (r = 0; r < A->rows; r++) {
        const double *row = A->data + r * A->cols;
        { IV c;
        for (c = 0; c < A->cols; c++) {
            sums[c] += row[c];
        }
        }
    }
    }
#endif
    return sums;
}

/* Add vector to each row */
static void mat_add_vec_rows_inplace(Mat *A, const double *vec) {
#if NMAT_HAVE_BLAS && defined(__APPLE__)
    vDSP_Length vcols = (vDSP_Length)A->cols;
    { IV r;
    for (r = 0; r < A->rows; r++) {
        double *row = A->data + r * A->cols;
        vDSP_vaddD(row, 1, vec, 1, row, 1, vcols);
    }
    }
#else
    { IV r;
    for (r = 0; r < A->rows; r++) {
        double *row = A->data + r * A->cols;
        mat_add_data(row, row, vec, A->cols);
    }
    }
#endif
}

/* Multiply each row by vector */
static void mat_mul_vec_rows_inplace(Mat *A, const double *vec) {
#if NMAT_HAVE_BLAS && defined(__APPLE__)
    vDSP_Length vcols = (vDSP_Length)A->cols;
    { IV r;
    for (r = 0; r < A->rows; r++) {
        double *row = A->data + r * A->cols;
        vDSP_vmulD(row, 1, vec, 1, row, 1, vcols);
    }
    }
#else
    { IV r;
    for (r = 0; r < A->rows; r++) {
        double *row = A->data + r * A->cols;
        mat_mul_data(row, row, vec, A->cols);
    }
    }
#endif
}

/* ============================================
   XS Functions
   ============================================ */

/* --- Constructors --- */

XS_INTERNAL(xs_mat_zeros) {
    dXSARGS;
    if (items != 2) croak("Usage: Numeric::Matrix::zeros($rows, $cols)");
    
    IV rows = SvIV(ST(0));
    IV cols = SvIV(ST(1));
    
    Mat *mat = mat_create(aTHX_ rows, cols);
    ST(0) = sv_2mortal(mat_wrap(aTHX_ mat));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_ones) {
    dXSARGS;
    if (items != 2) croak("Usage: Numeric::Matrix::ones($rows, $cols)");
    
    IV rows = SvIV(ST(0));
    IV cols = SvIV(ST(1));
    
    Mat *mat = mat_create(aTHX_ rows, cols);
    size_t n = (size_t)rows * (size_t)cols;
    { size_t i;
    for (i = 0; i < n; i++) {
        mat->data[i] = 1.0;
    }
    }
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ mat));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_randn) {
    dXSARGS;
    if (items != 2) croak("Usage: Numeric::Matrix::randn($rows, $cols)");
    
    IV rows = SvIV(ST(0));
    IV cols = SvIV(ST(1));
    
    Mat *mat = mat_create(aTHX_ rows, cols);
    size_t n = (size_t)rows * (size_t)cols;
    { size_t i;
    for (i = 0; i < n; i++) {
        mat->data[i] = mat_randn();
    }
    }
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ mat));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_from_array) {
    dXSARGS;
    if (items != 3) croak("Usage: Numeric::Matrix::from_array(\\@data, $rows, $cols)");
    
    SV *arrayref = ST(0);
    IV rows = SvIV(ST(1));
    IV cols = SvIV(ST(2));
    
    if (!SvROK(arrayref) || SvTYPE(SvRV(arrayref)) != SVt_PVAV) {
        croak("Numeric::Matrix::from_array: first argument must be an array reference");
    }
    
    AV *av = (AV *)SvRV(arrayref);
    IV len = av_len(av) + 1;
    
    if (len != rows * cols) {
        croak("Numeric::Matrix::from_array: array length (%"IVdf") != rows*cols (%"IVdf")", len, rows * cols);
    }
    
    Mat *mat = mat_create(aTHX_ rows, cols);
    { IV i;
    for (i = 0; i < len; i++) {
        SV **elem = av_fetch(av, i, 0);
        mat->data[i] = elem ? SvNV(*elem) : 0.0;
    }
    }
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ mat));
    XSRETURN(1);
}

/* --- Shape & Access --- */

XS_INTERNAL(xs_mat_rows) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->rows()");
    
    Mat *mat = mat_from_sv(aTHX_ ST(0));
    XSRETURN_IV(mat->rows);
}

XS_INTERNAL(xs_mat_cols) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->cols()");
    
    Mat *mat = mat_from_sv(aTHX_ ST(0));
    XSRETURN_IV(mat->cols);
}

XS_INTERNAL(xs_mat_shape) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->shape()");
    
    Mat *mat = mat_from_sv(aTHX_ ST(0));
    EXTEND(SP, 2);
    ST(0) = sv_2mortal(newSViv(mat->rows));
    ST(1) = sv_2mortal(newSViv(mat->cols));
    XSRETURN(2);
}

XS_INTERNAL(xs_mat_get) {
    dXSARGS;
    if (items != 3) croak("Usage: $mat->get($r, $c)");
    
    Mat *mat = mat_from_sv(aTHX_ ST(0));
    IV r = SvIV(ST(1));
    IV c = SvIV(ST(2));
    
    if (r < 0 || r >= mat->rows || c < 0 || c >= mat->cols) {
        croak("Numeric::Matrix::get: index out of bounds (%"IVdf", %"IVdf") for (%"IVdf", %"IVdf")", 
              r, c, mat->rows, mat->cols);
    }
    
    XSRETURN_NV(mat->data[r * mat->cols + c]);
}

XS_INTERNAL(xs_mat_set) {
    dXSARGS;
    if (items != 4) croak("Usage: $mat->set($r, $c, $val)");
    
    Mat *mat = mat_from_sv(aTHX_ ST(0));
    IV r = SvIV(ST(1));
    IV c = SvIV(ST(2));
    NV val = SvNV(ST(3));
    
    if (r < 0 || r >= mat->rows || c < 0 || c >= mat->cols) {
        croak("Numeric::Matrix::set: index out of bounds");
    }
    
    mat->data[r * mat->cols + c] = val;
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_clone) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->clone()");
    
    Mat *src = mat_from_sv(aTHX_ ST(0));
    Mat *dst = mat_create(aTHX_ src->rows, src->cols);
    
    memcpy(dst->data, src->data, (size_t)src->rows * (size_t)src->cols * sizeof(double));
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ dst));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_zeros_like) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->zeros_like()");
    
    Mat *src = mat_from_sv(aTHX_ ST(0));
    Mat *dst = mat_create(aTHX_ src->rows, src->cols);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ dst));
    XSRETURN(1);
}

/* --- Element-wise Binary --- */

XS_INTERNAL(xs_mat_add) {
    dXSARGS;
    if (items != 2) croak("Usage: $A->add($B)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    
    if (A->rows != B->rows || A->cols != B->cols) {
        croak("Numeric::Matrix::add: dimension mismatch");
    }
    
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_add_data(C->data, A->data, B->data, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_sub) {
    dXSARGS;
    if (items != 2) croak("Usage: $A->sub($B)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    
    if (A->rows != B->rows || A->cols != B->cols) {
        croak("Numeric::Matrix::sub: dimension mismatch");
    }
    
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_sub_data(C->data, A->data, B->data, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_mul) {
    dXSARGS;
    if (items != 2) croak("Usage: $A->mul($B)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    
    if (A->rows != B->rows || A->cols != B->cols) {
        croak("Numeric::Matrix::mul: dimension mismatch");
    }
    
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_mul_data(C->data, A->data, B->data, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_div) {
    dXSARGS;
    if (items != 2) croak("Usage: $A->div($B)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    
    if (A->rows != B->rows || A->cols != B->cols) {
        croak("Numeric::Matrix::div: dimension mismatch");
    }
    
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_div_data(C->data, A->data, B->data, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

/* --- Element-wise In-place --- */

XS_INTERNAL(xs_mat_add_inplace) {
    dXSARGS;
    if (items != 2) croak("Usage: $A->add_inplace($B)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    
    if (A->rows != B->rows || A->cols != B->cols) {
        croak("Numeric::Matrix::add_inplace: dimension mismatch");
    }
    
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_add_data(A->data, A->data, B->data, n);
    
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_sub_inplace) {
    dXSARGS;
    if (items != 2) croak("Usage: $A->sub_inplace($B)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    
    if (A->rows != B->rows || A->cols != B->cols) {
        croak("Numeric::Matrix::sub_inplace: dimension mismatch");
    }
    
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_sub_data(A->data, A->data, B->data, n);
    
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_mul_inplace) {
    dXSARGS;
    if (items != 2) croak("Usage: $A->mul_inplace($B)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    
    if (A->rows != B->rows || A->cols != B->cols) {
        croak("Numeric::Matrix::mul_inplace: dimension mismatch");
    }
    
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_mul_data(A->data, A->data, B->data, n);
    
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_div_inplace) {
    dXSARGS;
    if (items != 2) croak("Usage: $A->div_inplace($B)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    
    if (A->rows != B->rows || A->cols != B->cols) {
        croak("Numeric::Matrix::div_inplace: dimension mismatch");
    }
    
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_div_data(A->data, A->data, B->data, n);
    
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_add_scaled_inplace) {
    dXSARGS;
    if (items != 3) croak("Usage: $A->add_scaled_inplace($B, $s)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    NV s = SvNV(ST(2));
    
    if (A->rows != B->rows || A->cols != B->cols) {
        croak("Numeric::Matrix::add_scaled_inplace: dimension mismatch");
    }
    
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_add_scaled_data(A->data, B->data, s, n);
    
    XSRETURN(1);
}

/* --- Scalar Ops --- */

XS_INTERNAL(xs_mat_scale) {
    dXSARGS;
    if (items != 2) croak("Usage: $mat->scale($s)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    NV s = SvNV(ST(1));
    
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_scale_data(C->data, A->data, s, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_scale_inplace) {
    dXSARGS;
    if (items != 2) croak("Usage: $mat->scale_inplace($s)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    NV s = SvNV(ST(1));
    
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_scale_data(A->data, A->data, s, n);
    
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_add_scalar) {
    dXSARGS;
    if (items != 2) croak("Usage: $mat->add_scalar($s)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    NV s = SvNV(ST(1));
    
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_add_scalar_data(C->data, A->data, s, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_add_scalar_inplace) {
    dXSARGS;
    if (items != 2) croak("Usage: $mat->add_scalar_inplace($s)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    NV s = SvNV(ST(1));
    
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_add_scalar_data(A->data, A->data, s, n);
    
    XSRETURN(1);
}

/* --- Unary Ops --- */

XS_INTERNAL(xs_mat_sqrt) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->sqrt()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_sqrt_data(C->data, A->data, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_exp) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->exp()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_exp_data(C->data, A->data, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_log) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->log()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_log_data(C->data, A->data, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_neg) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->neg()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_neg_data(C->data, A->data, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_abs) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->abs()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *C = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_abs_data(C->data, A->data, n);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

/* --- Reductions --- */

XS_INTERNAL(xs_mat_sum) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->sum()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    size_t n = (size_t)A->rows * (size_t)A->cols;
    
    XSRETURN_NV(mat_sum_data(A->data, n));
}

XS_INTERNAL(xs_mat_norm) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->norm()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    size_t n = (size_t)A->rows * (size_t)A->cols;
    
    double sum_sq = 0.0;
    { size_t i;
    for (i = 0; i < n; i++) {
        sum_sq += A->data[i] * A->data[i];
    }
    }
    
    XSRETURN_NV(sqrt(sum_sq));
}

XS_INTERNAL(xs_mat_max) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->max()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    size_t n = (size_t)A->rows * (size_t)A->cols;
    
    XSRETURN_NV(mat_max_data(A->data, n));
}

XS_INTERNAL(xs_mat_min) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->min()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    size_t n = (size_t)A->rows * (size_t)A->cols;
    
    XSRETURN_NV(mat_min_data(A->data, n));
}

/* --- Transpose --- */

XS_INTERNAL(xs_mat_transpose) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->transpose()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *T = mat_create(aTHX_ A->cols, A->rows);
    
    { IV r;
    for (r = 0; r < A->rows; r++) {
        { IV c;
        for (c = 0; c < A->cols; c++) {
            T->data[c * T->cols + r] = A->data[r * A->cols + c];
        }
        }
    }
    }
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ T));
    XSRETURN(1);
}

/* --- GEMM --- */

XS_INTERNAL(xs_mat_matmul) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: $A->matmul($B [, $transpose])");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    Mat *B = mat_from_sv(aTHX_ ST(1));
    IV trans = (items == 3) ? SvIV(ST(2)) : 0;
    
    IV M, N, K;
    Mat *C;
    
    if (trans == 0) {
        /* C = A * B */
        if (A->cols != B->rows)
            croak("matmul: A(%"IVdf"x%"IVdf") * B(%"IVdf"x%"IVdf") dimension mismatch",
                  A->rows, A->cols, B->rows, B->cols);
        M = A->rows; N = B->cols; K = A->cols;
        C = mat_create(aTHX_ M, N);
#if NMAT_HAVE_BLAS
        cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                    (int)M, (int)N, (int)K,
                    1.0, A->data, (int)A->cols,
                    B->data, (int)B->cols,
                    0.0, C->data, (int)N);
#else
        mat_matmul_tiled(A, B, C);
#endif
    }
    else if (trans == 1) {
        /* C = A * B^T */
        if (A->cols != B->cols)
            croak("matmul(trans=1): A(%"IVdf"x%"IVdf") * B^T(%"IVdf"x%"IVdf") dimension mismatch",
                  A->rows, A->cols, B->cols, B->rows);
        M = A->rows; N = B->rows; K = A->cols;
        C = mat_create(aTHX_ M, N);
#if NMAT_HAVE_BLAS
        cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasTrans,
                    (int)M, (int)N, (int)K,
                    1.0, A->data, (int)A->cols,
                    B->data, (int)B->cols,
                    0.0, C->data, (int)N);
#else
        /* Fallback: transpose B first, then multiply */
        Mat *BT = mat_create(aTHX_ B->cols, B->rows);
        { IV r; IV c;
        for (r = 0; r < B->rows; r++)
            for (c = 0; c < B->cols; c++)
                BT->data[c * BT->cols + r] = B->data[r * B->cols + c];
        }
        mat_matmul_tiled(A, BT, C);
        nmat_aligned_free(BT->data);
        Safefree(BT);
#endif
    }
    else if (trans == 2) {
        /* C = A^T * B */
        if (A->rows != B->rows)
            croak("matmul(trans=2): A^T(%"IVdf"x%"IVdf") * B(%"IVdf"x%"IVdf") dimension mismatch",
                  A->cols, A->rows, B->rows, B->cols);
        M = A->cols; N = B->cols; K = A->rows;
        C = mat_create(aTHX_ M, N);
#if NMAT_HAVE_BLAS
        cblas_dgemm(CblasRowMajor, CblasTrans, CblasNoTrans,
                    (int)M, (int)N, (int)K,
                    1.0, A->data, (int)A->cols,
                    B->data, (int)B->cols,
                    0.0, C->data, (int)N);
#else
        /* Fallback: transpose A first, then multiply */
        Mat *AT = mat_create(aTHX_ A->cols, A->rows);
        { IV r; IV c;
        for (r = 0; r < A->rows; r++)
            for (c = 0; c < A->cols; c++)
                AT->data[c * AT->cols + r] = A->data[r * A->cols + c];
        }
        mat_matmul_tiled(AT, B, C);
        nmat_aligned_free(AT->data);
        Safefree(AT);
#endif
    }
    else {
        croak("matmul: invalid transpose flag %"IVdf" (use 0, 1, or 2)", trans);
    }
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ C));
    XSRETURN(1);
}

/* --- Fused Ops --- */

XS_INTERNAL(xs_mat_softmax_rows_inplace) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->softmax_rows_inplace()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    mat_softmax_rows_inplace(A);
    
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_silu_inplace) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->silu_inplace()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    mat_silu_inplace(A);
    
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_gelu_inplace) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->gelu_inplace()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    mat_gelu_inplace(A);
    
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_rms_norm) {
    dXSARGS;
    if (items != 2) croak("Usage: $mat->rms_norm($gamma_vec)");
    
    Mat *X = mat_from_sv(aTHX_ ST(0));
    SV *gamma_sv = ST(1);
    
    if (!SvROK(gamma_sv) || SvTYPE(SvRV(gamma_sv)) != SVt_PVAV)
        croak("Numeric::Matrix::rms_norm: gamma must be an arrayref");
    
    AV *gamma_av = (AV*)SvRV(gamma_sv);
    IV gamma_len = av_len(gamma_av) + 1;
    
    if (gamma_len != X->cols)
        croak("Numeric::Matrix::rms_norm: gamma length (%d) != cols (%d)",
              (int)gamma_len, (int)X->cols);
    
    double *gamma;
    Newx(gamma, gamma_len, double);
    { IV i;
    for (i = 0; i < gamma_len; i++) {
        SV **v = av_fetch(gamma_av, i, 0);
        gamma[i] = v ? SvNV(*v) : 0.0;
    }
    }
    
    Mat *Y = mat_rms_norm(aTHX_ X, gamma);
    Safefree(gamma);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ Y));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_layer_norm) {
    dXSARGS;
    if (items != 3) croak("Usage: $mat->layer_norm($gamma, $beta)");
    
    Mat *X = mat_from_sv(aTHX_ ST(0));
    SV *gamma_sv = ST(1);
    SV *beta_sv = ST(2);
    
    if (!SvROK(gamma_sv) || SvTYPE(SvRV(gamma_sv)) != SVt_PVAV)
        croak("Numeric::Matrix::layer_norm: gamma must be an arrayref");
    if (!SvROK(beta_sv) || SvTYPE(SvRV(beta_sv)) != SVt_PVAV)
        croak("Numeric::Matrix::layer_norm: beta must be an arrayref");
    
    AV *gamma_av = (AV*)SvRV(gamma_sv);
    AV *beta_av = (AV*)SvRV(beta_sv);
    IV cols = X->cols;
    
    double *gamma, *beta;
    Newx(gamma, cols, double);
    Newx(beta, cols, double);
    { IV i;
    for (i = 0; i < cols; i++) {
        SV **gv = av_fetch(gamma_av, i, 0);
        SV **bv = av_fetch(beta_av, i, 0);
        gamma[i] = gv ? SvNV(*gv) : 1.0;
        beta[i] = bv ? SvNV(*bv) : 0.0;
    }
    }
    
    Mat *Y;
    double *mean, *inv_std;
    mat_layer_norm(aTHX_ X, gamma, beta, &Y, &mean, &inv_std);
    
    Safefree(gamma);
    Safefree(beta);
    
    /* Return (Y, mean_aref, inv_std_aref) */
    AV *mean_av = newAV();
    AV *inv_std_av = newAV();
    av_extend(mean_av, X->rows - 1);
    av_extend(inv_std_av, X->rows - 1);
    { IV r;
    for (r = 0; r < X->rows; r++) {
        av_store(mean_av, r, newSVnv(mean[r]));
        av_store(inv_std_av, r, newSVnv(inv_std[r]));
    }
    }
    Safefree(mean);
    Safefree(inv_std);
    
    SP -= items;
    XPUSHs(sv_2mortal(mat_wrap(aTHX_ Y)));
    XPUSHs(sv_2mortal(newRV_noinc((SV*)mean_av)));
    XPUSHs(sv_2mortal(newRV_noinc((SV*)inv_std_av)));
    XSRETURN(3);
}

XS_INTERNAL(xs_mat_layer_norm_bwd) {
    dXSARGS;
    if (items != 5) croak("Usage: layer_norm_bwd($dY, $X, $mean, $inv_std, $gamma)");
    
    Mat *dY = mat_from_sv(aTHX_ ST(0));
    Mat *X = mat_from_sv(aTHX_ ST(1));
    SV *mean_sv = ST(2);
    SV *inv_std_sv = ST(3);
    SV *gamma_sv = ST(4);
    
    if (!SvROK(mean_sv) || SvTYPE(SvRV(mean_sv)) != SVt_PVAV)
        croak("layer_norm_bwd: mean must be arrayref");
    if (!SvROK(inv_std_sv) || SvTYPE(SvRV(inv_std_sv)) != SVt_PVAV)
        croak("layer_norm_bwd: inv_std must be arrayref");
    if (!SvROK(gamma_sv) || SvTYPE(SvRV(gamma_sv)) != SVt_PVAV)
        croak("layer_norm_bwd: gamma must be arrayref");
    
    AV *mean_av = (AV*)SvRV(mean_sv);
    AV *inv_std_av = (AV*)SvRV(inv_std_sv);
    AV *gamma_av = (AV*)SvRV(gamma_sv);
    
    IV rows = X->rows, cols = X->cols;
    double *mean, *inv_std, *gamma;
    Newx(mean, rows, double);
    Newx(inv_std, rows, double);
    Newx(gamma, cols, double);
    
    { IV r;
    for (r = 0; r < rows; r++) {
        SV **mv = av_fetch(mean_av, r, 0);
        SV **iv = av_fetch(inv_std_av, r, 0);
        mean[r] = mv ? SvNV(*mv) : 0.0;
        inv_std[r] = iv ? SvNV(*iv) : 1.0;
    }
    }
    { IV c;
    for (c = 0; c < cols; c++) {
        SV **gv = av_fetch(gamma_av, c, 0);
        gamma[c] = gv ? SvNV(*gv) : 1.0;
    }
    }
    
    Mat *dX;
    double *dgamma, *dbeta;
    mat_layer_norm_bwd(aTHX_ dY, X, mean, inv_std, gamma, &dX, &dgamma, &dbeta);
    
    Safefree(mean);
    Safefree(inv_std);
    Safefree(gamma);
    
    /* Return (dX, dgamma_aref, dbeta_aref) */
    AV *dgamma_av = newAV();
    AV *dbeta_av = newAV();
    av_extend(dgamma_av, cols - 1);
    av_extend(dbeta_av, cols - 1);
    { IV c;
    for (c = 0; c < cols; c++) {
        av_store(dgamma_av, c, newSVnv(dgamma[c]));
        av_store(dbeta_av, c, newSVnv(dbeta[c]));
    }
    }
    Safefree(dgamma);
    Safefree(dbeta);
    
    SP -= items;
    XPUSHs(sv_2mortal(mat_wrap(aTHX_ dX)));
    XPUSHs(sv_2mortal(newRV_noinc((SV*)dgamma_av)));
    XPUSHs(sv_2mortal(newRV_noinc((SV*)dbeta_av)));
    XSRETURN(3);
}

XS_INTERNAL(xs_mat_row_sum) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->row_sum()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    double *sums = mat_row_sum(aTHX_ A);
    
    AV *av = newAV();
    av_extend(av, A->rows - 1);
    { IV r;
    for (r = 0; r < A->rows; r++) {
        av_store(av, r, newSVnv(sums[r]));
    }
    }
    Safefree(sums);
    
    ST(0) = sv_2mortal(newRV_noinc((SV*)av));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_col_sum) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->col_sum()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    double *sums = mat_col_sum(aTHX_ A);
    
    AV *av = newAV();
    av_extend(av, A->cols - 1);
    { IV c;
    for (c = 0; c < A->cols; c++) {
        av_store(av, c, newSVnv(sums[c]));
    }
    }
    Safefree(sums);
    
    ST(0) = sv_2mortal(newRV_noinc((SV*)av));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_row) {
    dXSARGS;
    if (items != 2) croak("Usage: $mat->row($r)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    IV r = SvIV(ST(1));
    
    if (r < 0 || r >= A->rows)
        croak("Numeric::Matrix::row: index %d out of bounds [0..%d)",
              (int)r, (int)A->rows);
    
    /* Return as arrayref for now (no Numeric::Vector dep) */
    AV *av = newAV();
    av_extend(av, A->cols - 1);
    double *row = A->data + r * A->cols;
    { IV c;
    for (c = 0; c < A->cols; c++) {
        av_store(av, c, newSVnv(row[c]));
    }
    }
    
    ST(0) = sv_2mortal(newRV_noinc((SV*)av));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_set_row) {
    dXSARGS;
    if (items != 3) croak("Usage: $mat->set_row($r, $aref)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    IV r = SvIV(ST(1));
    SV *vec_sv = ST(2);
    
    if (r < 0 || r >= A->rows)
        croak("Numeric::Matrix::set_row: index %d out of bounds", (int)r);
    
    if (!SvROK(vec_sv) || SvTYPE(SvRV(vec_sv)) != SVt_PVAV)
        croak("Numeric::Matrix::set_row: values must be arrayref");
    
    AV *av = (AV*)SvRV(vec_sv);
    IV len = av_len(av) + 1;
    if (len != A->cols)
        croak("Numeric::Matrix::set_row: array length %d != cols %d",
              (int)len, (int)A->cols);
    
    double *row = A->data + r * A->cols;
    { IV c;
    for (c = 0; c < A->cols; c++) {
        SV **v = av_fetch(av, c, 0);
        row[c] = v ? SvNV(*v) : 0.0;
    }
    }
    
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_slice_rows) {
    dXSARGS;
    if (items != 3) croak("Usage: $mat->slice_rows($start, $end)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    IV start = SvIV(ST(1));
    IV end = SvIV(ST(2));
    
    if (start < 0 || start >= A->rows || end <= start || end > A->rows)
        croak("Numeric::Matrix::slice_rows: invalid range [%d, %d) for %d rows",
              (int)start, (int)end, (int)A->rows);
    
    IV new_rows = end - start;
    Mat *B = mat_create(aTHX_ new_rows, A->cols);
    
    memcpy(B->data, A->data + start * A->cols,
           (size_t)new_rows * (size_t)A->cols * sizeof(double));
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ B));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_add_vec_rows) {
    dXSARGS;
    if (items != 2) croak("Usage: $mat->add_vec_rows($vec_aref)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    SV *vec_sv = ST(1);
    
    if (!SvROK(vec_sv) || SvTYPE(SvRV(vec_sv)) != SVt_PVAV)
        croak("Numeric::Matrix::add_vec_rows: argument must be arrayref");
    
    AV *av = (AV*)SvRV(vec_sv);
    IV len = av_len(av) + 1;
    if (len != A->cols)
        croak("Numeric::Matrix::add_vec_rows: vector length %d != cols %d",
              (int)len, (int)A->cols);
    
    double *vec;
    Newx(vec, len, double);
    { IV c;
    for (c = 0; c < len; c++) {
        SV **v = av_fetch(av, c, 0);
        vec[c] = v ? SvNV(*v) : 0.0;
    }
    }
    
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    memcpy(B->data, A->data, (size_t)A->rows * (size_t)A->cols * sizeof(double));
    mat_add_vec_rows_inplace(B, vec);
    Safefree(vec);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ B));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_mul_vec_rows) {
    dXSARGS;
    if (items != 2) croak("Usage: $mat->mul_vec_rows($vec_aref)");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    SV *vec_sv = ST(1);
    
    if (!SvROK(vec_sv) || SvTYPE(SvRV(vec_sv)) != SVt_PVAV)
        croak("Numeric::Matrix::mul_vec_rows: argument must be arrayref");
    
    AV *av = (AV*)SvRV(vec_sv);
    IV len = av_len(av) + 1;
    if (len != A->cols)
        croak("Numeric::Matrix::mul_vec_rows: vector length %d != cols %d",
              (int)len, (int)A->cols);
    
    double *vec;
    Newx(vec, len, double);
    { IV c;
    for (c = 0; c < len; c++) {
        SV **v = av_fetch(av, c, 0);
        vec[c] = v ? SvNV(*v) : 0.0;
    }
    }
    
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    memcpy(B->data, A->data, (size_t)A->rows * (size_t)A->cols * sizeof(double));
    mat_mul_vec_rows_inplace(B, vec);
    Safefree(vec);
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ B));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_from_vector) {
    dXSARGS;
    if (items != 3) croak("Usage: Numeric::Matrix::from_vector($vec_aref, $rows, $cols)");
    
    SV *vec_sv = ST(0);
    IV rows = SvIV(ST(1));
    IV cols = SvIV(ST(2));
    
    if (!SvROK(vec_sv) || SvTYPE(SvRV(vec_sv)) != SVt_PVAV)
        croak("Numeric::Matrix::from_vector: first arg must be arrayref");
    
    AV *av = (AV*)SvRV(vec_sv);
    IV len = av_len(av) + 1;
    
    if (len != rows * cols)
        croak("Numeric::Matrix::from_vector: vector length %d != rows*cols (%d*%d=%d)",
              (int)len, (int)rows, (int)cols, (int)(rows*cols));
    
    Mat *mat = mat_create(aTHX_ rows, cols);
    { IV i;
    for (i = 0; i < len; i++) {
        SV **v = av_fetch(av, i, 0);
        mat->data[i] = v ? SvNV(*v) : 0.0;
    }
    }
    
    ST(0) = sv_2mortal(mat_wrap(aTHX_ mat));
    XSRETURN(1);
}

XS_INTERNAL(xs_mat_to_vector) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->to_vector()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    size_t n = (size_t)A->rows * (size_t)A->cols;
    
    AV *av = newAV();
    av_extend(av, n - 1);
    { size_t i;
    for (i = 0; i < n; i++) {
        av_store(av, i, newSVnv(A->data[i]));
    }
    }
    
    ST(0) = sv_2mortal(newRV_noinc((SV*)av));
    XSRETURN(1);
}

/* --- Serialization --- */

XS_INTERNAL(xs_mat_to_array) {
    dXSARGS;
    if (items != 1) croak("Usage: $mat->to_array()");
    
    Mat *A = mat_from_sv(aTHX_ ST(0));
    size_t n = (size_t)A->rows * (size_t)A->cols;
    
    AV *av = newAV();
    av_extend(av, n - 1);
    { size_t i;
    for (i = 0; i < n; i++) {
        av_store(av, i, newSVnv(A->data[i]));
    }
    }
    
    ST(0) = sv_2mortal(newRV_noinc((SV*)av));
    XSRETURN(1);
}

/* --- Functional Export --- */

XS_INTERNAL(xs_nmat_import) {
    dXSARGS;
    const char *caller_pkg;
    HV         *caller_stash;
    I32         i;

    /* Skip class name (first arg), return if no imports requested */
    if (items < 2)
        XSRETURN_EMPTY;

    caller_pkg   = CopSTASHPV(PL_curcop);
    caller_stash = gv_stashpv(caller_pkg, GV_ADD);

    for (i = 1; i < items; i++) {
        const char *name = SvPV_nolen(ST(i));
        char src_name[512];
        char dst_name[512];
        CV  *src_cv;
        GV  *gv;

        if ((size_t)snprintf(src_name, sizeof(src_name),
                             "Numeric::Matrix::%s", name) >= sizeof(src_name))
            croak("Numeric::Matrix::import: name too long: '%s'", name);

        src_cv = get_cv(src_name, 0);
        if (!src_cv)
            croak("Numeric::Matrix::import: unknown function '%s'", name);

        if ((size_t)snprintf(dst_name, sizeof(dst_name),
                             "%s::nmat_%s", caller_pkg, name) >= sizeof(dst_name))
            croak("Numeric::Matrix::import: destination name too long");

        gv = gv_fetchpv(dst_name, GV_ADD, SVt_PVCV);
        GvMULTI_on(gv);  /* suppress "used only once" warning */
        if (GvCV(gv) && GvCV(gv) != src_cv)
            warn("Subroutine nmat_%s redefined", name);

        GvCV_set(gv, src_cv);
        SvREFCNT_inc_simple_void_NN((SV*)src_cv);
        GvCVGEN(gv) = 0;
        mro_method_changed_in(caller_stash);
    }

    XSRETURN_EMPTY;
}

/* ============================================
   Custom Op Implementations (pp functions)
   ============================================ */

/* pp_mat_rows: $m->rows as a custom op */
static OP* pp_mat_rows(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    POPs;
    mPUSHi(m->rows);
    RETURN;
}

/* pp_mat_cols: $m->cols as a custom op */
static OP* pp_mat_cols(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    POPs;
    mPUSHi(m->cols);
    RETURN;
}

/* pp_mat_sum: $m->sum as a custom op */
static OP* pp_mat_sum(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    POPs;
    mPUSHn(mat_sum_data(m->data, (size_t)m->rows * (size_t)m->cols));
    RETURN;
}

/* pp_mat_norm: $m->norm as a custom op */
static OP* pp_mat_norm(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    size_t n = (size_t)m->rows * (size_t)m->cols;
    double result = sqrt(mat_dot_data(m->data, m->data, n));
    POPs;
    mPUSHn(result);
    RETURN;
}

/* pp_mat_max: $m->max as a custom op */
static OP* pp_mat_max(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    POPs;
    mPUSHn(mat_max_data(m->data, (size_t)m->rows * (size_t)m->cols));
    RETURN;
}

/* pp_mat_min: $m->min as a custom op */
static OP* pp_mat_min(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    POPs;
    mPUSHn(mat_min_data(m->data, (size_t)m->rows * (size_t)m->cols));
    RETURN;
}

/* pp_mat_clone: $m->clone as a custom op */
static OP* pp_mat_clone(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    memcpy(B->data, A->data, n * sizeof(double));
    POPs;
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_transpose: $m->transpose as a custom op */
static OP* pp_mat_transpose(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    Mat *B = mat_create(aTHX_ A->cols, A->rows);
    
    { IV r;
    for (r = 0; r < A->rows; r++) {
        { IV c;
        for (c = 0; c < A->cols; c++) {
            B->data[c * B->cols + r] = A->data[r * A->cols + c];
        }
        }
    }
    }
    POPs;
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_neg: $m->neg as a custom op */
static OP* pp_mat_neg(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_neg_data(B->data, A->data, n);
    POPs;
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_abs: $m->abs as a custom op */
static OP* pp_mat_abs(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_abs_data(B->data, A->data, n);
    POPs;
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_sqrt: $m->sqrt as a custom op */
static OP* pp_mat_sqrt(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_sqrt_data(B->data, A->data, n);
    POPs;
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_exp: $m->exp as a custom op */
static OP* pp_mat_exp(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_exp_data(B->data, A->data, n);
    POPs;
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_log: $m->log as a custom op */
static OP* pp_mat_log(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_log_data(B->data, A->data, n);
    POPs;
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_softmax_rows_inplace: $m->softmax_rows_inplace as a custom op */
static OP* pp_mat_softmax_rows_inplace(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    mat_softmax_rows_inplace(A);
    RETURN;
}

/* pp_mat_silu_inplace: $m->silu_inplace as a custom op */
static OP* pp_mat_silu_inplace(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    mat_silu_inplace(A);
    RETURN;
}

/* pp_mat_gelu_inplace: $m->gelu_inplace as a custom op */
static OP* pp_mat_gelu_inplace(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    mat_gelu_inplace(A);
    RETURN;
}

/* Binary ops - take 2 matrices on stack */

/* pp_mat_add: $a->add($b) as a custom op */
static OP* pp_mat_add(pTHX) {
    dSP;
    SV *sv_b = POPs;
    SV *sv_a = POPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    Mat *C;
    size_t n;
    
    if (A->rows != B->rows || A->cols != B->cols)
        croak("Numeric::Matrix: dimension mismatch in add");
    
    C = mat_create(aTHX_ A->rows, A->cols);
    n = (size_t)A->rows * (size_t)A->cols;
    mat_add_data(C->data, A->data, B->data, n);
    
    PUSHs(sv_2mortal(mat_wrap(aTHX_ C)));
    RETURN;
}

/* pp_mat_sub: $a->sub($b) as a custom op */
static OP* pp_mat_sub(pTHX) {
    dSP;
    SV *sv_b = POPs;
    SV *sv_a = POPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    Mat *C;
    size_t n;
    
    if (A->rows != B->rows || A->cols != B->cols)
        croak("Numeric::Matrix: dimension mismatch in sub");
    
    C = mat_create(aTHX_ A->rows, A->cols);
    n = (size_t)A->rows * (size_t)A->cols;
    mat_sub_data(C->data, A->data, B->data, n);
    
    PUSHs(sv_2mortal(mat_wrap(aTHX_ C)));
    RETURN;
}

/* pp_mat_mul: $a->mul($b) as a custom op */
static OP* pp_mat_mul(pTHX) {
    dSP;
    SV *sv_b = POPs;
    SV *sv_a = POPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    Mat *C;
    size_t n;
    
    if (A->rows != B->rows || A->cols != B->cols)
        croak("Numeric::Matrix: dimension mismatch in mul");
    
    C = mat_create(aTHX_ A->rows, A->cols);
    n = (size_t)A->rows * (size_t)A->cols;
    mat_mul_data(C->data, A->data, B->data, n);
    
    PUSHs(sv_2mortal(mat_wrap(aTHX_ C)));
    RETURN;
}

/* pp_mat_div: $a->div($b) as a custom op */
static OP* pp_mat_div(pTHX) {
    dSP;
    SV *sv_b = POPs;
    SV *sv_a = POPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    Mat *C;
    size_t n;
    
    if (A->rows != B->rows || A->cols != B->cols)
        croak("Numeric::Matrix: dimension mismatch in div");
    
    C = mat_create(aTHX_ A->rows, A->cols);
    n = (size_t)A->rows * (size_t)A->cols;
    mat_div_data(C->data, A->data, B->data, n);
    
    PUSHs(sv_2mortal(mat_wrap(aTHX_ C)));
    RETURN;
}

/* pp_mat_scale: $a->scale($scalar) as a custom op */
static OP* pp_mat_scale(pTHX) {
    dSP;
    NV scalar = POPn;
    SV *sv_a = POPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_scale_data(B->data, A->data, scalar, n);
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_matmul: $a->matmul($b) as a custom op */
static OP* pp_mat_matmul(pTHX) {
    dSP;
    SV *sv_b = POPs;
    SV *sv_a = POPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    Mat *C;
    
    if (A->cols != B->rows)
        croak("Numeric::Matrix: dimension mismatch in matmul (%ld x %ld) vs (%ld x %ld)",
              (long)A->rows, (long)A->cols, (long)B->rows, (long)B->cols);
    
    C = mat_create(aTHX_ A->rows, B->cols);
    
#if NMAT_HAVE_BLAS
    mat_matmul_blas(A, B, C);
#else
    mat_matmul_tiled(A, B, C);
#endif
    
    PUSHs(sv_2mortal(mat_wrap(aTHX_ C)));
    RETURN;
}

/* pp_mat_get: $m->get($r, $c) as a custom op - needs 3 args */
static OP* pp_mat_get(pTHX) {
    dSP;
    IV c = POPi;
    IV r = POPi;
    SV *sv_m = POPs;
    Mat *m = mat_from_sv(aTHX_ sv_m);
    
    if (r < 0 || r >= m->rows || c < 0 || c >= m->cols)
        croak("Numeric::Matrix: index out of bounds");
    
    mPUSHn(m->data[r * m->cols + c]);
    RETURN;
}

/* pp_mat_set: $m->set($r, $c, $v) as a custom op - needs 4 args */
static OP* pp_mat_set(pTHX) {
    dSP;
    NV v = POPn;
    IV c = POPi;
    IV r = POPi;
    SV *sv_m = POPs;
    Mat *m = mat_from_sv(aTHX_ sv_m);
    
    if (r < 0 || r >= m->rows || c < 0 || c >= m->cols)
        croak("Numeric::Matrix: index out of bounds");
    
    m->data[r * m->cols + c] = v;
    PUSHs(sv_m);
    RETURN;
}

/* pp_mat_shape: $m->shape as a custom op - returns (rows, cols) */
static OP* pp_mat_shape(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    POPs;
    EXTEND(SP, 2);
    mPUSHi(m->rows);
    mPUSHi(m->cols);
    RETURN;
}

/* pp_mat_zeros_like: $m->zeros_like as a custom op */
static OP* pp_mat_zeros_like(pTHX) {
    dSP;
    Mat *A = mat_from_sv(aTHX_ TOPs);
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    POPs;
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_add_inplace: $a->add_inplace($b) as a custom op */
static OP* pp_mat_add_inplace(pTHX) {
    dSP;
    SV *sv_b = POPs;
    SV *sv_a = TOPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    size_t n;
    
    if (A->rows != B->rows || A->cols != B->cols)
        croak("Numeric::Matrix: dimension mismatch in add_inplace");
    
    n = (size_t)A->rows * (size_t)A->cols;
    mat_add_data(A->data, A->data, B->data, n);
    RETURN;
}

/* pp_mat_sub_inplace: $a->sub_inplace($b) as a custom op */
static OP* pp_mat_sub_inplace(pTHX) {
    dSP;
    SV *sv_b = POPs;
    SV *sv_a = TOPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    size_t n;
    
    if (A->rows != B->rows || A->cols != B->cols)
        croak("Numeric::Matrix: dimension mismatch in sub_inplace");
    
    n = (size_t)A->rows * (size_t)A->cols;
    mat_sub_data(A->data, A->data, B->data, n);
    RETURN;
}

/* pp_mat_mul_inplace: $a->mul_inplace($b) as a custom op */
static OP* pp_mat_mul_inplace(pTHX) {
    dSP;
    SV *sv_b = POPs;
    SV *sv_a = TOPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    size_t n;
    
    if (A->rows != B->rows || A->cols != B->cols)
        croak("Numeric::Matrix: dimension mismatch in mul_inplace");
    
    n = (size_t)A->rows * (size_t)A->cols;
    mat_mul_data(A->data, A->data, B->data, n);
    RETURN;
}

/* pp_mat_div_inplace: $a->div_inplace($b) as a custom op */
static OP* pp_mat_div_inplace(pTHX) {
    dSP;
    SV *sv_b = POPs;
    SV *sv_a = TOPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    size_t n;
    
    if (A->rows != B->rows || A->cols != B->cols)
        croak("Numeric::Matrix: dimension mismatch in div_inplace");
    
    n = (size_t)A->rows * (size_t)A->cols;
    mat_div_data(A->data, A->data, B->data, n);
    RETURN;
}

/* pp_mat_scale_inplace: $a->scale_inplace($s) as a custom op */
static OP* pp_mat_scale_inplace(pTHX) {
    dSP;
    NV scalar = POPn;
    SV *sv_a = TOPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_scale_data(A->data, A->data, scalar, n);
    RETURN;
}

/* pp_mat_add_scalar: $a->add_scalar($s) as a custom op */
static OP* pp_mat_add_scalar(pTHX) {
    dSP;
    NV scalar = POPn;
    SV *sv_a = POPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_create(aTHX_ A->rows, A->cols);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_add_scalar_data(B->data, A->data, scalar, n);
    PUSHs(sv_2mortal(mat_wrap(aTHX_ B)));
    RETURN;
}

/* pp_mat_add_scalar_inplace: $a->add_scalar_inplace($s) as a custom op */
static OP* pp_mat_add_scalar_inplace(pTHX) {
    dSP;
    NV scalar = POPn;
    SV *sv_a = TOPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    size_t n = (size_t)A->rows * (size_t)A->cols;
    mat_add_scalar_data(A->data, A->data, scalar, n);
    RETURN;
}

/* pp_mat_add_scaled_inplace: $a->add_scaled_inplace($b, $s) as ternary op */
static OP* pp_mat_add_scaled_inplace(pTHX) {
    dSP;
    NV scalar = POPn;
    SV *sv_b = POPs;
    SV *sv_a = TOPs;
    Mat *A = mat_from_sv(aTHX_ sv_a);
    Mat *B = mat_from_sv(aTHX_ sv_b);
    size_t n;
    
    if (A->rows != B->rows || A->cols != B->cols)
        croak("Numeric::Matrix: dimension mismatch in add_scaled_inplace");
    
    n = (size_t)A->rows * (size_t)A->cols;
    mat_add_scaled_data(A->data, B->data, scalar, n);
    RETURN;
}

/* pp_mat_row: $m->row($r) as a binary op */
static OP* pp_mat_row(pTHX) {
    dSP;
    IV r = POPi;
    SV *sv_m = POPs;
    Mat *m = mat_from_sv(aTHX_ sv_m);
    AV *av;
    double *row_data;
    IV i;
    
    if (r < 0 || r >= m->rows)
        croak("Numeric::Matrix: row index out of bounds");
    
    av = newAV();
    av_extend(av, m->cols - 1);
    row_data = m->data + r * m->cols;
    for (i = 0; i < m->cols; i++) {
        av_store(av, i, newSVnv(row_data[i]));
    }
    
    PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
    RETURN;
}

/* pp_mat_row_sum: $m->row_sum as a custom op */
static OP* pp_mat_row_sum(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    AV *av;
    IV r;
    
    POPs;
    av = newAV();
    av_extend(av, m->rows - 1);
    
    for (r = 0; r < m->rows; r++) {
        double sum = 0.0;
        double *row = m->data + r * m->cols;
        IV c;
        for (c = 0; c < m->cols; c++) sum += row[c];
        av_store(av, r, newSVnv(sum));
    }
    
    PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
    RETURN;
}

/* pp_mat_col_sum: $m->col_sum as a custom op */
static OP* pp_mat_col_sum(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    AV *av;
    IV c;
    
    POPs;
    av = newAV();
    av_extend(av, m->cols - 1);
    
    for (c = 0; c < m->cols; c++) {
        double sum = 0.0;
        IV r;
        for (r = 0; r < m->rows; r++) {
            sum += m->data[r * m->cols + c];
        }
        av_store(av, c, newSVnv(sum));
    }
    
    PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
    RETURN;
}

/* pp_mat_to_array: $m->to_array as a custom op */
static OP* pp_mat_to_array(pTHX) {
    dSP;
    Mat *m = mat_from_sv(aTHX_ TOPs);
    size_t n = (size_t)m->rows * (size_t)m->cols;
    AV *av;
    size_t i;
    
    POPs;
    av = newAV();
    av_extend(av, n - 1);
    for (i = 0; i < n; i++) {
        av_store(av, i, newSVnv(m->data[i]));
    }
    
    PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
    RETURN;
}

/* ============================================
   Call Checkers
   ============================================ */

/* Unary call checker: $m->method() */
static OP* mat_unary_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*pp_func)(pTHX)) {
    OP *pushop, *selfop, *nextop, *cvop, *newop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) return entersubop;

    selfop = OpSIBLING(pushop);
    if (!selfop) return entersubop;

    nextop = OpSIBLING(selfop);
    if (!nextop) return entersubop;

    if (OpSIBLING(nextop)) {
        cvop = OpSIBLING(nextop);
        if (cvop && OpSIBLING(cvop)) return entersubop;
    }

    OpMORESIB_set(pushop, nextop);
    OpLASTSIB_set(selfop, NULL);

    newop = newUNOP(OP_CUSTOM, 0, selfop);
    newop->op_ppaddr = pp_func;

    op_free(entersubop);
    return newop;
}

/* Binary call checker: $m->method($arg) */
static OP* mat_binary_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*pp_func)(pTHX)) {
    OP *pushop, *selfop, *argop, *cvop, *newop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) return entersubop;

    selfop = OpSIBLING(pushop);
    if (!selfop || !OpHAS_SIBLING(selfop)) return entersubop;

    argop = OpSIBLING(selfop);
    if (!argop || !OpHAS_SIBLING(argop)) return entersubop;

    cvop = OpSIBLING(argop);
    if (!cvop) return entersubop;
    if (OpSIBLING(cvop)) return entersubop;

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(selfop, NULL);
    OpLASTSIB_set(argop, NULL);
    OpMORESIB_set(selfop, argop);

    newop = newUNOP(OP_CUSTOM, 0, selfop);
    newop->op_ppaddr = pp_func;

    op_free(entersubop);
    return newop;
}

/* Ternary call checker: $m->method($arg1, $arg2) */
static OP* mat_ternary_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*pp_func)(pTHX)) {
    OP *pushop, *selfop, *arg1op, *arg2op, *cvop, *newop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) return entersubop;

    selfop = OpSIBLING(pushop);
    if (!selfop || !OpHAS_SIBLING(selfop)) return entersubop;

    arg1op = OpSIBLING(selfop);
    if (!arg1op || !OpHAS_SIBLING(arg1op)) return entersubop;

    arg2op = OpSIBLING(arg1op);
    if (!arg2op || !OpHAS_SIBLING(arg2op)) return entersubop;

    cvop = OpSIBLING(arg2op);
    if (!cvop) return entersubop;
    if (OpSIBLING(cvop)) return entersubop;

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(selfop, NULL);
    OpLASTSIB_set(arg1op, NULL);
    OpLASTSIB_set(arg2op, NULL);
    OpMORESIB_set(selfop, arg1op);
    OpMORESIB_set(arg1op, arg2op);

    newop = newUNOP(OP_CUSTOM, 0, selfop);
    newop->op_ppaddr = pp_func;

    op_free(entersubop);
    return newop;
}

/* Quaternary call checker: $m->method($arg1, $arg2, $arg3) - for set */
static OP* mat_quaternary_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*pp_func)(pTHX)) {
    OP *pushop, *selfop, *arg1op, *arg2op, *arg3op, *cvop, *newop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) return entersubop;

    selfop = OpSIBLING(pushop);
    if (!selfop || !OpHAS_SIBLING(selfop)) return entersubop;

    arg1op = OpSIBLING(selfop);
    if (!arg1op || !OpHAS_SIBLING(arg1op)) return entersubop;

    arg2op = OpSIBLING(arg1op);
    if (!arg2op || !OpHAS_SIBLING(arg2op)) return entersubop;

    arg3op = OpSIBLING(arg2op);
    if (!arg3op || !OpHAS_SIBLING(arg3op)) return entersubop;

    cvop = OpSIBLING(arg3op);
    if (!cvop) return entersubop;
    if (OpSIBLING(cvop)) return entersubop;

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(selfop, NULL);
    OpLASTSIB_set(arg1op, NULL);
    OpLASTSIB_set(arg2op, NULL);
    OpLASTSIB_set(arg3op, NULL);
    OpMORESIB_set(selfop, arg1op);
    OpMORESIB_set(arg1op, arg2op);
    OpMORESIB_set(arg2op, arg3op);

    newop = newUNOP(OP_CUSTOM, 0, selfop);
    newop->op_ppaddr = pp_func;

    op_free(entersubop);
    return newop;
}

/* Specific call checkers */
static OP* mat_rows_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_rows);
}

static OP* mat_cols_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_cols);
}

static OP* mat_sum_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_sum);
}

static OP* mat_norm_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_norm);
}

static OP* mat_max_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_max);
}

static OP* mat_min_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_min);
}

static OP* mat_clone_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_clone);
}

static OP* mat_transpose_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_transpose);
}

static OP* mat_neg_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_neg);
}

static OP* mat_abs_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_abs);
}

static OP* mat_sqrt_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_sqrt);
}

static OP* mat_exp_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_exp);
}

static OP* mat_log_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_log);
}

static OP* mat_softmax_rows_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_softmax_rows_inplace);
}

static OP* mat_silu_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_silu_inplace);
}

static OP* mat_gelu_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_gelu_inplace);
}

/* Binary call checkers */
static OP* mat_add_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_add);
}

static OP* mat_sub_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_sub);
}

static OP* mat_mul_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_mul);
}

static OP* mat_div_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_div);
}

static OP* mat_scale_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_scale);
}

static OP* mat_matmul_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_matmul);
}

/* Ternary call checker for get */
static OP* mat_get_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_get);
}

/* Quaternary call checker for set */
static OP* mat_set_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_quaternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_set);
}

/* Additional unary call checkers */
static OP* mat_shape_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_shape);
}

static OP* mat_zeros_like_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_zeros_like);
}

static OP* mat_row_sum_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_row_sum);
}

static OP* mat_col_sum_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_col_sum);
}

static OP* mat_to_array_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_unary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_to_array);
}

/* Additional binary call checkers */
static OP* mat_add_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_add_inplace);
}

static OP* mat_sub_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_sub_inplace);
}

static OP* mat_mul_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_mul_inplace);
}

static OP* mat_div_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_div_inplace);
}

static OP* mat_scale_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_scale_inplace);
}

static OP* mat_add_scalar_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_add_scalar);
}

static OP* mat_add_scalar_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_add_scalar_inplace);
}

static OP* mat_row_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_binary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_row);
}

/* Ternary call checkers */
static OP* mat_add_scaled_inplace_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return mat_ternary_call_checker(aTHX_ entersubop, namegv, ckobj, pp_mat_add_scaled_inplace);
}

/* ============================================
   BOOT
   ============================================ */

XS_EXTERNAL(boot_Numeric__Matrix);
XS_EXTERNAL(boot_Numeric__Matrix) {
    dXSBOOTARGSXSAPIVERCHK;
    PERL_UNUSED_VAR(items);
    
    /* Constructors */
    newXS("Numeric::Matrix::zeros", xs_mat_zeros, __FILE__);
    newXS("Numeric::Matrix::ones", xs_mat_ones, __FILE__);
    newXS("Numeric::Matrix::randn", xs_mat_randn, __FILE__);
    newXS("Numeric::Matrix::from_array", xs_mat_from_array, __FILE__);
    newXS("Numeric::Matrix::from_vector", xs_mat_from_vector, __FILE__);
    
    /* Shape & Access */
    newXS("Numeric::Matrix::rows", xs_mat_rows, __FILE__);
    newXS("Numeric::Matrix::cols", xs_mat_cols, __FILE__);
    newXS("Numeric::Matrix::shape", xs_mat_shape, __FILE__);
    newXS("Numeric::Matrix::get", xs_mat_get, __FILE__);
    newXS("Numeric::Matrix::set", xs_mat_set, __FILE__);
    newXS("Numeric::Matrix::clone", xs_mat_clone, __FILE__);
    newXS("Numeric::Matrix::zeros_like", xs_mat_zeros_like, __FILE__);
    
    /* Element-wise Binary */
    newXS("Numeric::Matrix::add", xs_mat_add, __FILE__);
    newXS("Numeric::Matrix::sub", xs_mat_sub, __FILE__);
    newXS("Numeric::Matrix::mul", xs_mat_mul, __FILE__);
    newXS("Numeric::Matrix::div", xs_mat_div, __FILE__);
    
    /* Element-wise In-place */
    newXS("Numeric::Matrix::add_inplace", xs_mat_add_inplace, __FILE__);
    newXS("Numeric::Matrix::sub_inplace", xs_mat_sub_inplace, __FILE__);
    newXS("Numeric::Matrix::mul_inplace", xs_mat_mul_inplace, __FILE__);
    newXS("Numeric::Matrix::div_inplace", xs_mat_div_inplace, __FILE__);
    newXS("Numeric::Matrix::add_scaled_inplace", xs_mat_add_scaled_inplace, __FILE__);
    
    /* Scalar Ops */
    newXS("Numeric::Matrix::scale", xs_mat_scale, __FILE__);
    newXS("Numeric::Matrix::scale_inplace", xs_mat_scale_inplace, __FILE__);
    newXS("Numeric::Matrix::add_scalar", xs_mat_add_scalar, __FILE__);
    newXS("Numeric::Matrix::add_scalar_inplace", xs_mat_add_scalar_inplace, __FILE__);
    
    /* Unary Ops */
    newXS("Numeric::Matrix::sqrt", xs_mat_sqrt, __FILE__);
    newXS("Numeric::Matrix::exp", xs_mat_exp, __FILE__);
    newXS("Numeric::Matrix::log", xs_mat_log, __FILE__);
    newXS("Numeric::Matrix::neg", xs_mat_neg, __FILE__);
    newXS("Numeric::Matrix::abs", xs_mat_abs, __FILE__);
    
    /* Reductions */
    newXS("Numeric::Matrix::sum", xs_mat_sum, __FILE__);
    newXS("Numeric::Matrix::norm", xs_mat_norm, __FILE__);
    newXS("Numeric::Matrix::max", xs_mat_max, __FILE__);
    newXS("Numeric::Matrix::min", xs_mat_min, __FILE__);
    newXS("Numeric::Matrix::row_sum", xs_mat_row_sum, __FILE__);
    newXS("Numeric::Matrix::col_sum", xs_mat_col_sum, __FILE__);
    
    /* Row/Shape Ops */
    newXS("Numeric::Matrix::transpose", xs_mat_transpose, __FILE__);
    newXS("Numeric::Matrix::row", xs_mat_row, __FILE__);
    newXS("Numeric::Matrix::set_row", xs_mat_set_row, __FILE__);
    newXS("Numeric::Matrix::slice_rows", xs_mat_slice_rows, __FILE__);
    
    /* Broadcast Ops */
    newXS("Numeric::Matrix::add_vec_rows", xs_mat_add_vec_rows, __FILE__);
    newXS("Numeric::Matrix::mul_vec_rows", xs_mat_mul_vec_rows, __FILE__);
    
    /* GEMM */
    newXS("Numeric::Matrix::matmul", xs_mat_matmul, __FILE__);
    
    /* Fused Ops */
    newXS("Numeric::Matrix::softmax_rows_inplace", xs_mat_softmax_rows_inplace, __FILE__);
    newXS("Numeric::Matrix::silu_inplace", xs_mat_silu_inplace, __FILE__);
    newXS("Numeric::Matrix::gelu_inplace", xs_mat_gelu_inplace, __FILE__);
    newXS("Numeric::Matrix::rms_norm", xs_mat_rms_norm, __FILE__);
    newXS("Numeric::Matrix::layer_norm", xs_mat_layer_norm, __FILE__);
    newXS("Numeric::Matrix::layer_norm_bwd", xs_mat_layer_norm_bwd, __FILE__);
    
    /* Serialization */
    newXS("Numeric::Matrix::to_array", xs_mat_to_array, __FILE__);
    newXS("Numeric::Matrix::to_vector", xs_mat_to_vector, __FILE__);
    
    /* Functional Export */
    newXS("Numeric::Matrix::import", xs_nmat_import, __FILE__);
    
    /* ============================================
       Register Custom Ops
       ============================================ */
    
    XopENTRY_set(&mat_rows_xop, xop_name, "mat_rows");
    XopENTRY_set(&mat_rows_xop, xop_desc, "mat rows accessor");
    Perl_custom_op_register(aTHX_ pp_mat_rows, &mat_rows_xop);
    
    XopENTRY_set(&mat_cols_xop, xop_name, "mat_cols");
    XopENTRY_set(&mat_cols_xop, xop_desc, "mat cols accessor");
    Perl_custom_op_register(aTHX_ pp_mat_cols, &mat_cols_xop);
    
    XopENTRY_set(&mat_get_xop, xop_name, "mat_get");
    XopENTRY_set(&mat_get_xop, xop_desc, "mat element get");
    Perl_custom_op_register(aTHX_ pp_mat_get, &mat_get_xop);
    
    XopENTRY_set(&mat_set_xop, xop_name, "mat_set");
    XopENTRY_set(&mat_set_xop, xop_desc, "mat element set");
    Perl_custom_op_register(aTHX_ pp_mat_set, &mat_set_xop);
    
    XopENTRY_set(&mat_add_xop, xop_name, "mat_add");
    XopENTRY_set(&mat_add_xop, xop_desc, "mat addition");
    Perl_custom_op_register(aTHX_ pp_mat_add, &mat_add_xop);
    
    XopENTRY_set(&mat_sub_xop, xop_name, "mat_sub");
    XopENTRY_set(&mat_sub_xop, xop_desc, "mat subtraction");
    Perl_custom_op_register(aTHX_ pp_mat_sub, &mat_sub_xop);
    
    XopENTRY_set(&mat_mul_xop, xop_name, "mat_mul");
    XopENTRY_set(&mat_mul_xop, xop_desc, "mat element-wise multiplication");
    Perl_custom_op_register(aTHX_ pp_mat_mul, &mat_mul_xop);
    
    XopENTRY_set(&mat_div_xop, xop_name, "mat_div");
    XopENTRY_set(&mat_div_xop, xop_desc, "mat element-wise division");
    Perl_custom_op_register(aTHX_ pp_mat_div, &mat_div_xop);
    
    XopENTRY_set(&mat_scale_xop, xop_name, "mat_scale");
    XopENTRY_set(&mat_scale_xop, xop_desc, "mat scalar multiplication");
    Perl_custom_op_register(aTHX_ pp_mat_scale, &mat_scale_xop);
    
    XopENTRY_set(&mat_sum_xop, xop_name, "mat_sum");
    XopENTRY_set(&mat_sum_xop, xop_desc, "mat sum reduction");
    Perl_custom_op_register(aTHX_ pp_mat_sum, &mat_sum_xop);
    
    XopENTRY_set(&mat_norm_xop, xop_name, "mat_norm");
    XopENTRY_set(&mat_norm_xop, xop_desc, "mat Frobenius norm");
    Perl_custom_op_register(aTHX_ pp_mat_norm, &mat_norm_xop);
    
    XopENTRY_set(&mat_max_xop, xop_name, "mat_max");
    XopENTRY_set(&mat_max_xop, xop_desc, "mat max reduction");
    Perl_custom_op_register(aTHX_ pp_mat_max, &mat_max_xop);
    
    XopENTRY_set(&mat_min_xop, xop_name, "mat_min");
    XopENTRY_set(&mat_min_xop, xop_desc, "mat min reduction");
    Perl_custom_op_register(aTHX_ pp_mat_min, &mat_min_xop);
    
    XopENTRY_set(&mat_transpose_xop, xop_name, "mat_transpose");
    XopENTRY_set(&mat_transpose_xop, xop_desc, "mat transpose");
    Perl_custom_op_register(aTHX_ pp_mat_transpose, &mat_transpose_xop);
    
    XopENTRY_set(&mat_matmul_xop, xop_name, "mat_matmul");
    XopENTRY_set(&mat_matmul_xop, xop_desc, "mat matrix multiplication");
    Perl_custom_op_register(aTHX_ pp_mat_matmul, &mat_matmul_xop);
    
    XopENTRY_set(&mat_clone_xop, xop_name, "mat_clone");
    XopENTRY_set(&mat_clone_xop, xop_desc, "mat clone");
    Perl_custom_op_register(aTHX_ pp_mat_clone, &mat_clone_xop);
    
    XopENTRY_set(&mat_neg_xop, xop_name, "mat_neg");
    XopENTRY_set(&mat_neg_xop, xop_desc, "mat negation");
    Perl_custom_op_register(aTHX_ pp_mat_neg, &mat_neg_xop);
    
    XopENTRY_set(&mat_abs_xop, xop_name, "mat_abs");
    XopENTRY_set(&mat_abs_xop, xop_desc, "mat absolute value");
    Perl_custom_op_register(aTHX_ pp_mat_abs, &mat_abs_xop);
    
    XopENTRY_set(&mat_sqrt_xop, xop_name, "mat_sqrt");
    XopENTRY_set(&mat_sqrt_xop, xop_desc, "mat square root");
    Perl_custom_op_register(aTHX_ pp_mat_sqrt, &mat_sqrt_xop);
    
    XopENTRY_set(&mat_exp_xop, xop_name, "mat_exp");
    XopENTRY_set(&mat_exp_xop, xop_desc, "mat exponential");
    Perl_custom_op_register(aTHX_ pp_mat_exp, &mat_exp_xop);
    
    XopENTRY_set(&mat_log_xop, xop_name, "mat_log");
    XopENTRY_set(&mat_log_xop, xop_desc, "mat natural log");
    Perl_custom_op_register(aTHX_ pp_mat_log, &mat_log_xop);
    
    XopENTRY_set(&mat_softmax_rows_inplace_xop, xop_name, "mat_softmax_rows_inplace");
    XopENTRY_set(&mat_softmax_rows_inplace_xop, xop_desc, "mat softmax rows inplace");
    Perl_custom_op_register(aTHX_ pp_mat_softmax_rows_inplace, &mat_softmax_rows_inplace_xop);
    
    XopENTRY_set(&mat_silu_inplace_xop, xop_name, "mat_silu_inplace");
    XopENTRY_set(&mat_silu_inplace_xop, xop_desc, "mat SiLU inplace");
    Perl_custom_op_register(aTHX_ pp_mat_silu_inplace, &mat_silu_inplace_xop);
    
    XopENTRY_set(&mat_gelu_inplace_xop, xop_name, "mat_gelu_inplace");
    XopENTRY_set(&mat_gelu_inplace_xop, xop_desc, "mat GELU inplace");
    Perl_custom_op_register(aTHX_ pp_mat_gelu_inplace, &mat_gelu_inplace_xop);
    
    /* Additional ops */
    XopENTRY_set(&mat_shape_xop, xop_name, "mat_shape");
    XopENTRY_set(&mat_shape_xop, xop_desc, "mat shape");
    Perl_custom_op_register(aTHX_ pp_mat_shape, &mat_shape_xop);
    
    XopENTRY_set(&mat_zeros_like_xop, xop_name, "mat_zeros_like");
    XopENTRY_set(&mat_zeros_like_xop, xop_desc, "mat zeros like");
    Perl_custom_op_register(aTHX_ pp_mat_zeros_like, &mat_zeros_like_xop);
    
    XopENTRY_set(&mat_add_inplace_xop, xop_name, "mat_add_inplace");
    XopENTRY_set(&mat_add_inplace_xop, xop_desc, "mat add inplace");
    Perl_custom_op_register(aTHX_ pp_mat_add_inplace, &mat_add_inplace_xop);
    
    XopENTRY_set(&mat_sub_inplace_xop, xop_name, "mat_sub_inplace");
    XopENTRY_set(&mat_sub_inplace_xop, xop_desc, "mat sub inplace");
    Perl_custom_op_register(aTHX_ pp_mat_sub_inplace, &mat_sub_inplace_xop);
    
    XopENTRY_set(&mat_mul_inplace_xop, xop_name, "mat_mul_inplace");
    XopENTRY_set(&mat_mul_inplace_xop, xop_desc, "mat mul inplace");
    Perl_custom_op_register(aTHX_ pp_mat_mul_inplace, &mat_mul_inplace_xop);
    
    XopENTRY_set(&mat_div_inplace_xop, xop_name, "mat_div_inplace");
    XopENTRY_set(&mat_div_inplace_xop, xop_desc, "mat div inplace");
    Perl_custom_op_register(aTHX_ pp_mat_div_inplace, &mat_div_inplace_xop);
    
    XopENTRY_set(&mat_scale_inplace_xop, xop_name, "mat_scale_inplace");
    XopENTRY_set(&mat_scale_inplace_xop, xop_desc, "mat scale inplace");
    Perl_custom_op_register(aTHX_ pp_mat_scale_inplace, &mat_scale_inplace_xop);
    
    XopENTRY_set(&mat_add_scalar_xop, xop_name, "mat_add_scalar");
    XopENTRY_set(&mat_add_scalar_xop, xop_desc, "mat add scalar");
    Perl_custom_op_register(aTHX_ pp_mat_add_scalar, &mat_add_scalar_xop);
    
    XopENTRY_set(&mat_add_scalar_inplace_xop, xop_name, "mat_add_scalar_inplace");
    XopENTRY_set(&mat_add_scalar_inplace_xop, xop_desc, "mat add scalar inplace");
    Perl_custom_op_register(aTHX_ pp_mat_add_scalar_inplace, &mat_add_scalar_inplace_xop);
    
    XopENTRY_set(&mat_add_scaled_inplace_xop, xop_name, "mat_add_scaled_inplace");
    XopENTRY_set(&mat_add_scaled_inplace_xop, xop_desc, "mat add scaled inplace");
    Perl_custom_op_register(aTHX_ pp_mat_add_scaled_inplace, &mat_add_scaled_inplace_xop);
    
    XopENTRY_set(&mat_row_xop, xop_name, "mat_row");
    XopENTRY_set(&mat_row_xop, xop_desc, "mat row extraction");
    Perl_custom_op_register(aTHX_ pp_mat_row, &mat_row_xop);
    
    XopENTRY_set(&mat_row_sum_xop, xop_name, "mat_row_sum");
    XopENTRY_set(&mat_row_sum_xop, xop_desc, "mat row sum");
    Perl_custom_op_register(aTHX_ pp_mat_row_sum, &mat_row_sum_xop);
    
    XopENTRY_set(&mat_col_sum_xop, xop_name, "mat_col_sum");
    XopENTRY_set(&mat_col_sum_xop, xop_desc, "mat col sum");
    Perl_custom_op_register(aTHX_ pp_mat_col_sum, &mat_col_sum_xop);
    
    XopENTRY_set(&mat_to_array_xop, xop_name, "mat_to_array");
    XopENTRY_set(&mat_to_array_xop, xop_desc, "mat to array");
    Perl_custom_op_register(aTHX_ pp_mat_to_array, &mat_to_array_xop);
    
    /* ============================================
       Install Call Checkers for Optimization
       ============================================ */
    {
        CV *cv;
        
        /* Unary - dimension accessors */
        cv = get_cv("Numeric::Matrix::rows", 0);
        if (cv) cv_set_call_checker(cv, mat_rows_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::cols", 0);
        if (cv) cv_set_call_checker(cv, mat_cols_call_checker, (SV*)cv);
        
        /* Unary - reductions */
        cv = get_cv("Numeric::Matrix::sum", 0);
        if (cv) cv_set_call_checker(cv, mat_sum_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::norm", 0);
        if (cv) cv_set_call_checker(cv, mat_norm_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::max", 0);
        if (cv) cv_set_call_checker(cv, mat_max_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::min", 0);
        if (cv) cv_set_call_checker(cv, mat_min_call_checker, (SV*)cv);
        
        /* Unary - transforms */
        cv = get_cv("Numeric::Matrix::clone", 0);
        if (cv) cv_set_call_checker(cv, mat_clone_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::transpose", 0);
        if (cv) cv_set_call_checker(cv, mat_transpose_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::neg", 0);
        if (cv) cv_set_call_checker(cv, mat_neg_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::abs", 0);
        if (cv) cv_set_call_checker(cv, mat_abs_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::sqrt", 0);
        if (cv) cv_set_call_checker(cv, mat_sqrt_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::exp", 0);
        if (cv) cv_set_call_checker(cv, mat_exp_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::log", 0);
        if (cv) cv_set_call_checker(cv, mat_log_call_checker, (SV*)cv);
        
        /* Unary - activation functions */
        cv = get_cv("Numeric::Matrix::softmax_rows_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_softmax_rows_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::silu_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_silu_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::gelu_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_gelu_inplace_call_checker, (SV*)cv);
        
        /* Binary - element-wise */
        cv = get_cv("Numeric::Matrix::add", 0);
        if (cv) cv_set_call_checker(cv, mat_add_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::sub", 0);
        if (cv) cv_set_call_checker(cv, mat_sub_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::mul", 0);
        if (cv) cv_set_call_checker(cv, mat_mul_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::div", 0);
        if (cv) cv_set_call_checker(cv, mat_div_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::scale", 0);
        if (cv) cv_set_call_checker(cv, mat_scale_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::matmul", 0);
        if (cv) cv_set_call_checker(cv, mat_matmul_call_checker, (SV*)cv);
        
        /* Ternary - element access */
        cv = get_cv("Numeric::Matrix::get", 0);
        if (cv) cv_set_call_checker(cv, mat_get_call_checker, (SV*)cv);
        
        /* Quaternary - element set */
        cv = get_cv("Numeric::Matrix::set", 0);
        if (cv) cv_set_call_checker(cv, mat_set_call_checker, (SV*)cv);
        
        /* Additional unary */
        cv = get_cv("Numeric::Matrix::shape", 0);
        if (cv) cv_set_call_checker(cv, mat_shape_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::zeros_like", 0);
        if (cv) cv_set_call_checker(cv, mat_zeros_like_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::row_sum", 0);
        if (cv) cv_set_call_checker(cv, mat_row_sum_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::col_sum", 0);
        if (cv) cv_set_call_checker(cv, mat_col_sum_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::to_array", 0);
        if (cv) cv_set_call_checker(cv, mat_to_array_call_checker, (SV*)cv);
        
        /* Additional binary (inplace) */
        cv = get_cv("Numeric::Matrix::add_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_add_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::sub_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_sub_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::mul_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_mul_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::div_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_div_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::scale_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_scale_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::add_scalar", 0);
        if (cv) cv_set_call_checker(cv, mat_add_scalar_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::add_scalar_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_add_scalar_inplace_call_checker, (SV*)cv);
        
        cv = get_cv("Numeric::Matrix::row", 0);
        if (cv) cv_set_call_checker(cv, mat_row_call_checker, (SV*)cv);
        
        /* Additional ternary */
        cv = get_cv("Numeric::Matrix::add_scaled_inplace", 0);
        if (cv) cv_set_call_checker(cv, mat_add_scaled_inplace_call_checker, (SV*)cv);
    }
    
#ifdef PERL_IMPLICIT_CONTEXT
    Perl_xs_boot_epilog(aTHX_ ax);
#else  
    Perl_xs_boot_epilog(ax);
#endif
}
