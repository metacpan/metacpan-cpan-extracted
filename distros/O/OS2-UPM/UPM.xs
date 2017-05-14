#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ctype.h>
#include <malloc.h>
#include <os2emx.h>
#include <os2thunk.h>

#define INCL_32
#include <upm.h>

#define _THUNK_CALL16(p) _THUNK_CALLI(_emx_32to16(p))

static short	last_error;
static BYTE *	buffer;
static int	buflen;
static char *	empty = "";

static void
initialize(void)
{
	buflen = 4096;
	buffer = _tmalloc(buflen);
	last_error = 0;
}

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

	if (strEQ(name, "UPM_ACTIVE"))
	    return (USHORT) UPM_ACTIVE;
	if (strEQ(name, "UPM_ADMIN"))
	    return (USHORT) UPM_ADMIN;
	if (strEQ(name, "UPM_ALL"))
	    return (USHORT) UPM_ALL;
	if (strEQ(name, "UPM_BAD_AUTHCHECK"))
	    return (USHORT) UPM_BAD_AUTHCHECK;
	if (strEQ(name, "UPM_BAD_PARAMETER"))
	    return (USHORT) UPM_BAD_PARAMETER;
	if (strEQ(name, "UPM_BAD_TYPE"))
	    return (USHORT) UPM_BAD_TYPE;
	if (strEQ(name, "UPM_CONFIG"))
	    return (USHORT) UPM_CONFIG;
	if (strEQ(name, "UPM_DNODE"))
	    return (USHORT) UPM_DNODE;
	if (strEQ(name, "UPM_DOMAIN"))
	    return (USHORT) UPM_DOMAIN;
	if (strEQ(name, "UPM_DOMAIN_MAX_FORCE"))
	    return (USHORT) UPM_DOMAIN_MAX_FORCE;
	if (strEQ(name, "UPM_DOMAIN_VERBOSE"))
	    return (USHORT) UPM_DOMAIN_VERBOSE;
	if (strEQ(name, "UPM_DUP_ULP_ENTRY"))
	    return (USHORT) UPM_DUP_ULP_ENTRY;
	if (strEQ(name, "UPM_ERROR_MORE_DATA"))
	    return (USHORT) UPM_ERROR_MORE_DATA;
	if (strEQ(name, "UPM_ERROR_NONVAL_LOGON"))
	    return (USHORT) UPM_ERROR_NONVAL_LOGON;
	if (strEQ(name, "UPM_FAIL_SECURITY"))
	    return (USHORT) UPM_FAIL_SECURITY;
	if (strEQ(name, "UPM_FL_DOMVER"))
	    return (USHORT) UPM_FL_DOMVER;
	if (strEQ(name, "UPM_FL_LOCVER"))
	    return (USHORT) UPM_FL_LOCVER;
	if (strEQ(name, "UPM_FL_NOVER"))
	    return (USHORT) UPM_FL_NOVER;
	if (strEQ(name, "UPM_LOCAL"))
	    return (USHORT) UPM_LOCAL;
	if (strEQ(name, "UPM_LOCAL_HPFS"))
	    return (USHORT) UPM_LOCAL_HPFS;
	if (strEQ(name, "UPM_LOGGED"))
	    return (USHORT) UPM_LOGGED;
	if (strEQ(name, "UPM_LOGGED_ELSEWHERE"))
	    return (USHORT) UPM_LOGGED_ELSEWHERE;
	if (strEQ(name, "UPM_LOG_CANCEL"))
	    return (USHORT) UPM_LOG_CANCEL;
	if (strEQ(name, "UPM_LOG_FILE_NOT_FOUND"))
	    return (USHORT) UPM_LOG_FILE_NOT_FOUND;
	if (strEQ(name, "UPM_LOG_INPROC"))
	    return (USHORT) UPM_LOG_INPROC;
	if (strEQ(name, "UPM_MAX_ENT_EXCEEDED"))
	    return (USHORT) UPM_MAX_ENT_EXCEEDED;
	if (strEQ(name, "UPM_MAX_ULP_EXCEEDED"))
	    return (USHORT) UPM_MAX_ULP_EXCEEDED;
	if (strEQ(name, "UPM_NODISK"))
	    return (USHORT) UPM_NODISK;
	if (strEQ(name, "UPM_NOMEM"))
	    return (USHORT) UPM_NOMEM;
	if (strEQ(name, "UPM_NOT_LOGGED"))
	    return (USHORT) UPM_NOT_LOGGED;
	if (strEQ(name, "UPM_OK"))
	    return (USHORT) UPM_OK;
	if (strEQ(name, "UPM_OPEN_SESSIONS"))
	    return (USHORT) UPM_OPEN_SESSIONS;
	if (strEQ(name, "UPM_PASSWORD_EXP"))
	    return (USHORT) UPM_PASSWORD_EXP;
	if (strEQ(name, "UPM_PRIV_ADMIN"))
	    return (USHORT) UPM_PRIV_ADMIN;
	if (strEQ(name, "UPM_PRIV_LOCAL_ADMIN"))
	    return (USHORT) UPM_PRIV_LOCAL_ADMIN;
	if (strEQ(name, "UPM_PRIV_USER"))
	    return (USHORT) UPM_PRIV_USER;
	if (strEQ(name, "UPM_PROF_NOT_FOUND"))
	    return (USHORT) UPM_PROF_NOT_FOUND;
	if (strEQ(name, "UPM_PWDLEN"))
	    return (USHORT) UPM_PWDLEN;
	if (strEQ(name, "UPM_REMLEN"))
	    return (USHORT) UPM_REMLEN;
	if (strEQ(name, "UPM_SS_BUSY"))
	    return (USHORT) UPM_SS_BUSY;
	if (strEQ(name, "UPM_SS_DEAD"))
	    return (USHORT) UPM_SS_DEAD;
	if (strEQ(name, "UPM_SS_PWDEXPWARNING"))
	    return (USHORT) UPM_SS_PWDEXPWARNING;
	if (strEQ(name, "UPM_SYS_ERROR"))
	    return (USHORT) UPM_SYS_ERROR;
	if (strEQ(name, "UPM_UIDLEN"))
	    return (USHORT) UPM_UIDLEN;
	if (strEQ(name, "UPM_ULP_LOADED"))
	    return (USHORT) UPM_ULP_LOADED;
	if (strEQ(name, "UPM_UNAVAIL"))
	    return (USHORT) UPM_UNAVAIL;
	if (strEQ(name, "UPM_USER"))
	    return (USHORT) UPM_USER;

    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = OS2::UPM		PACKAGE = OS2::UPM

BOOT:
	initialize();

int
constant(name,arg)
	char *		name
	int		arg

void
local_user()
	PPCODE:
	{
		USHORT  rc;
		PBYTE   puserid = (buffer+0);
		PUSHORT ptype   = (PUSHORT)(buffer+10);
		rc = (_THUNK_PROLOG (4+4);
		      _THUNK_FLAT (puserid);
		      _THUNK_FLAT (ptype);
		      _THUNK_CALL16 (UPMELOCU));
		if (!rc) {
			EXTEND(sp, 2);
			PUSHs(sv_2mortal(newSVpv(puserid, 0)));
			PUSHs(sv_2mortal(newSViv(*ptype)));
		} else
			last_error = rc;
	}

void
user_list(remote_node="",remote_type=UPM_LOCAL)
	char *		remote_node
	int		remote_type
	PPCODE:
	{
		USHORT  rc;
		PBYTE   premotename = (buffer+0);
		PUSHORT pread       = (PUSHORT)(buffer+18);
		PUSHORT ptotal      = (PUSHORT)(buffer+20);
		PBYTE   pentries    = (buffer+24);
		strcpy((char *)premotename, remote_node);
		rc = (_THUNK_PROLOG (4+2+4+2+4+4);
		      _THUNK_FLAT (premotename);
		      _THUNK_SHORT (remote_type);
		      _THUNK_FLAT (pentries);
		      _THUNK_SHORT (buflen-24);
		      _THUNK_FLAT (pread);
		      _THUNK_FLAT (ptotal);
		      _THUNK_CALL16 (UPMEUSRL));
		if (!rc) {
			int i;
			void *p0 = pentries;
			struct UPM_USER_LOGON *p = p0;
			EXTEND(sp, *pread * 4);
			for (i = *pread; --i >= 0; ++p) {
				PUSHs(sv_2mortal(newSVpv(p->userid, 0)));
				PUSHs(sv_2mortal(newSVpv(p->remotename, 0)));
				PUSHs(sv_2mortal(newSViv(p->remotetype)));
				PUSHs(sv_2mortal(newSViv(p->sessionid)));
			}
		} else
			last_error = rc;
	}

int
logoff(userid,remote_node="",remote_type=UPM_LOCAL)
	char *		userid
	char *		remote_node
	int		remote_type
	CODE:
	{
		USHORT rc;
		PBYTE  puserid     = (buffer+0);
		PBYTE  premotename = (buffer+9);
		strcpy((char *)puserid, userid);
		strcpy((char *)premotename, remote_node);
		rc = (_THUNK_PROLOG (4+4+2);
		      _THUNK_FLAT (puserid);
		      _THUNK_FLAT (premotename);
		      _THUNK_SHORT (remote_type);
		      _THUNK_CALL16 (UPMELGFF));
		if (rc) {
			last_error = RETVAL;
			RETVAL = FALSE;
		} else
			RETVAL = TRUE;
	}
	OUTPUT:
		RETVAL

int
logoff_user(userid,remote_node="",remote_type=UPM_LOCAL)
	char *		userid
	char *		remote_node
	int		remote_type
	CODE:
	{
		USHORT rc;
		PBYTE  puserid     = (buffer+0);
		PBYTE  premotename = (buffer+9);
		strcpy((char *)puserid, userid);
		strcpy((char *)premotename, remote_node);
		rc = (_THUNK_PROLOG (4+4+2);
		      _THUNK_FLAT (puserid);
		      _THUNK_FLAT (premotename);
		      _THUNK_SHORT (remote_type);
		      _THUNK_CALL16 (UPMEULGF));
		if (rc) {
			last_error = RETVAL;
			RETVAL = FALSE;
		} else
			RETVAL = TRUE;
	}
	OUTPUT:
		RETVAL

void
local_logon()
	PPCODE:
	{
		USHORT  rc;
		PBYTE   puserid = (buffer+0);
		PUSHORT ptype   = (PUSHORT)(buffer+10);
		rc = (_THUNK_PROLOG (4+4);
		      _THUNK_FLAT (puserid);
		      _THUNK_FLAT (ptype);
		      _THUNK_CALL16 (UPMELOCL));
		if (!rc) {
			EXTEND(sp, 2);
			PUSHs(sv_2mortal(newSVpv(puserid, 0)));
			PUSHs(sv_2mortal(newSViv(*ptype)));
		} else
			last_error = rc;
	}

int
logon(userid,password,auth_check=UPM_USER,remote_node="",remote_type=UPM_LOCAL)
	char *		userid
	char *		password
	int		auth_check
	char *		remote_node
	int		remote_type
	CODE:
	{
		USHORT rc;
		PBYTE  puserid     = (buffer+0);
		PBYTE  ppassword   = (buffer+9);
		PBYTE  premotename = (buffer+18);
		strcpy((char *)puserid, userid);
		strcpy((char *)password, password);
		strcpy((char *)premotename, remote_node);
		rc = (_THUNK_PROLOG (4+4+4+2+2);
		      _THUNK_FLAT (puserid);
		      _THUNK_FLAT (ppassword);
		      _THUNK_FLAT (premotename);
		      _THUNK_SHORT (remote_type);
		      _THUNK_SHORT (auth_check);
		      _THUNK_CALL16 (UPMELGN));
		if (rc) {
			last_error = RETVAL;
			RETVAL = FALSE;
		} else
			RETVAL = TRUE;
	}
	OUTPUT:
		RETVAL

int
logon_user(userid,password,remote_node="",remote_type=UPM_LOCAL)
	char *		userid
	char *		password
	char *		remote_node
	int		remote_type
	CODE:
	{
		USHORT rc;
		PBYTE  puserid     = (buffer+0);
		PBYTE  ppassword   = (buffer+9);
		PBYTE  premotename = (buffer+18);
		strcpy((char *)puserid, userid);
		strcpy((char *)password, password);
		strcpy((char *)premotename, remote_node);
		rc = (_THUNK_PROLOG (4+4+4+2+2);
		      _THUNK_FLAT (puserid);
		      _THUNK_FLAT (ppassword);
		      _THUNK_FLAT (premotename);
		      _THUNK_SHORT (remote_type);
		      _THUNK_SHORT (0);
		      _THUNK_CALL16 (UPMEULGN));
		if (rc) {
			last_error = RETVAL;
			RETVAL = FALSE;
		} else
			RETVAL = TRUE;
	}
	OUTPUT:
		RETVAL

int
error()
	CODE:
		RETVAL = last_error;
		last_error = 0;
	OUTPUT:
		RETVAL

char *
message(code)
	int		code
	CODE:
	{
		ULONG rc, len;
		if (code > 0) {
			rc = DosGetMessage(NULL, 0, buffer, buflen,
				code, "OSO001.MSG", len);
			if (rc == 0)
				len = sprintf(buffer, "OS/2 system error code %d", code);
			RETVAL = buffer;
			while (len > 0 && isspace(buffer[len-1]))
				--len;
			buffer[len] = '\0';
		} else {
			switch ((USHORT)code) {
			case UPM_OK:	     
				RETVAL = "Successful.";
				break;
			case UPM_LOG_INPROC:	     
				RETVAL = "Another logon is in process.";
				break;
			case UPM_BAD_TYPE:	     
				RETVAL = "Bad remotetype.";
				break;
			case UPM_NOMEM: 	     
				RETVAL = "Cannot allocate required memory.";
				break;
			case UPM_LOG_FILE_NOT_FOUND: 
				RETVAL = "An execute file could not be found.";
				break;
			case UPM_FAIL_SECURITY:      
				RETVAL = "User not logged, failed security clearance.";
				break;
			case UPM_BAD_PARAMETER:      
				RETVAL = "A parameter passed was invalid.";
				break;
			case UPM_BAD_AUTHCHECK:      
				RETVAL = "Authcheck was not valid.";
				break;
			case UPM_LOG_CANCEL:	     
				RETVAL = "User has canceled from the logon panel.";
				break;
			case UPM_NOT_LOGGED:	     
				RETVAL = "A logon has not occured for this userid.";
				break;
			case UPM_LOGGED:	     
				RETVAL = "A domain logon is currently active.";
				break;
			case UPM_SYS_ERROR:	     
				RETVAL = "An unexpected system error.";
				break;
			case UPM_OPEN_SESSIONS:      
				RETVAL = "The domain logoff failed, The domain"
					 " logon has active sessions.";
				break;
			case UPM_ULP_LOADED:	     
				RETVAL = "The local logon failed, a local"
					 " logon with a user logon profile is"
					 " active.";
				break;
			case UPM_LOGGED_ELSEWHERE:   
				RETVAL = "The domain logon failed, the userid"
					 " is already logged on the domain.";
				break;
			case UPM_PASSWORD_EXP:	     
				RETVAL = "The users password is expired.";
				break;
			case UPM_UNAVAIL:	     
				RETVAL = "The logon failed, The remote node"
					 " or server could not be contacted to"
					 " process the logon request.";
				break;
			case UPM_ACTIVE:	     
				RETVAL = "The domain logon or logoff failed,"
					 " a domain logon, logoff or net"
					 " command is in process.";
				break;
			case UPM_SS_PWDEXPWARNING:   
				RETVAL = "The local logon succeeded. The users"
					 " password is expired.";
				break;
			case UPM_SS_BUSY:	     
				RETVAL = "The local logon failed. The Local"
					 " security was busy.";
				break;
			case UPM_SS_DEAD:	     
				RETVAL = "The local logon failed. Local"
					 " security has terminated unexpectedly.";
				break;
			case UPM_ERROR_MORE_DATA:    
				RETVAL = "More data is available, the buffer"
					 " provided is not large enough.";
				break;
			case UPM_MAX_ENT_EXCEEDED:   
				RETVAL = "Update failed, the input buffer"
					 " contains more than 16 entries.";
				break;
			case UPM_DUP_ULP_ENTRY:      
				RETVAL = "Two or more entries with the same"
					 " remote name and user ID were"
					 " detected.";
				break;
			case UPM_MAX_ULP_EXCEEDED:   
				RETVAL = "Database contains maximum number entries";
				break;
			case UPM_NODISK:	     
				RETVAL = "Insufficient disk space was available to"
					 " process this request";
				break;
			case UPM_PROF_NOT_FOUND:     
				RETVAL = "Did not find user logon profile for"
					 " user ID.";
				break;
			case UPM_ERROR_NONVAL_LOGON: 
				RETVAL = "Non validated Lan Server logons are not"
					 " allowed with server service started";
			default:
				sprintf(buffer, "UPM error code 0x%04X.", code);
				RETVAL = buffer;
			}
		}
	}
	OUTPUT:
		RETVAL

