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
 * $Id: main.c,v 1.22 2006/06/19 10:10:22 areggiori Exp $
 */ 
#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"
#include "dbmsd.h"
#include "version.h"

#include "deamon.h"
#include "handler.h"
#include "mymalloc.h"

#ifndef USER
#define USER		"nobody"
#endif

#ifndef PID_FILE
#define PID_FILE	"/var/run/dbms.pid"
#endif

#ifndef DUMP_FILE
#define DUMP_FILE	"/var/tmp/dbms.dump"
#endif

#ifndef PORT
#define PORT 		1234
#endif

#ifndef DIR_PREFIX
#define DIR_PREFIX	"/pen/dbms"
#endif

#ifndef CONF_FILE
#define CONF_FILE	DIR_PREFIX "/dbms.conf"
#endif

/* Listen queue, see listen() */
#ifndef MAX_QUEUE
#define	MAX_QUEUE	128
#endif

/* If defined, we check for timeouts (in seconds). When left
 * undefined, no time/bookkeeping is done.
 */
/* #define TIMEOUT		250 */

#ifdef RDFSTORE_DBMS_DEBUG_TIME
float			total_time;
#endif  
#ifdef FORKING
struct child_rec      * children=NULL;
#endif
struct connection      * client_list=NULL;
struct connection      * mum;
fd_set			rset,wset,eset,alleset,allrset,allwset;
int			sockfd,maxfd,mum_pid, mum_pgid;
char		      * my_dir = DIR_PREFIX;
char		      * pid_file = PID_FILE;
char		      * conf_file = CONF_FILE;
int			max_processes=MAX_CHILD;
int			max_dbms=MAX_DBMS_CHILD;
int			max_clients=MAX_CLIENT;

int			sysloglog = 1;
int	      stderrlog = 0;
FILE			* errorout;

#define SERVER_NAME	"DBMS-Dirkx/3.00"

int			debug = 0;
int			verbose = 0;
int			trace_on = 0;

#define barf(x) { dbms_log(L_FATAL,x ":%s",strerror(errno)); exit(1); }

static char *_exp[]={
	"**FATAL", "**ERROR", "Warning", " Inform", "verbose", "  bloat", "  debug"
	};

static int lexp[]={
	LOG_ALERT, LOG_ERR, LOG_WARNING, LOG_INFO, 
		LOG_DEBUG,LOG_DEBUG,LOG_DEBUG
	};

void
reply_log(connection * r, int level, char * fmt, ...)
{
	char tmp[ 1024 ];
	char tmp2[ 2*1024 ];
	va_list	ap;
	pid_t p = getpid();
	DBT v;
	errorout = stderr;
		
	va_start(ap,fmt);
	vsnprintf(tmp,sizeof(tmp),fmt,ap);
	va_end(ap);

	if (level<=verbose) {
	 	snprintf(tmp2,sizeof(tmp2),"%d:%s %s %s",p,
			(!mum_pid) ? "Mum" : "Cld",
			_exp[ level - L_FATAL ],
			tmp);

		if (sysloglog) 
			syslog(lexp[ level - L_FATAL ],"%s",tmp2);

		if (stderrlog) 
			fprintf(errorout,"%s\n",tmp2);
	}

	v.data = tmp;
	v.size = strlen(tmp);
	dispatch(r,TOKEN_ERROR,&v,NULL);
}

void
dbms_log(int level, char * fmt, ...)
{
	char tmp[ 1024 ];
	va_list	ap;
	pid_t p = getpid();
	errorout = stderr;

	if (level>verbose) 
		return;	

	snprintf(tmp,1024,"%d:%s %s %s",p,
		(!mum_pid) ? "Mum" : "Cld",
		_exp[ level - L_FATAL ],
		fmt);

if (sysloglog) {
	va_start(ap,fmt);
	vsyslog(lexp[ level - L_FATAL ],tmp,ap);					
	va_end(ap);
}
if (stderrlog) {
		va_start(ap,fmt);
		vfprintf(errorout,tmp,ap);					
		va_end(ap);
	   fprintf(errorout,"\n");
}
}

void
trace(char * fmt, ...)
{
        char tmp[ 1024 ];
        va_list ap;
	time_t tt;
	pid_t p = getpid();

	if (!trace_on) return;
	
	time(&tt);

        snprintf(tmp,1024,"%d:%s %20s\t%s\n",
		p,
                (!mum_pid) ? "Mum" : "Cld",
		asctime(gmtime(&tt)),
                fmt
		);

   va_start(ap,fmt);
   vprintf(tmp,ap);
   va_end(ap);

	fflush(stdout);
}    

int check_children=0;

void loglevel( int i) {
	if (i == SIGUSR1 ) verbose++;
	if (i == SIGUSR2 ) {
		verbose=0;
		for(i=0; i < sizeof(cmd_table) / sizeof(struct command_req); i++) 
			cmd_table[i].cnt = 0;
		};

	dbms_log(L_ERROR,"Log level changed by signal to %d",debug);
	}

	
void dumpie ( int i ) {
#ifdef FORKING
	child_rec * c;
#endif
	connection * r;
	dbase * d;
	time_t t=time(NULL);
	FILE * f;
	if ((f=fopen(DUMP_FILE,"w"))==NULL) {
		dbms_log(L_ERROR,"Cannot open dbmsd.dump: %s",strerror(errno));
		return;
		};

	fprintf(f,"# Dump DBMS - pid=%d - %s\n",(int)getpid(),ctime(&t));
#ifdef FORKING
	fprintf(f,"# Children\n");
	for( c=children; c; c=c->nxt) {
		fprintf(f," %7p Pid %5d conn=%p fd=%d\n",
			c,c->pid,c->r,c->r ? c->r->clientfd : -1);
		for( d=first_dbp; d; d=d->nxt ) if (d->handled_by == c)
			fprintf(f,"\t%7p %s\n",d,d->name);
		};
#endif
	fprintf(f,"# Databases\n");
	for( d=first_dbp; d; d=d->nxt ) 
#ifdef FORKING 
		fprintf(f," %7p %s %p\n", d,d->name, d->handled_by);
#else
		fprintf(f," %7p %s\n", d,d->name);
#endif
	
	fprintf(f,"# Clients\n");
	for( r=client_list; r; r=r->next)
		fprintf(f," %7p fd=%d type=%d Dbase %7p %s\n",
			r,r->clientfd,r->type,r->dbp,
			( r->dbp ? r->dbp->name : 0));

	fprintf(f,"# Stats\n");
	for(i=0; i < sizeof(cmd_table) / sizeof(struct command_req); i++) 
		fprintf(f," %8s: %d\n",cmd_table[i].info, cmd_table[i].cnt);

#ifdef RDFSTORE_DBMS_DEBUG_MALLOC
	fprintf(f,"# Memory in use\n");
	debug_malloc_dump(f);
#endif
	fprintf(f,"\n---------\n");
	fclose(f);
	};

void childied( int i ) {
	int oerrno=errno;
	int status;
	int pid;

	/* reap children, and mark them closed.
	 */
	while((pid=waitpid(-1,&status,WNOHANG))>0) {
#ifdef FORKING
		child_rec * c;
		dbms_log(L_INFORM,"Skeduled to zap one of my children pid=%d",pid);
		for(c=children;c;c=c->nxt) 
			if (c->pid == pid) 
				c->close = 1; MX;
#endif
		}

	if ((pid == -1) && ( errno=ECHILD)) {
#if 0
		dbms_log(L_ERROR,"Gotten CHILD died signal, but no child...");
#endif
		} else
	if (pid == -1) {
		dbms_log(L_ERROR,"Failed to get deceased PID: %s",strerror(errno));
		} 

	errno=oerrno;
	return;
}

int
main( int argc, char * argv[]) 
{
 	struct sockaddr_in  	server;
	int 			port;
	int 			dtch=1;
	int			one=1,i;
	struct rlimit 		l;
	int 			needed=0;
	char			* as_user=USER;
	struct sigaction 	act,oact;
	in_addr_t 		bound = INADDR_ANY;
	const char 		* erm;

	errorout = stderr;

	port = PORT;

	for( i=1; i<argc; i++) {
		if ((!strcmp(argv[i],"-p")) && (i+1<argc)) {
			port=atoi(argv[++i]);
			if (port<=1) {
				fprintf(stderr,"Aborted: You really want a port number >1.\n");
				exit(1);
				};
		} else
		if ((!strcmp(argv[i],"-b")) && (i+1<argc)) {
			char * iface = argv[++i];
			bound = inet_addr(iface);  /* First treat it as an UP address */
			if (bound == INADDR_NONE) {
				/* Not a valid IP address - try to look it up */
				struct hostent * hp;
				if((hp = gethostbyname(iface))==NULL) {     
					perror("Address to listen on not found");
					exit(1);
                        	};
                		bound = *(u_long *) hp->h_addr;
			}
		} else
		if ((!strcmp(argv[i],"-d")) && (i+1<argc)) {
			my_dir = argv[++i];
			} else
		if ((!strcmp(argv[i],"-u")) && (i+1<argc)) {
			as_user= argv[++i];
		} else
		if (!strcmp(argv[i],"-U")) {
			as_user= NULL;
		} else
		if ((!strcmp(argv[i],"-C")) && (i+1<argc)) {
			conf_file = argv[++i];
			if ((erm=parse_config(conf_file))) {
                                fprintf(stderr,"Aborted: %s\n",erm);
                                exit(1);
                        }; 
			printf("Config file parsed OK\n");
			exit(0);
		} else
		if ((!strcmp(argv[i],"-c")) && (i+1<argc)) {
			conf_file = argv[++i];
		} else
		if ((!strcmp(argv[i],"-P")) && (i+1<argc)) {
			pid_file= argv[++i];
		} else
		if ((!strcmp(argv[i],"-n")) && (i+1<argc)) { 
			max_processes = atoi( argv[ ++i ] );
			if ((max_processes < 1) || (max_processes > MAX_CHILD)) {
				fprintf(stderr,"Aborted: Max Number of child processes must be between 1 and %d\n",MAX_CHILD);
				exit(1);
				};
		} else
		if ((!strcmp(argv[i],"-m")) && (i+1<argc)) { 
			max_dbms = atoi( argv[ ++i ] );
			if ((max_dbms < 1) || (max_dbms > MAX_DBMS)) {
				fprintf(stderr,"Aborted: Max Number of DB's must be between 1 and %d\n",MAX_DBMS);
				exit(1);
				};
		} else
		if ((!strcmp(argv[i],"-C")) && (i+1<argc)) { 
			max_clients = atoi( argv[ ++i ] );
			if ((max_clients < 1) || (max_clients> MAX_CLIENT)) {
				fprintf(stderr,"Aborted: Max Number of children must be between 1 and %d\n",MAX_CLIENT);
				exit(1);
				};
		} else
		if (!strcmp(argv[i],"-x")) {
			verbose++; debug++; 
			if (debug>2) dtch = 0;
		} else
		if (!strcmp(argv[i],"-D")) {
			dtch = 0;
		} else
		if (!strcmp(argv[i],"-t")) {
			trace_on= 1;
		} else
		if (!strcmp(argv[i],"-v")) {
			printf("%s\n",get_full());
			printf("Max clients:	%d\n",MAX_CLIENT);
			printf("Max DBs:	%d\n",MAX_DBMS);
			printf("Max Children:	%d\n",MAX_CHILD);
			printf("Max Payload:	%d bytes\n",MAX_PAYLOAD);
			printf("Default dir:	%s\n",DIR_PREFIX);
			printf("Default config:	%s\n",CONF_FILE);
			exit(0);
		} else
		if (!strcmp(argv[i],"-X")) {
			verbose=debug=100; dtch = 0; sysloglog = 0; stderrlog = 1;
	   } else
		if ((!strcmp(argv[i],"-e")) && (i+1<argc)) {
	      stderrlog = 1;
		   if ((errorout = fopen(argv[++i],"a")) == NULL) {
				fprintf(stderr,"Aborted. Cannot open logfile %s for writing: %s\n",
						argv[i],strerror(errno));
				exit(1);
		   };
		} else
		if (!strcmp(argv[i],"-E")) {
	      stderrlog = 1;
		} else { 	
			fprintf(stderr,"Syntax: %s [-U | -u <userid>] [-E] [-P <pid-file>] [-d <directory_prefix>] [-b <ip to bind to>] [-p <port>] [-x] [-n <max children>] [-m <max databases>] [-C <max clients>] <-c conffile>\n",argv[0]);
			exit(1);
			};
		};
	if ((erm=parse_config(conf_file))) {
               	fprintf(stderr,"Aborted: %s\n",erm);
        	exit(1);
        }

	if (HARD_MAX_CLIENTS < max_clients +3) {
		fprintf(stderr,"Aborted: Max number of clients larger than compiled hard max(%d)\n",HARD_MAX_CLIENTS);
		exit(1);
		};

	needed=MAX(max_processes, max_clients/max_processes+max_dbms/max_processes) + 5;

	if (FD_SETSIZE < needed ) {
		fprintf(stderr,"Aborted: Number of select()-able file descriptors too low (FD_SETSIZE)\n");
		exit(1);
		};

     	if (getrlimit(RLIMIT_NOFILE,&l)==-1) 
		barf("Could not obtain limit of files open\n");

	if (l.rlim_cur < needed ) {
		fprintf(stderr,"Aborted: Resource limit imposes on number of open files too limiting\n");
		exit(1);
		};

#ifndef RDFSTORE_PLATFORM_SOLARIS
     	if (getrlimit(RLIMIT_NPROC,&l)==-1) 
		barf("Could not obtain limit on children\n");

	if (l.rlim_cur < 2+max_processes) {
		fprintf(stderr,"Aborted: Resource limit imposes on number of children too limiting\n");
		exit(1);
		};
#endif

	if (sysloglog)
		openlog("dbms",LOG_LOCAL4, LOG_PID | LOG_CONS);

	if ( (sockfd = socket( AF_INET, SOCK_STREAM, 0))<0 ) 
		barf("Cannot open socket");

   	if( (setsockopt(sockfd,SOL_SOCKET,SO_REUSEADDR,(const char *)&one,sizeof(one))) <0)
		barf("Could not set REUSEADDR option");

       	if( (setsockopt(sockfd,IPPROTO_TCP,TCP_NODELAY,(const void *)&one,sizeof(one))) <0) 
      		barf("Could not distable Nagle algoritm");

{
	int sendbuf = 32 * 1024;
	int recvbuf = 32 * 1024;

       	if( (setsockopt(sockfd,SOL_SOCKET,SO_SNDBUF,(const void *)&sendbuf,sizeof(sendbuf))) <0) 
      		barf("Could not set sendbuffer size");

       	if( (setsockopt(sockfd,SOL_SOCKET,SO_RCVBUF,(const void *)&recvbuf,sizeof(sendbuf))) <0) 
      		barf("Could not set sendbuffer size");
}
	if ( (i=fcntl(sockfd, F_GETFL, 0)<0) || (fcntl(sockfd, F_SETFL,i | O_NONBLOCK)<0) )
		barf("Could not make socket non blocking");

	bzero( (char *) &server,sizeof(server) );
	server.sin_family	= AF_INET;
	server.sin_addr.s_addr	= bound;		/* Already in network order. */
	server.sin_port		= htons( port );

	if ( (bind( sockfd, ( struct sockaddr *) &server, sizeof (server)))<0 )
		barf("Cannot bind server to (lcoal) address.");

	/* Allow for a que.. */
	if ( listen(sockfd,MAX_QUEUE)<0 ) 
		barf("Could not start to listen to my port");

	/* fork and detach if ness. 
	 */
	if (dtch) {
#ifdef FORKING
		pid_t   pid;
/*
		fclose(stdin); 
		if (!trace_on) fclose(stdout); 
*/
        	if ( (pid = fork()) < 0) {
                	perror("Could not fork");
			exit(1);
			}
        	else if (pid != 0) {
			FILE * fd;
			if (!(fd=fopen(pid_file,"w"))) {
				fprintf(stderr,"Warning: Could not write pid file %s:%s",pid_file,strerror(errno));
				exit(1);
				};
			fprintf(fd,"%d\n", (int)pid);
			fclose(fd);	
                	exit(0);
			};
 
#else
		fprintf(stderr,"No forking compiled in, no detach\n");
#endif

	        /* become session leader 
		 */
       		if ((mum_pgid = setsid())<0)
			barf("Could not become session leader");
		};

	/* XXX security hole.. yes I know... 
	 */
	if (as_user != NULL) {
		struct passwd * p = getpwnam( as_user );
		uid_t uid;

		uid = (p == NULL) ? atoi( as_user ) : p->pw_uid;

		if ( !uid || setuid(uid) ) {
			perror("Cannot setuid");
			exit(0);
			};
	};

#if 0
        chdir(my_dir);          /* change working directory */
//	chroot(my_dir);		/* for sanities sake */
        umask(0);               /* clear our file mode creation mask */
#endif

	mum_pid = 0;

	FD_ZERO(&allrset);
	FD_ZERO(&allwset);
	FD_ZERO(&alleset);

	FD_SET(sockfd,&allrset);
	FD_SET(sockfd,&alleset);

	maxfd=sockfd;
	client_list=NULL;

	dbms_log(L_INFORM,"Waiting for connections");

	signal(SIGHUP,dumpie);
	signal(SIGUSR1,loglevel);
	signal(SIGUSR2,loglevel);
	signal(SIGINT,cleandown);
	signal(SIGQUIT,cleandown);
	signal(SIGKILL,cleandown);
	signal(SIGTERM,cleandown);
#ifdef FORKING
	signal(SIGCHLD,childied); 
#endif
	mum = NULL;

	trace("Tracing started\n");

	/* for now, SA_RESTART any interupted PIPE calls
	 */
	act.sa_handler = SIG_IGN;
	sigemptyset(&act.sa_mask);
	act.sa_flags = SA_RESTART;
	sigaction(SIGPIPE,&act,&oact);

	init_cmd_table();

	select_loop(); 
		/* get down to handling.. (as the mother) */

	return 0; /* keep the compiler happy.. */
	}
