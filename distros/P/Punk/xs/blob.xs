MODULE = Punk        PACKAGE = Punk::Plugin::Blob

PROTOTYPES: DISABLE

# Content-addressed storage for uploads, on Apophis. punk_blob.h holds the
# rules and says why each is what it is - in particular why a deduplication
# hit reads and compares rather than trusting the id.

SV *
new(class)
        SV *class
    CODE:
        RETVAL = sv_bless(newRV_noinc(newSViv(0)),
                          gv_stashpv(SvPV_nolen(class), GV_ADD));
    OUTPUT:
        RETVAL

# register($app, \%opts)
#
# `namespace` is required and is not boilerplate: deduplication crosses
# tenants, and a dedup hit is measurably faster than a write - so an account
# can upload a file, time the response, and learn whether another account
# already holds it. A namespace per tenant makes the ids disjoint. The cost is
# the deduplication between them, which is the application's trade to make and
# the reason there is no default.
void
register(self, app, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *opts
    CODE:
    {
        HV *o = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
                ? (HV *)SvRV(opts) : NULL;
        SV **root = o ? hv_fetchs(o, "root", 0) : NULL;
        SV **ns   = o ? hv_fetchs(o, "namespace", 0) : NULL;
        SV *store, *cache, *argv[4];
        AV *cap;
        int i;
        static const struct { const char *name; XSUBADDR_t body; } H[] = {
            { "blob_put",       pb_put_cb },
            { "blob_send",      pb_send_cb },
            { "blob_exists",    pb_exists_cb },
            { "blob_path",      pb_path_cb },
            { "blob_remove",    pb_remove_cb },
            { "blob_store",     pb_store_cb },
            { "blob_root",      pb_root_cb },
            { "blob_safe_type", pb_safe_type_cb }
        };

        PERL_UNUSED_VAR(self);

        /* Apophis has to be LOADED, and nothing above here has done it.
         *
         * `plugin 'Blob'` skips its require when the class already has a
         * `register` method - and this XS defines one in
         * Punk::Plugin::Blob the moment Punk itself loads, so
         * lib/Punk/Plugin/Blob.pm is never read and its `use Apophis`
         * never runs. Being a prerequisite means Apophis is installed,
         * not that it is in memory.
         *
         * The same is true of every plugin that ships inside this dist and
         * provides `register` from C. Sitemap gets away with it by needing
         * nothing. */
        (void)pk_require_once(aTHX_ "Apophis", TRUE);

        /* Resolve the C ABI here, so a missing or too-old Apophis is a BOOT
         * error naming what to upgrade, rather than a croak out of the first
         * request that happens to touch a blob. There is no Perl fallback:
         * a second implementation of the sharding and the id derivation is
         * exactly what the ABI exists to prevent. */
        (void)punk_ap(aTHX);

        if (!(root && pb_given(aTHX_ *root)))
            croak("Punk::Plugin::Blob: `root` is required - it is where the "
                  "blobs live (plugin 'Blob' => { root => '/var/...' })");
        if (!(ns && pb_given(aTHX_ *ns)))
            croak("Punk::Plugin::Blob: `namespace` is required - "
                  "deduplication crosses tenants, and a namespace per tenant "
                  "is what stops one account learning that another already "
                  "holds a file. See 'Deduplication crosses tenants'");

        /* A CODEREF namespace is one store per tenant, and cannot be built
         * here: it depends on the request. It is built on first use and
         * cached per worker instead - see pb_store_for. */
        if (SvROK(*ns) && SvTYPE(SvRV(*ns)) == SVt_PVCV) {
            store = NULL;
            cache = newRV_noinc((SV *)newHV());
        }
        else {
            argv[0] = sv_2mortal(newSVpvs("namespace"));
            argv[1] = *ns;
            argv[2] = sv_2mortal(newSVpvs("store_dir"));
            argv[3] = *root;
            store = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Apophis")), "new",
                                  argv, 4, 1);
            if (!(store && SvROK(store)))
                croak("Punk::Plugin::Blob: Apophis->new gave back no store");
            sv_2mortal(store);
            cache = newRV_noinc((SV *)newHV());
        }
        sv_2mortal(cache);

        for (i = 0; i < (int)(sizeof H / sizeof H[0]); i++) {
            SV *h[3];
            SV *r;
            cap = newAV();
            av_push(cap, store ? newSVsv(store) : newSV(0));
            av_push(cap, newSVsv(*root));
            av_push(cap, newSVsv(*ns));
            /* ONE cache across every helper, so blob_put and blob_send in the
             * same request reach the same store rather than building two. */
            av_push(cap, newSVsv(cache));
            h[0] = sv_2mortal(newSVpv(H[i].name, 0));
            h[1] = sv_2mortal(punk_closure(aTHX_ H[i].body, cap));
            h[2] = sv_2mortal(newSVpvs("Punk::Plugin::Blob"));
            r = pcx_call_meth(aTHX_ app, "helper", h, 3, 1);
            if (r) SvREFCNT_dec(r);
        }
    }

# sweep($root_or_app, live => sub {...}, %opts) -> (removed, kept)
#
# Nothing unlinks during a request; this is where bytes actually go. The
# refusals come before the work: the callback is called first, and its failure
# or emptiness aborts before a directory is opened.
void
sweep(class, where, ...)
        SV *class
        SV *where
    PPCODE:
    {
        SV *cb = NULL, *root = NULL;
        double grace = 3600.0;
        int dry = 0, allow_empty = 0, i;
        HV *live;
        UV removed = 0, kept = 0;

        PERL_UNUSED_VAR(class);
        for (i = 2; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if      (strEQ(k, "live"))        cb = v;
            else if (strEQ(k, "grace"))       grace = SvOK(v) ? SvNV(v) : 0.0;
            else if (strEQ(k, "dry_run"))     dry = SvTRUE(v) ? 1 : 0;
            else if (strEQ(k, "allow_empty")) allow_empty = SvTRUE(v) ? 1 : 0;
        }
        if (!(cb && SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
            croak("Punk::Plugin::Blob: sweep needs live => sub { ... } "
                  "returning the blob ids still referenced");

        /* an app, or the root itself */
        if (SvROK(where)) root = sv_2mortal(pcx_call_meth(aTHX_ where,
                                                          "blob_root", NULL, 0, 1));
        else root = where;
        if (!(root && SvOK(root) && SvCUR(root)))
            croak("Punk::Plugin::Blob: sweep needs the store root");

        live = pb_live_set(aTHX_ cb, allow_empty);
        sv_2mortal((SV *)live);
        pb_sweep(aTHX_ SvPV_nolen(root), live, grace, dry, &removed, &kept);

        EXTEND(SP, 2);
        mPUSHu(removed);
        mPUSHu(kept);
    }

# The type a blob may be served inline as, or undef. Raster images only; see
# punk_blob.h for why SVG and PDF are not on the list.
SV *
safe_inline_type(class, claimed)
        SV *class
        SV *claimed
    CODE:
    {
        STRLEN l = 0;
        const char *s = SvOK(claimed) ? SvPV_const(claimed, l) : NULL;
        const char *ok = pb_inline_ok(s, l);
        PERL_UNUSED_VAR(class);
        if (!ok) XSRETURN_UNDEF;
        RETVAL = newSVpv(ok, 0);
    }
    OUTPUT:
        RETVAL

# Is this a blob id? The guard between a request and a filesystem path.
IV
_id_ok(class, id)
        SV *class
        SV *id
    CODE:
    {
        STRLEN l = 0;
        const char *s = SvOK(id) ? SvPV_const(id, l) : NULL;
        PERL_UNUSED_VAR(class);
        RETVAL = pb_id_ok(s, l);
    }
    OUTPUT:
        RETVAL

# The store seam the phase-1 tests assert through.
SV *
_store(class, ca, content)
        SV *class
        SV *ca
        SV *content
    CODE:
    {
        PERL_UNUSED_VAR(class);
        if (!(ca && SvROK(ca)))
            croak("Punk::Plugin::Blob: need an Apophis store");
        if (!(content && SvROK(content)))
            croak("Punk::Plugin::Blob: content must be a scalar reference");
        RETVAL = pb_store(aTHX_ ca, content);
    }
    OUTPUT:
        RETVAL
