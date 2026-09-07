#ifndef PCHAL_SOLVE_H
#define PCHAL_SOLVE_H

/* The solver: the nonce for a puzzle, the way the browser finds it. For the
 * tests and `punk challenge solve` only.
 *
 * NEVER FROM A HANDLER. A solver reachable from the request path is a denial
 * of service on yourself: every request that reaches it costs the server the
 * CPU the puzzle was designed to charge the client. Nothing under the plugin
 * calls this, and nothing should.
 *
 * Only the shape is checked - the solver has no secret and cannot check the
 * MAC - and `bits` is read from the puzzle, which is what the browser does
 * too.
 *
 * Must be included after pchal_token.h.
 */

/* The solution, or NULL when `max` nonces (0 for no bound) were tried
 * without one. Croaks on a string that is not a puzzle. */
static SV *pchal_solve(pTHX_ const char *p, STRLEN pl, UV max)
{
    const char *f[5];
    STRLEN fl[5];
    IV bits;
    SV *out;
    STRLEN base;
    UV nonce;

    if (pl > PCHAL_MAX_TOKEN || pchal_split(p, pl, f, fl, 5) != 5
        || !(fl[0] == 2 && memEQ(f[0], "v1", 2))
        || fl[2] > 2 || !pchal_dec(f[2], fl[2], &bits)
        || bits < 1 || bits > PCHAL_MAX_BITS
        || !pchal_mac_shape_ok(f[4], fl[4]))
        croak("%s: not a puzzle: '%.*s'", PCHAL_WHO, (int)(pl > 60 ? 60 : pl), p);

    out = newSVpvn(p, pl);
    sv_catpvs(out, ".");
    base = SvCUR(out);

    for (nonce = 0; max == 0 || nonce < max; nonce++) {
        unsigned char d[32];
        SvCUR_set(out, base);
        sv_catpvf(out, "%" UVuf, nonce);
        pchal_sha256((const unsigned char *)SvPVX(out), SvCUR(out), d);
        if (pchal_zero_bits(d, 32) >= (int)bits) return out;
    }
    SvREFCNT_dec(out);
    return NULL;
}

#endif /* PCHAL_SOLVE_H */
