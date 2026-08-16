MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2

# Mint a login flow: { state, verifier, nonce, challenge } where
# state/verifier/nonce are 256-bit base64url and challenge is the PKCE
# S256 challenge b64url(sha256(verifier)).
SV *
_mint_flow()
    CODE:
        SV *verifier = pox_random_b64(aTHX_ 32);
        STRLEN vl, dl;
        const char *vp = SvPVbyte(verifier, vl);
        SV *digest = pox_sha256(aTHX_ (const unsigned char *)vp, vl);
        const unsigned char *dp = (const unsigned char *)SvPVbyte(digest, dl);
        SV *challenge = pox_b64url(aTHX_ dp, dl);
        HV *h = newHV();
        (void)hv_stores(h, "state",     newSVsv(pox_random_b64(aTHX_ 32)));
        (void)hv_stores(h, "verifier",  newSVsv(verifier));
        (void)hv_stores(h, "nonce",     newSVsv(pox_random_b64(aTHX_ 32)));
        (void)hv_stores(h, "challenge", newSVsv(challenge));
        RETVAL = newRV_noinc((SV *)h);
    OUTPUT:
        RETVAL

int
ct_eq(a, b)
        SV *a
        SV *b
    CODE:
        RETVAL = pox_ct_eq_sv(aTHX_ a, b);
    OUTPUT:
        RETVAL
