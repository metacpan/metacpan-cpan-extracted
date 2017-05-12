/*                               -*- Mode: C -*- 
 * $Basename$
 * $Revision$
 * Author          : Edward Walker / Denis Leconte
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Thu Sep 20 20:23:12 2001
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
#define MAXARGS		50

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
 
  if ( SvROK(node) )
  {
    if ( SvTYPE(SvRV(node)) == SVt_PVHV )
    {
      hv_tmp = (HV *)SvRV(node);
      return hv_tmp;
    }
  }
  return 0;
}

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
  /* This function is used for autoloading, no need to optimeze for
     speed.  The ifdef stuff also makes not too much sense, because
     nobody will handle different name sets anyway. */
  errno = 0;
  if (strEQ(name, "PVM_BYTE"))              return PVM_BYTE;
  if (strEQ(name, "PVM_CPLX"))              return PVM_CPLX;
  if (strEQ(name, "PVM_DCPLX"))             return PVM_DCPLX;
  if (strEQ(name, "PVM_DOUBLE"))            return PVM_DOUBLE;
  if (strEQ(name, "PVM_FLOAT"))             return PVM_FLOAT;
  if (strEQ(name, "PVM_INT"))               return PVM_INT;
  if (strEQ(name, "PVM_LONG"))              return PVM_LONG;
  if (strEQ(name, "PVM_SHORT"))             return PVM_SHORT;
  if (strEQ(name, "PVM_STR"))               return PVM_STR;
  if (strEQ(name, "PVM_UINT"))              return PVM_UINT;
  if (strEQ(name, "PVM_ULONG"))             return PVM_ULONG;
  if (strEQ(name, "PVM_USHORT"))            return PVM_USHORT;
  if (strEQ(name, "PvmAllowDirect"))        return PvmAllowDirect;
  if (strEQ(name, "PvmAlready"))            return PvmAlready;
  if (strEQ(name, "PvmAutoErr"))            return PvmAutoErr;
  if (strEQ(name, "PvmBadMsg"))             return PvmBadMsg;
  if (strEQ(name, "PvmBadParam"))           return PvmBadParam;
  if (strEQ(name, "PvmBadVersion"))         return PvmBadVersion;
  if (strEQ(name, "PvmCantStart"))          return PvmCantStart;
  if (strEQ(name, "PvmDSysErr"))            return PvmDSysErr;
  if (strEQ(name, "PvmDataDefault"))        return PvmDataDefault;
  if (strEQ(name, "PvmDataFoo"))            return PvmDataFoo;
  if (strEQ(name, "PvmDataInPlace"))        return PvmDataInPlace;
  if (strEQ(name, "PvmDataRaw"))            return PvmDataRaw;
  if (strEQ(name, "PvmDebugMask"))          return PvmDebugMask;
  if (strEQ(name, "PvmDontRoute"))          return PvmDontRoute;
  if (strEQ(name, "PvmDupEntry"))           return PvmDupEntry;
  if (strEQ(name, "PvmDupGroup"))           return PvmDupGroup;
  if (strEQ(name, "PvmDupHost"))            return PvmDupHost;
  if (strEQ(name, "PvmFragSize"))           return PvmFragSize;
  if (strEQ(name, "PvmHostAdd"))            return PvmHostAdd;
  if (strEQ(name, "PvmHostCompl"))          return PvmHostCompl;
  if (strEQ(name, "PvmHostDelete"))         return PvmHostDelete;
  if (strEQ(name, "PvmHostFail"))           return PvmHostFail;
  if (strEQ(name, "PvmMismatch"))           return PvmMismatch;
  if (strEQ(name, "PvmMppFront"))           return PvmMppFront;
  if (strEQ(name, "PvmNoBuf"))              return PvmNoBuf;
  if (strEQ(name, "PvmNoData"))             return PvmNoData;
  if (strEQ(name, "PvmNoEntry"))            return PvmNoEntry;
  if (strEQ(name, "PvmNoFile"))             return PvmNoFile;
  if (strEQ(name, "PvmNoGroup"))            return PvmNoGroup;
  if (strEQ(name, "PvmNoHost"))             return PvmNoHost;
  if (strEQ(name, "PvmNoInst"))             return PvmNoInst;
  if (strEQ(name, "PvmNoMem"))              return PvmNoMem;
  if (strEQ(name, "PvmNoParent"))           return PvmNoParent;
  if (strEQ(name, "PvmNoSuchBuf"))          return PvmNoSuchBuf;
  if (strEQ(name, "PvmNoTask"))             return PvmNoTask;
  if (strEQ(name, "PvmNotImpl"))            return PvmNotImpl;
  if (strEQ(name, "PvmNotInGroup"))         return PvmNotInGroup;
  if (strEQ(name, "PvmNullGroup"))          return PvmNullGroup;
  if (strEQ(name, "PvmOk"))                 return PvmOk;
  if (strEQ(name, "PvmOutOfRes"))           return PvmOutOfRes;
  if (strEQ(name, "PvmOutputCode"))         return PvmOutputCode;
  if (strEQ(name, "PvmOutputTid"))          return PvmOutputTid;
  if (strEQ(name, "PvmOverflow"))           return PvmOverflow;
  if (strEQ(name, "PvmPollConstant"))       return PvmPollConstant;
  if (strEQ(name, "PvmPollSleep"))          return PvmPollSleep;
  if (strEQ(name, "PvmPollTime"))           return PvmPollTime;
  if (strEQ(name, "PvmPollType"))           return PvmPollType;
  if (strEQ(name, "PvmResvTids"))           return PvmResvTids;
  if (strEQ(name, "PvmRoute"))              return PvmRoute;
  if (strEQ(name, "PvmRouteDirect"))        return PvmRouteDirect;
  if (strEQ(name, "PvmSelfOutputCode"))     return PvmSelfOutputCode;
  if (strEQ(name, "PvmSelfOutputTid"))      return PvmSelfOutputTid;
  if (strEQ(name, "PvmSelfTraceCode"))      return PvmSelfTraceCode;
  if (strEQ(name, "PvmSelfTraceTid"))       return PvmSelfTraceTid;
  if (strEQ(name, "PvmShowTids"))           return PvmShowTids;
  if (strEQ(name, "PvmSysErr"))             return PvmSysErr;
  if (strEQ(name, "PvmTaskArch"))           return PvmTaskArch;
  if (strEQ(name, "PvmTaskChild"))          return PvmTaskChild;
  if (strEQ(name, "PvmTaskDebug"))          return PvmTaskDebug;
  if (strEQ(name, "PvmTaskDefault"))        return PvmTaskDefault;
  if (strEQ(name, "PvmTaskExit"))           return PvmTaskExit;
  if (strEQ(name, "PvmTaskHost"))           return PvmTaskHost;
  if (strEQ(name, "PvmTaskSelf"))           return PvmTaskSelf;
  if (strEQ(name, "PvmTaskTrace"))          return PvmTaskTrace;
  if (strEQ(name, "PvmTraceCode"))          return PvmTraceCode;
  if (strEQ(name, "PvmTraceTid"))           return PvmTraceTid;
  if (strEQ(name, "PvmMboxDefault"))        return PvmMboxDefault;
  if (strEQ(name, "PvmMboxPersistent"))     return PvmMboxPersistent;
  if (strEQ(name, "PvmMboxMultiInstance"))  return PvmMboxMultiInstance;
  if (strEQ(name, "PvmMboxOverWritable"))   return PvmMboxOverWritable;
  if (strEQ(name, "PvmMboxFirstAvail"))     return PvmMboxFirstAvail;
  if (strEQ(name, "PvmMboxReadAndDelete"))  return PvmMboxReadAndDelete;
  
  errno = EINVAL;
  return 0;

 not_there:
  errno = ENOENT;
  return 0;
}


MODULE = Parallel::Pvm		PACKAGE = Parallel::Pvm		

double
constant(name,arg)
	char *		name
	int		arg

PROTOTYPES: ENABLE

void
spawn(task,ntask,flag=PvmTaskDefault,where="",argvRef=0)
  char *  task
  int     ntask
  int     flag
  char *  where
  SV *    argvRef
  PREINIT:
  int tids[MAXPROCS];
  int info;
  int i;
  char ** argv = (char **)0;
  PPCODE:
 
  if (argvRef)
  {
    int   argc;
    AV *  av;
    SV ** a;
 
    if (!SvROK(argvRef))
      croak("Parallel::Pvm::spawn - non-reference passed for argv");
 
    av = (AV *) SvRV( argvRef );
    argc = av_len( av ) + 1;        /* number of elts in vector */
    Newz( 0, argv, argc+1, char *); /* last one will be NULL */
 
    for (i = 0; i < argc; i++)
    {
      if ( a = av_fetch( av, i, 0) )
        argv[i] = (char *) SvPV( *a, PL_na );
    }
  }
 
  info = pvm_spawn(task,argv,flag,where,ntask,tids);
 
  Safefree( argv ); /* no harm done if argv is NULL */
 
  XPUSHs(sv_2mortal(newSViv(info)));
  for (i=0;i<info;i++)
  {
    XPUSHs(sv_2mortal(newSViv(tids[i])));
  }

MODULE = Parallel::Pvm		PACKAGE = Parallel::Pvm		PREFIX=pvm_

int
start_pvmd(block=0,...)
  int block;
  PROTOTYPE: ;$@
  PREINIT:
  int i;
  char *argv[MAXARGS];
  CODE:
  if ( items > 1 ) 
  {
    if ( items > MAXARGS )
      croak("Warning: too many arguments.  Try increasing MAXARGS");
    for(i=1;i<items;i++)
      argv[i-1] = (char *)SvPV(ST(i), PL_na); 
    RETVAL = pvm_start_pvmd(items - 1, argv, block);
  } 
  else 
  {
    RETVAL = pvm_start_pvmd(0, NULL, block);
  }
  OUTPUT:
  RETVAL
 
int
pvm_initsend(flag=PvmDataDefault)
  int flag;

int
pvm_send(tid,tag)
  int tid
  int tag

int
psend(tid,tag,...)
  int   tid
  int  tag
  PREINIT:
  int i;
  char *str, *po;
  char *buf, *in;
  STRLEN buflen = 0;
  CODE:
  if ( items <= 2 )
     croak("Usage: Parallel::Pvm::psend(@argv)");
  for(i=2;i<items;i++)
  {
    STRLEN len;
    po = (char *)SvPV(ST(i), len);
    buflen += len + 1;
  }
  New(2401, buf, buflen, char);
  in = buf;
  for(i=2;i<items;i++)
  {
    STRLEN len; int j;
    po = (char *)SvPV(ST(i), len);
    for (j=0;j<len;j++) 
      *(in++) = *(po++);
    *(in++) = '\v';
  }
  *(--in) = '\0';               /* we are sure that items > 2 and
                                   therefore in > buf */
  RETVAL = pvm_psend(tid,tag,buf,buflen,PVM_BYTE);
  Safefree(buf);
  OUTPUT:
  RETVAL


int
mcast(...)
  PREINIT:
  int i;
  int tag_num;
  int proc_num;
  int tids[MAXPROCS];
  int tag;
  CODE:
  if ( items < 2 )
    croak("Usage: Parallel::Pvm::pvm_mcast(tids_list,tag)");
  for (i=0;i<items-1;i++)
  {
    tids[i] = SvIV(ST(i));
  }
  proc_num = tag_num = items-1;
  tag = SvIV(ST(tag_num));
  RETVAL = pvm_mcast(tids,proc_num,tag);
  OUTPUT:
  RETVAL


int
pvm_sendsig(tid,sig)
  int	tid
  int	sig

int
pvm_probe(tid=-1,tag=-1)
  int	tid
  int	tag

int
pvm_recv(tid=-1,tag=-1)
  int	tid
  int	tag

int
pvm_nrecv(tid=-1,tag=-1)
  int	tid
  int	tag

int
trecv(tid=-1,tag=-1,sec=1,usec=0)
  int  tid
  int  tag
  int  sec
  int  usec
  PREINIT:
  struct timeval tmout;
  CODE:
  tmout.tv_sec = sec;
  tmout.tv_usec = usec;
  RETVAL = pvm_trecv(tid,tag,&tmout);
  OUTPUT:
  RETVAL
  
  
void
precv(tid=-1,tag=-1,buflen=MAXSTR)
  int   tid
  int   tag
  int   buflen
  PREINIT:
  int info, src, stag, scnt;
  char *buf;
  char *po;
  int type;
  PPCODE:
  New(2401, buf, buflen, char);

  info = pvm_precv(tid,tag,buf,buflen,PVM_BYTE,&src,&stag,&scnt);
  XPUSHs(sv_2mortal(newSViv(info)));
  XPUSHs(sv_2mortal(newSViv(src)));
  XPUSHs(sv_2mortal(newSViv(stag)));
  po = strtok(buf,"\v");
  while ( po != NULL )
  {
	/* Change: Everything is a string 
     * sn@neopoly.com Fri Feb  9 13:41:46 CET 2001 */
    XPUSHs(sv_2mortal(newSVpv(po,0)));
    po = strtok(NULL,"\v");
  }
  Safefree(buf);


int
pvm_parent()

int
pvm_mytid()

int
pack(...)
  PREINIT:
  int i;
  char *str, *po;
  char *buf, *in;
  STRLEN buflen = 0;

  CODE:
  if ( items <= 0 )
    croak("Usage: Parallel::Pvm::pack(@argv)");

  for(i=0;i<items;i++)
  {
    STRLEN len;
    po = (char *)SvPV(ST(i), len);
    buflen += len + 1;
  }
  New(2401, buf, buflen, char);
  in = buf;

  for(i=0;i<items;i++)
  {
    STRLEN len; int j;
    po = (char *)SvPV(ST(i), len);
    for (j=0;j<len;j++) 
      *(in++) = *(po++);
    *(in++) = '\v';
  }
  *(--in) = '\0';               /* we are sure that items > 0 and
                                   therefore in > buf */
  RETVAL = pvm_pkstr(buf); 
  Safefree(buf);
  OUTPUT:
  RETVAL


void
unpack(buflen=MAXSTR)
  int   buflen
  PREINIT:
  char *buf, *po;
  int type;
  PPCODE:
  New(2401, buf, buflen, char);
  if (pvm_upkstr(buf) != 0) {
    if (PL_dowarn) {
      warn("pvm_upkstr failed");
      Safefree(buf);
      XSRETURN_UNDEF;
    }
  }
  po = strtok(buf,"\v");
  while ( po != NULL )
  {
	/* Change: Everything is a string 
     * sn@neopoly.com Fri Feb  9 13:41:46 CET 2001 */
    XPUSHs(sv_2mortal(newSVpv(po,0)));
    po = strtok(NULL,"\v");
  }
  Safefree(buf);

int
pvm_exit()

int
pvm_halt()

int
pvm_catchout(io=stdout)
  FILE *	io

void
tasks(where=0)
  int  where
  PREINIT:
  int ntask,i,info;
  struct pvmtaskinfo *taskp;
  int ti_tid,ti_ptid,ti_host,ti_flag,ti_pid;
  char ti_a_out[256];
  HV *hv_tmp;
  PPCODE:
  info = pvm_tasks(where,&ntask,&taskp);
  XPUSHs(sv_2mortal(newSViv(info)));
  if (info >= 0) /* ntask may be undefined if there was an error */
    for(i=0;i<ntask;i++)
    {
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
      XPUSHs(sv_2mortal(newRV_noinc((SV *)hv_tmp)));
    }


void
config()
  PREINIT:
  int nhosts, narch, info;
  struct pvmhostinfo *hostp;
  char hi_name[256], hi_arch[256];
  int hi_tid, hi_speed;
  int i;
  HV *hv_tmp;
  PPCODE:
  info = pvm_config(&nhosts,&narch,&hostp);
  if (info == PvmOk)
    XPUSHs(sv_2mortal(newSViv(info)));
  else
    XPUSHs(sv_2mortal(newSViv(nhosts)));
  for (i=0;i<nhosts;i++)
  {
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
    XPUSHs(sv_2mortal(newRV_noinc((SV *)hv_tmp)));
  }


void
addhosts(...)
  PREINIT:
  int i;
  int info;
  char *po;
  char *hosts[MAXHOSTS]; 
  int infos[MAXHOSTS];
  PPCODE:
  if ( items < 1 )
    croak("Usage: Parallel::Pvm::pvm_addhosts(host_list)");
  for (i=0;i<items;i++)
  {
    hosts[i] = (char *)SvPV(ST(i), PL_na);
  }
  info = pvm_addhosts(hosts,items,infos);
  XPUSHs(sv_2mortal(newSViv(info)));  
  for (i=0;i<items;i++)
  {
    XPUSHs(sv_2mortal(newSViv(infos[i])));
  }


void
delhosts(...)
  PREINIT:
  char *po;
  char *hosts[MAXHOSTS]; 
  int infos[MAXHOSTS];
  int info, i, nhost;
  PPCODE:
  if ( items < 1 )
    croak("Usage: Parallel::Pvm::pvm_delhosts(host_list)");
  for (i=0;i<items;i++)
  {
    hosts[i] = (char *)SvPV(ST(i), PL_na);
  }
  info = pvm_delhosts(hosts,items,infos);
  XPUSHs(sv_2mortal(newSViv(info)));  
  for (i=0;i<items;i++)
  {
    XPUSHs(sv_2mortal(newSViv(infos[i])));
  }

void
bufinfo(bufid)
  int  bufid
  PREINIT:
  int bytes, tag, tid, info;
  PPCODE:
  if (info = pvm_bufinfo(bufid,&bytes,&tag,&tid)) {
    if (PL_dowarn) {
      warn("pvm_bufinfo failed");
      XSRETURN_EMPTY;
    }
  }
  XPUSHs(sv_2mortal(newSViv(info)));
  XPUSHs(sv_2mortal(newSViv(bytes)));
  XPUSHs(sv_2mortal(newSViv(tag)));
  XPUSHs(sv_2mortal(newSViv(tid)));

  
int
pvm_freebuf(bufid)
  int	bufid

int
pvm_getrbuf()

int
pvm_getsbuf()

int
pvm_mkbuf(encode=PvmDataDefault)
  int	encode

int
pvm_setrbuf(bufid)
  int   bufid

int
pvm_setsbuf(bufid)
  int	bufid

int
pvm_kill(tid)
  int	tid

int
pvm_mstat(host)
  char *	host

int
pvm_pstat(tid)
  int	tid

int
pvm_tidtohost(tid)
  int	tid

int
pvm_getopt(what)
  int	what

int
pvm_setopt(what,val)
  int	what
  int	val

int
pvm_reg_hoster()

int
pvm_reg_tasker()

int
pvm_reg_rm()
  PREINIT:
  struct pvmhostinfo *hip;
  CODE:
  RETVAL = pvm_reg_rm(&hip);
  OUTPUT:
  RETVAL

int
pvm_perror(msg)
  char *	msg

int
notify(what,tag,...)
  int     what
  int     tag
  PREINIT:
  int i, cnt, tids[MAXPROCS];
  CODE:
  switch(what){
    case PvmTaskExit:
    case PvmHostDelete:
      if ( items < 3 )
        croak("Usage: Parallel::Pvm::pvm_notify(what,tag,tid_list");
      for (i=2;i<items;i++)
      {
        tids[i-2] = SvIV(ST(i));
      }
      RETVAL = pvm_notify(what,tag,items-2,tids);
      break;
    case PvmHostAdd:
      if ( items < 2 )
        croak("Usage:  Parallel::Pvm::pvm_notify(PvmHostAdd,tag [,cnt]");
      if (2 == items )
        cnt = -1;
      else
        cnt = SvIV(ST(2));
      RETVAL = pvm_notify(what,tag, cnt, (int *)0 );
    break;
  }
  OUTPUT:
  RETVAL


int
recv_notify(what)
  int what
  PREINIT:
  int id,i,cnt;
  int tids[MAXPROCS];
  PPCODE:
  pvm_recv(-1,-1);
  switch (what )
  {
    case PvmTaskExit:
    case PvmHostDelete:
      pvm_upkint(&id,1,1);
      XPUSHs( sv_2mortal(newSViv(id)) );
      break;
    case PvmHostAdd:
      pvm_upkint( &cnt, 1, 1 );
      pvm_upkint( tids, cnt, 1 );
    for ( i=0; i < cnt; i++)
      XPUSHs(sv_2mortal(newSViv(tids[i])));
  }


void
hostsync(hst)
  int	hst
  PREINIT:
  struct timeval rclk, delta;
  int info;
  int sec, usec;
  HV *hv_tmp;
  PPCODE:
  info = pvm_hostsync(hst,&rclk,&delta);
  XPUSHs(sv_2mortal(newSViv(info)));
  sec = rclk.tv_sec;
  usec = rclk.tv_usec;
  /* set up hash entry */
  hv_tmp = newHV();
  hv_store(hv_tmp,"tv_sec",6,newSViv(sec),0);
  hv_store(hv_tmp,"hi_usec",7,newSViv(usec),0);
  /* create reference and stick in on the stack */
  XPUSHs(sv_2mortal(newRV_noinc((SV *)hv_tmp)));
  sec = delta.tv_sec;
  usec = delta.tv_usec;
  /* set up hash entry */
  hv_tmp = newHV();
  hv_store(hv_tmp,"tv_sec",6,newSViv(sec),0);
  hv_store(hv_tmp,"hi_usec",7,newSViv(usec),0);
  /* create reference and stick in on the stack */
  XPUSHs(sv_2mortal(newRV_noinc((SV *)hv_tmp)));


void
recvf(fn)
  SV *	fn
  CODE:
  if ( recvf_callback == (SV *)NULL )
  {
    recvf_callback = newSVsv(fn);
  }
  else
  {
    sv_setsv(recvf_callback,fn);
  }
  olmatch = pvm_recvf(recvf_foo);


void
recvf_old()
  CODE:
  if ( olmatch !=  NULL )
  {
    pvm_recvf(olmatch);
  }

int
pvm_joingroup(group)
     char *	group

int
pvm_lvgroup(group)
     char *	group

int
pvm_bcast(group, msgtag)
     char *	group
     int	msgtag

int
pvm_freezegroup(group, size=-1)
     char *	group
     int	size

int
pvm_barrier(group, count)
     char *	group
     int	count

int
pvm_getinst(group, tid)
     char *	group
     int	tid

int
pvm_gettid(group, inum)
     char *	group
     int	inum

int
pvm_gsize(group)
     char *	group

void
endtask()
     PROTOTYPE:
     CODE:
     pvmendtask();

void
siblings()
	PREINIT:
	int *tids;
	int ntids;
	int n;
	PPCODE:
	ntids = pvm_siblings(&tids);
	XPUSHs(sv_2mortal(newSViv(ntids)));
	for (n = 0; n < ntids; n++)
		{
		XPUSHs(sv_2mortal(newSViv(tids[n])));
		}

int
getcontext()
	CODE:
	RETVAL = pvm_getcontext();
	OUTPUT:
	RETVAL

int
newcontext()
	CODE:
	RETVAL = pvm_newcontext();
	OUTPUT:
	RETVAL

int
setcontext(context)
	int context
	CODE:
	RETVAL = pvm_setcontext(context);
	OUTPUT:
	RETVAL

int
freecontext(context)
	int context
	CODE:
	RETVAL = pvm_freecontext(context);
	OUTPUT:
	RETVAL

int
putinfo(name,bufid,flags=PvmMboxDefault)
	char * name;
	int bufid;
	int flags;
	CODE:
	RETVAL = pvm_putinfo(name,bufid,flags);
	OUTPUT:
	RETVAL

int
recvinfo(name,index=0,flags=PvmMboxDefault)
	char * name;
	int index;
	int flags;
	CODE:
	RETVAL = pvm_recvinfo(name,index,flags);
	OUTPUT:
	RETVAL

int
delinfo(name,index=0)
	char * name;
	int index;
	CODE:
	RETVAL = pvm_delinfo(name,index,0);	/*flags always 0, because according to manpages there are not flags specified */
	OUTPUT:
	RETVAL

void
getmboxinfo(pattern,nclasses=100)
	char * pattern;
	int nclasses;
	PREINIT:
	int n,m;
	
	int info;
	struct pvmmboxinfo *classes;
	
	char mi_name[256];

	HV * hv_tmp;
	AV * arr_tmp;
	PPCODE:
	info = pvm_getmboxinfo(pattern,&nclasses,&classes);
	if (info == PvmOk)
		XPUSHs(newSViv(nclasses));
	else
		XPUSHs(newSViv(info));
	for (n=0;n<nclasses;n++)
		{
		strcpy(mi_name,classes[n].mi_name);
		hv_tmp = (HV *)sv_2mortal((SV *)newHV());
		
		hv_store(hv_tmp,"mi_name",7,newSVpv(mi_name,0),0);
		
		hv_store(hv_tmp,"mi_nentries",11,newSViv(classes[n].mi_nentries),0);
		
		arr_tmp = (AV *)sv_2mortal((SV *)newAV());
		for (m=0;m<classes[n].mi_nentries;m++)
			{
			av_push(arr_tmp,newSViv(classes[n].mi_indices[m]));
			}
		hv_store(hv_tmp,"mi_indices",10,newRV((SV *)arr_tmp),0);
		
		arr_tmp = (AV *)sv_2mortal((SV *)newAV());
		for (m=0;m<classes[n].mi_nentries;m++)
			{
			av_push(arr_tmp,newSViv(classes[n].mi_owners[m]));
			}
		hv_store(hv_tmp,"mi_owners",9,  newRV((SV *)arr_tmp),0);
		
		arr_tmp = (AV *)sv_2mortal((SV *)newAV());
		for (m=0;m<classes[n].mi_nentries;m++)
			{
			av_push(arr_tmp,newSViv(classes[n].mi_flags[m]));
			}
		hv_store(hv_tmp,"mi_flags",8,   newRV((SV *)arr_tmp),0);
		
		XPUSHs(newRV((SV *)hv_tmp));
		}
