/* punk_sessionstore.h - where a server-side session lives.
 *
 * `session store => ...` moves the payload off the client: the cookie carries
 * an id, the session itself sits in a store. This file is the seam - it turns
 * whatever the keyword was given into a Punk::Cache handle at to_app, and
 * refuses at boot the configurations that would fail as a random logout at
 * three in the morning.
 *
 * The store contract is Punk::Cache's, deliberately, and there is no second
 * one: a Redis or DBI backend implements get/set/delete/clear/stats because it
 * already had to, so one module serves `cache`, Idempotency and this. What
 * that reuse costs is that a cache is allowed to FORGET, and a forgotten
 * session is somebody logged out - which is why the documentation says to give
 * sessions their own store, sized to hold every live one.
 *
 * Must be included after punk_cachefront.h (pkc_can) and punk_session.h
 * (ps_cfg_iv).
 */

#ifndef PUNK_SESSIONSTORE_H
#define PUNK_SESSIONSTORE_H

/* The resolved handle, on the session config under a reserved key. Reserved
 * rather than replacing `store`: resolving is then idempotent, and the spec
 * stays visible for anything that wants to report what was asked for. */
#define PK_SESSION_STORE     "punk.store"
#define PK_SESSION_STORE_LEN 10

/* The name a privately built store is registered under - its own invalidation
 * topic, separate from any cache the application declared. */
#define PK_SESSION_STORE_NAME "session"

/* ---- the id ---------------------------------------------------------------- *
 *
 * With a cookie session, forging one means forging an HMAC. With a server-side
 * session it means GUESSING AN ID, so the id is the whole authentication and
 * everything here is downstream of that sentence.
 *
 * 128 bits from a CSPRNG, and nothing derived from anything the user supplies:
 * an id that encodes the account is an id an attacker can construct.
 *
 * The bytes come from pk_ent_take (punk_entropy.h) rather than a fresh draw,
 * for both of the reasons that helper exists. `getentropy` costs the same for
 * 16 bytes as for 256, so drawing per id is 17x the cost for nothing; and a
 * buffer filled before `fork` hands every worker the same bytes - measured
 * while building RequestId at 767 duplicates in 8000 across four workers, and
 * it looks perfectly random the whole time. A duplicate request id is a
 * nuisance. A duplicate session id is one user handed another user's session,
 * which is the worst bug this distribution could ship, so the pid guard is the
 * load-bearing half and the reason not to hand-roll a draw here. */

#define PK_SESSION_ID       "punk.id"
#define PK_SESSION_ID_LEN   7
#define PK_SESSION_ID_BYTES 16                 /* 128 bits */
#define PK_SESSION_ID_HEX   (PK_SESSION_ID_BYTES * 2)

static SV *ps_new_id(pTHX) {
    static const char hex[] = "0123456789abcdef";
    unsigned char raw[PK_SESSION_ID_BYTES];
    char out[PK_SESSION_ID_HEX];
    int i;
    pk_ent_take(aTHX_ raw, sizeof raw);
    for (i = 0; i < PK_SESSION_ID_BYTES; i++) {
        out[2 * i]     = hex[raw[i] >> 4];
        out[2 * i + 1] = hex[raw[i] & 0x0f];
    }
    return newSVpvn(out, sizeof out);          /* +1 */
}

/* The shape, checked before an id is ever used as a store key.
 *
 * The signature has already rejected anything this server did not mint, so
 * this is not what keeps a guess out - it is what keeps a session written by
 * hand, or by a later bug, from reaching a backend as a key of some other
 * shape. Thirty-two byte comparisons, once per request.
 *
 * Not constant time, deliberately, and worth writing down because the next
 * reader will wonder: an id is never compared against a stored secret here.
 * It is a key, and the comparison that decides anything happens inside the
 * backend - the file store compares the key it read against the key it was
 * asked for, so a hash collision is a miss rather than a wrong answer. That
 * compare is not constant time either, and making every backend promise it
 * would be a sixth thing on the contract. What protects the keyspace is the
 * signature, which IS constant time (pk_ct_eq), and which an attacker has to
 * beat before any of this is reached. */
static int ps_id_ok(const char *s, STRLEN len) {
    STRLEN i;
    if (len != PK_SESSION_ID_HEX) return 0;
    for (i = 0; i < len; i++)
        if (!((s[i] >= '0' && s[i] <= '9') || (s[i] >= 'a' && s[i] <= 'f')))
            return 0;
    return 1;
}

/* ---- the id in the cookie -------------------------------------------------- *
 *
 * The cookie still carries a SIGNED payload, and the payload is still JSON
 * with the expiry stamped inside it. Only its contents shrink: one reserved
 * key holding the id, where the whole session used to be.
 *
 * Keeping the format buys three things at the cost of about sixty bytes on the
 * wire. The signer, the verifier and the expiry check are the ones already in
 * service, so there is no second crypto path to keep in step. The 0.19 expiry
 * stamp keeps applying, so a cookie past its lifetime is refused rather than
 * looked up. And phase 2 changes only what goes INTO the payload.
 *
 * The signature is not protecting a secret any more - an id is not one - so it
 * would be easy to argue away. It stays because an unsigned id turns the store
 * into an ORACLE: anyone could send a guess and make the server do a lookup
 * for it, which is a cheap denial of service against a network store, a way to
 * litter a file store with lock files, and a timing channel that distinguishes
 * a hit from a miss. One HMAC refuses every guess before it costs a round
 * trip. */

/* the cookie value for an id (+1): {"punk.id":..., "punk.exp":...}, signed */
static SV *ps_id_seal(pTHX_ SV *id, const char *key, STRLEN kl, IV ttl) {
    HV *payload = newHV();
    SV *prv, *json;
    if (ttl <= 0) ttl = PK_SESSION_MAX_LIFETIME;
    (void)hv_store(payload, PK_SESSION_ID, PK_SESSION_ID_LEN, newSVsv(id), 0);
    (void)hv_store(payload, PK_SESSION_EXP, PK_SESSION_EXP_LEN,
                   newSViv((IV)time(NULL) + ttl), 0);
    prv  = sv_2mortal(newRV_noinc((SV *)payload));
    json = sv_2mortal(ps_encode(aTHX_ prv));
    return pk_session_sign(aTHX_ json, key, kl);
}

/* the id inside a cookie value (+1), or NULL for anything that is not one:
 * a bad signature, a payload past its stamped expiry, or an id whose shape
 * says it was not minted here. A caller does not need to know which - all
 * three mean "no session", and telling them apart is a distinction useful
 * only to somebody probing. */
static SV *ps_id_unseal(pTHX_ const char *cv, STRLEN cvl,
                        const char *key, STRLEN kl) {
    SV *payload, *decoded, *id = NULL;
    if (!(cv && cvl && kl)) return NULL;
    payload = pk_session_verify(aTHX_ cv, cvl, key, kl);
    if (!payload) return NULL;
    sv_2mortal(payload);
    decoded = punk_frj(aTHX)->decode(aTHX_ SvPVX(payload), SvCUR(payload), NULL);
    if (!decoded) return NULL;
    sv_2mortal(decoded);
    if (SvROK(decoded) && SvTYPE(SvRV(decoded)) == SVt_PVHV) {
        HV *dh = (HV *)SvRV(decoded);
        SV **ep = hv_fetch(dh, PK_SESSION_EXP, PK_SESSION_EXP_LEN, 0);
        SV **ip = hv_fetch(dh, PK_SESSION_ID, PK_SESSION_ID_LEN, 0);
        if (ep && *ep && SvOK(*ep) && SvIV(*ep) <= (IV)time(NULL)) return NULL;
        if (ip && *ip && SvOK(*ip)) {
            STRLEN l;
            const char *s = SvPV_const(*ip, l);
            if (ps_id_ok(s, l)) id = newSVpvn(s, l);
        }
    }
    return id;                                 /* +1, or NULL */
}

/* ---- the memory tier, and why a session goes round it ---------------------- *
 *
 * `Punk::Cache`'s `memory` option puts a per-worker copy in front of a shared
 * store. For a cache that is the right trade. For a session it is a bound on
 * HOW LONG A REVOKED SESSION KEEPS WORKING - a worker that missed the
 * invalidation answers from its own copy for up to `memory_ttl`, and the copy
 * it answers with is the session before the logout.
 *
 * Be accurate about the other direction while here, because the loose version
 * of this argument is wrong: a tier MISS falls through to the backend, so a
 * tier can never manufacture a missing session. The hazard is staleness in one
 * direction only, and it is authentication staleness.
 *
 * So a session read goes straight to the backend by default, the way
 * Punk::Plugin::Idempotency reaches past the tier for its own keys. An
 * application's `memory => '64M'` stays honoured for everything else.
 *
 * WRITES are not routed around it. `set` and `delete` on the front already do
 * the right thing in both modes: the backend changes, this worker's tier copy
 * is dropped, and an invalidation is published so the other workers drop
 * theirs. Reaching past that would leave the local copy stale, which is the
 * one thing worse than reading through it. */
#define PK_SESSION_TIER_MAX 5              /* seconds a revocation may lag */

static SV *ps_store_get(pTHX_ SV *store, SV *key, int use_tier) {
    punk_cachefront *f = pkc_of(aTHX_ store);
    return use_tier ? pkc_read(aTHX_ f, key)
                    : pkc_be_get(aTHX_ f, key, NULL);
}

/* The stores the `cache` keyword built, or NULL when there are none. */
static HV *ps_built_stores(pTHX_ HV *h) {
    SV **b = hv_fetchs(h, "cache", 0);
    return (b && *b && SvROK(*b) && SvTYPE(SvRV(*b)) == SVt_PVHV)
        ? (HV *)SvRV(*b) : NULL;
}

/* Punk::Cache->_from_spec($backend, \%opts, 'session') - the same constructor
 * the `cache` keyword's own stores go through, so a session store is built by
 * one code path and not by a second parser that drifts from it. */
static SV *ps_store_build(pTHX_ SV *spec, SV *opts) {
    SV *argv[3];
    SV *store;
    argv[0] = spec ? spec : &PL_sv_undef;
    argv[1] = opts ? opts : &PL_sv_undef;
    argv[2] = sv_2mortal(newSVpvs(PK_SESSION_STORE_NAME));
    (void)pk_require_once(aTHX_ "Punk::Cache", TRUE);
    store = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Punk::Cache")),
                          "_from_spec", argv, 3, 1);
    if (!(store && SvOK(store))) {
        if (store) SvREFCNT_dec(store);
        croak("Punk: `session store` could not build a store");
    }
    return store;                                          /* +1 */
}

/* Whether a session written here can be read from another worker.
 *
 * The question is asked of the BACKEND, never of the front's `stats`. The
 * front reports `shared` as "the backend is shared AND there is no tier",
 * which is the right answer to its own question - a tiered store needs
 * invalidation traffic - and the wrong answer to this one: a tiered file store
 * is perfectly capable of holding a session, and refusing it at boot would be
 * a bug fixed by deleting the check. */
static int ps_store_shared(pTHX_ SV *store) {
    SV *backend = pcx_call_meth(aTHX_ store, "backend", NULL, 0, 1);
    int shared = 0;
    if (backend) {
        if (SvOK(backend) && pkc_can(aTHX_ backend, "is_shared")) {
            SV *r = pcx_call_meth(aTHX_ backend, "is_shared", NULL, 0, 1);
            if (r) {
                shared = SvTRUE(r) ? 1 : 0;
                SvREFCNT_dec(r);
            }
        }
        SvREFCNT_dec(backend);
    }
    return shared;
}

/* A store the `cache` keyword declared, by name.
 *
 * `cache` is the reserved spelling for the default store, because "the cache"
 * is what an application with one store calls it and `default` - the name it
 * is actually built under - is an internal detail nobody should have to know.
 * A store genuinely declared under that name is refused rather than guessed
 * at, naming both readings. */
static SV *ps_store_named(pTHX_ HV *h, SV *spec) {
    STRLEN nl;
    const char *name = SvPV_const(spec, nl);
    HV *stores = ps_built_stores(aTHX_ h);
    int is_the_default = (nl == 5 && memEQ(name, "cache", 5));
    SV **slot;

    /* `store:` in a YAML config with nothing after it. Absent means the cookie
     * session, which is a decision; empty is a line somebody meant to fill in,
     * and reading it as "the cookie" is the silent failure this whole check
     * exists to prevent. */
    if (!nl)
        croak("Punk: `session store` is empty - name a store, or leave the "
              "option out entirely for the cookie session");

    if (!stores)
        croak("Punk: `session store => '%s'` needs a store to point at, and "
              "this application declares none - add a `cache` keyword",
              name);

    if (is_the_default) {
        if (hv_exists(stores, "cache", 5))
            croak("Punk: `session store => 'cache'` is the DEFAULT store, but "
                  "this application also declares one named `cache` - rename "
                  "that store, since the two readings cannot both be right");
        slot = hv_fetch(stores, K_DEFAULT, sizeof(K_DEFAULT) - 1, 0);
        if (!(slot && *slot && SvROK(*slot)))
            croak("Punk: `session store => 'cache'` is the default store, and "
                  "this application declares only named ones - either add "
                  "`cache 'file', dir => ...` or name the store the session "
                  "should use");
    }
    else {
        slot = hv_fetch(stores, name, (I32)nl, 0);
        if (!(slot && *slot && SvROK(*slot)))
            croak("Punk: `session store => '%s'` names a store that was never "
                  "declared - add `cache %s => { backend => ... }`, or use "
                  "`store => 'cache'` for the default one. A session store "
                  "that silently never hits looks like a login page that "
                  "forgets everybody", name, name);
    }
    return newSVsv(*slot);                                 /* +1 */
}

/* Resolve `session store => ...` into a handle on the session config.
 *
 * Runs at to_app, and it has to run AFTER the `cache` keyword's stores are
 * built: it resolves names out of that hash, so a resolution that goes first
 * finds an empty one and every declared store looks like a typo. */
static void ps_store_resolve(pTHX_ HV *h) {
    SV **sc = hv_fetchs(h, "session", 0);
    HV *cfg;
    SV **sp;
    SV *spec, *store;

    if (!(sc && *sc && SvROK(*sc) && SvTYPE(SvRV(*sc)) == SVt_PVHV)) return;
    cfg = (HV *)SvRV(*sc);
    sp = hv_fetchs(cfg, "store", 0);
    if (!(sp && *sp && SvOK(*sp))) return;      /* no store: the cookie, as before */
    spec = *sp;

    /* The four forms, told apart by what the value IS rather than by reading a
     * string and guessing. A rule that inspects the string to decide whether
     * it names a declared store or a class is a rule that eventually guesses
     * wrong on somebody's store named `file`.
     *
     * BLESSED FIRST. Nearly every object is a hashref underneath, so a test
     * for SVt_PVHV alone claims the object form as a spec, finds no `backend`
     * key in it and quietly builds a file store instead of using the store it
     * was handed - a backend swapped out under an application that named one.
     * The `cache` keyword shipped that exact bug once already. */
    if (SvROK(spec) && SvOBJECT(SvRV(spec))) {
        /* a ready-made object: _from_spec checks the five methods on it the
         * same way it checks any other backend */
        store = ps_store_build(aTHX_ spec, NULL);
    }
    else if (SvROK(spec) && SvTYPE(SvRV(spec)) == SVt_PVHV) {
        /* a plain hashref: built here, in the shape `cache` already takes for
         * a named store, so there is nothing new to learn */
        HV *opts = (HV *)SvRV(spec);
        SV **b = hv_fetchs(opts, "backend", 0);
        store = ps_store_build(aTHX_ (b && *b && SvOK(*b)) ? *b : NULL, spec);
    }
    else if (SvROK(spec)) {
        croak("Punk: `session store` takes the name of a store, a hashref "
              "describing one, or a store object - not a %s reference",
              sv_reftype(SvRV(spec), 0));
    }
    else {
        store = ps_store_named(aTHX_ h, spec);
    }
    sv_2mortal(store);

    /* A store that is not shared between workers cannot hold a session. Not
     * "is slower" and not "is eventually consistent": the session written on
     * worker A is ABSENT on worker B, so the user is logged out on whichever
     * request the pool sends elsewhere, at random, forever.
     *
     * allow_unshared is how somebody says there is only one process - the test
     * suite, a dev server, a single-worker deployment - which is a thing only
     * the person deploying knows. */
    if (!ps_store_shared(aTHX_ store) && !ps_cfg_iv(aTHX_ cfg, "allow_unshared", 0))
        croak("Punk: the session store reports that it is not shared between "
              "workers, so a session written on one worker would be missing "
              "on the next - a logout at random, once per request. Use a "
              "shared store (the `file` one is), or `allow_unshared => 1` if "
              "this process is the only one");

    /* The tier, if the application opted into one for its sessions. The
     * number is what the operator is prepared to have a revocation lag by,
     * and both halves of it are checked here rather than discovered when
     * somebody logs out and stays logged in. */
    {
        IV tier = ps_cfg_iv(aTHX_ cfg, "tier", 0);
        if (tier) {
            punk_cachefront *f = pkc_of(aTHX_ store);
            if (tier < 0 || tier > PK_SESSION_TIER_MAX)
                croak("Punk: `session tier => %" IVdf "` is how many seconds a "
                      "revoked session may keep working on a worker that "
                      "missed the invalidation, and %d is the most this will "
                      "accept - a logout that lags longer than that is not a "
                      "logout", tier, PK_SESSION_TIER_MAX);
            if (!f->tier)
                croak("Punk: `session tier => %" IVdf "` asks to read sessions "
                      "through a memory tier, and this store has none - add "
                      "`memory => '8M'` to the cache, or drop the option",
                      tier);
            if (f->tier_ttl > (double)tier)
                croak("Punk: `session tier => %" IVdf "` accepts a %" IVdf
                      "-second lag on a revocation, but the store's "
                      "memory_ttl is %d seconds - lower memory_ttl, or say "
                      "what you actually accept", tier, tier,
                      (int)f->tier_ttl);
        }
    }

    (void)hv_store(cfg, PK_SESSION_STORE, PK_SESSION_STORE_LEN,
                   SvREFCNT_inc(store), 0);
}

#endif /* PUNK_SESSIONSTORE_H */
