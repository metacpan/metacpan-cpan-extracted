#ifndef PCHAL_B64_H
#define PCHAL_B64_H

/* base64url, no padding: the one alphabet that is safe in a cookie value, a
 * header, a query string, a data attribute and JSON without escaping.
 *
 * Encode only. Nothing here decodes a MAC: a presented token is verified by
 * recomputing the MAC, encoding it the same way and comparing the text, so
 * there is no decoder for a hostile string to reach.
 *
 * Needs nothing before it.
 */

static const char PCHAL_B64U[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

/* Bytes an encoding of `len` input bytes needs. */
#define PCHAL_B64_LEN(len) (4 * (((len) + 2) / 3))

/* Encodes into `out`, which must hold PCHAL_B64_LEN(len) bytes, and returns
 * the number written. No terminator is added. */
static size_t pchal_b64url(const unsigned char *in, size_t len, char *out)
{
    size_t i = 0, o = 0;
    for (; i + 3 <= len; i += 3) {
        U32 n = ((U32)in[i] << 16) | ((U32)in[i+1] << 8) | (U32)in[i+2];
        out[o++] = PCHAL_B64U[(n >> 18) & 63];
        out[o++] = PCHAL_B64U[(n >> 12) & 63];
        out[o++] = PCHAL_B64U[(n >> 6) & 63];
        out[o++] = PCHAL_B64U[n & 63];
    }
    if (i < len) {
        size_t rem = len - i;
        U32 n = (U32)in[i] << 16;
        if (rem == 2) n |= (U32)in[i+1] << 8;
        out[o++] = PCHAL_B64U[(n >> 18) & 63];
        out[o++] = PCHAL_B64U[(n >> 12) & 63];
        if (rem == 2) out[o++] = PCHAL_B64U[(n >> 6) & 63];
    }
    return o;
}

#endif /* PCHAL_B64_H */
