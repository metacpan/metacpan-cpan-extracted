/*
Perl ARP Extension
Send the packet
Linux code

Programmed by Bastian Ballmann
Last update: 01.12.2004

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
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>      
#include <arpa/inet.h>
#include "arp.h"

int send_packet_linux(const char *dev, u_char *packet, u_int packetsize)
{
  struct sockaddr addr;
  int sock;

  if(strlen(dev) == 0)
  {
    printf("dev is undefined. Terminating.\n");
    return 0;
  }

  if(packetsize == 0)
  {
    printf("packetsize is zero. Terminating.\n");
    return 0;
  }

  // Create socket descriptor
  if( ( sock = socket(AF_INET,SOCK_TYPE,htons(ETH_P_ALL))) < 0 ) 
    { 
      perror("socket"); 
      return 0;
    }

  // Set dev and send the packet
  strncpy(addr.sa_data,dev,sizeof(addr.sa_data));

  if( (sendto(sock,packet,packetsize,0,&addr,sizeof(struct sockaddr))) < 0 )
    {
      perror("send");
      return 0;
    }

  close(sock);
  return 1;
}
