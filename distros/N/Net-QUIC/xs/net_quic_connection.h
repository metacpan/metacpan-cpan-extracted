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

static void
net_quic_system_free(void *ptr)
{
    free(ptr);
}

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

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

static const char *
net_quic_crypto_backend(void)
{
    return "picotls";
}

typedef struct net_quic_connection net_quic_connection;
typedef struct net_quic_stream_state net_quic_stream_state;
typedef struct net_quic_cid_event net_quic_cid_event;
typedef struct net_quic_server_tls net_quic_server_tls;

struct net_quic_cid_event {
    int add;
    ngtcp2_cid cid;
    net_quic_cid_event *next;
};

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
    int ready;
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

    size_t closebuflen;
    int closebuf_pending;
    ngtcp2_sockaddr_union close_local_addr;
    ngtcp2_socklen close_local_addrlen;
    ngtcp2_sockaddr_union close_peer_addr;
    ngtcp2_socklen close_peer_addrlen;

    net_quic_cid_event *cid_event_head;
    net_quic_cid_event *cid_event_tail;

    uint8_t txbuf[NET_QUIC_TX_BUFSIZE];
    int tx_batch_active;

    net_quic_stream_state *streams;
    net_quic_stream_state *streams_tail;
    net_quic_stream_state *incoming_stream_head;
    net_quic_stream_state *incoming_stream_tail;
    net_quic_stream_state *tx_cursor;

    ptls_context_t ptls_ctx;
    ngtcp2_crypto_picotls_ctx picotls_ctx;
    ptls_iovec_t picotls_alpn;
    ptls_openssl_verify_certificate_t picotls_verify_cert;
    int picotls_verify_cert_ready;
};

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
net_quic_handshake_completed_cb(ngtcp2_conn *conn, void *user_data)
{
    net_quic_connection *ep = (net_quic_connection *)user_data;
    (void)conn;

    ep->ready = 1;
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

    net_quic_streams_free(aTHX_ ep);
    net_quic_cid_events_free(aTHX_ ep);

    Safefree(ep->alpn);
    Safefree(ep->server_name);
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
    const ngtcp2_addr *peer
)
{
    AV *av = newAV();
    SV *rv;

    av_push(av, newSVpvn((const char *)data, (STRLEN)datalen));
    av_push(av, newSVpvn((const char *)local->addr, (STRLEN)local->addrlen));
    av_push(av, newSVpvn((const char *)peer->addr, (STRLEN)peer->addrlen));

    rv = newRV_noinc((SV *)av);
    sv_bless(rv, gv_stashpv("Net::QUIC::Datagram", GV_ADD));
    return rv;
}

