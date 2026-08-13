/*
 * strigram_compat.h - backwards compatibility for Trigram.xs
 * Supports Perl 5.10+ with graceful degradation:
 *   - XOP API / custom op registration (5.14+, falls back to PL_custom_op_names)
 *   - cv_set_call_checker (5.14+, no-op on older perls)
 *   - Op sibling navigation macros (5.22+, falls back to op_sibling field)
 *   - newSVpvn_flags (5.10.1+, falls back to newSVpvn + SvUTF8_on)
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

/* newSVpvn_flags - added in 5.10.1, so a build against 5.10.0 links but dies
 * with "undefined symbol: newSVpvn_flags" the first time a search returns a
 * hit. Only SVf_UTF8 and SVs_TEMP are honoured, which is all Trigram.xs asks
 * for. */
#if (PERL_REVISION == 5 && (PERL_VERSION < 10 \
     || (PERL_VERSION == 10 && PERL_SUBVERSION < 1)))
static SV *
strigram_newSVpvn_flags(pTHX_ const char *s, STRLEN len, U32 flags) {
    SV *sv = newSVpvn(s, len);
    if (s && (flags & SVf_UTF8)) SvUTF8_on(sv);
    if (flags & SVs_TEMP)        sv = sv_2mortal(sv);
    return sv;
}
#  undef  newSVpvn_flags
#  define newSVpvn_flags(s, len, flags) \
       strigram_newSVpvn_flags(aTHX_ (s), (len), (flags))
#endif

/* Utility fallbacks */
#ifndef PERL_UNUSED_ARG
#  define PERL_UNUSED_ARG(x) ((void)(x))
#endif

#ifndef INT2PTR
#  define INT2PTR(type, i) ((type)(i))
#endif

#endif /* STRIGRAM_COMPAT_H */
