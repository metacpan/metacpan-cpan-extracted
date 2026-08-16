/* punk_accept.h - Accept negotiation for $c->respond_to, in C.
 *
 * A small RFC 9110 media-range parser: no regex engine, no allocation - the
 * ranges point into the header's own buffer. Enough Accept to be correct
 * about the two things naive matching gets wrong: q-values order the
 * browser's `text/html,application/xml;q=0.9,* / *;q=0.8` correctly, and
 * `q=0` excludes rather than matches.
 *
 * Include after punk_response.h; xs/context.xs is the consumer.
 */

#ifndef PUNK_ACCEPT_H
#define PUNK_ACCEPT_H

#define PA_RANGE_MAX 32

typedef struct pa_range {
    const char *t; STRLEN tl;    /* type,    pointing into the header */
    const char *s; STRLEN sl;    /* subtype, pointing into the header */
    int q;                       /* per mille: 0..1000 */
} pa_range;

static int pa_ws(char c) { return c == ' ' || c == '\t'; }

/* the q of one parameter list: ";q=0.8" -> 800; absent or malformed -> 1000 */
static int pa_q_of(const char *p, const char *end) {
    while (p < end) {
        while (p < end && (pa_ws(*p) || *p == ';')) p++;
        if (p + 1 < end && (*p == 'q' || *p == 'Q')) {
            const char *v = p + 1;
            while (v < end && pa_ws(*v)) v++;
            if (v < end && *v == '=') {
                int q;
                v++;
                while (v < end && pa_ws(*v)) v++;
                if (v >= end) return 1000;
                if (*v == '1') return 1000;
                if (*v != '0') return 1000;
                q = 0; v++;
                if (v < end && *v == '.') {
                    int place = 100;
                    v++;
                    while (v < end && *v >= '0' && *v <= '9' && place) {
                        q += (*v - '0') * place;
                        place /= 10; v++;
                    }
                }
                return q;
            }
        }
        while (p < end && *p != ';') p++;
    }
    return 1000;
}

/* Split an Accept value into media ranges. Returns how many were kept;
 * anything past PA_RANGE_MAX or with no shape is ignored, never fatal -
 * a malformed Accept from a client must not be able to error a response. */
static int pa_parse(const char *a, STRLEN al, pa_range *out, int max) {
    const char *p = a, *end = a + al;
    int n = 0;
    while (p < end && n < max) {
        const char *seg_end = p, *slash, *sub_end, *par;
        while (seg_end < end && *seg_end != ',') seg_end++;
        while (p < seg_end && pa_ws(*p)) p++;
        par = p;
        while (par < seg_end && *par != ';') par++;
        sub_end = par;
        while (sub_end > p && pa_ws(sub_end[-1])) sub_end--;
        slash = p;
        while (slash < sub_end && *slash != '/') slash++;
        if (slash < sub_end && slash > p && sub_end > slash + 1) {
            out[n].t  = p;         out[n].tl = (STRLEN)(slash - p);
            out[n].s  = slash + 1; out[n].sl = (STRLEN)(sub_end - slash - 1);
            out[n].q  = pa_q_of(par, seg_end);
            n++;
        }
        else if (sub_end == p + 1 && *p == '*') {   /* a bare '*' is '* / *' */
            out[n].t = p; out[n].tl = 1;
            out[n].s = p; out[n].sl = 1;
            out[n].q = pa_q_of(par, seg_end);
            n++;
        }
        p = seg_end + 1;
    }
    return n;
}

static int pa_star(const char *s, STRLEN l) { return l == 1 && *s == '*'; }

/* How well the ranges accept one media type: returns the specificity of the
 * most specific matching range (2 exact, 1 type / *, 0 * / *, -1 none), and
 * through q/order that range's q-value and position. RFC 9110's rule: the
 * most specific match decides the q, and q=0 is an exclusion (reported as a
 * match with *q 0, so the caller can tell "refused" from "unmentioned"). */
static int pa_match(pTHX_ const pa_range *r, int n,
                    const char *t, STRLEN tl, const char *s, STRLEN sl,
                    int *q, int *order) {
    int i, spec = -1;
    for (i = 0; i < n; i++) {
        int this_spec;
        if (pa_star(r[i].t, r[i].tl))
            this_spec = 0;
        else if (r[i].tl == tl && foldEQ(r[i].t, t, (I32)tl))
            this_spec = pa_star(r[i].s, r[i].sl) ? 1
                      : (r[i].sl == sl && foldEQ(r[i].s, s, (I32)sl)) ? 2
                      : -1;
        else
            this_spec = -1;
        if (this_spec > spec) {
            spec = this_spec;
            *q = r[i].q;
            *order = i;
        }
    }
    return spec;
}

/* The media type a respond_to format name means. A name with a '/' is taken
 * literally; the short names cover what an application negotiates in
 * practice. Returns 0 for a name it does not know. */
static int pa_fmt_mime(const char *name, STRLEN nl,
                       const char **t, STRLEN *tl,
                       const char **s, STRLEN *sl) {
    const char *slash = (const char *)memchr(name, '/', nl);
    if (slash && slash > name && (STRLEN)(slash - name) < nl - 1) {
        *t = name;      *tl = (STRLEN)(slash - name);
        *s = slash + 1; *sl = nl - *tl - 1;
        return 1;
    }
    if (nl == 4 && memEQ(name, "json", 4)) {
        *t = "application"; *tl = 11; *s = "json"; *sl = 4; return 1;
    }
    if (nl == 4 && memEQ(name, "html", 4)) {
        *t = "text"; *tl = 4; *s = "html"; *sl = 4; return 1;
    }
    if (nl == 4 && memEQ(name, "text", 4)) {
        *t = "text"; *tl = 4; *s = "plain"; *sl = 5; return 1;
    }
    if (nl == 3 && memEQ(name, "xml", 3)) {
        *t = "application"; *tl = 11; *s = "xml"; *sl = 3; return 1;
    }
    return 0;
}

/* Add Accept to the response's Vary - creating the pair, or appending to an
 * existing value that does not already carry the token (a whole-token check:
 * `Vary: Accept-Encoding` does not contain Accept). A negotiated response
 * without this poisons every shared cache between here and the client. */
static void pa_vary_accept(pTHX_ AV *headers) {
    SSize_t i, n = av_len(headers) + 1;
    SV *first_vary = NULL;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(headers, i, 0);
        STRLEN kl; const char *kp;
        if (!(k && *k)) continue;
        kp = SvPV_const(*k, kl);
        if (kl == 4 && foldEQ(kp, "Vary", 4)) {
            SV **v = av_fetch(headers, i + 1, 0);
            STRLEN vl; const char *vp, *p, *vend;
            if (!(v && *v && SvOK(*v))) continue;
            vp = SvPV_const(*v, vl);
            p = vp; vend = vp + vl;
            while (p < vend) {
                const char *tok_end = p, *tok;
                while (tok_end < vend && *tok_end != ',') tok_end++;
                tok = p;
                while (tok < tok_end && pa_ws(*tok)) tok++;
                {
                    const char *te = tok_end;
                    while (te > tok && pa_ws(te[-1])) te--;
                    if ((STRLEN)(te - tok) == 6 && foldEQ(tok, "Accept", 6))
                        return;                    /* already varies on it */
                }
                p = tok_end + 1;
            }
            if (!first_vary) first_vary = *v;
        }
    }
    if (first_vary) sv_catpvs(first_vary, ", Accept");
    else {
        av_push(headers, newSVpvs("Vary"));
        av_push(headers, newSVpvs("Accept"));
    }
}

#endif /* PUNK_ACCEPT_H */
