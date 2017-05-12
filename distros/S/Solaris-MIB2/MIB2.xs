#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "MIB2.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

static int
ipdot(IpAddress addr, char *buf) {
   unsigned char *caddr;
   caddr = (unsigned char*)&addr;
   return sprintf(buf,"%d.%d.%d.%d",
      caddr[0],caddr[1],caddr[2],caddr[3]);
}

static int
ip6dot(Ip6Address addr, char *buf, size_t size ) {
   inet_ntop(AF_INET6, &addr, buf, size);
   return 0;
}

static int
ipmac(Octet_t addr, char *buf, size_t size) {
   int   i;
   char *sep;
   char *bp;
   sep = "%02x"; memset(buf, 0x00, size);
   for(i = 0, bp = buf; i < addr.o_length; i++ ) {
      sprintf(bp, sep, (unsigned char)addr.o_bytes[i]);
      bp += i ? 3 : 2; sep = ":%02x";
   }
   return 0;
}

static int
ipnmsk(Octet_t mask, char *buf, size_t size) {
   int   i;
   char *bp;
   memset(buf, 0x00, size);
   for(i = 0, bp = buf; i < mask.o_length; i++ ) {
      sprintf(bp, "%02x", (unsigned char)mask.o_bytes[i]);
      bp += 2;
   }
   return 0;
}

static HV*
get_hash(HV* hash, char *key) {
   SV **rhash;
   HV  *ihash;
   if (!(rhash = hv_fetch(hash,key,strlen(key),FALSE))) {
      ihash  = newHV();
      hv_store(hash,key,strlen(key),newRV_noinc((SV*)ihash),0);
   } else {
      ihash = (HV*)SvRV(*rhash);
   }
   return ihash;
}

static AV*
get_list(HV* hash, char *key) {
   SV **rlist;
   AV  *ilist;
   if (!(rlist = hv_fetch(hash,key,strlen(key),FALSE))) {
      ilist  = newAV();
      hv_store(hash,key,strlen(key),newRV_noinc((SV*)ilist),0);
   } else {
      ilist = (AV*)SvRV(*rlist);
   }
   return ilist;
}

static int
get_mib2_data(SV* self) 
{
   int    sd;
   MAGIC *mg;
   HV    *hash;
   HV    *temp;
   AV    *list;
   SV    *ref;

   char  *msg      = 0;
   int    msg_size = 0;
   char   buf[BUFSIZ];
   char   ipb[BUFSIZ];
   int    flags;
   int    n;

   struct strbuf         control;
   struct strbuf         data;
   struct T_optmgmt_req *req_opt = (struct T_optmgmt_req *)buf;
   struct T_optmgmt_ack *ack_opt = (struct T_optmgmt_ack *)buf;
   struct T_error_ack   *err_opt = (struct T_error_ack *)buf;
   struct opthdr        *req_hdr;

   if(!(mg = mg_find(SvRV(self),'~'))) {
      croak("lost ~ magic");
   }
   sd   = SvIVX(mg->mg_obj);
   hash = (HV*)SvRV(self); 
     
   req_opt->PRIM_type  = T_OPTMGMT_REQ;
   req_opt->OPT_offset = sizeof(struct T_optmgmt_req);
   req_opt->OPT_length = sizeof(struct opthdr);

#if SOLARIS_VERSION >= 260
   req_opt->MGMT_flags = T_CURRENT;
#else
   req_opt->MGMT_flags = MI_T_CURRENT;
#endif

   req_hdr        = (struct opthdr *)&req_opt[1];
   req_hdr->level = MIB2_IP;
   req_hdr->name  = 0;
   req_hdr->len   = 0;

   control.buf    = buf;
   control.len    = req_opt->OPT_length + req_opt->OPT_offset;

   if(putmsg(sd,&control,0,0) < 0)
      fatal("failed to send control message");

   req_hdr        = (struct opthdr *)&ack_opt[1];
   control.maxlen = sizeof(buf);
   for(;;) {
      flags = 0;
      if((n = getmsg(sd,&control,0,&flags)) < 0)
         fatal("failed to get control message");
      if(!n && control.len    >= sizeof(struct T_optmgmt_ack) &&
	 (ack_opt->PRIM_type  == T_OPTMGMT_ACK)               &&
	 (ack_opt->MGMT_flags == T_SUCCESS)                   &&
	 (req_hdr->len        == 0))
         break;
      if((control.len       >= sizeof(struct T_error_ack))    &&
	 err_opt->PRIM_type == T_ERROR_ACK)
         fatal("failed to read control message");
      if((n != MOREDATA)                                      ||
	 (control.len         <  sizeof(struct T_optmgmt_ack))||
	 (ack_opt->PRIM_type  != T_OPTMGMT_ACK)               ||
	 (ack_opt->MGMT_flags != T_SUCCESS ) )
         fatal( "invalid control message received" );

      if(!msg || req_hdr->len > msg_size) {
	 if(msg) Safefree(msg);
	 New(0,msg,req_hdr->len,char);
	 msg_size = req_hdr->len;
      }
      data.maxlen = req_hdr->len;
      data.buf    = msg;
      data.len    = 0;
      flags       = 0;

      if ((n = getmsg(sd,0,&data,&flags)) < 0) 
         fatal( "error reading data" );

      switch( req_hdr->level ) {
	 case MIB2_IP:
	    if (req_hdr->name == 0) {
	       temp = get_hash(hash,MIB2_GROUP_IP);
	       SAVE_MIB2_IP(temp,(mib2_ip_t*)msg);
            }
	    if (req_hdr->name == MIB2_IP_ADDR ) {
               list = get_list(hash,MIB2_GROUP_IP_ADDR_ENTRY); av_clear(list);
	       for(n=0; (char*)((mib2_ipAddrEntry_t*)msg + n)<(msg+req_hdr->len); n++) {
		  temp = newHV();
		  SAVE_MIB2_IP_ADDR_ENTRY(temp,(((mib2_ipAddrEntry_t*)msg)+n),ipb);
		  ref = (SV*)newRV_noinc((SV*)temp);
		  av_store(list,n,ref);
               }
	    }
	    if (req_hdr->name == MIB2_IP_ROUTE ) {
               list = get_list(hash,MIB2_GROUP_IP_ROUTE_ENTRY); av_clear(list);
	       for(n=0; (char*)((mib2_ipRouteEntry_t*)msg + n)<(msg+req_hdr->len); n++) {
		  temp = newHV();
		  SAVE_MIB2_IP_ROUTE_ENTRY(temp,(((mib2_ipRouteEntry_t*)msg)+n),ipb);
		  ref = (SV*)newRV_noinc((SV*)temp);
		  av_store(list,n,ref);
               }
	    }
	    if (req_hdr->name == MIB2_IP_MEDIA ) {
               list = get_list(hash,MIB2_GROUP_IP_NET2MEDIA_ENTRY); av_clear(list);
	       for(n=0; (char*)((mib2_ipNetToMediaEntry_t*)msg + n)<(msg+req_hdr->len); n++) {
		  temp = newHV();
		  SAVE_MIB2_IP_NET2MEDIA_ENTRY(temp,(((mib2_ipNetToMediaEntry_t*)msg)+n),ipb);
		  ref = (SV*)newRV_noinc((SV*)temp);
		  av_store(list,n,ref);
               }
	    }
	    if (req_hdr->name == EXPER_IP_GROUP_MEMBERSHIP ) {
               list = get_list(hash,MIB2_GROUP_IP_MEMBER); av_clear(list);
	       for(n=0; (char*)((ip_member_t*)msg + n)<(msg+req_hdr->len); n++) {
		  temp = newHV();
		  SAVE_MIB2_IP_MEMBER(temp,(((ip_member_t*)msg)+n),ipb);
		  ref = (SV*)newRV_noinc((SV*)temp);
		  av_store(list,n,ref);
               }
	    }
	    break;
	 case MIB2_ICMP:
	    if (req_hdr->name == 0) {
	       temp = get_hash(hash,MIB2_GROUP_ICMP);
	       SAVE_MIB2_ICMP(temp,(mib2_icmp_t*)msg);
	    }
	    break;
	 case MIB2_TCP:
	    if (req_hdr->name == 0) {
	       temp = get_hash(hash,MIB2_GROUP_TCP);
	       SAVE_MIB2_TCP(temp,(mib2_tcp_t*)msg);
	    }
	    if (req_hdr->name == MIB2_TCP_CONN) {
               list = get_list(hash,MIB2_GROUP_TCP_CONN_ENTRY); av_clear(list);
	       for(n=0; (char*)((mib2_tcpConnEntry_t*)msg + n)<(msg+req_hdr->len); n++) {
		  temp = newHV();
		  SAVE_MIB2_TCP_CONN_ENTRY(temp,(((mib2_tcpConnEntry_t*)msg)+n),ipb);
		  ref = (SV*)newRV_noinc((SV*)temp);
		  av_store(list,n,ref);
               }
	    }
	    break;
	 case MIB2_UDP:
	    if (req_hdr->name == 0) {
	       temp = get_hash(hash,MIB2_GROUP_UDP);
	       SAVE_MIB2_UDP(temp,(mib2_udp_t*)msg);
	    }
	    if (req_hdr->name == MIB2_UDP_ENTRY) {
               list = get_list(hash,MIB2_GROUP_UDP_ENTRY); av_clear(list);
	       for(n=0; (char*)((mib2_udpEntry_t*)msg + n)<(msg+req_hdr->len); n++) {
		  temp = newHV();
		  SAVE_MIB2_UDP_ENTRY(temp,(((mib2_udpEntry_t*)msg)+n),ipb);
		  ref = (SV*)newRV_noinc((SV*)temp);
		  av_store(list,n,ref);
               }
	    }
	    break;
	 case EXPER_RAWIP:
	    if (req_hdr->name == 0) {
	       temp = get_hash(hash,MIB2_GROUP_RAWIP);
	       SAVE_MIB2_RAWIP(temp,(mib2_rawip_t*)msg);
	    }
	    break;
         default:
	    break;
      }
   }
   return 0;
};   

MODULE = Solaris::MIB2		PACKAGE = Solaris::MIB2		
PROTOTYPES: ENABLE

SV*
new(class,device=DEV_DEFAULT)
   char *class;
   char *device;
PREINIT:
   HV   *stash;
   HV   *hash;
   SV   *sdsv;
   int   sd;
   int   n;
CODE:
   hash   = newHV();
   RETVAL = (SV*)newRV_noinc((SV*)hash);
   stash  = gv_stashpv(class,TRUE);
   sv_bless(RETVAL,stash);

   if ( ( sd = open( device, O_RDWR ) ) < 0 ) 
      fatal("failed to open network device");
   while( ioctl( sd, I_POP, &n ) != -1 );

   /* only need to push arp module for /dev/ip */
   if (!strcmp(device,"/dev/ip")) {
      if ( ioctl( sd, I_PUSH, ARP_MODULE ) < 0 )
         fatal( "failed to push ARP_MODULE" );
   }

   if ( ioctl( sd, I_PUSH, TCP_MODULE ) < 0 ) 
      fatal( "failed to push TCP_MODULE" );
   if ( ioctl( sd, I_PUSH, UDP_MODULE ) < 0 ) 
      fatal( "failed to push UDP_MODULE" );
#if defined _PUSH_ICMP
   /* only works for Solaris 7 onward (as per Casper Dik) */
   if ( ioctl( sd, I_PUSH, ICMP_MODULE ) < 0 ) 
      fatal( "failed to push ICMP_MODULE" );
#endif

   sdsv = newSViv(sd);
   sv_magic(SvRV(RETVAL),sdsv,'~',0,0);
   SvREFCNT_dec(sdsv);

   get_mib2_data(RETVAL);
   SvREADONLY_on(hash);
OUTPUT:
   RETVAL

int
update(self)
   SV* self;
PREINIT:
   HV* hash;
CODE:
   get_mib2_data(self);
   RETVAL = 0;
OUTPUT:
   RETVAL

void
DESTROY(self)
   SV    *self;
PREINIT:
   MAGIC *mg;
   int    sd;
CODE:
   mg = mg_find(SvRV(self),'~');
   if(!mg) { croak("lost ~ magic"); }
   sd = SvIVX(mg->mg_obj);
   close(sd);
