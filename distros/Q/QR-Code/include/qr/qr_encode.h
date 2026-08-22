#ifndef QR_ENCODE_H
#define QR_ENCODE_H

#include <stdlib.h>
#include <string.h>

#include "qr/qr_gf.h"
#include "qr/qr_bits.h"
#include "qr/qr_mask.h"

/* qr_encode.h - byte mode QR encoding, versions 1 to 15.
 *
 * Byte mode only. An otpauth:// URI is mixed case, which alphanumeric
 * mode cannot represent at all, so the denser mode is not available and
 * numeric mode is irrelevant. Adding a mode later is additive: it
 * changes the header and the capacity check and nothing else.
 *
 * Versions stop at 15 because a centre logo forces ECC level H, which
 * roughly halves capacity - version 10 at H holds 119 bytes and a
 * typical enrolment URI is 149. Versions 7 and up carry a second
 * BCH-coded version information block; nothing further changes between
 * 7 and 15, so the ceiling is a matter of table rows.
 */

#define QR_ECC_L 0
#define QR_ECC_M 1
#define QR_ECC_Q 2
#define QR_ECC_H 3

#define QR_MIN_VERSION 1
#define QR_MAX_VERSION 15
#define QR_MAX_SIZE    (17 + 4 * QR_MAX_VERSION)   /* 77 */
#define QR_MAX_CW      655

/* Total codewords per version, data plus error correction. */
static const short qr_total_cw[QR_MAX_VERSION + 1] = {
    0, 26, 44, 70, 100, 134, 172, 196, 242, 292, 346, 404, 466, 532, 581, 655
};

/* Reed-Solomon block structure, ISO/IEC 18004 Table 9, indexed
 * [version][ecc] as { ec_per_block, g1_blocks, g1_data, g2_blocks,
 * g2_data }. Group 2 blocks, where present, hold exactly one more data
 * codeword than group 1. */
static const unsigned char qr_rs[QR_MAX_VERSION + 1][4][5] = {
    /* v0 unused */
    { {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0} },
    /* v1  */ { { 7,1, 19,0,  0}, {10,1, 16,0,  0}, {13,1, 13,0,  0}, {17,1,  9,0,  0} },
    /* v2  */ { {10,1, 34,0,  0}, {16,1, 28,0,  0}, {22,1, 22,0,  0}, {28,1, 16,0,  0} },
    /* v3  */ { {15,1, 55,0,  0}, {26,1, 44,0,  0}, {18,2, 17,0,  0}, {22,2, 13,0,  0} },
    /* v4  */ { {20,1, 80,0,  0}, {18,2, 32,0,  0}, {26,2, 24,0,  0}, {16,4,  9,0,  0} },
    /* v5  */ { {26,1,108,0,  0}, {24,2, 43,0,  0}, {18,2, 15,2, 16}, {22,2, 11,2, 12} },
    /* v6  */ { {18,2, 68,0,  0}, {16,4, 27,0,  0}, {24,4, 19,0,  0}, {28,4, 15,0,  0} },
    /* v7  */ { {20,2, 78,0,  0}, {18,4, 31,0,  0}, {18,2, 14,4, 15}, {26,4, 13,1, 14} },
    /* v8  */ { {24,2, 97,0,  0}, {22,2, 38,2, 39}, {22,4, 18,2, 19}, {26,4, 14,2, 15} },
    /* v9  */ { {30,2,116,0,  0}, {22,3, 36,2, 37}, {20,4, 16,4, 17}, {24,4, 12,4, 13} },
    /* v10 */ { {18,2, 68,2, 69}, {26,4, 43,1, 44}, {24,6, 19,2, 20}, {28,6, 15,2, 16} },
    /* v11 */ { {20,4, 81,0,  0}, {30,1, 50,4, 51}, {28,4, 22,4, 23}, {24,3, 12,8, 13} },
    /* v12 */ { {24,2, 92,2, 93}, {22,6, 36,2, 37}, {26,4, 20,6, 21}, {28,7, 14,4, 15} },
    /* v13 */ { {26,4,107,0,  0}, {22,8, 37,1, 38}, {24,8, 20,4, 21}, {22,12,11,4, 12} },
    /* v14 */ { {30,3,115,1,116}, {24,4, 40,5, 41}, {20,11,16,5, 17}, {24,11,12,5, 13} },
    /* v15 */ { {22,5, 87,1, 88}, {24,5, 41,5, 42}, {30,5, 24,7, 25}, {24,11,12,7, 13} }
};

/* Alignment pattern centre coordinates, zero-terminated. Patterns go at
 * every combination of these, minus the three that would land on a
 * finder.
 *
 * Worth noticing for anything that overlays the centre of a symbol:
 * versions with an odd number of centres (7 to 13) place one exactly in
 * the middle, and versions with an even number (2 to 6, 14, 15) do not. */
static const unsigned char qr_align[QR_MAX_VERSION + 1][8] = {
    {0},                    /* v0 unused */
    {0},                    /* v1  none */
    {6,18,0},               /* v2  */
    {6,22,0},               /* v3  */
    {6,26,0},               /* v4  */
    {6,30,0},               /* v5  */
    {6,34,0},               /* v6  */
    {6,22,38,0},            /* v7  */
    {6,24,42,0},            /* v8  */
    {6,26,46,0},            /* v9  */
    {6,28,50,0},            /* v10 */
    {6,30,54,0},            /* v11 */
    {6,32,58,0},            /* v12 */
    {6,34,62,0},            /* v13 */
    {6,26,46,66,0},         /* v14 */
    {6,26,48,70,0}          /* v15 */
};

typedef struct {
    int           version;
    int           ecc;
    int           mask;
    int           size;
    unsigned char mod[QR_MAX_SIZE * QR_MAX_SIZE];   /* 1 = dark */
    unsigned char fixed[QR_MAX_SIZE * QR_MAX_SIZE]; /* 1 = function pattern */
} qr_matrix;

/* Data codewords available at this version and ECC level. */
static int qr_data_cw(int version, int ecc)
{
    const unsigned char *r = qr_rs[version][ecc];
    return r[1] * r[2] + r[3] * r[4];
}

/* Byte mode payload capacity: the data codewords less the 4-bit mode
 * indicator and the character count. */
static int qr_capacity(int version, int ecc)
{
    int bits = qr_data_cw(version, ecc) * 8;
    return (bits - 4 - qr_bits_count_len(version)) / 8;
}

/* Smallest version holding `len` bytes at this ECC level, or -1. */
static int qr_pick_version(int len, int ecc)
{
    int v;

    for (v = QR_MIN_VERSION; v <= QR_MAX_VERSION; v++)
        if (qr_capacity(v, ecc) >= len)
            return v;

    return -1;
}

/* --- function patterns --------------------------------------------------- */

static void qr_set(qr_matrix *q, int row, int col, int dark, int fixed)
{
    if (row < 0 || col < 0 || row >= q->size || col >= q->size)
        return;
    q->mod[row * q->size + col] = (unsigned char)(dark ? 1 : 0);
    q->fixed[row * q->size + col] = (unsigned char)(fixed ? 1 : 0);
}

/* A finder pattern and its separator, anchored at the given top-left of
 * the 7x7 finder. The separator is the ring of light modules outside it,
 * which is written one module wider in every direction and simply falls
 * off the edge where the finder is against a border. */
static void qr_place_finder(qr_matrix *q, int top, int left)
{
    int r, c;

    for (r = -1; r <= 7; r++) {
        for (c = -1; c <= 7; c++) {
            int inner = (r >= 2 && r <= 4 && c >= 2 && c <= 4);
            int ring  = (r >= 0 && r <= 6 && c >= 0 && c <= 6) &&
                        (r == 0 || r == 6 || c == 0 || c == 6);
            qr_set(q, top + r, left + c, inner || ring, 1);
        }
    }
}

static void qr_place_alignment(qr_matrix *q, int row, int col)
{
    int r, c;

    for (r = -2; r <= 2; r++)
        for (c = -2; c <= 2; c++) {
            int dark = (r == 0 && c == 0) ||
                       (r == -2 || r == 2 || c == -2 || c == 2);
            qr_set(q, row + r, col + c, dark, 1);
        }
}

/* Reserve, without writing, the modules the format and version blocks
 * will occupy. They have to be off-limits to the data walk before it
 * runs, but their contents depend on the mask, which is not chosen
 * until after the data is placed. */
static void qr_reserve_info(qr_matrix *q)
{
    int size = q->size, i;

    /* Row 8 and column 8, except where they cross the timing patterns:
     * the format block skips (8,6) and (6,8) precisely because those
     * modules belong to the timing pattern. Reserving them here would
     * blank two timing modules - which still produces a symbol that
     * looks right at a glance, and a timing pattern is the one thing a
     * decoder cannot recover by error correction. */
    for (i = 0; i <= 8; i++) {
        if (i != 6) {
            qr_set(q, 8, i, 0, 1);
            qr_set(q, i, 8, 0, 1);
        }
    }
    for (i = 0; i < 8; i++) {
        qr_set(q, 8, size - 1 - i, 0, 1);
        qr_set(q, size - 1 - i, 8, 0, 1);
    }

    /* the dark module, which is a constant rather than format data */
    qr_set(q, size - 8, 8, 1, 1);

    if (q->version >= 7) {
        for (i = 0; i < 18; i++) {
            qr_set(q, i / 3, size - 11 + i % 3, 0, 1);
            qr_set(q, size - 11 + i % 3, i / 3, 0, 1);
        }
    }
}

static void qr_place_function_patterns(qr_matrix *q)
{
    int size = q->size, i, j;
    const unsigned char *a = qr_align[q->version];

    memset(q->mod, 0, (size_t)(size * size));
    memset(q->fixed, 0, (size_t)(size * size));

    qr_place_finder(q, 0, 0);
    qr_place_finder(q, 0, size - 7);
    qr_place_finder(q, size - 7, 0);

    /* timing patterns: row 6 and column 6, dark on even coordinates */
    for (i = 8; i < size - 8; i++) {
        qr_set(q, 6, i, (i % 2) == 0, 1);
        qr_set(q, i, 6, (i % 2) == 0, 1);
    }

    /* alignment patterns at every pair of centres except the three that
     * would sit on a finder */
    for (i = 0; a[i]; i++) {
        for (j = 0; a[j]; j++) {
            int r = a[i], c = a[j];
            int last = size - 7;
            if ((r == 6 && c == 6) ||
                (r == 6 && c >= last) ||
                (r >= last && c == 6))
                continue;
            qr_place_alignment(q, r, c);
        }
    }

    qr_reserve_info(q);
}

/* --- data placement ------------------------------------------------------ */

/* The zigzag walk: two-module-wide columns from the right edge leftward,
 * alternating upward and downward, right module before left, skipping
 * every module already claimed by a function pattern. Column 6 is
 * skipped entirely because the vertical timing pattern runs down it. */
static void qr_place_data(qr_matrix *q, const unsigned char *cw, int cw_len)
{
    int size = q->size;
    int bit = 0, total = cw_len * 8;
    int col, i, c;
    int upward = 1;

    for (col = size - 1; col > 0; col -= 2) {
        if (col == 6)
            col = 5;

        for (i = 0; i < size; i++) {
            int row = upward ? (size - 1 - i) : i;

            for (c = 0; c < 2; c++) {
                int cc = col - c;
                int idx = row * size + cc;
                int dark;

                if (q->fixed[idx])
                    continue;

                dark = 0;
                if (bit < total)
                    dark = (cw[bit >> 3] >> (7 - (bit & 7))) & 1;
                bit++;

                q->mod[idx] = (unsigned char)dark;
            }
        }
        upward = !upward;
    }
}

/* --- error correction ---------------------------------------------------- */

/* Split the data codewords into blocks, error-correct each, and
 * interleave. The interleave is what makes a contiguous burst of damage
 * survivable: consecutive modules on the symbol belong to different
 * blocks, so a blot covering one region spreads its damage evenly rather
 * than destroying one block outright. It is also what makes a centre
 * logo work. */
static int qr_build_codewords(int version, int ecc,
                              const unsigned char *data,
                              unsigned char *out)
{
    const unsigned char *r = qr_rs[version][ecc];
    int ec_len   = r[0];
    int g1_blocks = r[1], g1_data = r[2];
    int g2_blocks = r[3], g2_data = r[4];
    int blocks = g1_blocks + g2_blocks;
    int max_data = g2_data > g1_data ? g2_data : g1_data;
    unsigned char ecbuf[64][QR_MAX_EC];
    const unsigned char *dstart[64];
    int dlen[64];
    int i, j, pos = 0, n = 0;

    for (i = 0; i < blocks; i++) {
        int len = (i < g1_blocks) ? g1_data : g2_data;
        dstart[i] = data + pos;
        dlen[i] = len;
        pos += len;
        qr_rs_encode(dstart[i], len, ec_len, ecbuf[i]);
    }

    /* data codewords, column-major across blocks */
    for (j = 0; j < max_data; j++)
        for (i = 0; i < blocks; i++)
            if (j < dlen[i])
                out[n++] = dstart[i][j];

    /* then the error correction codewords, same way */
    for (j = 0; j < ec_len; j++)
        for (i = 0; i < blocks; i++)
            out[n++] = ecbuf[i][j];

    return n;
}

/* --- masking and the information blocks ---------------------------------- */

/* The fifteen format bits, twice.
 *
 * Bit 14 is the MSB and it goes FIRST, at (8,0). Writing this the other
 * way round - bit 0 at (8,0) - produces a symbol that is perfectly
 * self-consistent and that no scanner on earth can read, because the
 * format block is the one field a decoder must interpret before it can
 * do anything else. Verified against a known-good symbol rather than
 * from memory: both copies match at Hamming distance 0 MSB-first and 3
 * LSB-first.
 *
 * The second copy is seven modules up the right-hand column and eight
 * along the bottom row - not eight and seven. The eighth position down
 * that column is the dark module, so an off-by-one there silently loses
 * bit 7 when the dark module is written over it. */
static void qr_write_format(qr_matrix *q, int mask)
{
    static const unsigned char c1r[15] =
        { 8,8,8,8,8,8,8,8,7,5,4,3,2,1,0 };
    static const unsigned char c1c[15] =
        { 0,1,2,3,4,5,7,8,8,8,8,8,8,8,8 };
    unsigned int f = qr_format_bits(q->ecc, mask);
    int size = q->size, i;

    for (i = 0; i < 15; i++)
        qr_set(q, c1r[i], c1c[i], (f >> (14 - i)) & 1u, 1);

    for (i = 0; i < 7; i++)
        qr_set(q, size - 1 - i, 8, (f >> (14 - i)) & 1u, 1);
    for (i = 0; i < 8; i++)
        qr_set(q, 8, size - 8 + i, (f >> (7 - i)) & 1u, 1);

    qr_set(q, size - 8, 8, 1, 1);
}

static void qr_write_version(qr_matrix *q)
{
    unsigned int v;
    int size = q->size, i;

    if (q->version < 7)
        return;

    v = qr_version_bits(q->version);
    for (i = 0; i < 18; i++) {
        int b = (int)((v >> i) & 1u);
        qr_set(q, i / 3, size - 11 + i % 3, b, 1);
        qr_set(q, size - 11 + i % 3, i / 3, b, 1);
    }
}

/* Apply every mask in turn, score each, keep the best. The format block
 * has to be written before scoring, because its modules are part of the
 * symbol the penalty rules see. */
static void qr_apply_best_mask(qr_matrix *q)
{
    unsigned char best[QR_MAX_SIZE * QR_MAX_SIZE];
    int size = q->size, n = size * size;
    int best_score = -1, best_mask = 0;
    int m, i, j;

    for (m = 0; m < 8; m++) {
        int score;

        for (i = 0; i < size; i++)
            for (j = 0; j < size; j++) {
                int idx = i * size + j;
                if (!q->fixed[idx] && qr_mask_bit(m, i, j))
                    q->mod[idx] ^= 1;
            }

        qr_write_format(q, m);
        score = qr_penalty(q->mod, size);

        if (best_score < 0 || score < best_score) {
            best_score = score;
            best_mask = m;
            memcpy(best, q->mod, (size_t)n);
        }

        /* undo, ready for the next mask */
        for (i = 0; i < size; i++)
            for (j = 0; j < size; j++) {
                int idx = i * size + j;
                if (!q->fixed[idx] && qr_mask_bit(m, i, j))
                    q->mod[idx] ^= 1;
            }
    }

    memcpy(q->mod, best, (size_t)n);
    q->mask = best_mask;
}

/* --- the entry point ----------------------------------------------------- */

/* Encode `len` bytes at the given ECC level into `q`. Pass version 0 to
 * choose the smallest that fits. Returns 0 on success, -1 if the payload
 * does not fit at this level, -2 if the arguments are out of range. */
static int qr_encode(qr_matrix *q, const unsigned char *data, int len,
                     int ecc, int version)
{
    unsigned char stream[QR_MAX_CW];
    unsigned char final[QR_MAX_CW];
    qr_bits bits;
    int data_cw, n, i;

    if (ecc < 0 || ecc > 3 || len < 0)
        return -2;

    if (version == 0) {
        version = qr_pick_version(len, ecc);
        if (version < 0)
            return -1;
    } else {
        if (version < QR_MIN_VERSION || version > QR_MAX_VERSION)
            return -2;
        if (qr_capacity(version, ecc) < len)
            return -1;
    }

    q->version = version;
    q->ecc = ecc;
    q->size = 17 + 4 * version;
    q->mask = 0;

    data_cw = qr_data_cw(version, ecc);

    qr_bits_init(&bits, stream, data_cw);
    qr_bits_put(&bits, 0x4u, 4);                                /* byte mode */
    qr_bits_put(&bits, (unsigned int)len, qr_bits_count_len(version));
    for (i = 0; i < len; i++)
        qr_bits_put(&bits, data[i], 8);
    qr_bits_finish(&bits, data_cw);

    n = qr_build_codewords(version, ecc, stream, final);

    qr_place_function_patterns(q);
    qr_place_data(q, final, n);
    qr_apply_best_mask(q);
    qr_write_version(q);

    return 0;
}

#endif /* QR_ENCODE_H */
