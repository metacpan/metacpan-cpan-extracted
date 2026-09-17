MODULE = Punk::Observe   PACKAGE = Punk::Observe::Trace   PREFIX = pot_

UV
pot_span_size(...)
    CODE:
        RETVAL = (UV)sizeof(po_span);
    OUTPUT:
        RETVAL


# --- the whole pipeline in one call ----------------------------------------
#
# Add spans, seal (which sorts), index, summarise, graph. Returns everything a
# test needs to assert against, so no intermediate has to be trusted.
void
pot_analyse(SV *specs)
    PPCODE:
        {
            po_span_w w;
            po_traceidx idx;
            po_tsum_set sums;
            po_sgraph g;
            HV *res;

            if (!po_span_w_init(&w)) croak("oom");
            if (!pot_load(aTHX_ specs, &w)) { po_span_w_free(&w); croak("bad specs"); }
            po_span_w_seal(&w);

            if (!po_traceidx_build(&idx, w.s, (uint32_t)w.n)) {
                po_span_w_free(&w); croak("index");
            }
            if (!po_tsum_init(&sums) || !po_tsum_build(&sums, w.s, (uint32_t)w.n)
                || !po_tsum_index(&sums)) {
                po_traceidx_free(&idx); po_span_w_free(&w); croak("summaries");
            }
            if (!po_sgraph_init(&g) || !po_sgraph_build(&g, w.s, (uint32_t)w.n)) {
                po_tsum_free(&sums); po_traceidx_free(&idx);
                po_span_w_free(&w); croak("graph");
            }

            res = newHV();
            hv_stores(res, "spans",   newSVuv((UV)w.n));
            hv_stores(res, "traces",  newSVuv((UV)sums.n));
            hv_stores(res, "slots",   newSVuv((UV)idx.slots));
            hv_stores(res, "clamped", newSVuv((UV)w.clamped));
            hv_stores(res, "any_error", newSViv(w.any_error));
            hv_stores(res, "t_min",   po_u64_to_sv(w.n ? w.t_min : 0));
            hv_stores(res, "t_max",   po_u64_to_sv(w.t_max));
            hv_stores(res, "dur_max", po_u64_to_sv(w.dur_max));

            {   /* summaries, in duration order */
                AV *by = newAV();
                uint32_t i;
                for (i = 0; i < sums.n; i++) {
                    const po_tsummary *t = &sums.t[sums.by_dur[i]];
                    HV *h = newHV();
                    hv_stores(h, "trace_hi", po_u64_to_sv(t->trace_hi));
                    hv_stores(h, "trace_lo", po_u64_to_sv(t->trace_lo));
                    hv_stores(h, "duration", po_u64_to_sv(t->dur_ns));
                    hv_stores(h, "spans",    newSVuv((UV)t->spans));
                    hv_stores(h, "errors",   newSVuv((UV)t->errors));
                    hv_stores(h, "root_service", newSVuv((UV)t->root_service_sym));
                    av_push(by, newRV_noinc((SV *)h));
                }
                hv_stores(res, "by_duration", newRV_noinc((SV *)by));
            }

            {   /* the service graph */
                AV *edges = newAV();
                uint32_t i;
                for (i = 0; i < g.n; i++) {
                    HV *h = newHV();
                    hv_stores(h, "caller", g.e[i].caller == PO_SVC_UNKNOWN
                              ? newSVpvs("*") : newSVuv((UV)g.e[i].caller));
                    hv_stores(h, "callee", newSVuv((UV)g.e[i].callee));
                    hv_stores(h, "count",  po_u64_to_sv(g.e[i].count));
                    hv_stores(h, "errors", po_u64_to_sv(g.e[i].errors));
                    hv_stores(h, "dur_max", po_u64_to_sv(g.e[i].dur_max));
                    av_push(edges, newRV_noinc((SV *)h));
                }
                hv_stores(res, "edges", newRV_noinc((SV *)edges));
            }

            {   /* the assembled tree of the FIRST trace */
                AV *tree = newAV();
                if (w.n) {
                    uint32_t j = 1;
                    po_tree t;
                    while (j < w.n && w.s[j].trace_hi == w.s[0].trace_hi
                                   && w.s[j].trace_lo == w.s[0].trace_lo) j++;
                    if (po_tree_build(&t, w.s, j)) {
                        uint32_t i;
                        for (i = 0; i < t.n; i++) {
                            HV *h = newHV();
                            hv_stores(h, "span_id", po_u64_to_sv(w.s[i].span_id));
                            hv_stores(h, "parent_index", newSViv((IV)t.parent[i]));
                            hv_stores(h, "depth",   newSViv((IV)t.depth[i]));
                            av_push(tree, newRV_noinc((SV *)h));
                        }
                        hv_stores(res, "roots",   newSVuv((UV)t.roots));
                        hv_stores(res, "cycles",  newSVuv((UV)t.cycles));
                        hv_stores(res, "orphans", newSVuv((UV)t.orphans));
                        po_tree_free(&t);
                    }
                }
                hv_stores(res, "tree", newRV_noinc((SV *)tree));
            }

            mXPUSHs(newRV_noinc((SV *)res));
            po_sgraph_free(&g);
            po_tsum_free(&sums);
            po_traceidx_free(&idx);
            po_span_w_free(&w);
        }

# --- the trace-id index, on its own ----------------------------------------

# Insert n traces, then look every one up, plus some absent ones. Reports the
# average probe count, which is the assertion that the table has not
# degenerated into a scan.
void
pot_index_probe(SV *specs, SV *lookups)
    PPCODE:
        {
            po_span_w w;
            po_traceidx idx;
            AV *lk;
            SSize_t i, n;
            uint32_t found = 0, missing = 0;
            AV *hits = newAV();

            if (!po_span_w_init(&w)) croak("oom");
            if (!pot_load(aTHX_ specs, &w)) { po_span_w_free(&w); croak("bad specs"); }
            po_span_w_seal(&w);
            if (!po_traceidx_build(&idx, w.s, (uint32_t)w.n)) {
                po_span_w_free(&w); croak("index");
            }

            if (!SvROK(lookups)) croak("lookups must be an arrayref");
            lk = (AV *)SvRV(lookups);
            n = av_len(lk) + 1;
            for (i = 0; i < n; i += 2) {
                SV **a = av_fetch(lk, i, 0);
                SV **b = av_fetch(lk, i + 1, 0);
                po_u64 hi = 0, lo = 0;
                uint32_t first = 0, count = 0;
                if (!a || !b) break;
                (void)po_sv_to_u64(aTHX_ *a, &hi);
                (void)po_sv_to_u64(aTHX_ *b, &lo);
                if (po_traceidx_get(&idx, hi, lo, &first, &count)) {
                    found++;
                    av_push(hits, newSVuv((UV)count));
                }
                else { missing++; av_push(hits, newSViv(-1)); }
            }

            {
                HV *res = newHV();
                hv_stores(res, "found",   newSVuv((UV)found));
                hv_stores(res, "missing", newSVuv((UV)missing));
                hv_stores(res, "counts",  newRV_noinc((SV *)hits));
                hv_stores(res, "slots",   newSVuv((UV)idx.slots));
                hv_stores(res, "distinct", newSVuv((UV)idx.n));
                hv_stores(res, "probes",  po_u64_to_sv(idx.probes));
                hv_stores(res, "lookups", po_u64_to_sv(idx.lookups));
                mXPUSHs(newRV_noinc((SV *)res));
            }
            po_traceidx_free(&idx);
            po_span_w_free(&w);
        }

# --- duration search --------------------------------------------------------

# Everything at or above `min_dur`, from the ordinal array. Returns the
# ordinal where the range starts, so a test can assert it is a RANGE rather
# than a filtered scan.
void
pot_slower_than(SV *specs, SV *min_dur)
    PPCODE:
        {
            po_span_w w;
            po_tsum_set sums;
            po_u64 want = 0;
            uint32_t lo, i;
            AV *out = newAV();

            (void)po_sv_to_u64(aTHX_ min_dur, &want);
            if (!po_span_w_init(&w)) croak("oom");
            if (!pot_load(aTHX_ specs, &w)) { po_span_w_free(&w); croak("bad specs"); }
            po_span_w_seal(&w);
            if (!po_tsum_init(&sums) || !po_tsum_build(&sums, w.s, (uint32_t)w.n)
                || !po_tsum_index(&sums)) {
                po_span_w_free(&w); croak("summaries");
            }

            lo = po_tsum_lower_bound(&sums, want);
            for (i = lo; i < sums.n; i++)
                av_push(out, po_u64_to_sv(sums.t[sums.by_dur[i]].dur_ns));

            {
                HV *res = newHV();
                hv_stores(res, "durations", newRV_noinc((SV *)out));
                hv_stores(res, "from",      newSVuv((UV)lo));
                hv_stores(res, "total",     newSVuv((UV)sums.n));
                mXPUSHs(newRV_noinc((SV *)res));
            }
            po_tsum_free(&sums);
            po_span_w_free(&w);
        }

# --- segment pruning --------------------------------------------------------

int
pot_seg_may_match(SV *t_min, SV *t_max, SV *dur_max, SV *any_error, \
                  SV *from, SV *to, SV *min_dur, SV *want_error)
    CODE:
        {
            po_seg_trace_stats st;
            po_u64 f = 0, t = 0, md = 0;
            memset(&st, 0, sizeof(st));
            (void)po_sv_to_u64(aTHX_ t_min,   &st.t_min);
            (void)po_sv_to_u64(aTHX_ t_max,   &st.t_max);
            (void)po_sv_to_u64(aTHX_ dur_max, &st.dur_max);
            st.any_error = (int)SvIV(any_error);
            (void)po_sv_to_u64(aTHX_ from, &f);
            (void)po_sv_to_u64(aTHX_ to,   &t);
            (void)po_sv_to_u64(aTHX_ min_dur, &md);
            RETVAL = po_seg_may_match(&st, f, t, md, (int)SvIV(want_error));
        }
    OUTPUT:
        RETVAL
