/* Copyright Jepri 2003.  Released under the GPL. */
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>

#include "mdnsd.h"
#include "sdtxt.h"
#include "mdns_server.h"

int mdnss_daemon_socket;
mdnsd mdnss_daemon;
int mdnss_zzz[2];										/*  I have no frickin idea */




void mdnss_stop()
{
	/*_shutdown = 1;*/
	mdnsd_shutdown(mdnss_daemon);
	write(mdnss_zzz[1]," ",1);
	mdnsd_free(mdnss_daemon);
	/*signal(SIGHUP,SIG_DFL);*/
}

void
mdnss_conflict_handler (char *hostname, int type, void *arg)
	{
		 printf("Somebody is already using the hostname %s for type %d.  You will have to change your host name (or convince them to change theirs)\n",hostname,type);
	}

// create multicast 224.0.0.251:5353 socket
int mdnss_msock()
{
    int s, flag = 1, ittl = 255;
    struct sockaddr_in in;
    struct ip_mreq mc;
    char ttl = 255;

    bzero(&in, sizeof(in));
    in.sin_family = AF_INET;
    in.sin_port = htons(5353);
    in.sin_addr.s_addr = 0;

    if((s = socket(AF_INET,SOCK_DGRAM,0)) < 0) return 0;
#ifdef SO_REUSEPORT
    setsockopt(s, SOL_SOCKET, SO_REUSEPORT, (char*)&flag, sizeof(flag));
#endif
    setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (char*)&flag, sizeof(flag));
    if(bind(s,(struct sockaddr*)&in,sizeof(in))) { close(s); return 0; }

    mc.imr_multiaddr.s_addr = inet_addr("224.0.0.251");
    mc.imr_interface.s_addr = htonl(INADDR_ANY);
    setsockopt(s, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mc, sizeof(mc)); 
    setsockopt(s, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(ttl));
    setsockopt(s, IPPROTO_IP, IP_MULTICAST_TTL, &ittl, sizeof(ittl));

    flag =  fcntl(s, F_GETFL, 0);
    flag |= O_NONBLOCK;
    fcntl(s, F_SETFL, flag);

    return s;
}
void
mdnss_add_service ( char * hostname, char *host_ip, int int_port, char * service, char *protocol)
	{
		 char hlocal[256], nlocal[256], shared_str[256];
		 unsigned long int service_ip;
		unsigned short int service_port;
		unsigned char *packet;
		xht h;
		int len;
		mdnss_rset rrs;




		service_port = int_port;
		 service_ip = inet_addr(host_ip);
		 if ( strlen(protocol) == 0) {protocol = "tcp";};
		 snprintf(hlocal,254,"%s._%s._%s.local.",hostname, service, protocol);
		 snprintf(nlocal,254,"%s-%s.local.",service, hostname);
		 snprintf(shared_str,254, "_%s._%s.local.", service, protocol);
		 rrs.r = mdnsd_shared(mdnss_daemon,shared_str,QTYPE_PTR,120);
		 mdnsd_set_host(mdnss_daemon,rrs.r,hlocal);
		 rrs.s = mdnsd_unique(mdnss_daemon,hlocal,QTYPE_SRV,600,mdnss_conflict_handler,0);
		 mdnsd_set_srv(mdnss_daemon,rrs.s,0,0,service_port,nlocal);
		 rrs.t = mdnsd_unique(mdnss_daemon,nlocal,QTYPE_A,600,mdnss_conflict_handler,0);
		 mdnsd_set_raw(mdnss_daemon,rrs.t,(unsigned char *)&service_ip,4);
		 rrs.u = mdnsd_shared(mdnss_daemon,hlocal,16,600);
		 h = xht_new(11);
		xht_set(h,"path","testpath");
		packet = sd2txt(h, &len);
		xht_free(h);
		mdnsd_set_raw(mdnss_daemon,rrs.u,packet,len);
		free(packet);
#if DEBUG
		 printf("Sharing %s on port %d\n", hlocal, service_port);
#endif
	}

void
mdnss_add_hostname ( char * hostname, char *host_ip)
        {
		char nlocal[256];
		unsigned long int service_ip;
		mdnss_rset rrs;




		service_ip = inet_addr(host_ip);
		snprintf(nlocal,254,"%s.local.", hostname);
		rrs.t = mdnsd_unique(mdnss_daemon,nlocal,QTYPE_A,600,mdnss_conflict_handler,0);
	}
 
int
mdnss_start()
	{
		/*signal(SIGHUP,stop_mdns);*/
		pipe(mdnss_zzz);
		mdnss_daemon = mdnsd_new(1,1000);
		if((mdnss_daemon_socket = mdnss_msock()) == 0) 
			{ 
				printf("can't create socket: %s\n",strerror(errno));
				return 1; 
			}
		return 0;
	}

int
mdnss_process_network_events()
	{
struct message m;
unsigned long int ip;
unsigned short int port;
static struct timeval *tv;
int bsize, ssize = sizeof(struct sockaddr_in);
static unsigned char buf[MAX_PACKET_LEN];
struct sockaddr_in from, to;
static fd_set fds;
        tv = mdnsd_sleep(mdnss_daemon);
        FD_ZERO(&fds);
        FD_SET(mdnss_zzz[0],&fds);
        FD_SET(mdnss_daemon_socket,&fds);
				tv->tv_sec=0;
				tv->tv_usec=1;
        select(mdnss_daemon_socket+1,&fds,0,0,tv);

        // only used when we wake-up from a signal, shutting down
        if(FD_ISSET(mdnss_zzz[0],&fds)) read(mdnss_zzz[0],buf,MAX_PACKET_LEN);

        if(FD_ISSET(mdnss_daemon_socket,&fds))
        {
            while((bsize = recvfrom(mdnss_daemon_socket,buf,MAX_PACKET_LEN,0,(struct sockaddr*)&from,&ssize)) > 0)
            {
                bzero(&m,sizeof(struct message));
                message_parse(&m,buf);
                mdnsd_in(mdnss_daemon,&m,(unsigned long int)from.sin_addr.s_addr,from.sin_port);
            }
            if(bsize < 0 && errno != EAGAIN) { printf("can't read from socket %d: %s\n",errno,strerror(errno)); return 1; }
        }
        while(mdnsd_out(mdnss_daemon,&m,&ip,&port))
        {
            bzero(&to, sizeof(to));
            to.sin_family = AF_INET;
            to.sin_port = port;
            to.sin_addr.s_addr = ip;
            if(sendto(mdnss_daemon_socket,message_packet(&m),message_packet_len(&m),0,(struct sockaddr *)&to,sizeof(struct sockaddr_in)) != message_packet_len(&m))  { printf("can't write to socket: %s\n",strerror(errno)); return 1; }
        }
		}
