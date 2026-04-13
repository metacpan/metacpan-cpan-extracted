/*

The stable djbsort API functions are as follows:

    void djbsort_int32(int32_t *,long long);
    void djbsort_int32down(int32_t *,long long);
    void djbsort_uint32(uint32_t *,long long);
    void djbsort_uint32down(uint32_t *,long long);
    void djbsort_float32(float *,long long);
    void djbsort_float32down(float *,long long);

    void djbsort_int64(int32_t *,long long);
    void djbsort_int64down(int32_t *,long long);
    void djbsort_uint64(uint32_t *,long long);
    void djbsort_uint64down(uint32_t *,long long);
    void djbsort_float64(double *,long long);
    void djbsort_float64down(double *,long long);

All other functions (e.g., functions used for internal tests and
benchmarks) may change.

*/

#ifndef djbsort_h
#define djbsort_h

#ifdef __cplusplus
extern "C" {
#endif

#include <inttypes.h>

extern void djbsort_cpuid(unsigned int *,long long);
extern const char *djbsort_version(void);
extern const char *djbsort_arch(void);

extern void djbsort_int32(int32_t *,long long);
extern void (*djbsort_dispatch_int32(long long))(int32_t *,long long);

extern const char *djbsort_int32_implementation(void);
extern const char *djbsort_int32_compiler(void);
extern const char *djbsort_dispatch_int32_implementation(long long);
extern const char *djbsort_dispatch_int32_compiler(long long);
extern long long djbsort_numimpl_int32(void);

extern void djbsort_int32down(int32_t *,long long);
extern void (*djbsort_dispatch_int32down(long long))(int32_t *,long long);

extern const char *djbsort_int32down_implementation(void);
extern const char *djbsort_int32down_compiler(void);
extern const char *djbsort_dispatch_int32down_implementation(long long);
extern const char *djbsort_dispatch_int32down_compiler(long long);
extern long long djbsort_numimpl_int32down(void);

extern void djbsort_uint32(uint32_t *,long long);
extern void (*djbsort_dispatch_uint32(long long))(uint32_t *,long long);

extern const char *djbsort_uint32_implementation(void);
extern const char *djbsort_uint32_compiler(void);
extern const char *djbsort_dispatch_uint32_implementation(long long);
extern const char *djbsort_dispatch_uint32_compiler(long long);
extern long long djbsort_numimpl_uint32(void);

extern void djbsort_uint32down(uint32_t *,long long);
extern void (*djbsort_dispatch_uint32down(long long))(uint32_t *,long long);

extern const char *djbsort_uint32down_implementation(void);
extern const char *djbsort_uint32down_compiler(void);
extern const char *djbsort_dispatch_uint32down_implementation(long long);
extern const char *djbsort_dispatch_uint32down_compiler(long long);
extern long long djbsort_numimpl_uint32down(void);

extern void djbsort_float32(float *,long long);
extern void (*djbsort_dispatch_float32(long long))(float *,long long);

extern const char *djbsort_float32_implementation(void);
extern const char *djbsort_float32_compiler(void);
extern const char *djbsort_dispatch_float32_implementation(long long);
extern const char *djbsort_dispatch_float32_compiler(long long);
extern long long djbsort_numimpl_float32(void);

extern void djbsort_float32down(float *,long long);
extern void (*djbsort_dispatch_float32down(long long))(float *,long long);

extern const char *djbsort_float32down_implementation(void);
extern const char *djbsort_float32down_compiler(void);
extern const char *djbsort_dispatch_float32down_implementation(long long);
extern const char *djbsort_dispatch_float32down_compiler(long long);
extern long long djbsort_numimpl_float32down(void);

extern void djbsort_int64(int64_t *,long long);
extern void (*djbsort_dispatch_int64(long long))(int64_t *,long long);

extern const char *djbsort_int64_implementation(void);
extern const char *djbsort_int64_compiler(void);
extern const char *djbsort_dispatch_int64_implementation(long long);
extern const char *djbsort_dispatch_int64_compiler(long long);
extern long long djbsort_numimpl_int64(void);

extern void djbsort_int64down(int64_t *,long long);
extern void (*djbsort_dispatch_int64down(long long))(int64_t *,long long);

extern const char *djbsort_int64down_implementation(void);
extern const char *djbsort_int64down_compiler(void);
extern const char *djbsort_dispatch_int64down_implementation(long long);
extern const char *djbsort_dispatch_int64down_compiler(long long);
extern long long djbsort_numimpl_int64down(void);

extern void djbsort_uint64(uint64_t *,long long);
extern void (*djbsort_dispatch_uint64(long long))(uint64_t *,long long);

extern const char *djbsort_uint64_implementation(void);
extern const char *djbsort_uint64_compiler(void);
extern const char *djbsort_dispatch_uint64_implementation(long long);
extern const char *djbsort_dispatch_uint64_compiler(long long);
extern long long djbsort_numimpl_uint64(void);

extern void djbsort_uint64down(uint64_t *,long long);
extern void (*djbsort_dispatch_uint64down(long long))(uint64_t *,long long);

extern const char *djbsort_uint64down_implementation(void);
extern const char *djbsort_uint64down_compiler(void);
extern const char *djbsort_dispatch_uint64down_implementation(long long);
extern const char *djbsort_dispatch_uint64down_compiler(long long);
extern long long djbsort_numimpl_uint64down(void);

extern void djbsort_float64(double *,long long);
extern void (*djbsort_dispatch_float64(long long))(double *,long long);

extern const char *djbsort_float64_implementation(void);
extern const char *djbsort_float64_compiler(void);
extern const char *djbsort_dispatch_float64_implementation(long long);
extern const char *djbsort_dispatch_float64_compiler(long long);
extern long long djbsort_numimpl_float64(void);

extern void djbsort_float64down(double *,long long);
extern void (*djbsort_dispatch_float64down(long long))(double *,long long);

extern const char *djbsort_float64down_implementation(void);
extern const char *djbsort_float64down_compiler(void);
extern const char *djbsort_dispatch_float64down_implementation(long long);
extern const char *djbsort_dispatch_float64down_compiler(long long);
extern long long djbsort_numimpl_float64down(void);

#ifdef __cplusplus
}
#endif

#endif
