/* punk_multipart.h - multipart/form-data parsing, in C.
 *
 * Punk::Request->form() gains a multipart branch beside its urlencoded one:
 * field parts merge into the form hash (so $c->param sees them), file parts
 * become Punk::Upload objects collected in PQ_UPLOADS. Boundary and line
 * scanning use Perl's ninstr (portable substring search). Upload content is
 * held in memory this cut.
 *
 * Must be included after punk_request.h (the PQ_* slots).
 */

#ifndef PUNK_MULTIPART_H
#define PUNK_MULTIPART_H

/* add a value under a key, promoting a repeat to an arrayref (as the
 * urlencoded parser does), without decoding */
static void pq_hv_add(pTHX_ HV *out, const char *k, STRLEN kl, SV *val) {
    SV *key = sv_2mortal(newSVpvn(k, kl));
    HE *he = hv_fetch_ent(out, key, 0, 0);
    if (he) {
        SV *have = HeVAL(he);
        AV *list;
        if (SvROK(have) && SvTYPE(SvRV(have)) == SVt_PVAV) list = (AV *)SvRV(have);
        else {
            list = newAV();
            av_push(list, newSVsv(have));
            (void)hv_store_ent(out, key, newRV_noinc((SV *)list), 0);
        }
        av_push(list, val);
    }
    else (void)hv_store_ent(out, key, val, 0);
}

/* the value of a header parameter: name=value or name="value". Returns a
 * pointer into s (with *vl set) or NULL. */
static const char *pq_hdr_param(const char *s, STRLEN sl, const char *p,
                                STRLEN *vl) {
    STRLEN pl = strlen(p), i;
    for (i = 0; i + pl + 1 <= sl; i++) {
        if ((i == 0 || s[i-1] == ' ' || s[i-1] == ';' || s[i-1] == '\t')
            && memEQ(s + i, p, pl) && s[i + pl] == '=') {
            const char *v = s + i + pl + 1;
            const char *e;
            if (v < s + sl && *v == '"') {
                v++; e = v;
                while (e < s + sl && *e != '"') e++;
            }
            else { e = v; while (e < s + sl && *e != ';') e++; }
            *vl = (STRLEN)(e - v);
            return v;
        }
    }
    return NULL;
}

/* The whole-body parser that used to live here had no callers: every
 * multipart body goes through pq_parse_multipart_stream (punk_mpstream.h),
 * which spills large parts to disk and bounds what it holds. */

#endif /* PUNK_MULTIPART_H */
