#ifndef STENCIL_H
#define STENCIL_H

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

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

#include "stencil_types.h"
#include "stencil_arena.h"
#include "stencil_buf.h"
#include "stencil_escape.h"
#include "stencil_compile.h"
#include "stencil_render.h"
#include "stencil_engine.h"
#include "stencil_filters.h"

#endif /* STENCIL_H */
