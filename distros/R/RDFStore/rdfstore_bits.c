/*
##############################################################################
# 	Copyright (c) 2000-2006 All rights reserved
# 	Alberto Reggiori <areggiori@webweaving.org>
#	Dirk-Willem van Gulik <dirkx@webweaving.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer. 
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. The end-user documentation included with the redistribution,
#    if any, must include the following acknowledgment:
#       "This product includes software developed by 
#        Alberto Reggiori <areggiori@webweaving.org> and
#        Dirk-Willem van Gulik <dirkx@webweaving.org>."
#    Alternately, this acknowledgment may appear in the software itself,
#    if and wherever such third-party acknowledgments normally appear.
#
# 4. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#    This product includes software developed by the University of
#    California, Berkeley and its contributors. 
#
# 5. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# 6. Products derived from this software may not be called "RDFStore"
#    nor may "RDFStore" appear in their names without prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ====================================================================
#
# This software consists of work developed by Alberto Reggiori and 
# Dirk-Willem van Gulik. The RDF specific part is based based on public 
# domain software written at the Stanford University Database Group by 
# Sergey Melnik. For more information on the RDF API Draft work, 
# please see <http://www-db.stanford.edu/~melnik/rdf/api.html>
# The DBMS TCP/IP server part is based on software originally written
# by Dirk-Willem van Gulik for Web Weaving Internet Engineering m/v Enschede,
# The Netherlands.
#
##############################################################################

 $Id: rdfstore_bits.c,v 1.16 2006/06/19 10:10:21 areggiori Exp $
*/

#include <sys/types.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <assert.h>

#include "dbms.h"
#include "dbms_compat.h"

#include "rdfstore.h"
#include "rdfstore_bits.h"
#include "rdfstore_log.h"

/* within p->size / p->bits
 * set at -bit- position 'at' 
 * the masked bits to value
 *
 * return the modified bits
 */

/*
 * #define RDFSTORE_DEBUG_BITS
 */

int rdfstore_bits_setmask( 
	unsigned int * size,
	unsigned char * bits,
	unsigned int at, 
	unsigned int mask,
	unsigned int value,
	unsigned int max
) {
	register int depth,change;

	if (mask == 0) return(0);

	/* auto extend if needed... */
	if ( (at/8) >= *size) {
		unsigned int n=*size;
		unsigned int s= STEP * ( 1 + at/8/STEP );
		if (s>max) {
			fprintf(stderr, "Too many bit=%d byte=%d %d of %d\n",
				at, at/8, s, max);
			exit(1);
			};
		*size = s;
		bzero(bits+n, s-n);
		};

	/*	x x x x x x as stored
	 *	0 0 1 1 1 0 mask
  	 *	0 0 0 1 1 0 value
	 */
	mask <<= at % 8;	
	value <<= at % 8;
	at /= 8;
	change =0; depth = 0;
	do {
		register unsigned char d,c;
		if (at>=max) {
			fprintf(stderr,"Uncontrolled overflow %d of %d\n",
				at, max);
			exit(1);
			};

		c = bits[ at ];
		d = ( c & (~ mask) ) | value;

		if (d != c) {
			bits[ at ] = d;
			change |= (d ^ c) << depth; 
			};
		at ++;

		depth += 8;
		mask >>= 8;
		value >>= 8;

		} while ((mask) && (at < *size ));

	return (change);
	};

/* Return the record number (bit number / 4) of the
 * first record from record 'at' onwards which has
 * a bit set within the mask.
 */
unsigned int 
rdfstore_bits_getfirstrecord (
        unsigned int size,	/* in bytes */
        unsigned char * bits,	/* bit array */
        unsigned int at, 	/* as record no (bits/4) */
        unsigned char mask	/* 0000 to 1111 */
) {
	unsigned mask2 = mask << 4;
	unsigned i = at >> 1;
	unsigned char c = bits[i];

	assert(mask < 16);
	assert(mask != 0);

	if (at & 1)
		c &= 0xF0;

	do {
		if ((c & 0x0f) & mask)
			return 2*i+0;
		if ((c & 0xf0) & mask2)
			return 2*i+1;
		c = bits[ ++i ];
	} while (i < size);

	return size*2;
}

/*
 * rdfstore_bits_isanyset - returns != 0 if any bit in the bitmask is set
 * in addition it returns the positions of the first bit set in at
 *
 */

int rdfstore_bits_isanyset( 
        unsigned int * size,
        unsigned char * bits,
        unsigned int * at, 
        unsigned char mask
) {
	register unsigned rest=0;
	rest = ( *at % 8 );
        mask = mask << rest;
        *at /= 8;

        while ((mask) && (*at < *size)) {
                register int c = bits[ *at ] & mask;
                if (c) {
			(*at) *=8;
			(*at) += rest;
			return c;
			};
                (*at)++;
                };

        return 0;
        };

/*
 * returns the first bit set from (and including) at in the
 * bit array of size bytes. If no bit set is found after
 * the size-est byte of bits; size*8 is returned (i.e. the number
 * of * last bit (not byte)+1; starting from zero.
 *
 * size		in bytes
 * bits		unsigned array of bytes with 8 bits each
 * at		location in bits.
 * return	location in bits (or size*8).
 *
 */
unsigned int rdfstore_bits_getfirstsetafter (
        unsigned int size,
        unsigned char * bits,
        unsigned int at
) {
        register unsigned int i = at >> 3;
        register unsigned char c = bits[ i ];

        /* first byte is special; skip over the bits
         * before 'at'.
         */
        c &= ( 0xFF << (at & 0x7 ));
        do {
                if (c) {
			i <<= 3;
#define _RX(x) 		if (c & (1<<x)) return (i+x);
			_RX(0); _RX(1); _RX(2); _RX(3);
			_RX(4); _RX(5); _RX(6); 
			return (i+7);
#undef _RX
                }
                i++;
                c = bits[i];
        } while (i < size);

	/* Fail; return bits+1. */
        return size<<3;
}

/* slightly tricky bin-ops; in that it can cope with 'infinitive
 * lenght type tricks.. Returns the len of the changed bitseq.
 */

/*
 * exor - Exor's to bitvectors to each other, ba of length la and bb of len lb
 * 
 * returns result in bc (should be preallocated) and length as function result
 */

unsigned int rdfstore_bits_exor (
	unsigned int la, unsigned char * ba,
	unsigned int lb, unsigned char * bb,
	unsigned char * bc
	) 
{
	register unsigned int len,i;
	/* set in a, but not set in b 
	 * a b -> a|b ^ b 
         * 0 0    0     0
	 * 0 1    1     0
	 * 1 0    1     1
	 * 1 1    1     0
	 */
#if 0
	A real EXOR does
	 00 -> 0
	 10 -> 1
	 01 -> 1
	 11 -> 0
#endif
	for(len=0,i=0; (i<la) || (i<lb); i++) {
		register unsigned char a = ( i>=la ) ? 0 : ba[i];
		register unsigned char b = ( i>=lb ) ? 0 : bb[i];
#if 0
		/* real exor */
	  	register unsigned char c = a ^ b;
#endif
	  	register unsigned char c = (a | b) ^ b;
	  	if (c) len = i+1;
		bc[i] = c;
		};
	return len;
	};

/*
 * or - Or's to bitvectors to each other, ba of length la and bb of length lb
 * 
 * returns result in bc (should be preallocated) and length as function result
 */

unsigned int rdfstore_bits_or (
	unsigned int la, unsigned char * ba,
	unsigned int lb, unsigned char * bb,
	unsigned char * bc
	) 
{
	register unsigned int len,i;
	for(len=0,i=0; (i<la) || (i<lb); i++) {
		register unsigned char a = ( i>=la ) ? 0 : ba[i];
		register unsigned char b = ( i>=lb ) ? 0 : bb[i];
	  	register unsigned char c = (a | b);
	  	if (c) len = i+1;
		bc[i] = c;
		};
	return len;
	};


/*
 * and - And's to bitvectors to each other, ba of length la and bb of length lb
 * 
 * returns result in bc (should be preallocated) and length as function result
 */

unsigned int rdfstore_bits_and (
	unsigned int la, unsigned char * ba,
	unsigned int lb, unsigned char * bb,
	unsigned char * bc
	) 
{
	register unsigned int len,i;
	for(len=0,i=0; (i<la) && (i<lb); i++) {
		register unsigned char a = ( i>=la ) ? 0 : ba[i];
		register unsigned char b = ( i>=lb ) ? 0 : bb[i];
	  	register unsigned char c = (a & b);
	  	if (c) len = i+1;
		bc[i] = c;
		};

	return len;
	};

/*
 * not - Not's a bitvector ba of length la
 * 
 * returns result in bb (should be preallocated) and length as function result
 */

unsigned int rdfstore_bits_not (
	unsigned int la, unsigned char * ba,
	unsigned char * bb
	) 
{
	register unsigned int len,i;
	for(len=0,i=0; (i<la) ; i++) {
		register unsigned char a = ( i>=la ) ? 0 : ba[i];
	  	register unsigned char b = ~ a;
	  	if (b) len = i+1;
		bb[i] = b;
		};

	return len;
	};


/*
 * shorten - removes the top zero bits of the bitvector
 *
 * returns length of bitvector (without trailing zeroes) as bytes as function
 * result
 */

unsigned int rdfstore_bits_shorten(
	unsigned int la, unsigned char * ba
	) 
{	
	while( ( la >0 ) && (ba[la-1] == 0) ) la--;
	return(la);
	};

/* n = 6 - size of a record.
 * A = row of records; at 1 bit wide.
 * 	lenght in bytes, not bits !
 * B = row of records; each 6 bits wide.
 * 	lenght in bytes, not bits !
 * M = mask of 6 bits.
 * 	no lenght
 * OUT:
 *	bc filled
 *	returns number of bytes in use.
 *
 */
unsigned int rdfstore_bits_and2(
	int n,
	unsigned int la, unsigned char * ba,
	unsigned int lb, unsigned char * bb,
	unsigned char mask,
	unsigned char * bc
	) 
{
	unsigned int i = 0;
	int endbit = la * 8;
	assert(n <= 8);			/* up to 8 bits - see q+1 below */		
	assert(mask < (1<<n));		/* Mask cannot be bigger than N bits */

	bzero(bc,la);		/* Out array of length A max */

	/* If B has less records than A has bits; shorten A 
	 */
	if (lb * 8 / n < endbit)
		endbit = (lb * 8 / n) * 8;

#ifdef RDFSTORE_DEBUG_BITS
{
int             i,j=0;
printf("rdfstore_bits_and2 la=%d lb=%d endbit=%d endbyte=%d\n",(int)la,(int)lb,endbit,endbit/8);
printf("rdfstore_bits_and2 ba -->'");       
for(i=0;i<8*la;i++) {
	printf("Rec %d %c\n", i,(ba[i>>3] & (1<<(i&7))) ? '1':'0');
        };
printf("'\n");
printf("rdfstore_bits_and2 bb -->'");       
for(i=0;i<8*lb;i++) {
	if (i % n == 0) {
		int a = 0;
		if (j<8*la) a= ba[j>>3] & (1<<(j&7));
		printf("Rec %d A=%d ",j,a ? '1':'0');
		j++;
	};
	printf("%c", (bb[i>>3] & (1<<(i&7))) ? '1':'0');
	if (i % n == n-1) printf("\n");
        };
printf("'\n");
printf("rdfstore_bits_and2 mask -->'");
for(i=0;i<8;i++) {
	printf("%c", (mask & (1<<(i&7))) ? '1':'0');
        };
printf("'\n");
}
#endif
	
	for(i=0; i < endbit ; i++) {
		/* Check if bit 'i' is set or not 
		 */
		if (ba[ i>>3 ] & (1<<(i & 7))) {
			unsigned int p = n * i;		/* bit number where the record starts */
			unsigned int q = p >> 3;	/* byte number. */
			unsigned int r = p & 7;		/* bit offset in the byte */
			unsigned int record;

			/* fetch N bits from the B. Note 8 bits max now; if we have
			 * records of more than 8 bits; then add q + 2.
			 */
			record = (((bb[ q + 1 ] << 8) + bb[ q ]) >> (r));

			/* If there is one or more bits in the record set; within
			 * the mask; set a bit at recno in the output.
			 */

			if (record & mask) /* and2 */
				bc[ i >> 3 ] |= (1 << ( i & 7));
			};
		};

#ifdef RDFSTORE_DEBUG_BITS
{
int  j;
printf("rdfstore_bits_or2 bc -->'");       
for(j=0;j<8*(i>>3);j++) {
	printf("Rec %d %c\n", j,(bc[j>>3] & (1<<(j&7))) ? '1':'0');
        };
printf("'\n");
};
#endif

	/* Return the lenght in bytes, not bits */
	return i >> 3;
	};

/* n = 6 - size of a record.
 * A = row of records; at 1 bit wide.
 * 	lenght in bytes, not bits !
 * B = row of records; each 6 bits wide.
 * 	lenght in bytes, not bits !
 * M = mask of 6 bits.
 * 	no lenght
 * OUT:
 *	bc filled
 *	returns number of bytes in use.
 *
 */
unsigned int rdfstore_bits_or2(
	int n,
	unsigned int la, unsigned char * ba,
	unsigned int lb, unsigned char * bb,
	unsigned char mask,
	unsigned char * bc
	) 
{
	unsigned int i = 0;
	int endbit = la * 8;
	assert(n <= 8);			/* up to 8 bits - see q+1 below */		
	assert(mask < (1<<n));		/* Mask cannot be bigger than N bits */

	bzero(bc,la);		/* Out array of length A max */

	/* If B has less records than A has bits; shorten A 
	 */
	if (lb * 8 / n < endbit)
		endbit = (lb * 8 / n) * 8;

#ifdef RDFSTORE_DEBUG_BITS
{
int             i,j=0;
printf("rdfstore_bits_or2 la=%d lb=%d endbit=%d endbyte=%d\n",(int)la,(int)lb,endbit,endbit/8);
printf("rdfstore_bits_or2 ba -->'");       
for(i=0;i<8*la;i++) {
	printf("Rec %d %c\n", i,(ba[i>>3] & (1<<(i&7))) ? '1':'0');
        };
printf("'\n");
printf("rdfstore_bits_or2 bb -->'");       
for(i=0;i<8*lb;i++) {
	if (i % n == 0) {
		int a = 0;
		if (j<8*la) a= ba[j>>3] & (1<<(j&7));
		printf("Rec %d A=%d ",j,a ? '1':'0');
		j++;
	};
	printf("%c", (bb[i>>3] & (1<<(i&7))) ? '1':'0');
	if (i % n == n-1) printf("\n");
        };
printf("'\n");
printf("rdfstore_bits_or2 mask -->'");
for(i=0;i<8;i++) {
	printf("%c", (mask & (1<<(i&7))) ? '1':'0');
        };
printf("'\n");
}
#endif
	
	for(i=0; i < endbit ; i++) {
		unsigned int p = n * i;		/* bit number where the record starts */
		unsigned int q = p >> 3;	/* byte number. */
		unsigned int r = p & 7;		/* bit offset in the byte */
		unsigned int record;

		/* fetch N bits from the B. Note 8 bits max now; if we have
		 * records of more than 8 bits; then add q + 2.
		 */
		record = (((bb[ q + 1 ] << 8) + bb[ q ]) >> (r));

		/* If there is one or more bits in the record set; within
		 * the mask; set a bit at recno in the output.
		 */

		if ( (ba[ i>>3 ] & (1<<(i & 7))) | (record & mask) ) /* or2 */
			bc[ i >> 3 ] |= (1 << ( i & 7));
		};

#ifdef RDFSTORE_DEBUG_BITS
{
int  j;
printf("rdfstore_bits_or2 bc -->'");
for(j=0;j<8*(i>>3);j++) {
        printf("Rec %d %c\n", j,(bc[j>>3] & (1<<(j&7))) ? '1':'0');
        };
printf("'\n");
};
#endif

	/* Return the lenght in bytes, not bits */
	return i >> 3;
	};
