/*
Perl ARP Extension
Create and send an arp packets, lookup mac addresses

Programmed by Bastian Ballmann
Last update: 11.05.2022

This program is free software; you can redistribute 
it and/or modify it under the terms of the 
GNU General Public License version 2 as published 
by the Free Software Foundation.

This program is distributed in the hope that it will 
be useful, but WITHOUT ANY WARRANTY; without even 
the implied warranty of MERCHANTABILITY or FITNESS 
FOR A PARTICULAR PURPOSE. 
See the GNU General Public License for more details. 
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <stdio.h>           
#include <stdlib.h>          
#include <string.h>          
#include <errno.h>           
#include <net/ethernet.h>    
#ifdef BSD
#include <netinet/if_ether.h>
#else
#include <netinet/ether.h>
#endif
#include <net/if.h>
#include <arpa/inet.h>       
#include "arp.h"

MODULE = Net::ARP		PACKAGE = Net::ARP		

int
send_packet(dev, sip, dip, smac, dmac, type)
	const char *dev;
	const char *sip;
	const char *dip;
	const char *smac;
	const char *dmac;
	const char *type;

	CODE:
	int uid;
	unsigned int packetsize = sizeof(struct my_arphdr) + sizeof(struct ether_header);
	unsigned char packet[packetsize];
	struct ether_header *ethhdr = (struct ether_header *)packet;
	struct my_arphdr *arp = (struct my_arphdr *)(packet + sizeof(struct ether_header));
	u_short op;	
	in_addr_t ipaddr;

	RETVAL = 1;

	// Are you root?
	uid = getuid();
	if(uid != 0) 
	{ 
		printf("You must have UID 0 instead of %d.\n", uid); 
		exit(0);
	}

	// Initialize packet buffer 
	memset(packet,0,packetsize);

	// What's the ARP operation type?
	if(!strcmp(type, "request"))
	{
		op = ARPOP_REQUEST;
	}
	else if(!strcmp(type, "reply"))
	{
		op = ARPOP_REPLY;
	}
	else if(!strcmp(type, "revrequest"))
	{
		op = ARPOP_REVREQUEST;
	}
	else if(!strcmp(type, "revreply"))
	{
		op = ARPOP_REVREPLY;
	}
	else if(!strcmp(type, "invrequest"))
	{
		op = ARPOP_INVREQUEST;
	}
	else if(!strcmp(type, "invreply"))
	{
		op = ARPOP_INVREPLY;
	}
	else
	{
		printf("Unknown ARP operation\n");
		RETVAL = 0;
	}

	if(smac == NULL)
	{
		printf("Parameter smac is NULL! Terminating.\n");
		RETVAL = 0;
	}

	if(dmac == NULL)
	{
		printf("Parameter dmac is NULL! Terminating.\n");
		RETVAL = 0;
	}

	// Found a dollar sign?
	if(strchr(smac, 36))
	{
		printf("Found a $ char in smac! Terminating.\n");
		RETVAL = 0;
	}

	if(strchr(dmac, 36))
	{
		printf("Found a $ char in dmac! Terminating.\n");
		RETVAL = 0;
	}

	if(ether_aton(smac) == NULL)
	{
		printf("Invalid source mac address! Terminating.\n");
		RETVAL = 0;
	}

	if(ether_aton(dmac) == NULL)
	{
		printf("Invalid destination mac address! Terminating.\n");
		RETVAL = 0;
	}

	// Check ips
	if(inet_addr(sip) == INADDR_NONE)
	{
		printf("Invalid source ip address! Terminating.\n");
		RETVAL = 0;
	}

	if(inet_addr(dip) == INADDR_NONE)
	{
		printf("Invalid destination ip address! Terminating.\n");
		RETVAL = 0;
	}

	// Construct and send packet
	if(RETVAL != 0)
	{
		// Ethernet header
		memcpy(ethhdr->ether_dhost,(u_char *)ether_aton(dmac), ETHER_ADDR_LEN); // Destination MAC
		memcpy(ethhdr->ether_shost,(u_char *)ether_aton(smac), ETHER_ADDR_LEN); // Source MAC
		ethhdr->ether_type = htons(ETHERTYPE_ARP);                              // ARP protocol

		// ARP header
		arp->hw_type = htons(ARPHDR_ETHER);                                     // Hardware address type
		arp->proto_type = htons(ETH_P_IP);                                      // Protocol address type
		arp->ha_len = ETH_ALEN;                                                 // Hardware address length
		arp->pa_len = IP_ALEN;                                                  // Protocol address length
		arp->opcode = htons(op);                                                // ARP operation
		memcpy(arp->source_add,(u_char *)ether_aton(smac), ETH_ALEN);           // Source MAC
		memcpy(arp->dest_add,(u_char *)ether_aton(dmac), ETH_ALEN);             // Destination MAC
		ipaddr = inet_addr(sip);
		memcpy(arp->source_ip, (u_char *)&ipaddr, IP_ALEN);        		        // Source IP

		ipaddr = inet_addr(dip);
		memcpy(arp->dest_ip, (u_char *)&ipaddr, IP_ALEN);	            	    // Destination IP


		if(LINUX == 1)
		{
			RETVAL = send_packet_linux(dev, packet, packetsize);	    
		}
		else
		{
			RETVAL = send_packet_bsd(dev, packet, packetsize);	
		}
	}

	OUTPUT:
	RETVAL

char *
get_mac(dev)
	const char *dev;
	CODE:
    char tmp[HEX_HW_ADDR_LEN] = "unknown";

	if(LINUX == 1)
	{
		get_mac_linux(dev, tmp);
	}
	else
	{
		get_mac_bsd(dev, tmp);	  
	}

	RETVAL = tmp;

	OUTPUT:
	RETVAL


char *
arp_lookup(dev, ip)
	const char *dev;
	const char *ip;

	CODE:
	char tmp[HEX_HW_ADDR_LEN] = "unknown";

	if(LINUX == 1)
	{
		arp_lookup_linux(dev, ip, tmp);
	}
	else
	{
		arp_lookup_bsd(dev, ip, tmp);	
	}

	RETVAL = tmp;

	OUTPUT:
	RETVAL
