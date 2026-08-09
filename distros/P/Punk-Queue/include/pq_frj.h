#ifndef PQ_FRJ_H
#define PQ_FRJ_H

/* The File::Raw::JSON C ABI - the codec for a job's args, result and notes.
 *
 * Resolved lazily on first use from File::Raw::JSON::_abi_ptr, the consumer
 * pattern every dist in this ecosystem uses. File::Raw::JSON is a hard
 * PREREQ and the gate is `==` (frj's table is not documented as append-only
 * the way hm_abi's is), so a mismatch is a startup-environment error and
 * croaks rather than degrading.
 *
 * Include after pq_compat.h and frj_abi.h. */

static const frj_abi *PQ_FRJ = NULL;
static int PQ_FRJ_TRIED = 0;

static const frj_abi *pq_frj(pTHX) {
    if (!PQ_FRJ && !PQ_FRJ_TRIED) {
        dSP; int count; IV p = 0;
        PQ_FRJ_TRIED = 1;
        eval_pv("require File::Raw::JSON;", FALSE);
        /* The require runs arbitrary Perl. If that grew the value stack it
         * was reallocated, and the SP captured by dSP above now points into
         * the freed block - which the PUTBACK below would publish as
         * PL_stack_sp. */
        SPAGAIN;
        if (!SvTRUE(ERRSV)) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("File::Raw::JSON::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const frj_abi *a = INT2PTR(const frj_abi *, p);
                if (a && a->abi_version == FRJ_ABI_VERSION) PQ_FRJ = a;
            }
        }
    }
    if (!PQ_FRJ)
        croak("Punk::Queue needs File::Raw::JSON with a compatible C ABI "
              "(FRJ_ABI_VERSION %d)", FRJ_ABI_VERSION);
    return PQ_FRJ;
}

/* Encode a Perl value to JSON. Returns +1, caller owns. `fallback` is
 * emitted when the value is undef, which is how an absent args list becomes
 * "[]" and absent notes become "{}" without a branch at every call site.
 *
 * frj returns UTF-8 *bytes* with the UTF8 flag off. That is exactly wrong
 * for a DBI bind: DBD::Pg upgrades an unflagged string as if it were
 * latin-1 on the way to a UTF-8 database, double-encoding every multibyte
 * character, while DBD::SQLite stores the bytes verbatim - so the same
 * payload would round-trip differently per backend, which is the one thing
 * the conformance suite exists to forbid. sv_utf8_decode turns the bytes
 * into the character string they spell (validating as it goes; frj output
 * is guaranteed well-formed), after which every driver agrees on what is
 * being stored. */
static SV *pq_json_encode(pTHX_ SV *value, const char *fallback) {
    const frj_abi *A;
    SV *out;
    if (!value || !SvOK(value)) return newSVpv(fallback, 0);
    A = pq_frj(aTHX);
    out = A->encode(aTHX_ value, NULL);
    (void)sv_utf8_decode(out);
    return out;
}

/* Decode JSON bytes to a Perl value. Returns +1, caller owns. An undef or
 * empty column decodes as undef rather than croaking: a NULL result column
 * is normal for a job that has not finished. Malformed stored JSON is a
 * real error and is allowed to croak. */
static SV *pq_json_decode(pTHX_ SV *bytes) {
    const frj_abi *A;
    const char *p;
    STRLEN len;
    if (!bytes || !SvOK(bytes)) return newSV(0);
    p = SvPV_const(bytes, len);
    if (!len) return newSV(0);
    A = pq_frj(aTHX);
    return A->decode(aTHX_ p, len, NULL);
}

#endif /* PQ_FRJ_H */
