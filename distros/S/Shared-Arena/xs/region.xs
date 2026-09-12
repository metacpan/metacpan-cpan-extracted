# The region's Perl surface.
#
# The object is a blessed SV carrying the sa_region pointer, and every entry
# takes it explicitly. There is no file-scope state anywhere in this dist, which
# is the property that stops a second consumer quietly getting a second region
# instead of sharing the first.

MODULE = Shared::Arena    PACKAGE = Shared::Arena

# Shared::Arena->create(size => N, name => 'x', regions => N)
#
# A name makes it a named segment another process can attach; without one it is
# anonymous and reaches only fork children. Creating a name that already exists
# ATTACHES to it, which is what lets every worker run the same setup code.
SV *
create(class, ...)
        SV *class
    PREINIT:
        sa_region *r;
        const char *name = NULL;
        STRLEN nlen = 0;
        UV size = 1024 * 1024;
        UV regions = SA_REGIONS_MAX;
        int err = SA_E_OK;
        I32 i;
        SV *obj;
    CODE:
        for (i = 1; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if      (strEQ(o, "size"))    size    = SvUV(ST(i + 1));
            else if (strEQ(o, "regions")) regions = SvUV(ST(i + 1));
            else if (strEQ(o, "name") && SvOK(ST(i + 1)))
                name = SvPV(ST(i + 1), nlen);
        }
        if (regions < 1) regions = 1;
        if (regions > 4096) regions = 4096;
        /* The header and its registry come out of the same mapping, so a caller
         * asking for a megabyte gets a megabyte of usable region plus what the
         * bookkeeping costs, rather than silently less than it asked for.
         *
         * CHECKED, because this is unsigned arithmetic on a number that came
         * from Perl: `size => ~0` wrapped round to a few hundred bytes and
         * created a region far SMALLER than the one that was refused, with a
         * header that agreed with itself and a caller that had asked for
         * everything. Refusing is the only honest answer to a size that cannot
         * be represented. */
        {
            UV bookkeeping = (UV)sa_header_bytes((uint32_t)regions);
            if (size > (UV)-1 - bookkeeping)
                croak("Shared::Arena: a region of %" UVuf " bytes plus its "
                      "header does not fit an unsigned integer", size);
            size += bookkeeping;
        }

        r = sa_region_open(name, nlen, (uint64_t)size, (uint32_t)regions,
                           1, &err);
        if (!r) croak("Shared::Arena: the region %s", sa_strerror(err));

        obj = newSV(0);
        sv_setref_pv(obj, SvPV_nolen(class), (void *)r);
        RETVAL = obj;
    OUTPUT:
        RETVAL

# Shared::Arena->attach($name) - a process that is not a fork child.
#
# Named `attach` rather than `open` on purpose: a member or method called `open`
# is a function-like macro on every Strawberry perl, and this dist avoids those
# names rather than working around them at each call site.
SV *
attach(class, name)
        SV *class
        SV *name
    PREINIT:
        sa_region *r;
        const char *nm;
        STRLEN nlen;
        int err = SA_E_OK;
        SV *obj;
    CODE:
        nm = SvPV(name, nlen);
        /* Length 0 here means "attach whatever is there", and the header the
         * creator published says how big it really is. */
        r = sa_region_open(nm, nlen, (uint64_t)sa_header_bytes(SA_REGIONS_MAX),
                           SA_REGIONS_MAX, 0, &err);
        if (!r) XSRETURN_UNDEF;
        obj = newSV(0);
        sv_setref_pv(obj, SvPV_nolen(class), (void *)r);
        RETVAL = obj;
    OUTPUT:
        RETVAL

int
destroy(class, name)
        SV *class
        SV *name
    PREINIT:
        const char *nm;
        STRLEN nlen;
    CODE:
        PERL_UNUSED_VAR(class);
        nm = SvPV(name, nlen);
        RETVAL = (sa_region_destroy(nm, nlen) == SA_E_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
have_atomics(...)
    CODE:
        RETVAL = SA_HAVE_ATOMICS ? 1 : 0;
    OUTPUT:
        RETVAL

# A new thread gets no copy of anything here.
#
# Every object in this dist is a C pointer in a blessed scalar. Cloning an
# interpreter clones the scalar and shares the pointer, and whichever copy is
# destroyed first frees it under the other - or, for the region, unmaps the
# arena under the thread that made it. This makes the new thread's copies
# inert, and a thread that wants the arena attaches to it by name, as another
# process would.
int
CLONE_SKIP(...)
    ALIAS:
        Shared::Arena::Ring::CLONE_SKIP         = 1
        Shared::Arena::Ring::Cursor::CLONE_SKIP = 2
        Shared::Arena::Ring::Group::CLONE_SKIP  = 3
        Shared::Arena::Map::CLONE_SKIP          = 4
        Shared::Arena::Bloom::CLONE_SKIP        = 5
        Shared::Arena::Histogram::CLONE_SKIP    = 6
        Shared::Arena::Cache::CLONE_SKIP        = 7
        Shared::Arena::Rate::CLONE_SKIP         = 8
        Shared::Arena::CountMin::CLONE_SKIP     = 9
        Shared::Arena::Frozen::CLONE_SKIP       = 10
        Shared::Arena::Frozen::View::CLONE_SKIP = 11
        Shared::Arena::Cuckoo::CLONE_SKIP       = 12
        Shared::Arena::Lease::CLONE_SKIP        = 13
        Shared::Arena::Scoreboard::CLONE_SKIP   = 14
    CODE:
        PERL_UNUSED_VAR(ix);
        RETVAL = 1;
    OUTPUT:
        RETVAL

# The compiled layout, so t/01-format.t can assert from Perl what the C thinks
# it is. These numbers are in the region's own header at create, and a process
# whose build disagrees fails open rather than reading a shape it does not
# share - so they are a contract, not a curiosity.
void
_layout(...)
    PPCODE:
        EXTEND(SP, 14);
        mPUSHp("magic", 5);        mPUSHu((UV)SA_MAGIC);
        mPUSHp("layout", 6);       mPUSHu((UV)SA_LAYOUT_VERSION);
        mPUSHp("header", 6);       mPUSHu((UV)sizeof(sa_header));
        mPUSHp("reg", 3);          mPUSHu((UV)sizeof(sa_reg));
        mPUSHp("align", 5);        mPUSHu((UV)SA_ALIGN);
        mPUSHp("namelen", 7);      mPUSHu((UV)SA_NAMELEN);
        mPUSHp("word", 4);         mPUSHu((UV)sizeof(void *));

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

UV
sar_size(self)
        SV *self
    PREINIT:
        sa_region *r;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        RETVAL = (UV)r->total;
    OUTPUT:
        RETVAL

# Did THIS process create the region, or attach to one that was already there?
# A caller that has to seed a region exactly once uses this to decide.
int
sar_created(self)
        SV *self
    PREINIT:
        sa_region *r;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        RETVAL = r->created ? 1 : 0;
    OUTPUT:
        RETVAL

# The address this process mapped at. Only a test has any business with it -
# t/03-relocatable.t asserts two mappings of one region land at DIFFERENT
# addresses, which is what makes that test prove anything.
UV
sar_base(self)
        SV *self
    PREINIT:
        sa_region *r;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        RETVAL = PTR2UV(r->map.base);
    OUTPUT:
        RETVAL

# Registry entries this process has refused because their extent is not inside
# the mapping. Non-zero means the arena has been written by something that
# should not have: corruption, or another process. It is not a health metric to
# graph and forget - it is zero or it is a bug.
UV
sar_refused(self)
        SV *self
    PREINIT:
        sa_region *r;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
#if SA_HAVE_ATOMICS
        RETVAL = (UV)sa_at_load32_acq(&r->hdr->reg_refused);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

# $arena->region($name, size => N) -> ($offset, $length)
#
# Carves it, or hands back the one already there under that name. An empty list
# when the region is full or the name is unusable.
void
sar_region(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *r;
        sa_reg *e;
        const char *nm;
        STRLEN nlen;
        UV size = 0;
        int err = SA_E_OK;
        I32 i;
    PPCODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        nm = SvPV(name, nlen);
        for (i = 2; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if (strEQ(o, "size")) size = SvUV(ST(i + 1));
        }
        e = size ? sa_carve(r, nm, (size_t)nlen, (uint64_t)size, SA_T_RAW, &err)
                 : sa_find(r, nm, (size_t)nlen);
        if (!e) XSRETURN_EMPTY;
        EXTEND(SP, 2);
        mPUSHu((UV)e->off);
        mPUSHu((UV)e->len);

# ---- wakeups ---------------------------------------------------------------
#
# $arena->wakers($n) BEFORE the fork, then $arena->waker in each child, then
# select on $arena->waker_fd and call $arena->drained before draining the ring.
#
# A wakeup means there is something to read: the poke follows the commit, never
# precedes it. sa_wake.h has the reasoning and t/12-wake.t holds a publisher
# inside its commit to prove it.

# Create the pipes. Must run before the fork: the descriptors are inherited,
# which is what makes their numbers meaningful in every process.
int
sar_wakers(self, ...)
        SV *self
    PREINIT:
        sa_region *r;
        UV n = 16;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        if (items > 1) n = SvUV(ST(1));
        RETVAL = sa_wake_init(r, (uint32_t)n);
    OUTPUT:
        RETVAL

# Claim one for this process, after the fork. Returns its index, or -1 when
# there is none to be had - in which case the caller polls.
int
sar_waker(self, ...)
        SV *self
    PREINIT:
        sa_region *r;
        IV idx = -1;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        if (items > 1) idx = SvIV(ST(1));
        RETVAL = sa_wake_take(r, (int)idx);
    OUTPUT:
        RETVAL

# The descriptor to select on, or -1. A process that attached to a NAMED region
# inherited no pipe and can never be given one, so it polls; the POD says so
# rather than pretending otherwise.
int
sar_waker_fd(self)
        SV *self
    PREINIT:
        sa_region *r;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        RETVAL = sa_wake_fd(r);
    OUTPUT:
        RETVAL

void
sar_drained(self)
        SV *self
    PREINIT:
        sa_region *r;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        sa_wake_drained(r);

# The two knobs a crash test needs, and nothing else has any use for.
#
# `stall_us` widens the window between reserving a record and committing it, so
# a test can kill a publisher INSIDE it rather than racing to. `reap_grace_us`
# is how long a reader waits on a hole before it starts asking whether the
# publisher is dead. Both live in the region header rather than behind an
# #ifdef, because a forked child has to honour them and a child of a build that
# compiled them out cannot.
void
sar__test_timing(self, ...)
        SV *self
    PREINIT:
        sa_region *r;
        I32 i;
    PPCODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        for (i = 1; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if      (strEQ(o, "stall_us"))
                sa_at_store32_rel(&r->hdr->stall_us, (uint32_t)SvUV(ST(i + 1)));
            else if (strEQ(o, "reap_grace_us"))
                sa_at_store32_rel(&r->hdr->reap_grace_us,
                                  (uint32_t)SvUV(ST(i + 1)));
        }
        EXTEND(SP, 4);
        mPUSHp("stall_us", 8);
        mPUSHu((UV)sa_at_load32_acq(&r->hdr->stall_us));
        mPUSHp("reap_grace_us", 13);
        mPUSHu((UV)sa_at_load32_acq(&r->hdr->reap_grace_us));

# How many processes are registered as peers, and how many of those are live.
void
sar_peers(self)
        SV *self
    PREINIT:
        sa_region *r;
        sa_peer *peers;
        uint32_t i, used, live = 0, reaped = 0;
    PPCODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        peers = SA_PEERS(r->map.base, r->hdr);
        used  = sa_at_load32_acq(&r->hdr->peers_used);
        if (used > r->hdr->peers_max) used = r->hdr->peers_max;
        for (i = 0; i < used; i++) {
            uint32_t st = sa_at_load32_acq(&peers[i].state);
            if (st == SA_P_LIVE)   live++;
            if (st == SA_P_REAPED) reaped++;
        }
        EXTEND(SP, 6);
        mPUSHp("used", 4);   mPUSHu((UV)used);
        mPUSHp("live", 4);   mPUSHu((UV)live);
        mPUSHp("reaped", 6); mPUSHu((UV)reaped);

# Raw bytes into and out of a carved region.
#
# These exist because a region with no tenant is still worth testing, and
# because SA_T_RAW is a real use: a caller who wants a fixed-size shared
# structure of its own design carves one and addresses it itself.
void
sar_poke(self, name, off, bytes)
        SV *self
        SV *name
        UV off
        SV *bytes
    PREINIT:
        sa_region *r;
        sa_reg *e;
        const char *nm, *p;
        STRLEN nlen, blen;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        nm = SvPV(name, nlen);
        e = sa_find(r, nm, (size_t)nlen);
        if (!e) croak("Shared::Arena: no region called '%s'", nm);
        p = SvPV(bytes, blen);
        if (off + blen > e->len)
            croak("Shared::Arena: %lu bytes at %lu runs past the region's %lu",
                  (unsigned long)blen, (unsigned long)off,
                  (unsigned long)e->len);
        memcpy((char *)sa_ptr(r, e->off) + off, p, blen);

SV *
sar_peek(self, name, off, len)
        SV *self
        SV *name
        UV off
        UV len
    PREINIT:
        sa_region *r;
        sa_reg *e;
        const char *nm;
        STRLEN nlen;
    CODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        nm = SvPV(name, nlen);
        e = sa_find(r, nm, (size_t)nlen);
        if (!e) croak("Shared::Arena: no region called '%s'", nm);
        if (off + len > e->len)
            croak("Shared::Arena: %lu bytes at %lu runs past the region's %lu",
                  (unsigned long)len, (unsigned long)off,
                  (unsigned long)e->len);
        RETVAL = newSVpvn((char *)sa_ptr(r, e->off) + off, (STRLEN)len);
    OUTPUT:
        RETVAL

# The names carved so far, in the order they were carved.
void
sar_regions(self)
        SV *self
    PREINIT:
        sa_region *r;
        sa_reg *regs;
        uint32_t used, i;
    PPCODE:
        r = SA_SELF(sa_region, self);
        if (!r || !r->map.base) croak("Shared::Arena: this region is released");
        regs = SA_REGS(r->map.base, r->hdr);
        used = sa_at_load32_acq(&r->hdr->reg_used);
        if (used > r->hdr->reg_max) used = r->hdr->reg_max;
        for (i = 0; i < used; i++) {
            if (sa_at_load32_acq(&regs[i].state) != SA_R_LIVE) continue;
            mXPUSHp(regs[i].name, strlen(regs[i].name));
        }

MODULE = Shared::Arena    PACKAGE = Shared::Arena

void
DESTROY(self)
        SV *self
    PREINIT:
        sa_region *r;
    CODE:
        r = SA_SELF(sa_region, self);
        if (r) {
            sa_region_release(r);
            sv_setiv(SvRV(self), 0);
        }
