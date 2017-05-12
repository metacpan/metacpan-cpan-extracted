
/* ********************************************************************	*
 * ni_linuxproc.c	version 0.04 3-9-09				*
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
 * ********************************************************************	*/

#include "localconf.h"

#ifdef __ni_Linux

#define _PATH_PROCNET_DEV	       "/proc/net/dev"
#define _PATH_PROCNET_IFINET6	   "/proc/net/if_inet6"

/*	should be  include from /linux/include/linux/rtnetlink.h	*/

/* ifa_flags */
#ifndef IFA_F_SECONDARY
#define IFA_F_SECONDARY		0x01
#endif
#ifndef IFA_F_TEMPORARY
#define IFA_F_TEMPORARY		IFA_F_SECONDARY
#endif
#ifndef IFA_F_NODAD
#define IFA_F_NODAD		0x02
#endif
#ifndef IFA_F_OPTIMISTIC
#define IFA_F_OPTIMISTIC	0x04
#endif
#ifndef IFA_F_HOMEADDRESS
#define IFA_F_HOMEADDRESS	0x10
#endif
#ifndef IFA_F_DEPRECATED
#define IFA_F_DEPRECATED	0x20
#endif
#ifndef IFA_F_TENTATIVE
#define IFA_F_TENTATIVE		0x40
#endif
#ifndef IFA_F_PERMANENT
#define IFA_F_PERMANENT		0x80
#endif

static void
lx_ifa_f_flags(int flags)
{
    if (flags & IFA_F_SECONDARY)
	printf("Secondory ");
    if (flags & IFA_F_NODAD)
	printf("NoDAD ");
    if (flags & IFA_F_OPTIMISTIC)
	printf("Optimistic ");
    if (flags & IFA_F_HOMEADDRESS)
	printf("Home ");
    if (flags & IFA_F_DEPRECATED)
	printf("Deprecated ");
    if (flags & IFA_F_TENTATIVE)
	printf("Tentative ");
    if (flags & IFA_F_PERMANENT)
	printf("Permanent ");
}

struct ni_linux_iface {
    char	devname[20];
    char	chp[8][5];
#if LOCAL_SIZEOF_POINTER == 8
    char	_pad[4];
#endif			/* align 64 bit host	*/
    int		plen;
    int		scope;
    int		dad;
    int		idx;
};

/* ********************************************	*
 *	return n * the sizeof above structure	*
 *	blocks of info about /proc/net/if_net6	*
 *	    this memory must be free(d)		*
 * ********************************************	*/
 
/*      				     plen
					idx   scp flgs
	00000000000000000000000000000001 01 80 10 80       lo  
	fe8000000000000002a0ccfffe26d380 02 40 20 80     eth0
 */

static struct ni_linux_iface *
lx_get_addr()
{
    FILE * fd;
    int n = 1;
    struct ni_linux_iface * net6, * origin = NULL;
	
    if ((fd = fopen(_PATH_PROCNET_IFINET6, "r")) == NULL)
	return NULL;

    if ((origin = net6 = calloc(1,sizeof(struct ni_linux_iface))) == NULL)
	goto lxga_error0;

    while (fscanf(fd, "%4s%4s%4s%4s%4s%4s%4s%4s %02x %02x %02x %02x %20s\n",
	net6->chp[0], net6->chp[1], net6->chp[2], net6->chp[3],
	net6->chp[4], net6->chp[5], net6->chp[6], net6->chp[7],
	&net6->idx, &net6->plen, &net6->scope, &net6->dad, net6->devname) != EOF)
    {
	n++;
	if ((net6 = realloc(origin, n * sizeof(struct ni_linux_iface))) == NULL) {
	    free(origin);
    lxga_error0:
	    errno = ENOMEM;
	    return NULL;
	}
	origin = net6;
	net6 = origin + n -1;
	bzero(net6,sizeof(struct ni_linux_iface));	
    }
    fclose(fd);
    return origin;
}

/* ****************************************************	*
 *	text buffout xx::xx:xx, ary(xxxx),(xxxx)	*
 * ****************************************************	*/

static void
lx_hex2txt(char * txt, char (*chp)[5])
{
    sprintf(txt,"%s:%s:%s:%s:%s:%s:%s:%s",
	chp[0], chp[1], chp[2], chp[3],
	chp[4], chp[5], chp[6], chp[7]);
}

static int
lx_gifaddrs_solo(struct ifaddrs **ifap)
{
    struct ifaddrs * thisif, * lastif = NULL;
    struct ni_linux_iface * lxifc, * nxifc;
    struct sockaddr_in6 * sin6;
    char hostaddr[40];

    if ((nxifc = lxifc = lx_get_addr()) == NULL)
    	return -1;

    *ifap = NULL;
    
    while (nxifc->devname[0] != '\0') {
        if ((thisif =  calloc(1, sizeof(struct ifaddrs))) == NULL) {
  error_out:
            ni_freeifaddrs(*ifap);
	    free(lxifc);
            errno = ENOMEM;
            return -1;
        }

	if (lastif == NULL)
	    *ifap = thisif;
	else
	    lastif->ifa_next = thisif;

	if ((thisif->ifa_name = strdup(nxifc->devname)) == NULL) {
  error_out2:
	    ni_freeifaddrs(thisif);
	    goto error_out;
	}
	if ((sin6 = calloc(1, sizeof(struct sockaddr_in6))) == NULL)
	    goto error_out;
	sin6->sin6_family = AF_INET6;
#ifdef HAVE_SA_LEN
	sin6->sin6_len = LOCAL_SIZEOF_SOCKADDR_IN6;
#endif
	lx_hex2txt(hostaddr,nxifc->chp);
	inet_pton(AF_INET6,hostaddr,&sin6->sin6_addr);
	sin6->sin6_scope_id = ni_lx_type2scope(nxifc->scope);
	thisif->ifa_addr = (struct sockaddr * )sin6;

	thisif->ifa_flags = lxifc->scope;			/* what is supposed to go in here??	*/	
	if ((sin6 = calloc(1, sizeof(struct sockaddr_in6))) == NULL)
	    goto error_out2;
	sin6->sin6_family = AF_INET6;
	ni_plen2mask(&sin6->sin6_addr,nxifc->plen,sizeof(struct in6_addr));
	thisif->ifa_netmask = (struct sockaddr *)sin6;
	lastif = thisif;
	nxifc++;
    }
    free(lxifc);
    return 0;
}

/*	unlink ifap6 ifaddr records and link them into thisif	*/
static void
lx_relink(struct ifaddrs * this6, struct ifaddrs * last6, struct ifaddrs ** ifap6, struct ifaddrs * thisif)
{
    if (last6 == *ifap6)
    	*ifap6 = this6->ifa_next;
    else
        last6->ifa_next = this6->ifa_next;
    if (thisif == NULL)		/* no data ptr	*/
        this6->ifa_next == NULL;
    else {
	this6->ifa_next = thisif->ifa_next;
	thisif->ifa_next = this6;	/* insert record */
    }
}

/* ********************************************	*
 * 	if we get to here there is not another	*
 *	way to ipv6 data except from the proc	*
 *	file system. that means that only ifreq	*
 *	is functional for obtaining ipv4	*
 * ********************************************	*/

static int
lx_gifaddrs_merge(struct ifaddrs **ifap, struct ni_ifconf_flavor * nifp)
{
    struct ifaddrs * thisif, * lastif, * ifap6, * this6, *last6;
    struct ni_linux_iface * lxifc, * nxifc;
    u_int flags;
    char lastname[IFNAMSIZ];
    struct ifreq ifr;
    u_char * macp;
    int fd, err;

    if ((nifp = ni_ifcf_get(NI_IFREQ)) == NULL)	/* should never happen	*/
	return -1;
    if (nifp->gifaddrs(ifap,nifp) < 0)		/* ipv4 retrieval fail	*/
	return -1;
    if (lx_gifaddrs_solo(&ifap6) < 0) {
  merge_fatal0:
	err = errno;
  merge_fatal:
	ni_freeifaddrs(*ifap);
	errno = err;
	return -1;
    }
/* 	need to merge data	*/
    if (ifap6 == NULL)
        return NI_IFREQ;		/* there is no ipV6 data, no need to merge, return flavor */
    thisif = *ifap;
    if (thisif == NULL)			/* there was no ipV4 data */
        goto wrap_up_ipv6;

    while (1) {
	if (thisif->ifa_next == NULL ||
	    strncmp(thisif->ifa_name,(thisif->ifa_next)->ifa_name,IFNAMSIZ)) {
	    last6 = this6 = ifap6;
	    while (this6 != NULL) {
	    	if (this6->ifa_name != NULL && strncmp(thisif->ifa_name,this6->ifa_name,IFNAMSIZ) == 0)
		    lx_relink(this6,last6,&ifap6,thisif);
		last6 = this6;
		this6 = this6->ifa_next;
	    }
	}
	if ((thisif->ifa_next) == NULL)
	    break;
	thisif = thisif->ifa_next;
    }
  wrap_up_ipv6:
    if (thisif == NULL)
        *ifap = ifap6;
    else
        thisif->ifa_next = ifap6;

    return NI_LINUXPROC;
}

static int
lx_INET6_get_addr()
{
    struct ni_linux_iface * net6, * origin;
    int flags;
    u_int32_t xscope;
    struct in6_addr in6p;
    char hostaddr[40];
	
    if ((origin = net6 = lx_get_addr()) == NULL)
	return -1;

    while (net6->devname[0] != '\0') {
	printf("%s\t",net6->devname);
	lx_hex2txt(hostaddr,net6->chp);
	printf("%s/%d",hostaddr,net6->plen);
	flags = net6->dad;
	printf("\n\tflags=%0x<",flags);
	lx_ifa_f_flags(flags);
	if (flags == 0)
	    printf(" ");
	inet_pton(AF_INET6,hostaddr,&in6p);
	xscope = ni_in6_classify((u_char *)&in6p);
	printf("\b> Scope: ");
/*	ni_linux_scope2txt((uint32_t)(net6->scope & IPV6_ADDR_SCOPE_MASK));	*/
	ni_linux_scope2txt((uint32_t)(xscope));
	printf("\n");
	net6++;
    }
    free(origin);
    return 0;
}

static int
lx_get_solo()
{
    struct ifaddrs * ifap;
    
    if (lx_gifaddrs_solo(&ifap) != 0)
	return -1;
    ni_getifaddrs_dump(NI_LINUXPROC,ifap);
    ni_freeifaddrs(ifap);
    return 0;
}

int
static ni_flav_linuxproc_developer(void * ifcee)
{
    if (lx_INET6_get_addr() != 0)
        return -1;
    printf("\n");
    if (lx_get_solo() != 0)
        return -1;
    return 0;
}

static void * returnull() { return NULL; }

static struct ni_ifconf_flavor ni_flavor_linuxproc = {
    .ni_type		= NI_LINUXPROC,
    .siocgifindex	= SIOCGIFINDEX,
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
    .gifaddrs		= lx_gifaddrs_merge,
    .fifaddrs		= ni_freeifaddrs,
    .refreshifr		= NULL,
    .getifreqs		= returnull,
    .developer		= ni_flav_linuxproc_developer,
};

void
ni_linuxproc_ctor()
{
    struct stat not_used;
    int error, retry = 2;

/*	check for 'proc' file system available	*/
    while (retry > 0) {
      if ((error = stat("/proc",&not_used)) == 0) {
          ni_ifcf_register(&ni_flavor_linuxproc);
          break;
      }
      else if (error != EINTR)
          return;
      error -= 1;
    }
}

#else

void
ni_linuxproc_ctor()
{
    return;
}

#endif	/*	__ni_Linux	*/
