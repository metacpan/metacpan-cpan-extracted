/*
 * djbsort_dispatch.c - Provides all djbsort_* public API functions
 * for the portable (non-SIMD) build bundled in Sort::DJB.
 *
 * The internal sort files define functions like uint32_sort(), float32_sort(),
 * etc. This file provides the djbsort_* wrappers that call them, plus the
 * metadata functions (version, arch, implementation).
 *
 * Note: djbsort_int32 and djbsort_int64 are provided directly by int32_sort.c
 * and int64_sort.c via the #define in their headers (int32_sort -> djbsort_int32).
 */

#include <inttypes.h>
#include <string.h>
#include "djbsort.h"

/* Internal sort function declarations */
extern void uint32_sort(uint32_t *, long long);
extern void uint32down_sort(uint32_t *, long long);
extern void int32down_sort(int32_t *, long long);
extern void float32_sort(float *, long long);
extern void float32down_sort(float *, long long);
extern void uint64_sort(uint64_t *, long long);
extern void uint64down_sort(uint64_t *, long long);
extern void int64down_sort(int64_t *, long long);
extern void float64_sort(double *, long long);
extern void float64down_sort(double *, long long);

/* Wrappers: call internal functions with djbsort_ prefix */
void djbsort_uint32(uint32_t *x, long long n) { uint32_sort(x, n); }
void djbsort_uint32down(uint32_t *x, long long n) { uint32down_sort(x, n); }
void djbsort_int32down(int32_t *x, long long n) { int32down_sort(x, n); }
void djbsort_float32(float *x, long long n) { float32_sort(x, n); }
void djbsort_float32down(float *x, long long n) { float32down_sort(x, n); }
void djbsort_uint64(uint64_t *x, long long n) { uint64_sort(x, n); }
void djbsort_uint64down(uint64_t *x, long long n) { uint64down_sort(x, n); }
void djbsort_int64down(int64_t *x, long long n) { int64down_sort(x, n); }
void djbsort_float64(double *x, long long n) { float64_sort(x, n); }
void djbsort_float64down(double *x, long long n) { float64down_sort(x, n); }

/* Metadata */
const char *djbsort_version(void) { return "20260210"; }
const char *djbsort_arch(void) { return "portable"; }
void djbsort_cpuid(unsigned int *result, long long resultlen) {
    if (resultlen > 0) memset(result, 0, resultlen * sizeof(unsigned int));
}

/* Implementation info for the portable build */
const char *djbsort_int32_implementation(void) { return "portable4"; }
const char *djbsort_int32_compiler(void) { return "bundled"; }
const char *djbsort_int64_implementation(void) { return "portable4"; }
const char *djbsort_int64_compiler(void) { return "bundled"; }
long long djbsort_numimpl_int32(void) { return 1; }
long long djbsort_numimpl_int64(void) { return 1; }

/* Stub dispatch functions (portable has only one implementation) */
void (*djbsort_dispatch_int32(long long n))(int32_t *, long long) {
    (void)n; return djbsort_int32;
}
void (*djbsort_dispatch_int64(long long n))(int64_t *, long long) {
    (void)n; return djbsort_int64;
}
