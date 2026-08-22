#ifndef QR_MASK_H
#define QR_MASK_H

/* qr_mask.h - data masking, penalty scoring, and the BCH-coded format
 * and version information blocks.
 *
 * Masking exists because an unmasked symbol can contain long runs of one
 * colour, or accidental copies of the finder pattern, both of which
 * confuse a decoder. All eight masks are applied in turn, each result is
 * scored by four penalty rules, and the lowest score wins.
 *
 * A symbol with a suboptimal mask still scans, which is exactly why the
 * penalty rules need testing against fixtures rather than against "did a
 * decoder read it". A quiet mistake here costs robustness and reports
 * nothing.
 */

/* Whether module (row, col) is inverted under mask `m`. The eight
 * conditions are fixed by ISO/IEC 18004 Table 10. */
static int qr_mask_bit(int m, int row, int col)
{
    switch (m) {
    case 0: return ((row + col) % 2) == 0;
    case 1: return (row % 2) == 0;
    case 2: return (col % 3) == 0;
    case 3: return ((row + col) % 3) == 0;
    case 4: return (((row / 2) + (col / 3)) % 2) == 0;
    case 5: return (((row * col) % 2) + ((row * col) % 3)) == 0;
    case 6: return (((((row * col) % 2) + ((row * col) % 3)) % 2)) == 0;
    case 7: return (((((row + col) % 2) + ((row * col) % 3)) % 2)) == 0;
    default: return 0;
    }
}

/* --- penalty rules ------------------------------------------------------- */

/* Rule 1: runs of five or more same-coloured modules in a row or column
 * score 3, plus 1 for each module past five. */
static int qr_penalty_1(const unsigned char *m, int size)
{
    int total = 0, i, j;

    for (i = 0; i < size; i++) {
        int run_h = 1, run_v = 1;
        for (j = 1; j < size; j++) {
            /* horizontal */
            if (m[i * size + j] == m[i * size + j - 1]) {
                run_h++;
            } else {
                if (run_h >= 5) total += 3 + (run_h - 5);
                run_h = 1;
            }
            /* vertical */
            if (m[j * size + i] == m[(j - 1) * size + i]) {
                run_v++;
            } else {
                if (run_v >= 5) total += 3 + (run_v - 5);
                run_v = 1;
            }
        }
        if (run_h >= 5) total += 3 + (run_h - 5);
        if (run_v >= 5) total += 3 + (run_v - 5);
    }
    return total;
}

/* Rule 2: every 2x2 block of one colour scores 3. Blocks overlap, so a
 * 3x3 solid area contributes four of them. */
static int qr_penalty_2(const unsigned char *m, int size)
{
    int total = 0, i, j;

    for (i = 0; i < size - 1; i++) {
        for (j = 0; j < size - 1; j++) {
            unsigned char a = m[i * size + j];
            if (a == m[i * size + j + 1] &&
                a == m[(i + 1) * size + j] &&
                a == m[(i + 1) * size + j + 1])
                total += 3;
        }
    }
    return total;
}

/* Rule 3: the finder-like 1:1:3:1:1 sequence with four light modules on
 * one side scores 40, in rows and in columns.
 *
 * This is the rule implementations diverge on. The spec describes the
 * pattern as 1011101 preceded or followed by 0000, and the ambiguity is
 * whether the four light modules must be inside the symbol or may run
 * off the edge. Taken here as eleven modules that must all be inside -
 * the reading that matches the published penalty scores for the
 * ISO worked example. Both readings produce a scannable symbol, which
 * is why the fixture test rather than a decoder is what settles it. */
static int qr_penalty_3(const unsigned char *m, int size)
{
    static const unsigned char a[11] = { 1,0,1,1,1,0,1,0,0,0,0 };
    static const unsigned char b[11] = { 0,0,0,0,1,0,1,1,1,0,1 };
    int total = 0, i, j, k;

    for (i = 0; i < size; i++) {
        for (j = 0; j + 11 <= size; j++) {
            int ha = 1, hb = 1, va = 1, vb = 1;
            for (k = 0; k < 11; k++) {
                unsigned char h = m[i * size + j + k];
                unsigned char v = m[(j + k) * size + i];
                if (h != a[k]) ha = 0;
                if (h != b[k]) hb = 0;
                if (v != a[k]) va = 0;
                if (v != b[k]) vb = 0;
            }
            if (ha) total += 40;
            if (hb) total += 40;
            if (va) total += 40;
            if (vb) total += 40;
        }
    }
    return total;
}

/* Rule 4: deviation of the dark module proportion from 50%, scored 10
 * per 5% step. */
static int qr_penalty_4(const unsigned char *m, int size)
{
    int dark = 0, total = size * size, i;
    int percent, deviation;

    for (i = 0; i < total; i++)
        if (m[i])
            dark++;

    percent = (dark * 100) / total;
    deviation = percent > 50 ? percent - 50 : 50 - percent;
    return (deviation / 5) * 10;
}

static int qr_penalty(const unsigned char *m, int size)
{
    return qr_penalty_1(m, size) + qr_penalty_2(m, size)
         + qr_penalty_3(m, size) + qr_penalty_4(m, size);
}

/* --- format and version information -------------------------------------- */

/* ECC level to its two-bit format indicator. Note the ordering is NOT
 * the L/M/Q/H of the capacity tables: L is 01 and M is 00, so a
 * straight index would silently swap the two most common levels. */
static unsigned int qr_format_ecc_bits(int ecc)
{
    switch (ecc) {
    case 0: return 1u; /* L */
    case 1: return 0u; /* M */
    case 2: return 3u; /* Q */
    default: return 2u; /* H */
    }
}

/* 15-bit format information: 5 data bits (2 ECC + 3 mask) extended by
 * BCH(15,5) over generator 0x537, then XORed with 0x5412 so that an
 * all-zero format is not all-zero on the symbol. */
static unsigned int qr_format_bits(int ecc, int mask)
{
    unsigned int data = (qr_format_ecc_bits(ecc) << 3) | (unsigned int)mask;
    unsigned int rem = data;
    int i;

    for (i = 0; i < 10; i++)
        rem = (rem << 1) ^ ((rem >> 9) * 0x537u);

    return ((data << 10) | (rem & 0x3FFu)) ^ 0x5412u;
}

/* 18-bit version information, versions 7 and up: 6 data bits extended by
 * BCH(18,6) over generator 0x1F25. No final XOR, unlike the format
 * block. */
static unsigned int qr_version_bits(int version)
{
    unsigned int rem = (unsigned int)version;
    int i;

    for (i = 0; i < 12; i++)
        rem = (rem << 1) ^ ((rem >> 11) * 0x1F25u);

    return ((unsigned int)version << 12) | (rem & 0xFFFu);
}

#endif /* QR_MASK_H */
