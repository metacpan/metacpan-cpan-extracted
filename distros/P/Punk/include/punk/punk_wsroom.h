/* punk_wsroom.h - Punk::WebSocket::Room, in C.
 *
 * A per-worker named group of connections. Rooms live in one registry per
 * process (the fork-guarded static below), each a blessed hash { name,
 * members }, and members are held weakly: a live connection is kept alive by
 * the C self-reference it holds while open, so a room never resurrects a
 * closed one and never leaks a disconnected one. A broadcast encodes the frame
 * once (the _encode_text/_encode_binary XSUB) and queues the same bytes to
 * every open member. State and refaddr checks are done straight off the
 * punk_wsconn struct; the send and the encode reuse the connection XSUBs.
 *
 * Must be included after punk_wsconn.h (punk_ws_of, PW_ST_*) and
 * punk_context.h (pcx_call_meth).
 */

#ifndef PUNK_WSROOM_H
#define PUNK_WSROOM_H

/* The registry is per process: workers fork, and each owns the sockets it
 * accepted (the pid guard resets an inherited registry, as the Perl's
 * `$PID != $$` did). Not per-ithread - the server model is fork-per-worker. */
static HV *pwr_rooms = NULL;
static IV  pwr_rooms_pid = 0;

static HV *pwr_hv(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Punk::WebSocket::Room: not a room");
    return (HV *)SvRV(self);
}

static HV *pwr_members(pTHX_ SV *self) {
    HV *h = pwr_hv(aTHX_ self);
    SV **m = hv_fetchs(h, "members", 0);
    if (m && *m && SvROK(*m) && SvTYPE(SvRV(*m)) == SVt_PVHV) return (HV *)SvRV(*m);
    {
        HV *nm = newHV();
        (void)hv_stores(h, "members", newRV_noinc((SV *)nm));
        return nm;
    }
}

/* the wsconn state of a member SV, or -1 if it is not a live connection */
static int pwr_ws_state(pTHX_ SV *ws) {
    if (!ws || !SvOK(ws) || !SvROK(ws) || !SvIOK(SvRV(ws))) return -1;
    return punk_ws_of(aTHX_ ws)->state;
}

/* refaddr($sv) as a raw pointer - the member-hash key (binary, length-counted) */
#define PWR_ADDR(sv)  ((SvROK(sv)) ? (void *)SvRV(sv) : (void *)NULL)
#define PWR_KEYLEN    (sizeof(void *))

/* Fill out with a strong ref to every live member, pruning anything gone
 * (a weakref that went undef) or closed. Keys are snapshotted first so the
 * hash can be modified as we go. */
static void pwr_live(pTHX_ HV *members, AV *out) {
    AV *keys = (AV *)sv_2mortal((SV *)newAV());
    HE *he;
    SSize_t i, n;
    hv_iterinit(members);
    while ((he = hv_iternext(members))) av_push(keys, newSVsv(hv_iterkeysv(he)));
    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV *ksv = *av_fetch(keys, i, 0);
        STRLEN kl; const char *k = SvPV_const(ksv, kl);
        SV **mp = hv_fetch(members, k, (I32)kl, 0);
        SV *ws = (mp && *mp) ? *mp : NULL;
        int st;
        if (!ws || !SvOK(ws)) { (void)hv_delete(members, k, (I32)kl, 0); continue; }
        st = pwr_ws_state(aTHX_ ws);
        if (st < 0 || st == PW_ST_CLOSED) {
            (void)hv_delete(members, k, (I32)kl, 0);
            continue;
        }
        av_push(out, newSVsv(ws));      /* a strong ref for the loop's life */
    }
}

/* Encode once (via _encode_text / _encode_binary), queue to every open member
 * bar `except`; returns the number sent. */
static IV pwr_fan_skip(pTHX_ SV *self, SV *frame, void *skip) {
    HV *members = pwr_members(aTHX_ self);
    AV *live = (AV *)sv_2mortal((SV *)newAV());
    IV sent = 0;
    SSize_t i, n;
    STRLEN flen;
    const char *fp = SvPV_const(frame, flen);
    pwr_live(aTHX_ members, live);
    n = av_len(live) + 1;
    for (i = 0; i < n; i++) {
        SV *ws = *av_fetch(live, i, 0);
        punk_wsconn *w;
        if (skip && (void *)SvRV(ws) == skip) continue;
        if (pwr_ws_state(aTHX_ ws) != PW_ST_OPEN) continue;
        /* what Punk::WebSocket::_send_raw does, without the method call
         * per member: `live` holds a strong reference to each, so a member
         * that fails here outlives the loop */
        w = punk_ws_of(aTHX_ ws);
        if (w->write_buffer_limit
            && w->wlen - w->woff + flen > w->write_buffer_limit) {
            pw_fail(aTHX_ w, PW_CLOSE_POLICY_VIOLATION, "send buffer full");
            continue;
        }
        pw_append(&w->wbuf, &w->wlen, &w->wcap, fp, flen);
        pw_flush(aTHX_ w);
        sent++;
    }
    return sent;
}

static IV pwr_fan(pTHX_ SV *self, SV *frame, SV *except) {
    return pwr_fan_skip(aTHX_ self, frame,
                        (except && SvOK(except)) ? PWR_ADDR(except) : NULL);
}

#endif /* PUNK_WSROOM_H */
