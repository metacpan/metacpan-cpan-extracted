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
  * $Id: rdfstore_compress.c,v 1.12 2006/06/19 10:10:21 areggiori Exp $
  */

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <string.h>

#include "rdfstore_compress.h"
#include "sflcomp.h"
#include "my_compress.h"
#include "fraenkel_compress.h"

#define xross_map(name) \
	static void _ ## name (unsigned int srclen,unsigned char* src, unsigned int * dstlen, unsigned char * dst) \
	{ \
		* dstlen = name (src,dst,srclen); \
	}

#define xross_pair( name ) \
	xross_map( compress_ ## name ); \
	xross_map( expand_ ## name );

/* Build 5x2 functions to de- and en-code using the right arguments. 
 * XXX todo - remove those functions and edit the rdfstore_kernel.c functions
 *     to accept 'bcopy' style arguments.
 */
xross_pair( nulls );
xross_pair( bits );
xross_pair( block );
xross_pair( rle );
xross_pair( mine );
xross_pair( fraenkel );

static void _bcopy(unsigned int srclen,unsigned char* src, unsigned int * dstlen, unsigned char * dst)
{
	bcopy(src,dst,srclen);
	* dstlen = srclen;
};

#ifdef DEBUG_BDB_PAGESIZES
/* Fake compression method which will pad each record up to a specific
 * multiple of 2; such as 1024 - as to hide small size changes for
 * the BDB above.
 */
#define LOGSIZE (10)	/* 1024 */
static void _enc(unsigned int srclen,unsigned char* src, unsigned int * dstlen, unsigned char * dst)
{
	*(int *)dst = srclen;
	bcopy(src,dst+4,srclen);
	srclen = ((srclen >> LOGSIZE) + 1) << LOGSIZE;
	* dstlen = srclen;
};

static void _dec(unsigned int srclen,unsigned char* src, unsigned int * dstlen, unsigned char * dst)
{
	* dstlen = *(int *)src;
	bcopy(src,dst+4,srclen);
};
#endif

int rdfstore_compress_init(
	rdfstore_compression_types type, 
	void(**func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
	void(**func_encode)(unsigned int,unsigned char*, unsigned int *, unsigned char *)
) 
{
	if ((type == RDFSTORE_COMPRESSION_TYPE_DEFAULT) && 
		(getenv("RDFSTORE_COMPRESSION")) &&
		(atoi(getenv("RDFSTORE_COMPRESSION")))
		) {
		type = atoi(getenv("RDFSTORE_COMPRESSION"));
		fprintf(stderr,"Override type %d\n",type);
	}

	switch(type) {
#ifdef DEBUG_BDB_PAGESIZES
	case 999:
		*func_encode = &_enc;
		*func_decode = &_dec;
		break;
#endif
	case RDFSTORE_COMPRESSION_TYPE_NONE:
		*func_encode = &_bcopy;
		*func_decode = &_bcopy;
		break;
	case RDFSTORE_COMPRESSION_TYPE_BITS:
		*func_encode = &_compress_bits;
		*func_decode = &_expand_bits;
		break;
	case RDFSTORE_COMPRESSION_TYPE_BLOCK:
		*func_encode = &_compress_block;
		*func_decode = &_expand_block;
		break;
	case RDFSTORE_COMPRESSION_TYPE_RLE:
		*func_encode = &_compress_rle;
		*func_decode = &_expand_rle;
		break;
	case RDFSTORE_COMPRESSION_TYPE_FRAENKEL:
		*func_encode = &_compress_fraenkel;
		*func_decode = &_expand_fraenkel;
		break;
	case RDFSTORE_COMPRESSION_TYPE_ORIGINAL: 
		*func_encode = &_compress_mine;
		*func_decode = &_expand_mine;
		break;
	case RDFSTORE_COMPRESSION_TYPE_DEFAULT:	/* break intentionally missing */
	case RDFSTORE_COMPRESSION_TYPE_NULLS:
		*func_encode = &_compress_nulls;
		*func_decode = &_expand_nulls;
		break;
	default:
		fprintf(stderr,"No compression default specified\n");
		exit(1);
	}
	return 0;
}
