/* punk_wsconn.h - the live WebSocket connection.
 *
 * Drives the frame codec (punk_ws.h) over one socket the application owns
 * after Hyperman::detach, watching it on the worker loop through Hyperman's
 * C ABI (hm_abi.h, via ExtUtils::Depends). Reads, unmasks, reassembles,
 * answers pings and runs the closing handshake entirely in C; Perl is
 * entered only to deliver a completed message or a lifecycle event.
 *
 * The object is a blessed IV-ref to a punk_wsconn (the Punk::Router
 * precedent - a C-buffer-heavy object rather than a slot AV). It holds a
 * strong reference to itself while the socket is live, so a handler that
 * wires callbacks and returns does not take the connection down with its
 * lexicals; teardown drops it.
 */

#ifndef PUNK_WSCONN_H
#define PUNK_WSCONN_H

#define PW_ST_CONNECTING 0
#define PW_ST_OPEN       1
#define PW_ST_CLOSING    2
#define PW_ST_CLOSED     3

#define PW_DEFAULT_MAX_MESSAGE (16 * 1024 * 1024)
#define PW_DEFAULT_WRITE_LIMIT (16 * 1024 * 1024)
#define PW_READ_CHUNK          16384
#define PW_CLOSE_TIMEOUT       10.0

typedef struct punk_wsconn {
    int    fd;
    int    state;
    int    blocking;              /* opt-in fallback: no loop, no watchers */
    unsigned char reading, writing, close_sent, close_rcvd, in_teardown;

    char  *rbuf; size_t rlen, rcap;
    char  *wbuf; size_t wlen, woff, wcap;

    char  *frag; size_t fraglen, fragcap;   /* message reassembly */
    unsigned char frag_op, frag_active;
    pw_utf8 utf8;                           /* across text fragments */

    size_t max_message_size, write_buffer_limit;

    uint16_t peer_code;
    SV    *peer_reason;
    SV    *protocol;
    HV    *cbs;                   /* event name -> coderef */
    SV    *self_rv;               /* strong self-ref while live */

    void  *loop;                  /* hm_loop*, borrowed */
    const hm_abi *abi;
    hm_abi_timer *close_tw;
} punk_wsconn;

/* ---- Hyperman's ABI, resolved once (the punk_dispatch.h idiom) ----------- */

static const hm_abi *PUNK_HM = NULL;
static int PUNK_HM_TRIED = 0;

/* NULL means "no detach seam": websocket routes then need blocking mode.
 * PUNK_NO_HM_ABI forces that path for tests. */
static const hm_abi *punk_hm(pTHX) {
    if (getenv("PUNK_NO_HM_ABI")) return NULL;
    if (!PUNK_HM_TRIED) {
        dSP; int count, ok; IV p = 0;
        PUNK_HM_TRIED = 1;
        ok = pk_require_once(aTHX_ "Hyperman", FALSE);
        SPAGAIN;   /* the require may have reallocated the value stack */
        if (ok) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("Hyperman::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const hm_abi *a = INT2PTR(const hm_abi *, p);
                /* >= : the table only grows at its tail, so a later
                 * Hyperman still satisfies what we compiled against */
                if (a && a->abi_version >= HM_ABI_VERSION) PUNK_HM = a;
            }
        }
    }
    return PUNK_HM;
}

/* ---- small buffer helpers ------------------------------------------------ */

static void pw_buf_reserve(char **buf, size_t *cap, size_t need) {
    if (*cap >= need) return;
    {
        size_t n = *cap ? *cap : 1024;
        while (n < need) n *= 2;
        *buf = (char *)realloc(*buf, n);
        if (!*buf) croak("Punk::WebSocket: out of memory");
        *cap = n;
    }
}

static void pw_append(char **buf, size_t *len, size_t *cap,
                      const char *src, size_t n) {
    pw_buf_reserve(buf, cap, *len + n);
    memcpy(*buf + *len, src, n);
    *len += n;
}

/* ---- event dispatch ------------------------------------------------------
 * The ABI contract is that C callbacks must not croak, so every call into
 * Perl is trapped. A handler that dies surfaces as the error event and
 * closes the connection with 1011. */

static void pw_queue_frame(pTHX_ punk_wsconn *ws, unsigned char op,
                           const char *payload, size_t len);
static void pw_fail(pTHX_ punk_wsconn *ws, uint16_t code, const char *why);
static void pw_teardown(pTHX_ punk_wsconn *ws, uint16_t code,
                        const char *reason, size_t rlen);
static void pw_flush(pTHX_ punk_wsconn *ws);

static SV *pw_cb(pTHX_ punk_wsconn *ws, const char *name) {
    SV **e;
    if (!ws->cbs) return NULL;
    e = hv_fetch(ws->cbs, name, (I32)strlen(name), 0);
    return (e && *e && SvROK(*e)) ? *e : NULL;
}

/* Fire an event with (self, @args). Returns 0 if a handler died. */
static int pw_emit(pTHX_ punk_wsconn *ws, const char *name,
                   SV **args, int nargs) {
    SV *cb = pw_cb(aTHX_ ws, name);
    dSP;
    int i, died;
    if (!cb) return 1;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, nargs + 1);
    PUSHs(ws->self_rv ? ws->self_rv : &PL_sv_undef);
    for (i = 0; i < nargs; i++) PUSHs(args[i]);
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    SPAGAIN;
    died = SvTRUE(ERRSV) ? 1 : 0;
    if (died) {
        SV *err = newSVsv(ERRSV);
        SV *ecb = pw_cb(aTHX_ ws, "error");
        if (ecb && strNE(name, "error")) {
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(ws->self_rv ? ws->self_rv : &PL_sv_undef);
            PUSHs(sv_2mortal(err));
            PUTBACK;
            call_sv(ecb, G_DISCARD | G_EVAL);
            SPAGAIN;
            (void)SvTRUE(ERRSV);      /* an error handler that dies: give up */
        }
        else {
            PerlIO_printf(PerlIO_stderr(),
                          "Punk::WebSocket: %s handler died: %s",
                          name, SvPV_nolen(err));
            SvREFCNT_dec(err);
        }
    }
    PUTBACK;
    FREETMPS; LEAVE;
    return !died;
}

/* ---- writing -------------------------------------------------------------
 * Everything queues; pw_flush drains what the socket will take and arms a
 * write watcher for the rest. A peer that will not read cannot stall the
 * worker, and cannot make us drop bytes mid-frame either. */

static void pw_on_writable(pTHX_ int fd, int mask, void *ud);

static void pw_flush(pTHX_ punk_wsconn *ws) {
    while (ws->woff < ws->wlen) {
        ssize_t n = write(ws->fd, ws->wbuf + ws->woff, ws->wlen - ws->woff);
        if (n > 0) { ws->woff += (size_t)n; continue; }
        if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            if (!ws->writing && !ws->blocking && ws->abi && ws->loop) {
                ws->abi->io_watch(aTHX_ ws->loop, ws->fd, HM_ABI_WRITE,
                                  pw_on_writable, ws);
                ws->writing = 1;
            }
            return;
        }
        if (n < 0 && errno == EINTR) continue;
        pw_teardown(aTHX_ ws, PW_CLOSE_ABNORMAL, NULL, 0);   /* write error */
        return;
    }
    ws->wlen = ws->woff = 0;
    if (ws->writing && ws->abi && ws->loop) {
        ws->abi->io_unwatch(aTHX_ ws->loop, ws->fd, HM_ABI_WRITE);
        ws->writing = 0;
    }
    /* the closing handshake is done once our close frame is on the wire */
    if (ws->state == PW_ST_CLOSING && ws->close_sent && ws->close_rcvd)
        pw_teardown(aTHX_ ws, 0, NULL, 0);
}

static void pw_on_writable(pTHX_ int fd, int mask, void *ud) {
    punk_wsconn *ws = (punk_wsconn *)ud;
    PERL_UNUSED_ARG(fd); PERL_UNUSED_ARG(mask);
    pw_flush(aTHX_ ws);
}

static void pw_queue_frame(pTHX_ punk_wsconn *ws, unsigned char op,
                           const char *payload, size_t len) {
    char hdr[10];
    size_t hn;
    if (ws->state == PW_ST_CLOSED) return;
    if (ws->write_buffer_limit
        && ws->wlen - ws->woff + len > ws->write_buffer_limit) {
        pw_fail(aTHX_ ws, PW_CLOSE_POLICY_VIOLATION, "send buffer full");
        return;
    }
    hn = pw_encode_header(hdr, op, 1, len);
    pw_append(&ws->wbuf, &ws->wlen, &ws->wcap, hdr, hn);
    if (len) pw_append(&ws->wbuf, &ws->wlen, &ws->wcap, payload, len);
    pw_flush(aTHX_ ws);
}

static void pw_queue_close(pTHX_ punk_wsconn *ws, uint16_t code,
                           const char *reason, size_t rlen) {
    char body[2 + PW_MAX_REASON];
    size_t blen;
    if (ws->close_sent || ws->state == PW_ST_CLOSED) return;
    blen = pw_close_payload(body, code, reason, rlen);
    ws->close_sent = 1;
    if (ws->state == PW_ST_OPEN) ws->state = PW_ST_CLOSING;
    pw_queue_frame(aTHX_ ws, PW_OP_CLOSE, body, blen);
}

/* A protocol failure: tell the peer why, then close. */
static void pw_fail(pTHX_ punk_wsconn *ws, uint16_t code, const char *why) {
    if (ws->state == PW_ST_CLOSED || ws->in_teardown) return;
    {
        SV *msg = sv_2mortal(newSVpv(why ? why : "protocol error", 0));
        SV *a[1]; a[0] = msg;
        (void)pw_emit(aTHX_ ws, "error", a, 1);
    }
    pw_queue_close(aTHX_ ws, code, why, why ? strlen(why) : 0);
    /* do not wait for the peer's echo after a protocol failure */
    pw_teardown(aTHX_ ws, code, why, why ? strlen(why) : 0);
}

/* ---- teardown ------------------------------------------------------------ */

static void pw_teardown(pTHX_ punk_wsconn *ws, uint16_t code,
                        const char *reason, size_t rlen) {
    SV *args[2];
    if (ws->in_teardown || ws->state == PW_ST_CLOSED) return;
    ws->in_teardown = 1;

    if (ws->abi && ws->loop && !ws->blocking) {
        if (ws->reading) ws->abi->io_unwatch(aTHX_ ws->loop, ws->fd, HM_ABI_READ);
        if (ws->writing) ws->abi->io_unwatch(aTHX_ ws->loop, ws->fd, HM_ABI_WRITE);
        if (ws->close_tw) {
            ws->abi->timer_cancel(aTHX_ ws->loop, ws->close_tw);
            ws->close_tw = NULL;
        }
    }
    ws->reading = ws->writing = 0;
    if (ws->fd >= 0) { close(ws->fd); ws->fd = -1; }
    ws->state = PW_ST_CLOSED;

    args[0] = sv_2mortal(newSViv(ws->peer_code ? ws->peer_code : code));
    args[1] = ws->peer_reason ? sv_2mortal(newSVsv(ws->peer_reason))
            : sv_2mortal(rlen ? newSVpvn(reason, rlen) : newSVpvs(""));
    (void)pw_emit(aTHX_ ws, "close", args, 2);

    if (ws->cbs) { SvREFCNT_dec((SV *)ws->cbs); ws->cbs = NULL; }
    ws->in_teardown = 0;
    /* drop the self-reference last: this may free the object */
    if (ws->self_rv) { SV *s = ws->self_rv; ws->self_rv = NULL; SvREFCNT_dec(s); }
}

static void pw_close_timeout(pTHX_ void *ud) {
    punk_wsconn *ws = (punk_wsconn *)ud;
    ws->close_tw = NULL;
    pw_teardown(aTHX_ ws, PW_CLOSE_ABNORMAL, "close timeout", 13);
}

/* ---- reading -------------------------------------------------------------
 * One pass over everything buffered: control frames are answered inline,
 * data frames reassemble into ws->frag until FIN. */

static void pw_process(pTHX_ punk_wsconn *ws) {
    size_t off = 0;
    /* Teardown drops the connection's self-reference, which can free the
     * struct while we are still inside this loop (a close frame, or any
     * protocol failure, does exactly that). Hold a reference for the
     * duration so the tail of this function - and our caller - still have
     * something to look at; the object goes away when this guard does. */
    SV *guard = ws->self_rv ? SvREFCNT_inc(ws->self_rv) : NULL;
    while (ws->state != PW_ST_CLOSED && off < ws->rlen) {
        pw_frame f;
        int n = pw_decode_frame(ws->rbuf + off, ws->rlen - off, &f,
                                ws->max_message_size, 1);
        if (n == PW_NEED_MORE) break;
        if (n == PW_E_PROTO) {
            pw_fail(aTHX_ ws, PW_CLOSE_PROTOCOL_ERROR, "protocol error");
            goto consumed;
        }
        if (n == PW_E_TOO_BIG) {
            pw_fail(aTHX_ ws, PW_CLOSE_MESSAGE_TOO_BIG, "message too big");
            goto consumed;
        }
        pw_unmask(&f, ws->rbuf + off + f.header_size);
        {
            const char *pl = ws->rbuf + off + f.header_size;
            size_t      pn = (size_t)f.payload_len;

            if (pw_is_control(f.opcode)) {
                if (f.opcode == PW_OP_PING) {
                    pw_queue_frame(aTHX_ ws, PW_OP_PONG, pl, pn);
                    { SV *a[1]; a[0] = sv_2mortal(newSVpvn(pl, pn));
                      (void)pw_emit(aTHX_ ws, "ping", a, 1); }
                }
                else if (f.opcode == PW_OP_PONG) {
                    SV *a[1]; a[0] = sv_2mortal(newSVpvn(pl, pn));
                    (void)pw_emit(aTHX_ ws, "pong", a, 1);
                }
                else {   /* close */
                    uint16_t code = PW_CLOSE_NO_STATUS;
                    if (pn == 1) {
                        pw_fail(aTHX_ ws, PW_CLOSE_PROTOCOL_ERROR,
                                "bad close payload");
                        goto consumed;
                    }
                    if (pn >= 2) {
                        code = (uint16_t)(((unsigned char)pl[0] << 8)
                                        | (unsigned char)pl[1]);
                        if (!pw_close_code_ok(code)) {
                            pw_fail(aTHX_ ws, PW_CLOSE_PROTOCOL_ERROR,
                                    "bad close code");
                            goto consumed;
                        }
                        if (pn > 2 && !pw_utf8_valid(pl + 2, pn - 2)) {
                            pw_fail(aTHX_ ws, PW_CLOSE_INVALID_PAYLOAD,
                                    "close reason is not utf8");
                            goto consumed;
                        }
                    }
                    ws->close_rcvd = 1;
                    ws->peer_code  = code;
                    if (ws->peer_reason) SvREFCNT_dec(ws->peer_reason);
                    ws->peer_reason = pn > 2 ? newSVpvn(pl + 2, pn - 2)
                                             : newSVpvs("");
                    SvUTF8_on(ws->peer_reason);
                    if (!ws->close_sent)
                        pw_queue_close(aTHX_ ws, code == PW_CLOSE_NO_STATUS
                                       ? PW_CLOSE_NORMAL : code, NULL, 0);
                    off += (size_t)n;
                    /* everything queued is flushed by pw_queue_close ->
                     * pw_flush, which tears down once it drains */
                    if (ws->wlen == ws->woff)
                        pw_teardown(aTHX_ ws, code, NULL, 0);
                    goto consumed;
                }
            }
            else {   /* data */
                unsigned char op = f.opcode;
                if (op == PW_OP_CONT) {
                    if (!ws->frag_active) {
                        pw_fail(aTHX_ ws, PW_CLOSE_PROTOCOL_ERROR,
                                "continuation without a start frame");
                        goto consumed;
                    }
                }
                else {
                    if (ws->frag_active) {
                        pw_fail(aTHX_ ws, PW_CLOSE_PROTOCOL_ERROR,
                                "new data frame inside a fragmented message");
                        goto consumed;
                    }
                    ws->frag_active = 1;
                    ws->frag_op     = op;
                    ws->fraglen     = 0;
                    pw_utf8_reset(&ws->utf8);
                }
                if (ws->max_message_size
                    && ws->fraglen + pn > ws->max_message_size) {
                    pw_fail(aTHX_ ws, PW_CLOSE_MESSAGE_TOO_BIG,
                            "message too big");
                    goto consumed;
                }
                /* validate text as it arrives, so a split multibyte
                 * character is judged on the whole message, not a fragment */
                if (ws->frag_op == PW_OP_TEXT
                    && !pw_utf8_step(&ws->utf8, pl, pn)) {
                    pw_fail(aTHX_ ws, PW_CLOSE_INVALID_PAYLOAD,
                            "text is not utf8");
                    goto consumed;
                }
                if (pn) pw_append(&ws->frag, &ws->fraglen, &ws->fragcap, pl, pn);

                if (f.fin) {
                    int is_text = (ws->frag_op == PW_OP_TEXT);
                    if (is_text && !pw_utf8_ok(&ws->utf8)) {
                        pw_fail(aTHX_ ws, PW_CLOSE_INVALID_PAYLOAD,
                                "text is not utf8");
                        goto consumed;
                    }
                    {
                        SV *msg = newSVpvn(ws->fraglen ? ws->frag : "",
                                           ws->fraglen);
                        SV *a[1];
                        if (is_text) SvUTF8_on(msg);
                        a[0] = sv_2mortal(msg);
                        ws->frag_active = 0;
                        ws->fraglen     = 0;
                        (void)pw_emit(aTHX_ ws, is_text ? "message" : "binary",
                                      a, 1);
                    }
                }
            }
        }
        off += (size_t)n;
    }
consumed:
    if (off && ws->rbuf) {
        if (off < ws->rlen) memmove(ws->rbuf, ws->rbuf + off, ws->rlen - off);
        ws->rlen -= off;
    }
    if (guard) SvREFCNT_dec(guard);
}

static void pw_on_readable(pTHX_ int fd, int mask, void *ud) {
    punk_wsconn *ws = (punk_wsconn *)ud;
    PERL_UNUSED_ARG(fd); PERL_UNUSED_ARG(mask);
    for (;;) {
        ssize_t n;
        size_t cap = ws->max_message_size
                   ? ws->max_message_size + PW_READ_CHUNK : 0;
        if (cap && ws->rlen >= cap) {
            pw_fail(aTHX_ ws, PW_CLOSE_MESSAGE_TOO_BIG, "message too big");
            return;
        }
        pw_buf_reserve(&ws->rbuf, &ws->rcap, ws->rlen + PW_READ_CHUNK);
        n = read(ws->fd, ws->rbuf + ws->rlen, PW_READ_CHUNK);
        if (n > 0) { ws->rlen += (size_t)n; continue; }
        if (n == 0) {                       /* peer went away */
            pw_teardown(aTHX_ ws, PW_CLOSE_ABNORMAL, NULL, 0);
            return;
        }
        if (errno == EINTR) continue;
        if (errno == EAGAIN || errno == EWOULDBLOCK) break;
        pw_teardown(aTHX_ ws, PW_CLOSE_ABNORMAL, NULL, 0);
        return;
    }
    pw_process(aTHX_ ws);
}

/* ---- construction and destruction ---------------------------------------- */

static punk_wsconn *pw_new(pTHX_ int fd, HV *opts) {
    punk_wsconn *ws;
    SV **e;
    Newxz(ws, 1, punk_wsconn);
    ws->fd    = fd;
    ws->state = PW_ST_CONNECTING;
    ws->cbs   = newHV();
    ws->max_message_size   = PW_DEFAULT_MAX_MESSAGE;
    ws->write_buffer_limit = PW_DEFAULT_WRITE_LIMIT;
    pw_utf8_reset(&ws->utf8);
    if (opts) {
        if ((e = hv_fetchs(opts, "max_message_size", 0)) && *e && SvOK(*e))
            ws->max_message_size = (size_t)SvUV(*e);
        if ((e = hv_fetchs(opts, "write_buffer_limit", 0)) && *e && SvOK(*e))
            ws->write_buffer_limit = (size_t)SvUV(*e);
        if ((e = hv_fetchs(opts, "protocol", 0)) && *e && SvOK(*e))
            ws->protocol = newSVsv(*e);
        if ((e = hv_fetchs(opts, "blocking", 0)) && *e && SvTRUE(*e))
            ws->blocking = 1;
    }
    return ws;
}

/* The blessed IV-ref -> the struct, guarded like Punk::Router's handles. */
static punk_wsconn *punk_ws_of(pTHX_ SV *self) {
    if (!SvROK(self) || !SvIOK(SvRV(self)))
        croak("Punk::WebSocket: not a connection");
    return (punk_wsconn *)INT2PTR(void *, SvIV(SvRV(self)));
}

static void pw_free(pTHX_ punk_wsconn *ws) {
    if (!ws) return;
    if (ws->fd >= 0) close(ws->fd);
    if (ws->cbs)         SvREFCNT_dec((SV *)ws->cbs);
    if (ws->protocol)    SvREFCNT_dec(ws->protocol);
    if (ws->peer_reason) SvREFCNT_dec(ws->peer_reason);
    if (ws->rbuf) free(ws->rbuf);
    if (ws->wbuf) free(ws->wbuf);
    if (ws->frag) free(ws->frag);
    Safefree(ws);
}

#endif /* PUNK_WSCONN_H */
