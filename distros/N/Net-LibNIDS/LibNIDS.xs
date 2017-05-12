#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "nids.h"

#include "const-c.inc"


#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "pcap.h"



SV* our_tcp_callback = 0;


void
tcp_callback_f (struct tcp_stream *tcp_stream, SV ** tcp_stream_sv_ptr) {



  if(tcp_stream->nids_state == NIDS_JUST_EST) {
    SV* tcp_stream_sv = newRV_noinc(newSViv((IV) tcp_stream));
    sv_bless(tcp_stream_sv, gv_stashpv("Net::LibNIDS::tcp_stream",1));
    *tcp_stream_sv_ptr = tcp_stream_sv;
  }
  {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(*tcp_stream_sv_ptr);
    PUTBACK;
    call_sv(our_tcp_callback, G_VOID);
    FREETMPS;
    LEAVE;
	  
  }
  if((!tcp_stream->server.collect 
      && !tcp_stream->client.collect
      && !tcp_stream->server.collect_urg
      && !tcp_stream->client.collect_urg)
     || tcp_stream->nids_state == NIDS_CLOSE
     || tcp_stream->nids_state == NIDS_RESET
     ) {
    
    SvREFCNT_dec(*tcp_stream_sv_ptr);
    *tcp_stream_sv_ptr = NULL;
    if(tcp_stream->nids_state == NIDS_CLOSE 
       || tcp_stream->nids_state == NIDS_RESET) {
    }
  }

}

char* state2string (IV state) {
  switch (state) {
  case NIDS_JUST_EST:
    return "NIDS_JUST_EST";
  case NIDS_DATA:
    return "NIDS_DATA";
  case NIDS_CLOSE:
    return "NIDS_CLOSE";
  case NIDS_RESET:
    return "NIDS_RESET";
  case NIDS_TIMED_OUT:
    return "NIDS_TIMED_OUT";
  case NIDS_EXITING:
    return "NIDS_EXITING";
  default:
    return "UNKNOWN";
  }     
}

#define obj2tcpstream(obj)     ((struct tcp_stream*) SvIV(SvRV(obj)))
#define obj2halfstream(obj)     ((struct half_stream*) SvIV(SvRV(obj)))
#define int_ntoa(x)     inet_ntoa(*((struct in_addr *)&x))

MODULE = Net::LibNIDS		PACKAGE = Net::LibNIDS::tcp_stream

# Export of last_pcap_header was added in libnids-1.19
#if NIDS_MINOR>=19
IV
lastpacket_sec(obj)
	  SV* obj
	CODE:
	  RETVAL = nids_last_pcap_header->ts.tv_sec;
	OUTPUT:
	  RETVAL

IV
lastpacket_usec(obj)
	  SV* obj
	CODE:
	  RETVAL = nids_last_pcap_header->ts.tv_usec;
	OUTPUT:
	  RETVAL

#else

void
lastpacket_sec(obj)
	  SV* obj
	CODE:
	  croak("You need libnids >1.19 in order to use this function");

void
lastpacket_usec(obj)
	  SV* obj
	CODE:
	  croak("You need libnids >1.19 in order to use this function");

#endif

IV
state(obj)
	  SV* obj
	CODE:
      	  RETVAL = obj2tcpstream(obj)->nids_state;
	OUTPUT:
	  RETVAL

char*
state_string(obj)
	  SV* obj
	CODE:
      	  RETVAL = state2string(obj2tcpstream(obj)->nids_state);
	OUTPUT:
	  RETVAL

SV*
server(obj)
	  SV* obj
	CODE:
	  RETVAL = newRV_noinc(newSViv((IV) &(obj2tcpstream(obj)->server )));
	  sv_bless(RETVAL, gv_stashpv("Net::LibNIDS::tcp_stream::half",1));
	OUTPUT:
	  RETVAL

SV*
client(obj)
	  SV* obj
	CODE:
	  RETVAL = newRV_noinc(newSViv((IV) &(obj2tcpstream(obj)->client )));
	  sv_bless(RETVAL, gv_stashpv("Net::LibNIDS::tcp_stream::half",1));
	OUTPUT:
	  RETVAL
		

char*
client_ip(obj)
	  SV* obj
	CODE:
	  RETVAL = int_ntoa(obj2tcpstream(obj)->addr.saddr);
	OUTPUT: 
	  RETVAL

char*
server_ip(obj)
	  SV* obj
	CODE:     
	  RETVAL = int_ntoa(obj2tcpstream(obj)->addr.daddr);
	OUTPUT: 
	  RETVAL

IV
client_port(obj)
	  SV* obj
	CODE:
	  RETVAL = obj2tcpstream(obj)->addr.source;
	OUTPUT: 
	  RETVAL

IV
server_port(obj)
	  SV* obj
	CODE:
	  RETVAL = obj2tcpstream(obj)->addr.dest;
	OUTPUT: 
	  RETVAL

void
discard(obj, numbytes);
    SV* obj;
    int numbytes;
  CODE:
    nids_discard(obj2tcpstream(obj), numbytes);



MODULE = Net::LibNIDS		PACKAGE = Net::LibNIDS::tcp_stream::half

void
collect_on(obj)
	  SV* obj
	CODE:
	  obj2halfstream(obj)->collect = 1;

void
collect_off(obj)
	  SV* obj
	CODE:
	  obj2halfstream(obj)->collect = 0;

IV
collect(obj)
	  SV* obj
	CODE:
	  RETVAL = obj2halfstream(obj)->collect;
	OUTPUT:
	  RETVAL

void
collect_urg_on(obj)
	  SV* obj
	CODE:
	  obj2halfstream(obj)->collect_urg = 1;

void
collect_urg_off(obj)
	  SV* obj
	CODE:
	  obj2halfstream(obj)->collect_urg = 0;

IV
collect_urg(obj)
	  SV* obj
	CODE:
	  RETVAL = obj2halfstream(obj)->collect_urg;
	OUTPUT:
	  RETVAL

IV
count(obj)
	  SV* obj
	CODE:
	  RETVAL = obj2halfstream(obj)->count;
	OUTPUT:
	  RETVAL

IV
count_new(obj)
	  SV* obj
	CODE:
	  RETVAL = obj2halfstream(obj)->count_new;
	OUTPUT:
	  RETVAL

IV
offset(obj)
	  SV* obj
	CODE:
	  RETVAL = obj2halfstream(obj)->offset;
	OUTPUT:
	  RETVAL

SV*
data(obj)
	  SV* obj
	CODE:
	  RETVAL = newSVpv( obj2halfstream(obj)->data ,  obj2halfstream(obj)->count_new);
	OUTPUT:
	  RETVAL

IV
curr_ts(obj)
	  SV* obj
	CODE:
	  RETVAL = obj2halfstream(obj)->curr_ts;
	OUTPUT:
	  RETVAL



MODULE = Net::LibNIDS		PACKAGE = Net::LibNIDS		

INCLUDE: const-xs.inc


IV
nids_init()
     POSTCALL:
	  if(!RETVAL)
            croak("Net::LibNIDS: %s", nids_errbuf);

void
nids_run()



void
tcp_callback(cb);
    SV* cb
  CODE:
      our_tcp_callback = SvRV(cb);
      nids_register_tcp(tcp_callback_f);

void
checksum_off()
	CODE:
	  struct nids_chksum_ctl nochksumchk;
	  nochksumchk.netaddr = 0;
	  nochksumchk.mask = 0;
	  nochksumchk.action = NIDS_DONT_CHKSUM;
	  nids_register_chksum_ctl(&nochksumchk, 1);


MODULE = Net::LibNIDS		PACKAGE = Net::LibNIDS::param

char*
get_device()
     CODE:
       RETVAL = nids_params.device;
     OUTPUT:
       RETVAL

void
set_device(device)
	    char* device
	  CODE:
	    nids_params.device = device;


char*
get_filename()
     CODE:
       RETVAL = nids_params.filename;
     OUTPUT:
       RETVAL

void
set_filename(filename)
	    char* filename
	  CODE:
	    nids_params.filename = filename;

char*
get_pcap_filter()
     CODE:
       RETVAL = nids_params.pcap_filter;
     OUTPUT:
       RETVAL

void
set_pcap_filter(pcap_filter)
	    char* pcap_filter
	  CODE:
	    nids_params.pcap_filter = pcap_filter;


IV
get_n_tcp_streams()
     CODE:
       RETVAL = nids_params.n_tcp_streams;
     OUTPUT:
       RETVAL

void
set_n_tcp_streams(n_tcp_streams)
	    IV n_tcp_streams
	  CODE:
	    nids_params.n_tcp_streams = n_tcp_streams;


IV
get_n_hosts()
     CODE:
       RETVAL = nids_params.n_hosts;
     OUTPUT:
       RETVAL

void
set_n_hosts(n_hosts)
	    IV n_hosts
	  CODE:
	    nids_params.n_hosts = n_hosts;

IV
get_sk_buff_size()
     CODE:
       RETVAL = nids_params.sk_buff_size;
     OUTPUT:
       RETVAL

void
set_sk_buff_size(sk_buff_size)
	    IV sk_buff_size
	  CODE:
	    nids_params.sk_buff_size = sk_buff_size;

IV
get_dev_addon()
     CODE:
       RETVAL = nids_params.dev_addon;
     OUTPUT:
       RETVAL

void
set_dev_addon(dev_addon)
	    IV dev_addon
	  CODE:
	    nids_params.dev_addon = dev_addon;


IV
get_syslog_level()
     CODE:
       RETVAL = nids_params.syslog_level;
     OUTPUT:
       RETVAL

void
set_syslog_level(syslog_level)
	    IV syslog_level
	  CODE:
	    nids_params.syslog_level = syslog_level;


IV
get_scan_num_hosts()
     CODE:
       RETVAL = nids_params.scan_num_hosts;
     OUTPUT:
       RETVAL

void
set_scan_num_hosts(scan_num_hosts)
	    IV scan_num_hosts
	  CODE:
	    nids_params.scan_num_hosts = scan_num_hosts;

IV
get_scan_num_ports()
     CODE:
       RETVAL = nids_params.scan_num_ports;
     OUTPUT:
       RETVAL

void
set_scan_num_ports(scan_num_ports)
	    IV scan_num_ports
	  CODE:
	    nids_params.scan_num_ports = scan_num_ports;

IV
get_scan_delay()
     CODE:
       RETVAL = nids_params.scan_delay;
     OUTPUT:
       RETVAL

void
set_scan_delay(scan_delay)
	    IV scan_delay
	  CODE:
	    nids_params.scan_delay = scan_delay;

IV
get_promisc()
     CODE:
       RETVAL = nids_params.promisc;
     OUTPUT:
       RETVAL

void
set_promisc(promisc)
	    IV promisc
	  CODE:
	    nids_params.promisc = promisc;

IV
get_one_loop_less()
     CODE:
       RETVAL = nids_params.one_loop_less;
     OUTPUT:
       RETVAL

void
set_one_loop_less(one_loop_less)
	    IV one_loop_less
	  CODE:
	    nids_params.one_loop_less = one_loop_less;
