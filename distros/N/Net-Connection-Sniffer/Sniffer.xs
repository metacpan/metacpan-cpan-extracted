
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/*
#include <time.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <netinet/ether.h>
#include <netinet/ip.h>
#include <string.h>
#include <ctype.h>

#include <pcap.h>
*/
#include "defaults.h"

#ifndef NV
#define NV double
#endif

#ifndef newSVuv
SV*
newSVuv(U32 in)
{ 
  SV* out = newSViv(in);
  sv_setuv(out,in);
  return out;
}
#endif

#define minlen	ETH_HLEN + IP_HLEN + 4		/* need src/dst ports in packet for filtering	*/

const int nxtrateupd = 60, nxtupd = 300, oneday = 86400, onehour = 3600;

SV	** vpp;
AV	* dnsrequest;
HV	* stats;
double	rate, bw, ba;
u_int32_t	ra, now, next, start, nextp;
int * udp_tcp_hdr;

union buffer
{
	unsigned char e[PCAP_ERRBUF_SIZE+1];
	unsigned char s[512];
} out;

union naddr
{
	unsigned char	s[4];
	u_int32_t	host;
	struct in_addr	naddr;
} me, trgt;

/*	'dumptofile' is the flag indicating that this is/is not a dump to file/STDERR
	'signal_dump' is the flag indicating a dump was initiated by a signal
 */
int	dumptofile, signal_dump = 0, nleft, dnsRflag = 0, socklen = sizeof(struct sockaddr);
int	maxfd, max, run, hup, nfound, dump_head, nextrate;
int	dnsFD, lFD, wFD, pFD, dnsFDm = 0, lFDm = 0, wFDm = 0, pFDm = 0;
int	payoff = 0, pktlen = minlen;
size_t	paysize;

FILE	* WFD;

char	filepath[512], tmp[512], pbuf[512], * bptr;
u_char	haystack[65536];	/*	payload buffer	*/

union sock
{
struct sockaddr_in si;
struct sockaddr sa;
};

union sock listner, sender, dnsaddr;

pcap_t  * pcap;
bpf_u_int32 netp, maskp;

fd_set	rset, wset;

struct timeval tloop;

struct sigaction sa;
sigset_t set;

unsigned char * match = NULL, * nomatch = NULL;

void
debug_packet(unsigned char * str, int len)
{
  int i, c, d = 0, hex = 1;	/*	set hex = 1, alpha = 0	*/
  for (i=0;i<len;i++) {
    c = (int)*(str +i);
    if (hex != 0)
      fprintf(stderr,"%02X",c);
    else {
      if (isgraph(c) == 0)
        c = (int)('.');
      fprintf(stderr,"%c",(u_char)c);
    }
    d++;
    if (d >= 8) {	/*	set character segmentation here	*/
      d = 0;
      fprintf(stderr," ");
    }
  }
  fprintf(stderr,"\n");
}

int
dumpmore()
{
  int nwritten;

  if (nleft < 1)
    return 0;
  nwritten = write(wFD,bptr,nleft);
  if (nwritten <= 0) {
    if (errno == EINTR || errno == EWOULDBLOCK)
      nwritten = 0;
    else
      return 0;		/*	force flush if fatal error	*/
  }
  bptr += nwritten;
  nleft -= nwritten;
  if (nleft < 0)
    nleft = 0;
  return nleft;
}
   
int
my_dump(char * buf, int len)
{
  if (len < 1)
    return 0;
  strncpy(pbuf,buf,len);
  bptr 	= pbuf;
  nleft	= len;
  return dumpmore();
}

void
closeMOST()
{
  if (dnsFD != 0)
    close(dnsFD);
  if (lFD != 0)
    close(lFD);
  pcap_breakloop(pcap);
  dnsFD	= 0;
  lFD	= 0;
  pFD	= 0;
  maxfd	= 0;
}

void
q_handler (int sig)
{
  switch (sig) {
	case SIGUSR1	:
		if (hup != 0)
		  break;
		if (wFD == 0)
		  signal_dump = 1;	/*	ignore dump in process	*/
		break;
	case SIGHUP	:
		if (hup == 0);
		  hup	= 1;
		if (wFD == 0)
		  signal_dump = 1;	/*	ignore dump in process	*/
		break;
	case SIGINT	:
	case SIGQUIT	:
	case SIGTERM	: 
		hup	= -1;
		closeMOST();
		if (dumptofile) {
		  if (wFD == 0)
		    signal_dump = 1;
		}
		else
		  run = 0;
		break;
  }
}

void
set_signals (void)
{
  sa.sa_handler = q_handler;
  sigemptyset (&sa.sa_mask);
  sigaddset (&sa.sa_mask, SIGTERM);
  sigaddset (&sa.sa_mask, SIGHUP);
  sigaddset (&sa.sa_mask, SIGUSR1);
  sigaddset (&sa.sa_mask, SIGQUIT);
  sigaddset (&sa.sa_mask, SIGINT);
/*  sa.sa_flags = SA_RESTART;
*/
  sa.sa_flags = 0;
  sigaction (SIGINT, &sa, NULL);
  sigaction (SIGQUIT, &sa, NULL);
  sigaction (SIGUSR1, &sa, NULL);
  sigaction (SIGTERM, &sa, NULL);
  sigaction (SIGHUP, &sa, NULL);
}


u_int32_t
fetch_uv(HV * hp, char * key)
{
  u_int32_t val;
/*	perl likes to store ints as NV's so
	to preserve space we convert to UV's
 */
  vpp = hv_fetch(hp,key,1,0);
  if (SvIOK(*vpp))
    return SvUVX(*vpp);
  val = SvUV(*vpp);
  sv_setuv(*vpp,val);
  return val;
}

void
set_uv(HV * hp, char * key, u_int32_t val)
{
  vpp = hv_fetch(hp,key,1,1);
  sv_setuv(*vpp, val);
}

void
inc_sv(HV * hp, char * key)
{
  vpp = hv_fetch(hp,key,1,0);
  sv_inc(*vpp);
}

void
set_nv(HV * hp, char * key, double val)
{
  vpp = hv_fetch(hp,key,1,1);
  sv_setnv(*vpp, val);
}

void
add_nv(HV * hp, char * key, u_int32_t val)
{
  vpp = hv_fetch(hp,key,1,0);
  sv_setnv(*vpp, SvNVX(*vpp) + val);
}

/*	NV = (NV + UV) * NV	*/
void
aEQaPLUSbXm(HV * hp, char * key1, char * key2, double multiply)
{
  double tmpb;

  vpp = hv_fetch(hp,key2,1,0);
  if (key2[0] == 'B')
    tmpb = (double)SvNVX(*vpp);
  else if (SvIOK(*vpp))
    tmpb = SvUVX(*vpp);
  else
    tmpb = SvUV(*vpp);
  vpp = hv_fetch(hp,key1,1,0);
  sv_setnv(*vpp,((SvNVX(*vpp) + tmpb) * multiply));
}

void
init_hv(HV * dusr, int32_t len)
{
  hv_store(dusr,"B",1,newSVnv(len),0);
  hv_store(dusr,"C",1,newSVuv(1),0);
  hv_store(dusr,"E",1,newSVuv(now),0);
  hv_store(dusr,"N",1,newRV_noinc((SV *)newAV()),0);
  hv_store(dusr,"R",1,newSVnv(0),0);
  hv_store(dusr,"S",1,newSVuv(start),0);
  hv_store(dusr,"T",1,newSVuv(0),0);
  hv_store(dusr,"W",1,newSVnv(0),0);
}

void
sniffit(u_char *user, const struct pcap_pkthdr *h, const u_char *bytes)
{
  SV	** vpp;
  HV	* dusr;
  AV	* hn;			/* hostnames	*/
  double	multiplier, tmpd;
  u_int32_t	e, s;
  int32_t	len	= h->len;
  u_char * pcaptr, * hay, * hayend;

  union naddr	ip_src, ip_dst;
  struct ether_header  * eth	= (struct ether_header *)bytes;
  struct iphdr * iph		= (struct iphdr *)(bytes + ETH_HLEN);
  udp_tcp_hdr			= (int *)(bytes + ETH_HLEN + IP_HLEN);

  if (	(iph->ihl*4 != IP_HLEN) ||		/* drop non-standard packets	*/
	(iph->frag_off & htons(IP_OFFMASK)) ||	/* drop fragments		*/
	(len < pktlen)	)			/* minimum packet len = minlen || snaplen	*/
    return;

  if (match != NULL || nomatch != NULL) {
    pcaptr = (u_char *)(bytes + payoff);
    hay = haystack;
    hayend = hay + paysize;
    while (hay < hayend) {
      *hay = (u_char) tolower((int) *pcaptr);
      hay++;
      pcaptr++;
    }
    *hayend = '\0';	/*	make sure there is a terminating null at end of char string	*/

/*	drop if match needed and not found	*/

    if (match != NULL && strstr((char *)haystack,(char *)match) == NULL) {
      return;
    }
/*	drop if no match needed and found	*/
    if (nomatch != NULL && strstr((char *)haystack,(char *)match) != NULL) {
      return;
    }
  }

  ip_src.host	= iph->saddr;
  ip_dst.host	= iph->daddr;

  if (me.host == ip_src.host)
    trgt.host	= ip_dst.host;
  else
    trgt.host	= ip_src.host;

/*	do global averaging first	*/
  if (next > now || (rate < 1 && ra < 5)) {
    ba += len;
    ra++;
  } else {
/* force compilier to boost to doubles for now, onehour	*/
    multiplier = onehour;
    tmpd = now;
    if (rate < 1) {
/*	tmpd = now - start		*/
      tmpd -= start;
      if (tmpd < 1)
	tmpd = 1;
    } else {
/*	tmpd = onehour + now + nextrate - next	---	where next was (now + nextrate) so it really is (now - old)	*/
      tmpd = multiplier + tmpd + nextrate - next;		/* first interval was 5 minutes	*/
    }
/*	multiplier = onehour / tmpd	*/
    multiplier /= tmpd;
    rate	= (rate + ra) * multiplier;
    bw		= (bw + ba) * multiplier;
    ba		= len;
    ra		= 1;
    next	= now + nxtrateupd;
    nextrate	= nxtrateupd;
  }

/*	collect user stats		*/
  if (hv_exists(stats,(char *)trgt.s,4)) {
    vpp		= hv_fetch(stats,(char *)trgt.s,4,0);
    dusr	= (HV *)SvRV(*vpp);

    if ((e = fetch_uv(dusr,"E")) + nxtupd > now ||
	(e == fetch_uv(dusr,"S") && fetch_uv(dusr,"C") < 5)) {
      add_nv(dusr,"B", len);
      inc_sv(dusr,"C");
    } else {
/* force compilier to boost to doubles for now, onehour	*/
      multiplier = onehour;
      tmpd = now;
      if ((s = fetch_uv(dusr,"S")) == e) {
/*	tmpd = now - start		*/
	tmpd -= s;
      } else {
/*	tmpd = onehour + now - old	*/
	tmpd = multiplier + now - e;
      }
      multiplier /= tmpd;
      aEQaPLUSbXm(dusr,"R","C",multiplier);
      aEQaPLUSbXm(dusr,"W","B",multiplier);
      set_uv(dusr,"E",now);
      set_nv(dusr,"B",(double)len);
      set_uv(dusr,"C",1);
    }
  } else {
    dusr	= newHV();
    init_hv(dusr,len);
    hv_store(stats,(char *)trgt.s,4,newRV_noinc((SV *)dusr),0);
  }
  if ((fetch_uv(dusr,"T")) < now) {
    dnsRflag = 1;
    av_push(dnsrequest,newSVpv((char *)trgt.s,4));
  }
}

MODULE = Net::Connection::Sniffer	PACKAGE = Net::Connection::Sniffer

PROTOTYPES: DISABLE

 # run, now, next, start 		I32
 # rate, bw				NV

 #	SVt_NULL,       /* 0 */
 #	SVt_IV,         /* 1 */
 #	SVt_NV,         /* 2 */
 #	SVt_RV,         /* 3 */
 #	SVt_PV,         /* 4 */
 #	SVt_PVIV,       /* 5 */
 #	SVt_PVNV,       /* 6 */
 #	SVt_PVMG,       /* 7 */
 #	SVt_PVBM,       /* 8 */
 #	SVt_PVLV,       /* 9 */
 #	SVt_PVAV,       /* 10 */
 #	SVt_PVHV,       /* 11 */
 #	SVt_PVCV,       /* 12 */
 #	SVt_PVGV,       /* 13 */
 #	SVt_PVFM,       /* 14 */
 #	SVt_PVIO        /* 15 */

void
p2xs_gvars(pnow, pstart, prate, pbw)
	SV	* pnow
	SV	* pstart
	SV	* prate
	SV	* pbw
  INIT:
	if (items != 4)
	  croak("Usage: Net::Connection::Sniffer::p2xs_gvars(pnow, pstart, prate, pbw)");

  CODE:
	now	= SvUV(pnow);
	nextp	= now;
	nextrate= 300;
	next	= now + nextrate;	/*	first increment is 5 minutes, following are different	*/
	start	= SvUV(pstart);
	rate	= SvNV(prate);
	bw	= SvNV(pbw);
	hup	= 0;
	ra	= 0;
	ba	= 0;

PROTOTYPES: ENABLE

void
xs2p_gvars()
  PPCODE:
	EXTEND(SP,4);
	PUSHs(sv_2mortal(newSVuv(now)));
	PUSHs(sv_2mortal(newSVuv(start)));
	PUSHs(sv_2mortal(newSVnv(rate)));
	PUSHs(sv_2mortal(newSVnv(bw)));
	XSRETURN(4);

void
xs_daemon_init(sniffer,hpref,dnsref,nhost,dnshost,port,listenon,bpfstr,dev,snaplen,promisc,to)
	SV	* sniffer
	SV	* hpref
	SV	* dnsref
	SV	* nhost
	SV	* dnshost
	int	port
	SV	* listenon
	char	* bpfstr
	char	* dev
	int	snaplen
	int	promisc
	int	to
    PREINIT:
	unsigned char * ip, * lip, * sniffp;
	STRLEN	len;
	char	errorbuf[PCAP_ERRBUF_SIZE+1];
	struct bpf_program real_fp;
    CODE:
	pktlen = snaplen;
	if (SvPOK(sniffer) == 0)
	  croak("sniffer is not a 'path' or 'STDERR'");

	if (! SvROK(hpref))
	  croak("stats is not a REF");
	if (SvTYPE(SvRV(hpref)) != SVt_PVHV)
	  croak("stats is not a hash REF");

	if (! SvROK(dnsref))
	  croak("dnslookup is not REF");
	if (SvTYPE(SvRV(dnsref)) != SVt_PVAV)
	  croak("dnslookup is not an array REF");

	if (SvPOK(nhost) == 0)
	  croak("nhost is not a netaddr");
	ip = (u_char *)SvPV(nhost,len);
	if (len != 4)
	  croak("nhost length of netaddr length is %d, should be 4", len);
	strncpy((char *)me.s,(char *)ip,4);

	if (SvPOK(dnshost) == 0)
	  croak("dnshost is not a netaddr");
	ip = (u_char *)SvPV(dnshost,len);
	if (len != 4)
	  croak("dnshost length of netaddr length is %d, should be 4", len);
	bzero(&dnsaddr.sa,socklen);
	dnsaddr.si.sin_family = PF_INET;
	dnsaddr.si.sin_addr.s_addr = *((unsigned long *)ip);
	dnsaddr.si.sin_port = htons(53);

	if ((dnsFD = socket(PF_INET,SOCK_DGRAM,0)) < 0)
	  croak("could not open name server socket");

	if(port != 0) {
	  if (SvPOK(listenon) == 0)
	    croak("listen is not a netaddr");
	  lip = (u_char *)SvPV(listenon,len);
	  if (len != 4)
	    croak("listen netaddr length is %d, should be 4", len);

	  if ((lFD = socket(PF_INET,SOCK_DGRAM,0)) < 0)
	    croak("could not open 'listen on' socket");
	  fcntl(lFD, F_SETFL, O_NONBLOCK);

	  bzero(&listner.sa,socklen);
	  listner.si.sin_family = PF_INET;
	  listner.si.sin_addr.s_addr = *((unsigned long *)lip);
	  listner.si.sin_port = htons(port);
	  if (bind(lFD,&listner.sa,socklen) < 0)
	    croak("could not bind 'listen on' to port %d",port);
	}

	sniffp = (u_char *)SvPV(sniffer,len);
	if (strncmp("STDERR",(char *)sniffp,6) == 0) {
	  fcntl(fileno(stderr), F_SETFL, O_NONBLOCK);
	  dumptofile = 0;
	  WFD = stderr;
	} else {
	  dumptofile = 1;
	  strncpy(filepath,(char *)sniffp,len +1);
	  strncpy(tmp,(char *)sniffp,len);
	  strcpy((tmp + len),".tmp");
	}
	wFD = 0;

	if ((pcap = pcap_open_live(dev,snaplen,promisc,to,errorbuf)) == NULL)
	  croak("error: %s",errorbuf);
	if (pcap_lookupnet(dev,&netp,&maskp,errorbuf) < 0)
	  croak("error: %s",errorbuf);
	if (pcap_compile(pcap,&real_fp,bpfstr,1,maskp) < 0)
	  croak("error: %s", pcap_geterr(pcap));
	if (pcap_setfilter(pcap,&real_fp) < 0)
	  croak("error: %s", pcap_geterr(pcap));
	pcap_freecode(&real_fp);
	if (pcap_setnonblock(pcap,1,errorbuf) < 0)
	  croak("error: %s",errorbuf);
	if ((pFD =  pcap_get_selectable_fd(pcap)) < 1)
	  croak("can not get selectable pFD");

	stats = (HV *)SvRV(hpref);
	dnsrequest = (AV *)SvRV(dnsref);
	sigemptyset(&set);
	sigprocmask(SIG_SETMASK, &set, NULL);

 #####################################################################
 #
 #	vector value indicates the		args
 #	"return from" function		
 #	0	initial entry			run	
 #	1	send to dnsFD			send buffer
 #	2	send to lFD			msg || undef, 1 dump else 0 no dump
 #	3	initialize wFD			undef, 1 dump else 0 no dump (for compatibility)
 #	4	receive from dnsFD
 #	5	print wFD request		print buffer
 #	6	close wFD
 #	7	purge return
 #	8	set run = 0
 #
#define INITIALIZE	0
#define SEND_dns	1
#define SEND_listen	2
#define INIT_wFD	3
#define RECV_dns	4
#define PRINT_dumptxt	5
#define CLOSE_wFD	6
#define WAS_PURGE	7
#define TERMINATE	8

int
_enter_constants(...)
    ALIAS:
	Net::Connection::Sniffer::INITIALIZE	= 0
	Net::Connection::Sniffer::SEND_dns	= 1
	Net::Connection::Sniffer::SEND_listen	= 2
	Net::Connection::Sniffer::INIT_wFD	= 3
	Net::Connection::Sniffer::RECV_dns	= 4
	Net::Connection::Sniffer::PRINT_dumptxt	= 5
	Net::Connection::Sniffer::CLOSE_wFD	= 6
	Net::Connection::Sniffer::WAS_PURGE	= 7
	Net::Connection::Sniffer::TERMINATE	= 8
    CODE:
	RETVAL = ix;
    OUTPUT:
	RETVAL

 #
 #	first return value indicates 		args
 #	the requested perl run operation
 #	0	end, run is zero
 #	1	listen interrupt		now, sender.naddr, message received
 #	2	dnslookup
 #	3	dump request			hup, init
 #	4	dns receive			len, buffer
 #	5	purge interrupt -- dns alarm is checked here in Perl
 #
#define END_RUN		0
#define LISTEN_MSG	1
#define DNS_NEEDED	2
#define DUMP_REQUEST	3
#define DNS_RECEIVE	4
#define PURGE		5

int
_exit_constants()
    ALIAS:
	Net::Connection::Sniffer::END_RUN	= 0
	Net::Connection::Sniffer::LISTEN_MSG	= 1
	Net::Connection::Sniffer::DNS_NEEDED	= 2
	Net::Connection::Sniffer::DUMP_REQUEST	= 3
	Net::Connection::Sniffer::DNS_RECEIVE	= 4
	Net::Connection::Sniffer::PURGE		= 5
    CODE:
	RETVAL = ix;
    OUTPUT:
	RETVAL

void
xs_while(vector,...)
	int	vector
    PREINIT:
	unsigned char * buf;
	STRLEN	len;
	int	dnslen, listenlen;
    PPCODE:
	switch(vector)
	{
	case SEND_dns	:	
		if (av_len(dnsrequest) < 0) {
		  dnsRflag = 0;
		  av_undef(dnsrequest);
		}
		buf = (unsigned char *)SvPV(ST(1),len);
		sendto(dnsFD,buf,len,0,&dnsaddr.sa,socklen);
		break;
	case WAS_PURGE	:
		break;
	case PRINT_dumptxt :
		buf = (unsigned char *)SvPV(ST(1),len);
		my_dump((char *)buf,len);
		break;
	case SEND_listen :
		if (SvPOK(ST(1)) == 0)
		  break;
		buf = (unsigned char *)SvPV(ST(1),len);
		sendto(lFD,buf,len,0,&sender.sa,socklen);
	case INIT_wFD	:
		signal_dump = 0;
		if (SvIOK(ST(2)) == 0)
		  croak("arg2 is not a boolean 0/1");
		if (SvIV(ST(2)) != 0) {
		  if (dumptofile) {
		    WFD = fopen(tmp,"w");
		  }
		  wFD = fileno(WFD);
		  dump_head = 1;
		  nleft = 0;
		}
		break;
	case CLOSE_wFD	:
		if (dumptofile != 0) {
 #		  fsync(wFD);
		  while(1) {
		    if (close(wFD) < 0) {
		      if (errno == EINTR)
			continue;		/*	try again	*/
		      break;			/*	else fatal	*/
		    } else
		      rename(tmp,filepath);
		    break;
		  }
		}
		wFD = 0;
		break;
	case INITIALIZE	:
		run = SvIV(ST(1));
		ra = 0;
		ba = 0;
		maxfd = dnsFD + 1;
		if (lFD != 0 && lFD >= maxfd)
		  maxfd = lFD +1;
		if (pFD >= maxfd)
		  maxfd = pFD +1;
		max = maxfd;
		FD_ZERO(&rset);
		FD_ZERO(&wset);
		set_signals();
		goto WHILE_run;
	case TERMINATE	:
		run = 0;
	default		:
		break;
	}
	now = (u_int32_t)time(NULL);		/*	update time when returning from external call	*/

      WHILE_run:
	while (run) {
	  if (vector != 0) {
	    switch(vector) {
	/*	INITIALIZE == 0, don't have to clear vector	*/
	      case SEND_dns	:
		vector = 0;
		goto LISTENCHECK;
	      case SEND_listen	:
		vector = 0;
		goto DNSCHECK;
	      case RECV_dns	:
		vector = 0;
		goto WFDCHECK;
	      case PRINT_dumptxt	:
	      case CLOSE_wFD	:
		vector = 0;
		goto TIMECHECK;
	      default		:
		vector = 0;
	/*	continue by falling out the bottom of this	*/
		break;
	    }
	  }

	/* clear any closed/changed file descriptors	*/
	  if (wFD != wFDm) {
	    if (wFDm != 0) {
	      FD_CLR(wFDm,&wset);
	    }
	    max = maxfd;	/* downgrade max fd count	*/
	    wFDm = wFD;
	  }
	  if (pFD != pFDm) {
	    if (pFDm != 0) {
	      FD_CLR(pFDm,&rset);
	    }
	    pFDm = pFD;
	  }
	  if (dnsFD != dnsFDm) {
	    if (dnsFDm != 0) {
	      FD_CLR(dnsFDm,&rset);
	    }
	    dnsFDm = dnsFD;
	  }
	  if (lFD != lFDm) {
	    if (lFDm != 0) {
	      FD_CLR(lFDm,&rset);
	    }
	    lFDm = lFD;
	  }
	/* enable active file descriptors	*/
	  if (wFD != 0) {
	    if (wFD >= maxfd)
	      max = wFD +1;
	    FD_SET(wFD,&wset);
	  }
	  if (pFD != 0)			/*	unless terminated		*/
	    FD_SET(pFD,&rset);
	  if (dnsFD != 0)		/*	unless terminated		*/
	    FD_SET(dnsFD,&rset);
	  if (lFD != 0)			/*	if active			*/
	    FD_SET(lFD,&rset);

	  if (now > nextp)		/*	if one second timeout exceeded	*/
	    goto TIMEFORCE;

	  tloop.tv_sec = 1;		/*	wake up every second		*/
	  tloop.tv_usec = 0;
	  nfound = select(max,&rset,&wset,NULL,&tloop);
 	  if (nfound < 0) {
 	    if (errno == EINTR ||
 		errno == EWOULDBLOCK ||
 		errno == ECONNABORTED ||
 		errno == EPIPE)
 	      continue;
 # 	    croak("encountered fatal error %d: %s",errno,strerror(errno));
 	  }

	  now = (u_int32_t)time(NULL);
	  if (nfound == 0)
	    goto TIMECHECK;

	  if (FD_ISSET(pFD,&rset)) {
 #	hold signals
 #	    sigprocmask (SIG_BLOCK, &sa.sa_mask, 0);
	    pcap_dispatch(pcap,-1,sniffit,(u_char *)"");
 #	    sigprocmask (SIG_UNBLOCK, &sa.sa_mask, 0);
	    if (dnsRflag != 0) {
	      XPUSHs(sv_2mortal(newSViv(DNS_NEEDED)));
	      XSRETURN(1);
	    }
	  }

	LISTENCHECK:
	  if (lFD != 0 && FD_ISSET(lFD,&rset)) {
	    listenlen = recvfrom(lFD,out.s,512,0,&sender.sa,(socklen_t *)&socklen);
	    if (listenlen > 0) {
	      EXTEND(SP,4);
	      PUSHs(sv_2mortal(newSViv(LISTEN_MSG)));
	      PUSHs(sv_2mortal(newSVuv(now)));
	      PUSHs(sv_2mortal(newSVpv((char *)&sender.si.sin_addr.s_addr,4)));
	      PUSHs(sv_2mortal(newSVpv((char *)out.s,listenlen)));
	      XSRETURN(4);
	    }
	  }

	DNSCHECK:
	  if (FD_ISSET(dnsFD,&rset)) {
	    dnslen = recv(dnsFD,out.s,512,0);
	    if (dnslen > 0) {
	      EXTEND(SP,3);
	      PUSHs(sv_2mortal(newSViv(DNS_RECEIVE)));
	      PUSHs(sv_2mortal(newSViv(dnslen)));
	      PUSHs(sv_2mortal(newSVpv((char *)out.s,dnslen)));
	      XSRETURN(3);
	    }
	  }

	WFDCHECK:
	  if (wFD != 0 && FD_ISSET(wFD,&wset) && dumpmore() == 0) {
	    EXTEND(SP,3);
	    PUSHs(sv_2mortal(newSViv(DUMP_REQUEST)));
	    PUSHs(sv_2mortal(newSViv(hup)));
	    PUSHs(sv_2mortal(newSViv(dump_head)));
	    dump_head = 0;
	    XSRETURN(3);
	  }

	TIMECHECK:
	  if (now > nextp) {		/* purge once a second			*/
	TIMEFORCE:
	    nextp = now;
	    if (run > 0)
	      run--;
	    if (wFD != 0)
	      signal_dump = 0;
	    EXTEND(SP,3);
	    PUSHs(sv_2mortal(newSViv(PURGE)));
	    PUSHs(sv_2mortal(newSViv(now)));
	    PUSHs(sv_2mortal(newSViv(signal_dump)));
	    XSRETURN(3);
	  }
	}
	closeMOST();
	if (wFD != 0 && dumptofile != 0)
	  close(wFD);
	pcap_close(pcap);
	XPUSHs(sv_2mortal(newSViv(END_RUN)));
	XSRETURN(1);

 # ############## THIS STUFF IS FOR TESTING ONLY!

void
inc_sv(hpp,key)
	SV	* hpp
	char	* key
  ALIAS:
	Net::Connection::Sniffer::fetch_uv = 1
  PREINIT:
	HV	* hp;
  INIT:
	if (SvTYPE(SvRV(hpp)) != SVt_PVHV)
	  croak("hp is not a hash REF");
	hp = (HV *)SvRV(hpp);
  PPCODE:
	if (ix == 1) {
	  XPUSHs(sv_2mortal(newSVuv(fetch_uv(hp,key))));
	  XSRETURN(1);
	} else
	  inc_sv(hp,key);

void
set_uv(hpp,key,vp)
	SV	* hpp
	char	* key
	SV	* vp
  ALIAS:
	Net::Connection::Sniffer::set_nv = 2
	Net::Connection::Sniffer::add_nv = 1
  PREINIT:
	HV	* hp;
	u_int32_t	val32;
	double	valnv;
  INIT:
	if (SvTYPE(SvRV(hpp)) != SVt_PVHV)
	  croak("hp is not a hash REF");
	hp = (HV *)SvRV(hpp);
  CODE:
	if (ix == 2) {
	  valnv = SvNV(vp);
	  set_nv(hp,key,valnv);
	} else {
	  val32 = SvUV(vp);
	  if (ix == 1)
	    add_nv(hp,key,val32);
	  else
	    set_uv(hp,key,val32);
	}

void
aEQaPLUSbXm(hpp,key1,key2,multi)
	SV	* hpp
	char	* key1
	char	* key2
	NV	multi
  PREINIT:
	HV	* hp;
  INIT:
	if (SvTYPE(SvRV(hpp)) != SVt_PVHV)
	  croak("hp is not a hash REF");
	hp = (HV *)SvRV(hpp);
  CODE:
	aEQaPLUSbXm(hp,key1,key2,multi);

void
init_hv(hpp,len)
	SV	* hpp
	I32	len
  PREINIT:
	HV	* hp;
  INIT:
	if (SvTYPE(SvRV(hpp)) != SVt_PVHV)
	  croak("hp is not a hash REF");
	hp = (HV *)SvRV(hpp);
  CODE:
	init_hv(hp,len);

void
match_init(mtch,nomtch,paystart,paystop)
	SV	* mtch
	SV	* nomtch
	int	paystart
	int	paystop
  PREINIT:
	STRLEN	len;
  CODE:
	if (SvPOK(mtch) == 0) {
	  match = NULL;
	} else {
	  match = (u_char *)SvPV(mtch,len);
	  if (len == 0)
	    match = NULL;
	}
	if (SvPOK(nomtch) == 0) {
	  nomatch = NULL;
	} else {
	  nomatch = (u_char *)SvPV(nomtch,len);
	  if (len == 0)
	    nomatch = NULL;
	}
	if (match != NULL || nomatch != NULL) {
	  payoff = paystart;
	  paysize = paystop - paystart;
	  if (paysize < 1)
	    croak("payload length specifier to short");
	}
