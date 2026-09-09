#ifndef PSAML_DEFLATE_H
#define PSAML_DEFLATE_H

/* Raw DEFLATE (RFC 1951), stored blocks only.
 *
 * The HTTP-Redirect binding carries the AuthnRequest as raw DEFLATE,
 * base64, then percent-encoded. Nothing in this family links zlib and
 * this is the only place a compressor is wanted, so rather than take a
 * dependency for it we emit the one block type that needs no compressor
 * at all: BTYPE 00, stored, which is a five-byte header and the bytes
 * themselves.
 *
 * That is legal, complete DEFLATE. Every inflater reads it, which is
 * what matters, because the reader here is somebody else's identity
 * provider and it must never have to be tolerant of us.
 *
 * What it costs is the compression, and the redirect binding is where a
 * URL length limit actually bites. An AuthnRequest is around 1 KB and
 * grows by five bytes per 65535 here rather than shrinking by about
 * two thirds, so the encoded URL is roughly three times what a real
 * deflater would produce. It stays inside every limit that matters
 * (Internet Explorer's 2083 characters is the historical floor and no
 * longer applies; Apache's default is 8190), and the moment this dist
 * signs something large enough to care, this header is where a fixed
 * Huffman encoder goes. There is no inflater here: the SP deflates its
 * own request and never inflates anything, because Responses arrive
 * over the POST binding uncompressed.
 *
 * The caller sizes the output with psaml_deflate_bound. */

#include <string.h>

#define PSAML_DEFLATE_MAX_BLOCK 65535

PERL_STATIC_INLINE STRLEN psaml_deflate_bound(STRLEN n) {
  /* five bytes per block, and a final empty block when n is a multiple
   * of the block size (including n == 0, which still needs one block to
   * carry BFINAL) */
  STRLEN blocks = n / PSAML_DEFLATE_MAX_BLOCK + 1;
  return n + blocks * 5;
}

/* Writes raw DEFLATE into out, which must have psaml_deflate_bound(n)
 * bytes. Returns the number written. */
PERL_STATIC_INLINE STRLEN psaml_deflate_stored(unsigned char *out,
                                   const unsigned char *in, STRLEN n) {
  unsigned char *o = out;
  STRLEN i = 0;
  for (;;) {
    STRLEN chunk = n - i;
    int    final;
    if (chunk > PSAML_DEFLATE_MAX_BLOCK) chunk = PSAML_DEFLATE_MAX_BLOCK;
    final = (i + chunk == n);
    /* BFINAL in bit 0, BTYPE 00 in bits 1-2, then the byte-aligned
     * LEN/NLEN pair little-endian. A stored block's header is the only
     * one in DEFLATE that is byte aligned, which is why this needs no
     * bit writer. */
    *o++ = (unsigned char)(final ? 1 : 0);
    *o++ = (unsigned char)( chunk        & 0xFF);
    *o++ = (unsigned char)((chunk >>  8) & 0xFF);
    *o++ = (unsigned char)(~chunk        & 0xFF);
    *o++ = (unsigned char)((~chunk >> 8) & 0xFF);
    if (chunk) {
      memcpy(o, in + i, chunk);
      o += chunk;
    }
    i += chunk;
    if (final) break;
  }
  return (STRLEN)(o - out);
}

#endif /* PSAML_DEFLATE_H */
