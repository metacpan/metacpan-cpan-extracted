/*
 * strigram_compat.h - backwards compatibility for Trigram.xs
 * Supports Perl 5.10+ with graceful degradation:
 *   - XOP API / custom op registration (5.14+, falls back to PL_custom_op_names)
 *   - cv_set_call_checker (5.14+, no-op on older perls)
 *   - Op sibling navigation macros (5.22+, falls back to op_sibling field)
 */

#ifndef STRIGRAM_COMPAT_H
#define STRIGRAM_COMPAT_H

/* XOP API + cv_set_call_checker compat */
#include "xop_compat.h"

/* Op sibling navigation macros — introduced in 5.22 */
#ifndef OpHAS_SIBLING
#  define OpHAS_SIBLING(o)         ((o)->op_sibling != NULL)
#endif

#ifndef OpSIBLING
#  define OpSIBLING(o)             ((o)->op_sibling)
#endif

#ifndef OpMORESIB_set
#  define OpMORESIB_set(o, sib)    ((o)->op_sibling = (sib))
#endif

#ifndef OpLASTSIB_set
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
#endif

/* Utility fallbacks */
#ifndef PERL_UNUSED_ARG
#  define PERL_UNUSED_ARG(x) ((void)(x))
#endif

#ifndef INT2PTR
#  define INT2PTR(type, i) ((type)(i))
#endif

#endif /* STRIGRAM_COMPAT_H */
