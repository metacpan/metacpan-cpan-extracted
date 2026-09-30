#include "xs/net_quic_connection.h"

static int
net_quic_stream_close_limit_cb(
    ngtcp2_conn *conn,
    uint32_t flags,
    int64_t stream_id,
    uint64_t app_error_code,
    void *user_data,
    void *stream_user_data
)
{
    net_quic_connection *ep = (net_quic_connection *)user_data;
    int rv;

    rv = net_quic_stream_close_cb(
        conn,
        flags,
        stream_id,
        app_error_code,
        user_data,
        stream_user_data
    );
    if (rv != 0) {
        return rv;
    }

    if (!net_quic_stream_id_is_local(ep, stream_id)) {
        if (net_quic_stream_id_is_bidirectional(stream_id)) {
            ngtcp2_conn_extend_max_streams_bidi(conn, 1);
        } else {
            ngtcp2_conn_extend_max_streams_uni(conn, 1);
        }
    }

    return 0;
}

static int
net_quic_start_error_close(
    net_quic_connection *ep,
    int rv,
    ngtcp2_tstamp now
)
{
    ngtcp2_ccerr ccerr;
    ngtcp2_path_storage ps;
    ngtcp2_pkt_info pi;
    ngtcp2_ssize nwrite;

    ngtcp2_ccerr_default(&ccerr);

    if (rv == NGTCP2_ERR_CRYPTO) {
        ngtcp2_ccerr_set_tls_alert(
            &ccerr,
            ngtcp2_conn_get_tls_alert(ep->conn),
            NULL,
            0
        );
    } else {
        ngtcp2_ccerr_set_liberr(&ccerr, rv, NULL, 0);
    }

    ngtcp2_path_storage_zero(&ps);
    memset(&pi, 0, sizeof(pi));

    nwrite = ngtcp2_conn_write_connection_close(
        ep->conn,
        &ps.path,
        &pi,
        ep->txbuf,
        sizeof(ep->txbuf),
        &ccerr,
        now
    );
    if (nwrite == NGTCP2_ERR_INVALID_STATE) {
        ep->retired = 1;
        ep->close_wait = 0;
        return 0;
    }

    if (nwrite < 0) {
        return (int)nwrite;
    }

    if (nwrite > 0) {
        if (net_quic_copy_ngtcp2_addr(
                &ep->close_local_addr,
                &ep->close_local_addrlen,
                &ps.path.local
            ) != 0 ||
            net_quic_copy_ngtcp2_addr(
                &ep->close_peer_addr,
                &ep->close_peer_addrlen,
                &ps.path.remote
            ) != 0) {
            return NGTCP2_ERR_INTERNAL;
        }

        ep->closebuflen = (size_t)nwrite;
        ep->closebuf_pending = 1;
    }

    net_quic_start_close_wait(ep, now);
    return 0;
}

static UV
net_quic_transport_value(AV *av, SSize_t index)
{
    SV **svp = av_fetch(av, index, 0);

    if (svp == NULL || !SvOK(*svp)) {
        croak("invalid internal transport configuration");
    }

    return SvUV(*svp);
}

static void
net_quic_apply_transport_config(
    ngtcp2_settings *settings,
    ngtcp2_transport_params *params,
    SV *transport_sv
)
{
    AV *av;
    UV handshake_ms;
    UV idle_ms;
    UV connection_window;
    UV stream_window;
    UV max_bidi_streams;
    UV max_uni_streams;

    if (!SvOK(transport_sv)) {
        settings->handshake_timeout = 10 * NGTCP2_SECONDS;
        params->max_idle_timeout = 30 * NGTCP2_SECONDS;
        params->initial_max_stream_data_bidi_local = 256 * 1024;
        params->initial_max_stream_data_bidi_remote = 256 * 1024;
        params->initial_max_stream_data_uni = 256 * 1024;
        params->initial_max_data = 1024 * 1024;
        params->initial_max_streams_bidi = 100;
        params->initial_max_streams_uni = 100;
        params->active_connection_id_limit = 4;
        params->disable_active_migration = 1;
        return;
    }

    if (!SvROK(transport_sv) ||
        SvTYPE(SvRV(transport_sv)) != SVt_PVAV) {
        croak("invalid internal transport configuration");
    }

    av = (AV *)SvRV(transport_sv);
    if (av_len(av) != 5) {
        croak("invalid internal transport configuration");
    }

    handshake_ms = net_quic_transport_value(av, 0);
    idle_ms = net_quic_transport_value(av, 1);
    connection_window = net_quic_transport_value(av, 2);
    stream_window = net_quic_transport_value(av, 3);
    max_bidi_streams = net_quic_transport_value(av, 4);
    max_uni_streams = net_quic_transport_value(av, 5);

    if (handshake_ms == 0 ||
        handshake_ms > UINT64_MAX / NGTCP2_MILLISECONDS) {
        croak("handshake_timeout is outside the supported range");
    }
    if (idle_ms > NGTCP2_MAX_VARINT ||
        idle_ms > UINT64_MAX / NGTCP2_MILLISECONDS) {
        croak("idle_timeout is outside the supported range");
    }
    if (connection_window > NGTCP2_MAX_VARINT) {
        croak("connection_window is outside the supported range");
    }
    if (stream_window > NGTCP2_MAX_VARINT) {
        croak("stream_window is outside the supported range");
    }
    if (max_bidi_streams > NGTCP2_MAX_VARINT) {
        croak("max_bidi_streams is outside the supported range");
    }
    if (max_uni_streams > NGTCP2_MAX_VARINT) {
        croak("max_uni_streams is outside the supported range");
    }

    settings->handshake_timeout =
        (ngtcp2_duration)handshake_ms * NGTCP2_MILLISECONDS;

    params->max_idle_timeout =
        (ngtcp2_duration)idle_ms * NGTCP2_MILLISECONDS;
    params->initial_max_stream_data_bidi_local = stream_window;
    params->initial_max_stream_data_bidi_remote = stream_window;
    params->initial_max_stream_data_uni = stream_window;
    params->initial_max_data = connection_window;
    params->initial_max_streams_bidi = max_bidi_streams;
    params->initial_max_streams_uni = max_uni_streams;
    params->active_connection_id_limit = 4;
    params->disable_active_migration = 1;
}

static net_quic_server_tls *
net_quic_server_tls_from_sv(SV *self)
{
    net_quic_server_tls *tls;

    if (!SvROK(self) ||
        !sv_derived_from(self, "Net::QUIC::_ServerTLS")) {
        croak("not a Net::QUIC::_ServerTLS object");
    }

    tls = INT2PTR(net_quic_server_tls *, SvIV(SvRV(self)));
    if (tls == NULL) {
        croak("Net::QUIC::_ServerTLS has already been destroyed");
    }

    return tls;
}

static SV *
net_quic_server_tls_bless(const char *class, net_quic_server_tls *tls)
{
    SV *inner = newSViv(PTR2IV(tls));
    SV *rv = newRV_noinc(inner);
    sv_bless(rv, gv_stashpv(class, GV_ADD));
    return rv;
}

MODULE = Net::QUIC    PACKAGE = Net::QUIC

PROTOTYPES: DISABLE

const char *
ngtcp2_version()
    PREINIT:
        const ngtcp2_info *info;
    CODE:
        info = ngtcp2_version(0);
        if (info == NULL || info->version_str == NULL) {
            croak("ngtcp2 did not report a version");
        }
        RETVAL = info->version_str;
    OUTPUT:
        RETVAL

int
ngtcp2_version_num()
    PREINIT:
        const ngtcp2_info *info;
    CODE:
        info = ngtcp2_version(0);
        if (info == NULL) {
            croak("ngtcp2 did not report version information");
        }
        RETVAL = info->version_num;
    OUTPUT:
        RETVAL

const char *
crypto_backend()
    CODE:
        RETVAL = net_quic_crypto_backend();
    OUTPUT:
        RETVAL

int
_local_address_is_unspecified(local_sv)
    SV *local_sv
    PREINIT:
        const char *local;
        STRLEN locallen;
        ngtcp2_sockaddr_union local_addr;
        ngtcp2_socklen local_addrlen;
    CODE:
        local = SvPVbyte(local_sv, locallen);

        if (net_quic_copy_sockaddr(
                &local_addr,
                &local_addrlen,
                local,
                locallen
            ) != 0) {
            croak("local must be a packed IPv4 or IPv6 socket address");
        }

        RETVAL = net_quic_sockaddr_is_unspecified(&local_addr) ? 1 : 0;
    OUTPUT:
        RETVAL

int
_crypto_self_test()
    PREINIT:
        uint8_t token[NGTCP2_STATELESS_RESET_TOKENLEN];
        uint8_t secret[32];
        ngtcp2_cid cid;
        int rv;
    CODE:
        memset(token, 0, sizeof(token));
        memset(secret, 0, sizeof(secret));
        memset(&cid, 0, sizeof(cid));

        cid.datalen = 8;

        rv = ngtcp2_crypto_generate_stateless_reset_token(
            token,
            secret,
            sizeof(secret),
            &cid
        );

        RETVAL = rv == 0 ? 1 : 0;
    OUTPUT:
        RETVAL

MODULE = Net::QUIC    PACKAGE = Net::QUIC::_ServerTLS

SV *
_new(class, cert_file_sv, key_file_sv)
    const char *class
    SV *cert_file_sv
    SV *key_file_sv
    PREINIT:
        net_quic_server_tls *tls = NULL;
        const char *cert_file;
        const char *key_file;
        STRLEN cert_file_len;
        STRLEN key_file_len;
        const char *tls_error;
    CODE:
        cert_file = SvPVbyte(cert_file_sv, cert_file_len);
        key_file = SvPVbyte(key_file_sv, key_file_len);

        if (cert_file_len == 0 || key_file_len == 0 ||
            memchr(cert_file, '\0', (size_t)cert_file_len) != NULL ||
            memchr(key_file, '\0', (size_t)key_file_len) != NULL) {
            croak("certificate and key paths must be non-empty and cannot contain NUL");
        }

        Newxz(tls, 1, net_quic_server_tls);
        if (tls == NULL) {
            croak("unable to allocate shared server TLS context");
        }

        tls_error = net_quic_server_tls_init(tls, cert_file, key_file);
        if (tls_error != NULL) {
            net_quic_server_tls_dispose(tls);
            Safefree(tls);
            croak("%s", tls_error);
        }

        RETVAL = net_quic_server_tls_bless(class, tls);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    PREINIT:
        net_quic_server_tls *tls;
        SV *inner;
    CODE:
        if (!SvROK(self)) {
            XSRETURN_EMPTY;
        }

        inner = SvRV(self);
        tls = INT2PTR(net_quic_server_tls *, SvIV(inner));
        if (tls != NULL) {
            net_quic_server_tls_dispose(tls);
            Safefree(tls);
            sv_setiv(inner, 0);
        }

MODULE = Net::QUIC    PACKAGE = Net::QUIC::Connection

SV *
_client_new(class, local_sv, peer_sv, alpn_sv, server_name_sv, ca_file_sv, transport_sv = &PL_sv_undef)
    const char *class
    SV *local_sv
    SV *peer_sv
    SV *alpn_sv
    SV *server_name_sv
    SV *ca_file_sv
    SV *transport_sv
    PREINIT:
        net_quic_connection *ep = NULL;
        const char *local;
        const char *peer;
        const char *alpn;
        const char *server_name;
        const char *ca_file;
        STRLEN locallen;
        STRLEN peerlen;
        STRLEN alpnlen;
        STRLEN server_namelen;
        STRLEN ca_file_len;
        ngtcp2_callbacks callbacks;
        ngtcp2_settings settings;
        ngtcp2_transport_params params;
        ngtcp2_path path;
        ngtcp2_cid dcid;
        ngtcp2_cid scid;
        const char *tls_error;
        int rv;
    CODE:
        local = SvPVbyte(local_sv, locallen);
        peer = SvPVbyte(peer_sv, peerlen);
        alpn = SvPVbyte(alpn_sv, alpnlen);
        server_name = SvPVbyte(server_name_sv, server_namelen);
        ca_file = SvPVbyte(ca_file_sv, ca_file_len);

        if (alpnlen == 0 || alpnlen > 255) {
            croak("alpn must contain 1 to 255 bytes");
        }
        if (server_namelen == 0 ||
            server_namelen > 255 ||
            memchr(server_name, '\0', (size_t)server_namelen) != NULL) {
            croak("server_name must contain 1 to 255 bytes and cannot contain NUL");
        }
        if (memchr(ca_file, '\0', (size_t)ca_file_len) != NULL) {
            croak("ca_file path cannot contain NUL");
        }

        Newxz(ep, 1, net_quic_connection);
        if (ep == NULL) {
            croak("unable to allocate Net::QUIC::Connection");
        }

        if (net_quic_copy_sockaddr(
                &ep->local_addr,
                &ep->local_addrlen,
                local,
                locallen
            ) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("local must be a packed IPv4 or IPv6 socket address");
        }

        if (net_quic_copy_sockaddr(
                &ep->peer_addr,
                &ep->peer_addrlen,
                peer,
                peerlen
            ) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("peer must be a packed IPv4 or IPv6 socket address");
        }

        ep->alpn = net_quic_strdup_len(aTHX_ alpn, (size_t)alpnlen);
        ep->alpnlen = (size_t)alpnlen;
        ep->server_name = net_quic_strdup_len(aTHX_ server_name, (size_t)server_namelen);
        if (ep->alpn == NULL || ep->server_name == NULL) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to allocate Net::QUIC::Connection strings");
        }

        ep->conn_ref.get_conn = net_quic_get_conn;
        ep->conn_ref.user_data = ep;

        tls_error = net_quic_tls_client_prepare(ep, ca_file);
        if (tls_error != NULL) {
            net_quic_connection_free(aTHX_ ep);
            croak("%s", tls_error);
        }

        memset(&callbacks, 0, sizeof(callbacks));
        callbacks.client_initial = ngtcp2_crypto_client_initial_cb;
        callbacks.recv_crypto_data = ngtcp2_crypto_recv_crypto_data_cb;
        callbacks.handshake_completed = net_quic_handshake_completed_cb;
        callbacks.recv_stream_data = net_quic_recv_stream_data_cb;
        callbacks.acked_stream_data_offset = net_quic_acked_stream_data_offset_cb;
        callbacks.stream_open = net_quic_stream_open_cb;
        callbacks.stream_close = net_quic_stream_close_limit_cb;
        callbacks.stream_reset = net_quic_stream_reset_cb;
        callbacks.extend_max_local_streams_bidi =
            net_quic_extend_max_local_streams_bidi_cb;
        callbacks.extend_max_local_streams_uni =
            net_quic_extend_max_local_streams_uni_cb;
        callbacks.encrypt = ngtcp2_crypto_encrypt_cb;
        callbacks.decrypt = ngtcp2_crypto_decrypt_cb;
        callbacks.hp_mask = ngtcp2_crypto_hp_mask_cb;
        callbacks.recv_retry = ngtcp2_crypto_recv_retry_cb;
        callbacks.rand = net_quic_rand_cb;
        callbacks.update_key = ngtcp2_crypto_update_key_cb;
        callbacks.delete_crypto_aead_ctx = ngtcp2_crypto_delete_crypto_aead_ctx_cb;
        callbacks.delete_crypto_cipher_ctx = ngtcp2_crypto_delete_crypto_cipher_ctx_cb;
        callbacks.version_negotiation = ngtcp2_crypto_version_negotiation_cb;
        callbacks.get_new_connection_id2 = net_quic_get_new_connection_id_cb;
        callbacks.get_path_challenge_data2 = ngtcp2_crypto_get_path_challenge_data2_cb;

        if (net_quic_random_bytes(dcid.data, NGTCP2_MIN_INITIAL_DCIDLEN) != 0 ||
            net_quic_random_bytes(scid.data, 16) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to generate QUIC connection IDs");
        }
        dcid.datalen = NGTCP2_MIN_INITIAL_DCIDLEN;
        scid.datalen = 16;

        ngtcp2_settings_default(&settings);
        settings.initial_ts = net_quic_now();

        ngtcp2_transport_params_default(&params);
        net_quic_apply_transport_config(&settings, &params, transport_sv);

        memset(&path, 0, sizeof(path));
        path.local.addr = &ep->local_addr.sa;
        path.local.addrlen = ep->local_addrlen;
        path.remote.addr = &ep->peer_addr.sa;
        path.remote.addrlen = ep->peer_addrlen;

        rv = ngtcp2_conn_client_new(
            &ep->conn,
            &dcid,
            &scid,
            &path,
            NGTCP2_PROTO_VER_V1,
            &callbacks,
            &settings,
            &params,
            NULL,
            ep
        );
        if (rv != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("ngtcp2_conn_client_new failed: %s", ngtcp2_strerror(rv));
        }

        if (net_quic_tls_client_finish(aTHX_ ep) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to configure Picotls for QUIC");
        }

        RETVAL = net_quic_connection_bless(class, ep);
    OUTPUT:
        RETVAL

SV *
_server_new(class, initial_sv, local_sv, peer_sv, alpn_sv, server_tls_sv, odcid_sv = &PL_sv_undef, server_secret_sv = &PL_sv_undef, transport_sv = &PL_sv_undef)
    const char *class
    SV *initial_sv
    SV *local_sv
    SV *peer_sv
    SV *alpn_sv
    SV *server_tls_sv
    SV *odcid_sv
    SV *server_secret_sv
    SV *transport_sv
    PREINIT:
        net_quic_connection *ep = NULL;
        const char *initial;
        const char *local;
        const char *peer;
        const char *alpn;
        net_quic_server_tls *server_tls;
        const char *server_secret_data = NULL;
        STRLEN server_secret_len = 0;
        STRLEN initiallen;
        STRLEN locallen;
        STRLEN peerlen;
        STRLEN alpnlen;
        const char *odcid_data = NULL;
        STRLEN odcid_len = 0;
        ngtcp2_version_cid vcid;
        ngtcp2_pkt_hd hd;
        ngtcp2_callbacks callbacks;
        ngtcp2_settings settings;
        ngtcp2_transport_params params;
        ngtcp2_path path;
        ngtcp2_cid dcid;
        ngtcp2_cid scid;
        const char *tls_error;
        int rv;
    CODE:
        initial = SvPVbyte(initial_sv, initiallen);
        local = SvPVbyte(local_sv, locallen);
        peer = SvPVbyte(peer_sv, peerlen);
        alpn = SvPVbyte(alpn_sv, alpnlen);
        server_tls = net_quic_server_tls_from_sv(server_tls_sv);
        if (SvOK(server_secret_sv)) {
            server_secret_data = SvPVbyte(server_secret_sv, server_secret_len);
            if (server_secret_len != NET_QUIC_SERVER_SECRET_LEN) {
                croak("server secret has invalid length");
            }
        }
        if (SvOK(odcid_sv)) {
            odcid_data = SvPVbyte(odcid_sv, odcid_len);
            if (odcid_len == 0 || odcid_len > NGTCP2_MAX_CIDLEN) {
                croak("original destination connection ID has invalid length");
            }
        }

        if (alpnlen == 0 || alpnlen > 255) {
            croak("alpn must contain 1 to 255 bytes");
        }

        memset(&vcid, 0, sizeof(vcid));
        rv = ngtcp2_pkt_decode_version_cid(
            &vcid,
            (const uint8_t *)initial,
            (size_t)initiallen,
            0
        );
        if (rv != 0) {
            croak("unable to decode client Initial connection IDs: %s", ngtcp2_strerror(rv));
        }

        memset(&hd, 0, sizeof(hd));
        rv = ngtcp2_accept(&hd, (const uint8_t *)initial, (size_t)initiallen);
        if (rv != 0) {
            croak("packet is not an acceptable QUIC Initial");
        }

        if (vcid.scidlen == 0 ||
            vcid.scidlen > NGTCP2_MAX_CIDLEN ||
            vcid.dcidlen > NGTCP2_MAX_CIDLEN) {
            croak("client Initial contains unsupported connection IDs");
        }

        Newxz(ep, 1, net_quic_connection);
        if (ep == NULL) {
            croak("unable to allocate Net::QUIC::Connection");
        }
        ep->is_server = 1;

        if (server_secret_data != NULL) {
            memcpy(
                ep->server_secret,
                server_secret_data,
                sizeof(ep->server_secret)
            );
        } else if (net_quic_random_bytes(
                ep->server_secret,
                sizeof(ep->server_secret)
            ) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to generate server secret");
        }

        if (net_quic_copy_sockaddr(
                &ep->local_addr,
                &ep->local_addrlen,
                local,
                locallen
            ) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("local must be a packed IPv4 or IPv6 socket address");
        }

        if (net_quic_copy_sockaddr(
                &ep->peer_addr,
                &ep->peer_addrlen,
                peer,
                peerlen
            ) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("peer must be a packed IPv4 or IPv6 socket address");
        }

        ep->alpn = net_quic_strdup_len(aTHX_ alpn, (size_t)alpnlen);
        ep->alpnlen = (size_t)alpnlen;
        if (ep->alpn == NULL) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to allocate Net::QUIC::Connection ALPN");
        }

        ep->conn_ref.get_conn = net_quic_get_conn;
        ep->conn_ref.user_data = ep;
        ep->server_tls_owner = newSVsv(server_tls_sv);
        if (ep->server_tls_owner == NULL) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to retain shared server TLS context");
        }

        tls_error = net_quic_tls_server_prepare(ep, server_tls);
        if (tls_error != NULL) {
            net_quic_connection_free(aTHX_ ep);
            croak("%s", tls_error);
        }

        memset(&callbacks, 0, sizeof(callbacks));
        callbacks.recv_client_initial = ngtcp2_crypto_recv_client_initial_cb;
        callbacks.recv_crypto_data = ngtcp2_crypto_recv_crypto_data_cb;
        callbacks.handshake_completed = net_quic_handshake_completed_cb;
        callbacks.recv_stream_data = net_quic_recv_stream_data_cb;
        callbacks.acked_stream_data_offset = net_quic_acked_stream_data_offset_cb;
        callbacks.stream_open = net_quic_stream_open_cb;
        callbacks.stream_close = net_quic_stream_close_limit_cb;
        callbacks.stream_reset = net_quic_stream_reset_cb;
        callbacks.extend_max_local_streams_bidi =
            net_quic_extend_max_local_streams_bidi_cb;
        callbacks.extend_max_local_streams_uni =
            net_quic_extend_max_local_streams_uni_cb;
        callbacks.encrypt = ngtcp2_crypto_encrypt_cb;
        callbacks.decrypt = ngtcp2_crypto_decrypt_cb;
        callbacks.hp_mask = ngtcp2_crypto_hp_mask_cb;
        callbacks.rand = net_quic_rand_cb;
        callbacks.update_key = ngtcp2_crypto_update_key_cb;
        callbacks.delete_crypto_aead_ctx = ngtcp2_crypto_delete_crypto_aead_ctx_cb;
        callbacks.delete_crypto_cipher_ctx = ngtcp2_crypto_delete_crypto_cipher_ctx_cb;
        callbacks.version_negotiation = ngtcp2_crypto_version_negotiation_cb;
        callbacks.get_new_connection_id2 = net_quic_get_new_connection_id_cb;
        callbacks.remove_connection_id = net_quic_remove_connection_id_cb;
        callbacks.get_path_challenge_data2 = ngtcp2_crypto_get_path_challenge_data2_cb;

        ngtcp2_cid_init(&dcid, vcid.scid, vcid.scidlen);

        scid.datalen = NET_QUIC_SERVER_CIDLEN;
        if (net_quic_random_bytes(scid.data, scid.datalen) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to generate server QUIC connection ID");
        }

        ngtcp2_settings_default(&settings);
        settings.initial_ts = net_quic_now();

        if (odcid_data != NULL) {
            if (hd.tokenlen == 0) {
                net_quic_connection_free(aTHX_ ep);
                croak("Retry-validated connection is missing its token");
            }
            settings.token = hd.token;
            settings.tokenlen = hd.tokenlen;
            settings.token_type = NGTCP2_TOKEN_TYPE_RETRY;
        }

        ngtcp2_transport_params_default(&params);
        net_quic_apply_transport_config(&settings, &params, transport_sv);
        params.stateless_reset_token_present = 1;

        rv = ngtcp2_crypto_generate_stateless_reset_token(
            params.stateless_reset_token,
            ep->server_secret,
            sizeof(ep->server_secret),
            &scid
        );
        if (rv != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to generate server stateless reset token");
        }

        if (odcid_data != NULL) {
            ngtcp2_cid_init(
                &params.original_dcid,
                (const uint8_t *)odcid_data,
                (size_t)odcid_len
            );
            ngtcp2_cid_init(&params.retry_scid, hd.dcid.data, hd.dcid.datalen);
            params.retry_scid_present = 1;
        } else {
            ngtcp2_cid_init(&params.original_dcid, vcid.dcid, vcid.dcidlen);
        }
        params.original_dcid_present = 1;

        memset(&path, 0, sizeof(path));
        path.local.addr = &ep->local_addr.sa;
        path.local.addrlen = ep->local_addrlen;
        path.remote.addr = &ep->peer_addr.sa;
        path.remote.addrlen = ep->peer_addrlen;

        rv = ngtcp2_conn_server_new(
            &ep->conn,
            &dcid,
            &scid,
            &path,
            vcid.version,
            &callbacks,
            &settings,
            &params,
            NULL,
            ep
        );
        if (rv != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("ngtcp2_conn_server_new failed: %s", ngtcp2_strerror(rv));
        }

        if (net_quic_queue_cid_event(aTHX_ ep, 1, &scid) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to register server QUIC connection ID");
        }

        if (net_quic_tls_server_finish(aTHX_ ep) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to configure Picotls server session");
        }

        RETVAL = net_quic_connection_bless(class, ep);
    OUTPUT:
        RETVAL

SV *
_open_stream(self, bidirectional)
    SV *self
    int bidirectional
    PREINIT:
        net_quic_connection *ep;
        int64_t stream_id;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (!ep->ready) {
            croak("cannot open a QUIC stream before the handshake is ready");
        }

        rv = net_quic_stream_open_local(
            aTHX_ ep,
            bidirectional ? 1 : 0,
            &stream_id
        );
        if (rv == NGTCP2_ERR_STREAM_ID_BLOCKED) {
            if (bidirectional) {
                ep->local_bidi_stream_waiting = 1;
            } else {
                ep->local_uni_stream_waiting = 1;
            }
            RETVAL = &PL_sv_undef;
        } else if (rv != 0) {
            croak(
                "unable to open QUIC stream: %s",
                ngtcp2_strerror(rv)
            );
        } else {
            RETVAL = newSViv((IV)stream_id);
        }
    OUTPUT:
        RETVAL

SV *
_open_bidi_stream(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        int64_t stream_id;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (!ep->ready) {
            croak("cannot open a QUIC stream before the handshake is ready");
        }

        rv = net_quic_stream_open_local(aTHX_ ep, 1, &stream_id);
        if (rv == NGTCP2_ERR_STREAM_ID_BLOCKED) {
            RETVAL = &PL_sv_undef;
        } else if (rv != 0) {
            croak(
                "unable to open QUIC stream: %s",
                ngtcp2_strerror(rv)
            );
        } else {
            RETVAL = newSViv((IV)stream_id);
        }
    OUTPUT:
        RETVAL

UV
_take_stream_available(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        unsigned int events;
    CODE:
        ep = net_quic_connection_from_sv(self);
        events = ep->stream_available_events;
        ep->stream_available_events = 0;
        RETVAL = (UV)events;
    OUTPUT:
        RETVAL

SV *
_next_stream_id(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_next_incoming(ep);

        if (stream == NULL) {
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = newSViv((IV)stream->id);
        }
    OUTPUT:
        RETVAL

SV *
_stream_info(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        AV *av;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        av = newAV();
        av_push(av, newSViv(stream->local_initiated ? 1 : 0));
        av_push(av, newSViv(stream->bidirectional ? 1 : 0));
        RETVAL = newRV_noinc((SV *)av);
    OUTPUT:
        RETVAL

void
_stream_retain(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        if (net_quic_stream_retain(stream) != 0) {
            croak("too many Net::QUIC::Stream references");
        }

void
_stream_release(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            XSRETURN_EMPTY;
        }

        if (net_quic_stream_release(aTHX_ ep, stream) != 0) {
            croak("Net::QUIC::Stream reference count underflow");
        }

UV
_stream_state_count(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);
        RETVAL = (UV)net_quic_stream_count(ep);
    OUTPUT:
        RETVAL

SV *
_stream_tx_stats(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        AV *av;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        av = newAV();
        av_push(av, newSVuv((UV)net_quic_stream_tx_chunk_count(stream)));
        av_push(av, newSVuv((UV)net_quic_stream_tx_buffered_bytes(stream)));
        RETVAL = newRV_noinc((SV *)av);
    OUTPUT:
        RETVAL

void
_stream_send(self, stream_id_iv, data_sv)
    SV *self
    IV stream_id_iv
    SV *data_sv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        const char *data;
        STRLEN datalen;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        data = SvPVbyte(data_sv, datalen);
        rv = net_quic_stream_queue_data(
            aTHX_ stream,
            (const uint8_t *)data,
            (size_t)datalen
        );
        if (rv != 0) {
            croak("unable to queue QUIC stream data: %s", ngtcp2_strerror(rv));
        }

void
_stream_finish(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        rv = net_quic_stream_queue_fin(aTHX_ stream);
        if (rv != 0) {
            croak("unable to finish QUIC stream: %s", ngtcp2_strerror(rv));
        }

SV *
_stream_take_data(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        net_quic_stream_rx_chunk *chunk;
        AV *av;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        rv = net_quic_stream_consume_rx(ep, stream, &chunk);
        if (rv != 0) {
            croak(
                "unable to consume QUIC stream data: %s",
                ngtcp2_strerror(rv)
            );
        }

        if (chunk == NULL) {
            RETVAL = &PL_sv_undef;
        } else {
            av = newAV();
            av_push(
                av,
                newSVpvn((const char *)chunk->data, (STRLEN)chunk->len)
            );
            av_push(av, newSViv(chunk->fin ? 1 : 0));
            RETVAL = newRV_noinc((SV *)av);
            net_quic_stream_rx_chunk_free(aTHX_ chunk);
        }
    OUTPUT:
        RETVAL

int
_stream_remote_finished(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }
        RETVAL = stream->remote_finished ? 1 : 0;
    OUTPUT:
        RETVAL

int
_stream_closed(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }
        RETVAL = stream->closed ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
_stream_remote_reset_code(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        if (!stream->remote_reset) {
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = newSVuv((UV)stream->remote_reset_code);
        }
    OUTPUT:
        RETVAL

SV *
_stream_local_reset_code(self, stream_id_iv)
    SV *self
    IV stream_id_iv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        if (!stream->local_reset) {
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = newSVuv((UV)stream->local_reset_code);
        }
    OUTPUT:
        RETVAL

void
_stream_reset(self, stream_id_iv, app_error_code_uv)
    SV *self
    IV stream_id_iv
    UV app_error_code_uv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        rv = ngtcp2_conn_shutdown_stream(
            ep->conn,
            0,
            stream->id,
            (uint64_t)app_error_code_uv
        );
        if (rv != 0) {
            croak("unable to reset QUIC stream: %s", ngtcp2_strerror(rv));
        }

        stream->local_reset = 1;
        stream->local_reset_code = (uint64_t)app_error_code_uv;
        stream->write_shutdown = 1;
        net_quic_stream_reclaim_closed(aTHX_ ep);

void
_queue_stream_data(self, stream_id_iv, data_sv, fin)
    SV *self
    IV stream_id_iv
    SV *data_sv
    int fin
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        const char *data;
        STRLEN datalen;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        data = SvPVbyte(data_sv, datalen);
        rv = net_quic_stream_queue_data(
            aTHX_ stream,
            (const uint8_t *)data,
            (size_t)datalen
        );
        if (rv != 0) {
            croak("unable to queue QUIC stream data: %s", ngtcp2_strerror(rv));
        }

        if (fin) {
            rv = net_quic_stream_queue_fin(aTHX_ stream);
            if (rv != 0) {
                croak("unable to finish QUIC stream: %s", ngtcp2_strerror(rv));
            }
        }

SV *
_take_stream_data(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        net_quic_stream_rx_chunk *chunk;
        AV *av;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = ep->streams;
        while (stream != NULL && stream->rx_head == NULL) {
            stream = stream->next;
        }

        if (stream == NULL) {
            RETVAL = &PL_sv_undef;
        } else {
            rv = net_quic_stream_consume_rx(ep, stream, &chunk);
            if (rv != 0) {
                croak(
                    "unable to consume QUIC stream data: %s",
                    ngtcp2_strerror(rv)
                );
            }

            av = newAV();
            av_push(av, newSViv((IV)stream->id));
            av_push(
                av,
                newSVpvn((const char *)chunk->data, (STRLEN)chunk->len)
            );
            av_push(av, newSViv(chunk->fin ? 1 : 0));
            RETVAL = newRV_noinc((SV *)av);
            net_quic_stream_rx_chunk_free(aTHX_ chunk);
        }
    OUTPUT:
        RETVAL

SV *
_next_datagram(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        net_quic_stream_tx_chunk *chunk;
        ngtcp2_path_storage ps;
        ngtcp2_pkt_info pi;
        ngtcp2_addr close_local;
        ngtcp2_addr close_peer;
        ngtcp2_ssize nwrite;
        ngtcp2_ssize wdatalen;
        ngtcp2_tstamp now;
        uint32_t flags;
        size_t remaining;
        size_t attempts;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (ep->retired) {
            RETVAL = &PL_sv_undef;
            goto next_datagram_done;
        }

        if (ep->closebuf_pending) {
            memset(&close_local, 0, sizeof(close_local));
            memset(&close_peer, 0, sizeof(close_peer));
            close_local.addr = &ep->close_local_addr.sa;
            close_local.addrlen = ep->close_local_addrlen;
            close_peer.addr = &ep->close_peer_addr.sa;
            close_peer.addrlen = ep->close_peer_addrlen;

            ep->closebuf_pending = 0;
            RETVAL = net_quic_datagram_new(
                ep->txbuf,
                ep->closebuflen,
                &close_local,
                &close_peer
            );
            goto next_datagram_done;
        }

        if (ep->close_wait ||
            ngtcp2_conn_in_closing_period2(ep->conn) ||
            ngtcp2_conn_in_draining_period2(ep->conn)) {
            RETVAL = &PL_sv_undef;
            goto next_datagram_done;
        }

        ngtcp2_path_storage_zero(&ps);
        memset(&pi, 0, sizeof(pi));

        now = net_quic_now();
        nwrite = 0;
        wdatalen = -1;
        attempts = net_quic_stream_count(ep);

        while (attempts-- != 0) {
            stream = net_quic_stream_next_tx(ep);
            if (stream == NULL) {
                break;
            }

            chunk = net_quic_stream_pending_chunk(stream);
            if (chunk == NULL) {
                continue;
            }

            remaining = chunk->len - chunk->sent;
            flags = chunk->fin
                ? NGTCP2_WRITE_STREAM_FLAG_FIN
                : NGTCP2_WRITE_STREAM_FLAG_NONE;

            nwrite = ngtcp2_conn_write_stream(
                ep->conn,
                &ps.path,
                &pi,
                ep->txbuf,
                sizeof(ep->txbuf),
                &wdatalen,
                flags,
                stream->id,
                chunk->data + chunk->sent,
                remaining,
                now
            );

            if (nwrite == NGTCP2_ERR_STREAM_DATA_BLOCKED) {
                nwrite = 0;
                wdatalen = -1;
                continue;
            }

            if (nwrite < 0) {
                croak(
                    "ngtcp2 packet write failed: %s",
                    ngtcp2_strerror((int)nwrite)
                );
            }

            if (wdatalen >= 0) {
                chunk->sent += (size_t)wdatalen;
                if (chunk->fin && chunk->sent == chunk->len) {
                    chunk->fin_sent = 1;
                }
            }

            if (nwrite != 0) {
                break;
            }
        }

        if (nwrite == 0) {
            ngtcp2_path_storage_zero(&ps);
            memset(&pi, 0, sizeof(pi));
            nwrite = ngtcp2_conn_write_pkt(
                ep->conn,
                &ps.path,
                &pi,
                ep->txbuf,
                sizeof(ep->txbuf),
                now
            );
        }

        if (nwrite < 0) {
            croak("ngtcp2 packet write failed: %s", ngtcp2_strerror((int)nwrite));
        }

        if (nwrite == 0) {
            if (ep->tx_batch_active) {
                ngtcp2_conn_update_pkt_tx_time(ep->conn, now);
                ep->tx_batch_active = 0;
            }
            RETVAL = &PL_sv_undef;
        } else {
            if (ps.path.local.addr == NULL || ps.path.remote.addr == NULL) {
                croak("ngtcp2 produced a datagram without a network path");
            }

            ep->tx_batch_active = 1;
            RETVAL = net_quic_datagram_new(
                ep->txbuf,
                (size_t)nwrite,
                &ps.path.local,
                &ps.path.remote
            );
        }

        next_datagram_done:
        net_quic_stream_reclaim_closed(aTHX_ ep);
        ;
    OUTPUT:
        RETVAL

void
_receive_datagram(self, data_sv, local_sv, peer_sv)
    SV *self
    SV *data_sv
    SV *local_sv
    SV *peer_sv
    PREINIT:
        net_quic_connection *ep;
        const char *data;
        const char *local;
        const char *peer;
        STRLEN datalen;
        STRLEN locallen;
        STRLEN peerlen;
        ngtcp2_sockaddr_union local_addr;
        ngtcp2_socklen local_addrlen;
        ngtcp2_sockaddr_union peer_addr;
        ngtcp2_socklen peer_addrlen;
        ngtcp2_path path;
        ngtcp2_pkt_info pi;
        ngtcp2_tstamp now;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (ep->retired) {
            XSRETURN_EMPTY;
        }
        data = SvPVbyte(data_sv, datalen);
        local = SvPVbyte(local_sv, locallen);
        peer = SvPVbyte(peer_sv, peerlen);

        if (net_quic_copy_sockaddr(&local_addr, &local_addrlen, local, locallen) != 0 ||
            net_quic_copy_sockaddr(&peer_addr, &peer_addrlen, peer, peerlen) != 0) {
            croak("local and peer must be packed IPv4 or IPv6 socket addresses");
        }

        memset(&path, 0, sizeof(path));
        path.local.addr = &local_addr.sa;
        path.local.addrlen = local_addrlen;
        path.remote.addr = &peer_addr.sa;
        path.remote.addrlen = peer_addrlen;
        memset(&pi, 0, sizeof(pi));

        now = net_quic_now();
        rv = ngtcp2_conn_read_pkt(
            ep->conn,
            &path,
            &pi,
            (const uint8_t *)data,
            (size_t)datalen,
            now
        );

        if (rv == NGTCP2_ERR_DRAINING || rv == NGTCP2_ERR_CLOSING) {
            net_quic_capture_peer_close(ep);
            net_quic_start_close_wait(ep, now);
            if (rv == NGTCP2_ERR_CLOSING && ep->closebuflen != 0) {
                ep->closebuf_pending = 1;
            }
        } else if (rv == NGTCP2_ERR_DROP_CONN) {
            net_quic_set_close_info(
                ep,
                NET_QUIC_CLOSE_INFO_DROP,
                NET_QUIC_CLOSE_INITIATOR_PEER,
                0,
                0,
                rv
            );
            ep->retired = 1;
            ep->close_wait = 0;
        } else if (rv == NGTCP2_ERR_NOMEM ||
                   rv == NGTCP2_ERR_INVALID_ARGUMENT ||
                   rv == NGTCP2_ERR_CALLBACK_FAILURE ||
                   rv == NGTCP2_ERR_INTERNAL) {
            croak("ngtcp2_conn_read_pkt failed: %s", ngtcp2_strerror(rv));
        } else if (rv != 0) {
            net_quic_capture_local_failure(ep, rv);
            rv = net_quic_start_error_close(ep, rv, now);
            if (rv != 0) {
                croak(
                    "unable to send QUIC failure close: %s",
                    ngtcp2_strerror(rv)
                );
            }
        }

        net_quic_stream_reclaim_closed(aTHX_ ep);

SV *
_timeout_after(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        ngtcp2_tstamp expiry;
        ngtcp2_tstamp now;
        NV seconds;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (ep->retired) {
            RETVAL = &PL_sv_undef;
        } else {
            now = net_quic_now();
            expiry = ep->close_wait
                ? ep->retirement_deadline
                : ngtcp2_conn_get_expiry2(ep->conn);

            if (expiry == UINT64_MAX) {
                RETVAL = &PL_sv_undef;
            } else {
                seconds = expiry <= now
                    ? 0.0
                    : (NV)(expiry - now) / (NV)NGTCP2_SECONDS;
                RETVAL = newSVnv(seconds);
            }
        }
    OUTPUT:
        RETVAL

void
_handle_timeout(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        ngtcp2_tstamp now;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (ep->retired) {
            XSRETURN_EMPTY;
        }

        now = net_quic_now();

        if (ep->close_wait) {
            if (ep->retirement_deadline <= now) {
                ep->retired = 1;
                ep->close_wait = 0;
            }
            XSRETURN_EMPTY;
        }

        rv = ngtcp2_conn_handle_expiry(ep->conn, now);
        if (rv == NGTCP2_ERR_IDLE_CLOSE) {
            net_quic_set_close_info(
                ep,
                NET_QUIC_CLOSE_INFO_IDLE,
                NET_QUIC_CLOSE_INITIATOR_LOCAL,
                0,
                0,
                rv
            );
            ep->retired = 1;
        } else if (rv == NGTCP2_ERR_DROP_CONN) {
            net_quic_set_close_info(
                ep,
                NET_QUIC_CLOSE_INFO_DROP,
                NET_QUIC_CLOSE_INITIATOR_LOCAL,
                0,
                0,
                rv
            );
            ep->retired = 1;
        } else if (rv == NGTCP2_ERR_DRAINING || rv == NGTCP2_ERR_CLOSING) {
            net_quic_capture_peer_close(ep);
            net_quic_start_close_wait(ep, now);
        } else if (rv == NGTCP2_ERR_NOMEM ||
                   rv == NGTCP2_ERR_INVALID_ARGUMENT ||
                   rv == NGTCP2_ERR_CALLBACK_FAILURE ||
                   rv == NGTCP2_ERR_INTERNAL) {
            croak("ngtcp2_conn_handle_expiry failed: %s", ngtcp2_strerror(rv));
        } else if (rv != 0) {
            net_quic_capture_local_failure(ep, rv);
            rv = net_quic_start_error_close(ep, rv, now);
            if (rv != 0) {
                croak(
                    "unable to send QUIC failure close: %s",
                    ngtcp2_strerror(rv)
                );
            }
        } else if (ngtcp2_conn_in_closing_period2(ep->conn) ||
                   ngtcp2_conn_in_draining_period2(ep->conn)) {
            net_quic_capture_peer_close(ep);
            net_quic_start_close_wait(ep, now);
        }

        net_quic_stream_reclaim_closed(aTHX_ ep);

void
_close(self, app_error_code_uv = 0)
    SV *self
    UV app_error_code_uv
    PREINIT:
        net_quic_connection *ep;
        ngtcp2_ccerr ccerr;
        ngtcp2_path_storage ps;
        ngtcp2_pkt_info pi;
        ngtcp2_ssize nwrite;
        ngtcp2_tstamp now;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if ((uint64_t)app_error_code_uv > NGTCP2_MAX_VARINT) {
            croak("application error code is too large");
        }

        if (ep->retired || ep->close_wait) {
            XSRETURN_EMPTY;
        }

        now = net_quic_now();

        if (ngtcp2_conn_in_closing_period2(ep->conn) ||
            ngtcp2_conn_in_draining_period2(ep->conn)) {
            net_quic_start_close_wait(ep, now);
            XSRETURN_EMPTY;
        }

        ngtcp2_ccerr_default(&ccerr);
        ngtcp2_ccerr_set_application_error(
            &ccerr,
            (uint64_t)app_error_code_uv,
            NULL,
            0
        );

        net_quic_set_close_info(
            ep,
            NET_QUIC_CLOSE_INFO_APPLICATION,
            NET_QUIC_CLOSE_INITIATOR_LOCAL,
            (uint64_t)app_error_code_uv,
            0,
            0
        );

        ngtcp2_path_storage_zero(&ps);
        memset(&pi, 0, sizeof(pi));

        nwrite = ngtcp2_conn_write_connection_close(
            ep->conn,
            &ps.path,
            &pi,
            ep->txbuf,
            sizeof(ep->txbuf),
            &ccerr,
            now
        );

        if (nwrite < 0) {
            croak(
                "ngtcp2 connection close failed: %s",
                ngtcp2_strerror((int)nwrite)
            );
        }

        if (nwrite > 0) {
            if (net_quic_copy_ngtcp2_addr(
                    &ep->close_local_addr,
                    &ep->close_local_addrlen,
                    &ps.path.local
                ) != 0 ||
                net_quic_copy_ngtcp2_addr(
                    &ep->close_peer_addr,
                    &ep->close_peer_addrlen,
                    &ps.path.remote
                ) != 0) {
                croak("ngtcp2 produced a connection close without a network path");
            }

            ep->closebuflen = (size_t)nwrite;
            ep->closebuf_pending = 1;
        }

        net_quic_start_close_wait(ep, now);

SV *
_close_info(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        HV *hv;
        const char *type;
        const char *initiator;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (ep->close_info_type == NET_QUIC_CLOSE_INFO_NONE) {
            RETVAL = &PL_sv_undef;
        } else {
            switch (ep->close_info_type) {
            case NET_QUIC_CLOSE_INFO_APPLICATION:
                type = "application";
                break;
            case NET_QUIC_CLOSE_INFO_TRANSPORT:
                type = "transport";
                break;
            case NET_QUIC_CLOSE_INFO_TLS:
                type = "tls";
                break;
            case NET_QUIC_CLOSE_INFO_CERTIFICATE:
                type = "certificate";
                break;
            case NET_QUIC_CLOSE_INFO_HANDSHAKE:
                type = "handshake";
                break;
            case NET_QUIC_CLOSE_INFO_IDLE:
                type = "idle";
                break;
            case NET_QUIC_CLOSE_INFO_DROP:
                type = "drop";
                break;
            default:
                type = "transport";
                break;
            }

            initiator = ep->close_info_initiator == NET_QUIC_CLOSE_INITIATOR_PEER
                ? "peer"
                : "local";

            hv = newHV();
            hv_store(hv, "type", 4, newSVpv(type, 0), 0);
            hv_store(hv, "initiator", 9, newSVpv(initiator, 0), 0);
            hv_store(
                hv,
                "code",
                4,
                newSVuv((UV)ep->close_info_code),
                0
            );

            if (ep->close_info_frame_type != 0) {
                hv_store(
                    hv,
                    "frame_type",
                    10,
                    newSVuv((UV)ep->close_info_frame_type),
                    0
                );
            }

            if (ep->close_info_native_error != 0) {
                hv_store(
                    hv,
                    "native_error",
                    12,
                    newSViv((IV)ep->close_info_native_error),
                    0
                );
            }

            RETVAL = newRV_noinc((SV *)hv);
        }
    OUTPUT:
        RETVAL

int
_retired(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);
        RETVAL = ep->retired ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
_transport_info(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        const ngtcp2_transport_params *params;
        HV *hv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        params = ngtcp2_conn_get_local_transport_params(ep->conn);

        hv = newHV();
        hv_store(
            hv,
            "idle_timeout_ms",
            15,
            newSVuv((UV)(params->max_idle_timeout / NGTCP2_MILLISECONDS)),
            0
        );
        hv_store(
            hv,
            "connection_window",
            17,
            newSVuv((UV)params->initial_max_data),
            0
        );
        hv_store(
            hv,
            "stream_window_bidi_local",
            24,
            newSVuv((UV)params->initial_max_stream_data_bidi_local),
            0
        );
        hv_store(
            hv,
            "stream_window_bidi_remote",
            25,
            newSVuv((UV)params->initial_max_stream_data_bidi_remote),
            0
        );
        hv_store(
            hv,
            "stream_window_uni",
            17,
            newSVuv((UV)params->initial_max_stream_data_uni),
            0
        );
        hv_store(
            hv,
            "max_bidi_streams",
            16,
            newSVuv((UV)params->initial_max_streams_bidi),
            0
        );
        hv_store(
            hv,
            "max_uni_streams",
            15,
            newSVuv((UV)params->initial_max_streams_uni),
            0
        );
        hv_store(
            hv,
            "active_connection_id_limit",
            26,
            newSVuv((UV)params->active_connection_id_limit),
            0
        );
        hv_store(
            hv,
            "disable_active_migration",
            24,
            newSViv(params->disable_active_migration ? 1 : 0),
            0
        );

        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

int
ready(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);
        RETVAL = ep->ready ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
_take_cid_event(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        net_quic_cid_event *event;
        AV *av;
    CODE:
        ep = net_quic_connection_from_sv(self);
        event = ep->cid_event_head;

        if (event == NULL) {
            RETVAL = &PL_sv_undef;
        } else {
            ep->cid_event_head = event->next;
            if (ep->cid_event_head == NULL) {
                ep->cid_event_tail = NULL;
            }

            av = newAV();
            av_push(av, newSViv(event->add ? 1 : 0));
            av_push(
                av,
                newSVpvn(
                    (const char *)event->cid.data,
                    (STRLEN)event->cid.datalen
                )
            );
            RETVAL = newRV_noinc((SV *)av);
            Safefree(event);
        }
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        SV *inner;
    CODE:
        if (!SvROK(self)) {
            XSRETURN_EMPTY;
        }

        inner = SvRV(self);
        ep = INT2PTR(net_quic_connection *, SvIV(inner));
        if (ep != NULL) {
            net_quic_connection_free(aTHX_ ep);
            sv_setiv(inner, 0);
        }

MODULE = Net::QUIC    PACKAGE = Net::QUIC::Endpoint

SV *
_server_secret(class)
    const char *class
    PREINIT:
        uint8_t secret[NET_QUIC_SERVER_SECRET_LEN];
    CODE:
        (void)class;
        if (net_quic_random_bytes(secret, sizeof(secret)) != 0) {
            croak("unable to generate server secret");
        }
        RETVAL = newSVpvn((const char *)secret, (STRLEN)sizeof(secret));
    OUTPUT:
        RETVAL

UV
_server_cid_length(class)
    const char *class
    CODE:
        (void)class;
        RETVAL = NET_QUIC_SERVER_CIDLEN;
    OUTPUT:
        RETVAL

SV *
_packet_dcid(class, data_sv, short_dcidlen_uv)
    const char *class
    SV *data_sv
    UV short_dcidlen_uv
    PREINIT:
        const char *data;
        STRLEN datalen;
        ngtcp2_version_cid vcid;
        int rv;
    CODE:
        (void)class;
        data = SvPVbyte(data_sv, datalen);

        if (short_dcidlen_uv > NGTCP2_MAX_CIDLEN) {
            croak("short QUIC connection ID length is too large");
        }

        memset(&vcid, 0, sizeof(vcid));
        rv = ngtcp2_pkt_decode_version_cid(
            &vcid,
            (const uint8_t *)data,
            (size_t)datalen,
            (size_t)short_dcidlen_uv
        );

        if (rv != 0 && rv != NGTCP2_ERR_VERSION_NEGOTIATION) {
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = newSVpvn((const char *)vcid.dcid, (STRLEN)vcid.dcidlen);
        }
    OUTPUT:
        RETVAL

SV *
_initial_dcid(class, data_sv)
    const char *class
    SV *data_sv
    PREINIT:
        const char *data;
        STRLEN datalen;
        ngtcp2_version_cid vcid;
        ngtcp2_pkt_hd hd;
        int rv;
    CODE:
        (void)class;
        data = SvPVbyte(data_sv, datalen);

        memset(&hd, 0, sizeof(hd));
        rv = ngtcp2_accept(&hd, (const uint8_t *)data, (size_t)datalen);
        if (rv != 0) {
            RETVAL = &PL_sv_undef;
        } else {
            memset(&vcid, 0, sizeof(vcid));
            rv = ngtcp2_pkt_decode_version_cid(
                &vcid,
                (const uint8_t *)data,
                (size_t)datalen,
                0
            );
            if (rv != 0 && rv != NGTCP2_ERR_VERSION_NEGOTIATION) {
                RETVAL = &PL_sv_undef;
            } else {
                RETVAL = newSVpvn(
                    (const char *)vcid.dcid,
                    (STRLEN)vcid.dcidlen
                );
            }
        }
    OUTPUT:
        RETVAL

SV *
_server_front_door(class, data_sv, peer_sv, secret_sv, validate_address)
    const char *class
    SV *data_sv
    SV *peer_sv
    SV *secret_sv
    int validate_address
    PREINIT:
        const char *data;
        const char *peer;
        const char *secret;
        STRLEN datalen;
        STRLEN peerlen;
        STRLEN secretlen;
        ngtcp2_sockaddr_union peer_addr;
        ngtcp2_socklen peer_addrlen;
        ngtcp2_version_cid vcid;
        ngtcp2_pkt_hd hd;
        ngtcp2_cid retry_scid;
        ngtcp2_cid odcid;
        ngtcp2_cid reset_cid;
        ngtcp2_stateless_reset_token reset_token;
        uint8_t token[NGTCP2_CRYPTO_MAX_RETRY_TOKENLEN2];
        uint8_t response[NGTCP2_MAX_UDP_PAYLOAD_SIZE];
        uint8_t reset_random[NET_QUIC_STATELESS_RESET_MAX_RANDLEN];
        uint8_t unused_random;
        uint32_t supported_versions[2];
        size_t supported_versionslen;
        size_t reset_random_len;
        ngtcp2_ssize tokenlen;
        ngtcp2_ssize nwrite;
        ngtcp2_tstamp now;
        AV *av;
        int rv;
    CODE:
        (void)class;
        data = SvPVbyte(data_sv, datalen);
        peer = SvPVbyte(peer_sv, peerlen);
        secret = SvPVbyte(secret_sv, secretlen);

        av = newAV();

        if (secretlen != NET_QUIC_SERVER_SECRET_LEN ||
            net_quic_copy_sockaddr(
                &peer_addr,
                &peer_addrlen,
                peer,
                peerlen
            ) != 0) {
            av_push(av, newSViv(0));
            RETVAL = newRV_noinc((SV *)av);
        } else {
            memset(&vcid, 0, sizeof(vcid));
            rv = ngtcp2_pkt_decode_version_cid(
                &vcid,
                (const uint8_t *)data,
                (size_t)datalen,
                NET_QUIC_SERVER_CIDLEN
            );

            if (rv == NGTCP2_ERR_VERSION_NEGOTIATION) {
                supported_versions[0] = NGTCP2_PROTO_VER_V1;
                supported_versions[1] = NGTCP2_PROTO_VER_V2;
                supported_versionslen = 2;

                if (net_quic_random_bytes(&unused_random, 1) != 0) {
                    croak("unable to generate Version Negotiation randomness");
                }

                nwrite = ngtcp2_pkt_write_version_negotiation(
                    response,
                    sizeof(response),
                    unused_random,
                    vcid.scid,
                    vcid.scidlen,
                    vcid.dcid,
                    vcid.dcidlen,
                    supported_versions,
                    supported_versionslen
                );

                if (nwrite < 0) {
                    croak(
                        "unable to write QUIC Version Negotiation packet: %s",
                        ngtcp2_strerror((int)nwrite)
                    );
                }

                av_push(av, newSViv(1));
                av_push(
                    av,
                    newSVpvn((const char *)response, (STRLEN)nwrite)
                );
                RETVAL = newRV_noinc((SV *)av);
            } else if (rv != 0) {
                av_push(av, newSViv(0));
                RETVAL = newRV_noinc((SV *)av);
            } else {
                memset(&hd, 0, sizeof(hd));
                rv = ngtcp2_accept(
                    &hd,
                    (const uint8_t *)data,
                    (size_t)datalen
                );

                if (rv != 0) {
                    if (
                        datalen >= NET_QUIC_SERVER_CIDLEN + 21 &&
                        (((const uint8_t *)data)[0] & 0x80) == 0
                    ) {
                        ngtcp2_cid_init(
                            &reset_cid,
                            vcid.dcid,
                            vcid.dcidlen
                        );

                        rv = ngtcp2_crypto_generate_stateless_reset_token(
                            reset_token.data,
                            (const uint8_t *)secret,
                            (size_t)secretlen,
                            &reset_cid
                        );
                        if (rv != 0) {
                            croak("unable to generate stateless reset token");
                        }

                        reset_random_len = datalen <= 43
                            ? (size_t)datalen
                                - NGTCP2_STATELESS_RESET_TOKENLEN
                                - 1
                            : NET_QUIC_STATELESS_RESET_MAX_RANDLEN;

                        if (net_quic_random_bytes(
                                reset_random,
                                reset_random_len
                            ) != 0) {
                            croak("unable to generate stateless reset randomness");
                        }

                        nwrite = ngtcp2_pkt_write_stateless_reset2(
                            response,
                            sizeof(response),
                            &reset_token,
                            reset_random,
                            reset_random_len
                        );
                        if (nwrite < 0) {
                            croak(
                                "unable to write QUIC Stateless Reset: %s",
                                ngtcp2_strerror((int)nwrite)
                            );
                        }

                        av_push(av, newSViv(1));
                        av_push(
                            av,
                            newSVpvn(
                                (const char *)response,
                                (STRLEN)nwrite
                            )
                        );
                    } else {
                        av_push(av, newSViv(0));
                    }
                    RETVAL = newRV_noinc((SV *)av);
                } else if (hd.tokenlen == 0 && validate_address) {
                    retry_scid.datalen = NET_QUIC_SERVER_CIDLEN;
                    if (net_quic_random_bytes(
                            retry_scid.data,
                            retry_scid.datalen
                        ) != 0) {
                        croak("unable to generate Retry connection ID");
                    }

                    now = net_quic_system_now();
                    tokenlen = ngtcp2_crypto_generate_retry_token2(
                        token,
                        (const uint8_t *)secret,
                        (size_t)secretlen,
                        hd.version,
                        &peer_addr.sa,
                        peer_addrlen,
                        &retry_scid,
                        &hd.dcid,
                        now
                    );

                    if (tokenlen < 0) {
                        croak("unable to generate QUIC Retry token");
                    }

                    nwrite = ngtcp2_crypto_write_retry(
                        response,
                        sizeof(response),
                        hd.version,
                        &hd.scid,
                        &retry_scid,
                        &hd.dcid,
                        token,
                        (size_t)tokenlen
                    );

                    if (nwrite < 0) {
                        croak("unable to write QUIC Retry packet");
                    }

                    av_push(av, newSViv(1));
                    av_push(
                        av,
                        newSVpvn((const char *)response, (STRLEN)nwrite)
                    );
                    RETVAL = newRV_noinc((SV *)av);
                } else if (
                    hd.tokenlen != 0 &&
                    hd.token[0] == NGTCP2_CRYPTO_TOKEN_MAGIC_RETRY2
                ) {
                    now = net_quic_system_now();
                    memset(&odcid, 0, sizeof(odcid));

                    rv = ngtcp2_crypto_verify_retry_token2(
                        &odcid,
                        hd.token,
                        hd.tokenlen,
                        (const uint8_t *)secret,
                        (size_t)secretlen,
                        hd.version,
                        &peer_addr.sa,
                        peer_addrlen,
                        &hd.dcid,
                        NET_QUIC_RETRY_TOKEN_TIMEOUT,
                        now
                    );

                    if (rv == 0) {
                        av_push(av, newSViv(2));
                        av_push(
                            av,
                            newSVpvn(
                                (const char *)odcid.data,
                                (STRLEN)odcid.datalen
                            )
                        );
                        RETVAL = newRV_noinc((SV *)av);
                    } else {
                        nwrite = ngtcp2_crypto_write_connection_close(
                            response,
                            sizeof(response),
                            hd.version,
                            &hd.scid,
                            &hd.dcid,
                            NGTCP2_INVALID_TOKEN,
                            NULL,
                            0
                        );

                        if (nwrite < 0) {
                            av_push(av, newSViv(0));
                        } else {
                            av_push(av, newSViv(1));
                            av_push(
                                av,
                                newSVpvn(
                                    (const char *)response,
                                    (STRLEN)nwrite
                                )
                            );
                        }
                        RETVAL = newRV_noinc((SV *)av);
                    }
                } else if (hd.tokenlen != 0 && validate_address) {
                    retry_scid.datalen = NET_QUIC_SERVER_CIDLEN;
                    if (net_quic_random_bytes(
                            retry_scid.data,
                            retry_scid.datalen
                        ) != 0) {
                        croak("unable to generate Retry connection ID");
                    }

                    now = net_quic_system_now();
                    tokenlen = ngtcp2_crypto_generate_retry_token2(
                        token,
                        (const uint8_t *)secret,
                        (size_t)secretlen,
                        hd.version,
                        &peer_addr.sa,
                        peer_addrlen,
                        &retry_scid,
                        &hd.dcid,
                        now
                    );

                    if (tokenlen < 0) {
                        croak("unable to generate QUIC Retry token");
                    }

                    nwrite = ngtcp2_crypto_write_retry(
                        response,
                        sizeof(response),
                        hd.version,
                        &hd.scid,
                        &retry_scid,
                        &hd.dcid,
                        token,
                        (size_t)tokenlen
                    );

                    if (nwrite < 0) {
                        croak("unable to write QUIC Retry packet");
                    }

                    av_push(av, newSViv(1));
                    av_push(
                        av,
                        newSVpvn((const char *)response, (STRLEN)nwrite)
                    );
                    RETVAL = newRV_noinc((SV *)av);
                } else {
                    av_push(av, newSViv(2));
                    av_push(av, newSV(0));
                    RETVAL = newRV_noinc((SV *)av);
                }
            }
        }
    OUTPUT:
        RETVAL
