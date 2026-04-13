/*
 * object_compat.h - Perl compatibility macros for object
 * Supports Perl 5.10.0+ with graceful degradation
 * XOP API (5.14+), fallback to PL_custom_op_names (older)
 * Op sibling navigation (5.22+), refcount macros, and boot macros
 */

#ifndef OBJECT_COMPAT_H
#define OBJECT_COMPAT_H

/* Devel::PPPort compatibility - provides many backported macros */
#include "../ppport.h"

/* Include shared XOP compatibility for custom ops (5.14+ fallback) */
#include "xop_compat.h"

/* XS_INTERNAL - available since 5.16, fallback for older Perls */
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) static XSPROTO(name)
#endif

/* Version checking macro */
#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

/* Compile-time minimum version check - require 5.10.0 for basic features */
#if !PERL_VERSION_GE(5,10,0)
#  error "object requires Perl 5.10.0 or later"
#endif

/* C89/C99/C23 bool compatibility
 * - C89: no bool type, need typedef
 * - C99: bool from <stdbool.h> (macro expanding to _Bool)
 * - C23: bool is a keyword, cannot typedef over it
 *
 * Note: Old Perl defines 'bool' as a macro but not 'true'/'false'
 */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 202311L
   /* C23: bool is a keyword, true/false are keywords - nothing to do */
#elif defined(__bool_true_false_are_defined)
   /* stdbool.h already included with true/false - nothing to do */
#else
   /* bool may or may not be defined by perl.h, but we need true/false */
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

/* C89 inline compatibility - C89 has no inline keyword */
#ifndef OBJECT_INLINE
#  if defined(__GNUC__) || defined(__clang__)
#    define OBJECT_INLINE static __inline__
#  elif defined(_MSC_VER)
#    define OBJECT_INLINE static __inline
#  else
#    define OBJECT_INLINE static
#  endif
#endif

/* OP_AELEMFAST_LEX - introduced in 5.16
 * Don't define fallback - code should check if it exists */

/* op_contextualize - introduced in 5.14, no-op fallback */
#if !PERL_VERSION_GE(5,14,0)
#  define op_contextualize(op, ctx) (op)
#endif

/* wrap_op_checker - introduced in 5.16 */
#if !PERL_VERSION_GE(5,16,0)
#  define wrap_op_checker(opcode, new_checker, old_ptr) \
    do { \
        *(old_ptr) = PL_check[opcode]; \
        PL_check[opcode] = (new_checker); \
    } while(0)
#endif

/* cv_set_call_checker - introduced in 5.14 (5.13.006)
 * No-op fallback: call checkers are an optimization, not required for correctness */
#if !PERL_VERSION_GE(5,14,0)
#  define cv_set_call_checker(cv, checker, ckobj) ((void)0)
#  define OBJECT_HAS_CALL_CHECKER 0
#else
#  define OBJECT_HAS_CALL_CHECKER 1
#endif

/* Backwards compatibility - alias for XOP_COMPAT_HAS_XOP */
#define OBJECT_HAS_XOP XOP_COMPAT_HAS_XOP

/* Op sibling macros - introduced in 5.22 */
#ifndef OpHAS_SIBLING
#  define OpHAS_SIBLING(o)      ((o)->op_sibling != NULL)
#endif

#ifndef OpSIBLING
#  define OpSIBLING(o)          ((o)->op_sibling)
#endif

#ifndef OpMORESIB_set
#  define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
#endif

#ifndef OpLASTSIB_set
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
#endif

/* Refcount macros */
#ifndef SvREFCNT_inc_simple_NN
#  define SvREFCNT_inc_simple_NN(sv) SvREFCNT_inc(sv)
#endif

#ifndef SvREFCNT_dec_NN
#  define SvREFCNT_dec_NN(sv) SvREFCNT_dec(sv)
#endif

/* XS boot macros - introduced in 5.22 */
#ifndef dXSBOOTARGSXSAPIVERCHK
#  define dXSBOOTARGSXSAPIVERCHK dXSARGS
#endif

/* Perl_xs_boot_epilog - introduced in 5.21.6 (use 5.22 as safe boundary)
 * On older perls, just return from the boot function.
 * We define a single-arg wrapper to avoid aTHX_ preprocessing issues:
 * the C preprocessor counts macro args before expanding aTHX_, so
 * Perl_xs_boot_epilog(aTHX_ ax) is seen as 1 arg, not 2. */
#if !PERL_VERSION_GE(5,22,0)
#  ifndef OBJECT_PROTO_XS_BOOT_EPILOG
#    define OBJECT_PROTO_XS_BOOT_EPILOG(ax) XSRETURN_YES
#  endif
#else
#  define OBJECT_PROTO_XS_BOOT_EPILOG(ax) Perl_xs_boot_epilog(aTHX_ ax)
#endif

/* XS_EXTERNAL - introduced in 5.16 */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif

/* Utility macros */
#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(x) ((void)(x))
#endif

#ifndef PERL_UNUSED_ARG
#  define PERL_UNUSED_ARG(x) ((void)(x))
#endif

/* PTR2IV/INT2PTR - should exist but provide fallback */
#ifndef PTR2IV
#  define PTR2IV(p) ((IV)(p))
#endif

#ifndef INT2PTR
#  define INT2PTR(type, i) ((type)(i))
#endif

/* GvCV_set - introduced in 5.13.3 (use 5.14 as safe boundary) */
#ifndef GvCV_set
#  define GvCV_set(gv, cv) (GvCV(gv) = (cv))
#endif

/* HvNAMELEN - introduced in 5.16 */
#ifndef HvNAMELEN
#  define HvNAMELEN(hv) (HvNAME(hv) ? strlen(HvNAME(hv)) : 0)
#endif

/* newXS_flags - may not exist on older perls */
#ifndef newXS_flags
#  define newXS_flags(name, xsub, file, proto, flags) newXS(name, xsub, file)
#endif

#endif /* OBJECT_COMPAT_H */
