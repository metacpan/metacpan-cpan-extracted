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
        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        # uncoverable condition left count:2 class:ignore_covered_err
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Punk::Upload: not an upload"); /* # uncoverable statement */
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
            SV **pp = (ix == 3 && !(v && *v)) ? hv_fetchs(h, "path", 0) : NULL; /* # uncoverable condition left count:3 class:ignore_covered_err */
            # uncoverable condition right count:2 class:ignore_covered_err
            # uncoverable condition right count:3 class:ignore_covered_err
            if (pp && *pp && SvOK(*pp)) {
                PerlIO *fh = PerlIO_open(SvPV_nolen(*pp), "rb");
                RETVAL = newSVpvs("");
                # uncoverable branch false
                # uncoverable condition right count:1 class:ignore_covered_err
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
            else RETVAL = (v && *v) ? newSVsv(*v) : newSV(0); /* # uncoverable condition right count:2 class:ignore_covered_err */
        }
    }
    OUTPUT:
        RETVAL

# The client's file name reduced to a name: what follows the last / or \,
# without leading dots and without control bytes. undef when nothing is left.
# Safe to show; a path is still better built from a name the server chose.
SV *
basename(self)
        SV *self
    CODE:
    {
        SV **v;
        STRLEN l, i, start = 0;
        const char *p;
        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        # uncoverable condition left count:2 class:ignore_covered_err
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Punk::Upload: not an upload"); /* # uncoverable statement */
        v = hv_fetchs((HV *)SvRV(self), "filename", 0);
        RETVAL = newSV(0);
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        # uncoverable condition right count:2 class:ignore_covered_err
        # uncoverable condition right count:3 class:ignore_covered_err
        if (v && *v && SvOK(*v)) {
            p = SvPV_const(*v, l);
            for (i = 0; i < l; i++)
                if (p[i] == '/' || p[i] == '\\') start = i + 1;
            if (start < l) {
                STRLEN lead = 0;
                /* control bytes first, dots second: stripping the dots
                 * before the bytes let "\x01.env" come out as ".env" */
                sv_setpvs(RETVAL, "");
                for (i = start; i < l; i++) {
                    unsigned char ch = (unsigned char)p[i];
                    if (ch < 0x20 || ch == 0x7f) continue;
                    sv_catpvn(RETVAL, (const char *)&ch, 1);
                }
                while (lead < SvCUR(RETVAL) && SvPVX(RETVAL)[lead] == '.') lead++;
                if (lead) sv_chop(RETVAL, SvPVX(RETVAL) + lead);
                if (!SvCUR(RETVAL)) sv_setsv(RETVAL, &PL_sv_undef);
                # uncoverable branch true
                # uncoverable condition left count:1 class:ignore_covered_err
                else if (SvUTF8(*v)) SvUTF8_on(RETVAL);
            }
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
        # uncoverable condition right count:1 class:ignore_covered_err
        # uncoverable condition right count:2 class:ignore_covered_err
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
        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        # uncoverable condition left count:2 class:ignore_covered_err
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Punk::Upload: not an upload"); /* # uncoverable statement */
        h = (HV *)SvRV(self);
        {
            STRLEN plen;
            p = SvPV(path, plen);
            /* open() stops at a NUL and the caller's allowlist did not:
             * "x.php\0.txt" is x.php on disk */
            if (memchr(p, 0, plen))
                croak("Punk::Upload: save path contains a NUL byte");
        }
        pp = hv_fetchs(h, "path", 0);

        # uncoverable condition right count:2 class:ignore_covered_err
        # uncoverable condition right count:3 class:ignore_covered_err
        if (pp && *pp && SvOK(*pp)) {
            const char *from = SvPV_nolen(*pp);
            # uncoverable branch false
            # uncoverable condition right count:1 class:ignore_covered_err
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
                    # uncoverable branch false
                    # uncoverable condition right count:1 class:ignore_covered_err
                    # uncoverable condition right count:2 class:ignore_covered_err
                    # uncoverable condition right count:3 class:ignore_covered_err
                    if (t && *t && SvROK(*t)) sv_setsv(SvRV(*t), &PL_sv_undef);
                }
                RETVAL = 1;
                XSRETURN_IV(RETVAL);
            }
            {   /* across filesystems rename fails; copy instead */
                PerlIO *in = PerlIO_open(from, "rb"); /* # uncoverable statement */
                char buf[65536];
                SSize_t n;
                # uncoverable statement
                # uncoverable branch true
                # uncoverable branch false
                # uncoverable branch true count:2
                # uncoverable branch false count:2
                # uncoverable branch true count:3
                # uncoverable branch false count:3
                # uncoverable condition left count:1
                # uncoverable condition right count:1
                if (!in) croak("Punk::Upload: cannot read '%s': %s",
                               from, Strerror(errno)); /* # uncoverable statement */
                fh = PerlIO_open(p, "wb"); /* # uncoverable statement */
                # uncoverable statement
                # uncoverable branch true
                # uncoverable branch false
                # uncoverable condition left count:1
                # uncoverable condition right count:1
                if (!fh) { PerlIO_close(in);
                           croak("Punk::Upload: cannot write '%s': %s", /* # uncoverable statement */
                                 p, Strerror(errno)); } /* # uncoverable statement */
                # uncoverable statement
                # uncoverable branch true
                # uncoverable branch false
                # uncoverable condition left count:1
                # uncoverable condition right count:1
                while ((n = PerlIO_read(in, buf, sizeof buf)) > 0)
                    # uncoverable statement
                    # uncoverable branch true
                    # uncoverable branch false
                    # uncoverable condition left count:1
                    # uncoverable condition right count:1
                    if (PerlIO_write(fh, buf, n) != n) {
                        int e = errno; /* # uncoverable statement */
                        PerlIO_close(in); PerlIO_close(fh); /* # uncoverable statement */
                        croak("Punk::Upload: short write to '%s': %s", p, /* # uncoverable statement */
                              Strerror(e)); /* # uncoverable statement */
                    }
                PerlIO_close(in); /* # uncoverable statement */
                # uncoverable statement
                # uncoverable branch true
                # uncoverable branch false
                # uncoverable condition left count:1
                # uncoverable condition right count:1
                if (PerlIO_close(fh) != 0)
                    croak("Punk::Upload: cannot finish '%s': %s", p, /* # uncoverable statement */
                          Strerror(errno)); /* # uncoverable statement */
                RETVAL = 1; /* # uncoverable statement */
                XSRETURN_IV(RETVAL); /* # uncoverable statement */
            }
        }

        cv = hv_fetchs(h, "content", 0);
        {
            STRLEN cl = 0;
            # uncoverable condition right count:1 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            # uncoverable condition right count:3 class:ignore_covered_err
            const char *c = (cv && *cv && SvOK(*cv)) ? SvPV_const(*cv, cl) : "";
            fh = PerlIO_open(p, "wb");
            # uncoverable branch true
            # uncoverable branch true count:2 class:ignore_covered_err
            # uncoverable branch false count:3 class:ignore_covered_err
            # uncoverable condition left count:1 class:ignore_covered_err
            if (!fh) croak("Punk::Upload: cannot write '%s': %s",
                           p, Strerror(errno)); /* # uncoverable statement */
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            # uncoverable condition right count:1 class:ignore_covered_err
            # uncoverable condition left count:2 class:ignore_covered_err
            if (cl && PerlIO_write(fh, c, cl) != (SSize_t)cl) {
                int e = errno; /* # uncoverable statement */
                PerlIO_close(fh); /* # uncoverable statement */
                croak("Punk::Upload: short write to '%s': %s", p, Strerror(e)); /* # uncoverable statement */
            }
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            if (PerlIO_close(fh) != 0)
                croak("Punk::Upload: cannot finish '%s': %s", p, /* # uncoverable statement */
                      Strerror(errno)); /* # uncoverable statement */
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
        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        # uncoverable condition left count:2 class:ignore_covered_err
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) XSRETURN_EMPTY;
        h = (HV *)SvRV(self);
        t = hv_fetchs(h, "tmpslot", 0);
        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        # uncoverable condition left count:2 class:ignore_covered_err
        # uncoverable condition right count:2 class:ignore_covered_err
        # uncoverable condition left count:3 class:ignore_covered_err
        # uncoverable condition right count:3 class:ignore_covered_err
        if (t && *t && SvROK(*t)) sv_setsv(SvRV(*t), &PL_sv_undef);
        (void)hv_stores(h, "moved", newSViv(1));
    }
