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
    int deferred;           /* Currently deferred */
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
} nghttp2_perl_session;

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

static void add_data_provider(nghttp2_perl_session *ps, nghttp2_perl_data_provider *dp) {
    int i;
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

static void remove_data_provider(nghttp2_perl_session *ps, int32_t stream_id) {
    dTHX;
    int i;
    for (i = 0; i < ps->data_providers_count; i++) {
        if (ps->data_providers[i] && ps->data_providers[i]->stream_id == stream_id) {
            nghttp2_perl_data_provider *dp = ps->data_providers[i];
            if (dp->callback) SvREFCNT_dec(dp->callback);
            if (dp->user_data) SvREFCNT_dec(dp->user_data);
            Safefree(dp);
            ps->data_providers[i] = NULL;
            return;
        }
    }
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

    /* Special case: if callback is NULL but user_data contains body, use it directly */
    if (!dp->callback && dp->user_data && SvOK(dp->user_data) && !dp->eof) {
        STRLEN body_len;
        const char *body_ptr = SvPVbyte(dp->user_data, body_len);

        if (body_len > length) {
            body_len = length;
        }
        if (body_len > 0) {
            memcpy(buf, body_ptr, body_len);
        }

        /* Mark as EOF - we send the entire body in one go */
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        dp->eof = 1;

        return (ssize_t)body_len;
    }

    if (!dp->callback || !SvOK(dp->callback)) {
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        return 0;
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* Call: $callback->($stream_id, $max_length) */
    /* Returns: ($data, $eof) or undef for deferred */
    XPUSHs(sv_2mortal(newSViv(stream_id)));
    XPUSHs(sv_2mortal(newSVuv(length)));
    if (dp->user_data && SvOK(dp->user_data)) {
        XPUSHs(dp->user_data);
    }

    PUTBACK;
    count = call_sv(dp->callback, G_ARRAY | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        /* Callback threw an exception */
        warn("nghttp2 data provider callback error: %s", SvPV_nolen(ERRSV));
        ret = NGHTTP2_ERR_CALLBACK_FAILURE;
    } else if (count == 0) {
        /* No return value = defer */
        dp->deferred = 1;
        ret = NGHTTP2_ERR_DEFERRED;
    } else if (count >= 1) {
        SV *eof_sv = NULL;
        SV *data_sv = NULL;

        if (count >= 2) {
            eof_sv = POPs;
        }
        data_sv = POPs;

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
            }
            /* If returned empty string with no eof, also defer */
            if (data_len == 0 && !dp->eof) {
                dp->deferred = 1;
                ret = NGHTTP2_ERR_DEFERRED;
            }
        }
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

/* Frame receive callback */
static int perl_on_frame_recv_callback(nghttp2_session *session,
                                       const nghttp2_frame *frame,
                                       void *user_data) {
    dTHX;
    nghttp2_perl_session *ps = (nghttp2_perl_session *)user_data;
    AV *args;
    HV *frame_hv;
    int ret;

    if (!ps->cb_on_frame_recv || !SvOK(ps->cb_on_frame_recv)) {
        return 0;
    }

    /* Build frame info hash */
    frame_hv = newHV();
    hv_store(frame_hv, "stream_id", 9, newSViv(frame->hd.stream_id), 0);
    hv_store(frame_hv, "type", 4, newSViv(frame->hd.type), 0);
    hv_store(frame_hv, "flags", 5, newSViv(frame->hd.flags), 0);
    hv_store(frame_hv, "length", 6, newSViv(frame->hd.length), 0);

    args = newAV();
    av_push(args, newRV_noinc((SV *)frame_hv));

    ret = call_perl_callback(aTHX_ ps->cb_on_frame_recv, args);

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
_new_server_xs(class, callbacks_hv, user_data)
        char *class
        HV *callbacks_hv
        SV *user_data
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_session_callbacks *callbacks;
        int rv;
        SV **svp;
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

        /* Create nghttp2 callbacks */
        nghttp2_session_callbacks_new(&callbacks);
        nghttp2_session_callbacks_set_send_callback(callbacks, perl_send_callback);
        nghttp2_session_callbacks_set_on_begin_headers_callback(callbacks, perl_on_begin_headers_callback);
        nghttp2_session_callbacks_set_on_header_callback(callbacks, perl_on_header_callback);
        nghttp2_session_callbacks_set_on_frame_recv_callback(callbacks, perl_on_frame_recv_callback);
        nghttp2_session_callbacks_set_on_data_chunk_recv_callback(callbacks, perl_on_data_chunk_recv_callback);
        nghttp2_session_callbacks_set_on_stream_close_callback(callbacks, perl_on_stream_close_callback);

        /* Create session */
        rv = nghttp2_session_server_new(&ps->session, callbacks, ps);
        nghttp2_session_callbacks_del(callbacks);

        if (rv != 0) {
            if (ps->user_data) SvREFCNT_dec(ps->user_data);
            if (ps->cb_on_begin_headers) SvREFCNT_dec(ps->cb_on_begin_headers);
            if (ps->cb_on_header) SvREFCNT_dec(ps->cb_on_header);
            if (ps->cb_on_frame_recv) SvREFCNT_dec(ps->cb_on_frame_recv);
            if (ps->cb_on_data_chunk_recv) SvREFCNT_dec(ps->cb_on_data_chunk_recv);
            if (ps->cb_on_stream_close) SvREFCNT_dec(ps->cb_on_stream_close);
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
            }
            if (ps->user_data) SvREFCNT_dec(ps->user_data);
            if (ps->cb_on_begin_headers) SvREFCNT_dec(ps->cb_on_begin_headers);
            if (ps->cb_on_header) SvREFCNT_dec(ps->cb_on_header);
            if (ps->cb_on_frame_recv) SvREFCNT_dec(ps->cb_on_frame_recv);
            if (ps->cb_on_data_chunk_recv) SvREFCNT_dec(ps->cb_on_data_chunk_recv);
            if (ps->cb_on_stream_close) SvREFCNT_dec(ps->cb_on_stream_close);
            if (ps->send_buf) free(ps->send_buf);
            /* Clean up data providers */
            for (i = 0; i < ps->data_providers_count; i++) {
                if (ps->data_providers[i]) {
                    nghttp2_perl_data_provider *dp = ps->data_providers[i];
                    if (dp->callback) SvREFCNT_dec(dp->callback);
                    if (dp->user_data) SvREFCNT_dec(dp->user_data);
                    Safefree(dp);
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
        buf = SvPVbyte(data, len);

        rv = nghttp2_session_mem_recv(ps->session, (const uint8_t *)buf, len);
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

        /* Clear send buffer */
        ps->send_buf_len = 0;

        /* Trigger send callback to fill buffer */
        rv = nghttp2_session_send(ps->session);
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

        rv = nghttp2_submit_settings(ps->session, NGHTTP2_FLAG_NONE, iv, niv);
        if (rv != 0) {
            croak("nghttp2_submit_settings failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Submit response (simple version with static body)
int
_submit_response_with_body(self, stream_id, headers_av, body)
        SV *self
        int stream_id
        AV *headers_av
        SV *body
    PREINIT:
        nghttp2_perl_session *ps;
        nghttp2_nv *nva;
        size_t nvlen;
        nghttp2_data_provider data_prd;
        int rv;
        I32 i;
        STRLEN body_len;
        char *body_ptr;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));

        /* Build name-value array from Perl array of arrayrefs */
        nvlen = av_len(headers_av) + 1;
        Newxz(nva, nvlen, nghttp2_nv);

        for (i = 0; i < (I32)nvlen; i++) {
            SV **pair = av_fetch(headers_av, i, 0);
            if (pair && SvROK(*pair) && SvTYPE(SvRV(*pair)) == SVt_PVAV) {
                AV *pair_av = (AV *)SvRV(*pair);
                SV **name_sv = av_fetch(pair_av, 0, 0);
                SV **value_sv = av_fetch(pair_av, 1, 0);

                if (name_sv && value_sv) {
                    STRLEN name_len, value_len;
                    nva[i].name = (uint8_t *)SvPVbyte(*name_sv, name_len);
                    nva[i].namelen = name_len;
                    nva[i].value = (uint8_t *)SvPVbyte(*value_sv, value_len);
                    nva[i].valuelen = value_len;
                    nva[i].flags = NGHTTP2_NV_FLAG_NONE;
                }
            }
        }

        /* For now, submit without data provider (headers only) */
        /* TODO: Implement proper data provider for body */
        body_ptr = SvPVbyte(body, body_len);

        rv = nghttp2_submit_response(ps->session, stream_id, nva, nvlen, NULL);

        Safefree(nva);

        if (rv != 0) {
            croak("nghttp2_submit_response failed: %s", nghttp2_strerror(rv));
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
        I32 i;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));

        /* Build name-value array */
        nvlen = av_len(headers_av) + 1;
        Newxz(nva, nvlen, nghttp2_nv);

        for (i = 0; i < (I32)nvlen; i++) {
            SV **pair = av_fetch(headers_av, i, 0);
            if (pair && SvROK(*pair) && SvTYPE(SvRV(*pair)) == SVt_PVAV) {
                AV *pair_av = (AV *)SvRV(*pair);
                SV **name_sv = av_fetch(pair_av, 0, 0);
                SV **value_sv = av_fetch(pair_av, 1, 0);

                if (name_sv && value_sv) {
                    STRLEN name_len, value_len;
                    nva[i].name = (uint8_t *)SvPVbyte(*name_sv, name_len);
                    nva[i].namelen = name_len;
                    nva[i].value = (uint8_t *)SvPVbyte(*value_sv, value_len);
                    nva[i].valuelen = value_len;
                    nva[i].flags = NGHTTP2_NV_FLAG_NONE;
                }
            }
        }

        rv = nghttp2_submit_response(ps->session, stream_id, nva, nvlen, NULL);

        Safefree(nva);

        if (rv != 0) {
            croak("nghttp2_submit_response failed: %s", nghttp2_strerror(rv));
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
        /* Note: caller must ensure data SV survives */
        rv = nghttp2_session_set_stream_user_data(ps->session, stream_id,
                                                   SvOK(data) ? newSVsv(data) : NULL);
        RETVAL = rv;
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
        rv = nghttp2_session_terminate_session(ps->session, error_code);
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Submit response with streaming data callback
# Callback receives ($stream_id, $max_length, $user_data) and returns ($data, $eof)
# Return undef or empty list to defer (call resume_data later)
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
        I32 i;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));

        /* Build name-value array from Perl array of arrayrefs */
        nvlen = av_len(headers_av) + 1;
        Newxz(nva, nvlen, nghttp2_nv);

        for (i = 0; i < (I32)nvlen; i++) {
            SV **pair = av_fetch(headers_av, i, 0);
            if (pair && SvROK(*pair) && SvTYPE(SvRV(*pair)) == SVt_PVAV) {
                AV *pair_av = (AV *)SvRV(*pair);
                SV **name_sv = av_fetch(pair_av, 0, 0);
                SV **value_sv = av_fetch(pair_av, 1, 0);

                if (name_sv && value_sv) {
                    STRLEN name_len, value_len;
                    nva[i].name = (uint8_t *)SvPVbyte(*name_sv, name_len);
                    nva[i].namelen = name_len;
                    nva[i].value = (uint8_t *)SvPVbyte(*value_sv, value_len);
                    nva[i].valuelen = value_len;
                    nva[i].flags = NGHTTP2_NV_FLAG_NONE;
                }
            }
        }

        /* Create data provider state */
        Newxz(dp, 1, nghttp2_perl_data_provider);
        dp->stream_id = stream_id;
        dp->callback = newSVsv(data_callback);
        if (SvOK(cb_user_data)) {
            dp->user_data = newSVsv(cb_user_data);
        }
        dp->eof = 0;
        dp->deferred = 0;

        /* Track the data provider */
        add_data_provider(ps, dp);

        /* Set up nghttp2 data provider */
        data_prd.source.ptr = dp;
        data_prd.read_callback = perl_data_source_read_callback;

        rv = nghttp2_submit_response(ps->session, stream_id, nva, nvlen, &data_prd);

        Safefree(nva);

        if (rv != 0) {
            remove_data_provider(ps, stream_id);
            croak("nghttp2_submit_response failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL

# Submit DATA frame directly (for simple cases)
int
submit_data(self, stream_id, data, eof)
        SV *self
        int stream_id
        SV *data
        int eof
    PREINIT:
        nghttp2_perl_session *ps;
        STRLEN len;
        const uint8_t *buf;
        int rv;
        uint8_t flags = NGHTTP2_FLAG_NONE;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));

        if (eof) {
            flags |= NGHTTP2_FLAG_END_STREAM;
        }

        buf = (const uint8_t *)SvPVbyte(data, len);

        /* Use nghttp2_submit_data to queue data */
        /* Note: This requires the stream to already have a response submitted */
        rv = nghttp2_submit_data(ps->session, flags, stream_id, NULL);

        if (rv != 0) {
            croak("nghttp2_submit_data failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
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
        SV **svp;
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
        if (callbacks_hv) {
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
        }

        /* Create nghttp2 callbacks */
        nghttp2_session_callbacks_new(&callbacks);
        nghttp2_session_callbacks_set_send_callback(callbacks, perl_send_callback);
        nghttp2_session_callbacks_set_on_begin_headers_callback(callbacks, perl_on_begin_headers_callback);
        nghttp2_session_callbacks_set_on_header_callback(callbacks, perl_on_header_callback);
        nghttp2_session_callbacks_set_on_frame_recv_callback(callbacks, perl_on_frame_recv_callback);
        nghttp2_session_callbacks_set_on_data_chunk_recv_callback(callbacks, perl_on_data_chunk_recv_callback);
        nghttp2_session_callbacks_set_on_stream_close_callback(callbacks, perl_on_stream_close_callback);

        /* Create CLIENT session (difference from server) */
        rv = nghttp2_session_client_new(&ps->session, callbacks, ps);
        nghttp2_session_callbacks_del(callbacks);

        if (rv != 0) {
            if (ps->user_data) SvREFCNT_dec(ps->user_data);
            if (ps->cb_on_begin_headers) SvREFCNT_dec(ps->cb_on_begin_headers);
            if (ps->cb_on_header) SvREFCNT_dec(ps->cb_on_header);
            if (ps->cb_on_frame_recv) SvREFCNT_dec(ps->cb_on_frame_recv);
            if (ps->cb_on_data_chunk_recv) SvREFCNT_dec(ps->cb_on_data_chunk_recv);
            if (ps->cb_on_stream_close) SvREFCNT_dec(ps->cb_on_stream_close);
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
        I32 i;
        STRLEN body_len = 0;
    CODE:
        ps = (nghttp2_perl_session *)SvIV(SvRV(self));

        /* Build name-value array from Perl array of arrayrefs */
        nvlen = av_len(headers_av) + 1;
        Newxz(nva, nvlen, nghttp2_nv);

        for (i = 0; i < (I32)nvlen; i++) {
            SV **pair = av_fetch(headers_av, i, 0);
            if (pair && SvROK(*pair) && SvTYPE(SvRV(*pair)) == SVt_PVAV) {
                AV *pair_av = (AV *)SvRV(*pair);
                SV **name_sv = av_fetch(pair_av, 0, 0);
                SV **value_sv = av_fetch(pair_av, 1, 0);

                if (name_sv && value_sv) {
                    STRLEN name_len, value_len;
                    nva[i].name = (uint8_t *)SvPVbyte(*name_sv, name_len);
                    nva[i].namelen = name_len;
                    nva[i].value = (uint8_t *)SvPVbyte(*value_sv, value_len);
                    nva[i].valuelen = value_len;
                    nva[i].flags = NGHTTP2_NV_FLAG_NONE;
                }
            }
        }

        /* Check if we have a body to send */
        if (SvOK(body_sv) && SvPOK(body_sv)) {
            const char *body_ptr = SvPVbyte(body_sv, body_len);
            if (body_len > 0) {
                /* Create a simple one-shot data provider for the body */
                Newxz(dp, 1, nghttp2_perl_data_provider);
                dp->stream_id = 0;  /* Will be set after submit */
                dp->eof = 0;
                dp->deferred = 0;

                /* Store body as a callback that returns the body once */
                /* We'll use a closure-like approach: store body in user_data */
                dp->user_data = newSVsv(body_sv);
                dp->callback = NULL;  /* Special marker: use user_data as body */

                data_prd.source.ptr = dp;
                data_prd.read_callback = perl_data_source_read_callback;
                data_prd_ptr = &data_prd;
            }
        }

        stream_id = nghttp2_submit_request(ps->session, NULL, nva, nvlen, data_prd_ptr, NULL);

        Safefree(nva);

        if (stream_id < 0) {
            if (dp) {
                if (dp->user_data) SvREFCNT_dec(dp->user_data);
                Safefree(dp);
            }
            croak("nghttp2_submit_request failed: %s", nghttp2_strerror(stream_id));
        }

        /* Track data provider if we have one */
        if (dp) {
            dp->stream_id = stream_id;
            add_data_provider(ps, dp);
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
        rv = nghttp2_submit_rst_stream(ps->session, NGHTTP2_FLAG_NONE, stream_id, error_code);
        if (rv != 0) {
            croak("nghttp2_submit_rst_stream failed: %s", nghttp2_strerror(rv));
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
        rv = nghttp2_submit_window_update(ps->session, NGHTTP2_FLAG_NONE, stream_id, window_size_increment);
        if (rv != 0) {
            croak("nghttp2_submit_window_update failed: %s", nghttp2_strerror(rv));
        }
        RETVAL = rv;
    OUTPUT:
        RETVAL
