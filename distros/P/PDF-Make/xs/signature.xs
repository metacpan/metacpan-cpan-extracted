##############################################################################
# Signature XS bindings
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::Signature
PROTOTYPES: ENABLE

##############################################################################
# Signature verification and counting
##############################################################################

SV *
_verify(data_sv, index)
    SV *data_sv
    int index
    PREINIT:
        STRLEN len;
        const uint8_t *data;
        pdfmake_arena_t *arena;
        pdfmake_sig_verify_result_t *result;
        HV *hv;
    CODE:
        data = (const uint8_t *)SvPVbyte(data_sv, len);
        
        arena = pdfmake_arena_new();
        if (!arena)
            croak("PDF::Make::Signature::_verify: out of memory");
        
        result = pdfmake_sig_verify(arena, data, len, index);
        
        hv = newHV();
        
        if (result) {
            hv_store(hv, "valid", 5, newSViv(result->valid), 0);
            hv_store(hv, "signature_valid", 15, newSViv(result->signature_valid), 0);
            hv_store(hv, "digest_valid", 12, newSViv(result->digest_valid), 0);
            hv_store(hv, "cert_valid", 10, newSViv(result->cert_valid), 0);
            hv_store(hv, "timestamp_valid", 15, newSViv(result->timestamp_valid), 0);
            hv_store(hv, "document_modified", 17, newSViv(result->document_modified), 0);
            
            if (result->signer_name)
                hv_store(hv, "signer_name", 11, newSVpv(result->signer_name, 0), 0);
            if (result->signer_email)
                hv_store(hv, "signer_email", 12, newSVpv(result->signer_email, 0), 0);
            if (result->signing_time > 0)
                hv_store(hv, "signing_time", 12, newSViv(result->signing_time), 0);
            if (result->error)
                hv_store(hv, "error", 5, newSVpv(result->error, 0), 0);
        } else {
            hv_store(hv, "valid", 5, newSViv(0), 0);
            hv_store(hv, "error", 5, newSVpv("Verification not implemented or no signature found", 0), 0);
        }
        
        pdfmake_arena_free(arena);
        
        /* Return a PDF::Make::SignatureResult object */
        {
            SV *obj_ref = newRV_noinc((SV*)hv);
            sv_bless(obj_ref, gv_stashpv("PDF::Make::SignatureResult", GV_ADD));
            RETVAL = obj_ref;
        }
    OUTPUT:
        RETVAL

int
_count(data_sv)
    SV *data_sv
    PREINIT:
        STRLEN len;
        const uint8_t *data;
    CODE:
        data = (const uint8_t *)SvPVbyte(data_sv, len);
        RETVAL = pdfmake_sig_count(data, len);
    OUTPUT:
        RETVAL

##############################################################################
# Hash functions
##############################################################################

SV *
_hash_sha256(data_sv)
    SV *data_sv
    PREINIT:
        STRLEN len;
        const uint8_t *data;
        uint8_t digest[32];
        size_t digest_len;
    CODE:
        data = (const uint8_t *)SvPVbyte(data_sv, len);
        digest_len = pdfmake_hash(PDFMAKE_HASH_SHA256, data, len, digest);
        if (digest_len == 0)
            XSRETURN_UNDEF;
        RETVAL = newSVpvn((const char *)digest, digest_len);
    OUTPUT:
        RETVAL

SV *
_hash_sha384(data_sv)
    SV *data_sv
    PREINIT:
        STRLEN len;
        const uint8_t *data;
        uint8_t digest[48];
        size_t digest_len;
    CODE:
        data = (const uint8_t *)SvPVbyte(data_sv, len);
        digest_len = pdfmake_hash(PDFMAKE_HASH_SHA384, data, len, digest);
        if (digest_len == 0)
            XSRETURN_UNDEF;
        RETVAL = newSVpvn((const char *)digest, digest_len);
    OUTPUT:
        RETVAL

SV *
_hash_sha512(data_sv)
    SV *data_sv
    PREINIT:
        STRLEN len;
        const uint8_t *data;
        uint8_t digest[64];
        size_t digest_len;
    CODE:
        data = (const uint8_t *)SvPVbyte(data_sv, len);
        digest_len = pdfmake_hash(PDFMAKE_HASH_SHA512, data, len, digest);
        if (digest_len == 0)
            XSRETURN_UNDEF;
        RETVAL = newSVpvn((const char *)digest, digest_len);
    OUTPUT:
        RETVAL

##############################################################################
# SigningIdentity - PKCS#12 and PEM parsing
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::SigningIdentity
PROTOTYPES: ENABLE

pdfmake_signing_identity_t *
_from_pkcs12(class, data_sv, password)
    const char *class
    SV *data_sv
    const char *password
    PREINIT:
        STRLEN len;
        const uint8_t *data;
        pdfmake_arena_t *arena;
    CODE:
        PERL_UNUSED_VAR(class);
        data = (const uint8_t *)SvPVbyte(data_sv, len);
        
        arena = pdfmake_arena_new();
        if (!arena)
            croak("PDF::Make::SigningIdentity: out of memory");
        
        RETVAL = pdfmake_pkcs12_parse(arena, data, len, password);
        if (!RETVAL) {
            pdfmake_arena_free(arena);
            croak("PDF::Make::SigningIdentity: failed to parse PKCS#12 data");
        }
        /* Note: arena is now owned by the identity */
    OUTPUT:
        RETVAL

void
DESTROY(self_sv)
    SV *self_sv
    PREINIT:
        SV *inner;
        pdfmake_signing_identity_t *self;
    CODE:
        /* The PDF::Make::SigningIdentity package has two constructors:
         *   - XS: _from_pkcs12() blesses a scalar holding a native pointer
         *   - pure-Perl: ::new() in lib/PDF/Make/Signature.pm blesses a HASH
         * Only the XS-created variant owns a pdfmake_signing_identity_t
         * that must be freed here. Without this guard, calling SvIV on a
         * blessed HASH at global destruction emits a spurious
         * "Use of uninitialized value in subroutine entry" warning. */
        if (sv_isobject(self_sv) && SvROK(self_sv)) {
            inner = SvRV(self_sv);
            if (inner && SvTYPE(inner) < SVt_PVAV) {
                self = INT2PTR(pdfmake_signing_identity_t *, SvIV(inner));
                if (self) pdfmake_signing_identity_free(self);
            }
        }

int
has_private_key(self)
    pdfmake_signing_identity_t *self
    CODE:
        RETVAL = (self && self->privkey != NULL);
    OUTPUT:
        RETVAL

int
has_certificate(self)
    pdfmake_signing_identity_t *self
    CODE:
        RETVAL = (self && self->cert != NULL);
    OUTPUT:
        RETVAL

int
chain_length(self)
    pdfmake_signing_identity_t *self
    CODE:
        if (!self || !self->chain)
            RETVAL = 0;
        else
            RETVAL = self->chain->count;
    OUTPUT:
        RETVAL

SV *
subject(self)
    pdfmake_signing_identity_t *self
    CODE:
        if (!self || !self->cert || !self->cert->subject.dn)
            XSRETURN_UNDEF;
        RETVAL = newSVpv(self->cert->subject.dn, 0);
    OUTPUT:
        RETVAL

SV *
issuer(self)
    pdfmake_signing_identity_t *self
    CODE:
        if (!self || !self->cert || !self->cert->issuer.dn)
            XSRETURN_UNDEF;
        RETVAL = newSVpv(self->cert->issuer.dn, 0);
    OUTPUT:
        RETVAL

SV *
serial(self)
    pdfmake_signing_identity_t *self
    CODE:
        if (!self || !self->cert || !self->cert->serial_hex)
            XSRETURN_UNDEF;
        RETVAL = newSVpv(self->cert->serial_hex, 0);
    OUTPUT:
        RETVAL

IV
not_before(self)
    pdfmake_signing_identity_t *self
    CODE:
        if (!self || !self->cert)
            RETVAL = 0;
        else
            RETVAL = self->cert->not_before;
    OUTPUT:
        RETVAL

IV
not_after(self)
    pdfmake_signing_identity_t *self
    CODE:
        if (!self || !self->cert)
            RETVAL = 0;
        else
            RETVAL = self->cert->not_after;
    OUTPUT:
        RETVAL

int
is_valid(self, ...)
    pdfmake_signing_identity_t *self
    PREINIT:
        int64_t check_time;
    CODE:
        if (items > 1)
            check_time = (int64_t)SvIV(ST(1));
        else
            check_time = 0;  /* pdfmake_x509_is_valid handles 0 as "now" */
        
        if (!self || !self->cert)
            RETVAL = 0;
        else
            RETVAL = pdfmake_x509_is_valid(self->cert, check_time);
    OUTPUT:
        RETVAL

int
can_sign(self)
    pdfmake_signing_identity_t *self
    CODE:
        if (!self || !self->cert)
            RETVAL = 0;
        else
            RETVAL = pdfmake_x509_can_sign_documents(self->cert);
    OUTPUT:
        RETVAL

const char *
algorithm(self)
    pdfmake_signing_identity_t *self
    CODE:
        if (!self || !self->privkey)
            RETVAL = "unknown";
        else
            RETVAL = pdfmake_x509_pk_algorithm_name(self->privkey->algorithm);
    OUTPUT:
        RETVAL

##############################################################################
# Certificate wrapper
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::CertificateXS
PROTOTYPES: ENABLE

SV *
subject(self)
    pdfmake_x509_cert_t *self
    CODE:
        if (!self || !self->subject.dn)
            XSRETURN_UNDEF;
        RETVAL = newSVpv(self->subject.dn, 0);
    OUTPUT:
        RETVAL

SV *
issuer(self)
    pdfmake_x509_cert_t *self
    CODE:
        if (!self || !self->issuer.dn)
            XSRETURN_UNDEF;
        RETVAL = newSVpv(self->issuer.dn, 0);
    OUTPUT:
        RETVAL

IV
version(self)
    pdfmake_x509_cert_t *self
    CODE:
        RETVAL = self ? self->version : 0;
    OUTPUT:
        RETVAL

int
is_ca(self)
    pdfmake_x509_cert_t *self
    CODE:
        RETVAL = self ? self->is_ca : 0;
    OUTPUT:
        RETVAL

int
is_self_signed(self)
    pdfmake_x509_cert_t *self
    CODE:
        RETVAL = self ? self->is_self_signed : 0;
    OUTPUT:
        RETVAL

int
can_sign_documents(self)
    pdfmake_x509_cert_t *self
    CODE:
        RETVAL = self ? pdfmake_x509_can_sign_documents(self) : 0;
    OUTPUT:
        RETVAL

int
is_valid(self, ...)
    pdfmake_x509_cert_t *self
    PREINIT:
        int64_t check_time;
    CODE:
        if (items > 1)
            check_time = (int64_t)SvIV(ST(1));
        else
            check_time = 0;
        RETVAL = self ? pdfmake_x509_is_valid(self, check_time) : 0;
    OUTPUT:
        RETVAL



MODULE = PDF::Make  PACKAGE = PDF::Make::Signature

SV *
_sign_doc(doc, identity, hash_alg, reason, location, contact, name, signing_time_sv, tst_token_sv, placeholder_sv, appearance_sv)
    pdfmake_doc_t *doc
    pdfmake_signing_identity_t *identity
    int hash_alg
    SV *reason
    SV *location
    SV *contact
    SV *name
    SV *signing_time_sv
    SV *tst_token_sv
    SV *placeholder_sv
    SV *appearance_sv
    PREINIT:
        pdfmake_sig_config_t config;
        pdfmake_buf_t out;
        STRLEN tst_len = 0;
        const uint8_t *tst_bytes = NULL;
        /* Appearance-local storage: the HV* fields point into SVs owned by
         * the caller's hashref; we only need these local char** arrays for
         * the duration of the pdfmake_doc_sign call. */
        char **ap_names = NULL;
        char **ap_bases = NULL;
        size_t ap_font_count = 0;
        char     **ap_xo_names = NULL;
        uint32_t  *ap_xo_nums  = NULL;
        size_t     ap_xo_count = 0;
    CODE:
        pdfmake_sig_config_init(&config);
        config.identity = identity;
        config.hash_algorithm = (pdfmake_hash_algorithm_t)hash_alg;
        if (SvOK(reason))   config.reason       = SvPV_nolen(reason);
        if (SvOK(location)) config.location      = SvPV_nolen(location);
        if (SvOK(contact))  config.contact_info  = SvPV_nolen(contact);
        if (SvOK(name))     config.name          = SvPV_nolen(name);
        if (SvOK(signing_time_sv)) config.signing_time = (int64_t)SvIV(signing_time_sv);
        if (SvOK(tst_token_sv)) {
            tst_bytes = (const uint8_t *)SvPVbyte(tst_token_sv, tst_len);
            config.tst_token     = tst_bytes;
            config.tst_token_len = (size_t)tst_len;
        }
        if (SvOK(placeholder_sv)) {
            config.placeholder_size = (size_t)SvUV(placeholder_sv);
        }
        /* appearance_sv: hashref with optional keys
         *   visible => bool
         *   page    => int (1-based)
         *   rect    => [x0, y0, x1, y1]
         *   stream  => bytes (raw PDF content operators)
         *   fonts   => { "Resource-name" => "BaseFont-name", ... }
         *   show_name / show_date / show_reason => bool
         */
        if (SvOK(appearance_sv) && SvROK(appearance_sv) &&
            SvTYPE(SvRV(appearance_sv)) == SVt_PVHV) {
            HV *ap = (HV *)SvRV(appearance_sv);
            SV **v;
            if ((v = hv_fetchs(ap, "visible", 0)) && SvTRUE(*v)) config.visible = 1;
            if ((v = hv_fetchs(ap, "page", 0))    && SvOK(*v))   config.page = SvIV(*v);
            if ((v = hv_fetchs(ap, "rect", 0))    && SvROK(*v) &&
                SvTYPE(SvRV(*v)) == SVt_PVAV) {
                AV *r = (AV *)SvRV(*v);
                for (int i = 0; i < 4 && i <= av_len(r); i++) {
                    SV **e = av_fetch(r, i, 0);
                    if (e && SvOK(*e)) config.rect[i] = SvNV(*e);
                }
            }
            if ((v = hv_fetchs(ap, "stream", 0)) && SvOK(*v)) {
                STRLEN sl;
                config.appearance_stream     = (const uint8_t *)SvPVbyte(*v, sl);
                config.appearance_stream_len = (size_t)sl;
            }
            if ((v = hv_fetchs(ap, "show_name",   0)) && SvOK(*v)) config.ap_show_name   = SvTRUE(*v) ? 1 : 0;
            if ((v = hv_fetchs(ap, "show_date",   0)) && SvOK(*v)) config.ap_show_date   = SvTRUE(*v) ? 1 : 0;
            if ((v = hv_fetchs(ap, "show_reason", 0)) && SvOK(*v)) config.ap_show_reason = SvTRUE(*v) ? 1 : 0;

            if ((v = hv_fetchs(ap, "fonts", 0)) && SvROK(*v) &&
                SvTYPE(SvRV(*v)) == SVt_PVHV) {
                HV *fh = (HV *)SvRV(*v);
                I32 keylen;
                char *key;
                SV *val;
                hv_iterinit(fh);
                while ((val = hv_iternextsv(fh, &key, &keylen))) ap_font_count++;
                if (ap_font_count > 0) {
                    ap_names = (char **)calloc(ap_font_count, sizeof(char *));
                    ap_bases = (char **)calloc(ap_font_count, sizeof(char *));
                    size_t i = 0;
                    hv_iterinit(fh);
                    while ((val = hv_iternextsv(fh, &key, &keylen))) {
                        if (!SvOK(val)) continue;
                        ap_names[i] = pdfmake_xs_strndup(aTHX_ key, (size_t)keylen);
                        ap_bases[i] = strdup(SvPV_nolen(val));
                        i++;
                    }
                    config.appearance_font_count = i;
                    config.appearance_font_names = (const char **)ap_names;
                    config.appearance_font_bases = (const char **)ap_bases;
                }
            }

            /* xobjects => { "Im1" => 7, "Im2" => 11, ... } — already-added
             * indirect object numbers referenced from the appearance stream.
             * Used e.g. for embedding a scanned scribbled-signature PNG. */
            if ((v = hv_fetchs(ap, "xobjects", 0)) && SvROK(*v) &&
                SvTYPE(SvRV(*v)) == SVt_PVHV) {
                HV *xh = (HV *)SvRV(*v);
                I32 keylen;
                char *key;
                SV *val;
                hv_iterinit(xh);
                while ((val = hv_iternextsv(xh, &key, &keylen))) ap_xo_count++;
                if (ap_xo_count > 0) {
                    ap_xo_names = (char **)calloc(ap_xo_count, sizeof(char *));
                    ap_xo_nums  = (uint32_t *)calloc(ap_xo_count, sizeof(uint32_t));
                    size_t i = 0;
                    hv_iterinit(xh);
                    while ((val = hv_iternextsv(xh, &key, &keylen))) {
                        if (!SvOK(val)) continue;
                        ap_xo_names[i] = pdfmake_xs_strndup(aTHX_ key, (size_t)keylen);
                        ap_xo_nums[i]  = (uint32_t)SvUV(val);
                        i++;
                    }
                    config.appearance_xobject_count = i;
                    config.appearance_xobject_names = (const char **)ap_xo_names;
                    config.appearance_xobject_nums  = ap_xo_nums;
                }
            }
        }

        pdfmake_buf_init(&out);
        pdfmake_err_t err = pdfmake_doc_sign(doc, &config, &out);
        /* Free the font name/base allocations regardless of outcome. */
        if (ap_xo_names) {
            for (size_t i = 0; i < ap_xo_count; i++) Safefree(ap_xo_names[i]);
            free(ap_xo_names);
            free(ap_xo_nums);
        }
        if (ap_names) {
            for (size_t i = 0; i < ap_font_count; i++) {
                Safefree(ap_names[i]);
                if (ap_bases) free(ap_bases[i]);
            }
            free(ap_names);
            free(ap_bases);
        }
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&out);
            croak("PDF::Make::Signature: signing failed (error %d)", err);
        }

        RETVAL = newSVpvn((const char *)pdfmake_buf_data(&out), pdfmake_buf_len(&out));
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_build_tsa_request(hash_alg, digest_sv, cert_req)
    int hash_alg
    SV *digest_sv
    int cert_req
    PREINIT:
        pdfmake_arena_t *arena;
        pdfmake_buf_t out;
        STRLEN dlen;
        const uint8_t *dbytes;
    CODE:
        dbytes = (const uint8_t *)SvPVbyte(digest_sv, dlen);
        arena = pdfmake_arena_new();
        if (!arena) croak("PDF::Make::Signature::_build_tsa_request: arena alloc failed");
        pdfmake_buf_init(&out);
        pdfmake_err_t err = pdfmake_tsa_build_request(
            arena, (pdfmake_hash_algorithm_t)hash_alg,
            dbytes, (size_t)dlen, cert_req, &out);
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&out);
            pdfmake_arena_free(arena);
            croak("PDF::Make::Signature::_build_tsa_request: failed (%d)", err);
        }
        RETVAL = newSVpvn((const char *)pdfmake_buf_data(&out), pdfmake_buf_len(&out));
        pdfmake_buf_free(&out);
        pdfmake_arena_free(arena);
    OUTPUT:
        RETVAL

SV *
_parse_tsa_response(resp_sv)
    SV *resp_sv
    PREINIT:
        pdfmake_arena_t *arena;
        STRLEN rlen;
        const uint8_t *rbytes;
        const uint8_t *token = NULL;
        size_t token_len = 0;
        int rc;
    CODE:
        rbytes = (const uint8_t *)SvPVbyte(resp_sv, rlen);
        arena = pdfmake_arena_new();
        if (!arena) croak("PDF::Make::Signature::_parse_tsa_response: arena alloc failed");
        rc = pdfmake_tsa_parse_response(arena, rbytes, (size_t)rlen,
                                        &token, &token_len);
        if (rc == -2) {
            pdfmake_arena_free(arena);
            croak("PDF::Make::Signature::_parse_tsa_response: TSA rejected request");
        }
        if (rc != 0 || !token) {
            pdfmake_arena_free(arena);
            croak("PDF::Make::Signature::_parse_tsa_response: malformed response");
        }
        RETVAL = newSVpvn((const char *)token, token_len);
        pdfmake_arena_free(arena);
    OUTPUT:
        RETVAL

SV *
_extract_cms_signature(cms_sv)
    SV *cms_sv
    PREINIT:
        pdfmake_arena_t *arena;
        STRLEN clen;
        const uint8_t *cbytes;
        const uint8_t *sig = NULL;
        size_t sig_len = 0;
    CODE:
        cbytes = (const uint8_t *)SvPVbyte(cms_sv, clen);
        arena = pdfmake_arena_new();
        if (!arena) croak("PDF::Make::Signature::_extract_cms_signature: arena alloc failed");
        if (pdfmake_cms_extract_signature(arena, cbytes, (size_t)clen,
                                          &sig, &sig_len) != 0 || !sig) {
            pdfmake_arena_free(arena);
            croak("PDF::Make::Signature::_extract_cms_signature: failed to parse CMS");
        }
        RETVAL = newSVpvn((const char *)sig, sig_len);
        pdfmake_arena_free(arena);
    OUTPUT:
        RETVAL
