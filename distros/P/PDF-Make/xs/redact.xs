MODULE = PDF::Make  PACKAGE = PDF::Make::Redaction
PROTOTYPES: ENABLE

void
mark(class, page, ...)
    char *class
    pdfmake_page_t *page
    PREINIT:
        double x0 = 0, y0 = 0, x1 = 0, y1 = 0;
        pdfmake_redact_opts_t opts;
        pdfmake_redact_t *r;
        int i;
    CODE:
        PERL_UNUSED_VAR(class);
        memset(&opts, 0, sizeof(opts));
        opts.overlay_font_size = 10;

        for (i = 2; i < items - 1; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "x0")) x0 = SvNV(val);
            else if (strEQ(key, "y0")) y0 = SvNV(val);
            else if (strEQ(key, "x1")) x1 = SvNV(val);
            else if (strEQ(key, "y1")) y1 = SvNV(val);
            else if (strEQ(key, "rect") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                AV *av = (AV *)SvRV(val);
                SV **e;
                if ((e = av_fetch(av, 0, 0))) x0 = SvNV(*e);
                if ((e = av_fetch(av, 1, 0))) y0 = SvNV(*e);
                if ((e = av_fetch(av, 2, 0))) x1 = SvNV(*e);
                if ((e = av_fetch(av, 3, 0))) y1 = SvNV(*e);
            }
            else if (strEQ(key, "overlay_color") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                AV *av = (AV *)SvRV(val);
                SV **e;
                if ((e = av_fetch(av, 0, 0))) opts.overlay_color[0] = SvNV(*e);
                if ((e = av_fetch(av, 1, 0))) opts.overlay_color[1] = SvNV(*e);
                if ((e = av_fetch(av, 2, 0))) opts.overlay_color[2] = SvNV(*e);
            }
            else if (strEQ(key, "overlay_text")) opts.overlay_text = SvPV_nolen(val);
            else if (strEQ(key, "overlay_font_size")) opts.overlay_font_size = SvNV(val);
        }

        r = pdfmake_page_mark_redaction(page, x0, y0, x1, y1, &opts);
        if (!r)
            croak("PDF::Make::Redaction: mark failed");

void
apply_page(class, page)
    char *class
    pdfmake_page_t *page
    CODE:
        PERL_UNUSED_VAR(class);
        if (pdfmake_page_apply_redactions(page) != PDFMAKE_OK)
            croak("PDF::Make::Redaction: apply failed");

void
apply_doc(class, doc)
    char *class
    pdfmake_doc_t *doc
    CODE:
        PERL_UNUSED_VAR(class);
        if (pdfmake_doc_apply_redactions(doc) != PDFMAKE_OK)
            croak("PDF::Make::Redaction: apply failed");

void
sanitize(class, doc)
    char *class
    pdfmake_doc_t *doc
    CODE:
        PERL_UNUSED_VAR(class);
        if (pdfmake_doc_sanitize_metadata(doc) != PDFMAKE_OK)
            croak("PDF::Make::Redaction: sanitize failed");

UV
count(class, page)
    char *class
    pdfmake_page_t *page
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pdfmake_page_redaction_count(page);
    OUTPUT:
        RETVAL

SV *
rewrite_stream(class, content_sv, rects_sv)
    char *class
    SV *content_sv
    SV *rects_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in_bytes;
        AV *rects_av;
        SSize_t n_rects;
        pdfmake_redact_t *rects = NULL;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        PERL_UNUSED_VAR(class);
        in_bytes = (const uint8_t *)SvPVbyte(content_sv, in_len);

        if (!SvROK(rects_sv) || SvTYPE(SvRV(rects_sv)) != SVt_PVAV) {
            croak("PDF::Make::Redaction::rewrite_stream: rects must be an arrayref");
        }
        rects_av = (AV *)SvRV(rects_sv);
        n_rects  = av_len(rects_av) + 1;

        if (n_rects > 0) {
            rects = (pdfmake_redact_t *)calloc((size_t)n_rects, sizeof(*rects));
            if (!rects) croak("PDF::Make::Redaction::rewrite_stream: out of memory");
            for (SSize_t i = 0; i < n_rects; i++) {
                SV **e = av_fetch(rects_av, i, 0);
                if (!e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVAV) {
                    free(rects);
                    croak("PDF::Make::Redaction::rewrite_stream: rect %ld not an arrayref", (long)i);
                }
                AV *rav = (AV *)SvRV(*e);
                SV **v;
                if ((v = av_fetch(rav, 0, 0))) rects[i].rect[0] = SvNV(*v);
                if ((v = av_fetch(rav, 1, 0))) rects[i].rect[1] = SvNV(*v);
                if ((v = av_fetch(rav, 2, 0))) rects[i].rect[2] = SvNV(*v);
                if ((v = av_fetch(rav, 3, 0))) rects[i].rect[3] = SvNV(*v);
            }
        }

        if (pdfmake_buf_init(&out) != PDFMAKE_OK) {
            free(rects);
            croak("PDF::Make::Redaction::rewrite_stream: buf init failed");
        }

        err = pdfmake_redact_rewrite_stream(
            in_bytes, (size_t)in_len, rects, (size_t)n_rects, &out);
        free(rects);
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&out);
            croak("PDF::Make::Redaction::rewrite_stream: rewrite failed");
        }

        RETVAL = newSVpvn((const char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL
