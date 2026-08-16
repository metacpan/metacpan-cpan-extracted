MODULE = Punk        PACKAGE = Punk::Config

PROTOTYPES: DISABLE

# Punk::Config->load(file => $path, env => $name, secrets => $mode)
#
# Read punk.yml, then punk.$env.yml, then punk.local.yml; merge them;
# resolve every secret reference; build the redacted public copy. All of it
# here, except the YAML parse itself (one YAML::XS call per file).
SV *
load(class, ...)
        SV *class
    CODE:
    {
        punk_config *cfg;
        SV *file = NULL, *env = NULL, *mode_sv = NULL;
        SV *merged = NULL;
        const char *stem, *ext;
        STRLEN flen;
        char layer[2048];
        int i, mode = PC_SECRETS_WARN;

        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            if      (kl == 4 && memEQ(k, "file", 4))    file    = ST(i + 1);
            else if (kl == 3 && memEQ(k, "env", 3))     env     = ST(i + 1);
            else if (kl == 7 && memEQ(k, "secrets", 7)) mode_sv = ST(i + 1);
            else croak("Punk::Config->load: unknown option '%.*s'",
                       (int)kl, k);
        }
        if (!(file && SvOK(file)))
            croak("Punk::Config->load: a file is required");
        if (mode_sv && SvOK(mode_sv)) {
            const char *m = SvPV_nolen(mode_sv);
            mode = strEQ(m, "strict") ? PC_SECRETS_STRICT
                 : strEQ(m, "warn")   ? PC_SECRETS_WARN
                 : strEQ(m, "off")    ? PC_SECRETS_OFF : -1;
            if (mode < 0)
                croak("Punk::Config: secrets must be strict, warn or off "
                      "(not '%s')", m);
        }

        Newxz(cfg, 1, punk_config);
        cfg->mode    = mode;
        cfg->file    = newSVsv(file);
        cfg->secrets = newHV();
        cfg->files   = newAV();
        cfg->env     = (env && SvOK(env)) ? newSVsv(env)
                     : newSVpv(getenv("PUNK_ENV") ? getenv("PUNK_ENV")
                                                  : "production", 0);

        /* config/punk.yml -> punk.yml, punk.<env>.yml, punk.local.yml */
        {
            const char *f = SvPV_const(file, flen);
            const char *dot = NULL;
            STRLEN j;
            for (j = flen; j > 0; j--) {
                if (f[j - 1] == '/') break;
                if (f[j - 1] == '.') { dot = f + j - 1; break; }
            }
            stem = f;
            ext  = dot ? dot : "";
            for (i = 0; i < 3; i++) {
                SV *body, *doc;
                STRLEN stem_len = dot ? (STRLEN)(dot - f) : flen;
                if (i == 0)
                    my_snprintf(layer, sizeof layer, "%.*s%s",
                                (int)stem_len, stem, ext);
                else
                    my_snprintf(layer, sizeof layer, "%.*s.%s%s",
                                (int)stem_len, stem,
                                i == 1 ? SvPV_nolen(cfg->env) : "local", ext);
                body = pc_slurp(aTHX_ layer);
                if (!body) continue;
                av_push(cfg->files, newSVpv(layer, 0));
                doc = pc_yaml_decode(aTHX_ body, layer);
                if (!(SvOK(doc) && SvROK(doc)
                      && SvTYPE(SvRV(doc)) == SVt_PVHV)) {
                    pc_free(aTHX_ cfg);
                    croak("Punk::Config: '%s' is not a YAML mapping", layer);
                }
                merged = merged ? sv_2mortal(pc_merge(aTHX_ merged, doc))
                                : sv_2mortal(newSVsv(doc));
            }
        }
        if (av_len(cfg->files) < 0) {      /* -1: nothing was readable */
            SV *f = sv_2mortal(newSVsv(cfg->file));
            pc_free(aTHX_ cfg);
            croak("Punk::Config: no config file found (looked for '%s')",
                  SvPV_nolen(f));
        }

        {   /* resolve + redact in one walk */
            SV *resolved = NULL;
            SV *public   = pc_walk(aTHX_ cfg, merged,
                                   sv_2mortal(newSVpvs("")), &resolved);
            cfg->public   = (SvROK(public) && SvTYPE(SvRV(public)) == SVt_PVHV)
                          ? (HV *)SvREFCNT_inc(SvRV(public)) : newHV();
            cfg->resolved = (resolved && SvROK(resolved)
                             && SvTYPE(SvRV(resolved)) == SVt_PVHV)
                          ? (HV *)SvREFCNT_inc(SvRV(resolved)) : newHV();
            SvREFCNT_dec(public);
            if (resolved) SvREFCNT_dec(resolved);
        }

        RETVAL = sv_setref_iv(newSV(0), SvPV_nolen(class), PTR2IV(cfg));
    }
    OUTPUT:
        RETVAL

# The public structure: secrets replaced by [redacted].
SV *
config(self)
        SV *self
    ALIAS:
        resolved = 1
    CODE:
    {
        punk_config *cfg = punk_config_of(aTHX_ self);
        HV *hv = ix ? cfg->resolved : cfg->public;
        RETVAL = newRV_inc((SV *)hv);
    }
    OUTPUT:
        RETVAL

SV *
env(self)
        SV *self
    CODE:
        RETVAL = newSVsv(punk_config_of(aTHX_ self)->env);
    OUTPUT:
        RETVAL

SV *
files(self)
        SV *self
    CODE:
    {
        punk_config *cfg = punk_config_of(aTHX_ self);
        AV *out = newAV();
        SSize_t i, n = av_len(cfg->files) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(cfg->files, i, 0);
            av_push(out, newSVsv(e && *e ? *e : &PL_sv_undef));
        }
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# The resolved value at a dotted path - secrets included. What the boot
# consumers read.
SV *
get(self, path)
        SV *self
        SV *path
    CODE:
    {
        punk_config *cfg = punk_config_of(aTHX_ self);
        SV *root = sv_2mortal(newRV_inc((SV *)cfg->resolved));
        STRLEN plen;
        const char *p = SvPV_const(path, plen);
        SV *found = pc_at_path(aTHX_ root, p, plen);
        RETVAL = found ? newSVsv(found) : newSV(0);
    }
    OUTPUT:
        RETVAL

SV *
secret(self, path)
        SV *self
        SV *path
    CODE:
    {
        punk_config *cfg = punk_config_of(aTHX_ self);
        HE *he = hv_fetch_ent(cfg->secrets, path, 0, 0);
        if (!he)
            croak("Punk::Config: no secret at '%s'", SvPV_nolen(path));
        RETVAL = newSVsv(HeVAL(he));
    }
    OUTPUT:
        RETVAL

int
has_secret(self, path)
        SV *self
        SV *path
    CODE:
        RETVAL = hv_exists_ent(punk_config_of(aTHX_ self)->secrets, path, 0)
               ? 1 : 0;
    OUTPUT:
        RETVAL

# The dotted paths of every resolved secret, sorted.
SV *
secret_paths(self)
        SV *self
    CODE:
    {
        punk_config *cfg = punk_config_of(aTHX_ self);
        AV *out = newAV();
        HE *he;
        hv_iterinit(cfg->secrets);
        while ((he = hv_iternext(cfg->secrets)))
            av_push(out, newSVsv(HeSVKEY_force(he)));
        sortsv(AvARRAY(out), (U32)(av_len(out) + 1), Perl_sv_cmp);
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
    {
        if (SvROK(self) && SvIOK(SvRV(self)))
            pc_free(aTHX_ punk_config_of(aTHX_ self));
    }
