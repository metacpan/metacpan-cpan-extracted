#ifndef PCHAL_COMPAT_H
#define PCHAL_COMPAT_H

/* What the 5.10 floor costs.
 *
 * Every shim here is dead code on a modern perl, which is the problem with
 * shims: they are compiled only on the machines nobody develops on, and they
 * rot silently in between. They live in a header rather than inline in
 * Challenge.xs so that a scratch translation unit can #undef the macros and
 * compile them on purpose.
 *
 * Include before everything else under pchal/.
 */

/* G_LIST is the 5.36 name for G_ARRAY. Unguarded it breaks the build on
 * everything older, which is most of the smokers. */
#ifndef G_LIST
#define G_LIST G_ARRAY
#endif

/* XS_INTERNAL is 5.16+. */
#ifndef XS_INTERNAL
#define XS_INTERNAL(name) static void name(pTHX_ CV *cv)
#endif

/* mg_findext is 5.14+, and the closures in pchal_clos.h are built on it.
 *
 * The real one walks the same chain; the only thing this cannot do is find
 * magic that perl has not yet upgraded the SV for, which does not arise
 * because we attached it ourselves. */
#ifndef mg_findext
static MAGIC *
pchal_mg_findext(pTHX_ const SV *sv, int type, const MGVTBL *vtbl)
{
    PERL_UNUSED_CONTEXT;
    if (sv) {
        MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type == type && mg->mg_virtual == vtbl)
                return mg;
        }
    }
    return NULL;
}
#define mg_findext(sv, type, vtbl) pchal_mg_findext(aTHX_ (sv), (type), (vtbl))
#endif

/* PERL_UNUSED_CONTEXT is what to spell on a perl built without
 * MULTIPLICITY, where there is no my_perl to mark unused. Old perls lack
 * the macro itself. */
#ifndef PERL_UNUSED_CONTEXT
#  ifdef PERL_IMPLICIT_CONTEXT
#    define PERL_UNUSED_CONTEXT PERL_UNUSED_VAR(my_perl)
#  else
#    define PERL_UNUSED_CONTEXT NOOP
#  endif
#endif

#endif /* PCHAL_COMPAT_H */
