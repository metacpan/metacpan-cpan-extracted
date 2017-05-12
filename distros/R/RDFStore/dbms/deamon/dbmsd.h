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
 * $Id: dbmsd.h,v 1.13 2006/06/19 10:10:22 areggiori Exp $
 */
#ifndef _H_DBMSD
#define _H_DBMSD

#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"
#include "deamon.h"

#ifdef RDFSTORE_DBMS_DEBUG_TIME
extern float		total_time;
#endif    

extern connection	      * client_list, *mum;
extern struct child_rec	      * children;
extern fd_set			rset,wset,eset,alleset,allrset,allwset;
extern char		      * default_dir;
extern char		      * dir;
extern int			sockfd,maxfd,mum_pgid,mum_pid,max_dbms,max_processes,max_clients;
extern char		      * my_dir;
extern char		      * pid_file;
extern char		      * conf_file;
extern int			check_children;
extern dbase                 * first_dbp;

void select_loop();

/* Some reasonable limit, to avoid running out of
 * all sorts of resources, such as file descriptors
 * and all that..
 */
#define MAX_CLIENT     		2048

/* An absolute limit, above this limit, connections
 * are no longer accepted, and simply dropped without
 * as much as an error.
 */
#define HARD_MAX_CLIENTS   	MAX_CLIENT+5
#define HARD_MAX_DBASE		256

/* hard number for the total number of DBMS-es we
 * are willing to server (in total)
 */

#define MAX_DBMS_CHILD		256
#define MAX_CHILD		32
#define MAX_DBMS		(MAX_DBMS_CHILD * MAX_CHILD)

    
#define SERVER_NAME	"DBMS-Dirkx/3.00"

#define	SERVER		1
#define CLIENT		0

/* some connection types... */
#define		C_UNK		0
#define		C_MUM		1
#define		C_CLIENT	2
#define		C_NEW_CLIENT	3
#define		C_CHILD		4
#define		C_LEGACY	5

struct child_rec * create_new_child(void);
int handoff_fd( struct child_rec * child, connection * r );
int takeon_fd(int conn_fd);
connection * handle_new_local_connection( int sockfd , int type);
connection * handle_new_connection( int sockfd , int type, struct sockaddr_in addr);

#define MX dbms_log(L_DEBUG,"@@ %s:%d",__FILE__,__LINE__);
#endif
