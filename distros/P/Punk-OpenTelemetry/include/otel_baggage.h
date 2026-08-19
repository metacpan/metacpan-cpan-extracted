/* otel_baggage.h - W3C Baggage.
 *
 *     baggage: key1=value1;prop=x,key2=value2
 *
 * Application state travelling with the trace. Percent-encoded values, three
 * size limits (180 entries, 4096 bytes an entry, 8192 bytes total), and
 * per-entry properties carried through opaquely.
 *
 * BAGGAGE IS NOT AUTOMATICALLY ATTACHED TO SPANS, and that is a security
 * decision rather than an omission.
 *
 * Baggage arrives in a request header, which on any public endpoint means an
 * attacker chooses its contents. Copying it into every span's attributes -
 * which is the obvious convenience, and which some SDKs offer by default -
 * hands that attacker two things at once: a cardinality bomb, because they
 * pick both the key names and the values, and a data-leak path, because
 * whatever they put there is now stored in a telemetry backend that is
 * usually less guarded than the application and is often a third party.
 *
 * So the capability exists and is off. An application that wants baggage on
 * its spans asks for it, by name, for the keys it expects.
 */

#ifndef OTEL_BAGGAGE_H
#define OTEL_BAGGAGE_H

#include "otel_ctx.h"

#define OTEL_BAGGAGE_MAX_ENTRIES 180
#define OTEL_BAGGAGE_MAX_ENTRY   4096
#define OTEL_BAGGAGE_MAX_TOTAL   8192

/* Percent-encode a baggage key or value into `out`. Everything outside
 * unreserved ASCII is escaped, which covers the delimiters (`,` `;` `=`) and
 * every control byte - so a value taken from a request and re-emitted cannot
 * forge an entry or split the header. Bounded; returns 0 if it will not
 * fit. */
static STRLEN otel_pct_encode(const char *s, STRLEN len, char *out,
                              STRLEN cap) {
    static const char H[] = "0123456789ABCDEF";
    STRLEN i, o = 0;
    for (i = 0; i < len; i++) {
        unsigned char c = (unsigned char)s[i];
        int safe = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
                || (c >= '0' && c <= '9')
                || c == '-' || c == '.' || c == '_' || c == '~';
        if (safe) {
            if (o + 1 > cap) return 0;
            out[o++] = (char)c;
        }
        else {
            if (o + 3 > cap) return 0;
            out[o++] = '%';
            out[o++] = H[c >> 4];
            out[o++] = H[c & 0xf];
        }
    }
    return o;
}

/* Parse a baggage header into a hashref of { key => value }, decoding both.
 * Properties (the `;prop` tail) are preserved on the value as received, since
 * they are opaque to us and dropping them would lose somebody's metadata.
 *
 * Over-limit entries are DROPPED rather than truncated: a truncated value is
 * a different value, and silently changing an application's data is worse
 * than not carrying it. */
static HV *otel_baggage_parse(pTHX_ const char *s, STRLEN len) {
    HV *out = newHV();
    STRLEN i = 0, total = 0;
    int entries = 0;
    if (!s || !len) return out;

    while (i < len && entries < OTEL_BAGGAGE_MAX_ENTRIES
                   && total < OTEL_BAGGAGE_MAX_TOTAL) {
        STRLEN start, end, eq;
        char kbuf[OTEL_BAGGAGE_MAX_ENTRY], vbuf[OTEL_BAGGAGE_MAX_ENTRY];
        STRLEN kl, vl;

        while (i < len && (s[i] == ' ' || s[i] == '\t' || s[i] == ',')) i++;
        if (i >= len) break;
        start = i;
        while (i < len && s[i] != ',') i++;
        end = i;
        while (end > start && (s[end - 1] == ' ' || s[end - 1] == '\t')) end--;
        if (end <= start) continue;
        if (end - start > OTEL_BAGGAGE_MAX_ENTRY) continue;   /* drop it */

        for (eq = start; eq < end && s[eq] != '='; eq++) ;
        if (eq >= end) continue;                              /* no '=' */

        kl = otel_pct_decode(s + start, eq - start, kbuf, sizeof kbuf);
        vl = otel_pct_decode(s + eq + 1, end - eq - 1, vbuf, sizeof vbuf);
        if (!kl) continue;
        {
            STRLEN j;
            int ok = 1;
            for (j = 0; j < kl; j++) {
                unsigned char c = (unsigned char)kbuf[j];
                if (c < 0x21 || c > 0x7e) { ok = 0; break; }
            }
            if (!ok) continue;
        }
        total += (end - start);
        (void)hv_store(out, kbuf, (I32)kl, newSVpvn(vbuf, vl), 0);
        entries++;
    }
    return out;
}

/* Render a hashref as a baggage header. Keys are sorted, for the same reason
 * everything else in this dist sorts: a header that reorders itself between
 * runs cannot be diffed or tested. Returns a mortal SV. */
static SV *otel_baggage_format(pTHX_ HV *in) {
    SV *out = sv_2mortal(newSVpvs(""));
    AV *keys;
    HE *he;
    SSize_t i, n = 0;
    int entries = 0;
    if (!in) return out;

    keys = (AV *)sv_2mortal((SV *)newAV());
    hv_iterinit(in);
    while ((he = hv_iternext(in))) { av_push(keys, newSVsv(hv_iterkeysv(he))); n++; }
    if (n > 1) sortsv(AvARRAY(keys), (STRLEN)n, Perl_sv_cmp);

    for (i = 0; i < n && entries < OTEL_BAGGAGE_MAX_ENTRIES; i++) {
        SV **kp = av_fetch(keys, i, 0);
        HE *e;
        STRLEN kl, vl, ek, ev;
        const char *k, *v;
        char kb[OTEL_BAGGAGE_MAX_ENTRY], vb[OTEL_BAGGAGE_MAX_ENTRY];
        if (!(kp && *kp)) continue;
        k = SvPV_const(*kp, kl);
        e = hv_fetch_ent(in, *kp, 0, 0);
        v = (e && HeVAL(e) && SvOK(HeVAL(e))) ? SvPV_const(HeVAL(e), vl)
                                              : (vl = 0, "");
        ek = otel_pct_encode(k, kl, kb, sizeof kb);
        ev = otel_pct_encode(v, vl, vb, sizeof vb);
        if (!ek) continue;
        if (SvCUR(out) + ek + ev + 2 > OTEL_BAGGAGE_MAX_TOTAL) break;
        if (SvCUR(out)) sv_catpvs(out, ",");
        sv_catpvn(out, kb, ek);
        sv_catpvs(out, "=");
        sv_catpvn(out, vb, ev);
        entries++;
    }
    return out;
}

#endif /* OTEL_BAGGAGE_H */
