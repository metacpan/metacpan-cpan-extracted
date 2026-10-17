/* punk_response.h - C response assembly.
 *
 * Builds the PSGI triplet - status, header AV with Content-Type and
 * Content-Length, single-element body AV - in one pass, and gives the
 * data-return coercion a JSON fast path straight through
 * File::Raw::JSON's C ABI (the encode returns an owned SV that drops
 * into the body slot untouched - no lexical hop, no PV steal).
 */

#ifndef PUNK_RESPONSE_H
#define PUNK_RESPONSE_H

/* extra: NULL, or an AV of header pairs appended after CT/CL.
 * ct is the content type SV, taken as an owned (+1) value. */
static SV *punk_triplet_own(pTHX_ IV status, SV *ct, SV *body, AV *extra) {
    AV *resp    = newAV();
    AV *headers = newAV();
    AV *bodyav  = newAV();
    av_extend(resp, 2);
    av_extend(headers, extra ? 3 + av_len(extra) + 1 : 3);
    av_store(resp, 0, newSViv(status));
    av_store(headers, 0, newSVpvs("Content-Type"));
    av_store(headers, 1, ct);
    av_store(headers, 2, newSVpvs("Content-Length"));
    av_store(headers, 3, newSViv((IV)(SvOK(body) ? sv_len(body) : 0)));
    if (extra) {
        SSize_t i, n = av_len(extra) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(extra, i, 0);
            av_push(headers, e && *e ? newSVsv(*e) : newSV(0));
        }
    }
    av_store(resp, 1, newRV_noinc((SV *)headers));
    av_store(bodyav, 0, body);   /* takes ownership */
    av_store(resp, 2, newRV_noinc((SV *)bodyav));
    return newRV_noinc((SV *)resp);
}

/* the same with the content type borrowed (copied once) */
static SV *punk_triplet(pTHX_ IV status, SV *ct, SV *body, AV *extra) {
    return punk_triplet_own(aTHX_ status, newSVsv(ct), body, extra);
}

/* and with the content type as a C string: no mortal, one SV */
static SV *punk_triplet_ct(pTHX_ IV status, const char *ct, STRLEN ctl,
                           SV *body, AV *extra) {
    return punk_triplet_own(aTHX_ status, newSVpvn(ct, ctl), body, extra);
}

/* ---- the Punk::Response builder ------------------------------------------ *
 * A plain blessed AV; lib/Punk/Response.pm is documentation only. Slots: */
enum {
    PS_STATUS  = 0,
    PS_HEADERS = 1,   /* live header-pair AV ref */
    PS_TYPE    = 2,
    PS_BODY    = 3
};

static AV *punk_res_av(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
        croak("Punk::Response: not a response object");
    return (AV *)SvRV(self);
}

static AV *punk_res_headers(pTHX_ AV *res) {
    SV **e = av_fetch(res, PS_HEADERS, 0);
    if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)
        return (AV *)SvRV(*e);
    {
        AV *h = newAV();
        (void)av_store(res, PS_HEADERS, newRV_noinc((SV *)h));
        return h;
    }
}

/* A status a handler asked for, as the number to send: 100 to 599, or 0 for
 * "none given" (undef, 0, the empty string), which the caller turns into its
 * default. Anything else croaks. It used to be passed through, and a status
 * the dispatcher did not recognise made the finished response look like data:
 * it was JSON-encoded, headers and all, and sent as a 200. */
static IV ps_status_arg(pTHX_ SV *sv) {
    IV st;
    if (!(sv && SvOK(sv)) || !SvTRUE(sv)) return 0;
    if (SvROK(sv))
        croak("Punk: a response status must be a number from 100 to 599");
    st = (looks_like_number(sv) && (NV)SvIV(sv) == SvNV(sv)) ? SvIV(sv) : -1;
    if (st < 100 || st > 599)
        croak("Punk: a response status must be a number from 100 to 599, "
              "not '%" SVf "'", SVfARG(sv));
    return st;
}

#endif /* PUNK_RESPONSE_H */
