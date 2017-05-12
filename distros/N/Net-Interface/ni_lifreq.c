
/* ********************************************************************	*
 * ni_lifreq.c	version 0.05 3-7-09					*
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
 *
 *

  DESCRIPTION
    Accessor functions for 'lifconf' and 'lifreq'
 *
 */

#include "localconf.h"

#ifdef HAVE_STRUCT_LIFREQ
 
#ifndef LIFC_TEMPORARY
#define LIFC_TEMPORARY 0
#endif
#ifndef LIFC_ALLZONES
#define LIFC_ALLZONES 0
#endif

static int
_ni_get_ifaddrs(int fd, struct ifaddrs * thisif, struct lifreq * ifr,...)
{
    int cmd;
    
    if (ioctl(fd,SIOCGLIFFLAGS,ifr) < 0)
	return -1;
    thisif->ifa_flags = (u_int)(ifr->lifr_flags & 0xFFFFu);

    if (ioctl(fd,SIOCGLIFNETMASK,ifr) != -1) {
	if ((thisif->ifa_netmask = ni_memdup(&(ifr->lifr_addr),
				    SA_LEN(((struct sockaddr *)&ifr->lifr_addr)))) == NULL)
	    return -1;
    }
    if (thisif->ifa_flags & (IFF_POINTOPOINT | IFF_BROADCAST)) {
	if (thisif->ifa_flags & IFF_POINTOPOINT)
	    cmd = SIOCGLIFDSTADDR;
	else
	    cmd = SIOCGLIFBRDADDR;

	if (ioctl(fd,cmd,ifr) != -1) {
	    if ((thisif->ifa_dstaddr = ni_memdup(&(ifr->lifr_addr),
					SA_LEN(((struct sockaddr *)&ifr->lifr_addr)))) == NULL)
		return -1;
	}
    }
    return 0;
}

/*	nifp points to me	*/
static int
ni_lifreq_gifaddrs(struct ifaddrs **ifap, struct ni_ifconf_flavor * nifp)
{
    struct lifconf ifc;
    struct lifreq * ifr;
    struct ifaddrs * thisif, * lastif = NULL;
    struct sockaddr * sa;
    int fd, af, inc, ret, n;
    
    *ifap = NULL;

    if ((fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
	return errno;

    if (nifp->getifreqs(fd,&ifc) == NULL) {
	close(fd);
	return errno;
    }

    ifr = ifc.lifc_req;

    for (n = 0; n < ifc.lifc_len; n += sizeof(struct lifreq)) {
	if ((thisif = calloc(1, sizeof(struct ifaddrs))) == NULL) {
	    errno = ENOMEM;
	    goto error_out;
	}
	if (lastif == NULL) 	/* taken care of in init statement */
	    *ifap = thisif;
	else
	    lastif->ifa_next = thisif;

	if ((thisif->ifa_name = strdup(ifr->lifr_name)) == NULL) {
	    errno = ENOMEM;
	    goto error_out;
	}

	af = ifr->lifr_addr.ss_family;
	if ((thisif->ifa_addr = ni_memdup(&(ifr->lifr_addr),
				    SA_LEN(((struct sockaddr *)&ifr->lifr_addr)))) == NULL)
	    goto error_out;

	if (af == AF_INET) {

            fd = ni_clos_reopn_dgrm(fd,af);
	    if (_ni_get_ifaddrs(fd,thisif,ifr) < 0)
	        goto error_out;

	}	/* == AF_INET	*/
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
	else if (af == AF_INET6) {

            fd = ni_clos_reopn_dgrm(fd,af);
	    if (_ni_get_ifaddrs(fd,thisif,ifr) < 0)
	        goto error_out;

	}	/* == AF_INET6	*/
#endif
/*	for AF_LINK, AF_PACKET nothing is used except the contents of the addr record	*/

	lastif = thisif;
	ifr = (struct lifreq *)((char *)ifr + sizeof(struct lifreq));
    }
    close(fd);
    free(ifc.lifc_req);		/* free ifreq	*/
    return nifp->ni_type;	/* return family type */

  error_out:
    ret = errno;	/* preserve errno	*/
    free(ifc.lifc_req);
    ni_freeifaddrs(*ifap);
    close(fd);
    errno = ret;
    return -1;
}

static void *
_ni_getifreqs(int fd, void * vifc)
{
    int n, af, size;
    struct lifconf * ifc = vifc;
    struct lifnum lifn;
    void * buf;

    bzero(ifc,sizeof(struct lifconf));
    errno = ENOSYS;
    
    n = 2;
    buf = NULL;
    while (1) {
        size = n * PAGE_SIZE;
        if (size > NI_IFREQ_MEM_MAX) {
            free(buf);
            errno = ENOMEM;
            return NULL;
        }
        buf = realloc(buf, size);
        if (buf == NULL) {
            free(ifc->lifc_buf);
            errno = ENOMEM;
            return NULL;
        }
        ifc->lifc_family = AF_UNSPEC;
        ifc->lifc_flags =  LIFC_NOXMIT | LIFC_TEMPORARY | LIFC_ALLZONES;
        ifc->lifc_buf = buf;
        ifc->lifc_len = size;
        if (ioctl( fd, SIOCGLIFCONF, ifc) < 0 && errno != EINVAL) {
            free(buf);
            return NULL;
        }
        if (ifc->lifc_len < size - PAGE_SIZE)
            break;
        n *= 2;
/*
printf("n %d, len %d, buf %d, ifclen %d, ifr %u\n",size,buf,ifc->lifc_len,ifc->lifc_req);
 */
    }
    return ifc->lifc_req;
}
    
static void
_ni_common_flags(u_int64_t flags)
{
    int i, n;

#include "ni_IFF_inc.c"

    if (flags & IFF_UP)
        printf("UP ");
    else
        printf("DOWN ");
    n = sizeof(ni_iff_tab) / sizeof(ni_iff_t);
    for (i=0;i<n;i++) {
        if (flags & ni_iff_tab[i].iff_val)
            printf("%s ",ni_iff_tab[i].iff_nam);
    }
}

int
ni_flav_lifreq_developer(void * ifcee)
{
    /*	ifcee unused	*/
    int n, fd = -1, af, namegood, macgood;
    u_int64_t flags;
    struct lifconf lifc;
    struct lifreq * ifr;
    struct ifreq mifr;
    unsigned char mac[6] = {0x0,0x0,0x0,0xfa,0x11,0xed};
    unsigned char altmac[6], * macp;
    char namebuf[NI_MAXHOST];
    struct sockaddr_storage laddr;
    struct sockaddr_in * sin;
    struct sockaddr_in6 * sin6;
    
    lifc.lifc_family = AF_UNSPEC;	/* stuff AF for ni_getifreqs	*/
    af = AF_INET;
    if ((fd = socket(af,SOCK_DGRAM,0)) < 0)
    	return errno;

    if (_ni_getifreqs(fd,&lifc) == NULL) {
	close(fd);
	return errno;
    }
    ifr = lifc.lifc_req;
    for (n = 0; n < lifc.lifc_len; n += sizeof(struct lifreq)) {
        namegood = macgood = 0;
/* BSD pretty much assumes that SA_LEN is defined, if not fudge it	*/

	af = ifr->lifr_addr.ss_family;
	printf("%s\t",ifr->lifr_name);

	if (af == AF_INET) {
	    fd = ni_clos_reopn_dgrm(fd,AF_INET);
	    if (ioctl(fd, SIOCGLIFFLAGS,ifr) != -1) {
		flags = ifr->lifr_flags;
		printf("flags=%0llx<",flags);
                _ni_common_flags(flags);
		if (flags == 0)
		    printf(" ");
		printf("\b> ");
	    }
	    if (ioctl(fd,SIOCGLIFMETRIC,ifr) != -1 );
	    	printf("metric %d ",ifr->lifr_metric);
	    if (ioctl(fd,SIOCGLIFMTU,ifr) != -1 )
	    	printf("mtu %d",ifr->lifr_mtu);
	    printf("\n\t");

	    if (ioctl(fd,SIOCGLIFADDR,ifr) != -1 ) {
	        sin = (struct sockaddr_in *) &ifr->lifr_addr;
#ifdef HAVE_GETNAMEINFO
		if (getnameinfo(&sin->sin_addr,
		    LOCAL_SIZEOF_SOCKADDR_IN,namebuf,NI_MAXHOST,NULL,0,NI_NUMERICHOST) != 0)
#endif
		    strcpy(namebuf,inet_ntoa(sin->sin_addr));
	    	printf("address %s\t",namebuf);
	    }
	    if (ioctl(fd,SIOCGLIFNETMASK,ifr) != -1 ) {
	        sin = (struct sockaddr_in *) &ifr->lifr_addr;
		printf("mask 0x%lx\t",(unsigned long)ntohl(sin->sin_addr.s_addr));
            }
/* want to include here.... flags & IFF_BROADCAST	*/
	    if (ioctl(fd,SIOCGLIFBRDADDR,ifr) != -1) {
	        sin = (struct sockaddr_in *) &ifr->lifr_addr;
                strcpy(namebuf,inet_ntoa(sin->sin_addr));
	    	printf("netmask %s\t",namebuf);
            }
	}
	else if (af == AF_INET6) {
	    fd = ni_clos_reopn_dgrm(fd,AF_INET6);
	    if (ioctl(fd,SIOCGLIFADDR,ifr) != -1 ) {
	        sin6 = (struct sockaddr_in6 *)&ifr->lifr_addr;
#ifdef HAVE_GETNAMEINFO
		if (getnameinfo(&ifr->ni_saddr,LOCAL_SIZEOF_SOCKADDR_IN6,namebuf,NI_MAXHOST,NULL,0,NI_NUMERICHOST) != 0)
#endif
		    strcpy(namebuf,inet_ntop(AF_INET6,&sin6->sin6_addr,namebuf,NI_MAXHOST));
                namegood = 1;
            }

	    if (ioctl(fd,SIOCGLIFFLAGS,ifr) < 0 ) {
	        printf("\nflags error: %d %s",errno, strerror(errno));
	    }
            else {
		flags = ifr->lifr_flags; 
                printf("flags=%0llx<",flags);
                _ni_common_flags(flags);
	        if (flags == 0)
                    printf(" ");
                printf("\b> ");
            }
            if (ioctl(fd,SIOCGLIFMETRIC,ifr) != -1 );
		printf("metric %d ",ifr->lifr_metric);
	    if (ioctl(fd,SIOCGLIFMTU,ifr) != -1 )
		printf("mtu %d",ifr->lifr_mtu);
        }
        printf("\n\t");
        if (namegood)
            printf("address %s\n\t",namebuf);

	printf("af=%d sz=%d ",af,sizeof(struct lifreq));
	
#if defined SIOCENADDR
	if (ioctl(fd,SIOCENADDR,ifr) != -1)
	    macgood = 1;
#endif
	if (macgood == 1)
            macp = (unsigned char *)&ifr->lifr_enaddr;
	else {
	    strlcpy(mifr.ifr_name,ifr->lifr_name,IFNAMSIZ);
	    close(fd);
	    fd = -1;
	    if ((macp = ni_fallbackhwaddr(af,&mifr)) != NULL)
	        macgood = 1;
        }
        if (macgood)
	    printf("MAC addr %02X:%02X:%02X:%02X:%02X:%02X",
	        macp[0],macp[1],macp[2],macp[3],macp[4],macp[5]);

	printf("\n");
	ifr++;
    }
    close(fd);
    free(lifc.lifc_req);
    return 0;
}

static struct ni_ifconf_flavor ni_flavor_lifreq = {
    .ni_type		= NI_LIFREQ,
    .siocgifindex	= SIOCGLIFINDEX,
    .siocsifaddr	= SIOCSLIFADDR,
    .siocgifaddr	= SIOCGLIFADDR,
    .siocdifaddr	= SIOCLIFREMOVEIF,
    .siocaifaddr	= SIOCLIFADDIF,
    .siocsifdstaddr	= SIOCSLIFDSTADDR,
    .siocgifdstaddr	= SIOCGLIFDSTADDR,
    .siocsifflags	= SIOCSLIFFLAGS,
    .siocgifflags	= SIOCGLIFFLAGS,
    .siocsifmtu		= SIOCSLIFMTU,
    .siocgifmtu		= SIOCGLIFMTU,
    .siocsifbrdaddr	= SIOCSLIFBRDADDR,
    .siocgifbrdaddr	= SIOCGLIFBRDADDR,
    .siocsifnetmask	= SIOCGLIFNETMASK,
    .siocgifnetmask	= SIOCGLIFNETMASK,
    .siocsifmetric	= SIOCSLIFMETRIC,
    .siocgifmetric	= SIOCGLIFMETRIC,
    .ifr_offset		= NI_LIFREQ_OFFSET,
    .gifaddrs		= ni_lifreq_gifaddrs,
    .fifaddrs		= ni_freeifaddrs,
    .refreshifr		= NULL,
    .getifreqs		= _ni_getifreqs,
    .developer		= ni_flav_lifreq_developer,
};

void
ni_lifreq_ctor()
{
    ni_ifcf_register(&ni_flavor_lifreq);
}

#else
    
void
ni_lifreq_ctor()
{
    return;
}
    
#endif	/* have lifreq */

