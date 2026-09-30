#ifndef NET_QUIC_STREAM_H
#define NET_QUIC_STREAM_H

#define NET_QUIC_STREAM_TX_CHUNK_SIZE 16384

typedef struct net_quic_stream_tx_chunk net_quic_stream_tx_chunk;
typedef struct net_quic_stream_rx_chunk net_quic_stream_rx_chunk;

struct net_quic_stream_tx_chunk {
    uint8_t *data;
    size_t len;
    size_t sent;
    uint64_t offset;
    int fin;
    int fin_sent;
    net_quic_stream_tx_chunk *next;
};

struct net_quic_stream_rx_chunk {
    uint8_t *data;
    size_t len;
    int fin;
    net_quic_stream_rx_chunk *next;
};

struct net_quic_stream_state {
    int64_t id;
    int local_initiated;
    int bidirectional;
    int incoming_announced;
    int incoming_queued;
    size_t public_refs;
    int remote_finished;
    int local_finished;
    int write_shutdown;
    int closed;
    int remote_reset;
    uint64_t remote_reset_code;
    int local_reset;
    uint64_t local_reset_code;
    uint64_t rx_next_offset;
    uint64_t tx_next_offset;
    uint64_t tx_acked_through;
    int fin_acked;

    net_quic_stream_tx_chunk *tx_head;
    net_quic_stream_tx_chunk *tx_tail;
    net_quic_stream_rx_chunk *rx_head;
    net_quic_stream_rx_chunk *rx_tail;

    net_quic_stream_state *next;
    net_quic_stream_state *incoming_next;
};

static int
net_quic_stream_id_is_local(const net_quic_connection *ep, int64_t stream_id)
{
    int server_initiated = (stream_id & 0x01) != 0;
    return server_initiated == (ep->is_server ? 1 : 0);
}

static int
net_quic_stream_id_is_bidirectional(int64_t stream_id)
{
    return (stream_id & 0x02) == 0;
}

static int
net_quic_stream_can_send(const net_quic_stream_state *stream)
{
    return stream->bidirectional || stream->local_initiated;
}

static int
net_quic_stream_can_receive(const net_quic_stream_state *stream)
{
    return stream->bidirectional || !stream->local_initiated;
}

static net_quic_stream_state *
net_quic_stream_find(net_quic_connection *ep, int64_t stream_id)
{
    net_quic_stream_state *stream;

    for (stream = ep->streams; stream != NULL; stream = stream->next) {
        if (stream->id == stream_id) {
            return stream;
        }
    }

    return NULL;
}

static void
net_quic_stream_announce_incoming(
    net_quic_connection *ep,
    net_quic_stream_state *stream
)
{
    if (stream->local_initiated || stream->incoming_announced) {
        return;
    }

    stream->incoming_announced = 1;
    stream->incoming_queued = 1;
    stream->incoming_next = NULL;

    if (ep->incoming_stream_tail != NULL) {
        ep->incoming_stream_tail->incoming_next = stream;
    } else {
        ep->incoming_stream_head = stream;
    }

    ep->incoming_stream_tail = stream;
}

static net_quic_stream_state *
net_quic_stream_create(
    pTHX_ net_quic_connection *ep,
    int64_t stream_id,
    int local_initiated,
    int bidirectional,
    int announce_incoming
)
{
    net_quic_stream_state *stream;

    Newxz(stream, 1, net_quic_stream_state);
    if (stream == NULL) {
        return NULL;
    }

    stream->id = stream_id;
    stream->local_initiated = local_initiated ? 1 : 0;
    stream->bidirectional = bidirectional ? 1 : 0;

    if (ep->streams_tail != NULL) {
        ep->streams_tail->next = stream;
    } else {
        ep->streams = stream;
    }
    ep->streams_tail = stream;

    if (ep->tx_cursor == NULL) {
        ep->tx_cursor = stream;
    }

    if (announce_incoming) {
        net_quic_stream_announce_incoming(ep, stream);
    }

    return stream;
}

static net_quic_stream_state *
net_quic_stream_ensure_remote(
    pTHX_ ngtcp2_conn *conn,
    net_quic_connection *ep,
    int64_t stream_id
)
{
    net_quic_stream_state *stream;
    int rv;

    stream = net_quic_stream_find(ep, stream_id);
    if (stream != NULL) {
        return stream;
    }

    stream = net_quic_stream_create(
        aTHX_ ep,
        stream_id,
        0,
        net_quic_stream_id_is_bidirectional(stream_id),
        1
    );
    if (stream == NULL) {
        return NULL;
    }

    rv = ngtcp2_conn_set_stream_user_data(conn, stream_id, stream);
    if (rv != 0) {
        return NULL;
    }

    return stream;
}

static void
net_quic_stream_tx_chunk_free(pTHX_ net_quic_stream_tx_chunk *chunk)
{
    if (chunk == NULL) {
        return;
    }

    Safefree(chunk->data);
    Safefree(chunk);
}

static void
net_quic_stream_rx_chunk_free(pTHX_ net_quic_stream_rx_chunk *chunk)
{
    if (chunk == NULL) {
        return;
    }

    Safefree(chunk->data);
    Safefree(chunk);
}

static void
net_quic_stream_free_tx(pTHX_ net_quic_stream_state *stream)
{
    net_quic_stream_tx_chunk *chunk;
    net_quic_stream_tx_chunk *next;

    for (chunk = stream->tx_head; chunk != NULL; chunk = next) {
        next = chunk->next;
        net_quic_stream_tx_chunk_free(aTHX_ chunk);
    }

    stream->tx_head = NULL;
    stream->tx_tail = NULL;
}

static void
net_quic_stream_free_rx(pTHX_ net_quic_stream_state *stream)
{
    net_quic_stream_rx_chunk *chunk;
    net_quic_stream_rx_chunk *next;

    for (chunk = stream->rx_head; chunk != NULL; chunk = next) {
        next = chunk->next;
        net_quic_stream_rx_chunk_free(aTHX_ chunk);
    }

    stream->rx_head = NULL;
    stream->rx_tail = NULL;
}

static void
net_quic_stream_unlink_free(
    pTHX_ net_quic_connection *ep,
    net_quic_stream_state *stream
)
{
    net_quic_stream_state *prev = NULL;
    net_quic_stream_state *cur = ep->streams;
    net_quic_stream_state *next;

    while (cur != NULL && cur != stream) {
        prev = cur;
        cur = cur->next;
    }

    if (cur == NULL) {
        return;
    }

    next = cur->next;

    if (prev != NULL) {
        prev->next = next;
    } else {
        ep->streams = next;
    }

    if (ep->streams_tail == cur) {
        ep->streams_tail = prev;
    }

    if (ep->tx_cursor == cur) {
        ep->tx_cursor = next != NULL ? next : ep->streams;
    }

    if (ep->streams == NULL) {
        ep->streams_tail = NULL;
        ep->tx_cursor = NULL;
    }

    net_quic_stream_free_tx(aTHX_ cur);
    net_quic_stream_free_rx(aTHX_ cur);
    Safefree(cur);
}

static int
net_quic_stream_reclaimable(const net_quic_stream_state *stream)
{
    return stream->closed &&
           stream->public_refs == 0 &&
           !stream->incoming_queued;
}

static void
net_quic_stream_reclaim_closed(pTHX_ net_quic_connection *ep)
{
    net_quic_stream_state *stream;
    net_quic_stream_state *next;

    for (stream = ep->streams; stream != NULL; stream = next) {
        next = stream->next;

        if (net_quic_stream_reclaimable(stream)) {
            net_quic_stream_unlink_free(aTHX_ ep, stream);
        }
    }
}

static int
net_quic_stream_retain(net_quic_stream_state *stream)
{
    if (stream->public_refs == SIZE_MAX) {
        return -1;
    }

    ++stream->public_refs;
    return 0;
}

static int
net_quic_stream_release(
    pTHX_ net_quic_connection *ep,
    net_quic_stream_state *stream
)
{
    if (stream->public_refs == 0) {
        return -1;
    }

    --stream->public_refs;

    if (net_quic_stream_reclaimable(stream)) {
        net_quic_stream_unlink_free(aTHX_ ep, stream);
    }

    return 0;
}

static void
net_quic_streams_free(pTHX_ net_quic_connection *ep)
{
    net_quic_stream_state *stream;
    net_quic_stream_state *next;

    for (stream = ep->streams; stream != NULL; stream = next) {
        next = stream->next;
        net_quic_stream_free_tx(aTHX_ stream);
        net_quic_stream_free_rx(aTHX_ stream);
        Safefree(stream);
    }

    ep->streams = NULL;
    ep->streams_tail = NULL;
    ep->incoming_stream_head = NULL;
    ep->incoming_stream_tail = NULL;
    ep->tx_cursor = NULL;
}

static int
net_quic_stream_open_local(
    pTHX_ net_quic_connection *ep,
    int bidirectional,
    int64_t *pstream_id
)
{
    net_quic_stream_state *stream;
    int64_t stream_id = -1;
    int rv;

    stream = net_quic_stream_create(aTHX_ ep, -1, 1, bidirectional, 0);
    if (stream == NULL) {
        return NGTCP2_ERR_NOMEM;
    }

    if (bidirectional) {
        rv = ngtcp2_conn_open_bidi_stream(ep->conn, &stream_id, stream);
    } else {
        rv = ngtcp2_conn_open_uni_stream(ep->conn, &stream_id, stream);
    }

    if (rv != 0) {
        if (ep->streams == stream) {
            ep->streams = NULL;
            ep->streams_tail = NULL;
            ep->tx_cursor = NULL;
        } else {
            net_quic_stream_state *prev = ep->streams;
            while (prev != NULL && prev->next != stream) {
                prev = prev->next;
            }
            if (prev != NULL) {
                prev->next = NULL;
                ep->streams_tail = prev;
                if (ep->tx_cursor == stream) {
                    ep->tx_cursor = ep->streams;
                }
            }
        }
        Safefree(stream);
        return rv;
    }

    stream->id = stream_id;
    *pstream_id = stream_id;
    return 0;
}

static int
net_quic_stream_queue_data(
    pTHX_ net_quic_stream_state *stream,
    const uint8_t *data,
    size_t datalen
)
{
    net_quic_stream_tx_chunk *head = NULL;
    net_quic_stream_tx_chunk *tail = NULL;
    net_quic_stream_tx_chunk *chunk;
    net_quic_stream_tx_chunk *next;
    size_t consumed = 0;
    size_t chunklen;

    if (datalen == 0) {
        return 0;
    }
    if (!net_quic_stream_can_send(stream) || stream->local_finished ||
        stream->write_shutdown || stream->closed) {
        return NGTCP2_ERR_STREAM_SHUT_WR;
    }
    if (datalen > UINT64_MAX - stream->tx_next_offset) {
        return NGTCP2_ERR_INVALID_ARGUMENT;
    }

    while (consumed < datalen) {
        chunklen = datalen - consumed;
        if (chunklen > NET_QUIC_STREAM_TX_CHUNK_SIZE) {
            chunklen = NET_QUIC_STREAM_TX_CHUNK_SIZE;
        }

        Newxz(chunk, 1, net_quic_stream_tx_chunk);
        if (chunk == NULL) {
            goto nomem;
        }

        Newx(chunk->data, chunklen, uint8_t);
        if (chunk->data == NULL) {
            Safefree(chunk);
            goto nomem;
        }

        memcpy(chunk->data, data + consumed, chunklen);
        chunk->len = chunklen;
        chunk->offset = stream->tx_next_offset + (uint64_t)consumed;

        if (tail != NULL) {
            tail->next = chunk;
        } else {
            head = chunk;
        }
        tail = chunk;
        consumed += chunklen;
    }

    if (stream->tx_tail != NULL) {
        stream->tx_tail->next = head;
    } else {
        stream->tx_head = head;
    }
    stream->tx_tail = tail;
    stream->tx_next_offset += (uint64_t)datalen;

    return 0;

nomem:
    for (chunk = head; chunk != NULL; chunk = next) {
        next = chunk->next;
        net_quic_stream_tx_chunk_free(aTHX_ chunk);
    }

    return NGTCP2_ERR_NOMEM;
}

static int
net_quic_stream_queue_fin(pTHX_ net_quic_stream_state *stream)
{
    net_quic_stream_tx_chunk *chunk;

    if (!net_quic_stream_can_send(stream) || stream->local_finished ||
        stream->write_shutdown || stream->closed) {
        return NGTCP2_ERR_STREAM_SHUT_WR;
    }

    if (stream->tx_tail != NULL &&
        stream->tx_tail->sent < stream->tx_tail->len &&
        !stream->tx_tail->fin) {
        stream->tx_tail->fin = 1;
        stream->local_finished = 1;
        return 0;
    }

    Newxz(chunk, 1, net_quic_stream_tx_chunk);
    if (chunk == NULL) {
        return NGTCP2_ERR_NOMEM;
    }

    Newx(chunk->data, 1, uint8_t);
    if (chunk->data == NULL) {
        Safefree(chunk);
        return NGTCP2_ERR_NOMEM;
    }

    chunk->offset = stream->tx_next_offset;
    chunk->fin = 1;
    stream->local_finished = 1;

    if (stream->tx_tail != NULL) {
        stream->tx_tail->next = chunk;
    } else {
        stream->tx_head = chunk;
    }
    stream->tx_tail = chunk;

    return 0;
}

static net_quic_stream_tx_chunk *
net_quic_stream_pending_chunk(net_quic_stream_state *stream)
{
    net_quic_stream_tx_chunk *chunk;

    if (stream->write_shutdown || stream->closed) {
        return NULL;
    }

    for (chunk = stream->tx_head; chunk != NULL; chunk = chunk->next) {
        if (chunk->sent < chunk->len) {
            return chunk;
        }
        if (chunk->fin && !chunk->fin_sent) {
            return chunk;
        }
    }

    return NULL;
}

static size_t
net_quic_stream_tx_chunk_count(const net_quic_stream_state *stream)
{
    const net_quic_stream_tx_chunk *chunk;
    size_t count = 0;

    for (chunk = stream->tx_head; chunk != NULL; chunk = chunk->next) {
        ++count;
    }

    return count;
}

static uint64_t
net_quic_stream_tx_buffered_bytes(const net_quic_stream_state *stream)
{
    const net_quic_stream_tx_chunk *chunk;
    uint64_t total = 0;

    for (chunk = stream->tx_head; chunk != NULL; chunk = chunk->next) {
        total += (uint64_t)chunk->len;
    }

    return total;
}

static size_t
net_quic_stream_count(const net_quic_connection *ep)
{
    const net_quic_stream_state *stream;
    size_t count = 0;

    for (stream = ep->streams; stream != NULL; stream = stream->next) {
        ++count;
    }

    return count;
}

static net_quic_stream_state *
net_quic_stream_next_tx(net_quic_connection *ep)
{
    net_quic_stream_state *start;
    net_quic_stream_state *stream;
    net_quic_stream_state *next;

    start = ep->tx_cursor != NULL ? ep->tx_cursor : ep->streams;
    if (start == NULL) {
        return NULL;
    }

    stream = start;
    do {
        next = stream->next != NULL ? stream->next : ep->streams;
        ep->tx_cursor = next;

        if (net_quic_stream_pending_chunk(stream) != NULL) {
            return stream;
        }

        stream = next;
    } while (stream != NULL && stream != start);

    return NULL;
}

static net_quic_stream_state *
net_quic_stream_next_incoming(net_quic_connection *ep)
{
    net_quic_stream_state *stream = ep->incoming_stream_head;

    if (stream == NULL) {
        return NULL;
    }

    ep->incoming_stream_head = stream->incoming_next;
    if (ep->incoming_stream_head == NULL) {
        ep->incoming_stream_tail = NULL;
    }
    stream->incoming_next = NULL;
    stream->incoming_queued = 0;

    return stream;
}

static int
net_quic_stream_consume_rx(
    net_quic_connection *ep,
    net_quic_stream_state *stream,
    net_quic_stream_rx_chunk **pchunk
)
{
    net_quic_stream_rx_chunk *chunk;
    int rv;

    chunk = stream->rx_head;
    if (chunk == NULL) {
        *pchunk = NULL;
        return 0;
    }

    if (chunk->len != 0) {
        rv = ngtcp2_conn_extend_max_stream_offset(
            ep->conn,
            stream->id,
            (uint64_t)chunk->len
        );
        if (rv != 0 && rv != NGTCP2_ERR_STREAM_NOT_FOUND) {
            return rv;
        }

        ngtcp2_conn_extend_max_offset(ep->conn, (uint64_t)chunk->len);
    }

    stream->rx_head = chunk->next;
    if (stream->rx_head == NULL) {
        stream->rx_tail = NULL;
    }
    chunk->next = NULL;
    *pchunk = chunk;

    return 0;
}

static void
net_quic_stream_release_acked(pTHX_ net_quic_stream_state *stream)
{
    net_quic_stream_tx_chunk *chunk;
    uint64_t end;

    while ((chunk = stream->tx_head) != NULL) {
        if (chunk->fin && chunk->len == 0) {
            if (!stream->fin_acked) {
                break;
            }
        } else {
            if (chunk->len > UINT64_MAX - chunk->offset) {
                break;
            }
            end = chunk->offset + (uint64_t)chunk->len;
            if (end > stream->tx_acked_through) {
                break;
            }
        }

        stream->tx_head = chunk->next;
        if (stream->tx_head == NULL) {
            stream->tx_tail = NULL;
        }
        net_quic_stream_tx_chunk_free(aTHX_ chunk);
    }
}

static int
net_quic_stream_open_cb(
    ngtcp2_conn *conn,
    int64_t stream_id,
    void *user_data
)
{
    dTHX;
    net_quic_connection *ep = (net_quic_connection *)user_data;
    net_quic_stream_state *stream;

    stream = net_quic_stream_ensure_remote(aTHX_ conn, ep, stream_id);
    return stream != NULL ? 0 : NGTCP2_ERR_CALLBACK_FAILURE;
}

static int
net_quic_recv_stream_data_cb(
    ngtcp2_conn *conn,
    uint32_t flags,
    int64_t stream_id,
    uint64_t offset,
    const uint8_t *data,
    size_t datalen,
    void *user_data,
    void *stream_user_data
)
{
    dTHX;
    net_quic_connection *ep = (net_quic_connection *)user_data;
    net_quic_stream_state *stream =
        (net_quic_stream_state *)stream_user_data;
    net_quic_stream_rx_chunk *chunk;
    size_t alloclen;

    if (stream == NULL) {
        stream = net_quic_stream_ensure_remote(aTHX_ conn, ep, stream_id);
        if (stream == NULL) {
            return NGTCP2_ERR_CALLBACK_FAILURE;
        }
    }

    if (!net_quic_stream_can_receive(stream) ||
        offset != stream->rx_next_offset ||
        datalen > UINT64_MAX - stream->rx_next_offset) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    if (datalen == 0 && (flags & NGTCP2_STREAM_DATA_FLAG_FIN) == 0) {
        return 0;
    }

    Newxz(chunk, 1, net_quic_stream_rx_chunk);
    if (chunk == NULL) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    alloclen = datalen == 0 ? 1 : datalen;
    Newx(chunk->data, alloclen, uint8_t);
    if (chunk->data == NULL) {
        Safefree(chunk);
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    if (datalen != 0) {
        memcpy(chunk->data, data, datalen);
        chunk->len = datalen;
        stream->rx_next_offset += (uint64_t)datalen;
    }

    if ((flags & NGTCP2_STREAM_DATA_FLAG_FIN) != 0) {
        chunk->fin = 1;
        stream->remote_finished = 1;
    }

    if (stream->rx_tail != NULL) {
        stream->rx_tail->next = chunk;
    } else {
        stream->rx_head = chunk;
    }
    stream->rx_tail = chunk;

    return 0;
}

static int
net_quic_acked_stream_data_offset_cb(
    ngtcp2_conn *conn,
    int64_t stream_id,
    uint64_t offset,
    uint64_t datalen,
    void *user_data,
    void *stream_user_data
)
{
    dTHX;
    net_quic_connection *ep = (net_quic_connection *)user_data;
    net_quic_stream_state *stream =
        (net_quic_stream_state *)stream_user_data;
    uint64_t end;

    (void)conn;

    if (stream == NULL) {
        stream = net_quic_stream_find(ep, stream_id);
        if (stream == NULL) {
            return NGTCP2_ERR_CALLBACK_FAILURE;
        }
    }

    if (datalen == 0) {
        if (stream->local_finished && offset == stream->tx_next_offset) {
            stream->fin_acked = 1;
        }
    } else {
        if (datalen > UINT64_MAX - offset) {
            return NGTCP2_ERR_CALLBACK_FAILURE;
        }
        end = offset + datalen;
        if (end > stream->tx_acked_through) {
            stream->tx_acked_through = end;
        }
    }

    net_quic_stream_release_acked(aTHX_ stream);
    return 0;
}

static int
net_quic_stream_close_cb(
    ngtcp2_conn *conn,
    uint32_t flags,
    int64_t stream_id,
    uint64_t app_error_code,
    void *user_data,
    void *stream_user_data
)
{
    dTHX;
    net_quic_connection *ep = (net_quic_connection *)user_data;
    net_quic_stream_state *stream =
        (net_quic_stream_state *)stream_user_data;

    (void)conn;
    (void)flags;
    (void)app_error_code;

    if (stream == NULL) {
        stream = net_quic_stream_find(ep, stream_id);
    }
    if (stream != NULL) {
        stream->closed = 1;
        stream->write_shutdown = 1;
        net_quic_stream_free_tx(aTHX_ stream);
    }

    return 0;
}

static int
net_quic_stream_reset_cb(
    ngtcp2_conn *conn,
    int64_t stream_id,
    uint64_t final_size,
    uint64_t app_error_code,
    void *user_data,
    void *stream_user_data
)
{
    dTHX;
    net_quic_connection *ep = (net_quic_connection *)user_data;
    net_quic_stream_state *stream =
        (net_quic_stream_state *)stream_user_data;

    (void)final_size;

    if (stream == NULL) {
        stream = net_quic_stream_ensure_remote(aTHX_ conn, ep, stream_id);
        if (stream == NULL) {
            return NGTCP2_ERR_CALLBACK_FAILURE;
        }
    }

    stream->remote_reset = 1;
    stream->remote_reset_code = app_error_code;
    return 0;
}

#endif
