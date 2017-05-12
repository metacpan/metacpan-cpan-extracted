#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <netinet/in.h>
#include "./mdns/mdns_client.h"

#include "const-c.inc"

MODULE = Net::MDNS::Client		PACKAGE = Net::MDNS::Client		PREFIX = mdnsc_

INCLUDE: const-xs.inc

void
mdnsc_cancel_query(query_type, query_string)
	char *	query_string
	char *	query_type

mdnsda
mdnsc_get_a_result(query_type, query_string)
	char *	query_string
	char *	query_type

	INIT:
		mdnsda r;
		struct in_addr in;
		char * t;

	PPCODE:
		r = mdnsc_get_a_result(query_type, query_string);
		if ( GIMME_V == G_VOID )
			{ XSRETURN_UNDEF;}
		if (r)
			{
				if ( GIMME_V == G_SCALAR )
					{
						if (!strcmp("host by service", query_type))
                        				{
								int len; char u[513]; char * p;
								p = (char *) &u;
								if ( r->rdlen >511 ) {len=511;} else {len=r->rdlen;}
								strncpy( p, (char *)(r->rdata+1), len-3);
								u[len-3]=0;
								XSRETURN_PV( p);
							}
        
                				if (!strcmp("ip by hostname", query_type))
                        				{  
								in.s_addr = r->ip;
								t = inet_ntoa(in);
								XSRETURN_PV(t);
							}
        
                				if (!strcmp("data by hostname", query_type))
                        				{ XSRETURN_IV(r->srv.port); }
					}
         			if ( GIMME_V == G_ARRAY )
           				{
						if (r->name)
							{
								XPUSHs(sv_2mortal(newSVpv("name", 4)));
								XPUSHs(sv_2mortal(newSVpv(r->name, strlen(r->name))));
							}
						XPUSHs(sv_2mortal(newSVpv("type", 4)));
						XPUSHs(sv_2mortal(newSViv((int ) r->type)));
						XPUSHs(sv_2mortal(newSVpv("ttl", 3)));
						XPUSHs(sv_2mortal(newSViv((int ) r->ttl)));
						if (r->rdlen>2)
							{
								XPUSHs(sv_2mortal(newSVpv("rdata", 5)));
								XPUSHs(sv_2mortal(newSVpv(r->rdata, r->rdlen-2)));
							}
						XPUSHs(sv_2mortal(newSVpv("ip", 2)));
						in.s_addr = r->ip;
						t = inet_ntoa(in);
						XPUSHs(sv_2mortal(newSVpv(t, strlen(t))));
						XPUSHs(sv_2mortal(newSVpv("priority", 8)));
						XPUSHs(sv_2mortal(newSViv((int )r->srv.priority)));
						XPUSHs(sv_2mortal(newSVpv("weight", 6)));
						XPUSHs(sv_2mortal(newSViv((int )r->srv.weight)));
						XPUSHs(sv_2mortal(newSVpv("port", 4)));
						XPUSHs(sv_2mortal(newSViv((int )r->srv.port)));
					}
			}



	

char *
mdnsc_make_query(query_type, hostname, service, domain, protocol)
	char *	query_type
	char *	hostname
	char *	service
	char *	domain
	char *	protocol

int
mdnsc_process_network_events()

int
mdnsc_query(query_type, query_string)
	char *	query_string
	char *	query_type

int
mdnsc_start()

void
mdnsc_stop()
