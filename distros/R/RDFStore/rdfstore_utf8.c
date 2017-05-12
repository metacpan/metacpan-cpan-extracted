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
#
# $Id: rdfstore_utf8.c,v 1.7 2006/06/19 10:10:22 areggiori Exp $
#
*/

#if !defined(WIN32)
#include <sys/param.h>
#endif

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <strings.h>
#include <string.h>


#include "rdfstore_utf8.h"
#include "rdfstore_log.h"

/* a table of number of bytes to skip for speed */
static const unsigned char rdfstore_utf8_toskip[] = {
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* ASCII */
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* not valid */
	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, /* scripts */
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3, /* others */
	4,4,4,4,4,4,4,4,5,5,5,5,6,6,
        };
static const unsigned char rdfstore_utf8_mask[] = { 
	0, 0x7f, 0x1f, 0x0f, 0x07, 0x03, 0x01 
	};

/*

 UTF8 encoding rules on 32 bits

 Code Points		1st Byte  2nd Byte  3rd Byte  4th Byte

   U+0000..U+007F	00..7F
   U+0080..U+07FF	C2..DF    80..BF
   U+0800..U+0FFF	E0        A0..BF    80..BF
   U+1000..U+CFFF       E1..EC    80..BF    80..BF
   U+D000..U+D7FF       ED        80..9F    80..BF
   U+D800..U+DFFF       ******* ill-formed *******
   U+E000..U+FFFF       EE..EF    80..BF    80..BF
  U+10000..U+3FFFF	F0        90..BF    80..BF    80..BF
  U+40000..U+FFFFF	F1..F3    80..BF    80..BF    80..BF
 U+100000..U+10FFFF	F4        80..8F    80..BF    80..BF

*/

/* convert a given codepoint to its UTF8 encoding; the len of the result is put in len */
int rdfstore_utf8_cp_to_utf8(
        unsigned long c,
        int * len,
        unsigned char * outbuff
	) {
        if (	(len == NULL ) ||
		(outbuff == NULL) )
		return -1;

	(*len) = 0;

        if( c < 0x80 ) {
                outbuff[(*len)++] = c;
        } else if( c < 0x800 ) {
                outbuff[(*len)++] = 0xc0 | ( c >> 6 );
                outbuff[(*len)++] = 0x80 | ( c & 0x3f );
        } else if( c < 0x10000 ) {
                outbuff[(*len)++] = 0xe0 | ( c >> 12 );
                outbuff[(*len)++] = 0x80 | ( (c >> 6) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( c & 0x3f );
        } else if( c < 0x200000 ) {
                outbuff[(*len)++] = 0xf0 | ( c >> 18 );
                outbuff[(*len)++] = 0x80 | ( (c >> 12) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( (c >> 6) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( c & 0x3f );
        } else if( c < 0x4000000 ) {
                outbuff[(*len)++] = 0xf8 | ( c >> 24 );
                outbuff[(*len)++] = 0x80 | ( (c >> 18) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( (c >> 12) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( (c >> 6) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( c & 0x3f );
        } else if( c < 0x80000000 ) {
                outbuff[(*len)++] = 0xfc | ( c >> 30 );
                outbuff[(*len)++] = 0x80 | ( (c >> 24) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( (c >> 18) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( (c >> 12) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( (c >> 6) & 0x3f );
                outbuff[(*len)++] = 0x80 | ( c & 0x3f );
        } else {	
        	outbuff[(*len)++] = 0xfe; /* Can't match U+FEFF! */
        	outbuff[(*len)++] = ( ( (c >> 30) & 0x3f) | 0x80 );
        	outbuff[(*len)++] = ( ( (c >> 24) & 0x3f) | 0x80 );
        	outbuff[(*len)++] = ( ( (c >> 18) & 0x3f) | 0x80 );
        	outbuff[(*len)++] = ( ( (c >> 12) & 0x3f) | 0x80 );
        	outbuff[(*len)++] = ( ( (c >>  6) & 0x3f) | 0x80 );
        	outbuff[(*len)++] = ( ( c & 0x3f) | 0x80 );
		};

        return 0;
	};

/* convert a given UTF8 char to its unicode codepoint; the result is put in cp */
int rdfstore_utf8_utf8_to_cp(
        int inlen,
        unsigned char * inbuff,
        unsigned long * cp
	) {
        register int i;

        if ( inlen == 0 )
		return -1;

        (*cp) = inbuff[0] & rdfstore_utf8_mask[inlen];

        for(i=1; i < inlen; i++) {
                if ((inbuff[i] & 0xc0) != 0x80) {
                        return -1;
                }
                (*cp) <<= 6;
                (*cp) |= inbuff[i] & 0x3f;
        }

	return 0;
	};

/*
  check whether a given number of bytes is a valid UTF8 char; if true the number
  bytes of the utf8 char length is returned in len
*/
int rdfstore_utf8_is_utf8(
        unsigned char * bytes,
        int * len
	) {
	int ll;
	unsigned char * p;
	unsigned char a;
	unsigned long b,c;

	p = bytes;
	a = *bytes;

	(*len)=0;

	if ( (unsigned char)a < 0x80 ) {
		(*len)=1;
        	return 1;
		};

	if ( !(	(a >= 0xc0) && 
		(a <= 0xfd) ) )
		return 0;

    	(*len) = rdfstore_utf8_toskip[ (*bytes) ];

    	if (	((*len) < 2) || 
		(! (	((*(bytes+1)) >= 0x80) && 
			((*(bytes+1)) <= 0xbf) ) ) )
        	return 0;

	ll = (*len) - 1;
    	a &= ((*len) >=  7) ? 0x00 : (0x1F >> ((*len)-2));
    	p++;
	for ( 	b = a, c = b;
		ll--;
		p++, c = b ) {
        	if (! (	((*p) >= 0x80) && 
			((*p) <= 0xbf) ) )
            		return 0;
        	b = (b << 6) | ((*p) & 0x3f);
        	if (b < c)
            		return 0;
    		};

	c = 	(b  < 0x80) ? 1 :
		(b  < 0x800) ? 2 :
		(b  < 0x10000) ? 3 :
		(b  < 0x200000) ? 4 :
		(b  < 0x4000000) ? 5 :
		(b  < 0x80000000) ? 6 : 7;

    	if ( (int)c < (*len) )
        	return 0;

	return 1;
	};

/*
   convert an arbitrary bytes string to utf8 case-folded (see http://www.unicode.org/unicode/reports/tr21/#Caseless%20Matching)
   the output string is stored in outbuff and the length in len
*/
int rdfstore_utf8_string_to_utf8_foldedcase(
        int insize,
        unsigned char * in,
        int * outsize,
        unsigned char * out
	) {
	register unsigned int i,j,step=0;
	unsigned int utf8_size=0;
        unsigned char utf8_buff[RDFSTORE_UTF8_MAXLEN+1]; /* one utf8 char */
	unsigned long cp=0;

	/*
		the idea here is:
			<foreach input byte>
				1) convert the input byte/code-point to utf8 if not utf8
				2) get the unicode codepoint of the given utf8 char
				2) case-fold the char and output it
			</endforeach>
	*/

	(*outsize)=0;

        for(i=0,j=0; i<insize; i+=step) {
		if ( !( rdfstore_utf8_is_utf8( in+i, &utf8_size ) ) ) {
                	utf8_size=0;
			bzero(utf8_buff,RDFSTORE_UTF8_MAXLEN);
                	if ( rdfstore_utf8_cp_to_utf8( (unsigned long)in[i], &utf8_size, utf8_buff) ) {
				perror("rdfstore_utf8_string_to_utf8_foldedcase");
                        	fprintf(stderr,"Cannot convert input codepoint to utf8\n");
                        	return -1;
                        	};
#ifdef RDFSTORE_DEBUG_UTF8
			if(utf8_size>0) {
				int j=0;
				printf("Got converted to UTF8 char '%c / %02x' as '",in[i],in[i]);
				for (j=0; j< utf8_size; j++) {
					printf("%02x",utf8_buff[j]);
				};
				printf("'\n");
				};
#endif
			step=1; /* hop the next input byte */
		} else {
			bcopy(in+i,utf8_buff,utf8_size); /* copy the input utf8 char in the buff */
			step=utf8_size;
			};

			cp=0;
			rdfstore_utf8_utf8_to_cp( utf8_size, utf8_buff, &cp );

			/*
			The is my *FAT AND UGLY* implementation of the case-folding table
			- see http://www.unicode.org/Public/UNIDATA/CaseFolding.txt
			It could be even auto-generated via a script
			Does full case folding, use the mappings with status C + F + I.
			NOTE: please give me an advise how I can map this table in memory efficently in C :)
			Of course bleed-perl has these already built in as an hash but
			I am much worried about efficency problems here.........
			*/
			if      ( cp == 0x0041 ) { rdfstore_utf8_cp_to_utf8( 0x0061, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A */
			else if ( cp == 0x0042 ) { rdfstore_utf8_cp_to_utf8( 0x0062, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER B */
			else if ( cp == 0x0043 ) { rdfstore_utf8_cp_to_utf8( 0x0063, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER C */
			else if ( cp == 0x0044 ) { rdfstore_utf8_cp_to_utf8( 0x0064, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D */
			else if ( cp == 0x0045 ) { rdfstore_utf8_cp_to_utf8( 0x0065, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E */
			else if ( cp == 0x0046 ) { rdfstore_utf8_cp_to_utf8( 0x0066, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER F */
			else if ( cp == 0x0047 ) { rdfstore_utf8_cp_to_utf8( 0x0067, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G */
			else if ( cp == 0x0048 ) { rdfstore_utf8_cp_to_utf8( 0x0068, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER H */
			else if ( cp == 0x0049 ) { rdfstore_utf8_cp_to_utf8( 0x0069, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I */
			else if ( cp == 0x004A ) { rdfstore_utf8_cp_to_utf8( 0x006A, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER J */
			else if ( cp == 0x004B ) { rdfstore_utf8_cp_to_utf8( 0x006B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER K */
			else if ( cp == 0x004C ) { rdfstore_utf8_cp_to_utf8( 0x006C, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L */
			else if ( cp == 0x004D ) { rdfstore_utf8_cp_to_utf8( 0x006D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER M */
			else if ( cp == 0x004E ) { rdfstore_utf8_cp_to_utf8( 0x006E, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N */
			else if ( cp == 0x004F ) { rdfstore_utf8_cp_to_utf8( 0x006F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O */
			else if ( cp == 0x0050 ) { rdfstore_utf8_cp_to_utf8( 0x0070, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER P */
			else if ( cp == 0x0051 ) { rdfstore_utf8_cp_to_utf8( 0x0071, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Q */
			else if ( cp == 0x0052 ) { rdfstore_utf8_cp_to_utf8( 0x0072, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R */
			else if ( cp == 0x0053 ) { rdfstore_utf8_cp_to_utf8( 0x0073, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S */
			else if ( cp == 0x0054 ) { rdfstore_utf8_cp_to_utf8( 0x0074, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T */
			else if ( cp == 0x0055 ) { rdfstore_utf8_cp_to_utf8( 0x0075, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U */
			else if ( cp == 0x0056 ) { rdfstore_utf8_cp_to_utf8( 0x0076, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER V */
			else if ( cp == 0x0057 ) { rdfstore_utf8_cp_to_utf8( 0x0077, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER W */
			else if ( cp == 0x0058 ) { rdfstore_utf8_cp_to_utf8( 0x0078, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER X */
			else if ( cp == 0x0059 ) { rdfstore_utf8_cp_to_utf8( 0x0079, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y */
			else if ( cp == 0x005A ) { rdfstore_utf8_cp_to_utf8( 0x007A, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Z */
			else if ( cp == 0x00B5 ) { rdfstore_utf8_cp_to_utf8( 0x03BC, &utf8_size, utf8_buff ); } /*  MICRO SIGN */
			else if ( cp == 0x00C0 ) { rdfstore_utf8_cp_to_utf8( 0x00E0, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH GRAVE */
			else if ( cp == 0x00C1 ) { rdfstore_utf8_cp_to_utf8( 0x00E1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH ACUTE */
			else if ( cp == 0x00C2 ) { rdfstore_utf8_cp_to_utf8( 0x00E2, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH CIRCUMFLEX */
			else if ( cp == 0x00C3 ) { rdfstore_utf8_cp_to_utf8( 0x00E3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH TILDE */
			else if ( cp == 0x00C4 ) { rdfstore_utf8_cp_to_utf8( 0x00E4, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH DIAERESIS */
			else if ( cp == 0x00C5 ) { rdfstore_utf8_cp_to_utf8( 0x00E5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH RING ABOVE */
			else if ( cp == 0x00C6 ) { rdfstore_utf8_cp_to_utf8( 0x00E6, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER AE */
			else if ( cp == 0x00C7 ) { rdfstore_utf8_cp_to_utf8( 0x00E7, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER C WITH CEDILLA */
			else if ( cp == 0x00C8 ) { rdfstore_utf8_cp_to_utf8( 0x00E8, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH GRAVE */
			else if ( cp == 0x00C9 ) { rdfstore_utf8_cp_to_utf8( 0x00E9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH ACUTE */
			else if ( cp == 0x00CA ) { rdfstore_utf8_cp_to_utf8( 0x00EA, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CIRCUMFLEX */
			else if ( cp == 0x00CB ) { rdfstore_utf8_cp_to_utf8( 0x00EB, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH DIAERESIS */
			else if ( cp == 0x00CC ) { rdfstore_utf8_cp_to_utf8( 0x00EC, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH GRAVE */
			else if ( cp == 0x00CD ) { rdfstore_utf8_cp_to_utf8( 0x00ED, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH ACUTE */
			else if ( cp == 0x00CE ) { rdfstore_utf8_cp_to_utf8( 0x00EE, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH CIRCUMFLEX */
			else if ( cp == 0x00CF ) { rdfstore_utf8_cp_to_utf8( 0x00EF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH DIAERESIS */
			else if ( cp == 0x00D0 ) { rdfstore_utf8_cp_to_utf8( 0x00F0, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER ETH */
			else if ( cp == 0x00D1 ) { rdfstore_utf8_cp_to_utf8( 0x00F1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH TILDE */
			else if ( cp == 0x00D2 ) { rdfstore_utf8_cp_to_utf8( 0x00F2, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH GRAVE */
			else if ( cp == 0x00D3 ) { rdfstore_utf8_cp_to_utf8( 0x00F3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH ACUTE */
			else if ( cp == 0x00D4 ) { rdfstore_utf8_cp_to_utf8( 0x00F4, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH CIRCUMFLEX */
			else if ( cp == 0x00D5 ) { rdfstore_utf8_cp_to_utf8( 0x00F5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH TILDE */
			else if ( cp == 0x00D6 ) { rdfstore_utf8_cp_to_utf8( 0x00F6, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH DIAERESIS */
			else if ( cp == 0x00D8 ) { rdfstore_utf8_cp_to_utf8( 0x00F8, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH STROKE */
			else if ( cp == 0x00D9 ) { rdfstore_utf8_cp_to_utf8( 0x00F9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH GRAVE */
			else if ( cp == 0x00DA ) { rdfstore_utf8_cp_to_utf8( 0x00FA, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH ACUTE */
			else if ( cp == 0x00DB ) { rdfstore_utf8_cp_to_utf8( 0x00FB, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH CIRCUMFLEX */
			else if ( cp == 0x00DC ) { rdfstore_utf8_cp_to_utf8( 0x00FC, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH DIAERESIS */
			else if ( cp == 0x00DD ) { rdfstore_utf8_cp_to_utf8( 0x00FD, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH ACUTE */
			else if ( cp == 0x00DE ) { rdfstore_utf8_cp_to_utf8( 0x00FE, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER THORN */
			else if ( cp == 0x00DF ) { rdfstore_utf8_cp_to_utf8( 0x0073, &utf8_size, utf8_buff );  /*  LATIN SMALL LETTER SHARP S */
			                           rdfstore_utf8_cp_to_utf8( 0x0073, &utf8_size, utf8_buff ); }
			else if ( cp == 0x0100 ) { rdfstore_utf8_cp_to_utf8( 0x0101, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH MACRON */
			else if ( cp == 0x0102 ) { rdfstore_utf8_cp_to_utf8( 0x0103, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH BREVE */
			else if ( cp == 0x0104 ) { rdfstore_utf8_cp_to_utf8( 0x0105, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH OGONEK */
			else if ( cp == 0x0106 ) { rdfstore_utf8_cp_to_utf8( 0x0107, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER C WITH ACUTE */
			else if ( cp == 0x0108 ) { rdfstore_utf8_cp_to_utf8( 0x0109, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER C WITH CIRCUMFLEX */
			else if ( cp == 0x010A ) { rdfstore_utf8_cp_to_utf8( 0x010B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER C WITH DOT ABOVE */
			else if ( cp == 0x010C ) { rdfstore_utf8_cp_to_utf8( 0x010D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER C WITH CARON */
			else if ( cp == 0x010E ) { rdfstore_utf8_cp_to_utf8( 0x010F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH CARON */
			else if ( cp == 0x0110 ) { rdfstore_utf8_cp_to_utf8( 0x0111, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH STROKE */
			else if ( cp == 0x0112 ) { rdfstore_utf8_cp_to_utf8( 0x0113, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH MACRON */
			else if ( cp == 0x0114 ) { rdfstore_utf8_cp_to_utf8( 0x0115, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH BREVE */
			else if ( cp == 0x0116 ) { rdfstore_utf8_cp_to_utf8( 0x0117, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH DOT ABOVE */
			else if ( cp == 0x0118 ) { rdfstore_utf8_cp_to_utf8( 0x0119, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH OGONEK */
			else if ( cp == 0x011A ) { rdfstore_utf8_cp_to_utf8( 0x011B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CARON */
			else if ( cp == 0x011C ) { rdfstore_utf8_cp_to_utf8( 0x011D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G WITH CIRCUMFLEX */
			else if ( cp == 0x011E ) { rdfstore_utf8_cp_to_utf8( 0x011F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G WITH BREVE */
			else if ( cp == 0x0120 ) { rdfstore_utf8_cp_to_utf8( 0x0121, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G WITH DOT ABOVE */
			else if ( cp == 0x0122 ) { rdfstore_utf8_cp_to_utf8( 0x0123, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G WITH CEDILLA */
			else if ( cp == 0x0124 ) { rdfstore_utf8_cp_to_utf8( 0x0125, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER H WITH CIRCUMFLEX */
			else if ( cp == 0x0126 ) { rdfstore_utf8_cp_to_utf8( 0x0127, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER H WITH STROKE */
			else if ( cp == 0x0128 ) { rdfstore_utf8_cp_to_utf8( 0x0129, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH TILDE */
			else if ( cp == 0x012A ) { rdfstore_utf8_cp_to_utf8( 0x012B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH MACRON */
			else if ( cp == 0x012C ) { rdfstore_utf8_cp_to_utf8( 0x012D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH BREVE */
			else if ( cp == 0x012E ) { rdfstore_utf8_cp_to_utf8( 0x012F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH OGONEK */
			else if ( cp == 0x0130 ) { rdfstore_utf8_cp_to_utf8( 0x0069, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH DOT ABOVE */
			else if ( cp == 0x0131 ) { rdfstore_utf8_cp_to_utf8( 0x0069, &utf8_size, utf8_buff ); } /*  LATIN SMALL LETTER DOTLESS I */
			else if ( cp == 0x0132 ) { rdfstore_utf8_cp_to_utf8( 0x0133, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LIGATURE IJ */
			else if ( cp == 0x0134 ) { rdfstore_utf8_cp_to_utf8( 0x0135, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER J WITH CIRCUMFLEX */
			else if ( cp == 0x0136 ) { rdfstore_utf8_cp_to_utf8( 0x0137, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER K WITH CEDILLA */
			else if ( cp == 0x0139 ) { rdfstore_utf8_cp_to_utf8( 0x013A, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH ACUTE */
			else if ( cp == 0x013B ) { rdfstore_utf8_cp_to_utf8( 0x013C, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH CEDILLA */
			else if ( cp == 0x013D ) { rdfstore_utf8_cp_to_utf8( 0x013E, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH CARON */
			else if ( cp == 0x013F ) { rdfstore_utf8_cp_to_utf8( 0x0140, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH MIDDLE DOT */
			else if ( cp == 0x0141 ) { rdfstore_utf8_cp_to_utf8( 0x0142, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH STROKE */
			else if ( cp == 0x0143 ) { rdfstore_utf8_cp_to_utf8( 0x0144, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH ACUTE */
			else if ( cp == 0x0145 ) { rdfstore_utf8_cp_to_utf8( 0x0146, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH CEDILLA */
			else if ( cp == 0x0147 ) { rdfstore_utf8_cp_to_utf8( 0x0148, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH CARON */
			else if ( cp == 0x0149 ) { rdfstore_utf8_cp_to_utf8( 0x02BC, &utf8_size, utf8_buff );   /*  LATIN SMALL LETTER N PR0xECEDED BY APOSTROPHE */
			                           rdfstore_utf8_cp_to_utf8( 0x006E, &utf8_size, utf8_buff ); }
			else if ( cp == 0x014A ) { rdfstore_utf8_cp_to_utf8( 0x014B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER ENG */
			else if ( cp == 0x014C ) { rdfstore_utf8_cp_to_utf8( 0x014D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH MACRON */
			else if ( cp == 0x014E ) { rdfstore_utf8_cp_to_utf8( 0x014F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH BREVE */
			else if ( cp == 0x0150 ) { rdfstore_utf8_cp_to_utf8( 0x0151, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH DOUBLE ACUTE */
			else if ( cp == 0x0152 ) { rdfstore_utf8_cp_to_utf8( 0x0153, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LIGATURE OE */
			else if ( cp == 0x0154 ) { rdfstore_utf8_cp_to_utf8( 0x0155, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R WITH ACUTE */
			else if ( cp == 0x0156 ) { rdfstore_utf8_cp_to_utf8( 0x0157, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R WITH CEDILLA */
			else if ( cp == 0x0158 ) { rdfstore_utf8_cp_to_utf8( 0x0159, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R WITH CARON */
			else if ( cp == 0x015A ) { rdfstore_utf8_cp_to_utf8( 0x015B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH ACUTE */
			else if ( cp == 0x015C ) { rdfstore_utf8_cp_to_utf8( 0x015D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH CIRCUMFLEX */
			else if ( cp == 0x015E ) { rdfstore_utf8_cp_to_utf8( 0x015F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH CEDILLA */
			else if ( cp == 0x0160 ) { rdfstore_utf8_cp_to_utf8( 0x0161, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH CARON */
			else if ( cp == 0x0162 ) { rdfstore_utf8_cp_to_utf8( 0x0163, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH CEDILLA */
			else if ( cp == 0x0164 ) { rdfstore_utf8_cp_to_utf8( 0x0165, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH CARON */
			else if ( cp == 0x0166 ) { rdfstore_utf8_cp_to_utf8( 0x0167, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH STROKE */
			else if ( cp == 0x0168 ) { rdfstore_utf8_cp_to_utf8( 0x0169, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH TILDE */
			else if ( cp == 0x016A ) { rdfstore_utf8_cp_to_utf8( 0x016B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH MACRON */
			else if ( cp == 0x016C ) { rdfstore_utf8_cp_to_utf8( 0x016D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH BREVE */
			else if ( cp == 0x016E ) { rdfstore_utf8_cp_to_utf8( 0x016F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH RING ABOVE */
			else if ( cp == 0x0170 ) { rdfstore_utf8_cp_to_utf8( 0x0171, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH DOUBLE ACUTE */
			else if ( cp == 0x0172 ) { rdfstore_utf8_cp_to_utf8( 0x0173, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH OGONEK */
			else if ( cp == 0x0174 ) { rdfstore_utf8_cp_to_utf8( 0x0175, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER W WITH CIRCUMFLEX */
			else if ( cp == 0x0176 ) { rdfstore_utf8_cp_to_utf8( 0x0177, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH CIRCUMFLEX */
			else if ( cp == 0x0178 ) { rdfstore_utf8_cp_to_utf8( 0x00FF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH DIAERESIS */
			else if ( cp == 0x0179 ) { rdfstore_utf8_cp_to_utf8( 0x017A, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Z WITH ACUTE */
			else if ( cp == 0x017B ) { rdfstore_utf8_cp_to_utf8( 0x017C, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Z WITH DOT ABOVE */
			else if ( cp == 0x017D ) { rdfstore_utf8_cp_to_utf8( 0x017E, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Z WITH CARON */
			else if ( cp == 0x017F ) { rdfstore_utf8_cp_to_utf8( 0x0073, &utf8_size, utf8_buff ); } /*  LATIN SMALL LETTER LONG S */
			else if ( cp == 0x0181 ) { rdfstore_utf8_cp_to_utf8( 0x0253, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER B WITH HOOK */
			else if ( cp == 0x0182 ) { rdfstore_utf8_cp_to_utf8( 0x0183, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER B WITH TOPBAR */
			else if ( cp == 0x0184 ) { rdfstore_utf8_cp_to_utf8( 0x0185, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER TONE SIX */
			else if ( cp == 0x0186 ) { rdfstore_utf8_cp_to_utf8( 0x0254, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER OPEN O */
			else if ( cp == 0x0187 ) { rdfstore_utf8_cp_to_utf8( 0x0188, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER C WITH HOOK */
			else if ( cp == 0x0189 ) { rdfstore_utf8_cp_to_utf8( 0x0256, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER AFRICAN D */
			else if ( cp == 0x018A ) { rdfstore_utf8_cp_to_utf8( 0x0257, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH HOOK */
			else if ( cp == 0x018B ) { rdfstore_utf8_cp_to_utf8( 0x018C, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH TOPBAR */
			else if ( cp == 0x018E ) { rdfstore_utf8_cp_to_utf8( 0x01DD, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER REVERSED E */
			else if ( cp == 0x018F ) { rdfstore_utf8_cp_to_utf8( 0x0259, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER SCHWA */
			else if ( cp == 0x0190 ) { rdfstore_utf8_cp_to_utf8( 0x025B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER OPEN E */
			else if ( cp == 0x0191 ) { rdfstore_utf8_cp_to_utf8( 0x0192, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER F WITH HOOK */
			else if ( cp == 0x0193 ) { rdfstore_utf8_cp_to_utf8( 0x0260, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G WITH HOOK */
			else if ( cp == 0x0194 ) { rdfstore_utf8_cp_to_utf8( 0x0263, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER GAMMA */
			else if ( cp == 0x0196 ) { rdfstore_utf8_cp_to_utf8( 0x0269, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER IOTA */
			else if ( cp == 0x0197 ) { rdfstore_utf8_cp_to_utf8( 0x0268, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH STROKE */
			else if ( cp == 0x0198 ) { rdfstore_utf8_cp_to_utf8( 0x0199, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER K WITH HOOK */
			else if ( cp == 0x019C ) { rdfstore_utf8_cp_to_utf8( 0x026F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER TURNED M */
			else if ( cp == 0x019D ) { rdfstore_utf8_cp_to_utf8( 0x0272, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH LEFT HOOK */
			else if ( cp == 0x019F ) { rdfstore_utf8_cp_to_utf8( 0x0275, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH MIDDLE TILDE */
			else if ( cp == 0x01A0 ) { rdfstore_utf8_cp_to_utf8( 0x01A1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH HORN */
			else if ( cp == 0x01A2 ) { rdfstore_utf8_cp_to_utf8( 0x01A3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER OI */
			else if ( cp == 0x01A4 ) { rdfstore_utf8_cp_to_utf8( 0x01A5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER P WITH HOOK */
			else if ( cp == 0x01A6 ) { rdfstore_utf8_cp_to_utf8( 0x0280, &utf8_size, utf8_buff ); } /*  LATIN LETTER YR */
			else if ( cp == 0x01A7 ) { rdfstore_utf8_cp_to_utf8( 0x01A8, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER TONE TWO */
			else if ( cp == 0x01A9 ) { rdfstore_utf8_cp_to_utf8( 0x0283, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER ESH */
			else if ( cp == 0x01AC ) { rdfstore_utf8_cp_to_utf8( 0x01AD, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH HOOK */
			else if ( cp == 0x01AE ) { rdfstore_utf8_cp_to_utf8( 0x0288, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH RETROFLEX HOOK */
			else if ( cp == 0x01AF ) { rdfstore_utf8_cp_to_utf8( 0x01B0, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH HORN */
			else if ( cp == 0x01B1 ) { rdfstore_utf8_cp_to_utf8( 0x028A, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER UPSILON */
			else if ( cp == 0x01B2 ) { rdfstore_utf8_cp_to_utf8( 0x028B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER V WITH HOOK */
			else if ( cp == 0x01B3 ) { rdfstore_utf8_cp_to_utf8( 0x01B4, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH HOOK */
			else if ( cp == 0x01B5 ) { rdfstore_utf8_cp_to_utf8( 0x01B6, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Z WITH STROKE */
			else if ( cp == 0x01B7 ) { rdfstore_utf8_cp_to_utf8( 0x0292, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER EZH */
			else if ( cp == 0x01B8 ) { rdfstore_utf8_cp_to_utf8( 0x01B9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER EZH REVERSED */
			else if ( cp == 0x01BC ) { rdfstore_utf8_cp_to_utf8( 0x01BD, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER TONE FIVE */
			else if ( cp == 0x01C4 ) { rdfstore_utf8_cp_to_utf8( 0x01C6, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER DZ WITH CARON */
			else if ( cp == 0x01C5 ) { rdfstore_utf8_cp_to_utf8( 0x01C6, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH SMALL LETTER Z WITH CARON */
			else if ( cp == 0x01C7 ) { rdfstore_utf8_cp_to_utf8( 0x01C9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER LJ */
			else if ( cp == 0x01C8 ) { rdfstore_utf8_cp_to_utf8( 0x01C9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH SMALL LETTER J */
			else if ( cp == 0x01CA ) { rdfstore_utf8_cp_to_utf8( 0x01CC, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER NJ */
			else if ( cp == 0x01CB ) { rdfstore_utf8_cp_to_utf8( 0x01CC, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH SMALL LETTER J */
			else if ( cp == 0x01CD ) { rdfstore_utf8_cp_to_utf8( 0x01CE, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH CARON */
			else if ( cp == 0x01CF ) { rdfstore_utf8_cp_to_utf8( 0x01D0, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH CARON */
			else if ( cp == 0x01D1 ) { rdfstore_utf8_cp_to_utf8( 0x01D2, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH CARON */
			else if ( cp == 0x01D3 ) { rdfstore_utf8_cp_to_utf8( 0x01D4, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH CARON */
			else if ( cp == 0x01D5 ) { rdfstore_utf8_cp_to_utf8( 0x01D6, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH DIAERESIS AND MACRON */
			else if ( cp == 0x01D7 ) { rdfstore_utf8_cp_to_utf8( 0x01D8, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH DIAERESIS AND ACUTE */
			else if ( cp == 0x01D9 ) { rdfstore_utf8_cp_to_utf8( 0x01DA, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH DIAERESIS AND CARON */
			else if ( cp == 0x01DB ) { rdfstore_utf8_cp_to_utf8( 0x01DC, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH DIAERESIS AND GRAVE */
			else if ( cp == 0x01DE ) { rdfstore_utf8_cp_to_utf8( 0x01DF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH DIAERESIS AND MACRON */
			else if ( cp == 0x01E0 ) { rdfstore_utf8_cp_to_utf8( 0x01E1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH DOT ABOVE AND MACRON */
			else if ( cp == 0x01E2 ) { rdfstore_utf8_cp_to_utf8( 0x01E3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER AE WITH MACRON */
			else if ( cp == 0x01E4 ) { rdfstore_utf8_cp_to_utf8( 0x01E5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G WITH STROKE */
			else if ( cp == 0x01E6 ) { rdfstore_utf8_cp_to_utf8( 0x01E7, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G WITH CARON */
			else if ( cp == 0x01E8 ) { rdfstore_utf8_cp_to_utf8( 0x01E9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER K WITH CARON */
			else if ( cp == 0x01EA ) { rdfstore_utf8_cp_to_utf8( 0x01EB, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH OGONEK */
			else if ( cp == 0x01EC ) { rdfstore_utf8_cp_to_utf8( 0x01ED, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH OGONEK AND MACRON */
			else if ( cp == 0x01EE ) { rdfstore_utf8_cp_to_utf8( 0x01EF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER EZH WITH CARON */
			else if ( cp == 0x01F0 ) { rdfstore_utf8_cp_to_utf8( 0x006A, &utf8_size, utf8_buff );   /*  LATIN SMALL LETTER J WITH CARON */
			                           rdfstore_utf8_cp_to_utf8( 0x030C, &utf8_size, utf8_buff ); }
			else if ( cp == 0x01F1 ) { rdfstore_utf8_cp_to_utf8( 0x01F3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER DZ */
			else if ( cp == 0x01F2 ) { rdfstore_utf8_cp_to_utf8( 0x01F3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH SMALL LETTER Z */
			else if ( cp == 0x01F4 ) { rdfstore_utf8_cp_to_utf8( 0x01F5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G WITH ACUTE */
			else if ( cp == 0x01F6 ) { rdfstore_utf8_cp_to_utf8( 0x0195, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER HWAIR */
			else if ( cp == 0x01F7 ) { rdfstore_utf8_cp_to_utf8( 0x01BF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER WYNN */
			else if ( cp == 0x01F8 ) { rdfstore_utf8_cp_to_utf8( 0x01F9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH GRAVE */
			else if ( cp == 0x01FA ) { rdfstore_utf8_cp_to_utf8( 0x01FB, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH RING ABOVE AND ACUTE */
			else if ( cp == 0x01FC ) { rdfstore_utf8_cp_to_utf8( 0x01FD, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER AE WITH ACUTE */
			else if ( cp == 0x01FE ) { rdfstore_utf8_cp_to_utf8( 0x01FF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH STROKE AND ACUTE */
			else if ( cp == 0x0200 ) { rdfstore_utf8_cp_to_utf8( 0x0201, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH DOUBLE GRAVE */
			else if ( cp == 0x0202 ) { rdfstore_utf8_cp_to_utf8( 0x0203, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH INVERTED BREVE */
			else if ( cp == 0x0204 ) { rdfstore_utf8_cp_to_utf8( 0x0205, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH DOUBLE GRAVE */
			else if ( cp == 0x0206 ) { rdfstore_utf8_cp_to_utf8( 0x0207, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH INVERTED BREVE */
			else if ( cp == 0x0208 ) { rdfstore_utf8_cp_to_utf8( 0x0209, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH DOUBLE GRAVE */
			else if ( cp == 0x020A ) { rdfstore_utf8_cp_to_utf8( 0x020B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH INVERTED BREVE */
			else if ( cp == 0x020C ) { rdfstore_utf8_cp_to_utf8( 0x020D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH DOUBLE GRAVE */
			else if ( cp == 0x020E ) { rdfstore_utf8_cp_to_utf8( 0x020F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH INVERTED BREVE */
			else if ( cp == 0x0210 ) { rdfstore_utf8_cp_to_utf8( 0x0211, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R WITH DOUBLE GRAVE */
			else if ( cp == 0x0212 ) { rdfstore_utf8_cp_to_utf8( 0x0213, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R WITH INVERTED BREVE */
			else if ( cp == 0x0214 ) { rdfstore_utf8_cp_to_utf8( 0x0215, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH DOUBLE GRAVE */
			else if ( cp == 0x0216 ) { rdfstore_utf8_cp_to_utf8( 0x0217, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH INVERTED BREVE */
			else if ( cp == 0x0218 ) { rdfstore_utf8_cp_to_utf8( 0x0219, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH COMMA BELOW */
			else if ( cp == 0x021A ) { rdfstore_utf8_cp_to_utf8( 0x021B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH COMMA BELOW */
			else if ( cp == 0x021C ) { rdfstore_utf8_cp_to_utf8( 0x021D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER YOGH */
			else if ( cp == 0x021E ) { rdfstore_utf8_cp_to_utf8( 0x021F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER H WITH CARON */
			else if ( cp == 0x0222 ) { rdfstore_utf8_cp_to_utf8( 0x0223, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER OU */
			else if ( cp == 0x0224 ) { rdfstore_utf8_cp_to_utf8( 0x0225, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Z WITH HOOK */
			else if ( cp == 0x0226 ) { rdfstore_utf8_cp_to_utf8( 0x0227, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH DOT ABOVE */
			else if ( cp == 0x0228 ) { rdfstore_utf8_cp_to_utf8( 0x0229, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CEDILLA */
			else if ( cp == 0x022A ) { rdfstore_utf8_cp_to_utf8( 0x022B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH DIAERESIS AND MACRON */
			else if ( cp == 0x022C ) { rdfstore_utf8_cp_to_utf8( 0x022D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH TILDE AND MACRON */
			else if ( cp == 0x022E ) { rdfstore_utf8_cp_to_utf8( 0x022F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH DOT ABOVE */
			else if ( cp == 0x0230 ) { rdfstore_utf8_cp_to_utf8( 0x0231, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH DOT ABOVE AND MACRON */
			else if ( cp == 0x0232 ) { rdfstore_utf8_cp_to_utf8( 0x0233, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH MACRON */
			else if ( cp == 0x0345 ) { rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); } /*  COMBINING GREEK YPOGEGRAMMENI */
			else if ( cp == 0x0386 ) { rdfstore_utf8_cp_to_utf8( 0x03AC, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH TONOS */
			else if ( cp == 0x0388 ) { rdfstore_utf8_cp_to_utf8( 0x03AD, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON WITH TONOS */
			else if ( cp == 0x0389 ) { rdfstore_utf8_cp_to_utf8( 0x03AE, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH TONOS */
			else if ( cp == 0x038A ) { rdfstore_utf8_cp_to_utf8( 0x03AF, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH TONOS */
			else if ( cp == 0x038C ) { rdfstore_utf8_cp_to_utf8( 0x03CC, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON WITH TONOS */
			else if ( cp == 0x038E ) { rdfstore_utf8_cp_to_utf8( 0x03CD, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH TONOS */
			else if ( cp == 0x038F ) { rdfstore_utf8_cp_to_utf8( 0x03CE, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH TONOS */
			else if ( cp == 0x0390 ) { rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS */
			                           rdfstore_utf8_cp_to_utf8( 0x0308, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0301, &utf8_size, utf8_buff ); }
			else if ( cp == 0x0391 ) { rdfstore_utf8_cp_to_utf8( 0x03B1, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA */
			else if ( cp == 0x0392 ) { rdfstore_utf8_cp_to_utf8( 0x03B2, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER BETA */
			else if ( cp == 0x0393 ) { rdfstore_utf8_cp_to_utf8( 0x03B3, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER GAMMA */
			else if ( cp == 0x0394 ) { rdfstore_utf8_cp_to_utf8( 0x03B4, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER DELTA */
			else if ( cp == 0x0395 ) { rdfstore_utf8_cp_to_utf8( 0x03B5, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON */
			else if ( cp == 0x0396 ) { rdfstore_utf8_cp_to_utf8( 0x03B6, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ZETA */
			else if ( cp == 0x0397 ) { rdfstore_utf8_cp_to_utf8( 0x03B7, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA */
			else if ( cp == 0x0398 ) { rdfstore_utf8_cp_to_utf8( 0x03B8, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER THETA */
			else if ( cp == 0x0399 ) { rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA */
			else if ( cp == 0x039A ) { rdfstore_utf8_cp_to_utf8( 0x03BA, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER KAPPA */
			else if ( cp == 0x039B ) { rdfstore_utf8_cp_to_utf8( 0x03BB, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER LAMDA */
			else if ( cp == 0x039C ) { rdfstore_utf8_cp_to_utf8( 0x03BC, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER MU */
			else if ( cp == 0x039D ) { rdfstore_utf8_cp_to_utf8( 0x03BD, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER NU */
			else if ( cp == 0x039E ) { rdfstore_utf8_cp_to_utf8( 0x03BE, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER XI */
			else if ( cp == 0x039F ) { rdfstore_utf8_cp_to_utf8( 0x03BF, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON */
			else if ( cp == 0x03A0 ) { rdfstore_utf8_cp_to_utf8( 0x03C0, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER PI */
			else if ( cp == 0x03A1 ) { rdfstore_utf8_cp_to_utf8( 0x03C1, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER RHO */
			else if ( cp == 0x03A3 ) { rdfstore_utf8_cp_to_utf8( 0x03C3, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER SIGMA */
			else if ( cp == 0x03A4 ) { rdfstore_utf8_cp_to_utf8( 0x03C4, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER TAU */
			else if ( cp == 0x03A5 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON */
			else if ( cp == 0x03A6 ) { rdfstore_utf8_cp_to_utf8( 0x03C6, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER PHI */
			else if ( cp == 0x03A7 ) { rdfstore_utf8_cp_to_utf8( 0x03C7, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER CHI */
			else if ( cp == 0x03A8 ) { rdfstore_utf8_cp_to_utf8( 0x03C8, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER PSI */
			else if ( cp == 0x03A9 ) { rdfstore_utf8_cp_to_utf8( 0x03C9, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA */
			else if ( cp == 0x03AA ) { rdfstore_utf8_cp_to_utf8( 0x03CA, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH DIALYTIKA */
			else if ( cp == 0x03AB ) { rdfstore_utf8_cp_to_utf8( 0x03CB, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH DIALYTIKA */
			else if ( cp == 0x03B0 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS */
			                           rdfstore_utf8_cp_to_utf8( 0x0308, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0301, &utf8_size, utf8_buff ); }
			else if ( cp == 0x03C2 ) { rdfstore_utf8_cp_to_utf8( 0x03C3, &utf8_size, utf8_buff ); } /*  GREEK SMALL LETTER FINAL SIGMA */
			else if ( cp == 0x03D0 ) { rdfstore_utf8_cp_to_utf8( 0x03B2, &utf8_size, utf8_buff ); } /*  GREEK BETA SYMBOL */
			else if ( cp == 0x03D1 ) { rdfstore_utf8_cp_to_utf8( 0x03B8, &utf8_size, utf8_buff ); } /*  GREEK THETA SYMBOL */
			else if ( cp == 0x03D5 ) { rdfstore_utf8_cp_to_utf8( 0x03C6, &utf8_size, utf8_buff ); } /*  GREEK PHI SYMBOL */
			else if ( cp == 0x03D6 ) { rdfstore_utf8_cp_to_utf8( 0x03C0, &utf8_size, utf8_buff ); } /*  GREEK PI SYMBOL */
			else if ( cp == 0x03DA ) { rdfstore_utf8_cp_to_utf8( 0x03DB, &utf8_size, utf8_buff ); } /*  GREEK LETTER STIGMA */
			else if ( cp == 0x03DC ) { rdfstore_utf8_cp_to_utf8( 0x03DD, &utf8_size, utf8_buff ); } /*  GREEK LETTER DIGAMMA */
			else if ( cp == 0x03DE ) { rdfstore_utf8_cp_to_utf8( 0x03DF, &utf8_size, utf8_buff ); } /*  GREEK LETTER KOPPA */
			else if ( cp == 0x03E0 ) { rdfstore_utf8_cp_to_utf8( 0x03E1, &utf8_size, utf8_buff ); } /*  GREEK LETTER SAMPI */
			else if ( cp == 0x03E2 ) { rdfstore_utf8_cp_to_utf8( 0x03E3, &utf8_size, utf8_buff ); } /*  COPTIC CAPITAL LETTER SHEI */
			else if ( cp == 0x03E4 ) { rdfstore_utf8_cp_to_utf8( 0x03E5, &utf8_size, utf8_buff ); } /*  COPTIC CAPITAL LETTER FEI */
			else if ( cp == 0x03E6 ) { rdfstore_utf8_cp_to_utf8( 0x03E7, &utf8_size, utf8_buff ); } /*  COPTIC CAPITAL LETTER KHEI */
			else if ( cp == 0x03E8 ) { rdfstore_utf8_cp_to_utf8( 0x03E9, &utf8_size, utf8_buff ); } /*  COPTIC CAPITAL LETTER HORI */
			else if ( cp == 0x03EA ) { rdfstore_utf8_cp_to_utf8( 0x03EB, &utf8_size, utf8_buff ); } /*  COPTIC CAPITAL LETTER GANGIA */
			else if ( cp == 0x03EC ) { rdfstore_utf8_cp_to_utf8( 0x03ED, &utf8_size, utf8_buff ); } /*  COPTIC CAPITAL LETTER SHIMA */
			else if ( cp == 0x03EE ) { rdfstore_utf8_cp_to_utf8( 0x03EF, &utf8_size, utf8_buff ); } /*  COPTIC CAPITAL LETTER DEI */
			else if ( cp == 0x03F0 ) { rdfstore_utf8_cp_to_utf8( 0x03BA, &utf8_size, utf8_buff ); } /*  GREEK KAPPA SYMBOL */
			else if ( cp == 0x03F1 ) { rdfstore_utf8_cp_to_utf8( 0x03C1, &utf8_size, utf8_buff ); } /*  GREEK RHO SYMBOL */
			else if ( cp == 0x03F2 ) { rdfstore_utf8_cp_to_utf8( 0x03C3, &utf8_size, utf8_buff ); } /*  GREEK LUNATE SIGMA SYMBOL */
			else if ( cp == 0x03F4 ) { rdfstore_utf8_cp_to_utf8( 0x03B8, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL THETA SYMBOL */
			else if ( cp == 0x03F5 ) { rdfstore_utf8_cp_to_utf8( 0x03B5, &utf8_size, utf8_buff ); } /*  GREEK LUNATE EPSILON SYMBOL */
			else if ( cp == 0x0400 ) { rdfstore_utf8_cp_to_utf8( 0x0450, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER IE WITH GRAVE */
			else if ( cp == 0x0401 ) { rdfstore_utf8_cp_to_utf8( 0x0451, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER IO */
			else if ( cp == 0x0402 ) { rdfstore_utf8_cp_to_utf8( 0x0452, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER DJE */
			else if ( cp == 0x0403 ) { rdfstore_utf8_cp_to_utf8( 0x0453, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER GJE */
			else if ( cp == 0x0404 ) { rdfstore_utf8_cp_to_utf8( 0x0454, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER UKRAINIAN IE */
			else if ( cp == 0x0405 ) { rdfstore_utf8_cp_to_utf8( 0x0455, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER DZE */
			else if ( cp == 0x0406 ) { rdfstore_utf8_cp_to_utf8( 0x0456, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I */
			else if ( cp == 0x0407 ) { rdfstore_utf8_cp_to_utf8( 0x0457, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER YI */
			else if ( cp == 0x0408 ) { rdfstore_utf8_cp_to_utf8( 0x0458, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER JE */
			else if ( cp == 0x0409 ) { rdfstore_utf8_cp_to_utf8( 0x0459, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER LJE */
			else if ( cp == 0x040A ) { rdfstore_utf8_cp_to_utf8( 0x045A, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER NJE */
			else if ( cp == 0x040B ) { rdfstore_utf8_cp_to_utf8( 0x045B, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER TSHE */
			else if ( cp == 0x040C ) { rdfstore_utf8_cp_to_utf8( 0x045C, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER KJE */
			else if ( cp == 0x040D ) { rdfstore_utf8_cp_to_utf8( 0x045D, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER I WITH GRAVE */
			else if ( cp == 0x040E ) { rdfstore_utf8_cp_to_utf8( 0x045E, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER SHORT U */
			else if ( cp == 0x040F ) { rdfstore_utf8_cp_to_utf8( 0x045F, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER DZHE */
			else if ( cp == 0x0410 ) { rdfstore_utf8_cp_to_utf8( 0x0430, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER A */
			else if ( cp == 0x0411 ) { rdfstore_utf8_cp_to_utf8( 0x0431, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER BE */
			else if ( cp == 0x0412 ) { rdfstore_utf8_cp_to_utf8( 0x0432, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER VE */
			else if ( cp == 0x0413 ) { rdfstore_utf8_cp_to_utf8( 0x0433, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER GHE */
			else if ( cp == 0x0414 ) { rdfstore_utf8_cp_to_utf8( 0x0434, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER DE */
			else if ( cp == 0x0415 ) { rdfstore_utf8_cp_to_utf8( 0x0435, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER IE */
			else if ( cp == 0x0416 ) { rdfstore_utf8_cp_to_utf8( 0x0436, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ZHE */
			else if ( cp == 0x0417 ) { rdfstore_utf8_cp_to_utf8( 0x0437, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ZE */
			else if ( cp == 0x0418 ) { rdfstore_utf8_cp_to_utf8( 0x0438, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER I */
			else if ( cp == 0x0419 ) { rdfstore_utf8_cp_to_utf8( 0x0439, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER SHORT I */
			else if ( cp == 0x041A ) { rdfstore_utf8_cp_to_utf8( 0x043A, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER KA */
			else if ( cp == 0x041B ) { rdfstore_utf8_cp_to_utf8( 0x043B, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER EL */
			else if ( cp == 0x041C ) { rdfstore_utf8_cp_to_utf8( 0x043C, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER EM */
			else if ( cp == 0x041D ) { rdfstore_utf8_cp_to_utf8( 0x043D, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER EN */
			else if ( cp == 0x041E ) { rdfstore_utf8_cp_to_utf8( 0x043E, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER O */
			else if ( cp == 0x041F ) { rdfstore_utf8_cp_to_utf8( 0x043F, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER PE */
			else if ( cp == 0x0420 ) { rdfstore_utf8_cp_to_utf8( 0x0440, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ER */
			else if ( cp == 0x0421 ) { rdfstore_utf8_cp_to_utf8( 0x0441, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ES */
			else if ( cp == 0x0422 ) { rdfstore_utf8_cp_to_utf8( 0x0442, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER TE */
			else if ( cp == 0x0423 ) { rdfstore_utf8_cp_to_utf8( 0x0443, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER U */
			else if ( cp == 0x0424 ) { rdfstore_utf8_cp_to_utf8( 0x0444, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER EF */
			else if ( cp == 0x0425 ) { rdfstore_utf8_cp_to_utf8( 0x0445, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER HA */
			else if ( cp == 0x0426 ) { rdfstore_utf8_cp_to_utf8( 0x0446, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER TSE */
			else if ( cp == 0x0427 ) { rdfstore_utf8_cp_to_utf8( 0x0447, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER CHE */
			else if ( cp == 0x0428 ) { rdfstore_utf8_cp_to_utf8( 0x0448, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER SHA */
			else if ( cp == 0x0429 ) { rdfstore_utf8_cp_to_utf8( 0x0449, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER SHCHA */
			else if ( cp == 0x042A ) { rdfstore_utf8_cp_to_utf8( 0x044A, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER HARD SIGN */
			else if ( cp == 0x042B ) { rdfstore_utf8_cp_to_utf8( 0x044B, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER YERU */
			else if ( cp == 0x042C ) { rdfstore_utf8_cp_to_utf8( 0x044C, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER SOFT SIGN */
			else if ( cp == 0x042D ) { rdfstore_utf8_cp_to_utf8( 0x044D, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER E */
			else if ( cp == 0x042E ) { rdfstore_utf8_cp_to_utf8( 0x044E, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER YU */
			else if ( cp == 0x042F ) { rdfstore_utf8_cp_to_utf8( 0x044F, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER YA */
			else if ( cp == 0x0460 ) { rdfstore_utf8_cp_to_utf8( 0x0461, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER OMEGA */
			else if ( cp == 0x0462 ) { rdfstore_utf8_cp_to_utf8( 0x0463, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER YAT */
			else if ( cp == 0x0464 ) { rdfstore_utf8_cp_to_utf8( 0x0465, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER IOTIFIED E */
			else if ( cp == 0x0466 ) { rdfstore_utf8_cp_to_utf8( 0x0467, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER LITTLE YUS */
			else if ( cp == 0x0468 ) { rdfstore_utf8_cp_to_utf8( 0x0469, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER IOTIFIED LITTLE YUS */
			else if ( cp == 0x046A ) { rdfstore_utf8_cp_to_utf8( 0x046B, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER BIG YUS */
			else if ( cp == 0x046C ) { rdfstore_utf8_cp_to_utf8( 0x046D, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER IOTIFIED BIG YUS */
			else if ( cp == 0x046E ) { rdfstore_utf8_cp_to_utf8( 0x046F, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER KSI */
			else if ( cp == 0x0470 ) { rdfstore_utf8_cp_to_utf8( 0x0471, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER PSI */
			else if ( cp == 0x0472 ) { rdfstore_utf8_cp_to_utf8( 0x0473, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER FITA */
			else if ( cp == 0x0474 ) { rdfstore_utf8_cp_to_utf8( 0x0475, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER IZHITSA */
			else if ( cp == 0x0476 ) { rdfstore_utf8_cp_to_utf8( 0x0477, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER IZHITSA WITH DOUBLE GRAVE 0xACCENT */
			else if ( cp == 0x0478 ) { rdfstore_utf8_cp_to_utf8( 0x0479, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER UK */
			else if ( cp == 0x047A ) { rdfstore_utf8_cp_to_utf8( 0x047B, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ROUND OMEGA */
			else if ( cp == 0x047C ) { rdfstore_utf8_cp_to_utf8( 0x047D, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER OMEGA WITH TITLO */
			else if ( cp == 0x047E ) { rdfstore_utf8_cp_to_utf8( 0x047F, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER OT */
			else if ( cp == 0x0480 ) { rdfstore_utf8_cp_to_utf8( 0x0481, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER KOPPA */
			else if ( cp == 0x048C ) { rdfstore_utf8_cp_to_utf8( 0x048D, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER SEMISOFT SIGN */
			else if ( cp == 0x048E ) { rdfstore_utf8_cp_to_utf8( 0x048F, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ER WITH TICK */
			else if ( cp == 0x0490 ) { rdfstore_utf8_cp_to_utf8( 0x0491, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER GHE WITH UPTURN */
			else if ( cp == 0x0492 ) { rdfstore_utf8_cp_to_utf8( 0x0493, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER GHE WITH STROKE */
			else if ( cp == 0x0494 ) { rdfstore_utf8_cp_to_utf8( 0x0495, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER GHE WITH MIDDLE HOOK */
			else if ( cp == 0x0496 ) { rdfstore_utf8_cp_to_utf8( 0x0497, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ZHE WITH DESCENDER */
			else if ( cp == 0x0498 ) { rdfstore_utf8_cp_to_utf8( 0x0499, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ZE WITH DESCENDER */
			else if ( cp == 0x049A ) { rdfstore_utf8_cp_to_utf8( 0x049B, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER KA WITH DESCENDER */
			else if ( cp == 0x049C ) { rdfstore_utf8_cp_to_utf8( 0x049D, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER KA WITH VERTICAL STROKE */
			else if ( cp == 0x049E ) { rdfstore_utf8_cp_to_utf8( 0x049F, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER KA WITH STROKE */
			else if ( cp == 0x04A0 ) { rdfstore_utf8_cp_to_utf8( 0x04A1, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER BASHKIR KA */
			else if ( cp == 0x04A2 ) { rdfstore_utf8_cp_to_utf8( 0x04A3, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER EN WITH DESCENDER */
			else if ( cp == 0x04A4 ) { rdfstore_utf8_cp_to_utf8( 0x04A5, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LIGATURE EN GHE */
			else if ( cp == 0x04A6 ) { rdfstore_utf8_cp_to_utf8( 0x04A7, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER PE WITH MIDDLE HOOK */
			else if ( cp == 0x04A8 ) { rdfstore_utf8_cp_to_utf8( 0x04A9, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ABKHASIAN HA */
			else if ( cp == 0x04AA ) { rdfstore_utf8_cp_to_utf8( 0x04AB, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ES WITH DESCENDER */
			else if ( cp == 0x04AC ) { rdfstore_utf8_cp_to_utf8( 0x04AD, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER TE WITH DESCENDER */
			else if ( cp == 0x04AE ) { rdfstore_utf8_cp_to_utf8( 0x04AF, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER STRAIGHT U */
			else if ( cp == 0x04B0 ) { rdfstore_utf8_cp_to_utf8( 0x04B1, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER STRAIGHT U WITH STROKE */
			else if ( cp == 0x04B2 ) { rdfstore_utf8_cp_to_utf8( 0x04B3, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER HA WITH DESCENDER */
			else if ( cp == 0x04B4 ) { rdfstore_utf8_cp_to_utf8( 0x04B5, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LIGATURE TE TSE */
			else if ( cp == 0x04B6 ) { rdfstore_utf8_cp_to_utf8( 0x04B7, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER CHE WITH DESCENDER */
			else if ( cp == 0x04B8 ) { rdfstore_utf8_cp_to_utf8( 0x04B9, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER CHE WITH VERTICAL STROKE */
			else if ( cp == 0x04BA ) { rdfstore_utf8_cp_to_utf8( 0x04BB, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER SHHA */
			else if ( cp == 0x04BC ) { rdfstore_utf8_cp_to_utf8( 0x04BD, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ABKHASIAN CHE */
			else if ( cp == 0x04BE ) { rdfstore_utf8_cp_to_utf8( 0x04BF, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ABKHASIAN CHE WITH DESCENDER */
			else if ( cp == 0x04C1 ) { rdfstore_utf8_cp_to_utf8( 0x04C2, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ZHE WITH BREVE */
			else if ( cp == 0x04C3 ) { rdfstore_utf8_cp_to_utf8( 0x04C4, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER KA WITH HOOK */
			else if ( cp == 0x04C7 ) { rdfstore_utf8_cp_to_utf8( 0x04C8, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER EN WITH HOOK */
			else if ( cp == 0x04CB ) { rdfstore_utf8_cp_to_utf8( 0x04CC, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER KHAKASSIAN CHE */
			else if ( cp == 0x04D0 ) { rdfstore_utf8_cp_to_utf8( 0x04D1, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER A WITH BREVE */
			else if ( cp == 0x04D2 ) { rdfstore_utf8_cp_to_utf8( 0x04D3, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER A WITH DIAERESIS */
			else if ( cp == 0x04D4 ) { rdfstore_utf8_cp_to_utf8( 0x04D5, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LIGATURE A IE */
			else if ( cp == 0x04D6 ) { rdfstore_utf8_cp_to_utf8( 0x04D7, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER IE WITH BREVE */
			else if ( cp == 0x04D8 ) { rdfstore_utf8_cp_to_utf8( 0x04D9, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER SCHWA */
			else if ( cp == 0x04DA ) { rdfstore_utf8_cp_to_utf8( 0x04DB, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER SCHWA WITH DIAERESIS */
			else if ( cp == 0x04DC ) { rdfstore_utf8_cp_to_utf8( 0x04DD, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ZHE WITH DIAERESIS */
			else if ( cp == 0x04DE ) { rdfstore_utf8_cp_to_utf8( 0x04DF, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ZE WITH DIAERESIS */
			else if ( cp == 0x04E0 ) { rdfstore_utf8_cp_to_utf8( 0x04E1, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER ABKHASIAN DZE */
			else if ( cp == 0x04E2 ) { rdfstore_utf8_cp_to_utf8( 0x04E3, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER I WITH MACRON */
			else if ( cp == 0x04E4 ) { rdfstore_utf8_cp_to_utf8( 0x04E5, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER I WITH DIAERESIS */
			else if ( cp == 0x04E6 ) { rdfstore_utf8_cp_to_utf8( 0x04E7, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER O WITH DIAERESIS */
			else if ( cp == 0x04E8 ) { rdfstore_utf8_cp_to_utf8( 0x04E9, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER BARRED O */
			else if ( cp == 0x04EA ) { rdfstore_utf8_cp_to_utf8( 0x04EB, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER BARRED O WITH DIAERESIS */
			else if ( cp == 0x04EC ) { rdfstore_utf8_cp_to_utf8( 0x04ED, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER E WITH DIAERESIS */
			else if ( cp == 0x04EE ) { rdfstore_utf8_cp_to_utf8( 0x04EF, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER U WITH MACRON */
			else if ( cp == 0x04F0 ) { rdfstore_utf8_cp_to_utf8( 0x04F1, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER U WITH DIAERESIS */
			else if ( cp == 0x04F2 ) { rdfstore_utf8_cp_to_utf8( 0x04F3, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER U WITH DOUBLE ACUTE */
			else if ( cp == 0x04F4 ) { rdfstore_utf8_cp_to_utf8( 0x04F5, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER CHE WITH DIAERESIS */
			else if ( cp == 0x04F8 ) { rdfstore_utf8_cp_to_utf8( 0x04F9, &utf8_size, utf8_buff ); } /*  CYRILLIC CAPITAL LETTER YERU WITH DIAERESIS */
			else if ( cp == 0x0531 ) { rdfstore_utf8_cp_to_utf8( 0x0561, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER AYB */
			else if ( cp == 0x0532 ) { rdfstore_utf8_cp_to_utf8( 0x0562, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER BEN */
			else if ( cp == 0x0533 ) { rdfstore_utf8_cp_to_utf8( 0x0563, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER GIM */
			else if ( cp == 0x0534 ) { rdfstore_utf8_cp_to_utf8( 0x0564, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER DA */
			else if ( cp == 0x0535 ) { rdfstore_utf8_cp_to_utf8( 0x0565, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER ECH */
			else if ( cp == 0x0536 ) { rdfstore_utf8_cp_to_utf8( 0x0566, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER ZA */
			else if ( cp == 0x0537 ) { rdfstore_utf8_cp_to_utf8( 0x0567, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER EH */
			else if ( cp == 0x0538 ) { rdfstore_utf8_cp_to_utf8( 0x0568, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER ET */
			else if ( cp == 0x0539 ) { rdfstore_utf8_cp_to_utf8( 0x0569, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER TO */
			else if ( cp == 0x053A ) { rdfstore_utf8_cp_to_utf8( 0x056A, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER ZHE */
			else if ( cp == 0x053B ) { rdfstore_utf8_cp_to_utf8( 0x056B, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER INI */
			else if ( cp == 0x053C ) { rdfstore_utf8_cp_to_utf8( 0x056C, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER LIWN */
			else if ( cp == 0x053D ) { rdfstore_utf8_cp_to_utf8( 0x056D, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER XEH */
			else if ( cp == 0x053E ) { rdfstore_utf8_cp_to_utf8( 0x056E, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER CA */
			else if ( cp == 0x053F ) { rdfstore_utf8_cp_to_utf8( 0x056F, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER KEN */
			else if ( cp == 0x0540 ) { rdfstore_utf8_cp_to_utf8( 0x0570, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER HO */
			else if ( cp == 0x0541 ) { rdfstore_utf8_cp_to_utf8( 0x0571, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER JA */
			else if ( cp == 0x0542 ) { rdfstore_utf8_cp_to_utf8( 0x0572, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER GHAD */
			else if ( cp == 0x0543 ) { rdfstore_utf8_cp_to_utf8( 0x0573, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER CHEH */
			else if ( cp == 0x0544 ) { rdfstore_utf8_cp_to_utf8( 0x0574, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER MEN */
			else if ( cp == 0x0545 ) { rdfstore_utf8_cp_to_utf8( 0x0575, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER YI */
			else if ( cp == 0x0546 ) { rdfstore_utf8_cp_to_utf8( 0x0576, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER NOW */
			else if ( cp == 0x0547 ) { rdfstore_utf8_cp_to_utf8( 0x0577, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER SHA */
			else if ( cp == 0x0548 ) { rdfstore_utf8_cp_to_utf8( 0x0578, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER VO */
			else if ( cp == 0x0549 ) { rdfstore_utf8_cp_to_utf8( 0x0579, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER CHA */
			else if ( cp == 0x054A ) { rdfstore_utf8_cp_to_utf8( 0x057A, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER PEH */
			else if ( cp == 0x054B ) { rdfstore_utf8_cp_to_utf8( 0x057B, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER JHEH */
			else if ( cp == 0x054C ) { rdfstore_utf8_cp_to_utf8( 0x057C, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER RA */
			else if ( cp == 0x054D ) { rdfstore_utf8_cp_to_utf8( 0x057D, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER SEH */
			else if ( cp == 0x054E ) { rdfstore_utf8_cp_to_utf8( 0x057E, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER VEW */
			else if ( cp == 0x054F ) { rdfstore_utf8_cp_to_utf8( 0x057F, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER TIWN */
			else if ( cp == 0x0550 ) { rdfstore_utf8_cp_to_utf8( 0x0580, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER REH */
			else if ( cp == 0x0551 ) { rdfstore_utf8_cp_to_utf8( 0x0581, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER CO */
			else if ( cp == 0x0552 ) { rdfstore_utf8_cp_to_utf8( 0x0582, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER YIWN */
			else if ( cp == 0x0553 ) { rdfstore_utf8_cp_to_utf8( 0x0583, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER PIWR */
			else if ( cp == 0x0554 ) { rdfstore_utf8_cp_to_utf8( 0x0584, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER KEH */
			else if ( cp == 0x0555 ) { rdfstore_utf8_cp_to_utf8( 0x0585, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER OH */
			else if ( cp == 0x0556 ) { rdfstore_utf8_cp_to_utf8( 0x0586, &utf8_size, utf8_buff ); } /*  ARMENIAN CAPITAL LETTER FEH */
			else if ( cp == 0x0587 ) { rdfstore_utf8_cp_to_utf8( 0x0565, &utf8_size, utf8_buff );   /*  ARMENIAN SMALL LIGATURE ECH YIWN */
			                           rdfstore_utf8_cp_to_utf8( 0x0582, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1E00 ) { rdfstore_utf8_cp_to_utf8( 0x1E01, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH RING BELOW */
			else if ( cp == 0x1E02 ) { rdfstore_utf8_cp_to_utf8( 0x1E03, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER B WITH DOT ABOVE */
			else if ( cp == 0x1E04 ) { rdfstore_utf8_cp_to_utf8( 0x1E05, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER B WITH DOT BELOW */
			else if ( cp == 0x1E06 ) { rdfstore_utf8_cp_to_utf8( 0x1E07, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER B WITH LINE BELOW */
			else if ( cp == 0x1E08 ) { rdfstore_utf8_cp_to_utf8( 0x1E09, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER C WITH CEDILLA AND ACUTE */
			else if ( cp == 0x1E0A ) { rdfstore_utf8_cp_to_utf8( 0x1E0B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH DOT ABOVE */
			else if ( cp == 0x1E0C ) { rdfstore_utf8_cp_to_utf8( 0x1E0D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH DOT BELOW */
			else if ( cp == 0x1E0E ) { rdfstore_utf8_cp_to_utf8( 0x1E0F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH LINE BELOW */
			else if ( cp == 0x1E10 ) { rdfstore_utf8_cp_to_utf8( 0x1E11, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH CEDILLA */
			else if ( cp == 0x1E12 ) { rdfstore_utf8_cp_to_utf8( 0x1E13, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER D WITH CIRCUMFLEX BELOW */
			else if ( cp == 0x1E14 ) { rdfstore_utf8_cp_to_utf8( 0x1E15, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH MACRON AND GRAVE */
			else if ( cp == 0x1E16 ) { rdfstore_utf8_cp_to_utf8( 0x1E17, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH MACRON AND ACUTE */
			else if ( cp == 0x1E18 ) { rdfstore_utf8_cp_to_utf8( 0x1E19, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CIRCUMFLEX BELOW */
			else if ( cp == 0x1E1A ) { rdfstore_utf8_cp_to_utf8( 0x1E1B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH TILDE BELOW */
			else if ( cp == 0x1E1C ) { rdfstore_utf8_cp_to_utf8( 0x1E1D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CEDILLA AND BREVE */
			else if ( cp == 0x1E1E ) { rdfstore_utf8_cp_to_utf8( 0x1E1F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER F WITH DOT ABOVE */
			else if ( cp == 0x1E20 ) { rdfstore_utf8_cp_to_utf8( 0x1E21, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER G WITH MACRON */
			else if ( cp == 0x1E22 ) { rdfstore_utf8_cp_to_utf8( 0x1E23, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER H WITH DOT ABOVE */
			else if ( cp == 0x1E24 ) { rdfstore_utf8_cp_to_utf8( 0x1E25, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER H WITH DOT BELOW */
			else if ( cp == 0x1E26 ) { rdfstore_utf8_cp_to_utf8( 0x1E27, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER H WITH DIAERESIS */
			else if ( cp == 0x1E28 ) { rdfstore_utf8_cp_to_utf8( 0x1E29, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER H WITH CEDILLA */
			else if ( cp == 0x1E2A ) { rdfstore_utf8_cp_to_utf8( 0x1E2B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER H WITH BREVE BELOW */
			else if ( cp == 0x1E2C ) { rdfstore_utf8_cp_to_utf8( 0x1E2D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH TILDE BELOW */
			else if ( cp == 0x1E2E ) { rdfstore_utf8_cp_to_utf8( 0x1E2F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH DIAERESIS AND ACUTE */
			else if ( cp == 0x1E30 ) { rdfstore_utf8_cp_to_utf8( 0x1E31, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER K WITH ACUTE */
			else if ( cp == 0x1E32 ) { rdfstore_utf8_cp_to_utf8( 0x1E33, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER K WITH DOT BELOW */
			else if ( cp == 0x1E34 ) { rdfstore_utf8_cp_to_utf8( 0x1E35, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER K WITH LINE BELOW */
			else if ( cp == 0x1E36 ) { rdfstore_utf8_cp_to_utf8( 0x1E37, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH DOT BELOW */
			else if ( cp == 0x1E38 ) { rdfstore_utf8_cp_to_utf8( 0x1E39, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH DOT BELOW AND MACRON */
			else if ( cp == 0x1E3A ) { rdfstore_utf8_cp_to_utf8( 0x1E3B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH LINE BELOW */
			else if ( cp == 0x1E3C ) { rdfstore_utf8_cp_to_utf8( 0x1E3D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER L WITH CIRCUMFLEX BELOW */
			else if ( cp == 0x1E3E ) { rdfstore_utf8_cp_to_utf8( 0x1E3F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER M WITH ACUTE */
			else if ( cp == 0x1E40 ) { rdfstore_utf8_cp_to_utf8( 0x1E41, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER M WITH DOT ABOVE */
			else if ( cp == 0x1E42 ) { rdfstore_utf8_cp_to_utf8( 0x1E43, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER M WITH DOT BELOW */
			else if ( cp == 0x1E44 ) { rdfstore_utf8_cp_to_utf8( 0x1E45, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH DOT ABOVE */
			else if ( cp == 0x1E46 ) { rdfstore_utf8_cp_to_utf8( 0x1E47, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH DOT BELOW */
			else if ( cp == 0x1E48 ) { rdfstore_utf8_cp_to_utf8( 0x1E49, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH LINE BELOW */
			else if ( cp == 0x1E4A ) { rdfstore_utf8_cp_to_utf8( 0x1E4B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER N WITH CIRCUMFLEX BELOW */
			else if ( cp == 0x1E4C ) { rdfstore_utf8_cp_to_utf8( 0x1E4D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH TILDE AND ACUTE */
			else if ( cp == 0x1E4E ) { rdfstore_utf8_cp_to_utf8( 0x1E4F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH TILDE AND DIAERESIS */
			else if ( cp == 0x1E50 ) { rdfstore_utf8_cp_to_utf8( 0x1E51, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH MACRON AND GRAVE */
			else if ( cp == 0x1E52 ) { rdfstore_utf8_cp_to_utf8( 0x1E53, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH MACRON AND ACUTE */
			else if ( cp == 0x1E54 ) { rdfstore_utf8_cp_to_utf8( 0x1E55, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER P WITH ACUTE */
			else if ( cp == 0x1E56 ) { rdfstore_utf8_cp_to_utf8( 0x1E57, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER P WITH DOT ABOVE */
			else if ( cp == 0x1E58 ) { rdfstore_utf8_cp_to_utf8( 0x1E59, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R WITH DOT ABOVE */
			else if ( cp == 0x1E5A ) { rdfstore_utf8_cp_to_utf8( 0x1E5B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R WITH DOT BELOW */
			else if ( cp == 0x1E5C ) { rdfstore_utf8_cp_to_utf8( 0x1E5D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R WITH DOT BELOW AND MACRON */
			else if ( cp == 0x1E5E ) { rdfstore_utf8_cp_to_utf8( 0x1E5F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER R WITH LINE BELOW */
			else if ( cp == 0x1E60 ) { rdfstore_utf8_cp_to_utf8( 0x1E61, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH DOT ABOVE */
			else if ( cp == 0x1E62 ) { rdfstore_utf8_cp_to_utf8( 0x1E63, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH DOT BELOW */
			else if ( cp == 0x1E64 ) { rdfstore_utf8_cp_to_utf8( 0x1E65, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH ACUTE AND DOT ABOVE */
			else if ( cp == 0x1E66 ) { rdfstore_utf8_cp_to_utf8( 0x1E67, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH CARON AND DOT ABOVE */
			else if ( cp == 0x1E68 ) { rdfstore_utf8_cp_to_utf8( 0x1E69, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER S WITH DOT BELOW AND DOT ABOVE */
			else if ( cp == 0x1E6A ) { rdfstore_utf8_cp_to_utf8( 0x1E6B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH DOT ABOVE */
			else if ( cp == 0x1E6C ) { rdfstore_utf8_cp_to_utf8( 0x1E6D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH DOT BELOW */
			else if ( cp == 0x1E6E ) { rdfstore_utf8_cp_to_utf8( 0x1E6F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH LINE BELOW */
			else if ( cp == 0x1E70 ) { rdfstore_utf8_cp_to_utf8( 0x1E71, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER T WITH CIRCUMFLEX BELOW */
			else if ( cp == 0x1E72 ) { rdfstore_utf8_cp_to_utf8( 0x1E73, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH DIAERESIS BELOW */
			else if ( cp == 0x1E74 ) { rdfstore_utf8_cp_to_utf8( 0x1E75, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH TILDE BELOW */
			else if ( cp == 0x1E76 ) { rdfstore_utf8_cp_to_utf8( 0x1E77, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH CIRCUMFLEX BELOW */
			else if ( cp == 0x1E78 ) { rdfstore_utf8_cp_to_utf8( 0x1E79, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH TILDE AND ACUTE */
			else if ( cp == 0x1E7A ) { rdfstore_utf8_cp_to_utf8( 0x1E7B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH MACRON AND DIAERESIS */
			else if ( cp == 0x1E7C ) { rdfstore_utf8_cp_to_utf8( 0x1E7D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER V WITH TILDE */
			else if ( cp == 0x1E7E ) { rdfstore_utf8_cp_to_utf8( 0x1E7F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER V WITH DOT BELOW */
			else if ( cp == 0x1E80 ) { rdfstore_utf8_cp_to_utf8( 0x1E81, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER W WITH GRAVE */
			else if ( cp == 0x1E82 ) { rdfstore_utf8_cp_to_utf8( 0x1E83, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER W WITH ACUTE */
			else if ( cp == 0x1E84 ) { rdfstore_utf8_cp_to_utf8( 0x1E85, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER W WITH DIAERESIS */
			else if ( cp == 0x1E86 ) { rdfstore_utf8_cp_to_utf8( 0x1E87, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER W WITH DOT ABOVE */
			else if ( cp == 0x1E88 ) { rdfstore_utf8_cp_to_utf8( 0x1E89, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER W WITH DOT BELOW */
			else if ( cp == 0x1E8A ) { rdfstore_utf8_cp_to_utf8( 0x1E8B, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER X WITH DOT ABOVE */
			else if ( cp == 0x1E8C ) { rdfstore_utf8_cp_to_utf8( 0x1E8D, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER X WITH DIAERESIS */
			else if ( cp == 0x1E8E ) { rdfstore_utf8_cp_to_utf8( 0x1E8F, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH DOT ABOVE */
			else if ( cp == 0x1E90 ) { rdfstore_utf8_cp_to_utf8( 0x1E91, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Z WITH CIRCUMFLEX */
			else if ( cp == 0x1E92 ) { rdfstore_utf8_cp_to_utf8( 0x1E93, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Z WITH DOT BELOW */
			else if ( cp == 0x1E94 ) { rdfstore_utf8_cp_to_utf8( 0x1E95, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Z WITH LINE BELOW */
			else if ( cp == 0x1E96 ) { rdfstore_utf8_cp_to_utf8( 0x0068, &utf8_size, utf8_buff );   /*  LATIN SMALL LETTER H WITH LINE BELOW */
			                           rdfstore_utf8_cp_to_utf8( 0x0331, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1E97 ) { rdfstore_utf8_cp_to_utf8( 0x0074, &utf8_size, utf8_buff );   /*  LATIN SMALL LETTER T WITH DIAERESIS */
			                           rdfstore_utf8_cp_to_utf8( 0x0308, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1E98 ) { rdfstore_utf8_cp_to_utf8( 0x0077, &utf8_size, utf8_buff );   /*  LATIN SMALL LETTER W WITH RING ABOVE */
			                           rdfstore_utf8_cp_to_utf8( 0x030A, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1E99 ) { rdfstore_utf8_cp_to_utf8( 0x0079, &utf8_size, utf8_buff );   /*  LATIN SMALL LETTER Y WITH RING ABOVE */
			                           rdfstore_utf8_cp_to_utf8( 0x030A, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1E9A ) { rdfstore_utf8_cp_to_utf8( 0x0061, &utf8_size, utf8_buff );   /*  LATIN SMALL LETTER A WITH RIGHT HALF RING */
			                           rdfstore_utf8_cp_to_utf8( 0x02BE, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1E9B ) { rdfstore_utf8_cp_to_utf8( 0x1E61, &utf8_size, utf8_buff ); } /*  LATIN SMALL LETTER LONG S WITH DOT ABOVE */
			else if ( cp == 0x1EA0 ) { rdfstore_utf8_cp_to_utf8( 0x1EA1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH DOT BELOW */
			else if ( cp == 0x1EA2 ) { rdfstore_utf8_cp_to_utf8( 0x1EA3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH HOOK ABOVE */
			else if ( cp == 0x1EA4 ) { rdfstore_utf8_cp_to_utf8( 0x1EA5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH CIRCUMFLEX AND ACUTE */
			else if ( cp == 0x1EA6 ) { rdfstore_utf8_cp_to_utf8( 0x1EA7, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH CIRCUMFLEX AND GRAVE */
			else if ( cp == 0x1EA8 ) { rdfstore_utf8_cp_to_utf8( 0x1EA9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH CIRCUMFLEX AND HOOK ABOVE */
			else if ( cp == 0x1EAA ) { rdfstore_utf8_cp_to_utf8( 0x1EAB, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH CIRCUMFLEX AND TILDE */
			else if ( cp == 0x1EAC ) { rdfstore_utf8_cp_to_utf8( 0x1EAD, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH CIRCUMFLEX AND DOT BELOW */
			else if ( cp == 0x1EAE ) { rdfstore_utf8_cp_to_utf8( 0x1EAF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH BREVE AND ACUTE */
			else if ( cp == 0x1EB0 ) { rdfstore_utf8_cp_to_utf8( 0x1EB1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH BREVE AND GRAVE */
			else if ( cp == 0x1EB2 ) { rdfstore_utf8_cp_to_utf8( 0x1EB3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH BREVE AND HOOK ABOVE */
			else if ( cp == 0x1EB4 ) { rdfstore_utf8_cp_to_utf8( 0x1EB5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH BREVE AND TILDE */
			else if ( cp == 0x1EB6 ) { rdfstore_utf8_cp_to_utf8( 0x1EB7, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER A WITH BREVE AND DOT BELOW */
			else if ( cp == 0x1EB8 ) { rdfstore_utf8_cp_to_utf8( 0x1EB9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH DOT BELOW */
			else if ( cp == 0x1EBA ) { rdfstore_utf8_cp_to_utf8( 0x1EBB, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH HOOK ABOVE */
			else if ( cp == 0x1EBC ) { rdfstore_utf8_cp_to_utf8( 0x1EBD, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH TILDE */
			else if ( cp == 0x1EBE ) { rdfstore_utf8_cp_to_utf8( 0x1EBF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CIRCUMFLEX AND ACUTE */
			else if ( cp == 0x1EC0 ) { rdfstore_utf8_cp_to_utf8( 0x1EC1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CIRCUMFLEX AND GRAVE */
			else if ( cp == 0x1EC2 ) { rdfstore_utf8_cp_to_utf8( 0x1EC3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CIRCUMFLEX AND HOOK ABOVE */
			else if ( cp == 0x1EC4 ) { rdfstore_utf8_cp_to_utf8( 0x1EC5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CIRCUMFLEX AND TILDE */
			else if ( cp == 0x1EC6 ) { rdfstore_utf8_cp_to_utf8( 0x1EC7, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER E WITH CIRCUMFLEX AND DOT BELOW */
			else if ( cp == 0x1EC8 ) { rdfstore_utf8_cp_to_utf8( 0x1EC9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH HOOK ABOVE */
			else if ( cp == 0x1ECA ) { rdfstore_utf8_cp_to_utf8( 0x1ECB, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER I WITH DOT BELOW */
			else if ( cp == 0x1ECC ) { rdfstore_utf8_cp_to_utf8( 0x1ECD, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH DOT BELOW */
			else if ( cp == 0x1ECE ) { rdfstore_utf8_cp_to_utf8( 0x1ECF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH HOOK ABOVE */
			else if ( cp == 0x1ED0 ) { rdfstore_utf8_cp_to_utf8( 0x1ED1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH CIRCUMFLEX AND ACUTE */
			else if ( cp == 0x1ED2 ) { rdfstore_utf8_cp_to_utf8( 0x1ED3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH CIRCUMFLEX AND GRAVE */
			else if ( cp == 0x1ED4 ) { rdfstore_utf8_cp_to_utf8( 0x1ED5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH CIRCUMFLEX AND HOOK ABOVE */
			else if ( cp == 0x1ED6 ) { rdfstore_utf8_cp_to_utf8( 0x1ED7, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH CIRCUMFLEX AND TILDE */
			else if ( cp == 0x1ED8 ) { rdfstore_utf8_cp_to_utf8( 0x1ED9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH CIRCUMFLEX AND DOT BELOW */
			else if ( cp == 0x1EDA ) { rdfstore_utf8_cp_to_utf8( 0x1EDB, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH HORN AND ACUTE */
			else if ( cp == 0x1EDC ) { rdfstore_utf8_cp_to_utf8( 0x1EDD, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH HORN AND GRAVE */
			else if ( cp == 0x1EDE ) { rdfstore_utf8_cp_to_utf8( 0x1EDF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH HORN AND HOOK ABOVE */
			else if ( cp == 0x1EE0 ) { rdfstore_utf8_cp_to_utf8( 0x1EE1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH HORN AND TILDE */
			else if ( cp == 0x1EE2 ) { rdfstore_utf8_cp_to_utf8( 0x1EE3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER O WITH HORN AND DOT BELOW */
			else if ( cp == 0x1EE4 ) { rdfstore_utf8_cp_to_utf8( 0x1EE5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH DOT BELOW */
			else if ( cp == 0x1EE6 ) { rdfstore_utf8_cp_to_utf8( 0x1EE7, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH HOOK ABOVE */
			else if ( cp == 0x1EE8 ) { rdfstore_utf8_cp_to_utf8( 0x1EE9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH HORN AND ACUTE */
			else if ( cp == 0x1EEA ) { rdfstore_utf8_cp_to_utf8( 0x1EEB, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH HORN AND GRAVE */
			else if ( cp == 0x1EEC ) { rdfstore_utf8_cp_to_utf8( 0x1EED, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH HORN AND HOOK ABOVE */
			else if ( cp == 0x1EEE ) { rdfstore_utf8_cp_to_utf8( 0x1EEF, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH HORN AND TILDE */
			else if ( cp == 0x1EF0 ) { rdfstore_utf8_cp_to_utf8( 0x1EF1, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER U WITH HORN AND DOT BELOW */
			else if ( cp == 0x1EF2 ) { rdfstore_utf8_cp_to_utf8( 0x1EF3, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH GRAVE */
			else if ( cp == 0x1EF4 ) { rdfstore_utf8_cp_to_utf8( 0x1EF5, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH DOT BELOW */
			else if ( cp == 0x1EF6 ) { rdfstore_utf8_cp_to_utf8( 0x1EF7, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH HOOK ABOVE */
			else if ( cp == 0x1EF8 ) { rdfstore_utf8_cp_to_utf8( 0x1EF9, &utf8_size, utf8_buff ); } /*  LATIN CAPITAL LETTER Y WITH TILDE */
			else if ( cp == 0x1F08 ) { rdfstore_utf8_cp_to_utf8( 0x1F00, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH PSILI */
			else if ( cp == 0x1F09 ) { rdfstore_utf8_cp_to_utf8( 0x1F01, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH DASIA */
			else if ( cp == 0x1F0A ) { rdfstore_utf8_cp_to_utf8( 0x1F02, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH PSILI AND VARIA */
			else if ( cp == 0x1F0B ) { rdfstore_utf8_cp_to_utf8( 0x1F03, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH DASIA AND VARIA */
			else if ( cp == 0x1F0C ) { rdfstore_utf8_cp_to_utf8( 0x1F04, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH PSILI AND OXIA */
			else if ( cp == 0x1F0D ) { rdfstore_utf8_cp_to_utf8( 0x1F05, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH DASIA AND OXIA */
			else if ( cp == 0x1F0E ) { rdfstore_utf8_cp_to_utf8( 0x1F06, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH PSILI AND PERISPOMENI */
			else if ( cp == 0x1F0F ) { rdfstore_utf8_cp_to_utf8( 0x1F07, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH DASIA AND PERISPOMENI */
			else if ( cp == 0x1F18 ) { rdfstore_utf8_cp_to_utf8( 0x1F10, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON WITH PSILI */
			else if ( cp == 0x1F19 ) { rdfstore_utf8_cp_to_utf8( 0x1F11, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON WITH DASIA */
			else if ( cp == 0x1F1A ) { rdfstore_utf8_cp_to_utf8( 0x1F12, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON WITH PSILI AND VARIA */
			else if ( cp == 0x1F1B ) { rdfstore_utf8_cp_to_utf8( 0x1F13, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON WITH DASIA AND VARIA */
			else if ( cp == 0x1F1C ) { rdfstore_utf8_cp_to_utf8( 0x1F14, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON WITH PSILI AND OXIA */
			else if ( cp == 0x1F1D ) { rdfstore_utf8_cp_to_utf8( 0x1F15, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON WITH DASIA AND OXIA */
			else if ( cp == 0x1F28 ) { rdfstore_utf8_cp_to_utf8( 0x1F20, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH PSILI */
			else if ( cp == 0x1F29 ) { rdfstore_utf8_cp_to_utf8( 0x1F21, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH DASIA */
			else if ( cp == 0x1F2A ) { rdfstore_utf8_cp_to_utf8( 0x1F22, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH PSILI AND VARIA */
			else if ( cp == 0x1F2B ) { rdfstore_utf8_cp_to_utf8( 0x1F23, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH DASIA AND VARIA */
			else if ( cp == 0x1F2C ) { rdfstore_utf8_cp_to_utf8( 0x1F24, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH PSILI AND OXIA */
			else if ( cp == 0x1F2D ) { rdfstore_utf8_cp_to_utf8( 0x1F25, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH DASIA AND OXIA */
			else if ( cp == 0x1F2E ) { rdfstore_utf8_cp_to_utf8( 0x1F26, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH PSILI AND PERISPOMENI */
			else if ( cp == 0x1F2F ) { rdfstore_utf8_cp_to_utf8( 0x1F27, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH DASIA AND PERISPOMENI */
			else if ( cp == 0x1F38 ) { rdfstore_utf8_cp_to_utf8( 0x1F30, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH PSILI */
			else if ( cp == 0x1F39 ) { rdfstore_utf8_cp_to_utf8( 0x1F31, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH DASIA */
			else if ( cp == 0x1F3A ) { rdfstore_utf8_cp_to_utf8( 0x1F32, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH PSILI AND VARIA */
			else if ( cp == 0x1F3B ) { rdfstore_utf8_cp_to_utf8( 0x1F33, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH DASIA AND VARIA */
			else if ( cp == 0x1F3C ) { rdfstore_utf8_cp_to_utf8( 0x1F34, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH PSILI AND OXIA */
			else if ( cp == 0x1F3D ) { rdfstore_utf8_cp_to_utf8( 0x1F35, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH DASIA AND OXIA */
			else if ( cp == 0x1F3E ) { rdfstore_utf8_cp_to_utf8( 0x1F36, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH PSILI AND PERISPOMENI */
			else if ( cp == 0x1F3F ) { rdfstore_utf8_cp_to_utf8( 0x1F37, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH DASIA AND PERISPOMENI */
			else if ( cp == 0x1F48 ) { rdfstore_utf8_cp_to_utf8( 0x1F40, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON WITH PSILI */
			else if ( cp == 0x1F49 ) { rdfstore_utf8_cp_to_utf8( 0x1F41, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON WITH DASIA */
			else if ( cp == 0x1F4A ) { rdfstore_utf8_cp_to_utf8( 0x1F42, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON WITH PSILI AND VARIA */
			else if ( cp == 0x1F4B ) { rdfstore_utf8_cp_to_utf8( 0x1F43, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON WITH DASIA AND VARIA */
			else if ( cp == 0x1F4C ) { rdfstore_utf8_cp_to_utf8( 0x1F44, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON WITH PSILI AND OXIA */
			else if ( cp == 0x1F4D ) { rdfstore_utf8_cp_to_utf8( 0x1F45, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON WITH DASIA AND OXIA */
			else if ( cp == 0x1F50 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER UPSILON WITH PSILI */
			                           rdfstore_utf8_cp_to_utf8( 0x0313, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F52 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER UPSILON WITH PSILI AND VARIA */
			                           rdfstore_utf8_cp_to_utf8( 0x0313, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0300, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F54 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER UPSILON WITH PSILI AND OXIA */
			                           rdfstore_utf8_cp_to_utf8( 0x0313, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0301, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F56 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER UPSILON WITH PSILI AND PERISPOMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0313, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F59 ) { rdfstore_utf8_cp_to_utf8( 0x1F51, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH DASIA */
			else if ( cp == 0x1F5B ) { rdfstore_utf8_cp_to_utf8( 0x1F53, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH DASIA AND VARIA */
			else if ( cp == 0x1F5D ) { rdfstore_utf8_cp_to_utf8( 0x1F55, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH DASIA AND OXIA */
			else if ( cp == 0x1F5F ) { rdfstore_utf8_cp_to_utf8( 0x1F57, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH DASIA AND PERISPOMENI */
			else if ( cp == 0x1F68 ) { rdfstore_utf8_cp_to_utf8( 0x1F60, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH PSILI */
			else if ( cp == 0x1F69 ) { rdfstore_utf8_cp_to_utf8( 0x1F61, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH DASIA */
			else if ( cp == 0x1F6A ) { rdfstore_utf8_cp_to_utf8( 0x1F62, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH PSILI AND VARIA */
			else if ( cp == 0x1F6B ) { rdfstore_utf8_cp_to_utf8( 0x1F63, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH DASIA AND VARIA */
			else if ( cp == 0x1F6C ) { rdfstore_utf8_cp_to_utf8( 0x1F64, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH PSILI AND OXIA */
			else if ( cp == 0x1F6D ) { rdfstore_utf8_cp_to_utf8( 0x1F65, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH DASIA AND OXIA */
			else if ( cp == 0x1F6E ) { rdfstore_utf8_cp_to_utf8( 0x1F66, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH PSILI AND PERISPOMENI */
			else if ( cp == 0x1F6F ) { rdfstore_utf8_cp_to_utf8( 0x1F67, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH DASIA AND PERISPOMENI */
			else if ( cp == 0x1F80 ) { rdfstore_utf8_cp_to_utf8( 0x1F00, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH PSILI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F81 ) { rdfstore_utf8_cp_to_utf8( 0x1F01, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH DASIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F82 ) { rdfstore_utf8_cp_to_utf8( 0x1F02, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH PSILI AND VARIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F83 ) { rdfstore_utf8_cp_to_utf8( 0x1F03, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH DASIA AND VARIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F84 ) { rdfstore_utf8_cp_to_utf8( 0x1F04, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH PSILI AND OXIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F85 ) { rdfstore_utf8_cp_to_utf8( 0x1F05, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH DASIA AND OXIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F86 ) { rdfstore_utf8_cp_to_utf8( 0x1F06, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH PSILI AND PERISPOMENI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F87 ) { rdfstore_utf8_cp_to_utf8( 0x1F07, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH DASIA AND PERISPOMENI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F88 ) { rdfstore_utf8_cp_to_utf8( 0x1F00, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ALPHA WITH PSILI AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F89 ) { rdfstore_utf8_cp_to_utf8( 0x1F01, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ALPHA WITH DASIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F8A ) { rdfstore_utf8_cp_to_utf8( 0x1F02, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ALPHA WITH PSILI AND VARIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F8B ) { rdfstore_utf8_cp_to_utf8( 0x1F03, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ALPHA WITH DASIA AND VARIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F8C ) { rdfstore_utf8_cp_to_utf8( 0x1F04, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ALPHA WITH PSILI AND OXIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F8D ) { rdfstore_utf8_cp_to_utf8( 0x1F05, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ALPHA WITH DASIA AND OXIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F8E ) { rdfstore_utf8_cp_to_utf8( 0x1F06, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ALPHA WITH PSILI AND PERISPOMENI AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F8F ) { rdfstore_utf8_cp_to_utf8( 0x1F07, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ALPHA WITH DASIA AND PERISPOMENI AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F90 ) { rdfstore_utf8_cp_to_utf8( 0x1F20, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH PSILI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F91 ) { rdfstore_utf8_cp_to_utf8( 0x1F21, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH DASIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F92 ) { rdfstore_utf8_cp_to_utf8( 0x1F22, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH PSILI AND VARIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F93 ) { rdfstore_utf8_cp_to_utf8( 0x1F23, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH DASIA AND VARIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F94 ) { rdfstore_utf8_cp_to_utf8( 0x1F24, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH PSILI AND OXIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F95 ) { rdfstore_utf8_cp_to_utf8( 0x1F25, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH DASIA AND OXIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F96 ) { rdfstore_utf8_cp_to_utf8( 0x1F26, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH PSILI AND PERISPOMENI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F97 ) { rdfstore_utf8_cp_to_utf8( 0x1F27, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH DASIA AND PERISPOMENI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F98 ) { rdfstore_utf8_cp_to_utf8( 0x1F20, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ETA WITH PSILI AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F99 ) { rdfstore_utf8_cp_to_utf8( 0x1F21, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ETA WITH DASIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F9A ) { rdfstore_utf8_cp_to_utf8( 0x1F22, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ETA WITH PSILI AND VARIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F9B ) { rdfstore_utf8_cp_to_utf8( 0x1F23, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ETA WITH DASIA AND VARIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F9C ) { rdfstore_utf8_cp_to_utf8( 0x1F24, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ETA WITH PSILI AND OXIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F9D ) { rdfstore_utf8_cp_to_utf8( 0x1F25, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ETA WITH DASIA AND OXIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F9E ) { rdfstore_utf8_cp_to_utf8( 0x1F26, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ETA WITH PSILI AND PERISPOMENI AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1F9F ) { rdfstore_utf8_cp_to_utf8( 0x1F27, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ETA WITH DASIA AND PERISPOMENI AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA0 ) { rdfstore_utf8_cp_to_utf8( 0x1F60, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH PSILI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA1 ) { rdfstore_utf8_cp_to_utf8( 0x1F61, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH DASIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA2 ) { rdfstore_utf8_cp_to_utf8( 0x1F62, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH PSILI AND VARIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA3 ) { rdfstore_utf8_cp_to_utf8( 0x1F63, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH DASIA AND VARIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA4 ) { rdfstore_utf8_cp_to_utf8( 0x1F64, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH PSILI AND OXIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA5 ) { rdfstore_utf8_cp_to_utf8( 0x1F65, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH DASIA AND OXIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA6 ) { rdfstore_utf8_cp_to_utf8( 0x1F66, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH PSILI AND PERISPOMENI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA7 ) { rdfstore_utf8_cp_to_utf8( 0x1F67, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH DASIA AND PERISPOMENI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA8 ) { rdfstore_utf8_cp_to_utf8( 0x1F60, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER OMEGA WITH PSILI AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FA9 ) { rdfstore_utf8_cp_to_utf8( 0x1F61, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER OMEGA WITH DASIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FAA ) { rdfstore_utf8_cp_to_utf8( 0x1F62, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER OMEGA WITH PSILI AND VARIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FAB ) { rdfstore_utf8_cp_to_utf8( 0x1F63, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER OMEGA WITH DASIA AND VARIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FAC ) { rdfstore_utf8_cp_to_utf8( 0x1F64, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER OMEGA WITH PSILI AND OXIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FAD ) { rdfstore_utf8_cp_to_utf8( 0x1F65, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER OMEGA WITH DASIA AND OXIA AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FAE ) { rdfstore_utf8_cp_to_utf8( 0x1F66, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER OMEGA WITH PSILI AND PERISPOMENI AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FAF ) { rdfstore_utf8_cp_to_utf8( 0x1F67, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER OMEGA WITH DASIA AND PERISPOMENI AND PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FB2 ) { rdfstore_utf8_cp_to_utf8( 0x1F70, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH VARIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FB3 ) { rdfstore_utf8_cp_to_utf8( 0x03B1, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FB4 ) { rdfstore_utf8_cp_to_utf8( 0x03AC, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH OXIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FB6 ) { rdfstore_utf8_cp_to_utf8( 0x03B1, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH PERISPOMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FB7 ) { rdfstore_utf8_cp_to_utf8( 0x03B1, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ALPHA WITH PERISPOMENI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FB8 ) { rdfstore_utf8_cp_to_utf8( 0x1FB0, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH VRACHY */
			else if ( cp == 0x1FB9 ) { rdfstore_utf8_cp_to_utf8( 0x1FB1, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH MACRON */
			else if ( cp == 0x1FBA ) { rdfstore_utf8_cp_to_utf8( 0x1F70, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH VARIA */
			else if ( cp == 0x1FBB ) { rdfstore_utf8_cp_to_utf8( 0x1F71, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ALPHA WITH OXIA */
			else if ( cp == 0x1FBC ) { rdfstore_utf8_cp_to_utf8( 0x03B1, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ALPHA WITH PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FBE ) { rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); } /*  GREEK PROSGEGRAMMENI */
			else if ( cp == 0x1FC2 ) { rdfstore_utf8_cp_to_utf8( 0x1F74, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH VARIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FC3 ) { rdfstore_utf8_cp_to_utf8( 0x03B7, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FC4 ) { rdfstore_utf8_cp_to_utf8( 0x03AE, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH OXIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FC6 ) { rdfstore_utf8_cp_to_utf8( 0x03B7, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH PERISPOMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FC7 ) { rdfstore_utf8_cp_to_utf8( 0x03B7, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER ETA WITH PERISPOMENI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FC8 ) { rdfstore_utf8_cp_to_utf8( 0x1F72, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON WITH VARIA */
			else if ( cp == 0x1FC9 ) { rdfstore_utf8_cp_to_utf8( 0x1F73, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER EPSILON WITH OXIA */
			else if ( cp == 0x1FCA ) { rdfstore_utf8_cp_to_utf8( 0x1F74, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH VARIA */
			else if ( cp == 0x1FCB ) { rdfstore_utf8_cp_to_utf8( 0x1F75, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER ETA WITH OXIA */
			else if ( cp == 0x1FCC ) { rdfstore_utf8_cp_to_utf8( 0x03B7, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER ETA WITH PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FD2 ) { rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER IOTA WITH DIALYTIKA AND VARIA */
			                           rdfstore_utf8_cp_to_utf8( 0x0308, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0300, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FD3 ) { rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER IOTA WITH DIALYTIKA AND OXIA */
			                           rdfstore_utf8_cp_to_utf8( 0x0308, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0301, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FD6 ) { rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER IOTA WITH PERISPOMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FD7 ) { rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER IOTA WITH DIALYTIKA AND PERISPOMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0308, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FD8 ) { rdfstore_utf8_cp_to_utf8( 0x1FD0, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH VRACHY */
			else if ( cp == 0x1FD9 ) { rdfstore_utf8_cp_to_utf8( 0x1FD1, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH MACRON */
			else if ( cp == 0x1FDA ) { rdfstore_utf8_cp_to_utf8( 0x1F76, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH VARIA */
			else if ( cp == 0x1FDB ) { rdfstore_utf8_cp_to_utf8( 0x1F77, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER IOTA WITH OXIA */
			else if ( cp == 0x1FE2 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND VARIA */
			                           rdfstore_utf8_cp_to_utf8( 0x0308, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0300, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FE3 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND OXIA */
			                           rdfstore_utf8_cp_to_utf8( 0x0308, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0301, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FE4 ) { rdfstore_utf8_cp_to_utf8( 0x03C1, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER RHO WITH PSILI */
			                           rdfstore_utf8_cp_to_utf8( 0x0313, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FE6 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER UPSILON WITH PERISPOMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FE7 ) { rdfstore_utf8_cp_to_utf8( 0x03C5, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND PERISPOMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0308, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FE8 ) { rdfstore_utf8_cp_to_utf8( 0x1FE0, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH VRACHY */
			else if ( cp == 0x1FE9 ) { rdfstore_utf8_cp_to_utf8( 0x1FE1, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH MACRON */
			else if ( cp == 0x1FEA ) { rdfstore_utf8_cp_to_utf8( 0x1F7A, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH VARIA */
			else if ( cp == 0x1FEB ) { rdfstore_utf8_cp_to_utf8( 0x1F7B, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER UPSILON WITH OXIA */
			else if ( cp == 0x1FEC ) { rdfstore_utf8_cp_to_utf8( 0x1FE5, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER RHO WITH DASIA */
			else if ( cp == 0x1FF2 ) { rdfstore_utf8_cp_to_utf8( 0x1F7C, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH VARIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FF3 ) { rdfstore_utf8_cp_to_utf8( 0x03C9, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FF4 ) { rdfstore_utf8_cp_to_utf8( 0x03CE, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH OXIA AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FF6 ) { rdfstore_utf8_cp_to_utf8( 0x03C9, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH PERISPOMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FF7 ) { rdfstore_utf8_cp_to_utf8( 0x03C9, &utf8_size, utf8_buff );   /*  GREEK SMALL LETTER OMEGA WITH PERISPOMENI AND YPOGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x0342, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x1FF8 ) { rdfstore_utf8_cp_to_utf8( 0x1F78, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON WITH VARIA */
			else if ( cp == 0x1FF9 ) { rdfstore_utf8_cp_to_utf8( 0x1F79, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMICRON WITH OXIA */
			else if ( cp == 0x1FFA ) { rdfstore_utf8_cp_to_utf8( 0x1F7C, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH VARIA */
			else if ( cp == 0x1FFB ) { rdfstore_utf8_cp_to_utf8( 0x1F7D, &utf8_size, utf8_buff ); } /*  GREEK CAPITAL LETTER OMEGA WITH OXIA */
			else if ( cp == 0x1FFC ) { rdfstore_utf8_cp_to_utf8( 0x03C9, &utf8_size, utf8_buff );   /*  GREEK CAPITAL LETTER OMEGA WITH PROSGEGRAMMENI */
			                           rdfstore_utf8_cp_to_utf8( 0x03B9, &utf8_size, utf8_buff ); }
			else if ( cp == 0x2126 ) { rdfstore_utf8_cp_to_utf8( 0x03C9, &utf8_size, utf8_buff ); } /*  OHM SIGN */
			else if ( cp == 0x212A ) { rdfstore_utf8_cp_to_utf8( 0x006B, &utf8_size, utf8_buff ); } /*  KELVIN SIGN */
			else if ( cp == 0x212B ) { rdfstore_utf8_cp_to_utf8( 0x00E5, &utf8_size, utf8_buff ); } /*  ANGSTROM SIGN */
			else if ( cp == 0x2160 ) { rdfstore_utf8_cp_to_utf8( 0x2170, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL ONE */
			else if ( cp == 0x2161 ) { rdfstore_utf8_cp_to_utf8( 0x2171, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL TWO */
			else if ( cp == 0x2162 ) { rdfstore_utf8_cp_to_utf8( 0x2172, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL THREE */
			else if ( cp == 0x2163 ) { rdfstore_utf8_cp_to_utf8( 0x2173, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL FOUR */
			else if ( cp == 0x2164 ) { rdfstore_utf8_cp_to_utf8( 0x2174, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL FIVE */
			else if ( cp == 0x2165 ) { rdfstore_utf8_cp_to_utf8( 0x2175, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL SIX */
			else if ( cp == 0x2166 ) { rdfstore_utf8_cp_to_utf8( 0x2176, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL SEVEN */
			else if ( cp == 0x2167 ) { rdfstore_utf8_cp_to_utf8( 0x2177, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL EIGHT */
			else if ( cp == 0x2168 ) { rdfstore_utf8_cp_to_utf8( 0x2178, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL NINE */
			else if ( cp == 0x2169 ) { rdfstore_utf8_cp_to_utf8( 0x2179, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL TEN */
			else if ( cp == 0x216A ) { rdfstore_utf8_cp_to_utf8( 0x217A, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL ELEVEN */
			else if ( cp == 0x216B ) { rdfstore_utf8_cp_to_utf8( 0x217B, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL TWELVE */
			else if ( cp == 0x216C ) { rdfstore_utf8_cp_to_utf8( 0x217C, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL FIFTY */
			else if ( cp == 0x216D ) { rdfstore_utf8_cp_to_utf8( 0x217D, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL ONE HUNDRED */
			else if ( cp == 0x216E ) { rdfstore_utf8_cp_to_utf8( 0x217E, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL FIVE HUNDRED */
			else if ( cp == 0x216F ) { rdfstore_utf8_cp_to_utf8( 0x217F, &utf8_size, utf8_buff ); } /*  ROMAN NUMERAL ONE THOUSAND */
			else if ( cp == 0x24B6 ) { rdfstore_utf8_cp_to_utf8( 0x24D0, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER A */
			else if ( cp == 0x24B7 ) { rdfstore_utf8_cp_to_utf8( 0x24D1, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER B */
			else if ( cp == 0x24B8 ) { rdfstore_utf8_cp_to_utf8( 0x24D2, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER C */
			else if ( cp == 0x24B9 ) { rdfstore_utf8_cp_to_utf8( 0x24D3, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER D */
			else if ( cp == 0x24BA ) { rdfstore_utf8_cp_to_utf8( 0x24D4, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER E */
			else if ( cp == 0x24BB ) { rdfstore_utf8_cp_to_utf8( 0x24D5, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER F */
			else if ( cp == 0x24BC ) { rdfstore_utf8_cp_to_utf8( 0x24D6, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER G */
			else if ( cp == 0x24BD ) { rdfstore_utf8_cp_to_utf8( 0x24D7, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER H */
			else if ( cp == 0x24BE ) { rdfstore_utf8_cp_to_utf8( 0x24D8, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER I */
			else if ( cp == 0x24BF ) { rdfstore_utf8_cp_to_utf8( 0x24D9, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER J */
			else if ( cp == 0x24C0 ) { rdfstore_utf8_cp_to_utf8( 0x24DA, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER K */
			else if ( cp == 0x24C1 ) { rdfstore_utf8_cp_to_utf8( 0x24DB, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER L */
			else if ( cp == 0x24C2 ) { rdfstore_utf8_cp_to_utf8( 0x24DC, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER M */
			else if ( cp == 0x24C3 ) { rdfstore_utf8_cp_to_utf8( 0x24DD, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER N */
			else if ( cp == 0x24C4 ) { rdfstore_utf8_cp_to_utf8( 0x24DE, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER O */
			else if ( cp == 0x24C5 ) { rdfstore_utf8_cp_to_utf8( 0x24DF, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER P */
			else if ( cp == 0x24C6 ) { rdfstore_utf8_cp_to_utf8( 0x24E0, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER Q */
			else if ( cp == 0x24C7 ) { rdfstore_utf8_cp_to_utf8( 0x24E1, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER R */
			else if ( cp == 0x24C8 ) { rdfstore_utf8_cp_to_utf8( 0x24E2, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER S */
			else if ( cp == 0x24C9 ) { rdfstore_utf8_cp_to_utf8( 0x24E3, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER T */
			else if ( cp == 0x24CA ) { rdfstore_utf8_cp_to_utf8( 0x24E4, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER U */
			else if ( cp == 0x24CB ) { rdfstore_utf8_cp_to_utf8( 0x24E5, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER V */
			else if ( cp == 0x24CC ) { rdfstore_utf8_cp_to_utf8( 0x24E6, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER W */
			else if ( cp == 0x24CD ) { rdfstore_utf8_cp_to_utf8( 0x24E7, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER X */
			else if ( cp == 0x24CE ) { rdfstore_utf8_cp_to_utf8( 0x24E8, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER Y */
			else if ( cp == 0x24CF ) { rdfstore_utf8_cp_to_utf8( 0x24E9, &utf8_size, utf8_buff ); } /*  CIRCLED LATIN CAPITAL LETTER Z */
			else if ( cp == 0xFB00 ) { rdfstore_utf8_cp_to_utf8( 0x0066, &utf8_size, utf8_buff );   /*  LATIN SMALL LIGATURE FF */
			                           rdfstore_utf8_cp_to_utf8( 0x0066, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB01 ) { rdfstore_utf8_cp_to_utf8( 0x0066, &utf8_size, utf8_buff );   /*  LATIN SMALL LIGATURE FI */
			                           rdfstore_utf8_cp_to_utf8( 0x0069, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB02 ) { rdfstore_utf8_cp_to_utf8( 0x0066, &utf8_size, utf8_buff );   /*  LATIN SMALL LIGATURE FL */
			                           rdfstore_utf8_cp_to_utf8( 0x006C, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB03 ) { rdfstore_utf8_cp_to_utf8( 0x0066, &utf8_size, utf8_buff );   /*  LATIN SMALL LIGATURE FFI */
			                           rdfstore_utf8_cp_to_utf8( 0x0066, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x0069, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB04 ) { rdfstore_utf8_cp_to_utf8( 0x0066, &utf8_size, utf8_buff );   /*  LATIN SMALL LIGATURE FFL */
			                           rdfstore_utf8_cp_to_utf8( 0x0066, &utf8_size, utf8_buff );  
			                           rdfstore_utf8_cp_to_utf8( 0x006C, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB05 ) { rdfstore_utf8_cp_to_utf8( 0x0073, &utf8_size, utf8_buff );   /*  LATIN SMALL LIGATURE LONG S T */
			                           rdfstore_utf8_cp_to_utf8( 0x0074, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB06 ) { rdfstore_utf8_cp_to_utf8( 0x0073, &utf8_size, utf8_buff );   /*  LATIN SMALL LIGATURE ST */
			                           rdfstore_utf8_cp_to_utf8( 0x0074, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB13 ) { rdfstore_utf8_cp_to_utf8( 0x0574, &utf8_size, utf8_buff );   /*  ARMENIAN SMALL LIGATURE MEN NOW */
			                           rdfstore_utf8_cp_to_utf8( 0x0576, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB14 ) { rdfstore_utf8_cp_to_utf8( 0x0574, &utf8_size, utf8_buff );   /*  ARMENIAN SMALL LIGATURE MEN ECH */
			                           rdfstore_utf8_cp_to_utf8( 0x0565, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB15 ) { rdfstore_utf8_cp_to_utf8( 0x0574, &utf8_size, utf8_buff );   /*  ARMENIAN SMALL LIGATURE MEN INI */
			                           rdfstore_utf8_cp_to_utf8( 0x056B, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB16 ) { rdfstore_utf8_cp_to_utf8( 0x057E, &utf8_size, utf8_buff );   /*  ARMENIAN SMALL LIGATURE VEW NOW */
			                           rdfstore_utf8_cp_to_utf8( 0x0576, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFB17 ) { rdfstore_utf8_cp_to_utf8( 0x0574, &utf8_size, utf8_buff );   /*  ARMENIAN SMALL LIGATURE MEN XEH */
			                           rdfstore_utf8_cp_to_utf8( 0x056D, &utf8_size, utf8_buff ); }
			else if ( cp == 0xFF21 ) { rdfstore_utf8_cp_to_utf8( 0xFF41, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER A */
			else if ( cp == 0xFF22 ) { rdfstore_utf8_cp_to_utf8( 0xFF42, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER B */
			else if ( cp == 0xFF23 ) { rdfstore_utf8_cp_to_utf8( 0xFF43, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER C */
			else if ( cp == 0xFF24 ) { rdfstore_utf8_cp_to_utf8( 0xFF44, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER D */
			else if ( cp == 0xFF25 ) { rdfstore_utf8_cp_to_utf8( 0xFF45, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER E */
			else if ( cp == 0xFF26 ) { rdfstore_utf8_cp_to_utf8( 0xFF46, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER F */
			else if ( cp == 0xFF27 ) { rdfstore_utf8_cp_to_utf8( 0xFF47, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER G */
			else if ( cp == 0xFF28 ) { rdfstore_utf8_cp_to_utf8( 0xFF48, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER H */
			else if ( cp == 0xFF29 ) { rdfstore_utf8_cp_to_utf8( 0xFF49, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER I */
			else if ( cp == 0xFF2A ) { rdfstore_utf8_cp_to_utf8( 0xFF4A, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER J */
			else if ( cp == 0xFF2B ) { rdfstore_utf8_cp_to_utf8( 0xFF4B, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER K */
			else if ( cp == 0xFF2C ) { rdfstore_utf8_cp_to_utf8( 0xFF4C, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER L */
			else if ( cp == 0xFF2D ) { rdfstore_utf8_cp_to_utf8( 0xFF4D, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER M */
			else if ( cp == 0xFF2E ) { rdfstore_utf8_cp_to_utf8( 0xFF4E, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER N */
			else if ( cp == 0xFF2F ) { rdfstore_utf8_cp_to_utf8( 0xFF4F, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER O */
			else if ( cp == 0xFF30 ) { rdfstore_utf8_cp_to_utf8( 0xFF50, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER P */
			else if ( cp == 0xFF31 ) { rdfstore_utf8_cp_to_utf8( 0xFF51, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER Q */
			else if ( cp == 0xFF32 ) { rdfstore_utf8_cp_to_utf8( 0xFF52, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER R */
			else if ( cp == 0xFF33 ) { rdfstore_utf8_cp_to_utf8( 0xFF53, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER S */
			else if ( cp == 0xFF34 ) { rdfstore_utf8_cp_to_utf8( 0xFF54, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER T */
			else if ( cp == 0xFF35 ) { rdfstore_utf8_cp_to_utf8( 0xFF55, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER U */
			else if ( cp == 0xFF36 ) { rdfstore_utf8_cp_to_utf8( 0xFF56, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER V */
			else if ( cp == 0xFF37 ) { rdfstore_utf8_cp_to_utf8( 0xFF57, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER W */
			else if ( cp == 0xFF38 ) { rdfstore_utf8_cp_to_utf8( 0xFF58, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER X */
			else if ( cp == 0xFF39 ) { rdfstore_utf8_cp_to_utf8( 0xFF59, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER Y */
			else if ( cp == 0xFF3A ) { rdfstore_utf8_cp_to_utf8( 0xFF5A, &utf8_size, utf8_buff ); } /*  FULLWIDTH LATIN CAPITAL LETTER Z */
			else if ( cp == 0x10400 ) { rdfstore_utf8_cp_to_utf8( 0x10428, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER LONG I */
			else if ( cp == 0x10401 ) { rdfstore_utf8_cp_to_utf8( 0x10429, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER LONG E */
			else if ( cp == 0x10402 ) { rdfstore_utf8_cp_to_utf8( 0x1042A, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER LONG A */
			else if ( cp == 0x10403 ) { rdfstore_utf8_cp_to_utf8( 0x1042B, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER LONG AH */
			else if ( cp == 0x10404 ) { rdfstore_utf8_cp_to_utf8( 0x1042C, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER LONG O */
			else if ( cp == 0x10405 ) { rdfstore_utf8_cp_to_utf8( 0x1042D, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER LONG OO */
			else if ( cp == 0x10406 ) { rdfstore_utf8_cp_to_utf8( 0x1042E, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER SHORT I */
			else if ( cp == 0x10407 ) { rdfstore_utf8_cp_to_utf8( 0x1042F, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER SHORT E */
			else if ( cp == 0x10408 ) { rdfstore_utf8_cp_to_utf8( 0x10430, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER SHORT A */
			else if ( cp == 0x10409 ) { rdfstore_utf8_cp_to_utf8( 0x10431, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER SHORT AH */
			else if ( cp == 0x1040A ) { rdfstore_utf8_cp_to_utf8( 0x10432, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER SHORT O */
			else if ( cp == 0x1040B ) { rdfstore_utf8_cp_to_utf8( 0x10433, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER SHORT OO */
			else if ( cp == 0x1040C ) { rdfstore_utf8_cp_to_utf8( 0x10434, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER AY */
			else if ( cp == 0x1040D ) { rdfstore_utf8_cp_to_utf8( 0x10435, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER OW */
			else if ( cp == 0x1040E ) { rdfstore_utf8_cp_to_utf8( 0x10436, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER WU */
			else if ( cp == 0x1040F ) { rdfstore_utf8_cp_to_utf8( 0x10437, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER YEE */
			else if ( cp == 0x10410 ) { rdfstore_utf8_cp_to_utf8( 0x10438, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER H */
			else if ( cp == 0x10411 ) { rdfstore_utf8_cp_to_utf8( 0x10439, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER PEE */
			else if ( cp == 0x10412 ) { rdfstore_utf8_cp_to_utf8( 0x1043A, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER BEE */
			else if ( cp == 0x10413 ) { rdfstore_utf8_cp_to_utf8( 0x1043B, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER TEE */
			else if ( cp == 0x10414 ) { rdfstore_utf8_cp_to_utf8( 0x1043C, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER DEE */
			else if ( cp == 0x10415 ) { rdfstore_utf8_cp_to_utf8( 0x1043D, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER CHEE */
			else if ( cp == 0x10416 ) { rdfstore_utf8_cp_to_utf8( 0x1043E, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER JEE */
			else if ( cp == 0x10417 ) { rdfstore_utf8_cp_to_utf8( 0x1043F, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER KAY */
			else if ( cp == 0x10418 ) { rdfstore_utf8_cp_to_utf8( 0x10440, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER GAY */
			else if ( cp == 0x10419 ) { rdfstore_utf8_cp_to_utf8( 0x10441, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER EF */
			else if ( cp == 0x1041A ) { rdfstore_utf8_cp_to_utf8( 0x10442, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER VEE */
			else if ( cp == 0x1041B ) { rdfstore_utf8_cp_to_utf8( 0x10443, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER ETH */
			else if ( cp == 0x1041C ) { rdfstore_utf8_cp_to_utf8( 0x10444, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER THEE */
			else if ( cp == 0x1041D ) { rdfstore_utf8_cp_to_utf8( 0x10445, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER ES */
			else if ( cp == 0x1041E ) { rdfstore_utf8_cp_to_utf8( 0x10446, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER ZEE */
			else if ( cp == 0x1041F ) { rdfstore_utf8_cp_to_utf8( 0x10447, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER ESH */
			else if ( cp == 0x10420 ) { rdfstore_utf8_cp_to_utf8( 0x10448, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER ZHEE */
			else if ( cp == 0x10421 ) { rdfstore_utf8_cp_to_utf8( 0x10449, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER ER */
			else if ( cp == 0x10422 ) { rdfstore_utf8_cp_to_utf8( 0x1044A, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER EL */
			else if ( cp == 0x10423 ) { rdfstore_utf8_cp_to_utf8( 0x1044B, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER EM */
			else if ( cp == 0x10424 ) { rdfstore_utf8_cp_to_utf8( 0x1044C, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER EN */
			else if ( cp == 0x10425 ) { rdfstore_utf8_cp_to_utf8( 0x1044D, &utf8_size, utf8_buff ); } /*  DESERET CAPITAL LETTER ENG */

			memcpy(out+(*outsize),utf8_buff,utf8_size);
			(*outsize)+=utf8_size;
		};
	out[(*outsize)]='\0';

	return 0;
	};

/*
   convert an arbitrary bytes string to utf8 
   the output string is stored in outbuff and the length in len
*/
int rdfstore_utf8_string_to_utf8(
        int insize,
        unsigned char * in,
        int * outsize,
        unsigned char * out
	) {
	register unsigned int i,j,step=0;
	unsigned int utf8_size=0;
        unsigned char utf8_buff[RDFSTORE_UTF8_MAXLEN+1]; /* one utf8 char */

	(*outsize)=0;

        for(i=0,j=0; i<insize; i+=step) {
		if ( !( rdfstore_utf8_is_utf8( in+i, &utf8_size ) ) ) {
                	utf8_size=0;
			bzero(utf8_buff,RDFSTORE_UTF8_MAXLEN);
                	if ( rdfstore_utf8_cp_to_utf8( (unsigned long)in[i], &utf8_size, utf8_buff) ) {
				perror("rdfstore_utf8_string_to_utf8_foldedcase");
                        	fprintf(stderr,"Cannot convert input codepoint to utf8\n");
                        	return -1;
                        	};
#ifdef RDFSTORE_DEBUG_UTF8
			if(utf8_size>0) {
				int j=0;
				printf("Got converted to UTF8 char '%c / %02x' as '",in[i],in[i]);
				for (j=0; j< utf8_size; j++) {
					printf("%02x",utf8_buff[j]);
				};
				printf("'\n");
				};
#endif
			step=1; /* hop the next input byte */
		} else {
			bcopy(in+i,utf8_buff,utf8_size); /* copy the input utf8 char in the buff */
			step=utf8_size;
			};

		memcpy(out+(*outsize),utf8_buff,utf8_size);
		(*outsize)+=utf8_size;
		};
	out[(*outsize)]='\0';

	return 0;
	};
