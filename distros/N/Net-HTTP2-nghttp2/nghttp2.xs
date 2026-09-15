#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <nghttp2/nghttp2.h>
#include <string.h>

/*
 * Net::HTTP2::nghttp2 - Perl XS bindings for nghttp2
 *
 * This module provides server-side HTTP/2 support via nghttp2.
 */

/* Per-stream data provider state for streaming responses */
typedef struct {
    SV *callback;           /* Perl callback to produce data */
    SV *user_data;          /* User data for callback */
    int32_t stream_id;      /* Stream ID */
    int eof;                /* End of data flag */
    int no_end_stream;      /* Suppress END_STREAM at EOF */
    int deferred;           /* Currently deferred */
    int released;           /* Stream closed; awaiting free, do not touch Perl data */
} nghttp2_perl_data_provider;

/* Session wrapper structure */
typedef struct {
    nghttp2_session *session;
    SV *user_data;
    SV *cb_on_begin_headers;
    SV *cb_on_header;
    SV *cb_on_frame_recv;
    SV *cb_on_data_chunk_recv;
    SV *cb_on_stream_close;
    SV *cb_on_frame_send;
    SV *cb_on_frame_not_send;
    SV *cb_on_invalid_frame_recv;
    SV *cb_on_error;
    SV *cb_send;
    SV *cb_data_source_read;
    /* Output buffer for mem_send */
    char *send_buf;
    size_t send_buf_len;
    size_t send_buf_cap;
    /* Data providers for active streams (simple linear array) */
    nghttp2_perl_data_provider **data_providers;
    int data_providers_count;
    int data_providers_cap;
    /* Nonzero while nghttp2 is running callbacks for this session */
    int in_session_call;
    /* Providers unlinked during a session call, freed when it returns */
    nghttp2_perl_data_provider **pending_free;
    int pending_free_count;
    int pending_free_cap;
} nghttp2_perl_session;

/* Every method reaches nghttp2 through ps->session. DESTROY clears that pointer
   before it releases anything that can run Perl, so a Perl destructor that calls
   back into the session being torn down is refused here rather than handed a
   deleted nghttp2_session. */
#define SESSION_ALIVE_OR_CROAK(ps) STMT_START {                               \
        if (!(ps) || !(ps)->session) {                                        \
            croak("Net::HTTP2::nghttp2::Session: session has been destroyed"); \
        }                                                                     \
    } STMT_END

/* Forward declarations */
static ssize_t perl_send_callback(nghttp2_session *session,
                                  const uint8_t *data, size_t length,
                                  int flags, void *user_data);
static int perl_on_begin_headers_callback(nghttp2_session *session,
                                          const nghttp2_frame *frame,
                                          void *user_data);
static int perl_on_header_callback(nghttp2_session *session,
                                   const nghttp2_frame *frame,
                                   const uint8_t *name, size_t namelen,
                                   const uint8_t *value, size_t valuelen,
                                   uint8_t flags, void *user_data);
static int perl_on_frame_recv_callback(nghttp2_session *session,
                                       const nghttp2_frame *frame,
                                       void *user_data);
static int perl_on_data_chunk_recv_callback(nghttp2_session *session,
                                            uint8_t flags, int32_t stream_id,
                                            const uint8_t *data, size_t len,
                                            void *user_data);
static int perl_on_stream_close_callback(nghttp2_session *session,
                                         int32_t stream_id,
                                         uint32_t error_code,
                                         void *user_data);
static int perl_on_frame_send_callback(nghttp2_session *session,
                                       const nghttp2_frame *frame,
                                       void *user_data);
static int perl_on_frame_not_send_callback(nghttp2_session *session,
                                           const nghttp2_frame *frame,
                                           int lib_error_code,
                                           void *user_data);
static int perl_on_invalid_frame_recv_callback(nghttp2_session *session,
                                               const nghttp2_frame *frame,
                                               int lib_error_code,
                                               void *user_data);
static int perl_error_callback(nghttp2_session *session, int lib_error_code,
                               const char *msg, size_t len, void *user_data);

/* Session callback plumbing shared by the server and client constructors */
static void extract_perl_callbacks(pTHX_ nghttp2_perl_session *ps,
                                   HV *callbacks_hv) {
    SV **svp;

    if (!callbacks_hv) {
        return;
    }

    if ((svp = hv_fetch(callbacks_hv, "on_begin_headers", 16, 0))) {
        ps->cb_on_begin_headers = newSVsv(*svp);
    }
    if ((svp = hv_fetch(callbacks_hv, "on_header", 9, 0))) {
        ps->cb_on_header = newSVsv(*svp);
    }
    if ((svp = hv_fetch(callbacks_hv, "on_frame_recv", 13, 0))) {
        ps->cb_on_frame_recv = newSVsv(*svp);
    }
    if ((svp = hv_fetch(callbacks_hv, "on_data_chunk_recv", 18, 0))) {
        ps->cb_on_data_chunk_recv = newSVsv(*svp);
    }
    if ((svp = hv_fetch(callbacks_hv, "on_stream_close", 15, 0))) {
        ps->cb_on_stream_close = newSVsv(*svp);
    }
    if ((svp = hv_fetch(callbacks_hv, "on_frame_send", 13, 0))) {
        ps->cb_on_frame_send = newSVsv(*svp);
    }
    if ((svp = hv_fetch(callbacks_hv, "on_frame_not_send", 17, 0))) {
        ps->cb_on_frame_not_send = newSVsv(*svp);
    }
    if ((svp = hv_fetch(callbacks_hv, "on_invalid_frame_recv", 21, 0))) {
        ps->cb_on_invalid_frame_recv = newSVsv(*svp);
    }
    if ((svp = hv_fetch(callbacks_hv, "on_error", 8, 0))) {
        ps->cb_on_error = newSVsv(*svp);
    }
}

static void release_perl_callbacks(pTHX_ nghttp2_perl_session *ps) {
    if (ps->user_data) SvREFCNT_dec(ps->user_data);
    if (ps->cb_on_begin_headers) SvREFCNT_dec(ps->cb_on_begin_headers);
    if (ps->cb_on_header) SvREFCNT_dec(ps->cb_on_header);
    if (ps->cb_on_frame_recv) SvREFCNT_dec(ps->cb_on_frame_recv);
    if (ps->cb_on_data_chunk_recv) SvREFCNT_dec(ps->cb_on_data_chunk_recv);
    if (ps->cb_on_stream_close) SvREFCNT_dec(ps->cb_on_stream_close);
    if (ps->cb_on_frame_send) SvREFCNT_dec(ps->cb_on_frame_send);
    if (ps->cb_on_frame_not_send) SvREFCNT_dec(ps->cb_on_frame_not_send);
    if (ps->cb_on_invalid_frame_recv) SvREFCNT_dec(ps->cb_on_invalid_frame_recv);
    if (ps->cb_on_error) SvREFCNT_dec(ps->cb_on_error);
}

static void register_nghttp2_callbacks(nghttp2_session_callbacks *callbacks) {
    nghttp2_session_callbacks_set_send_callback(callbacks, perl_send_callback);
    nghttp2_session_callbacks_set_on_begin_headers_callback(callbacks, perl_on_begin_headers_callback);
    nghttp2_session_callbacks_set_on_header_callback(callbacks, perl_on_header_callback);
    nghttp2_session_callbacks_set_on_frame_recv_callback(callbacks, perl_on_frame_recv_callback);
    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(callbacks, perl_on_data_chunk_recv_callback);
    nghttp2_session_callbacks_set_on_stream_close_callback(callbacks, perl_on_stream_close_callback);
    nghttp2_session_callbacks_set_on_frame_send_callback(callbacks, perl_on_frame_send_callback);
    nghttp2_session_callbacks_set_on_frame_not_send_callback(callbacks, perl_on_frame_not_send_callback);
    nghttp2_session_callbacks_set_on_invalid_frame_recv_callback(callbacks, perl_on_invalid_frame_recv_callback);
    nghttp2_session_callbacks_set_error_callback2(callbacks, perl_error_callback);
}

/* Data provider helper functions */
static nghttp2_perl_data_provider *find_data_provider(nghttp2_perl_session *ps, int32_t stream_id) {
    int i;
    for (i = 0; i < ps->data_providers_count; i++) {
        if (ps->data_providers[i] && ps->data_providers[i]->stream_id == stream_id) {
            return ps->data_providers[i];
        }
    }
    return NULL;
}

/* One provider per stream id. A second one would leave nghttp2 holding two data
   sources for the same stream while stream close reclaims only the first, and
   the loser would sit in the array keyed to a stream that can never free it.
   Submit paths check this before handing the descriptor to nghttp2; the check
   inside add_data_provider stands as the invariant, and reaching it there would
   mean stranding a provider nghttp2 has already taken. */
static void assert_stream_has_no_provider(pTHX_ nghttp2_perl_session *ps,
                                          int32_t stream_id) {
    if (find_data_provider(ps, stream_id)) {
        croak("Net::HTTP2::nghttp2::Session: stream %d already has a data provider",
              (int)stream_id);
    }
}

static void add_data_provider(pTHX_ nghttp2_perl_session *ps, nghttp2_perl_data_provider *dp) {
    int i;
    assert_stream_has_no_provider(aTHX_ ps, dp->stream_id);
    /* Find empty slot */
    for (i = 0; i < ps->data_providers_count; i++) {
        if (!ps->data_providers[i]) {
            ps->data_providers[i] = dp;
            return;
        }
    }
    /* Grow array if needed */
    if (ps->data_providers_count >= ps->data_providers_cap) {
        int new_cap = ps->data_providers_cap ? ps->data_providers_cap * 2 : 8;
        ps->data_providers = (nghttp2_perl_data_provider **)realloc(
            ps->data_providers, new_cap * sizeof(nghttp2_perl_data_provider *));
        memset(ps->data_providers + ps->data_providers_cap, 0,
               (new_cap - ps->data_providers_cap) * sizeof(nghttp2_perl_data_provider *));
        ps->data_providers_cap = new_cap;
    }
    ps->data_providers[ps->data_providers_count++] = dp;
}

static void free_data_provider(pTHX_ nghttp2_perl_data_provider *dp) {
    if (dp->callback) SvREFCNT_dec(dp->callback);
    if (dp->user_data) SvREFCNT_dec(dp->user_data);
    Safefree(dp);
}

/* Hold a released provider until the running session call returns. nghttp2
   still owns the outbound item whose data source points at it, and the header
   promises nothing about that pointer's lifetime past on_stream_close. */
static void defer_free_data_provider(pTHX_ nghttp2_perl_session *ps,
                                     nghttp2_perl_data_provider *dp) {
    if (ps->pending_free_count >= ps->pending_free_cap) {
        int new_cap = ps->pending_free_cap ? ps->pending_free_cap * 2 : 4;
        nghttp2_perl_data_provider **grown =
            (nghttp2_perl_data_provider **)realloc(
                ps->pending_free, new_cap * sizeof(nghttp2_perl_data_provider *));
        if (!grown) {
            /* Nowhere to park it; freeing now beats losing the list. */
            free_data_provider(aTHX_ dp);
            return;
        }
        ps->pending_free = grown;
        ps->pending_free_cap = new_cap;
    }
    ps->pending_free[ps->pending_free_count++] = dp;
}

/* Freeing a provider drops the last reference to its Perl callback_data, so a
   DESTROY runs here and may re-enter the session and drain again. Take the list
   off the session first: the nested drain then sees an empty list instead of
   freeing these entries a second time, and an append from the nested call
   cannot realloc the array this loop is walking. */
static void drain_pending_free(pTHX_ nghttp2_perl_session *ps) {
    nghttp2_perl_data_provider **list = ps->pending_free;
    int count = ps->pending_free_count;
    int i;

    ps->pending_free = NULL;
    ps->pending_free_count = 0;
    ps->pending_free_cap = 0;

    for (i = 0; i < count; i++) {
        free_data_provider(aTHX_ list[i]);
    }
    if (list) free(list);
}

static void remove_data_provider(nghttp2_perl_session *ps, int32_t stream_id) {
    dTHX;
    int i;
    for (i = 0; i < ps->data_providers_count; i++) {
        if (ps->data_providers[i] && ps->data_providers[i]->stream_id == stream_id) {
            nghttp2_perl_data_provider *dp = ps->data_providers[i];
            ps->data_providers[i] = NULL;
            dp->released = 1;
            if (ps->in_session_call) {
                defer_free_data_provider(aTHX_ ps, dp);
            } else {
                free_data_provider(aTHX_ dp);
            }
            return;
        }
    }
}

static nghttp2_nv *perl_headers_to_nva(pTHX_ AV *headers_av,
                                       size_t *nvlen_out) {
    I32 last_index = av_len(headers_av);
    size_t nvlen = last_index < 0 ? 0 : (size_t)last_index + 1;
    nghttp2_nv *nva = NULL;
    I32 i;

    *nvlen_out = nvlen;
    if (nvlen == 0) {
        return NULL;
    }

    Newxz(nva, nvlen, nghttp2_nv);

    for (i = 0; i < (I32)nvlen; i++) {
        SV **pair = av_fetch(headers_av, i, 0);
        if (pair && SvROK(*pair) && SvTYPE(SvRV(*pair)) == SVt_PVAV) {
            AV *pair_av = (AV *)SvRV(*pair);
            SV **name_sv = av_fetch(pair_av, 0, 0);
            SV **value_sv = av_fetch(pair_av, 1, 0);

            if (name_sv && value_sv) {
                STRLEN name_len;
                STRLEN value_len;
                nva[i].name = (uint8_t *)SvPVbyte(*name_sv, name_len);
                nva[i].namelen = name_len;
                nva[i].value = (uint8_t *)SvPVbyte(*value_sv, value_len);
                nva[i].valuelen = value_len;
                nva[i].flags = NGHTTP2_NV_FLAG_NONE;
            }
        }
    }

    return nva;
}

/* Data provider read callback - called by nghttp2 when it wants response body data */
static ssize_t perl_data_source_read_callback(
    nghttp2_session *session,
    int32_t stream_id,
    uint8_t *buf,
    size_t length,
    uint32_t *data_flags,
    nghttp2_data_source *source,
    void *user_data)
{
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    nghttp2_perl_data_provider *dp = (nghttp2_perl_data_provider *)source->ptr;
    dSP;
    int count;
    ssize_t ret = 0;

    if (!dp) {
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        return 0;
    }

    /* The stream closed while nghttp2 still held this data source. The Perl
       callback and body are spoken for, so end the body without touching them. */
    if (dp->released) {
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        return 0;
    }

    /* Special case: if callback is NULL but user_data contains body, use it directly */
    if (!dp->callback && dp->user_data && SvOK(dp->user_data)) {
        STRLEN full_len;
        const char *body_ptr = SvPVbyte(dp->user_data, full_len);
        STRLEN send_len = (full_len > length) ? length : full_len;

        if (send_len > 0) {
            memcpy(buf, body_ptr, send_len);
        }

        if (send_len >= full_len) {
            /* All data consumed */
            SvREFCNT_dec(dp->user_data);
            dp->user_data = NULL;
            if (dp->eof) {
                *data_flags |= NGHTTP2_DATA_FLAG_EOF;
                if (dp->no_end_stream) {
                    *data_flags |= NGHTTP2_DATA_FLAG_NO_END_STREAM;
                }
            } else {
                dp->no_end_stream = 0;
            }
        } else {
            /* Partial send - keep remainder for next call */
            SV *remaining = newSVpvn(body_ptr + send_len, full_len - send_len);
            SvREFCNT_dec(dp->user_data);
            dp->user_data = remaining;
        }

        return (ssize_t)send_len;
    }

    /* No callback and no pending data */
    if (!dp->callback || !SvOK(dp->callback)) {
        if (dp->eof) {
            *data_flags |= NGHTTP2_DATA_FLAG_EOF;
            if (dp->no_end_stream) {
                *data_flags |= NGHTTP2_DATA_FLAG_NO_END_STREAM;
            }
            return 0;
        }
        /* No EOF requested - defer until more data arrives via submit_data */
        dp->deferred = 1;
        return NGHTTP2_ERR_DEFERRED;
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* Call: $callback->($stream_id, $max_length[, $user_data]) */
    /* Returns: ($data, $eof[, $no_end_stream]) or undef/empty list to defer */
    XPUSHs(sv_2mortal(newSViv(stream_id)));
    XPUSHs(sv_2mortal(newSVuv(length)));
    if (dp->user_data && SvOK(dp->user_data)) {
        XPUSHs(dp->user_data);
    }

    PUTBACK;
    count = call_sv(dp->callback, G_ARRAY | G_EVAL);
    SPAGAIN;

    if (dp->released) {
        /* The callback closed its own stream. The provider is awaiting free,
           so discard the body rather than record state on it. */
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        ret = 0;
    } else if (SvTRUE(ERRSV)) {
        /* Callback threw an exception */
        warn("nghttp2 data provider callback error: %s", SvPV_nolen(ERRSV));
        ret = NGHTTP2_ERR_CALLBACK_FAILURE;
    } else if (count == 0) {
        /* No return value = defer */
        dp->deferred = 1;
        ret = NGHTTP2_ERR_DEFERRED;
    } else {
        SV **return_values = SP - count + 1;
        SV *data_sv = return_values[0];
        SV *eof_sv = count >= 2 ? return_values[1] : NULL;
        SV *no_end_stream_sv = count >= 3 ? return_values[2] : NULL;

        if (!SvOK(data_sv)) {
            /* undef = defer */
            dp->deferred = 1;
            ret = NGHTTP2_ERR_DEFERRED;
        } else {
            STRLEN data_len;
            const char *data_ptr = SvPVbyte(data_sv, data_len);

            /* Copy data to buffer */
            if (data_len > length) {
                data_len = length;  /* Truncate if too much */
            }
            if (data_len > 0) {
                memcpy(buf, data_ptr, data_len);
            }
            ret = (ssize_t)data_len;

            /* Check EOF flag */
            if (eof_sv && SvTRUE(eof_sv)) {
                *data_flags |= NGHTTP2_DATA_FLAG_EOF;
                dp->eof = 1;
                if (no_end_stream_sv && SvTRUE(no_end_stream_sv)) {
                    *data_flags |= NGHTTP2_DATA_FLAG_NO_END_STREAM;
                }
            }

            /* If returned empty string with no eof, also defer */
            if (data_len == 0 && !dp->eof) {
                dp->deferred = 1;
                ret = NGHTTP2_ERR_DEFERRED;
            }
        }
    }

    if (count > 0) {
        SP -= count;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

/* Helper to call Perl callbacks */
static int call_perl_callback(pTHX_ SV *callback, AV *args) {
    dSP;
    int count;
    int ret = 0;

    if (!callback || !SvOK(callback)) {
        return 0;
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    if (args) {
        int i;
        int len = av_len(args) + 1;
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(args, i, 0);
            if (elem) {
                XPUSHs(*elem);
            }
        }
    }

    PUTBACK;
    count = call_sv(callback, G_SCALAR | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        /* Callback threw an exception */
        warn("nghttp2 callback error: %s", SvPV_nolen(ERRSV));
        ret = NGHTTP2_ERR_CALLBACK_FAILURE;
    } else if (count > 0) {
        SV *result = POPs;
        if (SvIOK(result)) {
            ret = SvIV(result);
        }
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

/* Send callback - buffers data for mem_send */
static ssize_t perl_send_callback(nghttp2_session *session,
                                  const uint8_t *data, size_t length,
                                  int flags, void *user_data) {
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;

    /* Grow buffer if needed */
    if (ps->send_buf_len + length > ps->send_buf_cap) {
        size_t new_cap = ps->send_buf_cap * 2;
        if (new_cap < ps->send_buf_len + length) {
            new_cap = ps->send_buf_len + length + 16384;
        }
        ps->send_buf = (char *)realloc(ps->send_buf, new_cap);
        if (!ps->send_buf) {
            return NGHTTP2_ERR_NOMEM;
        }
        ps->send_buf_cap = new_cap;
    }

    memcpy(ps->send_buf + ps->send_buf_len, data, length);
    ps->send_buf_len += length;

    return (ssize_t)length;
}

/* Begin headers callback */
static int perl_on_begin_headers_callback(nghttp2_session *session,
                                          const nghttp2_frame *frame,
                                          void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    int ret;

    if (!ps->cb_on_begin_headers || !SvOK(ps->cb_on_begin_headers)) {
        return 0;
    }

    args = newAV();
    av_push(args, newSViv(frame->hd.stream_id));
    av_push(args, newSViv(frame->hd.type));
    av_push(args, newSViv(frame->hd.flags));

    ret = call_perl_callback(aTHX_ ps->cb_on_begin_headers, args);

    SvREFCNT_dec((SV *)args);
    return ret;
}

/* Header callback */
static int perl_on_header_callback(nghttp2_session *session,
                                   const nghttp2_frame *frame,
                                   const uint8_t *name, size_t namelen,
                                   const uint8_t *value, size_t valuelen,
                                   uint8_t flags, void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    int ret;

    if (!ps->cb_on_header || !SvOK(ps->cb_on_header)) {
        return 0;
    }

    args = newAV();
    av_push(args, newSViv(frame->hd.stream_id));
    av_push(args, newSVpvn((const char *)name, namelen));
    av_push(args, newSVpvn((const char *)value, valuelen));
    av_push(args, newSViv(flags));

    ret = call_perl_callback(aTHX_ ps->cb_on_header, args);

    SvREFCNT_dec((SV *)args);
    return ret;
}

/* Build the frame info hash the frame callbacks deliver to Perl */
static HV *perl_frame_to_hv(pTHX_ const nghttp2_frame *frame) {
    HV *frame_hv = newHV();

    hv_store(frame_hv, "stream_id", 9, newSViv(frame->hd.stream_id), 0);
    hv_store(frame_hv, "type", 4, newSViv(frame->hd.type), 0);
    hv_store(frame_hv, "flags", 5, newSViv(frame->hd.flags), 0);
    hv_store(frame_hv, "length", 6, newSViv(frame->hd.length), 0);
    if (frame->hd.type == NGHTTP2_HEADERS) {
        hv_store(frame_hv, "headers_category", 16,
                 newSViv(frame->headers.cat), 0);
    }

    return frame_hv;
}

/* Frame receive callback */
static int perl_on_frame_recv_callback(nghttp2_session *session,
                                       const nghttp2_frame *frame,
                                       void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    int ret;

    if (!ps->cb_on_frame_recv || !SvOK(ps->cb_on_frame_recv)) {
        return 0;
    }

    args = newAV();
    av_push(args, newRV_noinc((SV *)perl_frame_to_hv(aTHX_ frame)));

    ret = call_perl_callback(aTHX_ ps->cb_on_frame_recv, args);

    SvREFCNT_dec((SV *)args);
    return ret;
}

/* Frame send callback - the frame has been serialized into the send buffer */
static int perl_on_frame_send_callback(nghttp2_session *session,
                                       const nghttp2_frame *frame,
                                       void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    int ret;

    if (!ps->cb_on_frame_send || !SvOK(ps->cb_on_frame_send)) {
        return 0;
    }

    args = newAV();
    av_push(args, newRV_noinc((SV *)perl_frame_to_hv(aTHX_ frame)));

    ret = call_perl_callback(aTHX_ ps->cb_on_frame_send, args);

    SvREFCNT_dec((SV *)args);
    return ret;
}

/* Frame not-send callback - the queued frame was discarded before the wire */
static int perl_on_frame_not_send_callback(nghttp2_session *session,
                                           const nghttp2_frame *frame,
                                           int lib_error_code,
                                           void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    int ret;

    /* A response or trailer HEADERS discarded for a stream nghttp2 no longer
       has is the end of that stream's story: on_stream_close already ran, so
       nothing else will release the provider the submit registered, and
       nothing will ever read it. A HEADERS refused while the stream is still
       there is a different thing -- the stream is live and its provider is
       still feeding the response half -- so the release keys on the stream
       being gone, not on the frame being discarded.

       nghttp2.h, on the existence test used here:

         Returns 1 if remote peer half closed the given stream |stream_id|.
         Returns 0 if it did not.  Returns -1 if no such stream exists.

       nghttp2_session_get_stream_user_data cannot answer this question: it
       returns NULL both for a missing stream and for a live stream that has no
       user data, which on a server is every stream the peer opened.

       remove_data_provider defers the free while a session call is in
       progress, which it always is here. */
    if (frame->hd.type == NGHTTP2_HEADERS &&
        nghttp2_session_get_stream_remote_close(session, frame->hd.stream_id) < 0) {
        remove_data_provider(ps, frame->hd.stream_id);
    }

    if (!ps->cb_on_frame_not_send || !SvOK(ps->cb_on_frame_not_send)) {
        return 0;
    }

    args = newAV();
    av_push(args, newRV_noinc((SV *)perl_frame_to_hv(aTHX_ frame)));
    av_push(args, newSViv(lib_error_code));

    ret = call_perl_callback(aTHX_ ps->cb_on_frame_not_send, args);

    SvREFCNT_dec((SV *)args);
    return ret;
}

/* Invalid frame receive callback - nghttp2 rejected a peer frame */
static int perl_on_invalid_frame_recv_callback(nghttp2_session *session,
                                               const nghttp2_frame *frame,
                                               int lib_error_code,
                                               void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    int ret;

    if (!ps->cb_on_invalid_frame_recv || !SvOK(ps->cb_on_invalid_frame_recv)) {
        return 0;
    }

    args = newAV();
    av_push(args, newRV_noinc((SV *)perl_frame_to_hv(aTHX_ frame)));
    av_push(args, newSViv(lib_error_code));

    ret = call_perl_callback(aTHX_ ps->cb_on_invalid_frame_recv, args);

    SvREFCNT_dec((SV *)args);
    return ret;
}

/* Error callback - nghttp2's human-readable diagnostics */
static int perl_error_callback(nghttp2_session *session, int lib_error_code,
                               const char *msg, size_t len, void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    int ret;

    if (!ps->cb_on_error || !SvOK(ps->cb_on_error)) {
        return 0;
    }

    args = newAV();
    av_push(args, newSViv(lib_error_code));
    av_push(args, newSVpvn(msg ? msg : "", msg ? len : 0));

    ret = call_perl_callback(aTHX_ ps->cb_on_error, args);

    SvREFCNT_dec((SV *)args);
    return ret;
}

/* Data chunk receive callback */
static int perl_on_data_chunk_recv_callback(nghttp2_session *session,
                                            uint8_t flags, int32_t stream_id,
                                            const uint8_t *data, size_t len,
                                            void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    int ret;

    if (!ps->cb_on_data_chunk_recv || !SvOK(ps->cb_on_data_chunk_recv)) {
        return 0;
    }

    args = newAV();
    av_push(args, newSViv(stream_id));
    av_push(args, newSVpvn((const char *)data, len));
    av_push(args, newSViv(flags));

    ret = call_perl_callback(aTHX_ ps->cb_on_data_chunk_recv, args);

    SvREFCNT_dec((SV *)args);
    return ret;
}

/* Stream close callback */
static int perl_on_stream_close_callback(nghttp2_session *session,
                                         int32_t stream_id,
                                         uint32_t error_code,
                                         void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    int ret = 0;

    /* Clean up any data provider for this stream */
    remove_data_provider(ps, stream_id);

    if (!ps->cb_on_stream_close || !SvOK(ps->cb_on_stream_close)) {
        return 0;
    }

    args = newAV();
    av_push(args, newSViv(stream_id));
    av_push(args, newSVuv(error_code));

    ret = call_perl_callback(aTHX_ ps->cb_on_stream_close, args);

    SvREFCNT_dec((SV *)args);
    return ret;
}

MODULE = Net::HTTP2::nghttp2    PACKAGE = Net::HTTP2::nghttp2

PROTOTYPES: DISABLE

# Check if nghttp2 is available
int
_check_nghttp2_available()
    CODE:
        nghttp2_info *info = nghttp2_version(0);
        RETVAL = info ? 1 : 0;
    OUTPUT:
        RETVAL

# Get nghttp2 version string
const char *
version_string()
    CODE:
        nghttp2_info *info = nghttp2_version(0);
        RETVAL = info ? info->version_str : "unknown";
    OUTPUT:
        RETVAL

# Get nghttp2 version number
int
version_num()
    CODE:
        nghttp2_info *info = nghttp2_version(0);
        RETVAL = info ? info->version_num : 0;
    OUTPUT:
        RETVAL

# Constants
int
NGHTTP2_ERR_WOULDBLOCK()
    CODE:
        RETVAL = NGHTTP2_ERR_WOULDBLOCK;
    OUTPUT:
        RETVAL

int
NGHTTP2_ERR_CALLBACK_FAILURE()
    CODE:
        RETVAL = NGHTTP2_ERR_CALLBACK_FAILURE;
    OUTPUT:
        RETVAL

int
NGHTTP2_ERR_DEFERRED()
    CODE:
        RETVAL = NGHTTP2_ERR_DEFERRED;
    OUTPUT:
        RETVAL

int
NGHTTP2_ERR_STREAM_CLOSING()
    CODE:
        RETVAL = NGHTTP2_ERR_STREAM_CLOSING;
    OUTPUT:
        RETVAL

int
NGHTTP2_ERR_PROTO()
    CODE:
        RETVAL = NGHTTP2_ERR_PROTO;
    OUTPUT:
        RETVAL

int
NGHTTP2_ERR_HTTP_HEADER()
    CODE:
        RETVAL = NGHTTP2_ERR_HTTP_HEADER;
    OUTPUT:
        RETVAL

int
NGHTTP2_ERR_TEMPORAL_CALLBACK_FAILURE()
    CODE:
        RETVAL = NGHTTP2_ERR_TEMPORAL_CALLBACK_FAILURE;
    OUTPUT:
        RETVAL

int
NGHTTP2_FLAG_NONE()
    CODE:
        RETVAL = NGHTTP2_FLAG_NONE;
    OUTPUT:
        RETVAL

int
NGHTTP2_FLAG_END_STREAM()
    CODE:
        RETVAL = NGHTTP2_FLAG_END_STREAM;
    OUTPUT:
        RETVAL

int
NGHTTP2_FLAG_END_HEADERS()
    CODE:
        RETVAL = NGHTTP2_FLAG_END_HEADERS;
    OUTPUT:
        RETVAL

int
NGHTTP2_FLAG_ACK()
    CODE:
        RETVAL = NGHTTP2_FLAG_ACK;
    OUTPUT:
        RETVAL

int
NGHTTP2_FLAG_PADDED()
    CODE:
        RETVAL = NGHTTP2_FLAG_PADDED;
    OUTPUT:
        RETVAL

int
NGHTTP2_FLAG_PRIORITY()
    CODE:
        RETVAL = NGHTTP2_FLAG_PRIORITY;
    OUTPUT:
        RETVAL

int
NGHTTP2_NO_ERROR()
    CODE:
        RETVAL = NGHTTP2_NO_ERROR;
    OUTPUT:
        RETVAL

int
NGHTTP2_PROTOCOL_ERROR()
    CODE:
        RETVAL = NGHTTP2_PROTOCOL_ERROR;
    OUTPUT:
        RETVAL

int
NGHTTP2_INTERNAL_ERROR()
    CODE:
        RETVAL = NGHTTP2_INTERNAL_ERROR;
    OUTPUT:
        RETVAL

int
NGHTTP2_FLOW_CONTROL_ERROR()
    CODE:
        RETVAL = NGHTTP2_FLOW_CONTROL_ERROR;
    OUTPUT:
        RETVAL

int
NGHTTP2_SETTINGS_TIMEOUT()
    CODE:
        RETVAL = NGHTTP2_SETTINGS_TIMEOUT;
    OUTPUT:
        RETVAL

int
NGHTTP2_STREAM_CLOSED()
    CODE:
        RETVAL = NGHTTP2_STREAM_CLOSED;
    OUTPUT:
        RETVAL

int
NGHTTP2_FRAME_SIZE_ERROR()
    CODE:
        RETVAL = NGHTTP2_FRAME_SIZE_ERROR;
    OUTPUT:
        RETVAL

int
NGHTTP2_REFUSED_STREAM()
    CODE:
        RETVAL = NGHTTP2_REFUSED_STREAM;
    OUTPUT:
        RETVAL

int
NGHTTP2_CANCEL()
    CODE:
        RETVAL = NGHTTP2_CANCEL;
    OUTPUT:
        RETVAL

int
NGHTTP2_COMPRESSION_ERROR()
    CODE:
        RETVAL = NGHTTP2_COMPRESSION_ERROR;
    OUTPUT:
        RETVAL

int
NGHTTP2_CONNECT_ERROR()
    CODE:
        RETVAL = NGHTTP2_CONNECT_ERROR;
    OUTPUT:
        RETVAL

int
NGHTTP2_ENHANCE_YOUR_CALM()
    CODE:
        RETVAL = NGHTTP2_ENHANCE_YOUR_CALM;
    OUTPUT:
        RETVAL

int
NGHTTP2_INADEQUATE_SECURITY()
    CODE:
        RETVAL = NGHTTP2_INADEQUATE_SECURITY;
    OUTPUT:
        RETVAL

int
NGHTTP2_HTTP_1_1_REQUIRED()
    CODE:
        RETVAL = NGHTTP2_HTTP_1_1_REQUIRED;
    OUTPUT:
        RETVAL

int
NGHTTP2_HCAT_REQUEST()
    CODE:
        RETVAL = NGHTTP2_HCAT_REQUEST;
    OUTPUT:
        RETVAL

int
NGHTTP2_HCAT_RESPONSE()
    CODE:
        RETVAL = NGHTTP2_HCAT_RESPONSE;
    OUTPUT:
        RETVAL

int
NGHTTP2_HCAT_PUSH_RESPONSE()
    CODE:
        RETVAL = NGHTTP2_HCAT_PUSH_RESPONSE;
    OUTPUT:
        RETVAL

int
NGHTTP2_HCAT_HEADERS()
    CODE:
        RETVAL = NGHTTP2_HCAT_HEADERS;
    OUTPUT:
        RETVAL

int
NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS()
    CODE:
        RETVAL = NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS;
    OUTPUT:
        RETVAL

int
NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE()
    CODE:
        RETVAL = NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE;
    OUTPUT:
        RETVAL

int
NGHTTP2_SETTINGS_MAX_FRAME_SIZE()
    CODE:
        RETVAL = NGHTTP2_SETTINGS_MAX_FRAME_SIZE;
    OUTPUT:
        RETVAL

int
NGHTTP2_SETTINGS_ENABLE_PUSH()
    CODE:
        RETVAL = NGHTTP2_SETTINGS_ENABLE_PUSH;
    OUTPUT:
        RETVAL

int
NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL()
    CODE:
        RETVAL = NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL;
    OUTPUT:
        RETVAL

int
NGHTTP2_DATA_FLAG_NONE()
    CODE:
        RETVAL = NGHTTP2_DATA_FLAG_NONE;
    OUTPUT:
        RETVAL

int
NGHTTP2_DATA_FLAG_EOF()
    CODE:
        RETVAL = NGHTTP2_DATA_FLAG_EOF;
    OUTPUT:
        RETVAL

int
NGHTTP2_DATA_FLAG_NO_END_STREAM()
    CODE:
        RETVAL = NGHTTP2_DATA_FLAG_NO_END_STREAM;
    OUTPUT:
        RETVAL

int
NGHTTP2_DATA_FLAG_NO_COPY()
    CODE:
        RETVAL = NGHTTP2_DATA_FLAG_NO_COPY;
    OUTPUT:
        RETVAL

# Frame types
int
NGHTTP2_DATA()
    CODE:
        RETVAL = NGHTTP2_DATA;
    OUTPUT:
        RETVAL

int
NGHTTP2_HEADERS()
    CODE:
        RETVAL = NGHTTP2_HEADERS;
    OUTPUT:
        RETVAL

int
NGHTTP2_SETTINGS()
    CODE:
        RETVAL = NGHTTP2_SETTINGS;
    OUTPUT:
        RETVAL

int
NGHTTP2_PUSH_PROMISE()
    CODE:
        RETVAL = NGHTTP2_PUSH_PROMISE;
    OUTPUT:
        RETVAL

int
NGHTTP2_GOAWAY()
    CODE:
        RETVAL = NGHTTP2_GOAWAY;
    OUTPUT:
        RETVAL


MODULE = Net::HTTP2::nghttp2    PACKAGE = Net::HTTP2::nghttp2::Session

# Create new server session
SV *
_new_server_xs(class, callbacks_hv, user_data, ...)
        char *class
        HV *callbacks_hv
        SV *user_data
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_session_callbacks *callbacks;
        nghttp2_option *option = NULL;
        int rv;
        SV **svp;
        HV *options_hv = NULL;
    CODE:
        /* Check for optional options hash (4th argument) */
        if (items > 3 && SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVHV) {
            options_hv = (HV *)SvRV(ST(3));
        }

        /* Allocate our wrapper structure */
        Newxz(ps, 1, nghttp2_perl_session);

        /* Initialize send buffer */
        ps->send_buf_cap = 16384;
        ps->send_buf = (char *)malloc(ps->send_buf_cap);
        ps->send_buf_len = 0;

        /* Store user data */
        if (SvOK(user_data)) {
            ps->user_data = newSVsv(user_data);
        }

        /* Extract callbacks from hash */
        extract_perl_callbacks(aTHX_ ps, callbacks_hv);

        /* Create nghttp2 callbacks */
        rv = nghttp2_session_callbacks_new(&callbacks);
        if (rv != 0) {
            release_perl_callbacks(aTHX_ ps);
            free(ps->send_buf);
            Safefree(ps);
            croak("nghttp2_session_callbacks_new failed: %s", nghttp2_strerror(rv));
        }
        register_nghttp2_callbacks(callbacks);

        /* Create session — use new2 with options if provided */
        if (options_hv) {
            rv = nghttp2_option_new(&option);
            if (rv != 0) {
                nghttp2_session_callbacks_del(callbacks);
                release_perl_callbacks(aTHX_ ps);
                free(ps->send_buf);
                Safefree(ps);
                croak("nghttp2_option_new failed: %s", nghttp2_strerror(rv));
            }

            if ((svp = hv_fetch(options_hv, "max_send_header_block_length", 28, 0))) {
                nghttp2_option_set_max_send_header_block_length(option, SvUV(*svp));
            }

            if ((svp = hv_fetch(options_hv, "stream_reset_burst", 18, 0))) {
                SV **rate_svp = hv_fetch(options_hv, "stream_reset_rate", 17, 0);
                if (rate_svp) {
                    nghttp2_option_set_stream_reset_rate_limit(
                        option, (uint64_t)SvUV(*svp), (uint64_t)SvUV(*rate_svp));
                }
            }

            rv = nghttp2_session_server_new2(&ps->session, callbacks, ps, option);
            nghttp2_option_del(option);
        } else {
            rv = nghttp2_session_server_new(&ps->session, callbacks, ps);
        }
        nghttp2_session_callbacks_del(callbacks);

        if (rv != 0) {
            release_perl_callbacks(aTHX_ ps);
            free(ps->send_buf);
            Safefree(ps);
            croak("nghttp2_session_server_new failed: %s", nghttp2_strerror(rv));
        }

        /* Bless and return */
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, class, (void *)ps);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

# Destructor
void
DESTROY(self)
        SV *self
    PREINIT:
        nghttp2_perl_session *ps;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        if (ps) {
            int i;
            if (ps->session) {
                nghttp2_session_del(ps->session);
                /* Releasing the callbacks and the providers below runs Perl
                   destructors, which may call back in. From here on every
                   method croaks instead of following this pointer. */
                ps->session = NULL;
            }
            release_perl_callbacks(aTHX_ ps);
            if (ps->send_buf) free(ps->send_buf);
            /* Clean up data providers, released ones included */
            drain_pending_free(aTHX_ ps);
            if (ps->pending_free) free(ps->pending_free);
            for (i = 0; i < ps->data_providers_count; i++) {
                if (ps->data_providers[i]) {
                    free_data_provider(aTHX_ ps->data_providers[i]);
                }
            }
            if (ps->data_providers) free(ps->data_providers);
            Safefree(ps);
        }

# Feed incoming data to session
int
mem_recv(self, data)
        SV *self
        SV *data
    PREINIT:
        nghttp2_perl_session *ps;
        STRLEN len;
        const char *buf;
        ssize_t rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        if (ps->in_session_call) {
            croak("mem_recv called from inside a session callback");
        }
        buf = SvPVbyte(data, len);

        /* A callback error is reported with warn(), outside the eval that traps
           the callback, so a $SIG{__WARN__} that throws unwinds past the clear.
           The save stack restores the flag on every exit, C or Perl. */
        ENTER;
        SAVEINT(ps->in_session_call);
        ps->in_session_call = 1;
        rv = nghttp2_session_mem_recv(ps->session, (const uint8_t *)buf, len);
        LEAVE;
        drain_pending_free(aTHX_ ps);

        if (rv < 0) {
            croak("nghttp2_session_mem_recv failed: %s", nghttp2_strerror((int)rv));
        }
        RETVAL = (int)rv;
    OUTPUT:
        RETVAL

# Get data to send
SV *
mem_send(self)
        SV *self
    PREINIT:
        nghttp2_perl_session *ps;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        if (ps->in_session_call) {
            croak("mem_send called from inside a session callback");
        }

        /* Clear send buffer */
        ps->send_buf_len = 0;

        /* Trigger send callback to fill buffer */
        /* See mem_recv: the flag must survive a Perl-level unwind out of the
           session call. */
        ENTER;
        SAVEINT(ps->in_session_call);
        ps->in_session_call = 1;
        rv = nghttp2_session_send(ps->session);
        LEAVE;
        drain_pending_free(aTHX_ ps);

        if (rv != 0) {
            croak("nghttp2_session_send failed: %s", nghttp2_strerror(rv));
        }

        /* Return buffered data */
        if (ps->send_buf_len > 0) {
            RETVAL = newSVpvn(ps->send_buf, ps->send_buf_len);
        } else {
            RETVAL = newSVpvn("", 0);
        }
    OUTPUT:
        RETVAL

# Check if session wants to read
int
want_read(self)
        SV *self
    PREINIT:
        nghttp2_perl_session *ps;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        RETVAL = nghttp2_session_want_read(ps->session);
    OUTPUT:
        RETVAL

# Check if session wants to write
int
want_write(self)
        SV *self
    PREINIT:
        nghttp2_perl_session *ps;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        RETVAL = nghttp2_session_want_write(ps->session);
    OUTPUT:
        RETVAL

# Submit SETTINGS frame
int
submit_settings(self, settings_hv)
        SV *self
        HV *settings_hv
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_settings_entry iv[16];
        int niv = 0;
        SV **svp;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);

        if ((svp = hv_fetch(settings_hv, "max_concurrent_streams", 22, 0))) {
            iv[niv].settings_id = NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS;
            iv[niv].value = SvUV(*svp);
            niv++;
        }
        if ((svp = hv_fetch(settings_hv, "initial_window_size", 19, 0))) {
            iv[niv].settings_id = NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE;
            iv[niv].value = SvUV(*svp);
            niv++;
        }
        if ((svp = hv_fetch(settings_hv, "max_frame_size", 14, 0))) {
            iv[niv].settings_id = NGHTTP2_SETTINGS_MAX_FRAME_SIZE;
            iv[niv].value = SvUV(*svp);
            niv++;
        }
        if ((svp = hv_fetch(settings_hv, "enable_push", 11, 0))) {
            iv[niv].settings_id = NGHTTP2_SETTINGS_ENABLE_PUSH;
            iv[niv].value = SvTRUE(*svp) ? 1 : 0;
            niv++;
        }
        if ((svp = hv_fetch(settings_hv, "enable_connect_protocol", 23, 0))) {
            iv[niv].settings_id = NGHTTP2_SETTINGS_ENABLE_CONNECT_PROTOCOL;
            iv[niv].value = SvTRUE(*svp) ? 1 : 0;
            niv++;
        }
        if ((svp = hv_fetch(settings_hv, "header_table_size", 17, 0))) {
            iv[niv].settings_id = NGHTTP2_SETTINGS_HEADER_TABLE_SIZE;
            iv[niv].value = SvUV(*svp);
            niv++;
        }
        if ((svp = hv_fetch(settings_hv, "max_header_list_size", 20, 0))) {
            iv[niv].settings_id = NGHTTP2_SETTINGS_MAX_HEADER_LIST_SIZE;
            iv[niv].value = SvUV(*svp);
            niv++;
        }

        rv = nghttp2_submit_settings(ps->session, NGHTTP2_FLAG_NONE, iv, niv);
        if (rv != 0) {
            croak("nghttp2_submit_settings failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Submit response without body
int
_submit_response_no_body(self, stream_id, headers_av)
        SV *self
        int stream_id
        AV *headers_av
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);

        nva = perl_headers_to_nva(aTHX_ headers_av, &nvlen);

        rv = nghttp2_submit_response(ps->session, stream_id, nva, nvlen, NULL);

        if (nva) Safefree(nva);

        if (rv != 0) {
            croak("nghttp2_submit_response failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

int
_submit_trailer_xs(self, stream_id, headers_av)
        SV *self
        int stream_id
        AV *headers_av
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        nva = perl_headers_to_nva(aTHX_ headers_av, &nvlen);

        rv = nghttp2_submit_trailer(ps->session, stream_id, nva, nvlen);

        if (nva) {
            Safefree(nva);
        }

        if (rv != 0) {
            croak("nghttp2_submit_trailer failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Resume data on a stream (after NGHTTP2_ERR_DEFERRED)
int
resume_data(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        nghttp2_perl_session *ps;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        rv = nghttp2_session_resume_data(ps->session, stream_id);
        if (rv != 0 && rv != NGHTTP2_ERR_INVALID_ARGUMENT) {
            croak("nghttp2_session_resume_data failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Get stream user data
SV *
get_stream_user_data(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        nghttp2_perl_session *ps;
        void *data;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        data = nghttp2_session_get_stream_user_data(ps->session, stream_id);
        if (data) {
            RETVAL = newSVsv((SV *)data);
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

# Set stream user data
int
set_stream_user_data(self, stream_id, data)
        SV *self
        int stream_id
        SV *data
    PREINIT:
        nghttp2_perl_session *ps;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        /* Note: caller must ensure data SV survives */
        rv = nghttp2_session_set_stream_user_data(ps->session, stream_id,
                                                   SvOK(data) ? newSVsv(data) : NULL);
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Query whether the remote peer half closed a stream.
# Returns 1 or 0, or undef when no such stream exists.
SV *
get_stream_remote_close(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        nghttp2_perl_session *ps;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        rv = nghttp2_session_get_stream_remote_close(ps->session, stream_id);
        RETVAL = rv < 0 ? &PL_sv_undef : newSViv(rv);
    OUTPUT:
        RETVAL

# Query whether the local peer half closed a stream.
# Returns 1 or 0, or undef when no such stream exists.
SV *
get_stream_local_close(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        nghttp2_perl_session *ps;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        rv = nghttp2_session_get_stream_local_close(ps->session, stream_id);
        RETVAL = rv < 0 ? &PL_sv_undef : newSViv(rv);
    OUTPUT:
        RETVAL

# Terminate session with GOAWAY
int
terminate_session(self, error_code)
        SV *self
        int error_code
    PREINIT:
        nghttp2_perl_session *ps;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        rv = nghttp2_session_terminate_session(ps->session, error_code);
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Submit response with streaming data callback
# Callback receives ($stream_id, $max_length[, $user_data]); user data is optional.
# It returns:
#   ($data, $eof_flag)                 - send data; EOF ends the stream
#   ($data, $eof_flag, $no_end_stream) - EOF without DATA END_STREAM for trailers
#   defer: return undef or an empty list; resume or submit data later
int
_submit_response_streaming(self, stream_id, headers_av, data_callback, cb_user_data)
        SV *self
        int stream_id
        AV *headers_av
        SV *data_callback
        SV *cb_user_data
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        nghttp2_data_provider data_prd;
        nghttp2_perl_data_provider *dp;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        assert_stream_has_no_provider(aTHX_ ps, stream_id);

        nva = perl_headers_to_nva(aTHX_ headers_av, &nvlen);

        /* Create data provider state */
        Newxz(dp, 1, nghttp2_perl_data_provider);
        dp->stream_id = stream_id;
        dp->callback = newSVsv(data_callback);
        if (SvOK(cb_user_data)) {
            dp->user_data = newSVsv(cb_user_data);
        }
        dp->eof = 0;
        dp->deferred = 0;

        /* Set up nghttp2 data provider */
        data_prd.source.ptr = dp;
        data_prd.read_callback = perl_data_source_read_callback;

        rv = nghttp2_submit_response(ps->session, stream_id, nva, nvlen, &data_prd);

        if (nva) Safefree(nva);

        if (rv != 0) {
            /* nghttp2 copies the descriptor only when the submit succeeds, so a
               failure leaves the provider ours. No session call is running here,
               so there is nothing to hold it past. */
            free_data_provider(aTHX_ dp);
            croak("nghttp2_submit_response failed: %s", nghttp2_strerror(rv));
        }

        /* The session owns the provider from here on. */
        add_data_provider(aTHX_ ps, dp);
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Queue data to send on an existing stream.
# The stream must already have a data provider (from submit_request or
# submit_response with a streaming body callback).  This sets the data
# provider's user_data to the given data and eof flag, clears the deferred
# state, and calls nghttp2_session_resume_data so the next mem_send will
# invoke the read callback which returns this data.
int
submit_data(self, stream_id, data_sv, eof, no_end_stream = 0)
        SV *self
        int stream_id
        SV *data_sv
        int eof
        int no_end_stream
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_perl_data_provider *dp;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);

        dp = find_data_provider(ps, stream_id);
        if (!dp) {
            croak("submit_data: no data provider for stream %d "
                  "(submit_request or submit_response with body callback first)",
                  stream_id);
        }

        /* Replace the callback with NULL (one-shot static body mode) and
           store the data in user_data for the read callback to pick up */
        if (dp->callback) {
            SvREFCNT_dec(dp->callback);
            dp->callback = NULL;
        }
        if (dp->user_data) {
            SvREFCNT_dec(dp->user_data);
        }
        dp->user_data = SvOK(data_sv) ? newSVsv(data_sv) : NULL;
        dp->eof = eof ? 1 : 0;
        dp->no_end_stream = (eof && no_end_stream) ? 1 : 0;
        dp->deferred = 0;

        /* Resume the stream so nghttp2 calls the read callback */
        rv = nghttp2_session_resume_data(ps->session, stream_id);
        if (rv != 0 && rv != NGHTTP2_ERR_INVALID_ARGUMENT) {
            croak("submit_data: resume failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = 0;
    OUTPUT:
        RETVAL

# Check if stream is deferred (waiting for data)
int
is_stream_deferred(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_perl_data_provider *dp;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        dp = find_data_provider(ps, stream_id);
        RETVAL = dp ? dp->deferred : 0;
    OUTPUT:
        RETVAL

# Clear deferred flag for a stream (internal use after resume_data)
void
_clear_deferred(self, stream_id)
        SV *self
        int stream_id
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_perl_data_provider *dp;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        dp = find_data_provider(ps, stream_id);
        if (dp) {
            dp->deferred = 0;
        }

# Create new client session
SV *
_new_client_xs(class, callbacks_hv, user_data)
        char *class
        HV *callbacks_hv
        SV *user_data
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_session_callbacks *callbacks;
        int rv;
    CODE:
        /* Allocate our wrapper structure */
        Newxz(ps, 1, nghttp2_perl_session);

        /* Initialize send buffer */
        ps->send_buf_cap = 16384;
        ps->send_buf = (char *)malloc(ps->send_buf_cap);
        ps->send_buf_len = 0;

        /* Store user data */
        if (SvOK(user_data)) {
            ps->user_data = newSVsv(user_data);
        }

        /* Extract callbacks from hash */
        extract_perl_callbacks(aTHX_ ps, callbacks_hv);

        /* Create nghttp2 callbacks */
        rv = nghttp2_session_callbacks_new(&callbacks);
        if (rv != 0) {
            release_perl_callbacks(aTHX_ ps);
            free(ps->send_buf);
            Safefree(ps);
            croak("nghttp2_session_callbacks_new failed: %s", nghttp2_strerror(rv));
        }
        register_nghttp2_callbacks(callbacks);

        /* Create CLIENT session (difference from server) */
        rv = nghttp2_session_client_new(&ps->session, callbacks, ps);
        nghttp2_session_callbacks_del(callbacks);

        if (rv != 0) {
            release_perl_callbacks(aTHX_ ps);
            free(ps->send_buf);
            Safefree(ps);
            croak("nghttp2_session_client_new failed: %s", nghttp2_strerror(rv));
        }

        /* Bless and return */
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, class, (void *)ps);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

# Submit request (client-side)
# Returns stream ID on success
int
_submit_request_xs(self, headers_av, body_sv)
        SV *self
        AV *headers_av
        SV *body_sv
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        nghttp2_data_provider data_prd;
        nghttp2_data_provider *data_prd_ptr = NULL;
        nghttp2_perl_data_provider *dp = NULL;
        int32_t stream_id;
        STRLEN body_len = 0;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);

        nva = perl_headers_to_nva(aTHX_ headers_av, &nvlen);

        /* Check if we have a body to send */
        if (SvOK(body_sv) && SvROK(body_sv) && SvTYPE(SvRV(body_sv)) == SVt_PVCV) {
            /* CODE ref body: streaming callback data provider */
            Newxz(dp, 1, nghttp2_perl_data_provider);
            dp->stream_id = 0;  /* Will be set after submit */
            dp->eof = 0;
            dp->deferred = 0;
            dp->callback = newSVsv(body_sv);

            data_prd.source.ptr = dp;
            data_prd.read_callback = perl_data_source_read_callback;
            data_prd_ptr = &data_prd;
        }
        else if (SvOK(body_sv) && SvPOK(body_sv)) {
            const char *body_ptr = SvPVbyte(body_sv, body_len);
            if (body_len > 0) {
                /* Static string body: one-shot data provider */
                Newxz(dp, 1, nghttp2_perl_data_provider);
                dp->stream_id = 0;  /* Will be set after submit */
                dp->eof = 1;       /* Static bodies always want EOF after sending */
                dp->deferred = 0;
                dp->user_data = newSVsv(body_sv);
                dp->callback = NULL;  /* Use user_data as body */

                data_prd.source.ptr = dp;
                data_prd.read_callback = perl_data_source_read_callback;
                data_prd_ptr = &data_prd;
            }
        }

        stream_id = nghttp2_submit_request(ps->session, NULL, nva, nvlen, data_prd_ptr, NULL);

        if (nva) Safefree(nva);

        if (stream_id < 0) {
            /* The session never took the provider; see _submit_response_streaming. */
            if (dp) {
                free_data_provider(aTHX_ dp);
            }
            croak("nghttp2_submit_request failed: %s", nghttp2_strerror(stream_id));
        }

        /* The session owns the provider from here on. */
        if (dp) {
            dp->stream_id = stream_id;
            add_data_provider(aTHX_ ps, dp);
        }

        RETVAL = stream_id;
    OUTPUT:
        RETVAL

# Submit RST_STREAM (reset a stream)
int
submit_rst_stream(self, stream_id, error_code)
        SV *self
        int stream_id
        unsigned int error_code
    PREINIT:
        nghttp2_perl_session *ps;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        rv = nghttp2_submit_rst_stream(ps->session, NGHTTP2_FLAG_NONE, stream_id, error_code);
        if (rv != 0) {
            croak("nghttp2_submit_rst_stream failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Submit GOAWAY frame
int
_submit_goaway_xs(self, last_stream_id, error_code, opaque_data)
        SV *self
        int last_stream_id
        unsigned int error_code
        SV *opaque_data
    PREINIT:
        nghttp2_perl_session *ps;
        STRLEN len = 0;
        const uint8_t *data = NULL;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);

        if (SvOK(opaque_data)) {
            data = (const uint8_t *)SvPVbyte(opaque_data, len);
        }

        rv = nghttp2_submit_goaway(ps->session, NGHTTP2_FLAG_NONE,
                                   last_stream_id, error_code, data, len);
        if (rv != 0) {
            croak("nghttp2_submit_goaway failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Submit PING frame
int
submit_ping(self, ack, opaque_data)
        SV *self
        int ack
        SV *opaque_data
    PREINIT:
        nghttp2_perl_session *ps;
        STRLEN len;
        const uint8_t *data;
        uint8_t flags;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        flags = ack ? NGHTTP2_FLAG_ACK : NGHTTP2_FLAG_NONE;

        if (SvOK(opaque_data)) {
            data = (const uint8_t *)SvPVbyte(opaque_data, len);
            if (len != 8) {
                croak("PING opaque_data must be exactly 8 bytes");
            }
        } else {
            data = NULL;
        }

        rv = nghttp2_submit_ping(ps->session, flags, data);
        if (rv != 0) {
            croak("nghttp2_submit_ping failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Submit WINDOW_UPDATE frame
int
submit_window_update(self, stream_id, window_size_increment)
        SV *self
        int stream_id
        int window_size_increment
    PREINIT:
        nghttp2_perl_session *ps;
        int rv;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));
        SESSION_ALIVE_OR_CROAK(ps);
        rv = nghttp2_submit_window_update(ps->session, NGHTTP2_FLAG_NONE, stream_id, window_size_increment);
        if (rv != 0) {
            croak("nghttp2_submit_window_update failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL
