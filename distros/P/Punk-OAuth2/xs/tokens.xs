MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2::Tokens

SV *
new(class, ...)
        SV *class
    CODE:
        HV *data = newHV();
        int i;
        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("Punk::OAuth2::Tokens->new: uneven args");
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(data, ST(i), newSVsv(ST(i + 1)), 0);
        RETVAL = pox_tokens_new(aTHX_ data);
        SvREFCNT_dec((SV *)data);
    OUTPUT:
        RETVAL

SV *
from_response(class, data)
        SV *class
        SV *data
    CODE:
        PERL_UNUSED_VAR(class);
        if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVHV)
            croak("Punk::OAuth2::Tokens->from_response: expects a hashref");
        {
            HV *src = (HV *)SvRV(data);
            HV *args = newHV();
            static const char *keys[] = {
                "access_token", "token_type", "expires_in",
                "refresh_token", "id_token", "scope", NULL
            };
            int k;
            for (k = 0; keys[k]; k++) {
                SV **v = hv_fetch(src, keys[k], (I32)strlen(keys[k]), 0);
                if (v && *v)
                    (void)hv_store(args, keys[k], (I32)strlen(keys[k]),
                                   newSVsv(*v), 0);
            }
            (void)hv_stores(args, "raw", newSVsv(data));
            RETVAL = pox_tokens_new(aTHX_ args);
            SvREFCNT_dec((SV *)args);
        }
    OUTPUT:
        RETVAL

SV *
access_token(self)
        SV *self
    ALIAS:
        token_type    = 1
        refresh_token = 2
        id_token      = 3
        scope         = 4
        expires_at    = 5
        raw           = 6
    CODE:
        const char *key = ix == 1 ? "token_type"
                        : ix == 2 ? "refresh_token"
                        : ix == 3 ? "id_token"
                        : ix == 4 ? "scope"
                        : ix == 5 ? "expires_at"
                        : ix == 6 ? "raw" : "access_token";
        RETVAL = pox_tokens_get(aTHX_ self, key);
    OUTPUT:
        RETVAL

SV *
id_claims(self, ...)
        SV *self
    CODE:
        HV *h = pox_tokens_hv(aTHX_ self);
        if (items > 1) {
            (void)hv_stores(h, "id_claims", newSVsv(ST(1)));
            RETVAL = newSVsv(ST(1));
        }
        else {
            RETVAL = pox_tokens_get(aTHX_ self, "id_claims");
        }
    OUTPUT:
        RETVAL

int
expired(self, ...)
        SV *self
    CODE:
        HV *h = pox_tokens_hv(aTHX_ self);
        SV **ea = hv_fetchs(h, "expires_at", 0);
        IV leeway = items > 1 ? SvIV(ST(1)) : 30;
        if (!ea || !*ea || !SvOK(*ea))
            RETVAL = 0;
        else
            RETVAL = (IV)time(NULL) >= SvIV(*ea) - leeway;
    OUTPUT:
        RETVAL

int
refreshable(self)
        SV *self
    CODE:
        HV *h = pox_tokens_hv(aTHX_ self);
        SV **rt = hv_fetchs(h, "refresh_token", 0);
        RETVAL = rt && *rt && SvOK(*rt) && SvCUR(*rt) > 0;
    OUTPUT:
        RETVAL
