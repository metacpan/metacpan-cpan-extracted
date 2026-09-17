MODULE = Punk::Observe   PACKAGE = Punk::Observe::View   PREFIX = povw_

SV *
povw_severity_name(SV *n)
    CODE:
        RETVAL = newSVpv(po_severity_name(SvOK(n) ? (int)SvIV(n) : 0), 0);
    OUTPUT:
        RETVAL

SV *
povw_span_kind_name(SV *k)
    CODE:
        RETVAL = newSVpv(po_span_kind_name(SvOK(k) ? (int)SvIV(k) : 0), 0);
    OUTPUT:
        RETVAL

SV *
povw_fmt_time(SV *ns)
    ALIAS:
        fmt_date = 1
    CODE:
    {
        STRLEN l = 0;
        const char *p = SvOK(ns) ? SvPV(ns, l) : NULL;
        char out[40];
        size_t n = p ? (ix ? po_fmt_date(p, (size_t)l, out)
                           : po_fmt_time(p, (size_t)l, out))
                     : (out[0] = '\0', 0);
        RETVAL = newSVpvn(out, n);
    }
    OUTPUT:
        RETVAL

SV *
povw_fmt_dur(SV *ns)
    CODE:
    {
        po_u64 v = 0;
        char out[32];
        size_t n;
        if (SvOK(ns)) (void)po_sv_to_u64(aTHX_ ns, &v);
        n = po_fmt_dur(v, out);
        RETVAL = newSVpvn(out, n);
    }
    OUTPUT:
        RETVAL

SV *
povw_fmt_count(SV *n)
    CODE:
    {
        STRLEN l = 0;
        const char *p = SvOK(n) ? SvPV(n, l) : "0";
        char out[64];
        size_t k;
        if (!SvOK(n)) l = 1;
        k = po_fmt_count(p, (size_t)l, out, sizeof(out));
        RETVAL = newSVpvn(out, k);
    }
    OUTPUT:
        RETVAL

SV *
povw_url_esc(SV *s)
    CODE:
    {
        STRLEN l = 0;
        const char *p = SvOK(s) ? SvPV(s, l) : "";
        char *out;
        size_t n;
        /* Three bytes per input byte is the worst case, and it is reached by
         * anything non-ASCII - which a log body routinely is. */
        Newx(out, (size_t)l * 3 + 1, char);
        n = po_url_esc(p, (size_t)l, out, (size_t)l * 3 + 1);
        RETVAL = newSVpvn(out, n);
        Safefree(out);
    }
    OUTPUT:
        RETVAL

# A stable identifier for one record.
#
# THERE IS NO ROW ID IN THE DATA AND THERE SHOULD NOT BE ONE: a record is
# whatever the exporter sent. So the id is derived from the record - its
# timestamp and a hash of what it says - which makes the detail page a LOOKUP
# rather than an offset into a file that compaction may have moved.
SV *
povw_record_id(SV *rec)
    CODE:
        RETVAL = povw_record_id_sv(aTHX_ rec);
    OUTPUT:
        RETVAL

int
povw_record_matches(SV *rec, SV *id)
    CODE:
        RETVAL = povw_record_matches_c(aTHX_ rec, id);
    OUTPUT:
        RETVAL

NV
povw__pct(SV *v, SV *total)
    CODE:
    {
        po_u64 a = 0, b = 0;
        if (SvOK(v))     (void)po_sv_to_u64(aTHX_ v, &a);
        if (SvOK(total)) (void)po_sv_to_u64(aTHX_ total, &b);
        RETVAL = po_pct(a, b);
    }
    OUTPUT:
        RETVAL

SV *
povw_fmt_bytes(SV *n)
    CODE:
    {
        po_u64 v = 0;
        char out[48];
        size_t k;
        if (SvOK(n)) (void)po_sv_to_u64(aTHX_ n, &v);
        k = po_fmt_bytes(v, out);
        RETVAL = newSVpvn(out, k);
    }
    OUTPUT:
        RETVAL

# An SVG path from two coordinate arrays.
#
# The formatting is po_svg.h's, which is hand-rolled for the reason stated
# there: `%f` in a Perl-flavoured formatter reads an NV, and a path attribute
# containing `1e-05` is not a path - the chart silently does not draw, on one
# platform, with no error.
SV *
povw__path(SV *xs_sv, SV *ys_sv)
    CODE:
    {
        AV *ax, *ay;
        SSize_t i, n;
        double *xb, *yb;

        if (!SvROK(xs_sv) || !SvROK(ys_sv)) croak("arrayrefs required");
        ax = (AV *)SvRV(xs_sv);
        ay = (AV *)SvRV(ys_sv);
        n = av_len(ax) + 1;
        Newx(xb, n ? n : 1, double);
        Newx(yb, n ? n : 1, double);
        for (i = 0; i < n; i++) {
            SV **a = av_fetch(ax, i, 0);
            SV **b = av_fetch(ay, i, 0);
            xb[i] = a ? (double)SvNV(*a) : 0;
            yb[i] = b ? (double)SvNV(*b) : 0;
        }
        RETVAL = povw_path_sv(aTHX_ xb, yb, (size_t)n);
        Safefree(xb); Safefree(yb);
    }
    OUTPUT:
        RETVAL

NV
povw__max(NV a, NV b)
    ALIAS:
        _maxf = 1
    CODE:
        PERL_UNUSED_VAR(ix);
        RETVAL = a > b ? a : b;
    OUTPUT:
        RETVAL

# The x of a point as a fraction of the window, and the y of a value flipped
# for SVG. Both take the instants as they are, so the subtraction happens in
# the type that holds them.
NV
povw_chart_x(SV *t, SV *t0, SV *t1, NV width)
    CODE:
    {
        po_u64 a = 0, b = 0, c = 0;
        (void)po_sv_to_u64(aTHX_ t,  &a);
        (void)po_sv_to_u64(aTHX_ t0, &b);
        (void)po_sv_to_u64(aTHX_ t1, &c);
        RETVAL = po_chart_x(a, b, c, (double)width);
    }
    OUTPUT:
        RETVAL

NV
povw_chart_y(NV v, NV lo, NV hi, NV height)
    CODE:
        RETVAL = po_chart_y((double)v, (double)lo, (double)hi, (double)height);
    OUTPUT:
        RETVAL

# A trace identifier out of whatever somebody pasted, or nothing.
#
# TWO SPELLINGS ARE IN CIRCULATION and a search box has to take both. The UI's
# own links carry `<hi>-<lo>` in decimal, because that is what the record
# holds; every other tool in the ecosystem - a `traceparent` header, a log
# line from another vendor, the OTLP wire - spells the same id as 32 hex
# characters. Somebody pasting the second into a box that only understood the
# first gets "no traces", which reads as "that trace is gone".
#
# Returns (hi, lo), or an empty list when the text is not an identifier at
# all - which is the signal to treat it as a search term instead.
void
povw_trace_id(SV *text)
    PPCODE:
    {
        po_u64 hi = 0, lo = 0;
        if (!povw_trace_id_c(aTHX_ text, &hi, &lo)) XSRETURN_EMPTY;
        EXTEND(SP, 2);
        mPUSHs(po_u64_to_sv(hi));
        mPUSHs(po_u64_to_sv(lo));
        XSRETURN(2);
    }

# The time range a page reads, most specific source first: an explicit
# from/to (what the brush writes into the URL when a chart is dragged), then
# a named range, then the default.
void
povw_window(SV *req, ...)
    PPCODE:
    {
        HV *h = NULL;
        SV **f;
        const char *dflt = "1h";
        STRLEN dlen = 2;
        const po_range *r;
        IV ai;

        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV) h = (HV *)SvRV(req);
        for (ai = 1; ai + 1 < items; ai += 2)
            if (strEQ(SvPV_nolen(ST(ai)), "default") && SvOK(ST(ai + 1)))
                dflt = SvPV(ST(ai + 1), dlen);

        if (h) {
            SV **fs = hv_fetchs(h, "from", 0);
            SV **ts = hv_fetchs(h, "to", 0);
            if (fs && ts && SvOK(*fs) && SvOK(*ts)) {
                STRLEN fl, tl;
                const char *fp = SvPV(*fs, fl);
                const char *tp = SvPV(*ts, tl);
                if (po_ns_plausible(fp, (size_t)fl)
                    && po_ns_plausible(tp, (size_t)tl)) {
                    mXPUSHs(newSVpvn(fp, fl));
                    mXPUSHs(newSVpvn(tp, tl));
                    mXPUSHs(newSVpvs("custom"));
                    XSRETURN(3);
                }
            }
        }

        r = NULL;
        if (h && (f = hv_fetchs(h, "range", 0)) && SvOK(*f)) {
            STRLEN kl;
            const char *kp = SvPV(*f, kl);
            r = po_range_find(kp, (size_t)kl);
        }
        if (!r) r = po_range_find(dflt, (size_t)dlen);
        if (!r) r = po_range_find("1h", 2);

        if (!r->secs) {
            /* `all`: two undefs, and the caller passes them straight through
             * to the store, where an absent bound means no limit. */
            mXPUSHs(newSV(0));
            mXPUSHs(newSV(0));
            mXPUSHs(newSVpvs("all"));
            XSRETURN(3);
        }
        {
            po_u64 now = (po_u64)time(NULL);
            mXPUSHs(po_u64_to_sv((now - r->secs) * 1000000000ULL));
            mXPUSHs(po_u64_to_sv((now + 1) * 1000000000ULL));
            mXPUSHs(newSVpv(r->key, 0));
        }
    }

# The duration box, as a number of nanoseconds and the end it bounds.
#
# Three answers, not two: a duration, nothing at all, and TEXT THAT IS NOT A
# DURATION. The third used to be indistinguishable from the second, so a
# filter that could not be read was a filter that was not applied and not
# mentioned - and an unfiltered table is the one result that looks like an
# answer rather than like a mistake.
#
# Returns (ns, "min"|"max") for a duration, () for an empty box, and (undef)
# for text that was meant to be one. The caller says so on the page.
void
povw_min_duration(SV *text)
    PPCODE:
    {
        STRLEN len = 0;
        const char *p = SvOK(text) ? SvPV(text, len) : NULL;
        po_u64 ns = 0;
        int is_max = 0;
        int r = po_min_duration(p, (size_t)len, &ns, &is_max);
        if (r == 0) XSRETURN_EMPTY;
        if (r < 0) { mXPUSHs(newSV(0)); XSRETURN(1); }
        EXTEND(SP, 2);
        mPUSHs(po_u64_to_sv(ns));
        mPUSHs(newSVpv(is_max ? "max" : "min", 0));
        XSRETURN(2);
    }

# The range control's own variables, so every screen that reads a window can
# offer the same way of changing it.
void
povw_range_vars(SV *req, SV *active)
    PPCODE:
    {
        STRLEN al = 0;
        const char *ap = SvOK(active) ? SvPV(active, al) : "";
        AV *ranges = newAV();
        int i;
        int is_all = (al == 3 && memcmp(ap, "all", 3) == 0);

        PERL_UNUSED_VAR(req);
        for (i = 0; i < PO_NRANGES; i++) {
            HV *e = newHV();
            size_t kl = strlen(PO_RANGES[i].key);
            hv_stores(e, "key",   newSVpv(PO_RANGES[i].key, 0));
            hv_stores(e, "label", newSVpv(PO_RANGES[i].label, 0));
            hv_stores(e, "current",
                      newSViv(kl == (size_t)al && memcmp(PO_RANGES[i].key, ap, kl) == 0));
            av_push(ranges, newRV_noinc((SV *)e));
        }

        mXPUSHs(newSVpvs("range"));
        mXPUSHs(newSVpvn(ap, al));
        /* The `all` case reads differently in an empty state: there is no
         * wider range to suggest, so the message must not suggest one. */
        mXPUSHs(newSVpvs("range_all"));
        mXPUSHs(newSViv(is_all));
        /* A CUSTOM WINDOW HAS NO KEY, so the form carries the pair instead.
         * Without this the hidden field says "custom" and the two instants
         * that gave it meaning are gone by the next submit - which is a
         * dragged selection on a chart lasting exactly until the next thing
         * anybody types. */
        mXPUSHs(newSVpvs("range_custom"));
        mXPUSHs(newSViv(al == 6 && memcmp(ap, "custom", 6) == 0));
        mXPUSHs(newSVpvs("ranges"));
        mXPUSHs(newRV_noinc((SV *)ranges));
        /* A page that was given a range control needs the calendar's assets.
         * This is set HERE rather than per screen for the same reason the
         * button list is built here: the two would be one edit apart, and the
         * screen that got the flag without the vars, or the vars without the
         * flag, is the one nobody notices until it is in front of somebody. */
        mXPUSHs(newSVpvs("wants_range"));
        mXPUSHs(newSViv(1));
    }

# Dispatch, and the nav highlight.
#
# The nav highlights itself from the PAGE NAME rather than from the path,
# because a mount can be anywhere and the path is not the page.
void
povw_page(SV *class, SV *store, SV *name, SV *req)
    PPCODE:
    {
        STRLEN nl;
        const char *np = SvOK(name) ? SvPV(name, nl) : (nl = 0, "");
        char sub[64];
        SV *vars = NULL;
        HV *vh;
        GV *gv;

        if (nl + 7 >= sizeof(sub)) XSRETURN_UNDEF;
        memcpy(sub, "_page_", 6);
        memcpy(sub + 6, np, nl);
        sub[6 + nl] = '\0';

        gv = gv_fetchmethod_autoload(gv_stashsv(class, 0), sub, 0);
        if (!gv) {
            HV *e = newHV();
            char up[64];
            memcpy(up, np, nl); up[nl] = '\0';
            if (nl && up[0] >= 'a' && up[0] <= 'z') up[0] = (char)(up[0] - 32);
            hv_stores(e, "heading", newSVpvn(up, nl));
            mXPUSHs(newRV_noinc((SV *)e));
            XSRETURN(1);
        }

        {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(class);
            XPUSHs(store);
            XPUSHs(SvOK(req) && SvROK(req) ? req
                                           : sv_2mortal(newRV_noinc((SV *)newHV())));
            PUTBACK;
            n = call_sv((SV *)GvCV(gv), G_SCALAR);
            SPAGAIN;
            vars = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
        }

        if (!vars || !SvROK(vars) || SvTYPE(SvRV(vars)) != SVt_PVHV) {
            if (vars) SvREFCNT_dec(vars);
            vars = newRV_noinc((SV *)newHV());
        }
        vh = (HV *)SvRV(vars);

        {
            char key[80];
            memcpy(key, "here_", 5);
            memcpy(key + 5, np, nl);
            hv_store(vh, key, (I32)(5 + nl), newSViv(1), 0);
        }
        if (nl == 6 && memcmp(np, "status", 6) == 0)
            hv_stores(vh, "here_home", newSViv(1));
        if (nl == 5 && memcmp(np, "trace", 5) == 0)
            hv_stores(vh, "here_traces", newSViv(1));

        mXPUSHs(vars);
    }

# ---- the pages ------------------------------------------------------------

SV *
povw__page_status(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *out = newHV();
        HV *s;
        SV *stats = NULL;

        PERL_UNUSED_VAR(class);
        PERL_UNUSED_VAR(req);

        if (SvOK(store) && SvROK(store)) {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            PUTBACK;
            n = call_method("stats", G_SCALAR);
            SPAGAIN;
            stats = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
        }
        s = (stats && SvROK(stats) && SvTYPE(SvRV(stats)) == SVt_PVHV)
            ? (HV *)SvRV(stats) : newHV();

        /* THE RAW ANSWER RIDES ALONG, so the plugin does not ask again.
         *
         * _page needs the unformatted bytes for the storage gauge and used to
         * call $store->stats a second time to get them - the same directory
         * walk, every sidecar read twice, on every load of this page. The
         * underscore prefix is the convention for "not a template variable":
         * the plugin consumes it and deletes it before render. */
        if (stats)
            hv_stores(out, "_stats", SvREFCNT_inc(stats));

        hv_stores(out, "heading", newSVpvs("Overview"));
        hv_stores(out, "title",   newSVpvs("Overview"));

        povw_set_iv(aTHX_ out, "orphan_index",   s, "orphan_index");
        povw_set_iv(aTHX_ out, "wal_depth",      s, "wal_depth");
        povw_set_iv(aTHX_ out, "segments",       s, "segments");
        povw_set_iv(aTHX_ out, "compaction_lag", s, "unindexed");

        povw_set_count(aTHX_ out, "ingest_rate", s, "records");
        povw_set_count(aTHX_ out, "logs",        s, "logs");
        povw_set_count(aTHX_ out, "spans",       s, "spans");
        povw_set_count(aTHX_ out, "metrics",     s, "metrics");
        povw_set_count(aTHX_ out, "traces",      s, "traces");
        povw_set_count(aTHX_ out, "errors",      s, "errors");

        {
            SV **f = hv_fetchs(s, "bytes", 0);
            po_u64 b = 0;
            char buf[48];
            size_t n;
            if (f && SvOK(*f)) (void)po_sv_to_u64(aTHX_ *f, &b);
            n = po_fmt_bytes(b, buf);
            hv_stores(out, "store_bytes", newSVpvn(buf, n));
        }

        /* `series` is the COUNT and `services` the list, and they are two
         * different template variables with names one letter apart. Kept as
         * they were rather than tidied, because the templates read them. */
        {
            SV **f = hv_fetchs(s, "services", 0);
            hv_stores(out, "series", newSViv(f && SvOK(*f) ? SvIV(*f) : 0));
        }
        {
            AV *list = newAV();
            SV **f = hv_fetchs(s, "service", 0);
            if (f && SvROK(*f) && SvTYPE(SvRV(*f)) == SVt_PVHV) {
                HV *svc = (HV *)SvRV(*f);
                AV *keys = newAV();
                po_sortpair *pairs;
                HE *he;
                SSize_t i, n;

                hv_iterinit(svc);
                while ((he = hv_iternext(svc)))
                    av_push(keys, newSVsv(hv_iterkeysv(he)));
                n = av_len(keys) + 1;

                /* BUSIEST FIRST, so the eye lands on the traffic rather than
                 * on whatever order the hash happened to be in. */
                Newx(pairs, n ? n : 1, po_sortpair);
                for (i = 0; i < n; i++) {
                    SV **k = av_fetch(keys, i, 0);
                    STRLEN kl;
                    const char *kp = SvPV(*k, kl);
                    SV **v = hv_fetch(svc, kp, (I32)kl, 0);
                    pairs[i].key = (v && SvOK(*v)) ? (po_u64)SvUV(*v) : 0;
                    pairs[i].sv  = *k;
                }
                if (n > 1) qsort(pairs, (size_t)n, sizeof(po_sortpair),
                                 po_sortpair_desc);
                for (i = 0; i < n; i++) {
                    HV *e = newHV();
                    STRLEN kl;
                    const char *kp = SvPV(pairs[i].sv, kl);
                    SV **v = hv_fetch(svc, kp, (I32)kl, 0);
                    char buf[64];
                    STRLEN vl = 0;
                    const char *vp = (v && SvOK(*v)) ? SvPV(*v, vl) : "0";
                    size_t cn;
                    if (!v || !SvOK(*v)) vl = 1;
                    cn = po_fmt_count(vp, (size_t)vl, buf, sizeof(buf));
                    hv_stores(e, "name",  newSVpvn(kp, kl));
                    hv_stores(e, "count", newSVpvn(buf, cn));
                    av_push(list, newRV_noinc((SV *)e));
                }
                Safefree(pairs);
                SvREFCNT_dec((SV *)keys);
            }
            hv_stores(out, "services", newRV_noinc((SV *)list));
        }

        if (stats) SvREFCNT_dec(stats);
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

SV *
povw__page_logs(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *v = newHV();
        SV *from = NULL, *to = NULL, *res = NULL;
        HV *r = NULL;
        SV **f;
        const char *q = "log";
        STRLEN ql = 3;
        char *esc;

        PERL_UNUSED_VAR(class);

        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV) {
            f = hv_fetchs((HV *)SvRV(req), "q", 0);
            if (f && SvOK(*f)) {
                STRLEN l;
                const char *p = SvPV(*f, l);
                size_t i;
                for (i = 0; i < (size_t)l; i++)
                    if (p[i] != ' ' && p[i] != '\t' && p[i] != '\n') { q = p; ql = l; break; }
            }
        }

        hv_stores(v, "heading", newSVpvs("Logs"));
        hv_stores(v, "title",   newSVpvs("Logs"));
        hv_stores(v, "query",   newSVpvn(q, ql));
        hv_stores(v, "tail",    newSViv(1));
        hv_stores(v, "rows",    newRV_noinc((SV *)newAV()));
        Newx(esc, (size_t)ql * 3 + 1, char);
        {
            size_t en = po_url_esc(q, (size_t)ql, esc, (size_t)ql * 3 + 1);
            hv_stores(v, "query_esc", newSVpvn(esc, en));
        }
        Safefree(esc);

        povw_window_vars(aTHX_ v, req, &from, &to);

        /* THE CURSOR IS AN INSTANT, so it is stable while new lines arrive -
         * an offset is not: five hundred new lines shift every offset by five
         * hundred, and page two repeats page one. `before` narrows the top of
         * the window to just under the oldest line of the previous page; the
         * range, the query and everything else stay exactly as they were, so
         * a page of results is still a link.
         *
         * Exclusive by one nanosecond via nsub, because the boundary line was
         * already shown. Two lines sharing an instant across a page boundary
         * would be the one loss; at nanosecond resolution that is accepted
         * and recorded rather than solved with a composite cursor. */
        {
            SV **bf = NULL;
            if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV)
                bf = hv_fetchs((HV *)SvRV(req), "before", 0);
            if (bf && SvOK(*bf)) {
                STRLEN bl;
                const char *bp = SvPV(*bf, bl);
                if (po_ns_plausible(bp, (size_t)bl)) {
                    ENTER; SAVETMPS; PUSHMARK(SP);
                    XPUSHs(*bf);
                    XPUSHs(sv_2mortal(newSVpvs("1")));
                    PUTBACK;
                    if (call_pv("Punk::Observe::Store::nsub", G_SCALAR) == 1) {
                        SPAGAIN;
                        SvREFCNT_dec(to);
                        to = SvREFCNT_inc(POPs);
                        PUTBACK;
                    }
                    FREETMPS; LEAVE;
                    SPAGAIN;
                    hv_stores(v, "paged", newSViv(1));
                }
            }
        }

        if (!SvOK(store) || !SvROK(store)) {
            SvREFCNT_dec(from); SvREFCNT_dec(to);
            goto done;
        }

        {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(newSVpvn(q, ql)));
            XPUSHs(sv_2mortal(newSVpvs("from"))); XPUSHs(sv_2mortal(newSVsv(from)));
            XPUSHs(sv_2mortal(newSVpvs("to")));   XPUSHs(sv_2mortal(newSVsv(to)));
            /* A PAGE OF LOG LINES, NOT ALL OF THEM.
             *
             * Unbounded, this asked for every line in the window and got
             * them: a busy hour is six figures of rows, and the screen came
             * back as forty-four megabytes of HTML that no browser is going
             * to lay out. The store hands rows over newest first, so a bound
             * here is the most recent N - which is what a log viewer is for -
             * and it sets `truncated`, so the page says it is partial rather
             * than looking complete. */
            XPUSHs(sv_2mortal(newSVpvs("limit")));
            XPUSHs(sv_2mortal(newSViv(POVW_LOG_PAGE)));
            PUTBACK;
            n = call_method("query", G_SCALAR);
            SPAGAIN;
            res = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
        }
        SvREFCNT_dec(from); SvREFCNT_dec(to);

        if (!res || !SvROK(res) || SvTYPE(SvRV(res)) != SVt_PVHV) {
            if (res) SvREFCNT_dec(res);
            goto done;
        }
        r = (HV *)SvRV(res);

        f = hv_fetchs(r, "ok", 0);
        if (!f || !SvTRUE(*f)) {
            SV **e = hv_fetchs(r, "error", 0);
            SV **st = hv_fetchs(r, "stage", 0);
            int parse = st && SvOK(*st) && strEQ(SvPV_nolen(*st), "parse");
            hv_stores(v, "error", (e && SvOK(*e)) ? newSVsv(*e)
                      : newSVpvs("that query could not be run"));
            /* The hint names the NEXT THING TO TRY. The store's own is the
             * most specific one there is - a refused join says "narrow the
             * range, or aggregate before the jump" - and swallowing it for
             * a generic line threw the guidance away. */
            {
                SV **ht = hv_fetchs(r, "hint", 0);
                hv_stores(v, "hint", (ht && SvOK(*ht) && SvCUR(*ht))
                          ? newSVsv(*ht)
                          : parse
                          ? newSVpvs("Check the stage after the pipe.")
                          : newSVpvs("Narrow the range or add a filter."));
            }
            SvREFCNT_dec(res);
            goto done;
        }

        {
            SV **shape = hv_fetchs(r, "shape", 0);
            int is_rows = !shape || !SvOK(*shape)
                        || strEQ(SvPV_nolen(*shape), "rows");
            int is_buckets = shape && SvOK(*shape)
                          && strEQ(SvPV_nolen(*shape), "buckets");
            SV **mv = hv_fetchs(r, "meta", 0);

            /* `| viz` works here exactly as it does in the explorer - same
             * function, same refusals - and the bucketed fill comes with it,
             * so `log | bucket(30s) count` draws instead of heading an empty
             * panel. */
            povw_apply_viz(aTHX_ v, r, res, q, (size_t)ql,
                           is_rows, is_buckets);

            /* THE VOLUME CHART AND THE TABLE ANSWER THE SAME QUESTION.
             *
             * It is the reader's own query with a bucket stage added, so a
             * filter typed into the box narrows both. A chart of everything
             * above a table of errors is two answers on one screen, and
             * nothing on it says which one is being looked at.
             *
             * Only where they asked for rows: appending an aggregate to a
             * query that already has one is a different question, and usually
             * a parse error. */
            if (is_rows)
                povw_add_figure(aTHX_ v, "Punk::Observe::Plot::volume_figure",
                                store, q, ql, "volume_plot");

            HV *meta = (mv && SvROK(*mv) && SvTYPE(SvRV(*mv)) == SVt_PVHV)
                     ? (HV *)SvRV(*mv) : NULL;

            if (!is_rows) {
                /* An aggregate over logs is a table of numbers and is
                 * rendered as one. Drawing it as a log list would be
                 * inventing rows. */
                AV *groups = newAV();
                SV **gv = hv_fetchs(r, "groups", 0);
                if (gv && SvROK(*gv) && SvTYPE(SvRV(*gv)) == SVt_PVAV) {
                    AV *ga = (AV *)SvRV(*gv);
                    SSize_t i, n = av_len(ga) + 1;
                    for (i = 0; i < n; i++) {
                        SV **e = av_fetch(ga, i, 0);
                        HV *g, *o;
                        SV **x;
                        if (!e || !SvROK(*e)) continue;
                        g = (HV *)SvRV(*e);
                        o = newHV();
                        x = hv_fetchs(g, "key", 0);
                        hv_stores(o, "key", x ? newSVsv(*x) : newSVpvs(""));
                        x = hv_fetchs(g, "value", 0);
                        hv_stores(o, "value",
                                  x ? povw_fmt_value(aTHX_ (double)SvNV(*x))
                                    : newSVpvs("0"));
                        povw_set_count(aTHX_ o, "count", g, "count");
                        av_push(groups, newRV_noinc((SV *)o));
                    }
                }
                hv_stores(v, "groups", newRV_noinc((SV *)groups));
            }
            else {
                AV *rows = newAV();
                SV **rv = hv_fetchs(r, "rows", 0);
                if (rv && SvROK(*rv) && SvTYPE(SvRV(*rv)) == SVt_PVAV) {
                    AV *ra = (AV *)SvRV(*rv);
                    SSize_t i, n = av_len(ra) + 1;
                    for (i = 0; i < n; i++) {
                        SV **e = av_fetch(ra, i, 0);
                        HV *row, *o;
                        SV **x;
                        int sev;
                        const char *sname;
                        char tb[40];
                        size_t tn;
                        STRLEN tl = 0;
                        const char *tp;

                        if (!e || !SvROK(*e)) continue;
                        row = (HV *)SvRV(*e);
                        o = newHV();

                        x = hv_fetchs(row, "severity", 0);
                        sev = (x && SvOK(*x)) ? (int)SvIV(*x) : 0;
                        sname = po_severity_name(sev);

                        x = hv_fetchs(row, "t", 0);
                        tp = (x && SvOK(*x)) ? SvPV(*x, tl) : "";
                        tn = po_fmt_time(tp, (size_t)tl, tb);
                        hv_stores(o, "time", newSVpvn(tb, tn));
                        tn = po_fmt_date(tp, (size_t)tl, tb);
                        hv_stores(o, "date", newSVpvn(tb, tn));

                        hv_stores(o, "sev_name", newSVpv(sname, 0));
                        hv_stores(o, "severity", newSViv(sev));

                        x = hv_fetchs(row, "service", 0);
                        hv_stores(o, "service", (x && SvOK(*x) && SvCUR(*x))
                                  ? newSVsv(*x) : newSVpvs("unknown"));
                        x = hv_fetchs(row, "body", 0);
                        hv_stores(o, "body", (x && SvOK(*x)) ? newSVsv(*x)
                                                             : newSVpvs(""));
                        /* Colour is never the only signal: the row carries a
                         * class that adds weight and a marker too. */
                        hv_stores(o, "row_class",
                                  (strEQ(sname, "error") || strEQ(sname, "fatal"))
                                  ? newSVpvs("row-error") : newSVpvs(""));

                        {   /* THE CANONICAL SPELLING, the same one every
                             * link in this UI carries and the same one a
                             * `traceparent` header does. The decimal pair is
                             * what the record holds; it is not what anybody
                             * reads, pastes or recognises. */
                            SV **hi = hv_fetchs(row, "trace_hi", 0);
                            SV **lo = hv_fetchs(row, "trace_lo", 0);
                            int any = (hi && SvOK(*hi) && SvTRUE(*hi))
                                   || (lo && SvOK(*lo) && SvTRUE(*lo));
                            if (any)
                                hv_stores(o, "trace",
                                    povw_trace_hex_sv(aTHX_
                                        hi ? *hi : &PL_sv_no,
                                        lo ? *lo : &PL_sv_no));
                            else hv_stores(o, "trace", newSVpvs(""));
                        }

                        hv_stores(o, "id", povw_record_id_sv(aTHX_ *e));
                        av_push(rows, newRV_noinc((SV *)o));
                    }

                    /* THE WAY TO THE 501st LINE. Rows are newest first, so
                     * when the page is full the oldest line shown is the
                     * cursor for the next one: `before=<its instant>` narrows
                     * the window's top and everything else in the URL stays.
                     * Only when full - a short page IS the end, and an
                     * "older" link there would page into nothing. */
                    if (n >= POVW_LOG_PAGE && n > 0) {
                        SV **le = av_fetch(ra, n - 1, 0);
                        SV **lt = (le && SvROK(*le))
                                ? hv_fetchs((HV *)SvRV(*le), "t", 0) : NULL;
                        if (lt && SvOK(*lt))
                            hv_stores(v, "older_cursor", newSVsv(*lt));
                    }
                }
                hv_stores(v, "rows", newRV_noinc((SV *)rows));
                if (meta) povw_set_iv(aTHX_ v, "degraded", meta, "degraded");
            }

            if (meta) {
                povw_set_count(aTHX_ v, "scanned", meta, "scanned_rows");
                povw_set_iv(aTHX_ v, "truncated", meta, "truncated");
            }
        }
        SvREFCNT_dec(res);

    /* ONE EXIT.
     *
     * An early XSRETURN in a CODE:/OUTPUT: body returns before the generated
     * OUTPUT block has pushed RETVAL, so the caller gets whatever happened to
     * be on the stack - which for the error path here was an empty page with
     * no error on it, exactly when there was something to say. */
    done:
        RETVAL = newRV_noinc((SV *)v);
    }
    OUTPUT:
        RETVAL

SV *
povw__parent_id(SV *tree, SV *span)
    CODE:
        RETVAL = povw_parent_id_sv(aTHX_ tree, span);
    OUTPUT:
        RETVAL

# One dashboard, its panels each run through the same query path the explorer
# uses - so a chart on a dashboard and the same chart in the explorer are the
# same code and cannot disagree.
SV *
povw__page_dashboard(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *v = newHV();
        HV *rq = NULL;
        SV *from = NULL, *to = NULL;
        SV **f;
        SV *src = NULL, *d = NULL;
        HV *dh = NULL;
        const char *slug = "";
        STRLEN sl = 0;

        PERL_UNUSED_VAR(class);
        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV) rq = (HV *)SvRV(req);
        if (rq && (f = hv_fetchs(rq, "slug", 0)) && SvOK(*f)) slug = SvPV(*f, sl);

        hv_stores(v, "heading",    newSVpvs("Dashboard"));
        hv_stores(v, "title",      newSVpvs("Dashboard"));
        hv_stores(v, "panels",     newRV_noinc((SV *)newAV()));
        hv_stores(v, "cols",       newSViv(2));
        hv_stores(v, "slug",       newSVpvn(slug, sl));
        hv_stores(v, "can_edit",   newSViv(0));
        hv_stores(v, "configured", newSViv(0));
        povw_window_vars(aTHX_ v, req, &from, &to);
        /* The window variables INCLUDE the range control, and the page shows
         * it: every panel already runs over the reader's window, and hiding
         * the picker made the dashboard the one screen where narrowing to
         * the incident meant editing the URL by hand. */

        if (rq) src = (f = hv_fetchs(rq, "dashboards", 0)) && SvOK(*f) ? *f : NULL;
        if (!src) goto done;
        hv_stores(v, "configured", newSViv(1));

        /* A coderef is how a host supplies one dashboard at a time; a plain
         * hashref is how a test supplies the only one there is. */
        if (SvROK(src) && SvTYPE(SvRV(src)) == SVt_PVCV) {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpvn(slug, sl)));
            XPUSHs(req);
            PUTBACK;
            n = call_sv(src, G_SCALAR | G_EVAL);
            SPAGAIN;
            d = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
            if (povw_seam_died(aTHX_ v, "dashboard")) {
                if (d) SvREFCNT_dec(d);
                d = NULL;
            }
        }
        else d = SvREFCNT_inc(src);

        if (!d || !SvROK(d) || SvTYPE(SvRV(d)) != SVt_PVHV) {
            if (d) SvREFCNT_dec(d);
            goto done;
        }
        dh = (HV *)SvRV(d);

        {
            SV **t = hv_fetchs(dh, "title", 0);
            SV *title = (t && SvOK(*t) && SvCUR(*t)) ? newSVsv(*t)
                      : (sl ? newSVpvn(slug, sl) : newSVpvs("Dashboard"));
            hv_stores(v, "title",   newSVsv(title));
            hv_stores(v, "heading", title);
        }
        {
            SV **c = hv_fetchs(dh, "cols", 0);
            hv_stores(v, "cols",
                      newSViv(povw_grid((c && SvOK(*c)) ? SvIV(*c) : 0, 2)));
        }
        {
            SV **e = hv_fetchs(dh, "can_edit", 0);
            hv_stores(v, "can_edit", newSViv(e && SvTRUE(*e) ? 1 : 0));
        }
        {
            /* THE RESOLVED SLUG, when the reader supplies one: with no slug
             * in the URL the reader falls back to the first dashboard, and
             * every per-panel fragment URL, the range form and the edit
             * button must name the dashboard actually shown - an empty
             * segment in the middle of a deferred URL is a panel that
             * never loads, on exactly the page a bookmark lands on. */
            SV **s2 = hv_fetchs(dh, "slug", 0);
            if (s2 && SvOK(*s2) && SvCUR(*s2))
                hv_stores(v, "slug", newSVsv(*s2));
        }
        {
            AV *list = newAV();
            SV **lv = hv_fetchs(dh, "list", 0);
            if (lv && SvROK(*lv) && SvTYPE(SvRV(*lv)) == SVt_PVAV) {
                AV *la = (AV *)SvRV(*lv);
                SSize_t i, n = av_len(la) + 1;
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(la, i, 0);
                    HV *o, *s;
                    SV **x;
                    if (!e || !SvROK(*e)) continue;
                    s = (HV *)SvRV(*e);
                    o = newHV();
                    x = hv_fetchs(s, "slug", 0);
                    hv_stores(o, "slug",  x ? newSVsv(*x) : newSV(0));
                    x = hv_fetchs(s, "title", 0);
                    hv_stores(o, "title", x ? newSVsv(*x) : newSV(0));
                    av_push(list, newRV_noinc((SV *)o));
                }
            }
            hv_stores(v, "list", newRV_noinc((SV *)list));
        }

        {
            AV *panels = newAV();
            SV **pv = hv_fetchs(dh, "panels", 0);
            if (pv && SvROK(*pv) && SvTYPE(SvRV(*pv)) == SVt_PVAV) {
                AV *pa = (AV *)SvRV(*pv);
                SSize_t i, n = av_len(pa) + 1;
                po_sortpair *ord;

                /* Panel ORDER is a number and layout is a column count, and
                 * the absence of a drag grid is the deliberate subtraction it
                 * looks like. */
                Newx(ord, n ? n : 1, po_sortpair);
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(pa, i, 0);
                    /* `position`, which is the SQL column name. The
                     * renderer read `order`, check_panel read `position` and
                     * `cols`, and the schema had `position` and `span`:
                     * three names for two things, inert only while nothing
                     * wrote a row. Settled on the names with a schema behind
                     * them. */
                    SV **o = (e && SvROK(*e))
                           ? hv_fetchs((HV *)SvRV(*e), "position", 0) : NULL;
                    /* Descending sort, so the key is negated to get
                     * ascending order out of it. */
                    ord[i].key = (po_u64)(1000000 - ((o && SvOK(*o)) ? SvIV(*o) : 0));
                    ord[i].sv  = e ? *e : &PL_sv_undef;
                }
                if (n > 1) qsort(ord, (size_t)n, sizeof(po_sortpair),
                                 po_sortpair_desc);

                for (i = 0; i < n; i++) {
                    HV *p, *panel;
                    SV **x;

                    if (!SvROK(ord[i].sv)) continue;
                    p = (HV *)SvRV(ord[i].sv);
                    panel = povw_panel_meta(aTHX_ p, i);

                    /* THE BODY IS BUILT ONLY WHEN ASKED FOR. The shell
                     * ships metadata and a deferred placeholder per panel;
                     * ?full=1 sets `panels_inline` and pays for the queries
                     * with the page; the editor never sets it - it renders
                     * forms, and used to run every panel's query for
                     * nothing. */
                    if (rq && (x = hv_fetchs(rq, "panels_inline", 0))
                        && SvTRUE(*x))
                        povw_panel_fill(aTHX_ panel, ord[i].sv, store,
                                        from, to);

                    av_push(panels, newRV_noinc((SV *)panel));
                }
                Safefree(ord);
            }
            hv_stores(v, "panels", newRV_noinc((SV *)panels));
        }
        SvREFCNT_dec(d);

    done:
        if (from) SvREFCNT_dec(from);
        if (to)   SvREFCNT_dec(to);
        RETVAL = newRV_noinc((SV *)v);
    }
    OUTPUT:
        RETVAL

# One dashboard panel, body and all, for the deferred-fragment route.
#
# Resolves the dashboard through the SAME reader seam as the page, sorts
# the panels the same way (the index fallback key depends on it), finds the
# one the key names, and builds meta + body. Returns undef when the
# dashboard or the panel is not there - a deleted panel is a 404, not a
# broken page.
SV *
povw__panel(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *rq = NULL;
        HV *scratch = newHV();
        SV *from = NULL, *to = NULL;
        SV **f;
        SV *src = NULL, *d = NULL;
        HV *dh = NULL;
        HV *out = NULL;
        const char *slug = "";
        STRLEN sl = 0;
        const char *key = "";
        STRLEN kl = 0;

        PERL_UNUSED_VAR(class);
        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV)
            rq = (HV *)SvRV(req);
        if (rq && (f = hv_fetchs(rq, "slug", 0)) && SvOK(*f))
            slug = SvPV(*f, sl);
        if (rq && (f = hv_fetchs(rq, "panel", 0)) && SvOK(*f))
            key = SvPV(*f, kl);
        povw_window_vars(aTHX_ scratch, req, &from, &to);

        if (rq) src = (f = hv_fetchs(rq, "dashboards", 0)) && SvOK(*f)
                      ? *f : NULL;
        if (src && SvROK(src) && SvTYPE(SvRV(src)) == SVt_PVCV) {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpvn(slug, sl)));
            XPUSHs(req);
            PUTBACK;
            n = call_sv(src, G_SCALAR | G_EVAL);
            SPAGAIN;
            d = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
            if (SvTRUE(ERRSV)) { if (d) SvREFCNT_dec(d); d = NULL; }
        }
        else if (src) d = SvREFCNT_inc(src);

        if (d && SvROK(d) && SvTYPE(SvRV(d)) == SVt_PVHV)
            dh = (HV *)SvRV(d);

        if (dh && kl) {
            SV **pv = hv_fetchs(dh, "panels", 0);
            if (pv && SvROK(*pv) && SvTYPE(SvRV(*pv)) == SVt_PVAV) {
                AV *pa = (AV *)SvRV(*pv);
                SSize_t i, n = av_len(pa) + 1;
                po_sortpair *ord;

                /* The page's own ordering, exactly: an index key handed
                 * out by the shell must land on the same panel here. */
                Newx(ord, n ? n : 1, po_sortpair);
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(pa, i, 0);
                    SV **o = (e && SvROK(*e))
                           ? hv_fetchs((HV *)SvRV(*e), "position", 0) : NULL;
                    ord[i].key = (po_u64)(1000000
                                          - ((o && SvOK(*o)) ? SvIV(*o) : 0));
                    ord[i].sv  = e ? *e : &PL_sv_undef;
                }
                if (n > 1) qsort(ord, (size_t)n, sizeof(po_sortpair),
                                 po_sortpair_desc);

                for (i = 0; i < n && !out; i++) {
                    HV *p, *panel;
                    SV **kv;
                    STRLEN pkl;
                    const char *pk;
                    if (!SvROK(ord[i].sv)) continue;
                    p = (HV *)SvRV(ord[i].sv);
                    panel = povw_panel_meta(aTHX_ p, i);
                    kv = hv_fetchs(panel, "key", 0);
                    pk = (kv && SvOK(*kv)) ? SvPV(*kv, pkl) : "";
                    if (pkl == (STRLEN)kl && memcmp(pk, key, kl) == 0) {
                        povw_panel_fill(aTHX_ panel, ord[i].sv, store,
                                        from, to);
                        out = panel;
                    }
                    else SvREFCNT_dec((SV *)panel);
                }
                Safefree(ord);
            }
        }

        if (d) SvREFCNT_dec(d);
        SvREFCNT_dec((SV *)scratch);
        if (from) SvREFCNT_dec(from);
        if (to)   SvREFCNT_dec(to);
        RETVAL = out ? newRV_noinc((SV *)out) : newSV(0);
    }
    OUTPUT:
        RETVAL

# A trace identifier as the 32 hex characters everybody else spells it with.
#
# THE ID IN THE URL AND THE ID ON THE SCREEN MUST BE THE SAME ID. The list
# showed eight hex characters derived from the high half by a modulo, and
# linked to `<hi>-<lo>` in decimal - so the thing you read was not a prefix of
# the thing you clicked, was not what a `traceparent` header would show, and
# could not be pasted anywhere. Two spellings of one identifier, neither of
# them canonical.
SV *
povw_trace_hex(SV *hi_sv, SV *lo_sv)
    CODE:
        RETVAL = povw_trace_hex_sv(aTHX_ hi_sv, lo_sv);
    OUTPUT:
        RETVAL

SV *
povw__page_alerts(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *v = newHV();
        HV *rq = NULL;
        SV **f;
        SV *src = NULL, *r = NULL;
        HV *rh = NULL;
        const char *filter = NULL;
        STRLEN flen = 0;
        AV *rules = newAV();
        IV broken = 0;

        PERL_UNUSED_VAR(class);
        PERL_UNUSED_VAR(store);
        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV) rq = (HV *)SvRV(req);

        hv_stores(v, "heading",    newSVpvs("Alerts"));
        hv_stores(v, "title",      newSVpvs("Alerts"));
        hv_stores(v, "silences",   newRV_noinc((SV *)newAV()));
        hv_stores(v, "broken",     newSViv(0));
        hv_stores(v, "can_edit",   newSViv(0));
        hv_stores(v, "configured", newSViv(0));
        if (rq && (f = hv_fetchs(rq, "q", 0)) && SvOK(*f)) {
            hv_stores(v, "query", newSVsv(*f));
            filter = SvPV(*f, flen);
        }
        else hv_stores(v, "query", newSVpvs(""));

        if (rq) { f = hv_fetchs(rq, "alerts", 0); src = (f && SvTRUE(*f)) ? *f : NULL; }
        if (!src) {
            hv_stores(v, "rules", newRV_noinc((SV *)rules));
            hv_stores(v, "empty", newSViv(1));
            goto done;
        }
        hv_stores(v, "configured", newSViv(1));

        if (SvROK(src) && SvTYPE(SvRV(src)) == SVt_PVCV) {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(req);
            PUTBACK;
            n = call_sv(src, G_SCALAR | G_EVAL);
            SPAGAIN;
            r = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
            if (povw_seam_died(aTHX_ v, "alert rule")) {
                if (r) SvREFCNT_dec(r);
                r = NULL;
            }
        }
        else r = SvREFCNT_inc(src);

        if (!r || !SvROK(r) || SvTYPE(SvRV(r)) != SVt_PVHV) {
            if (r) SvREFCNT_dec(r);
            hv_stores(v, "rules", newRV_noinc((SV *)rules));
            goto done;
        }
        rh = (HV *)SvRV(r);

        f = hv_fetchs(rh, "can_edit", 0);
        hv_stores(v, "can_edit", newSViv(f && SvTRUE(*f) ? 1 : 0));

        /* HOW LONG, AND HOW OFTEN - which a table of current state cannot
         * say. A row reading `firing` answers neither "since when" nor "for
         * the third time today", and a rule that flaps every twenty minutes
         * looks identical in that table to one that broke once.
         *
         * Drawn only where the seam supplied the transitions. They are the
         * evaluator's own record - alert_events in the shipped schema - and a
         * timeline inferred from current state alone would be a straight line
         * claiming the present has always been the case. */
        povw_add_figure_sv(aTHX_ v, "Punk::Observe::Plot::timeline_figure",
                           r, "timeline_plot");

        {
            SV **rv = hv_fetchs(rh, "rules", 0);
            po_sortpair *ord = NULL;
            SSize_t nkeep = 0;

            if (rv && SvROK(*rv) && SvTYPE(SvRV(*rv)) == SVt_PVAV) {
                AV *ra = (AV *)SvRV(*rv);
                SSize_t i, n = av_len(ra) + 1;
                Newx(ord, n ? n : 1, po_sortpair);

                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(ra, i, 0);
                    HV *rule, *o;
                    SV **x;
                    const char *state = "ok";
                    STRLEN slen = 2;
                    int rank;

                    if (!e || !SvROK(*e)) continue;
                    rule = (HV *)SvRV(*e);

                    /* A case-insensitive substring on the NAME, which is what
                     * somebody types into the filter box. */
                    if (filter && flen) {
                        SV **nm = hv_fetchs(rule, "name", 0);
                        STRLEN nl = 0;
                        const char *np = (nm && SvOK(*nm)) ? SvPV(*nm, nl) : "";
                        if (!po_memfind(np, (size_t)nl, filter, (size_t)flen))
                            continue;
                    }

                    x = hv_fetchs(rule, "state", 0);
                    if (x && SvOK(*x) && SvCUR(*x)) state = SvPV(*x, slen);
                    if (slen == 5 && memcmp(state, "error", 5) == 0) broken++;

                    o = newHV();
                    x = hv_fetchs(rule, "id", 0);
                    hv_stores(o, "id", x ? newSVsv(*x) : newSV(0));
                    x = hv_fetchs(rule, "name", 0);
                    hv_stores(o, "name", x ? newSVsv(*x) : newSV(0));
                    hv_stores(o, "state", newSVpvn(state, slen));
                    x = hv_fetchs(rule, "series", 0);
                    hv_stores(o, "series", x ? newSVsv(*x) : newSV(0));

                    /* WHY, for a rule that could not be evaluated. Counting
                     * the broken rules without carrying the reason is how
                     * the screen ended up saying "1 rule(s) could not be
                     * evaluated" and nothing else. Carried whatever the
                     * state: a reason on a non-error row is the reader's
                     * bug to expose, not this table's to hide. */
                    x = hv_fetchs(rule, "reason", 0);
                    hv_stores(o, "reason", (x && SvOK(*x) && SvCUR(*x))
                              ? newSVsv(*x) : newSVpvs(""));

                    x = hv_fetchs(rule, "held", 0);
                    if (x && SvTRUE(*x)) {
                        po_u64 h = 0;
                        char b[32];
                        size_t bn;
                        (void)po_sv_to_u64(aTHX_ *x, &h);
                        bn = po_fmt_dur(h, b);
                        hv_stores(o, "held", newSVpvn(b, bn));
                    }
                    else hv_stores(o, "held", newSVpvs(""));

                    x = hv_fetchs(rule, "value", 0);
                    hv_stores(o, "value", (x && SvOK(*x))
                              ? povw_fmt_value(aTHX_ (double)SvNV(*x))
                              : newSVpvs(""));

                    x = hv_fetchs(rule, "silenced", 0);
                    hv_stores(o, "silenced", newSViv(x && SvTRUE(*x) ? 1 : 0));

                    x = hv_fetchs(rule, "query", 0);
                    {
                        STRLEN ql = 0;
                        const char *qp = (x && SvOK(*x)) ? SvPV(*x, ql) : "";
                        char *esc;
                        size_t en;
                        Newx(esc, ql * 3 + 1, char);
                        en = po_url_esc(qp, (size_t)ql, esc, ql * 3 + 1);
                        hv_stores(o, "query_esc", newSVpvn(esc, en));
                        Safefree(esc);
                    }

                    /* An ERROR rule is one that could not be EVALUATED, which
                     * is not a rule that is fine. It gets the error class,
                     * never the ok one, however it sorts. */
                    hv_stores(o, "row_class",
                              ((slen == 6 && memcmp(state, "firing", 6) == 0)
                            || (slen == 5 && memcmp(state, "error", 5) == 0))
                              ? newSVpvs("row-error") : newSVpvs(""));

                    /* FIRING AND BROKEN FIRST. Sorted by name, a rule that
                     * cannot evaluate sits wherever the alphabet puts it,
                     * which is how it goes unnoticed. */
                    rank = (slen == 5 && memcmp(state, "error", 5) == 0)   ? 0
                         : (slen == 6 && memcmp(state, "firing", 6) == 0)  ? 1
                         : (slen == 7 && memcmp(state, "pending", 7) == 0) ? 2
                         : (slen == 2 && memcmp(state, "ok", 2) == 0)      ? 3
                         :                                                   9;
                    ord[nkeep].key = (po_u64)(9 - rank);   /* descending sort */
                    ord[nkeep].sv  = newRV_noinc((SV *)o);
                    nkeep++;
                }
            }

            if (nkeep > 1) {
                /* A stable sort, so the name is the tie-break: qsort is not
                 * stable, and two rules in the same state would otherwise
                 * come out in whichever order the input had. */
                SSize_t i, j;
                for (i = 1; i < nkeep; i++) {
                    po_sortpair k = ord[i];
                    SV **kn = hv_fetchs((HV *)SvRV(k.sv), "name", 0);
                    for (j = i - 1; j >= 0; j--) {
                        SV **jn = hv_fetchs((HV *)SvRV(ord[j].sv), "name", 0);
                        int worse = ord[j].key < k.key;
                        if (!worse && ord[j].key == k.key) {
                            STRLEN al = 0, bl = 0;
                            const char *ap = (jn && SvOK(*jn)) ? SvPV(*jn, al) : "";
                            const char *bp = (kn && SvOK(*kn)) ? SvPV(*kn, bl) : "";
                            size_t m = al < bl ? al : bl;
                            int c = m ? memcmp(ap, bp, m) : 0;
                            if (!c) c = al == bl ? 0 : (al < bl ? -1 : 1);
                            worse = c > 0;
                        }
                        if (!worse) break;
                        ord[j + 1] = ord[j];
                    }
                    ord[j + 1] = k;
                }
            }
            { SSize_t i; for (i = 0; i < nkeep; i++) av_push(rules, ord[i].sv); }
            Safefree(ord);
        }
        hv_stores(v, "rules",  newRV_noinc((SV *)rules));
        hv_stores(v, "broken", newSViv(broken));

        {
            AV *sil = newAV();
            SV **sv = hv_fetchs(rh, "silences", 0);
            if (sv && SvROK(*sv) && SvTYPE(SvRV(*sv)) == SVt_PVAV) {
                AV *sa = (AV *)SvRV(*sv);
                SSize_t i, n = av_len(sa) + 1;
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(sa, i, 0);
                    HV *s, *o;
                    SV **x;
                    if (!e || !SvROK(*e)) continue;
                    s = (HV *)SvRV(*e);
                    o = newHV();
                    /* The id, or the revoke button has nothing to name. */
                    x = hv_fetchs(s, "id", 0);
                    hv_stores(o, "id", x ? newSVsv(*x) : newSV(0));
                    x = hv_fetchs(s, "pattern", 0);
                    hv_stores(o, "pattern", x ? newSVsv(*x) : newSV(0));
                    x = hv_fetchs(s, "until", 0);
                    if (x && SvTRUE(*x)) {
                        STRLEN ul;
                        const char *up = SvPV(*x, ul);
                        char b[48];
                        size_t bn = po_fmt_date(up, (size_t)ul, b);
                        hv_stores(o, "until", newSVpvn(b, bn));
                    }
                    else hv_stores(o, "until", newSVpvs(""));
                    x = hv_fetchs(s, "by", 0);
                    hv_stores(o, "by", x ? newSVsv(*x) : newSV(0));
                    x = hv_fetchs(s, "reason", 0);
                    hv_stores(o, "reason", x ? newSVsv(*x) : newSV(0));
                    av_push(sil, newRV_noinc((SV *)o));
                }
            }
            hv_stores(v, "empty",
                      newSViv((av_len(rules) < 0 && av_len(sil) < 0) ? 1 : 0));
            hv_stores(v, "silences", newRV_noinc((SV *)sil));
        }
        SvREFCNT_dec(r);

    done:
        RETVAL = newRV_noinc((SV *)v);
    }
    OUTPUT:
        RETVAL

SV *
povw__page_record(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *v = newHV();
        HV *rq = NULL;
        SV **f;
        SV *id = NULL;
        HV *row = NULL;
        SV *rowref = NULL;

        PERL_UNUSED_VAR(class);
        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV) rq = (HV *)SvRV(req);

        hv_stores(v, "heading", newSVpvs("Log line"));
        hv_stores(v, "title",   newSVpvs("Log line"));
        hv_stores(v, "found",   newSViv(0));
        hv_stores(v, "attrs",   newRV_noinc((SV *)newAV()));
        hv_stores(v, "record",  newRV_noinc((SV *)newHV()));

        if (rq && (f = hv_fetchs(rq, "id", 0)) && SvOK(*f)) id = *f;
        if (!id || !SvOK(store) || !SvROK(store)) goto done;

        {
            /* The second the record CLAIMS, not the window: a link pasted into
             * a chat a week later still resolves. */
            STRLEN il = 0;
            const char *ip = SvPV(id, il);
            const char *dot = (const char *)memchr(ip, '.', (size_t)il);
            STRLEN tl = dot ? (STRLEN)(dot - ip) : il;
            SV *t = newSVpvn(ip, tl);
            AV *rows = NULL;
            SV *rowsref = NULL;
            int n;

            /* Read in the ROW shape, which is the shape the identifier was
             * derived from: `service` is lifted out of the attributes there,
             * and a record hashed with the attribute still in place hashes to
             * something else. */
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(newSVpvs("from"))); XPUSHs(sv_2mortal(newSVsv(t)));
            XPUSHs(sv_2mortal(newSVpvs("to")));   XPUSHs(sv_2mortal(newSVsv(t)));
            PUTBACK;
            n = call_method("rows", G_LIST);
            SPAGAIN;
            {
                SSize_t i;
                for (i = n - 1; i > 0; i--) (void)POPs;   /* the meta half */
                rowsref = n ? SvREFCNT_inc(POPs) : NULL;
            }
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
            SvREFCNT_dec(t);

            if (rowsref && SvROK(rowsref) && SvTYPE(SvRV(rowsref)) == SVt_PVAV)
                rows = (AV *)SvRV(rowsref);
            if (rows) {
                SSize_t i, cnt = av_len(rows) + 1;
                for (i = 0; i < cnt; i++) {
                    SV **e = av_fetch(rows, i, 0);
                    if (e && povw_record_matches_c(aTHX_ *e, id)) {
                        rowref = SvREFCNT_inc(*e);
                        row = (HV *)SvRV(*e);
                        break;
                    }
                }
            }
            if (rowsref) SvREFCNT_dec(rowsref);
        }
        if (!row) goto done;

        {
            HV *rec = newHV();
            SV **x;
            const char *sev;
            const char *tp = "0";
            STRLEN tlen = 1;
            char b[64];
            size_t bn;

            x = hv_fetchs(row, "severity", 0);
            sev = po_severity_name(x && SvOK(*x) ? (int)SvIV(*x) : 0);

            x = hv_fetchs(row, "t", 0);
            if (x && SvOK(*x)) tp = SvPV(*x, tlen);
            bn = po_fmt_time(tp, (size_t)tlen, b);
            hv_stores(rec, "time", newSVpvn(b, bn));
            bn = po_fmt_date(tp, (size_t)tlen, b);
            hv_stores(rec, "date", newSVpvn(b, bn));
            hv_stores(rec, "t", x ? newSVsv(*x) : newSV(0));
            hv_stores(rec, "sev_name", newSVpv(sev, 0));

            x = hv_fetchs(row, "service", 0);
            hv_stores(rec, "service", x ? newSVsv(*x) : newSV(0));
            x = hv_fetchs(row, "body", 0);
            hv_stores(rec, "body", x ? newSVsv(*x) : newSV(0));
            x = hv_fetchs(row, "kind", 0);
            hv_stores(rec, "kind", x ? newSVsv(*x) : newSV(0));

            x = hv_fetchs(row, "duration", 0);
            if (x && SvTRUE(*x)) {
                po_u64 d = 0;
                (void)po_sv_to_u64(aTHX_ *x, &d);
                bn = po_fmt_dur(d, b);
                hv_stores(rec, "duration", newSVpvn(b, bn));
            }
            else hv_stores(rec, "duration", newSVpvs(""));

            {
                SV **hi = hv_fetchs(row, "trace_hi", 0);
                SV **lo = hv_fetchs(row, "trace_lo", 0);
                if ((hi && SvTRUE(*hi)) || (lo && SvTRUE(*lo)))
                    hv_stores(rec, "trace",
                              povw_trace_hex_sv(aTHX_ hi ? *hi : &PL_sv_no,
                                                      lo ? *lo : &PL_sv_no));
                else hv_stores(rec, "trace", newSVpvs(""));
            }

            x = hv_fetchs(row, "span_id", 0);
            hv_stores(rec, "span_id", (x && SvTRUE(*x)) ? newSVsv(*x)
                                                        : newSVpvs(""));

            hv_stores(v, "found", newSViv(1));
            hv_stores(v, "record", newRV_noinc((SV *)rec));

            {
                SV *head = newSVpv(sev, 0);
                SV **svc = hv_fetchs(row, "service", 0);
                sv_catpvs(head, " - ");
                if (svc && SvOK(*svc)) sv_catsv(head, *svc);
                hv_stores(v, "heading", head);
            }
        }

        {   /* the attributes, in a stable order */
            AV *out = newAV();
            SV **av = hv_fetchs(row, "attrs", 0);
            if (av && SvROK(*av) && SvTYPE(SvRV(*av)) == SVt_PVHV) {
                HV *ah = (HV *)SvRV(*av);
                SSize_t nk = 0, i;
                po_sortpair *ks = NULL;
                HE *he;
                hv_iterinit(ah);
                Newx(ks, HvUSEDKEYS(ah) ? HvUSEDKEYS(ah) : 1, po_sortpair);
                while ((he = hv_iternext(ah))) {
                    ks[nk].key = 0;
                    ks[nk].sv  = newSVsv(hv_iterkeysv(he));
                    nk++;
                }
                /* insertion sort on the key text: the attribute count on one
                 * record is small, and this keeps the comparison honest about
                 * being a byte compare */
                for (i = 1; i < nk; i++) {
                    po_sortpair k = ks[i];
                    SSize_t j;
                    STRLEN kl;
                    const char *kp = SvPV(k.sv, kl);
                    for (j = i - 1; j >= 0; j--) {
                        STRLEN jl;
                        const char *jp = SvPV(ks[j].sv, jl);
                        size_t m = jl < kl ? jl : kl;
                        int c = m ? memcmp(jp, kp, m) : 0;
                        if (!c) c = jl == kl ? 0 : (jl < kl ? -1 : 1);
                        if (c <= 0) break;
                        ks[j + 1] = ks[j];
                    }
                    ks[j + 1] = k;
                }
                for (i = 0; i < nk; i++) {
                    HV *pair = newHV();
                    STRLEN kl;
                    const char *kp = SvPV(ks[i].sv, kl);
                    SV **val = hv_fetch(ah, kp, (I32)kl, 0);
                    hv_stores(pair, "key", ks[i].sv);
                    /* stringified, as the page prints it */
                    hv_stores(pair, "value",
                              val ? newSVpv(SvPV_nolen(*val), 0) : newSVpvs(""));
                    av_push(out, newRV_noinc((SV *)pair));
                }
                Safefree(ks);
            }
            hv_stores(v, "attrs", newRV_noinc((SV *)out));
        }

        {   /* The lines either side, which is the question anybody opening one
             * line asks next.
             *
             * CENTRED ON THE RECORD, NOT ON THE WINDOW'S EDGE. `rows` answers
             * newest first and `limit` keeps that end, so the capped call this
             * used to make kept the newest 40 of the ten seconds: on a busy
             * store that is everything AFTER the record and nothing before
             * it, with the record itself pushed off its own context. The scan
             * materialises the whole window before any limit trims it, so
             * asking for it all costs the same and the centring is a slice
             * here. */
            AV *ctx = newAV();
            SV **tsv = hv_fetchs(row, "t", 0);
            po_u64 t = 0;
            SV *near = NULL;
            int n;

            if (tsv) (void)po_sv_to_u64(aTHX_ *tsv, &t);
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(newSVpvs("from")));
            XPUSHs(sv_2mortal(po_u64_to_sv(po_ns_sub(t, 5000000000ULL))));
            XPUSHs(sv_2mortal(newSVpvs("to")));
            XPUSHs(sv_2mortal(po_u64_to_sv(po_ns_add(t, 5000000000ULL))));
            XPUSHs(sv_2mortal(newSVpvs("kind")));  XPUSHs(sv_2mortal(newSViv(2)));
            PUTBACK;
            n = call_method("rows", G_LIST);
            SPAGAIN;
            {
                SSize_t i;
                for (i = n - 1; i > 0; i--) (void)POPs;
                near = n ? SvREFCNT_inc(POPs) : NULL;
            }
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;

            if (near && SvROK(near) && SvTYPE(SvRV(near)) == SVt_PVAV) {
                AV *na = (AV *)SvRV(near);
                SSize_t i, cnt = av_len(na) + 1;
                SSize_t i0 = cnt, lo, hi;

                /* The record's own place in the descending order: the first
                 * row at or before it. Everything above index i0 is after
                 * the record, everything from it on is at-or-before. */
                for (i = 0; i < cnt; i++) {
                    SV **e = av_fetch(na, i, 0);
                    SV **x;
                    po_u64 rt = 0;
                    if (!e || !SvROK(*e)) continue;
                    x = hv_fetchs((HV *)SvRV(*e), "t", 0);
                    if (x && SvOK(*x)) (void)po_sv_to_u64(aTHX_ *x, &rt);
                    if (rt <= t) { i0 = i; break; }
                }
                /* Twenty either side, a contiguous slice of the sorted
                 * window - so the page shows before, the line itself, and
                 * after, whatever the traffic rate. */
                lo = i0 > 20 ? i0 - 20 : 0;
                hi = i0 + 21 < cnt ? i0 + 21 : cnt;

                for (i = lo; i < hi; i++) {
                    SV **e = av_fetch(na, i, 0);
                    HV *w, *o;
                    SV **x;
                    char b[64];
                    size_t bn;
                    const char *wp = "0";
                    STRLEN wl = 1;

                    if (!e || !SvROK(*e)) continue;
                    w = (HV *)SvRV(*e);
                    o = newHV();
                    x = hv_fetchs(w, "t", 0);
                    if (x && SvOK(*x)) wp = SvPV(*x, wl);
                    bn = po_fmt_time(wp, (size_t)wl, b);
                    hv_stores(o, "time", newSVpvn(b, bn));
                    x = hv_fetchs(w, "severity", 0);
                    hv_stores(o, "sev_name",
                              newSVpv(po_severity_name(x && SvOK(*x)
                                                       ? (int)SvIV(*x) : 0), 0));
                    x = hv_fetchs(w, "service", 0);
                    hv_stores(o, "service", x ? newSVsv(*x) : newSV(0));
                    x = hv_fetchs(w, "body", 0);
                    hv_stores(o, "body", x ? newSVsv(*x) : newSV(0));
                    hv_stores(o, "id", povw_record_id_sv(aTHX_ *e));
                    /* THE WHOLE ID, not the nanosecond: two lines in the
                     * same ns both carried the highlight, and a context
                     * with two "current" rows reads as a rendering fault. */
                    hv_stores(o, "current",
                              newSViv(povw_record_matches_c(aTHX_ *e, id)
                                      ? 1 : 0));
                    av_push(ctx, newRV_noinc((SV *)o));
                }
            }
            if (near) SvREFCNT_dec(near);
            hv_stores(v, "context", newRV_noinc((SV *)ctx));
        }

    done:
        if (rowref) SvREFCNT_dec(rowref);
        RETVAL = newRV_noinc((SV *)v);
    }
    OUTPUT:
        RETVAL

# The SVG lines for a row set, and the y axis they share.
#
# THE EXTENTS ARE THE BOX, because the axis is already chosen: letting each
# series rescale would draw every one of them to its own top and bottom, and
# the legend would be comparing different axes.
SV *
povw__series_paths(SV *rows_sv, SV *from, SV *to, SV *vars)
    CODE:
    {
        AV *out = newAV();
        povw_series *g = NULL;
        SSize_t ng = 0, i;
        double lo = 0, hi = 0;
        int seen = 0;
        po_axis ax;
        double alo, ahi;
        HV *v = NULL;

        if (SvROK(vars) && SvTYPE(SvRV(vars)) == SVt_PVHV) v = (HV *)SvRV(vars);
        if (SvROK(rows_sv) && SvTYPE(SvRV(rows_sv)) == SVt_PVAV)
            ng = povw_series_split(aTHX_ (AV *)SvRV(rows_sv), &g);
        if (!ng) { if (g) povw_series_free(aTHX_ g, ng); goto done; }

        for (i = 0; i < ng; i++) {
            SSize_t j, cnt = av_len(g[i].pts) + 1;
            for (j = 0; j < cnt; j++) {
                SV **e = av_fetch(g[i].pts, j, 0);
                SV **val = e ? hv_fetchs((HV *)SvRV(*e), "value", 0) : NULL;
                double d = val ? (double)SvNV(*val) : 0;
                if (!seen) { lo = hi = d; seen = 1; }
                else { if (d < lo) lo = d; if (d > hi) hi = d; }
            }
        }
        if (!seen || hi == lo) hi = lo + 1;

        po_axis_make(&ax, lo, hi, 4);
        alo = ax.lo; ahi = ax.hi;
        if (ahi == alo) ahi = alo + 1;

        if (v) {
            AV *ticks = newAV();
            int k;
            for (k = 0; k < ax.n; k++) {
                HV *t = newHV();
                double y = POVW_CHART_H
                         - POVW_CHART_H * (ax.tick[k] - alo) / (ahi - alo);
                hv_stores(t, "y",       povw_fixed(aTHX_ y, 1));
                hv_stores(t, "label_y", povw_fixed(aTHX_ y - 3, 1));
                hv_stores(t, "label",   newSVnv((NV)ax.tick[k]));
                av_push(ticks, newRV_noinc((SV *)t));
            }
            (void)hv_stores(v, "yticks", newRV_noinc((SV *)ticks));
        }

        {
            po_u64 t0 = 0, t1 = 0;
            (void)po_sv_to_u64(aTHX_ from, &t0);
            (void)po_sv_to_u64(aTHX_ to, &t1);

            for (i = 0; i < ng; i++) {
                SSize_t j, cnt = av_len(g[i].pts) + 1;
                HV *s = newHV();
                AV *ex = newAV();
                double *xs, *ys;
                char cls[16];

                Newx(xs, cnt ? cnt : 1, double);
                Newx(ys, cnt ? cnt : 1, double);
                for (j = 0; j < cnt; j++) {
                    SV **e = av_fetch(g[i].pts, j, 0);
                    HV *row = (HV *)SvRV(*e);
                    SV **val = hv_fetchs(row, "value", 0);
                    SV **tsv = hv_fetchs(row, "t", 0);
                    po_u64 t = 0;
                    double d = val ? (double)SvNV(*val) : 0;

                    if (tsv) (void)po_sv_to_u64(aTHX_ *tsv, &t);
                    /* The projection is integer subtraction then one
                     * division, in C. */
                    xs[j] = po_chart_x(t, t0, t1, POVW_CHART_W);
                    ys[j] = POVW_CHART_H
                          - POVW_CHART_H * (d - alo) / (ahi - alo);

                    if (povw_row_has_trace(aTHX_ *e)) {
                        HV *x = newHV();
                        SV **thi = hv_fetchs(row, "trace_hi", 0);
                        SV **tlo = hv_fetchs(row, "trace_lo", 0);
                        hv_stores(x, "trace",
                                  povw_trace_hex_sv(aTHX_
                                      thi ? *thi : &PL_sv_no,
                                      tlo ? *tlo : &PL_sv_no));
                        hv_stores(x, "x", povw_fixed(aTHX_ xs[j], 1));
                        hv_stores(x, "y",
                                  povw_fixed(aTHX_
                                      po_chart_y(d, alo, ahi, POVW_CHART_H), 1));
                        av_push(ex, newRV_noinc((SV *)x));
                    }
                }

                hv_stores(s, "name", newSVsv(g[i].name));
                {
                    size_t cn = (size_t)my_snprintf(cls, sizeof(cls),
                                                    "series-%d", (int)(i % 8));
                    hv_stores(s, "class", newSVpvn(cls, cn));
                }
                hv_stores(s, "path", povw_path_sv(aTHX_ xs, ys, (size_t)cnt));
                hv_stores(s, "points", newSViv((IV)cnt));
                hv_stores(s, "exemplars", newRV_noinc((SV *)ex));
                av_push(out, newRV_noinc((SV *)s));
                Safefree(xs); Safefree(ys);
            }
        }
        povw_series_free(aTHX_ g, ng);

    done:
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# The same rows as a plotly figure, for the screens that draw client side.
#
# COLOUR IS NAMED BY ROLE, never by value: "series:2" is resolved against the
# stylesheet's custom properties in the browser, at draw time. A figure
# carrying a hex would be a figure that is wrong in one of the two themes, and
# the server has no idea which theme the reader is in.
SV *
povw__rows_as_series(SV *rows_sv, SV *req)
    CODE:
    {
        HV *v = newHV();
        AV *legend = newAV();
        AV *data = newAV();
        povw_series *g = NULL;
        SSize_t ng = 0, i;

        PERL_UNUSED_VAR(req);
        if (SvROK(rows_sv) && SvTYPE(SvRV(rows_sv)) == SVt_PVAV)
            ng = povw_series_split(aTHX_ (AV *)SvRV(rows_sv), &g);

        if (!ng) {
            if (g) povw_series_free(aTHX_ g, ng);
            SvREFCNT_dec((SV *)data);
            hv_stores(v, "legend", newRV_noinc((SV *)legend));
            goto done;
        }

        for (i = 0; i < ng; i++) {
            SSize_t j, cnt = av_len(g[i].pts) + 1, nex = 0;
            HV *line = newHV(), *lstyle = newHV(), *leg = newHV();
            AV *lx = newAV(), *ly = newAV();
            AV *ex_x = newAV(), *ex_y = newAV(), *ex_c = newAV();
            char role[16];
            size_t rn = (size_t)my_snprintf(role, sizeof(role),
                                            "series:%d", (int)(i % 8));
            /* THE LINE IS DECIMATED; THE EXEMPLARS ARE NOT.
             *
             * There are a handful of exemplars and each one is a link to a
             * trace, so dropping one removes a way into the data. There are
             * six figures of line points and the chart is 720 pixels wide. */
            SSize_t *keep = NULL, nkeep = 0, kc = 0;

            if (cnt > POVW_PLOT_MAX) {
                Newx(keep, POVW_PLOT_MAX + 2, SSize_t);
                nkeep = povw_decimate(aTHX_ g[i].pts, cnt, keep);
            }

            for (j = 0; j < cnt; j++) {
                SV **e = av_fetch(g[i].pts, j, 0);
                HV *row = (HV *)SvRV(*e);
                SV **val = hv_fetchs(row, "value", 0);
                SV **tsv = hv_fetchs(row, "t", 0);
                int take = 1;

                if (keep) {
                    take = (kc < nkeep && keep[kc] == j);
                    if (take) kc++;
                }
                if (take) {
                    av_push(lx, povw_plot_ms(aTHX_ tsv ? *tsv : NULL));
                    av_push(ly, povw_num(aTHX_ val ? *val : NULL));
                }

                if (povw_row_has_trace(aTHX_ *e)) {
                    SV **thi = hv_fetchs(row, "trace_hi", 0);
                    SV **tlo = hv_fetchs(row, "trace_lo", 0);
                    SV *cd = newSVpvs("");
                    if (thi && SvOK(*thi)) sv_catsv(cd, *thi);
                    sv_catpvs(cd, "-");
                    if (tlo && SvOK(*tlo)) sv_catsv(cd, *tlo);
                    av_push(ex_x, povw_plot_ms(aTHX_ tsv ? *tsv : NULL));
                    av_push(ex_y, povw_num(aTHX_ val ? *val : NULL));
                    av_push(ex_c, cd);
                    nex++;
                }
            }

            if (keep) Safefree(keep);

            hv_stores(lstyle, "color", newSVpvn(role, rn));
            hv_stores(lstyle, "width", newSViv(2));
            hv_stores(line, "type", newSVpvs("scatter"));
            hv_stores(line, "mode", newSVpvs("lines"));
            hv_stores(line, "name", newSVsv(g[i].name));
            hv_stores(line, "x", newRV_noinc((SV *)lx));
            hv_stores(line, "y", newRV_noinc((SV *)ly));
            hv_stores(line, "line", newRV_noinc((SV *)lstyle));
            av_push(data, newRV_noinc((SV *)line));

            if (nex) {
                HV *m = newHV(), *mstyle = newHV(), *mline = newHV();
                SV *nm = newSVsv(g[i].name);
                sv_catpvs(nm, " exemplars");
                hv_stores(mline, "width", newSViv(2));
                hv_stores(mstyle, "color", newSVpvn(role, rn));
                hv_stores(mstyle, "size", newSViv(9));
                hv_stores(mstyle, "symbol", newSVpvs("circle-open"));
                hv_stores(mstyle, "line", newRV_noinc((SV *)mline));
                hv_stores(m, "type", newSVpvs("scatter"));
                hv_stores(m, "mode", newSVpvs("markers"));
                hv_stores(m, "name", nm);
                /* The exemplar markers ride the series' own legend entry;
                 * a second one for them would double the list. */
                hv_stores(m, "showlegend", newRV_noinc(newSViv(0)));
                hv_stores(m, "x", newRV_noinc((SV *)ex_x));
                hv_stores(m, "y", newRV_noinc((SV *)ex_y));
                hv_stores(m, "customdata", newRV_noinc((SV *)ex_c));
                hv_stores(m, "marker", newRV_noinc((SV *)mstyle));
                hv_stores(m, "hovertemplate",
                          newSVpvs("trace %{customdata}<extra></extra>"));
                av_push(data, newRV_noinc((SV *)m));
            }
            else {
                SvREFCNT_dec((SV *)ex_x);
                SvREFCNT_dec((SV *)ex_y);
                SvREFCNT_dec((SV *)ex_c);
            }

            {
                char cls[16];
                size_t cn = (size_t)my_snprintf(cls, sizeof(cls),
                                                "series-%d", (int)(i % 8));
                hv_stores(leg, "name", newSVsv(g[i].name));
                hv_stores(leg, "class", newSVpvn(cls, cn));
                hv_stores(leg, "points", newSViv((IV)cnt));
                hv_stores(leg, "exemplars", newSViv((IV)nex));
            }
            av_push(legend, newRV_noinc((SV *)leg));
        }
        povw_series_free(aTHX_ g, ng);

        {
            HV *fig = newHV(), *layout = newHV(), *xaxis = newHV(), *yaxis = newHV();
            hv_stores(xaxis, "type", newSVpvs("date"));
            hv_stores(yaxis, "rangemode", newSVpvs("tozero"));
            hv_stores(layout, "hovermode", newSVpvs("x unified"));
            hv_stores(layout, "xaxis", newRV_noinc((SV *)xaxis));
            hv_stores(layout, "yaxis", newRV_noinc((SV *)yaxis));
            /* One series needs no legend: the heading already names it, and
             * a legend of one is a box that says the same word twice. */
            hv_stores(layout, "showlegend",
                      newRV_noinc(newSViv(av_len(legend) > 0 ? 1 : 0)));
            hv_stores(fig, "data", newRV_noinc((SV *)data));
            hv_stores(fig, "layout", newRV_noinc((SV *)layout));
            hv_stores(v, "legend", newRV_noinc((SV *)legend));
            hv_stores(v, "figure", newRV_noinc((SV *)fig));
        }

    done:
        RETVAL = newRV_noinc((SV *)v);
    }
    OUTPUT:
        RETVAL

# Frames into rects.
#
# THE X POSITION IS THE ONE THING THE TREE DOES NOT CARRY. Frames arrive in
# tree order with a parent index and a total, so each frame starts where its
# parent's cursor has got to, and the parent's cursor advances by what this
# frame took. Every frame is visited once and the whole layout falls out.
SV *
povw__flame_rows(SV *f_sv, SV *names_sv, SV *services_sv)
    CODE:
    {
        AV *out = newAV();
        AV *frames = NULL, *names = NULL, *services = NULL;
        SSize_t n = 0, i;
        po_u64 root_total = 0, root_cursor = 0;
        po_u64 *start = NULL, *cursor = NULL;
        char *seen = NULL;
        SV **path = NULL;

        if (SvROK(f_sv) && SvTYPE(SvRV(f_sv)) == SVt_PVHV) {
            SV **fr = hv_fetchs((HV *)SvRV(f_sv), "frames", 0);
            if (fr && SvROK(*fr) && SvTYPE(SvRV(*fr)) == SVt_PVAV)
                frames = (AV *)SvRV(*fr);
        }
        if (SvROK(names_sv) && SvTYPE(SvRV(names_sv)) == SVt_PVAV)
            names = (AV *)SvRV(names_sv);
        if (SvROK(services_sv) && SvTYPE(SvRV(services_sv)) == SVt_PVAV)
            services = (AV *)SvRV(services_sv);

        n = frames ? av_len(frames) + 1 : 0;
        if (!n) goto done;
#define POVW_FR(ix)  ((SV **)av_fetch(frames, (ix), 0))
#define POVW_FH(ix)  ((HV *)SvRV(*POVW_FR(ix)))

        {   /* The roots' total is the width of the whole picture. */
            for (i = 0; i < n; i++) {
                SV **e = POVW_FR(i);
                SV **p, **t;
                IV par;
                if (!e || !SvROK(*e)) continue;
                p = hv_fetchs((HV *)SvRV(*e), "parent", 0);
                par = (p && SvOK(*p)) ? SvIV(*p) : -1;
                if (par >= 0) continue;
                t = hv_fetchs((HV *)SvRV(*e), "total", 0);
                root_total += (t && SvOK(*t)) ? (po_u64)SvUV(*t) : 0;
            }
        }
        if (!root_total) goto done;

        Newxz(start,  n, po_u64);
        Newxz(cursor, n, po_u64);
        Newxz(seen,   n, char);      /* has this frame's cursor been set? */
        Newxz(path,   n, SV *);

        for (i = 0; i < n; i++) {
            SV **e = POVW_FR(i);
            HV *fr;
            SV **x;
            IV par;
            po_u64 total, self, count;
            SV *name = NULL;
            const char *np = "(unnamed)";
            STRLEN nlen = 9;
            int name_utf8 = 0;
            double wpct;
            IV budget, depth;
            HV *o;

            if (!e || !SvROK(*e)) { path[i] = newSVpvs(""); continue; }
            fr = (HV *)SvRV(*e);

            x = hv_fetchs(fr, "parent", 0);
            par = (x && SvOK(*x)) ? SvIV(*x) : -1;
            x = hv_fetchs(fr, "total", 0);
            total = (x && SvTRUE(*x)) ? (po_u64)SvUV(*x) : 0;

            if (par < 0) {
                start[i]     = root_cursor;
                root_cursor += total;
                path[i]      = newSViv((IV)i);
            }
            else {
                /* `||`, not a defined check: a cursor sitting at zero has not
                 * moved, so the frame starts where its parent starts. */
                po_u64 s = 0;
                SV *pp = NULL;
                if (par < n) {
                    s = cursor[par] ? cursor[par] : start[par];
                    pp = path[par];
                }
                start[i] = s;
                if (par < n) cursor[par] = start[i] + total;
                path[i] = pp ? newSVsv(pp) : newSVpvs("");
                sv_catpvs(path[i], "/");
                sv_catpvf(path[i], PO_IVf, (IV)i);
            }
            if (!seen[i]) { cursor[i] = start[i]; seen[i] = 1; }

            x = hv_fetchs(fr, "name", 0);
            if (names && x && SvOK(*x)) {
                SV **nm = av_fetch(names, SvIV(*x), 0);
                if (nm && SvOK(*nm) && SvCUR(*nm)) {
                    name = *nm;
                    np = SvPV(name, nlen);
                    name_utf8 = SvUTF8(name) ? 1 : 0;
                }
            }

            wpct = 100.0 * (double)total / (double)root_total;

            /* THE LABEL IS TRUNCATED HERE, not clipped by the browser. An SVG
             * text element neither wraps nor ellipsises; left whole it runs
             * straight across the frames beside it, and a flamegraph with
             * every name overlapping every other name is less readable than
             * one with no names at all. Roughly one character per 0.62% of
             * the width, and nothing at all below the width of an ellipsis. */
            budget = (IV)(wpct / 0.62);

            o = newHV();
            hv_stores(o, "name", name ? newSVsv(name) : newSVpvn(np, nlen));

            if (budget < 4) hv_stores(o, "label", newSVpvs(""));
            else {
                IV clen = name_utf8 ? (IV)sv_len_utf8(name) : (IV)nlen;
                if (clen <= budget)
                    hv_stores(o, "label",
                              name ? newSVsv(name) : newSVpvn(np, nlen));
                else {
                    STRLEN keep;
                    SV *lab;
                    if (name_utf8) {
                        const U8 *s = (const U8 *)np;
                        const U8 *e2 = s + nlen;
                        IV k = budget - 1;
                        while (k-- > 0 && s < e2) s += UTF8SKIP(s);
                        keep = (STRLEN)((const char *)s - np);
                    }
                    else keep = (STRLEN)(budget - 1);
                    lab = newSVpvn(np, keep);
                    if (name_utf8) SvUTF8_on(lab);
                    /* The ellipsis is one CHARACTER, so the result is a
                     * character string whatever the name was. */
                    sv_utf8_upgrade(lab);
                    sv_catpvn_flags(lab, "\342\200\246", 3, SV_CATUTF8);
                    hv_stores(o, "label", lab);
                }
            }

            x = hv_fetchs(fr, "service", 0);
            if (services && x && SvOK(*x)) {
                SV **sv = av_fetch(services, SvIV(*x), 0);
                hv_stores(o, "service",
                          (sv && SvOK(*sv)) ? newSVsv(*sv) : newSVpvs(""));
            }
            else hv_stores(o, "service", newSVpvs(""));

            x = hv_fetchs(fr, "depth", 0);
            depth = (x && SvOK(*x)) ? SvIV(*x) : 0;
            hv_stores(o, "depth", (x && SvOK(*x)) ? newSVsv(*x) : newSV(0));
            hv_stores(o, "y", newSViv(depth * 18));
            /* The baseline sits in the middle of the 16px band. */
            hv_stores(o, "text_y", newSViv(depth * 18 + 8));

            x = hv_fetchs(fr, "self", 0);
            self = (x && SvTRUE(*x)) ? (po_u64)SvUV(*x) : 0;
            x = hv_fetchs(fr, "count", 0);
            count = (x && SvTRUE(*x)) ? (po_u64)SvUV(*x) : 1;

            hv_stores(o, "total", po_u64_to_sv(total));
            hv_stores(o, "self",  po_u64_to_sv(self));
            hv_stores(o, "count", po_u64_to_sv(count));
            hv_stores(o, "start", po_u64_to_sv(start[i]));
            hv_stores(o, "path",  SvREFCNT_inc(path[i]));

            {
                char b[64];
                size_t bn = po_fmt_dur(self, b);
                hv_stores(o, "self_ms", newSVpvn(b, bn));
                bn = po_fmt_dur(total, b);
                hv_stores(o, "total_ms", newSVpvn(b, bn));
            }

            hv_stores(o, "x", povw_fixed(aTHX_
                          100.0 * (double)start[i] / (double)root_total, 4));
            /* A frame narrower than this is invisible; drawn at its real
             * width it is a rect nobody can click. */
            hv_stores(o, "width", povw_fixed(aTHX_
                          wpct > 0.05 ? wpct : 0.05, 4));
            av_push(out, newRV_noinc((SV *)o));
        }

        for (i = 0; i < n; i++) if (path[i]) SvREFCNT_dec(path[i]);
        Safefree(start); Safefree(cursor); Safefree(seen); Safefree(path);
#undef POVW_FR
#undef POVW_FH

    done:
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# One box over every signal.
SV *
povw__page_explore(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *v = newHV();
        HV *rq = NULL;
        SV **f;
        SV *from = NULL, *to = NULL, *res = NULL;
        HV *r = NULL;
        const char *q = "";
        STRLEN ql = 0;
        int has_q = 0;
        SSize_t i;
        /* THESE ARE THE PAGE when there is nothing else on it, so they are
         * the language's shop window rather than a hint under the box.
         *
         * The first five covered `where`, `search`, `slowest`, `by`+`count`
         * and `p95 by`, and demonstrated none of `bucket`, `rate`, `sort`,
         * `limit`, `distinct`, the `{...}` selector, `and`/`or`, `=~` - or
         * the cross-signal pipeline, which is the one thing this backend does
         * that a stack of separate tools cannot, and which the overview calls
         * the differentiator of the whole project.
         *
         * Every one of them is parsed by t/0915-discovery.t, so an example
         * that stopped being valid is a failing build rather than something
         * teaching the wrong thing from the front page. */
        /* EVERY ONE OF THESE ANSWERS ON THE DEMO STORE. The first set was
         * written against an imagined store: it named http.server.duration,
         * which the SDK never emits (the semconv name is
         * http.server.request.duration), asked a histogram metric for | p95,
         * which has no raw points to take a percentile of, and led with the
         * cross-signal pipeline, which is refused until it is executed.
         * An example that returns nothing teaches that the tool is broken. */
        static const char *const EX[] = {
            "log | where severity >= error", "every error in the window",
            "log | bucket(5m) count by severity",
                                             "log volume over time, by severity",
            "log | search \"refused\"",      "a substring, using the block filter",
            "log | where body =~ \"^connect\"",
                                             "an anchored prefix; =~ is not a full regex engine",
            "trace | slowest 20",            "the slowest traces",
            "spans | where duration > 500ms and status == 2 | by service | count",
                                             "failures that were also slow, per service",
            "spans{service = \"shop\"} | bucket(30s) p95 | viz area",
                                             "the selector, p95 of duration, and a chart",
            "spans | by service | count | top 5 by count",
                                             "the busiest five",
            "metric http.server.request.count | rate(1m) by http.route",
                                             "a per-second rate per route",
            "log | sort t desc | limit 100", "the hundred most recent",
            "log | by severity | count | viz bar",
                                             "one bar per group, drawn how you asked",
            "spans | by http.route | distinct",
                                             "how many distinct routes there are"
        };

        PERL_UNUSED_VAR(class);
        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV) rq = (HV *)SvRV(req);

        hv_stores(v, "heading", newSVpvs("Explore"));
        hv_stores(v, "title",   newSVpvs("Explore"));
        hv_stores(v, "rows",    newRV_noinc((SV *)newAV()));
        hv_stores(v, "groups",  newRV_noinc((SV *)newAV()));
        hv_stores(v, "columns", newRV_noinc((SV *)newAV()));

        if (rq && (f = hv_fetchs(rq, "q", 0)) && SvOK(*f)) {
            q = SvPV(*f, ql);
            hv_stores(v, "query", newSVsv(*f));
        }
        else hv_stores(v, "query", newSVpvs(""));
        {
            char *esc;
            size_t en;
            Newx(esc, ql * 3 + 1, char);
            en = po_url_esc(q, (size_t)ql, esc, ql * 3 + 1);
            hv_stores(v, "query_esc", newSVpvn(esc, en));
            Safefree(esc);
        }

        {   /* The examples are the page when there is nothing else on it, so
             * they are not a hint under the box - they are what it shows. */
            AV *ex = newAV();
            size_t k;
            for (k = 0; k < sizeof(EX) / sizeof(EX[0]); k += 2) {
                HV *e = newHV();
                size_t l = strlen(EX[k]);
                char *esc;
                size_t en;
                Newx(esc, l * 3 + 1, char);
                en = po_url_esc(EX[k], l, esc, l * 3 + 1);
                hv_stores(e, "q",    newSVpvn(EX[k], l));
                hv_stores(e, "href", newSVpvn(esc, en));
                hv_stores(e, "why",  newSVpv(EX[k + 1], 0));
                Safefree(esc);
                av_push(ex, newRV_noinc((SV *)e));
            }
            hv_stores(v, "examples", newRV_noinc((SV *)ex));
        }

        povw_window_vars(aTHX_ v, req, &from, &to);

        for (i = 0; i < (SSize_t)ql; i++)
            if (!isSPACE((U8)q[i])) { has_q = 1; break; }
        if (!has_q || !SvOK(store) || !SvROK(store)) {
            SvREFCNT_dec(from); SvREFCNT_dec(to);
            goto done;
        }

        {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(newSVpvn(q, ql)));
            XPUSHs(sv_2mortal(newSVpvs("from"))); XPUSHs(sv_2mortal(newSVsv(from)));
            XPUSHs(sv_2mortal(newSVpvs("to")));   XPUSHs(sv_2mortal(newSVsv(to)));
            PUTBACK;
            n = call_method(povw_read_method(aTHX_ store), G_SCALAR);
            SPAGAIN;
            res = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
        }
        SvREFCNT_dec(from); SvREFCNT_dec(to);

        if (!res || !SvROK(res) || SvTYPE(SvRV(res)) != SVt_PVHV) {
            if (res) SvREFCNT_dec(res);
            goto done;
        }
        r = (HV *)SvRV(res);

        f = hv_fetchs(r, "ok", 0);
        if (!f || !SvTRUE(*f)) {
            SV **e  = hv_fetchs(r, "error", 0);
            SV **of = hv_fetchs(r, "offset", 0);
            SV **st = hv_fetchs(r, "stage", 0);
            int parse = st && SvOK(*st) && strEQ(SvPV_nolen(*st), "parse");
            hv_stores(v, "error", (e && SvOK(*e)) ? newSVsv(*e)
                      : newSVpvs("that query could not be run"));
            hv_stores(v, "offset", of ? newSVsv(*of) : newSV(0));
            /* WHERE it failed is the whole message - and the store's own
             * hint, when it wrote one, is the most specific message there
             * is. The generic lines are the fallback, not the answer. */
            {
                SV **ht = hv_fetchs(r, "hint", 0);
                hv_stores(v, "hint", (ht && SvOK(*ht) && SvCUR(*ht))
                          ? newSVsv(*ht)
                          : parse
                          ? newSVpvs("The parser stopped there.")
                          : newSVpvs("The planner refused it before it ran."));
            }
            SvREFCNT_dec(res);
            goto done;
        }

        {
            SV **sh = hv_fetchs(r, "shape", 0);
            SV **meta = hv_fetchs(r, "meta", 0);
            HV *mh = (meta && SvROK(*meta) && SvTYPE(SvRV(*meta)) == SVt_PVHV)
                       ? (HV *)SvRV(*meta) : NULL;
            int rows_shape = !(sh && SvOK(*sh)) || strEQ(SvPV_nolen(*sh), "rows");
            int buckets_shape = sh && SvOK(*sh)
                             && strEQ(SvPV_nolen(*sh), "buckets");

            hv_stores(v, "shape", sh ? newSVsv(*sh) : newSV(0));

            /* A BUCKETED ANSWER IS A THIRD SHAPE, and this branched on two.
             *
             * `explore` is one box over every signal, so it cannot know what
             * shape an answer will take - and rows-versus-groups was every
             * shape there was until `bucket` added one. A bucketed answer has
             * `series` and no `groups`, so it took the groups branch, found
             * nothing, and drew a heading over an empty panel.
             *
             * The `| viz` handling and the bucketed fill live in
             * povw_apply_viz, SHARED with the logs page - one vocabulary, or
             * a viz that draws here and not in the box it was worked out
             * in. */
            povw_apply_viz(aTHX_ v, r, res, q, (size_t)ql,
                           rows_shape, buckets_shape);
            if (mh) {
                povw_set_count(aTHX_ v, "scanned", mh, "scanned_rows");
                f = hv_fetchs(mh, "truncated", 0);
                hv_stores(v, "truncated", f ? newSVsv(*f) : newSV(0));
                f = hv_fetchs(mh, "exact", 0);
                hv_stores(v, "exact", f ? newSVsv(*f) : newSV(0));
            }
            else {
                hv_stores(v, "scanned",   newSVpvs("0"));
                hv_stores(v, "truncated", newSV(0));
                hv_stores(v, "exact",     newSV(0));
            }

            if (rows_shape) {
                AV *out = newAV();
                SV **rv = hv_fetchs(r, "rows", 0);
                int has_sev = 0, has_dur = 0, has_val = 0, has_tr = 0;

                if (rv && SvROK(*rv) && SvTYPE(SvRV(*rv)) == SVt_PVAV) {
                    AV *ra = (AV *)SvRV(*rv);
                    SSize_t j, cnt = av_len(ra) + 1;
                    for (j = 0; j < cnt; j++) {
                        SV **e = av_fetch(ra, j, 0);
                        HV *row, *o;
                        SV **x;
                        char b[64];
                        size_t bn;
                        const char *tp = "0";
                        STRLEN tl = 1;

                        if (!e || !SvROK(*e)) continue;
                        row = (HV *)SvRV(*e);
                        o = newHV();

                        x = hv_fetchs(row, "t", 0);
                        if (x && SvOK(*x)) tp = SvPV(*x, tl);
                        bn = po_fmt_time(tp, (size_t)tl, b);
                        hv_stores(o, "time", newSVpvn(b, bn));

                        x = hv_fetchs(row, "service", 0);
                        hv_stores(o, "service", (x && SvTRUE(*x)) ? newSVsv(*x)
                                                                  : newSVpvs(""));
                        x = hv_fetchs(row, "body", 0);
                        hv_stores(o, "body", (x && SvOK(*x)) ? newSVsv(*x)
                                                             : newSVpvs(""));

                        x = hv_fetchs(row, "severity", 0);
                        if (x && SvOK(*x)) {
                            const char *s = po_severity_name((int)SvIV(*x));
                            hv_stores(o, "severity", newSVpv(s, 0));
                            if (*s) has_sev = 1;
                        }
                        else hv_stores(o, "severity", newSVpvs(""));

                        x = hv_fetchs(row, "duration", 0);
                        if (x && SvTRUE(*x)) {
                            po_u64 d = 0;
                            (void)po_sv_to_u64(aTHX_ *x, &d);
                            bn = po_fmt_dur(d, b);
                            hv_stores(o, "duration", newSVpvn(b, bn));
                            if (bn) has_dur = 1;
                        }
                        else hv_stores(o, "duration", newSVpvs(""));

                        x = hv_fetchs(row, "value", 0);
                        if (x && SvOK(*x)) {
                            SV *val = povw_fmt_value(aTHX_ (double)SvNV(*x));
                            if (SvCUR(val)) has_val = 1;
                            hv_stores(o, "value", val);
                        }
                        else hv_stores(o, "value", newSVpvs(""));

                        {
                            SV **hi = hv_fetchs(row, "trace_hi", 0);
                            SV **lo = hv_fetchs(row, "trace_lo", 0);
                            if ((hi && SvTRUE(*hi)) || (lo && SvTRUE(*lo))) {
                                hv_stores(o, "trace",
                                          povw_trace_hex_sv(aTHX_
                                              hi ? *hi : &PL_sv_no,
                                              lo ? *lo : &PL_sv_no));
                                has_tr = 1;
                            }
                            else hv_stores(o, "trace", newSVpvs(""));
                        }
                        av_push(out, newRV_noinc((SV *)o));
                    }
                }
                hv_stores(v, "rows", newRV_noinc((SV *)out));

                /* A COLUMN NO ROW FILLS IS NOT SHOWN. `explore` is one box
                 * over every signal, so the widest possible table is what it
                 * would otherwise draw - and a span query then renders a
                 * severity column and a value column that are empty on every
                 * row, for ever. The answer decides its own shape. */
                hv_stores(v, "has_severity", newSViv(has_sev));
                hv_stores(v, "has_duration", newSViv(has_dur));
                hv_stores(v, "has_value",    newSViv(has_val));
                hv_stores(v, "has_trace",    newSViv(has_tr));
            }
            else {
                AV *out = newAV();
                SV **gv = hv_fetchs(r, "groups", 0);
                double max = 0;
                if (gv && SvROK(*gv) && SvTYPE(SvRV(*gv)) == SVt_PVAV) {
                    AV *ga = (AV *)SvRV(*gv);
                    SSize_t j, cnt = av_len(ga) + 1;
                    for (j = 0; j < cnt; j++) {
                        SV **e = av_fetch(ga, j, 0);
                        SV **x = (e && SvROK(*e))
                                   ? hv_fetchs((HV *)SvRV(*e), "value", 0) : NULL;
                        double d = x ? (double)SvNV(*x) : 0;
                        if (d > max) max = d;
                    }
                    for (j = 0; j < cnt; j++) {
                        SV **e = av_fetch(ga, j, 0);
                        HV *gh, *o;
                        SV **x;
                        double d;

                        if (!e || !SvROK(*e)) continue;
                        gh = (HV *)SvRV(*e);
                        o = newHV();
                        x = hv_fetchs(gh, "key", 0);
                        hv_stores(o, "key", (x && SvOK(*x) && SvCUR(*x))
                                  ? newSVsv(*x) : newSVpvs("(none)"));
                        x = hv_fetchs(gh, "value", 0);
                        d = x ? (double)SvNV(*x) : 0;
                        hv_stores(o, "value", povw_fmt_value(aTHX_ d));
                        x = hv_fetchs(gh, "count", 0);
                        {
                            char b[32];
                            STRLEN cl = 0;
                            const char *cp = (x && SvOK(*x)) ? SvPV(*x, cl) : "";
                            size_t bn = po_fmt_count(cp, (size_t)cl, b, sizeof(b));
                            hv_stores(o, "count", newSVpvn(b, bn));
                        }
                        /* Truncated, as int() is: a bar drawn at 99.6% and
                         * labelled 100 is a bar that says it is the largest
                         * when it is not. */
                        hv_stores(o, "width_pct",
                                  newSViv(max ? (IV)(100.0 * d / max) : 0));
                        av_push(out, newRV_noinc((SV *)o));
                    }
                }
                hv_stores(v, "groups", newRV_noinc((SV *)out));
            }
        }
        SvREFCNT_dec(res);

    done:
        RETVAL = newRV_noinc((SV *)v);
    }
    OUTPUT:
        RETVAL

# THE WATERFALL, COMPLETE IN THE MARKUP.
#
# Every bar's offset and width are percentages computed here, so the tree, the
# timings and the nesting are all in the HTML. JavaScript makes it navigable;
# it does not make it exist.
SV *
povw__trace_one(SV *class, SV *store, SV *req, SV *from, SV *to, SV *range)
    CODE:
    {
        HV *v = newHV();
        HV *rq = NULL;
        SV **f;
        po_u64 hi = 0, lo = 0;
        int have_id = 0;
        SV *tsv = NULL;
        HV *t = NULL;
        AV *spans_out = newAV();
        AV *nname = newAV(), *sname = newAV();
        HV *nsym = newHV(), *ssym = newHV();
        AV *specs = newAV();
        po_u64 dur = 1;

        PERL_UNUSED_VAR(class);
        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV) rq = (HV *)SvRV(req);

        hv_stores(v, "heading", newSVpvs("Trace"));
        hv_stores(v, "title",   newSVpvs("Trace"));
        hv_stores(v, "spans",   newRV_noinc((SV *)spans_out));
        hv_stores(v, "from",    newSVsv(from));
        hv_stores(v, "to",      newSVsv(to));
        f = rq ? hv_fetchs(rq, "trace", 0) : NULL;
        hv_stores(v, "trace", f ? newSVsv(*f) : newSV(0));
        povw_range_vars(aTHX_ v, req, range);

        /* WHICHEVER SPELLING ARRIVED. The links carry hex now; a bookmark
         * from before, or a decimal pair somebody built by hand, still
         * resolves. */
        if (f) have_id = povw_trace_id_c(aTHX_ *f, &hi, &lo);
        if (!have_id || !SvOK(store) || !SvROK(store)) goto done;

        {   /* A trace is looked up over a wide window, because the link to
             * one is usually followed later than the window that produced
             * it. */
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(po_u64_to_sv(hi)));
            XPUSHs(sv_2mortal(po_u64_to_sv(lo)));
            XPUSHs(sv_2mortal(newSVpvs("from"))); XPUSHs(sv_2mortal(newSV(0)));
            XPUSHs(sv_2mortal(newSVpvs("to")));   XPUSHs(sv_2mortal(newSV(0)));
            PUTBACK;
            n = call_method("trace", G_SCALAR);
            SPAGAIN;
            tsv = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
        }
        if (!tsv || !SvTRUE(tsv) || !SvROK(tsv)
            || SvTYPE(SvRV(tsv)) != SVt_PVHV) {
            if (tsv) SvREFCNT_dec(tsv);
            hv_stores(v, "heading",   newSVpvs("Trace not found"));
            hv_stores(v, "root_name", newSVpvs("That trace is not in the store"));
            hv_stores(v, "error",
                newSVpvs("No spans with that trace id are in the retention window."));
            hv_stores(v, "hint",
                newSVpvs("It may have aged out, or the id may be truncated."));
            goto done;
        }
        t = (HV *)SvRV(tsv);

        f = hv_fetchs(t, "duration", 0);
        if (f && SvTRUE(*f)) (void)po_sv_to_u64(aTHX_ *f, &dur);
        if (!dur) dur = 1;

        {
            SV **sv = hv_fetchs(t, "spans", 0);
            AV *sa = (sv && SvROK(*sv) && SvTYPE(SvRV(*sv)) == SVt_PVAV)
                       ? (AV *)SvRV(*sv) : NULL;
            SSize_t i, cnt = sa ? av_len(sa) + 1 : 0;
            HV *attrs_of = newHV();

            /* THE ATTRIBUTES ARE NOT IN THE TREE. Assembly works on the
             * 64-byte span the seal indexes - ids, times, two symbols - so
             * a waterfall built from it alone can say SELECT and nothing
             * more. The records of this trace are read once more, filtered
             * in the scan on the trace id, and matched to their rows by
             * span id. `limit` is the span count: the trace has exactly
             * that many, so the read cannot be cut short. */
            if (cnt) {
                SV *rows = NULL;
                int n;
                ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(store);
                XPUSHs(sv_2mortal(newSVpvs("kind")));     XPUSHs(sv_2mortal(newSViv(3)));
                XPUSHs(sv_2mortal(newSVpvs("trace_hi"))); XPUSHs(sv_2mortal(po_u64_to_sv(hi)));
                XPUSHs(sv_2mortal(newSVpvs("trace_lo"))); XPUSHs(sv_2mortal(po_u64_to_sv(lo)));
                XPUSHs(sv_2mortal(newSVpvs("limit")));    XPUSHs(sv_2mortal(newSViv((IV)cnt)));
                PUTBACK;
                n = call_method("rows", G_LIST);
                SPAGAIN;
                {
                    SSize_t k;
                    for (k = n - 1; k > 0; k--) (void)POPs;
                    rows = n ? SvREFCNT_inc(POPs) : NULL;
                }
                PUTBACK;
                FREETMPS; LEAVE;
                SPAGAIN;
                if (rows && SvROK(rows) && SvTYPE(SvRV(rows)) == SVt_PVAV) {
                    AV *ra = (AV *)SvRV(rows);
                    SSize_t k, rn = av_len(ra) + 1;
                    for (k = 0; k < rn; k++) {
                        SV **e = av_fetch(ra, k, 0);
                        SV **id, **at;
                        STRLEN il;
                        const char *ip;
                        if (!e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVHV) continue;
                        id = hv_fetchs((HV *)SvRV(*e), "span_id", 0);
                        at = hv_fetchs((HV *)SvRV(*e), "attrs", 0);
                        if (!id || !SvOK(*id) || !at || !SvROK(*at)) continue;
                        ip = SvPV(*id, il);
                        (void)hv_store(attrs_of, ip, (I32)il, newSVsv(*at), 0);
                    }
                }
                if (rows) SvREFCNT_dec(rows);
            }

            for (i = 0; i < cnt; i++) {
                SV **e = av_fetch(sa, i, 0);
                HV *s, *o, *spec;
                SV **x;
                po_u64 off = 0, w = 0;
                IV depth = 0, status = 0;
                char b[64];
                size_t bn;
                SV *nm, *svc;
                IV nid, sid;

                if (!e || !SvROK(*e)) continue;
                s = (HV *)SvRV(*e);
                o = newHV();

                x = hv_fetchs(s, "offset", 0);
                if (x && SvTRUE(*x)) (void)po_sv_to_u64(aTHX_ *x, &off);
                x = hv_fetchs(s, "duration", 0);
                if (x && SvTRUE(*x)) (void)po_sv_to_u64(aTHX_ *x, &w);
                x = hv_fetchs(s, "depth", 0);
                depth = (x && SvOK(*x)) ? SvIV(*x) : 0;
                x = hv_fetchs(s, "status", 0);
                status = (x && SvOK(*x)) ? SvIV(*x) : 0;

                x = hv_fetchs(s, "span_id", 0);
                hv_stores(o, "span_id", x ? newSVsv(*x) : newSV(0));
                /* The parent, for collapsing a subtree by IDENTITY. Rows come
                 * out chronological (store.xs), so a subtree's descendants
                 * are not adjacent whenever two sibling subtrees overlap in
                 * time - and walking the next rows while depth is greater
                 * hides part of somebody else's subtree, or stops at the
                 * first sibling and hides nothing. */
                x = hv_fetchs(s, "parent_span_id", 0);
                hv_stores(o, "parent_span_id", x ? newSVsv(*x) : newSViv(0));
                x = hv_fetchs(s, "depth", 0);
                hv_stores(o, "depth", x ? newSVsv(*x) : newSV(0));
                /* A root span starts at 5 rather than 0: flush against the
                 * cell edge the label touches the panel border and reads as
                 * part of it. */
                /* depth is -1 for a span in a cycle or past PO_TREE_MAX_DEPTH;
                 * 5 + -1*14 is -9px, which pulls the label out of its cell. */
                hv_stores(o, "indent", newSViv(depth > 0 ? 5 + depth * 14 : 5));
                x = hv_fetchs(s, "kind", 0);
                hv_stores(o, "kind_name",
                          newSVpv(po_span_kind_name(x && SvOK(*x)
                                                    ? (int)SvIV(*x) : 0), 0));

                x = hv_fetchs(s, "name", 0);
                nm = (x && SvTRUE(*x)) ? newSVsv(*x) : newSVpvs("(unnamed)");
                hv_stores(o, "name", nm);
                x = hv_fetchs(s, "service", 0);
                svc = x ? newSVsv(*x) : newSV(0);
                hv_stores(o, "service", svc);

                bn = po_fmt_dur(w, b);
                hv_stores(o, "dur_ms", newSVpvn(b, bn));
                hv_stores(o, "start_pct", newSVnv(po_pct(off, dur)));
                /* A span that rounds to nothing still has to be visible, or a
                 * fast child of a slow parent vanishes from its own trace. */
                {
                    double p = po_pct(w, dur);
                    hv_stores(o, "width_pct", newSVnv(p > 1 ? p : 1));
                }
                hv_stores(o, "status", newSViv(status));
                hv_stores(o, "row_class",
                          status == 2 ? newSVpvs("row-error") : newSVpvs(""));

                {   /* the attributes, in a stable order */
                    AV *out = newAV();
                    SV **av = NULL;
                    x = hv_fetchs(s, "span_id", 0);
                    if (x && SvOK(*x)) {
                        STRLEN il;
                        const char *ip = SvPV(*x, il);
                        av = hv_fetch(attrs_of, ip, (I32)il, 0);
                    }
                    if (av && SvROK(*av) && SvTYPE(SvRV(*av)) == SVt_PVHV) {
                        HV *ah = (HV *)SvRV(*av);
                        SSize_t nk = 0, k;
                        SV **ks;
                        HE *he;
                        hv_iterinit(ah);
                        Newx(ks, HvUSEDKEYS(ah) ? HvUSEDKEYS(ah) : 1, SV *);
                        while ((he = hv_iternext(ah)))
                            ks[nk++] = newSVsv(hv_iterkeysv(he));
                        for (k = 1; k < nk; k++) {
                            SV *key = ks[k];
                            SSize_t j;
                            STRLEN kl;
                            const char *kp = SvPV(key, kl);
                            for (j = k - 1; j >= 0; j--) {
                                STRLEN jl;
                                const char *jp = SvPV(ks[j], jl);
                                size_t m = jl < kl ? jl : kl;
                                int c = m ? memcmp(jp, kp, m) : 0;
                                if (!c) c = jl == kl ? 0 : (jl < kl ? -1 : 1);
                                if (c <= 0) break;
                                ks[j + 1] = ks[j];
                            }
                            ks[j + 1] = key;
                        }
                        for (k = 0; k < nk; k++) {
                            HV *pair = newHV();
                            STRLEN kl;
                            const char *kp = SvPV(ks[k], kl);
                            SV **val = hv_fetch(ah, kp, (I32)kl, 0);
                            hv_stores(pair, "key", ks[k]);
                            hv_stores(pair, "value",
                                      val ? newSVpv(SvPV_nolen(*val), 0)
                                          : newSVpvs(""));
                            av_push(out, newRV_noinc((SV *)pair));
                            /* The statement, lifted out for the bar's
                             * tooltip: a database span is named for its
                             * OPERATION so the name stays a grouping key,
                             * and a row that says only SELECT answers
                             * nothing about which one. */
                            if (val && kl == 13 && !memcmp(kp, "db.query.text", 13))
                                hv_stores(o, "query", newSVsv(*val));
                        }
                        Safefree(ks);
                    }
                    hv_stores(o, "attrs", newRV_noinc((SV *)out));
                }
                av_push(spans_out, newRV_noinc((SV *)o));

                /* The tree wants SYMBOLS, not strings: it folds frames by
                 * identity, and comparing names as strings for every span of
                 * a large trace is the difference between a picture and a
                 * wait. */
                {
                    SV **x2 = hv_fetchs(s, "name", 0);
                    SV *key = (x2 && SvOK(*x2)) ? newSVsv(*x2) : newSVpvs("");
                    STRLEN kl;
                    const char *kp = SvPV(key, kl);
                    SV **slot = hv_fetch(nsym, kp, (I32)kl, 0);
                    if (slot) nid = SvIV(*slot);
                    else {
                        nid = av_len(nname) + 1;
                        av_push(nname, newSVsv(key));
                        (void)hv_store(nsym, kp, (I32)kl, newSViv(nid), 0);
                    }
                    SvREFCNT_dec(key);
                }
                {
                    SV **x2 = hv_fetchs(s, "service", 0);
                    SV *key = (x2 && SvOK(*x2)) ? newSVsv(*x2) : newSVpvs("");
                    STRLEN kl;
                    const char *kp = SvPV(key, kl);
                    SV **slot = hv_fetch(ssym, kp, (I32)kl, 0);
                    if (slot) sid = SvIV(*slot);
                    else {
                        sid = av_len(sname) + 1;
                        av_push(sname, newSVsv(key));
                        (void)hv_store(ssym, kp, (I32)kl, newSViv(sid), 0);
                    }
                    SvREFCNT_dec(key);
                }

                spec = newHV();
                hv_stores(spec, "trace_hi", po_u64_to_sv(hi));
                hv_stores(spec, "trace_lo", po_u64_to_sv(lo));
                x = hv_fetchs(s, "span_id", 0);
                hv_stores(spec, "span_id", x ? newSVsv(*x) : newSV(0));
                /* The store already gives the parent SPAN ID (store.xs), and
                 * Flame::build's span spec wants a span id - so this is a
                 * pass-through and was not.
                 *
                 * It ran through povw_parent_id_sv, which converts an INDEX to
                 * a span id and is written for Trace::analyse's output. Handed
                 * a span id it did this: the root, whose parent is 0, indexed
                 * spans[0] - ITSELF - and became its own parent, which
                 * po_tree_build reads as a cycle and po_flame_add then skips.
                 * Every child's real 64-bit parent fell outside the array and
                 * flattened to 0. So the flamegraph lost the root span of
                 * every trace, while the waterfall above it - which uses the
                 * store's own depth - looked right. */
                x = hv_fetchs(s, "parent_span_id", 0);
                hv_stores(spec, "parent", x ? newSVsv(*x) : newSViv(0));
                x = hv_fetchs(s, "start", 0);
                hv_stores(spec, "start", x ? newSVsv(*x) : newSV(0));
                {
                    po_u64 st = 0, d2 = 0;
                    if (x) (void)po_sv_to_u64(aTHX_ *x, &st);
                    {
                        SV **dd = hv_fetchs(s, "duration", 0);
                        if (dd) (void)po_sv_to_u64(aTHX_ *dd, &d2);
                    }
                    hv_stores(spec, "end", po_u64_to_sv(po_ns_add(st, d2)));
                }
                hv_stores(spec, "name",    newSViv(nid));
                hv_stores(spec, "service", newSViv(sid));
                x = hv_fetchs(s, "status", 0);
                hv_stores(spec, "status", x ? newSVsv(*x) : newSV(0));
                x = hv_fetchs(s, "kind", 0);
                hv_stores(spec, "kind", x ? newSVsv(*x) : newSV(0));
                av_push(specs, newRV_noinc((SV *)spec));
            }
            SvREFCNT_dec((SV *)attrs_of);
        }

        povw_set_iv(aTHX_ v, "span_count", t, "span_count");
        {
            char b[64];
            SV **d = hv_fetchs(t, "duration", 0);
            po_u64 dv = 0;
            size_t bn;
            if (d) (void)po_sv_to_u64(aTHX_ *d, &dv);
            bn = po_fmt_dur(dv, b);
            hv_stores(v, "duration_ms", newSVpvn(b, bn));
        }
        {
            SV **first = av_fetch(spans_out, 0, 0);
            SV *root;
            if (first && SvROK(*first)) {
                HV *o = (HV *)SvRV(*first);
                SV **svc = hv_fetchs(o, "service", 0);
                SV **nm  = hv_fetchs(o, "name", 0);
                root = newSVpvs("");
                if (svc && SvOK(*svc)) sv_catsv(root, *svc);
                sv_catpvs(root, " ");
                if (nm && SvOK(*nm)) sv_catsv(root, *nm);
            }
            else root = newSVpvs("Trace");
            hv_stores(v, "root_name", newSVsv(root));
            hv_stores(v, "heading",   root);
        }
        povw_set_iv(aTHX_ v, "orphans", t, "orphans");
        povw_set_iv(aTHX_ v, "cycles",  t, "cycles");
        povw_set_iv(aTHX_ v, "errors",  t, "errors");

        {   /* THE LOGS THIS TRACE PRODUCED, which is the cross-signal join
             * the query language names `traces | logs` and the reason log
             * records carry a trace id at all. Filtered in the scan on two
             * integers rather than read wholesale and sifted here.
             *
             * No window: a trace is looked at long after the window that
             * produced it, and a link pasted into a chat an hour later should
             * still show its logs. */
            AV *out = newAV();
            SV *logs = NULL;
            int n;

            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(newSVpvs("kind")));     XPUSHs(sv_2mortal(newSViv(2)));
            XPUSHs(sv_2mortal(newSVpvs("trace_hi"))); XPUSHs(sv_2mortal(po_u64_to_sv(hi)));
            XPUSHs(sv_2mortal(newSVpvs("trace_lo"))); XPUSHs(sv_2mortal(po_u64_to_sv(lo)));
            XPUSHs(sv_2mortal(newSVpvs("limit")));    XPUSHs(sv_2mortal(newSViv(500)));
            PUTBACK;
            n = call_method("rows", G_LIST);
            SPAGAIN;
            {
                SSize_t k;
                for (k = n - 1; k > 0; k--) (void)POPs;
                logs = n ? SvREFCNT_inc(POPs) : NULL;
            }
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;

            if (logs && SvROK(logs) && SvTYPE(SvRV(logs)) == SVt_PVAV) {
                AV *la = (AV *)SvRV(logs);
                SSize_t k, cnt = av_len(la) + 1;
                /* REVERSED: the store hands them back newest first and a log
                 * beside a waterfall reads downwards, in the order the trace
                 * happened. */
                for (k = cnt - 1; k >= 0; k--) {
                    SV **e = av_fetch(la, k, 0);
                    HV *w, *o;
                    SV **x;
                    const char *sev;
                    char b[64];
                    size_t bn;
                    const char *tp = "0";
                    STRLEN tl = 1;

                    if (!e || !SvROK(*e)) continue;
                    w = (HV *)SvRV(*e);
                    o = newHV();
                    x = hv_fetchs(w, "t", 0);
                    if (x && SvOK(*x)) tp = SvPV(*x, tl);
                    bn = po_fmt_time(tp, (size_t)tl, b);
                    hv_stores(o, "time", newSVpvn(b, bn));
                    x = hv_fetchs(w, "severity", 0);
                    sev = po_severity_name(x && SvOK(*x) ? (int)SvIV(*x) : 0);
                    hv_stores(o, "sev_name", newSVpv(sev, 0));
                    x = hv_fetchs(w, "service", 0);
                    hv_stores(o, "service", x ? newSVsv(*x) : newSV(0));
                    x = hv_fetchs(w, "body", 0);
                    hv_stores(o, "body", (x && SvOK(*x)) ? newSVsv(*x)
                                                         : newSVpvs(""));
                    hv_stores(o, "id", povw_record_id_sv(aTHX_ *e));
                    x = hv_fetchs(w, "span_id", 0);
                    hv_stores(o, "span_id", (x && SvTRUE(*x)) ? newSVsv(*x)
                                                              : newSVpvs(""));
                    hv_stores(o, "row_class",
                              (strEQ(sev, "error") || strEQ(sev, "fatal"))
                                ? newSVpvs("row-error") : newSVpvs(""));
                    av_push(out, newRV_noinc((SV *)o));
                }
            }
            if (logs) SvREFCNT_dec(logs);
            hv_stores(v, "logs", newRV_noinc((SV *)out));
        }

        {   /* The flamegraph, from SELF time rather than total, so a parent
             * that spent its time waiting on a child does not appear to have
             * spent it working. */
            SV *tree = NULL;
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(sv_2mortal(newRV_inc((SV *)specs)));
            PUTBACK;
            n = call_pv("Punk::Observe::Flame::build", G_SCALAR | G_EVAL);
            SPAGAIN;
            tree = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
            if (SvTRUE(ERRSV) && tree) { SvREFCNT_dec(tree); tree = NULL; }

            if (tree && SvTRUE(tree)) {
                SV *rows;
                ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSVsv(tree)));
                XPUSHs(sv_2mortal(newRV_inc((SV *)nname)));
                XPUSHs(sv_2mortal(newRV_inc((SV *)sname)));
                PUTBACK;
                n = call_pv("Punk::Observe::View::_flame_rows", G_SCALAR);
                SPAGAIN;
                rows = n ? SvREFCNT_inc(POPs) : NULL;
                PUTBACK;
                FREETMPS; LEAVE;
                SPAGAIN;

                if (rows) {
                    IV deep = 0;
                    if (SvROK(rows) && SvTYPE(SvRV(rows)) == SVt_PVAV) {
                        AV *ra = (AV *)SvRV(rows);
                        SSize_t k, cnt = av_len(ra) + 1;
                        for (k = 0; k < cnt; k++) {
                            SV **e = av_fetch(ra, k, 0);
                            SV **d = (e && SvROK(*e))
                                ? hv_fetchs((HV *)SvRV(*e), "depth", 0) : NULL;
                            IV dv = (d && SvOK(*d)) ? SvIV(*d) : 0;
                            if (dv > deep) deep = dv;
                        }
                    }
                    hv_stores(v, "flame", rows);
                    hv_stores(v, "flame_height", newSViv((deep + 1) * 18 + 4));
                }
            }
            if (tree) SvREFCNT_dec(tree);
        }
        SvREFCNT_dec(tsv);

    done:
        SvREFCNT_dec((SV *)nname);
        SvREFCNT_dec((SV *)sname);
        SvREFCNT_dec((SV *)nsym);
        SvREFCNT_dec((SV *)ssym);
        SvREFCNT_dec((SV *)specs);
        RETVAL = newRV_noinc((SV *)v);
    }
    OUTPUT:
        RETVAL

# ONE BOX, TWO QUESTIONS, because they are asked with the same gesture.
#
# Somebody arriving at this page has either an identifier - pasted out of a
# log line, a header, another vendor's UI - or a description of what they are
# looking for. Making them choose the right control first means the id goes in
# the filter box, matches nothing, and the page says "no traces", which reads
# as "that trace is gone".
#
# So: if it parses as an identifier, it IS one, and the trace opens.
# Everything that does not parse is a search term.
SV *
povw__page_trace(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *v = NULL;
        HV *rq = NULL;
        SV **f;
        SV *from = NULL, *to = NULL, *range = NULL;
        SV *res = NULL;
        const char *q = "";
        STRLEN qlen = 0;
        po_u64 ns = 0;
        int is_max = 0, have_ns = 0;
        const char *mm = "";
        STRLEN mmlen = 0;
        AV *traces_out = NULL;
        po_u64 max = 0;

        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV) rq = (HV *)SvRV(req);
        range = povw_window_range(aTHX_ req, &from, &to);

        /* An explicit trace opens it, and so does a query that parses as an
         * identifier - canonicalised on the way in, so the page it opens
         * carries the same identifier as every link to it. */
        f = rq ? hv_fetchs(rq, "trace", 0) : NULL;
        if (f && SvOK(*f) && SvCUR(*f)) {
            RETVAL = povw_trace_one_sv(aTHX_ class, store, req, from, to, range);
            goto out;
        }
        if (rq && (f = hv_fetchs(rq, "q", 0)) && SvOK(*f) && SvCUR(*f)) {
            po_u64 hi = 0, lo = 0;
            if (povw_trace_id_c(aTHX_ *f, &hi, &lo)) {
                HV *copy = newHVhv(rq);
                SV *rr = sv_2mortal(newRV_noinc((SV *)copy));
                hv_stores(copy, "trace", povw_trace_hex_sv(aTHX_
                              sv_2mortal(po_u64_to_sv(hi)),
                              sv_2mortal(po_u64_to_sv(lo))));
                RETVAL = povw_trace_one_sv(aTHX_ class, store, rr, from, to, range);
                goto out;
            }
        }

        v = newHV();
        hv_stores(v, "heading", newSVpvs("Traces"));
        hv_stores(v, "title",   newSVpvs("Traces"));
        hv_stores(v, "from",    newSVsv(from));
        hv_stores(v, "to",      newSVsv(to));
        hv_stores(v, "spans",   newRV_noinc((SV *)newAV()));
        traces_out = newAV();
        hv_stores(v, "traces",  newRV_noinc((SV *)traces_out));

        povw_range_vars(aTHX_ v, req, range);

        if (rq && (f = hv_fetchs(rq, "q", 0)) && SvTRUE(*f)) q = SvPV(*f, qlen);
        hv_stores(v, "query", newSVpvn(q, qlen));
        {
            char *esc;
            size_t en;
            Newx(esc, qlen * 3 + 1, char);
            en = po_url_esc(q, (size_t)qlen, esc, qlen * 3 + 1);
            hv_stores(v, "query_esc", newSVpvn(esc, en));
            Safefree(esc);
        }
        f = rq ? hv_fetchs(rq, "errors", 0) : NULL;
        hv_stores(v, "errors_only", newSViv(f && SvTRUE(*f) ? 1 : 0));
        /* The DISPLAY value blanks a bare "0", as `|| ''` did; the GUARD
         * below reads the raw string, because "0" is a filter somebody typed
         * and a filter of zero is not the absence of one. */
        f = rq ? hv_fetchs(rq, "min_ms", 0) : NULL;
        if (f && SvOK(*f)) mm = SvPV(*f, mmlen);
        hv_stores(v, "min_ms", (f && SvTRUE(*f)) ? newSVsv(*f) : newSVpvs(""));
        f = rq ? hv_fetchs(rq, "service", 0) : NULL;
        hv_stores(v, "service", (f && SvTRUE(*f)) ? newSVsv(*f) : newSVpvs(""));

        /* A FILTER THAT CANNOT BE READ IS REFUSED, NOT DROPPED. An empty box
         * is no filter; text that is not a duration is a mistake, and
         * dropping it silently answered with the whole unfiltered table -
         * which is the one outcome indistinguishable from a correct answer. */
        /* THREE ANSWERS, not two: nothing typed, something typed that does
         * not read as a duration, and a duration. Only the middle one is an
         * error, and collapsing it into the first is what made an unreadable
         * filter answer with the whole unfiltered table. */
        if (mmlen) have_ns = po_min_duration(mm, (size_t)mmlen, &ns, &is_max);
        if (mmlen && have_ns <= 0) {
            SV *e = newSVpvs("'");
            sv_catpvn(e, mm, mmlen);
            sv_catpvs(e, "' is not a duration.");
            hv_stores(v, "error", e);
            hv_stores(v, "hint",
                newSVpvs("Try 100 for milliseconds, or give a unit: 250us, "
                         "500ms, 1.5s. Put < in front for faster than: < 100ms."));
            goto done;
        }
        if (!SvOK(store) || !SvROK(store)) goto done;

        {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(newSVpvs("from"))); XPUSHs(sv_2mortal(newSVsv(from)));
            XPUSHs(sv_2mortal(newSVpvs("to")));   XPUSHs(sv_2mortal(newSVsv(to)));
            XPUSHs(sv_2mortal(newSVpvs("errors_only")));
            f = rq ? hv_fetchs(rq, "errors", 0) : NULL;
            XPUSHs(sv_2mortal(newSViv(f && SvTRUE(*f) ? 1 : 0)));
            /* THE SAME BOX BOUNDS EITHER END. "faster than 100ms" is a
             * question about the same column as "slower than 100ms" and there
             * is no reason one should be askable and the other not. */
            XPUSHs(sv_2mortal(newSVpv(is_max ? "max_duration" : "min_duration", 0)));
            XPUSHs(sv_2mortal(have_ns > 0 ? po_u64_to_sv(ns) : newSV(0)));
            XPUSHs(sv_2mortal(newSVpvs("service")));
            f = rq ? hv_fetchs(rq, "service", 0) : NULL;
            XPUSHs(sv_2mortal(f ? newSVsv(*f) : newSV(0)));
            XPUSHs(sv_2mortal(newSVpvs("match")));
            f = rq ? hv_fetchs(rq, "q", 0) : NULL;
            XPUSHs(sv_2mortal(f ? newSVsv(*f) : newSV(0)));
            XPUSHs(sv_2mortal(newSVpvs("limit"))); XPUSHs(sv_2mortal(newSViv(50)));
            /* THE PAGE CURSOR: "durns-hi-lo", the triple that gives the
             * duration walk its total order. Parsed strictly - a mangled
             * cursor is ignored and the first page answers, which beats a
             * 500 for a truncated paste. */
            f = rq ? hv_fetchs(rq, "after", 0) : NULL;
            if (f && SvOK(*f)) {
                STRLEN al;
                const char *ap = SvPV(*f, al);
                STRLEN d1 = 0, d2 = 0, ix;
                int digits = 1;
                for (ix = 0; ix < al; ix++) {
                    if (ap[ix] == '-') { if (!d1) d1 = ix; else if (!d2) d2 = ix; else digits = 0; }
                    else if (ap[ix] < '0' || ap[ix] > '9') digits = 0;
                }
                if (digits && d1 && d2 > d1 + 1 && d2 + 1 < al) {
                    XPUSHs(sv_2mortal(newSVpvs("after_dur")));
                    XPUSHs(sv_2mortal(newSVpvn(ap, d1)));
                    XPUSHs(sv_2mortal(newSVpvs("after_hi")));
                    XPUSHs(sv_2mortal(newSVpvn(ap + d1 + 1, d2 - d1 - 1)));
                    XPUSHs(sv_2mortal(newSVpvs("after_lo")));
                    XPUSHs(sv_2mortal(newSVpvn(ap + d2 + 1, al - d2 - 1)));
                    hv_stores(v, "paged", newSViv(1));
                }
            }
            PUTBACK;
            n = call_method("traces", G_SCALAR);
            SPAGAIN;
            res = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
        }
        if (!res || !SvROK(res) || SvTYPE(SvRV(res)) != SVt_PVHV) {
            if (res) SvREFCNT_dec(res);
            goto done;
        }

        {
            HV *r = (HV *)SvRV(res);
            SV **tv = hv_fetchs(r, "traces", 0);
            AV *ta = (tv && SvROK(*tv) && SvTYPE(SvRV(*tv)) == SVt_PVAV)
                       ? (AV *)SvRV(*tv) : NULL;
            SSize_t i, cnt = ta ? av_len(ta) + 1 : 0;
            AV *pts = newAV();

            for (i = 0; i < cnt; i++) {
                SV **e = av_fetch(ta, i, 0);
                SV **d = (e && SvROK(*e))
                           ? hv_fetchs((HV *)SvRV(*e), "duration", 0) : NULL;
                po_u64 dv = 0;
                if (d) (void)po_sv_to_u64(aTHX_ *d, &dv);
                if (dv > max) max = dv;
            }

            for (i = 0; i < cnt; i++) {
                SV **e = av_fetch(ta, i, 0);
                HV *t, *o;
                SV **x, **hi, **lo;
                po_u64 dv = 0;
                char b[64];
                size_t bn;

                if (!e || !SvROK(*e)) continue;
                t = (HV *)SvRV(*e);
                o = newHV();
                hi = hv_fetchs(t, "trace_hi", 0);
                lo = hv_fetchs(t, "trace_lo", 0);
                hv_stores(o, "id", povw_trace_hex_sv(aTHX_
                              hi ? *hi : &PL_sv_no, lo ? *lo : &PL_sv_no));
                x = hv_fetchs(t, "service", 0);
                hv_stores(o, "service", x ? newSVsv(*x) : newSV(0));
                x = hv_fetchs(t, "name", 0);
                hv_stores(o, "name", x ? newSVsv(*x) : newSV(0));
                x = hv_fetchs(t, "spans", 0);
                hv_stores(o, "spans", x ? newSVsv(*x) : newSV(0));
                x = hv_fetchs(t, "errors", 0);
                hv_stores(o, "errors", x ? newSVsv(*x) : newSV(0));
                hv_stores(o, "row_class",
                          (x && SvTRUE(*x)) ? newSVpvs("row-error")
                                            : newSVpvs(""));
                {
                    SV **dd = hv_fetchs(t, "duration", 0);
                    if (dd) (void)po_sv_to_u64(aTHX_ *dd, &dv);
                }
                bn = po_fmt_dur(dv, b);
                hv_stores(o, "duration", newSVpvn(b, bn));
                hv_stores(o, "width_pct",
                          newSViv(max ? (IV)(100.0 * (double)dv / (double)max)
                                      : 0));
                av_push(traces_out, newRV_noinc((SV *)o));

                /* WHERE THE SLOW ONES CLUSTER IS WHAT THE TABLE CANNOT SHOW.
                 *
                 * A list of the fifty slowest answers "which were slow"; it
                 * cannot answer "were they slow all afternoon or for ninety
                 * seconds at half past two", which is the question that
                 * separates a capacity problem from an incident. Same rows,
                 * plotted against the time they happened. */
                x = hv_fetchs(t, "t", 0);
                if (x && SvOK(*x)) {
                    HV *p = newHV();
                    SV **er = hv_fetchs(t, "errors", 0);
                    SV **dd = hv_fetchs(t, "duration", 0);
                    hv_stores(p, "t", newSVsv(*x));
                    hv_stores(p, "duration", dd ? newSVsv(*dd) : newSV(0));
                    hv_stores(p, "errors", er ? newSVsv(*er) : newSV(0));
                    hv_stores(p, "id", povw_trace_hex_sv(aTHX_
                                  hi ? *hi : &PL_sv_no, lo ? *lo : &PL_sv_no));
                    av_push(pts, newRV_noinc((SV *)p));
                }
            }

            /* The scatter is drawn from the same trace list the table below
             * it shows, so the two cannot disagree about what is in the
             * window. */
            if (cnt) {
                SV *fig = NULL, *enc = NULL;
                int n;
                ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(sv_2mortal(newRV_inc((SV *)pts)));
                PUTBACK;
                n = call_pv("Punk::Observe::Plot::latency_scatter", G_SCALAR);
                SPAGAIN;
                fig = n ? SvREFCNT_inc(POPs) : NULL;
                PUTBACK;
                FREETMPS; LEAVE;
                SPAGAIN;

                ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(sv_2mortal(fig ? newSVsv(fig) : newSV(0)));
                PUTBACK;
                n = call_pv("Punk::Observe::Plot::encode", G_SCALAR);
                SPAGAIN;
                enc = n ? SvREFCNT_inc(POPs) : NULL;
                PUTBACK;
                FREETMPS; LEAVE;
                SPAGAIN;
                if (fig) SvREFCNT_dec(fig);
                if (enc) hv_stores(v, "scatter_plot", enc);
            }
            SvREFCNT_dec((SV *)pts);

            /* MORE BEYOND THIS PAGE. A full page's last trace is the
             * cursor for the next fifty; a short page IS the end, and a
             * "next" link there would page into nothing. From the raw result
             * rather than the formatted rows, because the cursor needs the
             * exact duration and the row carries "1.3s". The first version
             * of this block ran before `res` existed, on the store of an
             * empty placeholder - which is a segfault, and the reminder that
             * "after the assignment in the source" is not "after it runs". */
            {
                SV **tv2 = hv_fetchs(r, "traces", 0);
                if (tv2 && SvROK(*tv2) && SvTYPE(SvRV(*tv2)) == SVt_PVAV) {
                    AV *ta2 = (AV *)SvRV(*tv2);
                    SSize_t n2 = av_len(ta2) + 1;
                    if (n2 >= 50) {
                        SV **le = av_fetch(ta2, n2 - 1, 0);
                        if (le && SvROK(*le)
                            && SvTYPE(SvRV(*le)) == SVt_PVHV) {
                            HV *lh = (HV *)SvRV(*le);
                            SV **du  = hv_fetchs(lh, "duration", 0);
                            SV **hi2 = hv_fetchs(lh, "trace_hi", 0);
                            SV **lo2 = hv_fetchs(lh, "trace_lo", 0);
                            if (du && hi2 && lo2) {
                                SV *cur = newSVsv(*du);
                                sv_catpvs(cur, "-");
                                sv_catsv(cur, *hi2);
                                sv_catpvs(cur, "-");
                                sv_catsv(cur, *lo2);
                                hv_stores(v, "next_cursor", cur);
                            }
                        }
                    }
                }
            }
            povw_set_iv(aTHX_ v, "span_count", r, "spans");
            povw_set_iv(aTHX_ v, "total", r, "total");
            hv_stores(v, "root_name", newSVpvs("Traces in this window"));
        }
        SvREFCNT_dec(res);

    done:
        RETVAL = newRV_noinc((SV *)v);
    out:
        SvREFCNT_dec(from); SvREFCNT_dec(to); SvREFCNT_dec(range);
    }
    OUTPUT:
        RETVAL

# The service map.
#
# Services become symbols for the layout and names again for the drawing. The
# layout works in numbers because a graph algorithm has no business comparing
# strings; the page needs the names back or it draws the boxes the demo drew:
# correctly placed and unlabelled.
SV *
povw__page_map(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *v = newHV();
        AV *nodes_out = newAV(), *edges_out = newAV();
        SV *from = NULL, *to = NULL, *range = NULL;
        SV *gsv = NULL, *lay = NULL;
        AV *edges = NULL;
        HV *sym = newHV();
        AV *names = newAV();
        SSize_t ne = 0, i;
        double *px = NULL, *py = NULL;
        char *hasp = NULL;
        SSize_t nsym = 0;

        PERL_UNUSED_VAR(class);
        hv_stores(v, "heading", newSVpvs("Service map"));
        hv_stores(v, "title",   newSVpvs("Service map"));
        hv_stores(v, "nodes",   newRV_noinc((SV *)nodes_out));
        hv_stores(v, "edges",   newRV_noinc((SV *)edges_out));
        hv_stores(v, "width",   newSViv(POVW_CHART_W));
        hv_stores(v, "height",  newSViv(POVW_CHART_H));

        range = povw_window_range(aTHX_ req, &from, &to);
        hv_stores(v, "from", newSVsv(from));
        hv_stores(v, "to",   newSVsv(to));
        povw_range_vars(aTHX_ v, req, range);

        if (!SvOK(store) || !SvROK(store)) goto done;

        {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(newSVpvs("from"))); XPUSHs(sv_2mortal(newSVsv(from)));
            XPUSHs(sv_2mortal(newSVpvs("to")));   XPUSHs(sv_2mortal(newSVsv(to)));
            PUTBACK;
            n = call_method("graph", G_SCALAR);
            SPAGAIN;
            gsv = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
        }
        if (gsv && SvROK(gsv) && SvTYPE(SvRV(gsv)) == SVt_PVHV) {
            SV **e = hv_fetchs((HV *)SvRV(gsv), "edges", 0);
            if (e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)
                edges = (AV *)SvRV(*e);
        }
        ne = edges ? av_len(edges) + 1 : 0;
        if (!ne) { hv_stores(v, "empty", newSViv(1)); goto done; }

        for (i = 0; i < ne; i++) {
            SV **e = av_fetch(edges, i, 0);
            HV *eh;
            int end;
            if (!e || !SvROK(*e)) continue;
            eh = (HV *)SvRV(*e);
            for (end = 0; end < 2; end++) {
                SV **x = end ? hv_fetchs(eh, "callee", 0)
                             : hv_fetchs(eh, "caller", 0);
                STRLEN l;
                const char *p;
                if (!x || !SvOK(*x)) continue;
                p = SvPV(*x, l);
                if (l == 1 && *p == '*') continue;
                if (hv_fetch(sym, p, (I32)l, 0)) continue;
                (void)hv_store(sym, p, (I32)l, newSViv((IV)(av_len(names) + 1)), 0);
                av_push(names, newSVpvn(p, l));
            }
        }
        nsym = av_len(names) + 1;

        {
            AV *in = newAV();
            int n;
            for (i = 0; i < ne; i++) {
                SV **e = av_fetch(edges, i, 0);
                HV *eh, *o;
                SV **x;
                if (!e || !SvROK(*e)) continue;
                eh = (HV *)SvRV(*e);
                o = newHV();
                x = hv_fetchs(eh, "caller", 0);
                if (x && SvOK(*x)) {
                    STRLEN l;
                    const char *p = SvPV(*x, l);
                    if (l == 1 && *p == '*') hv_stores(o, "caller", newSVpvs("*"));
                    else {
                        SV **s2 = hv_fetch(sym, p, (I32)l, 0);
                        hv_stores(o, "caller", s2 ? newSVsv(*s2) : newSV(0));
                    }
                }
                x = hv_fetchs(eh, "callee", 0);
                if (x && SvOK(*x)) {
                    STRLEN l;
                    const char *p = SvPV(*x, l);
                    SV **s2 = hv_fetch(sym, p, (I32)l, 0);
                    hv_stores(o, "callee", s2 ? newSVsv(*s2) : newSV(0));
                }
                x = hv_fetchs(eh, "count", 0);
                hv_stores(o, "count", x ? newSVsv(*x) : newSV(0));
                x = hv_fetchs(eh, "errors", 0);
                hv_stores(o, "errors", x ? newSVsv(*x) : newSV(0));
                av_push(in, newRV_noinc((SV *)o));
            }
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(sv_2mortal(newRV_noinc((SV *)in)));
            PUTBACK;
            n = call_pv("Punk::Observe::Map::layout", G_SCALAR | G_EVAL);
            SPAGAIN;
            lay = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
            if (SvTRUE(ERRSV) && lay) { SvREFCNT_dec(lay); lay = NULL; }
        }
        if (!lay || !SvTRUE(lay) || !SvROK(lay)
            || SvTYPE(SvRV(lay)) != SVt_PVHV) goto done;

        {
            HV *lh = (HV *)SvRV(lay);
            SV **x = hv_fetchs(lh, "nodes", 0);
            AV *ln = (x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVAV)
                       ? (AV *)SvRV(*x) : NULL;
            SSize_t nn = ln ? av_len(ln) + 1 : 0;
            IV layers, tallest = 1;
            IV *per_layer = NULL, *slot = NULL;
            IV maxlayer = 0;
            double w = POVW_CHART_W, h, dx;
            SSize_t k;

            x = hv_fetchs(lh, "layers", 0);
            layers = (x && SvTRUE(*x)) ? SvIV(*x) : 1;

            for (k = 0; k < nn; k++) {
                SV **e = av_fetch(ln, k, 0);
                SV **l = (e && SvROK(*e))
                           ? hv_fetchs((HV *)SvRV(*e), "layer", 0) : NULL;
                IV lv = (l && SvOK(*l)) ? SvIV(*l) : 0;
                if (lv > maxlayer) maxlayer = lv;
            }
            Newxz(per_layer, maxlayer + 1, IV);
            Newxz(slot,      maxlayer + 1, IV);
            for (k = 0; k < nn; k++) {
                SV **e = av_fetch(ln, k, 0);
                SV **l = (e && SvROK(*e))
                           ? hv_fetchs((HV *)SvRV(*e), "layer", 0) : NULL;
                IV lv = (l && SvOK(*l)) ? SvIV(*l) : 0;
                if (lv >= 0 && lv <= maxlayer) per_layer[lv]++;
            }
            for (k = 0; k <= maxlayer; k++)
                if (per_layer[k] > tallest) tallest = per_layer[k];

            /* Layer and slot are a grid; this is the only place that turns
             * them into coordinates, so the layout stays a layout and the
             * geometry stays here. */
            h = (double)POVW_CHART_H;
            if ((double)(tallest * 62 + 40) > h) h = (double)(tallest * 62 + 40);
            dx = layers > 1 ? (w - 140) / (double)(layers - 1) : 0;

            Newxz(px,   nsym + 1, double);
            Newxz(py,   nsym + 1, double);
            Newxz(hasp, nsym + 1, char);

            for (k = 0; k < nn; k++) {
                SV **e = av_fetch(ln, k, 0);
                HV *nh, *o;
                SV **svc, **l;
                IV lv, idx, count, islot;
                double nx, ny;
                int is_root;
                SV *nm;

                if (!e || !SvROK(*e)) continue;
                nh = (HV *)SvRV(*e);
                l = hv_fetchs(nh, "layer", 0);
                lv = (l && SvOK(*l)) ? SvIV(*l) : 0;
                count = (lv >= 0 && lv <= maxlayer && per_layer[lv])
                          ? per_layer[lv] : 1;
                islot = (lv >= 0 && lv <= maxlayer) ? slot[lv]++ : 0;
                nx = 70 + (double)lv * dx;
                ny = (h / (double)(count + 1)) * (double)(islot + 1);

                svc = hv_fetchs(nh, "service", 0);
                {
                    STRLEN sl = 0;
                    const char *sp = (svc && SvOK(*svc)) ? SvPV(*svc, sl) : "";
                    is_root = (sl == 1 && *sp == '*');
                    if (is_root) { idx = nsym; nm = newSVpvs("internet"); }
                    else {
                        SV **got;
                        idx = SvIV(*svc);
                        got = av_fetch(names, (SSize_t)idx, 0);
                        nm = got ? newSVsv(*got) : newSVpvs("");
                    }
                }
                if (idx >= 0 && idx <= nsym) {
                    px[idx] = nx; py[idx] = ny; hasp[idx] = 1;
                }

                o = newHV();
                hv_stores(o, "name", nm);
                hv_stores(o, "service",
                          is_root ? newSVpvs("") : newSVsv(nm));
                hv_stores(o, "x", povw_fixed(aTHX_ nx, 1));
                hv_stores(o, "y", povw_fixed(aTHX_ ny, 1));
                {
                    char b[32];
                    STRLEN cl;
                    const char *cp;
                    SV **c = hv_fetchs(nh, "in", 0);
                    size_t bn;
                    cp = (c && SvOK(*c)) ? SvPV(*c, cl) : (cl = 0, "");
                    bn = po_fmt_count(cp, (size_t)cl, b, sizeof(b));
                    hv_stores(o, "in", newSVpvn(b, bn));
                    c = hv_fetchs(nh, "out", 0);
                    cp = (c && SvOK(*c)) ? SvPV(*c, cl) : (cl = 0, "");
                    bn = po_fmt_count(cp, (size_t)cl, b, sizeof(b));
                    hv_stores(o, "out", newSVpvn(b, bn));
                }
                {
                    SV **er = hv_fetchs(nh, "errors", 0);
                    int bad = er && SvTRUE(*er);
                    hv_stores(o, "errors", bad ? newSVsv(*er) : newSViv(0));
                    hv_stores(o, "state",
                              bad ? newSVpvs("error") : newSVpvs("ok"));
                }
                hv_stores(o, "root", newSViv(is_root ? 1 : 0));
                av_push(nodes_out, newRV_noinc((SV *)o));
            }
            Safefree(per_layer); Safefree(slot);

            {   /* An edge is drawn from the DEDUPLICATED graph the layout
                 * saw, which is also what `back` indexes into. */
                HV *back = newHV();
                SV **bv = hv_fetchs(lh, "back", 0);
                po_u64 heaviest = 1;

                if (bv && SvROK(*bv) && SvTYPE(SvRV(*bv)) == SVt_PVAV) {
                    AV *ba = (AV *)SvRV(*bv);
                    SSize_t j, cnt = av_len(ba) + 1;
                    for (j = 0; j < cnt; j++) {
                        SV **e = av_fetch(ba, j, 0);
                        if (e && SvOK(*e)) {
                            STRLEN kl;
                            const char *kp = SvPV(*e, kl);
                            (void)hv_store(back, kp, (I32)kl, newSViv(1), 0);
                        }
                    }
                }
                for (i = 0; i < ne; i++) {
                    SV **e = av_fetch(edges, i, 0);
                    SV **c = (e && SvROK(*e))
                               ? hv_fetchs((HV *)SvRV(*e), "count", 0) : NULL;
                    po_u64 cv = 0;
                    if (c) (void)po_sv_to_u64(aTHX_ *c, &cv);
                    if (cv > heaviest) heaviest = cv;
                }

                for (i = 0; i < ne; i++) {
                    SV **e = av_fetch(edges, i, 0);
                    HV *eh, *o;
                    SV **x2;
                    IV ai = -1, bi = -1;
                    double mx;
                    po_u64 cv = 0;
                    SV *caller_name, *callee_name;
                    char b[32];
                    size_t bn;

                    if (!e || !SvROK(*e)) continue;
                    eh = (HV *)SvRV(*e);

                    x2 = hv_fetchs(eh, "caller", 0);
                    if (x2 && SvOK(*x2)) {
                        STRLEN l;
                        const char *p = SvPV(*x2, l);
                        if (l == 1 && *p == '*') ai = nsym;
                        else {
                            SV **s2 = hv_fetch(sym, p, (I32)l, 0);
                            if (s2) ai = SvIV(*s2);
                        }
                        caller_name = (l == 1 && *p == '*')
                                        ? newSVpvs("internet") : newSVsv(*x2);
                    }
                    else caller_name = newSV(0);

                    x2 = hv_fetchs(eh, "callee", 0);
                    if (x2 && SvOK(*x2)) {
                        STRLEN l;
                        const char *p = SvPV(*x2, l);
                        SV **s2 = hv_fetch(sym, p, (I32)l, 0);
                        if (s2) bi = SvIV(*s2);
                        callee_name = newSVsv(*x2);
                    }
                    else callee_name = newSV(0);

                    /* A node the layout dropped takes its edges with it, and
                     * the index still advances - `back` counts every edge,
                     * not every drawn one. */
                    if (ai < 0 || bi < 0 || ai > nsym || bi > nsym
                        || !hasp[ai] || !hasp[bi]) {
                        SvREFCNT_dec(caller_name);
                        SvREFCNT_dec(callee_name);
                        continue;
                    }

                    o = newHV();
                    mx = (px[ai] + px[bi]) / 2;
                    {
                        SV *d = newSVpvs("M");
                        char f2[32];
                        size_t fn;
                        fn = po_fmt(px[ai] + 52, f2); sv_catpvn(d, f2, fn);
                        sv_catpvs(d, ",");
                        fn = po_fmt(py[ai], f2);      sv_catpvn(d, f2, fn);
                        sv_catpvs(d, " C");
                        fn = po_fmt(mx, f2);          sv_catpvn(d, f2, fn);
                        sv_catpvs(d, ",");
                        fn = po_fmt(py[ai], f2);      sv_catpvn(d, f2, fn);
                        sv_catpvs(d, " ");
                        fn = po_fmt(mx, f2);          sv_catpvn(d, f2, fn);
                        sv_catpvs(d, ",");
                        fn = po_fmt(py[bi], f2);      sv_catpvn(d, f2, fn);
                        sv_catpvs(d, " ");
                        fn = po_fmt(px[bi] - 52, f2); sv_catpvn(d, f2, fn);
                        sv_catpvs(d, ",");
                        fn = po_fmt(py[bi], f2);      sv_catpvn(d, f2, fn);
                        hv_stores(o, "path", d);
                    }
                    x2 = hv_fetchs(eh, "count", 0);
                    if (x2) (void)po_sv_to_u64(aTHX_ *x2, &cv);
                    hv_stores(o, "weight", povw_fixed(aTHX_
                        1 + 4 * ((double)cv / (double)heaviest), 1));
                    {
                        char kb[32];
                        size_t kn = (size_t)my_snprintf(kb, sizeof(kb),
                                                        PO_IVf, (IV)i);
                        hv_stores(o, "back",
                                  newSViv(hv_fetch(back, kb, (I32)kn, 0) ? 1 : 0));
                    }
                    x2 = hv_fetchs(eh, "errors", 0);
                    hv_stores(o, "errors", x2 ? newSVsv(*x2) : newSV(0));
                    hv_stores(o, "state", (x2 && SvTRUE(*x2))
                              ? newSVpvs("error") : newSVpvs("ok"));
                    hv_stores(o, "caller", newSVsv(caller_name));
                    hv_stores(o, "callee", newSVsv(callee_name));
                    /* TWO KEYS, BECAUSE THEY ARE TWO THINGS.
                     *
                     * The table wants "62.6k" and the flow diagram wants
                     * 62577. This used to store only the formatted string
                     * under `count`, which is the same key the store's own
                     * edges use for the number - so the Sankey numified
                     * "62.6k" to 62.6, drew a link a thousandth of its real
                     * width, and labelled it "62 calls, 3121 in error". */
                    {
                        STRLEN cl = 0;
                        SV **c = hv_fetchs(eh, "count", 0);
                        const char *cp = (c && SvOK(*c)) ? SvPV(*c, cl) : "";
                        bn = po_fmt_count(cp, (size_t)cl, b, sizeof(b));
                        hv_stores(o, "count", c ? newSVsv(*c) : newSViv(0));
                    }
                    hv_stores(o, "count_label", newSVpvn(b, bn));
                    {
                        SV *lab = newSVsv(caller_name);
                        sv_catpvs(lab, " to ");
                        sv_catsv(lab, callee_name);
                        sv_catpvs(lab, ", ");
                        sv_catpvn(lab, b, bn);
                        sv_catpvs(lab, " calls");
                        hv_stores(o, "label", lab);
                    }
                    SvREFCNT_dec(caller_name);
                    SvREFCNT_dec(callee_name);
                    av_push(edges_out, newRV_noinc((SV *)o));
                }
                SvREFCNT_dec((SV *)back);
            }

            hv_stores(v, "width",  newSViv((IV)w));
            hv_stores(v, "height", povw_fixed(aTHX_ h, 0));
            x = hv_fetchs(lh, "back_edges", 0);
            hv_stores(v, "back_edges",
                      (x && SvTRUE(*x)) ? newSVsv(*x) : newSViv(0));
        }

        /* HOW MUCH, beside what-calls-what. Edge width carries volume on the
         * map above, which works for two edges and not for eight: a
         * four-pixel stroke against a six-pixel one does not read as three to
         * two. A flow diagram makes the volume the geometry rather than a
         * hint about it.
         *
         * Built from the same deduplicated list the layout saw and the table
         * shows, so all three agree by construction. */
        if (av_len(edges_out) >= 0) {
            SV *fig = NULL, *enc = NULL;
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(sv_2mortal(newRV_inc((SV *)edges_out)));
            PUTBACK;
            n = call_pv("Punk::Observe::Plot::service_flow", G_SCALAR);
            SPAGAIN;
            fig = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;

            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(sv_2mortal(fig ? newSVsv(fig) : newSV(0)));
            PUTBACK;
            n = call_pv("Punk::Observe::Plot::encode", G_SCALAR);
            SPAGAIN;
            enc = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
            if (fig) SvREFCNT_dec(fig);
            if (enc) hv_stores(v, "flow_plot", enc);
        }

    done:
        if (gsv) SvREFCNT_dec(gsv);
        if (lay) SvREFCNT_dec(lay);
        SvREFCNT_dec((SV *)sym);
        SvREFCNT_dec((SV *)names);
        SvREFCNT_dec(from); SvREFCNT_dec(to); SvREFCNT_dec(range);
        Safefree(px); Safefree(py); Safefree(hasp);
        RETVAL = newRV_noinc((SV *)v);
    }
    OUTPUT:
        RETVAL

# The metrics screen.
SV *
povw__page_metrics(SV *class, SV *store, SV *req)
    CODE:
    {
        HV *v = newHV();
        HV *rq = NULL;
        SV **f;
        SV *from = NULL, *to = NULL, *range = NULL, *res = NULL;
        HV *r = NULL;
        const char *q = "";
        STRLEN ql = 0;
        int has_q = 0;
        SSize_t i;

        PERL_UNUSED_VAR(class);
        if (SvROK(req) && SvTYPE(SvRV(req)) == SVt_PVHV) rq = (HV *)SvRV(req);

        hv_stores(v, "heading", newSVpvs("Metrics"));
        hv_stores(v, "title",   newSVpvs("Metrics"));
        hv_stores(v, "series",  newRV_noinc((SV *)newAV()));
        hv_stores(v, "yticks",  newRV_noinc((SV *)newAV()));
        hv_stores(v, "groups",  newRV_noinc((SV *)newAV()));
        hv_stores(v, "width",   newSViv(POVW_CHART_W));
        hv_stores(v, "height",  newSViv(POVW_CHART_H));

        if (rq && (f = hv_fetchs(rq, "q", 0)) && SvOK(*f)) {
            q = SvPV(*f, ql);
            hv_stores(v, "query", newSVsv(*f));
        }
        else hv_stores(v, "query", newSVpvs(""));
        {
            const char *e = (rq && (f = hv_fetchs(rq, "q", 0)) && SvTRUE(*f))
                              ? q : "";
            STRLEN el = (e == q) ? ql : 0;
            char *esc;
            size_t en;
            Newx(esc, el * 3 + 1, char);
            en = po_url_esc(e, (size_t)el, esc, el * 3 + 1);
            hv_stores(v, "query_esc", newSVpvn(esc, en));
            Safefree(esc);
        }

        range = povw_window_range(aTHX_ req, &from, &to);
        hv_stores(v, "from", newSVsv(from));
        hv_stores(v, "to",   newSVsv(to));
        povw_range_vars(aTHX_ v, req, range);

        if (!SvOK(store) || !SvROK(store)) goto done;

        for (i = 0; i < (SSize_t)ql; i++)
            if (!isSPACE((U8)q[i])) { has_q = 1; break; }

        if (!has_q) {
            /* With no query, the page offers what there is. An empty chart
             * and an empty box is a dead end; a list of the metric names the
             * store has seen is the next click.
             *
             * `metric_names` tallies the names during the scan - it used to
             * be a records() call with no limit, which built a Perl hash
             * for up to half a million points to read one field back out of
             * each: the single largest read in the UI, for a list of a few
             * dozen names. */
            HV *seen = newHV();
            AV *out = newAV();
            SV *names_rv = NULL;
            int n;

            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(newSVpvs("from"))); XPUSHs(sv_2mortal(newSVsv(from)));
            XPUSHs(sv_2mortal(newSVpvs("to")));   XPUSHs(sv_2mortal(newSVsv(to)));
            PUTBACK;
            n = call_method("metric_names", G_LIST);
            SPAGAIN;
            {
                SSize_t k;
                for (k = n - 1; k > 0; k--) (void)POPs;
                names_rv = n ? SvREFCNT_inc(POPs) : NULL;
            }
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;

            if (names_rv && SvROK(names_rv)
                && SvTYPE(SvRV(names_rv)) == SVt_PVHV) {
                SvREFCNT_dec((SV *)seen);
                seen = (HV *)SvRV(names_rv);
                (void)SvREFCNT_inc((SV *)seen);
            }
            if (names_rv) SvREFCNT_dec(names_rv);

            {   /* sorted, so the list does not reshuffle between two loads */
                SSize_t nk = 0, k;
                SV **keys;
                HE *he;
                hv_iterinit(seen);
                Newx(keys, HvUSEDKEYS(seen) ? HvUSEDKEYS(seen) : 1, SV *);
                while ((he = hv_iternext(seen)))
                    keys[nk++] = newSVsv(hv_iterkeysv(he));
                for (k = 1; k < nk; k++) {
                    SV *key = keys[k];
                    SSize_t j;
                    STRLEN kl;
                    const char *kp = SvPV(key, kl);
                    for (j = k - 1; j >= 0; j--) {
                        STRLEN jl;
                        const char *jp = SvPV(keys[j], jl);
                        size_t m = jl < kl ? jl : kl;
                        int c = m ? memcmp(jp, kp, m) : 0;
                        if (!c) c = jl == kl ? 0 : (jl < kl ? -1 : 1);
                        if (c <= 0) break;
                        keys[j + 1] = keys[j];
                    }
                    keys[j + 1] = key;
                }
                for (k = 0; k < nk; k++) {
                    HV *o = newHV();
                    STRLEN kl;
                    const char *kp = SvPV(keys[k], kl);
                    SV **c = hv_fetch(seen, kp, (I32)kl, 0);
                    char b[32];
                    STRLEN cl = 0;
                    const char *cp = (c && SvOK(*c)) ? SvPV(*c, cl) : "";
                    size_t bn = po_fmt_count(cp, (size_t)cl, b, sizeof(b));
                    SV *link = newSVpvs("metric ");
                    char *esc;
                    size_t en;

                    sv_catpvn(link, kp, kl);
                    Newx(esc, SvCUR(link) * 3 + 1, char);
                    en = po_url_esc(SvPVX(link), SvCUR(link), esc,
                                    SvCUR(link) * 3 + 1);
                    hv_stores(o, "name",  keys[k]);
                    hv_stores(o, "count", newSVpvn(b, bn));
                    hv_stores(o, "query", newSVpvn(esc, en));
                    Safefree(esc);
                    SvREFCNT_dec(link);
                    av_push(out, newRV_noinc((SV *)o));
                }
                Safefree(keys);
            }
            SvREFCNT_dec((SV *)seen);
            hv_stores(v, "empty", newSViv(av_len(out) >= 0 ? 0 : 1));
            hv_stores(v, "names", newRV_noinc((SV *)out));
            goto done;
        }

        {
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(store);
            XPUSHs(sv_2mortal(newSVpvn(q, ql)));
            XPUSHs(sv_2mortal(newSVpvs("from"))); XPUSHs(sv_2mortal(newSVsv(from)));
            XPUSHs(sv_2mortal(newSVpvs("to")));   XPUSHs(sv_2mortal(newSVsv(to)));
            PUTBACK;
            n = call_method(povw_read_method(aTHX_ store), G_SCALAR);
            SPAGAIN;
            res = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;
        }
        if (!res || !SvROK(res) || SvTYPE(SvRV(res)) != SVt_PVHV) {
            if (res) SvREFCNT_dec(res);
            goto done;
        }
        r = (HV *)SvRV(res);

        f = hv_fetchs(r, "ok", 0);
        if (!f || !SvTRUE(*f)) {
            SV **e  = hv_fetchs(r, "error", 0);
            SV **st = hv_fetchs(r, "stage", 0);
            const char *stage = (st && SvOK(*st)) ? SvPV_nolen(*st) : "";
            hv_stores(v, "error", (e && SvOK(*e)) ? newSVsv(*e)
                      : newSVpvs("that query could not be run"));
            {
                SV **ht = hv_fetchs(r, "hint", 0);
                hv_stores(v, "hint", (ht && SvOK(*ht) && SvCUR(*ht))
                          ? newSVsv(*ht)
                          : strEQ(stage, "parse")
                          ? newSVpvs("Check the stage after the pipe.")
                          : newSVpvs("Narrow the range or add a filter."));
            }
            /* A PLAN refusal is the planner saying no to a query that would
             * have run: it is a different message from a typo, and the page
             * says which one it was. */
            if (strEQ(stage, "plan") && e && SvOK(*e))
                hv_stores(v, "refusal", newSVsv(*e));
            SvREFCNT_dec(res);
            goto done;
        }

        hv_stores(v, "title", newSVpvn(q, ql));
        {
            SV **meta = hv_fetchs(r, "meta", 0);
            HV *mh = (meta && SvROK(*meta) && SvTYPE(SvRV(*meta)) == SVt_PVHV)
                       ? (HV *)SvRV(*meta) : NULL;
            if (mh) {
                povw_set_count(aTHX_ v, "scanned", mh, "scanned_rows");
                f = hv_fetchs(mh, "exact", 0);
                hv_stores(v, "exact", f ? newSVsv(*f) : newSV(0));
            }
            else {
                hv_stores(v, "scanned", newSVpvs("0"));
                hv_stores(v, "exact",   newSV(0));
            }
        }

        {
            SV **sh = hv_fetchs(r, "shape", 0);
            const char *shape = (sh && SvOK(*sh)) ? SvPV_nolen(*sh) : "";

            if (strEQ(shape, "buckets")) {
                /* A BUCKETED ANSWER IS A LINE OVER TIME, and it is the only
                 * kind of aggregate that is. Until `bucket` existed every
                 * aggregate collapsed to one number per group, which is why
                 * this screen drew a chart from raw points and a table from
                 * everything else. */
                int rate = povw_q_rate(q, (size_t)ql);
                SV *args[5];
                SV *enc;
                args[0] = sv_2mortal(newSVsv(res));
                args[1] = sv_2mortal(newSVpvs("zero_fill"));
                /* ONLY A COUNT MAY BE ZERO-FILLED. An absent bucket saw no
                 * rows, which is nought arrivals and an UNDEFINED
                 * percentile. */
                args[2] = sv_2mortal(newSViv(
                    (povw_q_bucket(q, (size_t)ql) || rate) ? 1 : 0));
                args[3] = sv_2mortal(newSVpvs("unit"));
                args[4] = sv_2mortal(rate ? newSVpvs("per second")
                                          : newSVpvs(""));
                enc = povw_plot_encode(aTHX_
                          "Punk::Observe::Plot::timeseries", args, 5);
                if (enc) hv_stores(v, "series_plot", enc);
                {
                    SV **sv = hv_fetchs(r, "series", 0);
                    int any = sv && SvROK(*sv)
                           && SvTYPE(SvRV(*sv)) == SVt_PVAV
                           && av_len((AV *)SvRV(*sv)) >= 0;
                    hv_stores(v, "empty", newSViv(any ? 0 : 1));
                }
                SvREFCNT_dec(res);
                goto done;
            }

            if (!strEQ(shape, "") && !strEQ(shape, "rows")) {
                /* AN AGGREGATE WITH NO TIME DIMENSION IS A BAR PER GROUP.
                 * `p95 by http.route` is one number per route; drawn as a
                 * line it would be a chart lying about having a shape, and
                 * the bar chart says exactly what the answer is. */
                SV **gv = hv_fetchs(r, "groups", 0);
                AV *ga = (gv && SvROK(*gv) && SvTYPE(SvRV(*gv)) == SVt_PVAV)
                           ? (AV *)SvRV(*gv) : newAV();
                AV *out = newAV();
                SV *args[1];
                SV *enc;
                SSize_t j, cnt = av_len(ga) + 1;

                args[0] = sv_2mortal(newRV_inc((SV *)ga));
                enc = povw_plot_encode(aTHX_
                          "Punk::Observe::Plot::bars", args, 1);
                if (enc) hv_stores(v, "groups_plot", enc);

                for (j = 0; j < cnt; j++) {
                    SV **e = av_fetch(ga, j, 0);
                    HV *gh, *o;
                    SV **x;
                    char b[32];
                    STRLEN cl = 0;
                    const char *cp;
                    size_t bn;

                    if (!e || !SvROK(*e)) continue;
                    gh = (HV *)SvRV(*e);
                    o = newHV();
                    x = hv_fetchs(gh, "key", 0);
                    hv_stores(o, "key", (x && SvOK(*x) && SvCUR(*x))
                              ? newSVsv(*x) : newSVpvs("(none)"));
                    x = hv_fetchs(gh, "value", 0);
                    hv_stores(o, "value",
                              povw_fmt_value(aTHX_ x ? (double)SvNV(*x) : 0));
                    x = hv_fetchs(gh, "count", 0);
                    cp = (x && SvOK(*x)) ? SvPV(*x, cl) : "";
                    bn = po_fmt_count(cp, (size_t)cl, b, sizeof(b));
                    hv_stores(o, "count", newSVpvn(b, bn));
                    av_push(out, newRV_noinc((SV *)o));
                }
                hv_stores(v, "groups", newRV_noinc((SV *)out));
                SvREFCNT_dec(res);
                goto done;
            }
        }

        {   /* Raw metric points. Each series is already a line over time - a
             * metric row carries its own instant - so this needs no
             * bucketing. */
            SV **rv = hv_fetchs(r, "rows", 0);
            SV *shaped = NULL;
            int n;

            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(sv_2mortal((rv && SvROK(*rv)) ? newSVsv(*rv)
                              : newRV_noinc((SV *)newAV())));
            XPUSHs(req);
            PUTBACK;
            n = call_pv("Punk::Observe::View::_rows_as_series", G_SCALAR);
            SPAGAIN;
            shaped = n ? SvREFCNT_inc(POPs) : NULL;
            PUTBACK;
            FREETMPS; LEAVE;
            SPAGAIN;

            if (shaped && SvROK(shaped) && SvTYPE(SvRV(shaped)) == SVt_PVHV) {
                HV *sh = (HV *)SvRV(shaped);
                SV **fig = hv_fetchs(sh, "figure", 0);
                SV **leg = hv_fetchs(sh, "legend", 0);

                if (fig && SvTRUE(*fig)) {
                    SV *enc = NULL;
                    ENTER; SAVETMPS; PUSHMARK(SP);
                    XPUSHs(sv_2mortal(newSVsv(*fig)));
                    PUTBACK;
                    n = call_pv("Punk::Observe::Plot::encode", G_SCALAR);
                    SPAGAIN;
                    enc = n ? SvREFCNT_inc(POPs) : NULL;
                    PUTBACK;
                    FREETMPS; LEAVE;
                    SPAGAIN;
                    if (enc) hv_stores(v, "series_plot", enc);
                }
                if (leg) {
                    int any = SvROK(*leg) && SvTYPE(SvRV(*leg)) == SVt_PVAV
                           && av_len((AV *)SvRV(*leg)) >= 0;
                    hv_stores(v, "series", newSVsv(*leg));
                    hv_stores(v, "empty", newSViv(any ? 0 : 1));
                }
            }
            if (shaped) SvREFCNT_dec(shaped);
        }
        {
            SV **meta = hv_fetchs(r, "meta", 0);
            HV *mh = (meta && SvROK(*meta) && SvTYPE(SvRV(*meta)) == SVt_PVHV)
                       ? (HV *)SvRV(*meta) : NULL;
            SV **t = mh ? hv_fetchs(mh, "truncated", 0) : NULL;
            hv_stores(v, "truncated", t ? newSVsv(*t) : newSV(0));
        }
        SvREFCNT_dec(res);

    done:
        SvREFCNT_dec(from); SvREFCNT_dec(to); SvREFCNT_dec(range);
        RETVAL = newRV_noinc((SV *)v);
    }
    OUTPUT:
        RETVAL
