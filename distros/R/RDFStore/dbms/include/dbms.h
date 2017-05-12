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

/*
 *
 * WARNING! if you change this file you have also to manually update ../../lib/DBMS.pm to be in-sync with these definitions
 *
 */ 

#ifndef _H_DBMS_
#define _H_DBMS_

#include "dbms_compat.h"

typedef uint32_t	dbms_counter;	

typedef enum { 
	DBMS_EVENT_RECONNECT,
	DBMS_EVENT_WAITING
} dbms_cause_t;

typedef enum {
	DBMS_XSMODE_DEFAULT = 0,
	DBMS_XSMODE_RDONLY,
	DBMS_XSMODE_RDWR,
	DBMS_XSMODE_CREAT,
	DBMS_XSMODE_DROP
} dbms_xsmode_t;

typedef int dbms_error_t;

typedef struct {
        char * name;
        char * host;
        unsigned long port;
        int mode;
        int sockfd;
        unsigned long addr;
	int bt_compare_fcn_type;

	void * (* malloc)(size_t s);
	void (* free)(void * adr);
	void (* callback)(dbms_cause_t cause, int cnt);
        void (* error)(char * err, int erx);
	
	char err[ 256 ];
        } dbms;

extern char *
dbms_get_error( 
	dbms * me 
);

extern dbms *
dbms_connect(
        char *name, 
	char * host, int port, 
	dbms_xsmode_t mode,
        void *(*_my_malloc)( size_t size),
        void(*_my_free)(void *),
        void(*_my_report)(dbms_cause_t cause, int count),
	void(*_my_error)(char * err, int erx),
	int bt_compare_fcn_type
);

extern dbms_error_t
dbms_disconnect(
	dbms * me
);

extern dbms_error_t
dbms_comms (
        dbms * me,
        int token, 
        int * retval,
        DBT * v1, 
        DBT * v2,
        DBT * r1,
        DBT * r2
        );

/* dbms_error_t values; beside normal
 * errno values from libc et. al.
 */
#define         E_UNDEF         1000
#define         E_NONNUL        1001 
#define         E_FULLREAD      1002 
#define         E_FULLWRITE     1003
#define         E_CLOSE         1004
#define         E_HOSTNAME      1005
#define         E_VERSION       1006
#define         E_PROTO         1007
#define         E_ERROR         1008
#define         E_NOMEM         1009
#define         E_RETRY         1010
#define         E_NOPE          1011
#define         E_XXX           1012
#define         E_TOOBIG        1013
#define         E_BUG           1014

#endif
