#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define _System
#include "ftpapi.h"

typedef struct {
    char *	host;
    char *	userid;
    char *	passwd;
    char *	acct;
    int		errno;
} OS2_FTP;

static int	nsessions = 0;

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static int
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    if (strEQ(name, "T_ASCII"))
	    return T_ASCII;
    if (strEQ(name, "T_BINARY"))
	    return T_BINARY;
    if (strEQ(name, "T_EBCDIC"))
	    return T_EBCDIC;
    if (strEQ(name, "FTPABORT"))
	    return FTPABORT;
    if (strEQ(name, "FTPCOMMAND"))
	    return FTPCOMMAND;
    if (strEQ(name, "FTPCONNECT"))
	    return FTPCONNECT;
    if (strEQ(name, "FTPDATACONN"))
	    return FTPDATACONN;
    if (strEQ(name, "FTPHOST"))
	    return FTPHOST;
    if (strEQ(name, "FTPLOCALFILE"))
	    return FTPLOCALFILE;
    if (strEQ(name, "FTPLOGIN"))
	    return FTPLOGIN;
    if (strEQ(name, "FTPNOPRIMARY"))
	    return FTPNOPRIMARY;
    if (strEQ(name, "FTPNOXLATETBL"))
	    return FTPNOXLATETBL;
    if (strEQ(name, "FTPPROXYTHIRD"))
	    return FTPPROXYTHIRD;
    if (strEQ(name, "FTPSERVICE"))
	    return FTPSERVICE;
    if (strEQ(name, "FTPSOCKET"))
	    return FTPSOCKET;
    if (strEQ(name, "PINGHOST"))
	    return PINGHOST;
    if (strEQ(name, "PINGPROTO"))
	    return PINGPROTO;
    if (strEQ(name, "PINGRECV"))
	    return PINGRECV;
    if (strEQ(name, "PINGREPLY"))
	    return PINGREPLY;
    if (strEQ(name, "PINGSEND"))
	    return PINGSEND;
    if (strEQ(name, "PINGSOCKET"))
	    return PINGSOCKET;
    errno = EINVAL;
    return 0;
}


MODULE = OS2::FTP	PACKAGE = OS2::FTP


int
constant(name,arg)
    char *	name
    int		arg

OS2_FTP *
new(class,host,userid,passwd,acct=NULL)
    void *	class
    char *	host
    char *	userid
    char *	passwd
    char *	acct
 CODE:
    RETVAL = malloc(sizeof(OS2_FTP));
    if (RETVAL) {
	RETVAL->host   = strdup(host);
	RETVAL->userid = strdup(userid);
	RETVAL->passwd = strdup(passwd);
	RETVAL->acct   = acct ? strdup(acct) : 0;
	RETVAL->errno  = 0;
	++nsessions;
    }
 OUTPUT:
    RETVAL

void
logoff()
 CODE:
    ftplogoff();

void
ping(...)
 PPCODE:
    int r;
    unsigned long addr;
    int pktlen = SvIV(ST(1));
    if (SvPOKp(ST(0))) {
	char *host = SvPV(ST(0), na);
	r = ftpping(host,pktlen,&addr);
	EXTEND(sp, 2);
	PUSHs(sv_2mortal(newSViv(r)));
	if (r >= 0)
	    PUSHs(sv_2mortal(newSVnv((double)addr)));
    } else {
	unsigned long addr = (unsigned long) SvNV(ST(0));
	r = ping(addr, pktlen);
	PUSHs(sv_2mortal(newSViv(r)));
    }

char *
message(errno)
    int		errno
 CODE:
    switch (errno) {
    case FTPSERVICE:    RETVAL = "ftp/tcp: unknown service"; break;
    case FTPHOST:       RETVAL = "unknown host"; break;
    case FTPSOCKET:     RETVAL = "unable to obtain socket"; break;
    case FTPCONNECT:    RETVAL = "unable to connect to server"; break;
    case FTPLOGIN:      RETVAL = "login failed"; break;
    case FTPABORT:      RETVAL = "transfer aborted"; break;
    case FTPLOCALFILE:  RETVAL = "problem openning local file"; break;
    case FTPDATACONN:   RETVAL = "problem initializing data connection"; break;
    case FTPCOMMAND:    RETVAL = "command failed"; break;
    case FTPPROXYTHIRD: RETVAL = "proxy server does not support third party transfers"; break;
    case FTPNOPRIMARY:  RETVAL = "no primary connection for proxy transfer"; break;
    case FTPNOXLATETBL: RETVAL = "no code page translation table was loded"; break;
    case PINGREPLY:     RETVAL = "host does not reply"; break;
    case PINGSOCKET:    RETVAL = "unable to obtain socket"; break;
    case PINGPROTO:     RETVAL = "unknown protcol ICMP"; break;
    case PINGSEND:      RETVAL = "send failed"; break;
    case PINGRECV:      RETVAL = "recv failed"; break;
    case PINGHOST:      RETVAL = "can't resolve the host name"; break;
    default:	  	RETVAL = "";
    }
 OUTPUT:
    RETVAL


MODULE = OS2::FTP	PACKAGE = OS2_FTPPtr


void
ftp_DESTROY(session)
    OS2_FTP *	session
 CODE:
    free(session->host);
    free(session->userid);
    free(session->passwd);
    if (session->acct)
        free(session->acct);
    free(session);
    if (--nsessions == 0)
        ftplogoff();

int
errno(session)
    OS2_FTP *	session
 CODE:
    RETVAL = session->errno;
 OUTPUT:
    RETVAL

int
append(session,local,remote=local,tfrtype=T_BINARY)
    OS2_FTP *	session
    char *	local	
    char *	remote
    int		tfrtype
 CODE:
    RETVAL = ftpappend(session->host, session->userid, session->passwd, session->acct,
		       local, remote, tfrtype);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
chdir(session,dir)
    OS2_FTP *	session
    char *	dir
 CODE:
    RETVAL = ftpcd(session->host, session->userid, session->passwd, session->acct,
		   dir);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
delete(session,name)
    OS2_FTP *	session
    char *	name
 CODE:
    RETVAL = ftpdelete(session->host, session->userid, session->passwd, session->acct,
		       name);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
dir(session,local,pattern="*")
    OS2_FTP *	session
    char *	local	
    char *	pattern
 CODE:
    RETVAL = ftpdir(session->host, session->userid, session->passwd, session->acct,
		    local, pattern);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
get(session,local,remote=local,mode="w",tfrtype=T_BINARY)
    OS2_FTP *	session
    char *	local
    char *	remote
    char *	mode
    int		tfrtype
 CODE:
    RETVAL = ftpget(session->host, session->userid, session->passwd, session->acct,
		    local, remote, mode, tfrtype);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
ls(session,local,pattern="*")
    OS2_FTP *	session
    char *	local
    char *	pattern
 CODE:
    RETVAL = ftpls(session->host, session->userid, session->passwd, session->acct,
		   local, pattern);
 OUTPUT:
    RETVAL

int
mkdir(session,dir)
    OS2_FTP *	session
    char *	dir
 CODE:
    RETVAL = ftpmkd(session->host, session->userid, session->passwd, session->acct,
		    dir);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
proxy(dst_session,src_session,dst_fn,src_fn,tfrtype=T_BINARY)
    OS2_FTP *	dst_session
    OS2_FTP *	src_session
    char *	dst_fn
    char *	src_fn
    int		tfrtype
 CODE:
    RETVAL = ftpproxy(dst_session->host, dst_session->userid,
		      dst_session->passwd, dst_session->acct,
		      src_session->host, src_session->userid,
		      src_session->passwd, src_session->acct,
		      dst_fn, src_fn, tfrtype);
    if (RETVAL < 0)
	dst_session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
put(session,local,remote=local,tfrtype=T_BINARY)
    OS2_FTP *	session
    char *	local
    char *	remote
    int		tfrtype
 CODE:
    RETVAL = ftpput(session->host, session->userid, session->passwd, session->acct,
		    local, remote, tfrtype);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
putunique(session,local,remote=local,tfrtype=T_BINARY)
    OS2_FTP *	session
    char *	local
    char *	remote
    int		tfrtype
 CODE:
    RETVAL = ftpputunique(session->host, session->userid, session->passwd, session->acct,
			  local, remote, tfrtype);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

void
getcwd(session)
    OS2_FTP *	session
 PPCODE:
 {
    char wd[500];
    int r = ftppwd(session->host, session->userid, session->passwd, session->acct,
		   wd, sizeof wd);
    if (r < 0)
	session->errno = ftperrno;
    EXTEND(sp, 2);
    PUSHs(sv_2mortal(newSViv(r)));
    if (r >= 0)
        PUSHs(sv_2mortal(newSVpv(wd, strlen(wd))));
 }

int
quote(session,string)
    OS2_FTP *	session
    char *	string
 CODE:
    RETVAL = ftpquote(session->host, session->userid, session->passwd, session->acct,
		      string);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
rename(session,namefrom,nameto)
    OS2_FTP *	session
    char *	namefrom
    char *	nameto
 CODE:
    RETVAL = ftprename(session->host, session->userid, session->passwd, session->acct,
		       namefrom, nameto);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
rmdir(session,dir)
    OS2_FTP *	session
    char *	dir
 CODE:
    RETVAL = ftprmd(session->host, session->userid, session->passwd, session->acct,
		    dir);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

int
site(session,string)
    OS2_FTP *	session
    char *	string
 CODE:
    RETVAL = ftpsite(session->host, session->userid, session->passwd, session->acct,
		     string);
    if (RETVAL < 0)
	session->errno = ftperrno;
 OUTPUT:
    RETVAL

void
sys(session)
    OS2_FTP *	session
 PPCODE:
 {
    char buf[2000];
    int r = ftpsys(session->host, session->userid, session->passwd, session->acct,
		   buf, sizeof buf);
    if (r < 0)
	session->errno = ftperrno;
    EXTEND(sp, 2);
    PUSHs(sv_2mortal(newSViv(r)));
    if (r >= 0)
        PUSHs(sv_2mortal(newSVpv(buf, strlen(buf))));
 }

