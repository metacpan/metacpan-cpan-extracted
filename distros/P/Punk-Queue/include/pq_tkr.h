#ifndef PQ_TKR_H
#define PQ_TKR_H

/* The Time::Keeper::Recurrence C ABI, resolved lazily and optionally.
 *
 * Time::Keeper::Recurrence is a SOFT dependency, as Hyperman is (pq_hm.h):
 * the cron walk is complete without it for UTC, local and +HHMM. With it,
 * a cron's tz may also be an IANA zone name (America/New_York), whose
 * occurrences come from its cron_next: Punk::Queue's own grammar, walked
 * through the zone database with the same DST answers as 'local' (a time
 * in the spring-forward gap does not fire; in the doubled hour a pinned
 * time fires once, at the first instance, and an every-minute spec every
 * real minute). Vendored headers pinned at version 1, a `>=` gate.
 *
 * pq_tkr() returns NULL to degrade, never croaks. PUNK_QUEUE_NO_RECURRENCE=1
 * forces NULL, which is the test seam for the path without it.
 *
 * Include after pq_compat.h and time_keeper_recurrence_abi.h. */

static const time_keeper_recurrence_abi *PQ_TKR = NULL;
static int PQ_TKR_TRIED = 0;

static const time_keeper_recurrence_abi *pq_tkr(pTHX) {
    if (!PQ_TKR && !PQ_TKR_TRIED) {
        SV *sv;
        PQ_TKR_TRIED = 1;
        {
            const char *no = PerlEnv_getenv("PUNK_QUEUE_NO_RECURRENCE");
            if (no && *no && strNE(no, "0")) return NULL;
        }
        ENTER;
        save_scalar(PL_errgv);     /* the caller's $@ survives the require */
        sv = eval_pv("require Time::Keeper::Recurrence; Time::Keeper::Recurrence::_abi_ptr()", FALSE);
        if (!SvTRUE(ERRSV) && sv && SvOK(sv)) {
            UV p = SvUV(sv);
            const time_keeper_recurrence_abi *a = INT2PTR(const time_keeper_recurrence_abi *, p);
            if (TIME_KEEPER_RECURRENCE_ABI_OK(a)) PQ_TKR = a;
        }
        LEAVE;
    }
    return PQ_TKR;
}

#endif /* PQ_TKR_H */
