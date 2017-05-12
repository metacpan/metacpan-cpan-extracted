/*
Perl ARP Extension
Get the MAC address of an interface
Linux code

Programmed by Bastian Ballmann
Last update: 09.02.2006

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

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <net/ethernet.h>    
#include <net/if.h>
#include "arp.h"

int get_mac_linux(const char *dev, char *mac)
{
  int    sock;
  struct ifreq iface;

  if ( !strlen(mac) || !strlen(dev) )
    return -1;

  /* Set hardware address as unknown */
  strncpy(mac,"unknown", HEX_HW_ADDR_LEN);
  mac[HEX_HW_ADDR_LEN-1] = '\0';

  /* Copy device name into the ifreq strcture so that we can look for its
   * hardware address through an ioctl request */
  strncpy(iface.ifr_name, dev, IFNAMSIZ);
  iface.ifr_name[IFNAMSIZ-1] = '\0';

  // Open a socket
  if((sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
      perror("socket");
      return -1;
    }
  else
    {
      // Get the interface hardware address
      if((ioctl(sock, SIOCGIFHWADDR, &iface)) < 0)
	{
	  perror("ioctl SIOCGIFHWADDR");
	  close(sock);
	  return -1;
	}
      else
	{
	  sprintf(mac,"%02x:%02x:%02x:%02x:%02x:%02x",
		  iface.ifr_hwaddr.sa_data[0] & 0xff, 
		  iface.ifr_hwaddr.sa_data[1] & 0xff,
		  iface.ifr_hwaddr.sa_data[2] & 0xff, 
		  iface.ifr_hwaddr.sa_data[3] & 0xff,
		  iface.ifr_hwaddr.sa_data[4] & 0xff, 
		  iface.ifr_hwaddr.sa_data[5] & 0xff);	
	}
    }

  close(sock);
  return 0;
}
