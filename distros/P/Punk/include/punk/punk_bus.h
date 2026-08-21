/* punk_bus.h - Punk's use of Hyperman's cross-worker message bus.
 *
 * WHAT THIS IS FOR.
 *
 * A prefork server makes anything held in a worker a lie about the pool.
 * Punk::WebSocket::Room said so in its own documentation: a room is per
 * worker, so under `workers => 4` a broadcast reached roughly a quarter of the
 * people in it, the call succeeded, the return value was a plausible number,
 * and nobody was told.
 *
 * Hyperman 0.28 grew the substrate that fixes it - one ring in shared memory,
 * mapped before the fork, reached through hm_abi v5. This is the half that
 * knows what a room is.
 *
 * OPTIONAL, AND LAZILY RESOLVED. A Punk running under a server that is not
 * Hyperman, or under a Hyperman too old to have the bus, keeps working exactly
 * as it did: a broadcast reaches this worker's own members and nothing else,
 * which is the behaviour that existed before any of this. What it does NOT do
 * is pretend - punk_bus_live() is how a caller finds out.
 *
 * THE ONE DELIVERY PATH.
 *
 * A room broadcast publishes, and every worker's subscriber - INCLUDING the
 * publishing worker's own - fans the frame out to its members. The publisher
 * does not also send locally.
 *
 * That is worth being deliberate about, because sending locally and then
 * publishing is the obvious implementation and it is wrong twice over: the
 * origin worker's members would receive the frame twice, and the two paths
 * would drift, so a bug in the shared one would be invisible to whoever tested
 * on a single worker. One path, exercised by everybody.
 */

#ifndef PUNK_BUS_H
#define PUNK_BUS_H

/* The bus arrived in hm_abi v5. Punk compiles against whatever Hyperman
 * header is installed, so this is checked at runtime rather than assumed:
 * a Punk built against v5 may still be loaded beside an older Hyperman. */
#define PUNK_BUS_ABI_MIN 5

static int  PUNK_BUS_READY  = 0;    /* subscriptions registered in this process */
static int  PUNK_BUS_ROOMSUB = -1;  /* the room fanout subscription id */

/* How many members the last local fan reached. broadcast() reads it, because
 * across a pool "how many got it" is otherwise unanswerable at call time and
 * the alternative is to invent a plausible number - which is the exact fault
 * this whole thing exists to remove. */
static IV   PUNK_BUS_LAST_FAN = 0;

/* Is there a pool to talk to at all?
 *
 * False under a non-Hyperman server, an older Hyperman, Windows, or a
 * compiler without the atomics the arena needs. Every one of those is a
 * supported configuration in which a room is simply local, which is what it
 * always was. */
static int punk_bus_live(pTHX) {
    const hm_abi *A = punk_hm(aTHX);
    if (!A || A->abi_version < PUNK_BUS_ABI_MIN || !A->bus_publish) return 0;
    return 1;
}

/* ONE topic for every room, with the room name inside the payload.
 *
 * The obvious design is a topic per room - "punk:ws:lobby" - but the bus
 * matches topics EXACTLY and has no wildcards, deliberately, so that would
 * mean a subscription per room and a registration to add and tear down every
 * time a room came or went. One topic and one subscription instead, with the
 * name length-prefixed ahead of the frame.
 *
 * A length prefix rather than a separator, because a separator has to be a
 * byte a room name cannot contain, and "cannot" is a promise about somebody
 * else's strings that this has no business making.
 *
 *     [u16 name length][name][the encoded WebSocket frame]
 */
#define PUNK_BUS_ROOM_TOPIC     "punk:ws"
#define PUNK_BUS_ROOM_TOPIC_LEN 7

/* Pack a room broadcast. Mortal SV. */
static SV *punk_bus_room_pack(pTHX_ SV *name, SV *frame) {
    STRLEN nl, fl;
    const char *np = SvPV_const(name, nl);
    const char *fp = SvPV_const(frame, fl);
    SV *out;
    unsigned char hdr[2];
    if (nl > 0xFFFF) return NULL;
    hdr[0] = (unsigned char)((nl >> 8) & 0xFF);
    hdr[1] = (unsigned char)(nl & 0xFF);
    out = sv_2mortal(newSVpvn((const char *)hdr, 2));
    sv_catpvn(out, np, nl);
    sv_catpvn(out, fp, fl);
    return out;
}

/* A frame arriving from any worker, including this one.
 *
 * The payload is the ALREADY ENCODED WebSocket frame, so it is encoded once
 * per broadcast rather than once per worker, and every member of the room
 * across the whole pool is sent byte-identical bytes. That is the property
 * pwr_fan was built for; publishing the raw text instead would have thrown it
 * away and re-encoded N times.
 *
 * MUST NOT CROAK: reached from the event loop with no Perl frame to unwind
 * into. Everything here is either C or a call that cannot die.
 */
static void punk_bus_room_cb(pTHX_ const char *topic, STRLEN tlen,
                             const char *payload, STRLEN plen, void *ud) {
    SV *name, *frame, *room;
    STRLEN nl;
    PERL_UNUSED_ARG(topic);
    PERL_UNUSED_ARG(tlen);
    PERL_UNUSED_ARG(ud);

    if (plen < 2) return;
    nl = ((STRLEN)(unsigned char)payload[0] << 8)
       |  (STRLEN)(unsigned char)payload[1];
    if (plen < 2 + nl) return;             /* truncated: refuse to guess */

    name  = sv_2mortal(newSVpvn(payload + 2, nl));
    frame = sv_2mortal(newSVpvn(payload + 2 + nl, plen - 2 - nl));

    /* named() creates the room on first use, which is right: a worker that
     * has never seen this room has no members in it, and fanning to an empty
     * room costs one hash lookup. */
    {
        SV *argv[1];
        argv[0] = name;
        room = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs(PK_WEBSOCKET "::Room")),
                             "named", argv, 1, 1);
    }
    if (!room) return;
    sv_2mortal(room);
    if (!SvOK(room)) return;

    PUNK_BUS_LAST_FAN += pwr_fan(aTHX_ room, frame, NULL);
}

/* Register this worker's subscriptions. Called from the worker hook, so it
 * runs once per worker, after the fork, on the process that will serve. */
static void punk_bus_attach(pTHX) {
    const hm_abi *A;
    if (PUNK_BUS_READY) return;
    A = punk_hm(aTHX);
    if (!A || A->abi_version < PUNK_BUS_ABI_MIN || !A->bus_subscribe) return;
    PUNK_BUS_READY = 1;
    /* One subscription for every room. The topic carries the room name, so a
     * per-room registration would buy nothing and would need tearing down as
     * rooms come and go. */
    PUNK_BUS_ROOMSUB = A->bus_subscribe(aTHX_ PUNK_BUS_ROOM_TOPIC,
                                        PUNK_BUS_ROOM_TOPIC_LEN,
                                        NULL, 0, punk_bus_room_cb, NULL);
}

/* Publish a room broadcast to the pool.
 *
 * Returns 1 when it reached the ring - in which case the caller must NOT also
 * send locally, because this worker's own subscriber will deliver it like
 * everybody else's. Returns 0 when there is no pool, and then the caller does
 * the local send it always did.
 *
 * That is the whole "one delivery path" rule, expressed as a return value. */
static int punk_bus_room_publish(pTHX_ SV *name, SV *frame) {
    const hm_abi *A = punk_hm(aTHX);
    SV *packed;
    STRLEN pl;
    const char *pp;

    /* No subscription in THIS process means nothing here would deliver the
     * frame to this worker's own members - so publishing would serve the rest
     * of the pool and silently skip the people in front of us. Fall back to
     * the local fan instead, which is what a Punk outside a worker does
     * anyway. */
    if (!PUNK_BUS_READY) return 0;
    if (!A || A->abi_version < PUNK_BUS_ABI_MIN || !A->bus_publish) return 0;
    packed = punk_bus_room_pack(aTHX_ name, frame);
    if (!packed) return 0;
    pp = SvPV_const(packed, pl);
    /* A refusal (too big for a slot) is NOT success: the caller falls back to
     * the local send, so the members on this worker still get their frame
     * rather than nobody getting anything. */
    if (A->bus_publish(PUNK_BUS_ROOM_TOPIC, PUNK_BUS_ROOM_TOPIC_LEN, pp, pl)
            != 1)
        return 0;

    /* Run this worker's own subscription NOW, so the local half of the
     * broadcast has happened by the time broadcast() returns and there is a
     * real number to give back. The other workers get it from their wakeup.
     *
     * Still ONE delivery path: this is the same subscriber they run, invoked
     * synchronously rather than from the loop. */
    PUNK_BUS_LAST_FAN = 0;
    if (A->abi_version >= PUNK_BUS_ABI_MIN && A->bus_dispatch)
        (void)A->bus_dispatch(aTHX);
    return 1;
}

/* The hm_abi worker callback: this is what runs inside each worker. */
static void punk_bus_worker_cb(pTHX_ void *loop, void *ud) {
    PERL_UNUSED_ARG(loop);
    PERL_UNUSED_ARG(ud);
    punk_bus_attach(aTHX);
}

/* Ask Hyperman to run punk_bus_attach in every worker.
 *
 * Called from compile(), which runs in the parent before any fork - the only
 * moment a registration reaches every worker. Registering from inside a
 * request would reach exactly one of them, which is the same class of mistake
 * the bus exists to fix. */
static void punk_bus_register(pTHX) {
    const hm_abi *A = punk_hm(aTHX);
    if (!A || A->abi_version < PUNK_BUS_ABI_MIN || !A->on_worker_start) return;
    (void)A->on_worker_start(aTHX_ punk_bus_worker_cb, NULL);
    /* A single-process server never forks and so never fires the hook. It
     * still has a bus (the arena is mapped either way), so attach now as
     * well; punk_bus_attach is idempotent. */
    punk_bus_attach(aTHX);
}

/* ---- the application's own use of the bus -------------------------------- *
 *
 * Rooms are the reason this exists, but they are not the only thing that wants
 * it: a cache key changing, a config being re-read, a presence update. So the
 * same ring is reachable directly.
 *
 * Topics are namespaced away from Punk's own - an application publishing to
 * "punk:ws" would otherwise be handing raw bytes to the room fanout, which
 * expects a length-prefixed name in front of a WebSocket frame. */
#define PUNK_BUS_APP_PREFIX     "app:"
#define PUNK_BUS_APP_PREFIX_LEN 4

static SV *punk_bus_app_topic(pTHX_ SV *topic) {
    STRLEN tl;
    const char *tp = SvPV_const(topic, tl);
    SV *out = sv_2mortal(newSVpvn(PUNK_BUS_APP_PREFIX, PUNK_BUS_APP_PREFIX_LEN));
    sv_catpvn(out, tp, tl);
    return out;
}

/* An application subscription. The coderef is held here, in this process,
 * because a callback cannot cross a fork - the ring is the shared thing, not
 * the list of people reading it.
 *
 * Punk's own cap, not Hyperman's: HM_BUS_SUBS lives in hm_bus.h, which is the
 * implementation rather than the ABI, and Punk consumes the ABI. If Hyperman
 * hands back an id past the end of this table the subscription is refused
 * rather than written out of bounds - a smaller cap here is a limitation, and
 * a missing bounds check is a corruption. */
#define PUNK_BUS_MAX_SUBS 64
static SV *PUNK_BUS_APP_CB[PUNK_BUS_MAX_SUBS];

static void punk_bus_app_cb(pTHX_ const char *topic, STRLEN tlen,
                            const char *payload, STRLEN plen, void *ud) {
    dSP;
    SV *cb = (SV *)ud;
    if (!cb || !SvOK(cb)) return;
    if (tlen < PUNK_BUS_APP_PREFIX_LEN) return;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVpvn(topic + PUNK_BUS_APP_PREFIX_LEN,
                              tlen - PUNK_BUS_APP_PREFIX_LEN)));
    PUSHs(sv_2mortal(newSVpvn(payload, plen)));
    PUTBACK;
    /* G_EVAL: this is reached from the event loop with no Perl frame to
     * unwind into, so a die from a subscriber would take the worker down and
     * quietly remove it from the pool. */
    (void)call_sv(cb, G_VOID | G_DISCARD | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV))
        warn("Punk: bus subscriber for a topic died: %" SVf, SVfARG(ERRSV));
    PUTBACK;
    FREETMPS; LEAVE;
}

/* publish($topic, $payload) -> 1 pool, 0 local-only, -1 too big */
static int punk_bus_app_publish(pTHX_ SV *topic, SV *payload) {
    const hm_abi *A = punk_hm(aTHX);
    SV *t;
    STRLEN tl, pl;
    const char *tp, *pp;
    int r;
    if (!A || A->abi_version < PUNK_BUS_ABI_MIN || !A->bus_publish) return 0;
    t  = punk_bus_app_topic(aTHX_ topic);
    tp = SvPV_const(t, tl);
    pp = SvPV_const(payload, pl);
    r = A->bus_publish(tp, tl, pp, pl);

    /* Deliver to THIS process's own subscribers too.
     *
     * A publisher deliberately does not poke itself - the poke exists to wake
     * somebody else's loop - so without this the publishing worker serves
     * every worker except its own, and its subscribers wait for whatever
     * unrelated event happens to wake them next. With four SSE streams spread
     * over two workers that showed up as one hearing the event and three not,
     * which reads as the bus dropping messages and is nothing of the kind.
     *
     * Same rule the room path already follows, and still one delivery path:
     * this runs the subscriber everybody else runs, synchronously. */
    if (r == 1 && A->bus_dispatch) (void)A->bus_dispatch(aTHX);
    return r;
}

/* subscribe($topic, $cb, $group) -> an id, or -1 */
static int punk_bus_app_subscribe(pTHX_ SV *topic, SV *cb, SV *group) {
    const hm_abi *A = punk_hm(aTHX);
    SV *t;
    STRLEN tl, gl = 0;
    const char *tp, *gp = NULL;
    int id;

    if (!A || A->abi_version < PUNK_BUS_ABI_MIN || !A->bus_subscribe) return -1;
    if (!(cb && SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) return -1;
    t  = punk_bus_app_topic(aTHX_ topic);
    tp = SvPV_const(t, tl);
    if (group && SvOK(group)) gp = SvPV_const(group, gl);

    /* The coderef goes through as the callback's `ud`, which is what that
     * argument is for. Reaching into Hyperman's own subscriber table would
     * need a static it does not export, and would couple Punk to an
     * implementation detail rather than to the ABI. */
    {
        SV *held = newSVsv(cb);
        id = A->bus_subscribe(aTHX_ tp, tl, gp, gl, punk_bus_app_cb,
                              (void *)held);
        if (id < 0 || id >= PUNK_BUS_MAX_SUBS) {
            /* Registered with Hyperman but past this table: hand it back
             * rather than leak the registration or scribble past the end. */
            if (id >= 0 && A->bus_unsubscribe) (void)A->bus_unsubscribe(aTHX_ id);
            SvREFCNT_dec(held);
            return -1;
        }
        if (PUNK_BUS_APP_CB[id]) SvREFCNT_dec(PUNK_BUS_APP_CB[id]);
        PUNK_BUS_APP_CB[id] = held;     /* kept alive for as long as the
                                         * subscription is registered */
    }
    return id;
}

/* ---- cache invalidation -------------------------------------------------- *
 *
 * Its own namespace, separate from application topics and from room frames.
 * A cache invalidating on a topic an application could publish to by accident
 * would be a cache that empties itself when somebody names a topic badly.
 *
 * What travels is the KEY, never the value. Publishing values would make this
 * a replication system - every worker paying to hold everything whether it
 * will be asked for it or not - and a bus slot is 2KB, so a cached page would
 * be refused outright and the pool would silently diverge.
 */
#define PUNK_BUS_CACHE_PREFIX     "pkc:"
#define PUNK_BUS_CACHE_PREFIX_LEN 4

static SV *PUNK_BUS_CACHE_CB[PUNK_BUS_MAX_SUBS];

static SV *punk_bus_cache_topic(pTHX_ SV *name) {
    STRLEN nl;
    const char *np = SvPV_const(name, nl);
    SV *out = sv_2mortal(newSVpvn(PUNK_BUS_CACHE_PREFIX,
                                  PUNK_BUS_CACHE_PREFIX_LEN));
    sv_catpvn(out, np, nl);
    return out;
}

static void punk_bus_cache_cb(pTHX_ const char *topic, STRLEN tlen,
                              const char *payload, STRLEN plen, void *ud) {
    dSP;
    SV *cb = (SV *)ud;
    PERL_UNUSED_ARG(topic);
    PERL_UNUSED_ARG(tlen);
    if (!cb || !SvOK(cb)) return;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpvn(payload, plen)));
    PUTBACK;
    /* G_EVAL: reached from the event loop with no Perl frame to unwind into,
     * and an invalidation that died would take the worker with it. */
    (void)call_sv(cb, G_VOID | G_DISCARD | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV))
        warn("Punk::Cache: an invalidation handler died: %" SVf,
             SVfARG(ERRSV));
    PUTBACK;
    FREETMPS; LEAVE;
}

/* 1 published to the pool, 0 local only. */
static int punk_bus_cache_publish(pTHX_ SV *name, SV *key) {
    const hm_abi *A = punk_hm(aTHX);
    SV *t;
    STRLEN tl, kl;
    const char *tp, *kp;
    if (!A || A->abi_version < PUNK_BUS_ABI_MIN || !A->bus_publish) return 0;
    t  = punk_bus_cache_topic(aTHX_ name);
    tp = SvPV_const(t, tl);
    kp = SvPV_const(key, kl);
    return A->bus_publish(tp, tl, kp, kl) == 1;
}

static int punk_bus_cache_subscribe(pTHX_ SV *name, SV *cb) {
    const hm_abi *A = punk_hm(aTHX);
    SV *t, *held;
    STRLEN tl;
    const char *tp;
    int id;

    if (!A || A->abi_version < PUNK_BUS_ABI_MIN || !A->bus_subscribe) return -1;
    if (!(cb && SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) return -1;
    t  = punk_bus_cache_topic(aTHX_ name);
    tp = SvPV_const(t, tl);

    held = newSVsv(cb);
    id = A->bus_subscribe(aTHX_ tp, tl, NULL, 0, punk_bus_cache_cb,
                          (void *)held);
    if (id < 0 || id >= PUNK_BUS_MAX_SUBS) {
        if (id >= 0 && A->bus_unsubscribe) (void)A->bus_unsubscribe(aTHX_ id);
        SvREFCNT_dec(held);
        return -1;
    }
    if (PUNK_BUS_CACHE_CB[id]) SvREFCNT_dec(PUNK_BUS_CACHE_CB[id]);
    PUNK_BUS_CACHE_CB[id] = held;
    return id;
}

#endif /* PUNK_BUS_H */
