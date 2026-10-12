MODULE = Punk        PACKAGE = Punk::Context

PROTOTYPES: DISABLE

# $c->stream($content_type, $cb) / $c->stream($content_type, \%opts, $cb):
# a streamed response of unknown length (punk_stream.h). The handler returns
# the value this returns; the callback gets ($c, $w) and writes the body as it
# is produced. Options: status, headers, write_buffer_limit, blocking.
SV *
stream(self, content_type, ...)
        SV *self
        SV *content_type
    CODE:
    {
        HV *opts = NULL;
        SV *cb;
        STRLEN ctl, i;
        const char *ctp;
        if (items == 3) cb = ST(2);
        else if (items == 4) {
            if (!(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV))
                croak("Punk::Context: stream options must be a hashref");
            opts = (HV *)SvRV(ST(2));
            cb = ST(3);
        }
        else croak("usage: $c->stream($content_type, [\\%%opts,] $cb)");
        if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
            croak("Punk::Context: stream needs a coderef");
        if (!SvOK(content_type) || SvROK(content_type))
            croak("Punk::Context: stream needs a content type");
        ctp = SvPV_const(content_type, ctl);
        if (ctl == 0)
            croak("Punk::Context: stream needs a content type");
        for (i = 0; i < ctl; i++)
            if (ctp[i] == '\r' || ctp[i] == '\n' || ctp[i] == '\0')
                croak("Punk::Context: stream content type carries a control byte");
        if (opts) {
            HE *he;
            hv_iterinit(opts);
            while ((he = hv_iternext(opts))) {
                I32 kl;
                const char *k = hv_iterkey(he, &kl);
                if (!((kl == 6 && memEQ(k, "status", 6))
                   || (kl == 7 && memEQ(k, "headers", 7))
                   || (kl == 18 && memEQ(k, "write_buffer_limit", 18))
                   || (kl == 8 && memEQ(k, "blocking", 8))))
                    croak("Punk::Context: unknown stream option '%.*s' "
                          "(status, headers, write_buffer_limit, blocking)",
                          (int)kl, k);
            }
            {
                SV **s = hv_fetchs(opts, "status", 0);
                if (s && *s && SvOK(*s)) {
                    IV st = SvIV(*s);
                    if (st < 100 || st > 599)
                        croak("Punk::Context: stream status %" IVdf
                              " is not an HTTP status", st);
                }
            }
            {
                SV **h = hv_fetchs(opts, "headers", 0);
                if (h && *h && SvOK(*h)) {
                    AV *ha;
                    SSize_t j, n;
                    if (!(SvROK(*h) && SvTYPE(SvRV(*h)) == SVt_PVAV))
                        croak("Punk::Context: stream headers must be an "
                              "arrayref of pairs");
                    ha = (AV *)SvRV(*h);
                    n = av_len(ha) + 1;
                    if (n % 2)
                        croak("Punk::Context: stream headers must be an "
                              "arrayref of pairs");
                    for (j = 0; j < n; j++) {
                        SV **e = av_fetch(ha, j, 0);
                        STRLEN vl, vi;
                        const char *vp;
                        if (!(e && *e && SvOK(*e)) || SvROK(*e))
                            croak("Punk::Context: stream headers must be "
                                  "plain strings");
                        vp = SvPV_const(*e, vl);
                        for (vi = 0; vi < vl; vi++)
                            if (vp[vi] == '\r' || vp[vi] == '\n' || vp[vi] == '\0')
                                croak("Punk::Context: stream header carries "
                                      "a control byte");
                    }
                }
            }
        }
        RETVAL = punk_stream_start(aTHX_ self, content_type, opts, cb);
    }
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::Stream

# write($bytes): queue one chunk of the body. Chainable. Bytes, as PSGI bodies
# are; a wide-character string should be encoded first.
SV *
write(self, bytes)
        SV *self
        SV *bytes
    CODE:
    {
        STRLEN l;
        const char *p = SvOK(bytes) ? SvPV_const(bytes, l) : NULL;
        if (p) pst_write_body(aTHX_ pst_of(aTHX_ self), p, l);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# drain: a Punk::Future settled with 1 once everything written so far has
# reached the kernel, or 0 when the stream closed first. Awaiting it after
# each write bounds the buffer to one chunk; on the synchronous transports it
# is already settled.
SV *
drain(self)
        SV *self
    CODE:
    {
        punk_stream *st = pst_of(aTHX_ self);
        /* Pending while there is something the transport has not taken: our
         * own buffer on a detached socket, the server's on a stream handle,
         * which says so by answering a write with "full". Without the second
         * half every TLS and HTTP/2 response drained at once, and a slow
         * client had the whole export buffered for it. */
        if (st->state == PST_OPEN
            && ((st->mode == PST_MODE_DETACH && st->wlen > st->woff)
                || (st->mode == PST_MODE_HSTREAM && st->full))) {
            if (!st->drain_f) {
                punk_future *pf = pf_new(aTHX);
                st->drain_f = pf_bless(aTHX_ pf, "Punk::Future");
            }
            RETVAL = newSVsv(st->drain_f);
        }
        else {
            punk_future *pf = pf_new(aTHX);
            SV *f = pf_bless(aTHX_ pf, "Punk::Future");
            AV *vals = newAV();
            av_push(vals, newSViv(st->state == PST_OPEN ? 1 : 0));
            pf_settle(aTHX_ pf, f, PF_DONE, vals);
            RETVAL = f;
        }
    }
    OUTPUT:
        RETVAL

# close: end the response cleanly (the terminal chunk, then teardown once the
# buffer drains). The callback returning does this for you. Chainable.
SV *
close(self)
        SV *self
    CODE:
        pst_close(aTHX_ pst_of(aTHX_ self));
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

IV
is_open(self)
        SV *self
    CODE:
        RETVAL = pst_of(aTHX_ self)->state == PST_OPEN ? 1 : 0;
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        pst_free(aTHX_ pst_of(aTHX_ self));
