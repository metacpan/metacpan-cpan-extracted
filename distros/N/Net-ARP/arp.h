/*
Perl ARP Extension header file

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

#define ARPOP_REQUEST    1
#define ARPOP_REPLY      2
#define ARPOP_REVREQUEST 3
#define ARPOP_REVREPLY   4
#define ARPOP_INVREQUEST 8
#define ARPOP_INVREPLY   9
#define ARPHDR_ETHER     1
#ifndef ETH_ALEN
#define ETH_ALEN         6
#endif
#ifndef ETH_P_IP
#define ETH_P_IP         0x0800
#endif
#ifndef ETH_P_ARP
#define ETH_P_ARP        0x0806
#endif
#ifndef ETH_P_ALL
#define ETH_P_ALL        0x0000
#endif
#define IP_ALEN          4

/* Length of the hardware address in the standard hex-digits-and-colons
 * notation (null terminated string) */
#define HEX_HW_ADDR_LEN  18

// ARP Header Struktur
struct my_arphdr {
   u_short hw_type;             // hardware type
   u_short proto_type;          // protocol type
   u_char ha_len;               // hardware address len
   u_char pa_len;               // protocol address len
   u_short opcode;              // arp opcode
   u_char source_add[ETH_ALEN]; // source mac
   u_char source_ip[IP_ALEN];   // source ip
   u_char dest_add[ETH_ALEN];   // dest mac
   u_char dest_ip[IP_ALEN];     // dest ip
};

#if defined(LINUX) && defined(__THROW) 
  extern struct ether_addr *ether_aton (__const char *__asc) __THROW;
#else
  #define LINUX 0
  extern struct ether_addr *ether_aton (__const char *__asc);
#endif
extern int get_mac_linux(const char *dev, char *mac);
extern int get_mac_bsd(const char *dev, char *mac);
extern int arp_lookup_linux(const char *dev, const char *ip, char *mac);
extern int arp_lookup_bsd(const char *dev, const char *ip, char *mac);
extern int send_packet_linux(const char *dev, u_char *packet, u_int packetsize);
extern int send_packet_bsd(const char *dev, u_char *packet, u_int packetsize);
