
/* ******************************************************************** *
 * defaults.h	version 0.01	3-2-09					*
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

#include "config.h"

#ifndef _SNIFF_DEFAULTS_H
#define _SNIFF_DEFAULTS_H

#include <errno.h>

#ifdef HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif
#ifdef STDC_HEADERS
# include <stdlib.h>
# include <stddef.h>
#else
# ifdef HAVE_STDLIB_H
#  include <stdlib.h>
# endif
#endif 
#ifdef HAVE_STRING_H
# if !defined STDC_HEADERS && defined HAVE_MEMORY_H
#  include <memory.h>
# endif
# include <string.h>
#endif
#ifdef HAVE_STRINGS_H
# include <strings.h>
#endif
#ifdef HAVE_INTTYPES_H
# include <inttypes.h>
#endif
#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#ifdef HAVE_NETINET_IP_H
#include <netinet/ip.h>
#endif
#ifdef HAVE_NETINET_ETHER_H
#include <netinet/ether.h>
#endif
#ifdef HAVE_PCAP
#include <pcap.h>
#endif

#ifdef WORDS_BIGENDIAN
#define host_is_BIG_ENDIAN 1
#else
#define host_is_LITTLE_ENDIAN 1
#endif

#if SIZEOF_U_INT8_T == 0
#undef SIZEOF_U_INT8_T  
#define SIZEOF_U_INT8_T SIZEOF_UINT8_T
typedef uint8_t u_int8_t;
#endif 

#if SIZEOF_U_INT16_T == 0
#undef SIZEOF_U_INT16_T  
#define SIZEOF_U_INT16_T SIZEOF_UINT16_T
typedef uint16_t u_int16_t;
#endif

#if SIZEOF_U_INT32_T == 0
#undef SIZEOF_U_INT32_T  
#define SIZEOF_U_INT32_T SIZEOF_UINT32_T
typedef uint32_t u_int32_t;
#endif

#ifndef ETH_HLEN
#define ETH_HLEN 14		/* size of ether header		*/
#endif
#ifndef ETH_ALEN
#define ETH_ALEN 6		/* ether address length		*/
#endif
#ifndef IP_HLEN
#define IP_HLEN 0x14		/* size of ip header		*/
#endif
#ifndef IP_OFFMASK
#define IP_OFFMASK 0x1fff	/* mask for fragmenting bits	*/
#endif

#ifndef  HAVE_STRUCT_ETHER_HEADER
struct ether_header {
  u_int8_t  ether_dhost[ETH_ALEN];
  u_int8_t  ether_shost[ETH_ALEN];
  u_int16_t ether_type;
};
#endif

#ifndef HAVE_STRUCT_IPHDR
struct iphdr {
# ifdef host_is_LITTLE_ENDIAN
    unsigned int ihl:4;
    unsigned int version:4;
# elif defined host_is_BIG_ENDIAN
    unsigned int version:4;
    unsigned int ihl:4;
# else
# error "Please fix <bits/endian.h>"
# endif
    u_int8_t tos;
    u_int16_t tot_len;
    u_int16_t id;
    u_int16_t frag_off;
    u_int8_t ttl;
    u_int8_t protocol;
    u_int16_t check;
    u_int32_t saddr;
    u_int32_t daddr;
};
#endif

#endif	/* _SNIFF_DEFAULTS_H	*/
