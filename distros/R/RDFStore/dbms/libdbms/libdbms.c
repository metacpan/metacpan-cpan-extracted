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
 * Perl 'tie' interface to a socket connection. Possibly to
 * the a server which runs a thin feneer to the Berkely DB.
 *
 */

#include "dbms.h"
#include "dbms_comms.h"

#include <stdio.h>

typedef dbms   *DBMS;

static char     _erm[256] = "\0";

static char    *dbms_error[] = {
	/* E_UNDEF         1000 */
	"Not defined",
	/* E_NONNUL        1001 */
	"Undefined Error",
	/* E_FULLREAD      1002 */
	"Could not receive all bytes from DBMS server",
	/* E_FULLWRITE     1003 */
	"Could not send all bytes to DBMS server",
	/* E_CLOSE         1004 */
	"DBMS server closed the connection",
	/* E_HOSTNAME      1005 */
	"Could not find/resolve DBMS servers hostname",
	/* E_VERSION       1006 */
	"DBMS Version not supported",
	/* E_PROTO         1007 */
	"DBMS Reply not understood",
	/* E_ERROR         1008 */
	"DBMS Server side error"
	/* E_NOMEM         1009 */
	"Out of memory",
	/* E_RETRY         1010 */
	"Failed after several retries",
	/* E_NOPE          1011 */
	"No such database",
	/* E_XXX           1012 */
	"No such database",
	/* E_TOOBIG        1013 */
	"Packed bigger than static",
	/* E_BUG           1014 */
	"Conceptual error"
};

static dbms_error_t reconnect(dbms * me);
static dbms_error_t reselect(dbms * me);
static dbms_error_t getpack(dbms * me, unsigned long len, DBT * r);
static dbms_error_t i_comms(dbms * me, int token, int *retval, DBT * v1, DBT * v2, DBT * r1, DBT * r2);

static void
mark_dbms_error(dbms * me, char *msg, dbms_error_t erx)
{
	bzero(me->err, sizeof(me->err));
	if (erx == E_ERROR) {
		snprintf(me->err, sizeof(me->err),
			 "DBMS Error %s: %s", msg,
			 errno == 0 ? "" : (strlen(strerror(errno)) <= sizeof(me->err)) ? strerror(errno) : "");
	} else if ((erx > E_UNDEF) && (erx <= E_BUG)) {
		strncat(me->err, msg, sizeof(me->err) - 1);
		strncat(me->err, ": ", sizeof(me->err) - 1);
		strncat(me->err, dbms_error[erx - E_UNDEF], sizeof(me->err) - 1);
	} else {
		strncat(me->err, msg, sizeof(me->err) - 1);
		strncat(me->err, ": ", sizeof(me->err) - 1);
		if (strlen(strerror(erx)) <= sizeof(me->err) - strlen(me->err) - 1)
			strncat(me->err, strerror(erx), sizeof(me->err) - 1);
	};

	if (strlen(me->err) <= sizeof(_erm))
		strcpy(_erm, me->err);
};

static void
set_dbms_error(dbms * me, char *msg, dbms_error_t erx)
{
	mark_dbms_error(me, msg, erx);
	if (me->error)
		(*(me->error)) (me->err, erx);
};

extern char    *
dbms_get_error(dbms * me)
{
	if (me == NULL)
		return _erm;
	else
		return me->err;
}

static void
_warning(dbms_cause_t event, int count)
{
	/*
	 * Note: _erm use NOT thread safe. Should change function signature
	 * to pass dbms * pointer.
	 */
	if (event == DBMS_EVENT_RECONNECT)
		fprintf(stderr, "DBMS Reconnecting %i (%s)...\n", count, _erm);
	else if (event == DBMS_EVENT_WAITING)
		fprintf(stderr, "DBMS Waiting %i...\n", count);
	else
		fprintf(stderr, "DBMS Unknown event (%s)\n", _erm);
}

static int      cnt = 0;
static FILE    *logfile = NULL;

static void 
_tlog(char *fmt,...)
{
	if (!logfile)
		return;
	{
		char            tmp[1024];
		char            buf[ 128 * 1024 ];
		va_list         ap;
		time_t          tt;
		time(&tt);
		snprintf(tmp, sizeof(tmp), "%04d:%20s %s", cnt, asctime(gmtime(&tt)), fmt);

		va_start(ap, fmt);
		vsnprintf(buf,sizeof(buf)-1, tmp, ap);
		va_end(ap);

		fprintf(logfile,"%s\n",buf);
		fflush(logfile);
	}
}

static char * _token2name(int x) {
	x = x & MASK_TOKEN;
#define CC(x) case x: return #x; break;
	switch (x) {
CC(TOKEN_ERROR);
CC(TOKEN_FETCH     );
CC(TOKEN_STORE    );
CC(TOKEN_DELETE  );
CC(TOKEN_NEXTKEY );
CC(TOKEN_FIRSTKEY);
CC(TOKEN_FROM );
CC(TOKEN_EXISTS );
CC(TOKEN_SYNC  );
CC(TOKEN_INIT  );
CC(TOKEN_CLOSE );
CC(TOKEN_CLEAR );
CC(TOKEN_FDPASS   );
CC(TOKEN_PING    );
CC(TOKEN_INC    );
CC(TOKEN_LIST   );
CC(TOKEN_DEC   );
CC(TOKEN_PACKINC  );
CC(TOKEN_PACKDEC );
CC(TOKEN_DROP    );
	default: 	return "TOKEN_UNKNOWN";
	};
	return "XXX";
}

static char    *
_hex(dbms * me, int len, void *str)
{
	size_t		i;
	char           *r = NULL;

	if (len == 0) {
		r = (char *) (*me->malloc)( strlen("[0]\"\"")+1 );
		strcpy( r, "[0]\"\"" );
		return r;
		};

	if (str == NULL) {
		r = (char *) (*me->malloc)( strlen("<null>")+1 );
		strcpy( r, "<null>" );
		return r;
		};

	if (len > 50000) {
		r = (char *) (*me->malloc)( strlen("<toolong>")+1 );
		strcpy( r, "<toolong>" );
		return r;
		};

	r = (char *) (*me->malloc)(3*len + 100);
	if (r == NULL) {
		r = (char *) (*me->malloc)( strlen("<outofmem>")+1 );
		strcpy( r, "<outofmem>" );
		return r;
		};

	sprintf(r, "[%06d]\"", len);

	for (i = 0; i < len; i++) {
		char p[3];
		unsigned int c = ((unsigned char *) str)[i];

		if (c && isprint(c) && (c != '%')) {
			p[0] =  c; p[1] = '\0';
		} else {
			sprintf(p,"%%%02x", c);
		};
		strcat(r,p);
	};
	strcat(r,"\"");
	return r;
}

extern dbms    *
dbms_connect(
	     char *name, char *host, int port,
	     dbms_xsmode_t mode,
	     void *(*_my_malloc) (size_t s),
	     void (*_my_free) (void *adr),
	     void (*_my_report) (dbms_cause_t event, int count),
	     void (*_my_error) (char *err, int erx),
	     int bt_compare_fcn_type
)
{
	dbms           *me;
	int             err = 0;

	if ((name == NULL) || (*name == '\0'))
		return NULL;

	if ((host == NULL) || (*host == '\0'))
		host = DBMS_HOST;

	if (port == 0)
		port = DBMS_PORT;


	if (_my_malloc == NULL)
		_my_malloc = &malloc;

	if (_my_free == NULL)
		_my_free = &free;

	if (_my_report == NULL)
		_my_report = &_warning;

	me = (dbms *) (*_my_malloc) (sizeof(dbms));
	if (me == NULL)
		return NULL;	/* rely on errno */

	me->bt_compare_fcn_type = bt_compare_fcn_type;

	me->malloc = _my_malloc;
	me->free = _my_free;
	me->callback = _my_report;
	me->error = _my_error;
	bzero(me->err, sizeof(me->err));

	switch (mode) {
	case DBMS_XSMODE_DEFAULT:
		mode = DBMS_MODE;	/* default */
		break;
		;;
	case DBMS_XSMODE_RDONLY:
		break;
		;;
	case DBMS_XSMODE_RDWR:
		break;
		;;
	case DBMS_XSMODE_CREAT:
		break;
		;;
	case DBMS_XSMODE_DROP:
		break;
		;;
	default:
		{
			char            _buff[1024];
			snprintf(_buff, sizeof(_buff), "Unknown DBMS Access type (%d)", (int) mode);
			set_dbms_error(me, _buff, 0);
		}
		(*(me->free)) (me);
		return NULL;
		break;
	}

	me->sockfd = -1;
	me->mode = (u_long) mode;
	me->port = port;
	me->name = (char *) (*me->malloc)( strlen(name)+1 );
	if( me->name == NULL ) {
		(*(me->free)) (me);
		return NULL;
		};
	strcpy( me->name, name );
	me->host = (char *) (*me->malloc)( strlen(host)+1 );
	if( me->host == NULL ) {
		(*(me->free)) (me->name);
		(*(me->free)) (me);
		return NULL;
		};
	strcpy( me->host, host );

	/*
	 * quick and dirty hack to check for IP vs FQHN and fall through when
	 * in doubt to resolving.
	 */
	me->addr = INADDR_NONE;
	{
		int             i = 0;
		for (; me->host[i] != '\0'; i++)
			if (!isdigit((int) (me->host[i])) && me->host[i] != '.')
				break;

		if (me->host[i] == '\0')
			me->addr = inet_addr(host);
	}

	if (me->addr == INADDR_NONE) {
		struct hostent *hp;
		if ((hp = gethostbyname(me->host)) == NULL) {
			set_dbms_error(me, "Hostname lookup failed", errno);
			(*(me->free)) (me->name);
			(*(me->free)) (me->host);
			(*(me->free)) (me);
			return NULL;
		};
		/*
		 * copy the address, rather than the pointer as we need it
		 * later. It is an unsigned long.
		 */
		me->addr = *(u_long *) hp->h_addr;
	};

	if ((err = reconnect(me))) {
		set_dbms_error(me, "Connection failed", err);
		(*(me->free)) (me->name);
		(*(me->free)) (me->host);
		(*(me->free)) (me);
		return NULL;
	};

	if ((err = reselect(me))) {
		set_dbms_error(me, "Selection failed", err);
		(*(me->free)) (me->name);
		(*(me->free)) (me->host);
		(*(me->free)) (me);
		return NULL;
	};

	{
		char * file = getenv("DBMS_LOG");
		cnt++;
		if (file && (logfile == NULL)) {
			if ((logfile = fopen(file, "a"))) {
				fprintf(stderr, "Logging to %s\n", file);
			} else {
				fprintf(stderr,"Failure to log to %s: %s\n",file,strerror(errno));
			};
		}
		if (logfile)
			_tlog("start %d %s",cnt,name);
	}
	return me;
}


static          dbms_error_t
reconnect(
	  dbms * me
)
{
	struct sockaddr_in server;
	int             one = 1;
	int             csnd_len, csnd, sndbuf = 16 * 1024;
	int             e = 0;

	/*
	 * we could moan if me->sockfd is still	set.. or do a silent close,
	 * just in case ?
	 */
	if (me->sockfd >= 0) {
		shutdown(me->sockfd, 2);
		close(me->sockfd);
	}
	if ((me->sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		set_dbms_error(me, "socket", errno);
		return E_ERROR;
	}
	if (0) {
		/*
		 * allow for re-use; to avoid that we have to wait for a fair
		 * amounth of time after disasterous crashes,
		 */
		if ((setsockopt(me->sockfd, SOL_SOCKET, SO_REUSEADDR,
				(const char *) &one, sizeof(one))) < 0) {
			set_dbms_error(me, "setsockopt(reuse)", errno);
			me->sockfd = -1;
			close(me->sockfd);
			return E_ERROR;
		};
	}
	csnd_len = sizeof(csnd);
	if (getsockopt(me->sockfd, SOL_SOCKET, SO_SNDBUF,
		       (void *) &csnd, (void *) &csnd_len) < 0) {
		set_dbms_error(me, "getsockopt(sndbuff)", errno);
		me->sockfd = -1;
		close(me->sockfd);
		return E_ERROR;
	};
	assert(csnd_len == sizeof(csnd));

	/*
	 * only set when smaller
	 */
	if ((csnd < sndbuf) &&
	    (setsockopt(me->sockfd, SOL_SOCKET, SO_SNDBUF,
			(const void *) &sndbuf, sizeof(sndbuf)) < 0)) {
		set_dbms_error(me, "setsockopt(sndbuff)", errno);
		me->sockfd = -1;
		close(me->sockfd);
		return E_ERROR;
	};

	/*
	 * Discard any data still in our send buffer whe closing and do not
	 * linger around for any thing from the server.
	 */
	{
		struct linger   l = {1, 0};	/* Linger On, Lingertime 0 */
		if ((setsockopt(me->sockfd, SOL_SOCKET, SO_LINGER,
				(const char *) &l, sizeof(l))) < 0) {
			set_dbms_error(me, "setsockopt(disble-nagle)", errno);
			me->sockfd = -1;
			close(me->sockfd);
			return E_ERROR;
		};
	}
	/*
	 * disable Nagle, for speed
	 */
	if ((setsockopt(me->sockfd, IPPROTO_TCP, TCP_NODELAY,
			(const char *) &one, sizeof(one))) < 0) {
		set_dbms_error(me, "setsockopt(disble-nagle)", errno);
		me->sockfd = -1;
		close(me->sockfd);
		return E_ERROR;
	};

	/*
	 * larger buffer; as we know that we can initially slide open the
	 * window bigger.
	 */

	while (e++ < 4) {
		bzero((char *) &server, sizeof(server));

		server.sin_family = AF_INET;
		server.sin_addr.s_addr = me->addr;
		server.sin_port = htons(me->port);

		if (connect(me->sockfd, (struct sockaddr *) & server, sizeof(server)) == 0)
			return 0;
		if (errno != EADDRINUSE)
			break;

		usleep(e * e * 100 * 1000);	/* wait 0.1, 0.4, 0.9, 2.5
						 * second */
	}
	mark_dbms_error(me, "connect()", errno);
	me->sockfd = -1;
	return E_ERROR;
}

dbms_error_t
dbms_disconnect(
		dbms * me
)
{
	int             retval;

	assert(me);
	assert(me->sockfd >= 0);

	dbms_comms(me, TOKEN_CLOSE, &retval, NULL, NULL, NULL, NULL);
#ifdef TPS
	if (getenv("GATEWAY_INTERFACE") == NULL)
		fprintf(stderr, "Performance: %ld # %.2f mSec/trans = %.1f\n",
			ttps, ttime / ttps / 1000.0,
			1000000.0 * ttps / ttime
			);
#endif
	shutdown(me->sockfd, 2);
	close(me->sockfd);
	(*(me->free)) (me->name);
	(*(me->free)) (me->host);
	(*(me->free)) (me);
	if (logfile) fclose(logfile);

	return 0;
}

static          dbms_error_t
getpack(
	dbms * me,
	unsigned long len,
	DBT * r
)
{
	unsigned int    gotten;
	char           *at;

	r->size = 0;
	r->data = NULL;

	if (len == 0)
		return 0;

	if (r == NULL)
		return E_BUG;

#ifdef STATIC_SC_BUFF
	if (len > MAX_SC_PAYLOAD)
		return E_TOOBIG;
#endif
	r->size = 0;
	r->data = (char *) (*me->malloc) (len);

	if (r->data == 0)
		return E_NOMEM;

	/* should block ? */

	for (at = r->data, gotten = 0; gotten < len;) {
		ssize_t         l;
		l = recv(me->sockfd, at, len - gotten, 0);
		if (l < 0) {
			set_dbms_error(me, "packet-recv()", errno);
			(*me->free) (r->data);
			r->data = NULL;
			return E_ERROR;
		} else if (l == 0) {
			(*me->free) (r->data);
			r->data = NULL;
			return E_CLOSE;
		};
		gotten += l, at += l;
	};

	r->size = len;
	return 0;
};

static
dbms_error_t 
i_comms(
	dbms * me,
	int token,
	int *retval,
	DBT * v1,
	DBT * v2,
	DBT * r1,
	DBT * r2
)
{
	int             err = 0;
	DBT             rr1, rr2;
	struct header   cmd;
	struct iovec    iov[3];
	struct msghdr   msg;
	size_t          s;

	if (retval)
		*retval = -1;

	rr1.data = rr2.data = NULL;

	cmd.token = token | F_CLIENT_SIDE;

	cmd.len1 = htonl((v1 == NULL) ? 0 : v1->size);
	cmd.len2 = htonl((v2 == NULL) ? 0 : v2->size);

	iov[0].iov_base = (char *) &cmd;
	iov[0].iov_len = sizeof(cmd);

	iov[1].iov_base = (v1 == NULL) ? NULL : v1->data;
	iov[1].iov_len = (v1 == NULL) ? 0 : v1->size;

	iov[2].iov_base = (v2 == NULL) ? NULL : v2->data;
	iov[2].iov_len = (v2 == NULL) ? 0 : v2->size;

#ifdef STATIC_CS_BUFF
	if (iov[0].iov_len + iov[1].iov_len + iov[2].iov_len > MAX_CS_PAYLOAD)
		return E_TOOBIG;
#endif
	msg.msg_name = NULL;
	msg.msg_namelen = 0;
	msg.msg_iov = iov;
	msg.msg_iovlen = 3;
/* temporal fix to make CYGWN compile the basic thing - need better solution */
#ifndef RDFSTORE_PLATFORM_CYGWIN
	msg.msg_control = NULL;
	msg.msg_controllen = 0;
	msg.msg_flags = 0;
#endif
	s = sendmsg(me->sockfd, &msg, 0);

	if (s == 0) {
		err = E_CLOSE;
		goto retry_com;
	} else if (s < 0) {
		mark_dbms_error(me, "sendmsg()", errno);
		err = E_ERROR;
		goto retry_com;
	} else if (s != iov[0].iov_len + iov[1].iov_len + iov[2].iov_len) {
		err = E_FULLWRITE;
		goto exit_com;
	};

	s = recv(me->sockfd, &cmd, sizeof(cmd), 0);

	if (s == 0) {
		err = E_CLOSE;
		goto retry_com;
	} else if (s < 0) {
		mark_dbms_error(me, "header-recv()", errno);
		err = E_ERROR;
		goto retry_com;
	} else if (s != sizeof(cmd)) {
		err = E_FULLREAD;
		goto exit_com;
	};

	cmd.len1 = ntohl(cmd.len1);
	cmd.len2 = ntohl(cmd.len2);

	rr2.data = rr1.data = NULL;
	if ((err = getpack(me, cmd.len1, r1 ? r1 : &rr1)) != 0)
		goto retry_com;

	if ((err = getpack(me, cmd.len2, r2 ? r2 : &rr2)) != 0)
		goto retry_com;

	if ((cmd.token & MASK_TOKEN) == TOKEN_ERROR) {
		char           *d = NULL;
		int             l = 0;
		if (r1) {
			l = r1->size;
			d = r1->data;
		} else {
			l = rr1.size;
			d = rr1.data;
		};
		errno = 0;
		if ((d) && (l > 0)) {
			d[l] = '\0';
		} else {
			d = "DBMS side errror, no cause reported";
		};
		err = E_ERROR;
		errno = 0;
		set_dbms_error(me, d, err);
		goto exit_com;
	} else if (((cmd.token & MASK_TOKEN) != token) ||
		   ((cmd.token | F_SERVER_SIDE) == 0)) {
		err = E_PROTO;
		goto exit_com;
	};

	if ((rr1.data != NULL) && (rr1.size)) {
		(*me->free) (rr1.data);
		rr1.size = 0;
	};

	if ((rr2.data != NULL) && (rr2.size)) {
		(*me->free) (rr2.data);
		rr1.size = 0;
	};

	if ((cmd.token & MASK_STATUS) == F_FOUND) {
		if (retval)
			*retval = 0;
	} else {
		if (retval)
			*retval = 1;
		if (r1 != NULL) {
			if ((r1->size) && (r1->size))
				(*me->free) (r1->data);
			r1->data = NULL;
			r1->size = 0;
		};
		if (r2 != NULL) {
			if ((r2->size) && (r2->size))
				(*me->free) (r2->data);
			r2->data = NULL;
			r2->size = 0;
		};
	};

	err = 0;
	goto done_com;

retry_com:
exit_com:
	if ((r1 != NULL) && (r1->data != NULL) && (r1->size != 0)) {
		(*me->free) (r1->data);
		r1->size = 0;
	};

	if ((r2 != NULL) && (r2->data != NULL) && (r2->size != 0)) {
		(*me->free) (r2->data);
		r2->size = 0;
	};

	if ((rr1.data != NULL) && (rr1.size)) {
		(*me->free) (rr1.data);
		rr1.size = 0;
	};

	if ((rr2.data != NULL) && (rr1.size)) {
		(*me->free) (rr2.data);
		rr2.size = 0;
	};

done_com:

	return err;
}


static          dbms_error_t
reselect(dbms * me)
{
	DBT             r1, r2, v1;
	int             retval;
	u_long          buff[3];
	int             err = 0;
	u_long          proto = DBMS_PROTO;
	u_long          mode = me->mode;
	char           *name = me->name;
	u_long          bt_compare_fcn_type = me->bt_compare_fcn_type;

	assert(sizeof(buff) == 12);	/* really 4 bytes on the network ? */

	buff[0] = htonl(proto);
	buff[1] = htonl(mode);
	buff[2] = htonl(bt_compare_fcn_type);

	r1.size = sizeof(buff);
	r1.data = &buff;

	r2.size = strlen(name);
	r2.data = name;

	v1.data = NULL;		/* set up buffer for return protocol and
				 * confirmation */
	v1.size = 0;

	if ((err = i_comms(me, TOKEN_INIT, &retval, &r1, &r2, &v1, NULL))) {
		/*
		 * keep the exit code fprintf(stderr,"Fail2\n");
		 */
	} else if (retval == 1) {
		err = E_NOPE;
	} else if (retval < 0) {
		err = E_PROTO;
	} else if (ntohl(*((u_long *) v1.data)) > DBMS_PROTO) {
		err = E_VERSION;
	};

	if (v1.size)
		(*me->free) (v1.data);
	return err;
}

extern          dbms_error_t
dbms_comms(
	   dbms * me,
	   int token,
	   int *retval,
	   DBT * v1,
	   DBT * v2,
	   DBT * r1,
	   DBT * r2
)
{
	int             errs = 5;
	int             err = 0;

	struct sigaction act, oact;
#ifdef TPS
	gettimeofday(&tstart, NULL);
#endif

	if (logfile) {
		char           *p1 = NULL;
		char           *p2 = NULL;
		if (v1)
			p1 = _hex(me, v1->size, v1->data);
		if (v2)
			p2 = _hex(me, v2->size, v2->data);

		_tlog("%s@%s:%d %s(%02d) >>> %s %s",
		      me->name, me->host,me->port, _token2name(token), token,
		      p1 ? p1 : "<null>",
		      p2 ? p2 : "<null>");
		if (p1) (*me->free)(p1);
		if (p2) (*me->free)(p2);
	}
	/*
	 * for now, SA_RESTART any interupted function calls
	 */
	act.sa_handler = SIG_IGN;
	sigemptyset(&act.sa_mask);
	act.sa_flags = SA_RESTART;

	sigaction(SIGPIPE, &act, &oact);
	if (retval)
		*retval = -1;

	/*
	 * now obviously this is wrong; we do _not_ want to continue during
	 * certain errors.. ah well..
	 */
	for (errs = 0; errs < 10; errs++) {
		if ((me->sockfd >= 0) &&
		  ((err = i_comms(me, token, retval, v1, v2, r1, r2)) == 0))
			break;

		/*
		 * we could of course exit on certain errors, but which ? we
		 * call recv, et.al.
		 */
		if (err == EAGAIN || err == EINTR)
			continue;

		/*
		 * If the DB on the other end reported an error - then it
		 * obviously is not a comms problem - so retrying makes no
		 * sense
		 */
		if (err == E_ERROR)
			break;

		sleep(errs * 2);
		shutdown(me->sockfd, 2);
		close(me->sockfd);

		me->sockfd = -1;/* mark that we have an issue */
		if (((err = reconnect(me)) == 0) &&
		    ((err = reselect(me)) == 0)) {
			if (errs)
				(*(me->callback)) (DBMS_EVENT_RECONNECT, errs);
		} else if (errs)
			(*(me->callback)) (DBMS_EVENT_WAITING, errs);
	};

#ifdef TPS
	gettimeofday(&tnow, NULL);
	ttps++;
	ttime +=
		(tnow.tv_sec - tstart.tv_sec) * 1000000 +
		(tnow.tv_usec - tstart.tv_usec) * 1;
#endif
	/*
	 * restore whatever it was before
	 */
	sigaction(SIGPIPE, &oact, &act);
	if (logfile) {
		char           *q1 = NULL;
		char           *q2 = NULL;
		if (r1)
			q1 = _hex(me, r1->size, r1->data);
		if (r2)
			q2 = _hex(me, r2->size, r2->data);

		_tlog("%s@%s:%d %s(%02d) <<< %s %s",
		      me->name, me->host,me->port, _token2name(token), token,
		      q1 ? q1 : "<null>",
		      q2 ? q2 : "<null>");
		if (q1) (*me->free)(q1);
		if (q2) (*me->free)(q2);
	}
	return err;
};
