/* pmcp_uri.h - RFC 6570 level 1 URI templates, and base64 for blobs.
 *
 * Needs: pmcp_reg.h.
 * Gives: pmcp_tpl (a parsed template), pmcp_tpl_parse, pmcp_tpl_match,
 * pmcp_tpl_overlap, pmcp_tpl_free, pmcp_b64.
 *
 * Level 1 only: {var}, no operators and no modifiers (16). A variable's value
 * is what simple expansion produces, so it never holds a raw '/', '?' or '#'
 * (expansion percent-encodes them), and a match captures a run without them.
 * Two variables must be separated by text, or the split between them would be
 * a guess.
 */

#ifndef PMCP_URI_H
#define PMCP_URI_H

typedef struct {
    int    is_var;
    char  *text;        /* the literal, or the variable's name */
    STRLEN len;
} pmcp_tok;

typedef struct {
    pmcp_tok *tok;
    int       n;
} pmcp_tpl;

static void pmcp_tpl_free(pmcp_tpl *t)
{
    int i;
    if (!t) return;
    for (i = 0; i < t->n; i++) Safefree(t->tok[i].text);
    Safefree(t->tok);
    Safefree(t);
}

/* Does the URI hold a template at all? */
static int pmcp_is_template(const char *p, STRLEN l)
{
    return memchr(p, '{', l) != NULL || memchr(p, '}', l) != NULL;
}

static void pmcp_tpl_push(pmcp_tpl *t, int is_var, const char *p, STRLEN l)
{
    pmcp_tok *k;
    Renew(t->tok, t->n + 1, pmcp_tok);
    k = &t->tok[t->n++];
    k->is_var = is_var;
    k->len = l;
    Newx(k->text, l + 1, char);
    Copy(p, k->text, l, char);
    k->text[l] = '\0';
}

/* Parse a template, or croak naming it and what is wrong. */
static pmcp_tpl *pmcp_tpl_parse(pTHX_ SV *uri)
{
    STRLEN l, i = 0, start = 0;
    const char *p = SvPV_const(uri, l);
    pmcp_tpl *t;
    const char *why = NULL;

    Newxz(t, 1, pmcp_tpl);
    while (i < l && !why) {
        if (p[i] == '}') { why = "has a '}' with no '{'"; break; }
        if (p[i] != '{') { i++; continue; }
        if (i > start) pmcp_tpl_push(t, 0, p + start, i - start);
        else if (t->n && t->tok[t->n - 1].is_var) {
            why = "has two variables with no text between them";
            break;
        }
        {
            STRLEN j = i + 1;
            if (j < l && strchr("+#./;?&=,!@|", p[j])) {
                why = "uses an operator, and only level 1 {var} is supported";
                break;
            }
            while (j < l && p[j] != '}') {
                char c = p[j];
                if (c == ':' || c == '*') {
                    why = "uses a modifier, and only level 1 {var} is supported";
                    break;
                }
                if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
                      || (c >= '0' && c <= '9') || c == '_')) {
                    why = "has a variable name that is not letters, digits and _";
                    break;
                }
                j++;
            }
            if (why) break;
            if (j >= l) { why = "has a '{' with no '}'"; break; }
            if (j == i + 1) { why = "has an empty {}"; break; }
            {
                int k;
                for (k = 0; k < t->n; k++)
                    if (t->tok[k].is_var && t->tok[k].len == j - i - 1
                        && memEQ(t->tok[k].text, p + i + 1, j - i - 1)) {
                        why = "uses one variable name twice";
                        break;
                    }
                if (why) break;
            }
            pmcp_tpl_push(t, 1, p + i + 1, j - i - 1);
            i = start = j + 1;
        }
    }
    if (!why && start < l) pmcp_tpl_push(t, 0, p + start, l - start);
    if (why) {
        pmcp_tpl_free(t);
        croak("%s: mcp resource '%" SVf "' %s", PMCP_WHO, SVfARG(uri), why);
    }
    return t;
}

/* ---- matching -------------------------------------------------------------- */

static int pmcp_var_char_ok(char c)
{
    return c != '/' && c != '?' && c != '#';
}

static int pmcp_hexval(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* Percent-decode p[0..l) into a new SV, or NULL for a malformed escape. */
static SV *pmcp_pct_decode(pTHX_ const char *p, STRLEN l)
{
    SV *out = newSV(l + 1);
    char *d = SvPVX(out);
    STRLEN i, o = 0;
    for (i = 0; i < l; i++) {
        if (p[i] == '%') {
            int hi, lo;
            if (i + 2 >= l) { SvREFCNT_dec(out); return NULL; }
            hi = pmcp_hexval(p[i + 1]);
            lo = pmcp_hexval(p[i + 2]);
            if (hi < 0 || lo < 0) { SvREFCNT_dec(out); return NULL; }
            d[o++] = (char)(hi * 16 + lo);
            i += 2;
        }
        else d[o++] = p[i];
    }
    d[o] = '\0';
    SvPOK_on(out);
    SvCUR_set(out, o);
    /* a decoded value that is UTF-8 is characters, as a route capture is */
    if (is_utf8_string((U8 *)d, o)) SvUTF8_on(out);
    return out;
}

static int pmcp_tpl_match_at(pTHX_ const pmcp_tpl *t, int k, const char *s,
                             STRLEN l, STRLEN pos, HV *caps)
{
    const pmcp_tok *tk;
    if (k == t->n) return pos == l;
    tk = &t->tok[k];
    if (!tk->is_var) {
        if (l - pos < tk->len || memNE(s + pos, tk->text, tk->len)) return 0;
        return pmcp_tpl_match_at(aTHX_ t, k + 1, s, l, pos + tk->len, caps);
    }
    {
        /* a variable runs to the next literal (the parser guarantees one
         * follows, or this is the last token), trying each place it occurs */
        STRLEN e;
        for (e = pos + 1; e <= l; e++) {
            if (!pmcp_var_char_ok(s[e - 1])) return 0;
            if (k + 1 == t->n ? e == l
                : (l - e >= t->tok[k + 1].len
                   && memEQ(s + e, t->tok[k + 1].text, t->tok[k + 1].len))) {
                if (pmcp_tpl_match_at(aTHX_ t, k + 1, s, l, e, caps)) {
                    SV *v = pmcp_pct_decode(aTHX_ s + pos, e - pos);
                    if (!v) return 0;
                    (void)hv_store(caps, tk->text, (I32)tk->len, v, 0);
                    return 1;
                }
            }
        }
        return 0;
    }
}

/* Match `uri` against `t`. Returns a new HV of decoded variables (+1), or
 * NULL when it does not match. */
static HV *pmcp_tpl_match(pTHX_ const pmcp_tpl *t, SV *uri)
{
    STRLEN l;
    const char *s = SvPV_const(uri, l);
    HV *caps = newHV();
    if (pmcp_tpl_match_at(aTHX_ t, 0, s, l, 0, caps)) return caps;
    SvREFCNT_dec((SV *)caps);
    return NULL;
}

/* ---- overlap --------------------------------------------------------------- */

/* Could one URI match both templates? A walk over pairs of positions, one per
 * template, reading the same character at each step. A position is a token
 * and, inside a variable, whether it has taken a character yet. The
 * characters tried are those of both templates' literals plus one that is in
 * neither, which stands for every other character a variable can take. */
typedef struct { int k; int in; } pmcp_pos;

static int pmcp_step(const pmcp_tpl *t, pmcp_pos at, char c, pmcp_pos *out)
{
    int n = 0;
    if (at.k >= t->n) return 0;
    if (t->tok[at.k].is_var) {
        if (pmcp_var_char_ok(c)) { out[n].k = at.k; out[n].in = 1; n++; }
    }
    else if ((STRLEN)at.in < t->tok[at.k].len && t->tok[at.k].text[at.in] == c) {
        /* inside a literal, `in` is the offset reached */
        if ((STRLEN)at.in + 1 == t->tok[at.k].len) { out[n].k = at.k + 1; out[n].in = 0; }
        else { out[n].k = at.k; out[n].in = at.in + 1; }
        n++;
    }
    return n;
}

/* A variable that has taken a character may end there. */
static int pmcp_close(const pmcp_tpl *t, pmcp_pos at, pmcp_pos *out)
{
    int n = 0;
    out[n++] = at;
    if (at.k < t->n && t->tok[at.k].is_var && at.in) {
        out[n].k = at.k + 1;
        out[n].in = 0;
        n++;
    }
    return n;
}

static int pmcp_tpl_overlap(const pmcp_tpl *a, const pmcp_tpl *b)
{
    char alpha[256];
    int na = 0, i, c;
    int wa = a->n + 1, wb = b->n + 1;
    STRLEN maxa = 1, maxb = 1;
    char *seen;
    int *queue, qh = 0, qt = 0, found = 0;
    int sa, sb, size;

    /* positions inside a literal carry an offset, so size by the longest */
    for (i = 0; i < a->n; i++) if (a->tok[i].len + 1 > maxa) maxa = a->tok[i].len + 1;
    for (i = 0; i < b->n; i++) if (b->tok[i].len + 1 > maxb) maxb = b->tok[i].len + 1;
    sa = wa * (int)maxa;
    sb = wb * (int)maxb;
    size = sa * sb;

    Zero(alpha, 256, char);
    {
        char present[256];
        Zero(present, 256, char);
        for (i = 0; i < a->n; i++) if (!a->tok[i].is_var) {
            STRLEN j;
            for (j = 0; j < a->tok[i].len; j++) present[(U8)a->tok[i].text[j]] = 1;
        }
        for (i = 0; i < b->n; i++) if (!b->tok[i].is_var) {
            STRLEN j;
            for (j = 0; j < b->tok[i].len; j++) present[(U8)b->tok[i].text[j]] = 1;
        }
        for (c = 1; c < 256; c++) if (present[c]) alpha[na++] = (char)c;
        for (c = 'a'; c < 256; c++)          /* one character in neither */
            if (!present[c] && pmcp_var_char_ok((char)c)) { alpha[na++] = (char)c; break; }
    }

    Newxz(seen, size, char);
    Newx(queue, size * 4, int);
#define PMCP_IDX(pa, pb) (((pa).k * (int)maxa + (pa).in) * sb + (pb).k * (int)maxb + (pb).in)
    {
        pmcp_pos s0 = { 0, 0 }, ca[2], cb[2];
        int x, y, nca = pmcp_close(a, s0, ca), ncb = pmcp_close(b, s0, cb);
        for (x = 0; x < nca; x++) for (y = 0; y < ncb; y++) {
            int id = PMCP_IDX(ca[x], cb[y]);
            if (!seen[id]) { seen[id] = 1; queue[qt++] = id; }
        }
    }
    while (qh < qt && !found) {
        int id = queue[qh++], ci;
        pmcp_pos pa, pb;
        pa.k = (id / sb) / (int)maxa;  pa.in = (id / sb) % (int)maxa;
        pb.k = (id % sb) / (int)maxb;  pb.in = (id % sb) % (int)maxb;
        if (pa.k == a->n && pb.k == b->n) { found = 1; break; }
        for (ci = 0; ci < na; ci++) {
            pmcp_pos sa1[1], sb1[1], ca[2], cb[2];
            int x, y, nca, ncb;
            if (!pmcp_step(a, pa, alpha[ci], sa1) || !pmcp_step(b, pb, alpha[ci], sb1))
                continue;
            nca = pmcp_close(a, sa1[0], ca);
            ncb = pmcp_close(b, sb1[0], cb);
            for (x = 0; x < nca; x++) for (y = 0; y < ncb; y++) {
                int nid = PMCP_IDX(ca[x], cb[y]);
                if (!seen[nid] && qt < size * 4) { seen[nid] = 1; queue[qt++] = nid; }
            }
        }
    }
#undef PMCP_IDX
    Safefree(seen);
    Safefree(queue);
    return found;
}

/* ---- base64 (standard, padded) for a blob ------------------------------------ */

static SV *pmcp_b64(pTHX_ const unsigned char *in, STRLEN n)
{
    static const char tbl[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    SV *out = newSV(((n + 2) / 3) * 4 + 1);
    char *o = SvPVX(out);
    STRLEN i = 0, k = 0;
    while (i + 3 <= n) {
        U32 v = ((U32)in[i] << 16) | ((U32)in[i + 1] << 8) | in[i + 2];
        o[k++] = tbl[(v >> 18) & 63]; o[k++] = tbl[(v >> 12) & 63];
        o[k++] = tbl[(v >> 6) & 63];  o[k++] = tbl[v & 63];
        i += 3;
    }
    if (n - i == 1) {
        U32 v = (U32)in[i] << 16;
        o[k++] = tbl[(v >> 18) & 63]; o[k++] = tbl[(v >> 12) & 63];
        o[k++] = '='; o[k++] = '=';
    }
    else if (n - i == 2) {
        U32 v = ((U32)in[i] << 16) | ((U32)in[i + 1] << 8);
        o[k++] = tbl[(v >> 18) & 63]; o[k++] = tbl[(v >> 12) & 63];
        o[k++] = tbl[(v >> 6) & 63];  o[k++] = '=';
    }
    o[k] = '\0';
    SvPOK_on(out);
    SvCUR_set(out, k);
    return out;
}

#endif /* PMCP_URI_H */
