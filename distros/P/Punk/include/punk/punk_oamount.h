/* punk_oamount.h - the `api` mount, in C.
 *
 * One `api` mount is an OpenAPI document compiled by Open::API and dispatched
 * to controller methods named after its operationIds. The request half was
 * already C (punk_dispatch.h, over Open::API's oa_abi table); this is the boot
 * half - controller discovery, the security-requirements-to-guards compiler,
 * the per-spec-prefix guards, and the operation table they all fold into.
 *
 * It is boot-time work, so the win is not speed: it is that the mount no
 * longer straddles two languages. The generated security guards used to be
 * Perl closures built by a Perl compiler and then called from the C
 * dispatcher; now they are magic CVs (punk_static.h's closure pattern)
 * carrying their alternatives, so the whole path from route to controller is
 * C calling the checkers the application registered.
 *
 * Two things still cross into Perl at boot, because the ABI has no C form for
 * them: $api->operations and $api->spec. Both are single calls per mount.
 *
 * Must be included after punk_context.h (pcx_call_meth), punk_dispatch.h
 * (punk_oa, the oa_abi table) and punk_static.h (punk_closure).
 */

#ifndef PUNK_OAMOUNT_H
#define PUNK_OAMOUNT_H

/* The 401 body. Its Content-Length is taken from the string rather than
 * written out beside it: the two had drifted, and a length two bytes short
 * truncated the JSON on the wire - a parse error for every client refused. */
#define POA_UNAUTHORIZED "{\"errors\":[{\"message\":\"unauthorized\"}]}"

static HV *poa_hv(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Punk::Mount::OpenAPI: not a mount object");
    return (HV *)SvRV(self);
}

static SV *poa_get(pTHX_ HV *h, const char *k) {
    SV **e = hv_fetch(h, k, (I32)strlen(k), 0);
    return (e && *e) ? *e : NULL;
}

static HV *poa_hash_of(pTHX_ SV *v) {
    return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) ? (HV *)SvRV(v) : NULL;
}
static AV *poa_av_of(pTHX_ SV *v) {
    return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) ? (AV *)SvRV(v) : NULL;
}

/* $resolve->($target, $what) - the boot-time target resolver Punk::App hands
 * every subsystem. Returns the coderef (+1). */
static SV *poa_resolve(pTHX_ SV *resolve, SV *target, const char *what) {
    dSP; SV *r; int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 2);
    PUSHs(target);
    mPUSHp(what, strlen(what));
    PUTBACK;
    count = call_sv(resolve, G_SCALAR);
    SPAGAIN;
    r = count > 0 ? SvREFCNT_inc(POPs) : NULL;
    PUTBACK; FREETMPS; LEAVE;
    if (!r) croak("Punk: %s did not resolve", what);
    return r;
}

/* $code->(@args) in scalar context. No G_EVAL: a checker that dies should
 * propagate to the guard chain's own eval, exactly as the Perl did. +1. */
static SV *poa_call_args(pTHX_ SV *code, SV **argv, int n) {
    dSP; SV *r; int count, i;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, n);
    for (i = 0; i < n; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_sv(code, G_SCALAR);
    SPAGAIN;
    r = count > 0 ? SvREFCNT_inc(POPs) : NULL;
    PUTBACK; FREETMPS; LEAVE;
    return r;
}

/* ---- base64 (HTTP Basic credentials) --------------------------------------
 * Decode only, and standard alphabet: the url-safe spelling never appears in
 * an Authorization header. Returns NULL when the input is not base64. */
static SV *poa_b64_decode(pTHX_ const char *s, STRLEN len) {
    SV *out = newSV(len + 1);
    char *d;
    unsigned v = 0;
    int bits = 0;
    STRLEN i;
    SvPOK_on(out);
    d = SvPVX(out);
    for (i = 0; i < len; i++) {
        char c = s[i];
        int x;
        if (c == '=') break;
        if      (c >= 'A' && c <= 'Z') x = c - 'A';
        else if (c >= 'a' && c <= 'z') x = c - 'a' + 26;
        else if (c >= '0' && c <= '9') x = c - '0' + 52;
        else if (c == '+') x = 62;
        else if (c == '/') x = 63;
        else if (c == '\n' || c == '\r') continue;
        else { SvREFCNT_dec(out); return NULL; }
        v = (v << 6) | (unsigned)x;
        bits += 6;
        if (bits >= 8) { bits -= 8; *d++ = (char)((v >> bits) & 0xFF); }
    }
    *d = '\0';
    SvCUR_set(out, (STRLEN)(d - SvPVX(out)));
    return out;
}

/* case-insensitive "<prefix> " at the front; returns the rest, or NULL.
 * Mirrors /\A<prefix> (.+)\z/i - so the remainder must be non-empty and, since
 * '.' does not match a newline, must not contain one. */
static const char *poa_auth_param(const char *s, STRLEN len,
                                  const char *word, STRLEN wlen,
                                  STRLEN *out_len) {
    STRLEN i;
    if (len <= wlen + 1) return NULL;
    for (i = 0; i < wlen; i++)
        if (toLOWER((U8)s[i]) != toLOWER((U8)word[i])) return NULL;
    if (s[wlen] != ' ') return NULL;
    for (i = wlen + 1; i < len; i++)
        if (s[i] == '\n') return NULL;
    *out_len = len - wlen - 1;
    return s + wlen + 1;
}

/* The credential a securityScheme describes, pulled off the request the way
 * the scheme says to. Mortal, or NULL. */
static SV *poa_credential(pTHX_ SV *c, HV *def) {
    SV *type = poa_get(aTHX_ def, "type");
    SV *req  = pcx_call_meth(aTHX_ c, "req", NULL, 0, 1);
    SV *out  = NULL;
    STRLEN tl = 0;
    const char *t = (type && SvOK(type)) ? SvPV_const(type, tl) : "";

    if (!req) return NULL;
    sv_2mortal(req);

    if (tl == 6 && memEQ(t, "apiKey", 6)) {
        SV *in   = poa_get(aTHX_ def, "in");
        SV *name = poa_get(aTHX_ def, "name");
        STRLEN il = 0;
        const char *ins = (in && SvOK(in)) ? SvPV_const(in, il) : "header";
        if (!(in && SvOK(in))) il = 6;
        if (!name) return NULL;
        if (il == 6 && memEQ(ins, "header", 6)) {
            SV *argv[1]; argv[0] = name;
            out = pcx_call_meth(aTHX_ req, "header", argv, 1, 1);
        }
        else if (il == 5 && memEQ(ins, "query", 5)) {
            SV *q = pcx_call_meth(aTHX_ req, "query", NULL, 0, 1);
            HV *qh = poa_hash_of(aTHX_ q);
            if (qh) {
                HE *he = hv_fetch_ent(qh, name, 0, 0);
                if (he) out = newSVsv(HeVAL(he));
            }
            if (q) SvREFCNT_dec(q);
        }
        else if (il == 6 && memEQ(ins, "cookie", 6)) {
            SV *argv[1]; argv[0] = name;
            out = pcx_call_meth(aTHX_ req, "cookie", argv, 1, 1);
        }
        return out ? sv_2mortal(out) : NULL;
    }

    {
        SV *argv[1], *auth;
        STRLEN al;
        const char *as;
        argv[0] = sv_2mortal(newSVpvs("authorization"));
        auth = pcx_call_meth(aTHX_ req, "header", argv, 1, 1);
        if (!(auth && SvOK(auth))) { if (auth) SvREFCNT_dec(auth); return NULL; }
        sv_2mortal(auth);
        as = SvPV_const(auth, al);

        if (tl == 4 && memEQ(t, "http", 4)) {
            SV *scheme = poa_get(aTHX_ def, "scheme");
            STRLEN sl = 0;
            const char *ss = (scheme && SvOK(scheme))
                             ? SvPV_const(scheme, sl) : "";
            if (sl == 5 && toLOWER((U8)ss[0]) == 'b' && toLOWER((U8)ss[1]) == 'a'
                && toLOWER((U8)ss[2]) == 's' && toLOWER((U8)ss[3]) == 'i'
                && toLOWER((U8)ss[4]) == 'c') {
                STRLEN pl;
                const char *p = poa_auth_param(as, al, "Basic", 5, &pl);
                if (!p) return NULL;
                out = poa_b64_decode(aTHX_ p, pl);
                return out ? sv_2mortal(out) : NULL;
            }
        }
        /* http bearer, oauth2 and openIdConnect all verify an issued token */
        {
            STRLEN pl;
            const char *p = poa_auth_param(as, al, "Bearer", 6, &pl);
            if (!p) return NULL;
            return sv_2mortal(newSVpvn(p, pl));
        }
    }
}

/* ---- the generated per-operation security guard ----------------------------
 *
 * Alternatives are OR, the schemes within one alternative are AND, and the
 * eldest passing alternative authorizes (its results land in
 * $c->stash->{auth}); none passing answers 401 before any body is read.
 *
 * Captured: [ $op_id, \@alts ] where each alt is an AV of
 * [ $name, \%def, $checker, $scopes ]. */

XS_INTERNAL(punk_oa_security_cb);
XS_INTERNAL(punk_oa_security_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c = items > 0 ? ST(0) : &PL_sv_undef;
    SV *op_id, *alts_sv;
    AV *alts;
    SSize_t ai, an;

    if (!cap || items < 1) croak("Punk: a security guard lost its captures");
    op_id   = *av_fetch(cap, 0, 0);
    alts_sv = *av_fetch(cap, 1, 0);
    alts    = (AV *)SvRV(alts_sv);
    an      = av_len(alts) + 1;

    for (ai = 0; ai < an; ai++) {
        AV *alt = (AV *)SvRV(*av_fetch(alts, ai, 0));
        SSize_t pi, pn = av_len(alt) + 1;
        HV *auth = newHV();
        int ok = 1;

        for (pi = 0; pi < pn; pi++) {
            AV *part = (AV *)SvRV(*av_fetch(alt, pi, 0));
            SV *name    = *av_fetch(part, 0, 0);
            HV *def     = (HV *)SvRV(*av_fetch(part, 1, 0));
            SV *checker = *av_fetch(part, 2, 0);
            SV **scp    = av_fetch(part, 3, 0);
            SV *cred = poa_credential(aTHX_ c, def);
            SV *got;

            if (!(cred && SvOK(cred) && SvCUR(cred))) { ok = 0; break; }
            {
                SV *argv[4];
                argv[0] = cred;
                argv[1] = c;
                argv[2] = op_id;
                argv[3] = (scp && *scp) ? *scp : &PL_sv_undef;
                got = poa_call_args(aTHX_ checker, argv, 4);
            }
            if (!(got && SvTRUE(got))) {
                if (got) SvREFCNT_dec(got);
                ok = 0; break;
            }
            (void)hv_store_ent(auth, name, got, 0);   /* takes the +1 */
        }

        if (ok) {
            SV *stash = pcx_call_meth(aTHX_ c, "stash", NULL, 0, 1);
            HV *sh = poa_hash_of(aTHX_ stash);
            if (sh) (void)hv_stores(sh, "auth", newRV_noinc((SV *)auth));
            else SvREFCNT_dec((SV *)auth);
            if (stash) SvREFCNT_dec(stash);
            XSRETURN_EMPTY;               /* authorized: the chain continues */
        }
        SvREFCNT_dec((SV *)auth);
    }

    {
        SV *body = newSVpvs(POA_UNAUTHORIZED);
        AV *hdrs = newAV();
        AV *bod  = newAV();
        AV *trip = newAV();
        av_push(hdrs, newSVpvs("Content-Type"));
        av_push(hdrs, newSVpvs("application/json"));
        av_push(hdrs, newSVpvs("Content-Length"));
        av_push(hdrs, newSViv((IV)SvCUR(body)));
        av_push(bod, body);
        av_push(trip, newSViv(401));
        av_push(trip, newRV_noinc((SV *)hdrs));
        av_push(trip, newRV_noinc((SV *)bod));
        ST(0) = sv_2mortal(newRV_noinc((SV *)trip));
        XSRETURN(1);
    }
}

/* ---- controller discovery --------------------------------------------------
 *
 * Every .pm under the namespace directory, across @INC, loaded; the class
 * names come back for the operationId search. */

/* A loadable class name: the only files that can define one are the ones whose
 * path is made of identifiers, so anything else is skipped rather than
 * required. It also makes the name safe to interpolate into the eval below. */
static int poa_ident_path(const char *s, STRLEN len) {
    STRLEN i = 0;
    if (!len) return 0;
    while (i < len) {
        STRLEN start = i;
        if (!(isALPHA((U8)s[i]) || s[i] == '_')) return 0;
        while (i < len && (isWORDCHAR((U8)s[i]))) i++;
        if (i == start) return 0;
        if (i == len) return 1;
        if (!(s[i] == ':' && i + 1 < len && s[i + 1] == ':')) return 0;
        i += 2;
    }
    return 0;
}

static void poa_walk_dir(pTHX_ SV *inc, SV *rel, HV *seen, AV *out) {
    SV *dir = sv_2mortal(newSVsv(inc));
    DIR *dh;
    Direntry_t *de;
    AV *ents = (AV *)sv_2mortal((SV *)newAV());
    SSize_t i, n;

    sv_catpvs(dir, "/");
    sv_catsv(dir, rel);
    dh = PerlDir_open(SvPV_nolen(dir));
    if (!dh) return;
    while ((de = PerlDir_read(dh))) {
        const char *nm = de->d_name;
        if (nm[0] == '.' && (nm[1] == '\0' || (nm[1] == '.' && nm[2] == '\0')))
            continue;
        av_push(ents, newSVpv(nm, 0));
    }
    PerlDir_close(dh);

    /* sorted so the traversal is stable across filesystems */
    n = av_len(ents) + 1;
    if (n > 1) sortsv(AvARRAY(ents), (STRLEN)n, Perl_sv_cmp);

    for (i = 0; i < n; i++) {
        SV *ent = *av_fetch(ents, i, 0);
        STRLEN el;
        const char *es = SvPV_const(ent, el);
        SV *child = sv_2mortal(newSVsv(rel));
        SV *full  = sv_2mortal(newSVsv(dir));
        Stat_t st;
        sv_catpvs(child, "/"); sv_catsv(child, ent);
        sv_catpvs(full,  "/"); sv_catsv(full,  ent);

        if (PerlLIO_stat(SvPV_nolen(full), &st) == 0 && S_ISDIR(st.st_mode)) {
            poa_walk_dir(aTHX_ inc, child, seen, out);
            continue;
        }
        if (!(el > 3 && memEQ(es + el - 3, ".pm", 3))) continue;

        {
            /* the @INC-relative path minus .pm, as a class name */
            SV *mod = sv_2mortal(newSVpvn(SvPVX(child), SvCUR(child) - 3));
            char *p = SvPVX(mod);
            STRLEN j, ml = SvCUR(mod);
            SV *colons = sv_2mortal(newSVpvs(""));
            for (j = 0; j < ml; j++) {
                if (p[j] == '/') sv_catpvs(colons, "::");
                else sv_catpvn(colons, p + j, 1);
            }
            if (!poa_ident_path(SvPVX(colons), SvCUR(colons))) continue;
            if (hv_exists_ent(seen, colons, 0)) continue;
            (void)hv_store_ent(seen, colons, newSViv(1), 0);

            /* Require by module name, which is the same %INC key
             * `require Foo::Bar` and Punk::App's target resolver both use.
             * Loading by absolute path instead made one file two %INC
             * entries and ran it twice - "Subroutine redefined" for every
             * controller reachable both ways, and two generations of the
             * same coderefs. */
            {
                SV *code = sv_2mortal(newSVpvs("require "));
                sv_catsv(code, colons);
                sv_catpvs(code, "; 1");
                eval_sv(code, G_SCALAR | G_DISCARD);
                if (SvTRUE(ERRSV))
                    croak("Punk: controller %s failed to load: %s",
                          SvPV_nolen(colons), SvPV_nolen(ERRSV));
            }
            av_push(out, newSVsv(colons));
        }
    }
}

/* The classes under $ns, loaded, sorted. Mortal AV. */
static AV *poa_load_namespace(pTHX_ SV *ns) {
    AV *out  = (AV *)sv_2mortal((SV *)newAV());
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    AV *inc  = GvAV(PL_incgv);
    SSize_t i, n = inc ? av_len(inc) + 1 : 0;
    STRLEN nl, j;
    const char *ns_s = SvPV_const(ns, nl);
    SV *rel = sv_2mortal(newSVpvs(""));

    for (j = 0; j < nl; j++) {
        if (ns_s[j] == ':' && j + 1 < nl && ns_s[j + 1] == ':') {
            sv_catpvs(rel, "/"); j++;
        }
        else sv_catpvn(rel, ns_s + j, 1);
    }

    for (i = 0; i < n; i++) {
        SV **ip = av_fetch(inc, i, 0);
        if (!ip || !*ip || SvROK(*ip) || !SvOK(*ip)) continue;
        poa_walk_dir(aTHX_ *ip, rel, seen, out);
    }
    n = av_len(out) + 1;
    if (n > 1) sortsv(AvARRAY(out), (STRLEN)n, Perl_sv_cmp);
    return out;
}

/* operationId -> coderef: an explicit handler first, then the one discovered
 * class implementing it. Two implementers is an ambiguity the application has
 * to resolve; none is only allowed under `stub`. Returns +1, or NULL. */
static SV *poa_find_handler(pTHX_ SV *id, HV *handlers, AV *classes,
                            SV *resolve) {
    HE *he = handlers ? hv_fetch_ent(handlers, id, 0, 0) : NULL;
    SSize_t i, n = av_len(classes) + 1;
    SV *found = NULL, *names = NULL;
    int hits = 0;

    if (he && SvOK(HeVAL(he))) {
        SV *what = sv_2mortal(newSVpvs("handler for '"));
        sv_catsv(what, id);
        sv_catpvs(what, "'");
        return poa_resolve(aTHX_ resolve, HeVAL(he), SvPV_nolen(what));
    }

    for (i = 0; i < n; i++) {
        SV *cls = *av_fetch(classes, i, 0);
        HV *stash = gv_stashsv(cls, 0);
        GV *gv = stash ? gv_fetchmethod_autoload(stash, SvPV_nolen(id), 0)
                       : NULL;
        if (!(gv && GvCV(gv))) continue;
        hits++;
        if (!found) found = newRV_inc((SV *)GvCV(gv));
        if (!names) names = sv_2mortal(newSVsv(cls));
        else { sv_catpvs(names, ", "); sv_catsv(names, cls); }
    }
    if (hits > 1)
        croak("Punk: operation '%s' is implemented by more than one "
              "controller (%s)", SvPV_nolen(id), SvPV_nolen(names));
    return found;
}

#endif /* PUNK_OAMOUNT_H */
