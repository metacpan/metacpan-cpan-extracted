
/* ********************************************************************	*
 * ni_fixups.h	version 0.02 2-25-09					*
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

#ifndef _NI_FIXUPS_H
#define _NI_FIXUPS_H 1

#ifndef HAVE_CADDR_T
#error 'caddr_t' undefined on this platform
#endif

/* **************************************************** *
 *	if this OS has buggy memory allocation, fix it	*
 * **************************************************** */

#if HAVE_MALLOC == 0 || HAVE_REALLOC == 0

#undef malloc
#undef calloc
#undef realloc
#undef free

void * ni_rpl_malloc();
void * ni_rpl_calloc();
void * ni_rpl_realloc();
void ni_rpl_free();

#define malloc ni_rpl_malloc
#define calloc ni_rpl_calloc
#define realloc ni_rpl_realloc
#define free ni_rpl_free

#warning FUNCTIONS calloc, malloc, realloc, free re-defined because of buggy C lib

#endif	/* HAVE_MALLOC == 0 || HAVE_REALLOC == 0	*/

/* **************************************************** *
 *	If field sa_len is missing and there is		*
 *	no OS supplied work-around, do it here		*
 * **************************************************** */

#ifndef SA_LEN
# ifndef HAVE_SA_LEN
static int
__libc_sa_len (const sa_family_t af)
{
   switch(af)
   {
#   ifdef LOCAL_SIZEOF_SOCKADDR_IN
    case AF_INET:
	return LOCAL_SIZEOF_SOCKADDR_IN;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_AT
    case AF_APPLETALK:
	return LOCAL_SIZEOF_SOCKADDR_AT;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_ASH
    case AF_ASH:
	return LOCAL_SIZEOF_SOCKADDR_ASH;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_X25
    case AF_X25:
	return LOCAL_SIZEOF_SOCKADDR_X25;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_EC
    case AF_ECONET:
	return LOCAL_SIZEOF_SOCKADDR_EC;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_IN6
    case AF_INET6:
	return LOCAL_SIZEOF_SOCKADDR_IN6;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_IPX
    case AF_IPX:
	return LOCAL_SIZEOF_SOCKADDR_IPX;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_UN
    case AF_LOCAL:		/* also AF_UNIX, AF_FILE */
	return LOCAL_SIZEOF_SOCKADDR_UN;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_LL
    case AF_PACKET:
	return LOCAL_SIZEOF_SOCKADDR_LL;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_ROSE
    case AF_ROSE:
	return LOCAL_SIZEOF_SOCKADDR_ROSE;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_DL
    case AF_LINK:
	return LOCAL_SIZEOF_SOCKADDR_DL;
#   endif
/*	This one is the same as AF_INET
 * #ifdef LOCAL_SIZEOF_SOCKADDR_INARP
 *   case AF_
 *	return LOCAL_SIZEOF_SOCKADDR_INARP;
 * #endif
 */
/*	Multiple socket families use ISO, some conflict	*/
#   ifdef LOCAL_SIZEOF_SOCKADDR_ISO
    case AF_ISO:
	return LOCAL_SIZEOF_SOCKADDR_ISO;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_TP
    case AF_ISO:
	return LOCAL_SIZEOF_SOCKADDR_TP;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_EON
    case AF_ISO:
	return LOCAL_SIZEOF_SOCKADDR_EON;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_OSITP
    case AF_ISO:
	return LOCAL_SIZEOF_SOCKADDR_OSITP;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_NS
    case AF_NUTSS:
	return LOCAL_SIZEOF_SOCKADDR_NS;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_AX25
    case AF_AX25:
	return LOCAL_SIZEOF_SOCKADDR_AX25;
#   endif
#   ifdef LOCAL_SIZEOF_SOCKADDR_DECnet
    case AF_DECnet:
	return LOCAL_SIZEOF_SOCKADDR_DECnet;
#   endif
   }
   return 0;
}
# define SA_LEN(sa) __libc_sa_len((sa)->sa_family)
# else
# define SA_LEN(sa) ((sa)->sa_len)
# endif
#endif

/* **************************************************** *
 * If the OS does not supply _SIZE_OF_ADDR_IFREQ use	*
 * this universal model for ifreq, in6_ifreq, lifreq	*
 * **************************************************** */

#ifdef _SIZEOF_ADDR_IFREQ

int
ni_SIZEOF_ADDR_IFREQ(struct ifreq * ifrp,struct sockaddr * sa,int size);

#else
#define ni_SIZEOF_ADDR_IFREQ(ifr,sa,size) \
	(SA_LEN(sa) > sizeof(struct sockaddr) ? \
	size - sizeof(struct sockaddr) + SA_LEN(sa) : size)
#endif

/* **************************************************** *
 *    If local libc does not have 'strlcpy', 'memcmp'	*
 *    some openbsd / sparc systems are missing memcmp,	*
 *    strlcpy is missing in a lot of places		*
 * **************************************************** */

#ifndef HAVE_STRLCPY
#include "ni_strlcpy.h"
#endif

#ifndef HAVE_MEMCMP
#include "ni_memcmp.h"
#endif

/* **************************************************** *
 *	define if_data if it is missing			*
 * **************************************************** */

#ifndef HAVE_STRUCT_IF_DATA

#define   LINK_STATE_UNKNOWN      0       /* link invalid/unknown */
#define   LINK_STATE_DOWN         1       /* link is down */
#define   LINK_STATE_UP           2       /* link is up */

/* ************************************************************	*
 * Structure describing information about an interface		*
 * which may be of interest to management entities.		*
 *								*
 *	THIS STRUCT IS INCOMPLETE, INSTATNIATE WITH CARE	*
 * ************************************************************	*/

struct if_data {
        /* generic interface information */
        u_char  ifi_type;               /* ethernet, tokenring, etc */
        u_char  ifi_physical;           /* e.g., AUI, Thinnet, 10base-T, etc */
        u_char  ifi_addrlen;            /* media address length */
        u_char  ifi_hdrlen;             /* media header length */
        u_char  ifi_link_state;         /* current link state */
        u_char  ifi_spare_char1;        /* spare byte */
        u_char  ifi_spare_char2;        /* spare byte */
        u_char  ifi_datalen;            /* length of this data struct */
        u_long  ifi_mtu;                /* maximum transmission unit */
        u_long  ifi_metric;             /* routing metric (external only) */
        u_long  ifi_baudrate;           /* linespeed */
/* ************************************************************	*
 * 	incomplete -- this struct is longer but the remaining	*
 *	data is volitile and we will never use it, thus 	*
 *	we don't need to know for this application.		*
 * ************************************************************	*/
};

#endif	/* HAVE_STRUCT_IF_DATA	*/
 
/* **************************************************** *
 *	define getifaddrs if the OS does not have one	*
 * **************************************************** */
 
#ifndef HAVE_IFADDRS_H

/*	some of the structure members have names
 *	that conflict with definitions in <net/if.h>
 *	for "struct ifaddr", don't need those here...
 */

#   ifdef ifa_next
#   undef ifa_next
#   endif
#   ifdef ifa_name
#   undef ifa_name
#   endif
#   ifdef ifa_flags
#   undef ifa_flags
#   endif
#   ifdef ifa_addr
#   undef ifa_addr
#   endif
#   ifdef ifa_netmask
#   undef ifa_netmask
#   endif
#   ifdef ifa_dstaddr
#   undef ifa_dstaddr
#   endif
#   ifdef ifa_data
#   undef ifa_data
#   endif

struct ifaddrs {
	struct ifaddrs  *ifa_next;
	char		*ifa_name;
	u_int		 ifa_flags;
	struct sockaddr	*ifa_addr;
	struct sockaddr	*ifa_netmask;
	struct sockaddr	*ifa_dstaddr;
	void		*ifa_data;
};

#endif 	/* not defined HAVE_IFADDRS_H	*/

void
ni_freeifaddrs(struct ifaddrs *ifp);

#ifndef HAVE_IFADDRS_H
#define getifaddrs(__ifap) ni_getifaddrs(__ifap,0)
#define freeifaddrs ni_freeifaddrs
#endif

#ifdef LOCAL_SIZEOF_SOCKADDR_IN6

/* **************************************************** *
 *	define missing IPV6 filter macros if needed	*
 * **************************************************** */

/*
 * Unspecified
 */
#ifndef IN6_IS_ADDR_UNSPECIFIED 
#define IN6_IS_ADDR_UNSPECIFIED(a) (	\
	(*(const u_int32_t *)(const void *)(&(a)->s6_addr[0]) |	\
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[4]) |	\
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[8]) |	\
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[12])) == 0)
#endif
/*
 * Loopback
 */
#ifndef IN6_IS_ADDR_LOOPBACK
#define IN6_IS_ADDR_LOOPBACK(a) (	\
	(*(const u_int32_t *)(const void *)(&(a)->s6_addr[0]) |	\
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[4]) |	\
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[8])) == 0 && \
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[12]) == ntohl(1))
#endif
/*
 * IPv4 compatible
 */
#ifndef IN6_IS_ADDR_V4COMPAT
#define IN6_IS_ADDR_V4COMPAT(a) (	\
	(*(const u_int32_t *)(const void *)(&(a)->s6_addr[0]) |	\
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[4]) |	\
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[8])) == 0 && \
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[12]) != 0 && \
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[12]) != ntohl(1))
#endif
/*
 * Mapped
 */
#ifndef IN6_IS_ADDR_V4MAPPED
#define IN6_IS_ADDR_V4MAPPED(a) (	\
	(*(const u_int32_t *)(const void *)(&(a)->s6_addr[0]) |	\
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[4])) == 0 && \
	 *(const u_int32_t *)(const void *)(&(a)->s6_addr[8]) == ntohl(0x0000FFFF))
#endif
#endif 	/* LOCAL_SIZEOF_SOCKADDR_IN6 */

#endif	/* _NI_FIXUPS_H */
