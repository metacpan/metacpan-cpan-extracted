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

/* Parse a multipart/form-data body: field parts -> form, file parts (a
 * Content-Disposition filename) -> Punk::Upload objects in uploads. */
static void pq_parse_multipart(pTHX_ const char *body, STRLEN blen,
                               const char *bnd, STRLEN bl,
                               HV *form, HV *uploads) {
    SV *dsv = sv_2mortal(newSVpvs("--"));
    const char *D, *end = body + blen, *p;
    STRLEN Dl;
    sv_catpvn(dsv, bnd, bl);
    D = SvPVX(dsv); Dl = SvCUR(dsv);
    p = ninstr((char *)body, (char *)end, (char *)D, (char *)D + Dl);
    if (!p) return;
    p += Dl;
    while (p < end) {
        const char *hend, *content, *nd, *cend, *hp;
        const char *disp = NULL, *ctype = NULL;
        const char *name = NULL, *fname = NULL;
        STRLEN displ = 0, ctypel = 0, namel = 0, fnamel = 0, clen;
        if (p + 2 <= end && p[0] == '-' && p[1] == '-') break;       /* end */
        if (p + 2 <= end && p[0] == '\r' && p[1] == '\n') p += 2; else break;
        { const char *crlf2 = "\r\n\r\n";
          hend = ninstr((char *)p, (char *)end, (char *)crlf2, (char *)crlf2 + 4); }
        if (!hend) break;
        content = hend + 4;
        {
            SV *ndsv = sv_2mortal(newSVpvs("\r\n"));
            sv_catpvn(ndsv, D, Dl);
            nd = ninstr((char *)content, (char *)end,
                        SvPVX(ndsv), SvPVX(ndsv) + SvCUR(ndsv));
        }
        cend = nd ? nd : end;
        clen = (STRLEN)(cend - content);
        for (hp = p; hp < hend; ) {
            const char *crlf = "\r\n";
            const char *le = ninstr((char *)hp, (char *)hend, (char *)crlf, (char *)crlf + 2);
            const char *lend = le ? le : hend;
            STRLEN ll = (STRLEN)(lend - hp);
            if (ll >= 20 && strncasecmp(hp, "Content-Disposition:", 20) == 0) {
                disp = hp + 20; displ = ll - 20;
            }
            else if (ll >= 13 && strncasecmp(hp, "Content-Type:", 13) == 0) {
                ctype = hp + 13;
                while (ctype < hp + ll && *ctype == ' ') ctype++;
                ctypel = (STRLEN)((hp + ll) - ctype);
            }
            if (!le) break;
            hp = le + 2;
        }
        if (disp) {
            name  = pq_hdr_param(disp, displ, "name", &namel);
            fname = pq_hdr_param(disp, displ, "filename", &fnamel);
        }
        if (fname) {                                  /* a file part */
            HV *up = newHV();
            SV *obj;
            (void)hv_stores(up, "name", name ? newSVpvn(name, namel) : newSVpvs(""));
            (void)hv_stores(up, "filename", newSVpvn(fname, fnamel));
            (void)hv_stores(up, "type",
                (ctype && ctypel) ? newSVpvn(ctype, ctypel)
                                  : newSVpvs("application/octet-stream"));
            (void)hv_stores(up, "content", newSVpvn(content, clen));
            (void)hv_stores(up, "size", newSViv((IV)clen));
            obj = sv_bless(newRV_noinc((SV *)up),
                           gv_stashpvs("Punk::Upload", GV_ADD));
            if (name) pq_hv_add(aTHX_ uploads, name, namel, obj);
            else SvREFCNT_dec(obj);
        }
        else if (name) {                              /* a field part */
            pq_hv_add(aTHX_ form, name, namel, newSVpvn(content, clen));
        }
        if (!nd) break;
        p = nd + 2 + Dl;                              /* past "\r\n--boundary" */
    }
}

#endif /* PUNK_MULTIPART_H */
