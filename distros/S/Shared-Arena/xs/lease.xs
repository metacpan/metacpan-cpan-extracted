# Shared::Arena::Lease - one holder at a time, a successor when it dies.
#
# Leader election on a fork-shared arena: whoever holds the lease is the one,
# and when the holder stops renewing - it exited, crashed, or wedged - a
# successor takes it over. The deadline carries correctness; the pid check only
# makes a handover happen sooner when the holder is provably gone.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->lease($name, ttl => 30)
#
# `ttl` (seconds, default 30) is how long an acquire or renew keeps the lease
# before it lapses. A holder must renew inside it; the length is a property of
# this handle, applied by acquire/renew unless one is passed there.
SV *
sar_lease(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_lease *lh;
        const char *nm;
        STRLEN nlen;
        double ttl = 30.0;
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
            if (strEQ(o, "ttl")) ttl = SvNV(ST(i + 1));
        }
        if (!(ttl > 0.0)) ttl = 30.0;
#if SA_HAVE_ATOMICS
        lh = sa_lease_bind(arena, nm, (uint32_t)nlen, &err);
        if (!lh) croak("Shared::Arena: the lease '%s' %s", nm, sa_strerror(err));
        lh->ttl_ms = (uint64_t)(ttl * 1000.0 + 0.5);
        if (!lh->ttl_ms) lh->ttl_ms = 1;
#else
        croak("Shared::Arena: leases need atomics this build does not have");
#endif
        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Lease", (void *)lh);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Lease    PREFIX = sal_

# Take the lease, or extend it if we already hold it. True when this process
# holds it afterwards, false when somebody else holds a current one.
#
# In list context returns (held, stole): `stole` is true when this acquire took
# over a holder that had lapsed or died - i.e. you have just become leader after
# a predecessor failed, not started from a free lease. A caller that must run
# recovery on takeover keys off it.
void
sal_acquire(self, ...)
        SV *self
    PREINIT:
        sa_lease *lh;
        uint64_t ttl_ms;
        int held = 0, stole = 0;
        I32 i;
    PPCODE:
        lh = SA_SELF(sa_lease, self);
        if (!lh) croak("Shared::Arena::Lease: this lease is released");
        ttl_ms = lh->ttl_ms;
        for (i = 1; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if (strEQ(o, "ttl")) ttl_ms = (uint64_t)(SvNV(ST(i + 1)) * 1000.0 + 0.5);
        }
        if (!ttl_ms) ttl_ms = 1;
#if SA_HAVE_ATOMICS
        held = (sa_lease_acquire(lh, ttl_ms, &stole) == SA_LEASE_HELD);
#endif
        if (GIMME_V == G_ARRAY) {
            EXTEND(SP, 2);
            mPUSHi(held ? 1 : 0);
            mPUSHi(stole ? 1 : 0);
        }
        else {
            mPUSHi(held ? 1 : 0);
        }

# Extend a lease we hold. True while we still hold it at the generation we
# acquired; false once a successor has taken it - a holder that comes back from
# a long pause finds out here rather than acting on a lease it has lost.
int
sal_renew(self, ...)
        SV *self
    PREINIT:
        sa_lease *lh;
        uint64_t ttl_ms;
        I32 i;
    CODE:
        lh = SA_SELF(sa_lease, self);
        if (!lh) croak("Shared::Arena::Lease: this lease is released");
        ttl_ms = lh->ttl_ms;
        for (i = 1; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if (strEQ(o, "ttl")) ttl_ms = (uint64_t)(SvNV(ST(i + 1)) * 1000.0 + 0.5);
        }
        if (!ttl_ms) ttl_ms = 1;
#if SA_HAVE_ATOMICS
        RETVAL = (sa_lease_renew(lh, ttl_ms) == SA_LEASE_HELD) ? 1 : 0;
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

# Give the lease up now, so a successor takes it at once rather than after the
# deadline. True when we held it and released it.
int
sal_release(self)
        SV *self
    PREINIT:
        sa_lease *lh;
    CODE:
        lh = SA_SELF(sa_lease, self);
        if (!lh) croak("Shared::Arena::Lease: this lease is released");
#if SA_HAVE_ATOMICS
        RETVAL = sa_lease_release(lh);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

# Do we hold it right now, at our generation, unlapsed?
int
sal_mine(self)
        SV *self
    PREINIT:
        sa_lease *lh;
    CODE:
        lh = SA_SELF(sa_lease, self);
        if (!lh) croak("Shared::Arena::Lease: this lease is released");
#if SA_HAVE_ATOMICS
        RETVAL = sa_lease_mine(lh);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

# The pid that effectively holds the lease now, or 0 when it is free or lapsed.
# A lapsed holder reports 0, not its stale pid: a successor could take it this
# instant, so the old pid is not an answer a caller should act on.
UV
sal_holder(self)
        SV *self
    PREINIT:
        sa_lease *lh;
    CODE:
        lh = SA_SELF(sa_lease, self);
        if (!lh) croak("Shared::Arena::Lease: this lease is released");
#if SA_HAVE_ATOMICS
        RETVAL = (UV)sa_lease_holder(lh);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

# The fencing token of this handle's tenure: the generation the last acquire
# won at. Stamp it on writes the lease protects, and the resource can reject a
# write from a leader that was superseded while it was paused - the late write
# carries an older fence than the one the successor now uses.
UV
sal_fence(self)
        SV *self
    PREINIT:
        sa_lease *lh;
    CODE:
        lh = SA_SELF(sa_lease, self);
        if (!lh) croak("Shared::Arena::Lease: this lease is released");
#if SA_HAVE_ATOMICS
        RETVAL = (UV)sa_lease_fence(lh);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

# name / held / holder / fence / acquires / steals
#
# `acquires` is every time the lease changed hands, including the first take and
# every takeover; `steals` is the subset that took it from a lapsed or dead
# holder. A steals count climbing in steady state means holders are dying or
# failing to renew - the number that says the lease is doing its job, or that
# the ttl is too short for how often the holder actually renews.
void
sal_stats(self)
        SV *self
    PREINIT:
        sa_lease *lh;
    PPCODE:
        lh = SA_SELF(sa_lease, self);
        if (!lh) croak("Shared::Arena::Lease: this lease is released");
        EXTEND(SP, 12);
        mPUSHp("name", 4);
        mPUSHp(lh->slot->name, strlen(lh->slot->name));
#if SA_HAVE_ATOMICS
        mPUSHp("held", 4);      mPUSHi(sa_lease_mine(lh));
        mPUSHp("holder", 6);    mPUSHu((UV)sa_lease_holder(lh));
        mPUSHp("fence", 5);     mPUSHu((UV)lh->gen);
        mPUSHp("acquires", 8);
        mPUSHu((UV)sa_at_load64_acq(&lh->slot->acquires));
        mPUSHp("steals", 6);
        mPUSHu((UV)sa_at_load64_acq(&lh->slot->steals));
#endif

void
sal_DESTROY(self)
        SV *self
    PREINIT:
        sa_lease *lh;
    CODE:
        lh = SA_SELF(sa_lease, self);
        /* A handle going out of scope is NOT a release: the lease in the
         * mapping outlives it, and a process that still holds it keeps holding
         * it until it lapses or calls release. Freeing the handle only drops
         * this process's view. */
        if (lh) { sa_lease_free(lh); sv_setiv(SvRV(self), 0); }
