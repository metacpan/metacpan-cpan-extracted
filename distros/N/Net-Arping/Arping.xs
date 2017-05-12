/*
 * Arping.xs
 * Copyright (c) 2002. Oleg Prokopyev. All rights reserved. This program is free
 * software; you can redistribute it and/or modify it under the same terms
 * as Perl itself.
 *
 * Thanks to Marvin (marvin@rootbusters.net).
 * I used a little bit his code from 
 * arping utility in my handlepacket function :)
 *
 * Comments/suggestions to riiki@gu.net
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libnet.h>
#include <pcap.h> 
#include <string.h>

#include <net/if.h>
#include <net/if_arp.h>

#include <setjmp.h>

#ifndef ETH_P_IP                                                                
#define ETH_P_IP 0x0800                                                         
#endif

MODULE = Net::Arping		PACKAGE = Net::Arping		

SV *
send_arp(dst_ip,timeout,...)
	char *dst_ip
	int timeout
	PREINIT:
		u_char *device=NULL;
		STRLEN n_a;		
	CODE:	
		
		u_long rr,src_ip; 
		u_char *packet;
		struct sockaddr_in sin;
		char err_buf[LIBNET_ERRBUF_SIZE];
		char errbuf[PCAP_ERRBUF_SIZE]; 
		struct libnet_link_int *network;
		int packet_size,i;
		struct ether_addr *src_mac;

		struct bpf_program filter;
		pcap_t *handle;
		jmp_buf Env;
		
	    
		u_char enet_src[6] = {0x00, 0x00, 0x00, 0x00, 0x00,0x00};
		u_char enet_dst[6] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff}; 
		
		char filter_app[] = "arp";
			    
		char ttt[17]="0";
		
		/*
		Handle Packet Procedure
		*/	
		
		void
		handlepacket(const char *unused, struct pcap_pkthdr *h,u_char *packet)
		{
			struct ethhdr *eth;
			struct arphdr *harp;
			u_int32_t ip;
			unsigned char *cp;
			unsigned int i;
			
			char tt[3];
			

			eth = (struct ethhdr*)packet;
			harp = (struct arphdr*)((char*)eth + sizeof(struct libnet_ethernet_hdr));
			memcpy(&ip, (char*)harp + harp->ar_hln + sizeof(struct arphdr), 4);
			cp = (u_char*)harp + sizeof(struct arphdr);
			
			if ((htons(harp->ar_op) == ARPOP_REPLY)
				&& (htons(harp->ar_pro) == ETH_P_IP) 
				&& (htons(harp->ar_hrd) == ARPHRD_ETHER)
				&& ((u_int32_t)rr == ip))
			{
				strcpy(ttt,"");

				for (i = 0; i < harp->ar_hln-1;i++)
				{	
	    			    sprintf(tt,"%.2x:", *cp++);
				    strcat(ttt,tt);
				}
				sprintf(tt,"%.2x", *cp++);
				strcat(ttt,tt);
				longjmp(Env, 1);
			}
			
		}
		
		void
		boom()
		{
		    longjmp(Env, 1);
		}    
		     
		/*
		*/
	
		if( items >2 )	
		{
			device=(u_char *)SvPV(ST(2),n_a);
		} 
		
		rr=libnet_name_resolve(dst_ip,LIBNET_RESOLVE);
		if(rr==-1)
		{
			croak("bad dst ip address\n");
		}
		
		if(device == NULL) 
		{
			if(libnet_select_device(&sin,&device,err_buf) == -1)
			{
				croak("libnet_select_device failed:\t %s",err_buf);
			}
		}
		
		if ((network = libnet_open_link_interface(device, err_buf)) == NULL)
		{
			croak("libnet_open_link_interface failed:\t %s",err_buf);
		}
		
		if(!(src_ip = htonl(libnet_get_ipaddr(network,device,err_buf))))
		{
			croak("libnet_get_ipaddr failed: \t %s",err_buf);
		}
		
		packet_size=LIBNET_IP_H + LIBNET_ETH_H + LIBNET_ARP_H;
		
		
		if (libnet_init_packet(packet_size, &packet) == -1)
		{
			croak("libnet_init_packet failed: \t %s",err_buf);
		}
		
		if (!(src_mac = libnet_get_hwaddr(network,device,err_buf)))
		{
			croak("libnet_get_hwaddr failed: \t %s",err_buf);
		}
		
		memcpy(enet_src, src_mac->ether_addr_octet,6);
		
		
 		if(libnet_build_ethernet(enet_dst,enet_src,ETHERTYPE_ARP,NULL,0,packet) == -1)
		{
			croak("libnet_build_ethernet failed: \t %s",err_buf);
		}
		
		if(libnet_build_arp(ARPHRD_ETHER,ETHERTYPE_IP,6,4,ARPOP_REQUEST,enet_src,(u_char*)&src_ip,enet_dst,(u_char*)&rr,NULL,0,packet + LIBNET_ETH_H) == -1)
		{
			croak("libnet_build_arp failed: \t %s",err_buf);
		}
		
		if(!(handle = pcap_open_live(device,100,1,10, errbuf)))
		{
			croak("pcap_open_live failed\n");
		}
                
		if(pcap_compile(handle,&filter,filter_app,0,-1) == -1)
		{
			croak("pcap_compile failed\n");
		}

		if(pcap_setfilter(handle,&filter) == -1)
		{
			croak("pcap_setfilter failed\n");
		}

		alarm(timeout);
		signal(SIGALRM, boom);		
		
		
		i = libnet_write_link_layer(network, device, packet,packet_size);
		
		if (setjmp(Env) == 0) {
		    pcap_loop(handle,0, (pcap_handler)handlepacket, NULL);
		} 
		    
		if(i!=packet_size) 
		{
			croak("failed, sent only %d bytes\n",i);
		}
		
		libnet_close_link_interface(network);
		libnet_destroy_packet(&packet); 
		
		RETVAL=newSVpv(ttt,0);
				
		OUTPUT:
			RETVAL
												   