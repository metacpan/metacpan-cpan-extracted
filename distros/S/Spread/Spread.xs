/* Filename: Spread.xs
 * Author:   Theo Schlossnagle <jesus@cnds.jhu.edu>
 * Created:  12th October 1999
 *
 * Copyright (c) 1999-2006,2008 Theo Schlossnagle. All rights reserved.
 *   This program is free software; you can redistribute it and/or
 *   modify it under the same terms as Perl itself.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sp.h"

#ifndef MIN
#define MIN(a,b) (((a)<(b))?(a):(b))
#endif

#ifndef PERL_VERSION
#include "patchlevel.h"
#define PERL_REVISION   5
#define PERL_VERSION    PATCHLEVEL
#define PERL_SUBVERSION SUBVERSION
#endif

#if PERL_REVISION == 5 && (PERL_VERSION < 4 || (PERL_VERSION == 4 && PERL_SUBVERSION <= 75 ))

#    define PL_sv_undef         sv_undef
#    define PL_na               na
#    define PL_curcop           curcop
#    define PL_compiling        compiling

#endif


#define SPERRNO "Spread::sperrno"
#define MAX_ERRMSG     4
#define SELECT_FAILED  4
#define SELECT_TIMEOUT 3
#define ARGS_INSUFF 2
static char *my_e_errmsg[] = {
 "Select Failed",       /* SELECT_FAILED        4 */
 "Select Timed Out",	/* SELECT_TIMEOUT		3 */
 "Insufficient Arguments", /* ARGS_INSUFF		2 */
 "Accept Session",	/* ACCEPT_SESSION		1 */
 ""		,	/*				0 */
 "Illegal Spread",	/* ILLEGAL_SPREAD		-1 */
 "Could Not Connect",	/* COULD_NOT_CONNECT		-2 */
 "Reject: Quota",	/* REJECT_QUOTA			-3 */
 "Reject: No Name",	/* REJECT_NO_NAME		-4 */
 "Reject: Illegal Name",/* REJECT_ILLEGAL_NAME		-5 */
 "Reject: Not Unique",	/* REJECT_NOT_UNIQUE		-6 */
 "Reject: Version",	/* REJECT_VERSION		-7 */
 "Connection Closed",	/* CONNECTION_CLOSED		-8 */
 "Reject: Auth",	/* REJECT_AUTH			-9 */
 ""		,	/*				-10 */
 "Illegal Session",	/* ILLEGAL_SESSION		-11 */
 "Illegal Service",	/* ILLEGAL_SERVICE		-12 */
 "Illegal Message",	/* ILLEGAL_MESSAGE		-13 */
 "Illegal Group",	/* ILLEGAL_GROUP		-14 */
 "Buffer Too Short",	/* BUFFER_TOO_SHORT		-15 */
#ifdef GROUPS_TOO_SHORT
 "Groups Too Short",	/* GROUPS_TOO_SHORT		-16 */
#endif
#ifdef MESSAGE_TOO_LONG
 "Message Too Long",	/* MESSAGE_TOO_LONG		-17 */
#else
#error You must install spread client libraries to build perl Spread.
#endif
 ""};
static char *connect_params[] = {
	"spread_name",
	"private_name",
	"priority",
	"group_membership",
	""};
static int nconnect_params = 4;

SV *sv_NULL ;

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
        if (strEQ(name, "ACCEPT_SESSION"))
#ifdef ACCEPT_SESSION
            return ACCEPT_SESSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "AGREED_MESS"))
#ifdef AGREED_MESS
            return AGREED_MESS;
#else
            goto not_there;
#endif
        break;
    case 'B':
        if (strEQ(name, "BUFFER_TOO_SHORT"))
#ifdef BUFFER_TOO_SHORT
            return BUFFER_TOO_SHORT;
#else
            goto not_there;
#endif
        break;
    case 'C':
        if (strEQ(name, "CAUSAL_MESS"))
#ifdef CAUSAL_MESS
            return CAUSAL_MESS;
#else
            goto not_there;
#endif
        if (strEQ(name, "CAUSED_BY_DISCONNECT"))
#ifdef CAUSED_BY_DISCONNECT
            return CAUSED_BY_DISCONNECT;
#else
            goto not_there;
#endif
        if (strEQ(name, "CAUSED_BY_JOIN"))
#ifdef CAUSED_BY_JOIN
            return CAUSED_BY_JOIN;
#else
            goto not_there;
#endif
        if (strEQ(name, "CAUSED_BY_LEAVE"))
#ifdef CAUSED_BY_LEAVE
            return CAUSED_BY_LEAVE;
#else
            goto not_there;
#endif
        if (strEQ(name, "CAUSED_BY_NETWORK"))
#ifdef CAUSED_BY_NETWORK
            return CAUSED_BY_NETWORK;
#else
            goto not_there;
#endif
        if (strEQ(name, "CONNECTION_CLOSED"))
#ifdef CONNECTION_CLOSED
            return CONNECTION_CLOSED;
#else
            goto not_there;
#endif
        if (strEQ(name, "COULD_NOT_CONNECT"))
#ifdef COULD_NOT_CONNECT
            return COULD_NOT_CONNECT;
#else
            goto not_there;
#endif
        break;
    case 'D':
        if (strEQ(name, "DROP_RECV"))
#ifdef DROP_RECV
            return DROP_RECV;
#else
            goto not_there;
#endif
        break;
    case 'E':
        break;
    case 'F':
        if (strEQ(name, "FIFO_MESS"))
#ifdef FIFO_MESS
            return FIFO_MESS;
#else
            goto not_there;
#endif
        break;
    case 'G':
        if (strEQ(name, "GROUPS_TOO_SHORT"))
#ifdef GROUPS_TOO_SHORT
            return GROUPS_TOO_SHORT;
#else
            goto not_there;
#endif
        break;
    case 'H':
        if (strEQ(name, "HIGH_PRIORITY"))
#ifdef HIGH_PRIORITY
            return HIGH_PRIORITY;
#else
            goto not_there;
#endif
        break;
    case 'I':
        if (strEQ(name, "ILLEGAL_GROUP"))
#ifdef ILLEGAL_GROUP
            return ILLEGAL_GROUP;
#else
            goto not_there;
#endif
        if (strEQ(name, "ILLEGAL_MESSAGE"))
#ifdef ILLEGAL_MESSAGE
            return ILLEGAL_MESSAGE;
#else
            goto not_there;
#endif
        if (strEQ(name, "ILLEGAL_SERVICE"))
#ifdef ILLEGAL_SERVICE
            return ILLEGAL_SERVICE;
#else
            goto not_there;
#endif
        if (strEQ(name, "ILLEGAL_SESSION"))
#ifdef ILLEGAL_SESSION
            return ILLEGAL_SESSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "ILLEGAL_SPREAD"))
#ifdef ILLEGAL_SPREAD
            return ILLEGAL_SPREAD;
#else
            goto not_there;
#endif
        break;
    case 'J':
        break;
    case 'K':
        break;
    case 'L':
        if (strEQ(name, "LOW_PRIORITY"))
#ifdef LOW_PRIORITY
            return LOW_PRIORITY;
#else
            goto not_there;
#endif
        break;
    case 'M':
        if (strEQ(name, "MAX_SCATTER_ELEMENTS"))
#ifdef MAX_SCATTER_ELEMENTS
            return MAX_SCATTER_ELEMENTS;
#else
            goto not_there;
#endif
        if (strEQ(name, "MEDIUM_PRIORITY"))
#ifdef MEDIUM_PRIORITY
            return MEDIUM_PRIORITY;
#else
            goto not_there;
#endif
        if (strEQ(name, "MEMBERSHIP_MESS"))
#ifdef MEMBERSHIP_MESS
            return MEMBERSHIP_MESS;
#else
            goto not_there;
#endif
        if (strEQ(name, "MESSAGE_TOO_LONG"))
#ifdef MESSAGE_TOO_LONG
            return MESSAGE_TOO_LONG;
#else
            goto not_there;
#endif
        break;
    case 'N':
        break;
    case 'O':
        break;
    case 'P':
        break;
    case 'Q':
        break;
    case 'R':
        if (strEQ(name, "REGULAR_MESS"))
#ifdef REGULAR_MESS
            return REGULAR_MESS;
#else
            goto not_there;
#endif
        if (strEQ(name, "REG_MEMB_MESS"))
#ifdef REG_MEMB_MESS
            return REG_MEMB_MESS;
#else
            goto not_there;
#endif
        if (strEQ(name, "REJECT_AUTH"))
#ifdef REJECT_AUTH
            return REJECT_AUTH;
#else
            goto not_there;
#endif
        if (strEQ(name, "REJECT_ILLEGAL_NAME"))
#ifdef REJECT_ILLEGAL_NAME
            return REJECT_ILLEGAL_NAME;
#else
            goto not_there;
#endif
        if (strEQ(name, "REJECT_MESS"))
#ifdef REJECT_MESS
            return REJECT_MESS;
#else
            goto not_there;
#endif
        if (strEQ(name, "REJECT_NOT_UNIQUE"))
#ifdef REJECT_NOT_UNIQUE
            return REJECT_NOT_UNIQUE;
#else
            goto not_there;
#endif
        if (strEQ(name, "REJECT_NO_NAME"))
#ifdef REJECT_NO_NAME
            return REJECT_NO_NAME;
#else
            goto not_there;
#endif
        if (strEQ(name, "REJECT_QUOTA"))
#ifdef REJECT_QUOTA
            return REJECT_QUOTA;
#else
            goto not_there;
#endif
        if (strEQ(name, "REJECT_VERSION"))
#ifdef REJECT_VERSION
            return REJECT_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "RELIABLE_MESS"))
#ifdef RELIABLE_MESS
            return RELIABLE_MESS;
#else
            goto not_there;
#endif
        break;
    case 'S':
        if (strEQ(name, "SAFE_MESS"))
#ifdef SAFE_MESS
            return SAFE_MESS;
#else
            goto not_there;
#endif
        if (strEQ(name, "SELF_DISCARD"))
#ifdef SELF_DISCARD
            return SELF_DISCARD;
#else
            goto not_there;
#endif
        break;
    case 'T':
        if (strEQ(name, "TRANSITION_MESS"))
#ifdef TRANSITION_MESS
            return TRANSITION_MESS;
#else
            goto not_there;
#endif
        break;
    case 'U':
        if (strEQ(name, "UNRELIABLE_MESS"))
#ifdef UNRELIABLE_MESS
            return UNRELIABLE_MESS;
#else
            goto not_there;
#endif
        break;
    case 'V':
        break;
    case 'W':
        break;
    case 'X':
        break;
    case 'Y':
        break;
    case 'Z':
        break;
    case 'a':
        break;
    case 'b':
        break;
    case 'c':
        break;
    case 'd':
        break;
    case 'e':
        break;
    case 'f':
        break;
    case 'g':
        break;
    case 'h':
        break;
    case 'i':
        break;
    case 'j':
        break;
    case 'k':
        break;
    case 'l':
        break;
    case 'm':
        break;
    case 'n':
        break;
    case 'o':
        break;
    case 'p':
        break;
    case 'q':
        break;
    case 'r':
        break;
    case 's':
        break;
    case 't':
        break;
    case 'u':
        break;
    case 'v':
        break;
    case 'w':
        break;
    case 'x':
        break;
    case 'y':
        break;
    case 'z':
        break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static void
SetSpErrorNo(error_no)
int error_no ;
{
	char * errstr ;
	SV * sperror_sv = perl_get_sv(SPERRNO, FALSE);

	errstr = (char *) my_e_errmsg[MAX_ERRMSG - error_no];
	if (SvIV(sperror_sv) != error_no) {
	  sv_setiv(sperror_sv, error_no) ;
	  sv_setpv(sperror_sv, errstr) ;
	  SvIOK_on(sperror_sv) ;
	}
}
static char *
SPversionstr() {
  static char version_string[60];
  int major, minor, patch;
  if(SP_version(&major, &minor, &patch) > 0) {
    sprintf(version_string, "%d.%d.%d", major, minor, patch);
  } else {
    sprintf(version_string, "SP_version failed, could not retrieve version.");
  }
  return version_string;
}

MODULE = Spread	PACKAGE = Spread	PREFIX = GC_

REQUIRE:	1.9505
PROTOTYPES:	DISABLE

BOOT:
	/* Check version of Spread == 3.11 */
	{
        int major, minor, patch;
	if(SP_version(&major, &minor, &patch) <= 0 ||
	   major<3 || (major==3 && minor<15) ||
	   (major==3 && minor==15 && patch<1))
	  croak("%s", SPversionstr()) ; 

	{
	  SV * sperror_sv = perl_get_sv(SPERRNO, GV_ADDMULTI) ;
	  sv_setiv(sperror_sv, 0) ;
	  sv_setpv(sperror_sv, "") ;
	  SvIOK_on(sperror_sv) ;
	}
	}
	sv_NULL = newSVpv("", 0) ;

double
constant(name,arg)
        char *          name
        int             arg

#define GC_version() SPversionstr()
char *
GC_version()

SV *
GC_disconnect(svmbox)
	SV * svmbox
	CODE:
	{
	  int mbox = SvIV(svmbox);
	  if((mbox = SP_disconnect(mbox))==0)
	    RETVAL = &PL_sv_yes;
	  else {
	    SetSpErrorNo(mbox);
	    RETVAL = &PL_sv_no;
	  }
	}
	OUTPUT:
	  RETVAL

AV *
GC_connect_i(rv)
	SV * rv
	PREINIT:
	  SV *MAILBOX, *PRIVATE_GROUP;
	  SV **afetch;
	  int i, error, pr, gm;
	  mailbox mbox = -1;
	  char *sn, *pn, pg[MAX_GROUP_NAME];
	  HV *hv;
	PPCODE:
	  MAILBOX = PRIVATE_GROUP = &PL_sv_undef;
	  if(!SvROK(rv) || SvTYPE(hv = (HV *)SvRV(rv))!=SVt_PVHV)
	    croak("not a HASH reference");
	  for(i=0;i<nconnect_params;i++)
	    if(hv_exists(hv, connect_params[i],
		strlen(connect_params[i])) == FALSE) {
	      SetSpErrorNo(ARGS_INSUFF);
	      goto ending;
            }
	  i=0;
	  afetch = hv_fetch(hv, connect_params[i],
		strlen(connect_params[i]), FALSE); i++;
	  sn = SvPV(*afetch, PL_na);
	  afetch = hv_fetch(hv, connect_params[i],
		strlen(connect_params[i]), FALSE); i++;
	  pn = SvPV(*afetch, PL_na);
	  afetch = hv_fetch(hv, connect_params[i],
		strlen(connect_params[i]), FALSE); i++;
	  pr = SvIV(*afetch);
	  afetch = hv_fetch(hv, connect_params[i],
		strlen(connect_params[i]), FALSE); i++;
	  gm = SvIV(*afetch);
	  if((error = SP_connect(sn,pn,pr,gm,&mbox,pg))>0 && mbox>0) {
	    MAILBOX = sv_2mortal(newSViv(mbox));
	    PRIVATE_GROUP = sv_2mortal(newSVpv(pg, 0));
          } else {
	    SetSpErrorNo(error);
	  }
	ending:
          EXTEND(SP, 2);
          PUSHs(MAILBOX);
          PUSHs(PRIVATE_GROUP);

SV *
GC_join(svmbox, group_name)
	SV * svmbox
	char *group_name
	CODE:
	{
	  int mbox = SvIV(svmbox);
	  if((mbox = SP_join(mbox, group_name))==0) {
	    RETVAL = &PL_sv_yes;
	  } else {
	    SetSpErrorNo(mbox);
	    RETVAL = &PL_sv_no;
	  }
	}
	OUTPUT:
	  RETVAL

SV *
GC_leave(svmbox, group_name)
	SV * svmbox
	char *group_name
	CODE:
	{
	  int mbox = SvIV(svmbox);
	  if((mbox = SP_leave(mbox, group_name))==0) {
	    RETVAL = &PL_sv_yes;
	  } else {
	    SetSpErrorNo(mbox);
	    RETVAL = &PL_sv_no;
	  }
	}
	OUTPUT:
	  RETVAL

SV *
GC_multicast(svmbox, stype, svgroups, mtype, mess)
	SV * svmbox
	service stype
	SV * svgroups
	int16 mtype
	SV * mess
	INIT:
	  static char *groupnames=NULL;
	  static int gsize=-1;
	CODE:
	{
	  int mbox = SvIV(svmbox);
	  int i, ret, ngroups=0;
          size_t mlength;
	  char *groupname;
	  char *message;
	/* It is OK to use NULL.. We only see this, it isn't returned */
	  AV * groups = (AV *)NULL;
	  SV * group = (SV *)NULL;
	  RETVAL = &PL_sv_undef;
	  if(SvROK(svgroups)) {
	    if(SvTYPE(groups = (AV *)SvRV(svgroups))==SVt_PVAV) {
	      ngroups = av_len(groups)+1;
	      if(gsize<ngroups) {
	        if(gsize<0) gsize=1;
		while(gsize<ngroups) gsize<<=1;
		if(!groupnames)
	          New(0, groupnames,gsize*MAX_GROUP_NAME,char);
		else
		  Renew(groupnames,gsize*MAX_GROUP_NAME,char);
	      }
	      for(i=0;i<ngroups;i++) {
		char *string;
		size_t slength;
		SV **afetch = av_fetch(groups, i, FALSE);
		string = SvPV(*afetch, slength);
		strncpy(&groupnames[i*MAX_GROUP_NAME],
			string,
			MAX_GROUP_NAME);
	      }
	    } else if(SvTYPE(group = SvRV(svgroups))==SVt_PV) {
	      groupname = SvPV(group, PL_na);
	    } else {
	      croak("not a SCALAR or ARRAY reference.");
	    }
	  } else if(groupname=SvPV(svgroups, PL_na)) {
	    group = svgroups;
	  } else {
	    SetSpErrorNo(ARGS_INSUFF);
	    goto multi_ending;
	  }

	  message = SvPV(mess, mlength);
	  if(group != NULL) {
	    /* groupname is already set and
	       we are multicasting to a single group */
	    ret = SP_multicast(mbox, stype, groupname,
				mtype, mlength, message);
	  } else if(groups != NULL) {
	    /* groupnames is already set and
	       we are multicasting to a multigroup */
	    ret = SP_multigroup_multicast(mbox, stype, ngroups,
				groupnames,
				mtype, mlength, message);
	  } else {
	    /* Something went horrbily wrong */
	    croak("not SCALAR, SCALAR ref or ARRAY ref.");
	  }
	  if(ret<0)
	    SetSpErrorNo(ret);
	  else
	    RETVAL = newSViv(ret);
	}
	multi_ending:
	OUTPUT:
	  RETVAL

AV *
GC_receive(svmbox, svtimeout=&PL_sv_undef)
	SV * svmbox
	SV * svtimeout
	PREINIT:
	  static int oldgsize=0, newgsize=(1<<6);
	  static int oldmsize=0, newmsize=(1<<15); /* 65k */
	  int i, mbox, endmis, ret, ngrps, msize;
	  int16 mtype;
	  service stype = 0;
	  struct timeval towait;
	  static char *groups=NULL;
	  static char *mess=NULL;
	  char sender[MAX_GROUP_NAME];
	  SV *STYPE, *MTYPE, *MESSAGE, *SENDER, *ENDMIS, *ERROR;
	  AV *GROUPS=(AV *)&PL_sv_undef;
	PPCODE:
	  if(svmbox == &PL_sv_undef) {
	    STYPE=SENDER=MTYPE=ENDMIS=MESSAGE=&PL_sv_undef;
	    SetSpErrorNo(ILLEGAL_SESSION);
	    goto rec_ending;
	  }
	  mbox = SvIV(svmbox);
	  ERROR=&PL_sv_undef;
	  if(svtimeout != &PL_sv_undef) {
	    double timeout;
	    fd_set readfs;
	    towait.tv_sec = 0L;
	    towait.tv_usec = 0L;
	    timeout = SvNV(svtimeout);
	    towait.tv_sec = (unsigned long)timeout;
	    towait.tv_usec =
	      (unsigned long)(1000000.0*(timeout-(double)towait.tv_sec));
	    FD_ZERO(&readfs); FD_SET(mbox, &readfs);
	    if((ret = select(mbox+1, &readfs, NULL, &readfs, &towait))!=1) {
	      STYPE=SENDER=MTYPE=ENDMIS=MESSAGE=&PL_sv_undef;
	      SetSpErrorNo( ret == 0 ? SELECT_TIMEOUT : SELECT_FAILED );
	      goto rec_ending;
	    }
	  }
       try_again:
	  /* realloc or alloc buffer if necessary */
	  if(oldgsize != newgsize) {
	    if(groups)
	      Renew(groups, newgsize*MAX_GROUP_NAME, char);
	    else
	      New(0, groups, newgsize*MAX_GROUP_NAME, char);
	    oldgsize=newgsize;
	  }
	  if(oldmsize != newmsize) {
	    if(mess)
	      Renew(mess, newmsize, char);
	    else
	      New(0, mess, newmsize, char);
	    oldmsize=newmsize;
	  }
	  if((ret=SP_receive(mbox, &stype, sender, newgsize, &ngrps, groups,
		&mtype, &endmis, newmsize, mess))<0) {
		if(ret==BUFFER_TOO_SHORT) {
		  /* Lets double it, so this won't happen again */
		  newmsize=-endmis;
		  ERROR = newSViv(BUFFER_TOO_SHORT);
		  msize = oldmsize;
		  goto try_again;
#ifdef GROUPS_TOO_SHORT
		} else if (ret==GROUPS_TOO_SHORT) {
		  newgsize=-ngrps;
		  ERROR = newSViv(GROUPS_TOO_SHORT);
		  ngrps = oldgsize;
		  goto try_again;
#endif
		} else {
		  STYPE=SENDER=MTYPE=ENDMIS=MESSAGE=&PL_sv_undef;
		  SetSpErrorNo(ret);
		}
	  } else {
	    msize=ret;
	still_okay:
	    /* We recieved the message */
	    if(newgsize+ngrps < 0)
		newgsize*=2;
	    if(ngrps<0) ngrps=oldgsize;	
   	    if(ngrps>0) {
	      GROUPS = (AV *)sv_2mortal((SV *)newAV());
	      for(i=0;i<ngrps;i++)
		av_push(GROUPS, newSVpv(&groups[i*MAX_GROUP_NAME],
		                     MIN(strlen(&groups[i*MAX_GROUP_NAME]),
			                 MAX_GROUP_NAME)));
	    }
	    SENDER=sv_2mortal(newSVpv(sender, 0));
	    STYPE=sv_2mortal(newSViv(stype));
	    MTYPE=sv_2mortal(newSViv(mtype));
	    ENDMIS=(endmis)?(&PL_sv_yes):(&PL_sv_no);
	    MESSAGE=sv_2mortal(newSVpv(mess, msize));
	  }
	rec_ending:
          EXTEND(SP, 6);
          PUSHs(STYPE);
	  PUSHs(SENDER);
	  PUSHs(sv_2mortal(newRV((SV *)GROUPS)));
	  PUSHs(MTYPE);
	  PUSHs(ENDMIS);
          PUSHs(MESSAGE);

SV *
GC_poll(svmbox)
	SV * svmbox
	PREINIT:
	  int mbox = SvIV(svmbox);
	CODE:
	  mbox = SP_poll(mbox);
	  if(mbox<0) {
	    SetSpErrorNo(mbox);
	    RETVAL = &PL_sv_undef;
	  } else {
	    RETVAL = newSViv(mbox);
	  }
	OUTPUT:
	  RETVAL
