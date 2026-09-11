# Shared::Arena::CountMin - how often a key has been seen, in fixed space.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->countmin($name, error => 0.001, confidence => 0.99)
#
# Sized from the error you will accept and how sure you want to be, because
# those are the numbers a caller has. `rows` and `width` are there for one who
# has already done the arithmetic.
SV *
sar_countmin(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_cms *s;
        const char *nm;
        STRLEN nlen;
        double error = 0.001, confidence = 0.99;
        UV rows = 0, width = 0;
        uint32_t d = 0;
        uint64_t w = 0;
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
            if      (strEQ(o, "error"))      error      = SvNV(ST(i + 1));
            else if (strEQ(o, "confidence")) confidence = SvNV(ST(i + 1));
            else if (strEQ(o, "rows"))       rows       = SvUV(ST(i + 1));
            else if (strEQ(o, "width"))      width      = SvUV(ST(i + 1));
        }
        if (rows || width) {
            d = rows ? (uint32_t)rows : 5;
            w = sa_cms_pow2(width ? (uint64_t)width : 2048);
            if (d > SA_CMS_MAX_ROWS) d = SA_CMS_MAX_ROWS;
        }
        else {
            sa_cms_size(error, confidence, &d, &w);
        }

        e = sa_carve(arena, nm, (size_t)nlen, sa_cms_bytes(d, w),
                     SA_T_CMS, &err);
        if (!e) croak("Shared::Arena: the sketch '%s' %s", nm, sa_strerror(err));

        s = sa_cms_bind(arena, e, d, w, &err);
        if (!s) croak("Shared::Arena: the sketch '%s' %s", nm, sa_strerror(err));

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::CountMin", (void *)s);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::CountMin    PREFIX = sacm_

# Count one, or `n`, and hand back what the sketch now believes. Returning the
# estimate costs nothing - the numbers are already in hand - and it is what a
# caller asking "has this key just crossed my threshold" wants.
UV
sacm_add(self, key, ...)
        SV *self
        SV *key
    PREINIT:
        sa_cms *s;
        const char *k;
        STRLEN klen;
        UV n = 1;
    CODE:
        s = SA_SELF(sa_cms, self);
        if (!s) croak("Shared::Arena::CountMin: this sketch is released");
        if (items > 2) n = SvUV(ST(2));
        if (n < 1) n = 1;
        k = SvPV(key, klen);
#if SA_HAVE_ATOMICS
        RETVAL = (UV)sa_cms_add(s, k, (uint32_t)klen, (uint64_t)n);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

# At most `error` too high, never too low.
UV
sacm_estimate(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_cms *s;
        const char *k;
        STRLEN klen;
    CODE:
        s = SA_SELF(sa_cms, self);
        if (!s) croak("Shared::Arena::CountMin: this sketch is released");
        k = SvPV(key, klen);
#if SA_HAVE_ATOMICS
        RETVAL = (UV)sa_cms_estimate(s, k, (uint32_t)klen);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

void
sacm_reset(self)
        SV *self
    PREINIT:
        sa_cms *s;
    CODE:
        s = SA_SELF(sa_cms, self);
        if (!s) croak("Shared::Arena::CountMin: this sketch is released");
#if SA_HAVE_ATOMICS
        sa_cms_reset(s);
#endif

UV
sacm_rows(self)
        SV *self
    PREINIT:
        sa_cms *s;
    CODE:
        s = SA_SELF(sa_cms, self);
        if (!s) croak("Shared::Arena::CountMin: this sketch is released");
        RETVAL = (UV)s->rows;
    OUTPUT:
        RETVAL

UV
sacm_width(self)
        SV *self
    PREINIT:
        sa_cms *s;
    CODE:
        s = SA_SELF(sa_cms, self);
        if (!s) croak("Shared::Arena::CountMin: this sketch is released");
        RETVAL = (UV)s->width;
    OUTPUT:
        RETVAL

# rows / width / total / adds / error / bytes
#
# `error` is the number that makes an estimate mean anything: an answer may be
# that much too high. It is a fraction of the TOTAL, not of the key's own count,
# so a sketch accurate enough to find the loudest client says nothing useful
# about one seen twice.
void
sacm_stats(self)
        SV *self
    PREINIT:
        sa_cms *s;
    PPCODE:
        s = SA_SELF(sa_cms, self);
        if (!s) croak("Shared::Arena::CountMin: this sketch is released");
        EXTEND(SP, 12);
        mPUSHp("rows", 4);      mPUSHu((UV)s->rows);
        mPUSHp("width", 5);     mPUSHu((UV)s->width);
        mPUSHp("bytes", 5);     mPUSHu((UV)sa_cms_bytes(s->rows, s->width));
#if SA_HAVE_ATOMICS
        mPUSHp("total", 5);     mPUSHu((UV)sa_at_load64_acq(&s->hdr->total));
        mPUSHp("adds", 4);      mPUSHu((UV)sa_at_load64_acq(&s->hdr->adds));
        mPUSHp("error", 5);     mPUSHu((UV)sa_cms_error(s));
#endif

void
sacm_DESTROY(self)
        SV *self
    PREINIT:
        sa_cms *s;
    CODE:
        s = SA_SELF(sa_cms, self);
        if (s) { sa_cms_free(s); sv_setiv(SvRV(self), 0); }
