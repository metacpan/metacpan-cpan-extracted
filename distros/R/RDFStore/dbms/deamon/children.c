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
 * DBMS Server
 *
 * Dealing with birth(control) of children, handing of
 * tasks and subsequent reaping of accidentally terminal
 * cases. 
 *
 * Strategy/Design/Bumpf
 *
 * 	The idea here is that each time a new/init comes
 *	in from a client; we check if we already have the database
 *	requested open (note; we assume a strict one socket
 *	per database relation). If one of our children already
 *	has the database openened; hand off the connection to
 * 	that child and forget about the connection.
 *
 *	This way we do not have to worry about locks; as each
 * 	dbm has just one process handling it.
 *
 *	If no child is currently handing the requested database
 *	we check how many we have running, and either spawn a
 *	new child; or ask an existing one to take the additional
 *	load. The assumtion here is that forking processis are
 *	able to handle RQ's more independently; thus allowing
 *	better utilizition of the bus to the disk; as we have
 *	decoupled the H function.
 *
 *	For now we changed to a fork(); rather than pull from a 
 *	thread pool as in the UKDCils. The main reasons are that
 *	we are worried about one DB blowing up another, and that
 *	some of the older FreeBSD production boxes give the same
 *	problems we had with the IMS user land hangs. But really
 *	treading would be better; and just require a few mutexi-es.
 *
 * $Id: children.c,v 1.20 2006/06/19 10:10:22 areggiori Exp $
 */                                   
#ifdef FORKING

#include "dbms.h"
#include "dbms_comms.h"
#include "dbmsd.h"

#include "deamon.h"
#include "handler.h"
#include "children.h"
#include "mymalloc.h"

// unpatched solaris and FreeBSD<2.2 need them. I think.
//
#ifndef ALIGN
#define ALIGN(x) (x)
#endif

#ifndef CMSG_LEN      
#if RDFSTORE_PLATFORM_SOLARIS
#define CMSG_LEN(x) (ALIGN(sizeof(struct cmsghdr)) + ALIGN(x))
#else
#define CMSG_LEN(x) (_CMSG_HDR_ALIGN(x))
#endif
#endif

#ifndef CMSG_SPACE
#if RDFSTORE_PLATFORM_SOLARIS
#define CMSG_SPACE(x) ( ALIGN(sizeof(struct cmsghdr)) + x)
#else
#define CMSG_SPACE(x) (_CMSG_DATA_ALIGN(x))
#endif
#endif

#ifdef STATIC_BUFF
static child_rec * free_child_list = NULL;
static int free_child_list_len = 0;
static int free_child_list_keep= 2;
static int free_child_list_max = 4;
#endif
int child_counter = 0;

// XXX inline or macro :-) most of the following functions are
// just used in one or two places..

int atomic_send(
	int fd,
  	struct msghdr * msg,
	int tosend
	)
{
  int n;
  assert(tosend != 0); // otherwise we cannot detect a child close

retry_snd:
  /* XXX does MSG_WAITALL actually work ?? 
   * SCO acts strange compared to BSDi....
   * we normally would do a proper loop;
   * but this should be atomic accourding
   * to the BSD man page. 
   */
   n=sendmsg(fd,msg,0); 

   if ((n<0) && (errno=EAGAIN))
	goto retry_snd;

   if ((n<=0) && (errno=EINTR)) 
	goto retry_snd;
 
   if (n<0) { 
	dbms_log(L_ERROR,"Could not atomically send msg: %s",strerror(errno)); 
	return -1; 
	} 	
   else
   if (n==0) {
	dbms_log(L_ERROR,"Child closed connection"); 
	return -1; 
	} 

   assert(n==tosend); // who trust the man page ?
   return 0;
}

void free_child( child_rec * r) 
{
	dbms_log(L_DEBUG,"Freeing child %x %d",r,r->pid);
	if (r->r) {
		dbms_log(L_DEBUG,"And marking close fd=%d",r->r->clientfd);
		r->r->close = 1; MX;
		if (mum_pid)
			zap(r->r);/* XXXXXXXX */
	};

#ifdef STATIC_BUFF
	if (free_child_list_len < free_child_list_keep) {
		r->nxt = free_child_list;
		assert( r != free_child_list);
		free_child_list = r;
		free_child_list_len ++;
	} else
#endif
	myfree(r);

	child_counter--;
}
	
void zap_child( child_rec * r)
{
	child_rec * * p;

	dbms_log(L_DEBUG,"Zapped memory for a child");
        for ( p = &children; *p && *p != r; )
                p = &((*p)->nxt);

	//if (*p == NULL)
	//	dbms_log(L_ERROR,"Zapping unkown child ? children=%p",children);
	assert( *p );

	*p = r->nxt;
	free_child(r);
}

void
clean_children( void )
{
	child_rec * p;

	for(p=children;p;) {
		child_rec * q=p; 
		p=p->nxt;
		free_child(q);
		};

	children=NULL;
}

/* Create a new child/thread. And then hand over the file descriptor of the current
 * incoming connection.
 *
 * Return values:
 *	ptr			child created; ptr to record with details.
 *	null, errno = 0		we are the child.
 *	noll, errno != 0	error occured.
 */
child_rec *
create_new_child( void )
{
	/* fork off a child.. make sure we keep the contact
	 * details so that we can pass on file descriptors
	 * later, should the need arise.
	 */
	int pipefd[2];
	child_rec * child = NULL;
	pid_t pid,this_pid;
	dbms_log(L_INFORM,"Creating new child");

	if ((socketpair(AF_UNIX, SOCK_STREAM,0,pipefd))<0)	
		return NULL;

/*
	XXXX

	Braindead... we fork and then always clean all the
	child cruft; as that child does not need to have
	global knowledge. i.e. we faul the page and cause
	a copy on first write and all that. Multi treading
	used to solve this; but no longer with the new fork().
*/

	this_pid=getpid();
	pid=fork();
	if (pid <0 ) {
		dbms_log(L_ERROR,"Failed to create a child: %s",strerror(errno));

		return NULL;
		} else
	if (pid == 0) {
                connection * r;
		struct sigaction 	act,oact;
		int mum_fd = pipefd[1];
		mum_pid = this_pid;

		close(pipefd[0]);

		dbms_log(L_DEBUG,"Child created - I am the Child fd=%d",mum_fd);

      		FD_CLR(sockfd,&allwset);
        	FD_CLR(sockfd,&allrset);
        	FD_CLR(sockfd,&alleset);

		close(sockfd);
		sockfd = -1; /* moved out of the way */

		/* for now, SA_RESTART any interupted PIPE calls
		 */
		act.sa_handler = SIG_IGN;
		sigemptyset(&act.sa_mask);
		act.sa_flags = SA_RESTART;
		sigaction(SIGPIPE,&act,&oact);

                for(r=client_list; r; r=r->next) {
			assert(r);
			r->type = C_LEGACY;
			r->close=1; MX;
			};

                close_all_dbps(); /* XXX wrong; I should not have any ? */
                clean_children(); 

		child = NULL;

		/* make sure we listen to our mother... both for
		 * reading and for exceptions.. This is the channel
		 * used (later) to pass off any connections, (re)do
		 * an init on; etc, etc.
		 */
		/* XXX no error trapping */
		mum = handle_new_local_connection(mum_fd,C_MUM);
		} 
	else {
		/* for the mother.. 
		 */
		int childfd = pipefd[0];
		close(pipefd[1]);

		dbms_log(L_DEBUG,"Child created - I am the Mother fd=%d",childfd);

#ifdef STATIC_BUFF
		/* If we still have free-ed children on the list
		 * then use those.
	         */
		if (free_child_list) {
			child = free_child_list;
			free_child_list = free_child_list->nxt;
			free_child_list_len --;
		} else {
			/* Increase the keep treshold if we have to malloc often. */
			if (free_child_list_keep < free_child_list_max)
				free_child_list_keep += 2;
#else
{
#endif
			child = (struct child_rec *) mymalloc(sizeof(struct child_rec));
		}
		if (child == NULL )
				return NULL;

		/* Tie into the list of active children. */
		child ->nxt = children;
		children = child;

		/* For statistics and logging - no real reasons */
		child_counter ++;
		child->pid=pid;

		/* Initalize the child 'real' structure */
		child->r=NULL;
		child->close=0;
		child->num_dbs=0;

		/* And take over the connection. 
		 */
		if ((child->r = handle_new_local_connection(childfd,C_CHILD)) == NULL) {
			free_child(child);
			return NULL;
			};
		}

	/* return myself.. or null to signal that
	 * we are the child.
	 */
        errno=0;
	
	return child;
}

int
handoff_fd(
	struct child_rec * child, 
	connection * r
	)
{
  struct header cmd;
  struct iovec iov[3];
  struct msghdr	msg;
  union {
	struct cmsghdr	cm;
	char   		control[ CMSG_SPACE( sizeof( int ) ) ];	
	} cmsgbuf;
  struct cmsghdr * cmptr;

  assert(mum_pid == 0);
  dbms_log(L_DEBUG, "Handoff fd=%d across on connection fd=%d to child",
	r ? r->clientfd : 0,
	child->r ? child->r->clientfd : 0
	);

  /* preamble.. we KNOW that the socket we
   * now use is _BLOCKing_ so no one else
   * is going to get between them and us..
   */

  cmd.token = TOKEN_FDPASS | F_INTERNAL;

  cmd.len1 = htonl(r->v1.size);
  cmd.len2 = htonl(r->v2.size);

  iov[0].iov_base = (void *)&cmd;
  iov[0].iov_len = sizeof(cmd);

  iov[1].iov_base = r->v1.data;
  iov[1].iov_len  = r->v1.size;

  iov[2].iov_base = r->v2.data;
  iov[2].iov_len  = r->v2.size;

  bzero( (void *) &msg, sizeof msg);
  msg.msg_name = NULL;
  msg.msg_namelen = 0;
  msg.msg_iov =iov;
  msg.msg_iovlen = 3;
  msg.msg_control = NULL;
  msg.msg_controllen = 0;

  if (atomic_send(child->r->clientfd,&msg,
	iov[0].iov_len + iov[1].iov_len + iov[2].iov_len    )<0) {
  	dbms_log(L_DEBUG, "Handoff fd=%d on fd=%d Fail: %s",
		r->clientfd,child->r->clientfd,
		strerror(errno));
	return -1;
	};

  bzero( (void *) &msg, sizeof msg);
  bzero( (void *) &cmsgbuf, sizeof cmsgbuf);

  /* use a special message to tell about
   * the file descriptior.
   */ 
  msg.msg_name = NULL;
  msg.msg_namelen = 0;
  msg.msg_iov = iov;
  msg.msg_iovlen = 1;
  msg.msg_control = cmsgbuf.control;
  msg.msg_controllen = sizeof cmsgbuf.control;

  /* pass an 'r' pointer as a future reference, and
   * to possibly side step a recfromit() issue.
   */
  iov[0].iov_base = (void *)&r;
  iov[0].iov_len = sizeof(r);

  cmptr = CMSG_FIRSTHDR( &msg );

  cmptr->cmsg_len = CMSG_LEN( sizeof(int) ); 
  cmptr->cmsg_level = SOL_SOCKET;
  cmptr->cmsg_type = SCM_RIGHTS;

  *(int *)CMSG_DATA(cmptr) = r->clientfd;

  if (atomic_send(child->r->clientfd, &msg, 
	iov[0].iov_len  )<0) {
  	dbms_log(L_DEBUG, "Handoff fd=%d on fd=%d Fail: %s",
		r->clientfd,child->r->clientfd,
		strerror(errno));
	return -1;
	};

  /* we did it, forget about any work _we_ where doing
   * on this connection  and/or database association 
   * except perhaps for the pid..
   * we only mark; to avoid double close if it gets
   * re-used somehow.
   */
  dbms_log(L_DEBUG, "Marking fd=%d ass closed",r->clientfd);
  r->close = 1; MX; 
  r->type = C_LEGACY;
  zap(r);
  return  0;
}
  
int
takeon_fd(int conn_fd)
{
  int fd;
  struct msghdr msg;
  struct iovec iov[1];
  connection * tmp;
  union {
	struct cmsghdr	cm;
	char   		control[ CMSG_SPACE( sizeof( int ) ) ];	
	} cmsgbuf;
  struct cmsghdr * cmptr;

  assert(mum_pid != 0);
	
  /* XXX really needed ? 
   */
  bzero( (void *) &msg, sizeof msg);
  bzero( (void *) &cmsgbuf, sizeof cmsgbuf);

  /* expect a special message to tell about
   * the file descriptior.
   */
  msg.msg_name = NULL;
  msg.msg_namelen = 0;

  msg.msg_iov = iov;
  msg.msg_iovlen = 1;
  msg.msg_control = cmsgbuf.control;
  msg.msg_controllen = sizeof cmsgbuf.control;

  iov[0].iov_base = (void *)&tmp;
  iov[0].iov_len = sizeof(tmp);

  /* we could use MSG_WAITALL here ?! */

  /* XXX message could be '0' in size !? */
  while(1) {
	int e=recvmsg(conn_fd,&msg,0);
	if ((e<0) && (errno == EAGAIN))
		continue;
	if ((e<=0) && (errno==EINTR))
		continue;
	if (e<0)
		return -1;
	break;
	};
		
  if ((cmptr=CMSG_FIRSTHDR(&msg)) == NULL ) {
	dbms_log(L_ERROR,"Not the right msg struct");
	return -1;
	};

   if (cmptr->cmsg_len != CMSG_LEN(sizeof(int))) {
	dbms_log(L_ERROR,"Not the right length of fd struct %d",
		cmptr->cmsg_len);
	return -1;
	};

  if (cmptr->cmsg_type != SCM_RIGHTS)  {
	dbms_log(L_ERROR,"Not the right SCM_RIGHTS passed");
	return -1;
	};

  if ( cmptr->cmsg_level != SOL_SOCKET) {
	dbms_log(L_ERROR,"Not the right SOL_SOCKET passed");
	return -1;
	};

  fd = *(int *)CMSG_DATA(cmptr);

  if (fd<0)
	dbms_log(L_FATAL,"Negative value ? %d",fd);

  dbms_log(L_VERBOSE,"Received FD=%d",fd);

  /* this is going to be follwed by an INIT type of msg so we
   * kinda are not going to handle right here. (We could do it,
   * as it would save a (cheapish) select call later. XXXX
   */
  return fd;
}
#endif
