#ifndef PCHAL_CT_H
#define PCHAL_CT_H

/* Constant-time equality, for a MAC a client presented against one this
 * process computed.
 *
 * Punk's pk_ct_eq shape: no early return on a length mismatch, the fold
 * runs over the whole of `a` whatever `b` is, and the lengths are folded in
 * as one more bit of difference. The length of a MAC is fixed and public,
 * so a fold that took a different time for a different length would leak
 * nothing anyway; the shape is kept because the next caller might not be a
 * MAC.
 *
 * Needs nothing before it.
 */

static int pchal_ct_eq(const char *a, STRLEN alen, const char *b, STRLEN blen)
{
    volatile unsigned char diff = (unsigned char)((alen ^ blen) != 0);
    STRLEN i;
    if (!alen || !blen) return 0;
    for (i = 0; i < alen; i++)
        diff |= (unsigned char)(a[i] ^ b[i % blen]);
    return diff == 0;
}

#endif /* PCHAL_CT_H */
