/* Copyright Jepri 2003.  Released under the GPL. */
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>

#include "mdnsd.h"
#include "sdtxt.h"
#include "mdns_client.h"

#define DEBUG 1

int mdnsc_daemon_socket;
int mdnsc_something_happened=0;
mdnsd mdnsc_daemon;

typedef struct 
	{
		int num_items;
		int max_items;
		int bytes;
		mdnsda * rec;
	}	rec_list;

rec_list rlist;


/*
 *	The string handed to the query function has to be constructed according to the mdns RFC
 *	If you are familiar with the RFC, you can make your own string and give it to the query function.  
 *	For everyone else, use this function to get the string to pass to the query function.
 *	
 *	Query types are: "host by service", "ip by hostname", and "data by hostname" which correspond to lookup types "PTR(12)", "A(1)", and "SRV(33)"
 *	"host_by_service":	Give a service name like "smtp" or "http" or "pudding".  Leave host blank.
 *	"ip by hostname":		Give a service name and a host name, leave protocol blank.
 *	"data by hostname":	Give a service name and a host name, leave protocol blank.
 *
 *	The domain must be set to "local." to query the local network, otherwise you may give a real domain name.  
 *	You must include the fullstop at the end of "local.", for other domains the full stop may be optional.
 *	
 *	Free the returned string after use.
 */
char *
mdnsc_make_query(char * query_type, char * hostname, char * domain, char * service, char * protocol)
	{
		char * retchar;
		retchar = (char *) calloc(1,MAX_STRING+1);
		if (!strcmp("host by service", query_type))
			{ snprintf(retchar, MAX_STRING, "_%s._%s.%s", service, protocol, domain);}
	
		if (!strcmp("ip by hostname", query_type))
			{  snprintf(retchar, MAX_STRING, "%s-%s.%s", service, hostname, domain);}
	
		if (!strcmp("data by hostname", query_type))
			{ snprintf(retchar, MAX_STRING, "%s._%s._%s.%s", hostname, service, protocol, domain);}

		return retchar;
	}
		
int
mdnsc_query_callback(mdnsda a, void *arg)
	{
		mdnsc_something_happened = 1;
		return 1;
	}



// create multicast 224.0.0.251:5353 socket
int mdnsc_msock()
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


int
mdnsc_start()
{
	mdnsc_daemon = mdnsd_new(1,1000);
	if((mdnsc_daemon_socket = mdnsc_msock()) == 0) { 
		printf("can't create socket: %s\n",strerror(errno)); 
		return 1; 
	}
	rlist.max_items = 64;
	rlist.num_items = 0;
	rlist.bytes = sizeof(mdnsda);
	
	return 0;

}

void
mdnsc_stop()
{
	mdnsd_shutdown(mdnsc_daemon);
	mdnsd_free(mdnsc_daemon);

}

mdnsda
mdnsc_get_a_result(char *query_type, char * query_string)
{
	static mdnsda rec = NULL;
	if (!strcmp("host by service", query_type))
		{rec = mdnsd_list(mdnsc_daemon, query_string, QTYPE_PTR, rec);}

	if (!strcmp("ip by hostname", query_type))
		{rec = mdnsd_list(mdnsc_daemon, query_string, QTYPE_A, rec);}

	if (!strcmp("data by hostname", query_type))
		{rec = mdnsd_list(mdnsc_daemon, query_string, QTYPE_SRV, rec);}
	return rec;
}

/*  The query string has to conform to the RFC.  You can do this by hand or use make_query to build it for you.
 *	Keep your query string around, it's the same one that you give to "get_a_result" to get the results for your query.
 *	Multiple queries can be run at once.
 */
int
mdnsc_query(char *query_type, char *query_string)
{

	int done_it=0;
#if DEBUG
	printf("Received query string ->|%s|<- and query type ->|%s|<-\n", query_string, query_type);
#endif
	if (!strcmp("host by service", query_type))
		{ 
#if DEBUG
			printf("Sending query ->|%s|<- for hosts by service\n", query_string);
#endif
			mdnsd_query(mdnsc_daemon,query_string, QTYPE_PTR,mdnsc_query_callback,0);
			done_it = 1;
		}

	if (!strcmp("ip by hostname", query_type))
		{
#if DEBUG
			printf("Sending query ->|%s|<- for ip by hostname\n", query_string);
#endif
			mdnsd_query(mdnsc_daemon,query_string, QTYPE_A,mdnsc_query_callback,0);
			done_it = 1;
		}

	if (!strcmp("data by hostname", query_type))
		{ 
#if DEBUG
			printf("Sending query ->|%s|<- for data by hostname\n", query_string);
#endif
			mdnsd_query(mdnsc_daemon,query_string, QTYPE_SRV,mdnsc_query_callback,0);
			done_it = 1;
		}
	return done_it;

}

/*	Use exactly the same terms as the original query to cancel the query */
void
mdnsc_cancel_query(char *query_type, char *query_string)
{
/*	Setting the callback function to NULL cancels the query */
	if (!strcmp("host by service", query_type))
		{ mdnsd_query(mdnsc_daemon,query_string, QTYPE_PTR,NULL,0);}

	if (!strcmp("ip by hostname", query_type))
		{  mdnsd_query(mdnsc_daemon,query_string, QTYPE_A,NULL,0);}

	if (!strcmp("data by hostname", query_type))
		{ mdnsd_query(mdnsc_daemon,query_string, QTYPE_SRV,NULL,0);}
}

int
mdnsc_process_network_events()
{
    static struct message m;
    static struct timeval *tv;
    int bsize, ssize = sizeof(struct sockaddr_in);
    static unsigned char buf[MAX_PACKET_LEN];
    static struct sockaddr_in from, to;
    static fd_set fds;
    static unsigned long int ip;
        static unsigned short int port;


				mdnsc_something_happened=0;
        tv = mdnsd_sleep(mdnsc_daemon);
        FD_ZERO(&fds);
        FD_SET(mdnsc_daemon_socket,&fds);
				tv->tv_sec=0;
				tv->tv_usec=1;
        select(mdnsc_daemon_socket+1,&fds,0,0,tv);

        if(FD_ISSET(mdnsc_daemon_socket,&fds))
        {
            while((bsize = recvfrom(mdnsc_daemon_socket,buf,MAX_PACKET_LEN,0,(struct sockaddr*)&from,&ssize)) > 0)
            {
                bzero(&m,sizeof(struct message));
                message_parse(&m,buf);
                mdnsd_in(mdnsc_daemon,&m,(unsigned long int)from.sin_addr.s_addr,from.sin_port);
            }
            if(bsize < 0 && errno != EAGAIN) { printf("can't read from socket %d: %s\n",errno,strerror(errno)); return 1; }
        }
        while(mdnsd_out(mdnsc_daemon,&m,&ip,&port))
        {
            bzero(&to, sizeof(to));
            to.sin_family = AF_INET;
            to.sin_port = port;
            to.sin_addr.s_addr = ip;
            if(sendto(mdnsc_daemon_socket,message_packet(&m),message_packet_len(&m),0,(struct sockaddr *)&to,sizeof(struct sockaddr_in)) != message_packet_len(&m))  { printf("can't write to socket: %s\n",strerror(errno)); return 1; }
        }

    return mdnsc_something_happened;
}

