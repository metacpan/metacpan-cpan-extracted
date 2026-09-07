#ifndef PCHAL_PAGE_H
#define PCHAL_PAGE_H

/* The interstitial: lib/Punk/Plugin/Challenge/page.html, read once at
 * register time, with five placeholders substituted per request:
 *
 *     {{puzzle}}   the puzzle
 *     {{bits}}     its difficulty
 *     {{verify}}   the verify route, under SCRIPT_NAME
 *     {{to}}       where to go afterwards: this request's URL
 *     {{script}}   the solver's URL, under SCRIPT_NAME, with ?v=VERSION
 *
 * Every value is escaped for an HTML attribute, because every placeholder
 * sits in one. Not a Stencil template: a plugin cannot assume which view
 * engine the application registered, and five substitutions do not want
 * one.
 *
 * Located through %INC. Punk/Challenge.pm is the module this bundle always
 * loads through - Punk/Plugin/Challenge.pm may never be in %INC at all,
 * since Punk skips the require when the package already has a register -
 * and the directory beside it is the one the running code came from, so a
 * blib and an installed copy cannot disagree about which page is served.
 *
 * Must be included after pchal_clos.h.
 */

#include <stdio.h>

#define PCHAL_PAGE_MAX (256 * 1024)

/* The page's bytes, or a croak naming the path. A new SV. */
static SV *pchal_page_load(pTHX)
{
    SV **pm = hv_fetchs(GvHV(PL_incgv), "Punk/Challenge.pm", 0);
    SV *path, *out;
    FILE *fh;
    size_t got;
    char buf[8192];

    if (!(pm && *pm && SvOK(*pm)))
        croak("%s: cannot find Punk/Challenge.pm in %%INC to locate page.html",
              PCHAL_WHO);
    path = sv_2mortal(newSVsv(*pm));
    {   /* .../Punk/Challenge.pm -> .../Punk/Plugin/Challenge/page.html */
        STRLEN pl;
        const char *pp = SvPV_const(path, pl);
        if (pl >= 12 && memEQ(pp + pl - 12, "Challenge.pm", 12))
            SvCUR_set(path, pl - 12);
    }
    sv_catpvs(path, "Plugin/Challenge/page.html");

    fh = fopen(SvPV_nolen(path), "rb");
    if (!fh)
        croak("%s: cannot read the interstitial %" SVf ": %s", PCHAL_WHO,
              SVfARG(path), Strerror(errno));
    out = newSVpvs("");
    while ((got = fread(buf, 1, sizeof buf, fh)) > 0) {
        sv_catpvn(out, buf, got);
        if (SvCUR(out) > PCHAL_PAGE_MAX) {
            fclose(fh);
            SvREFCNT_dec(out);
            croak("%s: %" SVf " is larger than a page has any reason to be",
                  PCHAL_WHO, SVfARG(path));
        }
    }
    fclose(fh);
    return out;
}

/* ---- escaping ------------------------------------------------------------ */

/* Escape for an HTML attribute. */
static void pchal_attr_cat(pTHX_ SV *out, const char *p, STRLEN l)
{
    STRLEN i, start = 0;
    for (i = 0; i < l; i++) {
        const char *rep = NULL;
        switch (p[i]) {
        case '&':  rep = "&amp;";  break;
        case '<':  rep = "&lt;";   break;
        case '>':  rep = "&gt;";   break;
        case '"':  rep = "&quot;"; break;
        case '\'': rep = "&#39;";  break;
        default: break;
        }
        if (rep) {
            if (i > start) sv_catpvn(out, p + start, i - start);
            sv_catpv(out, rep);
            start = i + 1;
        }
    }
    if (l > start) sv_catpvn(out, p + start, l - start);
}

/* Percent-encode a path: unreserved characters and '/' pass. PATH_INFO
 * arrives DECODED, so anything reflected from it has to be encoded again
 * before it is a URL - and a tab, a newline or a quote in it is exactly what
 * a request that wants to be reflected carries. */
static void pchal_pct_cat(pTHX_ SV *out, const char *p, STRLEN l, int keep_slash)
{
    static const char hex[] = "0123456789ABCDEF";
    STRLEN i;
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)p[i];
        if (isALPHA(c) || isDIGIT(c) || c == '-' || c == '.' || c == '_'
            || c == '~' || (keep_slash && c == '/')) {
            sv_catpvn(out, p + i, 1);
        }
        else {
            char e[3];
            e[0] = '%'; e[1] = hex[c >> 4]; e[2] = hex[c & 15];
            sv_catpvn(out, e, 3);
        }
    }
}

/* A query string is already encoded, but nothing promises it holds only
 * what an encoder emits: encode what is not printable ASCII and what would
 * end an attribute or a string. */
static void pchal_query_cat(pTHX_ SV *out, const char *p, STRLEN l)
{
    static const char hex[] = "0123456789ABCDEF";
    STRLEN i;
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)p[i];
        if (c <= 0x20 || c >= 0x7f || c == '"' || c == '\'' || c == '<'
            || c == '>' || c == '\\') {
            char e[3];
            e[0] = '%'; e[1] = hex[c >> 4]; e[2] = hex[c & 15];
            sv_catpvn(out, e, 3);
        }
        else sv_catpvn(out, p + i, 1);
    }
}

/* ---- rendering ----------------------------------------------------------- */

/* The page with `vars` substituted for its placeholders, every value
 * attribute-escaped. An unknown placeholder is left as it is, so an edited
 * page that invents one shows its own typo. A new SV. */
static SV *pchal_page_render(pTHX_ SV *page, HV *vars)
{
    STRLEN pl;
    const char *p = SvPV_const(page, pl);
    SV *out = newSV(pl + 256);
    STRLEN i = 0, start = 0;

    SvPOK_on(out);
    SvCUR_set(out, 0);
    while (i + 1 < pl) {
        if (p[i] == '{' && p[i + 1] == '{') {
            STRLEN j = i + 2;
            while (j + 1 < pl && !(p[j] == '}' && p[j + 1] == '}')) j++;
            if (j + 1 < pl) {
                SV **v = hv_fetch(vars, p + i + 2, (I32)(j - i - 2), 0);
                if (v && *v && SvOK(*v)) {
                    STRLEN vl;
                    const char *vp = SvPV_const(*v, vl);
                    if (i > start) sv_catpvn(out, p + start, i - start);
                    pchal_attr_cat(aTHX_ out, vp, vl);
                    i = j + 2;
                    start = i;
                    continue;
                }
                i = j + 2;
                continue;
            }
        }
        i++;
    }
    if (pl > start) sv_catpvn(out, p + start, pl - start);
    return out;
}

#endif /* PCHAL_PAGE_H */
