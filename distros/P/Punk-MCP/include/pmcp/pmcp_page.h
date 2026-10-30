/* pmcp_page.h - cursors and pages for the frozen lists.
 *
 * Needs: pmcp_rand.h (base64url), pmcp_decl.h.
 * Gives: pmcp_cursor_make, pmcp_cursor_read, pmcp_page_bytes.
 *
 * A cursor is this server's own token: the index of the next item, as
 * base64url of "c" and the decimal index. Opaque to the client, and a cursor
 * this server did not issue is refused rather than guessed at.
 *
 * A page is spliced from the entries frozen at to_app, so the bytes of an item
 * never change between calls. When an item has a guard, the caller's view is
 * filtered: each guarded item runs its guard and is left out on a refusal.
 */

#ifndef PMCP_PAGE_H
#define PMCP_PAGE_H

static SV *pmcp_cursor_make(pTHX_ IV index)
{
    char raw[32], out[48];
    int rl = my_snprintf(raw, sizeof raw, "c%" IVdf, index);
    size_t ol = pmcp_b64url((const unsigned char *)raw, (size_t)rl, out);
    return newSVpvn(out, ol);
}

static int pmcp_b64url_val(char c)
{
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '-') return 62;
    if (c == '_') return 63;
    return -1;
}

/* The index a cursor names, or -1 when it is not one of ours, or past `n`. */
static IV pmcp_cursor_read(pTHX_ SV *cursor, IV n)
{
    STRLEN l, i;
    const char *p;
    char raw[32];
    size_t rl = 0;
    U32 acc = 0;
    int bits = 0;
    IV idx = 0;

    if (!cursor || SvROK(cursor) || !SvOK(cursor)) return -1;
    p = SvPV_const(cursor, l);
    if (l == 0 || l > 40) return -1;
    for (i = 0; i < l; i++) {
        int v = pmcp_b64url_val(p[i]);
        if (v < 0) return -1;
        acc = (acc << 6) | (U32)v;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            if (rl >= sizeof raw - 1) return -1;
            raw[rl++] = (char)((acc >> bits) & 0xFF);
        }
    }
    if (rl < 2 || raw[0] != 'c') return -1;
    for (i = 1; i < rl; i++) {
        if (raw[i] < '0' || raw[i] > '9') return -1;
        idx = idx * 10 + (raw[i] - '0');
        if (idx > n) return -1;
    }
    if (idx < 1 || idx >= n) return -1;
    /* the canonical spelling only, so one index has one cursor */
    {
        SV *again = sv_2mortal(pmcp_cursor_make(aTHX_ idx));
        if (!sv_eq(again, cursor)) return -1;
    }
    return idx;
}

/* {"nextCursor":C,"KEY":[E,...]} with the keys in canonical order, from the
 * entries `entries[start..]`, at most `size` of them, skipping any `skip`
 * refuses. Returns +1 bytes. `skip` may be NULL: everything is visible. */
typedef int (*pmcp_visible_fn)(pTHX_ void *ctx, IV index);

static SV *pmcp_page_bytes(pTHX_ const char *key, SV **entries, IV n,
                           IV start, IV size, pmcp_visible_fn visible,
                           void *ctx)
{
    SV *items = sv_2mortal(newSVpvs("["));
    IV i, taken = 0, next = -1;
    SV *out;

    for (i = start; i < n; i++) {
        if (visible && !visible(aTHX_ ctx, i)) continue;
        if (taken == size) { next = i; break; }
        if (taken) sv_catpvs(items, ",");
        sv_catsv(items, entries[i]);
        taken++;
    }
    sv_catpvs(items, "]");

    out = newSVpvs("{");
    if (next >= 0) {
        SV *c = sv_2mortal(pmcp_cursor_make(aTHX_ next));
        sv_catpvs(out, "\"nextCursor\":\"");
        sv_catsv(out, c);
        sv_catpvs(out, "\",");
    }
    sv_catpvf(out, "\"%s\":", key);
    sv_catsv(out, items);
    sv_catpvs(out, "}");
    return out;
}

#endif /* PMCP_PAGE_H */
