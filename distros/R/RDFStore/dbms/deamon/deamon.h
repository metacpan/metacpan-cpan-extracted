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
 *
 * $Id: deamon.h,v 1.14 2006/06/19 10:10:22 areggiori Exp $
 */ 
#ifndef _H_DEAMON
#define _H_DEAMON

#include "dbms.h"
#include "conf.h"
#include "dbms_comms.h"

#ifdef RDFSTORE_DBMS_DEBUG
#ifdef RDFSTORE_DBMS_DEBUG_TIME
extern float total_time;

#define MDEBUG( x ) {  \
        struct timeval t;  \
        struct timezone tz; \
        gettimeofday(&t,&tz); \
        fprintf(stderr,"MDEBUG[%5d]: %f: ",getpid(),total_time);\
        fprintf x ; \
	fflush(stderr);\
        }
#else 
#define MDEBUG( x ) {  fprintf(stderr,"MDEBUG[%5d %s]: ",getpid(),getpid()==mum_pid ? "mum" : "cld"); fprintf x ; fflush(stderr); }
#endif

#else
#define MDEBUG( x ) { ; }
#endif


#ifdef FORKING	
typedef struct child_rec {
	int			close;
	struct child_rec	* nxt;
	struct connection 	* r;
	int			pid;	/* pid of the child (for sig detects) */
	int			num_dbs;	/* Number of DBS-es assigned sofar */
	} child_rec;
#endif

typedef struct dbase {
#ifdef FORKING	
	struct child_rec * handled_by;
#endif
	int	  sname;
	int	  mode;
	int       bt_compare_fcn_type;
#ifdef STATIC_BUFF
	char	pfile[ MAX_STATIC_PFILE ];
	char 	name[ MAX_STATIC_NAME ];
#else
	char	* pfile;
	char 	* name;
#endif
	DB	* handle;
#ifdef DB_VERSION_MAJOR
        DBC *   cursor ;
#endif
	int	  lastfd; /* last FD from which a cursor was set */
	int	  num_cls; /* Number of Clients served */
	struct dbase   * nxt;
	int	close;
	} dbase;

typedef struct connection {

   int	type; /* one of C_MUM, C_CHILD, ... */

	int      clientfd;

	struct sockaddr_in address;

	DBT	v1;
	DBT	v2;

	char	* sendbuff;
	char 	* recbuff;

	struct dbase	* dbp;

	struct header	cmd;
	struct iovec 	iov[3];
	struct msghdr	 msg;

	tops		op;	/* Max operation allowed */
	int	   	send;	/* size of the outgoing block */
	int	   	tosend;	/* bytes send sofar.. */

	int		gotten;
	int		toget;

	int	   	close;	/* Shall I close the connection ? */
#ifdef TIMEOUT
	TIMESPEC   	start,last;
#endif
	struct connection	* next;
	} connection;

typedef struct command_req {
        unsigned char cmd;	
	char * info;
	int cnt;
        void (*handler)(connection * r);
	tops op;
        } command_req;

extern struct command_req cmd_table[ TOKEN_MAX ];

#define	L_FATAL		-2
#define	L_ERROR 	-1
#define	L_WARN   	0
#define	L_INFORM 	1
#define	L_VERBOSE	2	 
#define	L_BLOAT		3
#define	L_DEBUG 	4

void reply_log(connection * r, int level, char *fmt, ...);
void dbms_log(int level, char *fmt, ...);
void trace(char *fmt, ...);

extern int debug,verbose,trace_on;

#define do_error(r,m) do_error_i(r,m,__FILE__,__LINE__);
#define do_error2(r,m,e) do_error2_i(r,m,e,__FILE__,__LINE__);
void do_error_i ( connection * r, char * msg, char *file, int line );
void do_error2_i ( connection * r, char * msg, int err, char *file, int line );

void dispatch( connection * r, int token, DBT * v1, DBT * v2);

void clean_children( void );
void cleanmost( void );
void cleandown( int signo );

void zap ( connection * r );
void zap_dbs( dbase * q );
#ifdef FORKING	
void zap_child( child_rec * r);
#endif

void close_connection ( connection * r );
void free_connection ( connection * r );
void continue_send( connection * r );
void final_read( connection * r) ;
void initial_read( connection * r );
void continue_read( connection * r );

extern int client_counter;

#endif
