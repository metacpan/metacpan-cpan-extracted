#ifndef PQ_LOG_H
#define PQ_LOG_H

/* pq_log.h - per-job log lines (schema step 3, pq_job_logs).
 *
 * Two writers: the transitions log their own lifecycle - claimed,
 * finished, attempt failed with the retry it scheduled, terminal
 * failure, operator retry - and the task body writes whatever it wants
 * through $job->log. The lifecycle rows are gated on the `logging`
 * backend option (default on) so a throughput-sensitive queue can shed
 * them; an explicit $job->log always writes, because a call the task
 * author typed is not noise.
 *
 * Rows live and die with their job: remove_job and repair's ancient
 * sweep cascade here, repair also sweeps orphans, and reset empties the
 * table. Retention is therefore the job's retention - inspecting a
 * finished job shows its whole story across every attempt, until
 * remove_after reaps the job itself.
 *
 * Include after pq_job.h (uses its hv helpers), before pq_backend.h
 * (whose transitions call these). */

static const char *pq_log_level(pTHX_ const char *l) {
    if (!l || !*l) return "info";
    if (strEQ(l, "debug") || strEQ(l, "info")
        || strEQ(l, "warn") || strEQ(l, "error"))
        return l;
    croak("Punk::Queue: log level must be debug, info, warn or error, "
          "not '%s'", l);
    return NULL; /* not reached */
}

static int pq_logging_on(pTHX_ SV *self) {
    return pq_opt_num(aTHX_ self, "logging", 1.0) != 0.0;
}

/* the one insert every writer funnels through */
static void pq_log_add(pTHX_ SV *self, IV id, const char *level, SV *msg) {
    AV *b = pq_binds(aTHX);
    pq_bind_iv(aTHX_ b, id);
    pq_bind_nv(aTHX_ b, pq_now(aTHX_ self));
    pq_bind_sv(aTHX_ b, sv_2mortal(newSVpv(pq_log_level(aTHX_ level), 0)));
    pq_bind_sv(aTHX_ b, msg);
    (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
        "INSERT INTO pq_job_logs (job_id, created, level, message)"
        " VALUES (?, ?, ?, ?)")), b);
}

/* lifecycle rows: printf-formatted, dropped when logging is off */
static void pq_log_addf(pTHX_ SV *self, IV id, const char *level,
                        const char *pat, ...) {
    SV *msg;
    va_list args;
    if (!pq_logging_on(aTHX_ self)) return;
    va_start(args, pat);
    msg = sv_2mortal(Perl_vnewSVpvf(aTHX_ pat, &args));
    va_end(args);
    pq_log_add(aTHX_ self, id, level, msg);
}

/* an error SV as a bounded, newline-stripped C string for the lifecycle
 * messages; refs go through their JSON so a structured die is readable */
#define PQ_LOG_ERRMAX 500
static const char *pq_log_errpv(pTHX_ SV *err, char *buf, size_t max) {
    STRLEN len;
    const char *p;
    SV *src = err;
    if (!src || !SvOK(src)) return "unknown error";
    if (SvROK(src))
        src = sv_2mortal(pq_json_encode(aTHX_ src, "null"));
    p = SvPV(src, len);
    while (len && (p[len - 1] == '\n' || p[len - 1] == '\r')) len--;
    if (len > max - 4) {
        memcpy(buf, p, max - 4);
        memcpy(buf + max - 4, "...", 4);
    }
    else {
        memcpy(buf, p, len);
        buf[len] = 0;
    }
    return buf;
}

/* the whole log for one job, oldest first. +1, caller owns. */
static AV *pq_job_log_rows(pTHX_ SV *self, IV id) {
    AV *out = newAV();
    AV *b = pq_binds(aTHX), *row;
    SV *sth;
    pq_bind_iv(aTHX_ b, id);
    sth = pq_sth(aTHX_ self, sv_2mortal(newSVpvs(
        "SELECT created, level, message FROM pq_job_logs"
        " WHERE job_id = ? ORDER BY id")));
    (void)pq_execute(aTHX_ sth, b);
    while ((row = pq_fetchrow(aTHX_ sth))) {
        HV *h = newHV();
        pq_hv_set_nv_or_undef(aTHX_ h, "created", pq_col(aTHX_ row, 0));
        pq_hv_set_sv(aTHX_ h, "level",   pq_col(aTHX_ row, 1));
        pq_hv_set_sv(aTHX_ h, "message", pq_col(aTHX_ row, 2));
        av_push(out, newRV_noinc((SV *)h));
        SvREFCNT_dec((SV *)row);
    }
    { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
      if (r) SvREFCNT_dec(r); }
    return out;
}

#endif /* PQ_LOG_H */
