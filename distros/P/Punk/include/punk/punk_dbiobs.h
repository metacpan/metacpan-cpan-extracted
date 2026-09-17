/* punk_dbiobs.h - Punk::DBI, the observed DBI handle.
 *
 * pk_abi's query observer used to fire from Punk::Model::DBI's six generated
 * methods, which are a LAYER ABOVE the handle: an application reaching through
 * to $model->backend->dbh for an OR, a UNION, a FOR UPDATE or an upsert ran
 * statements no observer could see, and nothing said so. These wrappers sit on
 * the handle instead, so every statement is seen however it was asked for.
 *
 * Included by Punk.xs after punk_obs.h (the registry) and punk_context.h.
 */

#ifndef PUNK_DBIOBS_H
#define PUNK_DBIOBS_H

/* The database-handle methods DBI implements in its own dispatch rather than
 * through the public prepare/execute pair, with where the bind values start
 * counting from ST(0).
 *
 * The offsets are not all the same, and guessing one is how a bind count ends
 * up off by one: selectall_hashref takes a key field between the statement and
 * the attributes, and nothing else here does.
 *
 * ST(0) is the handle, ST(1) the statement, so `do($sql, \%attr, @bind)` has
 * its binds from ST(3) on. */
typedef struct { const char *super; int bind_from; } punk_dbiobs_m;

static const punk_dbiobs_m PUNK_DBIOBS[] = {
    { "DBI::db::do",                 3 },
    { "DBI::db::selectall_arrayref", 3 },
    { "DBI::db::selectall_hashref",  4 },
    { "DBI::db::selectcol_arrayref", 3 },
    { "DBI::db::selectrow_array",    3 },
    { "DBI::db::selectrow_arrayref", 3 },
    { "DBI::db::selectrow_hashref",  3 }
};

/* ONE REPORT PER STATEMENT, AT THE OUTERMOST LEVEL.
 *
 * Whether DBI answers a select* or a do natively or falls back to prepare and
 * execute is a per-driver, per-call detail: DBD::SQLite runs a bind-free `do`
 * itself and takes the prepare/execute path the moment there is a placeholder.
 * Without this the same statement is reported once or twice depending on
 * whether it had binds, and every duration is double counted on the branch
 * that did. The caller asked for selectall_arrayref; that is the statement. */
static int PUNK_DBIOBS_IN = 0;

static void punk_dbiobs_leave(pTHX_ void *p) {
    PERL_UNUSED_CONTEXT;
    PUNK_DBIOBS_IN = PTR2IV(p);
}

/* The statement text out of the first argument, which every one of these also
 * accepts as an already-prepared handle. Borrowed, and mortal when fetched. */
static SV *punk_dbiobs_sql(pTHX_ SV *first) {
    SV *argv[1], *st;
    if (!first) return NULL;
    SvGETMAGIC(first);
    if (!SvROK(first)) return first;
    /* a statement handle in the statement's place: ask it, through magic,
     * for what it prepared */
    argv[0] = sv_2mortal(newSVpvs("Statement"));
    st = pcx_call_meth(aTHX_ first, "FETCH", argv, 1, 1);
    return st ? sv_2mortal(st) : NULL;
}

/* The CV of a DBI superclass method, resolved once per slot. Croaks rather
 * than silently doing nothing: a missing DBI method means this subclass is
 * wrong about what it wraps, and a statement that quietly did not run is far
 * worse than one that said so. */
static CV *PUNK_DBIOBS_CV[8];

static CV *punk_dbiobs_super(pTHX_ int slot, const char *name) {
    if (!PUNK_DBIOBS_CV[slot]) {
        CV *cv = get_cv(name, 0);
        if (!cv) croak("Punk::DBI: %s is not there to wrap", name);
        PUNK_DBIOBS_CV[slot] = cv;
    }
    return PUNK_DBIOBS_CV[slot];
}

#endif /* PUNK_DBIOBS_H */
