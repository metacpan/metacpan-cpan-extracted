/*
Perl ARP Extension
Lookup the MAC address of an ip address
BSD code

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

#include <sys/file.h>
#include <sys/socket.h>
#include <net/if_dl.h>
#include <net/route.h>
#include <net/if_arp.h>
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/if_ether.h>
#include <arpa/inet.h>
#include <sys/sysctl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "arp.h"

#define ROUNDUP(a) \
        ((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

int arp_lookup_bsd(const char *dev, const char *ip, char *mac)
{
  int mib[6];
  size_t needed;
  char *lim, *buf, *next;

  if ( (mac == NULL) || (dev == NULL) || (ip == NULL) )
    return -1;

  strncpy(mac,"unknown", HEX_HW_ADDR_LEN);
  mac[HEX_HW_ADDR_LEN-1] = '\0';

  mib[0] = CTL_NET;
  mib[1] = PF_ROUTE;
  mib[2] = 0;
  mib[3] = AF_INET;
  mib[4] = NET_RT_FLAGS;
  mib[5] = RTF_LLINFO;

  /* Retrieve routing table */

  if(sysctl(mib, 6, NULL, &needed, NULL, 0) < 0)
  {
    perror("route-sysctl-estimate");
    exit(1);
  }

  if((buf = malloc(needed)) == NULL)
  {
    perror("malloc");
    exit(1);
  }

  if(sysctl(mib, 6, buf, &needed, NULL, 0) < 0)
  {
    perror("retrieval of routing table");
    exit(1);
  }

  lim = buf + needed;
  next = buf;

  /* Search for the requested ip */
  while (next < lim) 
  {
    struct rt_msghdr *rtm = (struct rt_msghdr *)next;
    struct sockaddr_inarp *sinarp = (struct sockaddr_inarp *)(rtm + 1);
    struct sockaddr_dl *sdl = (struct sockaddr_dl *)((char *)sinarp + ROUNDUP(sinarp->sin_len));

    if( (sdl->sdl_alen) && (!strcmp(ip,inet_ntoa(sinarp->sin_addr))) )
	  { 
	    sprintf(mac,"%s", ether_ntoa((struct ether_addr *)LLADDR(sdl)));
	  }

    next += rtm->rtm_msglen;
  }

  free(buf);
  return(0);
}
