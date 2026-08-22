MODULE = Punk        PACKAGE = Punk::Plugin::I18n

PROTOTYPES: DISABLE

# Translations and language negotiation. punk_i18n.h holds the catalogue and
# says why it is bytes rather than SVs; punk_lang.h holds the negotiation and
# says why punk_accept.h could not be reused whole.

# _build($app, \%catalogues, \%opts)
#
# The catalogues arrive DECODED, from register in the .pm - see punk_i18n.h
# for why the directory walk and the JSON parse are Perl's job and the arena
# is C's.
#
# Called at boot, in the parent: the arena is read-only at request time, so
# building it before the fork shares it across every worker.
void
_build(self, app, cats, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *cats
        SV *opts
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        HV *cfg = newHV();
        HV *o = NULL;
        SV **dir, **def, **param, **cookie;
        const char *defp = NULL;
        STRLEN defl = 0;
        pi_arena *ar;

        PERL_UNUSED_VAR(self);

        if (SvOK(opts)) {
            if (!(SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV))
                croak("Punk::Plugin::I18n: options must be a hashref");
            o = (HV *)SvRV(opts);
        }
        if (!(SvROK(cats) && SvTYPE(SvRV(cats)) == SVt_PVHV))
            croak("Punk::Plugin::I18n: catalogues must be a hashref");

        dir    = o ? hv_fetchs(o, "dir", 0)     : NULL;
        def    = o ? hv_fetchs(o, "default", 0) : NULL;
        param  = o ? hv_fetchs(o, "param", 0)   : NULL;
        cookie = o ? hv_fetchs(o, "cookie", 0)  : NULL;

        if (!(def && *def && SvOK(*def) && SvCUR(*def)))
            croak("Punk::Plugin::I18n: `default` is required - it is the "
                  "answer when negotiation finds nothing, and an application "
                  "with no answer to that renders empty pages");

        defp = SvPV_const(*def, defl);
        ar = pi_arena_build(aTHX_ (HV *)SvRV(cats), defp, defl);

        (void)hv_stores(cfg, "dir",
            (dir && *dir && SvOK(*dir)) ? newSVsv(*dir) : newSVpvs(""));
        (void)hv_stores(cfg, "default", newSVsv(*def));
        (void)hv_stores(cfg, "param",
            (param && *param && SvOK(*param)) ? newSVsv(*param)
                                              : newSVpvs("lang"));
        (void)hv_stores(cfg, "cookie",
            (cookie && *cookie && SvOK(*cookie)) ? newSVsv(*cookie)
                                                 : newSVpvs("punk.lang"));
        /* The arena as an integer, because it is a C pointer and the only
         * thing Perl should ever do with it is hand it back. */
        (void)hv_stores(cfg, "_arena", newSViv(PTR2IV(ar)));
        (void)hv_stores(h, K_I18N, newRV_noinc((SV *)cfg));

        {   /* $c->locale($key, %substitutions), and $c->locale for the tag. */
            CV *cv = get_cv("Punk::Plugin::I18n::_locale", 0);
            if (cv) {
                SV *argv[2];
                SV *r;
                argv[0] = sv_2mortal(newSVpvs("locale"));
                argv[1] = sv_2mortal(newRV_inc((SV *)cv));
                r = pcx_call_meth(aTHX_ app, "helper", argv, 2, 1);
                if (r) SvREFCNT_dec(r);
            }
        }
    }

# $c->locale              - the negotiated tag, e.g. 'en-GB'
# $c->locale($key)        - the translation
# $c->locale($key, %subs) - interpolated
#
# Resolved ONCE per request and kept in the env, not in a C static: Punk
# dispatches asynchronously, so a worker can have several requests in flight
# and a "current locale" in a static would hand one request's language to
# another - invisibly, and only under load.
SV *
_locale(c, ...)
        SV *c
    CODE:
    {
        HV *cfg = pi_cfg_of(aTHX_ c);
        pi_arena *ar = pi_arena_of(aTHX_ cfg);
        const pi_cat *cat;
        RETVAL = NULL;

        if (!ar) croak("Punk::Plugin::I18n: the plugin is not registered on "
                       "this application");
        cat = pi_for_request(aTHX_ c, cfg, ar);
        if (!cat) XSRETURN_UNDEF;

        if (items < 2) {                      /* the tag itself */
            RETVAL = newSVpvn(cat->tag, cat->taglen);
        }
        else {
            STRLEN kl;
            const char *k = SvPV_const(ST(1), kl);
            STRLEN vl = 0;
            const char *v = NULL;
            char pkey[PI_KEY_MAX + 1];
            int r;
            int j;

            /* `count => N` selects a plural category, so `items` reaches
             * `items.few` under a rule that has one. The count stays in the
             * substitutions as well, because the string it chose almost
             * always interpolates it: "{count} produkty". */
            for (j = 2; j + 1 < items; j += 2) {
                STRLEN nl;
                const char *nm = SvPV_const(ST(j), nl);
                if (nl != 5 || memcmp(nm, "count", 5) != 0) continue;
                {
                    SV *cv = ST(j + 1);
                    NV nv = SvOK(cv) ? SvNV(cv) : 0;
                    int is_int = 1;

                    /* CLDR's `v` is the number of VISIBLE fraction digits,
                     * which is a property of how the count was written and
                     * not of its value: "1.0" has v = 1 and takes English's
                     * `other` - "1.0 items" - where 1 takes `one`. So the
                     * string form decides when there is one, and the numeric
                     * value only when there is not. */
                    if (SvPOK(cv)) {
                        STRLEN sl;
                        const char *sp = SvPV_const(cv, sl);
                        STRLEN z;
                        for (z = 0; z < sl; z++)
                            if (sp[z] == '.') { is_int = 0; break; }
                    }
                    if (is_int && nv != (NV)(IV)nv) is_int = 0;
                    pi_rule rule = pi_rule_for(cat->tag, cat->taglen);
                    pi_pcat pc;
                    const char *cn;
                    STRLEN cnl, want;

                    if (rule == PR_NONE) break;   /* checked at boot */
                    pc  = pi_plural(rule, (double)nv, is_int);
                    cn  = PI_CAT_NAME[pc];
                    cnl = strlen(cn);
                    if (kl + 1 + cnl > PI_KEY_MAX) break;

                    memcpy(pkey, k, kl);
                    pkey[kl] = '.';
                    memcpy(pkey + kl + 1, cn, cnl);
                    want = kl + 1 + cnl;

                    if (pi_get(cat, pkey, want, &vl)) {
                        k = pkey; kl = want;
                    }
                    else {
                        /* `other` is the category every rule can reach and
                         * the one a catalogue must carry. A category the
                         * translator did not write falls back to it rather
                         * than to the key. */
                        memcpy(pkey + kl + 1, "other", 5);
                        want = kl + 1 + 5;
                        if (pi_get(cat, pkey, want, &vl)) { k = pkey; kl = want; }
                    }
                }
                break;
            }

            /* The same lookup the template hash uses - the counters and the
             * warning live in there, so the two paths cannot disagree about
             * what is missing. */
            r = pi_lookup(aTHX_ ar, cat, k, kl, &v, &vl);

            if (r != PI_HIT) {
                /* The KEY, never the empty string. An empty gap hides the
                 * omission until a user finds it; the key is visible in the
                 * page and greppable in the logs.
                 *
                 * A LEVEL asked for as a string is the same answer: there is
                 * no translation at `items`, only below it. */
                if (r == PI_MISSING && pi_dev(aTHX_ cfg))
                    pi_warn_missing(aTHX_ c, k, kl);
                RETVAL = newSVpvn(k, kl);
            }
            else if (items > 2) {
                RETVAL = pi_interpolate(aTHX_ v, vl, &ST(2), items - 2);
            }
            else RETVAL = newSVpvn(v, vl);
            SvUTF8_on(RETVAL);
        }
    }
    OUTPUT:
        RETVAL

# What this process has seen.
#
# `untranslated` is separate from `missing` on purpose: one is a bug and the
# other is a translation that has not been written yet, and an application
# that cannot tell them apart cannot measure its own coverage.
#
# `warned` makes "it did not warn in production" a number. Asserting on the
# ABSENCE of a warning also passes when the warning is broken.
void
stats(class = &PL_sv_undef)
        SV *class
    PPCODE:
    {
        PERL_UNUSED_VAR(class);
        EXTEND(SP, 6);
        mPUSHs(newSVpvs("missing"));      mPUSHu(pi_n_missing);
        mPUSHs(newSVpvs("untranslated")); mPUSHu(pi_n_untranslated);
        mPUSHs(newSVpvs("warned"));       mPUSHu(pi_n_warned);
        XSRETURN(6);
    }

# The counters and the warned-about set, for tests that need a clean slate.
void
_reset(class = &PL_sv_undef)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        pi_n_missing = pi_n_untranslated = pi_n_warned = 0;
        if (pi_seen) { SvREFCNT_dec((SV *)pi_seen); pi_seen = NULL; }

MODULE = Punk        PACKAGE = Punk::Plugin::I18n::Cat

PROTOTYPES: DISABLE

# The tied hash behind `{% locale.welcome %}`. punk_i18n.h says why it is tied
# rather than built, and what it needed from Template::Stencil 0.10.
#
# FETCH is almost the whole class: a template only ever reads.

SV *
FETCH(self, key)
        SV *self
        SV *key
    CODE:
    {
        AV *o = (AV *)SvRV(self);
        SV **arsv = av_fetch(o, PIT_ARENA, 0);
        SV **idxs = av_fetch(o, PIT_CAT, 0);
        SV **pfx  = av_fetch(o, PIT_PREFIX, 0);
        SV **cfgs = av_fetch(o, PIT_CFG, 0);
        SV **ctx  = av_fetch(o, PIT_CTX, 0);
        pi_arena *ar = (arsv && *arsv) ? INT2PTR(pi_arena *, SvIV(*arsv)) : NULL;
        int idx = (idxs && *idxs) ? (int)SvIV(*idxs) : -1;
        HV *cfg = (cfgs && *cfgs && SvROK(*cfgs)) ? (HV *)SvRV(*cfgs) : NULL;
        SV *c   = (ctx && *ctx) ? *ctx : NULL;
        const pi_cat *cat;
        SV *full;
        STRLEN kl, fl;
        const char *k, *vp = NULL, *fp;
        STRLEN vl = 0;
        int r;

        if (!ar || idx < 0 || idx >= ar->ncat) XSRETURN_UNDEF;
        cat = &ar->cat[idx];

        /* The path so far, joined with a dot - the same flat key the arena
         * was loaded with, so a nested catalogue and a dotted key are one
         * thing to look up. */
        k = SvPV_const(key, kl);
        if (pfx && *pfx && SvOK(*pfx)) {
            full = sv_2mortal(newSVsv(*pfx));
            sv_catpvs(full, ".");
            sv_catpvn(full, k, kl);
        }
        else full = sv_2mortal(newSVpvn(k, kl));

        fp = SvPV_const(full, fl);
        r = pi_lookup(aTHX_ ar, cat, fp, fl, &vp, &vl);

        if (r == PI_HIT) {
            RETVAL = newSVpvn(vp, vl);
            SvUTF8_on(RETVAL);
        }
        else if (r == PI_LEVEL) {
            /* Descend. `items` in a catalogue holding `items.one` is not a
             * translation and not missing - it is a level, and the template
             * is part way down a path. */
            RETVAL = pi_tied_hash(aTHX_ ar, idx, full, cfg, c);
        }
        else {
            /* The KEY, exactly as the handler path renders it. A template
             * resolves a missing path to the empty string, and an omission
             * that is visible in a handler and invisible in a template is
             * the worse half to lose - which is the whole reason this hash
             * is tied. */
            if (cfg && pi_dev(aTHX_ cfg) && c && SvOK(c))
                pi_warn_missing(aTHX_ c, fp, fl);
            RETVAL = newSVpvn(fp, fl);
        }
    }
    OUTPUT:
        RETVAL

# A template asking whether a key is there, without building its value.
bool
EXISTS(self, key)
        SV *self
        SV *key
    CODE:
    {
        AV *o = (AV *)SvRV(self);
        SV **arsv = av_fetch(o, PIT_ARENA, 0);
        SV **idxs = av_fetch(o, PIT_CAT, 0);
        SV **pfx  = av_fetch(o, PIT_PREFIX, 0);
        pi_arena *ar = (arsv && *arsv) ? INT2PTR(pi_arena *, SvIV(*arsv)) : NULL;
        int idx = (idxs && *idxs) ? (int)SvIV(*idxs) : -1;
        STRLEN kl, fl;
        const char *k;
        SV *full;

        if (!ar || idx < 0 || idx >= ar->ncat) XSRETURN_NO;
        k = SvPV_const(key, kl);
        if (pfx && *pfx && SvOK(*pfx)) {
            full = sv_2mortal(newSVsv(*pfx));
            sv_catpvs(full, ".");
            sv_catpvn(full, k, kl);
        }
        else full = sv_2mortal(newSVpvn(k, kl));
        {
            const char *fp = SvPV_const(full, fl);
            const pi_cat *cat = &ar->cat[idx];
            STRLEN vl;
            RETVAL = (pi_get(cat, fp, fl, &vl) != NULL)
                  || pi_is_prefix(cat, fp, fl);
        }
    }
    OUTPUT:
        RETVAL

# A catalogue is read-only at request time. Saying so beats letting a template
# write into one and wonder why it did not stick.
void
STORE(self, key, value)
        SV *self
        SV *key
        SV *value
    CODE:
        PERL_UNUSED_VAR(self); PERL_UNUSED_VAR(key); PERL_UNUSED_VAR(value);
        croak("Punk::Plugin::I18n: the locale hash is read-only - a "
              "catalogue is loaded at boot and shared across the pool, so a "
              "write here would either be lost or be one worker's private "
              "copy of a translation");

void
DELETE(self, key)
        SV *self
        SV *key
    CODE:
        PERL_UNUSED_VAR(self); PERL_UNUSED_VAR(key);
        croak("Punk::Plugin::I18n: the locale hash is read-only");

MODULE = Punk        PACKAGE = Punk::Plugin::I18n

# ---- the seams the tests need ---------------------------------------------
#
# Negotiation is a table, and a table is worth testing directly rather than
# through twenty forked servers. These take the header and the catalogue tags
# and answer the same question the request path asks.

# _interpolate($string, %substitutions) -> the string with {name} filled in
SV *
_interpolate(class, str, ...)
        SV *class
        SV *str
    CODE:
    {
        STRLEN vl;
        const char *v;
        PERL_UNUSED_VAR(class);
        v = SvPV_const(str, vl);
        RETVAL = pi_interpolate(aTHX_ v, vl, &ST(2), items - 2);
    }
    OUTPUT:
        RETVAL

# _negotiate($header, \@catalogue_tags) -> the chosen tag, or undef
SV *
_negotiate(class, header, tags)
        SV *class
        SV *header
        SV *tags
    CODE:
    {
        pi_arena ar;
        AV *av;
        int i, n, pick;
        STRLEN hl;
        const char *hp;

        PERL_UNUSED_VAR(class);
        if (!(SvROK(tags) && SvTYPE(SvRV(tags)) == SVt_PVAV))
            croak("Punk::Plugin::I18n::_negotiate: tags must be an arrayref");
        av = (AV *)SvRV(tags);
        n = (int)(av_len(av) + 1);

        Zero(&ar, 1, pi_arena);
        ar.def = -1;
        if (n) Newxz(ar.cat, n, pi_cat);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            STRLEN tl;
            const char *tp = (e && *e) ? SvPV_const(*e, tl) : NULL;
            STRLEN j;
            if (!tp || tl > PI_TAG_MAX) continue;
            for (j = 0; j < tl; j++) ar.cat[ar.ncat].tag[j] = pi_fold(tp[j]);
            ar.cat[ar.ncat].tag[tl] = '\0';
            ar.cat[ar.ncat].taglen  = tl;
            ar.ncat++;
        }

        hp = SvOK(header) ? SvPV_const(header, hl) : NULL;
        if (!hp) hl = 0;
        pick = pl_negotiate(hp, hl, &ar);
        RETVAL = (pick >= 0)
               ? newSVpvn(ar.cat[pick].tag, ar.cat[pick].taglen)
               : newSV(0);
        Safefree(ar.cat);
    }
    OUTPUT:
        RETVAL
