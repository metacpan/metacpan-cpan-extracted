/*
 * Converts a string into a int128_t
 *
 * modified from strtoint128.h in Math::Int128, which in turn is:
 *
 * based on OpenBSD: strtoll.c,v 1.6 2005/11/10 10:00:17 espie Exp $
 */

/*-
 * Copyright (c) 1992 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include "perl.h"
#include <ctype.h>

/*
 * Convert a string to an int128_t/uint128_t.
 */

static groknum_err_t
strtoint128(pTHX_ const char *s, STRLEN len,
                  int base, int sign, uint128_t *u128) {
    uint128_t acc = 0;
    int c, neg, between = 0;
    const char *top = s + len;
    uint128_t upper_mul_limit = 0;

    /*
     * Skip white space and pick up leading +/- sign if any.
     * If base is 0, allow 0x for hex and 0 for octal, else
     * assume decimal; if base is already 16, allow 0x.
     */
    do {
        if (s >= top) {
            *u128 = 0;
            return GROKNUM_OK;
        }
        c = *s++;
    } while (isspace(c));

    if (c == '-') {
        if (!sign)
            return GROKNUM_ERR_NEG;
        if (s >= top) {
            *u128 = 0;
            return GROKNUM_OK;
        }
        neg = 1;
        c = *s++;
    } else {
        neg = 0;
        if (c == '+') {
            if (s >= top) {
                *u128 = 0;
                return GROKNUM_OK;
            }
            c = *s++;
        }
    }
    if (((base == 0) || (base == 16)) &&
        (c == '0') &&
        (s + 1 < top) && ((*s == 'x') || (*s == 'X'))) {
        c = s[1];
        s += 2;
        base = 16;
    }

    if (base == 0)
        base = ((c == '0') ? 8 : 10);

    for (;s <= top; c = (unsigned char) *s++) {
        if (isdigit(c))
            c -= '0';
        else if (isalpha(c))
            c -= isupper(c) ? 'A' - 10 : 'a' - 10;
        else if ((c == '_') && between)
            continue; /* ignore underscores as Perl does */
        else
            return GROKNUM_ERR_NAN;
        if (c >= base)
            return GROKNUM_ERR_NAN;
        redo:
        if (acc > upper_mul_limit) {
            if (!upper_mul_limit) {
                upper_mul_limit = UINT128_MAX / base;
                goto redo;
            }
            return sign ? GROKNUM_ERR_I128_OVERFLOW :
                          GROKNUM_ERR_U128_OVERFLOW;
        }
        acc *= base;
        if (UINT128_MAX - acc < c)
            return sign ? GROKNUM_ERR_I128_OVERFLOW :
                          GROKNUM_ERR_U128_OVERFLOW;
        acc += c;
        between = 1;
    }
    if (sign && ( acc > (neg ? (~(uint128_t)INT128_MIN + 1) : INT128_MAX) ) )
        return GROKNUM_ERR_I128_OVERFLOW;

    *u128 = (neg ? ~acc + 1 : acc);
    return GROKNUM_OK;
}
