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
    CODE:
    {
        static const char *const f[] = { "filename", "name", "type", "content" };
        HV *h;
        SV **v;
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Punk::Upload: not an upload");
        h = (HV *)SvRV(self);
        v = hv_fetch(h, f[ix], (I32)strlen(f[ix]), 0);
        RETVAL = (v && *v) ? newSVsv(*v) : &PL_sv_undef;
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

# save($path): write the uploaded bytes out. Returns true.
IV
save(self, path)
        SV *self
        SV *path
    CODE:
    {
        HV *h;
        SV **cv;
        const char *c, *p;
        STRLEN cl = 0;
        PerlIO *fh;
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Punk::Upload: not an upload");
        h = (HV *)SvRV(self);
        cv = hv_fetchs(h, "content", 0);
        c = (cv && *cv && SvOK(*cv)) ? SvPV_const(*cv, cl) : "";
        p = SvPV_nolen(path);
        fh = PerlIO_open(p, "wb");
        if (!fh) croak("Punk::Upload: cannot write '%s': %s", p, Strerror(errno));
        if (cl) (void)PerlIO_write(fh, c, cl);
        PerlIO_close(fh);
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL
