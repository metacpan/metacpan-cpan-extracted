MODULE = Punk        PACKAGE = Punk::Mount::Markdown

PROTOTYPES: DISABLE

# Punk::Mount::Markdown->app($dir, \%opts, $prefix) - the PSGI coderef
# serving that directory of markdown as a documentation site. The request
# path itself is punk_md_cb in include/punk/punk_markdown.h; everything
# below runs once, at boot.
#
# lib/Punk/Mount/Markdown.pm is documentation only.
SV *
app(class, dir, opts = NULL, prefix = NULL)
        SV *class
        SV *dir
        SV *opts
        SV *prefix
    CODE:
    {
        const mds_abi *md = punk_mds(aTHX);
        const sg_abi  *sg = NULL;
        AV *cap = newAV();
        HV *ohv;
        AV *rels, *order;
        HV *pages, *docmap;
        Stat_t st;
        /* idx_sv stays NULL without an index so the av_store below makes a
         * fresh undef to own. &PL_sv_undef must never go in: av_store takes
         * over a reference, and the matching decrement when the capture is
         * freed lands on the immortal - fatal before perl 5.20, where
         * immortals are not yet immune to refcount juggling. */
        SV *root, *tmpl_dir = NULL, *idx_sv = NULL;
        SSize_t i, n;
        const char *index_name;
        int want_search;
        void *idx = NULL;

        PERL_UNUSED_VAR(class);

        if (PerlLIO_stat(SvPV_nolen(dir), &st) < 0 || !S_ISDIR(st.st_mode))
            croak("Punk: markdown '%s' is not a directory", SvPV_nolen(dir));

        ohv = (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            ? (HV *)SvRV(opts) : newHV();
        if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            ohv = (HV *)SvRV(newRV_inc((SV *)ohv));   /* borrow, +1 below */

        /* keep the root without a trailing slash, so joining a PATH_INFO
         * (which always starts with one) cannot double it */
        {
            STRLEN dlen;
            const char *p = SvPV_const(dir, dlen);
            while (dlen > 1 && p[dlen - 1] == '/') dlen--;
            root = newSVpvn(p, dlen);
        }

        index_name  = pmd_opt_str(aTHX_ ohv, "index", "index.md");
        want_search = pmd_opt_bool(aTHX_ ohv, "search", 1);

        pages  = newHV();
        order  = newAV();
        docmap = newHV();

        /* The engines, created once here: three Perl calls at boot, so a bad
         * option fails with the rest of the configuration rather than on the
         * first request. */
        {
            SV *argv[1];
            HV *mopts = newHV();
            (void)hv_stores(mopts, "gfm",
                newSViv(pmd_opt_bool(aTHX_ ohv, "gfm", 1)));
            (void)hv_stores(mopts, "highlight",
                newSViv(pmd_opt_bool(aTHX_ ohv, "highlight", 1)));
            (void)hv_stores(mopts, "heading_ids", newSViv(1));
            argv[0] = sv_2mortal(newRV_noinc((SV *)mopts));
            av_store(cap, PMDC_MD,
                pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Markdown::Simple")),
                              "new", argv, 1, 1));
        }
        {
            SV *argv[1];
            HV *sopts = newHV();
            SV *tdir = pmd_opt(aTHX_ ohv, "template_dir");
            if (tdir) tmpl_dir = sv_2mortal(newSVsv(tdir));
            else {
                /* the templates that ship beside lib/Punk/Mount/Markdown.pm,
                 * located the way Open::API::UI locates its own */
                HV *inc = get_hv("INC", 0);
                SV **pm;
                (void)pk_require_once(aTHX_ PK_MOUNT_MD, FALSE);
                inc = get_hv("INC", 0);
                pm = inc ? hv_fetchs(inc, "Punk/Mount/Markdown.pm", 0) : NULL;
                if (!pm || !*pm || !SvOK(*pm))
                    croak("Punk::Mount::Markdown: cannot locate my own "
                          "installation to find the default templates");
                tmpl_dir = sv_2mortal(newSVsv(*pm));
                if (SvCUR(tmpl_dir) > 3)
                    SvCUR_set(tmpl_dir, SvCUR(tmpl_dir) - 3);
                sv_catpvs(tmpl_dir, "/templates");
            }
            (void)hv_stores(sopts, "template_dir", newSVsv(tmpl_dir));
            (void)hv_stores(sopts, "wrapper",
                newSVpv(pmd_opt_str(aTHX_ ohv, "wrapper", "wrapper.tmpl"), 0));
            /* punk_st resolves the ABI but the constructor below is an
             * ordinary method call, so the class has to be loaded too. */
            (void)punk_st(aTHX);
            if (!pk_require_once(aTHX_ "Template::Stencil", FALSE))
                croak("Punk::Mount::Markdown: Template::Stencil failed to "
                      "load: %s", SvPV_nolen(ERRSV));
            argv[0] = sv_2mortal(newRV_noinc((SV *)sopts));
            av_store(cap, PMDC_STENCIL,
                pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Template::Stencil")),
                              "new", argv, 1, 1));
        }
        if (want_search) {
            sg = punk_sg(aTHX);
            idx_sv = pcx_call_meth(aTHX_
                        sv_2mortal(newSVpvs("Search::Trigram")),
                        "new", NULL, 0, 1);
            idx = idx_sv ? sg->index_of(aTHX_ idx_sv) : NULL;
        }

        av_store(cap, PMDC_DIR,    root);
        av_store(cap, PMDC_PAGES,  newRV_noinc((SV *)pages));
        av_store(cap, PMDC_ORDER,  newRV_noinc((SV *)order));
        av_store(cap, PMDC_OPTS,   newRV_inc((SV *)ohv));
        av_store(cap, PMDC_INDEX,  idx_sv ? idx_sv : newSV(0));
        av_store(cap, PMDC_DOCMAP, newRV_noinc((SV *)docmap));
        av_store(cap, PMDC_PREFIX,
            prefix && SvOK(prefix) ? newSVsv(prefix) : newSVpvs(""));

        /* ---- walk, then read every page's metadata ---- */
        rels = (AV *)sv_2mortal((SV *)newAV());
        pmd_walk_dir(aTHX_ SvPV_nolen(root), sv_2mortal(newSVpvs("")), rels,
                     pmd_opt_bool(aTHX_ ohv, "recursive", 1));

        n = av_len(rels) + 1;
        for (i = 0; i < n; i++) {
            SV *rel = *av_fetch(rels, i, 0);
            AV *page = newAV();
            SV *full = sv_2mortal(newSVsv(root));
            SV *src, *title = NULL, *nav = NULL;
            HV *meta = (HV *)sv_2mortal((SV *)newHV());
            STRLEN blen, off;
            const char *bytes;
            SV *v;
            Stat_t pst;

            sv_catpvs(full, "/"); sv_catsv(full, rel);
            src = pmd_slurp(aTHX_ SvPV_nolen(full));
            if (!src) continue;
            bytes = SvPV_const(src, blen);
            off = pmd_front_matter(aTHX_ bytes, blen, meta);

            if ((v = pmd_opt(aTHX_ meta, "draft")) && SvTRUE(v)) continue;

            av_extend(page, PMD__COUNT - 1);
            av_store(page, PMD_URL,  pmd_url_for(aTHX_ rel, index_name));
            av_store(page, PMD_FILE, newSVsv(full));
            av_store(page, PMD_SECTION, pmd_section_for(aTHX_ rel));

            if ((v = pmd_opt(aTHX_ meta, "title"))) title = newSVsv(v);
            if (!title) title = pmd_first_h1(aTHX_ bytes + off, blen - off);
            if (!title) {
                /* the basename, prettified. memrchr is a GNU extension, so
                 * scan back by hand rather than assume it. */
                STRLEN rl, k;
                const char *r = SvPV_const(rel, rl);
                const char *b = r;
                STRLEN bl;
                for (k = rl; k > 0; k--)
                    if (r[k - 1] == '/') { b = r + k; break; }
                bl = rl - (STRLEN)(b - r);
                if (bl > 3) bl -= 3;                  /* drop ".md" */
                title = pmd_title_from_name(aTHX_ b, bl);
            }
            av_store(page, PMD_TITLE, title);

            if ((v = pmd_opt(aTHX_ meta, "nav"))) nav = newSVsv(v);
            av_store(page, PMD_NAV, nav ? nav : newSVsv(title));

            /* An index file is the landing page for whatever it sits in, so
             * it leads its section unless it says otherwise. Without this it
             * would sort last, the front page of a guide arriving underneath
             * the pages it introduces. */
            v = pmd_opt(aTHX_ meta, "order");
            if (v) av_store(page, PMD_ORDER, newSViv(SvIV(v)));
            else {
                STRLEN rl, il = strlen(index_name);
                const char *r = SvPV_const(rel, rl);
                int is_index = rl >= il && memEQ(r + rl - il, index_name, il)
                            && (rl == il || r[rl - il - 1] == '/');
                av_store(page, PMD_ORDER, newSViv(is_index ? IV_MIN : IV_MAX));
            }

            av_store(page, PMD_MTIME,
                newSViv(PerlLIO_stat(SvPV_nolen(full), &pst) == 0
                        ? (IV)pst.st_mtime : 0));

            /* plain text for the index and for snippets */
            {
                SV *plain = newSVpvs("");
                SV *err = NULL;
                (void)md->strip(aTHX_ bytes + off, blen - off, plain, &err);
                av_store(page, PMD_PLAIN, plain);
                if (idx) {
                    SV *doc = sv_2mortal(newSVsv(*av_fetch(page, PMD_TITLE, 0)));
                    uint32_t id;
                    sv_catpvs(doc, "\n");
                    sv_catsv(doc, plain);
                    id = sg->add(idx, SvPVX(doc), (uint32_t)SvCUR(doc));
                    av_store(page, PMD_DOCID, newSVuv(id));
                    (void)hv_store_ent(docmap, sv_2mortal(newSVuv(id)),
                                       newSVsv(*av_fetch(page, PMD_URL, 0)), 0);
                }
                else av_store(page, PMD_DOCID, newSViv(-1));
            }
            av_store(page, PMD_BODY, newSVpvs(""));

            (void)hv_store_ent(pages, *av_fetch(page, PMD_URL, 0),
                               newRV_noinc((SV *)page), 0);
            av_push(order, newSVsv(*av_fetch(page, PMD_URL, 0)));
        }
        if (idx) sg->optimize(idx);

        /* ---- order the nav ---- */
        {
            const char *how = pmd_opt_str(aTHX_ ohv, "sort", "order");
            /* `order` groups by section then honours front-matter order:,
             * falling back to the title. `alpha` is the walk order, which is
             * already sorted by path. Both keep a section's pages together,
             * which is what a sidebar needs. */
            if (strEQ(how, "order")) {
                AV *sorted = newAV();
                SSize_t j, m = av_len(order) + 1;
                SSize_t placed = 0;
                while (placed < m) {
                    SSize_t best = -1;
                    for (j = 0; j < m; j++) {
                        SV **u = av_fetch(order, j, 0);
                        HE *he;
                        AV *pg, *bp;
                        if (!u || !*u || !SvOK(*u)) continue;
                        he = hv_fetch_ent(pages, *u, 0, 0);
                        if (!he || !HeVAL(he)) continue;
                        pg = (AV *)SvRV(HeVAL(he));
                        if (best < 0) { best = j; continue; }
                        {
                            SV **b = av_fetch(order, best, 0);
                            HE *bhe = hv_fetch_ent(pages, *b, 0, 0);
                            int c;
                            bp = (AV *)SvRV(HeVAL(bhe));
                            c = sv_cmp(*av_fetch(pg, PMD_SECTION, 0),
                                       *av_fetch(bp, PMD_SECTION, 0));
                            if (c < 0) { best = j; continue; }
                            if (c > 0) continue;
                            if (SvIV(*av_fetch(pg, PMD_ORDER, 0)) <
                                SvIV(*av_fetch(bp, PMD_ORDER, 0)))
                                best = j;
                        }
                    }
                    if (best < 0) break;
                    av_push(sorted, newSVsv(*av_fetch(order, best, 0)));
                    av_store(order, best, newSV(0));
                    placed++;
                }
                av_clear(order);
                for (j = 0; j <= av_len(sorted); j++)
                    av_push(order, newSVsv(*av_fetch(sorted, j, 0)));
                SvREFCNT_dec((SV *)sorted);
            }
        }

        /* ---- the shipped stylesheet, read once ----
         * Slurped rather than rendered: CSS is full of braces and has no
         * business going through a template engine. It lives beside the
         * templates so that a template_dir override carries its own
         * stylesheet, which is what a caller replacing the shell wants. */
        {
            SV *cssfile = sv_2mortal(newSVsv(tmpl_dir));
            SV *css;
            sv_catpvs(cssfile, "/app.css");
            css = pmd_slurp(aTHX_ SvPV_nolen(cssfile));
            av_store(cap, PMDC_CSS, css ? newSVsv(css) : newSVpvs(""));
        }

        /* ---- render every page, and the 404 ---- */
        av_store(cap, PMDC_NOTFOUND, newSVpvs(""));
        n = av_len(order) + 1;
        for (i = 0; i < n; i++) {
            HE *he = hv_fetch_ent(pages, *av_fetch(order, i, 0), 0, 0);
            if (he && HeVAL(he) && SvROK(HeVAL(he)))
                pmd_render_page(aTHX_ cap, (AV *)SvRV(HeVAL(he)));
        }
        {
            SV *nav = sv_2mortal(pmd_nav_html(aTHX_ order, pages,
                        *av_fetch(cap, PMDC_PREFIX, 0),
                        sv_2mortal(newSVpvs("\x01none"))));
            SV *body = pmd_shell(aTHX_ cap, "notfound",
                        sv_2mortal(newSVpvs("Not Found")), nav,
                        sv_2mortal(newSVpvs(
                            "<h1>Not Found</h1>\n<p>There is no page at "
                            "this address.</p>\n")),
                        NULL, sv_2mortal(newSVpvs("")));
            av_store(cap, PMDC_NOTFOUND, body);
        }

        RETVAL = punk_closure(aTHX_ punk_md_cb, cap);
    }
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk

# Whether the Markdown::Simple / Search::Trigram C ABIs resolved, for
# `punk doctor`. Not part of the public Perl API.
IV
_mds_available()
    CODE:
        RETVAL = punk_mds_try(aTHX) ? 1 : 0;
    OUTPUT:
        RETVAL

IV
_mds_abi_version()
    CODE:
        RETVAL = MDS_ABI_VERSION;
    OUTPUT:
        RETVAL

IV
_sg_available()
    CODE:
        RETVAL = punk_sg_try(aTHX) ? 1 : 0;
    OUTPUT:
        RETVAL

IV
_sg_abi_version()
    CODE:
        RETVAL = SG_ABI_VERSION;
    OUTPUT:
        RETVAL
