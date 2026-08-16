MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2

# _verify_claims($claims_hashref, $issuer, $client_id, $nonce, $leeway)
# -> bool. OIDC iss/aud/azp/exp/iat/nonce checks in C.
int
_verify_claims(claims, issuer, client_id, nonce, leeway)
        SV *claims
        SV *issuer
        SV *client_id
        SV *nonce
        IV leeway
    CODE:
        if (!SvROK(claims) || SvTYPE(SvRV(claims)) != SVt_PVHV)
            croak("Punk::OAuth2::_verify_claims: claims must be a hashref");
        RETVAL = pox_verify_claims(aTHX_ (HV *)SvRV(claims),
                                   issuer, client_id, nonce, (int)leeway);
    OUTPUT:
        RETVAL
