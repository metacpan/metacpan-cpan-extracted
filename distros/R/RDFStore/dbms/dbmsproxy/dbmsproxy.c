/* DBMS Proxy
 *
 * Copyright (c) 2005 Asemantics S.R.L., All Rights Reserved.
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <sys/uio.h>
#include <unistd.h>
#include <string.h>
#include <strings.h>
#include <stdlib.h>
#include <errno.h>
#ifdef RDFSTORE_PLATFORM_DARWIN
#include <stdint.h>
#endif
#include <unistd.h>

#include <dbms.h>
#include <dbms_comms.h>

#include "dbmsproxy.h"

#define RBUFF (1024)
#define WBUFF (1024)

#ifndef pdie
#define pdie(x) { perror(x); exit(1); }
#endif

#ifndef max
#define max(x,y) (((x) > (y)) ? (x) : (y))
#endif

FILE *errorout;
int verbose = 0, debug = 0, trace_on = 0, sysloglog = 1, stderrlog = 0;

static void childied(int i)
{
    return;
}

static void _log(int level, char *msg,...)
{
}

static void select_loop(void);
static int process(unsigned char *cmd_buff, int r, unsigned char *out_buff, int *w, int maxw);

int sockfd;
dbms *dc;
fd_set rset, wset, eset, alleset, allrset, allwset;
int maxfd;

static void usage(const char *s)
{
    fprintf(stderr, "Syntax: %s "
	    "[-U | -u <userid>] "	/* run as user */
	    "[-e <file>]"	/* error log */
	    "[-P <pid-file>] "	/* write pid file to */
	    "[-d <directory_prefix>] "	/* chroot */
	    "[-p <socket-device (default is " UNIX_SOCK ")>] "	/* unix datagram socket
								 * path */
	    "[-X] "		/* max error debuggin */
	    "[-t] "		/* tracing */
	    "[-D] "		/* do not detach */
	    "[-v] "		/* version */
	    "<dbms url>\n", s);
    exit(1);
}

int main(int argc, char *argv[])
{
    struct sockaddr_un server;
    char *sockpath = UNIX_SOCK;
    int dtch = 1;
    char *as_user = USER;
    struct sigaction act, oact;
    char *my_dir = DIR_PREFIX;
    char *pid_file = PID_FILE;
    int i, len;
    char *pname = argv[0];
    char ch;
    errorout = stderr;

    while ((ch = getopt(argc, argv, "p:d:u:UP:xDtvXe:Eh")) != -1)
	switch (ch) {
	case 'p':
	    sockpath = optarg;
	    break;
	case 'd':
	    my_dir = optarg;
	    break;
	case 'u':
	    as_user = optarg;
	    break;
	case 'U':
	    as_user = NULL;
	    break;
	case 'P':
	    pid_file = optarg;
	    break;
	case 'x':
	    verbose++;
	    debug++;
	    if (debug > 2)
		dtch = 0;
	    break;
	case 'D':
	    dtch = 0;
	    break;
	case 't':
	    trace_on = 1;
	    break;
	case 'v':
	    printf("Version:        %s\n", VERSION);
	    printf("Default dir:    %s\n", DIR_PREFIX);
	    printf("Default device: %s\n", UNIX_SOCK);
	    printf("Default pidfle: %s\n", PID_FILE);
	    exit(0);
	    break;
	case 'X':
	    verbose = debug = 100;
	    dtch = 0;
	    sysloglog = 0;
	    stderrlog = 1;
	    break;
	case 'e':
	    stderrlog = 1;
	    if ((errorout = fopen(argv[++i], "a")) == NULL) {
		fprintf(stderr, "Aborted. Cannot open logfile %s for writing: %s\n",
			argv[i], strerror(errno));
		exit(1);
	    };
	    break;
	case 'E':
	    stderrlog = 1;
	    break;
	case 'h':
	default:
	    usage(pname);
	    break;
	};
    argc -= optind;
    argv += optind;
    if (argc != 1)
	usage(pname);

    {
	char *uri = *argv;
	char *host = NULL;
	char *db = NULL;
	int port = 0;
	if (!strncasecmp(uri, "dbms://", 7))
	    uri += 7;
	if ((db = index(uri, '/'))) {
	    char *p;
	    host = uri;
	    *db = '\0';
	    db++;
	    if ((p = index(host, ':'))) {
		*p = '\0';
		port = atoi(p++);
	    };
	}
	else {
	    db = uri;
	};

	if (!(dc = dbms_connect(db, host, port, DBMS_XSMODE_RDONLY, NULL, NULL, NULL, NULL, 0)))
	    pdie(dbms_get_error(NULL));
    };

    if (sysloglog)
	openlog(pname, LOG_LOCAL4, LOG_PID | LOG_CONS);

    unlink(sockpath);		/* XX warn, etc.. */

    if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)
	pdie("Could not open socket");

    memset(&server, 0, sizeof(server));
    server.sun_family = SOCK_STREAM;
    strncpy(server.sun_path, sockpath, sizeof(server.sun_path) - 1);

#if defined(SCM_RIGHTS) && !defined(RDFSTORE_PLATFORM_LINUX)
    len = sizeof(server.sun_family) + strlen(server.sun_path) + sizeof(server.sun_len) + 1;
    server.sun_len = len;
#else
    len = strlen(server.sun_path) + sizeof(server.sun_family);
#endif

    if ((bind(sockfd, (struct sockaddr *) & server, len)) < 0)
	pdie("Cannot bind server to unix domain socket.");

    if (listen(sockfd, 0) < 0)
	pdie("Could not start to listen to my port");

    /*
     * fork and detach if ness.
     */
    if (dtch) {
	pid_t pid;
	fclose(stdin);
	if (!trace_on)
	    fclose(stdout);
	if ((pid = fork()) < 0) {
	    perror("Could not fork");
	    exit(1);
	}
	else if (pid != 0) {
	    FILE *fd;
	    if (!(fd = fopen(pid_file, "w"))) {
		fprintf(stderr, "Warning: Could not write pid file %s:%s",
			pid_file, strerror(errno));
		exit(1);
	    };
	    fprintf(fd, "%d\n", (int) pid);
	    fclose(fd);
	    exit(0);
	};

	/*
	 * become session leader
	 */
	if ((setsid()) < 0)
	    pdie("Could not become session leader");
    };

    /*
     * XXX security hole.. fix ..
     */
    if (as_user != NULL) {
	struct passwd *p = getpwnam(as_user);
	uid_t uid;

	uid = (p == NULL) ? atoi(as_user) : p->pw_uid;

	if (!uid || setuid(uid)) {
	    perror("Cannot setuid");
	    exit(0);
	};
    };

    chdir(my_dir);		/* change working directory */
    chroot(my_dir);		/* for sanities sake -- must be after things
				 * like pid file where written */
    umask(0);			/* clear our file mode creation mask */

    FD_ZERO(&allrset);
    FD_ZERO(&allwset);
    FD_ZERO(&alleset);

    FD_SET(sockfd, &allrset);
    FD_SET(sockfd, &alleset);

    maxfd = sockfd;
    _log(LOG_NOTICE, "Waiting for connections on %s", sockpath);

#if 0
    signal(SIGHUP, dumpie);
    signal(SIGUSR1, loglevel);
    signal(SIGUSR2, loglevel);
    signal(SIGINT, cleandown);
    signal(SIGQUIT, cleandown);
    signal(SIGKILL, cleandown);
    signal(SIGTERM, cleandown);
#endif
    signal(SIGCHLD, childied);

    /*
     * for now, SA_RESTART any interupted PIPE calls
     */
    act.sa_handler = SIG_IGN;
    sigemptyset(&act.sa_mask);
    act.sa_flags = SA_RESTART;
    sigaction(SIGPIPE, &act, &oact);

    select_loop();
    return 0;			/* keep the compiler happy.. */
}


void select_loop(void)
{
    unsigned char *rbuff[FD_SETSIZE], *wbuff[FD_SETSIZE];
    int fd, w[FD_SETSIZE], r[FD_SETSIZE];

    for (;;) {
	struct timeval np = {600, 0};	/* seconds and micro seconds. */
	int n;

	rset = allrset;
	wset = allwset;
	eset = alleset;

	if ((n = select(maxfd + 1, &rset, &wset, &eset, &np)) < 0) {
	    if (errno != EINTR)
		_log(LOG_ERR, "RWE Select Probem %s", strerror(errno));
	    continue;
	};

#if 0
	/* We've been idle for 600 seconds (np above) */
	if (n == 0)
	    exit(0);
#endif

	/*
	 * Is someone knocking on our front door ?
	 */
	if (FD_ISSET(sockfd, &rset)) {
	    struct sockaddr_in client;
	    int len = sizeof(client);

	    if ((fd = accept(sockfd,
			     (struct sockaddr *) & client, &len)) < 0) {
		_log(LOG_ERR, "Could not accept");
	    }
	    else {
		/* activate select on my connection */
		FD_SET(fd, &allrset);
		FD_SET(fd, &alleset);
		maxfd = max(maxfd, fd);
		rbuff[fd] = malloc(RBUFF);
		wbuff[fd] = malloc(WBUFF);
		r[fd] = 0;
		w[fd] = 0;
	    };
	}			/* knock on the door */

	for (fd = 0; fd <= maxfd; fd++) {
	    int cc = 0;

	    if (fd == sockfd)
		continue;

	    if (FD_ISSET(fd, &rset)) {
		int n;
		if (r[fd] > RBUFF) {
		    _log(LOG_ERR, "Closed due to rbuffer overfilling");
		    goto _c;
		};
		n = read(fd, rbuff[fd], RBUFF);
		if (n == 0) {
		    _log(LOG_DEBUG, "Closed after zero read (normal close)");
		    goto _c;
		}
		else if ((n < 0) && (errno != EINTR) && (errno != EAGAIN)) {
		    _log(LOG_ERR, "Closed after read error");
		    exit(0);
		}
		else if (n > 0) {
		    int p;
		    r[fd] += n;
		    p = process(rbuff[fd], r[fd], wbuff[fd], &w[fd], WBUFF);
		    if (p) {
			if (p < 0) {
			    _log(LOG_ERR, "Output buffer overflow");
			    goto _c;
			};
			r[fd] -= p;
			if (r[fd] > 0) {
			    memcpy(rbuff, rbuff[fd] + p, r[fd]);
			}
			else {
			    r[fd] = 0;
			}
			FD_SET(fd, &allwset);
			cc = 1;
		    }
		}
	    }
	    if (cc | FD_ISSET(fd, &wset)) {
		int n = write(fd, wbuff[fd], w[fd]);
		if ((n == 0) && w[fd]) {
		    _log(LOG_DEBUG, "Closed on zero write");
		    goto _c;
		}
		else if ((n < 0) && (errno != EINTR) && (errno != EAGAIN)) {
		    _log(LOG_ERR, "Closed after write error");
		    goto _c;
		}
		else if (n > 0) {
		    w[fd] -= n;
		    if (w[fd] > 0) {
			memcpy(wbuff[fd], rbuff[fd] + n, w[fd]);
		    }
		    else {
			w[fd] = 0;
			FD_CLR(fd, &allwset);
		    }
		};
	    }
	    if (FD_ISSET(fd, &eset)) {
		_log(LOG_ERR, "Somethinig nasty");
		exit(0);
	    }
	    continue;

    _c:
	    FD_CLR(fd, &allrset);
	    FD_CLR(fd, &allwset);
	    FD_CLR(fd, &alleset);
	    free(rbuff[fd]);
	    free(wbuff[fd]);
	    r[fd] = -1;
	    w[fd] = -1;
	}			/* loop over all FD's */
    }				/* endless for */
}

int process(
	        unsigned char *cmd_buff, int r,
	        unsigned char *out_buff, int *wp,
	        int maxw
)
{
    int at = 0;
    out_buff += *wp;

    /* Request - <1 byte len of key> [ key ] */
    /* Reply <1 byte len>, 1 byte ok/nok, string */

    for (; at < r;) {
	unsigned char *cmd = cmd_buff + at;
	int len = cmd[0];

	char key[256];
	DBT k, val;
	int e;

	/* Wait for more data if there is not a complete packet to process. */
	if (r < len + 1)
	    return at;

	strncpy(key, cmd + 1, len);
	key[len] = '\0';

	at = at + len + 1;

	k.data = key;
	k.size = len;

	if (trace_on)
	    printf("Requesting %s\n", key);

	r = 0;
#ifdef LOCALTEST
	val.data = "1234567890";
	val.size = 10;
	e = 0;
#else
	e = dbms_comms(dc, TOKEN_FETCH, &r, &k, NULL, NULL, &val);
#endif
	if (e || r != 0) {
	    if (*wp + 10 > maxw)
		return -1;
	    strcpy(out_buff + 2, dbms_get_error(dc));
	    out_buff[0] = strlen(out_buff + 2);
	    out_buff[1] = 1;
	}
	else {
	    if (*wp + 1 + val.size > maxw)
		return -1;

	    strncpy(out_buff + 2, val.data, val.size);
	    out_buff[0] = val.size;
	    out_buff[1] = 0;
	};
	if (trace_on)
	    printf("	reply '%s' len(%d)\n", out_buff + 2, out_buff[0]);

	/* Queue up the output */
	*wp += 2 + out_buff[0];

    };

    /* Return pointer to any partial/non completed commands */
    return at;
}
