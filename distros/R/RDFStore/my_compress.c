/*
  *
  *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
  *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
  *
  * NOTICE
  *
  * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
  * file you should have received together with this source code. If you did not get a
  * a copy of such a license agreement you can pick up one at:
  *
  *     http://rdfstore.sourceforge.net/LICENSE
  *
  * $Id: my_compress.c,v 1.5 2006/06/19 10:10:21 areggiori Exp $
  */

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <string.h>

#include "rdfstore_compress.h"
#include "my_compress.h"


/* RLE+VLE like de/encoder
 *
 * DISCLAIMER: I have no idea whether the following algorithm is under any existing patent
 *
 *
 * First byte
 *     bit     value   meaning
 *     0..3    ...     lenght of run (len)
 *     4-5     00      len is between 0 .. 15, no other bytes
 *             10      len is continued in next byte, next is LSB (short int)
 *             01      len is continued in next 3 bytes (long int)
 *                        * first is upper nibble of MSB
 *                        * next is lower nibble of MSB
 *                        * next+1 is upper nibble of LSB
 *                        * next+2 is lower nibble of LSB
 *             11      len is continued in next 7 bytes (64 bit int, not implemented yet...)
 *     6       set     the byte just *after* the run len (see bit 4 and 5) gives the variable-length (up to 127)
 *             unset   no var len
 *     7       set     run of len bytes set to the byte value after the run len
 *             unset   no run, next len bytes are to be copied as-is i.e. "literal bytes"; such bytes could be repeated for a
 *                     a given variable-length given in the next byte (up to 127) if bit 6 is set
 */

/*
 *
 * (compress|expand)_mine (
 *	len		in buffer
 *	buff		unsigned char buffer
 *
 *	len-ptr 	will contain out size 
 *	outbuff 	will contain compressed/decompressed data
 *			must be big enough ! if set to 'NULL' just
 *			the size will be calculated... (deleted as
 *			it takes (some) cycles.
 *	)
 */
unsigned int
compress_mine (
	unsigned char * in,
	unsigned char * out,
	unsigned int insize
) {
	register unsigned int i,j,vlen,l,len,comp,best_match;
	unsigned int matches[MAXVARLENGTH];
	double ratio;

	for(i=0,j=0; i<insize; ) {
		comp=0;
		best_match=0;
		len=1;
		vlen=1;

		/* look for the "best" repeated code; the loop can be repeated up to 2*vlen */
		for(	vlen=1;
			(	(i+(vlen*2) < insize) &&
				(vlen<=MAXVARLENGTH) );
			vlen++ ) {
			matches[ vlen-1 ]=0;
			/* check if there is at least *two* matches for vlen sequence to compress */
			if(memcmp( in+i, in+i+vlen, vlen ) == 0 ) {
				matches[ vlen-1 ]=1;
				/* look for more matches to compress */
				for( 	len=2, matches[ vlen-1 ]=2;
					( i+(len*vlen)+vlen < insize ) && 
					(len < MAXRUNLENGTH) &&
					( memcmp( in+i, in+i+(len*vlen), vlen ) == 0 ); 
					matches[ vlen-1 ]++, len++ ) { };
				/* we should check if the compression is good enough vlen/len << 1/100 (or take the best one) */
				ratio= (double)vlen / (double)len;
				if ( ratio <= OPTIMAL ) {
/*
printf("GOT OPTIMAL i=%u j=%u value %u/%u: %f << %f\n",i,j,vlen,len,ratio,OPTIMAL);
*/
					comp=1;
					break;
				};

				if(	(best_match == 0) ||
					(ratio < ( (double)best_match / (double)matches[ best_match-1 ] ) ) )
					best_match = vlen;
			};
		};
                if(comp == 0) {
			/* is there any good/best match? */
			if (	( best_match > 0 ) &&
				( matches[ best_match-1 ] > 1 ) ) { /* do compress len>1 */
				vlen = best_match;
				len = matches[ best_match-1 ];
				ratio= (double)vlen / (double)len;
				comp=1;
			} else {

				/* the following is for "literal bytes"; we do store dict entries also for literals to refer them if the are at least 1 byte long */
				vlen=1; /* force this */

				for(    len=1;
                                        (len+i < insize) &&
                                        (len < MAXVARLENGTH) &&
					(len < MAXRUNLENGTH);
                                        len++) {
					if(len==1) {
						if(in[i]==in[i+len]) {
							break;
						};
					} else if( memchr( in+i, in[i+len], len ) != NULL ) {
						break;
					};
				};

/*
{
unsigned int w=0;
printf("LITERAL BYTES insize=%u i=%u j=%u len=%u \n",insize,i,j,len);
printf("LITERAL BYTES insize=%u i=%u j=%u len=%u : ",insize,i,j,len); w=0; while (w<len) { printf("%x,", in[ i+w ]); w++; }; printf("\n");
};
*/
			};
		};

		if (len == 0)
			fprintf(stderr,"Compressing: RLE len=0\n");

		if ( vlen > MAXVARLENGTH)
			fprintf(stderr,"Var length too high!!!\n");

		l = j;
		if (len > 4095 ) {
			out[ l ] = 32 + ((len >> 24) & 15);
                        out[ l+1 ] = (len>>16) & 0xffff;
                        out[ l+2 ] = (len>>8) & 0xffff;
                        out[ l+3 ] = len & 0xffff;
                        j+=3;
			if(vlen>1) {
				out[ l+4 ] = vlen & 127; /* see MAXVARLENGTH */
                        	j++;
				out[ l ] |= 64; /* having vlen>1 */
			};
                } else if (len > 15 ) {
			out[ l ] = 16 + ((len >> 8) & 15);
                        out[ l+1 ] = len & 0xff;
                        j++;
			if(vlen>1) {
				out[ l+2 ] = vlen & 127;
                        	j++;
				out[ l ] |= 64;
			};
                } else {
                        out[ l ] = len & 15;
			if(vlen>1) {
				out[ l+1 ] = vlen & 127;
                        	j++;
				out[ l ] |= 64;
			};
                };

		j++;
		if ( comp ) {
			out[ l ] |= 128;
/*
printf("COMPRESSING for i=%u j=%u insize=%u vlen=%u len=%u comp=%u ratio=%f\n",i,j,insize,vlen,len,comp,ratio);
*/
			/* just the repeated bytes */
			bcopy(in+i,out+j,vlen);

			j+=vlen;
		} else {
/*
printf("NOT COMPRESSING for i=%u j=%u insize=%u vlen=%u len=%u comp=%u\n",i,j,insize,vlen,len,comp);
*/
			if (len==1) {
				out[j] = in[i];
			} else {
				bcopy(in+i,out+j,len);
			};

			j+=len;
		}; /* non-compressed else */
		i+=(len*vlen); /* hop on for the next ones... */

/*
{
unsigned int w=0;
printf(">>>COMPRESSED STRING so far insize=%u i=%u j=%u : ",insize,i,j); w=0; while (w<j) { printf("%x,", out[ w ]); w++; }; printf("\n");
};
*/

	}; /* for loop */	
/*
	printf("compressed string is %u bytes\n",j);
*/

	/*
	 * pad to sensible length (in the hope it makes
	 * the db storage a bit faster .... if we do not
	 * have to increase the size of the stored block
	 * for each and every change.. 
	 *
	 * 	for(;j % 32;j++) out[j]='\0'; 
	 */

	return j;
};

unsigned int
expand_mine ( 
	unsigned char * in,
	unsigned char * out,
	unsigned int insize
) {
	register unsigned int i,j,c,len,vlen,k;

	for(i=0,j=0; i<insize;) {
		/* work out run length */
		c = in[i]; 

		if (!c) 
			break; /* no compress, no length */

		if ( c & 32 ) {
			len = c & 31;
			len = ( len << 8 ) + in[ ++i ];
			len = ( len << 8 ) + in[ ++i ];
			len = ( len << 8 ) + in[ ++i ];
		} else {
			len = c & 15;
			if ( c & 16 ) 
				len = ( len << 8 ) + in[ ++i ];
		};

		if ( c & 64 ) {
			vlen=in[ ++i ];
		} else {
			vlen=1;
		};

		if (len == 0) {
			fprintf(stderr,"Bug: RLE len=0\n");
			break;
		};
		i++;
		if (c & 128) {
			if (vlen>1) {
/*
printf("DECOMPRESSING for i=%u j=%u insize=%u vlen=%u len=%u\n",i,j,insize,vlen,len);
*/

                        	for(k=0; k<len;k++) {
                                	bcopy(in+i,out+(j+(k*vlen)),vlen);
                                };
                                i+=vlen;
                        } else {
/*
printf("DECOMPRESSING for i=%u j=%u insize=%u vlen=%u len=%u\n",i,j,insize,vlen,len);
*/
                                if(in[i] == 0) {
                                        bzero(out+j, len);
                                } else {
                                        memset(out+j, in[i], len);
                                };
                                i+=vlen;
                        };
		} else {
/*
printf("EXPANDING literal bytes for i=%u j=%u vlen=%u len=%u insize=%u\n",i,j,vlen,len,insize);
*/
                	bcopy(in+i,out+j,len);
			i+=len;
		};
		j+=(len*vlen);
	}; /* for */

/*
	printf("decompressed string is %u bytes\n",j);
*/
	return j;
};
