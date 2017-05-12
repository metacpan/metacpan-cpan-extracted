/*
 * This file was generated automatically by xsubpp version 1.933 from the 
 * contents of Pvm.xs. Don't edit this file, edit Pvm.xs instead.
 *
 *	ANY CHANGES MADE HERE WILL BE LOST! 
 *
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* MY EXTENSION */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include "pvm3.h"
 
#define MAXPROCS	100
#define MAXHOSTS	100
#define MAXSTR		100000

#define STRING          1
#define INTEGER         2
#define DOUBLE          3
 
static SV *recvf_callback = (SV *)NULL;
static int (*olmatch)();

static int
recvf_foo( int bufid, int tid, int tag )
{
dSP ;
int count;
int compare_val;

ENTER ;
SAVETMPS ;

PUSHMARK(sp) ;
XPUSHs(sv_2mortal(newSViv(bufid)));
XPUSHs(sv_2mortal(newSViv(tid)));
XPUSHs(sv_2mortal(newSViv(tag)));
PUTBACK ;

count = perl_call_sv(recvf_callback,G_SCALAR);

SPAGAIN ;

if ( count != 1 )
   croak("pvm_recvf: comparison function must return only one scalar\n");

compare_val = POPi;

PUTBACK ;
FREETMPS ;
LEAVE ;

return compare_val;

}


static HV *
derefHV( SV *node )
{
HV *hv_tmp;
 
if ( SvROK(node) ){
   if ( SvTYPE(SvRV(node)) == SVt_PVHV ){
      hv_tmp = (HV *)SvRV(node);
      return hv_tmp;
   }
}
return 0;
}

static int
string_byte_cnt( char *str )
{
int cnt=0;

   while( str[cnt] != '\0' ){
      cnt++;
   }
   /* add 1 for the byte holding the '\0' */
   return cnt+1;
}

static int
string_type( char *str )
{
int i=0;
int could_be_double=0;
int must_be_double=0;
 
    while ( str[i] != '\0' ){
        /* */
        if ( ! isdigit(str[i]) ){
             if ( str[i] == '.' && could_be_double == 0 ){
                could_be_double = 1;
             }else{
                return STRING;
             }
        }
        /* else{
             if ( could_be_double ){
                if ( str[i] != '0' ){
                   must_be_double = 1;
                }
             }
        } */
        i++;
    }
    if ( could_be_double ) return DOUBLE;
    return INTEGER;
}

static char *
buffer_string( char *str, int new_flag )
{
static int bufsize;
static char *buf ;
 
   if ( new_flag ){
      bufsize = 1;
      free(buf);
      buf = (char *)calloc(strlen(str)+1,sizeof(char));
      buf[0] = '\0';
      bufsize = (strlen(str)+1)*sizeof(char);
      sprintf(buf,"%s", str );
   }else{
      bufsize += (strlen(str)+1)*sizeof(char);
      buf = (char *)realloc(buf,bufsize);
      /* use vertical tab as token separator */
      sprintf(buf,"%s\v%s",buf, str );
   }
   return buf ;
}

/*****/

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
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	if (strEQ(name, "PVM_BYTE"))
#ifdef PVM_BYTE
	    return PVM_BYTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_CPLX"))
#ifdef PVM_CPLX
	    return PVM_CPLX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_DCPLX"))
#ifdef PVM_DCPLX
	    return PVM_DCPLX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_DOUBLE"))
#ifdef PVM_DOUBLE
	    return PVM_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_FLOAT"))
#ifdef PVM_FLOAT
	    return PVM_FLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_INT"))
#ifdef PVM_INT
	    return PVM_INT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_LONG"))
#ifdef PVM_LONG
	    return PVM_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_SHORT"))
#ifdef PVM_SHORT
	    return PVM_SHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_STR"))
#ifdef PVM_STR
	    return PVM_STR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_UINT"))
#ifdef PVM_UINT
	    return PVM_UINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_ULONG"))
#ifdef PVM_ULONG
	    return PVM_ULONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PVM_USHORT"))
#ifdef PVM_USHORT
	    return PVM_USHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmAllowDirect"))
#ifdef PvmAllowDirect
	    return PvmAllowDirect;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmAlready"))
#ifdef PvmAlready
	    return PvmAlready;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmAutoErr"))
#ifdef PvmAutoErr
	    return PvmAutoErr;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmBadMsg"))
#ifdef PvmBadMsg
	    return PvmBadMsg;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmBadParam"))
#ifdef PvmBadParam
	    return PvmBadParam;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmBadVersion"))
#ifdef PvmBadVersion
	    return PvmBadVersion;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmCantStart"))
#ifdef PvmCantStart
	    return PvmCantStart;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDSysErr"))
#ifdef PvmDSysErr
	    return PvmDSysErr;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDataDefault"))
#ifdef PvmDataDefault
	    return PvmDataDefault;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDataFoo"))
#ifdef PvmDataFoo
	    return PvmDataFoo;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDataInPlace"))
#ifdef PvmDataInPlace
	    return PvmDataInPlace;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDataRaw"))
#ifdef PvmDataRaw
	    return PvmDataRaw;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDebugMask"))
#ifdef PvmDebugMask
	    return PvmDebugMask;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDontRoute"))
#ifdef PvmDontRoute
	    return PvmDontRoute;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDupEntry"))
#ifdef PvmDupEntry
	    return PvmDupEntry;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDupGroup"))
#ifdef PvmDupGroup
	    return PvmDupGroup;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmDupHost"))
#ifdef PvmDupHost
	    return PvmDupHost;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmFragSize"))
#ifdef PvmFragSize
	    return PvmFragSize;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmHostAdd"))
#ifdef PvmHostAdd
	    return PvmHostAdd;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmHostCompl"))
#ifdef PvmHostCompl
	    return PvmHostCompl;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmHostDelete"))
#ifdef PvmHostDelete
	    return PvmHostDelete;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmHostFail"))
#ifdef PvmHostFail
	    return PvmHostFail;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmMismatch"))
#ifdef PvmMismatch
	    return PvmMismatch;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmMppFront"))
#ifdef PvmMppFront
	    return PvmMppFront;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoBuf"))
#ifdef PvmNoBuf
	    return PvmNoBuf;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoData"))
#ifdef PvmNoData
	    return PvmNoData;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoEntry"))
#ifdef PvmNoEntry
	    return PvmNoEntry;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoFile"))
#ifdef PvmNoFile
	    return PvmNoFile;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoGroup"))
#ifdef PvmNoGroup
	    return PvmNoGroup;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoHost"))
#ifdef PvmNoHost
	    return PvmNoHost;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoInst"))
#ifdef PvmNoInst
	    return PvmNoInst;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoMem"))
#ifdef PvmNoMem
	    return PvmNoMem;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoParent"))
#ifdef PvmNoParent
	    return PvmNoParent;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoSuchBuf"))
#ifdef PvmNoSuchBuf
	    return PvmNoSuchBuf;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNoTask"))
#ifdef PvmNoTask
	    return PvmNoTask;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNotImpl"))
#ifdef PvmNotImpl
	    return PvmNotImpl;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNotInGroup"))
#ifdef PvmNotInGroup
	    return PvmNotInGroup;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmNullGroup"))
#ifdef PvmNullGroup
	    return PvmNullGroup;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmOk"))
#ifdef PvmOk
	    return PvmOk;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmOutOfRes"))
#ifdef PvmOutOfRes
	    return PvmOutOfRes;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmOutputCode"))
#ifdef PvmOutputCode
	    return PvmOutputCode;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmOutputTid"))
#ifdef PvmOutputTid
	    return PvmOutputTid;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmOverflow"))
#ifdef PvmOverflow
	    return PvmOverflow;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmPollConstant"))
#ifdef PvmPollConstant
	    return PvmPollConstant;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmPollSleep"))
#ifdef PvmPollSleep
	    return PvmPollSleep;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmPollTime"))
#ifdef PvmPollTime
	    return PvmPollTime;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmPollType"))
#ifdef PvmPollType
	    return PvmPollType;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmResvTids"))
#ifdef PvmResvTids
	    return PvmResvTids;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmRoute"))
#ifdef PvmRoute
	    return PvmRoute;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmRouteDirect"))
#ifdef PvmRouteDirect
	    return PvmRouteDirect;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmSelfOutputCode"))
#ifdef PvmSelfOutputCode
	    return PvmSelfOutputCode;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmSelfOutputTid"))
#ifdef PvmSelfOutputTid
	    return PvmSelfOutputTid;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmSelfTraceCode"))
#ifdef PvmSelfTraceCode
	    return PvmSelfTraceCode;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmSelfTraceTid"))
#ifdef PvmSelfTraceTid
	    return PvmSelfTraceTid;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmShowTids"))
#ifdef PvmShowTids
	    return PvmShowTids;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmSysErr"))
#ifdef PvmSysErr
	    return PvmSysErr;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTaskArch"))
#ifdef PvmTaskArch
	    return PvmTaskArch;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTaskChild"))
#ifdef PvmTaskChild
	    return PvmTaskChild;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTaskDebug"))
#ifdef PvmTaskDebug
	    return PvmTaskDebug;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTaskDefault"))
#ifdef PvmTaskDefault
	    return PvmTaskDefault;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTaskExit"))
#ifdef PvmTaskExit
	    return PvmTaskExit;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTaskHost"))
#ifdef PvmTaskHost
	    return PvmTaskHost;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTaskSelf"))
#ifdef PvmTaskSelf
	    return PvmTaskSelf;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTaskTrace"))
#ifdef PvmTaskTrace
	    return PvmTaskTrace;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTraceCode"))
#ifdef PvmTraceCode
	    return PvmTraceCode;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PvmTraceTid"))
#ifdef PvmTraceTid
	    return PvmTraceTid;
#else
	    goto not_there;
#endif
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
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
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


XS(XS_Pvm_constant)
{
    dXSARGS;
    if (items != 2)
	croak("Usage: Pvm::constant(name,arg)");
    {
	char *	name = (char *)SvPV(ST(0),na);
	int	arg = (int)SvIV(ST(1));
	double	RETVAL;

	RETVAL = constant(name, arg);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_spawn)
{
    dXSARGS;
    if (items < 2 || items > 4)
	croak("Usage: Pvm::spawn(task,ntask,flag=PvmTaskDefault,where=\"\")");
    SP -= items;
    {
	char *	task = (char *)SvPV(ST(0),na);
	int	ntask = (int)SvIV(ST(1));
	int	flag;
	char *	where;
        int tids[MAXPROCS];
	int info;
        int i;

	if (items < 3)
	    flag = PvmTaskDefault;
	else {
	    flag = (int)SvIV(ST(2));
	}

	if (items < 4)
	    where = "";
	else {
	    where = (char *)SvPV(ST(3),na);
	}
	info = pvm_spawn(task,0,flag,where,ntask,tids);
	XPUSHs(sv_2mortal(newSViv(info)));
        if ( i > 0 ){
	   for (i=0;i<info;i++){
	     XPUSHs(sv_2mortal(newSViv(tids[i])));
	   }
        } /* else empty list is returned */
	PUTBACK;
	return;
    }
}

XS(XS_Pvm_initsend)
{
    dXSARGS;
    if (items < 0 || items > 1)
	croak("Usage: Pvm::initsend(flag=PvmDataDefault)");
    {
	int	flag;
	int	RETVAL;

	if (items < 1)
	    flag = PvmDataDefault;
	else {
	    flag = (int)SvIV(ST(0));
	}
	RETVAL = pvm_initsend(flag);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_send)
{
    dXSARGS;
    if (items != 2)
	croak("Usage: Pvm::send(tid,tag)");
    {
	int	tid = (int)SvIV(ST(0));
	int	tag = (int)SvIV(ST(1));
	int	RETVAL;
	RETVAL = pvm_send(tid,tag);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_psend)
{
    dXSARGS;
    if (items < 2)
	croak("Usage: Pvm::psend(tid,tag,...)");
    {
	int	tid = (int)SvIV(ST(0));
	int	tag = (int)SvIV(ST(1));
	int i;
	char *str, *po;
	int	RETVAL;
	for(i=2;i<items;i++){
	   po = (char *)SvPV(ST(i),na);
           if ( i == 2 ) {
              str = buffer_string(po,1);
           } else{
              str = buffer_string(po,0);
           }
	}
	if ( items == 2 ){
	   str = (char *)calloc(1,sizeof(char));
	   str[0] = '\0';
	}
	RETVAL = pvm_psend(tid,tag,str,string_byte_cnt(str),PVM_BYTE);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_mcast)
{
    dXSARGS;
    {
	int i;
	int tag_num;
	int proc_num;
	int tids[MAXPROCS];
	int tag;
	int	RETVAL;
	if ( items < 2 )
	   croak("Usage: Pvm::pvm_mcast(tids_list,tag)");
	for (i=0;i<items-1;i++){
	  tids[i] = SvIV(ST(i));
	}
	proc_num = tag_num = items-1;
	tag = SvIV(ST(tag_num));
	RETVAL = pvm_mcast(tids,proc_num,tag);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_sendsig)
{
    dXSARGS;
    if (items != 2)
	croak("Usage: Pvm::sendsig(tid,sig)");
    {
	int	tid = (int)SvIV(ST(0));
	int	sig = (int)SvIV(ST(1));
	int	RETVAL;
	RETVAL = pvm_sendsig(tid,sig);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_probe)
{
    dXSARGS;
    if (items < 0 || items > 2)
	croak("Usage: Pvm::probe(tid=-1,tag=-1)");
    {
	int	tid;
	int	tag;
	int	RETVAL;

	if (items < 1)
	    tid = -1;
	else {
	    tid = (int)SvIV(ST(0));
	}

	if (items < 2)
	    tag = -1;
	else {
	    tag = (int)SvIV(ST(1));
	}
	RETVAL = pvm_probe(tid,tag);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_recv)
{
    dXSARGS;
    if (items < 0 || items > 2)
	croak("Usage: Pvm::recv(tid=-1,tag=-1)");
    {
	int	tid;
	int	tag;
	int	RETVAL;

	if (items < 1)
	    tid = -1;
	else {
	    tid = (int)SvIV(ST(0));
	}

	if (items < 2)
	    tag = -1;
	else {
	    tag = (int)SvIV(ST(1));
	}
	RETVAL = pvm_recv(tid,tag);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_nrecv)
{
    dXSARGS;
    if (items < 0 || items > 2)
	croak("Usage: Pvm::nrecv(tid=-1,tag=-1)");
    {
	int	tid;
	int	tag;
	int	RETVAL;

	if (items < 1)
	    tid = -1;
	else {
	    tid = (int)SvIV(ST(0));
	}

	if (items < 2)
	    tag = -1;
	else {
	    tag = (int)SvIV(ST(1));
	}
	RETVAL = pvm_nrecv(tid,tag);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_trecv)
{
    dXSARGS;
    if (items < 0 || items > 4)
	croak("Usage: Pvm::trecv(tid=-1,tag=-1,sec=1,usec=0)");
    {
	int	tid;
	int	tag;
	int	sec;
	int	usec;
	struct timeval tmout;
	int	RETVAL;

	if (items < 1)
	    tid = -1;
	else {
	    tid = (int)SvIV(ST(0));
	}

	if (items < 2)
	    tag = -1;
	else {
	    tag = (int)SvIV(ST(1));
	}

	if (items < 3)
	    sec = 1;
	else {
	    sec = (int)SvIV(ST(2));
	}

	if (items < 4)
	    usec = 0;
	else {
	    usec = (int)SvIV(ST(3));
	}
	tmout.tv_sec = sec;
	tmout.tv_usec = usec;
	RETVAL = pvm_trecv(tid,tag,&tmout);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_precv)
{
    dXSARGS;
    if (items < 0 || items > 2)
	croak("Usage: Pvm::precv(tid=-1,tag=-1)");
    SP -= items;
    {
	int	tid;
	int	tag;
	int info, src, stag, scnt;
	char str[MAXSTR];
	char *po;
	int type;

	if (items < 1)
	    tid = -1;
	else {
	    tid = (int)SvIV(ST(0));
	}

	if (items < 2)
	    tag = -1;
	else {
	    tag = (int)SvIV(ST(1));
	}
	info = pvm_precv(tid,tag,str,MAXSTR,PVM_BYTE,&src,&stag,&scnt);
	XPUSHs(sv_2mortal(newSViv(info)));
	XPUSHs(sv_2mortal(newSViv(src)));
	XPUSHs(sv_2mortal(newSViv(stag)));
	po = strtok(str,"\v");
        while ( po != NULL ){
           type = string_type(po); 
           switch(type){
                case STRING:
                        XPUSHs(sv_2mortal(newSVpv(po,0)));
                        break;
                case INTEGER:
                        XPUSHs(sv_2mortal(newSViv(atoi(po))));
                        break;
                case DOUBLE:
                        XPUSHs(sv_2mortal(newSVnv(atof(po))));
                        break;
           }
	   po = strtok(NULL,"\v");
        }
	PUTBACK;
	return;
    }
}

XS(XS_Pvm_parent)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::parent()");
    {
	int	RETVAL;
	RETVAL = pvm_parent();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_mytid)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::mytid()");
    {
	int	RETVAL;
	RETVAL = pvm_mytid();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_pack)
{
    dXSARGS;
    {
	int i;
	char *str, *po;
	int	RETVAL;
        for (i=0;i<items;i++){
	   po = (char *)SvPV(ST(i),na);
           if ( i == 0 ) {
              str = buffer_string(po,1);
           } else{
              str = buffer_string(po,0);
           }
	}
	if ( items <= 0 ){
	   str = (char *)calloc(1,sizeof(char));
	   str[0] ='\0';
	}
        RETVAL = pvm_pkstr(str); 
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_unpack)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::unpack()");
    SP -= items;
    {
	char str[MAXSTR], *po;
	int type;
	pvm_upkstr(str); 
	po = strtok(str,"\v");
        while ( po != NULL ){
           type = string_type(po); 
           switch(type){
                case STRING:
                        XPUSHs(sv_2mortal(newSVpv(po,0)));
                        break;
                case INTEGER:
                        XPUSHs(sv_2mortal(newSViv(atoi(po))));
                        break;
                case DOUBLE:
                        XPUSHs(sv_2mortal(newSVnv(atof(po))));
                        break;
           }
	   po = strtok(NULL,"\v");
        }
	PUTBACK;
	return;
    }
}

XS(XS_Pvm_exit)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::exit()");
    {
	int	RETVAL;
	RETVAL = pvm_exit();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_halt)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::halt()");
    {
	int	RETVAL;
	RETVAL = pvm_halt();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_catchout)
{
    dXSARGS;
    if (items < 0 || items > 1)
	croak("Usage: Pvm::catchout(io=stdout)");
    {
	FILE *	io;
	int	RETVAL;

	if (items < 1)
	    io = stdout;
	else {
	    io = IoIFP(sv_2io(ST(0)));
	}
	RETVAL = pvm_catchout(io);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_tasks)
{
    dXSARGS;
    if (items < 0 || items > 1)
	croak("Usage: Pvm::tasks(where=0)");
    SP -= items;
    {
	int	where;
	int ntask,i,info;
	struct pvmtaskinfo *taskp;
	int ti_tid,ti_ptid,ti_host,ti_flag,ti_pid;
	char ti_a_out[256];
	HV *hv_tmp;

	if (items < 1)
	    where = 0;
	else {
	    where = (int)SvIV(ST(0));
	}
	info = pvm_tasks(where,&ntask,&taskp);
	XPUSHs(sv_2mortal(newSViv(info)));
	for(i=0;i<ntask;i++){
	   strcpy(ti_a_out,taskp[i].ti_a_out);
	   ti_tid = taskp[i].ti_tid;
	   ti_ptid = taskp[i].ti_ptid;
	   ti_pid = taskp[i].ti_pid;
	   ti_host = taskp[i].ti_host;
	   ti_flag = taskp[i].ti_flag;
	   /* set up hash entry */
	   hv_tmp = newHV();
	   /* sv_2mortal((SV *)hv_tmp); */
	   hv_store(hv_tmp,"ti_a_out",8,newSVpv(ti_a_out,0),0);
	   hv_store(hv_tmp,"ti_tid",6,newSViv(ti_tid),0);
	   hv_store(hv_tmp,"ti_ptid",7,newSViv(ti_ptid),0);
	   hv_store(hv_tmp,"ti_pid",6,newSViv(ti_pid),0);
	   hv_store(hv_tmp,"ti_host",7,newSViv(ti_host),0);
	   hv_store(hv_tmp,"ti_flag",7,newSViv(ti_flag),0);
	   /* create reference and stick in on the stack */
	   XPUSHs(sv_2mortal(newRV((SV *)hv_tmp)));
	}
	PUTBACK;
	return;
    }
}

XS(XS_Pvm_config)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::config()");
    SP -= items;
    {
	int nhosts, narch, info;
	struct pvmhostinfo *hostp;
	char hi_name[256], hi_arch[256];
	int hi_tid, hi_speed;
	int i;
	HV *hv_tmp;
	info = pvm_config(&nhosts,&narch,&hostp);
	XPUSHs(sv_2mortal(newSViv(info)));
	for (i=0;i<nhosts;i++){
	   hi_tid = hostp[i].hi_tid;
	   strcpy(hi_name,hostp[i].hi_name);
	   strcpy(hi_arch,hostp[i].hi_arch);
	   hi_speed = hostp[i].hi_speed; 
	   /* set up hash entry */
	   hv_tmp = newHV();
	   /* sv_2mortal((SV *)hv_tmp); */
	   hv_store(hv_tmp,"hi_tid",6,newSViv(hi_tid),0);
	   hv_store(hv_tmp,"hi_name",7,newSVpv(hi_name,0),0);
	   hv_store(hv_tmp,"hi_arch",7,newSVpv(hi_arch,0),0);
	   hv_store(hv_tmp,"hi_speed",8,newSViv(hi_speed),0);
	   /* create reference and stick in on the stack */
	   XPUSHs(sv_2mortal(newRV((SV *)hv_tmp)));
	}
	PUTBACK;
	return;
    }
}

XS(XS_Pvm_addhosts)
{
    dXSARGS;
    SP -= items;
    {
	int i;
	int info;
	char *po;
	char *hosts[MAXHOSTS]; 
	int infos[MAXHOSTS];
	if ( items < 1 )
	   croak("Usage: Pvm::pvm_addhosts(host_list)");
        for (i=0;i<items;i++){
	   hosts[i] = (char *)SvPV(ST(i),na);
	   /*
	   hosts[i] = (char *)calloc(strlen(po)+1,sizeof(char));
	   strcpy(hosts[i],po);
	   */
	}
	info = pvm_addhosts(hosts,items,infos);
        XPUSHs(sv_2mortal(newSViv(info)));	
        for (i=0;i<items;i++){
	    XPUSHs(sv_2mortal(newSViv(infos[i])));
	}
	/*
        for (i=0;i<items;i++){
	    free(hosts[i]);
	}
	*/
	PUTBACK;
	return;
    }
}

XS(XS_Pvm_delhosts)
{
    dXSARGS;
    SP -= items;
    {
	char *po;
	char *hosts[MAXHOSTS]; 
	int infos[MAXHOSTS];
	int info, i, nhost;
	if ( items < 1 )
	   croak("Usage: Pvm::pvm_delhosts(host_list)");
        for (i=0;i<items;i++){
	   hosts[i] = (char *)SvPV(ST(i),na);
	   /*
	   hosts[i] = (char *)calloc(strlen(po)+1,sizeof(char));
	   strcpy(hosts[i],po);
	   */
	}
	info = pvm_delhosts(hosts,items,infos);
        XPUSHs(sv_2mortal(newSViv(info)));	
        for (i=0;i<items;i++){
	    XPUSHs(sv_2mortal(newSViv(infos[i])));
	}
	/*
        for (i=0;i<items;i++){
	    free(hosts[i]);
	}
	*/
	PUTBACK;
	return;
    }
}

XS(XS_Pvm_bufinfo)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::bufinfo(bufid)");
    SP -= items;
    {
	int	bufid = (int)SvIV(ST(0));
	int bytes, tag, tid, info;
	info = pvm_bufinfo(bufid,&bytes,&tag,&tid);
	XPUSHs(sv_2mortal(newSViv(info)));
	XPUSHs(sv_2mortal(newSViv(bytes)));
	XPUSHs(sv_2mortal(newSViv(tag)));
	XPUSHs(sv_2mortal(newSViv(tid)));
	PUTBACK;
	return;
    }
}

XS(XS_Pvm_freebuf)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::freebuf(bufid)");
    {
	int	bufid = (int)SvIV(ST(0));
	int	RETVAL;
	RETVAL = pvm_freebuf(bufid);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_getrbuf)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::getrbuf()");
    {
	int	RETVAL;
	RETVAL = pvm_getrbuf();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_getsbuf)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::getsbuf()");
    {
	int	RETVAL;
	RETVAL = pvm_getsbuf();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_mkbuf)
{
    dXSARGS;
    if (items < 0 || items > 1)
	croak("Usage: Pvm::mkbuf(encode=PvmDataDefault)");
    {
	int	encode;
	int	RETVAL;

	if (items < 1)
	    encode = PvmDataDefault;
	else {
	    encode = (int)SvIV(ST(0));
	}
	RETVAL = pvm_mkbuf(encode);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_setrbuf)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::setrbuf(bufid)");
    {
	int	bufid = (int)SvIV(ST(0));
	int	RETVAL;
	RETVAL = pvm_setrbuf(bufid);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_setsbuf)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::setsbuf(bufid)");
    {
	int	bufid = (int)SvIV(ST(0));
	int	RETVAL;
	RETVAL = pvm_setsbuf(bufid);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_kill)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::kill(tid)");
    {
	int	tid = (int)SvIV(ST(0));
	int	RETVAL;
	RETVAL = pvm_kill(tid);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_mstat)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::mstat(host)");
    {
	char *	host = (char *)SvPV(ST(0),na);
	int	RETVAL;
	RETVAL = pvm_mstat(host);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_pstat)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::pstat(tid)");
    {
	int	tid = (int)SvIV(ST(0));
	int	RETVAL;
	RETVAL = pvm_pstat(tid);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_tidtohost)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::tidtohost(tid)");
    {
	int	tid = (int)SvIV(ST(0));
	int	RETVAL;
	RETVAL = pvm_tidtohost(tid);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_getopt)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::getopt(what)");
    {
	int	what = (int)SvIV(ST(0));
	int	RETVAL;
	RETVAL = pvm_getopt(what);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_setopt)
{
    dXSARGS;
    if (items != 2)
	croak("Usage: Pvm::setopt(what,val)");
    {
	int	what = (int)SvIV(ST(0));
	int	val = (int)SvIV(ST(1));
	int	RETVAL;
	RETVAL = pvm_setopt(what,val);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_reg_hoster)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::reg_hoster()");
    {
	int	RETVAL;
	RETVAL = pvm_reg_hoster();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_reg_tasker)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::reg_tasker()");
    {
	int	RETVAL;
	RETVAL = pvm_reg_tasker();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_reg_rm)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::reg_rm()");
    {
	struct pvmhostinfo *hip;
	int	RETVAL;
	RETVAL = pvm_reg_rm(&hip);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_perror)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::perror(msg)");
    {
	char *	msg = (char *)SvPV(ST(0),na);
	int	RETVAL;
	RETVAL = pvm_perror(msg);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_notify)
{
    dXSARGS;
    if (items < 2)
	croak("Usage: Pvm::notify(what,tag,...)");
    {
	int	what = (int)SvIV(ST(0));
	int	tag = (int)SvIV(ST(1));
	int i, tids[MAXPROCS];
	int	RETVAL;
	switch(what){
	   case PvmTaskExit:
	   case PvmHostDelete:
		if ( items < 3 )
		   croak("Usage: Pvm::pvm_notify(what,tag,tid_list");
        	for (i=2;i<items;i++){
	  	   tids[i-2] = SvIV(ST(i));
		}
		RETVAL = pvm_notify(what,tag,items-2,tids);
		break;
	   case PvmHostAdd:
		RETVAL = pvm_notify(what,tag,0,tids);
		break;
	}
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_recv_notify)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::recv_notify()");
    {
	int id;
	int	RETVAL;
	pvm_recv(-1,-1);
	pvm_upkint(&id,1,1);
	RETVAL = id;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Pvm_hostsync)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::hostsync(hst)");
    SP -= items;
    {
	int	hst = (int)SvIV(ST(0));
	struct timeval rclk, delta;
	int info;
	int sec, usec;
	HV *hv_tmp;
	info = pvm_hostsync(hst,&rclk,&delta);
	XPUSHs(sv_2mortal(newSViv(info)));
	sec = rclk.tv_sec;
	usec = rclk.tv_usec;
	/* set up hash entry */
	hv_tmp = newHV();
	hv_store(hv_tmp,"tv_sec",6,newSViv(sec),0);
	hv_store(hv_tmp,"hi_usec",7,newSViv(usec),0);
	/* create reference and stick in on the stack */
	XPUSHs(sv_2mortal(newRV((SV *)hv_tmp)));
	sec = delta.tv_sec;
	usec = delta.tv_usec;
	/* set up hash entry */
	hv_tmp = newHV();
	hv_store(hv_tmp,"tv_sec",6,newSViv(sec),0);
	hv_store(hv_tmp,"hi_usec",7,newSViv(usec),0);
	/* create reference and stick in on the stack */
	XPUSHs(sv_2mortal(newRV((SV *)hv_tmp)));
	PUTBACK;
	return;
    }
}

XS(XS_Pvm_recvf)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: Pvm::recvf(fn)");
    {
	SV *	fn = ST(0);
	if ( recvf_callback == (SV *)NULL ){
	   recvf_callback = newSVsv(fn);
	}else{
	   sv_setsv(recvf_callback,fn);
	}
	olmatch = pvm_recvf(recvf_foo);
    }
    XSRETURN(1);
}

XS(XS_Pvm_recvf_old)
{
    dXSARGS;
    if (items != 0)
	croak("Usage: Pvm::recvf_old()");
    {
	if ( olmatch !=  NULL ){
	   pvm_recvf(olmatch);
	}
    }
    XSRETURN(1);
}

#ifdef __cplusplus
extern "C"
#endif
XS(boot_Pvm)
{
    dXSARGS;
    char* file = __FILE__;

    XS_VERSION_BOOTCHECK ;

        newXS("Pvm::constant", XS_Pvm_constant, file);
        newXSproto("Pvm::spawn", XS_Pvm_spawn, file, "$$;$$");
        newXSproto("Pvm::initsend", XS_Pvm_initsend, file, ";$");
        newXSproto("Pvm::send", XS_Pvm_send, file, "$$");
        newXSproto("Pvm::psend", XS_Pvm_psend, file, "$$;@");
        newXSproto("Pvm::mcast", XS_Pvm_mcast, file, "@");
        newXSproto("Pvm::sendsig", XS_Pvm_sendsig, file, "$$");
        newXSproto("Pvm::probe", XS_Pvm_probe, file, ";$$");
        newXSproto("Pvm::recv", XS_Pvm_recv, file, ";$$");
        newXSproto("Pvm::nrecv", XS_Pvm_nrecv, file, ";$$");
        newXSproto("Pvm::trecv", XS_Pvm_trecv, file, ";$$$$");
        newXSproto("Pvm::precv", XS_Pvm_precv, file, ";$$");
        newXSproto("Pvm::parent", XS_Pvm_parent, file, "");
        newXSproto("Pvm::mytid", XS_Pvm_mytid, file, "");
        newXSproto("Pvm::pack", XS_Pvm_pack, file, "@");
        newXSproto("Pvm::unpack", XS_Pvm_unpack, file, "");
        newXSproto("Pvm::exit", XS_Pvm_exit, file, "");
        newXSproto("Pvm::halt", XS_Pvm_halt, file, "");
        newXSproto("Pvm::catchout", XS_Pvm_catchout, file, ";$");
        newXSproto("Pvm::tasks", XS_Pvm_tasks, file, ";$");
        newXSproto("Pvm::config", XS_Pvm_config, file, "");
        newXSproto("Pvm::addhosts", XS_Pvm_addhosts, file, "@");
        newXSproto("Pvm::delhosts", XS_Pvm_delhosts, file, "@");
        newXSproto("Pvm::bufinfo", XS_Pvm_bufinfo, file, "$");
        newXSproto("Pvm::freebuf", XS_Pvm_freebuf, file, "$");
        newXSproto("Pvm::getrbuf", XS_Pvm_getrbuf, file, "");
        newXSproto("Pvm::getsbuf", XS_Pvm_getsbuf, file, "");
        newXSproto("Pvm::mkbuf", XS_Pvm_mkbuf, file, "$");
        newXSproto("Pvm::setrbuf", XS_Pvm_setrbuf, file, "$");
        newXSproto("Pvm::setsbuf", XS_Pvm_setsbuf, file, "$");
        newXSproto("Pvm::kill", XS_Pvm_kill, file, "$");
        newXSproto("Pvm::mstat", XS_Pvm_mstat, file, "$");
        newXSproto("Pvm::pstat", XS_Pvm_pstat, file, "$");
        newXSproto("Pvm::tidtohost", XS_Pvm_tidtohost, file, "$");
        newXSproto("Pvm::getopt", XS_Pvm_getopt, file, "$");
        newXSproto("Pvm::setopt", XS_Pvm_setopt, file, "$$");
        newXSproto("Pvm::reg_hoster", XS_Pvm_reg_hoster, file, "");
        newXSproto("Pvm::reg_tasker", XS_Pvm_reg_tasker, file, "");
        newXSproto("Pvm::reg_rm", XS_Pvm_reg_rm, file, "");
        newXSproto("Pvm::perror", XS_Pvm_perror, file, "$");
        newXSproto("Pvm::notify", XS_Pvm_notify, file, "$$;@");
        newXSproto("Pvm::recv_notify", XS_Pvm_recv_notify, file, "");
        newXS("Pvm::hostsync", XS_Pvm_hostsync, file);
        newXSproto("Pvm::recvf", XS_Pvm_recvf, file, "$");
        newXSproto("Pvm::recvf_old", XS_Pvm_recvf_old, file, "");
    ST(0) = &sv_yes;
    XSRETURN(1);
}
