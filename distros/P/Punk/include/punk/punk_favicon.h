/* punk_favicon.h - GET /favicon.ico, from bytes frozen at to_app.
 *
 *     favicon 'root/static/favicon.ico';
 *
 * A browser and Google's favicon crawler both request /favicon.ico at the
 * site ROOT, where a /static mount does not answer - so every application
 * ends up hand-rolling the same root route: send_file, a Cache-Control, and
 * sitemap => 0. This is that route, once.
 *
 * The file is slurped at to_app and served from memory: an icon is a few
 * kilobytes fetched constantly, and a missing file should croak at boot
 * rather than 404 for as long as nobody notices. `punk dev` restarts on
 * change, so a replaced icon is picked up by the next boot for free.
 */

#ifndef PUNK_FAVICON_H
#define PUNK_FAVICON_H

/* A STRONG tag, unlike pcg_body_tag's weak one: the body is one frozen
 * buffer, so byte-equality is exactly what the tag promises, and it is
 * content-derived so every worker in a pool agrees without coordination. */
static SV *pfav_tag(pTHX_ SV *body) {
    unsigned char sum[32];
    char hex[PA_DIGEST_LEN + 1];
    STRLEN bl;
    const char *bp = SvPV_const(body, bl);
    SV *out;
    pk_sha256((const unsigned char *)bp, (size_t)bl, sum);
    pa_hex(sum, PA_DIGEST_LEN / 2, hex);
    out = newSVpvs("\"");
    sv_catpvn(out, hex, PA_DIGEST_LEN);
    sv_catpvs(out, "\"");
    return out;
}

/* Slurp and freeze, at to_app. The keyword stored only the path; everything
 * a request needs - bytes, type, tag, Cache-Control - is derived here, once,
 * so the serve closure is a write of things that already exist. */
static void pfav_freeze(pTHX_ HV *h) {
    SV *path = app_get(aTHX_ h, "favicon_path");
    SV *ma   = app_get(aTHX_ h, "favicon_max_age");
    STRLEN pl;
    const char *pp;
    PerlIO *fp;
    SV *body, *cc;
    char buf[8192];

    if (!(path && SvOK(path))) return; /* # uncoverable condition left count:2 class:ignore_covered_err */
    pp = SvPV_const(path, pl);
    fp = PerlIO_open(pp, "rb");
    if (!fp)
        croak("Punk: favicon '%s' cannot be read: %s", pp, Strerror(errno));
    body = newSVpvs("");
    for (;;) {
        SSize_t got = PerlIO_read(fp, buf, sizeof buf);
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err */
        if (got < 0) {
            SvREFCNT_dec(body); /* # uncoverable statement */
            PerlIO_close(fp); /* # uncoverable statement */
            croak("Punk: favicon '%s' cannot be read: %s", pp, /* # uncoverable statement */
                  Strerror(errno)); /* # uncoverable statement */
        }
        if (got == 0) break;
        sv_catpvn(body, buf, (STRLEN)got);
    }
    PerlIO_close(fp);

    (void)hv_stores(h, "favicon_etag", pfav_tag(aTHX_ body));
    (void)hv_stores(h, "favicon_body", body);
    (void)hv_stores(h, "favicon_type",
                    newSVpv(ps_content_type(pp, pl), 0));
    cc = newSVpvs("public, max-age=");
    sv_catpvf(cc, "%" IVdf,
              (ma && SvOK(ma)) ? SvIV(ma) : (IV)86400);
    (void)hv_stores(h, "favicon_cc", cc);
}

/* Serve. cap = [app]; the frozen values live on the app hash, so a request
 * is one closure call and a handful of fetches.
 *
 * The 304 follows punk_cget.h's rule that a 304 is defined by what is
 * ABSENT: the validator and the freshness lifetime go back, the headers
 * describing a representation that is not being sent do not - above all
 * Content-Length, which is how a client is taught to wait for a body that
 * never arrives. If-None-Match parsing is psf_not_modified's, the same
 * matcher send_file uses, so a list or a W/-prefixed tag behaves here
 * exactly as it does there. */
XS_INTERNAL(pfav_serve_cb);
XS_INTERNAL(pfav_serve_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app = cap ? *av_fetch(cap, 0, 0) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *c = items > 0 ? ST(0) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    HV *h = app ? app_hv(aTHX_ app) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *body = h ? app_get(aTHX_ h, "favicon_body") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *etag = h ? app_get(aTHX_ h, "favicon_etag") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *type = h ? app_get(aTHX_ h, "favicon_type") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *cc   = h ? app_get(aTHX_ h, "favicon_cc")   : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    int matched = 0;
    AV *resp, *headers, *bodyav;

    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err */
    if (!(body && SvOK(body))) XSRETURN_EMPTY;

    /*
     # uncoverable branch false
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err
     # uncoverable condition right count:3 class:ignore_covered_err */
    if (c && etag && SvOK(etag)) {
        AV *cav = pcx_av(aTHX_ c);
        SV *envsv = cav ? pcx_get(aTHX_ cav, PCX_ENV) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 class:ignore_covered_err
         # uncoverable condition right count:2 class:ignore_covered_err
         # uncoverable condition right count:3 class:ignore_covered_err */
        if (envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV) {
            STRLEN el;
            const char *ep = SvPV_const(etag, el);
            matched = psf_not_modified(aTHX_ (HV *)SvRV(envsv), ep, el, NULL);
        }
    }

    resp = newAV(); headers = newAV(); bodyav = newAV();
    if (matched) {
        av_push(headers, newSVpvs("ETag"));
        av_push(headers, newSVsv(etag));
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 class:ignore_covered_err
         # uncoverable condition right count:2 class:ignore_covered_err */
        if (cc && SvOK(cc)) {
            av_push(headers, newSVpvs("Cache-Control"));
            av_push(headers, newSVsv(cc));
        }
        av_push(resp, newSViv(304));
    }
    else {
        av_push(headers, newSVpvs("Content-Type"));
        /*
         # uncoverable condition right count:1 class:ignore_covered_err
         # uncoverable condition right count:2 class:ignore_covered_err */
        av_push(headers, (type && SvOK(type))
                             ? newSVsv(type)
                             : newSVpvs("application/octet-stream"));
        av_push(headers, newSVpvs("Content-Length"));
        av_push(headers, newSViv((IV)SvCUR(body)));
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 class:ignore_covered_err
         # uncoverable condition right count:2 class:ignore_covered_err */
        if (cc && SvOK(cc)) {
            av_push(headers, newSVpvs("Cache-Control"));
            av_push(headers, newSVsv(cc));
        }
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 class:ignore_covered_err
         # uncoverable condition right count:2 class:ignore_covered_err */
        if (etag && SvOK(etag)) {
            av_push(headers, newSVpvs("ETag"));
            av_push(headers, newSVsv(etag));
        }
        av_push(bodyav, newSVsv(body));
        av_push(resp, newSViv(200));
    }
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)bodyav));
    ST(0) = sv_2mortal(newRV_noinc((SV *)resp));
    XSRETURN(1);
}

#endif /* PUNK_FAVICON_H */
