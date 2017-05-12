
/* ********************************************************************	*
 * ni_getifaddrs.c	version 0.02	1-12-09				*
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

SYNOPSIS

     int
     ni_getifaddrs(struct ifaddrs **ifap);

     void
     ni_freeifaddrs(struct ifaddrs *ifp);

DESCRIPTION
     The getifaddrs() function stores a reference to a linked list of the
     network interfaces on the local machine in the memory referenced by ifap.
     The list consists of ifaddrs structures, as defined in the include file
     <ifaddrs.h>.  The ifaddrs structure contains at least the following
     entries:

         struct ifaddrs   *ifa_next;         Pointer to next struct
         char             *ifa_name;         Interface name
         u_int             ifa_flags;        Interface flags
         struct sockaddr  *ifa_addr;         Interface address
         struct sockaddr  *ifa_netmask;      Interface netmask
         struct sockaddr  *ifa_dstaddr;      P2P interface destination (broadcast)
         void             *ifa_data;         Address specific data

     The ifa_next field contains a pointer to the next structure on the list.
     This field is NULL in last structure on the list.

     The ifa_name field contains the interface name.

     The ifa_flags field contains the interface flags, as set by the ifconfig
     utility.

     The ifa_addr field references either the address of the interface or the
     link level address of the interface, if one exists, otherwise it is NULL.
     (The sa_family field of the ifa_addr field should be consulted to
     determine the format of the ifa_addr address.)

     The ifa_netmask field references the netmask associated with ifa_addr,
     if one is set, otherwise it is NULL.

     The ifa_broadaddr field, which should only be referenced for non-P2P
     interfaces, references the broadcast address associated with ifa_addr,
     if one exists, otherwise it is NULL.

     The ifa_dstaddr field references the destination address on a P2P
     interface, if one exists, otherwise it is NULL.

     The ifa_data field references address family specific data.  For AF_LINK
     addresses it contains a pointer to the struct if_data (as defined in
     include file <net/if.h>) which contains various interface attributes and
     statistics.  For all other address families, it contains a pointer to the
     struct ifa_data (as defined in include file <net/if.h>) which contains
     per-address interface statistics.

     The data returned by getifaddrs() is dynamically allocated and should be
     freed using freeifaddrs() when no longer needed.

RETURN VALUES
     The getifaddrs() function returns the value 0 if successful; otherwise
     the value -1 is returned and the global variable errno is set to indicate
     the error.

IMPLEMENTATION NOTES

 *
 *
 */
#include "localconf.h"

/* we fill it, we have to clear it	*/
void
ni_freeifaddrs(struct ifaddrs *ifap)
{
    struct ifaddrs * me;

    if (ifap == NULL)
        return;
/*
 *	bsd & linux do not iterate through the link list they just do a
 * 	free(pointer). Apparently all the elements are allocated from the
 *	same chunk of memory. solaris does the same as we do more or less
 */

    while (ifap != NULL) {
	free(ifap->ifa_name);
	free(ifap->ifa_addr);
	free(ifap->ifa_netmask);
	free(ifap->ifa_dstaddr);
	free(ifap->ifa_data);
	me = ifap;
	ifap = ifap->ifa_next;
	free(me);
    }
}

void
ni_free_gifa(struct ifaddrs * ifap, int flavor)
{
    if (flavor)
        ni_freeifaddrs(ifap);
    else
        freeifaddrs(ifap);
}

int
ni_getifaddrs(struct ifaddrs **ifap, int flavor)
{
    struct ni_ifconf_flavor * nifp;
    int rv;
    
    if (flavor != 0) {		/* if testing, go to specific routine	*/
	if ((nifp = ni_ifcf_get(flavor)) == NULL)
	    return -1;
	else {
	    return nifp->gifaddrs(ifap,nifp);
	}
    }

#ifdef HAVE_IFADDRS_H

    return getifaddrs(ifap);
}
#else

/*	this decision tree should be updated when new AF_XXX families are
 *	are added and/or new flavors of 'ifreq' are encountered or updated
 *
 *	the decision tree is a combination of compile time #ifdef's and
 *	run time if's that depend on the response of the underlying OS
 *
 *	examples:  	older Solaris systems have lifreq but it does not 
 *			appear to be implemented. the decision tree attempts
 *			to use it and uses the soft fail to try other 
 *			methods to satisfy the request. Linux has a struct 
 *			in6_ifreq that is nothing like the BSD version and
 *			does not respond to SIOCxxx requests.
 */
# ifdef __ni_Linux

    if ((nifp = ni_ifcf_get(NI_LINUXPROC)) == NULL)
    	return -1;		/* this should never happen	*/

# elif defined HAVE_STRUCT_LIFREQ

/*	several OS's have this, not sure how they all work	*/
    if ((nifp = ni_ifcf_get(NI_LIFREQ)) == NULL)
	goto fallback;
	
# elif defined HAVE_STRUCT_IN6_IFREQ

/*	several variants of this flavor				*/
    if ((nifp = ni_ifcf_get(NI_IN6_IFREQ)) == NULL)
	goto fallback;

# endif

    if ((rv = nifp->gifaddrs(ifap,nifp)) != -1)
	return rv;

  fallback:	/* supports ipV4 only	*/
    if ((nifp = ni_ifcf_get(NI_IFREQ)) == NULL)
	return -1;		/* this should never happen	*/

    return nifp->gifaddrs(ifap,nifp);
}
	    
#endif	/* ! have getifaddrs	*/

/*	byte pointer, byte count	*/
static void
xx_printbytes(u_char * cp,int cnt)
{
    int i = 0;

    while (i < cnt) {
	printf("%02X ",cp[i]);
	i++;
    }
    printf("\n");
}

void
ni_getifaddrs_dump(int flavor, struct ifaddrs * ifap)
{
    u_int af, sz, i, n, mtu, metric, fd, prefix;
    u_int64_t flags;
    u_int32_t xscope;
    struct sockaddr_in sin;
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
    struct sockaddr_in6 * sin6;
#endif
#ifdef LOCAL_SIZEOF_SOCKADDR_DL
    struct sockaddr_dl * sadl;
#elif defined LOCAL_SIZEOF_SOCKADDR_LL
    struct sockaddr_ll *sall;
#endif
#ifdef HAVE_STRUCT_LIFREQ
    struct lifreq lifr;
#endif
    char hostaddr[40];
    u_char * macp;
    struct ifreq ifr;
    struct ni_ifconf_flavor * nifp = ni_ifcf_get(flavor);
    struct if_data * ifi;

#include "ni_IFF_inc.c"
#include "ni_SMI-NUMBERS.c"

    while (1) {
         flags = (u_int64_t)ifap->ifa_flags;
#ifdef HAVE_STRUCT_LIFREQ
        strlcpy(lifr.lifr_name,ifap->ifa_name,IFNAMSIZ);
        if ((fd = socket(AF_INET,SOCK_DGRAM,0)) < 0)
            goto no_xflags;
        if (ioctl(fd,nifp->siocgifflags,&lifr) != -1)
            flags = (u_int64_t)lifr.lifr_flags;
        close(fd);
    no_xflags:
#endif
	af = ifap->ifa_addr->sa_family;
	printf("%s\taf %d ",ifap->ifa_name,af);

	if (af == AF_INET) {

    	    printf("flags=%0llx<",flags);
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
	    if ((fd = socket(AF_INET,SOCK_DGRAM,0)) >= 0) {
		strlcpy(ifr.ifr_name,ifap->ifa_name,IFNAMSIZ);
		if ((mtu = ni_get_any(fd,nifp->siocgifmtu,&ifr)) < 0)
		    mtu = 0;
		strlcpy(ifr.ifr_name,ifap->ifa_name,IFNAMSIZ);
		if ((metric = ni_get_any(fd,nifp->siocgifmetric,&ifr)) < 0)
		    metric = 0;
		else if (metric == 0)
		    metric = 1;
		if (mtu)
		    printf("mtu %d ",mtu);
		if (metric)
		    printf("metric %d ",metric);

		strlcpy(ifr.ifr_name,ifap->ifa_name,IFNAMSIZ);
		close(fd);
		if ((macp = ni_fallbackhwaddr(af,&ifr)) != NULL) {
		    printf("\n\t");
		    NI_PRINT_MAC(macp);
                }
	    }
	    printf("\n");
	    printf("\taddr: %s ",inet_ntoa(((struct sockaddr_in *)ifap->ifa_addr)->sin_addr));
	    if (ifap->ifa_netmask != NULL)
		printf("mask %s ",inet_ntoa(((struct sockaddr_in *)ifap->ifa_netmask)->sin_addr));
	    if (ifap->ifa_dstaddr != NULL) {
	        if (flags & IFF_POINTOPOINT)
	            printf("dst ");
	        else if (flags & IFF_BROADCAST)
	            printf("brd ");
	        else
	            printf("ukn ");
		printf("%s ",inet_ntoa(((struct sockaddr_in *)ifap->ifa_dstaddr)->sin_addr));
	    }
            printf("\n");
	}
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
	else if (af == AF_INET6) {

/* throw away scope to correct the extra bits in the address for KAME	*/
	    (void) ni_get_scopeid((struct sockaddr_in6 *)ifap->ifa_addr);
/* calculate scope	*/
	    xscope = ni_in6_classify((u_char *)&((struct sockaddr_in6 *)ifap->ifa_addr)->sin6_addr);
	    printf("type=%04x<",xscope);
	    ni_linux_scope2txt(xscope);
	    if (xscope == 0)
	    	printf(" ");
	    printf("\b>\n");

	    inet_ntop(AF_INET6,&((struct sockaddr_in6 *)ifap->ifa_addr)->sin6_addr,hostaddr,LOCAL_SIZEOF_SOCKADDR_IN6);
	    printf("\taddr : %s",hostaddr);
	    if (ifap->ifa_netmask != NULL) {
		prefix = ni_prefix(&((struct sockaddr_in6 *)ifap->ifa_netmask)->sin6_addr,sizeof(struct in6_addr));
		printf("/%d",prefix);
	    }
	    printf("\n");
	    if (ifap->ifa_dstaddr != NULL) {
		inet_ntop(AF_INET6,&((struct sockaddr_in6 *)ifap->ifa_dstaddr)->sin6_addr,hostaddr,LOCAL_SIZEOF_SOCKADDR_IN6);
		printf("\tdest : %s\n",hostaddr);
	    }
	}
#endif
#ifdef LOCAL_SIZEOF_SOCKADDR_DL
	else if (af == AF_LINK) {
	    printf("\n");
	    if (ifap->ifa_addr != NULL) {
		sadl = (struct sockaddr_dl *)ifap->ifa_addr;
                macp = (unsigned char *)(sadl->sdl_data + sadl->sdl_nlen);
		if (NI_MAC_NOT_ZERO(macp)) {
		    printf("\t");
		    NI_PRINT_MAC(macp);
		    printf("\n");
                }
	    }
# ifdef KILL_ALL_CODE_save_for_postarity
	    if (ifap->ifa_netmask != NULL) {
	    	printf("\tlmask : ");
	    	xx_printbytes((u_char *)ifap->ifa_netmask,64);
	    }
	    if (ifap->ifa_dstaddr != NULL) {
	    	printf("\tldest : ");
	    	xx_printbytes((u_char *)ifap->ifa_dstaddr,64);
	    }
# endif
	}
#elif defined LOCAL_SIZEOF_SOCKADDR_LL
	else if (af == AF_PACKET) {
	    printf("\n");
	    if (ifap->ifa_addr != NULL) {
	        sall = (struct sockaddr_ll *)ifap->ifa_addr;
	        macp = (unsigned char *)sall->sll_addr;
		if (NI_MAC_NOT_ZERO(macp)) {
		    printf("\t");
		    NI_PRINT_MAC(macp);
		    printf("\n");
                }
            }
# ifdef KILL_ALL_CODE_save_for_postarity
            if (ifap->ifa_addr != NULL) {
                printf("\tpaddr : ");
                xx_printbytes((u_char *)ifap->ifa_addr,64);
            }
# endif
	}
#endif
	if ((ifap = ifap->ifa_next) == NULL)
	    break;
    }
}
