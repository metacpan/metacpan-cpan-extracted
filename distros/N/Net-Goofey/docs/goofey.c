/* $Id: goofey.c,v 1.3 1997/03/18 02:22:21 tym Exp $ */
/*
 *
 * $RCSfile: goofey.c,v $
 *
@(#)goofey.c    2.08 Pluto Client code.
 * This code maintainns connections with the central pluto server
 * and is used to inform it of the users activity.
 *
 * Written: Darren Platt , Tim MacKenzie.
 *	Started: Sometime
 *
 * This was SCCS version: 2.02
 *
 * History:
 * Daz v0.00: Goofey gasps its first breath of CPU time.
 * tym v1.11: Added check of tty owner to exit conditions... problem on decs
 * tym v1.12: Now checks time since last keypress as condition of death.
 * tym v1.15: Now uses statics for the ttyname rather than getting it everytime
 * tym v1.17: Uses grandparent pid for death (got it right finally).
 * daz v1.17: Better command line parsing.
 * daz v1.18: Once more for good luck so that -s works correctly.
 * tym v1.19: Changed tty code, dont call ttyslot when we're not on a tty.
 * tym 31 Oct 1991: Modified addr code. Clock can tell goofey to stay around
 *      after a query. Now prompts for message of none given to -s.
 * daz v1.22: Changed so that exit codes are indicative of exit status.
 * tym  6 Apr 1992: Checks for tty, removed 'Arrived_message',
 *      No more static limits! Removed a lot of dead code.
 * tym  7 Apr 1992: Added '.' on line as exit condition for '-s'
 * tym  8 Apr 1992: Fixed the problem with pluto restarts (can accept() while
 *      waiting for pluto to come back to life).
 * tym 13 Apr 1992: Fixed problem with sgi's stuff getpw*
 * tym 14 Apr 1992: Another try at proper user identification.
 * tym 15 Apr 1992: Problem with idle time?
 * tym 15 Apr 1992: Now ignores SIGTTOU... stty tostop was killing it!
 * tym 10 Jun 1992: Restores tty modification times after writing if able.
 * tym 20 Jun 1992: Sends password if it is found.
 * tym 20 Jun 1992: Only allow connections from the server machine.
 * tym 12 Oct 1992: Added anthony's FIREWALL changes, protocol change.
 * tym  3 Dec 1992: Added GOOFEYUSER environment variable for rik.
 * tym  7 Dec 1992: Now bzero's sockaddr's before using them.
 * tym  8 Dec 1992: Ansi'ized ?
 * tym  7 Apr 1993: Checks result of read since linux is slightly broken.
 * tym 27 May 1993: Changed way that we declare funcs so it's neater :)
 * tym  7 Dec 1993: configure'ized. Added client options, width handling
 * tym 16 Dec 1993: added readline/getline support (M Battersby/A Cosgriff)
 * tym 23 Dec 1993: made non-blocking broken by default, fixed getenv proto
 * tym 26 Aug 1994: added GOOFEYLOC support
 * tym 29 Aug 1994: fixed problem with readline and eof.
 * tym 21 Jul 1995: fixed problem with long lines and readline/getline
 * tym 22 Sep 1995: Added editor patches from Karl, extended them somewhat
 * tym 23 Sep 1995: Allow ~r to read output from command
 * tym  2 Oct 1995: Fixed to keep non-ansi compilers happy.
 * tym  6 Oct 1995: Fixed ~c... stupid ?: precedence...
 * tym  3 Apr 1996: Added autosplit
 * tym 26 Sep 1996: Added "I don't know" idletime.
 * tym 29 Oct 1996: Added variable timeout and re-register code
 * tym 24 Feb 1997: Fixed small problem with GOOFEY_ARGS
 * tym 18 Mar 1997: Changed hostname and added session_pwd stuff
 */

#define VERSION "3.15"
#define CLIENT_TYPE 'G'
#define PWD_FILE ".goofeypw"

static char *id_string = "$Id: goofey.c,v 1.3 1997/03/18 02:22:21 tym Exp $";

#ifndef MAX_WAIT
#define MAX_WAIT 20
#endif
int max_wait = MAX_WAIT;

#define NEWSERVER "130.194.9.2"
#ifndef SERVER_HOSTNAME
#define SERVER_HOSTNAME "pluto.cc.monash.edu.au"
#endif

#ifndef SERVER_PORT_NO
#define SERVER_PORT_NO 3987
#endif

#define LONELY_INTERVAL 60
#define MAX_RETRIES 10
#define SERVER_MAXREQ 999 /* Maximum size message server will handle */
#define I_DONT_KNOW 200000000

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <signal.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <netdb.h>
#include <stdio.h>
#include <assert.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <ctype.h>
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif
#include <errno.h>
extern int errno;

#ifdef READLINE
#include <readline/readline.h>
#else
#ifdef GETLINE
#include <getline.h>
#endif
#endif

#define TRUE 1
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#include <stddef.h>
#endif

/* Wierd macros for handling ansi/non-ansi prototypes */
#if ANSI || __GNUC__ || __STDC__
#define AND ,
#define DEFUN(a,b) ( b )
#define VOIDFUNC ( void )
#define _PROTO(a) a
#else
#define AND ;
#define DEFUN(a,b) a b;
#define _PROTO(a) ()
#define VOIDFUNC ( )
#endif

/* For firewall use: 
 * Define FIREWALL to be the minumum local port to use for outgoing connections
 * and FIREWALL_MAX to be the maximum port. LOCAL_PORT - LOCAL_PORT_MAX are
 * the port range over which we will accept connections for resident goofeys
 */
#ifdef FIREWALL
# ifndef FIREWALL_MAX
#  define FIREWALL_MAX FIREWALL
# endif
# ifndef LOCAL_PORT
#  define LOCAL_PORT FIREWALL
# endif
# ifndef LOCAL_PORT_MAX
#  define LOCAL_PORT_MAX FIREWALL_MAX
# endif
#endif

#ifndef LOCAL_PORT
# define LOCAL_PORT 0
#endif

#ifndef LOCAL_PORT_MAX
# define LOCAL_PORT_MAX LOCAL_PORT
#endif

/* Portability stuff: if we don't have fd_set or FD_SET,etc macros
 * then make them up.
 */
#ifndef FD_SET
# ifndef SUNOS3
typedef struct fd_set { int fds_bits[1]; }  fd_set;
# endif
# define FD_ZERO(fd) ((fd)->fds_bits[0] = 0)
# define FD_SET(b, fd) ((fd)->fds_bits[0] |= 1 << (b))
# define FD_ISSET(b, fd) ((fd)->fds_bits[0] & 1 << (b))
# define FD_SETSIZE 32
#endif

/* Handle bsd/sysv differences with string handling */
#if STDC_HEADERS || HAVE_STRING_H
#include <string.h>
/* An ANSI string.h and pre-ANSI memory.h might conflict.  */
#if !STDC_HEADERS && HAVE_MEMORY_H
#include <memory.h>
#endif /* not STDC_HEADERS and HAVE_MEMORY_H */
#define index strchr
#define rindex strrchr
#define bcopy(s, d, n) memcpy ((d), (s), (n))
#define bcmp(s1, s2, n) memcmp ((s1), (s2), (n))
#define bzero(s, n) memset ((s), 0, (n))
#else /* not STDC_HEADERS and not HAVE_STRING_H */
#include <strings.h>
/* memory.h and strings.h conflict on some systems.  */
#endif /* not STDC_HEADERS and not HAVE_STRING_H */

#ifndef RETSIGTYPE
#define RETSIGTYPE void
#endif

static struct sockaddr_in pluto_host;
char * build_arrived_string _PROTO((int));
void check_alloc _PROTO((void *, int));
int connect_to_server _PROTO((void));
void do_resize _PROTO((char **,int *,int,char *));
void establish_signal_handlers _PROTO((void));
char * get_my_tty _PROTO(());
void go_find_a_port _PROTO((void));
void print_help _PROTO((void));
void process_flags _PROTO((char **));
void request_handler _PROTO((void));
void say_hi_to_server _PROTO((int));
long when_last_keypress _PROTO((void));
void write_str _PROTO((int, char *));
void check_size _PROTO((void));
void process_env _PROTO((void));
void generate_password _PROTO((void));
char * get_message _PROTO((char **));
int write_goof _PROTO((char *s , char *name));
extern char *getenv();

int    local_sock;
int    ppid; /* Parent process id */
int    port_no; /* Port number we have reserved for ourselves at this end */
int    want_help;
int    reconnect_retries; /* Number of tries left to reconnect to the server */
int    width; /* Width I think my terminal is */
int    multipart; /* A kluge to handle multipart messages */
int    lonely_timer; /* How long is it since we've spoken/heard from server? */

#define REREGISTER_TIME 600 /* How long to wait before re-registering */

#define RESIZE(m,l,x,s) do_resize(&m,&l,x,s)

/* Where the server resides. Can be changed at command line. */
char machine_name[50] = SERVER_HOSTNAME;
int port_number = SERVER_PORT_NO;
char optstring[100] = "P";
int broke_shutdown;
char session_pwd[20];

int
main DEFUN((argc,argv), int argc AND char ** argv)
{
    check_size();
    process_env();
    process_flags(argv);  /* This may exit() if goofey is non-resident */
    if (when_last_keypress() < 0)  {
	fprintf(stderr,
	    "\rgoofey: Parent process died, exiting\n");
	exit(0);
    }
    go_find_a_port();			/* Assumed to work or die. */
    generate_password();
    say_hi_to_server(1);

    ppid = getppid();

    if (fork()) {
	exit(0); /* In parent */
    }
    else {
	fd_set mask;
	struct timeval tv;
	establish_signal_handlers(); 
	while(1) {
	    request_handler();
	    while (reconnect_retries) {
		int i;
		FD_ZERO(&mask);
		FD_SET(local_sock, &mask);
		tv.tv_sec = LONELY_INTERVAL;
		tv.tv_usec = 0;
		i=select(local_sock+1,&mask,0,0,&tv);
		if (i==1)
		    request_handler();
		if (i<0 && errno != EINTR) {
		    fprintf(stderr,"\rSomething has happened to my socket!\n");
		    exit(1);
		}
		say_hi_to_server(0);
	    }
	}
    }
}

void
check_size VOIDFUNC
{
#ifdef TIOCGWINSZ
    struct winsize ws;
#endif
    
    if (isatty(1)) {
	char *s;
#ifdef TIOCGWINSZ
	if (ioctl(1,TIOCGWINSZ,&ws))
	    return;
	width = ws.ws_col;
#endif
	s = getenv("COLUMNS");
	if (s)
	    width = atoi(s);
    }
}

int
autoSplit VOIDFUNC
{
    return strchr(optstring, 'A') != 0;
}

void
say_hi_to_server DEFUN((disp), int disp)
{
    int	sock;
    char	*mesg;
    char buf[100];
    int  i;

    sock = connect_to_server();	 /* Works or dies. */
    if (sock < 0) return;
    mesg = build_arrived_string(1);
    if (broke_shutdown) {
	sprintf(buf,"!%03x",strlen(mesg));
	write_str(sock,buf);
	write_str(sock,mesg);    /* Send the initial message */
	write_str(sock,"!000");  /* Send "eof" */
    } else {
	write_str(sock,mesg);    /* Send the initial message */
	shutdown(sock,1); /* Send Eof */
    }
    while ((i = read(sock,buf,(sizeof buf)-1)) > 0) {
	buf[i] = 0;
	if (disp)
	    printf("%s",buf);
	if (broke_shutdown && !buf[i-1])
	    break;
    }
    fflush(stdout);
    close(sock);
}

void
generate_password VOIDFUNC
{
    char *tmp = build_arrived_string(0);
    int i;
    unsigned long seed = time(0L);
    seed ^= (getpid() << 16) | (getppid());
    for (i=0;tmp[i];i++)
	seed ^= (tmp[i] << ((i%4) * 8));
    sprintf(session_pwd, "%08lx", seed);
}

void
die VOIDFUNC
{
    int sock;
    char buff[1024];
    sock = connect_to_server();	 /* Works or dies. */
    sprintf(buff,"%s,%s",build_arrived_string(0),"-2");
    write_str(sock,buff);
    close(sock);/* Say bye to server */
    exit(0);
}

RETSIGTYPE
sigdie DEFUN((sig), int sig)
{
    fprintf(stderr,"\rgoofey: received signal %d, exiting\n",sig);
    die();
}

void
send_and_get_message DEFUN((str1,str2), char * str1 AND char * str2)
{
    int sock;
    fd_set tm;
    struct timeval tout;
    int dont_exit = 0;
    char buff[1025];
    char *b;
    int i;

    sock = connect_to_server();	 /* Works or dies. */
    if (sock < 0) return;
    b = malloc(i=(strlen(build_arrived_string(0)) +
		  strlen(str1) +strlen(str2) + 4));
    check_alloc(b,i);
    if (i > SERVER_MAXREQ) {
	fprintf(stderr,"goofey: server may truncate message. \
Saving to 'dead.goofey' just in case\n");
	if (write_goof(str2,"dead.goofey")) {
	    fprintf(stderr,"goofey: unable to write to file 'dead.goofey'\n");
	}
    }
    sprintf(b,"%s,%s %s\n",build_arrived_string(0),str1,str2);
    if (broke_shutdown) {
	sprintf(buff,"!%03x",strlen(b));
	write_str(sock,buff);
	write_str(sock,b);
	write_str(sock,"!000");
    } else {
	write_str(sock,b);
	shutdown(sock,1); /* Send eof */
    }
    free(b);
    i=1;
    FD_ZERO(&tm);
    FD_SET(sock,&tm);
    while (i>0) {
	tout.tv_usec= 0;
	tout.tv_sec = max_wait;

	if (select(sock +1,&tm,0,0,&tout)<=0) {
	    printf("Pluto failed to reply within %d seconds\n",max_wait);
	    break;
	}
	i = read(sock,buff,(sizeof buff)-1);
	if (i<0) break;
	buff[i]=0;
	if (i && buff[0] == 1) dont_exit = 1;
	printf("%s",buff);
	fflush(stdout);
	if (broke_shutdown && !buff[i-1])
	    break;
    }
    close(sock);/* Say bye to server */
    if (dont_exit) return;
    if (multipart) return;
    exit(0);  /* The normal exit point for non-resident goofeys */
}
    
RETSIGTYPE
lonely DEFUN((ignored), int ignored)
{ /* Am I lonely and forgotten ? */
    int i;
    i = when_last_keypress();

    if (i < 0) {
	fprintf(stderr,"\rgoofey: parent process died, exiting\n");
	die();
    }

    signal(SIGALRM,lonely);
    alarm(LONELY_INTERVAL);
    lonely_timer += LONELY_INTERVAL;
    if (lonely_timer > REREGISTER_TIME) {
	int tmp = reconnect_retries;
	reconnect_retries = 2; /* just in case this fails */
	say_hi_to_server(0);
	reconnect_retries = tmp;
    }
}

int
allspace DEFUN((s), char *s)
{
    while (s && *s && isspace(*s)) s++;
    if (!s || !(*s)) return 1;
    return 0;
}

char *
get_users_name VOIDFUNC
{/* Find out the users name, do not modify this code unless absolutely
  * necessary (for your own protection)
  */
    static char *name;
    if (name) return name;
    if (!name || allspace(name))
	name = getenv("GOOFEYUSER");
    if (!name || allspace(name))
	name = getenv("USER");
    if (!name || allspace(name))
	name = getenv("LOGNAME");
    if (!name || allspace(name))
	name = "unknown";
    return name;
}

char *
build_arrived_string DEFUN((force), int force)
{
    /* Construct an arrived message giving details of the assigned port
     * number and the username etc. */

    static char data[300];
    char buf[100];
    char *loc,*s;
    struct stat st;
    static done,port,wid;

    if (done && port==port_no && wid == width && !force) return data;
    done =1;
    port = port_no;
    wid = width;
    sprintf(buf,"%s/%s",getenv("HOME"),PWD_FILE);
    if (stat(buf,&st))
	buf[0]=0;
    else {
	FILE *f;
	if (st.st_mode & 077) {
	    fprintf(stderr,"goofey: warning %s should have permission 0600!\n",
		buf);
	    fprintf(stderr,"goofey: type 'chmod 600 %s' to fix this\n",buf);
	}
	f = fopen(buf,"r");
	buf[0] = 0;
	if (f) {
	    fread(buf,1,10,f);
	    fclose(f);
	    buf[10] = 0;
	}
    }
	
    if (strchr(optstring,'S'))
	broke_shutdown = 1;

    loc = getenv("GOOFEYLOC");
    if (loc)
	for (s = strchr(loc, '&') ; s ; s = strchr(s+1, '&'))
	    *s = '*';
    
    sprintf(data,"#%c%s%s%s,|%d,%s%s%s#%s,%s,%s,%d,%s",CLIENT_TYPE,VERSION,
	*optstring?",@":"",optstring,
	width, 
	loc?"&":"", loc?loc:"", loc?"&,":"",
	session_pwd,
	get_users_name(),buf,port_no,get_my_tty() );
    return data;
}

void
go_find_a_port VOIDFUNC
{
    /* Allocate a port that the server can query this client through */

    int length;
    int count;
    struct sockaddr_in local_server;

    local_sock = socket(AF_INET,SOCK_STREAM,0);
    if (local_sock <0) {
	perror ("Opening stream socket :- couldn't get a socket");
	exit(1);
    }

    bzero(&local_server,sizeof local_server);
    local_server.sin_family = AF_INET;
    local_server.sin_addr.s_addr = INADDR_ANY;

    for (count = LOCAL_PORT; count <= LOCAL_PORT_MAX;count++) {
	local_server.sin_port = htons(count);
	if (bind(local_sock,(struct sockaddr *) &local_server,
		 sizeof local_server) == 0)
	    break;
    }
    if (count > LOCAL_PORT_MAX) {
	fprintf(stderr,
	    "goofey: couldn't allocate local port\n");
	exit(1);
    }

    length = sizeof local_server;
    if (getsockname(local_sock,(struct sockaddr *)&local_server,&length) <0) {
	perror("getsockname");
	exit(1);
    } /* Have established a port which the clock local_server may use to
	* interrogate this process.
       */

    port_no = ntohs(local_server.sin_port);
#ifdef DIAGNOSTICS
    fprintf(stderr,"%s\n",inet_ntoa(local_server.sin_addr));
    printf("Socket port #%d\n",ntohs(local_server.sin_port));
#endif
}

long 
when_last_keypress VOIDFUNC
{
    struct stat my_stat;
    if (kill(ppid,0)) return -3;  /* My daddy is dead :( */
    if (stat(get_my_tty(),&my_stat)) return I_DONT_KNOW;
    if (time(0) < my_stat.st_mtime) return 0;
    return time(0) - my_stat.st_mtime;
}

char *
get_my_tty VOIDFUNC
{
    char *ttyname();
    char *s;
    static set;
    static char buffer[30];

    if (set) return buffer;
    s = ttyname(0);
    if (!s) strcpy(buffer,"/dev/notatty");
    else strcpy(buffer,s);
    set =1;
    return buffer;
}

void
request_handler VOIDFUNC
{
    int msgsock;
    char buf[1024];
    struct sockaddr_in addr;
    int len = sizeof addr;
    char *msg=0;
    int rval,size=0;
    long int last=0;

    msgsock = accept(local_sock,(struct sockaddr *)&addr,(int *)&len);
    if (msgsock == -1) 
	return;

    lonely_timer = 0;

    do {
	if ((rval = read(msgsock,buf,1023)) < 0) {
	    if (errno != EINTR) {
		perror("Handling clock request.");
		break;
	    }
	} else {
	    if (size == 0) {
		if (strchr("ZW",*buf)) {
		    char tmp[100];
		    sprintf(tmp,"%ld\n",last=when_last_keypress());
		    write_str(msgsock,tmp);
		}
	    }
	    RESIZE(msg,size,rval,buf);
	}
    } while (rval != 0);
    if (last < 0) {
	fprintf(stderr,"\rGoofey: parent process has died, exiting\n");
	exit(0);
    }
    if (msg) {
	if (*msg && strncmp(msg+1, session_pwd, strlen(session_pwd))) {
	    fprintf(stderr,"\n\rGoofey: Message received from %s with invalid session password (intruder?)\n",inet_ntoa(addr.sin_addr));
	    free(msg);
	    close(msgsock);
	    return;
	}
	msg[size] = 0;
	switch(msg[0]) {
	    case 'S':
		/* Attempt to reconnect to clock at 1 minute intervals */
		reconnect_retries=MAX_RETRIES;
		break;
	    case 'W':
		/* Return time since last keypress */
		break;

	    case 'Z':
		/* Why not. */
	    {
		struct stat times;
		time_t timeout[2];
		int doit;
		doit = stat(get_my_tty(),&times); 
		    /* Store the access and mod times */
		puts(msg+1+strlen(session_pwd)); /* Output a message */
		/* Reset the access and modify time to value before blatting */
		if (!doit) {
		    timeout[0] = times.st_atime;
		    timeout[1] = times.st_mtime;
		    utime(get_my_tty(),timeout);
		}
		break;
	    }

	    case 'E':
		/* Exit */
		close(local_sock);
		close(msgsock);
		sleep(1);
		fprintf(stderr,
	    "\rgoofey: resident goofey killed by server at your request\n");
		exit(0);

	    default:
		write_str(msgsock,"Unknown command to goofey\n");
	}
	free(msg);
    }
    close(msgsock);
}

void
find_inet_addr DEFUN((ad), struct sockaddr_in * ad)
{/* Find address by lookup __once__ */
    struct hostent *hp, *gethostbyname();
    static int done=0;   /* Have I found it yet? */
    ad->sin_family = AF_INET;
    if (done) {
	ad->sin_addr.s_addr = pluto_host.sin_addr.s_addr;
	return;
    }

    pluto_host.sin_addr.s_addr = inet_addr(machine_name); 
	/* Is it a 130.x.x.x ? */
    if (pluto_host.sin_addr.s_addr != -1) { /* YES! */
	pluto_host.sin_family = AF_INET;
    } else {/* Must be a hostname */
	hp = gethostbyname(machine_name);
	if (hp) {
	    pluto_host.sin_family = hp->h_addrtype;
#if     defined(h_addr)	 /* In 4.3, this is a #define */
	    bcopy(hp->h_addr_list[0],(caddr_t)&pluto_host.sin_addr,
		 hp->h_length);
#else   /* defined(h_addr) */
	    bcopy(hp->h_addr,(caddr_t)&pluto_host.sin_addr, hp->h_length);
#endif  /* defined(h_addr) */
	} else {
	    fprintf(stderr,"%s: unknown host\n", machine_name);
	    exit(2);
	}
    }
    ad->sin_addr.s_addr = pluto_host.sin_addr.s_addr;
    done =1;
}

int
connect_to_server VOIDFUNC
{
    /* Establish connection with the central server */

    int sock;
    int res;
    struct sockaddr_in server;

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock<0) {
	perror("opening stream socket");
	exit(1);
    }
    bzero(&server,sizeof server);
    server.sin_family = AF_INET;
#ifdef FIREWALL
    {
	int count;
	server.sin_addr.s_addr = INADDR_ANY;
	for (count = FIREWALL; count <= FIREWALL_MAX;count++) {
	    server.sin_port = htons(count);
	    if (bind(sock,(struct sockaddr *) &server,
		     sizeof server) == 0)
		break;
	}
	if (count > FIREWALL_MAX) {
	    fprintf(stderr,
		"goofey: couldn't allocate local port for firewall\n");
	    exit(1);
	}
    }
#endif

    find_inet_addr(&server);
    server.sin_port = htons(port_number);

#define NONBLOCK_BROKE
#ifndef NONBLOCK_BROKE
# ifdef FNDELAY
    if (fcntl(sock,F_SETFL,FNDELAY))
# else
    if (fcntl(sock,F_SETFL,O_NONBLOCK))
# endif
    {
	perror("Setting non blocking mode on connecting socket");
	exit(1);
    }
#endif

    res = connect(sock,(struct sockaddr *)&server,sizeof server);
#ifndef NONBLOCK_BROKE
    /* These #if's are a bit ugly ... if nonblocking is broken for some
     * reason then don't fcntl and don't select.
     */
    signal(SIGPIPE,SIG_IGN);
    if ( res < 0 && (errno == EWOULDBLOCK || errno == EAGAIN)) {
	fd_set tm;
	struct timeval tout;
	tout.tv_usec= 0;
	tout.tv_sec = max_wait;
	FD_ZERO(&tm);
	FD_SET(sock,&tm);
	res =  select(sock+1,0,&tm,0,&tout);
	if (res > 0) {
	    res = connect(sock,(struct sockaddr *)&server,sizeof server);
	    if (res < 0 && errno == EISCONN)
		res = 1;
	}
    } else 
#else
    /* If non blocking is broken then set res to 1 if the connect succeeded */
    if ( ! res)
#endif
    {
	res = 1;
    }
	
    if (res <= 0) {
	if (reconnect_retries > 1) {
	    close(sock);
	    sock = -1;
	    reconnect_retries--;
	} else if (reconnect_retries == 1) {
	    fprintf(stderr,"\rGoofey: lost connection to server\n");
	    exit(1);
	} else {
	    if (res < 0)
		fprintf(stderr,
		    "goofey: The server is currently unavailable.\n");
#ifndef NONBLOCK_BROKE
	    else
		fprintf(stderr,
		    "goofey: Timed out while connecting to server.\n");
#endif
	    if (want_help) print_help();
	    exit(1);
	}
    } else {
	reconnect_retries=0;
	lonely_timer = 0;
    }
#ifndef NONBLOCK_BROKE
    signal(SIGPIPE,SIG_DFL);
    fcntl(sock,F_SETFL,0);
#endif
    return sock;
}

void
write_str DEFUN((sock,mesg),int sock AND char *mesg)
{
    if (write(sock,mesg,strlen(mesg)) <0)
	perror("writing on stream socket");
}

#ifdef SIGWINCH
RETSIGTYPE
size_change DEFUN((ignored),int ignored)
{
    int owidth;
    owidth = width;
    check_size();
    say_hi_to_server(0);
}
#endif

void
establish_signal_handlers VOIDFUNC
{
    signal(SIGINT,sigdie);
    signal(SIGQUIT,sigdie);
    signal(SIGHUP,sigdie);
    signal(SIGALRM,lonely);
    signal(SIGTTOU,SIG_IGN);
#ifdef SIGWINCH	
    signal(SIGWINCH,size_change);
#endif
    alarm(LONELY_INTERVAL);

    listen(local_sock,5);
}

/* -------------------------------------------------------------------- *
 * Command line processing					      *
 * -------------------------------------------------------------------- */

int
check_split_arg DEFUN((argv,i),char ** argv AND int * i)
{
    /* Some people get stressed when asked to provide options immediately
     * after the command line flag, so we will give them the option of
     * supplying the option with a space !!
     * This routine advances the i variable if necessary etc.
     */

     ++argv[*i]; /* Advance past the flag itself */
     if (!strlen(argv[*i])) {
	/* No more string left for this arg, so try the next one. */
	(*i)++;
	if (!argv[*i]) {
	    /* No more args left, how tragic. */
	    return 0;
	}
	return 1;
    }
    /* Argument follows the flag */
    return 1;
}

struct { char *name; char *opt; } longopts[] = {
    {"no-blat", "B"},
    {"only-one", "1"},
    {"return-response", "R"},
    {"inform-replace", "I"},
    {"forget-fail", "F"},
    {"tag-success", "T"},
    {"format-outgoing","f"},
    {"shutdown-broke","S"},
    {"ignore-alias","E"},
    {"auto-split","A"},
    {0,0}
};

void
process_env VOIDFUNC
{
    char *tmpargv[40];
    char *env = getenv("GOOFEY_ARGS");
    int i = 1;
    if (!env)
	return;
    tmpargv[0] = "goofey";
    while (*env) {
	while (*env && isspace(*env)) env++;
	if (!*env) break;
	if (*env != '+' && !(*env == '-' && env[1] == '-')) {
	    fprintf(stderr,
	"goofey: GOOFEY_ARGS may only contain '+' or '--' args. Ignored\n");
	    return;
	}
	tmpargv[i++] = env;
	while (*env && !isspace(*env)) env++;
	if (*env) {
	    *env = 0;
	    env++;
	}
	if (i == 40 - 1) {
	    fprintf(stderr,"goofey: GOOFEY_ARGS too long, truncated\n");
	    break;
	}
    }
    if (i <= 1)
	return;
    tmpargv[i] = 0;
    process_flags(tmpargv);
}
    
void 
process_flags DEFUN((argv),char **argv)
{
      /* Process flags sequentially */
      int i;
      int ignore_rest = 0;
      int send_message = 0;
      char *m=0;
      int len=0;
      int got_args=0;

      for(i=1;argv[i]!=NULL;i++) {
	    if (i && argv[i-1] == 0) {
		fprintf(stderr,"goofey: missing argument to option\n");
		exit(1);
	    }
	    if (ignore_rest) {
		 /* we have found a piece of plain text */
		RESIZE(m,len,strlen(argv[i]),argv[i]);
		RESIZE(m,len,1," ");
		got_args = 1;
		continue;
	    } else if (*argv[i] == '+') {
		strcat(optstring,argv[i]+1);
		continue;
	    } else if (*argv[i] != '-') {
		fprintf(stderr,"Expected an argument beginning with '-'\n");
		exit(1);
		break;
	    } else if (argv[i][1] == '-') {
		/* Handle --options */
		char *s; 
		int j;
		argv[i]+=2;
		s = argv[i];
		if (!strncmp(s,"port",4) || (*s == 'p' && !isalpha(s[1]))) {
		    if ((s = strchr(s,'='))) {
			port_number = atoi(s+1);
		    } else {
			port_number = atoi(argv[++i]);
		    }
		    continue;
		} else if (!strncmp(s,"machine",7) ||
			(*s == 'm' && !isalpha(s[1]))) {
		    if ((s = strchr(s,'='))) {
			strcpy(machine_name,s+1);
		    } else {
			if (argv[++i])
			    strcpy(machine_name,argv[i]);
		    }
		    continue;
		} else if (!strncmp(s,"width",5)) {
		    if ((s = strchr(s,'='))) {
			width = atoi(s+1);
		    } else {
			width = atoi(argv[++i]);
		    }
		    continue;
		} else if (!strncmp(s,"timeout",7)) {
		    if ((s = strchr(s,'='))) {
			max_wait = atoi(s+1);
		    } else {
			max_wait = atoi(argv[++i]);
		    }
		    continue;
		} else {
		    for (j = 0;longopts[j].name;j++)
			if (!strcmp(s,longopts[j].name)) {
			    strcat(optstring,longopts[j].opt);
			    break;
			}
		    if (longopts[j].name)
			continue;
		}
	    }
	    while (*(++argv[i])!= 0) {
	     switch(*(argv[i])) {
		case 'v':
		    printf("Goofey version %s\n",VERSION);
		    break;
		case 's':
		    /* Send message to user */
		    if (!check_split_arg(argv,&i)) {
			fputs("Expected user's name.\n",stderr);
			print_help();
			exit(1);
		    }
		    RESIZE(m,len,2,"*s");
		    RESIZE(m,len,strlen(argv[i]),argv[i]);
		    RESIZE(m,len,1," ");
		    send_message = ignore_rest = 1;
		    *(argv[i]+1)= 0;
		    break;
		case 'h':
		    want_help = 1;
		default: {
                    XXX
		    /* Goofey doesn't understand the command, so send it to the
		     * clock. */
		    
		    RESIZE(m,len,1,"*");
		    RESIZE(m,len,strlen(argv[i]),argv[i]);
		    RESIZE(m,len,1," ");
		    *(argv[i]+1)= 0;
		    ignore_rest = 1;
		}
	    }
	}
    }
    if (m) {
	char *n;
	if (send_message && !got_args) {
	    n = get_message(&m);
	    if (!n) {
		fprintf(stderr,"goofey: Empty message: not sent!\n");
		exit(0);
	    }
	    if (autoSplit()) {
		int otherlen = strlen(m) + strlen(build_arrived_string(0)) + 5;
		if (strlen(n) + otherlen > SERVER_MAXREQ) {
		    char *tmp, *end, *orig, old;
		    int part = 0;
		    fprintf(stderr, 
			"goofey: message exceeds maximum, autosplitting...\n");
		    tmp = n;
		    multipart = 1;
		    while (*tmp) {
			end = tmp + strlen(tmp);
			if (end - tmp > SERVER_MAXREQ - otherlen) {
			    end = tmp + SERVER_MAXREQ - otherlen;
			}
			orig = end;
			while (end > tmp && *end && *end != '\n') end--;
			if (end == tmp) {
			    end = orig;
			} else if (*end) {
			    end++;
			}
			old = *end;
			*end = 0;
			part++;
			fprintf(stderr,"goofey: sending part %d\n", part);
			send_and_get_message(m,tmp);
			*end = old;
			tmp = end;
		    }
		    fprintf(stderr,"goofey: Message sent in %d parts\n",part);
		    exit(0);
		} else {
		    send_and_get_message(m,n?n:"");
		}
	    } else {
		send_and_get_message(m,n?n:"");
	    }
	    if (n)
		free(n);
	} else {
	    send_and_get_message(m,"");
	}
	free(m);
    }
}

char *
editor VOIDFUNC
{
    int l;
    static char *e;
    char *ed;
    if (e)
	return e;
    ed=getenv("VISUAL");
    if (!ed)
    {
	ed=getenv("EDITOR");
	if (!ed)
	    ed="vi";
    }
    l=strlen(ed);
    e=malloc(++l);
    check_alloc(e,l);
    strcpy(e, ed);
    return e;
}

int
write_goof DEFUN((s, name), char *s AND char *name)
{
    int fd;
    int len=0;
    fd = creat(name, 0600);
    if (fd < 0) {
	return 1;
    }
    if (s) {
	len = strlen(s);
	if (len != write(fd, s, len)) {
	    unlink(name);
	    close(fd);
	    return 1;
	}
    }
    close(fd);
    return 0;
}

char *
editmsg DEFUN((msg,len), char * msg AND int * len)
{
    FILE *fp = 0;
    char tmpfile[32];
    char buf[500];
    int i;

    for (i = 'a';i<='z';i++) {
	sprintf(tmpfile, "/tmp/goof%05lu%c", (long)getpid(), i);
	if (!write_goof(msg, tmpfile)) {
	    i = 0;
	    break;
	}
    }
    if (i) {
	fprintf(stderr, "goofey: unable to create file '%s'\n", tmpfile);
	return msg;
    }
    sprintf(buf, "%s %s", editor(), tmpfile);
    fprintf(stderr,"goofey: invoking editor (%s)...\n",buf);
    system(buf);
    fp=fopen(tmpfile,"r");
    if (!fp) {
	fprintf(stderr, "\rgoofey: temp file cannot be accessed\n");
	return msg;
    }

    free(msg);	/* We can discard existing msg now */
    msg=0;
    *len=0;
    while (fgets(buf, sizeof(buf)-1, fp)!=NULL) {
	RESIZE(msg,(*len),strlen(buf),buf);
    }
    fclose(fp);

    unlink(tmpfile);
    return msg;
}

char *
readln DEFUN((prompt,extra), char *prompt AND char **extra)
{
    char *ln;
    static char buf[400];
    *extra = 0;
#ifdef READLINE
    if (prompt) {
	ln = readline(prompt);
	*extra = "\n";
    } else
#else
#ifdef GETLINE
    if (prompt) {
	ln = getline(prompt);
    } else
#else
    if (prompt) {
	printf(prompt);
	fflush(stdout);
    }
#endif
#endif
	/* This is called if we have no prompt for GETLINE and READLINE,
	 * and always if neither of them are set
	 */
	{
	    if (!fgets(buf,(sizeof buf)-1,stdin))
		return 0;
	    ln = buf;
	}
    return ln;
}

char *
strip_ws DEFUN((s), char *s)
{
    char *t;
    if (!s)
	return 0;
    while (*s && isspace(*s)) s++;
    for (t = s; *t && !isspace(*t); t++) {
	/* Nothing */
    }
    if (*t)
	*t = 0;
    return s;
}
	
void
save_goof DEFUN((s), char *s)
{
    char *ln;
    char *junk;
    ln = readln("Enter filename to save to> ", &junk);
    ln = strip_ws(ln);
    if (!ln || !*ln) {
	fprintf(stderr,"goofey: Message not saved\n");
	return;
    }
    if (write_goof(s, ln)) {
	fprintf(stderr,"goofey: Could not save to '%s'\n",ln);
	return;
    }
    fprintf(stderr,"goofey: Message saved to '%s'\n",ln);
}

void
read_file DEFUN((str,len), char **str AND int *len)
{
    int pipe = 0;
    char *ln;
    FILE *f;
    char buf[100];
    char *junk;

    ln = readln("File to read from (or !command)> ",&junk);
    if (ln && *ln == '!') {
	f = popen(ln + 1, "r");
	if (!f) {
	    fprintf(stderr,"goofey: could not execute '%s'\n",ln+1);
	    return;
	}
	pipe = 1;
    } else {
	ln = strip_ws(ln);
	if (!ln || !*ln) {
	    return;
	}
	f = fopen(ln, "r");
	if (!f) {
	    fprintf(stderr,"goofey: Could not open file '%s'\n",ln);
	    return;
	}
    }
    while (fgets(buf, sizeof(buf)-1, f)!=NULL) {
	printf("%s",buf);
	RESIZE(*str,(*len),strlen(buf),buf);
    }
    if (pipe) {
	int status;
	status = pclose(f);
	if (status)
	    fprintf(stderr,"goofey: command returned error code %d\n",status);
    } else {
	fclose(f);
    }
    return;
}

void
get_recip DEFUN((recip), char **recip)
{
    char *ln,*junk;
    int len = 0;
    printf("Currently to: %s\n",(*recip)+2);
    ln = readln("Enter (comma separated) list of recipients> ",&junk);
    ln = strip_ws(ln);
    if (!ln || !*ln) {
	fprintf(stderr,"goofey: recipients not changed\n");
	return;
    }
    free(*recip);
    *recip = 0;
    RESIZE(*recip,len,2,"*s");
    RESIZE(*recip,len,strlen(ln),ln);
    RESIZE(*recip,len,1," ");
    fprintf(stderr,"goofey: recipients changed to: %s\n",ln);
}


char *
get_message DEFUN((recip), char **recip)
{
    int prompt=isatty(0);  /* Only prompt on tty's */
    char *s;
    int len;
    char *ln,*extra=0;

    s = 0;
    len = 0;

    if (prompt)
	printf("Enter your message: (blank line or ^D to end, ~h for help)\n");
    while (1) {
	int i;
	fflush(stdout);

	ln = readln(prompt?"> ":0, &extra);
	if (ln && (extra || *ln)) {
	    int meta=0;
	    int textlen;
	    textlen = i = strlen(ln);
	    if (ln[i-1] == '\n')
		textlen = i-1;
	    if (prompt && textlen == 2 && *ln=='~') {
		meta=1;
		switch(ln[1]) {
		case 'v':
		case 'e':
		    s = editmsg(s, &len);
		    break;
		case 't':
		    get_recip(recip);
		    break;
		case 'p':
		    printf("[ To: %s]\n",(*recip) + 2);
		    if (s) {
			printf("%s",s);
		    }
		    break;
		case '.':
		    textlen = 0;
		    break;
		case 'q':
		    if (write_goof(s,"dead.goofey")) {
			fprintf(stderr,
			    "goofey: Could not write to file 'dead.goofey'\n");
			break;
		    }
		    fprintf(stderr,
		    	"goofey: Message written to file 'dead.goofey'\n");
		    /* Fall through */
		case 'x':
		    fprintf(stderr,"goofey: Quitting: message not sent\n");
		    exit(0);
		case 'c':
		{
		    int leng;
		    leng = (s?strlen(s):0) + strlen(*recip) +
		    	strlen(build_arrived_string(0)) + 3;
		    fprintf(stderr,
			"goofey: Total message length is %d which %s\n", leng,
			    (leng>SERVER_MAXREQ)?
		       (autoSplit()?"will result in split": "exceeds maximum"):
			    "is OK!");
		    break;
		}
		case 'w':
		    save_goof(s);
		    break;
		case 'r':
		    read_file(&s, &len);
		    break;
		case '?':
		case 'h':
		    printf(
"~ commands for goofey message editing:\n\
~e, ~v: Edit message using editor\n\
~p:     Print current message\n\
~.:     End message (don't use this if you're using rlogin!).\n\
~w:     Write message to a file (you will be prompted for a filename)\n\
~r:     Read from a file or command.\n\
~q:     Quit, save message in dead.goofey, don't send\n\
~x:     Quit, don't send, don't save\n\
~t:     Re-enter recipients (will prompt for recipients)\n\
~c:     Check message length\n\
~h, ~?: Print help\n"
		    );
		    break;
		default:
		    fprintf(stderr,
			"goofey: Unknown ~ command. Use ~h for help\n");
		    break;
		}
	    }
	    if (prompt && (textlen==0 || (textlen==1 && *ln=='.')))
		break;          /* Exit if empty line or '.'is entered */
	    if (!meta) {
		RESIZE(s,len,i,ln);
		if (extra)
		    RESIZE(s,len,strlen(extra),extra);
	    }
	} else
	    break;
    }
    return s;
}

void
print_help VOIDFUNC
{
puts("\
Usage: goofey [-v] [options]* [command]\n\
    -v       : prints the version number\n\
    -h       : prints help.\n\
    --width=Width : set terminal width for this client\n\
    --port=PortNumber   : Specify port number where server lives.\n\
    --machine=MachineName  : Specify machine where server lives.\n\
    --no-blat : request server to send no blat message\n\
    --only-one : server will only send 1 request per connection\n\
    --return-response : server will redirect response for pages to caller\n\
    --inform-replace : will generate GOOF IN messages on client replace\n\
    --forget-fail : messages that don't get through are not buffered\n\
    --tag-success : server will add an extra character for failed messages\n\
    --format-outgoing : server will line wrap your message for you\n\
    --shutdown-broke : do not use the 'shutdown' system call\n\
\n\
The server may have further help when it is available\n\
");
}

void
check_alloc DEFUN((v,i),void * v AND int i)
{
    if (v==0) {
	fprintf(stderr,"\rGoofey: memory allocation (%d bytes) failed!\n",i);
	exit(1);
    }
}

void
do_resize DEFUN((m,l,x,s), char **m AND int *l AND int x AND char *s)
{/* Resize an block of memory */
    if (*m) 
	*m = realloc(*m,(*l)+x+2);
    else 
	*m = malloc(x+2);
    check_alloc(*m,*l + x +2);
    bcopy(s,(*m)+(*l),x);
    *l+=x;
    (*m)[*l]=0;
}

#ifdef READLINE
char *
xmalloc (int bytes)
{
    char *temp = (char *)malloc (bytes);

    check_alloc(temp,bytes);
    return (temp);
}

char *
xrealloc (char *pointer, int bytes)
{
    char *temp;

    if (!pointer)
	temp = (char *)xmalloc (bytes);
    else
	temp = (char *)realloc (pointer, bytes);

    check_alloc(temp,bytes);
    return (temp);
}
#endif

