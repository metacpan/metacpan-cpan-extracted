/*
Perl ARP Extension
Lookup the MAC address of an ip address
Linux code

Programmed by Bastian Ballmann and Alexander Mueller
Last update: 20.09.2006

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

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/if_arp.h>

/*
 * Search for a hardware address linked to an IP address on a device
 *
 * @device:  network interface name we are going to query
 * @ip:      ip address (IPv4 numbers-and-dots notation) whose hardware address
 *           is going to be looked for
 * @hw_addr: buffer containing the hardware mac_address
 *
 * \returns 0 if a hardware address has been found. @mac is set accordingly as
 *            a null terminated string.
 *          1 if an error occured
 */
int
arp_lookup_linux (
        const char *device, const char *ip, char *hw_addr)
{
    int                 s;
    unsigned char       err;
    struct in_addr      ipaddr;
    struct arpreq       areq;
    struct sockaddr_in *sin;

    err = 1;

    /* A device name must be a null terminated string whose length is less
     * than 16 bytes */
    if ( !strlen(device) || (strlen(device) >= 16) )
        fprintf(stderr, "No valid device name found.\n");

    /* Is there a buffer allocated to store the hardware address? */
    else if (hw_addr == NULL)
        fprintf(stderr, "No memory allocated to store the hardware address.\n");

    /* Make sure the ip address is valid */
    else if ( !strlen(ip) || (inet_aton(ip, &ipaddr) == 0) )
        fprintf(stderr, "Invalid ip address.\n");

    /* Create the socket */
    else if ((s = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
        perror("Socket");

    else {

        /* Set up the protocol address */
        memset(&areq, 0, sizeof(areq));
        sin = (struct sockaddr_in *) &areq.arp_pa;
        sin->sin_family = AF_INET;
        sin->sin_addr = ipaddr;

        /* Set up the hardware address */
        sin = (struct sockaddr_in *) &areq.arp_ha;
        sin->sin_family = ARPHRD_ETHER;
        strcpy(areq.arp_dev, device);

        /* Carry out the request */
        if (ioctl(s, SIOCGARP, &areq) == -1)
            perror("SIOCGARP");

        else {
            sprintf(hw_addr, "%02x:%02x:%02x:%02x:%02x:%02x",
                        areq.arp_ha.sa_data[0] & 0xFF,
                        areq.arp_ha.sa_data[1] & 0xFF,
                        areq.arp_ha.sa_data[2] & 0xFF,
                        areq.arp_ha.sa_data[3] & 0xFF,
                        areq.arp_ha.sa_data[4] & 0xFF,
                        areq.arp_ha.sa_data[5] & 0xFF);
            err = 0;
        }

	/* Close the current socket */
	close(s);
    }

    return err;
}
