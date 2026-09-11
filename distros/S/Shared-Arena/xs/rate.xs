# Shared::Arena::Rate - a token bucket per key, shared by every worker.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->rate($name, limit => 100, window => 60, slots => 4096)
#
# `limit` is the burst - the most a key may spend at once - and `window` is how
# long a full refill takes, in seconds. Together they are the sustained rate.
# Both are the limiter's, not the caller's: a second policy is a second carve,
# which costs a few kilobytes and cannot be got wrong by two callers passing
# different numbers for one table.
SV *
sar_rate(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_rate *rl;
        const char *nm;
        STRLEN nlen;
        UV limit = 100, slots = 4096;
        double window = 60.0;
        uint64_t nslots, burst_u, window_ms;
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
            if      (strEQ(o, "limit"))  limit  = SvUV(ST(i + 1));
            else if (strEQ(o, "window")) window = SvNV(ST(i + 1));
            else if (strEQ(o, "slots"))  slots  = SvUV(ST(i + 1));
        }
        if (limit < 1) limit = 1;
        if (!(window > 0.0)) window = 60.0;
        /* A burst is counted in whole requests, so the scaled form has to fit
         * the 32 bits a packed bucket gives it. */
        if (limit > 0x3FFFFFu) limit = 0x3FFFFFu;
        burst_u   = (uint64_t)limit * SA_RATE_SCALE;
        window_ms = (uint64_t)(window * 1000.0 + 0.5);
        if (!window_ms) window_ms = 1;
        nslots    = sa_rate_pow2((uint64_t)slots);

        e = sa_carve(arena, nm, (size_t)nlen, sa_rate_bytes(nslots),
                     SA_T_RATE, &err);
        if (!e) croak("Shared::Arena: the limiter '%s' %s", nm, sa_strerror(err));

        rl = sa_rate_bind(arena, e, nslots, burst_u, window_ms, &err);
        if (!rl) croak("Shared::Arena: the limiter '%s' %s", nm, sa_strerror(err));

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Rate", (void *)rl);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Rate    PREFIX = sart_

# 1 when the request is within the limit, 0 when it is not. A second argument
# is the cost, for a caller charging an expensive route more than a cheap one.
#
# An INT rather than a list, so `if ($rl->allow($ip))` cannot be read as
# anything else. The numbers for an X-RateLimit header come from `remaining`
# and `retry_after`, which do not spend a token.
int
sart_allow(self, key, ...)
        SV *self
        SV *key
    PREINIT:
        sa_rate *rl;
        const char *k;
        STRLEN klen;
        UV cost = 1;
    CODE:
        rl = SA_SELF(sa_rate, self);
        if (!rl) croak("Shared::Arena::Rate: this limiter is released");
        if (items > 2) cost = SvUV(ST(2));
        if (cost < 1) cost = 1;
        k = SvPV(key, klen);
#if SA_HAVE_ATOMICS
        RETVAL = sa_rate_take(rl, k, (uint32_t)klen,
                              (uint64_t)cost * SA_RATE_SCALE, 0, NULL, NULL);
#else
        RETVAL = 1;      /* no atomics: the limiter is not the reason a good
                          * request is refused */
#endif
    OUTPUT:
        RETVAL

# What the key could spend right now, in whole requests, WITHOUT spending one.
NV
sart_remaining(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_rate *rl;
        const char *k;
        STRLEN klen;
        uint64_t left = 0;
    CODE:
        rl = SA_SELF(sa_rate, self);
        if (!rl) croak("Shared::Arena::Rate: this limiter is released");
        k = SvPV(key, klen);
#if SA_HAVE_ATOMICS
        (void)sa_rate_take(rl, k, (uint32_t)klen,
                           (uint64_t)SA_RATE_SCALE, 1, &left, NULL);
        RETVAL = (NV)left / (NV)SA_RATE_SCALE;
#else
        RETVAL = (NV)0;
#endif
    OUTPUT:
        RETVAL

# Seconds until one more request would be allowed. Zero when one already is.
# This is the number a Retry-After header wants.
NV
sart_retry_after(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_rate *rl;
        const char *k;
        STRLEN klen;
        uint64_t retry = 0;
    CODE:
        rl = SA_SELF(sa_rate, self);
        if (!rl) croak("Shared::Arena::Rate: this limiter is released");
        k = SvPV(key, klen);
#if SA_HAVE_ATOMICS
        (void)sa_rate_take(rl, k, (uint32_t)klen,
                           (uint64_t)SA_RATE_SCALE, 1, NULL, &retry);
        RETVAL = (NV)retry / (NV)1000.0;
#else
        RETVAL = (NV)0;
#endif
    OUTPUT:
        RETVAL

# Refill one key to full: an operator lifting a limit by hand, or a test.
void
sart_reset(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_rate *rl;
        const char *k;
        STRLEN klen;
    CODE:
        rl = SA_SELF(sa_rate, self);
        if (!rl) croak("Shared::Arena::Rate: this limiter is released");
        k = SvPV(key, klen);
#if SA_HAVE_ATOMICS
        sa_rate_reset_key(rl, k, (uint32_t)klen);
#else
        PERL_UNUSED_VAR(k);
#endif

# Give the key's slot back, so somebody else can have it.
void
sart_forget(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_rate *rl;
        const char *k;
        STRLEN klen;
    CODE:
        rl = SA_SELF(sa_rate, self);
        if (!rl) croak("Shared::Arena::Rate: this limiter is released");
        k = SvPV(key, klen);
#if SA_HAVE_ATOMICS
        sa_rate_forget(rl, k, (uint32_t)klen);
#else
        PERL_UNUSED_VAR(k);
#endif

UV
sart_slots(self)
        SV *self
    PREINIT:
        sa_rate *rl;
    CODE:
        rl = SA_SELF(sa_rate, self);
        if (!rl) croak("Shared::Arena::Rate: this limiter is released");
        RETVAL = (UV)rl->nslots;
    OUTPUT:
        RETVAL

# limit / window / slots / keys / allowed / denied / evicted / contended
#
# `evicted` is how many live buckets were taken over because the table had no
# room, which is how you find out the table is too small. `contended` is how
# many hits gave up on the compare-and-swap and were ALLOWED without being
# counted against anybody - a limiter that has stopped limiting, which is a
# thing an operator has to be able to see rather than infer from a suspiciously
# clean denied count.
void
sart_stats(self)
        SV *self
    PREINIT:
        sa_rate *rl;
    PPCODE:
        rl = SA_SELF(sa_rate, self);
        if (!rl) croak("Shared::Arena::Rate: this limiter is released");
        EXTEND(SP, 16);
        mPUSHp("limit", 5);
        mPUSHn((NV)rl->burst_u / (NV)SA_RATE_SCALE);
        mPUSHp("window", 6);
        mPUSHn((NV)rl->window_ms / (NV)1000.0);
        mPUSHp("slots", 5);     mPUSHu((UV)rl->nslots);
#if SA_HAVE_ATOMICS
        mPUSHp("keys", 4);      mPUSHu((UV)sa_rate_used(rl));
        mPUSHp("allowed", 7);   mPUSHu((UV)sa_at_load64_acq(&rl->hdr->allowed));
        mPUSHp("denied", 6);    mPUSHu((UV)sa_at_load64_acq(&rl->hdr->denied));
        mPUSHp("evicted", 7);   mPUSHu((UV)sa_at_load64_acq(&rl->hdr->evicted));
        mPUSHp("contended", 9);
        mPUSHu((UV)sa_at_load64_acq(&rl->hdr->contended));
#endif

void
sart_DESTROY(self)
        SV *self
    PREINIT:
        sa_rate *rl;
    CODE:
        rl = SA_SELF(sa_rate, self);
        if (rl) { sa_rate_free(rl); sv_setiv(SvRV(self), 0); }

# TEST ONLY, and underscore-named because of it. Move a key's stored timestamp
# forward, which is precisely what a process whose clock reading is a
# millisecond ahead does to every other caller.
#
# The race this reproduces needs three processes and half a second of contention
# to happen by accident, and then happens 88 times in 1.5M calls. This produces
# it exactly, once, in one process, with no timing at all. A test that has to
# win a race to see a bug is a test that will one day stop seeing it.
void
sart__skew(self, key, ms)
        SV *self
        SV *key
        IV ms
    PREINIT:
        sa_rate *rl;
        const char *k;
        STRLEN klen;
        uint64_t h, idx, state;
    CODE:
        rl = SA_SELF(sa_rate, self);
        if (!rl) croak("Shared::Arena::Rate: this limiter is released");
#if SA_HAVE_ATOMICS
        k = SvPV(key, klen);
        h = sa_at_fnv(k, (size_t)klen);
        if (!h) h = 1;
        idx   = sa_rate_slot_for(rl, h, sa_rate_now_ms(), NULL);
        state = sa_at_load64_acq(&rl->slots[idx].state);
        sa_at_store64_rel(&rl->slots[idx].state,
            SA_RATE_STATE(SA_RATE_TOKENS(state),
                          (uint32_t)((uint32_t)SA_RATE_WHEN(state)
                                     + (uint32_t)(int32_t)ms)));
#else
        PERL_UNUSED_VAR(key);
        PERL_UNUSED_VAR(ms);
#endif
