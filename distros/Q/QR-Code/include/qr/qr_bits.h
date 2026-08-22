#ifndef QR_BITS_H
#define QR_BITS_H

#include <string.h>

/* qr_bits.h - the bit writer that assembles a QR data stream.
 *
 * The stream is, in order: a 4-bit mode indicator, a character count
 * whose width depends on the version, the payload, a terminator of up to
 * four zero bits, zero padding to the next byte boundary, and then the
 * alternating pad bytes 0xEC 0x11 until the data capacity is full.
 *
 * Bits are written most significant first, which is the only ordering
 * the format allows and the one thing here that is easy to get backwards.
 */

typedef struct {
    unsigned char *buf;   /* caller-owned, at least cap bytes */
    int            cap;   /* capacity in BYTES */
    int            len;   /* length written so far, in BITS */
} qr_bits;

static void qr_bits_init(qr_bits *b, unsigned char *buf, int cap)
{
    b->buf = buf;
    b->cap = cap;
    b->len = 0;
    memset(buf, 0, (size_t)cap);
}

/* Append the low `n` bits of `val`, most significant first. Silently
 * refuses to run past the buffer: capacity is chosen by the version
 * selector before anything is written, so an overrun here would be a
 * bug in the caller rather than bad input, and a truncated symbol is
 * easier to diagnose than a smashed stack. */
static void qr_bits_put(qr_bits *b, unsigned int val, int n)
{
    int i;

    for (i = n - 1; i >= 0; i--) {
        int bit = (int)((val >> i) & 1u);
        int pos = b->len;

        if (pos >= b->cap * 8)
            return;

        if (bit)
            b->buf[pos >> 3] |= (unsigned char)(0x80 >> (pos & 7));

        b->len++;
    }
}

/* The character count indicator width for byte mode. Eight bits through
 * version 9, sixteen from version 10 - a boundary that sits inside the
 * supported range, so a wrong branch here is invisible for short inputs
 * and only shows up near capacity. */
static int qr_bits_count_len(int version)
{
    return version < 10 ? 8 : 16;
}

/* Close the stream: terminator, byte alignment, then pad bytes to fill
 * `data_cw` codewords. */
static void qr_bits_finish(qr_bits *b, int data_cw)
{
    int limit = data_cw * 8;
    int remain = limit - b->len;
    int i;

    /* terminator: up to four zero bits, fewer if the stream is nearly
     * full, none if it is exactly full */
    if (remain > 4)
        remain = 4;
    for (i = 0; i < remain; i++)
        qr_bits_put(b, 0, 1);

    /* pad to a byte boundary */
    while (b->len % 8 != 0)
        qr_bits_put(b, 0, 1);

    /* alternating pad codewords until the data capacity is used */
    for (i = 0; b->len < limit; i++)
        qr_bits_put(b, (i % 2) ? 0x11u : 0xECu, 8);
}

#endif /* QR_BITS_H */
