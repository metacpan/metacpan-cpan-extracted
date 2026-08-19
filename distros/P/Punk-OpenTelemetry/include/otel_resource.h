/* otel_resource.h - what produced this telemetry, in C.
 *
 * The resource attributes attached to everything a process exports: which
 * service this is, which instance of it, and what it is running on.
 * lib/Punk/OpenTelemetry/Resource.pm is documentation.
 *
 * The instance id comes from otel_id.h's generator - the same getentropy /
 * cached-urandom source the trace and span ids use - and not from rand().
 * That is not tidiness. Perl seeds its RNG lazily and does NOT reseed it
 * across fork, so a parent that has called rand() once (anything might) hands
 * every prefork worker the SAME sequence, and therefore the same
 * service.instance.id. Which is the exact failure this attribute exists to
 * prevent: a collector seeing eight contradictory cumulative series that all
 * claim to be one instance, resolving it by resetting, summing or taking the
 * last write - all three wrong, none of them wrong-looking on a dashboard.
 *
 * Needs otel_id.h (otel_gen_id, otel_bytes_to_hex).
 */

#ifndef OTEL_RESOURCE_H
#define OTEL_RESOURCE_H

/* A process-unique instance id, shaped like a UUID because that is what every
 * backend expects to see in this attribute. Generated on demand and never
 * cached: the one thing it must not do is hand the same value to two
 * processes. Owned (+1). */
static SV *otel_res_instance_id(pTHX) {
    unsigned char b[16];
    char hex[32];
    SV *out;
    if (!otel_gen_id(b, sizeof b)) {
        /* No entropy source at all. Rather than return something a caller
         * cannot tell from a real id, fall back to something that is at
         * least per-process distinct and say so in the shape. */
        UV pid = (UV)PerlProc_getpid();
        UV now = (UV)time(NULL);
        int i;
        for (i = 0; i < 16; i++)
            b[i] = (unsigned char)((pid >> ((i % 4) * 8)) ^ (now >> ((i % 4) * 8))
                                   ^ (unsigned)(i * 31));
    }
    otel_bytes_to_hex(b, sizeof b, hex);
    out = newSVpvn(hex, 8);
    sv_catpvs(out, "-"); sv_catpvn(out, hex + 8,  4);
    sv_catpvs(out, "-"); sv_catpvn(out, hex + 12, 4);
    sv_catpvs(out, "-"); sv_catpvn(out, hex + 16, 4);
    sv_catpvs(out, "-"); sv_catpvn(out, hex + 20, 12);
    return out;
}

/* $^X, $^V and friends, read from the interpreter rather than guessed. */
static SV *otel_res_perl_sv(pTHX_ const char *name, STRLEN len) {
    SV *sv = get_sv(name, 0);
    return (sv && SvOK(sv)) ? sv : NULL;
    PERL_UNUSED_ARG(len);
}

/* Sys::Hostname, by name and under eval, exactly as the Perl did: it tries
 * several sources and knows more about the odd platforms than a bare
 * gethostname call does. A failure means the attribute is simply omitted -
 * a resource missing host.name is fine, and a boot that died looking for it
 * is not. Mortal SV, or NULL. */
static SV *otel_res_hostname(pTHX) {
    dSP;
    int count;
    SV *h = NULL;
    eval_pv("require Sys::Hostname;", FALSE);
    SPAGAIN;
    if (SvTRUE(ERRSV)) return NULL;
    ENTER; SAVETMPS;
    PUSHMARK(SP); PUTBACK;
    count = call_pv("Sys::Hostname::hostname", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) { SV *r = POPs; if (SvOK(r)) h = newSVsv(r); }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (!h) return NULL;
    sv_2mortal(h);
    return SvCUR(h) ? h : NULL;
}

/* OTEL_RESOURCE_ATTRIBUTES: comma-separated key=value, spec-defined.
 *
 * The split is the Perl's, byte for byte: pairs on comma with the whitespace
 * around it eaten, then key and value on the FIRST '=' only, so a value may
 * contain one. A pair with no '=' or an empty key is skipped rather than
 * guessed at. The key is trimmed at both ends; the value is not, because
 * whitespace inside a value is the caller's business and only the run beside
 * a comma was ever eaten. */
static void otel_res_parse_env_attrs(pTHX_ HV *out, const char *s, STRLEN len) {
    STRLEN i = 0;
    while (i < len) {
        STRLEN start, end, eq;
        const char *kp, *vp;
        STRLEN kl, vl;
        /* leading whitespace of this pair, then up to the next comma */
        while (i < len && isSPACE(s[i])) i++;
        start = i;
        while (i < len && s[i] != ',') i++;
        end = i;
        if (i < len) i++;                       /* step over the comma */
        while (end > start && isSPACE(s[end - 1])) end--;   /* trailing */
        if (end <= start) continue;

        for (eq = start; eq < end && s[eq] != '='; eq++) ;
        if (eq >= end) continue;                /* no '=' : skipped */
        kp = s + start; kl = eq - start;
        vp = s + eq + 1; vl = end - eq - 1;
        while (kl && isSPACE(kp[0]))      { kp++; kl--; }   /* trim the key */
        while (kl && isSPACE(kp[kl - 1])) { kl--; }
        if (!kl) continue;                      /* empty key : skipped */
        (void)hv_store(out, kp, (I32)kl, newSVpvn(vp, vl), 0);
    }
}

#endif /* OTEL_RESOURCE_H */
