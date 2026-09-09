MODULE = Punk::SAML  PACKAGE = Punk::SAML::IdP

# read($bytes, %opts): a provider out of metadata bytes.
#
# Bytes, not a URL. The fetch is a separate thing, so every refusal this
# reader makes is testable against a string and needs no network.
SV *
read(class, bytes, ...)
        SV *class
        SV *bytes
    CODE:
        HV *a;
        SV *want;
        int i;
        PERL_UNUSED_VAR(class);
        if ((items - 2) % 2)
            croak("%s: IdP->read takes bytes and a list of pairs", PSAML_WHO);
        a = newHV();
        sv_2mortal((SV *)a);
        for (i = 2; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(a, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        want = psaml_hget(aTHX_ a, "entity_id");
        RETVAL = psaml_idp_from_metadata(aTHX_ bytes,
                    (want && SvOK(want)) ? SvPV_nolen(want) : NULL,
                    psaml_opt_bool(aTHX_ a, "enforce_cert_validity", 0));
    OUTPUT:
        RETVAL

MODULE = Punk::SAML  PACKAGE = Punk::SAML::Metadata

# The SP document. The ACS URL is passed in because phase 4 computed it
# once at on_compile and this must not be a second derivation of it.
SV *
build(class, ...)
        SV *class
    CODE:
        HV *a;
        int i;
        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("%s: Metadata->build takes a list of pairs", PSAML_WHO);
        a = newHV();
        sv_2mortal((SV *)a);
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(a, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        RETVAL = psaml_sp_metadata(aTHX_
                    psaml_hget(aTHX_ a, "entity_id"),
                    psaml_hget(aTHX_ a, "acs_url"),
                    psaml_hget(aTHX_ a, "cert"),
                    psaml_hget(aTHX_ a, "name_id_format"),
                    psaml_opt_bool(aTHX_ a, "authn_requests_signed", 0),
                    psaml_opt_bool(aTHX_ a, "want_assertions_signed", 1));
    OUTPUT:
        RETVAL

# sign($xml, $id, $key_pem, $cert_pem): an enveloped signature over the
# element with that ID, spliced in as its first child.
SV *
sign(class, xml, id, key_pem, cert_pem = &PL_sv_undef)
        SV *class
        SV *xml
        SV *id
        SV *key_pem
        SV *cert_pem
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = psaml_sign_document(aTHX_ xml, id, key_pem, cert_pem);
    OUTPUT:
        RETVAL

SV *
content_type(class)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = newSVpvs(PSAML_CT_METADATA);
    OUTPUT:
        RETVAL

MODULE = Punk::SAML  PACKAGE = Punk::SAML

# Verify an enveloped signature on an arbitrary document, for t/. The
# same psaml_signature.h the Response verifier uses, so sign_metadata is
# checked against the real verifier rather than a second one written to
# agree with it.
int
_verify_document(xml, id, certs)
        SV *xml
        SV *id
        SV *certs
    CODE:
        psaml_doc_guard *guard = NULL;
        frx_doc *doc;
        const frx_node *target;
        psaml_verify_ctx ctx;
        STRLEN il;
        const char *ip = SvPVbyte(id, il);
        if (!SvROK(certs) || SvTYPE(SvRV(certs)) != SVt_PVAV)
            croak("%s: _verify_document takes an arrayref of certificates",
                  PSAML_WHO);
        doc = psaml_parse_response(aTHX_ xml, &guard);
        target = psaml_frx(aTHX)->by_id(doc, "ID", ip, il);
        if (!target) XSRETURN_NO;
        ctx.doc = doc;
        ctx.keys = (AV *)SvRV(certs);
        ctx.allow_sha1 = 0;
        RETVAL = psaml_verify_element(aTHX_ &ctx, target);
    OUTPUT:
        RETVAL

MODULE = Punk::SAML  PACKAGE = Punk::SAML

# The flow cookie's pieces, for t/. Phase 8's routes call the same
# functions; these let the suite prove the cookie itself without driving
# a browser through a cross-site POST.

SV *
_flow_serialise(records, secret)
        SV *records
        SV *secret
    CODE:
        if (!SvROK(records) || SvTYPE(SvRV(records)) != SVt_PVAV)
            croak("%s: _flow_serialise takes an arrayref", PSAML_WHO);
        RETVAL = psaml_flow_serialise(aTHX_ (AV *)SvRV(records), secret);
    OUTPUT:
        RETVAL

SV *
_flow_parse(cookie, secret, now, ttl)
        SV *cookie
        SV *secret
        IV now
        IV ttl
    CODE:
        RETVAL = newRV_noinc((SV *)psaml_flow_parse(aTHX_ cookie, secret,
                                                    now, ttl));
    OUTPUT:
        RETVAL

SV *
_flow_cookie(value, mount, ttl)
        SV *value
        SV *mount
        IV ttl
    CODE:
        RETVAL = psaml_flow_cookie(aTHX_ value, mount, ttl);
    OUTPUT:
        RETVAL
