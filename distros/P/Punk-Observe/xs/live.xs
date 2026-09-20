MODULE = Punk::Observe   PACKAGE = Punk::Observe::Live   PREFIX = poli_

# Can the tail cross workers in this process? Built with Shared::Arena's
# header AND its table resolved at boot. A test that needs a second worker
# asks, rather than assuming a layout.
int
poli_have_bus()
    CODE:
#ifdef PO_HAVE_BUS
        RETVAL = PO_SA ? 1 : 0;
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

# The slot size this build encodes for, and - once the ring is open - what
# one of its slots carries, a RUNTIME answer. A test asserts the ring holds
# at least the slot the record is sized against, because a record sized
# against the wrong number is refused rather than truncated.
void
poli_slot_sizes()
    PPCODE:
        {
            mXPUSHi(PO_TAIL_SLOT);
#ifdef PO_HAVE_BUS
            mXPUSHi(po_sa_ring ? (IV)PO_SA->slot_bytes(po_sa_ring) : 0);
#else
            mXPUSHi(0);
#endif
        }

SV *
poli_topic(SV *tenant)
    CODE:
        {
            STRLEN tl;
            const char *t = SvPV(tenant, tl);
            char out[PO_TAIL_TOPIC_MAX];
            size_t n = po_tail_topic(t, (size_t)tl, out, sizeof(out));
            RETVAL = n ? newSVpvn(out, n) : newSVsv(&PL_sv_undef);
        }
    OUTPUT:
        RETVAL

# Encode a record, then decode it straight back. The round trip is the test:
# a truncation that the decoder cannot see is the same as a lost line.
void
poli_roundtrip(SV *spec)
    PPCODE:
        {
            po_tail_rec in, out;
            HV *h;
            SV **f;
            char buf[PO_TAIL_SLOT];
            size_t n;
            int cut = 0;
            HV *res = newHV();

            if (!SvROK(spec) || SvTYPE(SvRV(spec)) != SVt_PVHV)
                croak("spec must be a hashref");
            h = (HV *)SvRV(spec);
            memset(&in, 0, sizeof(in));
            if ((f = hv_fetchs(h, "t", 0)))        (void)po_sv_to_u64(aTHX_ *f, &in.t_unix_nano);
            if ((f = hv_fetchs(h, "stream", 0)))   (void)po_sv_to_u64(aTHX_ *f, &in.stream);
            if ((f = hv_fetchs(h, "severity", 0))) in.severity = (uint32_t)SvUV(*f);
            if ((f = hv_fetchs(h, "service", 0)))  in.service = SvPV(*f, in.service_len);
            if ((f = hv_fetchs(h, "body", 0)))     in.body    = SvPV(*f, in.body_len);

            n = po_tail_encode(&in, buf, &cut);
            hv_stores(res, "encoded_len", newSVuv((UV)n));
            hv_stores(res, "truncated",   newSViv(cut));
            hv_stores(res, "fits_slot",   newSViv(n <= PO_TAIL_SLOT));

            if (po_tail_decode(buf, n, &out)) {
                hv_stores(res, "ok", newSViv(1));
                hv_stores(res, "t",        po_u64_to_sv(out.t_unix_nano));
                hv_stores(res, "stream",   po_u64_to_sv(out.stream));
                hv_stores(res, "severity", newSVuv((UV)out.severity));
                hv_stores(res, "service",  newSVpvn(out.service ? out.service : "",
                                                    out.service_len));
                hv_stores(res, "body",     newSVpvn(out.body ? out.body : "",
                                                    out.body_len));
                hv_stores(res, "flagged",  newSViv(po_tail_is_truncated(&out)));
            }
            else hv_stores(res, "ok", newSViv(0));
            mXPUSHs(newRV_noinc((SV *)res));
        }

# A slot that another process wrote is untrusted input. Feed the decoder a
# damaged one and require a refusal rather than a pointer past the end.
int
poli_decode_bad(SV *bytes)
    CODE:
        {
            po_tail_rec r;
            STRLEN len;
            const char *p = SvPV(bytes, len);
            RETVAL = po_tail_decode(p, (size_t)len, &r) ? 1 : 0;
        }
    OUTPUT:
        RETVAL

# The resume ring: push rows, then ask what follows an id.
void
poli_ring(SV *opts)
    PPCODE:
        {
            po_tail_ring ring;
            HV *o;
            SV **f;
            AV *rows;
            SSize_t i, n;
            po_u64 since = 0, missed = 0;
            uint32_t first = 0, avail;
            AV *got = newAV();
            HV *res = newHV();
            UV cap = 0;
            po_u64 bytes = 0;

            if (!SvROK(opts) || SvTYPE(SvRV(opts)) != SVt_PVHV)
                croak("opts must be a hashref");
            o = (HV *)SvRV(opts);
            if ((f = hv_fetchs(o, "cap", 0)))   cap = SvUV(*f);
            if ((f = hv_fetchs(o, "bytes", 0))) (void)po_sv_to_u64(aTHX_ *f, &bytes);
            if ((f = hv_fetchs(o, "since", 0))) (void)po_sv_to_u64(aTHX_ *f, &since);
            f = hv_fetchs(o, "rows", 0);
            if (!f || !SvROK(*f)) croak("rows must be an arrayref");
            rows = (AV *)SvRV(*f);
            n = av_len(rows) + 1;

            if (!po_tail_ring_init(&ring, (uint32_t)cap, bytes)) croak("oom");
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(rows, i, 0);
                STRLEN l;
                const char *p;
                if (!e) continue;
                p = SvPV(*e, l);
                (void)po_tail_ring_push(&ring, p, (size_t)l);
            }

            avail = po_tail_ring_since(&ring, since, &first, &missed);
            for (i = 0; i < (SSize_t)avail; i++) {
                const po_ring_ent *e = po_tail_ring_at(&ring, first + (uint32_t)i);
                HV *rh = newHV();
                if (!e) break;
                hv_stores(rh, "id",   po_u64_to_sv(e->id));
                hv_stores(rh, "data", newSVpvn(e->p, e->len));
                av_push(got, newRV_noinc((SV *)rh));
            }

            hv_stores(res, "rows",    newRV_noinc((SV *)got));
            hv_stores(res, "missed",  po_u64_to_sv(missed));
            hv_stores(res, "evicted", po_u64_to_sv(ring.evicted));
            hv_stores(res, "held",    newSVuv((UV)ring.n));
            hv_stores(res, "oldest",  po_u64_to_sv(po_tail_ring_oldest(&ring)));
            hv_stores(res, "bytes",   po_u64_to_sv(ring.bytes));
            po_tail_ring_free(&ring);
            mXPUSHs(newRV_noinc((SV *)res));
        }

# Backpressure: feed a client that never drains and require a close, not a
# queue that grows until something else fails.
void
poli_flow(SV *limit, SV *sizes, SV *drain_each)
    PPCODE:
        {
            po_tail_flow f;
            AV *av;
            SSize_t i, n;
            po_u64 lim = 0;
            int drain = SvTRUE(drain_each);
            IV admitted = 0, refused = 0;
            HV *res = newHV();

            (void)po_sv_to_u64(aTHX_ limit, &lim);
            if (!SvROK(sizes)) croak("sizes must be an arrayref");
            av = (AV *)SvRV(sizes);
            n = av_len(av) + 1;
            po_tail_flow_init(&f, lim);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                size_t sz = e ? (size_t)SvUV(*e) : 0;
                if (po_tail_flow_admit(&f, sz)) {
                    admitted++;
                    if (drain) po_tail_flow_drained(&f, sz);
                }
                else refused++;
            }
            hv_stores(res, "admitted", newSViv(admitted));
            hv_stores(res, "refused",  newSViv(refused));
            hv_stores(res, "pending",  po_u64_to_sv(f.pending));
            hv_stores(res, "closed",   newSViv(f.closed));
            mXPUSHs(newRV_noinc((SV *)res));
        }

SV *
poli_sse(SV *id, SV *event, SV *data)
    CODE:
        {
            po_u64 i = 0;
            STRLEN el, dl;
            const char *e, *d;
            char out[8192];
            size_t n;
            (void)po_sv_to_u64(aTHX_ id, &i);
            e = SvOK(event) ? SvPV(event, el) : (el = 0, "");
            d = SvPV(data, dl);
            n = po_sse_frame(i, e, (size_t)el, d, (size_t)dl, out, sizeof(out));
            RETVAL = newSVpvn(out, n);
        }
    OUTPUT:
        RETVAL

SV *
poli_heartbeat()
    CODE:
        {
            char out[8];
            size_t n = po_sse_heartbeat(out, sizeof(out));
            RETVAL = newSVpvn(out, n);
        }
    OUTPUT:
        RETVAL

# ---- the bus, where this build has one -------------------------------------

# Set up the ring. Called BEFORE the fork, because a subscription made after
# one lands in a single process and a cursor that starts at "now" silently
# misses everything published before it.
#
#   bus_init()           an anonymous Shared::Arena of Observe's own
#   bus_init(, )   the ring on a Shared::Arena the caller holds
#                              (Hyperman->arena, or a test's with its hooks)
#
# The ring's slot is 64 bytes wider than PO_TAIL_SLOT, so a record sized
# against PO_TAIL_SLOT always fits one slot and never spans. Idempotent.
int
poli_bus_init(int slots, ...)
    CODE:
#ifdef PO_HAVE_BUS
        {
            int err = 0;
            if (!PO_SA) { RETVAL = 0; }
            else if (po_sa_ring) { RETVAL = 1; }
            else {
                if (slots < 2) slots = 2;
                if (items > 1 && SvROK(ST(1))) {
                    /* Ride on the caller's arena: Shared::Arena::_region_ptr */
                    dSP;
                    int count;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(ST(1));
                    PUTBACK;
                    count = call_method("_region_ptr", G_SCALAR | G_EVAL);
                    SPAGAIN;
                    if (count == 1 && !SvTRUE(ERRSV)) {
                        SV *p = POPs;
                        po_sa_region = INT2PTR(sa_region *, SvUV(p));
                    }
                    PUTBACK; FREETMPS; LEAVE;
                }
                if (!po_sa_region) {
                    sa_config cfg;
                    PO_SA->config_init(&cfg);
                    cfg.bytes = (uint64_t)slots * (PO_TAIL_SLOT + 64) + 65536;
                    po_sa_region = PO_SA->create(&cfg, &err);
                }
                if (po_sa_region)
                    po_sa_ring = PO_SA->ring_open(po_sa_region, "po.tail", 7,
                                                  (uint64_t)slots,
                                                  PO_TAIL_SLOT + 64, &err);
                RETVAL = po_sa_ring ? 1 : 0;
            }
        }
#else
        (void)slots;
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

int
poli_bus_publish(SV *topic, SV *payload)
    CODE:
#ifdef PO_HAVE_BUS
        {
            STRLEN tl, pl;
            const char *t = SvPV(topic, tl);
            const char *p = SvPV(payload, pl);
            /* 0 on the ring, -1 refused as oversize (never truncated: the
             * record is truncated at ingest, where the reader can see it),
             * 1 with no ring (this process only), -2 built without one. */
            if (!po_sa_ring) RETVAL = 1;
            else if ((uint64_t)tl + pl > PO_TAIL_SLOT - 16) RETVAL = -1;
            else {
                int64_t rc = PO_SA->publish(po_sa_ring, t, (uint32_t)tl,
                                            p, (uint32_t)pl);
                RETVAL = SA_PUBLISHED(rc) ? 0 : rc == SA_TOO_BIG ? -1 : 1;
            }
        }
#else
        (void)topic; (void)payload;
        RETVAL = -2;
#endif
    OUTPUT:
        RETVAL

# Drain the fanout cursor, returning every payload seen and the gap count.
#
# A GAP IS REPORTED, NOT SWALLOWED. A slow consumer that gets lapped and says
# nothing produces a stream indistinguishable from a quiet one.
void
poli_bus_drain(SV *topic, ...)
    PPCODE:
        {
#ifdef PO_HAVE_BUS
            AV *out = newAV();
            HV *res = newHV();
            STRLEN tl;
            const char *t = SvPV(topic, tl);
            long got;
            po_u64 before = po_live_gaps;
            po_live_ud ud;
            ud.av = out; ud.t = t; ud.tl = (size_t)tl;
            {
                sa_cursor *c = po_live_cursor();
                /* Draining is proof of life: a reader that only ever drains
                 * must still tick, or the ring's hole check would judge it
                 * wedged. Join once per process, beat on each drain. */
                if (c && !po_sa_joined) { PO_SA->join(po_sa_region); po_sa_joined = 1; }
                if (c) PO_SA->beat(po_sa_region);
                got = c ? PO_SA->drain(c, 0, po_live_collect, &ud) : 0;
                po_live_gaps = po_live_cursor_gaps();
            }
            /* THE DELTA GOES TO THE ARENA, when the caller passed one.
             *
             * po_live_gaps is a per-process cumulative: honest to this
             * worker, invisible to the one that renders the status page. The
             * arena is the cross-worker ledger, and it takes the DELTA
             * because adding the cumulative on every drain would count each
             * lost line once per drain that happened after it. */
            if (items > 1 && SvOK(ST(1)) && po_live_gaps > before) {
                po_shared *sh = INT2PTR(po_shared *, SvIV(ST(1)));
                if (sh && sh->ok)
                    po_atomic_add(&sh->m->live_gaps, po_live_gaps - before);
            }
            hv_stores(res, "count", newSViv(got));
            hv_stores(res, "gaps",  po_u64_to_sv(po_live_gaps));
            hv_stores(res, "rows",  newRV_noinc((SV *)out));
            mXPUSHs(newRV_noinc((SV *)res));
#else
            (void)topic;
            XSRETURN_UNDEF;
#endif
        }

# THE POST-FORK HOOK. A worker forked after a publish must not replay it, and
# one forked before must not skip what arrives after: both are the same
# inherited cursor, and both look like a broken tail rather than a fork bug.
void
poli_bus_reset_cursors()
    PPCODE:
#ifdef PO_HAVE_BUS
        po_live_cursor_reset();
#endif
        XSRETURN_EMPTY;
