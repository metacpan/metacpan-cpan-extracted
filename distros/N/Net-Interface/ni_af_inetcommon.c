
/* ********************************************************************	*
 * ni_af_inetcommon.c	version 0.03 2-27-09				*
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

static int
_ni_get_ifaddrs(int fd, struct ifaddrs * thisif, struct ni_ifconf_flavor * nifp, struct nifreq * ifr,...)
{
    int cmd;
    
    if (ioctl(fd,nifp->siocgifflags,ifr) < 0)
	return -1;
    thisif->ifa_flags = ifr->ni_ushort;

    if (ioctl(fd,nifp->siocgifnetmask,ifr) != -1) {
	if ((thisif->ifa_netmask = ni_memdup(&(ifr->ni_saddr),
				    SA_LEN((&ifr->ni_saddr)))) == NULL)
	    return -1;
    }
    if (thisif->ifa_flags & (IFF_POINTOPOINT | IFF_BROADCAST)) {
	if (thisif->ifa_flags & IFF_POINTOPOINT)
	    cmd = nifp->siocgifdstaddr;
	else
	    cmd = nifp->siocgifbrdaddr;

	if (ioctl(fd,cmd,ifr) != -1) {
	    if ((thisif->ifa_dstaddr = ni_memdup(&(ifr->ni_saddr),
					SA_LEN((&ifr->ni_saddr)))) == NULL)
		return -1;
	}
    }
    return 0;
}

/* ********************************************************************	*
 *	Not all OS's that use in6_ifreq are created equal, some	loose	*
 *	scope on the connection to info we want. These OS's require	*
 *	refresh. If the forth parameter (struct nifreq * ifr) is NULL	*
 *	then 'refresh' is needed for this particular OS and the args	*
 *	in the second line are valid and refresh should be called 	*
 *	after ioctl operations that retrieve address information	*
 * ********************************************************************	*/

#ifdef LOCAL_SIZEOF_SOCKADDR_IN6

static int
_ni_get_ifaddrs6(int fd, struct ifaddrs * thisif, struct ni_ifconf_flavor * nifp, struct nifreq * ifr,...)
{
/*	struct ifconf * ifc, void **oifr, void **olifr)	*/

    int cmd, needrefresh = 0;
    struct sockaddr_in6 copy6;
    struct ifconf * ifc;
    void ** oifr, ** olifr;
    va_list ap;

    va_start(ap,ifr);
    if (ifr == NULL) {		/* then refresh is required, second line args valid	*/
	needrefresh = 1;
	ifc	= (struct ifconf *)va_arg(ap,void *);
	oifr	= va_arg(ap,void **);
	olifr	= va_arg(ap,void **);
	ifr	= (struct nifreq *)*oifr;
    }
    va_end(ap);

#define NI_RESTORE_COPYS memcpy(&ifr->ni_saddr,&copy6,LOCAL_SIZEOF_SOCKADDR_IN6)
    if (needrefresh)
	memcpy(&copy6,&ifr->ni_saddr,LOCAL_SIZEOF_SOCKADDR_IN6);

    if (ioctl(fd,nifp->siocgifflags,ifr) < 0)
	return -1;

    thisif->ifa_flags = ifr->ni_ushort;

    if (needrefresh) {
	NI_RESTORE_COPYS;
	if (nifp->refreshifr(fd,ifc,oifr,olifr,nifp) < 0)
            return -1;
        else
            ifr = *oifr;
    }
/*	no support for tunnels yet	*/

    if (ioctl(fd,nifp->siocgifnetmask,ifr) != -1) {
	if ((thisif->ifa_netmask = ni_memdup(&(ifr->ni_saddr),
				    SA_LEN((&ifr->ni_saddr)))) == NULL) {
	    return -1;
       }
    }
    if (needrefresh) {
	NI_RESTORE_COPYS;
	if (nifp->refreshifr(fd,ifc,oifr,olifr,nifp) < 0) {
            return -1;
        }
        else
            ifr = *oifr;
    }

/* don't know about destinations, tunnels, etc... yet. Save this as a template
 *
 *   if (thisif->ifa_flags & (IFF_POINTOPOINT | IFF_BROADCAST)) {
 *	if (thisif->ifa_flags & IFF_POINTOPOINT)
 *	    cmd = SIOCGIFDSTADDR;
 *	else
 *	    cmd = SIOCGIFBRDADDR;
 *
 *	if (ioctl(fd,cmd,ifr) != -1) {
 *	    if ((thisif->ifa_dstaddr = ni_memdup(&(ifr->ni_saddr),
 *					SA_LEN((&ifr->ni_saddr)))) == NULL)
 *		return -1;
 *	}
 *   }
 */
    return 0;
}

#endif

/* ****************************************************	*
 * some OS lose scope on the particular device/addr	*
 * handle when certain ioctl's are performed. this	*
 * function refreshs the ifconf chain and positions	*
 * the pointers in the exact same spot with fresh scope	*
 * ****************************************************	*/

int
ni_refresh_ifreq(int fd, struct ifconf * ifc, void ** oifr, void ** olifr, struct ni_ifconf_flavor * nifp)
{
    unsigned char copy[sizeof(struct sockaddr_storage) + IFNAMSIZ];
    struct nifreq * ifr, * lifr, * cifr = (struct nifreq *)&copy;
    int af, inc;
/*    struct sockaddr_dl * sadl, * csadl;	*/

    inc = ni_SIZEOF_ADDR_IFREQ((struct ifreq *)*oifr,(&((struct nifreq *)*oifr)->ni_saddr),sizeof(struct ifreq));
    memcpy(cifr,*oifr,inc);			/* copy the current ifreq struct */
    if (ifc->ifc_req != NULL)
	free(ifc->ifc_req);			/* free the old buffer	*/
    if (nifp->getifreqs(fd,ifc) == NULL)
        return -1;				/* oh crap!	*/
        
    ifr = (struct nifreq *)(ifc->ifc_req);
    lifr = (struct nifreq *)&(ifc->ifc_buf[ifc->ifc_len]);
    for (; ifr < lifr; ifr = (struct nifreq *)(((char *)ifr) + inc)) {
        inc = ni_SIZEOF_ADDR_IFREQ((struct ifreq *)ifr,(&ifr->ni_saddr),sizeof(struct ifreq));
        if (strncmp(ifr->ni_ifr_name,cifr->ni_ifr_name,IFNAMSIZ))
            continue;
        if ((af = ifr->ni_saddr.sa_family) != cifr->ni_saddr.sa_family)
            continue;
        switch (af) {
        case AF_INET :
            if (memcmp(&cifr->ni_sin.sin_addr,&ifr->ni_sin.sin_addr,sizeof(struct in_addr)))
                continue;
            goto end_loop;
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
        case AF_INET6 :
            if (memcmp(&cifr->ni_sin6.sin6_addr,&ifr->ni_sin6.sin6_addr,sizeof(struct in6_addr)))
                continue;   
            goto end_loop;
#endif
#ifdef LOCAL_SIZEOF_SOCKET_DL
        case AF_LINK:
            break;
    	/* dangerous, don't want to do this	*/
        /*	MAC comparison			*/
/*
            csadl = (struct sockaddr_dl *)&(cifr->ni_saddr);
            sadl = (struct sockaddr_dl *)&(ifr->ni_saddr);
            if (memcmp((unsigned char *)(csadl->sdl_data + csadl->sdl_nlen),(unsigned char *)(sadl->sdl_data + sadl->sdl_nlen),6)
                goto end_loop;
 */
#endif
        default :		/* should never get here... this is bad	*/
                break;
	}
    }
    free(ifc->ifc_req);	/* we are in big trouble	*/
    return -1;

  end_loop:
    *olifr = lifr;
    *oifr = ifr;
    return inc;
}

/* ********************************************	*
 *   the semi-standard version of getifaddrs	*
 * ********************************************	*/

int
nifreq_gifaddrs(struct ifaddrs **ifap, struct ni_ifconf_flavor * nifp)
{
    struct ifconf ifc;
    struct nifreq * ifr, * lifr;
    struct ifaddrs * thisif, * lastif = NULL;
    struct sockaddr * sa;
    int fd, af, inc, ret, nop;
    
    *ifap = NULL;

    if ((fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
	return errno;

    if (nifp->getifreqs(fd,&ifc) == NULL) {
	close(fd);
	return errno;
    }
    ifr = (struct nifreq *)ifc.ifc_req;
    lifr = (struct nifreq *)&(ifc.ifc_buf[ifc.ifc_len]);

    while(ifr < lifr) {
	inc = ni_SIZEOF_ADDR_IFREQ((struct ifreq *)ifr,(&ifr->ni_saddr),sizeof(struct ifreq));

	if ((thisif = calloc(1, sizeof(struct ifaddrs))) == NULL) {
	    errno = ENOMEM;
	    goto error_out;
	}
	if (lastif == NULL) 	/* taken care of in init statement */
	    *ifap = thisif;
	else
	    lastif->ifa_next = thisif;

	if ((thisif->ifa_name = strdup(ifr->ni_ifr_name)) == NULL) {
	    errno = ENOMEM;
	    goto error_out;
	}

	af = ifr->ni_saddr.sa_family;
	if ((thisif->ifa_addr = ni_memdup(&(ifr->ni_saddr),
				    SA_LEN((&ifr->ni_saddr)))) == NULL)
	    goto error_out;

	if (af == AF_INET) {

            fd = ni_clos_reopn_dgrm(fd,af);
	    if (_ni_get_ifaddrs(fd,thisif,nifp, ifr) < 0)
	        goto error_out;

	}	/* == AF_INET	*/
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
	else if (af == AF_INET6) {

            fd = ni_clos_reopn_dgrm(fd,af);
	    if (&nifp->refreshifr == NULL)	/* then no refresh needed */
		nop = _ni_get_ifaddrs(fd,thisif,nifp,ifr);
	    else
	    	nop = _ni_get_ifaddrs6(fd,thisif,nifp,NULL,&ifc,&ifr,&lifr);
	    if (nop < 0)
	        goto error_out;

	}	/* == AF_INET6	*/
#endif
/*	for AF_LINK, AF_PACKET nothing is used except the contents of the addr record	*/

	lastif = thisif;
	ifr = (struct nifreq *)(((char *)ifr) + inc);
    }
    close(fd);
    free(ifc.ifc_req);		/* free ifreq	*/
    return nifp->ni_type;	/* return family type */

  error_out:
    ret = errno;	/* preserve errno	*/
    if (ret == 0)
      ret = EPERM;
    free(ifc.ifc_req);
    ni_freeifaddrs(*ifap);
    close(fd);
    *ifap = NULL;
    errno = ret;
    return -1;
}
