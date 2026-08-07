/* punk_scope.h - the `under` handle, in C.
 *
 * A scope is a blessed hash carrying its accumulated prefix and its
 * outer-to-inner guard chain (flattened at creation, never at request time).
 * It records into the application exactly as the top-level DSL does; to_app
 * resolves and freezes. Nothing here runs per request - this is boot-time
 * registration - so the point of the port is not speed but keeping the whole
 * registrar surface in one place now that Punk::App is C.
 *
 * Must be included after punk_context.h (for pcx_call_meth).
 */

#ifndef PUNK_SCOPE_H
#define PUNK_SCOPE_H

static HV *scope_hv(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Punk::Router::Scope: not a scope object");
    return (HV *)SvRV(self);
}

static SV *scope_get(pTHX_ HV *h, const char *k) {
    SV **e = hv_fetch(h, k, (I32)strlen(k), 0);
    return (e && *e) ? *e : NULL;
}

/* the scope's guard chain, or NULL when it holds none */
static AV *scope_guards_av(pTHX_ HV *h) {
    SV *g = scope_get(aTHX_ h, "guards");
    return (g && SvROK(g) && SvTYPE(SvRV(g)) == SVt_PVAV) ? (AV *)SvRV(g) : NULL;
}

/* A fresh arrayref holding this scope's guards, optionally with one more
 * appended. The copy matters: the scope hands its chain to every route it
 * registers and to every nested scope, and a shared arrayref would let a
 * later `under` retroactively add a guard to routes already recorded. */
static SV *scope_guards_copy(pTHX_ HV *h, SV *extra) {
    AV *src = scope_guards_av(aTHX_ h);
    AV *out = newAV();
    if (src) {
        SSize_t i, n = av_len(src) + 1;
        av_extend(out, n);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(src, i, 0);
            av_push(out, (e && *e) ? newSVsv(*e) : newSV(0));
        }
    }
    if (extra && SvOK(extra)) av_push(out, newSVsv(extra));
    return newRV_noinc((SV *)out);
}

/* prefix . path, with the two edge cases the Perl had:
 * a '/' path contributes nothing (so `under '/admin'` plus get '/' is
 * '/admin', not '/admin/'), and an empty result is the root. Mortal. */
static SV *scope_full_path(pTHX_ HV *h, SV *path) {
    SV *pfx = scope_get(aTHX_ h, "prefix");
    SV *out = newSVsv(pfx && SvOK(pfx) ? pfx : &PL_sv_no);
    STRLEN pl;
    const char *p = SvOK(path) ? SvPV_const(path, pl) : "";
    if (!SvOK(path)) pl = 0;
    if (!(pfx && SvOK(pfx))) sv_setpvs(out, "");
    if (!(pl == 1 && p[0] == '/')) sv_catpvn(out, p, pl);
    if (!SvCUR(out)) sv_setpvs(out, "/");
    return sv_2mortal(out);
}

/* Build a scope of the same class as $self (so a subclass nests as itself),
 * through its own new - the constructor is the documented seam. */
static SV *scope_new_like(pTHX_ SV *self, SV *app, SV *prefix, SV *guards) {
    SV *argv[6];
    SV *class = sv_2mortal(newSVpv(sv_reftype(SvRV(self), 1), 0));
    SV *r;
    argv[0] = sv_2mortal(newSVpvs("app"));    argv[1] = app ? app : &PL_sv_undef;
    argv[2] = sv_2mortal(newSVpvs("prefix")); argv[3] = prefix;
    argv[4] = sv_2mortal(newSVpvs("guards")); argv[5] = guards;
    r = pcx_call_meth(aTHX_ class, "new", argv, 6, 1);
    return r ? r : &PL_sv_undef;
}

/* $self->{app}->$meth(...), the one shape every registration here takes. */
static void scope_app_call(pTHX_ HV *h, const char *meth, SV **argv, int nargs) {
    SV *app = scope_get(aTHX_ h, "app");
    SV *r = pcx_call_meth(aTHX_ app ? app : &PL_sv_undef, meth, argv, nargs, 1);
    if (r) SvREFCNT_dec(r);
}

#endif /* PUNK_SCOPE_H */
