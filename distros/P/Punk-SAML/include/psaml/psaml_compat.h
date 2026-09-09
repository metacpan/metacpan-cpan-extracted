#ifndef PSAML_COMPAT_H
#define PSAML_COMPAT_H

/* Perl-version portability shims, so the dist builds on every perl it
 * claims (5.10.0+). Include after EXTERN.h / perl.h / XSUB.h / ppport.h
 * and before any psaml/ header, so the definitions are in scope
 * everywhere below. Each shim is the standard definition of the thing it
 * stands in for; on a perl new enough to have the real one, none of it is
 * compiled. ppport.h already covers av_count, mPUSHs and newSVpvn_flags.
 *
 * An XS floor is a claim until an old perl compiles it. Phase 11 has the
 * proof; nothing here is believed until then. */

/* XS_INTERNAL / XS_EXTERNAL (and XSPROTO) arrived in XSUB.h at 5.16. */
#ifndef XSPROTO
#  define XSPROTO(name) void name(pTHX_ CV *cv)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) STATIC XSPROTO(name)
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XSPROTO(name)
#endif

/* G_LIST is the 5.36 spelling of G_ARRAY. Unguarded it is not a test
 * failure, it is a build failure, which is worse: nothing runs to
 * report it. */
#ifndef G_LIST
#  define G_LIST G_ARRAY
#endif

#ifndef PERL_STATIC_INLINE
#  define PERL_STATIC_INLINE static
#endif

/* mg_findext arrived at 5.14. The fallback walks the chain itself and
 * matches on the type AND the vtable, which is the whole point of the
 * ext variant: two extensions can both use PERL_MAGIC_ext on one SV and
 * each must find only its own. */
#if (PERL_REVISION == 5 && PERL_VERSION < 14)
PERL_STATIC_INLINE MAGIC *
psaml_mg_findext(SV *sv, int type, const MGVTBL *vtbl) {
  MAGIC *mg;
  if (!sv || !SvMAGICAL(sv)) return NULL;
  for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
    if (mg->mg_type == type && mg->mg_virtual == vtbl) return mg;
  return NULL;
}
#  define mg_findext(sv, type, vtbl) psaml_mg_findext(sv, type, vtbl)
#endif

/* croak_sv is 5.13.1 and later, and this dist needs it on every perl:
 * every check in phase 6 throws a blessed Punk::SAML::Error rather than
 * a string, and a flattened exception has no `code` to assert on.
 *
 * This is ppport's shim, and it is TWO branches. Every dist in this
 * family hand-rolled it once and each got a different half wrong:
 *
 *   - `croak(NULL)` raises ERRSV verbatim, which is exactly right for a
 *     blessed error and keeps it blessed. Written as the only branch it
 *     drops the " at FILE line N.\n" from plain strings, and it does so
 *     only on the old perls that actually select the shim, so it passes
 *     everywhere you can test and fails on a smoker.
 *   - `croak("%" SVf, ...)` lets croak append the location, which is
 *     right for a string. Written as the only branch it FLATTENS a
 *     blessed exception to its stringification on perl < 5.14, which is
 *     the half that would break this dist specifically.
 *
 * psaml_croak_sv is compiled unconditionally and named separately from
 * the macro, so the shim body is exercised on every perl through
 * Punk::SAML::_croak_sv_selftest rather than shipping unrun. Be honest
 * about what that buys: it catches crashes, wrong types and
 * ref-flattening anywhere, but it cannot catch the location-dropping
 * half, because on a modern perl the wrong shim passes those assertions
 * too. That half is only ever provable on a smoker. */
PERL_STATIC_INLINE void
psaml_croak_sv(pTHX_ SV *sv) {
  if (sv && SvROK(sv)) {
    sv_setsv(ERRSV, sv);
    Perl_croak(aTHX_ NULL);
  }
  Perl_croak(aTHX_ "%" SVf, SVfARG(sv ? sv : &PL_sv_undef));
}

#ifndef croak_sv
#  define croak_sv(sv) psaml_croak_sv(aTHX_ (sv))
#endif

/* PERL_UNUSED_ARG(my_perl) is a build error, not a warning: under a
 * threaded perl my_perl is not an ordinary identifier and the expansion
 * is not an expression. The spelling for an unused interpreter context
 * is PERL_UNUSED_CONTEXT, written out here because this family has got
 * it wrong before. */
#ifndef PERL_UNUSED_CONTEXT
#  define PERL_UNUSED_CONTEXT
#endif

/* The owner string, here rather than in psaml_reg.h because every header
 * below croaks with it and the include order should not decide who can. */
#define PSAML_WHO "Punk::Plugin::SAML"

#endif /* PSAML_COMPAT_H */
