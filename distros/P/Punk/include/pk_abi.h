#ifndef PK_ABI_H
#define PK_ABI_H

/* Punk's public C ABI - the table a consumer XS module reaches the request
 * through without a Perl frame between the dispatcher and its own code.
 *
 * Resolved at RUNTIME via Punk::_abi_ptr - a DBI-style function-pointer table
 * - so there is no link-time symbol coupling and each dist builds and upgrades
 * independently. A consumer reaches this header through ExtUtils::Depends, or
 * vendors a copy pinned at PK_ABI_VERSION, and checks abi_version at boot; a
 * mismatch means "do without", never a crash.
 *
 * The table only ever grows at the end; PK_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version == the version it was written against
 * (or >=, treating later tables as a superset it uses a prefix of).
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV, AV, HV, IV and pTHX are defined.
 *
 * WHAT THIS IS FOR. Punk already gives Perl the whole request through hooks.
 * This exists for the one thing hooks cannot do cheaply: observe every request
 * from before routing to after the response, on every path, without paying a
 * call_sv per request for the privilege. The motivating consumer is a
 * telemetry layer; nothing here knows what telemetry is.
 *
 * WHAT THIS IS NOT. It is an OBSERVER interface. Nothing here mutates a
 * request or a response: `after_dispatch` already does that, in Perl, where a
 * reader can see it. A consumer that wants to change the answer should use the
 * hook, not this.
 */

/* Version history (append-only; a consumer checks abi_version):
 *   1 - context accessors, route_pattern_of, on_request/on_response
 *   2 - on_query (the shipped Punk::Model::DBI backend)
 *   3 - on_log (a COPY of every log record, for a logs signal) */
#define PK_ABI_VERSION 3

/* An observer of the start of a request. `c` is the request context - the same
 * one the handler will get, so anything left in its stash is there later.
 *
 * Fires before routing, which means before the csrf check, before rate_limit
 * and before the max_body ceiling: the callback sees requests all three will
 * refuse. That is deliberate (a refused request is still a request worth
 * counting) and is the same trade `hook before_request` makes.
 *
 * MUST NOT croak. It runs from the dispatcher, outside any eval frame, and a
 * croak here unwinds the request. */
typedef void (*pk_abi_req_cb)(pTHX_ SV *c, void *ud);

/* An observer of a finished response. `response` is the final PSGI triplet
 * after the after_dispatch hooks have had it - or a streaming coderef, for a
 * detached response, which has no status to read.
 *
 * Fires exactly once per request, on every path: a matched route, an API
 * operation, a mounted PSGI or static app, a 404, a 405, a 413, and a request
 * answered asynchronously (where it fires when the future settles, not when
 * the handler returned it).
 *
 * MUST NOT croak; same reason. */
typedef void (*pk_abi_res_cb)(pTHX_ SV *c, SV *response, void *ud);

/* v2. An observer of a statement run by the SHIPPED Punk::Model::DBI backend.
 *
 * This exists because there are two database paths, not one. DBIx::Loop has
 * its own observer (dbil_abi's on_exec) and an application using the default
 * `model` backend generates no DBIx::Loop traffic at all - so a consumer that
 * registered only there would see nothing, and nothing would say why.
 *
 * `sql` is the statement text and `nbind` the number of bind values. The bind
 * VALUES are deliberately not passed: they are the literal data, and the SQL
 * carries placeholders exactly where they would have been.
 *
 * `start` returns an opaque token handed back to `done` when the statement
 * has run. `ok` is what DBI's execute returned - false means it failed.
 * Neither may croak. */
typedef void *(*pk_abi_query_cb)(pTHX_ const char *sql, STRLEN sql_len,
                                 int nbind, void *ud);
typedef void  (*pk_abi_query_done_cb)(pTHX_ void *token, int ok, void *ud);

/* v3. A COPY of every log record Punk::Logger emits at or above its level.
 *
 * A TAP, not a replacement. The line still goes wherever it was going -
 * stderr, psgix.logger, a `to` coderef - and the observer receives a
 * duplicate. Letting an observer take the sink would mean a telemetry layer
 * silently redirecting an operator's logs, and their vanishing whenever its
 * collector is unreachable. Nobody should have to choose between having their
 * logs and exporting them.
 *
 * `fields` is the record's fields (Punk 0.19's `$c->log->info(\%record)`) or
 * NULL for a plain message. `msg` is the message, before any formatting: an
 * observer wants the record, not a rendered line.
 *
 * Fires only for a line that passed the level threshold - one dropped below
 * it was never a record. MUST NOT croak. */
typedef void (*pk_abi_log_cb)(pTHX_ const char *level, STRLEN llen, SV *msg,
                              HV *fields, void *ud);

typedef struct pk_abi {
    int abi_version;                     /* == PK_ABI_VERSION */

    /* ---- context accessors --------------------------------------------- *
     * All borrowed (no reference count is transferred), all NULL rather than
     * croaking when handed something that is not a context or when the slot
     * is empty. A consumer runs on the request path and must be able to probe
     * safely. */

    SV *(*env_of)(pTHX_ SV *c);          /* the PSGI env hashref */
    SV *(*app_of)(pTHX_ SV *c);          /* the Punk::App */
    SV *(*match_of)(pTHX_ SV *c);        /* { captures, route, operation } */

    /* The context's stash, CREATED if it does not exist yet - a consumer's
     * first act is usually to leave something in it for the response side to
     * find, and it should not have to reach into slot layout to do that. */
    SV *(*stash_of)(pTHX_ SV *c);

    /* ---- routing identity ---------------------------------------------- */

    /* The DECLARED route path - "/users/:id", not "/users/7". This is the
     * whole reason the table is worth publishing: an observer that wants to
     * group by route must have the pattern, and the router is the only thing
     * that knows it. Substituting the request path is how a bounded dimension
     * becomes an unbounded one.
     *
     * NULL when there is no matched route to name: inside a request-start
     * callback (routing has not happened yet), for a 404 or 405, for anything
     * answered by a mount, and for an API operation - which has an operation
     * id instead, below. All four are ordinary states, not errors. */
    SV *(*route_pattern_of)(pTHX_ SV *c);

    /* The OpenAPI operationId for a request answered by an `api` mount, else
     * NULL. The API equivalent of a route pattern, and bounded the same way. */
    SV *(*operation_of)(pTHX_ SV *c);

    /* ---- response ------------------------------------------------------- */

    /* The status of a PSGI triplet, or -1 when there is no status to read
     * (a streaming coderef, or anything that is not a triplet). */
    IV (*status_of)(pTHX_ SV *response);

    /* ---- observers ------------------------------------------------------ *
     * Registration is PROCESS-GLOBAL, not per application: an app is a
     * compiled artifact and there can be several in one process, while an
     * observer is a property of the process. This is the opposite of every
     * other Punk hook and is the one thing about this table worth reading
     * twice.
     *
     * Register at boot. There is no deregistration in v1.
     *
     * Registering EITHER callback makes the dispatcher build the request
     * context up front, so a response callback is guaranteed the same context
     * its request callback saw, on every path. Register neither and nothing is
     * built and nothing is called.
     *
     * Both return 1 when registered and 0 when the table is full
     * (PK_ABI_MAX_OBSERVERS), which a consumer should treat as "do without". */
    int (*on_request)(pTHX_ pk_abi_req_cb cb, void *ud);
    int (*on_response)(pTHX_ pk_abi_res_cb cb, void *ud);

    /* ---- v2 ------------------------------------------------------------- *
     * Observe statements run by the shipped Punk::Model::DBI backend. The
     * OTHER database path, DBIx::Loop, has its own observer in dbil_abi; a
     * consumer wanting to see every query an application makes registers with
     * both, because they are different distributions doing different work.
     * Same contract as above: register at boot, process-global, no
     * deregistration, returns 1 or 0. */
    int (*on_query)(pTHX_ pk_abi_query_cb start, pk_abi_query_done_cb done,
                    void *ud);

    /* ---- v3 ------------------------------------------------------------- *
     * A copy of every log record. Same contract: boot-time, process-global,
     * no deregistration, returns 1 or 0.
     *
     * `trace_id` and `span_id` joined the logger's reserved key set for this:
     * a telemetry layer writes them from the active span, and an application
     * field of the same name would forge a correlation - pointing a reader at
     * somebody else's trace. */
    int (*on_log)(pTHX_ pk_abi_log_cb cb, void *ud);
} pk_abi;

/* How many observers of each kind the dispatcher will hold. Fixed, so
 * registration allocates nothing and the request path walks a small array
 * rather than chasing a list. */
#define PK_ABI_MAX_OBSERVERS 8

#endif /* PK_ABI_H */
