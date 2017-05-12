
/* ********************************************************************	*
 * ni_ifreq.c	version 0.04	3-7-09					*
 *									*
 *     COPYRIGHT 2008-2009 Michael Robinton <michael@bizsystems.com>	*
 *									*
 * This program is free software; you can redistribute it and/or modify	*
 * it under the terms of either:					*
 *									*
 *  a) the GNU General Public License as published by the Free		*
 *  Software Foundation; either version 2, or (at your option) any	*
 *  later version, or							*
 *									*
 *  b) the "Artistic License" which comes with this distribution.	*
 *									*
 * This program is distributed in the hope that it will be useful,	*
 * but WITHOUT ANY WARRANTY; without even the implied warranty of	*
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either	*
 * the GNU General Public License or the Artistic License for more 	*
 * details.								*
 *									*
 * You should have received a copy of the Artistic License with this	*
 * distribution, in the file named "Artistic".  If not, I'll be glad 	*
 * to provide one.							*
 *									*
 * You should also have received a copy of the GNU General Public 	*
 * License along with this program in the file named "Copying". If not, *
 * write to the 							*
 *									*
 *	Free Software Foundation, Inc.					*
 *	59 Temple Place, Suite 330					*
 *	Boston, MA  02111-1307, USA					*
 *									*
 * or visit their web page on the internet at:				*
 *									*
 *	http://www.gnu.org/copyleft/gpl.html.				*
 * ********************************************************************	*

DESCRIPTION
    Accessor functions for 'ifconf' and 'ifreq'
 *
 */

/* for BSD flavors, consider using ifmib facility and struct if_data	*/

#include "localconf.h"

#ifdef HAVE_STRUCT_IFREQ

static void *
_ni_getifreqs(int fd, void * vifc)
{
    int n,size;
    struct ifconf * ifc = (struct ifconf *)vifc;
    void * ifr;

    bzero(ifc,sizeof(struct ifconf));

#ifdef SIOCGIFCOUNT

    if (ioctl(fd, SIOCGIFCOUNT, ifc) != -1) {
	size = ifc->ifc_len * sizeof(struct ifreq);
	if (size > NI_IFREQ_MEM_MAX)
	    goto nifreq_nomem;
	ifr = malloc(size);
	if (ifr == NULL) {
  nifreq_nomem:
	    errno = ENOMEM;
	    return NULL;
	}
	ifc->ifc_req = ifr;
	ifc->ifc_len = size;
/* Solaris returns EINVAL for small buffer	*/
	if (ioctl (fd, SIOCGIFCONF, ifc) < 0) {
	    free(ifr);
	    if (errno == EINVAL)
		goto nifreq_iterate;
	    else
		return NULL;
	}
	return ifr;
    }
  nifreq_iterate:

#endif

    n = 2;
    ifr = ifc->ifc_req;
    while (1) {
	ifr = realloc(ifr, n * PAGE_SIZE );
	if (ifr == NULL) {
  nifreq_mem_over:
	    free(ifc->ifc_req);
	    errno = ENOMEM;
      	    return NULL;
	}
	ifc->ifc_req = ifr;
	size = n * PAGE_SIZE;
	if (size > NI_IFREQ_MEM_MAX)
	    goto nifreq_mem_over;
	ifc->ifc_len = size;
	if (ioctl( fd, SIOCGIFCONF, ifc ) < 0 && errno != EINVAL) {
	    free (ifr);
	    return NULL;
	}
	if (ifc->ifc_len < size - PAGE_SIZE)	/* (n-1) * PAGE_SIZE */
	    break;
	n *= 2;
    }
    return ifr;
}

/* print stuff of interest, return 0 on success else the errno	*/

int
ni_flav_ifreq_developer(void * ifcee)
{
/*	ifcee unused	*/
    int i, n, fd, inc, af, j;
    unsigned short flags;
    struct ifconf ifc;
    struct nifreq *ifr, *lifr;
    unsigned char * macp;
    char namebuf[NI_MAXHOST];
#ifdef LOCAL_SIZEOF_SOCKADDR_DL
    const struct sockaddr_dl * sdl;
#endif

#include "ni_IFF_inc.c"
    
    if ((fd = socket(AF_INET,SOCK_DGRAM,0)) < 0)
    	return errno;
    if (_ni_getifreqs(fd,&ifc) == NULL) {
	close(fd);
	return errno;
    }
    ifr = (struct nifreq *)ifc.ifc_req;
    lifr = (struct nifreq *)&(ifc.ifc_buf[ifc.ifc_len]);
/*    while (ifr < lifr) { */
for(j = 0; j < ifc.ifc_len; j += inc) {
	macp = NULL;
	inc = ni_SIZEOF_ADDR_IFREQ((struct ifreq *)ifr,(&ifr->ni_saddr),sizeof(struct ifreq));
	af = ifr->ni_saddr.sa_family;
	printf("%s\t",ifr->ni_ifr_name);
	
	if (af == AF_INET) {
	    if (ioctl(fd, SIOCGIFFLAGS,ifr) != -1) {
	    	flags = ifr->ni_ushort;
	    	printf("flags=%0x<",flags);
		if (flags & IFF_UP)
		    printf("UP ");
		else
		    printf("DOWN ");
		n = sizeof(ni_iff_tab) / sizeof(ni_iff_t);
		for (i=0;i<n;i++) {
		    if (flags & ni_iff_tab[i].iff_val)
		    	printf("%s ",ni_iff_tab[i].iff_nam);
		}

		if (flags == 0)
		    printf(" ");
		printf("\b> ");
	    }   

	    if (ioctl(fd,SIOCGIFMETRIC,ifr) != -1 );
	    	printf("metric %d ",ifr->ni_int);
#ifdef SIOCGIFMTU
	    if (ioctl(fd,SIOCGIFMTU,ifr) != -1 )
	    	printf("mtu %d",ifr->ni_uint);
#elif defined SIOCGIFDATA
	    if (ioctl(fd,SIOCGIFDATA,ifr) != -1)
		printf("mtu %d",((struct ifdata *)ifr->ni_data)->ifi_mtu;
#endif
	    printf("\n\t");

	    if (ioctl(fd,SIOCGIFADDR,ifr) != -1 ) {
#ifdef HAVE_GETNAMEINFO
		if (getnameinfo(&ifr->ni_saddr,LOCAL_SIZEOF_SOCKADDR_IN,namebuf,NI_MAXHOST,NULL,0,NI_NUMERICHOST) != 0)
#endif
		    strcpy(namebuf,inet_ntoa(ifr->ni_sin.sin_addr));
	    	printf("address %s\t",namebuf);
	    }
	    if (ioctl(fd,SIOCGIFNETMASK,ifr) != -1 )
		printf("mask 0x%lx\t",(unsigned long)ntohl(ifr->ni_sin.sin_addr.s_addr));
	    if (ioctl(fd,SIOCGIFBRDADDR,ifr) != -1 )
	    	printf("broadcast %s\t",inet_ntoa(ifr->ni_sin.sin_addr));
	}
	printf("\n\taf=%d sz=%d ",af,inc);
	
#if defined SIOCGIFHWADDR
	if (ioctl(fd,SIOCGIFHWADDR,ifr) != -1 && NI_MAC_NOT_ZERO(&ifr->ni_saddr.sa_data))
	    macp = (unsigned char *)(&ifr->ni_saddr.sa_data);
#endif
#if defined SIOCGENADDR
	if (ioctl(fd,SIOCGENADDR,ifr) != -1)
	    macp = (unsigned char *)(&ifr->ni_char);
#endif
	if (macp != NULL)
	    NI_PRINT_MAC(macp);

	printf("\n");

	ifr = (struct nifreq *)(((char *)ifr) + inc);
    }
    close(fd);
    free(ifc.ifc_req);
    return 0;
}

static struct ni_ifconf_flavor ni_flavor_ifreq = {
    .ni_type		= NI_IFREQ,
#ifdef SIOCGIFINDEX
    .siocgifindex	= SIOCGIFINDEX,
#else
    .siocgifindex	= 0,
#endif
    .siocsifaddr	= SIOCSIFADDR,
    .siocgifaddr	= SIOCGIFADDR,
#ifdef SIOCDIFADDR
    .siocdifaddr	= SIOCDIFADDR,
# else
    .siocdifaddr	= 0,
#endif
#ifdef SIOCAIFADDR
    .siocaifaddr	= SIOCAIFADDR,
#else
    .siocaifaddr	= 0,
#endif
    .siocsifdstaddr	= SIOCSIFDSTADDR,
    .siocgifdstaddr	= SIOCGIFDSTADDR,
    .siocsifflags	= SIOCSIFFLAGS,
    .siocgifflags	= SIOCGIFFLAGS,
    .siocsifmtu		= SIOCSIFMTU,
    .siocgifmtu		= SIOCGIFMTU,
    .siocsifbrdaddr	= SIOCSIFBRDADDR,
    .siocgifbrdaddr	= SIOCGIFBRDADDR,
    .siocsifnetmask	= SIOCGIFNETMASK,
    .siocgifnetmask	= SIOCGIFNETMASK,
    .siocsifmetric	= SIOCSIFMETRIC,
    .siocgifmetric	= SIOCGIFMETRIC,
    .ifr_offset		= 0,
    .gifaddrs		= nifreq_gifaddrs,
    .fifaddrs		= ni_freeifaddrs,
    .refreshifr		= NULL,
    .getifreqs		= _ni_getifreqs,
    .developer		= ni_flav_ifreq_developer,
};

void
ni_ifreq_ctor()
{
    ni_ifcf_register(&ni_flavor_ifreq);
}

#else

void
ni_ifreq_ctor()
{
    return;
};

#endif	/* have ifreq */
