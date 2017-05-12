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
 * $Id: loop.c,v 1.18 2006/06/19 10:10:22 areggiori Exp $
 */ 
#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"
#include "dbmsd.h"

#include "deamon.h"
#include "handler.h"

/* for debugging..
 */
char * 
show(
	int max,
	fd_set * all, 
	fd_set * show
	)
{	int i;
	static char out[16*1024];
	out[0]='\0'; 
	for(i=0; i<max; i++) if (FD_ISSET(i,all)) {
		char tmp[16];
		if (FD_ISSET(i,show))
			snprintf(tmp,16," %4d",i);
		else
			snprintf(tmp,16,"     ");
		strcat(out,tmp);
		};
	return out;
}

/* sync and flush on DB level, file descriptior level
 * as well as on filesystem/kernel level.
 */
void flush_all( void ) { 
	dbase * p;
	int one = 0;
	int fd;

	for(p=first_dbp; p;p=p->nxt) 
		if (p->handle) {
			(p->handle->sync)(p->handle,0);
#ifdef DB_VERSION_MAJOR
			(p->handle->fd)(p->handle, &fd);
#else
			fd = (p->handle->fd)(p->handle);
#endif
			fsync( fd );
			one++;
		};

	if (one)
		sync();

	dbms_log(L_INFORM,"Synced %d databases and the file system",one);
	}

void
select_loop( void )
{
	time_t lsync = time(NULL);
	/* seconds and micro seconds. */
	struct timeval nill={600,0};
	struct timeval *np = &nill;

	if (!mum_pid)
			np = NULL;

	for (;;) {
		int n;
		time_t now = time(NULL);
		struct connection *r, *s;
		dbase * p;
#ifdef FORKING
		child_rec * d;
#endif
		rset=allrset;
		wset=allwset;
		eset=alleset;

		/* mothers do not time out, or if
		 * the last cycle was synced and 
		 * was nothing to do... 
		 */	
		if ((n=select(maxfd+1,&rset,&wset,&eset,np)) < 0) {
			if (errno != EINTR )
				dbms_log(L_ERROR,"RWE Select Probem %s",strerror(errno));
			continue;
			};

		/* not done anything for 15 minutes or so.
		 * are there any connections outstanding apart 
		 * from the one to mum ?
		 */
		if ( (n==0) && (mum_pid) && 
			(!(first_dbp && client_list && client_list->next))) {

			// clients but no dbase ?
			assert( ! (client_list) && (client_list->next));

			// a dbase but no clients ?
			assert(! first_dbp);

			dbms_log(L_INFORM,"Nothing to do, this child stops..");

			exit(0);
			}

		/* upon request from alberto...  flush
		   every 5 minutes or so.. see if that
		   cures the issue since we moved to raid.
	 	 */
		if ((mum_pid) && (difftime(now,lsync) > 300))  {
			flush_all();
			lsync = now;
			/* next round, we can wait for just about forever */
			// if (n == 0) np = NULL;  XXX not needed
		};
		dbms_log(L_DEBUG,"Read  : %s",show(maxfd+1,&allrset,&rset));
		dbms_log(L_DEBUG,"Write : %s",show(maxfd+1,&allrset,&wset));
		dbms_log(L_DEBUG,"Except: %s",show(maxfd+1,&allrset,&eset));

		/* Is someone knocking on our front door ? 
		 */
		if ((sockfd>=0) && (FD_ISSET(sockfd,&rset))) {
			struct sockaddr_in client;
		        int len=sizeof(client);
			int fd;

			if (mum_pid) 
				dbms_log(L_ERROR,"Should not get such an accept()");
			else 
        		if ((fd = accept(sockfd, 
				    ( struct sockaddr *) &client, &len)) <0) 
                		dbms_log(L_ERROR,"Could not accept");
			else {
				tops level = allowed_ops(client.sin_addr.s_addr);
                		dbms_log(L_DEBUG,"Accept(%d) op level for IP=%s: %s",
					fd,inet_ntoa(client.sin_addr),op2string(level));

				if (level > T_NONE)
					handle_new_connection(fd, C_NEW_CLIENT, client); 
				else {
					dbms_log(L_ERROR,"Accept violation: %s rejected.",
						inet_ntoa(client.sin_addr));
					close(fd);
				}
			}
		}

		/* note that for the pthreads we rely on a mark-and-sweep
		 * style of garbage collect.
		 */
	if (client_list != NULL) for ( s = client_list; s != NULL; ) {	
			/* Page early, as the record might get zapped
			 * and taken out of the lists in this loop.
			 */
			assert( s != NULL );
			r=s; s=r->next;

			assert( r != s );
			if (r->close)
				continue;

			if (FD_ISSET(r->clientfd,&rset)) {
				int trapit=getpid(); // trap forks.
				if (r->tosend != 0) {
					dbms_log(L_ERROR,"read request received while working on send");
					zap(r);
					continue;
					} 
				dbms_log(L_DEBUG,"read F=%d R%d W%d E%d",
					r->clientfd,
					FD_ISSET(r->clientfd,&rset) ? 1 : 0,
					FD_ISSET(r->clientfd,&wset) ? 1 : 0,
					FD_ISSET(r->clientfd,&eset) ? 1 : 0
					);

				if (r->toget == 0) 
					initial_read(r);
				else 
					continue_read(r);
	
				if (trapit != getpid())
					break;
#ifdef TIMEOUT
				r->last=time(NULL);
#endif
				if (r->close) 
					continue;
				};

			if (FD_ISSET(r->clientfd,&wset)) {
				if (r->tosend >= 0 )
					continue_send(r);
				else
					dbms_log(L_ERROR,"write select while not expecting to write");
#ifdef TIMEOUT
				r->last=time(NULL);
#endif
				if (r->close) 
					continue;
				};

// XXX this eset is a pointless
// excersize, perhaps ??
// only seen on linux-RH5.1
//
			if (FD_ISSET(r->clientfd,&eset)) {
				dbms_log(L_ERROR,"Some exception. Unexpected");
				r->close = 1; MX;
#ifdef TIMEOUT
				r->last=time(NULL);
#endif
				};
#ifdef TIMEOUT
			if (difftime( r->last, time(NULL) ) > TIMEOUT) {
				inform("Timeout, closed the connection."); 
				r->close =1; MX;
				};
#endif
		}; /* client set loop */

		/* clean up operations... 
		 *    note the order 
		 */
		for ( s=client_list; s != NULL; ) {	
			r=s; s=r->next;
			assert( r != s );
			if ( r->close ) {
				dbms_log(L_DEBUG,"General clean %d",r->clientfd);
				zap(r);	
				};
		};

#ifdef FORKING
		for(d=children;d;) {
			child_rec * e = d; d=d->nxt;
			assert( d != e );
			if (e->close)
				zap_child( e );
			};
#endif

		for(p=first_dbp; p;) {
			dbase * q=p; p=p->nxt;
			assert( p != q );
			if (q->close)
				zap_dbs(q);
			};

		}; /* Forever.. */
	} /* of main */
