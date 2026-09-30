static ptls_key_exchange_algorithm_t *net_quic_picotls_key_exchanges[] = {
#if PTLS_OPENSSL_HAVE_X25519
    &ptls_openssl_x25519,
#endif
    &ptls_openssl_secp256r1,
    &ptls_openssl_secp384r1,
    &ptls_openssl_secp521r1,
#if PTLS_OPENSSL_HAVE_X25519MLKEM768
    &ptls_openssl_x25519mlkem768,
#endif
    NULL,
};

static ptls_cipher_suite_t *net_quic_picotls_cipher_suites[] = {
    &ptls_openssl_aes128gcmsha256,
    &ptls_openssl_aes256gcmsha384,
#if PTLS_OPENSSL_HAVE_CHACHA20_POLY1305
    &ptls_openssl_chacha20poly1305sha256,
#endif
    NULL,
};

struct net_quic_server_tls {
    ptls_context_t ptls_ctx;
    ptls_openssl_sign_certificate_t sign_cert;
    int sign_cert_ready;
};

static void
net_quic_tls_context_defaults(ptls_context_t *ctx)
{
    memset(ctx, 0, sizeof(*ctx));
    ctx->random_bytes = ptls_openssl_random_bytes;
    ctx->get_time = &ptls_get_time;
    ctx->key_exchanges = net_quic_picotls_key_exchanges;
    ctx->cipher_suites = net_quic_picotls_cipher_suites;
    ctx->require_dhe_on_psk = 1;
}

static const char *
net_quic_tls_client_prepare(net_quic_connection *ep, const char *ca_file)
{
    net_quic_tls_context_defaults(&ep->ptls_ctx);

    if (ngtcp2_crypto_picotls_configure_client_context(&ep->ptls_ctx) != 0) {
        return "unable to configure Picotls client context";
    }

    if (ptls_openssl_init_verify_certificate(
            &ep->picotls_verify_cert,
            NULL
        ) != 0) {
        return "unable to initialize Picotls certificate verifier";
    }
    ep->picotls_verify_cert_ready = 1;

    if (ca_file[0] != '\0' &&
        X509_STORE_load_locations(
            ep->picotls_verify_cert.cert_store,
            ca_file,
            NULL
        ) != 1) {
        return "unable to load client CA file";
    }

    ep->ptls_ctx.verify_certificate = &ep->picotls_verify_cert.super;

    ngtcp2_crypto_picotls_ctx_init(&ep->picotls_ctx);
    ep->picotls_ctx.ptls = ptls_client_new(&ep->ptls_ctx);
    if (ep->picotls_ctx.ptls == NULL) {
        return "unable to create Picotls client session";
    }

    *ptls_get_data_ptr(ep->picotls_ctx.ptls) = &ep->conn_ref;

    return NULL;
}

static int
net_quic_tls_alloc_extensions(pTHX_ net_quic_connection *ep)
{
    Newxz(
        ep->picotls_ctx.handshake_properties.additional_extensions,
        2,
        ptls_raw_extension_t
    );
    if (ep->picotls_ctx.handshake_properties.additional_extensions == NULL) {
        return -1;
    }

    ep->picotls_ctx.handshake_properties.additional_extensions[0].type = UINT16_MAX;
    ep->picotls_ctx.handshake_properties.additional_extensions[1].type = UINT16_MAX;

    return 0;
}

static int
net_quic_tls_client_finish(pTHX_ net_quic_connection *ep)
{
    if (ep->alpnlen == 0 || ep->alpnlen > 255) {
        return -1;
    }

    if (net_quic_tls_alloc_extensions(aTHX_ ep) != 0) {
        return -1;
    }

    if (ngtcp2_crypto_picotls_configure_client_session(&ep->picotls_ctx, ep->conn) != 0) {
        return -1;
    }

    ep->picotls_alpn.base = (uint8_t *)ep->alpn;
    ep->picotls_alpn.len = ep->alpnlen;
    ep->picotls_ctx.handshake_properties.client.negotiated_protocols.list =
        &ep->picotls_alpn;
    ep->picotls_ctx.handshake_properties.client.negotiated_protocols.count = 1;

    if (ep->server_name[0] != '\0' &&
        ptls_set_server_name(
            ep->picotls_ctx.ptls,
            ep->server_name,
            strlen(ep->server_name)
        ) != 0) {
        return -1;
    }

    ngtcp2_conn_set_tls_native_handle(ep->conn, &ep->picotls_ctx);
    return 0;
}

static int
net_quic_tls_on_client_hello(
    ptls_on_client_hello_t *self,
    ptls_t *ptls,
    ptls_on_client_hello_parameters_t *params
)
{
    ngtcp2_crypto_conn_ref *conn_ref;
    net_quic_connection *ep;
    size_t i;

    (void)self;

    conn_ref = (ngtcp2_crypto_conn_ref *)*ptls_get_data_ptr(ptls);
    if (conn_ref == NULL || conn_ref->user_data == NULL) {
        return PTLS_ALERT_INTERNAL_ERROR;
    }

    ep = (net_quic_connection *)conn_ref->user_data;

    for (i = 0; i < params->negotiated_protocols.count; ++i) {
        ptls_iovec_t proto = params->negotiated_protocols.list[i];

        if (proto.len == ep->alpnlen &&
            memcmp(proto.base, ep->alpn, ep->alpnlen) == 0) {
            return ptls_set_negotiated_protocol(
                ptls,
                (const char *)proto.base,
                proto.len
            );
        }
    }

    return PTLS_ALERT_NO_APPLICATION_PROTOCOL;
}

static ptls_on_client_hello_t net_quic_tls_client_hello_cb = {
    net_quic_tls_on_client_hello
};

static const char *
net_quic_server_tls_init(
    net_quic_server_tls *tls,
    const char *cert_file,
    const char *key_file
)
{
    FILE *fp;
    EVP_PKEY *pkey;

    net_quic_tls_context_defaults(&tls->ptls_ctx);
    tls->ptls_ctx.on_client_hello = &net_quic_tls_client_hello_cb;

    if (ngtcp2_crypto_picotls_configure_server_context(&tls->ptls_ctx) != 0) {
        return "unable to configure Picotls server context";
    }

    if (ptls_load_certificates(&tls->ptls_ctx, cert_file) != 0) {
        return "unable to load Picotls server certificate";
    }

    fp = net_quic_system_fopen(key_file, "rb");
    if (fp == NULL) {
        return "unable to open Picotls server private key";
    }

    pkey = PEM_read_PrivateKey(fp, NULL, NULL, NULL);
    net_quic_system_fclose(fp);
    if (pkey == NULL) {
        return "unable to parse Picotls server private key";
    }

    if (ptls_openssl_init_sign_certificate(&tls->sign_cert, pkey) != 0) {
        EVP_PKEY_free(pkey);
        return "unable to initialize Picotls signing certificate";
    }
    EVP_PKEY_free(pkey);

    tls->sign_cert_ready = 1;
    tls->ptls_ctx.sign_certificate = &tls->sign_cert.super;

    return NULL;
}

static void
net_quic_server_tls_dispose(net_quic_server_tls *tls)
{
    size_t i;

    if (tls == NULL) {
        return;
    }

    if (tls->sign_cert_ready) {
        ptls_openssl_dispose_sign_certificate(&tls->sign_cert);
        tls->sign_cert_ready = 0;
    }

    for (i = 0; i < tls->ptls_ctx.certificates.count; ++i) {
        net_quic_system_free(tls->ptls_ctx.certificates.list[i].base);
    }
    net_quic_system_free(tls->ptls_ctx.certificates.list);
    tls->ptls_ctx.certificates.list = NULL;
    tls->ptls_ctx.certificates.count = 0;
}

static const char *
net_quic_tls_server_prepare(
    net_quic_connection *ep,
    net_quic_server_tls *tls
)
{
    ngtcp2_crypto_picotls_ctx_init(&ep->picotls_ctx);
    ep->picotls_ctx.ptls = ptls_server_new(&tls->ptls_ctx);
    if (ep->picotls_ctx.ptls == NULL) {
        return "unable to create Picotls server session";
    }

    *ptls_get_data_ptr(ep->picotls_ctx.ptls) = &ep->conn_ref;

    return NULL;
}

static int
net_quic_tls_server_finish(pTHX_ net_quic_connection *ep)
{
    if (net_quic_tls_alloc_extensions(aTHX_ ep) != 0) {
        return -1;
    }

    if (ngtcp2_crypto_picotls_configure_server_session(&ep->picotls_ctx) != 0) {
        return -1;
    }

    ngtcp2_conn_set_tls_native_handle(ep->conn, &ep->picotls_ctx);
    return 0;
}

static void
net_quic_tls_cleanup(pTHX_ net_quic_connection *ep)
{
    ngtcp2_crypto_picotls_deconfigure_session(&ep->picotls_ctx);
    Safefree(ep->picotls_ctx.handshake_properties.additional_extensions);
    ep->picotls_ctx.handshake_properties.additional_extensions = NULL;

    if (ep->picotls_ctx.ptls != NULL) {
        *ptls_get_data_ptr(ep->picotls_ctx.ptls) = NULL;
        ptls_free(ep->picotls_ctx.ptls);
        ep->picotls_ctx.ptls = NULL;
    }

    if (!ep->is_server && ep->picotls_verify_cert_ready) {
        ptls_openssl_dispose_verify_certificate(&ep->picotls_verify_cert);
        ep->picotls_verify_cert.cert_store = NULL;
        ep->picotls_verify_cert_ready = 0;
    }

}
