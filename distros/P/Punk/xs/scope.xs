MODULE = Punk        PACKAGE = Punk::Router::Scope

PROTOTYPES: DISABLE

# The `under` handle, in C (punk_scope.h). A scope is a blessed hash of
# app/prefix/guards that records into the application exactly as the
# top-level DSL keywords do; Punk::Router::Scope.pm is the documentation.

SV *
new(class, ...)
        SV *class
    CODE:
    {
        HV *h = newHV();
        SV *app = NULL, *prefix = NULL, *guards = NULL;
        int i;
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if      (kl == 3 && memEQ(k, "app",    3)) app    = ST(i + 1);
            else if (kl == 6 && memEQ(k, "prefix", 6)) prefix = ST(i + 1);
            else if (kl == 6 && memEQ(k, "guards", 6)) guards = ST(i + 1);
        }
        (void)hv_stores(h, "app", app ? newSVsv(app) : newSV(0));
        (void)hv_stores(h, "prefix",
            (prefix && SvOK(prefix)) ? newSVsv(prefix) : newSVpvs(""));
        (void)hv_stores(h, "guards",
            (guards && SvROK(guards) && SvTYPE(SvRV(guards)) == SVt_PVAV)
                ? newSVsv(guards) : newRV_noinc((SV *)newAV()));
        RETVAL = sv_bless(newRV_noinc((SV *)h), gv_stashsv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

# under($prefix, $guard?) -> a nested scope: prefixes concatenate, the guard
# joins the end of the chain, and both are frozen into the new object.
SV *
under(self, prefix, guard = &PL_sv_undef)
        SV *self
        SV *prefix
        SV *guard
    CODE:
    {
        HV *h = scope_hv(aTHX_ self);
        SV *pfx = scope_get(aTHX_ h, "prefix");
        SV *full = sv_2mortal(newSVsv(pfx && SvOK(pfx) ? pfx : &PL_sv_no));
        if (!(pfx && SvOK(pfx))) sv_setpvs(full, "");
        sv_catsv(full, prefix);
        RETVAL = scope_new_like(aTHX_ self, scope_get(aTHX_ h, "app"), full,
                                sv_2mortal(scope_guards_copy(aTHX_ h, guard)));
    }
    OUTPUT:
        RETVAL

# _route($method, $path, $target), and the verbs that are it with the method
# already supplied. Chains.
#
# Declared variadic because the aliases differ in arity - get($path, $target)
# against _route($method, $path, $target) - and xsubpp generates one usage
# check from the declared parameter list for the whole ALIAS group.
SV *
_route(self, ...)
        SV *self
    ALIAS:
        get   = 1
        post  = 2
        put   = 3
        patch = 4
        del   = 5
        any   = 6
    CODE:
    {
        static const char *VERB[] =
            { NULL, "GET", "POST", "PUT", "PATCH", "DELETE", "ANY" };
        static const char *NAME[] =
            { "_route", "get", "post", "put", "patch", "del", "any" };
        HV *h = scope_hv(aTHX_ self);
        SV *method, *path, *target, *argv[4];

        if (ix) {
            if (items != 3)
                croak("Usage: Punk::Router::Scope::%s(self, path, target)",
                      NAME[ix]);
            method = sv_2mortal(newSVpv(VERB[ix], 0));
            path   = ST(1);
            target = ST(2);
        }
        else {
            if (items != 4)
                croak("Usage: Punk::Router::Scope::_route(self, method, "
                      "path, target)");
            method = ST(1);
            path   = ST(2);
            target = ST(3);
        }

        argv[0] = method;
        argv[1] = scope_full_path(aTHX_ h, path);
        argv[2] = target;
        argv[3] = sv_2mortal(scope_guards_copy(aTHX_ h, NULL));
        scope_app_call(aTHX_ h, "route", argv, 4);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# api($spec, $opts?) -> the Punk::Mount::OpenAPI, which takes this scope's
# prefix and guards. Returns the mount, not the scope - `docs` wants it.
SV *
api(self, spec, opts = &PL_sv_undef)
        SV *self
        SV *spec
        SV *opts
    CODE:
    {
        HV *h = scope_hv(aTHX_ self);
        SV *app = scope_get(aTHX_ h, "app");
        SV *argv[3], *mount;
        argv[0] = spec;
        argv[1] = opts;
        argv[2] = self;
        mount = pcx_call_meth(aTHX_ app ? app : &PL_sv_undef, "api", argv, 3, 1);
        RETVAL = mount ? mount : newSV(0);
    }
    OUTPUT:
        RETVAL

# websocket($path, $target, $opts?): the prefix and the guard chain apply
# exactly as they do to an ordinary route, so a guard can refuse the
# connection with a normal HTTP response before the upgrade. Chains.
SV *
websocket(self, path, target, opts = &PL_sv_undef)
        SV *self
        SV *path
        SV *target
        SV *opts
    CODE:
    {
        HV *h = scope_hv(aTHX_ self);
        SV *argv[4];
        argv[0] = scope_full_path(aTHX_ h, path);
        argv[1] = target;
        argv[2] = opts;
        argv[3] = sv_2mortal(scope_guards_copy(aTHX_ h, NULL));
        scope_app_call(aTHX_ h, "websocket", argv, 4);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

SV *
prefix(self)
        SV *self
    CODE:
    {
        SV *p = scope_get(aTHX_ scope_hv(aTHX_ self), "prefix");
        RETVAL = (p && SvOK(p)) ? newSVsv(p) : newSVpvs("");
    }
    OUTPUT:
        RETVAL

# A copy, so a caller cannot reach in and change what this scope's already
# registered routes were given.
SV *
guards(self)
        SV *self
    CODE:
        RETVAL = scope_guards_copy(aTHX_ scope_hv(aTHX_ self), NULL);
    OUTPUT:
        RETVAL
