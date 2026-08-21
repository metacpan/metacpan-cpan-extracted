MODULE = Punk        PACKAGE = Punk::Upload

PROTOTYPES: DISABLE

# An uploaded file part from a multipart/form-data request - a blessed hashref
# the multipart parser (punk_multipart.h) built. lib/Punk/Upload.pm is docs.

SV *
filename(self)
        SV *self
    ALIAS:
        name    = 1
        type    = 2
        content = 3
        path    = 4
    CODE:
    {
        static const char *const f[] = { "filename", "name", "type",
                                         "content", "path" };
        HV *h;
        SV **v;
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Punk::Upload: not an upload");
        h = (HV *)SvRV(self);
        v = hv_fetch(h, f[ix], (I32)strlen(f[ix]), 0);

        /* `content` on a spilled part reads the file back.
         *
         * That costs the file's size in memory, which is precisely what
         * streaming it to disk avoided - so the POD names the cost, the way
         * Plack::Request::Upload names its equivalent `slurp`. It is kept
         * working rather than made to croak because every application that
         * already handles uploads calls it. */
        {
            SV **pp = (ix == 3 && !(v && *v)) ? hv_fetchs(h, "path", 0) : NULL;
            if (pp && *pp && SvOK(*pp)) {
                PerlIO *fh = PerlIO_open(SvPV_nolen(*pp), "rb");
                RETVAL = newSVpvs("");
                if (fh) {
                    char tmp[65536];
                    SSize_t n;
                    while ((n = PerlIO_read(fh, tmp, sizeof tmp)) > 0)
                        sv_catpvn(RETVAL, tmp, (STRLEN)n);
                    PerlIO_close(fh);
                }
            }
            /* NOT an early XSRETURN here: with `OUTPUT: RETVAL` the generated
             * code pushes RETVAL after this block, so returning early hands
             * back ST(0) - which is `self`. That is exactly what it did, and
             * `length($up->content)` came out as 30: the length of
             * "Punk::Upload=HASH(0x...)". */
            else RETVAL = (v && *v) ? newSVsv(*v) : newSV(0);
        }
    }
    OUTPUT:
        RETVAL

IV
size(self)
        SV *self
    CODE:
    {
        SV **v = (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV)
            ? hv_fetchs((HV *)SvRV(self), "size", 0) : NULL;
        RETVAL = (v && *v) ? SvIV(*v) : 0;
    }
    OUTPUT:
        RETVAL

# save($path): put the uploaded bytes at $path. Returns true.
#
# A RENAME when the part is already a file and the destination shares its
# filesystem - which is the whole point of streaming it there, and why
# upload_dir wants to be on the same filesystem as wherever things are kept.
# A copy otherwise, and a plain write when the bytes are in memory.
IV
save(self, path)
        SV *self
        SV *path
    CODE:
    {
        HV *h;
        SV **cv, **pp;
        const char *p;
        PerlIO *fh;
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Punk::Upload: not an upload");
        h = (HV *)SvRV(self);
        p = SvPV_nolen(path);
        pp = hv_fetchs(h, "path", 0);

        if (pp && *pp && SvOK(*pp)) {
            const char *from = SvPV_nolen(*pp);
            if (PerlLIO_rename(from, p) == 0) {
                /* it is no longer ours to clean up, and no longer a temp
                 * file: the object now points at where the caller put it */
                (void)hv_stores(h, "path", newSVsv(path));
                (void)hv_stores(h, "moved", newSViv(1));
                /* the temp file is gone from where the request left it, so
                 * the cleanup must not go looking for it - and must not
                 * unlink the place the caller just asked for */
                {
                    SV **t = hv_fetchs(h, "tmpslot", 0);
                    if (t && *t && SvROK(*t)) sv_setsv(SvRV(*t), &PL_sv_undef);
                }
                RETVAL = 1;
                XSRETURN_IV(RETVAL);
            }
            {   /* across filesystems rename fails; copy instead */
                PerlIO *in = PerlIO_open(from, "rb");
                char buf[65536];
                SSize_t n;
                if (!in) croak("Punk::Upload: cannot read '%s': %s",
                               from, Strerror(errno));
                fh = PerlIO_open(p, "wb");
                if (!fh) { PerlIO_close(in);
                           croak("Punk::Upload: cannot write '%s': %s",
                                 p, Strerror(errno)); }
                while ((n = PerlIO_read(in, buf, sizeof buf)) > 0)
                    (void)PerlIO_write(fh, buf, n);
                PerlIO_close(in);
                PerlIO_close(fh);
                RETVAL = 1;
                XSRETURN_IV(RETVAL);
            }
        }

        cv = hv_fetchs(h, "content", 0);
        {
            STRLEN cl = 0;
            const char *c = (cv && *cv && SvOK(*cv)) ? SvPV_const(*cv, cl) : "";
            fh = PerlIO_open(p, "wb");
            if (!fh) croak("Punk::Upload: cannot write '%s': %s",
                           p, Strerror(errno));
            if (cl) (void)PerlIO_write(fh, c, cl);
            PerlIO_close(fh);
        }
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL

# _disown: the bytes have been moved somewhere permanent, so the request's
# cleanup must stop tracking them. Punk::Plugin::Blob calls this after moving
# an upload into the store, for the same reason save() clears its own slot:
# unlinking a file the caller was just handed would be far worse than leaking
# one.
void
_disown(self)
        SV *self
    CODE:
    {
        HV *h;
        SV **t;
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) XSRETURN_EMPTY;
        h = (HV *)SvRV(self);
        t = hv_fetchs(h, "tmpslot", 0);
        if (t && *t && SvROK(*t)) sv_setsv(SvRV(*t), &PL_sv_undef);
        (void)hv_stores(h, "moved", newSViv(1));
    }
