# Shared::Arena::Frozen - one structure, read in place by every process.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->frozen($name, size => N, slots => 4)
#
# `size` is the largest block this will ever carry, and the region costs that
# times `slots`, because the point of the slots is that a publish never writes
# where somebody is reading.
SV *
sar_frozen(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_frozen *f;
        const char *nm;
        STRLEN nlen;
        UV size = 65536, slots = 4;
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
            if      (strEQ(o, "size"))  size  = SvUV(ST(i + 1));
            else if (strEQ(o, "slots")) slots = SvUV(ST(i + 1));
        }
        if (slots < SA_FROZEN_MIN_SLOTS) slots = SA_FROZEN_MIN_SLOTS;
        if (slots > SA_FROZEN_MAX_SLOTS) slots = SA_FROZEN_MAX_SLOTS;
        if (!size) croak("Shared::Arena: a frozen region needs a size");

        e = sa_carve(arena, nm, (size_t)nlen,
                     sa_frozen_bytes((uint64_t)size, (uint32_t)slots),
                     SA_T_FROZEN, &err);
        if (!e) croak("Shared::Arena: the block '%s' %s", nm, sa_strerror(err));

        f = sa_frozen_bind(arena, e, (uint64_t)size, (uint32_t)slots, &err);
        if (!f) croak("Shared::Arena: the block '%s' %s", nm, sa_strerror(err));

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Frozen", (void *)f);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Frozen    PREFIX = saf_

# Freeze a structure and publish it. Returns the new generation, or undef when
# the block does not fit the slot the region was carved with.
#
# The freezing happens through the ABI table rather than through Frozen's Perl
# surface, so publishing costs one call rather than a method plus a copy.
SV *
saf_publish(self, data, ...)
        SV *self
        SV *data
    PREINIT:
        sa_frozen *f;
        SV *block;
        uint64_t gen = 0;
        int rc, lossy = 0;
        I32 i;
    CODE:
        f = SA_SELF(sa_frozen, self);
        if (!f) croak("Shared::Arena::Frozen: this block is released");
        for (i = 2; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if (strEQ(o, "lossy_nv")) lossy = (int)SvIV(ST(i + 1));
        }
        block = (SA_FZ->freeze)(aTHX_ data, lossy, NULL);
        if (!block) croak("Shared::Arena::Frozen: cannot freeze that");
        sv_2mortal(block);

        rc = sa_frozen_publish(f, SvPVX(block), (uint64_t)SvCUR(block), &gen);
        if (rc != SA_FZ_OK) XSRETURN_UNDEF;
        RETVAL = newSVuv((UV)gen);
    OUTPUT:
        RETVAL

# Publish bytes that are already a Frozen block, which is what a process that
# received one over the wire has. Refused unless it really is one: these bytes
# become every other process's structure, and the cheapest place to find out
# they are not a block is before publishing rather than during a read.
SV *
saf_publish_bytes(self, bytes)
        SV *self
        SV *bytes
    PREINIT:
        sa_frozen *f;
        fz_container *c;
        const char *p;
        STRLEN len;
        uint64_t gen = 0;
        int err = 0, rc;
    CODE:
        f = SA_SELF(sa_frozen, self);
        if (!f) croak("Shared::Arena::Frozen: this block is released");
        p = SvPV(bytes, len);
        c = (SA_FZ->borrow)(p, (size_t)len, &err);
        if (!c)
            croak("Shared::Arena::Frozen: those bytes %s",
                  (SA_FZ->error)(err));
        if ((SA_FZ->verify)(c) <= 0) {
            (void)(SA_FZ->release)(c);
            croak("Shared::Arena::Frozen: that block's structure does not hold "
                  "together");
        }
        (void)(SA_FZ->release)(c);

        rc = sa_frozen_publish(f, p, (uint64_t)len, &gen);
        if (rc != SA_FZ_OK) XSRETURN_UNDEF;
        RETVAL = newSVuv((UV)gen);
    OUTPUT:
        RETVAL

# A view of whatever is published now, or an EMPTY LIST when nothing is.
#
# The view BORROWS the bytes where they lie: nothing is copied, which is the
# whole reason this beats handing the same structure down a pipe. Take one,
# read it, drop it. See the POD on what holding one across a publish means.
void
saf_view(self)
        SV *self
    PREINIT:
        sa_frozen *f;
        sa_fzview *v;
        const unsigned char *bytes = NULL;
        uint64_t len = 0, gen = 0;
        uint32_t slot = 0;
        fz_container *c;
        int err = 0;
        SV *obj;
    PPCODE:
        f = SA_SELF(sa_frozen, self);
        if (!f) croak("Shared::Arena::Frozen: this block is released");
        if (sa_frozen_current(f, &bytes, &len, &gen, &slot) != SA_FZ_OK)
            XSRETURN_EMPTY;

        c = (SA_FZ->borrow)(bytes, (size_t)len, &err);
        if (!c) XSRETURN_EMPTY;

        Newxz(v, 1, sa_fzview);
        v->c    = c;
        v->f    = f;
        v->len  = len;
        v->slot = slot;
        v->gen  = gen;

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Frozen::View", (void *)v);
        /* The bytes belong to the arena, so the view has to keep the tenant -
         * and through it the region - alive for as long as it exists. */
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        XPUSHs(sv_2mortal(obj));

# A value by dotted path from whatever is published NOW, or an EMPTY LIST when
# nothing is published or the path does not resolve.
#
# The request-path door. It reads through a reader this handle keeps over the
# live block and borrows again only after a publish, so there is no view to
# take and drop, and every call sees the latest publish.
void
saf_get(self, path, ...)
        SV *self
        SV *path
    PREINIT:
        sa_frozen *f;
        fz_container *c;
        const char *p;
        STRLEN plen;
        char sep = '.';
        uint32_t node;
    PPCODE:
        f = SA_SELF(sa_frozen, self);
        if (!f) croak("Shared::Arena::Frozen: this block is released");
        if (items > 2) {
            STRLEN slen;
            const char *s = SvPV(ST(2), slen);
            if (slen != 1)
                croak("Shared::Arena::Frozen: a separator is one character");
            sep = s[0];
        }
        p = SvPV(path, plen);
        c = sa_fz_reader(f);
        if (!c) XSRETURN_EMPTY;
        node = (SA_FZ->path)(c, (SA_FZ->root)(c), p, plen, sep);
        if (node == FZ_NOHANDLE) XSRETURN_EMPTY;
        XPUSHs(sv_2mortal((SA_FZ->sv_from_node)(aTHX_ c, node)));

# One key against the root of whatever is published now, with no path
# splitting: the door for a key that contains the separator.
void
saf_find(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_frozen *f;
        fz_container *c;
        const char *k;
        STRLEN klen;
        uint32_t node;
    PPCODE:
        f = SA_SELF(sa_frozen, self);
        if (!f) croak("Shared::Arena::Frozen: this block is released");
        k = SvPV(key, klen);
        c = sa_fz_reader(f);
        if (!c) XSRETURN_EMPTY;
        node = (SA_FZ->child)(c, (SA_FZ->root)(c), k, klen);
        if (node == FZ_NOHANDLE) XSRETURN_EMPTY;
        XPUSHs(sv_2mortal((SA_FZ->sv_from_node)(aTHX_ c, node)));

# Whether a dotted path resolves in whatever is published now, without
# building the value. False when nothing is published.
int
saf_exists(self, path, ...)
        SV *self
        SV *path
    PREINIT:
        sa_frozen *f;
        fz_container *c;
        const char *p;
        STRLEN plen;
        char sep = '.';
    CODE:
        f = SA_SELF(sa_frozen, self);
        if (!f) croak("Shared::Arena::Frozen: this block is released");
        if (items > 2) {
            STRLEN slen;
            const char *s = SvPV(ST(2), slen);
            if (slen != 1)
                croak("Shared::Arena::Frozen: a separator is one character");
            sep = s[0];
        }
        p = SvPV(path, plen);
        c = sa_fz_reader(f);
        RETVAL = (c && (SA_FZ->path)(c, (SA_FZ->root)(c), p, plen, sep)
                           != FZ_NOHANDLE) ? 1 : 0;
    OUTPUT:
        RETVAL

UV
saf_generation(self)
        SV *self
    PREINIT:
        sa_frozen *f;
    CODE:
        f = SA_SELF(sa_frozen, self);
        if (!f) croak("Shared::Arena::Frozen: this block is released");
        RETVAL = (UV)sa_at_load64_acq(&f->hdr->generation);
    OUTPUT:
        RETVAL

UV
saf_max_block(self)
        SV *self
    PREINIT:
        sa_frozen *f;
    CODE:
        f = SA_SELF(sa_frozen, self);
        if (!f) croak("Shared::Arena::Frozen: this block is released");
        RETVAL = (UV)f->slot_bytes;
    OUTPUT:
        RETVAL

# generation / published / refused / slots / max_block / bytes
void
saf_stats(self)
        SV *self
    PREINIT:
        sa_frozen *f;
        uint64_t len = 0;
        const unsigned char *b = NULL;
    PPCODE:
        f = SA_SELF(sa_frozen, self);
        if (!f) croak("Shared::Arena::Frozen: this block is released");
        (void)sa_frozen_current(f, &b, &len, NULL, NULL);
        EXTEND(SP, 12);
        mPUSHp("generation", 10);
        mPUSHu((UV)sa_at_load64_acq(&f->hdr->generation));
        mPUSHp("published", 9);
        mPUSHu((UV)sa_at_load64_acq(&f->hdr->published));
        mPUSHp("refused", 7);
        mPUSHu((UV)sa_at_load64_acq(&f->hdr->refused));
        mPUSHp("slots", 5);      mPUSHu((UV)f->nslots);
        mPUSHp("max_block", 9);  mPUSHu((UV)f->slot_bytes);
        mPUSHp("bytes", 5);      mPUSHu((UV)len);

void
saf_DESTROY(self)
        SV *self
    PREINIT:
        sa_frozen *f;
    CODE:
        f = SA_SELF(sa_frozen, self);
        if (f) { sa_frozen_free(f); sv_setiv(SvRV(self), 0); }

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Frozen::View    PREFIX = safv_

# A value by dotted path, or an EMPTY LIST when it does not resolve.
#
# The same spelling Frozen uses - `$fz->get('limits.rate')` - and the same
# walk, because it IS the same walk: the splitting happens in the ABI's own
# path entry rather than being reimplemented here to be subtly different.
#
# The separator is an argument for the case that makes a fixed one wrong,
# which is a key with a dot in it.
void
safv_get(self, path, ...)
        SV *self
        SV *path
    PREINIT:
        sa_fzview *v;
        const char *p;
        STRLEN plen;
        char sep = '.';
        uint32_t node;
    PPCODE:
        v = SA_SELF(sa_fzview, self);
        if (!v || !v->c) croak("Shared::Arena::Frozen::View: this view is gone");
        if (items > 2) {
            STRLEN slen;
            const char *sp = SvPV(ST(2), slen);
            if (slen != 1)
                croak("Shared::Arena::Frozen::View: a separator is one "
                      "character");
            sep = sp[0];
        }
        p = SvPV(path, plen);
        node = (SA_FZ->path)(v->c, (SA_FZ->root)(v->c), p, plen, sep);
        if (node == FZ_NOHANDLE) XSRETURN_EMPTY;
        XPUSHs(sv_2mortal((SA_FZ->sv_from_node)(aTHX_ v->c, node)));

# One key against the root, with no path splitting at all - the narrowest door,
# and the right one when a key contains the separator or when a caller already
# knows there is nothing to descend into.
void
safv_find(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_fzview *v;
        const char *k;
        STRLEN klen;
        uint32_t node;
    PPCODE:
        v = SA_SELF(sa_fzview, self);
        if (!v || !v->c) croak("Shared::Arena::Frozen::View: this view is gone");
        k = SvPV(key, klen);
        node = (SA_FZ->child)(v->c, (SA_FZ->root)(v->c), k, klen);
        if (node == FZ_NOHANDLE) XSRETURN_EMPTY;
        XPUSHs(sv_2mortal((SA_FZ->sv_from_node)(aTHX_ v->c, node)));

# Whether a dotted path resolves, without building the value it resolves to.
# The cheap way to ask about something large.
int
safv_exists(self, path, ...)
        SV *self
        SV *path
    PREINIT:
        sa_fzview *v;
        const char *p;
        STRLEN plen;
        char sep = '.';
    CODE:
        v = SA_SELF(sa_fzview, self);
        if (!v || !v->c) croak("Shared::Arena::Frozen::View: this view is gone");
        if (items > 2) {
            STRLEN slen;
            const char *sp = SvPV(ST(2), slen);
            if (slen != 1)
                croak("Shared::Arena::Frozen::View: a separator is one "
                      "character");
            sep = sp[0];
        }
        p = SvPV(path, plen);
        RETVAL = (SA_FZ->path)(v->c, (SA_FZ->root)(v->c), p, plen, sep)
                 != FZ_NOHANDLE ? 1 : 0;
    OUTPUT:
        RETVAL

UV
safv_count(self)
        SV *self
    PREINIT:
        sa_fzview *v;
    CODE:
        v = SA_SELF(sa_fzview, self);
        if (!v || !v->c) croak("Shared::Arena::Frozen::View: this view is gone");
        RETVAL = (UV)(SA_FZ->count)(v->c, (SA_FZ->root)(v->c));
    OUTPUT:
        RETVAL

void
safv_keys(self)
        SV *self
    PREINIT:
        sa_fzview *v;
        uint32_t root, n, i;
    PPCODE:
        v = SA_SELF(sa_fzview, self);
        if (!v || !v->c) croak("Shared::Arena::Frozen::View: this view is gone");
        root = (SA_FZ->root)(v->c);
        n = (SA_FZ->count)(v->c, root);
        EXTEND(SP, (IV)n);
        for (i = 0; i < n; i++) {
            const char *k = NULL;
            STRLEN klen = 0;
            int utf8 = 0;
            if (!(SA_FZ->key_at)(v->c, root, i, &k, &klen, &utf8)) continue;
            {
                SV *sv = newSVpvn(k, klen);
                if (utf8) SvUTF8_on(sv);
                PUSHs(sv_2mortal(sv));
            }
        }

# The whole structure back as ordinary Perl data. This is the one door that
# costs what Storable costs, because it is the one that does what Storable
# does: it builds every value whether the caller wanted it or not.
SV *
safv_inflate(self)
        SV *self
    PREINIT:
        sa_fzview *v;
    CODE:
        v = SA_SELF(sa_fzview, self);
        if (!v || !v->c) croak("Shared::Arena::Frozen::View: this view is gone");
        RETVAL = (SA_FZ->sv_from_node)(aTHX_ v->c, (SA_FZ->root)(v->c));
    OUTPUT:
        RETVAL

# The generation this view was opened on.
UV
safv_generation(self)
        SV *self
    PREINIT:
        sa_fzview *v;
    CODE:
        v = SA_SELF(sa_fzview, self);
        if (!v) croak("Shared::Arena::Frozen::View: this view is gone");
        RETVAL = (UV)v->gen;
    OUTPUT:
        RETVAL

# Whether the slot still holds the block this view was opened on.
#
# A view cannot be stopped from going stale - the bytes belong to the arena and
# a publisher will eventually come round to that slot again - but it can always
# find out. False means read it again, not that anything is broken.
int
safv_fresh(self)
        SV *self
    PREINIT:
        sa_fzview *v;
    CODE:
        v = SA_SELF(sa_fzview, self);
        if (!v || !v->f) croak("Shared::Arena::Frozen::View: this view is gone");
        RETVAL = sa_frozen_fresh(v->f, v->slot, v->gen);
    OUTPUT:
        RETVAL

# What the block itself says its structure is: the node count, or a negative
# number when it does not hold together. O(n), for a caller checking bytes it
# did not write.
IV
safv_verify(self)
        SV *self
    PREINIT:
        sa_fzview *v;
    CODE:
        v = SA_SELF(sa_fzview, self);
        if (!v || !v->c) croak("Shared::Arena::Frozen::View: this view is gone");
        RETVAL = (IV)(SA_FZ->verify)(v->c);
    OUTPUT:
        RETVAL

UV
safv_bytes(self)
        SV *self
    PREINIT:
        sa_fzview *v;
    CODE:
        v = SA_SELF(sa_fzview, self);
        if (!v || !v->c) croak("Shared::Arena::Frozen::View: this view is gone");
        RETVAL = (UV)v->len;
    OUTPUT:
        RETVAL

void
safv_DESTROY(self)
        SV *self
    PREINIT:
        sa_fzview *v;
    CODE:
        v = SA_SELF(sa_fzview, self);
        if (v) {
            /* release is close without an interpreter, and it is the right one
             * here: a borrowed container never holds a perl reference, and the
             * bytes it points at are the arena's, so this frees the container
             * and touches nothing else. */
            if (v->c) (void)(SA_FZ->release)(v->c);
            Safefree(v);
            sv_setiv(SvRV(self), 0);
        }

MODULE = Shared::Arena    PACKAGE = Shared::Arena

BOOT:
{
    /* The two ends of the ABI, checked here rather than at the first publish.
     *
     * FZ_ABI_VERSION is what THIS file was compiled against; the table says
     * what is actually loaded. `>=` and never `==`, because the table is
     * append-only: a newer Frozen has everything this needs and more, an older
     * one is missing entries that would be called as null pointers - in a
     * worker, in production, at the first request that touched a block. */
    SV *fzp;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    call_pv("Frozen::_abi_ptr", G_SCALAR);
    SPAGAIN;
    fzp = POPs;
    SA_FZ = INT2PTR(const fz_abi *, SvUV(fzp));
    PUTBACK;
    FREETMPS;
    LEAVE;

    if (!SA_FZ)
        croak("Shared::Arena: Frozen gave no ABI table");
    if (SA_FZ->abi_version < FZ_ABI_VERSION)
        croak("Shared::Arena needs Frozen ABI %d or newer, and the Frozen "
              "that is installed publishes %d. Upgrade Frozen.",
              (int)FZ_ABI_VERSION, (int)SA_FZ->abi_version);
}
