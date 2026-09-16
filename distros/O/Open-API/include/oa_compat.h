#ifndef OA_COMPAT_H
#define OA_COMPAT_H

/* Perl-version portability shims for the C core. Include after EXTERN.h /
 * perl.h / XSUB.h and before any other oa_ header, so the definitions are in
 * scope for the C-closure callbacks throughout the core. */

/* SVfARG is 5.10. On 5.8 the `%" SVf` formats take the SV pointer itself, so
 * the argument wrapper is a cast and nothing more. Defined FIRST because the
 * croak_sv shim below uses it: without this, 5.8 compiles `SVfARG(...)` as an
 * implicit declaration - a warning, then a shared object carrying an
 * undefined symbol, and a failure only when that path is first taken. Found
 * by the docker matrix; every newer perl has the macro and said nothing. */
#ifndef SVfARG
#  define SVfARG(p) ((void *)(p))
#endif

/* XS_INTERNAL / XS_EXTERNAL (and XSPROTO) arrived in perl's XSUB.h at 5.16.
 * The core's C-closure callbacks and the ABI in oa_abi.h are declared with
 * XS_INTERNAL, so on 5.8 - 5.14 they otherwise fail to compile
 * ("XS_INTERNAL undeclared" / "cv undeclared"). These are the standard
 * definitions, and let Open::API build on every perl it claims (5.8.3+). */
#ifndef XSPROTO
#  define XSPROTO(name) void name(pTHX_ CV *cv)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) STATIC XSPROTO(name)
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XSPROTO(name)
#endif

/* mg_findext (5.14) and croak_sv (5.13.1) postdate the oldest perls Open::API
 * claims (5.8.3). The C-closure machinery uses mg_findext to fetch the magic
 * carrying a closure's captures, and a few request paths croak_sv an error.
 * Provide both on pre-5.14 perls; newer perls use the core versions. */
#if PERL_REVISION == 5 && PERL_VERSION < 14

static MAGIC *OpenAPI_mg_findext(SV *sv, int type, const MGVTBL *vtbl) {
    if (sv) {
        MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
            if (mg->mg_type == type && (const MGVTBL *)mg->mg_virtual == vtbl)
                return mg;
    }
    return NULL;
}
#  define mg_findext(sv, type, vtbl) OpenAPI_mg_findext((sv), (type), (vtbl))

#  define croak_sv(sv) Perl_croak(aTHX_ "%" SVf, SVfARG(sv))

#endif

/* hv_deletes is 5.25.6 - much newer than its hv_stores/hv_fetchs siblings,
 * which is easy to miss because the three read as one family. ppport.h does
 * not back-port it either. This is perl's own definition; the "" key ""
 * concatenation is what makes a non-literal key a compile error, exactly as
 * the core macro does. */
#ifndef hv_deletes
#  define hv_deletes(hv, key, flags) \
       hv_delete((hv), ("" key ""), (I32)(sizeof(key) - 1), (flags))
#endif

#endif /* OA_COMPAT_H */
