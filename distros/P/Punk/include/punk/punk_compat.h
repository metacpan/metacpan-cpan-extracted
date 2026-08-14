#ifndef PUNK_COMPAT_H
#define PUNK_COMPAT_H

/* Perl-version portability shims for the C core, so Punk builds on every perl
 * it claims (5.10.0+). Include after EXTERN.h / perl.h / XSUB.h and before any
 * other punk/ header, so the definitions are in scope everywhere below.
 *
 * Each shim is the standard definition of the thing it stands in for; on a
 * perl new enough to have the real one, none of this is compiled. */

/* XS_INTERNAL / XS_EXTERNAL (and XSPROTO) arrived in perl's XSUB.h at 5.16.
 * The C-closure callbacks (punk_static.h, punk_oamount.h, punk_model.h,
 * punk_compile.h, punk_sse.h, punk_future.h) are declared XS_INTERNAL, so
 * without these they fail with "XS_INTERNAL undeclared" / "cv undeclared". */
#ifndef XSPROTO
#  define XSPROTO(name) void name(pTHX_ CV *cv)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) STATIC XSPROTO(name)
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XSPROTO(name)
#endif

/* mg_findext (5.14) and croak_sv (5.13.1). punk_static.h uses mg_findext to
 * reach the magic carrying a closure's captures; the view tier, the websocket
 * handshake and Punk::Future croak_sv an error SV they were handed. */
#if PERL_REVISION == 5 && PERL_VERSION < 14

static MAGIC *Punk_mg_findext(SV *sv, int type, const MGVTBL *vtbl) {
    if (sv) {
        MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
            if (mg->mg_type == type && (const MGVTBL *)mg->mg_virtual == vtbl)
                return mg;
    }
    return NULL;
}
#  define mg_findext(sv, type, vtbl) Punk_mg_findext((sv), (type), (vtbl))

#  define croak_sv(sv) Perl_croak(aTHX_ "%" SVf, SVfARG(sv))

#endif

/* isWORDCHAR is the 5.14 spelling of what older perls call isALNUM. Both mean
 * [0-9A-Za-z_] here: every caller (route methods, extension sniffs, the mount
 * path scanner) is testing a single ASCII byte. */
#ifndef isWORDCHAR
#  define isWORDCHAR(c) isALNUM(c)
#endif

/* foldEQ is 5.13.2; before that the same function is spelled ibcmp, with the
 * opposite sense (ibcmp returns 0 when the strings match case-insensitively).
 * xs/response.xs uses it to compare a header name. */
#ifndef foldEQ
#  define foldEQ(a, b, len) (!ibcmp((a), (b), (len)))
#endif

/* mPUSHs / mXPUSHs are 5.10.1, one point release above the floor this dist
 * declares. Perl's own definitions. */
#ifndef mPUSHs
#  define mPUSHs(s) PUSHs(sv_2mortal(s))
#endif
#ifndef mXPUSHs
#  define mXPUSHs(s) XPUSHs(sv_2mortal(s))
#endif

/* A true value for a set-membership slot, that the container may own.
 *
 * &PL_sv_yes must never be stored bare: hv_store and friends take over a
 * reference, and the matching decrement when the hash is freed lands on an
 * immortal that nobody incremented. From perl 5.20 the immortals shrug that
 * off; before it the refcount really does walk down to zero and the next
 * thing to touch yes/no/undef segfaults. Taking the reference first costs
 * nothing - it is still the same singleton, with no allocation - and keeps
 * the books straight on every perl. See t/42-immortal-refcount.t. */
#define PUNK_SET_TRUE SvREFCNT_inc_simple_NN(&PL_sv_yes)

#endif /* PUNK_COMPAT_H */
