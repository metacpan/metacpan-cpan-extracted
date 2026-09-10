/* punk_sse.h - Server-Sent Events, in C.
 *
 * The lighter sibling of the WebSocket connection: an `sse` route hands the
 * socket to a stream the handler pushes text/event-stream events onto. No
 * upgrade handshake and no frame codec - just a kept-open 200 response - so it
 * reuses the WS connection's byte machinery (pw_append / a mirrored flush with
 * io_watch WRITE backpressure / teardown) and drops the rest.
 *
 * Four transports, chosen in order: Hyperman detach (stream on the loop), the
 * Hyperman stream handle (ABI v6), psgi.streaming (the portable
 * delayed-response writer), and blocking psgix.io.
 *
 * The stream handle sits under detach rather than over it, which is not where
 * an earlier sketch of this put it. Two things decide the order. On HTTP/1.1
 * in clear, detach already works and its bytes are what every existing test
 * asserts, so nothing may be taken off it. And a handle can only be opened
 * from a DEFERRED response - hm_stream_open refuses an HTTP/1.1 connection
 * whose handler has not yet returned, because a synchronous return value
 * would be serialised on top of the body - so the branch lives inside the
 * psgi.streaming responder, which is the deferral. What it buys is exactly
 * the cases detach refuses: HTTP/2, where a stream is one of many on a shared
 * connection and there is no fd to hand over, and TLS, where the session
 * state belongs to the server. Both used to end at a 503 or at a
 * psgi.streaming writer that buffers to close - which for an SSE stream that
 * never closes means nothing is ever delivered.
 *
 * Must be included after punk_wsconn.h (punk_hm, pw_append) and
 * punk_wshandshake.h (pw_err / pw_empty), and punk_context.h (pcx_* / frj).
 */

#ifndef PUNK_SSE_H
#define PUNK_SSE_H

#include <fcntl.h>

enum { SSE_MODE_DETACH = 0, SSE_MODE_STREAM = 1, SSE_MODE_BLOCK = 2,
       SSE_MODE_HSTREAM = 3 };
enum { SSE_OPEN = 0, SSE_CLOSED = 1 };

typedef struct punk_sse {
    int    fd;                    /* detach / block; -1 for a psgi writer */
    int    mode;
    int    state;
    unsigned char reading, writing, in_teardown;
    char  *wbuf; size_t wlen, woff, wcap;
    size_t write_buffer_limit;
    SV    *writer;                /* the psgi.streaming $writer (STREAM mode) */
    HV    *cbs;                   /* event name -> coderef (close) */
    SV    *self_rv;              /* strong self while live */
    void  *loop;
    const hm_abi *abi;
    void  *sh;                    /* the v6 stream handle (HSTREAM mode) */
    hm_abi_timer *hb_tw;          /* heartbeat timer */
    double heartbeat;             /* seconds; 0 = off */
} punk_sse;

/* The transports that run on the worker's event loop, and so have a timer to
 * arm a heartbeat on. The two differ in what they write through, not in when
 * they get to run. */
#define SE_ON_LOOP(sse) ((sse)->mode == SSE_MODE_DETACH \
                      || (sse)->mode == SSE_MODE_HSTREAM)

static const char SSE_RESPONSE[] =
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: text/event-stream\r\n"
    "Cache-Control: no-cache\r\n"
    "Connection: keep-alive\r\n"
    "X-Accel-Buffering: no\r\n"
    "\r\n";

static punk_sse *se_of(pTHX_ SV *self) {
    if (!SvROK(self) || !SvIOK(SvRV(self)))
        croak("Punk::SSE: not a stream");
    return (punk_sse *)INT2PTR(void *, SvIV(SvRV(self)));
}

static void se_teardown(pTHX_ punk_sse *sse);
static void se_on_writable(pTHX_ int fd, int mask, void *ud);

/* ---- writing (DETACH / BLOCK): mirror punk_wsconn.h's flush --------------- */

static void se_flush(pTHX_ punk_sse *sse) {
    while (sse->woff < sse->wlen) {
        ssize_t n = write(sse->fd, sse->wbuf + sse->woff, sse->wlen - sse->woff);
        if (n > 0) { sse->woff += (size_t)n; continue; }
        if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            if (!sse->writing && sse->mode == SSE_MODE_DETACH
                && sse->abi && sse->loop) {
                sse->abi->io_watch(aTHX_ sse->loop, sse->fd, HM_ABI_WRITE,
                                   se_on_writable, sse);
                sse->writing = 1;
            }
            return;
        }
        if (n < 0 && errno == EINTR) continue;
        se_teardown(aTHX_ sse);                  /* write error: client gone */
        return;
    }
    sse->wlen = sse->woff = 0;
    if (sse->writing && sse->abi && sse->loop) {
        sse->abi->io_unwatch(aTHX_ sse->loop, sse->fd, HM_ABI_WRITE);
        sse->writing = 0;
    }
}

static void se_on_writable(pTHX_ int fd, int mask, void *ud) {
    PERL_UNUSED_ARG(fd); PERL_UNUSED_ARG(mask);
    se_flush(aTHX_ (punk_sse *)ud);
}

/* the client closing is the only thing we read for; a read of 0 tears down */
static void se_on_readable(pTHX_ int fd, int mask, void *ud) {
    punk_sse *sse = (punk_sse *)ud;
    char scratch[512];
    ssize_t n;
    PERL_UNUSED_ARG(fd); PERL_UNUSED_ARG(mask);
    n = read(sse->fd, scratch, sizeof scratch);
    if (n == 0) { se_teardown(aTHX_ sse); return; }
    if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR))
        return;
    if (n < 0) se_teardown(aTHX_ sse);
    /* n > 0: a client should not send on an SSE stream; ignore it */
}

/* queue bytes to the active backend */
static void se_write(pTHX_ punk_sse *sse, const char *bytes, size_t len) {
    if (sse->state != SSE_OPEN) return;
    if (sse->mode == SSE_MODE_HSTREAM) {
        /* The write can close the connection under us, and Hyperman fires
         * the abort callback from there - which tears this stream down and
         * drops its own last reference. So the reference is held across the
         * call, exactly as the heartbeat holds one. */
        SV *keep = sse->self_rv ? SvREFCNT_inc(sse->self_rv) : NULL;
        int r = sse->abi->stream_write(aTHX_ sse->sh, bytes, len);
        /* HM_ABI_STREAM_FULL is not an error: the bytes were taken and the
         * connection is merely backed up. An event stream's writes are small
         * and there is nothing useful to drop, so the bound that matters is
         * Hyperman's own connection buffer rather than one kept here. */
        if (r < 0 && sse->state == SSE_OPEN) se_teardown(aTHX_ sse);
        if (keep) SvREFCNT_dec(keep);             /* sse may be gone now */
        return;
    }
    if (sse->mode == SSE_MODE_STREAM) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 2);
        PUSHs(sse->writer ? sse->writer : &PL_sv_undef);
        PUSHs(sv_2mortal(newSVpvn(bytes, len)));
        PUTBACK;
        call_method("write", G_DISCARD | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) { FREETMPS; LEAVE; se_teardown(aTHX_ sse); return; }
        PUTBACK; FREETMPS; LEAVE;
        return;
    }
    if (sse->write_buffer_limit
        && sse->wlen - sse->woff + len > sse->write_buffer_limit) {
        se_teardown(aTHX_ sse);                  /* a client that will not read */
        return;
    }
    pw_append(&sse->wbuf, &sse->wlen, &sse->wcap, bytes, len);
    se_flush(aTHX_ sse);
}

/* ---- SSE field formatting ------------------------------------------------- */

/* append `data:` lines for one payload (a ref -> JSON; a string -> one line
 * per newline), no terminating blank line */
static void se_append_data(pTHX_ SV *out, SV *data) {
    if (SvROK(data)) {
        SV *json = punk_frj(aTHX)->encode(aTHX_ data, NULL);
        sv_catpvs(out, "data: ");
        sv_catsv(out, json);
        sv_catpvs(out, "\n");
        SvREFCNT_dec(json);
    }
    else {
        STRLEN l = 0, i, start = 0;
        const char *p = SvOK(data) ? SvPV_const(data, l) : "";
        for (i = 0; i <= l; i++) {
            if (i == l || p[i] == '\n') {
                sv_catpvs(out, "data: ");
                sv_catpvn(out, p + start, i - start);
                sv_catpvs(out, "\n");
                start = i + 1;
            }
        }
    }
}

static void se_send(pTHX_ punk_sse *sse, SV *data) {
    SV *out = sv_2mortal(newSVpvs(""));
    se_append_data(aTHX_ out, data);
    sv_catpvs(out, "\n");
    se_write(aTHX_ sse, SvPVX(out), SvCUR(out));
}

static void se_event(pTHX_ punk_sse *sse, SV *name, SV *data) {
    SV *out = sv_2mortal(newSVpvs("event: "));
    STRLEN nl; const char *n = SvOK(name) ? SvPV_const(name, nl) : "";
    STRLEN i;
    for (i = 0; i < nl; i++) if (n[i] == '\n' || n[i] == '\r') break;  /* one line */
    sv_catpvn(out, n, i);
    sv_catpvs(out, "\n");
    se_append_data(aTHX_ out, data);
    sv_catpvs(out, "\n");
    se_write(aTHX_ sse, SvPVX(out), SvCUR(out));
}

static void se_field(pTHX_ punk_sse *sse, const char *field, SV *val) {
    SV *out = sv_2mortal(newSVpv(field, 0));
    STRLEN vl; const char *v = SvOK(val) ? SvPV_const(val, vl) : "";
    STRLEN i;
    for (i = 0; i < vl; i++) if (v[i] == '\n' || v[i] == '\r') break;
    sv_catpvn(out, v, i);
    sv_catpvs(out, "\n");
    se_write(aTHX_ sse, SvPVX(out), SvCUR(out));
}

/* ---- heartbeat, teardown -------------------------------------------------- */

static void se_arm_heartbeat(pTHX_ punk_sse *sse);

/* The keep-alive write is how a stream with nothing to say finds out its
 * client has gone, so tearing down from inside it is the normal case, not the
 * unlikely one - and teardown drops the stream's own reference, which for a
 * handler that has already returned is the LAST one. So the reference is held
 * across the write: without it the re-arm below reads freed memory and hands
 * the loop a timer pointed at it. */
static void se_heartbeat_cb(pTHX_ void *ud) {
    punk_sse *sse = (punk_sse *)ud;
    SV *keep = sse->self_rv ? SvREFCNT_inc(sse->self_rv) : NULL;
    sse->hb_tw = NULL;
    if (sse->state == SSE_OPEN) {
        se_write(aTHX_ sse, ":\n\n", 3);         /* a keep-alive comment */
        se_arm_heartbeat(aTHX_ sse);
    }
    if (keep) SvREFCNT_dec(keep);                /* sse may be gone after this */
}

static void se_arm_heartbeat(pTHX_ punk_sse *sse) {
    if (sse->state == SSE_OPEN && sse->heartbeat > 0
        && SE_ON_LOOP(sse) && sse->abi && sse->loop)
        sse->hb_tw = sse->abi->timer(aTHX_ sse->loop, sse->heartbeat,
                                     se_heartbeat_cb, sse);
}

/* The stream died before it was closed - an HTTP/2 RST_STREAM on this one
 * stream of many, or the connection going away underneath it.
 *
 * This has no HTTP/1 analogue and is the reason the handle beats detach
 * rather than merely matching it: on a multiplexed transport a peer can kill
 * one stream while the connection carries on, and a producer that never hears
 * about it goes on generating events for nobody. The handle stays valid to
 * close, which is what teardown does with it. */
static void se_on_abort(pTHX_ void *h, void *ud) {
    punk_sse *sse = (punk_sse *)ud;
    PERL_UNUSED_ARG(h);
    se_teardown(aTHX_ sse);
}

static SV *se_cb(pTHX_ punk_sse *sse, const char *name) {
    SV **e = sse->cbs ? hv_fetch(sse->cbs, name, (I32)strlen(name), 0) : NULL;
    return (e && *e && SvROK(*e)) ? *e : NULL;
}

static void se_teardown(pTHX_ punk_sse *sse) {
    SV *cb;
    if (sse->in_teardown || sse->state == SSE_CLOSED) return;
    sse->in_teardown = 1;
    if (sse->mode == SSE_MODE_DETACH && sse->abi && sse->loop) {
        if (sse->reading) sse->abi->io_unwatch(aTHX_ sse->loop, sse->fd, HM_ABI_READ);
        if (sse->writing) sse->abi->io_unwatch(aTHX_ sse->loop, sse->fd, HM_ABI_WRITE);
    }
    if (SE_ON_LOOP(sse) && sse->abi && sse->loop && sse->hb_tw) {
        sse->abi->timer_cancel(aTHX_ sse->loop, sse->hb_tw);
        sse->hb_tw = NULL;
    }
    if (sse->mode == SSE_MODE_HSTREAM && sse->abi && sse->sh) {
        /* NULLed first: closing ends the body, which on an EOF-delimited
         * HTTP/1.1 response closes the connection, and a re-entrant teardown
         * from that must not close the same handle twice. */
        void *h = sse->sh;
        sse->sh = NULL;
        (void)sse->abi->stream_close(aTHX_ h);
    }
    sse->reading = sse->writing = 0;
    if (sse->mode == SSE_MODE_STREAM && sse->writer) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(sse->writer); PUTBACK;
        call_method("close", G_DISCARD | G_EVAL);
        SPAGAIN; PUTBACK; FREETMPS; LEAVE;
    }
    if (sse->fd >= 0) { close(sse->fd); sse->fd = -1; }
    sse->state = SSE_CLOSED;
    cb = se_cb(aTHX_ sse, "close");
    if (cb) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1);
        PUSHs(sse->self_rv ? sse->self_rv : &PL_sv_undef);
        PUTBACK;
        call_sv(cb, G_DISCARD | G_EVAL);
        SPAGAIN; PUTBACK; FREETMPS; LEAVE;
    }
    if (sse->cbs) { SvREFCNT_dec((SV *)sse->cbs); sse->cbs = NULL; }
    sse->in_teardown = 0;
    if (sse->self_rv) { SV *s = sse->self_rv; sse->self_rv = NULL; SvREFCNT_dec(s); }
}

static void se_free(pTHX_ punk_sse *sse) {
    if (!sse) return;
    if (sse->mode == SSE_MODE_DETACH && sse->abi && sse->loop) {
        /* the watchers name this struct, so they must go before it does -
         * and before the fd, or the loop is left watching a number the next
         * connection will be given */
        if (sse->reading) sse->abi->io_unwatch(aTHX_ sse->loop, sse->fd, HM_ABI_READ);
        if (sse->writing) sse->abi->io_unwatch(aTHX_ sse->loop, sse->fd, HM_ABI_WRITE);
    }
    if (SE_ON_LOOP(sse) && sse->abi && sse->loop && sse->hb_tw)
        sse->abi->timer_cancel(aTHX_ sse->loop, sse->hb_tw);
    /* The handle names this struct through its callbacks, so it goes first;
     * stream_close is the only entry point that releases one, and a stream
     * aborted underneath us still has to be closed. */
    if (sse->mode == SSE_MODE_HSTREAM && sse->abi && sse->sh)
        (void)sse->abi->stream_close(aTHX_ sse->sh);
    if (sse->fd >= 0) close(sse->fd);
    if (sse->wbuf)   free(sse->wbuf);
    if (sse->writer) SvREFCNT_dec(sse->writer);
    if (sse->cbs)    SvREFCNT_dec((SV *)sse->cbs);
    if (sse->self_rv) SvREFCNT_dec(sse->self_rv);
    Safefree(sse);
}

/* ---- construction + the handler ------------------------------------------- */

static punk_sse *se_new(pTHX_ int mode, HV *opts) {
    punk_sse *sse;
    Newxz(sse, 1, punk_sse);
    sse->fd = -1;
    sse->mode = mode;
    sse->state = SSE_OPEN;
    sse->heartbeat = 15.0;
    sse->write_buffer_limit = 0;
    if (opts) {
        SV **h = hv_fetchs(opts, "heartbeat", 0);
        SV **w = hv_fetchs(opts, "write_buffer_limit", 0);
        if (h && *h && SvOK(*h)) sse->heartbeat = SvNV(*h);
        if (w && *w && SvOK(*w)) sse->write_buffer_limit = (size_t)SvUV(*w);
    }
    return sse;
}

/* run $code->($c, $stream); a die closes the stream (the 200 is already on the
 * wire, so there is no error response to send) and is reported */
static void se_run_handler(pTHX_ SV *code, SV *c, SV *self) {
    dSP; int died;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 2); PUSHs(c); PUSHs(self); PUTBACK;
    call_sv(code, G_DISCARD | G_EVAL);
    SPAGAIN;
    died = SvTRUE(ERRSV) ? 1 : 0;
    PUTBACK; FREETMPS; LEAVE;
    if (died) {
        warn("Punk::SSE: handler died: %s", SvPV_nolen(ERRSV));
        se_teardown(aTHX_ se_of(aTHX_ self));
    }
}

/* The SSE response head as a structured header list rather than the
 * SSE_RESPONSE byte string.
 *
 * Content-Type and Cache-Control carry over unchanged. Connection does NOT:
 * it is hop-by-hop, HTTP/2 and HTTP/3 forbid it outright, and there is no
 * connection to keep alive when the stream is one of many on a shared one.
 * X-Accel-Buffering is kept because it costs a header and an application may
 * still be behind nginx - though it means nothing when Hyperman is itself the
 * edge, which is the point of serving h2 and h3 natively. Owned (+1). */
static AV *se_header_av(pTHX) {
    AV *hdrs = newAV();
    av_push(hdrs, newSVpvs("Content-Type"));      av_push(hdrs, newSVpvs("text/event-stream"));
    av_push(hdrs, newSVpvs("Cache-Control"));     av_push(hdrs, newSVpvs("no-cache"));
    av_push(hdrs, newSVpvs("X-Accel-Buffering")); av_push(hdrs, newSVpvs("no"));
    return hdrs;
}

/* The `retry: N` field, which has to go out before anything the handler
 * writes and is the same three lines on every transport. */
static void se_send_retry(pTHX_ punk_sse *sse, HV *opts) {
    SV **r = opts ? hv_fetchs(opts, "retry", 0) : NULL;
    if (r && *r && SvOK(*r)) {
        se_field(aTHX_ sse, "retry: ", *r);   /* retry: N */
        se_write(aTHX_ sse, "\n", 1);         /* + blank = dispatch */
    }
}

/* the psgi.streaming responder: capture [ $c, $code, $opts ]. The server calls
 * it with the responder, which is the deferral a stream handle needs - so the
 * handle is tried first and the writer is the fallback. Either way the
 * handler sees one Punk::SSE and never learns which it got. */
XS_INTERNAL(sse_stream_cb);
XS_INTERNAL(sse_stream_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c    = *av_fetch(cap, 0, 0);
    SV *code = *av_fetch(cap, 1, 0);
    SV *osv  = *av_fetch(cap, 2, 0);
    SV *esv  = *av_fetch(cap, 3, 0);
    HV *opts = (SvROK(osv) && SvTYPE(SvRV(osv)) == SVt_PVHV) ? (HV *)SvRV(osv) : NULL;
    HV *envh = (SvROK(esv) && SvTYPE(SvRV(esv)) == SVt_PVHV) ? (HV *)SvRV(esv) : NULL;
    SV *responder = items > 0 ? ST(0) : &PL_sv_undef;
    AV *hdrs = se_header_av(aTHX);
    SV *self;
    punk_sse *sse;
    const hm_abi *A = NULL;
    void *loop = NULL, *h = NULL;

    if (envh) h = punk_hm_stream_open(aTHX_ envh, &A, &loop, 200, hdrs);
    if (h) {
        sse = se_new(aTHX_ SSE_MODE_HSTREAM, opts);
        sse->abi = A; sse->loop = loop; sse->sh = h;
        SvREFCNT_dec((SV *)hdrs);
        self = sv_2mortal(sv_setref_iv(newSV(0), "Punk::SSE", PTR2IV(sse)));
        sse->self_rv = newSVsv(self);
        /* before the handler writes anything: a stream reset while the
         * handler is still producing must reach it, and registering after
         * the event still fires, so there is no race to lose */
        (void)A->stream_on_abort(aTHX_ h, se_on_abort, sse);
        se_send_retry(aTHX_ sse, opts);
        se_arm_heartbeat(aTHX_ sse);
        se_run_handler(aTHX_ code, c, self);
        XSRETURN_EMPTY;
    }

    {
        AV *sh = newAV();
        SV *writer;
        dSP; int n;
        av_push(sh, newSViv(200));
        av_push(sh, newRV_noinc((SV *)hdrs));
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1);
        PUSHs(sv_2mortal(newRV_noinc((SV *)sh)));
        PUTBACK;
        n = call_sv(responder, G_SCALAR);
        SPAGAIN;
        writer = n > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
        sse = se_new(aTHX_ SSE_MODE_STREAM, opts);
        sse->writer = writer;                          /* +1 owned */
    }
    self = sv_2mortal(sv_setref_iv(newSV(0), "Punk::SSE", PTR2IV(sse)));
    sse->self_rv = newSVsv(self);
    se_send_retry(aTHX_ sse, opts);
    se_run_handler(aTHX_ code, c, self);
    XSRETURN_EMPTY;
}

/* ---- the dispatcher ------------------------------------------------------- */

static SV *punk_sse_dispatch(pTHX_ SV *c, SV *rec, SV *env) {
    HV *envh = (SvROK(env) && SvTYPE(SvRV(env)) == SVt_PVHV) ? (HV *)SvRV(env) : NULL;
    HV *rech = (SvROK(rec) && SvTYPE(SvRV(rec)) == SVt_PVHV) ? (HV *)SvRV(rec) : NULL;
    HV *opts = NULL;
    SV **x, *code;
    if (!envh || !rech) return pw_err(aTHX_ 500, "bad sse dispatch\n", NULL, NULL);
    x = hv_fetchs(rech, "sse", 0);
    if (x && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVHV) opts = (HV *)SvRV(*x);
    x = hv_fetchs(rech, K_CODE, 0);
    code = (x && *x) ? *x : &PL_sv_undef;

    /* 1. Hyperman detach: stream on the worker loop.
     *
     * A refusal falls through rather than answering 503. conn_detach says no
     * to TLS (-3) because the session state belongs to the server, and that
     * used to be the end of it - which is why deploying this meant
     * terminating TLS in front and speaking plain HTTP/1 to the application.
     * The stream handle below takes exactly that case, so the refusal is now
     * a reason to try the next transport rather than an answer to the
     * client. */
    x = hv_fetchs(envh, "psgix.hyperman.conn", 0);
    if (x && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVAV) {
        const hm_abi *A = punk_hm(aTHX);
        if (A) {
            AV *cid = (AV *)SvRV(*x);
            SV **fsv = av_fetch(cid, 0, 0), **isv = av_fetch(cid, 1, 0);
            void *loop = A->cur_loop(aTHX);
            int fd; int fl;
            punk_sse *sse; SV *self;
            if (fsv && *fsv && isv && *isv && loop
                && (fd = (int)SvIV(*fsv)) >= 0
                && A->conn_detach(aTHX_ loop, fd, SvUV(*isv)) == 0) {
                fl = fcntl(fd, F_GETFL, 0);
                if (fl >= 0) (void)fcntl(fd, F_SETFL, fl | O_NONBLOCK);
                sse = se_new(aTHX_ SSE_MODE_DETACH, opts);
                sse->fd = fd; sse->abi = A; sse->loop = loop;
                self = sv_2mortal(sv_setref_iv(newSV(0), "Punk::SSE",
                                               PTR2IV(sse)));
                sse->self_rv = newSVsv(self);
                se_write(aTHX_ sse, SSE_RESPONSE, sizeof(SSE_RESPONSE) - 1);
                se_send_retry(aTHX_ sse, opts);
                A->io_watch(aTHX_ loop, fd, HM_ABI_READ, se_on_readable, sse);
                sse->reading = 1;
                se_arm_heartbeat(aTHX_ sse);
                se_run_handler(aTHX_ code, c, self);
                return pw_empty(aTHX_ 200);     /* the socket is ours now */
            }
        }
    }

    /* 2. the deferred branch: a Hyperman v6 stream handle when the server
     * offers one (HTTP/2, and HTTP/1.1 over TLS), else the portable
     * psgi.streaming writer. sse_stream_cb decides, because the choice can
     * only be made once the response has been deferred. */
    x = hv_fetchs(envh, "psgi.streaming", 0);
    if (x && *x && SvTRUE(*x)) {
        AV *cap = newAV();
        av_push(cap, newSVsv(c));
        av_push(cap, newSVsv(code));
        av_push(cap, opts ? newRV_inc((SV *)opts) : newSV(0));
        av_push(cap, newRV_inc((SV *)envh));
        return punk_closure(aTHX_ sse_stream_cb, cap);   /* the responder */
    }

    /* 3. blocking psgix.io: stream inside the handler (pins a worker) */
    x = opts ? hv_fetchs(opts, K_BLOCKING, 0) : NULL;
    if (x && *x && SvTRUE(*x)) {
        SV **iop = hv_fetchs(envh, "psgix.io", 0);
        if (iop && *iop && SvOK(*iop)) {
            IO *io = sv_2io(*iop);
            int fd = (io && IoIFP(io)) ? PerlIO_fileno(IoIFP(io)) : -1;
            if (fd >= 0) {
                punk_sse *sse = se_new(aTHX_ SSE_MODE_BLOCK, opts);
                SV *self;
                sse->fd = fd;
                self = sv_2mortal(sv_setref_iv(newSV(0), "Punk::SSE",
                                               PTR2IV(sse)));
                sse->self_rv = newSVsv(self);
                se_write(aTHX_ sse, SSE_RESPONSE, sizeof(SSE_RESPONSE) - 1);
                se_send_retry(aTHX_ sse, opts);
                se_run_handler(aTHX_ code, c, self);     /* a sync generator */
                return pw_empty(aTHX_ 200);
            }
        }
    }

    return pw_err(aTHX_ 501,
        "this server cannot stream server-sent events (needs Hyperman "
        "0.11+, a psgi.streaming server, or blocking => 1 with psgix.io)\n",
        NULL, NULL);
}

#endif /* PUNK_SSE_H */
