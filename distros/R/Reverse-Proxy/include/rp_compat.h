#ifndef RP_COMPAT_H
#define RP_COMPAT_H

/* Perl-version portability shims for the C core. Include after EXTERN.h /
 * perl.h / XSUB.h and before anything that declares a C-closure callback. */

/* XS_INTERNAL / XS_EXTERNAL (and XSPROTO) arrived in perl's XSUB.h at 5.16.
 * The C-closure callbacks (rp_stream_cb, rp_app_cb) are declared with
 * XS_INTERNAL, so on 5.8 - 5.14 they otherwise fail to compile
 * ("XS_INTERNAL undeclared" / "cv undeclared"). These are the standard
 * definitions, and let Reverse::Proxy build on every perl it claims. */
#ifndef XSPROTO
#  define XSPROTO(name) void name(pTHX_ CV *cv)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) STATIC XSPROTO(name)
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XSPROTO(name)
#endif

/* mg_findext (5.14) postdates the oldest perls this dist claims. The
 * C-closure machinery uses it to fetch the magic carrying a closure's
 * captures. Provide it on pre-5.14 perls; newer perls use the core version. */
#if PERL_REVISION == 5 && PERL_VERSION < 14

static MAGIC *ReverseProxy_mg_findext(SV *sv, int type, const MGVTBL *vtbl) {
    if (sv) {
        MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
            if (mg->mg_type == type && (const MGVTBL *)mg->mg_virtual == vtbl)
                return mg;
    }
    return NULL;
}
#  define mg_findext(sv, type, vtbl) ReverseProxy_mg_findext((sv), (type), (vtbl))

#endif

#endif /* RP_COMPAT_H */
