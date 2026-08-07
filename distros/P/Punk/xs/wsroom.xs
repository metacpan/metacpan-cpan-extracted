MODULE = Punk        PACKAGE = Punk::WebSocket::Room

PROTOTYPES: DISABLE

# Per-worker pub/sub groups of connections, in C (punk_wsroom.h). Members are
# held weakly and pruned on access; a broadcast encodes once and queues the
# same bytes to every open member. lib/Punk/WebSocket/Room.pm is documentation.

# named($name): the worker's room of that name, created on first use.
SV *
named(class, name)
        SV *class
        SV *name
    CODE:
    {
        IV pid = (IV)PerlProc_getpid();
        STRLEN nl; const char *n = SvPV_const(name, nl);
        SV **rp;
        if (!pwr_rooms) { pwr_rooms = newHV(); pwr_rooms_pid = pid; }
        else if (pwr_rooms_pid != pid) { hv_clear(pwr_rooms); pwr_rooms_pid = pid; }
        rp = hv_fetch(pwr_rooms, n, (I32)nl, 0);
        if (rp && *rp && SvROK(*rp)) RETVAL = newSVsv(*rp);
        else {
            HV *room = newHV();
            SV *rv;
            (void)hv_stores(room, "name", newSVsv(name));
            (void)hv_stores(room, "members", newRV_noinc((SV *)newHV()));
            rv = sv_bless(newRV_noinc((SV *)room), gv_stashsv(class, GV_ADD));
            (void)hv_store(pwr_rooms, n, (I32)nl, rv, 0);   /* registry owns it */
            RETVAL = newSVsv(rv);
        }
    }
    OUTPUT:
        RETVAL

SV *
name(self)
        SV *self
    CODE:
    {
        SV **nm = hv_fetchs(pwr_hv(aTHX_ self), "name", 0);
        RETVAL = (nm && *nm) ? newSVsv(*nm) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# join($ws): add a member, held weakly. Chains.
SV *
join(self, ws)
        SV *self
        SV *ws
    CODE:
    {
        void *addr = PWR_ADDR(ws);
        if (addr) {
            HV *members = pwr_members(aTHX_ self);
            SV *copy = newSVsv(ws);
            (void)hv_store(members, (const char *)&addr, PWR_KEYLEN, copy, 0);
            sv_rvweaken(copy);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# leave($ws): drop a member. Chains.
SV *
leave(self, ws)
        SV *self
        SV *ws
    CODE:
    {
        void *addr = PWR_ADDR(ws);
        if (addr)
            (void)hv_delete(pwr_members(aTHX_ self), (const char *)&addr,
                            PWR_KEYLEN, 0);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# has($ws): is $ws a member and open?
IV
has(self, ws)
        SV *self
        SV *ws
    CODE:
    {
        void *addr = PWR_ADDR(ws);
        SV **mp = addr ? hv_fetch(pwr_members(aTHX_ self),
                                  (const char *)&addr, PWR_KEYLEN, 0) : NULL;
        RETVAL = (mp && *mp && pwr_ws_state(aTHX_ *mp) == PW_ST_OPEN) ? 1 : 0;
    }
    OUTPUT:
        RETVAL

# clients: the live members (pruning as it goes).
void
clients(self)
        SV *self
    PPCODE:
    {
        AV *live = (AV *)sv_2mortal((SV *)newAV());
        SSize_t i, n;
        pwr_live(aTHX_ pwr_members(aTHX_ self), live);
        n = av_len(live) + 1;
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(live, i, 0))));
    }

IV
count(self)
        SV *self
    CODE:
    {
        AV *live = (AV *)sv_2mortal((SV *)newAV());
        pwr_live(aTHX_ pwr_members(aTHX_ self), live);
        RETVAL = av_len(live) + 1;
    }
    OUTPUT:
        RETVAL

# broadcast($text, $except?) / broadcast_binary($bytes, $except?): encode once,
# queue to every open member bar $except; returns the number sent.
SV *
broadcast(self, message, except = &PL_sv_undef)
        SV *self
        SV *message
        SV *except
    ALIAS:
        broadcast_binary = 1
    CODE:
    {
        SV *frame; int count;
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(message); PUTBACK;
        count = call_pv(ix ? PK_WEBSOCKET "::_encode_binary"
                           : PK_WEBSOCKET "::_encode_text", G_SCALAR);
        SPAGAIN;
        frame = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
        sv_2mortal(frame);
        RETVAL = newSViv(pwr_fan(aTHX_ self, frame, except));
    }
    OUTPUT:
        RETVAL

# close_all($code = 1000, $reason = ''): close every member, empty the room.
IV
close_all(self, code = &PL_sv_undef, reason = &PL_sv_undef)
        SV *self
        SV *code
        SV *reason
    CODE:
    {
        HV *members = pwr_members(aTHX_ self);
        AV *live = (AV *)sv_2mortal((SV *)newAV());
        SSize_t i, n;
        IV closed = 0;
        pwr_live(aTHX_ members, live);
        n = av_len(live) + 1;
        for (i = 0; i < n; i++) {
            SV *ws = *av_fetch(live, i, 0);
            SV *argv[2], *r;
            argv[0] = sv_2mortal(newSViv(SvOK(code) ? SvIV(code) : 1000));
            argv[1] = SvOK(reason) ? reason : sv_2mortal(newSVpvs(""));
            r = pcx_call_meth(aTHX_ ws, "close", argv, 2, 0);
            if (r) SvREFCNT_dec(r);
            closed++;
        }
        hv_clear(members);
        RETVAL = closed;
    }
    OUTPUT:
        RETVAL

# clear: empty the room without closing anything. Chains.
SV *
clear(self)
        SV *self
    CODE:
        hv_clear(pwr_members(aTHX_ self));
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL
