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

/* The pool slot for this backend's dsn, connected on first use in this
 * process and shared with every other backend on the same one. Borrowed. */
static HV *pdbi_slot_for(pTHX_ SV *self) {
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
        /* Both caches belong to the connection: the quoted identifiers
         * because quoting is the driver's, and the assembled statements
         * because they have those identifiers baked into them. A reconnect
         * (or a fork) starts fresh ones. */
        (void)hv_delete(slot, "qi",   2, G_DISCARD);
        (void)hv_delete(slot, "sqlc", 4, G_DISCARD);
        dbh = conn;
    }

    /* create/update read this off the instance; keep it in step with the
     * pooled slot, which is where the detection actually lives */
    {
        SV *r = pdbi_get(aTHX_ slot, "returning");
        (void)hv_stores(h, "returning", newSViv(r ? SvIV(r) : 0));
    }
    PERL_UNUSED_VAR(dbh);
    return slot;
}

/* The live handle for this backend's dsn. Borrowed. */
static SV *pdbi_dbh(pTHX_ SV *self) {
    SV *dbh = pdbi_get(aTHX_ pdbi_slot_for(aTHX_ self), "dbh");
    return dbh ? dbh : &PL_sv_undef;
}

/* $dbh->quote_identifier($name), on a handle the caller already holds - the
 * DBIx::Loop backend quotes against its parent handle, which is not in this
 * pool. Mortal. */
static SV *pdbi_qi_dbh(pTHX_ SV *dbh, SV *name) {
    SV *argv[1], *q;
    argv[0] = name;
    q = pcx_call_meth(aTHX_ dbh, "quote_identifier", argv, 1, 1);
    return q ? sv_2mortal(q) : sv_2mortal(newSVsv(name));
}

/* quote_identifier, memoised on the pool slot.
 *
 * It is a Perl method call into DBI, and on a small statement it dominates:
 * a get quotes the table and one key column, and those two calls were 1.5us
 * of a 3.6us round trip - more than the query itself. The answer depends only
 * on the driver and the name, and a model's identifiers are a fixed, tiny set
 * (its table and its columns), so the first call per name pays for the rest.
 *
 * The cache lives on the SLOT rather than the instance because quoting is a
 * property of the connection: every model on one dsn shares it, and a
 * reconnect drops it (see pdbi_slot_for). The returned SV is borrowed from
 * the cache - callers concatenate it into the SQL immediately. */
static SV *pdbi_qi_slot(pTHX_ HV *slot, SV *dbh, SV *name) {
    SV **e = hv_fetchs(slot, "qi", 0);
    HV *cache;
    HE *he;
    if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)
        cache = (HV *)SvRV(*e);
    else {
        cache = newHV();
        (void)hv_stores(slot, "qi", newRV_noinc((SV *)cache));
    }
    he = hv_fetch_ent(cache, name, 0, 0);
    if (he && HeVAL(he) && SvOK(HeVAL(he))) return HeVAL(he);
    he = hv_store_ent(cache, name,
                      newSVsv(pdbi_qi_dbh(aTHX_ dbh, name)), 0);
    return (he && HeVAL(he)) ? HeVAL(he) : name;
}

/* $self->dbh->quote_identifier($name), memoised. Borrowed. */
static SV *pdbi_qi(pTHX_ SV *self, SV *name) {
    HV *slot = pdbi_slot_for(aTHX_ self);
    SV *dbh  = pdbi_get(aTHX_ slot, "dbh");
    return pdbi_qi_slot(aTHX_ slot, dbh ? dbh : &PL_sv_undef, name);
}

static SV *pdbi_qi_pv(pTHX_ SV *self, const char *name) {
    return pdbi_qi(aTHX_ self, sv_2mortal(newSVpv(name, 0)));
}

/* prepare_cached: one statement handle per distinct SQL string on the
 * connection, which is what keeps repeated queries off the parser (and what
 * t/12 checks through $dbh->{CachedKids}). Mortal. */
static SV *pdbi_sth_dbh(pTHX_ SV *dbh, SV *sql) {
    SV *argv[3], *sth;
    argv[0] = sql;
    argv[1] = &PL_sv_undef;
    argv[2] = sv_2mortal(newSViv(3));
    sth = pcx_call_meth(aTHX_ dbh, "prepare_cached", argv, 3, 1);
    if (!sth) croak("Punk::Model::DBI: prepare_cached returned nothing");
    return sv_2mortal(sth);
}

static SV *pdbi_sth(pTHX_ SV *self, SV *sql) {
    return pdbi_sth_dbh(aTHX_ pdbi_dbh(aTHX_ self), sql);
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

/* `cls` names the backend in the croak, so a bad token on the async backend
 * does not blame the DBI one. A shared codec is a correctness requirement,
 * not DRY: a `next` token minted by one backend must decode in the other, or
 * switching backends breaks every paginated URL in flight. */
static SV *pdbi_decode_token(pTHX_ SV *tok, const char *cls) {
    STRLEN tl;
    const char *tp = SvOK(tok) ? SvPV_const(tok, tl) : "";
    SV *json, *doc, *out = NULL;
    if (!SvOK(tok)) tl = 0;
    json = pdbi_b64u_decode(aTHX_ tp, tl);
    if (!json) croak("%s: invalid pagination token", cls);
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
    if (!doc) croak("%s: invalid pagination token", cls);

    if (SvROK(doc) && SvTYPE(SvRV(doc)) == SVt_PVHV) {
        SV *k = pdbi_get(aTHX_ (HV *)SvRV(doc), "k");
        if (k) out = newSVsv(k);
    }
    SvREFCNT_dec(doc);
    if (!out) croak("%s: invalid pagination token", cls);
    return out;
}

/* ---- shared SQL shapes ----------------------------------------------------- */

/* '<qi(a)> = ? AND <qi(b)> = ?' for the sorted keys, pushing each key's value
 * onto @bind in the same order, quoting through the slot's cache. Mortal. */
static SV *pdbi_where_eq_slot(pTHX_ HV *slot, SV *dbh, HV *src,
                              AV *keys, AV *bind) {
    SV *where = sv_2mortal(newSVpvs(""));
    SSize_t i, n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV *k = *av_fetch(keys, i, 0);
        HE *he;
        if (i) sv_catpvs(where, " AND ");
        sv_catsv(where, pdbi_qi_slot(aTHX_ slot, dbh, k));
        sv_catpvs(where, " = ?");
        he = hv_fetch_ent(src, k, 0, 0);
        av_push(bind, newSVsv(he ? HeVAL(he) : &PL_sv_undef));
    }
    return where;
}

/* The bind half of pdbi_where_eq_slot on its own, in the same (sorted) order -
 * what the cached-SQL path still has to do per call. */
static void pdbi_bind_keys(pTHX_ HV *src, AV *keys, AV *bind) {
    SSize_t i, n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV *k  = *av_fetch(keys, i, 0);
        HE *he = hv_fetch_ent(src, k, 0, 0);
        av_push(bind, newSVsv(he ? HeVAL(he) : &PL_sv_undef));
    }
}

static SV *pdbi_where_eq(pTHX_ SV *self, HV *src, AV *keys, AV *bind) {
    HV *slot = pdbi_slot_for(aTHX_ self);
    SV *dbh  = pdbi_get(aTHX_ slot, "dbh");
    return pdbi_where_eq_slot(aTHX_ slot, dbh ? dbh : &PL_sv_undef,
                              src, keys, bind);
}

/* A memoised statement, for the fixed-shape operations.
 *
 * get and delete generate one SQL string per set of key columns, and a model
 * is asked for the same set over and over - almost always the primary key. So
 * the string is built once and looked up thereafter, which also skips the
 * identifier quoting and the concatenation behind it. `sig` identifies the
 * shape (the operation plus its sorted key names); the cache lives on the
 * slot beside the quoting cache, and dies with the connection for the same
 * reason. Returns the SQL, borrowed. */
static SV *pdbi_sql_cached(pTHX_ HV *slot, SV *sig, SV *sql) {
    SV **e = hv_fetchs(slot, "sqlc", 0);
    HV *cache;
    HE *he;
    if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)
        cache = (HV *)SvRV(*e);
    else {
        cache = newHV();
        (void)hv_stores(slot, "sqlc", newRV_noinc((SV *)cache));
    }
    if (!sql) {
        he = hv_fetch_ent(cache, sig, 0, 0);
        return (he && HeVAL(he) && SvOK(HeVAL(he))) ? HeVAL(he) : NULL;
    }
    he = hv_store_ent(cache, sig, newSVsv(sql), 0);
    return (he && HeVAL(he)) ? HeVAL(he) : sql;
}

/* 'op\0table\0k1\0k2' - the shape of a fixed-form statement. The TABLE is in
 * the signature because the cache hangs off the connection, which every model
 * on that dsn shares: without it, two models with the same key columns would
 * read each other's statement. Mortal. */
static SV *pdbi_sig(pTHX_ const char *op, SV *table, AV *keys) {
    SV *sig = sv_2mortal(newSVpv(op, 0));
    SSize_t i, n = keys ? av_len(keys) + 1 : 0;
    sv_catpvn(sig, "\0", 1);
    if (table && SvOK(table)) sv_catsv(sig, table);
    for (i = 0; i < n; i++) {
        SV **k = av_fetch(keys, i, 0);
        sv_catpvn(sig, "\0", 1);
        if (k && *k) sv_catsv(sig, *k);
    }
    return sig;
}

/* The %key of get/delete, as sorted keys; croaks (naming the calling backend)
 * when empty. */
static AV *pdbi_key_args(pTHX_ SV **st, I32 items, HV **out,
                         const char *what, const char *cls) {
    HV *key = newHV();
    I32 i;
    if (items < 3 || !((items - 1) % 2 == 0))
        croak("%s: %s needs a key", cls, what);
    for (i = 1; i + 1 < items; i += 2)
        (void)hv_store_ent(key, st[i], newSVsv(st[i + 1]), 0);
    if (!HvUSEDKEYS(key)) {
        SvREFCNT_dec((SV *)key);
        croak("%s: %s needs a key", cls, what);
    }
    *out = (HV *)sv_2mortal((SV *)key);
    return pdbi_sorted_keys(aTHX_ key);
}

/* The backend object both shipped backends bless: the same slots the Perl
 * used (opts/table/primary/columns/col/returning), parsed from the
 * database/table/primary/columns pairs _instantiate passes. Shared so a
 * second backend cannot drift from the shape t/12 reaches through. */
static SV *pdbi_build_self(pTHX_ SV *class, SV **st, I32 items,
                           const char *cls) {
    HV *h = newHV();
    HV *col = newHV();
    SV *table = NULL, *primary = NULL, *columns = NULL, *database = NULL;
    I32 i;
    for (i = 1; i + 1 < items; i += 2) {
        STRLEN kl; const char *k = SvPV_const(st[i], kl);
        if      (kl == 5 && memEQ(k, "table",    5)) table    = st[i + 1];
        else if (kl == 7 && memEQ(k, "primary",  7)) primary  = st[i + 1];
        else if (kl == 7 && memEQ(k, "columns",  7)) columns  = st[i + 1];
        else if (kl == 8 && memEQ(k, "database", 8)) database = st[i + 1];
    }
    if (!(table && SvOK(table) && SvTRUE(table))) {
        SvREFCNT_dec((SV *)h); SvREFCNT_dec((SV *)col);
        croak("%s: a model with no table", cls);
    }
    /* the column set, for the create/update filters */
    if (columns && SvROK(columns) && SvTYPE(SvRV(columns)) == SVt_PVAV) {
        AV *c = (AV *)SvRV(columns);
        SSize_t n = av_len(c) + 1, j;
        for (j = 0; j < n; j++) {
            SV **e = av_fetch(c, j, 0);
            if (e && *e) (void)hv_store_ent(col, *e, newSViv(1), 0);
        }
    }
    (void)hv_stores(h, "opts",
        (database && SvROK(database) && SvTYPE(SvRV(database)) == SVt_PVHV)
            ? newSVsv(database) : newRV_noinc((SV *)newHV()));
    (void)hv_stores(h, "table",   newSVsv(table));
    (void)hv_stores(h, "primary",
        (primary && SvOK(primary)) ? newSVsv(primary) : newSV(0));
    (void)hv_stores(h, "columns",
        (columns && SvROK(columns) && SvTYPE(SvRV(columns)) == SVt_PVAV)
            ? newSVsv(columns) : newRV_noinc((SV *)newAV()));
    (void)hv_stores(h, "col", newRV_noinc((SV *)col));
    (void)hv_stores(h, "returning", newSViv(0));
    return sv_bless(newRV_noinc((SV *)h), gv_stashsv(class, GV_ADD));
}

#endif /* PUNK_DBI_H */
