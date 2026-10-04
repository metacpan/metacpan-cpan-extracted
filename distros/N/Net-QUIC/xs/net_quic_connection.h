#include <stdio.h>
#include <stdlib.h>

static FILE *
net_quic_system_fopen(const char *path, const char *mode)
{
    return fopen(path, mode);
}

static int
net_quic_system_fclose(FILE *fp)
{
    return fclose(fp);
}

static void *
net_quic_system_calloc(size_t count, size_t size)
{
    return calloc(count, size);
}

static void
net_quic_system_free(void *ptr)
{
    free(ptr);
}

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <limits.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

#include <ngtcp2/ngtcp2.h>
#include <ngtcp2/ngtcp2_crypto.h>

#if defined(_WIN32) || defined(WIN32)
# include <windows.h>
#else
# include <time.h>
#endif

#include <ngtcp2/ngtcp2_crypto_picotls.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/x509_vfy.h>
#include <picotls.h>
#include <picotls/openssl.h>

#define NET_QUIC_TX_BUFSIZE 65536
#define NET_QUIC_SERVER_CIDLEN 16
#define NET_QUIC_SERVER_SECRET_LEN 32
#define NET_QUIC_STATELESS_RESET_MAX_RANDLEN \
    (NGTCP2_MAX_CIDLEN + 22 - NGTCP2_STATELESS_RESET_TOKENLEN)
#define NET_QUIC_RETRY_TOKEN_TIMEOUT (10 * NGTCP2_SECONDS)
#define NET_QUIC_NEW_TOKEN_TIMEOUT (24 * 60 * 60 * NGTCP2_SECONDS)

static const char *
net_quic_crypto_backend(void)
{
    return "picotls";
}

typedef struct net_quic_connection net_quic_connection;
typedef struct net_quic_stream_state net_quic_stream_state;
typedef struct net_quic_cid_event net_quic_cid_event;
typedef struct net_quic_application_datagram net_quic_application_datagram;
typedef struct net_quic_server_tls net_quic_server_tls;

struct net_quic_cid_event {
    int add;
    ngtcp2_cid cid;
    net_quic_cid_event *next;
};

struct net_quic_application_datagram {
    uint8_t *data;
    size_t len;
    uint8_t early_data;
    net_quic_application_datagram *next;
};

#define NET_QUIC_DATAGRAM_RX_BUFFER_LIMIT (256u * 1024u)
#define NET_QUIC_DATAGRAM_RX_COUNT_LIMIT 1024u
#define NET_QUIC_1RTT_AEAD_OVERHEAD 16u
#define NET_QUIC_MAX_PKT_NUMLEN 4u
#define NET_QUIC_0RTT_LONG_HEADER_OVERHEAD \
    (1u + 4u + 1u + NGTCP2_MAX_CIDLEN + 1u + NGTCP2_MAX_CIDLEN + 8u + \
     NET_QUIC_MAX_PKT_NUMLEN + NET_QUIC_1RTT_AEAD_OVERHEAD)

#define NET_QUIC_STREAM_AVAILABLE_BIDI 0x01u
#define NET_QUIC_STREAM_AVAILABLE_UNI  0x02u

#define NET_QUIC_CLOSE_INFO_NONE        0
#define NET_QUIC_CLOSE_INFO_APPLICATION 1
#define NET_QUIC_CLOSE_INFO_TRANSPORT   2
#define NET_QUIC_CLOSE_INFO_TLS         3
#define NET_QUIC_CLOSE_INFO_CERTIFICATE 4
#define NET_QUIC_CLOSE_INFO_HANDSHAKE   5
#define NET_QUIC_CLOSE_INFO_IDLE        6
#define NET_QUIC_CLOSE_INFO_DROP        7

#define NET_QUIC_CLOSE_INITIATOR_NONE  0
#define NET_QUIC_CLOSE_INITIATOR_LOCAL 1
#define NET_QUIC_CLOSE_INITIATOR_PEER  2

#define NET_QUIC_PATH_VALIDATION_NONE       0
#define NET_QUIC_PATH_VALIDATION_VALIDATING 1
#define NET_QUIC_PATH_VALIDATION_SUCCESS    2
#define NET_QUIC_PATH_VALIDATION_FAILURE    3
#define NET_QUIC_PATH_VALIDATION_ABORTED    4

struct net_quic_connection {
    ngtcp2_conn *conn;
    ngtcp2_crypto_conn_ref conn_ref;

    ngtcp2_sockaddr_union local_addr;
    ngtcp2_socklen local_addrlen;
    ngtcp2_sockaddr_union peer_addr;
    ngtcp2_socklen peer_addrlen;

    char *alpn;
    size_t alpnlen;
    char *server_name;
    SV *server_tls_owner;
    uint8_t *resume_ticket;
    size_t resume_ticket_len;
    uint8_t *session_ticket;
    size_t session_ticket_len;
    uint32_t session_ticket_version;
    uint8_t *address_token;
    size_t address_token_len;
    uint32_t address_token_version;
    int issue_new_token;
    int ready;
    int resumed;
    int early_data_attempted;
    int early_data_accepted;
    int early_data_rejected;
    int is_server;
    int local_bidi_stream_waiting;
    int local_uni_stream_waiting;
    unsigned int stream_available_events;
    uint8_t server_secret[NET_QUIC_SERVER_SECRET_LEN];
    int retired;
    int close_wait;
    ngtcp2_tstamp retirement_deadline;

    int close_info_type;
    int close_info_initiator;
    uint64_t close_info_code;
    uint64_t close_info_frame_type;
    int close_info_native_error;

    int path_validation_status;
    uint32_t path_validation_flags;
    int path_validation_has_path;
    ngtcp2_sockaddr_union path_validation_local_addr;
    ngtcp2_socklen path_validation_local_addrlen;
    ngtcp2_sockaddr_union path_validation_peer_addr;
    ngtcp2_socklen path_validation_peer_addrlen;

    size_t closebuflen;
    uint8_t close_ecn;
    int closebuf_pending;
    ngtcp2_sockaddr_union close_local_addr;
    ngtcp2_socklen close_local_addrlen;
    ngtcp2_sockaddr_union close_peer_addr;
    ngtcp2_socklen close_peer_addrlen;

    net_quic_cid_event *cid_event_head;
    net_quic_cid_event *cid_event_tail;

    uint8_t txbuf[NET_QUIC_TX_BUFSIZE];
    int tx_batch_active;

    net_quic_application_datagram *datagram_tx_pending;
    net_quic_application_datagram *datagram_rx_head;
    net_quic_application_datagram *datagram_rx_tail;
    size_t datagram_rx_buffered_bytes;
    size_t datagram_rx_count;
    uint64_t datagram_rx_dropped;

    net_quic_stream_state *streams;
    net_quic_stream_state *streams_tail;
    net_quic_stream_state **stream_index;
    size_t stream_index_bucket_count;
    size_t stream_index_size;
    net_quic_stream_state *incoming_stream_head;
    net_quic_stream_state *incoming_stream_tail;
    net_quic_stream_state *stream_activity_head;
    net_quic_stream_state *stream_activity_tail;
    net_quic_stream_state *tx_cursor;
    int stream_activity_enabled;
    int stream_tx_buffer_limit_enabled;
    uint64_t stream_tx_buffer_limit;
    uint64_t stream_tx_buffered_bytes;

    ptls_context_t ptls_ctx;
    ngtcp2_crypto_picotls_ctx picotls_ctx;
    ptls_iovec_t picotls_alpn;
    ptls_openssl_verify_certificate_t picotls_verify_cert;
    int picotls_verify_cert_ready;
};

static net_quic_application_datagram *
net_quic_application_datagram_new(const uint8_t *data, size_t datalen)
{
    net_quic_application_datagram *datagram = NULL;

    Newxz(datagram, 1, net_quic_application_datagram);
    if (datagram == NULL) {
        return NULL;
    }

    if (datalen != 0) {
        Newx(datagram->data, datalen, uint8_t);
        if (datagram->data == NULL) {
            Safefree(datagram);
            return NULL;
        }

        memcpy(datagram->data, data, datalen);
    }

    datagram->len = datalen;
    return datagram;
}

static void
net_quic_application_datagram_free(net_quic_application_datagram *datagram)
{
    if (datagram == NULL) {
        return;
    }

    Safefree(datagram->data);
    Safefree(datagram);
}

static void
net_quic_application_datagrams_free(net_quic_connection *ep)
{
    net_quic_application_datagram *datagram;
    net_quic_application_datagram *next;

    datagram = ep->datagram_rx_head;
    while (datagram != NULL) {
        next = datagram->next;
        net_quic_application_datagram_free(datagram);
        datagram = next;
    }

    ep->datagram_rx_head = NULL;
    ep->datagram_rx_tail = NULL;
    ep->datagram_rx_buffered_bytes = 0;
    ep->datagram_rx_count = 0;

    net_quic_application_datagram_free(ep->datagram_tx_pending);
    ep->datagram_tx_pending = NULL;
}

static size_t
net_quic_varint_len(uint64_t value)
{
    if (value < 64) {
        return 1;
    }
    if (value < 16384) {
        return 2;
    }
    if (value < 1073741824) {
        return 4;
    }
    return 8;
}

static int
net_quic_datagram_payload_fits(uint64_t max_frame_size, size_t datalen)
{
    uint64_t payload;
    uint64_t overhead;

    payload = (uint64_t)datalen;
    if (payload > NGTCP2_MAX_VARINT) {
        return 0;
    }

    overhead = 1u + (uint64_t)net_quic_varint_len(payload);
    if (overhead > max_frame_size) {
        return 0;
    }

    return payload <= max_frame_size - overhead;
}

static size_t
net_quic_max_datagram_payload_size(net_quic_connection *ep)
{
    const ngtcp2_transport_params *params;
    const ngtcp2_cid *dcid;
    uint64_t path_max;
    uint64_t packet_overhead;
    uint64_t frame_limit;
    uint64_t candidate;

    params = ngtcp2_conn_get_remote_transport_params2(ep->conn);
    if (params == NULL || params->max_datagram_frame_size == 0) {
        return 0;
    }

    dcid = ngtcp2_conn_get_dcid(ep->conn);
    path_max = ngtcp2_conn_get_path_max_tx_udp_payload_size2(ep->conn);

    if (!ep->ready && ep->early_data_attempted) {
        packet_overhead = NET_QUIC_0RTT_LONG_HEADER_OVERHEAD;
    } else {
        packet_overhead =
            1u +
            (uint64_t)dcid->datalen +
            NET_QUIC_MAX_PKT_NUMLEN +
            NET_QUIC_1RTT_AEAD_OVERHEAD;
    }

    if (path_max <= packet_overhead) {
        return 0;
    }

    frame_limit = path_max - packet_overhead;
    candidate = params->max_datagram_frame_size < frame_limit
        ? params->max_datagram_frame_size
        : frame_limit;

    if (candidate > (uint64_t)SIZE_MAX) {
        candidate = (uint64_t)SIZE_MAX;
    }

    while (candidate != 0 &&
           (!net_quic_datagram_payload_fits(
                params->max_datagram_frame_size,
                (size_t)candidate
            ) ||
            !net_quic_datagram_payload_fits(
                frame_limit,
                (size_t)candidate
            ))) {
        --candidate;
    }

    return (size_t)candidate;
}

static int
net_quic_recv_datagram_cb(
    ngtcp2_conn *conn,
    uint32_t flags,
    const uint8_t *data,
    size_t datalen,
    void *user_data
)
{
    net_quic_connection *ep = (net_quic_connection *)user_data;
    net_quic_application_datagram *datagram;

    (void)conn;

    if (ep->datagram_rx_count >= NET_QUIC_DATAGRAM_RX_COUNT_LIMIT ||
        datalen > NET_QUIC_DATAGRAM_RX_BUFFER_LIMIT ||
        ep->datagram_rx_buffered_bytes >
            NET_QUIC_DATAGRAM_RX_BUFFER_LIMIT - datalen) {
        ++ep->datagram_rx_dropped;
        return 0;
    }

    datagram = net_quic_application_datagram_new(data, datalen);
    if (datagram == NULL) {
        ++ep->datagram_rx_dropped;
        return 0;
    }

    datagram->early_data =
        (flags & NGTCP2_DATAGRAM_FLAG_0RTT) != 0 ? 1 : 0;

    if (ep->datagram_rx_tail == NULL) {
        ep->datagram_rx_head = datagram;
    } else {
        ep->datagram_rx_tail->next = datagram;
    }
    ep->datagram_rx_tail = datagram;
    ep->datagram_rx_buffered_bytes += datalen;
    ++ep->datagram_rx_count;

    return 0;
}

static int
net_quic_extend_max_local_streams_bidi_cb(
    ngtcp2_conn *conn,
    uint64_t max_streams,
    void *user_data
)
{
    net_quic_connection *ep = (net_quic_connection *)user_data;

    (void)conn;
    (void)max_streams;

    if (ep->local_bidi_stream_waiting) {
        ep->local_bidi_stream_waiting = 0;
        ep->stream_available_events |= NET_QUIC_STREAM_AVAILABLE_BIDI;
    }

    return 0;
}

static int
net_quic_extend_max_local_streams_uni_cb(
    ngtcp2_conn *conn,
    uint64_t max_streams,
    void *user_data
)
{
    net_quic_connection *ep = (net_quic_connection *)user_data;

    (void)conn;
    (void)max_streams;

    if (ep->local_uni_stream_waiting) {
        ep->local_uni_stream_waiting = 0;
        ep->stream_available_events |= NET_QUIC_STREAM_AVAILABLE_UNI;
    }

    return 0;
}

static int
net_quic_tls_alert_is_certificate(uint8_t alert)
{
    switch (alert) {
    case 42:
    case 43:
    case 44:
    case 45:
    case 46:
    case 48:
        return 1;
    default:
        return 0;
    }
}

static void
net_quic_set_close_info(
    net_quic_connection *ep,
    int type,
    int initiator,
    uint64_t code,
    uint64_t frame_type,
    int native_error
)
{
    if (ep->close_info_type != NET_QUIC_CLOSE_INFO_NONE) {
        return;
    }

    ep->close_info_type = type;
    ep->close_info_initiator = initiator;
    ep->close_info_code = code;
    ep->close_info_frame_type = frame_type;
    ep->close_info_native_error = native_error;
}

static void
net_quic_capture_peer_close(net_quic_connection *ep)
{
    const ngtcp2_ccerr *ccerr = ngtcp2_conn_get_ccerr(ep->conn);
    int type = NET_QUIC_CLOSE_INFO_TRANSPORT;
    uint64_t code = ccerr->error_code;

    if (ccerr->type == NGTCP2_CCERR_TYPE_APPLICATION) {
        type = NET_QUIC_CLOSE_INFO_APPLICATION;
    } else if (ccerr->type == NGTCP2_CCERR_TYPE_IDLE_CLOSE) {
        type = NET_QUIC_CLOSE_INFO_IDLE;
    } else if (ccerr->type == NGTCP2_CCERR_TYPE_DROP_CONN) {
        type = NET_QUIC_CLOSE_INFO_DROP;
    } else if (ccerr->type == NGTCP2_CCERR_TYPE_TRANSPORT &&
               code >= NGTCP2_CRYPTO_ERROR &&
               code <= NGTCP2_CRYPTO_ERROR + 255) {
        uint8_t alert = (uint8_t)(code - NGTCP2_CRYPTO_ERROR);
        type = net_quic_tls_alert_is_certificate(alert)
            ? NET_QUIC_CLOSE_INFO_CERTIFICATE
            : NET_QUIC_CLOSE_INFO_TLS;
        code = (uint64_t)alert;
    }

    net_quic_set_close_info(
        ep,
        type,
        NET_QUIC_CLOSE_INITIATOR_PEER,
        code,
        ccerr->frame_type,
        0
    );
}

static void
net_quic_capture_local_failure(net_quic_connection *ep, int rv)
{
    uint8_t alert;

    if (rv == NGTCP2_ERR_CRYPTO) {
        alert = ngtcp2_conn_get_tls_alert(ep->conn);
        net_quic_set_close_info(
            ep,
            net_quic_tls_alert_is_certificate(alert)
                ? NET_QUIC_CLOSE_INFO_CERTIFICATE
                : NET_QUIC_CLOSE_INFO_TLS,
            NET_QUIC_CLOSE_INITIATOR_LOCAL,
            (uint64_t)alert,
            0,
            rv
        );
        return;
    }

    if (rv == NGTCP2_ERR_HANDSHAKE_TIMEOUT) {
        net_quic_set_close_info(
            ep,
            NET_QUIC_CLOSE_INFO_HANDSHAKE,
            NET_QUIC_CLOSE_INITIATOR_LOCAL,
            0,
            0,
            rv
        );
        return;
    }

    net_quic_set_close_info(
        ep,
        NET_QUIC_CLOSE_INFO_TRANSPORT,
        NET_QUIC_CLOSE_INITIATOR_LOCAL,
        ngtcp2_err_infer_quic_transport_error_code(rv),
        0,
        rv
    );
}

static ngtcp2_tstamp
net_quic_system_now(void)
{
    time_t now = time(NULL);

    if (now == (time_t)-1) {
        croak("unable to read system clock");
    }

    return (ngtcp2_tstamp)now * NGTCP2_SECONDS;
}

static ngtcp2_tstamp
net_quic_now(void)
{
#if defined(_WIN32) || defined(WIN32)
    LARGE_INTEGER freq;
    LARGE_INTEGER counter;
    uint64_t whole;
    uint64_t rem;

    if (!QueryPerformanceFrequency(&freq) || !QueryPerformanceCounter(&counter)) {
        croak("unable to read monotonic clock");
    }

    whole = (uint64_t)counter.QuadPart / (uint64_t)freq.QuadPart;
    rem = (uint64_t)counter.QuadPart % (uint64_t)freq.QuadPart;

    return whole * NGTCP2_SECONDS
         + rem * NGTCP2_SECONDS / (uint64_t)freq.QuadPart;
#else
    struct timespec ts;

    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        croak("unable to read monotonic clock");
    }

    return (ngtcp2_tstamp)ts.tv_sec * NGTCP2_SECONDS
         + (ngtcp2_tstamp)ts.tv_nsec;
#endif
}

static int
net_quic_random_bytes(uint8_t *dest, size_t destlen)
{
    return RAND_bytes(dest, (int)destlen) == 1 ? 0 : -1;
}

static void
net_quic_rand_cb(uint8_t *dest, size_t destlen, const ngtcp2_rand_ctx *rand_ctx)
{
    (void)rand_ctx;

    if (net_quic_random_bytes(dest, destlen) != 0) {
        abort();
    }
}

static int
net_quic_queue_cid_event(
    pTHX_ net_quic_connection *ep,
    int add,
    const ngtcp2_cid *cid
)
{
    net_quic_cid_event *event;

    Newxz(event, 1, net_quic_cid_event);
    if (event == NULL) {
        return -1;
    }

    event->add = add ? 1 : 0;
    event->cid = *cid;

    if (ep->cid_event_tail != NULL) {
        ep->cid_event_tail->next = event;
    } else {
        ep->cid_event_head = event;
    }
    ep->cid_event_tail = event;

    return 0;
}

static void
net_quic_cid_events_free(pTHX_ net_quic_connection *ep)
{
    net_quic_cid_event *event;
    net_quic_cid_event *next;

    for (event = ep->cid_event_head; event != NULL; event = next) {
        next = event->next;
        Safefree(event);
    }

    ep->cid_event_head = NULL;
    ep->cid_event_tail = NULL;
}

static int
net_quic_get_new_connection_id_cb(
    ngtcp2_conn *conn,
    ngtcp2_cid *cid,
    ngtcp2_stateless_reset_token *token,
    size_t cidlen,
    void *user_data
)
{
    dTHX;
    net_quic_connection *ep = (net_quic_connection *)user_data;

    (void)conn;

    if (cidlen > sizeof(cid->data) ||
        (ep->is_server && cidlen != NET_QUIC_SERVER_CIDLEN)) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    if (net_quic_random_bytes(cid->data, cidlen) != 0) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    cid->datalen = cidlen;

    if (ep->is_server) {
        if (ngtcp2_crypto_generate_stateless_reset_token(
                token->data,
                ep->server_secret,
                sizeof(ep->server_secret),
                cid
            ) != 0) {
            return NGTCP2_ERR_CALLBACK_FAILURE;
        }
    } else if (net_quic_random_bytes(token->data, sizeof(token->data)) != 0) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    if (ep->is_server &&
        net_quic_queue_cid_event(aTHX_ ep, 1, cid) != 0) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    return 0;
}

static int
net_quic_remove_connection_id_cb(
    ngtcp2_conn *conn,
    const ngtcp2_cid *cid,
    void *user_data
)
{
    dTHX;
    net_quic_connection *ep = (net_quic_connection *)user_data;

    (void)conn;

    if (!ep->is_server) {
        return 0;
    }

    return net_quic_queue_cid_event(aTHX_ ep, 0, cid) == 0
        ? 0
        : NGTCP2_ERR_CALLBACK_FAILURE;
}

static int
net_quic_new_token_secret(
    uint8_t out[NET_QUIC_SERVER_SECRET_LEN],
    const uint8_t base[NET_QUIC_SERVER_SECRET_LEN],
    uint32_t version
)
{
    static const uint8_t label[] = "Net::QUIC NEW_TOKEN v1";
    uint8_t input[
        NET_QUIC_SERVER_SECRET_LEN + sizeof(label) - 1 + 4
    ];
    unsigned int digest_len = 0;
    size_t offset = 0;

    memcpy(input + offset, base, NET_QUIC_SERVER_SECRET_LEN);
    offset += NET_QUIC_SERVER_SECRET_LEN;
    memcpy(input + offset, label, sizeof(label) - 1);
    offset += sizeof(label) - 1;
    input[offset++] = (uint8_t)(version >> 24);
    input[offset++] = (uint8_t)(version >> 16);
    input[offset++] = (uint8_t)(version >> 8);
    input[offset++] = (uint8_t)version;

    if (EVP_Digest(
            input,
            offset,
            out,
            &digest_len,
            EVP_sha256(),
            NULL
        ) != 1 ||
        digest_len != NET_QUIC_SERVER_SECRET_LEN) {
        ptls_clear_memory(input, sizeof(input));
        return -1;
    }

    ptls_clear_memory(input, sizeof(input));
    return 0;
}

static int
net_quic_submit_new_token(
    net_quic_connection *ep,
    ngtcp2_conn *conn,
    const ngtcp2_path *path
)
{
    uint8_t token[NGTCP2_CRYPTO_MAX_REGULAR_TOKENLEN];
    uint8_t token_secret[NET_QUIC_SERVER_SECRET_LEN];
    uint32_t version;
    ngtcp2_ssize tokenlen;
    ngtcp2_tstamp now;
    int rv;

    if (!ep->is_server || !ep->issue_new_token || path == NULL ||
        path->remote.addr == NULL || path->remote.addrlen == 0) {
        return 0;
    }

    version = ngtcp2_conn_get_negotiated_version2(conn);
    if (version == 0 ||
        net_quic_new_token_secret(
            token_secret,
            ep->server_secret,
            version
        ) != 0) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    now = net_quic_system_now();
    tokenlen = ngtcp2_crypto_generate_regular_token(
        token,
        token_secret,
        sizeof(token_secret),
        path->remote.addr,
        path->remote.addrlen,
        now
    );
    ptls_clear_memory(token_secret, sizeof(token_secret));

    if (tokenlen < 0) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    rv = ngtcp2_conn_submit_new_token(
        conn,
        token,
        (size_t)tokenlen
    );

    ptls_clear_memory(token, sizeof(token));

    return rv == 0 ? 0 : NGTCP2_ERR_CALLBACK_FAILURE;
}

static int
net_quic_recv_new_token_cb(
    ngtcp2_conn *conn,
    const uint8_t *token,
    size_t tokenlen,
    void *user_data
)
{
    dTHX;
    net_quic_connection *ep = (net_quic_connection *)user_data;
    uint8_t *copy;

    (void)conn;

    if (token == NULL || tokenlen == 0) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    Newx(copy, tokenlen, uint8_t);
    if (copy == NULL) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    memcpy(copy, token, tokenlen);

    if (ep->address_token != NULL) {
        ptls_clear_memory(ep->address_token, ep->address_token_len);
        Safefree(ep->address_token);
    }

    ep->address_token = copy;
    ep->address_token_len = tokenlen;
    ep->address_token_version =
        ngtcp2_conn_get_negotiated_version2(conn);

    if (ep->address_token_version == 0) {
        ptls_clear_memory(ep->address_token, ep->address_token_len);
        Safefree(ep->address_token);
        ep->address_token = NULL;
        ep->address_token_len = 0;
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    return 0;
}

static int
net_quic_handshake_completed_cb(ngtcp2_conn *conn, void *user_data)
{
    net_quic_connection *ep = (net_quic_connection *)user_data;

    ep->ready = 1;
    ep->resumed = ep->picotls_ctx.ptls != NULL
        && ptls_is_psk_handshake(ep->picotls_ctx.ptls);

    if (ep->early_data_attempted && ep->picotls_ctx.ptls != NULL) {
        ptls_early_data_acceptance_t acceptance =
            ep->picotls_ctx.handshake_properties.client.early_data_acceptance;

        if (acceptance == PTLS_EARLY_DATA_ACCEPTED) {
            ep->early_data_accepted = 1;
            ep->early_data_rejected = 0;
        } else if (acceptance == PTLS_EARLY_DATA_REJECTED) {
            ep->early_data_accepted = 0;
            ep->early_data_rejected = 1;
        }
    }

    if (ep->is_server && ep->issue_new_token) {
        const ngtcp2_path *path = ngtcp2_conn_get_path2(conn);

        if (net_quic_submit_new_token(ep, conn, path) != 0) {
            return NGTCP2_ERR_CALLBACK_FAILURE;
        }
    }

    return 0;
}

static ngtcp2_conn *
net_quic_get_conn(ngtcp2_crypto_conn_ref *conn_ref)
{
    net_quic_connection *ep = (net_quic_connection *)conn_ref->user_data;
    return ep->conn;
}

static int
net_quic_copy_sockaddr(
    ngtcp2_sockaddr_union *dest,
    ngtcp2_socklen *destlen,
    const char *src,
    STRLEN srclen
)
{
    ngtcp2_sockaddr *sa;

    if (srclen < sizeof(dest->sa.sa_family) || srclen > sizeof(*dest)) {
        return -1;
    }

    memset(dest, 0, sizeof(*dest));
    memcpy(dest, src, (size_t)srclen);

    sa = &dest->sa;
    if (sa->sa_family != NGTCP2_AF_INET && sa->sa_family != NGTCP2_AF_INET6) {
        return -1;
    }

    *destlen = (ngtcp2_socklen)srclen;
    return 0;
}

static int
net_quic_sockaddr_is_unspecified(
    const ngtcp2_sockaddr_union *addr
)
{
    const uint8_t *p;
    size_t i;

    if (addr->sa.sa_family == NGTCP2_AF_INET) {
        return addr->in.sin_addr.s_addr == 0;
    }

    if (addr->sa.sa_family != NGTCP2_AF_INET6) {
        return 0;
    }

    p = (const uint8_t *)&addr->in6.sin6_addr;

    for (i = 0; i < sizeof(addr->in6.sin6_addr); ++i) {
        if (p[i] != 0) {
            return 0;
        }
    }

    return 1;
}

static int
net_quic_copy_ngtcp2_addr(
    ngtcp2_sockaddr_union *dest,
    ngtcp2_socklen *destlen,
    const ngtcp2_addr *src
)
{
    if (src == NULL || src->addr == NULL ||
        src->addrlen > sizeof(*dest)) {
        return -1;
    }

    memset(dest, 0, sizeof(*dest));
    memcpy(dest, src->addr, (size_t)src->addrlen);
    *destlen = src->addrlen;
    return 0;
}


static int
net_quic_record_path_validation(
    net_quic_connection *ep,
    int status,
    uint32_t flags,
    const ngtcp2_path *path
)
{
    ep->path_validation_status = status;
    ep->path_validation_flags = flags;
    ep->path_validation_has_path = 0;

    if (path == NULL) {
        return 0;
    }

    if (net_quic_copy_ngtcp2_addr(
            &ep->path_validation_local_addr,
            &ep->path_validation_local_addrlen,
            &path->local
        ) != 0 ||
        net_quic_copy_ngtcp2_addr(
            &ep->path_validation_peer_addr,
            &ep->path_validation_peer_addrlen,
            &path->remote
        ) != 0) {
        return -1;
    }

    ep->path_validation_has_path = 1;
    return 0;
}

static int
net_quic_begin_path_validation_cb(
    ngtcp2_conn *conn,
    uint32_t flags,
    const ngtcp2_path *path,
    const ngtcp2_path *fallback_path,
    void *user_data
)
{
    net_quic_connection *ep = (net_quic_connection *)user_data;

    (void)conn;
    (void)fallback_path;

    return net_quic_record_path_validation(
        ep,
        NET_QUIC_PATH_VALIDATION_VALIDATING,
        flags,
        path
    ) == 0
        ? 0
        : NGTCP2_ERR_CALLBACK_FAILURE;
}

static int
net_quic_path_validation_cb(
    ngtcp2_conn *conn,
    uint32_t flags,
    const ngtcp2_path *path,
    const ngtcp2_path *fallback_path,
    ngtcp2_path_validation_result result,
    void *user_data
)
{
    net_quic_connection *ep = (net_quic_connection *)user_data;
    int status;

    (void)conn;
    (void)fallback_path;

    switch (result) {
    case NGTCP2_PATH_VALIDATION_RESULT_SUCCESS:
        status = NET_QUIC_PATH_VALIDATION_SUCCESS;
        break;
    case NGTCP2_PATH_VALIDATION_RESULT_FAILURE:
        status = NET_QUIC_PATH_VALIDATION_FAILURE;
        break;
    case NGTCP2_PATH_VALIDATION_RESULT_ABORTED:
        status = NET_QUIC_PATH_VALIDATION_ABORTED;
        break;
    default:
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    if (net_quic_record_path_validation(
            ep,
            status,
            flags,
            path
        ) != 0) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    if (result == NGTCP2_PATH_VALIDATION_RESULT_SUCCESS &&
        (flags & NGTCP2_PATH_VALIDATION_FLAG_NEW_TOKEN) != 0 &&
        ep->is_server &&
        ep->issue_new_token) {
        return net_quic_submit_new_token(ep, conn, path);
    }

    return 0;
}


static int
net_quic_select_preferred_addr_cb(
    ngtcp2_conn *conn,
    ngtcp2_path *dest,
    const ngtcp2_preferred_addr *paddr,
    void *user_data
)
{
    net_quic_connection *ep = (net_quic_connection *)user_data;
    const ngtcp2_path *current;

    (void)ep;

    current = ngtcp2_conn_get_path2(conn);
    if (current == NULL ||
        current->local.addr == NULL ||
        current->local.addrlen == 0) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    if (current->local.addr->sa_family == NGTCP2_AF_INET &&
        paddr->ipv4_present) {
        ngtcp2_sockaddr_in remote = paddr->ipv4;

#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__NetBSD__) || \
    defined(__OpenBSD__)
        remote.sin_len = (uint8_t)sizeof(remote);
#endif

        ngtcp2_addr_copy_byte(
            &dest->local,
            current->local.addr,
            current->local.addrlen
        );
        ngtcp2_addr_copy_byte(
            &dest->remote,
            (const ngtcp2_sockaddr *)&remote,
            (ngtcp2_socklen)sizeof(remote)
        );
        return 0;
    }

    if (current->local.addr->sa_family == NGTCP2_AF_INET6 &&
        paddr->ipv6_present) {
        ngtcp2_sockaddr_in6 remote = paddr->ipv6;

#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__NetBSD__) || \
    defined(__OpenBSD__)
        remote.sin6_len = (uint8_t)sizeof(remote);
#endif

        ngtcp2_addr_copy_byte(
            &dest->local,
            current->local.addr,
            current->local.addrlen
        );
        ngtcp2_addr_copy_byte(
            &dest->remote,
            (const ngtcp2_sockaddr *)&remote,
            (ngtcp2_socklen)sizeof(remote)
        );
        return 0;
    }

    /*
     * No preferred address matches the current local address family.
     * Leaving dest untouched tells ngtcp2 to ignore the offer.
     */
    return 0;
}

static void
net_quic_start_close_wait(
    net_quic_connection *ep,
    ngtcp2_tstamp now
)
{
    ngtcp2_duration pto;
    ngtcp2_duration wait;

    if (ep->retired || ep->close_wait) {
        return;
    }

    pto = ngtcp2_conn_get_pto2(ep->conn);
    if (pto > UINT64_MAX / 3) {
        wait = UINT64_MAX;
    } else {
        wait = pto * 3;
    }

    ep->close_wait = 1;
    ep->retirement_deadline =
        wait > UINT64_MAX - now ? UINT64_MAX : now + wait;
}

static char *
net_quic_strdup_len(pTHX_ const char *src, size_t len)
{
    char *dest;

    Newx(dest, len + 1, char);

    if (dest == NULL) {
        return NULL;
    }

    memcpy(dest, src, len);
    dest[len] = '\0';
    return dest;
}

#include "net_quic_stream.h"
#include "net_quic_tls.h"

static void
net_quic_connection_free(pTHX_ net_quic_connection *ep)
{
    if (ep == NULL) {
        return;
    }

    if (ep->conn != NULL) {
        ngtcp2_conn_del(ep->conn);
        ep->conn = NULL;
    }

    net_quic_tls_cleanup(aTHX_ ep);

    if (ep->server_tls_owner != NULL) {
        SvREFCNT_dec(ep->server_tls_owner);
        ep->server_tls_owner = NULL;
    }

    net_quic_application_datagrams_free(ep);
    net_quic_streams_free(aTHX_ ep);
    net_quic_cid_events_free(aTHX_ ep);

    Safefree(ep->alpn);
    Safefree(ep->server_name);

    if (ep->resume_ticket != NULL) {
        ptls_clear_memory(ep->resume_ticket, ep->resume_ticket_len);
        Safefree(ep->resume_ticket);
    }
    if (ep->session_ticket != NULL) {
        ptls_clear_memory(ep->session_ticket, ep->session_ticket_len);
        Safefree(ep->session_ticket);
    }
    if (ep->address_token != NULL) {
        ptls_clear_memory(ep->address_token, ep->address_token_len);
        Safefree(ep->address_token);
    }

    Safefree(ep);
}

static net_quic_connection *
net_quic_connection_from_sv(SV *self)
{
    net_quic_connection *ep;

    if (!SvROK(self) || !sv_derived_from(self, "Net::QUIC::Connection")) {
        croak("not a Net::QUIC::Connection object");
    }

    ep = INT2PTR(net_quic_connection *, SvIV(SvRV(self)));
    if (ep == NULL) {
        croak("Net::QUIC::Connection has already been destroyed");
    }

    return ep;
}

static SV *
net_quic_connection_bless(const char *class, net_quic_connection *ep)
{
    SV *inner = newSViv(PTR2IV(ep));
    SV *rv = newRV_noinc(inner);
    sv_bless(rv, gv_stashpv(class, GV_ADD));
    return rv;
}

static SV *
net_quic_datagram_new(
    const uint8_t *data,
    size_t datalen,
    const ngtcp2_addr *local,
    const ngtcp2_addr *peer,
    uint8_t ecn
)
{
    AV *av = newAV();
    SV *rv;

    av_push(av, newSVpvn((const char *)data, (STRLEN)datalen));
    av_push(av, newSVpvn((const char *)local->addr, (STRLEN)local->addrlen));
    av_push(av, newSVpvn((const char *)peer->addr, (STRLEN)peer->addrlen));
    av_push(av, newSVuv((UV)(ecn & NGTCP2_ECN_MASK)));

    rv = newRV_noinc((SV *)av);
    sv_bless(rv, gv_stashpv("Net::QUIC::Datagram", GV_ADD));
    return rv;
}

