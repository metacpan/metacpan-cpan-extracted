/*
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
 */ 

#ifndef _H_DBMS_COMMS
#define _H_DBMS_COMMS

#include "dbms_compat.h"

/* Define standard min/max macro's if they
 * are not defined.
 */
#ifndef	MIN
#define	MIN(x,y) (((x) < (y)) ? (x) : (y))
#endif

#ifndef	MAX
#define	MAX(x,y) (((x) > (y)) ? (x) : (y))
#endif

#ifdef RDFSTORE_DBMS_DEBUG_TIME
#define		P0		0
#else
#define		P0		1
#endif

#define		DBMS_HOST	"127.0.0.1"
#define		DBMS_PORT	1234
#define		DBMS_MODE	(DBMS_XSMODE_RDWR)

#define		MASK_SOURCE	(128+64)
#define 	F_CLIENT_SIDE	128
#define 	F_SERVER_SIDE	64
#define 	F_INTERNAL	(128+64)

#define		MASK_STATUS	32
#define		F_FOUND		32
#define		F_NOTFOUND	0

#define		MASK_TOKEN	31
#define		TOKEN_ERROR	0
#define		TOKEN_FETCH	1
#define		TOKEN_STORE 	2	
#define		TOKEN_DELETE 	3		
#define		TOKEN_NEXTKEY 	4
#define		TOKEN_FIRSTKEY 	5
#define		TOKEN_EXISTS	6
#define		TOKEN_SYNC	7
#define		TOKEN_INIT	8
#define		TOKEN_CLOSE	9
#define		TOKEN_CLEAR	10
#define		TOKEN_FDPASS	11 /* only used for internal passing FD*/
#define		TOKEN_PING	12 /* only used between servers ?? */
#define		TOKEN_INC	13 /* atomic increment */
#define		TOKEN_LIST	14 /* list all keys */
#define		TOKEN_DEC	15 /* atomic decrement */
#define		TOKEN_PACKINC   16 /* atomic packed increment */
#define		TOKEN_PACKDEC	17 /* atomic packed decrement */
#define		TOKEN_DROP	18 /* Drop database */
#define		TOKEN_FROM	19 /* Get first 'from' this point for a btree */

#define		TOKEN_MAX	20 /* last token.. */

struct header {
	unsigned char	token;
	unsigned long	len1;
	unsigned long	len2;
#ifdef RDFSTORE_DBMS_DEBUG_TIME
	struct timeval  stamp;
#endif
	};	

#define MAX_STATIC_NAME		256
#define MAX_STATIC_PFILE	MAXPATHLEN

#ifndef MAX_PAYLOAD

/* increased (original value was 32) for RDFStore by AR and DW 2002/09/11 after too many Reconnect and dbms: 676:Cld **ERROR RQ string(s) to big 
   anyway this should be somehow related to MAXRECORDS in compress.h */
#define MAX_PAYLOAD	(128*1024)

#endif

#ifdef STATIC_CS_BUFF
#define MAX_CS_PAYLOAD	MAX_PAYLOAD
#define	P2		1	
#else
#define P2		0
#endif

#ifdef STATIC_SC_BUFF
#define MAX_SC_PAYLOAD	MAX_PAYLOAD
#define	P1		1
#else
#define P1		0
#endif

#define		DBMS_PROTO	(110+P0*1+P1*2+P2*4)

#endif
