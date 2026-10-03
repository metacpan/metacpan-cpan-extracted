#include "xs/net_quic_connection.h"

static uint32_t
net_quic_wire_version(int version)
{
    switch (version) {
    case 1:
        return NGTCP2_PROTO_VER_V1;
    case 2:
        return NGTCP2_PROTO_VER_V2;
    default:
        croak("QUIC version must be 1 or 2");
    }

    return NGTCP2_PROTO_VER_V1;
}

static int
net_quic_public_version(uint32_t version)
{
    switch (version) {
    case NGTCP2_PROTO_VER_V1:
        return 1;
    case NGTCP2_PROTO_VER_V2:
        return 2;
    default:
        return 0;
    }
}

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
        ep->close_ecn = pi.ecn & NGTCP2_ECN_MASK;
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
        params->disable_active_migration = 0;
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
    params->disable_active_migration = 0;
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
_new(class, cert_file_sv, key_file_sv, accept_early_data = 0)
    const char *class
    SV *cert_file_sv
    SV *key_file_sv
    int accept_early_data
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

        tls_error = net_quic_server_tls_init(
            tls,
            cert_file,
            key_file,
            accept_early_data ? 1 : 0
        );
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
_client_new(class, local_sv, peer_sv, alpn_sv, server_name_sv, ca_file_sv, transport_sv = &PL_sv_undef, session_ticket_sv = &PL_sv_undef, early_transport_sv = &PL_sv_undef, address_token_sv = &PL_sv_undef, version = 1, version_locked = 0)
    const char *class
    SV *local_sv
    SV *peer_sv
    SV *alpn_sv
    SV *server_name_sv
    SV *ca_file_sv
    SV *transport_sv
    SV *session_ticket_sv
    SV *early_transport_sv
    SV *address_token_sv
    int version
    int version_locked
    PREINIT:
        net_quic_connection *ep = NULL;
        const char *local;
        const char *peer;
        const char *alpn;
        const char *server_name;
        const char *ca_file;
        const char *session_ticket = NULL;
        const char *early_transport = NULL;
        const char *address_token = NULL;
        STRLEN locallen;
        STRLEN peerlen;
        STRLEN alpnlen;
        STRLEN server_namelen;
        STRLEN ca_file_len;
        STRLEN session_ticket_len = 0;
        STRLEN early_transport_len = 0;
        STRLEN address_token_len = 0;
        ngtcp2_callbacks callbacks;
        ngtcp2_settings settings;
        uint32_t versions[2];
        uint32_t chosen_version;
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
        if (SvOK(session_ticket_sv)) {
            session_ticket = SvPVbyte(session_ticket_sv, session_ticket_len);
            if (session_ticket_len == 0) {
                croak("session_ticket cannot be empty");
            }
        }
        if (SvOK(early_transport_sv)) {
            early_transport = SvPVbyte(early_transport_sv, early_transport_len);
            if (early_transport_len == 0) {
                croak("early-data transport state cannot be empty");
            }
            if (session_ticket == NULL) {
                croak("early-data transport state requires a session ticket");
            }
        }
        if (SvOK(address_token_sv)) {
            address_token = SvPVbyte(address_token_sv, address_token_len);
            if (address_token_len == 0) {
                croak("address_token cannot be empty");
            }
        }

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

        if (session_ticket != NULL) {
            Newx(ep->resume_ticket, session_ticket_len, uint8_t);
            if (ep->resume_ticket == NULL) {
                net_quic_connection_free(aTHX_ ep);
                croak("unable to allocate TLS session ticket");
            }
            memcpy(ep->resume_ticket, session_ticket, (size_t)session_ticket_len);
            ep->resume_ticket_len = (size_t)session_ticket_len;
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
        callbacks.recv_stop_sending = net_quic_recv_stop_sending_cb;
        callbacks.extend_max_local_streams_bidi =
            net_quic_extend_max_local_streams_bidi_cb;
        callbacks.extend_max_local_streams_uni =
            net_quic_extend_max_local_streams_uni_cb;
        callbacks.encrypt = ngtcp2_crypto_encrypt_cb;
        callbacks.decrypt = ngtcp2_crypto_decrypt_cb;
        callbacks.hp_mask = ngtcp2_crypto_hp_mask_cb;
        callbacks.recv_retry = ngtcp2_crypto_recv_retry_cb;
        callbacks.recv_new_token = net_quic_recv_new_token_cb;
        callbacks.rand = net_quic_rand_cb;
        callbacks.update_key = ngtcp2_crypto_update_key_cb;
        callbacks.delete_crypto_aead_ctx = ngtcp2_crypto_delete_crypto_aead_ctx_cb;
        callbacks.delete_crypto_cipher_ctx = ngtcp2_crypto_delete_crypto_cipher_ctx_cb;
        callbacks.version_negotiation = ngtcp2_crypto_version_negotiation_cb;
        callbacks.tls_early_data_rejected =
            net_quic_tls_early_data_rejected_cb;
        callbacks.get_new_connection_id2 = net_quic_get_new_connection_id_cb;
        callbacks.get_path_challenge_data2 = ngtcp2_crypto_get_path_challenge_data2_cb;
        callbacks.begin_path_validation = net_quic_begin_path_validation_cb;
        callbacks.path_validation = net_quic_path_validation_cb;
        callbacks.select_preferred_addr = net_quic_select_preferred_addr_cb;

        if (net_quic_random_bytes(dcid.data, NGTCP2_MIN_INITIAL_DCIDLEN) != 0 ||
            net_quic_random_bytes(scid.data, 16) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to generate QUIC connection IDs");
        }
        dcid.datalen = NGTCP2_MIN_INITIAL_DCIDLEN;
        scid.datalen = 16;

        ngtcp2_settings_default(&settings);
        settings.initial_ts = net_quic_now();

        chosen_version = net_quic_wire_version(version);
        versions[0] = chosen_version;
        versions[1] = chosen_version == NGTCP2_PROTO_VER_V1
            ? NGTCP2_PROTO_VER_V2
            : NGTCP2_PROTO_VER_V1;

        settings.preferred_versions = versions;
        settings.preferred_versionslen = version_locked ? 1 : 2;
        settings.available_versions = versions;
        settings.available_versionslen = version_locked ? 1 : 2;
        settings.original_version = chosen_version;

        if (address_token != NULL) {
            settings.token = (const uint8_t *)address_token;
            settings.tokenlen = (size_t)address_token_len;
            settings.token_type = NGTCP2_TOKEN_TYPE_NEW_TOKEN;
        }

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
            chosen_version,
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

        if (early_transport != NULL) {
            rv = ngtcp2_conn_decode_and_set_0rtt_transport_params(
                ep->conn,
                (const uint8_t *)early_transport,
                (size_t)early_transport_len
            );
            if (rv != 0) {
                net_quic_connection_free(aTHX_ ep);
                croak(
                    "invalid early-data transport state: %s",
                    ngtcp2_strerror(rv)
                );
            }
            ep->early_data_attempted = 1;
        }

        if (net_quic_tls_client_finish(aTHX_ ep) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to configure Picotls for QUIC");
        }

        RETVAL = net_quic_connection_bless(class, ep);
    OUTPUT:
        RETVAL

SV *
_server_new(class, initial_sv, local_sv, peer_sv, alpn_sv, server_tls_sv, odcid_sv = &PL_sv_undef, server_secret_sv = &PL_sv_undef, transport_sv = &PL_sv_undef, preferred_address_sv = &PL_sv_undef, validated_token_type = 0, issue_new_token = 0, preferred_version = 0)
    const char *class
    SV *initial_sv
    SV *local_sv
    SV *peer_sv
    SV *alpn_sv
    SV *server_tls_sv
    SV *odcid_sv
    SV *server_secret_sv
    SV *transport_sv
    SV *preferred_address_sv
    int validated_token_type
    int issue_new_token
    int preferred_version
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
        const char *preferred_address = NULL;
        STRLEN preferred_address_len = 0;
        ngtcp2_sockaddr_union preferred_addr_storage;
        ngtcp2_socklen preferred_addrlen = 0;
        int preferred_addr_present = 0;
        ngtcp2_version_cid vcid;
        ngtcp2_pkt_hd hd;
        ngtcp2_callbacks callbacks;
        ngtcp2_settings settings;
        uint32_t available_versions[2];
        uint32_t preferred_versions[2];
        uint32_t server_preferred_version = 0;
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
        if (SvOK(preferred_address_sv)) {
            preferred_address = SvPVbyte(
                preferred_address_sv,
                preferred_address_len
            );
            if (net_quic_copy_sockaddr(
                    &preferred_addr_storage,
                    &preferred_addrlen,
                    preferred_address,
                    preferred_address_len
                ) != 0 ||
                net_quic_sockaddr_is_unspecified(&preferred_addr_storage)) {
                croak(
                    "preferred_address must be a concrete packed IPv4 or IPv6 socket address"
                );
            }
            preferred_addr_present = 1;
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
        ep->issue_new_token = issue_new_token ? 1 : 0;

        if (validated_token_type != NGTCP2_TOKEN_TYPE_UNKNOWN &&
            validated_token_type != NGTCP2_TOKEN_TYPE_RETRY &&
            validated_token_type != NGTCP2_TOKEN_TYPE_NEW_TOKEN) {
            net_quic_connection_free(aTHX_ ep);
            croak("invalid validated token type");
        }

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
        callbacks.recv_stop_sending = net_quic_recv_stop_sending_cb;
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
        callbacks.begin_path_validation = net_quic_begin_path_validation_cb;
        callbacks.path_validation = net_quic_path_validation_cb;

        ngtcp2_cid_init(&dcid, vcid.scid, vcid.scidlen);

        scid.datalen = NET_QUIC_SERVER_CIDLEN;
        if (net_quic_random_bytes(scid.data, scid.datalen) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to generate server QUIC connection ID");
        }

        ngtcp2_settings_default(&settings);
        settings.initial_ts = net_quic_now();

        available_versions[0] = NGTCP2_PROTO_VER_V1;
        available_versions[1] = NGTCP2_PROTO_VER_V2;
        settings.available_versions = available_versions;
        settings.available_versionslen = 2;

        if (preferred_version != 0) {
            server_preferred_version = net_quic_wire_version(preferred_version);
            preferred_versions[0] = server_preferred_version;
            preferred_versions[1] =
                server_preferred_version == NGTCP2_PROTO_VER_V1
                    ? NGTCP2_PROTO_VER_V2
                    : NGTCP2_PROTO_VER_V1;
            settings.preferred_versions = preferred_versions;
            settings.preferred_versionslen = 2;
        }

        if (validated_token_type != NGTCP2_TOKEN_TYPE_UNKNOWN) {
            if (hd.tokenlen == 0) {
                net_quic_connection_free(aTHX_ ep);
                croak("validated connection is missing its token");
            }

            if (odcid_data != NULL &&
                validated_token_type != NGTCP2_TOKEN_TYPE_RETRY) {
                net_quic_connection_free(aTHX_ ep);
                croak("original destination CID requires a Retry token");
            }

            settings.token = hd.token;
            settings.tokenlen = hd.tokenlen;
            settings.token_type = (ngtcp2_token_type)validated_token_type;
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

        if (preferred_addr_present) {
            params.preferred_addr_present = 1;
            params.preferred_addr.cid.datalen = NET_QUIC_SERVER_CIDLEN;

            if (net_quic_random_bytes(
                    params.preferred_addr.cid.data,
                    params.preferred_addr.cid.datalen
                ) != 0) {
                net_quic_connection_free(aTHX_ ep);
                croak("unable to generate preferred-address connection ID");
            }

            rv = ngtcp2_crypto_generate_stateless_reset_token(
                params.preferred_addr.stateless_reset_token,
                ep->server_secret,
                sizeof(ep->server_secret),
                &params.preferred_addr.cid
            );
            if (rv != 0) {
                net_quic_connection_free(aTHX_ ep);
                croak("unable to generate preferred-address reset token");
            }

            if (preferred_addr_storage.sa.sa_family == NGTCP2_AF_INET) {
                memcpy(
                    &params.preferred_addr.ipv4,
                    &preferred_addr_storage.in,
                    sizeof(params.preferred_addr.ipv4)
                );
                params.preferred_addr.ipv4_present = 1;
            } else if (
                preferred_addr_storage.sa.sa_family == NGTCP2_AF_INET6
            ) {
                memcpy(
                    &params.preferred_addr.ipv6,
                    &preferred_addr_storage.in6,
                    sizeof(params.preferred_addr.ipv6)
                );
                params.preferred_addr.ipv6_present = 1;
            }
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

        if (preferred_addr_present &&
            net_quic_queue_cid_event(
                aTHX_ ep,
                1,
                &params.preferred_addr.cid
            ) != 0) {
            net_quic_connection_free(aTHX_ ep);
            croak("unable to register preferred-address connection ID");
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

        if (!ep->ready &&
            (!ep->early_data_attempted || ep->early_data_rejected)) {
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

        if (!ep->ready &&
            (!ep->early_data_attempted || ep->early_data_rejected)) {
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

void
_set_stream_activity_enabled(self, enabled)
    SV *self
    int enabled
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);
        net_quic_stream_set_activity_enabled(ep, enabled ? 1 : 0);
        if (!enabled) {
            net_quic_stream_reclaim_closed(aTHX_ ep);
        }

int
_stream_activity_pending(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);
        RETVAL = ep->stream_activity_head != NULL ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
_next_active_stream_id(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        int64_t stream_id;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_next_activity(ep);

        if (stream == NULL) {
            RETVAL = &PL_sv_undef;
        } else {
            stream_id = stream->id;
            net_quic_stream_reclaim_closed(aTHX_ ep);
            RETVAL = newSViv((IV)stream_id);
        }
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

int
_stream_release(self, stream_id_iv)
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
            RETVAL = 0;
        } else {
            rv = net_quic_stream_release(aTHX_ ep, stream);
            if (rv < 0) {
                croak("Net::QUIC::Stream reference count underflow");
            }
            RETVAL = rv;
        }
    OUTPUT:
        RETVAL

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
_send_buffer_limit(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (!ep->stream_tx_buffer_limit_enabled) {
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = newSVuv((UV)ep->stream_tx_buffer_limit);
        }
    OUTPUT:
        RETVAL

void
_set_send_buffer_limit(self, limit_uv)
    SV *self
    UV limit_uv
    PREINIT:
        net_quic_connection *ep;
        uint64_t limit;
    CODE:
        ep = net_quic_connection_from_sv(self);
        limit = (uint64_t)limit_uv;

        if (ep->stream_tx_buffered_bytes > limit) {
            croak(
                "send buffer limit cannot be smaller than currently buffered data"
            );
        }

        ep->stream_tx_buffer_limit = limit;
        ep->stream_tx_buffer_limit_enabled = 1;

void
_clear_send_buffer_limit(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);
        ep->stream_tx_buffer_limit_enabled = 0;
        ep->stream_tx_buffer_limit = 0;

UV
_send_buffered_bytes(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);
        RETVAL = (UV)ep->stream_tx_buffered_bytes;
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
        uint64_t available;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        data = SvPVbyte(data_sv, datalen);

        if (ep->stream_tx_buffer_limit_enabled) {
            available = ep->stream_tx_buffer_limit -
                        ep->stream_tx_buffered_bytes;
            if ((uint64_t)datalen > available) {
                croak(
                    "QUIC send buffer limit exceeded; use send_some for partial acceptance"
                );
            }
        }

        rv = net_quic_stream_queue_data(
            aTHX_ ep,
            stream,
            (const uint8_t *)data,
            (size_t)datalen
        );
        if (rv != 0) {
            croak("unable to queue QUIC stream data: %s", ngtcp2_strerror(rv));
        }

UV
_stream_send_some(self, stream_id_iv, data_sv)
    SV *self
    IV stream_id_iv
    SV *data_sv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        const char *data;
        STRLEN datalen;
        uint64_t available;
        uint64_t accepted;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        if (!ep->stream_tx_buffer_limit_enabled) {
            croak(
                "send_some requires a configured connection send_buffer_limit"
            );
        }

        data = SvPVbyte(data_sv, datalen);
        available = ep->stream_tx_buffer_limit -
                    ep->stream_tx_buffered_bytes;
        accepted = (uint64_t)datalen;
        if (accepted > available) {
            accepted = available;
        }

        if (accepted != 0) {
            rv = net_quic_stream_queue_data(
                aTHX_ ep,
                stream,
                (const uint8_t *)data,
                (size_t)accepted
            );
            if (rv != 0) {
                croak(
                    "unable to queue QUIC stream data: %s",
                    ngtcp2_strerror(rv)
                );
            }
        }

        RETVAL = (UV)accepted;
    OUTPUT:
        RETVAL

UV
_stream_send_buffered_bytes(self, stream_id_iv)
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

        RETVAL = (UV)stream->tx_buffered_bytes;
    OUTPUT:
        RETVAL

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

        if (stream->rx_mode == NET_QUIC_STREAM_RX_MODE_EXPLICIT) {
            croak(
                "cannot use next_data after explicit QUIC stream receive consumption"
            );
        }

        if (stream->rx_head == NULL) {
            RETVAL = &PL_sv_undef;
        } else {
            if (net_quic_stream_select_rx_mode(
                    stream,
                    NET_QUIC_STREAM_RX_MODE_AUTO
                ) != 0) {
                croak("unable to select automatic QUIC stream receive mode");
            }

            rv = net_quic_stream_consume_rx(ep, stream, &chunk);
            if (rv != 0) {
                croak(
                    "unable to consume QUIC stream data: %s",
                    ngtcp2_strerror(rv)
                );
            }

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

SV *
_stream_take_data_chunk(self, stream_id_iv)
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

        if (stream->rx_mode == NET_QUIC_STREAM_RX_MODE_AUTO) {
            croak(
                "cannot use next_data_chunk after automatic QUIC stream receive consumption"
            );
        }

        if (stream->rx_head == NULL) {
            RETVAL = &PL_sv_undef;
        } else {
            if (net_quic_stream_select_rx_mode(
                    stream,
                    NET_QUIC_STREAM_RX_MODE_EXPLICIT
                ) != 0) {
                croak("unable to select explicit QUIC stream receive mode");
            }

            rv = net_quic_stream_take_rx_explicit(stream, &chunk);
            if (rv != 0) {
                croak(
                    "unable to take QUIC stream data without consuming it: %s",
                    ngtcp2_strerror(rv)
                );
            }

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

void
_stream_consume(self, stream_id_iv, amount_uv)
    SV *self
    IV stream_id_iv
    UV amount_uv
    PREINIT:
        net_quic_connection *ep;
        net_quic_stream_state *stream;
        uint64_t amount;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);
        stream = net_quic_stream_find(ep, (int64_t)stream_id_iv);
        if (stream == NULL) {
            croak("unknown QUIC stream");
        }

        if (stream->rx_mode == NET_QUIC_STREAM_RX_MODE_AUTO) {
            croak(
                "cannot use consume after automatic QUIC stream receive consumption"
            );
        }

        if (net_quic_stream_select_rx_mode(
                stream,
                NET_QUIC_STREAM_RX_MODE_EXPLICIT
            ) != 0) {
            croak("unable to select explicit QUIC stream receive mode");
        }

        amount = (uint64_t)amount_uv;
        if (amount > stream->rx_unconsumed) {
            croak(
                "cannot consume more QUIC stream data than has been delivered"
            );
        }

        rv = net_quic_stream_consume_explicit_rx(ep, stream, amount);
        if (rv != 0) {
            croak(
                "unable to consume explicit QUIC stream data: %s",
                ngtcp2_strerror(rv)
            );
        }

UV
_stream_acked_offset(self, stream_id_iv)
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

        RETVAL = (UV)stream->tx_acked_through;
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

int
_stream_early_data(self, stream_id_iv)
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
        RETVAL = stream->early_data ? 1 : 0;
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

SV *
_stream_remote_stop_sending_code(self, stream_id_iv)
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

        if (!stream->remote_stop_sending) {
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = newSVuv((UV)stream->remote_stop_sending_code);
        }
    OUTPUT:
        RETVAL

SV *
_stream_local_stop_sending_code(self, stream_id_iv)
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

        if (!stream->local_stop_sending) {
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = newSVuv((UV)stream->local_stop_sending_code);
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

        if (stream->local_reset || stream->remote_stop_sending || stream->closed) {
            XSRETURN_EMPTY;
        }

        rv = ngtcp2_conn_shutdown_stream_write(
            ep->conn,
            0,
            stream->id,
            (uint64_t)app_error_code_uv
        );
        if (rv != 0) {
            croak("unable to reset QUIC stream send side: %s", ngtcp2_strerror(rv));
        }

        stream->local_reset = 1;
        stream->local_reset_code = (uint64_t)app_error_code_uv;
        stream->write_shutdown = 1;
        net_quic_stream_free_tx(aTHX_ ep, stream);
        net_quic_stream_reclaim_closed(aTHX_ ep);

void
_stream_stop_sending(self, stream_id_iv, app_error_code_uv)
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

        if (stream->local_stop_sending || stream->closed) {
            XSRETURN_EMPTY;
        }

        rv = ngtcp2_conn_shutdown_stream_read(
            ep->conn,
            0,
            stream->id,
            (uint64_t)app_error_code_uv
        );
        if (rv != 0) {
            croak(
                "unable to stop receiving QUIC stream: %s",
                ngtcp2_strerror(rv)
            );
        }

        stream->local_stop_sending = 1;
        stream->local_stop_sending_code = (uint64_t)app_error_code_uv;
        stream->read_shutdown = 1;
        net_quic_stream_discard_rx(aTHX_ ep, stream);
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
            aTHX_ ep,
            stream,
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
        while (stream != NULL &&
               (stream->rx_head == NULL ||
                stream->rx_mode == NET_QUIC_STREAM_RX_MODE_EXPLICIT)) {
            stream = stream->next;
        }

        if (stream == NULL) {
            RETVAL = &PL_sv_undef;
        } else {
            if (net_quic_stream_select_rx_mode(
                    stream,
                    NET_QUIC_STREAM_RX_MODE_AUTO
                ) != 0) {
                croak("unable to select automatic QUIC stream receive mode");
            }

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
                &close_peer,
                ep->close_ecn
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
                &ps.path.remote,
                pi.ecn
            );
        }

        next_datagram_done:
        net_quic_stream_reclaim_closed(aTHX_ ep);
        ;
    OUTPUT:
        RETVAL

void
_receive_datagram(self, data_sv, local_sv, peer_sv, ecn_uv = 0)
    SV *self
    SV *data_sv
    SV *local_sv
    SV *peer_sv
    UV ecn_uv
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

        if (ecn_uv > NGTCP2_ECN_CE) {
            croak("ECN codepoint must be an integer from 0 through 3");
        }

        memset(&path, 0, sizeof(path));
        path.local.addr = &local_addr.sa;
        path.local.addrlen = local_addrlen;
        path.remote.addr = &peer_addr.sa;
        path.remote.addrlen = peer_addrlen;
        memset(&pi, 0, sizeof(pi));
        pi.ecn = (uint8_t)ecn_uv;

        now = net_quic_now();
        rv = ngtcp2_conn_read_pkt(
            ep->conn,
            &path,
            &pi,
            (const uint8_t *)data,
            (size_t)datalen,
            now
        );

        /*
         * recv_stop_sending runs inside ngtcp2_conn_read_pkt before ngtcp2
         * clears its own references to queued stream data.  Release our
         * transmit buffers only after the read call has returned.
         */
        net_quic_stream_apply_deferred_discards(aTHX_ ep);

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
            ep->close_ecn = pi.ecn & NGTCP2_ECN_MASK;
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

void
_migrate(self, local_sv)
    SV *self
    SV *local_sv
    PREINIT:
        net_quic_connection *ep;
        const ngtcp2_path *current;
        const char *local;
        STRLEN locallen;
        ngtcp2_sockaddr_union local_addr;
        ngtcp2_socklen local_addrlen;
        ngtcp2_path path;
        ngtcp2_tstamp now;
        int rv;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (ep->is_server) {
            croak("only a QUIC client can initiate active migration");
        }
        if (!ep->ready) {
            croak("cannot migrate before the QUIC handshake is ready");
        }

        local = SvPVbyte(local_sv, locallen);
        if (net_quic_copy_sockaddr(
                &local_addr,
                &local_addrlen,
                local,
                locallen
            ) != 0 ||
            net_quic_sockaddr_is_unspecified(&local_addr)) {
            croak("migration local address must be a concrete packed IPv4 or IPv6 socket address");
        }

        current = ngtcp2_conn_get_path2(ep->conn);
        if (current == NULL ||
            current->remote.addr == NULL ||
            current->remote.addrlen == 0) {
            croak("QUIC connection has no current network path");
        }

        memset(&path, 0, sizeof(path));
        path.local.addr = &local_addr.sa;
        path.local.addrlen = local_addrlen;
        path.remote = current->remote;

        now = net_quic_now();
        rv = ngtcp2_conn_initiate_migration(ep->conn, &path, now);
        if (rv == NGTCP2_ERR_INVALID_STATE) {
            croak("cannot migrate before the QUIC handshake is confirmed or while another path transition is active");
        }
        if (rv == NGTCP2_ERR_CONN_ID_BLOCKED) {
            croak("cannot migrate because no unused peer connection ID is available");
        }
        if (rv == NGTCP2_ERR_INVALID_ARGUMENT) {
            croak("migration requires a different local network path");
        }
        if (rv != 0) {
            croak("unable to start QUIC migration: %s", ngtcp2_strerror(rv));
        }

UV
path_max_udp_payload_size(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);
        RETVAL = (UV)ngtcp2_conn_get_path_max_tx_udp_payload_size2(ep->conn);
    OUTPUT:
        RETVAL

SV *
_path(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        const ngtcp2_path *path;
        AV *av;
    CODE:
        ep = net_quic_connection_from_sv(self);
        path = ngtcp2_conn_get_path2(ep->conn);

        if (path == NULL ||
            path->local.addr == NULL ||
            path->remote.addr == NULL) {
            RETVAL = &PL_sv_undef;
        } else {
            av = newAV();
            av_push(
                av,
                newSVpvn(
                    (const char *)path->local.addr,
                    (STRLEN)path->local.addrlen
                )
            );
            av_push(
                av,
                newSVpvn(
                    (const char *)path->remote.addr,
                    (STRLEN)path->remote.addrlen
                )
            );
            RETVAL = newRV_noinc((SV *)av);
        }
    OUTPUT:
        RETVAL

SV *
_path_validation(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        AV *av;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (ep->path_validation_status == NET_QUIC_PATH_VALIDATION_NONE) {
            RETVAL = &PL_sv_undef;
        } else {
            av = newAV();
            av_push(av, newSViv(ep->path_validation_status));
            av_push(av, newSVuv((UV)ep->path_validation_flags));

            if (ep->path_validation_has_path) {
                av_push(
                    av,
                    newSVpvn(
                        (const char *)&ep->path_validation_local_addr.sa,
                        (STRLEN)ep->path_validation_local_addrlen
                    )
                );
                av_push(
                    av,
                    newSVpvn(
                        (const char *)&ep->path_validation_peer_addr.sa,
                        (STRLEN)ep->path_validation_peer_addrlen
                    )
                );
            } else {
                av_push(av, newSVsv(&PL_sv_undef));
                av_push(av, newSVsv(&PL_sv_undef));
            }

            RETVAL = newRV_noinc((SV *)av);
        }
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
version(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        uint32_t version;
        int public_version;
    CODE:
        ep = net_quic_connection_from_sv(self);
        version = ngtcp2_conn_get_negotiated_version2(ep->conn);
        public_version = net_quic_public_version(version);

        if (public_version == 0) {
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = newSViv(public_version);
        }
    OUTPUT:
        RETVAL

int
client_chosen_version(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        uint32_t version;
    CODE:
        ep = net_quic_connection_from_sv(self);
        version = ngtcp2_conn_get_client_chosen_version2(ep->conn);
        RETVAL = net_quic_public_version(version);
        if (RETVAL == 0) {
            croak("unknown QUIC client-chosen version");
        }
    OUTPUT:
        RETVAL

int
resumed(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
    CODE:
        ep = net_quic_connection_from_sv(self);
        RETVAL = ep->resumed ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
_session_ticket_state(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        AV *av;
        int public_version;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (ep->session_ticket == NULL ||
            ep->session_ticket_len == 0 ||
            ep->session_ticket_version == 0) {
            RETVAL = &PL_sv_undef;
        } else {
            public_version =
                net_quic_public_version(ep->session_ticket_version);
            if (public_version == 0) {
                croak("unknown TLS session ticket QUIC version");
            }

            av = newAV();
            av_push(av, newSViv(public_version));
            av_push(
                av,
                newSVpvn(
                    (const char *)ep->session_ticket,
                    (STRLEN)ep->session_ticket_len
                )
            );
            RETVAL = newRV_noinc((SV *)av);
        }
    OUTPUT:
        RETVAL


SV *
_address_token_state(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        AV *av;
        int public_version;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (ep->address_token == NULL ||
            ep->address_token_len == 0 ||
            ep->address_token_version == 0) {
            RETVAL = &PL_sv_undef;
        } else {
            public_version =
                net_quic_public_version(ep->address_token_version);
            if (public_version == 0) {
                croak("unknown NEW_TOKEN QUIC version");
            }

            av = newAV();
            av_push(av, newSViv(public_version));
            av_push(
                av,
                newSVpvn(
                    (const char *)ep->address_token,
                    (STRLEN)ep->address_token_len
                )
            );
            RETVAL = newRV_noinc((SV *)av);
        }
    OUTPUT:
        RETVAL


SV *
_early_data_transport_params(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        uint8_t *buf = NULL;
        size_t buflen = 256;
        ngtcp2_ssize nwrite;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (!ep->ready ||
            ep->session_ticket == NULL ||
            ep->session_ticket_len == 0) {
            RETVAL = &PL_sv_undef;
        } else {
            for (;;) {
                Newx(buf, buflen, uint8_t);
                if (buf == NULL) {
                    croak("unable to allocate early-data transport state");
                }

                nwrite = ngtcp2_conn_encode_0rtt_transport_params2(
                    ep->conn,
                    buf,
                    buflen
                );

                if (nwrite != NGTCP2_ERR_NOBUF) {
                    break;
                }

                Safefree(buf);
                buf = NULL;

                if (buflen >= 16384) {
                    croak("early-data transport state is unexpectedly large");
                }
                buflen *= 2;
            }

            if (nwrite < 0) {
                Safefree(buf);
                croak(
                    "unable to encode early-data transport state: %s",
                    ngtcp2_strerror((int)nwrite)
                );
            }

            RETVAL = newSVpvn((const char *)buf, (STRLEN)nwrite);
            Safefree(buf);
        }
    OUTPUT:
        RETVAL

int
_early_data_status(self)
    SV *self
    PREINIT:
        net_quic_connection *ep;
        ptls_early_data_acceptance_t acceptance;
    CODE:
        ep = net_quic_connection_from_sv(self);

        if (!ep->early_data_attempted) {
            RETVAL = 0;
        } else if (ep->early_data_rejected) {
            RETVAL = 3;
        } else if (ep->early_data_accepted) {
            RETVAL = 2;
        } else if (ep->picotls_ctx.ptls != NULL) {
            acceptance =
                ep->picotls_ctx.handshake_properties.client.early_data_acceptance;
            if (acceptance == PTLS_EARLY_DATA_ACCEPTED) {
                RETVAL = 2;
            } else if (acceptance == PTLS_EARLY_DATA_REJECTED) {
                RETVAL = 3;
            } else {
                RETVAL = 1;
            }
        } else {
            RETVAL = 1;
        }
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
        uint8_t regular_token_secret[NET_QUIC_SERVER_SECRET_LEN];
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
                        av_push(
                            av,
                            newSViv(NGTCP2_TOKEN_TYPE_RETRY)
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
                } else if (
                    hd.tokenlen != 0 &&
                    hd.token[0] == NGTCP2_CRYPTO_TOKEN_MAGIC_REGULAR
                ) {
                    now = net_quic_system_now();

                    if (net_quic_new_token_secret(
                            regular_token_secret,
                            (const uint8_t *)secret,
                            hd.version
                        ) != 0) {
                        croak("unable to derive NEW_TOKEN version secret");
                    }

                    rv = ngtcp2_crypto_verify_regular_token(
                        hd.token,
                        hd.tokenlen,
                        regular_token_secret,
                        sizeof(regular_token_secret),
                        &peer_addr.sa,
                        peer_addrlen,
                        NET_QUIC_NEW_TOKEN_TIMEOUT,
                        now
                    );

                    ptls_clear_memory(
                        regular_token_secret,
                        sizeof(regular_token_secret)
                    );

                    if (rv == 0) {
                        av_push(av, newSViv(2));
                        av_push(av, newSV(0));
                        av_push(
                            av,
                            newSViv(NGTCP2_TOKEN_TYPE_NEW_TOKEN)
                        );
                        RETVAL = newRV_noinc((SV *)av);
                    } else if (validate_address) {
                        /*
                         * An invalid NEW_TOKEN is not a fatal token error.
                         * Treat the address as unvalidated and use Retry.
                         */
                        retry_scid.datalen = NET_QUIC_SERVER_CIDLEN;
                        if (net_quic_random_bytes(
                                retry_scid.data,
                                retry_scid.datalen
                            ) != 0) {
                            croak("unable to generate Retry connection ID");
                        }

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
                            newSVpvn(
                                (const char *)response,
                                (STRLEN)nwrite
                            )
                        );
                        RETVAL = newRV_noinc((SV *)av);
                    } else {
                        av_push(av, newSViv(2));
                        av_push(av, newSV(0));
                        av_push(
                            av,
                            newSViv(NGTCP2_TOKEN_TYPE_UNKNOWN)
                        );
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
                    av_push(
                        av,
                        newSViv(NGTCP2_TOKEN_TYPE_UNKNOWN)
                    );
                    RETVAL = newRV_noinc((SV *)av);
                }
            }
        }
    OUTPUT:
        RETVAL
