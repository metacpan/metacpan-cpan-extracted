MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2::JWKS

SV *
new(class, ...)
        SV *class
    CODE:
        HV *args = newHV();
        int i;
        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("Punk::OAuth2::JWKS->new: uneven args");
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(args, ST(i), newSVsv(ST(i + 1)), 0);
        RETVAL = pox_jwks_new(aTHX_ args);
        SvREFCNT_dec((SV *)args);
    OUTPUT:
        RETVAL

# key_for($c, $kid) -> Crypt::JWS::Key or undef
SV *
key_for(self, c, kid)
        SV *self
        SV *c
        SV *kid
    CODE:
        SV *key = pox_jwks_key_for(aTHX_ self, c, kid);
        RETVAL = key ? SvREFCNT_inc(key) : &PL_sv_undef;
    OUTPUT:
        RETVAL

# _fetch($c) -> bool (force a refresh; mainly for tests)
int
_fetch(self, c)
        SV *self
        SV *c
    CODE:
        RETVAL = pox_jwks_fetch(aTHX_ self, c);
    OUTPUT:
        RETVAL
