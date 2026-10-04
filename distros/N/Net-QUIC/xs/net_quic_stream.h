#ifndef NET_QUIC_STREAM_H
#define NET_QUIC_STREAM_H

#define NET_QUIC_STREAM_TX_CHUNK_SIZE 16384

#define NET_QUIC_STREAM_RX_MODE_NONE 0
#define NET_QUIC_STREAM_RX_MODE_AUTO 1
#define NET_QUIC_STREAM_RX_MODE_EXPLICIT 2

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
    int early_data;
    int incoming_announced;
    int incoming_queued;
    int activity_queued;
    size_t public_refs;
    int remote_finished;
    int local_finished;
    int write_shutdown;
    int read_shutdown;
    int closed;
    int remote_reset;
    uint64_t remote_reset_code;
    int local_reset;
    uint64_t local_reset_code;
    int remote_stop_sending;
    uint64_t remote_stop_sending_code;
    int local_stop_sending;
    uint64_t local_stop_sending_code;
    int tx_discard_pending;
    int rx_mode;
    uint64_t rx_unconsumed;
    uint64_t rx_next_offset;
    uint64_t tx_next_offset;
    uint64_t tx_acked_through;
    uint64_t tx_buffered_bytes;
    int fin_acked;

    net_quic_stream_tx_chunk *tx_head;
    net_quic_stream_tx_chunk *tx_tail;
    net_quic_stream_rx_chunk *rx_head;
    net_quic_stream_rx_chunk *rx_tail;

    net_quic_stream_state *next;
    net_quic_stream_state *index_next;
    net_quic_stream_state *incoming_next;
    net_quic_stream_state *activity_next;
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

static size_t
net_quic_stream_index_bucket(int64_t stream_id, size_t bucket_count)
{
    uint64_t value = (uint64_t)stream_id;

    value ^= value >> 33;
    value *= UINT64_C(0xff51afd7ed558ccd);
    value ^= value >> 33;
    value *= UINT64_C(0xc4ceb9fe1a85ec53);
    value ^= value >> 33;

    return (size_t)(value & (uint64_t)(bucket_count - 1));
}

static int
net_quic_stream_index_rehash(
    pTHX_ net_quic_connection *ep,
    size_t bucket_count
)
{
    net_quic_stream_state **buckets;
    net_quic_stream_state *stream;
    size_t bucket;

    Newxz(buckets, bucket_count, net_quic_stream_state *);
    if (buckets == NULL) {
        return -1;
    }

    for (stream = ep->streams; stream != NULL; stream = stream->next) {
        stream->index_next = NULL;

        if (stream->id < 0) {
            continue;
        }

        bucket = net_quic_stream_index_bucket(stream->id, bucket_count);
        stream->index_next = buckets[bucket];
        buckets[bucket] = stream;
    }

    Safefree(ep->stream_index);
    ep->stream_index = buckets;
    ep->stream_index_bucket_count = bucket_count;

    return 0;
}

static int
net_quic_stream_index_reserve(
    pTHX_ net_quic_connection *ep,
    size_t needed
)
{
    size_t bucket_count = ep->stream_index_bucket_count;

    if (bucket_count == 0) {
        bucket_count = 64;
    }

    while (needed > bucket_count - bucket_count / 4) {
        if (bucket_count > SIZE_MAX / 2) {
            return -1;
        }
        bucket_count *= 2;
    }

    if (bucket_count == ep->stream_index_bucket_count) {
        return 0;
    }

    return net_quic_stream_index_rehash(aTHX_ ep, bucket_count);
}

static void
net_quic_stream_index_insert(
    net_quic_connection *ep,
    net_quic_stream_state *stream
)
{
    size_t bucket;

    if (stream->id < 0) {
        return;
    }

    bucket = net_quic_stream_index_bucket(
        stream->id,
        ep->stream_index_bucket_count
    );

    stream->index_next = ep->stream_index[bucket];
    ep->stream_index[bucket] = stream;
    ++ep->stream_index_size;
}

static void
net_quic_stream_index_remove(
    net_quic_connection *ep,
    net_quic_stream_state *stream
)
{
    net_quic_stream_state *prev = NULL;
    net_quic_stream_state *cur;
    size_t bucket;

    if (stream->id < 0 || ep->stream_index_bucket_count == 0) {
        return;
    }

    bucket = net_quic_stream_index_bucket(
        stream->id,
        ep->stream_index_bucket_count
    );

    for (cur = ep->stream_index[bucket];
         cur != NULL && cur != stream;
         cur = cur->index_next) {
        prev = cur;
    }

    if (cur == NULL) {
        return;
    }

    if (prev != NULL) {
        prev->index_next = cur->index_next;
    } else {
        ep->stream_index[bucket] = cur->index_next;
    }

    cur->index_next = NULL;
    --ep->stream_index_size;
}

static net_quic_stream_state *
net_quic_stream_find(net_quic_connection *ep, int64_t stream_id)
{
    net_quic_stream_state *stream;
    size_t bucket;

    if (stream_id < 0 || ep->stream_index_bucket_count == 0) {
        return NULL;
    }

    bucket = net_quic_stream_index_bucket(
        stream_id,
        ep->stream_index_bucket_count
    );

    for (stream = ep->stream_index[bucket];
         stream != NULL;
         stream = stream->index_next) {
        if (stream->id == stream_id) {
            return stream;
        }
    }

    return NULL;
}

static void
net_quic_stream_mark_activity(
    net_quic_connection *ep,
    net_quic_stream_state *stream
)
{
    if (!ep->stream_activity_enabled || stream->activity_queued) {
        return;
    }

    stream->activity_queued = 1;
    stream->activity_next = NULL;

    if (ep->stream_activity_tail != NULL) {
        ep->stream_activity_tail->activity_next = stream;
    } else {
        ep->stream_activity_head = stream;
    }

    ep->stream_activity_tail = stream;
}

static void
net_quic_stream_remove_activity(
    net_quic_connection *ep,
    net_quic_stream_state *stream
)
{
    net_quic_stream_state *prev = NULL;
    net_quic_stream_state *cur;

    if (!stream->activity_queued) {
        return;
    }

    for (cur = ep->stream_activity_head;
         cur != NULL && cur != stream;
         cur = cur->activity_next) {
        prev = cur;
    }

    if (cur != NULL) {
        if (prev != NULL) {
            prev->activity_next = cur->activity_next;
        } else {
            ep->stream_activity_head = cur->activity_next;
        }

        if (ep->stream_activity_tail == cur) {
            ep->stream_activity_tail = prev;
        }
    }

    stream->activity_queued = 0;
    stream->activity_next = NULL;
}

static void
net_quic_stream_clear_activity(net_quic_connection *ep)
{
    net_quic_stream_state *stream;
    net_quic_stream_state *next;

    for (stream = ep->stream_activity_head; stream != NULL; stream = next) {
        next = stream->activity_next;
        stream->activity_queued = 0;
        stream->activity_next = NULL;
    }

    ep->stream_activity_head = NULL;
    ep->stream_activity_tail = NULL;
}

static int
net_quic_stream_has_latched_activity(
    const net_quic_stream_state *stream
)
{
    return stream->incoming_queued ||
           stream->rx_head != NULL ||
           stream->remote_finished ||
           stream->remote_reset ||
           stream->remote_stop_sending ||
           stream->closed ||
           stream->tx_acked_through != 0 ||
           stream->fin_acked;
}

static void
net_quic_stream_set_activity_enabled(
    net_quic_connection *ep,
    int enabled
)
{
    net_quic_stream_state *stream;

    if (!enabled) {
        ep->stream_activity_enabled = 0;
        net_quic_stream_clear_activity(ep);
        return;
    }

    if (ep->stream_activity_enabled) {
        return;
    }

    ep->stream_activity_enabled = 1;

    for (stream = ep->streams; stream != NULL; stream = stream->next) {
        if (net_quic_stream_has_latched_activity(stream)) {
            net_quic_stream_mark_activity(ep, stream);
        }
    }
}

static net_quic_stream_state *
net_quic_stream_next_activity(net_quic_connection *ep)
{
    net_quic_stream_state *stream = ep->stream_activity_head;

    if (stream == NULL) {
        return NULL;
    }

    ep->stream_activity_head = stream->activity_next;
    if (ep->stream_activity_head == NULL) {
        ep->stream_activity_tail = NULL;
    }

    stream->activity_queued = 0;
    stream->activity_next = NULL;
    return stream;
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
    net_quic_stream_mark_activity(ep, stream);
}

static void
net_quic_stream_unlink_free(
    pTHX_ net_quic_connection *ep,
    net_quic_stream_state *stream
);

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

    if (net_quic_stream_index_reserve(
            aTHX_ ep,
            ep->stream_index_size + 1
        ) != 0) {
        return NULL;
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

    net_quic_stream_index_insert(ep, stream);

    rv = ngtcp2_conn_set_stream_user_data(conn, stream_id, stream);
    if (rv != 0) {
        net_quic_stream_unlink_free(aTHX_ ep, stream);
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
net_quic_stream_free_tx(
    pTHX_ net_quic_connection *ep,
    net_quic_stream_state *stream
)
{
    net_quic_stream_tx_chunk *chunk;
    net_quic_stream_tx_chunk *next;
    uint64_t released = stream->tx_buffered_bytes;

    for (chunk = stream->tx_head; chunk != NULL; chunk = next) {
        next = chunk->next;
        net_quic_stream_tx_chunk_free(aTHX_ chunk);
    }

    stream->tx_head = NULL;
    stream->tx_tail = NULL;
    stream->tx_buffered_bytes = 0;
    ep->stream_tx_buffered_bytes -= released;
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

static uint64_t
net_quic_stream_discard_rx(
    pTHX_ net_quic_connection *ep,
    net_quic_stream_state *stream
)
{
    net_quic_stream_rx_chunk *chunk;
    net_quic_stream_rx_chunk *next;
    uint64_t discarded = 0;

    for (chunk = stream->rx_head; chunk != NULL; chunk = next) {
        next = chunk->next;
        discarded += (uint64_t)chunk->len;
        net_quic_stream_rx_chunk_free(aTHX_ chunk);
    }

    stream->rx_head = NULL;
    stream->rx_tail = NULL;

    if (stream->rx_unconsumed != 0) {
        discarded += stream->rx_unconsumed;
        stream->rx_unconsumed = 0;
    }

    if (discarded != 0) {
        ngtcp2_conn_extend_max_offset(ep->conn, discarded);
    }

    return discarded;
}

static void
net_quic_stream_apply_deferred_discards(
    pTHX_ net_quic_connection *ep
)
{
    net_quic_stream_state *stream;

    for (stream = ep->streams; stream != NULL; stream = stream->next) {
        if (!stream->tx_discard_pending) {
            continue;
        }

        stream->tx_discard_pending = 0;
        net_quic_stream_free_tx(aTHX_ ep, stream);
    }
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

    net_quic_stream_remove_activity(ep, cur);
    net_quic_stream_index_remove(ep, cur);
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

    net_quic_stream_free_tx(aTHX_ ep, cur);
    net_quic_stream_free_rx(aTHX_ cur);
    Safefree(cur);
}

static int
net_quic_stream_reclaimable(const net_quic_stream_state *stream)
{
    return stream->closed &&
           stream->public_refs == 0 &&
           !stream->incoming_queued &&
           !stream->activity_queued;
}

static void
net_quic_stream_reclaim_closed(pTHX_ net_quic_connection *ep)
{
    net_quic_stream_state *stream;
    net_quic_stream_state *next;

    for (stream = ep->streams; stream != NULL; stream = next) {
        next = stream->next;

        if (net_quic_stream_reclaimable(stream)) {
            net_quic_stream_discard_rx(aTHX_ ep, stream);
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
    uint64_t discarded = 0;

    if (stream->public_refs == 0) {
        return -1;
    }

    --stream->public_refs;

    if (net_quic_stream_reclaimable(stream)) {
        discarded = net_quic_stream_discard_rx(aTHX_ ep, stream);
        net_quic_stream_unlink_free(aTHX_ ep, stream);
    }

    return discarded != 0 ? 1 : 0;
}

static void
net_quic_streams_free(pTHX_ net_quic_connection *ep)
{
    net_quic_stream_state *stream;
    net_quic_stream_state *next;

    for (stream = ep->streams; stream != NULL; stream = next) {
        next = stream->next;
        net_quic_stream_free_tx(aTHX_ ep, stream);
        net_quic_stream_free_rx(aTHX_ stream);
        Safefree(stream);
    }

    ep->streams = NULL;
    ep->streams_tail = NULL;
    Safefree(ep->stream_index);
    ep->stream_index = NULL;
    ep->stream_index_bucket_count = 0;
    ep->stream_index_size = 0;
    ep->incoming_stream_head = NULL;
    ep->incoming_stream_tail = NULL;
    ep->stream_activity_head = NULL;
    ep->stream_activity_tail = NULL;
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

    if (net_quic_stream_index_reserve(
            aTHX_ ep,
            ep->stream_index_size + 1
        ) != 0) {
        return NGTCP2_ERR_NOMEM;
    }

    stream = net_quic_stream_create(aTHX_ ep, -1, 1, bidirectional, 0);
    if (stream == NULL) {
        return NGTCP2_ERR_NOMEM;
    }

    stream->early_data = !ep->ready
        && ep->early_data_attempted
        && !ep->early_data_rejected;

    if (bidirectional) {
        rv = ngtcp2_conn_open_bidi_stream(ep->conn, &stream_id, stream);
    } else {
        rv = ngtcp2_conn_open_uni_stream(ep->conn, &stream_id, stream);
    }

    if (rv != 0) {
        net_quic_stream_unlink_free(aTHX_ ep, stream);
        return rv;
    }

    stream->id = stream_id;
    net_quic_stream_index_insert(ep, stream);
    *pstream_id = stream_id;
    return 0;
}

static int
net_quic_stream_queue_data(
    pTHX_ net_quic_connection *ep,
    net_quic_stream_state *stream,
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
    if (datalen > UINT64_MAX - stream->tx_next_offset ||
        datalen > UINT64_MAX - ep->stream_tx_buffered_bytes) {
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
    stream->tx_buffered_bytes += (uint64_t)datalen;
    ep->stream_tx_buffered_bytes += (uint64_t)datalen;

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
    return stream->tx_buffered_bytes;
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
net_quic_stream_select_rx_mode(
    net_quic_stream_state *stream,
    int mode
)
{
    if (stream->rx_mode == NET_QUIC_STREAM_RX_MODE_NONE) {
        stream->rx_mode = mode;
        return 0;
    }

    return stream->rx_mode == mode ? 0 : -1;
}

static int
net_quic_stream_extend_rx_credit(
    net_quic_connection *ep,
    net_quic_stream_state *stream,
    uint64_t amount
)
{
    int rv;

    if (amount == 0) {
        return 0;
    }

    rv = ngtcp2_conn_extend_max_stream_offset(
        ep->conn,
        stream->id,
        amount
    );
    if (rv != 0 && rv != NGTCP2_ERR_STREAM_NOT_FOUND) {
        return rv;
    }

    ngtcp2_conn_extend_max_offset(ep->conn, amount);
    return 0;
}

static net_quic_stream_rx_chunk *
net_quic_stream_take_rx(net_quic_stream_state *stream)
{
    net_quic_stream_rx_chunk *chunk = stream->rx_head;

    if (chunk == NULL) {
        return NULL;
    }

    stream->rx_head = chunk->next;
    if (stream->rx_head == NULL) {
        stream->rx_tail = NULL;
    }

    chunk->next = NULL;
    return chunk;
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

    rv = net_quic_stream_extend_rx_credit(
        ep,
        stream,
        (uint64_t)chunk->len
    );
    if (rv != 0) {
        return rv;
    }

    *pchunk = net_quic_stream_take_rx(stream);
    return 0;
}

static int
net_quic_stream_take_rx_explicit(
    net_quic_stream_state *stream,
    net_quic_stream_rx_chunk **pchunk
)
{
    net_quic_stream_rx_chunk *chunk = stream->rx_head;

    if (chunk == NULL) {
        *pchunk = NULL;
        return 0;
    }

    if ((uint64_t)chunk->len > UINT64_MAX - stream->rx_unconsumed) {
        return NGTCP2_ERR_INVALID_ARGUMENT;
    }

    chunk = net_quic_stream_take_rx(stream);
    stream->rx_unconsumed += (uint64_t)chunk->len;
    *pchunk = chunk;

    return 0;
}

static int
net_quic_stream_consume_explicit_rx(
    net_quic_connection *ep,
    net_quic_stream_state *stream,
    uint64_t amount
)
{
    int rv;

    rv = net_quic_stream_extend_rx_credit(ep, stream, amount);
    if (rv != 0) {
        return rv;
    }

    stream->rx_unconsumed -= amount;
    return 0;
}

static void
net_quic_stream_release_acked(
    pTHX_ net_quic_connection *ep,
    net_quic_stream_state *stream
)
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

        stream->tx_buffered_bytes -= (uint64_t)chunk->len;
        ep->stream_tx_buffered_bytes -= (uint64_t)chunk->len;
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
        stream->read_shutdown ||
        offset != stream->rx_next_offset ||
        datalen > UINT64_MAX - stream->rx_next_offset) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    if ((flags & NGTCP2_STREAM_DATA_FLAG_0RTT) != 0) {
        stream->early_data = 1;
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
    net_quic_stream_mark_activity(ep, stream);

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
    int changed = 0;

    (void)conn;

    if (stream == NULL) {
        stream = net_quic_stream_find(ep, stream_id);
        if (stream == NULL) {
            return NGTCP2_ERR_CALLBACK_FAILURE;
        }
    }

    if (datalen == 0) {
        if (stream->local_finished &&
            offset == stream->tx_next_offset &&
            !stream->fin_acked) {
            stream->fin_acked = 1;
            changed = 1;
        }
    } else {
        if (datalen > UINT64_MAX - offset) {
            return NGTCP2_ERR_CALLBACK_FAILURE;
        }
        end = offset + datalen;
        if (end > stream->tx_acked_through) {
            stream->tx_acked_through = end;
            changed = 1;
        }
    }

    net_quic_stream_release_acked(aTHX_ ep, stream);
    if (changed) {
        net_quic_stream_mark_activity(ep, stream);
    }
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
        stream->read_shutdown = 1;
        net_quic_stream_free_tx(aTHX_ ep, stream);
        net_quic_stream_mark_activity(ep, stream);
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
    stream->read_shutdown = 1;
    net_quic_stream_mark_activity(ep, stream);
    return 0;
}

static int
net_quic_recv_stop_sending_cb(
    ngtcp2_conn *conn,
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

    if (stream == NULL) {
        stream = net_quic_stream_find(ep, stream_id);
    }
    if (stream == NULL && !net_quic_stream_id_is_local(ep, stream_id)) {
        stream = net_quic_stream_ensure_remote(aTHX_ conn, ep, stream_id);
    }
    if (stream == NULL) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    stream->remote_stop_sending = 1;
    stream->remote_stop_sending_code = app_error_code;
    stream->write_shutdown = 1;
    stream->tx_discard_pending = 1;
    net_quic_stream_mark_activity(ep, stream);

    return 0;
}


static int
net_quic_tls_early_data_rejected_cb(
    ngtcp2_conn *conn,
    void *user_data
)
{
    dTHX;
    net_quic_connection *ep = (net_quic_connection *)user_data;
    net_quic_stream_state *stream;
    net_quic_stream_state *next;

    (void)conn;

    ep->early_data_accepted = 0;
    ep->early_data_rejected = 1;
    ep->local_bidi_stream_waiting = 0;
    ep->local_uni_stream_waiting = 0;
    ep->stream_available_events = 0;

    if (ep->datagram_tx_pending != NULL &&
        ep->datagram_tx_pending->early_data) {
        net_quic_application_datagram_free(ep->datagram_tx_pending);
        ep->datagram_tx_pending = NULL;
    }

    for (stream = ep->streams; stream != NULL; stream = next) {
        next = stream->next;

        if (stream->early_data) {
            net_quic_stream_unlink_free(aTHX_ ep, stream);
        }
    }

    return 0;
}

#endif
