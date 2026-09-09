MODULE = Punk::SAML  PACKAGE = Punk::SAML::Response

# verify($bytes, %opts): the decoded XML in, an identity hashref out, or a
# Punk::SAML::Error thrown.
#
# No application and no request. The ACS route in phase 8 is a thin
# wrapper that supplies now, acs_url, entity_id, the keys and the flow
# from configuration; `punk saml verify` is another; and the suite is a
# third, running this a thousand times with none of the three.
SV *
verify(class, bytes, ...)
        SV *class
        SV *bytes
    ALIAS:
        _verify_field = 1
    CODE:
        HV *a;
        psaml_checks o;
        SV *v;
        int i;
        PERL_UNUSED_VAR(class);
        if ((items - 2) % 2)
            croak("%s: Response->verify takes bytes and a list of pairs",
                  PSAML_WHO);
        a = newHV();
        sv_2mortal((SV *)a);
        for (i = 2; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(a, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }

        /* _verify_field is verify with the transport in front of it: the
         * size cap on the ENCODED field, then the strict base64. It is an
         * ALIAS rather than a wrapper that re-enters verify through
         * call_method - the wrapper was written first, and pushing the
         * caller\'s own arguments back onto the stack it was reading them
         * from produced a freed-string panic. One body, two names. */
        if (ix == 1)
            bytes = sv_2mortal(psaml_decode_field(aTHX_ bytes,
                        psaml_opt_iv(aTHX_ a, "max_response", 262144)));

        Zero(&o, 1, psaml_checks);
        v = psaml_hget(aTHX_ a, "idp");
        o.idp_name = (v && SvOK(v)) ? SvPV_nolen(v) : "";
        v = psaml_hget(aTHX_ a, "entity_id");
        if (!v || !SvOK(v))
            croak("%s: Response->verify needs `entity_id`, this "
                  "application's own", PSAML_WHO);
        o.entity_id = SvPV_nolen(v);
        v = psaml_hget(aTHX_ a, "idp_entity_id");
        if (!v || !SvOK(v))
            croak("%s: Response->verify needs `idp_entity_id`, the "
                  "provider's", PSAML_WHO);
        o.idp_entity_id = SvPV_nolen(v);
        v = psaml_hget(aTHX_ a, "acs_url");
        if (!v || !SvOK(v))
            croak("%s: Response->verify needs `acs_url`", PSAML_WHO);
        o.acs_url = SvPV_nolen(v);

        v = psaml_hget(aTHX_ a, "certs");
        if (!v || !SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV)
            croak("%s: Response->verify needs `certs`, an arrayref of the "
                  "provider's signing certificates", PSAML_WHO);
        o.keys = (AV *)SvRV(v);

        v = psaml_hget(aTHX_ a, "now");
        o.now  = (v && SvOK(v)) ? SvIV(v) : (IV)time(NULL);
        o.skew = psaml_opt_iv(aTHX_ a, "skew", 120);
        o.allow_sha1 = psaml_opt_bool(aTHX_ a, "allow_sha1", 0);
        o.allow_idp_initiated =
            psaml_opt_bool(aTHX_ a, "allow_idp_initiated", 0);
        v = psaml_hget(aTHX_ a, "require_signed");
        o.require_signed = (v && SvOK(v)) ? SvPV_nolen(v) : "either";
        o.flow_id = psaml_hget(aTHX_ a, "in_response_to");
        o.seen_cb = psaml_hget(aTHX_ a, "seen");

        RETVAL = psaml_verify_response(aTHX_ bytes, &o);
    OUTPUT:
        RETVAL

MODULE = Punk::SAML  PACKAGE = Punk::SAML

# Sign raw bytes, for the suite's fixture builder. The same gap phase 5
# hit from the other side: jws_abi signs arbitrary bytes but Crypt::JWS's
# Perl surface only makes compact tokens, so a Perl harness that has to
# produce an XML-DSig SignatureValue has no way in without this.
SV *
_sign_bytes(priv_pem, alg, input)
        SV *priv_pem
        SV *alg
        SV *input
    CODE:
        const jws_abi *J = psaml_jws(aTHX);
        STRLEN pl, al, il;
        const char *pp = SvPVbyte(priv_pem, pl);
        const char *ap = SvPVbyte(alg, al);
        const char *ip = SvPVbyte(input, il);
        void *k = J->key_from_pem(aTHX_ pp, pl);
        if (!k) croak("%s: the private key will not parse", PSAML_WHO);
        RETVAL = J->sign(aTHX_ k, ap, al, (const unsigned char *)ip, il);
        J->key_free(aTHX_ k);
        if (!RETVAL) croak("%s: signing failed", PSAML_WHO);
    OUTPUT:
        RETVAL

