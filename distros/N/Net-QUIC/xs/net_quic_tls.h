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

#define NET_QUIC_TICKET_KEY_NAME_LEN 16
#define NET_QUIC_TICKET_KEY_LEN 32
#define NET_QUIC_TICKET_VERSION_LEN 4
#define NET_QUIC_TICKET_NONCE_LEN 12
#define NET_QUIC_TICKET_TAG_LEN 16
#define NET_QUIC_TICKET_LIFETIME 86400

typedef struct net_quic_ticket_encryptor net_quic_ticket_encryptor;

typedef struct net_quic_ticket_replay_entry net_quic_ticket_replay_entry;

struct net_quic_ticket_replay_entry {
    uint64_t fingerprint;
    uint64_t expires_at;
};

struct net_quic_ticket_encryptor {
    ptls_encrypt_ticket_t super;
    uint8_t key_name[NET_QUIC_TICKET_KEY_NAME_LEN];
    uint8_t key[NET_QUIC_TICKET_KEY_LEN];
    net_quic_ticket_replay_entry *used_tickets;
    size_t used_tickets_capacity;
    size_t used_tickets_count;
};

struct net_quic_server_tls {
    ptls_context_t ptls_ctx;
    ptls_openssl_sign_certificate_t sign_cert;
    net_quic_ticket_encryptor ticket_encryptor;
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


static int
net_quic_tls_ticket_encrypt(
    net_quic_ticket_encryptor *self,
    ptls_buffer_t *dst,
    ptls_iovec_t src,
    uint32_t version
)
{
    EVP_CIPHER_CTX *ctx = NULL;
    uint8_t *out;
    uint8_t nonce[NET_QUIC_TICKET_NONCE_LEN];
    uint8_t aad[
        NET_QUIC_TICKET_KEY_NAME_LEN + NET_QUIC_TICKET_VERSION_LEN
    ];
    int outlen = 0;
    int final_len = 0;
    int aad_len = 0;
    int ret = PTLS_ERROR_LIBRARY;

    if (src.len > INT_MAX ||
        src.len > SIZE_MAX
            - NET_QUIC_TICKET_KEY_NAME_LEN
            - NET_QUIC_TICKET_VERSION_LEN
            - NET_QUIC_TICKET_NONCE_LEN
            - NET_QUIC_TICKET_TAG_LEN) {
        return PTLS_ERROR_LIBRARY;
    }

    if (net_quic_random_bytes(nonce, sizeof(nonce)) != 0) {
        return PTLS_ERROR_LIBRARY;
    }

    if (ptls_buffer_reserve(
            dst,
            NET_QUIC_TICKET_KEY_NAME_LEN
                + NET_QUIC_TICKET_VERSION_LEN
                + NET_QUIC_TICKET_NONCE_LEN
                + src.len
                + NET_QUIC_TICKET_TAG_LEN
        ) != 0) {
        return PTLS_ERROR_NO_MEMORY;
    }

    ctx = EVP_CIPHER_CTX_new();
    if (ctx == NULL) {
        return PTLS_ERROR_NO_MEMORY;
    }

    out = dst->base + dst->off;
    memcpy(out, self->key_name, NET_QUIC_TICKET_KEY_NAME_LEN);
    out[NET_QUIC_TICKET_KEY_NAME_LEN + 0] = (uint8_t)(version >> 24);
    out[NET_QUIC_TICKET_KEY_NAME_LEN + 1] = (uint8_t)(version >> 16);
    out[NET_QUIC_TICKET_KEY_NAME_LEN + 2] = (uint8_t)(version >> 8);
    out[NET_QUIC_TICKET_KEY_NAME_LEN + 3] = (uint8_t)version;

    memcpy(aad, out, sizeof(aad));

    memcpy(
        out + NET_QUIC_TICKET_KEY_NAME_LEN + NET_QUIC_TICKET_VERSION_LEN,
        nonce,
        NET_QUIC_TICKET_NONCE_LEN
    );

    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL) != 1 ||
        EVP_CIPHER_CTX_ctrl(
            ctx,
            EVP_CTRL_GCM_SET_IVLEN,
            NET_QUIC_TICKET_NONCE_LEN,
            NULL
        ) != 1 ||
        EVP_EncryptInit_ex(ctx, NULL, NULL, self->key, nonce) != 1 ||
        EVP_EncryptUpdate(
            ctx,
            NULL,
            &aad_len,
            aad,
            (int)sizeof(aad)
        ) != 1 ||
        EVP_EncryptUpdate(
            ctx,
            out + NET_QUIC_TICKET_KEY_NAME_LEN
                + NET_QUIC_TICKET_VERSION_LEN
                + NET_QUIC_TICKET_NONCE_LEN,
            &outlen,
            src.base,
            (int)src.len
        ) != 1 ||
        EVP_EncryptFinal_ex(
            ctx,
            out + NET_QUIC_TICKET_KEY_NAME_LEN
                + NET_QUIC_TICKET_VERSION_LEN
                + NET_QUIC_TICKET_NONCE_LEN
                + outlen,
            &final_len
        ) != 1 ||
        EVP_CIPHER_CTX_ctrl(
            ctx,
            EVP_CTRL_GCM_GET_TAG,
            NET_QUIC_TICKET_TAG_LEN,
            out + NET_QUIC_TICKET_KEY_NAME_LEN
                + NET_QUIC_TICKET_VERSION_LEN
                + NET_QUIC_TICKET_NONCE_LEN
                + outlen
                + final_len
        ) != 1) {
        goto Exit;
    }

    dst->off += NET_QUIC_TICKET_KEY_NAME_LEN
        + NET_QUIC_TICKET_VERSION_LEN
        + NET_QUIC_TICKET_NONCE_LEN
        + (size_t)outlen
        + (size_t)final_len
        + NET_QUIC_TICKET_TAG_LEN;
    ret = 0;

Exit:
    EVP_CIPHER_CTX_free(ctx);
    return ret;
}

static int
net_quic_tls_ticket_decrypt(
    net_quic_ticket_encryptor *self,
    ptls_buffer_t *dst,
    ptls_iovec_t src,
    uint32_t expected_version
)
{
    EVP_CIPHER_CTX *ctx = NULL;
    const uint8_t *nonce;
    const uint8_t *ciphertext;
    uint8_t aad[
        NET_QUIC_TICKET_KEY_NAME_LEN + NET_QUIC_TICKET_VERSION_LEN
    ];
    uint32_t stored_version;
    const uint8_t *tag;
    size_t ciphertext_len;
    int outlen = 0;
    int final_len = 0;
    int aad_len = 0;
    int ret = PTLS_ALERT_HANDSHAKE_FAILURE;

    if (src.len < NET_QUIC_TICKET_KEY_NAME_LEN
            + NET_QUIC_TICKET_VERSION_LEN
            + NET_QUIC_TICKET_NONCE_LEN
            + NET_QUIC_TICKET_TAG_LEN ||
        !ptls_mem_equal(
            src.base,
            self->key_name,
            NET_QUIC_TICKET_KEY_NAME_LEN
        )) {
        return PTLS_ALERT_HANDSHAKE_FAILURE;
    }

    stored_version =
        ((uint32_t)src.base[NET_QUIC_TICKET_KEY_NAME_LEN + 0] << 24) |
        ((uint32_t)src.base[NET_QUIC_TICKET_KEY_NAME_LEN + 1] << 16) |
        ((uint32_t)src.base[NET_QUIC_TICKET_KEY_NAME_LEN + 2] << 8) |
        (uint32_t)src.base[NET_QUIC_TICKET_KEY_NAME_LEN + 3];

    if (stored_version != expected_version) {
        return PTLS_ALERT_HANDSHAKE_FAILURE;
    }

    memcpy(aad, src.base, sizeof(aad));

    nonce = src.base
        + NET_QUIC_TICKET_KEY_NAME_LEN
        + NET_QUIC_TICKET_VERSION_LEN;
    ciphertext = nonce + NET_QUIC_TICKET_NONCE_LEN;
    ciphertext_len = src.len
        - NET_QUIC_TICKET_KEY_NAME_LEN
        - NET_QUIC_TICKET_VERSION_LEN
        - NET_QUIC_TICKET_NONCE_LEN
        - NET_QUIC_TICKET_TAG_LEN;
    tag = ciphertext + ciphertext_len;

    if (ciphertext_len > INT_MAX) {
        return PTLS_ALERT_HANDSHAKE_FAILURE;
    }

    if (ptls_buffer_reserve(dst, ciphertext_len) != 0) {
        return PTLS_ERROR_NO_MEMORY;
    }

    ctx = EVP_CIPHER_CTX_new();
    if (ctx == NULL) {
        return PTLS_ERROR_NO_MEMORY;
    }

    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL) != 1 ||
        EVP_CIPHER_CTX_ctrl(
            ctx,
            EVP_CTRL_GCM_SET_IVLEN,
            NET_QUIC_TICKET_NONCE_LEN,
            NULL
        ) != 1 ||
        EVP_DecryptInit_ex(ctx, NULL, NULL, self->key, nonce) != 1 ||
        EVP_DecryptUpdate(
            ctx,
            NULL,
            &aad_len,
            aad,
            (int)sizeof(aad)
        ) != 1 ||
        EVP_DecryptUpdate(
            ctx,
            dst->base + dst->off,
            &outlen,
            ciphertext,
            (int)ciphertext_len
        ) != 1 ||
        EVP_CIPHER_CTX_ctrl(
            ctx,
            EVP_CTRL_GCM_SET_TAG,
            NET_QUIC_TICKET_TAG_LEN,
            (void *)tag
        ) != 1 ||
        EVP_DecryptFinal_ex(
            ctx,
            dst->base + dst->off + outlen,
            &final_len
        ) != 1) {
        goto Exit;
    }

    dst->off += (size_t)outlen + (size_t)final_len;
    ret = 0;

Exit:
    EVP_CIPHER_CTX_free(ctx);
    return ret;
}

static uint64_t
net_quic_tls_ticket_fingerprint(ptls_iovec_t ticket)
{
    uint8_t digest[32];
    unsigned int digest_len = 0;
    uint64_t value;

    if (EVP_Digest(
            ticket.base,
            ticket.len,
            digest,
            &digest_len,
            EVP_sha256(),
            NULL
        ) != 1 ||
        digest_len != sizeof(digest)) {
        return 0;
    }

    memcpy(&value, digest, sizeof(value));
    ptls_clear_memory(digest, sizeof(digest));

    return value != 0 ? value : 1;
}

static size_t
net_quic_tls_ticket_slot(uint64_t value, size_t capacity)
{
    value ^= value >> 30;
    value *= UINT64_C(0xbf58476d1ce4e5b9);
    value ^= value >> 27;
    value *= UINT64_C(0x94d049bb133111eb);
    value ^= value >> 31;

    return (size_t)value & (capacity - 1);
}

static void
net_quic_tls_ticket_replay_insert_raw(
    net_quic_ticket_replay_entry *table,
    size_t capacity,
    uint64_t fingerprint,
    uint64_t expires_at
)
{
    size_t slot = net_quic_tls_ticket_slot(fingerprint, capacity);

    while (table[slot].fingerprint != 0) {
        slot = (slot + 1) & (capacity - 1);
    }

    table[slot].fingerprint = fingerprint;
    table[slot].expires_at = expires_at;
}

static int
net_quic_tls_ticket_replay_rebuild(
    net_quic_ticket_encryptor *self,
    uint64_t now
)
{
    net_quic_ticket_replay_entry *new_table;
    size_t new_capacity;
    size_t live_count = 0;
    size_t i;

    new_capacity = self->used_tickets_capacity;

    for (i = 0; i < self->used_tickets_capacity; ++i) {
        if (self->used_tickets[i].fingerprint != 0 &&
            self->used_tickets[i].expires_at > now) {
            ++live_count;
        }
    }

    if ((live_count + 1) * 10 >= new_capacity * 7) {
        if (new_capacity > SIZE_MAX / 2) {
            return -1;
        }
        new_capacity *= 2;
    }

    new_table = net_quic_system_calloc(new_capacity, sizeof(*new_table));
    if (new_table == NULL) {
        return -1;
    }

    for (i = 0; i < self->used_tickets_capacity; ++i) {
        if (self->used_tickets[i].fingerprint != 0 &&
            self->used_tickets[i].expires_at > now) {
            net_quic_tls_ticket_replay_insert_raw(
                new_table,
                new_capacity,
                self->used_tickets[i].fingerprint,
                self->used_tickets[i].expires_at
            );
        }
    }

    net_quic_system_free(self->used_tickets);
    self->used_tickets = new_table;
    self->used_tickets_capacity = new_capacity;
    self->used_tickets_count = live_count;

    return 0;
}

static int
net_quic_tls_ticket_replay_check(
    net_quic_ticket_encryptor *self,
    ptls_iovec_t ticket
)
{
    uint64_t fingerprint;
    uint64_t now;
    uint64_t expires_at;
    size_t slot;
    time_t wall_now;

    fingerprint = net_quic_tls_ticket_fingerprint(ticket);
    if (fingerprint == 0) {
        return -1;
    }

    wall_now = time(NULL);
    if (wall_now == (time_t)-1) {
        return -1;
    }
    now = (uint64_t)wall_now;
    expires_at = now + NET_QUIC_TICKET_LIFETIME;

    if (self->used_tickets_capacity == 0) {
        self->used_tickets_capacity = 1024;
        self->used_tickets = net_quic_system_calloc(
            self->used_tickets_capacity,
            sizeof(*self->used_tickets)
        );
        if (self->used_tickets == NULL) {
            self->used_tickets_capacity = 0;
            return -1;
        }
    }

RetryLookup:
    slot = net_quic_tls_ticket_slot(
        fingerprint,
        self->used_tickets_capacity
    );

    while (self->used_tickets[slot].fingerprint != 0) {
        if (self->used_tickets[slot].fingerprint == fingerprint) {
            if (self->used_tickets[slot].expires_at > now) {
                return 1;
            }

            self->used_tickets[slot].expires_at = expires_at;
            return 0;
        }

        slot = (slot + 1) & (self->used_tickets_capacity - 1);
    }

    if ((self->used_tickets_count + 1) * 10
            >= self->used_tickets_capacity * 7) {
        if (net_quic_tls_ticket_replay_rebuild(self, now) != 0) {
            return -1;
        }
        goto RetryLookup;
    }

    self->used_tickets[slot].fingerprint = fingerprint;
    self->used_tickets[slot].expires_at = expires_at;
    ++self->used_tickets_count;

    return 0;
}

static int
net_quic_tls_encrypt_ticket(
    ptls_encrypt_ticket_t *base,
    ptls_t *ptls,
    int is_encrypt,
    ptls_buffer_t *dst,
    ptls_iovec_t src
)
{
    net_quic_ticket_encryptor *self =
        (net_quic_ticket_encryptor *)base;

    ngtcp2_crypto_conn_ref *conn_ref;
    net_quic_connection *ep;
    uint32_t version;
    int rv;
    int replay;

    conn_ref = (ngtcp2_crypto_conn_ref *)*ptls_get_data_ptr(ptls);
    if (conn_ref == NULL || conn_ref->user_data == NULL) {
        return PTLS_ERROR_LIBRARY;
    }

    ep = (net_quic_connection *)conn_ref->user_data;

    if (is_encrypt) {
        version = ngtcp2_conn_get_negotiated_version2(ep->conn);
        if (version == 0) {
            version = ngtcp2_conn_get_client_chosen_version2(ep->conn);
        }
        if (version == 0) {
            return PTLS_ERROR_LIBRARY;
        }

        return net_quic_tls_ticket_encrypt(self, dst, src, version);
    }

    version = ngtcp2_conn_get_client_chosen_version2(ep->conn);
    if (version == 0) {
        return PTLS_ALERT_HANDSHAKE_FAILURE;
    }

    rv = net_quic_tls_ticket_decrypt(self, dst, src, version);
    if (rv != 0) {
        return rv;
    }

    replay = net_quic_tls_ticket_replay_check(self, src);
    if (replay != 0) {
        /*
         * The ticket decrypted successfully, so TLS resumption remains
         * available.  Refuse only 0-RTT when the ticket was already used or
         * when replay tracking cannot safely record it.
         */
        return PTLS_ERROR_REJECT_EARLY_DATA;
    }

    return 0;
}

static int
net_quic_tls_save_ticket(
    ptls_save_ticket_t *base,
    ptls_t *ptls,
    ptls_iovec_t input
)
{
    dTHX;
    ngtcp2_crypto_conn_ref *conn_ref;
    net_quic_connection *ep;
    uint8_t *copy;

    (void)base;

    conn_ref = (ngtcp2_crypto_conn_ref *)*ptls_get_data_ptr(ptls);
    if (conn_ref == NULL || conn_ref->user_data == NULL || input.len == 0) {
        return PTLS_ERROR_LIBRARY;
    }

    ep = (net_quic_connection *)conn_ref->user_data;

    Newx(copy, input.len, uint8_t);
    if (copy == NULL) {
        return PTLS_ERROR_NO_MEMORY;
    }

    memcpy(copy, input.base, input.len);

    if (ep->session_ticket != NULL) {
        ptls_clear_memory(ep->session_ticket, ep->session_ticket_len);
        Safefree(ep->session_ticket);
    }

    ep->session_ticket = copy;
    ep->session_ticket_len = input.len;
    ep->session_ticket_version =
        ngtcp2_conn_get_negotiated_version2(ep->conn);

    if (ep->session_ticket_version == 0) {
        ep->session_ticket_version =
            ngtcp2_conn_get_client_chosen_version2(ep->conn);
    }

    if (ep->session_ticket_version == 0) {
        ptls_clear_memory(ep->session_ticket, ep->session_ticket_len);
        Safefree(ep->session_ticket);
        ep->session_ticket = NULL;
        ep->session_ticket_len = 0;
        return PTLS_ERROR_LIBRARY;
    }

    return 0;
}

static ptls_save_ticket_t net_quic_tls_save_ticket_cb = {
    net_quic_tls_save_ticket
};

static const char *
net_quic_tls_client_prepare(net_quic_connection *ep, const char *ca_file)
{
    net_quic_tls_context_defaults(&ep->ptls_ctx);

    if (ngtcp2_crypto_picotls_configure_client_context(&ep->ptls_ctx) != 0) {
        return "unable to configure Picotls client context";
    }

    ep->ptls_ctx.save_ticket = &net_quic_tls_save_ticket_cb;

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

    if (ep->resume_ticket_len != 0) {
        ep->picotls_ctx.handshake_properties.client.session_ticket =
            ptls_iovec_init(ep->resume_ticket, ep->resume_ticket_len);
    }

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

    /*
     * Accept the client's SNI into the Picotls session.  Picotls includes
     * this value in the session-ticket context, which prevents a ticket
     * issued for one server name from resuming under a different name.
     */
    if (params->server_name.len != 0 &&
        ptls_set_server_name(
            ptls,
            (const char *)params->server_name.base,
            params->server_name.len
        ) != 0) {
        return PTLS_ALERT_INTERNAL_ERROR;
    }

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
    const char *key_file,
    int accept_early_data
)
{
    FILE *fp;
    EVP_PKEY *pkey;

    net_quic_tls_context_defaults(&tls->ptls_ctx);
    tls->ptls_ctx.on_client_hello = &net_quic_tls_client_hello_cb;

    if (ngtcp2_crypto_picotls_configure_server_context(&tls->ptls_ctx) != 0) {
        return "unable to configure Picotls server context";
    }

    tls->ticket_encryptor.super.cb = net_quic_tls_encrypt_ticket;
    if (net_quic_random_bytes(
            tls->ticket_encryptor.key_name,
            sizeof(tls->ticket_encryptor.key_name)
        ) != 0 ||
        net_quic_random_bytes(
            tls->ticket_encryptor.key,
            sizeof(tls->ticket_encryptor.key)
        ) != 0) {
        return "unable to generate TLS session ticket key";
    }

    tls->ptls_ctx.encrypt_ticket = &tls->ticket_encryptor.super;
    tls->ptls_ctx.ticket_lifetime = NET_QUIC_TICKET_LIFETIME;
    tls->ptls_ctx.max_early_data_size =
        accept_early_data ? UINT32_MAX : 0;

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

    ptls_clear_memory(
        tls->ticket_encryptor.key,
        sizeof(tls->ticket_encryptor.key)
    );
    ptls_clear_memory(
        tls->ticket_encryptor.key_name,
        sizeof(tls->ticket_encryptor.key_name)
    );

    net_quic_system_free(tls->ticket_encryptor.used_tickets);
    tls->ticket_encryptor.used_tickets = NULL;
    tls->ticket_encryptor.used_tickets_capacity = 0;
    tls->ticket_encryptor.used_tickets_count = 0;
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
