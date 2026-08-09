#ifndef PQ_HM_H
#define PQ_HM_H

/* The Hyperman C ABI, resolved lazily and optionally.
 *
 * Hyperman is a SOFT dependency: the worker has a complete poll(2) path
 * without it, and the loop's only job is letting task code await futures in
 * loop mode. Hence the DBIx::Loop consumption pattern rather than Punk's -
 * a vendored include/hm_abi.h pinned at version 2 and no build-time
 * dependency at all, resolved at runtime through Hyperman::_abi_ptr with a
 * `>=` gate (hm_abi documents its table as append-only, so a newer provider
 * keeps working against our older header).
 *
 * pq_hm() returns NULL to degrade, never croaks. PUNK_QUEUE_NO_HM_ABI=1
 * forces NULL, which is the test seam for the degraded path.
 *
 * Include after pq_compat.h and hm_abi.h. */

static const hm_abi *PQ_HM = NULL;
static int PQ_HM_TRIED = 0;

static const hm_abi *pq_hm(pTHX) {
    if (!PQ_HM && !PQ_HM_TRIED) {
        dSP; int count; IV p = 0;
        PQ_HM_TRIED = 1;
        {
            const char *no = PerlEnv_getenv("PUNK_QUEUE_NO_HM_ABI");
            if (no && *no && strNE(no, "0")) return NULL;
        }
        eval_pv("require Hyperman;", FALSE);
        /* The require runs arbitrary Perl. If that grew the value stack it
         * was reallocated, and the SP captured by dSP above now points into
         * the freed block - which the PUTBACK below would publish as
         * PL_stack_sp. */
        SPAGAIN;
        if (!SvTRUE(ERRSV)) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("Hyperman::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const hm_abi *a = INT2PTR(const hm_abi *, p);
                if (a && a->abi_version >= HM_ABI_VERSION) PQ_HM = a;
            }
        }
    }
    return PQ_HM;
}

#endif /* PQ_HM_H */
