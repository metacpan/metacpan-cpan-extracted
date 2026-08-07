/* punk_dbi.h - the shipped Punk::Model backend, in C.
 *
 * What this port does and does not buy is worth stating, because the shape of
 * the win is unusual here. Every database operation is still a DBI method
 * call - connect, prepare_cached, execute, fetchrow_hashref, quote_identifier,
 * last_insert_id - and those are Perl-level calls into DBI's own XS that no
 * amount of C on this side removes. The round trip to the database dominates
 * either way.
 *
 * What moves into C is the glue around them: assembling the SQL, sorting the
 * column lists, the connection pool bookkeeping, and the keyset token codec
 * (base64url over the File::Raw::JSON ABI, so MIME::Base64 and a Perl eval
 * leave the pagination path entirely). Punk::Model's contract methods are
 * already XSUBs that call_method into the backend, so with this the whole
 * model tier is one C frame calling DBI rather than two Perl frames.
 *
 * The object stays a blessed hash with the same slots the Perl used
 * (opts/table/primary/columns/col/returning): t/12-model-dbi.t reaches
 * through ->backend->dbh, and keeping the shape means a hand-written backend
 * can still subclass this one.
 *
 * Must be included after punk_context.h (pcx_call_meth) and the punk_frj
 * resolver.
 */

#ifndef PUNK_DBI_H
#define PUNK_DBI_H

static HV *pdbi_hv(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Punk::Model::DBI: not a backend object");
    return (HV *)SvRV(self);
}

static SV *pdbi_get(pTHX_ HV *h, const char *k) {
    SV **e = hv_fetch(h, k, (I32)strlen(k), 0);
    return (e && *e) ? *e : NULL;
}

/* ---- the connection pool ---------------------------------------------------
 *
 * One handle per distinct connection (dsn + credentials), shared by every
 * model that uses it, so a hundred models on one database open one connection
 * per worker rather than a hundred. The pid lives in the reconnect check, so a
 * fork gets a fresh handle instead of a corrupted shared one. */

static HV *PDBI_POOL = NULL;

static HV *pdbi_pool(pTHX) {
    if (!PDBI_POOL) PDBI_POOL = newHV();
    return PDBI_POOL;
}

/* The pool slot for a connection key, created empty on first use. */
static SV *pdbi_slot(pTHX_ HV *pool, SV *key) {
    HE *he = hv_fetch_ent(pool, key, 0, 0);
    if (!he) {
        HV *slot = newHV();
        (void)hv_stores(slot, "pid", newSViv(-1));
        he = hv_store_ent(pool, key, newRV_noinc((SV *)slot), 0);
    }
    return HeVAL(he);
}

/* An attribute off a DBI handle's hash ($dbh->{Driver}), or NULL. DBI handles
 * are magical hashes, so this goes through hv_fetch, which runs the magic. */
static SV *pdbi_attr(pTHX_ SV *h, const char *name) {
    SV **e;
    if (!(h && SvROK(h) && SvTYPE(SvRV(h)) == SVt_PVHV)) return NULL;
    e = hv_fetch((HV *)SvRV(h), name, (I32)strlen(name), 0);
    if (!(e && *e)) return NULL;
    SvGETMAGIC(*e);
    return *e;
}

/* RETURNING support, feature-detected once per connection: PostgreSQL always,
 * SQLite from 3.35. Anything else re-fetches the row after a write. Detection
 * failing is not fatal - a 0 here only costs an extra SELECT. */
static int pdbi_detect_returning(pTHX_ SV *dbh) {
    SV *drv = pdbi_attr(aTHX_ dbh, "Driver");
    SV *name = drv ? pdbi_attr(aTHX_ drv, "Name") : NULL;
    const char *n;
    STRLEN nl;
    if (!(name && SvOK(name))) return 0;
    n = SvPV_const(name, nl);
    if (nl == 2 && memEQ(n, "Pg", 2)) return 1;
    if (nl == 6 && memEQ(n, "SQLite", 6)) {
        SV *v = pdbi_attr(aTHX_ dbh, "sqlite_version");
        if (v && SvOK(v)) {
            STRLEN vl;
            const char *s = SvPV_const(v, vl);
            int maj = 0, min = 0;
            STRLEN i = 0;
            while (i < vl && isDIGIT((U8)s[i])) maj = maj * 10 + (s[i++] - '0');
            if (i < vl && s[i] == '.') {
                i++;
                while (i < vl && isDIGIT((U8)s[i])) min = min * 10 + (s[i++] - '0');
            }
            if (maj > 3 || (maj == 3 && min >= 35)) return 1;
        }
    }
    return 0;
}

/* The live handle for this backend's dsn, connected on first use in this
 * process and shared with every other backend on the same one. Borrowed. */
static SV *pdbi_dbh(pTHX_ SV *self) {
    HV *h    = pdbi_hv(aTHX_ self);
    SV *opts = pdbi_get(aTHX_ h, "opts");
    HV *o    = (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
               ? (HV *)SvRV(opts) : NULL;
    SV *dsn  = o ? pdbi_get(aTHX_ o, "dsn") : NULL;
    SV *user = o ? pdbi_get(aTHX_ o, "user") : NULL;
    SV *pass = o ? pdbi_get(aTHX_ o, "password") : NULL;
    SV *key, *slot_sv, *dbh;
    HV *pool = pdbi_pool(aTHX), *slot;
    SV *pid;

    if (!(dsn && SvOK(dsn) && SvTRUE(dsn)))
        croak("Punk::Model::DBI: no dsn - add a database keyword");

    /* NUL-joined so a dsn containing the separator cannot collide */
    key = sv_2mortal(newSVsv(dsn));
    sv_catpvn(key, "\0", 1);
    if (user && SvOK(user)) sv_catsv(key, user);
    sv_catpvn(key, "\0", 1);
    if (pass && SvOK(pass)) sv_catsv(key, pass);

    slot_sv = pdbi_slot(aTHX_ pool, key);
    slot = (HV *)SvRV(slot_sv);
    pid  = pdbi_get(aTHX_ slot, "pid");
    dbh  = pdbi_get(aTHX_ slot, "dbh");

    if (!(pid && SvOK(pid) && SvIV(pid) == (IV)PerlProc_getpid())
        || !(dbh && SvROK(dbh))) {
        SV *argv[4], *attr_rv, *conn;
        HV *attr = newHV();
        SV *user_attr = o ? pdbi_get(aTHX_ o, "attr") : NULL;
        (void)hv_stores(attr, "RaiseError", newSViv(1));
        (void)hv_stores(attr, "AutoCommit", newSViv(1));
        (void)hv_stores(attr, "PrintError", newSViv(0));
        if (user_attr && SvROK(user_attr)
            && SvTYPE(SvRV(user_attr)) == SVt_PVHV) {
            HV *ua = (HV *)SvRV(user_attr);
            HE *he;
            hv_iterinit(ua);
            while ((he = hv_iternext(ua)))
                (void)hv_store_ent(attr, HeSVKEY_force(he),
                                   newSVsv(HeVAL(he)), 0);
        }
        attr_rv = sv_2mortal(newRV_noinc((SV *)attr));

        eval_pv("require DBI;", TRUE);
        argv[0] = dsn;
        argv[1] = (user && SvOK(user)) ? user : &PL_sv_undef;
        argv[2] = (pass && SvOK(pass)) ? pass : &PL_sv_undef;
        argv[3] = attr_rv;
        conn = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("DBI")), "connect",
                             argv, 4, 1);
        if (!conn) conn = newSV(0);
        (void)hv_stores(slot, "dbh", conn);
        (void)hv_stores(slot, "pid", newSViv((IV)PerlProc_getpid()));
        (void)hv_stores(slot, "returning",
                        newSViv(pdbi_detect_returning(aTHX_ conn)));
        dbh = conn;
    }

    /* create/update read this off the instance; keep it in step with the
     * pooled slot, which is where the detection actually lives */
    {
        SV *r = pdbi_get(aTHX_ slot, "returning");
        (void)hv_stores(h, "returning", newSViv(r ? SvIV(r) : 0));
    }
    return dbh;
}

/* $self->dbh->quote_identifier($name). Mortal. */
static SV *pdbi_qi(pTHX_ SV *self, SV *name) {
    SV *dbh = pdbi_dbh(aTHX_ self);
    SV *argv[1], *q;
    argv[0] = name;
    q = pcx_call_meth(aTHX_ dbh, "quote_identifier", argv, 1, 1);
    return q ? sv_2mortal(q) : sv_2mortal(newSVsv(name));
}

static SV *pdbi_qi_pv(pTHX_ SV *self, const char *name) {
    return pdbi_qi(aTHX_ self, sv_2mortal(newSVpv(name, 0)));
}

/* prepare_cached: one statement handle per distinct SQL string on the
 * connection, which is what keeps repeated queries off the parser (and what
 * t/12 checks through $dbh->{CachedKids}). Mortal. */
static SV *pdbi_sth(pTHX_ SV *self, SV *sql) {
    SV *dbh = pdbi_dbh(aTHX_ self);
    SV *argv[3], *sth;
    argv[0] = sql;
    argv[1] = &PL_sv_undef;
    argv[2] = sv_2mortal(newSViv(3));
    sth = pcx_call_meth(aTHX_ dbh, "prepare_cached", argv, 3, 1);
    if (!sth) croak("Punk::Model::DBI: prepare_cached returned nothing");
    return sv_2mortal(sth);
}

/* $sth->execute(@bind) */
static void pdbi_execute(pTHX_ SV *sth, AV *bind) {
    SSize_t n = bind ? av_len(bind) + 1 : 0, i;
    SV **argv = n ? (SV **)safemalloc(sizeof(SV *) * (size_t)n) : NULL;
    SV *r;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(bind, i, 0);
        argv[i] = (e && *e) ? *e : &PL_sv_undef;
    }
    r = pcx_call_meth(aTHX_ sth, "execute", argv, (int)n, 1);
    if (argv) safefree(argv);
    if (r) SvREFCNT_dec(r);
}

static SV *pdbi_meth0(pTHX_ SV *obj, const char *meth) {
    return pcx_call_meth(aTHX_ obj, meth, NULL, 0, 1);
}

/* The hash keys of an unblessed hashref, sorted the way `sort keys %$h` would
 * sort them - the generated SQL has to be stable, or prepare_cached sees a
 * different statement for every permutation of the same filter. Mortal AV. */
static AV *pdbi_sorted_keys(pTHX_ HV *h) {
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    HE *he;
    SSize_t n;
    if (!h) return out;
    hv_iterinit(h);
    while ((he = hv_iternext(h)))
        av_push(out, newSVsv(HeSVKEY_force(he)));
    n = av_len(out) + 1;
    if (n > 1) sortsv(AvARRAY(out), (size_t)n, Perl_sv_cmp);
    return out;
}

/* ---- the opaque keyset token ----------------------------------------------
 *
 * base64url of {"k":<primary key>}: url-safe, unpadded, and opaque enough
 * that nobody builds one by hand and depends on the shape. */

static const char PDBI_B64U[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

static SV *pdbi_b64u_encode(pTHX_ const unsigned char *s, STRLEN len) {
    SV *out = newSV(((len + 2) / 3) * 4 + 1);
    char *d;
    STRLEN i = 0;
    SvPOK_on(out);
    d = SvPVX(out);
    while (i + 2 < len) {
        unsigned v = ((unsigned)s[i] << 16) | ((unsigned)s[i+1] << 8) | s[i+2];
        *d++ = PDBI_B64U[(v >> 18) & 0x3F];
        *d++ = PDBI_B64U[(v >> 12) & 0x3F];
        *d++ = PDBI_B64U[(v >>  6) & 0x3F];
        *d++ = PDBI_B64U[ v        & 0x3F];
        i += 3;
    }
    if (i < len) {                       /* 1 or 2 bytes left, no padding */
        unsigned v = (unsigned)s[i] << 16;
        int two = (i + 1 < len);
        if (two) v |= (unsigned)s[i+1] << 8;
        *d++ = PDBI_B64U[(v >> 18) & 0x3F];
        *d++ = PDBI_B64U[(v >> 12) & 0x3F];
        if (two) *d++ = PDBI_B64U[(v >> 6) & 0x3F];
    }
    *d = '\0';
    SvCUR_set(out, (STRLEN)(d - SvPVX(out)));
    return out;
}

/* Decode, accepting the padded and url-unsafe spellings too. NULL when the
 * input is not base64 at all. */
static SV *pdbi_b64u_decode(pTHX_ const char *s, STRLEN len) {
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
        else if (c == '-' || c == '+') x = 62;
        else if (c == '_' || c == '/') x = 63;
        else { SvREFCNT_dec(out); return NULL; }
        v = (v << 6) | (unsigned)x;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            *d++ = (char)((v >> bits) & 0xFF);
        }
    }
    *d = '\0';
    SvCUR_set(out, (STRLEN)(d - SvPVX(out)));
    return out;
}

static SV *pdbi_encode_token(pTHX_ SV *val) {
    HV *w = newHV();
    SV *json, *tok;
    STRLEN jl;
    const char *jp;
    (void)hv_stores(w, "k", newSVsv(val));
    json = punk_frj(aTHX)->encode(aTHX_ sv_2mortal(newRV_noinc((SV *)w)), NULL);
    jp = SvPV_const(json, jl);
    tok = pdbi_b64u_encode(aTHX_ (const unsigned char *)jp, jl);
    SvREFCNT_dec(json);
    return tok;
}

static SV *pdbi_decode_token(pTHX_ SV *tok) {
    STRLEN tl;
    const char *tp = SvOK(tok) ? SvPV_const(tok, tl) : "";
    SV *json, *doc, *out = NULL;
    if (!SvOK(tok)) tl = 0;
    json = pdbi_b64u_decode(aTHX_ tp, tl);
    if (!json) croak("Punk::Model::DBI: invalid pagination token");
    sv_2mortal(json);

    /* The decode dies on malformed JSON, and a bad token is a client error
     * rather than a server one - so it has to be trapped and turned into the
     * croak below. Trapping it goes through Perl's eval (call_pv + G_EVAL)
     * rather than JMPENV directly: a longjmp past the C would leave the save
     * stack unwound only as far as the jump, and this is an error path where
     * correctness is worth more than the call. */
    {
        SV *argv[1];
        dSP;
        int count;
        argv[0] = json;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(json); PUTBACK;
        count = call_pv("File::Raw::JSON::file_json_decode",
                        G_SCALAR | G_EVAL);
        SPAGAIN;
        doc = (count > 0) ? SvREFCNT_inc(POPs) : NULL;
        PUTBACK; FREETMPS; LEAVE;
        if (SvTRUE(ERRSV)) { SvREFCNT_dec(doc); doc = NULL; }
        PERL_UNUSED_VAR(argv);
    }
    if (!doc) croak("Punk::Model::DBI: invalid pagination token");

    if (SvROK(doc) && SvTYPE(SvRV(doc)) == SVt_PVHV) {
        SV *k = pdbi_get(aTHX_ (HV *)SvRV(doc), "k");
        if (k) out = newSVsv(k);
    }
    SvREFCNT_dec(doc);
    if (!out) croak("Punk::Model::DBI: invalid pagination token");
    return out;
}

/* ---- shared SQL shapes ----------------------------------------------------- */

/* '<qi(a)> = ? AND <qi(b)> = ?' for the sorted keys, pushing each key's value
 * onto @bind in the same order. Mortal. */
static SV *pdbi_where_eq(pTHX_ SV *self, HV *src, AV *keys, AV *bind) {
    SV *where = sv_2mortal(newSVpvs(""));
    SSize_t i, n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV *k = *av_fetch(keys, i, 0);
        HE *he;
        if (i) sv_catpvs(where, " AND ");
        sv_catsv(where, pdbi_qi(aTHX_ self, k));
        sv_catpvs(where, " = ?");
        he = hv_fetch_ent(src, k, 0, 0);
        av_push(bind, newSVsv(he ? HeVAL(he) : &PL_sv_undef));
    }
    return where;
}

/* The %key of get/delete, as sorted keys; croaks when empty. */
static AV *pdbi_key_args(pTHX_ SV **st, I32 items, HV **out, const char *what) {
    HV *key = newHV();
    I32 i;
    if (items < 3 || !((items - 1) % 2 == 0))
        croak("Punk::Model::DBI: %s needs a key", what);
    for (i = 1; i + 1 < items; i += 2)
        (void)hv_store_ent(key, st[i], newSVsv(st[i + 1]), 0);
    if (!HvUSEDKEYS(key)) {
        SvREFCNT_dec((SV *)key);
        croak("Punk::Model::DBI: %s needs a key", what);
    }
    *out = (HV *)sv_2mortal((SV *)key);
    return pdbi_sorted_keys(aTHX_ key);
}

#endif /* PUNK_DBI_H */
