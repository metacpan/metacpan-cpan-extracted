/* pmcp_compat.h - what the 5.10 floor costs.
 *
 * Needs: the perl headers. Include before everything else under pmcp/.
 *
 * Every shim here is dead code on a modern perl, which is the problem with
 * shims: they are compiled only on the machines nobody develops on, and they
 * rot silently in between. Where one can be compiled unconditionally it is
 * (pmcp_croak_sv), and t/02 drives it.
 *
 * The floor is 5.010, which is 5.10.0, not 5.10.1. HeUTF8 and mPUSHs/mXPUSHs
 * are 5.10.1 macros and the docker 5.10 images are 5.10.1, so nothing local
 * catches their absence (memory: the 5010 floor is 5.10.0).
 */

#ifndef PMCP_COMPAT_H
#define PMCP_COMPAT_H

/* G_LIST is the 5.36 name for G_ARRAY. */
#ifndef G_LIST
#  define G_LIST G_ARRAY
#endif

/* XS_INTERNAL is 5.16+. */
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) static void name(pTHX_ CV *cv)
#endif

#ifndef HeUTF8
#  define HeUTF8(he) ((HeKLEN(he) == HEf_SVKEY) \
                      ? SvUTF8(HeKEY_sv(he)) : (U32)HeKUTF8(he))
#endif
#ifndef mPUSHs
#  define mPUSHs(s) PUSHs(sv_2mortal(s))
#endif
#ifndef mXPUSHs
#  define mXPUSHs(s) XPUSHs(sv_2mortal(s))
#endif

/* mg_findext is 5.14+, and the closures in pmcp_clos.h are built on it. The
 * dist calls this one on every perl rather than the native one where it
 * exists, so the code that ships is the code that is tested. */
static MAGIC *
pmcp_mg_findext(pTHX_ const SV *sv, int type, const MGVTBL *vtbl)
{
    PERL_UNUSED_CONTEXT;
    if (sv && SvTYPE(sv) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type == type && mg->mg_virtual == vtbl)
                return mg;
        }
    }
    return NULL;
}

/* croak_sv is 5.14+. ppport's two branches, both needed: a reference goes out
 * through ERRSV so a blessed exception stays blessed, and a string goes through
 * croak's format so it gains " at FILE line N." the way croak_sv would add it.
 * One branch alone passes every test on a modern perl and is wrong on the old
 * ones (memory: croak_sv shims). Called on every perl, as above, and t/02
 * drives both branches. */
static void
pmcp_croak_sv(pTHX_ SV *sv)
{
    if (SvROK(sv)) {
        sv_setsv(ERRSV, sv);
        croak(NULL);
    }
    croak("%" SVf, SVfARG(sv));
}

#endif /* PMCP_COMPAT_H */
