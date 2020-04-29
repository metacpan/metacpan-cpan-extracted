/*
Perl ARP Extension
Send the packet
BSD code

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

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <net/bpf.h>
#include <net/if.h>
#include "arp.h"

int send_packet_bsd(const char *dev, u_char *packet, u_int packetsize)
{
  int bpffd, i;
  char bpfdev[12];

  if( (strlen(dev) == 0) ||
      (packetsize == 0) )
    return 0;

  // Open a bpf device
  for(i = 0; i < 512; i++)
    {
      sprintf(bpfdev,"/dev/bpf%d",i);
      if((bpffd = open(bpfdev,O_WRONLY)) > 0)
	{
	  break;	     
	}
    }
  
  if(bpffd < 0)
    {
      perror("open bpf");
      return 0;
    }
  else
    {
      // Lock it
      flock(bpffd,LOCK_EX);
      
      // Bind it to a device
      ioctl(bpffd,BIOCSETIF,dev);
      
      // Send the packet and unlock
      write(bpffd,packet,packetsize);
      flock(bpffd,LOCK_UN);
      close(bpffd);
    }

  return 1;
}
