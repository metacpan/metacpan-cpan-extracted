# Shared::Arena::Scoreboard - one row per worker, published live.
#
# Every other shared table has many writers to one structure. This is the
# inverse: each worker owns one row and is its only writer, so an update takes
# no lock, and a reader - a status page, the supervisor - reads every row in one
# pass. Apache's scoreboard, for a fork-shared pool.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->scoreboard($name, fields => ['inflight','served'], slots => 256)
#
# `fields` names the gauge columns, set once by whoever creates the board; a
# later caller names the same ones or inherits them. `slots` is how many workers
# it holds; both cost memory for the life of the board.
SV *
sar_scoreboard(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_sb *b;
        const char *nm;
        STRLEN nlen;
        UV slots = 0;                 /* 0 = not given: inherit or default   */
        uint64_t want;
        const char *fbuf[SA_SB_FIELDS];
        uint32_t nfields = 0;
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
            if (strEQ(o, "slots")) slots = SvUV(ST(i + 1));
            else if (strEQ(o, "fields") && SvROK(ST(i + 1))
                     && SvTYPE(SvRV(ST(i + 1))) == SVt_PVAV) {
                AV *av = (AV *)SvRV(ST(i + 1));
                I32 n = av_len(av) + 1, j;
                if (n > SA_SB_FIELDS)
                    croak("Shared::Arena: a scoreboard holds at most %d fields",
                          (int)SA_SB_FIELDS);
                for (j = 0; j < n; j++) {
                    SV **el = av_fetch(av, j, 0);
                    fbuf[j] = el ? SvPV_nolen(*el) : "";
                }
                nfields = (uint32_t)n;
            }
        }
        /* `slots` is inherited, like `fields`: a worker asking for an existing
         * board by name should not have to know how big the supervisor made it.
         * If it was not given, bind to whatever is already there; only invent a
         * default when creating the board fresh. This carves at the requested
         * size only when a size was actually requested - passing a default here
         * would make every re-bind a shape mismatch against the real board. */
        if (slots) {
            if (slots > SA_SB_SLOTS_MAX) slots = SA_SB_SLOTS_MAX;
            want = sa_sb_bytes((uint32_t)slots);
        }
        else if (sa_find(arena, nm, (size_t)nlen)) {
            want = 0;                 /* it exists: find it, do not resize    */
        }
        else {
            want = sa_sb_bytes(256);  /* creating fresh: a default            */
        }

        e = sa_carve(arena, nm, (size_t)nlen, want, SA_T_SCOREBOARD, &err);
        if (!e) croak("Shared::Arena: the scoreboard '%s' %s", nm,
                      sa_strerror(err));
#if SA_HAVE_ATOMICS
        b = sa_sb_bind(arena, e, fbuf, nfields, &err);
        if (!b) croak("Shared::Arena: the scoreboard '%s' %s", nm,
                      sa_strerror(err));
#else
        croak("Shared::Arena: scoreboards need atomics this build does not have");
#endif
        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Scoreboard", (void *)b);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Scoreboard    PREFIX = sasb_

# Claim a row for this process, reclaiming a dead worker's row if the board is
# full. Returns the row index, or undef when every row belongs to a live worker.
# Idempotent - call it again in the same process and it returns the row it
# already holds. Call it once at worker start, after the fork.
SV *
sasb_take(self)
        SV *self
    PREINIT:
        sa_sb *b;
        int idx;
    CODE:
        b = SA_SELF(sa_sb, self);
        if (!b) croak("Shared::Arena::Scoreboard: this board is released");
#if SA_HAVE_ATOMICS
        idx = sa_sb_take(b);
#else
        idx = -1;
#endif
        RETVAL = (idx < 0) ? &PL_sv_undef : newSViv(idx);
    OUTPUT:
        RETVAL

# Our row index, or undef if we hold none.
SV *
sasb_mine(self)
        SV *self
    PREINIT:
        sa_sb *b;
    CODE:
        b = SA_SELF(sa_sb, self);
        if (!b) croak("Shared::Arena::Scoreboard: this board is released");
        RETVAL = (b->mine < 0) ? &PL_sv_undef : newSViv(b->mine);
    OUTPUT:
        RETVAL

# $sb->update(inflight => 3, served => 128, status => 'GET /x')
#
# Set gauge fields (by name) and/or the status line, in ONE coherent update: a
# reader sees them all as of one instant, never a mix of before and after. An
# unknown field name is a croak, not a silent no-op - a typo'd column is a bug.
# This is the call to put on the request path.
void
sasb_update(self, ...)
        SV *self
    PREINIT:
        sa_sb *b;
        sa_sb_slot *s;
        I32 i;
    CODE:
        b = SA_SELF(sa_sb, self);
        if (!b) croak("Shared::Arena::Scoreboard: this board is released");
        if (b->mine < 0 && sa_sb_take(b) < 0)
            croak("Shared::Arena::Scoreboard: the board is full, no row to write");
#if SA_HAVE_ATOMICS
        s = sa_sb_begin(b);
        if (s) {
            for (i = 1; i + 1 < items; i += 2) {
                STRLEN kl;
                const char *k = SvPV(ST(i), kl);
                if (strEQ(k, "status")) {
                    STRLEN vl;
                    const char *v = SvPV(ST(i + 1), vl);
                    sa_sb_set_status(s, v, (uint32_t)vl);
                }
                else {
                    int fi = sa_sb_field(b, k, (uint32_t)kl);
                    if (fi < 0) {
                        sa_sb_end(b, s);
                        croak("Shared::Arena::Scoreboard: no field '%s'", k);
                    }
                    sa_sb_set_gauge(s, fi, (uint64_t)SvUV(ST(i + 1)));
                }
            }
            sa_sb_end(b, s);
        }
#endif

# $sb->incr(served => 1, bytes => $n) - add to gauge fields, coherent. Negative
# steps allowed. Same one-instant snapshot as update.
void
sasb_incr(self, ...)
        SV *self
    PREINIT:
        sa_sb *b;
        sa_sb_slot *s;
        I32 i;
    CODE:
        b = SA_SELF(sa_sb, self);
        if (!b) croak("Shared::Arena::Scoreboard: this board is released");
        if (b->mine < 0 && sa_sb_take(b) < 0)
            croak("Shared::Arena::Scoreboard: the board is full, no row to write");
#if SA_HAVE_ATOMICS
        s = sa_sb_begin(b);
        if (s) {
            for (i = 1; i + 1 < items; i += 2) {
                STRLEN kl;
                const char *k = SvPV(ST(i), kl);
                int fi = sa_sb_field(b, k, (uint32_t)kl);
                if (fi < 0) {
                    sa_sb_end(b, s);
                    croak("Shared::Arena::Scoreboard: no field '%s'", k);
                }
                sa_sb_add_gauge(s, fi, (int64_t)SvIV(ST(i + 1)));
            }
            sa_sb_end(b, s);
        }
#endif

# $sb->status('idle') - just the status line.
void
sasb_status(self, str)
        SV *self
        SV *str
    PREINIT:
        sa_sb *b;
        sa_sb_slot *s;
        const char *p;
        STRLEN len;
    CODE:
        b = SA_SELF(sa_sb, self);
        if (!b) croak("Shared::Arena::Scoreboard: this board is released");
        if (b->mine < 0 && sa_sb_take(b) < 0)
            croak("Shared::Arena::Scoreboard: the board is full, no row to write");
        p = SvPV(str, len);
#if SA_HAVE_ATOMICS
        s = sa_sb_begin(b);
        if (s) { sa_sb_set_status(s, p, (uint32_t)len); sa_sb_end(b, s); }
#endif

# The whole board, as a list of hashrefs - one per live row, in row order:
#   { row, pid, epoch, updated, alive, status, <field> => <value>, ... }
#
# `alive` is whether the owner process is still running; a dead worker's row is
# shown with alive => 0 rather than dropped, so a supervisor can see who died.
# A row whose writer died MID-update is skipped: it cannot be read coherently
# and reporting a torn snapshot would be worse than reporting one fewer worker.
void
sasb_all(self)
        SV *self
    PREINIT:
        sa_sb *b;
        uint32_t i, f;
    PPCODE:
        b = SA_SELF(sa_sb, self);
        if (!b) croak("Shared::Arena::Scoreboard: this board is released");
#if SA_HAVE_ATOMICS
        for (i = 0; i < b->nslots; i++) {
            sa_sb_reading rd;
            HV *h;
            if (!sa_sb_read(b, i, &rd)) continue;
            h = newHV();
            (void)hv_stores(h, "row",     newSVuv((UV)i));
            (void)hv_stores(h, "pid",     newSVuv((UV)rd.pid));
            (void)hv_stores(h, "epoch",   newSVuv((UV)rd.epoch));
            (void)hv_stores(h, "updated", newSVuv((UV)rd.updated));
            (void)hv_stores(h, "alive",   newSViv(rd.alive));
            (void)hv_stores(h, "status",  newSVpvn(rd.status, rd.statuslen));
            for (f = 0; f < b->nfields; f++) {
                const char *fn = b->hdr->fields[f];
                (void)hv_store(h, fn, (I32)strlen(fn),
                               newSVuv((UV)rd.gauges[f]), 0);
            }
            mXPUSHs(newRV_noinc((SV *)h));
        }
#endif

# The field names, in order.
void
sasb_fields(self)
        SV *self
    PREINIT:
        sa_sb *b;
        uint32_t f;
    PPCODE:
        b = SA_SELF(sa_sb, self);
        if (!b) croak("Shared::Arena::Scoreboard: this board is released");
        for (f = 0; f < b->nfields; f++)
            mXPUSHp(b->hdr->fields[f], strlen(b->hdr->fields[f]));

UV
sasb_slots(self)
        SV *self
    PREINIT:
        sa_sb *b;
    CODE:
        b = SA_SELF(sa_sb, self);
        if (!b) croak("Shared::Arena::Scoreboard: this board is released");
        RETVAL = (UV)b->nslots;
    OUTPUT:
        RETVAL

# live / alive / dead - a quick count for a header line: rows claimed, rows
# whose owner is running, rows whose owner has died but not yet been reclaimed.
void
sasb_stats(self)
        SV *self
    PREINIT:
        sa_sb *b;
        uint32_t i, live = 0, alive = 0;
    PPCODE:
        b = SA_SELF(sa_sb, self);
        if (!b) croak("Shared::Arena::Scoreboard: this board is released");
#if SA_HAVE_ATOMICS
        for (i = 0; i < b->nslots; i++) {
            sa_sb_reading rd;
            if (!sa_sb_read(b, i, &rd)) continue;
            live++;
            if (rd.alive) alive++;
        }
#endif
        EXTEND(SP, 6);
        mPUSHp("slots", 5); mPUSHu((UV)b->nslots);
        mPUSHp("live", 4);  mPUSHu((UV)live);
        mPUSHp("alive", 5); mPUSHu((UV)alive);

void
sasb_DESTROY(self)
        SV *self
    PREINIT:
        sa_sb *b;
    CODE:
        b = SA_SELF(sa_sb, self);
        /* A handle going out of scope leaves this process's row where it is -
         * the row belongs to the process, not the handle, and a supervisor
         * still reads it until the process exits and a successor reclaims it. */
        if (b) { sa_sb_free(b); sv_setiv(SvRV(self), 0); }
