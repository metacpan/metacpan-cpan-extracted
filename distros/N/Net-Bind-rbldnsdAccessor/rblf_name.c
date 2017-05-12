/*	rblf_name.c
 * Copyright (c) 2004 by Internet Systems Consortium, Inc. ("ISC")
 * Copyright (c) 1996,1999 by Internet Software Consortium.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
 * OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/*
 * Copyright (c) 2006 by Michael Robinton, michael@bizsystems.com
 *
 * Permission to use, copy, modify, and distribute this software for any 
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.  
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND MICHAEL ROBINTON DISCLAIMS ALL
 * WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS.  IN NO EVENT SHALL MICHAEL ROBINTON BE
 * LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR
 * ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, 
 * WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
 * ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 */
            
 
#include <string.h>
#include <errno.h>
#include <arpa/nameser.h>

#define NS_TYPE_ELT			0x40	/* EDNS0 extended label type */
#define DNS_LABELTYPE_BITSTRING		0x41
#ifndef NS_CMPRSFLGS
#define NS_CMPRSFLGS			0xc0	/* Flag bits indicating name compression. */
#endif

static int
rblf_labellen(const unsigned char *lp)
{
	int bitlen;
	unsigned char l = *lp;

	if ((l & NS_CMPRSFLGS) == NS_CMPRSFLGS) {
		/* should be avoided by the caller */
		return(-1);
	}

	if ((l & NS_CMPRSFLGS) == NS_TYPE_ELT) {
		if (l == DNS_LABELTYPE_BITSTRING) {
			if ((bitlen = *(lp + 1)) == 0)
				bitlen = 256;
			return((bitlen + 7 ) / 8 + 1);
		}
		return(-1);	/* unknwon ELT */
	}
	return(l);
}

/*
 * rblf_unpack(msg, eom, *src, dst, dstlim)
 *	Unpack a domain name from a message, source may be compressed.
 * return:
 *	-1 on failure, length of unpacked string on success
 *	Advance *ptrptr to skip over the compressed name it points at
 */
int
rblf_unpack(unsigned char *msg, unsigned char *eom, unsigned char **ptrptr,unsigned char *dst, unsigned char *dstlim)
{
	const unsigned char *src, *srcp;
	unsigned char *dstp;
	int n, len, checked, l;

	len = -1;
	checked = 0;
	dstp = dst;
	src = *ptrptr;
	srcp = src;
	if (srcp < msg || srcp >= eom) {
		errno = EMSGSIZE;
		return (-1);
	}
	/* Fetch next label in domain name. */
	while ((n = *srcp++) != 0) {
		/* Check for indirection. */
		switch (n & NS_CMPRSFLGS) {
		case 0:
		case NS_TYPE_ELT:
			/* Limit checks. */
			if ((l = rblf_labellen(srcp - 1)) < 0) {
				errno = EMSGSIZE;
				return(-1);
			}
			if (dstp + l + 1 >= dstlim || srcp + l >= eom) {
				errno = EMSGSIZE;
				return (-1);
			}
			checked += l + 1;
			*dstp++ = n;
			memcpy(dstp, srcp, l);
			dstp += l;
			srcp += l;
			break;

		case NS_CMPRSFLGS:
			if (srcp >= eom) {
				errno = EMSGSIZE;
				return (-1);
			}
			if (len < 0)
				len = srcp - src + 1;
			srcp = msg + (((n & 0x3f) << 8) | (*srcp & 0xff));
			if (srcp < msg || srcp >= eom) {  /* Out of range. */
				errno = EMSGSIZE;
				return (-1);
			}
			checked += 2;
			/*
			 * Check for loops in the compressed name;
			 * if we've looked at the whole message,
			 * there must be a loop.
			 */
			if (checked >= eom - msg) {
				errno = EMSGSIZE;
				return (-1);
			}
			break;

		default:
			errno = EMSGSIZE;
			return (-1);			/* flag error */
		}
	}
	*dstp++ = '\0';
	if (len < 0)
		len = srcp - src;
	*ptrptr += len;
	len = dstp - dst;
	return (len);
}

/*
 * rblf_skip(ptrptr, eom)
 *	Advance *ptrptr to skip over the compressed name it points at.
 * return:
 *	0 on success, -1 (with errno set) on failure.
 */
int
rblf_skip(const unsigned char **ptrptr, const unsigned char *eom)
{
	const unsigned char *cp;
	unsigned int n;
	int l;

	cp = *ptrptr;
	while (cp < eom && (n = *cp++) != 0) {
		/* Check for indirection. */
		switch (n & NS_CMPRSFLGS) {
		case 0:			/* normal case, n == len */
			cp += n;
			continue;
		case NS_TYPE_ELT: /* EDNS0 extended label */
			if ((l = rblf_labellen(cp - 1)) < 0) {
				errno = EMSGSIZE; /* XXX */
				return(-1);
			}
			cp += l;
			continue;
		case NS_CMPRSFLGS:	/* indirection */
			cp++;
			break;
		default:		/* illegal type */
			errno = EMSGSIZE;
			return (-1);
		}
		break;
	}
	if (cp > eom) {
		errno = EMSGSIZE;
		return (-1);
	}
	*ptrptr = cp;
	return (0);
}
