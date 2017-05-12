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
  * $Id: my_compress.h,v 1.4 2006/06/19 10:10:23 areggiori Exp $
  */

#ifndef _MY_COMPRESS_H
#define _MY_COMRPESS_H
#define MAXBUFFRLE( bits ) ( \
        bits/sizeof(unsigned int) +\
        bits/sizeof(unsigned int)/15/256 \
        )
#define IDSBUFF (MAXBUFFRLE( RDFSTORE_MAXRECORDS )+2*sizeof(unsigned int))

#define MAXRUNLENGTH 16*256*256*256 /* too high for average machine I know.... */
#define MAXVARLENGTH 127 /* up to 127 bytes repeated - this value can be increased *up to* 127 - but watch out efficiency!! */
#define OPTIMAL ( (double)1 / (double)10000 ) /* this is a "optimal" compression a vlen/len value should be */

unsigned int 
compress_mine ( 
	unsigned char * in, 
	unsigned char * out,
	unsigned int insize
	); 

unsigned int 
expand_mine ( 
	unsigned char * in, 
	unsigned char * out,
	unsigned int insize
	); 
#endif

