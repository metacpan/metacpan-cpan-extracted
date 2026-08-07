MODULE = Punk        PACKAGE = Punk::WebSocket

PROTOTYPES: DISABLE

# ---- stateless codec hooks -------------------------------------------------
# The frame layer on its own, so it can be driven from tests against an
# independent reference implementation, and so Rooms can encode a broadcast
# frame once and queue the same bytes to every member.

# Encode one server frame (never masked).
SV *
_encode_frame(opcode, fin, payload)
        IV  opcode
        IV  fin
        SV *payload
    CODE:
    {
        STRLEN plen;
        const char *p = SvPV_const(payload, plen);
        char hdr[10];
        size_t hn = pw_encode_header(hdr, (unsigned char)opcode,
                                     fin ? 1 : 0, plen);
        RETVAL = newSVpvn(hdr, hn);
        if (plen) sv_catpvn(RETVAL, p, plen);
    }
    OUTPUT:
        RETVAL

# One complete text (UTF-8) or binary message, ready to write. Rooms encode
# a broadcast once through these and queue the same bytes to every member.
SV *
_encode_text(payload)
        SV *payload
    ALIAS:
        _encode_binary = 1
    CODE:
    {
        STRLEN plen;
        const char *p = ix ? SvPV_const(payload, plen)
                           : SvPVutf8(payload, plen);
        char hdr[10];
        size_t hn = pw_encode_header(hdr, ix ? PW_OP_BINARY : PW_OP_TEXT,
                                     1, plen);
        RETVAL = newSVpvn(hdr, hn);
        if (plen) sv_catpvn(RETVAL, p, plen);
    }
    OUTPUT:
        RETVAL

# Encode a close frame: 2-byte code plus an optional reason.
SV *
_encode_close(code, ...)
        IV code
    CODE:
    {
        char body[2 + PW_MAX_REASON], hdr[10];
        const char *reason = NULL;
        STRLEN rlen = 0;
        size_t blen, hn;
        if (items > 1 && SvOK(ST(1))) reason = SvPVutf8(ST(1), rlen);
        blen = pw_close_payload(body, (uint16_t)code, reason, rlen);
        hn   = pw_encode_header(hdr, PW_OP_CLOSE, 1, blen);
        RETVAL = newSVpvn(hdr, hn);
        sv_catpvn(RETVAL, body, blen);
    }
    OUTPUT:
        RETVAL

# Decode one frame from a buffer of client (masked) bytes.
#   (consumed, fin, opcode, payload)   a whole frame
#   (0)                                need more data
#   (negative)                         protocol failure: -1 proto (1002),
#                                      -2 too big (1009), -3 utf8 (1007)
# max_msg defaults to 0 (unbounded); server defaults to 1 (masking required).
void
_decode_frame(bytes, ...)
        SV *bytes
    PPCODE:
    {
        STRLEN len;
        const char *buf = SvPV_const(bytes, len);
        size_t max_msg = items > 1 && SvOK(ST(1)) ? (size_t)SvUV(ST(1)) : 0;
        int server     = items > 2 && SvOK(ST(2)) ? (int)SvIV(ST(2)) : 1;
        pw_frame f;
        int n = pw_decode_frame(buf, len, &f, max_msg, server);
        if (n <= 0) {
            mXPUSHi(n);
        }
        else {
            SV *pl = newSVpvn(f.payload, (STRLEN)f.payload_len);
            if (f.masked) pw_unmask(&f, SvPVX(pl));
            mXPUSHi(n);
            mXPUSHi(f.fin);
            mXPUSHi(f.opcode);
            mXPUSHs(pl);
        }
    }

# Is this a well-formed UTF-8 string? (the 1007 check, exposed for tests)
int
_utf8_valid(bytes)
        SV *bytes
    CODE:
    {
        STRLEN len;
        const char *p = SvPV_const(bytes, len);
        RETVAL = pw_utf8_valid(p, len);
    }
    OUTPUT:
        RETVAL

# May a peer send this close code? (RFC 6455 7.4)
int
_close_code_ok(code)
        IV code
    CODE:
        RETVAL = pw_close_code_ok((uint16_t)code);
    OUTPUT:
        RETVAL

# ---- the live connection ---------------------------------------------------

# Is Hyperman's detach ABI available? (the boot check behind websocket routes)
int
_hm_available()
    CODE:
        RETVAL = punk_hm(aTHX) ? 1 : 0;
    OUTPUT:
        RETVAL

# Take this request's socket over: $env -> the client fd, now ours.
IV
_hm_detach(env)
        SV *env
    CODE:
    {
        const hm_abi *A = punk_hm(aTHX);
        HV *ehv;
        SV **e;
        AV *cid;
        SV **fsv, **isv;
        void *loop;
        int fd, rc;
        if (!A)
            croak("Punk::WebSocket: Hyperman's detach ABI is unavailable "
                  "(needs Hyperman 0.11+)");
        if (!SvROK(env) || SvTYPE(SvRV(env)) != SVt_PVHV)
            croak("Punk::WebSocket::_hm_detach: env must be a hashref");
        ehv = (HV *)SvRV(env);
        e = hv_fetchs(ehv, "psgix.hyperman.conn", 0);
        if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV))
            croak("Punk::WebSocket: this request cannot be detached "
                  "(no psgix.hyperman.conn)");
        cid = (AV *)SvRV(*e);
        fsv = av_fetch(cid, 0, 0);
        isv = av_fetch(cid, 1, 0);
        if (!(fsv && *fsv && isv && *isv))
            croak("Punk::WebSocket: malformed psgix.hyperman.conn");
        loop = A->cur_loop(aTHX);
        if (!loop) croak("Punk::WebSocket: no running Hyperman loop");
        fd = (int)SvIV(*fsv);
        rc = A->conn_detach(aTHX_ loop, fd, SvUV(*isv));
        if (rc != 0)
            croak("Punk::WebSocket: detach failed (%d: %s)", rc,
                  rc == -1 ? "connection gone or stale"
                : rc == -2 ? "HTTP/2 cannot be detached"
                : rc == -3 ? "TLS cannot be detached"
                : rc == -4 ? "a response is still draining"
                : rc == -5 ? "already detached" : "unknown");
        RETVAL = (IV)fd;
    }
    OUTPUT:
        RETVAL

# Attach to a detached fd: queue the handshake bytes, arm the read watcher.
SV *
_attach(class, fd, handshake, opts)
        SV *class
        IV  fd
        SV *handshake
        SV *opts
    ALIAS:
        _attach_blocking = 1
    CODE:
    {
        punk_wsconn *ws;
        HV *o = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
              ? (HV *)SvRV(opts) : NULL;
        const hm_abi *A = ix ? NULL : punk_hm(aTHX);
        STRLEN hlen;
        const char *hs;
        if (!ix && !A)
            croak("Punk::WebSocket: Hyperman's ABI is unavailable");
        ws = pw_new(aTHX_ (int)fd, o);
        ws->blocking = ix ? 1 : 0;
        if (!ix) {
            ws->abi  = A;
            ws->loop = A->cur_loop(aTHX);
            if (!ws->loop) { pw_free(aTHX_ ws);
                             croak("Punk::WebSocket: no running loop"); }
        }
        /* non-blocking on the loop; the blocking fallback wants it blocking */
        {
            int fl = fcntl((int)fd, F_GETFL, 0);
            if (fl >= 0) (void)fcntl((int)fd, F_SETFL,
                ix ? (fl & ~O_NONBLOCK) : (fl | O_NONBLOCK));
        }
        RETVAL = sv_setref_iv(newSV(0), SvPV_nolen(class), PTR2IV(ws));
        /* a strong self-reference keeps the connection alive after the
         * handler that wired it returns; teardown drops it */
        ws->self_rv = newSVsv(RETVAL);
        ws->state   = PW_ST_OPEN;
        hs = SvPV_const(handshake, hlen);
        if (hlen) {
            pw_append(&ws->wbuf, &ws->wlen, &ws->wcap, hs, hlen);
            pw_flush(aTHX_ ws);
        }
        if (!ix) {
            ws->abi->io_watch(aTHX_ ws->loop, ws->fd, HM_ABI_READ,
                              pw_on_readable, ws);
            ws->reading = 1;
        }
    }
    OUTPUT:
        RETVAL

# Register an event handler. Unknown names croak - a typo in a callback
# name is a bug you want at wiring time, not silence at runtime.
SV *
on(self, event, cb)
        SV *self
        SV *event
        SV *cb
    CODE:
    {
        punk_wsconn *ws = punk_ws_of(aTHX_ self);
        STRLEN elen;
        const char *ev = SvPV_const(event, elen);
        static const char *const known[] = {
            "open", "message", "binary", "ping", "pong", "close", "error", NULL
        };
        int i, ok = 0;
        for (i = 0; known[i]; i++)
            if (strEQ(ev, known[i])) { ok = 1; break; }
        if (!ok)
            croak("Punk::WebSocket: unknown event '%s' (open, message, "
                  "binary, ping, pong, close, error)", ev);
        if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
            croak("Punk::WebSocket: the handler for '%s' must be a coderef",
                  ev);
        if (ws->cbs) (void)hv_store(ws->cbs, ev, (I32)elen, newSVsv(cb), 0);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# Fire the open event (the dispatcher does this once the handler has wired).
void
_open(self)
        SV *self
    CODE:
    {
        punk_wsconn *ws = punk_ws_of(aTHX_ self);
        (void)pw_emit(aTHX_ ws, "open", NULL, 0);
    }

void
send(self, payload)
        SV *self
        SV *payload
    ALIAS:
        send_binary = 1
        ping        = 2
        pong        = 3
    CODE:
    {
        punk_wsconn *ws = punk_ws_of(aTHX_ self);
        STRLEN len;
        const char *p;
        unsigned char op = ix == 0 ? PW_OP_TEXT
                         : ix == 1 ? PW_OP_BINARY
                         : ix == 2 ? PW_OP_PING : PW_OP_PONG;
        if (ws->state != PW_ST_OPEN) return;
        p = ix == 0 ? SvPVutf8(payload, len) : SvPV_const(payload, len);
        if ((op == PW_OP_PING || op == PW_OP_PONG) && len > PW_MAX_CONTROL)
            croak("Punk::WebSocket: a %s payload is limited to %d bytes",
                  op == PW_OP_PING ? "ping" : "pong", PW_MAX_CONTROL);
        pw_queue_frame(aTHX_ ws, op, p, len);
    }

# Queue pre-encoded frame bytes (Punk::WebSocket::Room broadcasts).
void
_send_raw(self, frame)
        SV *self
        SV *frame
    CODE:
    {
        punk_wsconn *ws = punk_ws_of(aTHX_ self);
        STRLEN len;
        const char *p = SvPV_const(frame, len);
        if (ws->state != PW_ST_OPEN) return;
        if (ws->write_buffer_limit
            && ws->wlen - ws->woff + len > ws->write_buffer_limit) {
            pw_fail(aTHX_ ws, PW_CLOSE_POLICY_VIOLATION, "send buffer full");
            return;
        }
        pw_append(&ws->wbuf, &ws->wlen, &ws->wcap, p, len);
        pw_flush(aTHX_ ws);
    }

void
close(self, ...)
        SV *self
    CODE:
    {
        punk_wsconn *ws = punk_ws_of(aTHX_ self);
        IV code = items > 1 && SvOK(ST(1)) ? SvIV(ST(1)) : PW_CLOSE_NORMAL;
        STRLEN rlen = 0;
        const char *reason = items > 2 && SvOK(ST(2))
                           ? SvPVutf8(ST(2), rlen) : NULL;
        if (ws->state == PW_ST_CLOSED) return;
        pw_queue_close(aTHX_ ws, (uint16_t)code, reason, rlen);
        /* give the peer a bounded window to echo the close */
        if (!ws->blocking && ws->abi && ws->loop && !ws->close_tw
            && ws->state == PW_ST_CLOSING)
            ws->close_tw = ws->abi->timer(aTHX_ ws->loop, PW_CLOSE_TIMEOUT,
                                          pw_close_timeout, ws);
    }

IV
state(self)
        SV *self
    ALIAS:
        is_open    = 1
        is_closing = 2
        is_closed  = 3
        fd         = 4
    CODE:
    {
        punk_wsconn *ws = punk_ws_of(aTHX_ self);
        RETVAL = ix == 0 ? ws->state
               : ix == 1 ? (ws->state == PW_ST_OPEN)
               : ix == 2 ? (ws->state == PW_ST_CLOSING)
               : ix == 3 ? (ws->state == PW_ST_CLOSED)
               : ws->fd;
    }
    OUTPUT:
        RETVAL

SV *
protocol(self)
        SV *self
    CODE:
    {
        punk_wsconn *ws = punk_ws_of(aTHX_ self);
        RETVAL = ws->protocol ? newSVsv(ws->protocol) : newSV(0);
    }
    OUTPUT:
        RETVAL

# The blocking fallback: own the socket inside the handler until it closes.
void
_run_blocking(self)
        SV *self
    CODE:
    {
        punk_wsconn *ws = punk_ws_of(aTHX_ self);
        while (ws->state != PW_ST_CLOSED) {
            ssize_t n;
            pw_buf_reserve(&ws->rbuf, &ws->rcap, ws->rlen + PW_READ_CHUNK);
            n = read(ws->fd, ws->rbuf + ws->rlen, PW_READ_CHUNK);
            if (n > 0)  { ws->rlen += (size_t)n; pw_process(aTHX_ ws); continue; }
            if (n < 0 && errno == EINTR) continue;
            pw_teardown(aTHX_ ws, PW_CLOSE_ABNORMAL, NULL, 0);
            break;
        }
    }

void
DESTROY(self)
        SV *self
    CODE:
    {
        punk_wsconn *ws = (SvROK(self) && SvIOK(SvRV(self)))
            ? (punk_wsconn *)INT2PTR(void *, SvIV(SvRV(self))) : NULL;
        if (!ws) return;
        /* a live connection dropped without closing (worker exit): shut it
         * down, but the self-ref means we normally arrive here after
         * teardown has already run */
        if (ws->state != PW_ST_CLOSED && !ws->in_teardown)
            pw_teardown(aTHX_ ws, PW_CLOSE_GOING_AWAY, NULL, 0);
        pw_free(aTHX_ ws);
    }
