MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2

SV *
uri_escape(str)
        SV *str
    CODE:
        STRLEN n;
        const char *p = SvPVbyte(str, n);
        RETVAL = SvREFCNT_inc(pox_uri_escape(aTHX_ p, n));
    OUTPUT:
        RETVAL

SV *
_form(pairs)
        SV *pairs
    CODE:
        if (!SvROK(pairs) || SvTYPE(SvRV(pairs)) != SVt_PVHV)
            croak("Punk::OAuth2::_form: expects a hashref");
        RETVAL = pox_form_from_hv(aTHX_ (HV *)SvRV(pairs));
    OUTPUT:
        RETVAL

SV *
same_origin_path(path)
        SV *path
    CODE:
        SV *ok = pox_same_origin_path(aTHX_ path);
        RETVAL = ok ? newSVsv(ok) : &PL_sv_undef;
    OUTPUT:
        RETVAL

# base_url($c, $cfg_hashref): configured base_url wins; otherwise derive
# from the request env, using X-Forwarded-* only under trust_proxy.
SV *
base_url(c, cfg)
        SV *c
        SV *cfg
    CODE:
        RETVAL = pox_base_url(aTHX_ c, cfg);
    OUTPUT:
        RETVAL

# safe_url($url, $allow_local): (1) or (0, reason). SSRF guard.
void
safe_url(url, ...)
        SV *url
    PPCODE:
        int allow_local = items > 1 && SvTRUE(ST(1));
        const char *why = NULL;
        int ok = pox_safe_url(aTHX_ url, allow_local, &why);
        if (ok) {
            EXTEND(SP, 1);
            mPUSHi(1);
        }
        else {
            EXTEND(SP, 2);
            mPUSHi(0);
            mPUSHp(why, strlen(why));
        }

# await($c, $value): resolve a future - $c->await for a Punk::Future
# (parks under Hyperman), ->get otherwise; passthrough for non-futures.
SV *
await(c, value)
        SV *c
        SV *value
    CODE:
        RETVAL = pox_await(aTHX_ c, value);
    OUTPUT:
        RETVAL
