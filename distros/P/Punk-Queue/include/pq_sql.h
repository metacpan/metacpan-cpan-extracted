#ifndef PQ_SQL_H
#define PQ_SQL_H

/* pq_sql.h - SQL text assembly and the name rules.
 *
 * Two jobs. The first is building statement text whose *shape* is stable,
 * because prepare_cached keys on the string: an IN list expanded to a
 * different arity, or a filter built in hash-iteration order, silently
 * produces a new statement handle every call and quietly undoes the cache.
 *
 * The second is the name rule. Queue and task names are validated once, at
 * enqueue, against a deliberately narrow character class. That is not
 * decoration: phase 5 assembles `LISTEN "pq.<queue>"` as an identifier in C,
 * and a name that cannot contain a quote or a backslash makes that safe by
 * construction rather than by remembering to escape at the call site.
 *
 * Include after pq_compat.h. */

/* ---- names ---------------------------------------------------------------- */

#define PQ_NAME_MAX 64

/* [A-Za-z0-9_.:-]{1,64}. Returns 1 if acceptable. */
static int pq_name_ok(pTHX_ SV *sv) {
    STRLEN len, i;
    const char *s;
    if (!sv || !SvOK(sv)) return 0;
    s = SvPV_const(sv, len);
    if (len < 1 || len > PQ_NAME_MAX) return 0;
    for (i = 0; i < len; i++) {
        const char c = s[i];
        if (isWORDCHAR((U8)c) || c == '.' || c == ':' || c == '-') continue;
        return 0;
    }
    return 1;
}

/* Validate or croak, naming the offender and the rule. A bad name is a
 * programming error, caught at enqueue, not something to sanitise silently. */
static void pq_name_check(pTHX_ SV *sv, const char *what) {
    if (!pq_name_ok(aTHX_ sv))
        croak("Punk::Queue: invalid %s name '%s' - 1 to %d characters of "
              "[A-Za-z0-9_.:-]",
              what,
              (sv && SvOK(sv)) ? SvPV_nolen(sv) : "(undef)",
              PQ_NAME_MAX);
}

/* ---- statement text ------------------------------------------------------- */

/* A growable SQL buffer. Mortal SV underneath, so an exception between here
 * and the execute leaks nothing. */
static SV *pq_sql_new(pTHX_ const char *initial) {
    SV *s = sv_2mortal(newSVpv(initial ? initial : "", 0));
    return s;
}

static void pq_sql_cat(pTHX_ SV *sql, const char *frag) {
    sv_catpv(sql, frag);
}

/* Append one buffer to another - the assembled-WHERE case, where the same
 * fragment ends up in both the count and the page statements. */
static void pq_sql_cat_all(pTHX_ SV *sql, SV *frag) {
    sv_catsv(sql, frag);
}

/* Append "?, ?, ?" for n placeholders. n must be >= 1. */
static void pq_sql_placeholders(pTHX_ SV *sql, SSize_t n) {
    SSize_t i;
    for (i = 0; i < n; i++) sv_catpvn(sql, i ? ", ?" : "?", i ? 3 : 1);
}

/* Append "<col> IN (?, ?, ?)" for the n values the caller will bind.
 *
 * Built in C rather than passed as an array bind (`= ANY(?)` on Pg) for two
 * reasons: the array literal needs Pg-specific quoting that has to be right
 * for names containing commas or braces, and it does not port to SQLite. The
 * worker's queue and task sets are fixed at boot, so the arity - and
 * therefore the statement text - is stable for the life of the process. */
static void pq_sql_in(pTHX_ SV *sql, const char *col, SSize_t n) {
    sv_catpv(sql, col);
    sv_catpvs(sql, " IN (");
    pq_sql_placeholders(aTHX_ sql, n);
    sv_catpvs(sql, ")");
}

/* The elements of an arrayref, or a single scalar treated as a one-element
 * list, or NULL for absent. Mortal AV; elements are copies. This is the
 * coercion behind `queues => 'mail'` and `queues => ['mail','sms']` both
 * working. */
static AV *pq_sql_list(pTHX_ SV *v) {
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    if (!v || !SvOK(v)) return out;
    if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {
        AV *in = (AV *)SvRV(v);
        SSize_t n = av_len(in) + 1, i;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(in, i, 0);
            if (e && *e && SvOK(*e)) av_push(out, newSVsv(*e));
        }
    }
    else {
        av_push(out, newSVsv(v));
    }
    return out;
}

#endif /* PQ_SQL_H */
