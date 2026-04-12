/*
 * nmat_compat.h - Perl compatibility macros for Numeric::Matrix
 */

#ifndef NMAT_COMPAT_H
#define NMAT_COMPAT_H

/* Devel::PPPort compatibility - provides many backported macros */
#include "ppport.h"

/* Include shared XOP compatibility for custom ops (5.14+ fallback) */
#include "xop_compat.h"

/* Version checking macro */
#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

/* C89/C99/C23 bool compatibility */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 202311L
   /* C23: bool is a keyword, true/false are keywords - nothing to do */
#elif defined(__bool_true_false_are_defined)
   /* stdbool.h already included with true/false - nothing to do */
#else
#  ifndef bool
     typedef int bool;
#  endif
#  ifndef true
#    define true 1
#  endif
#  ifndef false
#    define false 0
#  endif
#endif

/* Refcount macros */
#ifndef SvREFCNT_inc_simple_NN
#  define SvREFCNT_inc_simple_NN(sv) SvREFCNT_inc(sv)
#endif

#ifndef SvREFCNT_dec_NN
#  define SvREFCNT_dec_NN(sv) SvREFCNT_dec(sv)
#endif

#ifndef SvREFCNT_inc_simple_void_NN
#  define SvREFCNT_inc_simple_void_NN(sv) SvREFCNT_inc(sv)
#endif

/* XS boot macros - introduced in 5.22 */
#ifndef dXSBOOTARGSXSAPIVERCHK
#  define dXSBOOTARGSXSAPIVERCHK dXSARGS
#endif

/* Perl_xs_boot_epilog - introduced in 5.21.6 (use 5.22 as safe boundary) */
#if !PERL_VERSION_GE(5,22,0)
#  ifndef Perl_xs_boot_epilog
#    ifdef PERL_IMPLICIT_CONTEXT
#      define Perl_xs_boot_epilog(ctx, ax) XSRETURN_YES
#    else
#      define Perl_xs_boot_epilog(ax) XSRETURN_YES
#    endif
#  endif
#endif

/* XS_EXTERNAL - introduced in 5.16 */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif

/* XS_INTERNAL - introduced in 5.16, fallback for older Perls */
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) static XSPROTO(name)
#endif

/* Utility macros */
#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(x) ((void)(x))
#endif

#ifndef PERL_UNUSED_ARG
#  define PERL_UNUSED_ARG(x) ((void)(x))
#endif

/* mg_findext - introduced in 5.14 */
#if !PERL_VERSION_GE(5,14,0)
static MAGIC* nmat_compat_mg_findext(pTHX_ SV *sv, int type, const MGVTBL *vtbl) {
    MAGIC *mg;
    PERL_UNUSED_ARG(vtbl);
    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == type) {
            return mg;
        }
    }
    return NULL;
}
#  define mg_findext(sv, type, vtbl) nmat_compat_mg_findext(aTHX_ sv, type, vtbl)
#endif

/* Gv_AMupdate signature changed in 5.12 */
#if !PERL_VERSION_GE(5,12,0)
#  define Gv_AMupdate_compat(stash, destructing) Gv_AMupdate(stash)
#else
#  define Gv_AMupdate_compat(stash, destructing) Gv_AMupdate(stash, destructing)
#endif

/* ============================================
   Platform-specific alignment
   ============================================ */

/* 64-byte alignment for cache line optimization and AVX-512 */
#define NMAT_ALIGNMENT 64

#ifdef _WIN32
#  include <malloc.h>
#  define nmat_aligned_alloc(alignment, size) _aligned_malloc(size, alignment)
#  define nmat_aligned_free(ptr) _aligned_free(ptr)
#else
#  include <stdlib.h>
   static inline void* nmat_aligned_alloc(size_t alignment, size_t size) {
       void *ptr = NULL;
       if (posix_memalign(&ptr, alignment, size) != 0) return NULL;
       return ptr;
   }
#  define nmat_aligned_free(ptr) free(ptr)
#endif

/* ============================================
   SIMD detection (compile-time)
   ============================================ */

/* ARM NEON */
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#  define NMAT_HAVE_NEON 1
#  include <arm_neon.h>
#else
#  define NMAT_HAVE_NEON 0
#endif

/* x86 AVX2 */
#if defined(__AVX2__)
#  define NMAT_HAVE_AVX2 1
#  include <immintrin.h>
#else
#  define NMAT_HAVE_AVX2 0
#endif

/* x86 AVX */
#if defined(__AVX__)
#  define NMAT_HAVE_AVX 1
#  ifndef NMAT_HAVE_AVX2
#    include <immintrin.h>
#  endif
#else
#  define NMAT_HAVE_AVX 0
#endif

/* x86 SSE2 */
#if defined(__SSE2__) || defined(_M_X64) || (defined(_M_IX86_FP) && _M_IX86_FP >= 2)
#  define NMAT_HAVE_SSE2 1
#  ifndef NMAT_HAVE_AVX
#    include <emmintrin.h>
#  endif
#else
#  define NMAT_HAVE_SSE2 0
#endif

/* ============================================
   BLAS detection (set by Makefile.PL)
   ============================================ */

#ifndef NMAT_HAVE_BLAS
#  define NMAT_HAVE_BLAS 0
#endif

#if NMAT_HAVE_BLAS
#  ifdef __APPLE__
#    include <Accelerate/Accelerate.h>
#  else
#    include <cblas.h>
#  endif
#endif

#endif /* NMAT_COMPAT_H */
