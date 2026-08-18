MODULE = Punk        PACKAGE = Punk::Router

PROTOTYPES: DISABLE

# Punk::Router is entirely XS: the object is a blessed IV-ref to a C router
# (punk_route.h). new() opens an accumulation phase, add() records raw routes,
# compile() resolves their targets to coderefs (the one Perl call) and builds
# the whole table in C, and match_static/match run the request path in C.
# lib/Punk/Router.pm is documentation only.

SV *
new(class)
        SV *class
    CODE:
        RETVAL = sv_setref_iv(newSV(0), SvPV_nolen(class),
                              PTR2IV(pr_new(aTHX)));
    OUTPUT:
        RETVAL

# add(method => $m, path => $p, target => $t, guards => \@g): record one raw
# route (unresolved). The path must start with '/'. Chains.
void
add(self, ...)
        SV *self
    PPCODE:
    {
        pr_router *rt = punk_router_of(aTHX_ self);
        HV *rec = newHV();
        SV *path = NULL;
        int i;
        if (rt->compiled) croak("Punk::Router: cannot add after compile");
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(rec, k, (I32)kl, newSVsv(ST(i + 1)), 0);
            if (kl == 4 && memEQ(k, "path", 4)) path = ST(i + 1);
        }
        {
            STRLEN pl;
            const char *p = (path && SvOK(path)) ? SvPV_const(path, pl) : NULL;
            if (!p || !pl || p[0] != '/') {
                SvREFCNT_dec((SV *)rec);
                croak("Punk::Router: a route needs a path starting with '/'");
            }
        }
        av_push(rt->raw, newRV_noinc((SV *)rec));
        XPUSHs(self);
    }

# compile($resolve, \@extra?): resolve every target and guard through the
# app's $resolve->($target, $desc), then build the exact table, dynamic
# records, Allow lists and per-route record hashrefs in C. $extra is an
# arrayref of the same { method, path, target, guards } records (the docs UI
# routes). Returns self - the compiled handle.
void
compile(self, resolve, ...)
        SV *self
        SV *resolve
    PPCODE:
    {
        pr_router *rt = punk_router_of(aTHX_ self);
        AV *routes = (AV *)sv_2mortal((SV *)newAV());
        SSize_t i, n;
        if (rt->compiled) croak("Punk::Router: already compiled");
        n = av_len(rt->raw) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(rt->raw, i, 0);
            if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)
                pr_add_route(aTHX_ routes, resolve, (HV *)SvRV(*e));
        }
        if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV) {
            AV *extra = (AV *)SvRV(ST(2));
            SSize_t en = av_len(extra) + 1;
            for (i = 0; i < en; i++) {
                SV **e = av_fetch(extra, i, 0);
                if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)
                    pr_add_route(aTHX_ routes, resolve, (HV *)SvRV(*e));
            }
        }
        pr_build(aTHX_ rt, routes);
        XPUSHs(self);
    }

# The compiled record hashrefs (code + guards + method + path), indexed by the
# record index match_static / match return.
SV *
records(self)
        SV *self
    CODE:
        RETVAL = newRV_inc((SV *)punk_router_of(aTHX_ self)->records);
    OUTPUT:
        RETVAL

# The record index for an exact static match (HEAD falls back to GET), or the
# empty list. Consulted before mounts so a mounted app is never shadowed.
void
match_static(self, method, path)
        SV *self
        SV *method
        SV *path
    PPCODE:
    {
        pr_router *rt = punk_router_of(aTHX_ self);
        STRLEN ml, pl;
        const char *m = SvPV_const(method, ml);
        const char *p = SvPV_const(path, pl);
        IV idx = pr_static_match(aTHX_ rt, m, ml, p, pl);
        if (idx >= 0) mXPUSHi(idx);
    }

# Dynamic dispatch and the 405 cold path in one call:
#   (idx, \%captures)  a dynamic hit
#   (undef, \@allow)   the path exists under other methods (405)
#   ()                 no such path (404)
void
match(self, method, path)
        SV *self
        SV *method
        SV *path
    PPCODE:
    {
        pr_router *rt = punk_router_of(aTHX_ self);
        STRLEN ml, pl;
        const char *m = SvPV_const(method, ml);
        const char *p = SvPV_const(path, pl);
        HV *caps = (HV *)sv_2mortal((SV *)newHV());
        IV idx = pr_match(aTHX_ rt, m, ml, p, pl, caps);
        if (idx >= 0) {
            mXPUSHi(idx);
            mXPUSHs(newRV_inc((SV *)caps));
        }
        else {
            AV *allow = (AV *)sv_2mortal((SV *)newAV());
            if (pr_allow(aTHX_ rt, m, ml, p, pl, allow)) {
                XPUSHs(&PL_sv_undef);
                mXPUSHs(newRV_inc((SV *)allow));
            }
            /* else: empty list = 404 */
        }
    }

void
DESTROY(self)
        SV *self
    CODE:
    {
        if (SvROK(self) && SvIOK(SvRV(self)))
            pr_free(aTHX_ punk_router_of(aTHX_ self));
    }

MODULE = Punk        PACKAGE = Punk::Proxy

PROTOTYPES: DISABLE

# Punk::Proxy is the compiled `proxy` trust policy: a blessed IV-ref to a
# pp_policy (punk_proxy.h), built once at to_app and read by pp_resolve at
# the top of every request. There is no other method - the object exists so
# the struct is freed with the compiled application.

void
DESTROY(self)
        SV *self
    CODE:
    {
        if (SvROK(self) && SvIOK(SvRV(self)))
            pp_free(aTHX_ (pp_policy *)INT2PTR(void *, SvIV(SvRV(self))));
    }

# _client($xff, $peer, $trust): the hop walk alone, for t/61-proxy-parse.t.
# $trust is a hop count, an arrayref of CIDRs, or 'all' - the same shapes the
# keyword takes, compiled fresh per call. Author-facing, not documented.
SV *
_client(xff, peer, trust)
        SV *xff
        SV *peer
        SV *trust
    CODE:
    {
        HV *cfg = (HV *)sv_2mortal((SV *)newHV());
        pp_policy *p;
        STRLEN xl = 0, pl = 0, cl = 0;
        const char *x = SvOK(xff)  ? SvPV_const(xff, xl)  : NULL;
        const char *r = SvOK(peer) ? SvPV_const(peer, pl) : "";
        const char *c;
        (void)hv_stores(cfg, "trust", newSVsv(trust));
        p = pp_compile(aTHX_ cfg, "development");
        c = pp_xff_client(x, xl, p, r, pl, &cl);
        RETVAL = newSVpvn(c, cl);
        pp_free(aTHX_ p);
    }
    OUTPUT:
        RETVAL
