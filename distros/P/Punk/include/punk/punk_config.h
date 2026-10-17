/* punk_config.h - configuration: layered YAML, resolved secrets.
 *
 * Boot-time work, in C for the same reason the rest of Punk is: one
 * implementation, one place. YAML parsing itself is the exception - it
 * goes through YAML::XS with a single call per file (the shim Open::API
 * uses), which at once-per-boot costs nothing worth a parser of our own.
 *
 * The rule the design follows: a config file says WHERE a secret comes
 * from, never what it is. A reference is a single-key hash whose key
 * starts with '$' - a shape nothing else in a config has, and one that
 * needs nothing from the parser:
 *
 *     password: { $env: DB_PASSWORD }
 *
 * Resolved values land in `secrets` (dotted path -> value) and in
 * `resolved`; `public` is the same tree with every secret replaced by
 * [redacted], so it can be logged or serialised safely.
 */

#ifndef PUNK_CONFIG_H
#define PUNK_CONFIG_H

typedef struct punk_config {
    HV *public;      /* redacted copy                      */
    HV *resolved;    /* real values                        */
    HV *secrets;     /* dotted path -> resolved value      */
    AV *files;       /* the layers actually read           */
    SV *file;        /* the base path as given             */
    SV *env;         /* environment name                   */
} punk_config;

static punk_config *punk_config_of(pTHX_ SV *self) {
    if (!SvROK(self) || !SvIOK(SvRV(self)))
        croak("Punk::Config: not a config handle");
    return (punk_config *)INT2PTR(void *, SvIV(SvRV(self)));
}

/* ---- YAML ---------------------------------------------------------------- */

/* One document through YAML::XS. The shim localises the boolean class so
 * true/false decode like JSON booleans, the way Open::API does it. */
static SV *pc_yaml_decode(pTHX_ SV *text, const char *path) {
    dSP;
    int count;
    SV *ret;
    static int shim = 0;
    if (!pk_require_once(aTHX_ "YAML::XS", FALSE))
        croak("Punk::Config: reading '%s' needs YAML::XS (not installed)",
              path);
    if (!shim) {
        eval_pv(
            "sub Punk::Config::_yaml_load {"
            "  local $YAML::XS::Boolean ="
            "    eval { require JSON::PP; 1 } ? 'JSON::PP' : $YAML::XS::Boolean;"
            /* a config file is data; an object tag in it must not bless */
            "  local $YAML::XS::LoadBlessed = 0;"
            "  YAML::XS::Load($_[0]);"
            "}", TRUE);
        shim = 1;
    }
    /* Both eval_pv calls above can grow (and so reallocate) the value stack;
     * SP was captured before them, and the push below would write through
     * it. */
    SPAGAIN;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(text);
    PUTBACK;
    count = call_pv("Punk::Config::_yaml_load", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        SV *e = newSVsv(ERRSV);
        PUTBACK; FREETMPS; LEAVE;
        croak("Punk::Config: '%s' is not valid YAML: %s", path,
              SvPV_nolen(sv_2mortal(e)));
    }
    ret = count > 0 ? newSVsv(POPs) : &PL_sv_undef;
    PUTBACK; FREETMPS; LEAVE;
    return sv_2mortal(ret);
}

/* Slurp a file into a mortal SV, or NULL when it cannot be opened. */
static SV *pc_slurp(pTHX_ const char *path) {
    PerlIO *fh = PerlIO_open(path, "rb");
    SV *sv;
    char buf[8192];
    SSize_t n;
    if (!fh) return NULL;
    sv = sv_2mortal(newSVpvs(""));
    while ((n = PerlIO_read(fh, buf, sizeof buf)) > 0)
        sv_catpvn(sv, buf, (STRLEN)n);
    PerlIO_close(fh);
    return sv;
}

/* ---- merge ---------------------------------------------------------------
 * Later layers win. Hashes merge key by key; anything else replaces, so an
 * array in an overlay is a replacement rather than an append. */
/* How deep a document may nest. A YAML alias cycle is unbounded, and the
 * walk below copies subtrees, so an alias bomb is exponential: both end
 * here with a message instead of a stack or the machine. */
#define PC_MAX_DEPTH 64

static SV *pc_merge(pTHX_ SV *base, SV *over, int depth) {
    HV *bh, *oh, *out;
    if (depth > PC_MAX_DEPTH)
        croak("Punk::Config: nested deeper than %d levels (an alias "
              "cycle?)", PC_MAX_DEPTH);
    HE *he;
    if (!(base && SvROK(base) && SvTYPE(SvRV(base)) == SVt_PVHV
          && over && SvROK(over) && SvTYPE(SvRV(over)) == SVt_PVHV))
        return newSVsv(over);
    bh  = (HV *)SvRV(base);
    oh  = (HV *)SvRV(over);
    out = newHV();
    hv_iterinit(bh);
    while ((he = hv_iternext(bh)))
        (void)hv_store_ent(out, HeSVKEY_force(he), newSVsv(HeVAL(he)), 0);
    hv_iterinit(oh);
    while ((he = hv_iternext(oh))) {
        SV *key = HeSVKEY_force(he);
        HE *have = hv_fetch_ent(out, key, 0, 0);
        SV *merged = have ? pc_merge(aTHX_ HeVAL(have), HeVAL(he), depth + 1)
                          : newSVsv(HeVAL(he));
        (void)hv_store_ent(out, key, merged, 0);
    }
    return newRV_noinc((SV *)out);
}

/* ---- secret references ---------------------------------------------------
 * A single-key hash whose key starts with '$'. Returns the key SV (borrowed)
 * or NULL, setting *arg to the value. */
static SV *pc_reference(pTHX_ SV *node, SV **arg) {
    HV *hv;
    HE *he;
    SV *key;
    if (!(node && SvROK(node) && SvTYPE(SvRV(node)) == SVt_PVHV)) return NULL;
    hv = (HV *)SvRV(node);
    if (HvUSEDKEYS(hv) != 1) return NULL;
    hv_iterinit(hv);
    he = hv_iternext(hv);
    if (!he) return NULL;
    key = HeSVKEY_force(he);
    if (SvCUR(key) < 2 || *SvPVX(key) != '$') return NULL;
    *arg = HeVAL(he);
    return key;
}

/* Trim one trailing newline, the way a secret file or a command's output
 * carries one. */
static void pc_chomp(pTHX_ SV *sv) {
    STRLEN len;
    char *p;
    if (!SvOK(sv)) return;
    p = SvPV(sv, len);
    if (len && p[len - 1] == '\n') len--;
    if (len && p[len - 1] == '\r') len--;
    SvCUR_set(sv, len);
    p[len] = '\0';
}

/* Resolve one reference. Returns an owned SV, or croaks - a secret that
 * cannot be fetched must stop the boot, never become an empty password. */
static SV *pc_resolve(pTHX_ SV *key, SV *arg, const char *where) {
    STRLEN klen;
    const char *k = SvPV_const(key, klen);

    if (klen == 4 && memEQ(k, "$env", 4)) {
        STRLEN nlen;
        const char *name = SvPV_const(arg, nlen);
        const char *val  = getenv(name);
        if (!val)
            croak("Punk::Config: %s wants the environment variable '%s', "
                  "which is not set", where, name);
        return newSVpv(val, 0);
    }
    if (klen == 5 && memEQ(k, "$file", 5)) {
        const char *path = SvPV_nolen(arg);
        SV *body = pc_slurp(aTHX_ path);
        SV *out;
        if (!body)
            croak("Punk::Config: %s cannot read '%s': %s", where, path,
                  Strerror(errno));
        out = newSVsv(body);
        pc_chomp(aTHX_ out);
        return out;
    }
    if (klen == 5 && memEQ(k, "$exec", 5)) {
        /* list form runs without a shell; a bare string is one command,
         * which perl hands to the shell when it holds a metacharacter */
        AV *av = (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
               ? (AV *)SvRV(arg) : NULL;
        SV *out;
        dSP; int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        if (av) {
            SSize_t i, n = av_len(av) + 1;
            if (!n) croak("Punk::Config: %s has an empty $exec", where);
            EXTEND(SP, n);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                PUSHs(e && *e ? *e : &PL_sv_undef);
            }
        }
        else XPUSHs(arg);
        PUTBACK;
        count = call_pv("Punk::Config::_exec", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            SV *e = newSVsv(ERRSV);
            PUTBACK; FREETMPS; LEAVE;
            croak("Punk::Config: %s - %s", where,
                  SvPV_nolen(sv_2mortal(e)));
        }
        out = count > 0 ? newSVsv(POPs) : newSVpvs("");
        PUTBACK; FREETMPS; LEAVE;
        pc_chomp(aTHX_ out);
        return out;
    }
    if (klen == 8 && memEQ(k, "$literal", 8))
        return newSVsv(arg);      /* deliberate plaintext, spelled out */

    croak("Punk::Config: %s uses an unknown resolver '%s' "
          "(known: $env, $exec, $file, $literal)", where, k);
    return NULL;   /* not reached */
}

/* ---- the walk ------------------------------------------------------------
 * One pass: resolve references into `resolved` and `secrets`, and build the
 * public copy with each secret replaced by [redacted]. Returns the public
 * node (owned); *resolved_out gets the resolved node (owned). */
static SV *pc_walk(pTHX_ punk_config *cfg, SV *node, SV *path,
                   SV **resolved_out, int depth) {
    SV *arg = NULL;
    SV *key;
    if (depth > PC_MAX_DEPTH)
        croak("Punk::Config: nested deeper than %d levels (an alias "
              "cycle?)", PC_MAX_DEPTH);
    key = pc_reference(aTHX_ node, &arg);

    if (key) {
        const char *where_path = SvCUR(path) ? SvPV_nolen(path) : "(root)";
        SV *where = sv_2mortal(newSVpvf("'%s'", where_path));
        SV *value = pc_resolve(aTHX_ key, arg, SvPV_nolen(where));
        (void)hv_store_ent(cfg->secrets, path, newSVsv(value), 0);
        *resolved_out = value;                 /* the real thing */
        return newSVpvs("[redacted]");         /* what the public copy sees */
    }

    if (node && SvROK(node) && SvTYPE(SvRV(node)) == SVt_PVHV) {
        HV *src = (HV *)SvRV(node);
        HV *pub = newHV(), *res = newHV();
        HE *he;
        hv_iterinit(src);
        while ((he = hv_iternext(src))) {
            SV *k = HeSVKEY_force(he);
            STRLEN klen;
            const char *kp = SvPV_const(k, klen);
            SV *child = SvCUR(path)
                ? sv_2mortal(newSVpvf("%s.%s", SvPV_nolen(path), kp))
                : sv_2mortal(newSVsv(k));
            SV *rnode = NULL;
            SV *pnode;
            pnode = pc_walk(aTHX_ cfg, HeVAL(he), child, &rnode, depth + 1);
            (void)hv_store_ent(pub, k, pnode, 0);
            (void)hv_store_ent(res, k, rnode ? rnode : newSVsv(HeVAL(he)), 0);
        }
        *resolved_out = newRV_noinc((SV *)res);
        return newRV_noinc((SV *)pub);
    }

    if (node && SvROK(node) && SvTYPE(SvRV(node)) == SVt_PVAV) {
        AV *src = (AV *)SvRV(node);
        AV *pub = newAV(), *res = newAV();
        SSize_t i, n = av_len(src) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(src, i, 0);
            SV *child = sv_2mortal(newSVpvf("%s[%" IVdf "]",
                                            SvPV_nolen(path), (IV)i));
            SV *rnode = NULL;
            SV *pnode = pc_walk(aTHX_ cfg, e ? *e : &PL_sv_undef, child,
                                &rnode, depth + 1);
            av_push(pub, pnode);
            av_push(res, rnode ? rnode : newSVsv(e ? *e : &PL_sv_undef));
        }
        *resolved_out = newRV_noinc((SV *)res);
        return newRV_noinc((SV *)pub);
    }

    *resolved_out = newSVsv(node);
    return newSVsv(node);
}

/* ---- dotted-path lookup --------------------------------------------------- */

static SV *pc_at_path(pTHX_ SV *root, const char *path, STRLEN plen) {
    SV *node = root;
    STRLEN start = 0, i;
    for (i = 0; i <= plen; i++) {
        if (i == plen || path[i] == '.') {
            if (!(node && SvROK(node) && SvTYPE(SvRV(node)) == SVt_PVHV))
                return NULL;
            {
                HE *he = hv_fetch_ent((HV *)SvRV(node),
                    sv_2mortal(newSVpvn(path + start, i - start)), 0, 0);
                if (!he) return NULL;
                node = HeVAL(he);
            }
            start = i + 1;
        }
    }
    return node;
}

static void pc_free(pTHX_ punk_config *cfg) {
    if (!cfg) return;
    if (cfg->public)   SvREFCNT_dec((SV *)cfg->public);
    if (cfg->resolved) SvREFCNT_dec((SV *)cfg->resolved);
    if (cfg->secrets)  SvREFCNT_dec((SV *)cfg->secrets);
    if (cfg->files)    SvREFCNT_dec((SV *)cfg->files);
    if (cfg->file)     SvREFCNT_dec(cfg->file);
    if (cfg->env)      SvREFCNT_dec(cfg->env);
    Safefree(cfg);
}

#endif /* PUNK_CONFIG_H */
