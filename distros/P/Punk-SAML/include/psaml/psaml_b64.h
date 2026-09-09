#ifndef PSAML_B64_H
#define PSAML_B64_H

/* Standard base64, RFC 4648 section 4, with padding.
 *
 * jws_abi.h has the base64url form only (section 5, unpadded), which is
 * the wrong alphabet here: SAML carries the standard alphabet with `+`
 * and `/` in SAMLRequest, SAMLResponse and every ds:X509Certificate, and
 * decoding one as the other silently produces different bytes rather
 * than an error.
 *
 * Decoding is strict, because this is an input parser at a security
 * boundary. Strict means:
 *   - the standard alphabet only; `-` and `_` are refused rather than
 *     quietly accepted, so a url-form token cannot arrive here and
 *     decode to something plausible
 *   - length a multiple of four, padding only at the end, at most two
 *     `=`, and nothing after them
 *   - the unused low bits of the last group must be zero, so one
 *     encoding decodes from one input and a mutated tail is refused
 *     rather than ignored
 *
 * Whitespace is the one thing a caller chooses, and the choice is not
 * cosmetic. Base64 inside XML content is line-wrapped by essentially
 * every identity provider, so psaml_b64_decode_xml accepts space, tab,
 * CR and LF between characters; a protocol field like SAMLResponse has
 * no such excuse and goes through psaml_b64_decode, which refuses them. */

#include <string.h>

static const char PSAML_B64_ALPHA[] =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/* -1 not in the alphabet, -2 padding, -3 skippable whitespace */
PERL_STATIC_INLINE signed char psaml_b64_val(unsigned char c) {
  if (c >= 'A' && c <= 'Z') return (signed char)(c - 'A');
  if (c >= 'a' && c <= 'z') return (signed char)(c - 'a' + 26);
  if (c >= '0' && c <= '9') return (signed char)(c - '0' + 52);
  if (c == '+') return 62;
  if (c == '/') return 63;
  if (c == '=') return -2;
  if (c == ' ' || c == '\t' || c == '\r' || c == '\n') return -3;
  return -1;
}

PERL_STATIC_INLINE STRLEN psaml_b64_encoded_len(STRLEN n) {
  return ((n + 2) / 3) * 4;
}

/* Writes exactly psaml_b64_encoded_len(n) bytes; no NUL. */
PERL_STATIC_INLINE STRLEN psaml_b64_encode(char *out, const unsigned char *in, STRLEN n) {
  char *o = out;
  STRLEN i = 0;
  while (i + 3 <= n) {
    unsigned v = ((unsigned)in[i] << 16) | ((unsigned)in[i+1] << 8) | in[i+2];
    *o++ = PSAML_B64_ALPHA[(v >> 18) & 63];
    *o++ = PSAML_B64_ALPHA[(v >> 12) & 63];
    *o++ = PSAML_B64_ALPHA[(v >>  6) & 63];
    *o++ = PSAML_B64_ALPHA[ v        & 63];
    i += 3;
  }
  if (n - i == 1) {
    unsigned v = (unsigned)in[i] << 16;
    *o++ = PSAML_B64_ALPHA[(v >> 18) & 63];
    *o++ = PSAML_B64_ALPHA[(v >> 12) & 63];
    *o++ = '=';
    *o++ = '=';
  }
  else if (n - i == 2) {
    unsigned v = ((unsigned)in[i] << 16) | ((unsigned)in[i+1] << 8);
    *o++ = PSAML_B64_ALPHA[(v >> 18) & 63];
    *o++ = PSAML_B64_ALPHA[(v >> 12) & 63];
    *o++ = PSAML_B64_ALPHA[(v >>  6) & 63];
    *o++ = '=';
  }
  return (STRLEN)(o - out);
}

/* Upper bound on the decoded size, for allocation. */
PERL_STATIC_INLINE STRLEN psaml_b64_decoded_max(STRLEN n) {
  return (n / 4 + 1) * 3;
}

/* Returns the decoded length, or (STRLEN)-1 on any refusal. `out` must
 * have room for psaml_b64_decoded_max(n). allow_ws skips space, tab, CR
 * and LF anywhere between characters. */
PERL_STATIC_INLINE STRLEN psaml_b64_decode_ws(unsigned char *out, const char *in,
                                  STRLEN n, int allow_ws) {
  unsigned char *o = out;
  unsigned      quad = 0;
  int           have = 0;   /* alphabet characters in the current group */
  int           pad  = 0;
  STRLEN        i;

  for (i = 0; i < n; i++) {
    signed char v = psaml_b64_val((unsigned char)in[i]);
    if (v == -3) {
      if (allow_ws) continue;
      return (STRLEN)-1;
    }
    if (v == -1) return (STRLEN)-1;
    if (v == -2) {                      /* '=' */
      if (have < 2) return (STRLEN)-1;  /* "=" or "A=" is never valid */
      if (++pad > 2) return (STRLEN)-1;
      quad <<= 6;
      have++;
      if (have == 4) {
        /* flush what the padding leaves: one byte for "xx==", two for
         * "xxx=", and the bits the padding stands for must be zero */
        if (pad == 2) {
          if (quad & 0xFFFFu) return (STRLEN)-1;
          *o++ = (unsigned char)((quad >> 16) & 0xFF);
        }
        else {
          if (quad & 0xFFu) return (STRLEN)-1;
          *o++ = (unsigned char)((quad >> 16) & 0xFF);
          *o++ = (unsigned char)((quad >>  8) & 0xFF);
        }
        have = 0;
        quad = 0;
      }
      continue;
    }
    if (pad) return (STRLEN)-1;         /* data after padding */
    quad = (quad << 6) | (unsigned)v;
    if (++have == 4) {
      *o++ = (unsigned char)((quad >> 16) & 0xFF);
      *o++ = (unsigned char)((quad >>  8) & 0xFF);
      *o++ = (unsigned char)( quad        & 0xFF);
      have = 0;
      quad = 0;
    }
  }
  if (have) return (STRLEN)-1;           /* a trailing partial group */
  return (STRLEN)(o - out);
}

PERL_STATIC_INLINE STRLEN psaml_b64_decode(unsigned char *out, const char *in, STRLEN n) {
  return psaml_b64_decode_ws(out, in, n, 0);
}

PERL_STATIC_INLINE STRLEN psaml_b64_decode_xml(unsigned char *out, const char *in,
                                   STRLEN n) {
  return psaml_b64_decode_ws(out, in, n, 1);
}

#endif /* PSAML_B64_H */
