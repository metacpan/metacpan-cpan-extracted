#ifndef QR_IMG_H
#define QR_IMG_H

#include <stddef.h>

/* qr_img.h - what a raster logo needs from its bytes, and nothing more.
 *
 * A PNG or JPEG logo is never decoded: the SVG output embeds the bytes
 * as a data: URI and the renderer does the decoding. The only facts the
 * box geometry needs are the format (for the MIME type) and the pixel
 * dimensions (for the aspect ratio), and both formats state them in
 * their headers.
 *
 * The format comes from magic bytes, never from a file extension. A
 * file named .png that is actually a JPEG is a thing that happens, and
 * an <image> whose MIME type does not match its bytes renders as
 * nothing in some viewers.
 */

#define QR_IMG_UNKNOWN 0
#define QR_IMG_PNG     1
#define QR_IMG_JPEG    2
#define QR_IMG_SVG     3

/* Sniff the format. SVG is anything that opens with '<' once an
 * optional UTF-8 BOM and leading whitespace are skipped - the XML
 * declaration, a comment, or the root element itself all qualify. */
static int qr_img_sniff(const unsigned char *p, size_t n)
{
    static const unsigned char png_sig[8] =
        { 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A };
    size_t i = 0;

    if (n >= 8 && memcmp(p, png_sig, 8) == 0)
        return QR_IMG_PNG;

    if (n >= 3 && p[0] == 0xFF && p[1] == 0xD8 && p[2] == 0xFF)
        return QR_IMG_JPEG;

    if (n >= 3 && p[0] == 0xEF && p[1] == 0xBB && p[2] == 0xBF)
        i = 3;
    while (i < n && (p[i] == ' ' || p[i] == '\t' ||
                     p[i] == '\r' || p[i] == '\n'))
        i++;
    if (i < n && p[i] == '<')
        return QR_IMG_SVG;

    return QR_IMG_UNKNOWN;
}

/* Pixel dimensions from the header. Returns 0 and fills *w, *h, or -1
 * when the bytes are truncated or structurally wrong.
 *
 * PNG: the IHDR chunk is required to come first, so width and height
 * sit at fixed offsets - big-endian 32-bit at 16 and 20, after the
 * 8-byte signature, the 4-byte chunk length, and "IHDR". No chunk walk.
 *
 * JPEG: segments are a 0xFF marker byte, a marker, and for most
 * markers a two-byte big-endian length that includes itself. Walk them
 * until a start-of-frame marker - 0xC0 to 0xCF excluding 0xC4 (DHT),
 * 0xC8 (JPG extension), 0xCC (DAC) - which covers baseline SOF0 and
 * progressive SOF2 alike. Height then width sit at offsets 3 and 5 of
 * the segment body, after the length and the precision byte. EXIF
 * orientation is deliberately ignored; the POD owns that caveat. */
static int qr_img_dims(const unsigned char *p, size_t n, int fmt,
                       unsigned long *w, unsigned long *h)
{
    if (fmt == QR_IMG_PNG) {
        if (n < 24)
            return -1;
        if (memcmp(p + 12, "IHDR", 4) != 0)
            return -1;
        *w = ((unsigned long)p[16] << 24) | ((unsigned long)p[17] << 16) |
             ((unsigned long)p[18] << 8)  |  (unsigned long)p[19];
        *h = ((unsigned long)p[20] << 24) | ((unsigned long)p[21] << 16) |
             ((unsigned long)p[22] << 8)  |  (unsigned long)p[23];
        return (*w == 0 || *h == 0) ? -1 : 0;
    }

    if (fmt == QR_IMG_JPEG) {
        size_t i = 2;

        while (i + 3 < n) {
            unsigned int marker, len;

            if (p[i] != 0xFF)
                return -1;
            while (i < n && p[i] == 0xFF)   /* fill bytes are legal */
                i++;
            if (i >= n)
                return -1;
            marker = p[i++];

            /* standalone markers carry no length */
            if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD9))
                continue;
            if (i + 1 >= n)
                return -1;
            len = ((unsigned int)p[i] << 8) | p[i + 1];
            if (len < 2 || i + len > n)
                return -1;

            if (marker >= 0xC0 && marker <= 0xCF &&
                marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
                if (len < 7)
                    return -1;
                *h = ((unsigned long)p[i + 3] << 8) | p[i + 4];
                *w = ((unsigned long)p[i + 5] << 8) | p[i + 6];
                return (*w == 0 || *h == 0) ? -1 : 0;
            }

            i += len;
        }
        return -1;
    }

    return -1;
}

/* --- base64, for the data: URI ------------------------------------------- */

static size_t qr_b64_len(size_t n)
{
    return ((n + 2) / 3) * 4;
}

static void qr_b64_encode(const unsigned char *src, size_t n, char *dst)
{
    static const char tab[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    size_t i;

    for (i = 0; i + 2 < n; i += 3) {
        unsigned long v = ((unsigned long)src[i] << 16) |
                          ((unsigned long)src[i + 1] << 8) | src[i + 2];
        *dst++ = tab[(v >> 18) & 63];
        *dst++ = tab[(v >> 12) & 63];
        *dst++ = tab[(v >> 6) & 63];
        *dst++ = tab[v & 63];
    }
    if (i < n) {
        unsigned long v = (unsigned long)src[i] << 16;
        if (i + 1 < n)
            v |= (unsigned long)src[i + 1] << 8;
        *dst++ = tab[(v >> 18) & 63];
        *dst++ = tab[(v >> 12) & 63];
        *dst++ = (i + 1 < n) ? tab[(v >> 6) & 63] : '=';
        *dst++ = '=';
    }
    *dst = '\0';
}

#endif /* QR_IMG_H */
