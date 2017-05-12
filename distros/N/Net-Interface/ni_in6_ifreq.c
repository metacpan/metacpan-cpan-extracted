
/* ********************************************************************	*
 * ni_in6_ifreq.c	version 0.06	3-7-09				*
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

#include "localconf.h"

#if !defined (__ni_Linux) && defined (HAVE_STRUCT_IN6_IFREQ)

static void *
_ni_getifreqs(int fd, void * vifc)
{
    int n,size;
    struct ifconf * ifc = vifc;
    void * ifr;

    bzero(ifc,sizeof(struct ifconf));

# ifdef SIOCGIFCOUNT

    if (ioctl(fd, SIOCGIFCOUNT, ifc) != -1) {
	size = ifc->ifc_len * sizeof(struct ifreq);
	ifr = malloc(size);
	if (ifr == NULL) {
	    errno = ENOMEM;
	    return NULL;
	}
	ifc->ifc_req = ifr;
	ifc->ifc_len = size;
/* Solaris returns EINVAL for small buffer	*/
	if (ioctl (fd, SIOCGIFCONF, ifc) < 0) {
	    free (ifr);
	    return NULL;
	}
    }
    else

# endif

    {
	n = 2;
    /* New (0xbad, ifr, n, PAGE_SIZE); */
	ifr = ifc->ifc_req;
	while (1) {
	    ifr = realloc(ifr, n * PAGE_SIZE );
	    if (ifr == NULL) {
		free(ifc->ifc_req);
		errno = ENOMEM;
      		return NULL;
	    }
	    ifc->ifc_req = ifr;
	    size = n * PAGE_SIZE;
	    ifc->ifc_len = size;
	    if (ioctl( fd, SIOCGIFCONF, ifc ) < 0) {
		free (ifr);
		return NULL;
	    }
	    if (ifc->ifc_len < size - PAGE_SIZE)	/* (n-1) * PAGE_SIZE */
		break;
	    n *= 2;
	}
    }
    return ifr;
}

/* returns flags6 or -1	*/
static int
ni_getflags6(struct nifreq * ifr, int fd)
{
# ifndef SIOCGLIFADDR

    struct in6_ifreq ifr6;

    memcpy(&ifr6,ifr,IFNAMSIZ + LOCAL_SIZEOF_SOCKADDR_IN6);	/* copy name & family	*/
/*    ifr6.ifr_ifru.ifru_addr; */
    if (ioctl(fd,SIOCGIFAFLAG_IN6,&ifr6) < 0) {
        printf("gf6er fd %d, e %d, %s\n",fd,errno,strerror(errno));
        return -1;
    }
    else
        return ifr6.ifr_ifru.ifru_flags6;
    
# else

    struct sockaddr_in6 * sin6;
    struct if_laddrreq iflr;
    
    bzero(&iflr,sizeof(struct if_laddrreq));
    strlcpy(iflr.iflr_name,ifr->ni_ifr_name,IFNAMSIZ);
    iflr.prefixlen = 1;
    iflr.flags = IFLR_PREFIX;
    sin6 = (struct sockaddr_in6 *)&iflr.addr;    
    sin6->sin6_family = AF_INET6;
    sin6->sin6_len = LOCAL_SIZEOF_SOCKADDR_IN6;
    sin6->sin6_addr.s6_addr[0] = 0xFEu;	/* hardcode per UNIX WIDE, don't want alias */
    sin6->sin6_addr.s6_addr[1] = 0x80u;
    if ((ioctl(fd,SIOCGLIFADDR,&iflr)) < 0) {	/* EADDRNOTAVAIL - unsupported	*/
/*        printf("glifa %d, e %d, %s\n",fd,errno,strerror(errno));	*/
        return -1;
    }
    else
        return iflr.flags;

# endif	/* ndef SIOCGLIFADDR	*/

}

int
ni_flav_in6_ifreq_developer(void * ifcee)
{
/*	ifcee unused	*/
    int i, n, fd, inc, af, prefix, addr6good, lifetgood;
    u_int64_t flags;
    struct ifconf ifc;
    struct nifreq *ifr, *lifr;
    struct sockaddr_dl * sadl;
    struct sockaddr_in6 copy6;
    unsigned char * macp;
    char namebuf[NI_MAXHOST];
    unsigned int scopeid;
    struct in6_addrlifetime lifetime;
    time_t t = time(NULL);
    struct ni_ifconf_flavor * nifp = ni_ifcf_get(NI_IN6_IFREQ);
    
#include "ni_IFF_inc.c"

    if ((fd = socket(AF_INET,SOCK_DGRAM,0)) < 0)
    	return errno;

    if (_ni_getifreqs(fd,&ifc) == NULL) {
	close(fd);
	return errno;
    }
    ifr = (struct nifreq *)ifc.ifc_req;
    lifr = (struct nifreq *)&(ifc.ifc_buf[ifc.ifc_len]);
    while (ifr < lifr) {
        lifetgood = prefix = addr6good = 0;
        macp = NULL;
/* BSD pretty much assumes that SA_LEN is defined, if not fudge it	*/

        inc = ni_SIZEOF_ADDR_IFREQ((struct ifreq *)ifr,(&ifr->ni_saddr),sizeof(struct ifreq));
	af = ifr->ni_saddr.sa_family;

	printf("%s\t",ifr->ni_ifr_name);

	if (af == AF_INET) {
	    fd = ni_clos_reopn_dgrm(fd,af);

	    if (ioctl(fd, SIOCGIFFLAGS,ifr) < 0)
	        printf("Faf_inet SIOCGIFFLAGS ");
            else {
		flags = ifr->ni_ushort;
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
	    }

	    if (ioctl(fd,SIOCGIFMETRIC,ifr) < 0)
	        printf("Faf_inet SIOCGIFMETRIC ");
            else
	    	printf("metric %d ",ifr->ni_int);

	    if (ioctl(fd,SIOCGIFMTU,ifr) < 0)
	        printf("Faf_inet SIOCGIFMTU ");
            else
	    	printf("mtu %d",ifr->ni_uint);
	    printf("\n\t");

	    if (ioctl(fd,SIOCGIFADDR,ifr) <0)
	        printf("Faf_inet SIOCGIFADDR ");
            else {
#ifdef HAVE_GETNAMEINFO
		if (getnameinfo(&ifr->ni_saddr,LOCAL_SIZEOF_SOCKADDR_IN,namebuf,NI_MAXHOST,NULL,0,NI_NUMERICHOST) != 0)
#endif
		    strcpy(namebuf,inet_ntoa(ifr->ni_sin.sin_addr));
	    	printf("address %s\t",namebuf);
	    }

	    if (ioctl(fd,SIOCGIFNETMASK,ifr) < 0)
	        printf("Faf_inet SIOCGIFNETMASK ");
            else 
		printf("mask 0x%lx\t",(unsigned long)ntohl(ifr->ni_sin.sin_addr.s_addr));

	    if (ioctl(fd,SIOCGIFBRDADDR,ifr) < 0)
	        printf("Faf_inet SIOCGIFBRADDR ");
	    else
	    	printf("broadcast %s\t",inet_ntoa(ifr->ni_sin.sin_addr));
	}
	else if (af == AF_INET6) {
	    memcpy(&copy6,&ifr->ni_saddr,LOCAL_SIZEOF_SOCKADDR_IN6);
#define NI_RESTORE_COPYS memcpy(&ifr->ni_saddr,&copy6,LOCAL_SIZEOF_SOCKADDR_IN6)
            scopeid = ni_get_scopeid(&ifr->ni_sin6);
#ifdef HAVE_GETNAMEINFO
            if (getnameinfo(&ifr->ni_saddr,LOCAL_SIZEOF_SOCKADDR_IN6,namebuf,NI_MAXHOST,NULL,0,NI_NUMERICHOST) != 0)
#endif
                strcpy(namebuf,inet_ntop(AF_INET6,&ifr->ni_sin6.sin6_addr,namebuf,NI_MAXHOST));
            addr6good = 1;

	    fd = ni_clos_reopn_dgrm(fd,af);
	    if(fd < 0)
	        printf("bad socket\n");

            if (ioctl(fd,SIOCGIFNETMASK_IN6,ifr) < 0)
                printf("Fafinet6 Netmask %s\n",strerror(errno));
            else
                prefix = ni_prefix(&ifr->ni_sin6.sin6_addr,sizeof(struct in6_addr));

            NI_RESTORE_COPYS;
	    if (&nifp->refreshifr == NULL) {
	    	printf("REFRESH NOT AVAILABLE\n");
	    	errno = ENOSYS;
	    	return -1;
	    }
            if (nifp->refreshifr(fd,&ifc,(void **)&ifr,(void **)&lifr,nifp) < 0) {
                printf("REFRESH failed\n");
                return -1;
            }

            bzero(&lifetime,sizeof(struct in6_addrlifetime));
            if (ioctl(fd,SIOCGIFALIFETIME_IN6,ifr) < 0)
                printf("Fafinet6 LIFETIME %s\n",strerror(errno));
            else
                memcpy(&lifetime,&ifr->ni_lifetime,sizeof(struct in6_addrlifetime));

            NI_RESTORE_COPYS;
            if (nifp->refreshifr(fd,&ifc,(void **)&ifr,(void **)&lifr,nifp) < 0) {
                printf("REFRESH failed\n");
                return -1;
            }
/*            if ((flags = ni_getflags6(ifr,fd)) < 0) {		*/
           if (ioctl(fd,SIOCGIFAFLAG_IN6,ifr) < 0) {
                printf("flerr=<");
                flags = 0;
            }
            else
                printf("flags6=%0x<",flags);

/*            if (flags & IFF_UP)
                printf("UP ");
            else
	        printf("DOWN ");
 */
            n = sizeof(ni_iff_tabIN6) / sizeof(ni_iff_t);
            for (i=0;i<n;i++) {
                if (flags & ni_iff_tabIN6[i].iff_val)
                    printf("%s ",ni_iff_tabIN6[i].iff_nam);
            }
            if (flags == 0)
                printf(" ");
            printf("\b> ");

            if (scopeid) {
                scopeid &= 0xfu;
                printf("scopeid 0x%x ",scopeid);
                if (scopeid == RFC2373_NODELOCAL)
		    printf("IfaceLocal ");
                else if (scopeid == RFC2373_LINKLOCAL)
		    printf("LinkLocal ");
                else if (scopeid == RFC2373_SITELOCAL)
		    printf("SiteLocal ");
                else if (scopeid == RFC2373_GLOBAL)
		    printf("Global ");
		else if (scopeid == RFC2373_ORGLOCAL)
		    printf("OrgLocal ");
            }

            if (ioctl(fd,SIOCGIFMETRIC,ifr) < 0)
                printf("Faf_inet6 SIOCGIFMETRIC ");
            else
		printf("metric %d ",ifr->ni_int);

	    if (ioctl(fd,SIOCGIFMTU,ifr) < 0)
	        printf("Fafinet6 SIOCIFMTU ");
	    else
		printf("mtu %d",ifr->ni_int);

	    if (addr6good && prefix)
	        printf("\n\taddress %s/%d ",namebuf,prefix);

            if (lifetgood) {
                if (lifetime.ia6t_preferred || lifetime.ia6t_expire) {
                    printf("plt ");
                    if (lifetime.ia6t_preferred) {
                        if (lifetime.ia6t_preferred < t)
                            printf("0 ");
                        else
                            printf("%lu ",(lifetime.ia6t_preferred - t));
                    }
                    else
                        printf("inft ");

                    printf("vlt ");
                    if (lifetime.ia6t_expire) {
                        if (lifetime.ia6t_expire < t)
                            printf("0 ");
                        else
                            printf("%lu ",(lifetime.ia6t_expire - t));
                    }
                    else
                        printf("inft ");
                }
            }
        }
	else if (af == AF_LINK) {
	    sadl = (struct sockaddr_dl *)&(ifr->ni_saddr);
	    if (NI_MAC_NOT_ZERO((unsigned char *)(sadl->sdl_data + sadl->sdl_nlen)))
		macp = (unsigned char *)(sadl->sdl_data + sadl->sdl_nlen);
	}
        printf("\n\taf %d, sz %d ",af,inc);
        if (macp != NULL)
            NI_PRINT_MAC(macp);

	printf("\n");

	ifr = (struct nifreq *)(((char *)ifr) + inc);
    }
    close(fd);
    free(ifc.ifc_req);
    return 0;
}

static struct ni_ifconf_flavor ni_ifconf_flav_ni_ifreq = {
    .ni_type		= NI_IN6_IFREQ,
#ifdef SIOCGIFINDEX
    .siocgifindex	= SIOCGIFINDEX,
#else
    .siocgifindex	= 0,
#endif
    .siocsifaddr	= SIOCSIFADDR,
    .siocgifaddr	= SIOCGIFADDR,
# ifdef SIOCDIFADDR
    .siocdifaddr	= SIOCDIFADDR,
# else
    .siocdifaddr	= 0,
# endif
# ifdef SIOCAIFADDR
    .siocaifaddr	= SIOCAIFADDR,
# else
    .siocaifaddr	= 0,
# endif
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
    .refreshifr		= ni_refresh_ifreq,
    .getifreqs		= _ni_getifreqs,
    .developer		= ni_flav_in6_ifreq_developer,
};

void
ni_in6_ifreq_ctor()
{
    ni_ifcf_register(&ni_ifconf_flav_ni_ifreq);
}

#else
    
void
ni_in6_ifreq_ctor()
{
    return;
}

#endif	/* have in6_ifreq && ! __ni_Linux	  */
