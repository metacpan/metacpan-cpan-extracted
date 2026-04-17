/*
 * xop_compat.h - XOP API backwards compatibility for custom ops
 *
 * Include this in any XS module that uses custom ops.
 * Provides fallback to PL_custom_op_names/PL_custom_op_descs for pre-5.14 Perl.
 *
 * Usage:
 *   #include "xop_compat.h"
 *
 *   // Then use XopENTRY_set and Perl_custom_op_register as normal
 *   // On pre-5.14, they'll use the deprecated interface automatically
 */

#ifndef XOP_COMPAT_H
#define XOP_COMPAT_H

/* Version checking macro */
#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

/* ============================================
   XOP API compatibility (5.14+)
   For older Perls, use deprecated PL_custom_op_names/PL_custom_op_descs
   ============================================ */

#if PERL_VERSION_GE(5,14,0)
/* Modern XOP API available - OBJECT_HAS_XOP flag for conditional code */
#  define XOP_COMPAT_HAS_XOP 1
#else
/* Pre-5.14: use deprecated custom op interface */
#  define XOP_COMPAT_HAS_XOP 0

/* Dummy XOP struct for pre-5.14 (stores name/desc for registration) */
#  ifndef XOP_DEFINED_BY_COMPAT
#    define XOP_DEFINED_BY_COMPAT 1
typedef struct {
    const char *xop_name;
    const char *xop_desc;
} XOP;
#  endif

/* XopENTRY_set stores values in our dummy struct
 * Modern Perl passes xop_name/xop_desc as the field, so we use it directly
 * For xop_class on pre-5.14, it's a no-op since we don't have the real API */
#  ifndef XopENTRY_set
#    define XopENTRY_set(xop, field, value) \
        XopENTRY_set_impl_##field(xop, value)
#    define XopENTRY_set_impl_xop_name(xop, value) do { (xop)->xop_name = (value); } while(0)
#    define XopENTRY_set_impl_xop_desc(xop, value) do { (xop)->xop_desc = (value); } while(0)
#    define XopENTRY_set_impl_xop_class(xop, value) do { /* no-op on pre-5.14 */ } while(0)
#  endif

/* Fallback custom op registration using deprecated interface
 * 
 * IMPORTANT: The C preprocessor counts macro arguments BEFORE expanding aTHX_.
 * So Perl_custom_op_register(aTHX_ ppfunc, xop) is seen as 2 args, not 3.
 * 
 * We use a variadic macro to handle both threaded and non-threaded cases.
 * The helper function then uses pTHX to get the interpreter context.
 */
#  ifndef Perl_custom_op_register
#    define Perl_custom_op_register(...) xop_compat_register_custom_op(__VA_ARGS__)
#  endif

static void xop_compat_register_custom_op(pTHX_ Perl_ppaddr_t ppfunc, XOP *xop) {
    /*
     * The deprecated PL_custom_op_names/PL_custom_op_descs interface
     * uses the pp function pointer address as the hash key.
     * This interface is still supported but discouraged in newer Perls.
     */
    if (!PL_custom_op_names) {
        PL_custom_op_names = newHV();
    }
    if (!PL_custom_op_descs) {
        PL_custom_op_descs = newHV();
    }
    hv_store(PL_custom_op_names, (char*)&ppfunc, sizeof(ppfunc), newSVpv(xop->xop_name, 0), 0);
    hv_store(PL_custom_op_descs, (char*)&ppfunc, sizeof(ppfunc), newSVpv(xop->xop_desc, 0), 0);
}

#endif /* PERL_VERSION_GE(5,14,0) */

/* ============================================
   Call checker compatibility (5.14+)
   cv_set_call_checker was added in 5.14
   ============================================ */

#if !PERL_VERSION_GE(5,14,0)
/*
 * Pre-5.14: cv_set_call_checker doesn't exist
 * We provide a no-op fallback - optimizations won't happen but code still works
 */
#  ifndef cv_set_call_checker
#    define cv_set_call_checker(cv, checker, ckobj) /* no-op on pre-5.14 */
#  endif
#endif

#endif /* XOP_COMPAT_H */
