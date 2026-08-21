MODULE = Punk        PACKAGE = Punk::Context

PROTOTYPES: DISABLE

# $c->send_file($path_or_scalarref, %opts) - a finished download response
# (punk_sendfile.h): validators, single-range 206/416, Content-Disposition,
# HEAD. Returns the triplet, so the handler returns it. Options: type,
# filename, inline, ranges, mtime, etag, cache_control, missing.
SV *
send_file(self, src, ...)
        SV *self
        SV *src
    CODE:
    {
        AV *av  = pcx_av(aTHX_ self);
        AV *res = pcx_res_av(aTHX_ av);
        SV *envsv = pcx_get(aTHX_ av, PCX_ENV);
        HV *env;
        psf_src  s;
        psf_opts o;
        SV *mtime_opt = NULL, *missing = NULL;
        Stat_t st;
        int i;
        SV *resp;

        if (!envsv || !SvROK(envsv) || SvTYPE(SvRV(envsv)) != SVt_PVHV)
            croak("Punk::Context::send_file: no request env");
        env = (HV *)SvRV(envsv);

        Zero(&s, 1, psf_src);
        Zero(&o, 1, psf_opts);
        o.ranges = 1;
        o.extra  = res ? pcx_res_headers(aTHX_ res) : NULL;

        if ((items - 2) % 2)
            croak("Punk::Context::send_file: odd number of options");
        for (i = 2; i < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if      (strEQ(k, "type"))     o.type = v;
            else if (strEQ(k, "filename")) { o.filename = v; o.has_disp = 1; }
            else if (strEQ(k, "inline"))   { o.inline_ = SvTRUE(v) ? 1 : 0;
                                             o.has_disp = 1; }
            else if (strEQ(k, "ranges"))   o.ranges = SvTRUE(v) ? 1 : 0;
            else if (strEQ(k, "mtime"))    mtime_opt = v;
            else if (strEQ(k, "etag"))     o.etag = v;
            else if (strEQ(k, "cache_control")) o.cache_control = v;
            else if (strEQ(k, "missing"))  missing = v;
            else croak("Punk::Context::send_file: unknown option '%s'", k);
        }
        if (missing && SvOK(missing)
            && !strEQ(SvPV_nolen(missing), "not_found"))
            croak("Punk::Context::send_file: missing => '%s' is not "
                  "'not_found'", SvPV_nolen(missing));

        if (SvROK(src) && !sv_isobject(src)
            && SvTYPE(SvRV(src)) < SVt_PVAV) {       /* in-memory bytes */
            STRLEN bl;
            s.bytes = SvPV(SvRV(src), bl);
            s.size  = (UV)bl;
            if (mtime_opt && SvOK(mtime_opt)) {
                s.mtime = (UV)SvUV(mtime_opt);
                s.has_mtime = 1;
            }
        }
        else {                                        /* a file path */
            s.path = SvPV(src, s.plen);
            if (PerlLIO_stat(s.path, &st) < 0 || !S_ISREG(st.st_mode)) {
                if (missing && SvOK(missing)) {
                    RETVAL = punk_triplet(aTHX_ 404,
                        sv_2mortal(newSVpvs("application/json")),
                        newSVpvs("{\"errors\":[{\"message\":\"Not Found\"}]}"),
                        NULL);
                    goto done;
                }
                croak("Punk::Context::send_file: cannot read '%s'", s.path);
            }
            s.size  = (UV)st.st_size;
            s.mtime = (mtime_opt && SvOK(mtime_opt))
                          ? (UV)SvUV(mtime_opt) : (UV)st.st_mtime;
            s.has_mtime = 1;
        }

        resp = psf_respond(aTHX_ env, &s, &o);
        if (!resp) {                     /* lost between stat and open */
            if (missing && SvOK(missing))
                resp = punk_triplet(aTHX_ 404,
                    sv_2mortal(newSVpvs("application/json")),
                    newSVpvs("{\"errors\":[{\"message\":\"Not Found\"}]}"),
                    NULL);
            else
                croak("Punk::Context::send_file: cannot read '%s'", s.path);
        }
        RETVAL = resp;
        done: ;
    }
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::SendFile::Reader

# The bounded 206 body: getline yields up to 64KB until the range is
# spent, close closes the handle. Never constructed by hand - send_file
# builds it; the struct lives in punk_sendfile.h so a C server can lift
# the handle and count out instead of calling getline.

SV *
getline(self)
        SV *self
    CODE:
    {
        psf_reader *r = psf_reader_of(aTHX_ self);
        UV want;
        SSize_t got;
        if (!r->fp || !r->remaining) XSRETURN_UNDEF;
        want = r->remaining < PSF_READER_CHUNK
                   ? r->remaining : PSF_READER_CHUNK;
        RETVAL = newSV(want + 1);
        SvPOK_on(RETVAL);
        got = PerlIO_read(r->fp, SvPVX(RETVAL), want);
        if (got <= 0) {
            SvREFCNT_dec(RETVAL);
            r->remaining = 0;
            XSRETURN_UNDEF;
        }
        SvCUR_set(RETVAL, (STRLEN)got);
        *SvEND(RETVAL) = '\0';
        r->remaining -= (UV)got;
    }
    OUTPUT:
        RETVAL

void
close(self)
        SV *self
    CODE:
    {
        psf_reader *r = psf_reader_of(aTHX_ self);
        if (r->fp) {
            PerlIO_close(r->fp);
            r->fp = NULL;
        }
        r->remaining = 0;
    }

# The underlying file descriptor (or -1 once closed). This is the seam a
# streaming server keys on: fileno + getline + the response Content-Length
# is everything Hyperman needs to sendfile the range instead of calling
# getline (its hm_bsrc_lift; the fd is read at its current position).
SV *
fileno(self)
        SV *self
    CODE:
    {
        psf_reader *r = psf_reader_of(aTHX_ self);
        RETVAL = newSViv(r->fp ? (IV)PerlIO_fileno(r->fp) : -1);
    }
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::SendFile

# Test shims: the parser and builders alone, for the t/ grammar tables.

void
_parse_range(header, size)
        SV *header
        SV *size
    PPCODE:
    {
        STRLEN hl;
        const char *h = SvPV(header, hl);
        UV off = 0, n = 0;
        int r = psf_parse_range(h, hl, (UV)SvUV(size), &off, &n);
        EXTEND(SP, 3);
        mPUSHi(r);
        mPUSHu(off);
        mPUSHu(n);
    }

SV *
_disposition(filename, inline_)
        SV *filename
        SV *inline_
    CODE:
        RETVAL = psf_disposition(aTHX_ filename, SvTRUE(inline_) ? 1 : 0);
    OUTPUT:
        RETVAL

SV *
_etag(mtime, size)
        SV *mtime
        SV *size
    CODE:
    {
        char buf[48];
        psf_etag(buf, sizeof buf, (UV)SvUV(mtime), (UV)SvUV(size));
        RETVAL = newSVpv(buf, 0);
    }
    OUTPUT:
        RETVAL
