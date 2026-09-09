MODULE = Punk::SAML  PACKAGE = Punk::SAML::Request

# The outbound half, driven directly so the suite exercises it with no
# application booted. Phase 8 calls the same functions from the login
# route with values off the application hash.

SV *
new_id(class)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = psaml_request_id(aTHX);
    OUTPUT:
        RETVAL

# build(%args): the AuthnRequest document.
SV *
build(class, ...)
        SV *class
    CODE:
        HV *a;
        int i;
        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("%s: Request->build takes a list of pairs", PSAML_WHO);
        a = newHV();
        sv_2mortal((SV *)a);
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(a, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        RETVAL = psaml_authn_request(aTHX_
                    psaml_hget(aTHX_ a, "id"),
                    psaml_hget(aTHX_ a, "instant"),
                    psaml_hget(aTHX_ a, "destination"),
                    psaml_hget(aTHX_ a, "acs_url"),
                    psaml_hget(aTHX_ a, "issuer"),
                    psaml_hget(aTHX_ a, "name_id_format"),
                    psaml_opt_bool(aTHX_ a, "force_authn", 0));
    OUTPUT:
        RETVAL

# redirect_url($sso_url, $xml, $relay, $key_pem): the full 302 target.
SV *
redirect_url(class, sso_url, xml, relay = &PL_sv_undef, key_pem = &PL_sv_undef)
        SV *class
        SV *sso_url
        SV *xml
        SV *relay
        SV *key_pem
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = psaml_redirect_url(aTHX_ sso_url, xml, relay, key_pem);
    OUTPUT:
        RETVAL

MODULE = Punk::SAML  PACKAGE = Punk::SAML

# The pieces, for t/. Not public API: the leading underscore says so.

SV *
_urlenc(str)
        SV *str
    CODE:
        RETVAL = psaml_urlenc(aTHX_ str);
    OUTPUT:
        RETVAL

SV *
_deflate_b64(bytes)
        SV *bytes
    CODE:
        RETVAL = psaml_deflate_b64(aTHX_ bytes);
    OUTPUT:
        RETVAL

# The signed string of Bindings 3.4.4.1, over values ALREADY encoded, so a
# test can check the order and the omission of RelayState without having
# to reach inside redirect_url.
SV *
_signed_string(enc_req, enc_relay, enc_sigalg)
        SV *enc_req
        SV *enc_relay
        SV *enc_sigalg
    CODE:
        RETVAL = psaml_signed_string(aTHX_ enc_req,
                    (SvOK(enc_relay) && SvCUR(enc_relay)) ? enc_relay : NULL,
                    enc_sigalg);
    OUTPUT:
        RETVAL

SV *
_decode_field(field, max_bytes)
        SV *field
        IV max_bytes
    CODE:
        RETVAL = psaml_decode_field(aTHX_ field, max_bytes);
    OUTPUT:
        RETVAL

# Verify a detached signature over raw bytes, for t/.
#
# This is the gap phase 2 deferred: jws_abi's `verify` takes raw signing
# input, but Crypt::JWS's PERL surface insists on a compact token, so a
# Perl caller holding a detached signature has no way in. Punk::SAML is
# an XS consumer and reaches the table directly, so the test for the
# redirect signature goes through here rather than waiting for
# Crypt::JWS to grow verify_bytes.
int
_verify_bytes(pub_pem, alg, input, sig)
        SV *pub_pem
        SV *alg
        SV *input
        SV *sig
    CODE:
        const jws_abi *J = psaml_jws(aTHX);
        STRLEN pl, al, il, sl;
        const char *pp = SvPVbyte(pub_pem, pl);
        const char *ap = SvPVbyte(alg, al);
        const char *ip = SvPVbyte(input, il);
        const char *sp = SvPVbyte(sig, sl);
        void *k = J->key_from_pem(aTHX_ pp, pl);
        if (!k) croak("%s: the public key will not parse", PSAML_WHO);
        RETVAL = J->verify(aTHX_ k, ap, al,
                           (const unsigned char *)ip, il,
                           (const unsigned char *)sp, sl);
        J->key_free(aTHX_ k);
    OUTPUT:
        RETVAL
