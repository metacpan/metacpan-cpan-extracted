#ifndef STENCIL_H
#define STENCIL_H

#define PERL_NO_GET_CONTEXT

/* Under PERL_IMPLICIT_SYS (every threaded Windows perl) XSUB.h rewrites the
 * CRT names - malloc/free/stat/open/read/close - into (*my_perl->IMem)->...
 * calls, which do not compile in the plain C core where there is no pTHX in
 * scope, and would in any case route the arena through a per-interpreter
 * allocator that a differently-owned thread may not free. The core owns its
 * memory and its file reads outright, so opt out of the rewrite; the XS layer
 * still takes aTHX everywhere it touches an SV. Also set from Makefile.PL so
 * it holds even if a TU reaches XSUB.h before this header. */
#ifndef NO_XSLOCKS
#  define NO_XSLOCKS
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdint.h>

#define STENCIL_VERSION_MAJOR 0
#define STENCIL_VERSION_MINOR 1
#define STENCIL_VERSION_STRING "0.01"

#ifdef STENCIL_HAVE_BUILTIN_EXPECT
#  define STENCIL_LIKELY(x)   __builtin_expect(!!(x), 1)
#  define STENCIL_UNLIKELY(x) __builtin_expect(!!(x), 0)
#else
#  define STENCIL_LIKELY(x)   (x)
#  define STENCIL_UNLIKELY(x) (x)
#endif

#ifdef _MSC_VER
#  define STENCIL_INLINE static __inline
#else
#  define STENCIL_INLINE static inline
#endif

/* sv_eq_flags/sv_cmp_flags arrived in 5.13.6 and ppport.h does not
 * back-port them. The VM only ever passes flags=0, because its operands
 * come off the value stack already fetched and non-magical; for those the
 * older sv_eq/sv_cmp take the identical path - their get-magic check just
 * falls through. */
#if !PERL_VERSION_GE(5,14,0)
#  define sv_eq_flags(a, b, f)  sv_eq(a, b)
#  define sv_cmp_flags(a, b, f) sv_cmp(a, b)
#endif

/* cv_set_call_checker/ck_entersub_args_list landed in 5.13.6 and ppport.h
 * cannot back-port them (they need core op-tree internals). Below that the
 * statically-resolved fast path is simply not installed and every call goes
 * through the ordinary XSUB - same results, one prologue slower. */
#if PERL_VERSION_GE(5,14,0)
#  define STENCIL_HAVE_CALL_CHECKER 1
#endif

#include "stencil_types.h"
#include "stencil_arena.h"
#include "stencil_buf.h"
#include "stencil_escape.h"
#include "stencil_compile.h"
#include "stencil_render.h"
#include "stencil_engine.h"
#include "stencil_filters.h"

#endif /* STENCIL_H */
