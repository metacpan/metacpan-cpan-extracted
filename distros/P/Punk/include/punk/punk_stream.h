/* punk_stream.h - a streamed response for an ordinary route, in C.
 *
 * $c->stream($content_type, $cb) hands $cb a writer and emits the body as it
 * is produced: a CSV export walking a large query, an NDJSON dump - a response
 * of unknown length that should not cost its size in memory. This is the SSE
 * transport machinery (punk_sse.h) with the event framing removed: the same
 * four transports in the same order - Hyperman detach (stream on the loop),
 * the Hyperman stream handle (ABI v6, which is what serves HTTP/2 and TLS),
 * psgi.streaming (the portable delayed-response writer), and blocking
 * psgix.io - and the same pw_append / io_watch WRITE flush discipline.
 * punk_sse.h's own header explains why the handle sits under detach.
 *
 * What is new here is the ending. An SSE stream lives until someone closes
 * it; a streamed response ENDS, and how it ends must be visible to the
 * client. On the raw-socket transports the body is chunk-framed (HTTP/1.1),
 * so a clean close sends the terminal chunk and a handler that dies closes
 * the socket without one - the client sees truncation, never a valid-looking
 * short body. The contract is: the callback returning closes the stream
 * cleanly; a die closes it hard. The stream handle cannot say the second of
 * those - see pst_teardown.
 *
 * Backpressure is $w->drain: a Punk::Future settled with 1 when everything
 * written so far has reached the kernel, or 0 when the stream closed first.
 * On the detach transport a pending drain settles from the writable watcher;
 * on the stream handle it settles from the ABI's on_drain, or at once when a
 * write was taken without hitting the high-water mark; the blocking
 * transports flush synchronously, so it settles immediately.
 * Awaiting it after each write bounds the buffer to one chunk.
 *
 * Must be included after punk_wsconn.h (punk_hm, pw_append), punk_wshandshake.h
 * (pw_err / pw_empty), punk_context.h (pcx_*), punk_static.h (punk_closure)
 * and punk_future.h (pf_new / pf_settle).
 */

#ifndef PUNK_STREAM_H
#define PUNK_STREAM_H

#include <fcntl.h>

enum { PST_MODE_DETACH = 0, PST_MODE_STREAM = 1, PST_MODE_BLOCK = 2,
       PST_MODE_HSTREAM = 3 };
enum { PST_OPEN = 0, PST_CLOSING = 1, PST_CLOSED = 2 };

typedef struct punk_stream {
    int    fd;                    /* detach / block; -1 for a psgi writer */
    int    mode;
    int    state;
    unsigned char reading, writing, in_teardown, chunked;
    unsigned char ending_clean;   /* pst_close set this; anything else is a
                                   * body that stopped rather than finished */
    char  *wbuf; size_t wlen, woff, wcap;
    size_t write_buffer_limit;    /* 0 = unbounded; over it, teardown */
    SV    *writer;                /* the psgi.streaming $writer (STREAM mode) */
    SV    *self_rv;               /* strong self while live */
    SV    *drain_f;               /* the pending drain future, or NULL */
    SV    *reqid;                 /* psgix.request_id for the death report */
    SV    *defer_c, *defer_code, *defer_head;   /* the deferred detach start */
    hm_abi_timer *defer_tw;
    void  *loop;
    const hm_abi *abi;
    void  *sh;                    /* the v6 stream handle (HSTREAM mode) */
} punk_stream;

static punk_stream *pst_of(pTHX_ SV *self) {
    if (!SvROK(self) || !SvIOK(SvRV(self)))
        croak("Punk::Stream: not a stream");
    return (punk_stream *)INT2PTR(void *, SvIV(SvRV(self)));
}

static void pst_teardown(pTHX_ punk_stream *st);
static void pst_on_writable(pTHX_ int fd, int mask, void *ud);
static void pst_on_hdrain(pTHX_ void *h, void *ud);
static void pst_on_habort(pTHX_ void *h, void *ud);

/* settle the pending drain future, if any. ok is 1 (drained) or 0 (closed
 * first). The local copy matters: settling fires reactions that can call back
 * into this stream and ask for another drain. */
static void pst_settle_drain(pTHX_ punk_stream *st, int ok) {
    SV *f = st->drain_f;
    AV *vals;
    if (!f) return;
    st->drain_f = NULL;
    vals = newAV();
    av_push(vals, newSViv(ok));
    pf_settle(aTHX_ pf_of(aTHX_ f), f, PF_DONE, vals);
    SvREFCNT_dec(f);
}

/* ---- writing (DETACH / BLOCK): the punk_sse.h flush, plus two endings ------ */

static void pst_flush(pTHX_ punk_stream *st) {
    while (st->woff < st->wlen) {
        ssize_t n = write(st->fd, st->wbuf + st->woff, st->wlen - st->woff);
        if (n > 0) { st->woff += (size_t)n; continue; }
        if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            if (st->mode == PST_MODE_DETACH) {
                if (!st->writing && st->abi && st->loop) {
                    st->abi->io_watch(aTHX_ st->loop, st->fd, HM_ABI_WRITE,
                                      pst_on_writable, st);
                    st->writing = 1;
                }
                return;
            }
            {   /* blocking transport over a socket the server left
                 * non-blocking: wait for writability rather than spinning.
                 * SSE's writes were small enough never to meet this; an
                 * export is not. */
                fd_set wf;
                FD_ZERO(&wf);
                FD_SET(st->fd, &wf);
                (void)select(st->fd + 1, NULL, &wf, NULL, NULL);
                continue;
            }
        }
        if (n < 0 && errno == EINTR) continue;
        pst_teardown(aTHX_ st);                  /* write error: client gone */
        return;
    }
    st->wlen = st->woff = 0;
    if (st->writing && st->abi && st->loop) {
        st->abi->io_unwatch(aTHX_ st->loop, st->fd, HM_ABI_WRITE);
        st->writing = 0;
    }
    pst_settle_drain(aTHX_ st, 1);
    if (st->state == PST_CLOSING) pst_teardown(aTHX_ st);   /* fully sent */
}

static void pst_on_writable(pTHX_ int fd, int mask, void *ud) {
    PERL_UNUSED_ARG(fd); PERL_UNUSED_ARG(mask);
    pst_flush(aTHX_ (punk_stream *)ud);
}

/* ---- the stream handle's two callbacks ------------------------------------- */

/* Output that was over the high-water mark has gone out. This is what makes
 * $w->drain mean the same thing on the handle as on the detach transport:
 * settled with 1 when everything written so far has actually left. */
static void pst_on_hdrain(pTHX_ void *h, void *ud) {
    punk_stream *st = (punk_stream *)ud;
    PERL_UNUSED_ARG(h);
    pst_settle_drain(aTHX_ st, 1);
}

/* The stream died before it was closed - an HTTP/2 RST_STREAM on this one
 * stream of many, or the connection going away. Detach had no way to report
 * the first of those, because on HTTP/1 a reset stream IS a dead connection;
 * on a multiplexed transport it is not, and a producer that is not told goes
 * on generating a body for nobody. Teardown settles the drain future with 0,
 * so a handler awaiting it stops rather than blocking for ever. */
static void pst_on_habort(pTHX_ void *h, void *ud) {
    punk_stream *st = (punk_stream *)ud;
    PERL_UNUSED_ARG(h);
    pst_teardown(aTHX_ st);
}

/* the client closing early is the only thing we read for */
static void pst_on_readable(pTHX_ int fd, int mask, void *ud) {
    punk_stream *st = (punk_stream *)ud;
    char scratch[512];
    ssize_t n;
    PERL_UNUSED_ARG(fd); PERL_UNUSED_ARG(mask);
    n = read(st->fd, scratch, sizeof scratch);
    if (n == 0) { pst_teardown(aTHX_ st); return; }
    if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR))
        return;
    if (n < 0) pst_teardown(aTHX_ st);
    /* n > 0: bytes on a response stream are the client's mistake; ignored */
}

/* queue raw bytes (already framed) to the socket transports */
static void pst_write_raw(pTHX_ punk_stream *st, const char *bytes, size_t len) {
    if (st->write_buffer_limit
        && st->wlen - st->woff + len > st->write_buffer_limit) {
        pst_teardown(aTHX_ st);                  /* a client that will not read */
        return;
    }
    pw_append(&st->wbuf, &st->wlen, &st->wcap, bytes, len);
    pst_flush(aTHX_ st);
}

/* one body chunk, framed for the transport */
static void pst_write_body(pTHX_ punk_stream *st, const char *bytes, size_t len) {
    if (st->state != PST_OPEN || len == 0) return;
    if (st->mode == PST_MODE_HSTREAM) {
        /* Unframed: the transport frames it. HTTP/2 puts the bytes in a DATA
         * frame and HTTP/1.1 delimits by close, so a chunk header written
         * here would be body content on one and a lie on the other.
         *
         * The reference is held across the call because ending the body can
         * close the connection, and Hyperman fires the abort callback from
         * there - which tears this stream down and drops its own last
         * reference. */
        SV *keep = st->self_rv ? SvREFCNT_inc(st->self_rv) : NULL;
        int r = st->abi->stream_write(aTHX_ st->sh, bytes, len);
        if (r < 0) {
            if (st->state == PST_OPEN) pst_teardown(aTHX_ st);
        }
        else if (r == HM_ABI_STREAM_FULL) {
            /* over the high-water mark: on_drain settles the drain future,
             * which is how $w->drain becomes real backpressure here */
            (void)st->abi->stream_on_drain(aTHX_ st->sh, pst_on_hdrain, st);
        }
        else pst_settle_drain(aTHX_ st, 1);       /* all of it is away */
        if (keep) SvREFCNT_dec(keep);             /* st may be gone now */
        return;
    }
    if (st->mode == PST_MODE_STREAM) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 2);
        PUSHs(st->writer ? st->writer : &PL_sv_undef);
        PUSHs(sv_2mortal(newSVpvn(bytes, len)));
        PUTBACK;
        call_method("write", G_DISCARD | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) { FREETMPS; LEAVE; pst_teardown(aTHX_ st); return; }
        PUTBACK; FREETMPS; LEAVE;
        return;
    }
    if (st->chunked) {
        char pre[24];
        /* the size goes through its own variable: where perl expands
         * my_snprintf to a gcc statement expression, that expression declares
         * its own `len' from the snprintf return, and a `len' written in the
         * argument list resolves to that one - still uninitialised inside its
         * own initialiser. Every chunk header then reads the stack. */
        UV chunk_len = (UV)len;
        int n = my_snprintf(pre, sizeof pre, "%" UVxf "\r\n", chunk_len);
        if (st->write_buffer_limit
            && st->wlen - st->woff + len + (size_t)n + 2 > st->write_buffer_limit) {
            pst_teardown(aTHX_ st);
            return;
        }
        pw_append(&st->wbuf, &st->wlen, &st->wcap, pre, (size_t)n);
        pw_append(&st->wbuf, &st->wlen, &st->wcap, bytes, len);
        pw_append(&st->wbuf, &st->wlen, &st->wcap, "\r\n", 2);
        pst_flush(aTHX_ st);
        return;
    }
    pst_write_raw(aTHX_ st, bytes, len);
}

/* ---- teardown and the two closes ------------------------------------------- */

/* the hard stop: nothing more is sent, so on a chunked transport the client
 * sees a missing terminal chunk - truncation, not a short success.
 *
 * The stream handle says the same thing through stream_abort (hm_abi.h v7),
 * which is why `ending_clean` exists: pst_close sets it and every other way
 * of getting here leaves it clear. A streamed body has no declared length, so
 * ending cleanly IS the claim that it is whole - the two endings are the only
 * way a client can tell an export that finished from one whose query died on
 * the last page. */
static void pst_teardown(pTHX_ punk_stream *st) {
    if (st->in_teardown || st->state == PST_CLOSED) return;
    st->in_teardown = 1;
    if (st->mode == PST_MODE_DETACH && st->abi && st->loop) {
        if (st->reading) st->abi->io_unwatch(aTHX_ st->loop, st->fd, HM_ABI_READ);
        if (st->writing) st->abi->io_unwatch(aTHX_ st->loop, st->fd, HM_ABI_WRITE);
    }
    if (st->mode == PST_MODE_HSTREAM && st->abi && st->sh) {
        /* NULLed first: ending the body can close the connection, and the
         * teardown that re-enters from there must not end it twice */
        void *h = st->sh;
        st->sh = NULL;
        if (st->ending_clean) (void)st->abi->stream_close(aTHX_ h);
        else                  (void)st->abi->stream_abort(aTHX_ h);
    }
    st->reading = st->writing = 0;
    if (st->mode == PST_MODE_STREAM && st->writer) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(st->writer); PUTBACK;
        call_method("close", G_DISCARD | G_EVAL);
        SPAGAIN; PUTBACK; FREETMPS; LEAVE;
    }
    if (st->fd >= 0) { close(st->fd); st->fd = -1; }
    st->state = PST_CLOSED;
    pst_settle_drain(aTHX_ st, 0);
    st->in_teardown = 0;
    if (st->self_rv) { SV *s = st->self_rv; st->self_rv = NULL; SvREFCNT_dec(s); }
}

/* the clean end: terminal chunk, then teardown once every byte is out. On the
 * detach transport a still-loaded buffer keeps draining on the loop (the
 * stream holds itself alive until it has); the blocking transports flush here. */
static void pst_close(pTHX_ punk_stream *st) {
    if (st->state != PST_OPEN) return;
    if (st->mode == PST_MODE_STREAM || st->mode == PST_MODE_HSTREAM) {
        /* teardown does the ending; this is the one caller that gets to call
         * it a clean one, and there is no half-sent buffer of ours to drain */
        st->ending_clean = 1;
        pst_teardown(aTHX_ st);
        return;
    }
    st->state = PST_CLOSING;
    if (st->chunked)
        pw_append(&st->wbuf, &st->wlen, &st->wcap, "0\r\n\r\n", 5);
    pst_flush(aTHX_ st);        /* teardown fires from here once drained */
}

static void pst_free(pTHX_ punk_stream *st) {
    if (!st) return;
    if (st->mode == PST_MODE_DETACH && st->abi && st->loop) {
        /* watchers name this struct, so they go before it - and before the
         * fd, or the loop watches a number the next connection gets */
        if (st->reading) st->abi->io_unwatch(aTHX_ st->loop, st->fd, HM_ABI_READ);
        if (st->writing) st->abi->io_unwatch(aTHX_ st->loop, st->fd, HM_ABI_WRITE);
    }
    if (st->defer_tw && st->abi && st->loop)
        st->abi->timer_cancel(aTHX_ st->loop, st->defer_tw);
    /* The handle's callbacks name this struct, so it goes before the struct
     * does. Reaching here with one still open means nobody ended the body on
     * purpose, so it is aborted rather than closed: an ending nobody asked
     * for is not a claim that the response is whole. */
    if (st->mode == PST_MODE_HSTREAM && st->abi && st->sh)
        (void)st->abi->stream_abort(aTHX_ st->sh);
    if (st->fd >= 0)  close(st->fd);
    if (st->wbuf)     free(st->wbuf);
    if (st->writer)   SvREFCNT_dec(st->writer);
    if (st->drain_f)  SvREFCNT_dec(st->drain_f);
    if (st->reqid)    SvREFCNT_dec(st->reqid);
    if (st->defer_c)    SvREFCNT_dec(st->defer_c);
    if (st->defer_code) SvREFCNT_dec(st->defer_code);
    if (st->defer_head) SvREFCNT_dec(st->defer_head);
    if (st->self_rv)  SvREFCNT_dec(st->self_rv);
    Safefree(st);
}

/* ---- construction, the head, the handler ---------------------------------- */

static punk_stream *pst_new(pTHX_ int mode, HV *opts) {
    punk_stream *st;
    Newxz(st, 1, punk_stream);
    st->fd = -1;
    st->mode = mode;
    st->state = PST_OPEN;
    if (opts) {
        SV **w = hv_fetchs(opts, "write_buffer_limit", 0);
        if (w && *w && SvOK(*w)) st->write_buffer_limit = (size_t)SvUV(*w);
    }
    return st;
}

static IV pst_opt_status(pTHX_ HV *opts) {
    SV **s = opts ? hv_fetchs(opts, "status", 0) : NULL;
    return (s && *s && SvOK(*s)) ? SvIV(*s) : 200;
}
static AV *pst_opt_headers(pTHX_ HV *opts) {
    SV **h = opts ? hv_fetchs(opts, "headers", 0) : NULL;
    return (h && *h && SvROK(*h) && SvTYPE(SvRV(*h)) == SVt_PVAV)
        ? (AV *)SvRV(*h) : NULL;
}

/* an empty reason-phrase is valid HTTP; 200 keeps its customary one */
static const char *pst_phrase(IV status) {
    return status == 200 ? "OK" : "";
}

/* the raw response head for the socket transports */
static SV *pst_head(pTHX_ punk_stream *st, SV *ct, HV *opts) {
    IV status = pst_opt_status(aTHX_ opts);
    AV *extra = pst_opt_headers(aTHX_ opts);
    SV *head = sv_2mortal(newSVpvf("HTTP/1.1 %" IVdf " %s\r\nContent-Type: ",
                                   status, pst_phrase(status)));
    sv_catsv(head, ct);
    sv_catpvs(head, "\r\n");
    if (extra) {
        SSize_t i, n = av_len(extra) + 1;
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(extra, i, 0);
            SV **v = av_fetch(extra, i + 1, 0);
            if (!(k && *k && v && *v)) continue;
            sv_catsv(head, *k);
            sv_catpvs(head, ": ");
            sv_catsv(head, *v);
            sv_catpvs(head, "\r\n");
        }
    }
    if (st->chunked) sv_catpvs(head, "Transfer-Encoding: chunked\r\n");
    sv_catpvs(head, "Connection: close\r\nX-Accel-Buffering: no\r\n\r\n");
    return head;
}

/* Run $code->($c, $w). The callback returning is the clean end; a die is the
 * hard one - the head is already on the wire, so there is no error response
 * to send, and on a chunked transport the missing terminal chunk is the
 * client's evidence. The report carries the request id when one exists. */
static void pst_run_handler(pTHX_ SV *code, SV *c, SV *self) {
    dSP; int died;
    punk_stream *st;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 2); PUSHs(c); PUSHs(self); PUTBACK;
    call_sv(code, G_DISCARD | G_EVAL);
    SPAGAIN;
    died = SvTRUE(ERRSV) ? 1 : 0;
    PUTBACK; FREETMPS; LEAVE;
    st = pst_of(aTHX_ self);
    if (died) {
        if (st->reqid)
            warn("Punk::Stream: handler died (request %" SVf "): %" SVf,
                 SVfARG(st->reqid), SVfARG(ERRSV));
        else
            warn("Punk::Stream: handler died: %" SVf, SVfARG(ERRSV));
        pst_teardown(aTHX_ st);
        return;
    }
    pst_close(aTHX_ st);
}

/* The deferred half of the detach transport. Hyperman's detach is two-phase:
 * hm_detach disarms the server's watchers at once, but the connection slot is
 * only released after the app frame returns its sentinel - and the event
 * dispatch routes an fd to the application's watchers only once that slot is
 * empty. A handler that produced the whole body synchronously would arm its
 * write watcher against a slot still naming the server's connection, and the
 * first EAGAIN would stall the stream forever. So the detach transport starts
 * on the next loop tick, after the sentinel has made it home.
 *
 * The self-reference is held across the run: the handler can tear the stream
 * down (client gone), and teardown drops the stream's own reference - the
 * last one, here. The SSE heartbeat learned this the hard way. */
static void pst_start_cb(pTHX_ void *ud) {
    punk_stream *st = (punk_stream *)ud;
    SV *keep = st->self_rv ? SvREFCNT_inc(st->self_rv) : NULL;
    SV *c = st->defer_c, *code = st->defer_code, *head = st->defer_head;
    st->defer_tw = NULL;                    /* it fired; nothing to cancel */
    st->defer_c = st->defer_code = st->defer_head = NULL;
    if (st->state == PST_OPEN) {
        pst_write_raw(aTHX_ st, SvPVX(head), SvCUR(head));
        if (st->state == PST_OPEN) {
            st->abi->io_watch(aTHX_ st->loop, st->fd, HM_ABI_READ,
                              pst_on_readable, st);
            st->reading = 1;
            pst_run_handler(aTHX_ code, c, st->self_rv ? st->self_rv : keep);
        }
    }
    SvREFCNT_dec(c);
    SvREFCNT_dec(code);
    SvREFCNT_dec(head);
    if (keep) SvREFCNT_dec(keep);           /* st may be gone after this */
}

/* The response head as a structured header list rather than the pst_head byte
 * string. Content-Type and the caller's own headers carry over; Connection
 * and Transfer-Encoding do NOT. Both are hop-by-hop, HTTP/2 and HTTP/3 forbid
 * them, and framing is the transport's job on every version this branch
 * serves - HTTP/1.1 over TLS included, where Hyperman delimits by close.
 * pst_phrase has nothing to do here either: a header list carries the status
 * and never a reason phrase. Owned (+1). */
static AV *pst_header_av(pTHX_ SV *ct, HV *opts) {
    AV *hdrs = newAV(), *extra = pst_opt_headers(aTHX_ opts);
    av_push(hdrs, newSVpvs("Content-Type"));      av_push(hdrs, newSVsv(ct));
    if (extra) {
        SSize_t i, n = av_len(extra) + 1;
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(extra, i, 0);
            SV **v = av_fetch(extra, i + 1, 0);
            if (!(k && *k && v && *v)) continue;
            av_push(hdrs, newSVsv(*k));
            av_push(hdrs, newSVsv(*v));
        }
    }
    av_push(hdrs, newSVpvs("X-Accel-Buffering")); av_push(hdrs, newSVpvs("no"));
    return hdrs;
}

/* the psgi.streaming responder: capture [ $c, $code, $ct, $opts, $reqid, $env ].
 * The responder IS the deferral a stream handle needs, so the handle is tried
 * first here and the portable writer is the fallback. */
XS_INTERNAL(pst_stream_cb);
XS_INTERNAL(pst_stream_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c    = *av_fetch(cap, 0, 0);
    SV *code = *av_fetch(cap, 1, 0);
    SV *ct   = *av_fetch(cap, 2, 0);
    SV *osv  = *av_fetch(cap, 3, 0);
    SV *rid  = *av_fetch(cap, 4, 0);
    SV *esv  = *av_fetch(cap, 5, 0);
    HV *opts = (SvROK(osv) && SvTYPE(SvRV(osv)) == SVt_PVHV) ? (HV *)SvRV(osv) : NULL;
    HV *envh = (SvROK(esv) && SvTYPE(SvRV(esv)) == SVt_PVHV) ? (HV *)SvRV(esv) : NULL;
    SV *responder = items > 0 ? ST(0) : &PL_sv_undef;
    AV *hdrs = pst_header_av(aTHX_ ct, opts);
    IV status = pst_opt_status(aTHX_ opts);
    SV *self;
    punk_stream *st;
    const hm_abi *A = NULL;
    void *loop = NULL, *h = NULL;

    if (envh) h = punk_hm_stream_open(aTHX_ envh, &A, &loop, (int)status, hdrs);
    if (h) {
        st = pst_new(aTHX_ PST_MODE_HSTREAM, opts);
        st->abi = A; st->loop = loop; st->sh = h;
        SvREFCNT_dec((SV *)hdrs);
        if (SvOK(rid)) st->reqid = newSVsv(rid);
        self = sv_2mortal(sv_setref_iv(newSV(0), "Punk::Stream", PTR2IV(st)));
        st->self_rv = newSVsv(self);
        /* before the handler produces anything: a reset while it is still
         * writing must reach it, and registering after the event still fires */
        (void)A->stream_on_abort(aTHX_ h, pst_on_habort, st);
        pst_run_handler(aTHX_ code, c, self);
        XSRETURN_EMPTY;
    }

    {
        AV *sh = newAV();
        SV *writer;
        dSP; int n;
        av_push(sh, newSViv(status));
        av_push(sh, newRV_noinc((SV *)hdrs));
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1);
        PUSHs(sv_2mortal(newRV_noinc((SV *)sh)));
        PUTBACK;
        n = call_sv(responder, G_SCALAR);
        SPAGAIN;
        writer = n > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
        st = pst_new(aTHX_ PST_MODE_STREAM, opts);
        st->writer = writer;                       /* +1 owned */
    }
    if (SvOK(rid)) st->reqid = newSVsv(rid);
    self = sv_2mortal(sv_setref_iv(newSV(0), "Punk::Stream", PTR2IV(st)));
    st->self_rv = newSVsv(self);
    pst_run_handler(aTHX_ code, c, self);
    XSRETURN_EMPTY;
}

/* ---- $c->stream ------------------------------------------------------------ */

static SV *punk_stream_start(pTHX_ SV *c, SV *ct, HV *opts, SV *code) {
    AV *cav = pcx_av(aTHX_ c);
    SV *envsv = pcx_get(aTHX_ cav, PCX_ENV);
    HV *envh = (envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV)
               ? (HV *)SvRV(envsv) : NULL;
    SV **x, *rid;
    int chunked = 1;
    if (!envh) return pw_err(aTHX_ 500, "bad stream dispatch\n", NULL, NULL);

    /* Chunked framing is an HTTP/1.1 thing and only an HTTP/1.1 thing.
     * HTTP/1.0 has no chunked transfer coding; HTTP/2 and HTTP/3 forbid the
     * header and frame the body themselves. So the test names the one version
     * that wants it rather than the one that does not - "anything but
     * HTTP/1.0" put a Transfer-Encoding on an h2 response, and Hyperman spells
     * its h2 protocol "HTTP/2" (six bytes, not "HTTP/2.0"), so no amount of
     * widening the excluded literal would have caught it.
     *
     * A missing SERVER_PROTOCOL is HTTP/1.1: PSGI requires the key, and a
     * synthetic environment that omits it is a test writing HTTP/1.1. */
    x = hv_fetchs(envh, "SERVER_PROTOCOL", 0);
    if (x && *x && SvOK(*x)) {
        STRLEN pl;
        const char *p = SvPV_const(*x, pl);
        chunked = (pl == 8 && memEQ(p, "HTTP/1.1", 8));
    }
    x = hv_fetchs(envh, "psgix.request_id", 0);
    rid = (x && *x && SvOK(*x)) ? *x : NULL;

    /* 1. Hyperman detach: stream on the worker loop.
     *
     * A refusal falls through rather than answering 503: conn_detach says no
     * to TLS, and the stream handle below is exactly what serves that case. */
    x = hv_fetchs(envh, "psgix.hyperman.conn", 0);
    if (x && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVAV) {
        const hm_abi *A = punk_hm(aTHX);
        if (A) {
            AV *cid = (AV *)SvRV(*x);
            SV **fsv = av_fetch(cid, 0, 0), **isv = av_fetch(cid, 1, 0);
            void *loop = A->cur_loop(aTHX);
            int fd; int fl;
            punk_stream *st; SV *self;
            if (fsv && *fsv && isv && *isv && loop
                && (fd = (int)SvIV(*fsv)) >= 0
                && A->conn_detach(aTHX_ loop, fd, SvUV(*isv)) == 0) {
                fl = fcntl(fd, F_GETFL, 0);
                if (fl >= 0) (void)fcntl(fd, F_SETFL, fl | O_NONBLOCK);
                st = pst_new(aTHX_ PST_MODE_DETACH, opts);
                st->fd = fd; st->abi = A; st->loop = loop;
                st->chunked = (unsigned char)chunked;
                if (rid) st->reqid = newSVsv(rid);
                self = sv_2mortal(sv_setref_iv(newSV(0), "Punk::Stream", PTR2IV(st)));
                st->self_rv = newSVsv(self);
                st->defer_c    = newSVsv(c);
                st->defer_code = newSVsv(code);
                st->defer_head = newSVsv(pst_head(aTHX_ st, ct, opts));
                st->defer_tw   = A->timer(aTHX_ loop, 0.0, pst_start_cb, st);
                return pw_empty(aTHX_ 200);      /* the socket is ours now */
            }
        }
    }

    /* 2. the deferred branch: a Hyperman v6 stream handle when the server
     * offers one (HTTP/2, and HTTP/1.1 over TLS), else the portable
     * psgi.streaming writer. pst_stream_cb decides, because a handle can
     * only be opened once the response has been deferred. */
    x = hv_fetchs(envh, "psgi.streaming", 0);
    if (x && *x && SvTRUE(*x)) {
        AV *cap = newAV();
        av_push(cap, newSVsv(c));
        av_push(cap, newSVsv(code));
        av_push(cap, newSVsv(ct));
        av_push(cap, opts ? newRV_inc((SV *)opts) : newSV(0));
        av_push(cap, rid ? newSVsv(rid) : newSV(0));
        av_push(cap, newRV_inc((SV *)envh));
        return punk_closure(aTHX_ pst_stream_cb, cap);   /* the responder */
    }

    /* 3. blocking psgix.io: stream inside the handler (pins a worker) */
    x = opts ? hv_fetchs(opts, "blocking", 0) : NULL;
    if (x && *x && SvTRUE(*x)) {
        SV **iop = hv_fetchs(envh, "psgix.io", 0);
        if (iop && *iop && SvOK(*iop)) {
            IO *io = sv_2io(*iop);
            int fd = (io && IoIFP(io)) ? PerlIO_fileno(IoIFP(io)) : -1;
            if (fd >= 0) {
                punk_stream *st = pst_new(aTHX_ PST_MODE_BLOCK, opts);
                SV *self, *head;
                st->fd = fd; st->chunked = (unsigned char)chunked;
                if (rid) st->reqid = newSVsv(rid);
                self = sv_2mortal(sv_setref_iv(newSV(0), "Punk::Stream", PTR2IV(st)));
                st->self_rv = newSVsv(self);
                head = pst_head(aTHX_ st, ct, opts);
                pst_write_raw(aTHX_ st, SvPVX(head), SvCUR(head));
                pst_run_handler(aTHX_ code, c, self);
                return pw_empty(aTHX_ 200);
            }
        }
    }

    return pw_err(aTHX_ 501,
        "this server cannot stream a response (needs Hyperman 0.11+, a "
        "psgi.streaming server, or blocking => 1 with psgix.io)\n",
        NULL, NULL);
}

#endif /* PUNK_STREAM_H */
