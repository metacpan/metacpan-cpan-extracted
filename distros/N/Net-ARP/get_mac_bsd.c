/*
Perl ARP Extension
Get the MAC address of an interface
BSD code

Programmed by Bastian Ballmann
Last update: 09.02.2006

Fixed for FreeBSD by Niels Bakker
Last update: 2007-12-26

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

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>

#include <net/if_dl.h>
#include <net/if_types.h>
#include <net/ethernet.h>
#include "arp.h"

int get_mac_bsd(const char *dev, char *mac)
{
  struct ifaddrs *iface, *iffirst;

  if ( (mac == NULL) || (dev == NULL) )
    return -1;

  strncpy(mac,"unknown", HEX_HW_ADDR_LEN);
  mac[HEX_HW_ADDR_LEN - 1] = '\0';

  if (getifaddrs(&iface))
    return -1;

  iffirst = iface;
  while(iface->ifa_next != NULL)
  {
    if(!strcmp(iface->ifa_name,dev))
    {
      if (iface->ifa_addr->sa_family == AF_LINK)
      {
        struct sockaddr_dl *sdl = (struct sockaddr_dl *) iface->ifa_addr;
        sprintf(mac, "%s", ether_ntoa((struct ether_addr *)LLADDR(sdl)));
        break;
      }
    }

    iface = iface->ifa_next;	
  }

  freeifaddrs(iffirst);
  return 0;
}
