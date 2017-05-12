/* 
inet_pton.c -- convert IPv4 and IPv6 addresses from text to binary form

Modifications to inet_pton6 allowing IPv4 addresses to appear
throughout, and miscellaneous modifications to inet_pton4, by Tom
Harrison <tomhrr@cpan.org> (Copyright (C) 2010).

Copyright (C) 2006 Free Software Foundation, Inc.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software Foundation,
Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

Copyright (c) 1996,1999 by Internet Software Consortium.

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM DISCLAIMS
ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL INTERNET SOFTWARE
CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
SOFTWARE.
*/

#include <ctype.h>
#include <string.h>
#include <errno.h>

#define NS_INADDRSZ  4
#define NS_IN6ADDRSZ 16
#define NS_INT16SZ   2

int inet_pton4 (const char *src, unsigned char *dst);
int inet_pton6 (const char *src, unsigned char *dst);

/* int
 * inet_pton4(src, dst)
 *	like inet_aton() but without all the hexadecimal, octal (with the
 *	exception of 0) and shorthand.
 * return:
 *	1 if `src' is a valid dotted quad, else 0.
 * notice:
 *	does not touch `dst' unless it's returning 1.
 * author:
 *	Paul Vixie, 1996.
 *      (Some modifications by Tom Harrison, 2010.)
 */
int
inet_pton4 (const char *src, unsigned char *dst)
{
    int saw_digit, octets, ch;
    unsigned char tmp[NS_INADDRSZ], *tp;

    memset(tmp, 0, NS_INADDRSZ);
    saw_digit = 0;
    octets = 0;
    *(tp = tmp) = 0;
    
    while ((ch = *src++) != '\0') {
        if (ch >= '0' && ch <= '9') {
	    unsigned n = *tp * 10 + (ch - '0');
	  
            if (saw_digit && *tp == 0) {
                return 0;
            }
            if (n > 255) {
                return 0;
            }
            *tp = n;
            if (!saw_digit) {
                ++octets;
                saw_digit = 1;
	    }
        } else if (ch == '.' && saw_digit) {
            if (octets == 4) {
                return 0;
            }
            ++tp;
            saw_digit = 0;
	} else {
            return 0;
        }
    }
    
    memcpy(dst, tmp, NS_INADDRSZ);
    return 1;
}

/* int
 * inet_pton6(src, dst)
 *	convert presentation level address to network order binary form.
 * return:
 *	1 if `src' is a valid IPv6 address (may contain IPv4 addresses
 *      in any position), else 0.
 * notice:
 *	(1) does not touch `dst' unless it's returning 1.
 *	(2) :: in a full address is silently ignored.
 * credit:
 *	inspired by Mark Andrews.
 * author:
 *	Paul Vixie, 1996.
 *      (Modifications allowing IPv4 addresses to appear throughout
 *       by Tom Harrison, 2010.)
 */
int
inet_pton6 (const char *src, unsigned char *dst)
{
    static const char xdigits[] = "0123456789abcdef";
    unsigned char tmp[NS_IN6ADDRSZ], *tp, *endp, *colonp;
    const char *ipv4_endp;
    char ipv4[16];
    int diff;
    const char *curtok;
    int ch, saw_xdigit;
    unsigned val;

    tp = (unsigned char *) memset (tmp, '\0', NS_IN6ADDRSZ);
    endp = tp + NS_IN6ADDRSZ;
    colonp = NULL;
    /* Leading :: requires some special handling. */
    if (*src == ':') {
        if (*++src != ':') {
            return 0;
        }
    }
    curtok = src;
    saw_xdigit = 0;
    val = 0;
    while ((ch = tolower (*src++)) != '\0') {
        const char *pch;

        pch = strchr (xdigits, ch);
        if (pch != NULL) {
            val <<= 4;
            val |= (pch - xdigits);
            if (val > 0xffff) {
                return 0;
            }
            saw_xdigit = 1;
            continue;
        }
        if (ch == ':') {
            curtok = src;
            if (!saw_xdigit) {
                if (colonp) {
                    return 0;
                }
                colonp = tp;
                continue;
	    } else if (*src == '\0') {
                return 0;
	    }
            if (tp + NS_INT16SZ > endp) {
                return 0;
            }
            *tp++ = (unsigned char) (val >> 8) & 0xff;
            *tp++ = (unsigned char) val & 0xff;
            saw_xdigit = 0;
            val = 0;
            continue;
	}
        if (ch == '.' && ((tp + NS_INADDRSZ) <= endp)) {
            /* Find the next : from curtok, copy from curtok to that
             * point to ipv4, if it's IPv4 all is good. If the : is not found,
             * it terminates, so check it directly. */
            ipv4_endp = strchr(curtok, ':');
            if (ipv4_endp) {
                diff = ipv4_endp - curtok;
                if (diff > 15) {
                    return 0;
                }
                memcpy(ipv4, curtok, diff);
                ipv4[diff] = '\0';
                diff = inet_pton4(ipv4, tp);
            } else {
                diff = inet_pton4(curtok, tp);
            }
            if (diff) {
                val = (tp[2] << 8) | tp[3];
                tp += 2;
                saw_xdigit=1;
                if (ipv4_endp) {
                    src = ipv4_endp;
                    continue;
                } else {
                    saw_xdigit=0;
                    tp += 2; 
                    break;
                }
            }
        }
        return 0;
    }
    if (saw_xdigit) {
        if (tp + NS_INT16SZ > endp) {
            return 0;
        }
        *tp++ = (unsigned char) (val >> 8) & 0xff;
        *tp++ = (unsigned char) val & 0xff;
    }
    if (colonp != NULL) {
        /*
         * Since some memmove()'s erroneously fail to handle
         * overlapping regions, we'll do the shift by hand.
         */
        const int n = tp - colonp;
        int i;

        if (tp == endp) {
            return 0;
        }
        for (i = 1; i <= n; i++) {
            endp[-i] = colonp[n - i];
            colonp[n - i] = 0;
        }
        tp = endp;
    }

    while (tp < endp) {
        *(tp++) = 0;
    }
    memcpy(dst, tmp, NS_IN6ADDRSZ);
    return 1;
}
