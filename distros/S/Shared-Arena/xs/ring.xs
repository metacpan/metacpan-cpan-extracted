# Shared::Arena::Ring and its cursor.
#
# Both are objects holding a C pointer, and every entry takes one explicitly.
# A cursor in particular MUST be an object: two readers in one process that
# shared a position would consume each other's records, and whichever asked
# first would get everything.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->ring($name, slots => N, slot_size => N) -> Shared::Arena::Ring
#
# Carves the region if it is not there, binds to it if it is. Every process can
# call this with the same arguments; exactly one of them does the work.
SV *
sar_ring(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_ring *r;
        const char *nm;
        STRLEN nlen;
        UV slots = 1024, slot_size = 512;
        int err = SA_E_OK;
        I32 i;
        SV *obj;
    CODE:
        arena = SA_SELF(sa_region, self);
        if (!arena || !arena->map.base)
            croak("Shared::Arena: this region is released");
        nm = SvPV(name, nlen);
        for (i = 2; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if      (strEQ(o, "slots"))     slots     = SvUV(ST(i + 1));
            else if (strEQ(o, "slot_size")) slot_size = SvUV(ST(i + 1));
        }
        if (slots < 2) slots = 2;
        if (sa_ring_capacity((uint32_t)slot_size) == 0)
            croak("Shared::Arena: slot_size %lu is smaller than a slot header",
                  (unsigned long)slot_size);

        e = sa_carve(arena, nm, (size_t)nlen,
                     sa_ring_bytes((uint64_t)slots, (uint32_t)slot_size),
                     SA_T_RING, &err);
        if (!e) croak("Shared::Arena: the ring '%s' %s", nm, sa_strerror(err));

        r = sa_ring_bind(arena, e, (uint64_t)slots, (uint32_t)slot_size, &err);
        if (!r) croak("Shared::Arena: the ring '%s' %s", nm, sa_strerror(err));

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Ring", (void *)r);
        /* The ring borrows the arena's mapping, so the arena must outlive it.
         * Holding a reference in the ring's own magic is what makes
         * `my $r = Shared::Arena->create(...)->ring('x')` safe rather than a
         * use-after-free the moment the temporary arena goes. */
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Ring    PREFIX = sarr_

# The SEQUENCE the record was given, which is greater than zero for every
# published record; 0 when there is no ring, and -1 when the record was refused
# for size.
#
# One value rather than a pair, and not a context-sensitive one. `publish`
# returning (rc, seq) in list context reads well and then breaks the moment
# somebody writes `is($ring->publish(...), 1)` - which calls it in LIST context
# and compares the two returned values against each other. Sequences start at 1,
# so a single number carries both answers with no trap in it.
IV
sarr_publish(self, topic, payload)
        SV *self
        SV *topic
        SV *payload
    PREINIT:
        sa_ring *r;
        const char *t, *p;
        STRLEN tlen, plen;
        uint64_t seq = 0;
        int rc;
    CODE:
        r = SA_SELF(sa_ring, self);
        if (!r) croak("Shared::Arena::Ring: this ring is released");
        t = SvPV(topic, tlen);
        p = SvPV(payload, plen);
        rc = sa_ring_publish(r, t, (uint32_t)tlen, p, (uint32_t)plen, &seq);
        RETVAL = (rc == SA_PUB_OK) ? (IV)seq : (IV)rc;
    OUTPUT:
        RETVAL

# The largest topic+payload one record can carry. A RUNTIME accessor and never
# a constant a caller compiles in: a consumer that hard-codes the number is a
# consumer that starts silently refusing records the day the ring is configured
# with a different slot size.
UV
sarr_max_record(self)
        SV *self
    PREINIT:
        sa_ring *r;
    CODE:
        r = SA_SELF(sa_ring, self);
        if (!r) croak("Shared::Arena::Ring: this ring is released");
        RETVAL = (UV)r->record_max;
    OUTPUT:
        RETVAL

# What ONE slot carries. `max_record` is this times the slots a record may
# span; a caller sizing a ring wants both numbers.
UV
sarr_slot_bytes(self)
        SV *self
    PREINIT:
        sa_ring *r;
    CODE:
        r = SA_SELF(sa_ring, self);
        if (!r) croak("Shared::Arena::Ring: this ring is released");
        RETVAL = (UV)r->payload_max;
    OUTPUT:
        RETVAL

UV
sarr_slots(self)
        SV *self
    PREINIT:
        sa_ring *r;
    CODE:
        r = SA_SELF(sa_ring, self);
        if (!r) croak("Shared::Arena::Ring: this ring is released");
        RETVAL = (UV)r->nslots;
    OUTPUT:
        RETVAL

# published / oversize / seq, as a list of pairs.
void
sarr_stats(self)
        SV *self
    PREINIT:
        sa_ring *r;
    PPCODE:
        r = SA_SELF(sa_ring, self);
        if (!r) croak("Shared::Arena::Ring: this ring is released");
        EXTEND(SP, 6);
        mPUSHp("published", 9);
        mPUSHu((UV)sa_at_load64_acq(&r->hdr->published));
        mPUSHp("oversize", 8);
        mPUSHu((UV)sa_at_load64_acq(&r->hdr->oversize));
        mPUSHp("seq", 3);
        mPUSHu((UV)sa_at_load64_acq(&r->hdr->seq));

# $ring->cursor(from_start => 1)
#
# A cursor starts at NOW by default, which is what a tail wants: a process that
# attaches to a busy ring is asking about what happens next, not about the last
# ten thousand records it missed.
SV *
sarr_cursor(self, ...)
        SV *self
    PREINIT:
        sa_ring *r;
        sa_cursor *c;
        int from_start = 0;
        I32 i;
        SV *obj;
    CODE:
        r = SA_SELF(sa_ring, self);
        if (!r) croak("Shared::Arena::Ring: this ring is released");
        for (i = 1; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if (strEQ(o, "from_start")) from_start = SvTRUE(ST(i + 1));
        }
        c = sa_cursor_new(r, from_start);
        if (!c) croak("Shared::Arena::Ring: out of memory");
        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Ring::Cursor", (void *)c);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Ring    PREFIX = sarrd_

void
sarrd_DESTROY(self)
        SV *self
    PREINIT:
        sa_ring *r;
    CODE:
        r = SA_SELF(sa_ring, self);
        if (r) { sa_ring_free(r); sv_setiv(SvRV(self), 0); }

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Ring::Cursor    PREFIX = sarc_

# Everything published since this cursor last looked, as ([topic, payload], ...).
#
# The collector builds the list in C rather than calling back into Perl per
# record, because a drain of ten thousand records should not be ten thousand
# Perl frames.
void
sarc_drain(self, ...)
        SV *self
    PREINIT:
        sa_cursor *c;
        IV max = 0;
        I32 i;
    PPCODE:
        c = SA_SELF(sa_cursor, self);
        if (!c) croak("Shared::Arena::Ring::Cursor: this cursor is released");
        for (i = 1; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if (strEQ(o, "max")) max = SvIV(ST(i + 1));
        }
        {
            uint64_t end;
            /* Draining is proof of life too: a peer that only ever reads must
             * still tick, or a publisher's hole check would judge it wedged. */
            sa_peer_join(c->ring->arena);
            sa_peer_beat(c->ring->arena);
            sa_cursor_catchup(c);
            end = sa_at_load64_acq(&c->ring->hdr->seq);
            while (c->seq < end && (max <= 0 || (IV)(SP - MARK) < max)) {
                const char *topic = NULL, *data = NULL;
                uint32_t tlen = 0, dlen = 0, flags = 0;
                uint64_t span = 1;
                int rc = sa_ring_read(c, c->seq, &topic, &tlen,
                                      &data, &dlen, &flags, &span);
                if (rc == SA_READ_PENDING) {
                    /* A hole. Wait on the QUESTION of whether its publisher is
                     * alive, not on a clock, and fill it if the answer is no. */
                    if (!sa_ring_tombstone(c, c->seq)) break;
                    rc = sa_ring_read(c, c->seq, &topic, &tlen,
                                      &data, &dlen, &flags, &span);
                    if (rc != SA_READ_OK) break;
                }
                if (rc == SA_READ_LAPPED) { c->lapped++; c->seq++; continue; }
                if (flags & SA_SF_CONT) {
                    /* A continuation reached on its own means its head was
                     * missed: a delivered record jumps the cursor past its own
                     * tail. Counted as lapped, because `lapped` is in SLOTS and
                     * a lost record cost every slot it spanned. */
                    c->lapped++;
                    c->seq++;
                    continue;
                }
                if (flags & SA_SF_ABANDONED) {
                    /* Counted apart from `lapped`, because they are different
                     * diagnoses: lapped means this reader is too slow or the
                     * ring too small, abandoned means a process died mid-write
                     * and somebody should go and look at why. */
                    c->abandoned++;
                    c->seq++;
                    continue;
                }
                {
                    /* [topic, payload, sequence]. The sequence is the record's
                     * identity: it is what a gap is counted in, and what two
                     * cursors compare when they disagree about what they saw. */
                    AV *av = newAV();
                    av_push(av, newSVpvn(topic, tlen));
                    av_push(av, newSVpvn(data, dlen));
                    av_push(av, newSVuv((UV)c->seq));
                    XPUSHs(sv_2mortal(newRV_noinc((SV *)av)));
                }
                c->delivered++;
                c->seq += span;
            }
        }

# delivered / lapped / seq. `lapped` is the number this cursor LOST, and it is
# a per-cursor number on purpose: one slow reader being overtaken says nothing
# about any other.
void
sarc_stats(self)
        SV *self
    PREINIT:
        sa_cursor *c;
    PPCODE:
        c = SA_SELF(sa_cursor, self);
        if (!c) croak("Shared::Arena::Ring::Cursor: this cursor is released");
        EXTEND(SP, 10);
        mPUSHp("delivered", 9);    mPUSHu((UV)c->delivered);
        mPUSHp("lapped", 6);       mPUSHu((UV)c->lapped);
        mPUSHp("abandoned", 9);    mPUSHu((UV)c->abandoned);
        mPUSHp("unattributed", 12);mPUSHu((UV)c->unattributed);
        mPUSHp("seq", 3);          mPUSHu((UV)c->seq);

void
sarc_DESTROY(self)
        SV *self
    PREINIT:
        sa_cursor *c;
    CODE:
        c = SA_SELF(sa_cursor, self);
        if (c) { sa_cursor_free(c); sv_setiv(SvRV(self), 0); }
