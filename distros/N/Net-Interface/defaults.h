
/* ******************************************************************** *
 * defaults.h	version 0.01	1-23-09					*
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

#ifndef _NI_DEFAULTS_H
#define _NI_DEFAULTS_H

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
#ifdef HAVE_PCAP
#include <pcap.h>
#endif


#ifdef HAVE_ASM_TYPES_H
#include <asm/types.h>
#endif
#ifdef HAVE_FEATURES_H
#include <features.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
#ifdef HAVE_SYS_UN_H
#include <sys/un.h>
#endif
#ifdef HAVE_NETECONET_EC_H
#include <neteconet/ec.h>
#endif
#ifdef HAVE_LINUX_ATALK_H
#include <linux/atalk.h>
#endif
#ifdef HAVE_NETINET_IF_FDDI_H
#include <netinet/if_fddi.h>
#endif
#ifdef HAVE_LINUX_IF_FDDI_H
#include <linux/if_fddi.h>
#endif
#ifdef HAVE_LINUX_IF_TR_H
#include <linux/if_tr.h>
#endif
#ifdef HAVE_NET_IF_ARP_H
#include <net/if_arp.h>
#endif
#ifdef HAVE_LINUX_IF_ETHER_H
#include <linux/if_ether.h>
#endif
#ifdef HAVE_ENDIAN_H
#include <endian.h>
#endif
#ifdef HAVE_BYTESWAP_H
#include <byteswap.h>
#endif
#ifdef HAVE_ALLOCA_H
#include <alloca.h>
#endif
#ifdef HAVE_SYS_SOCKIO_H
#include <sys/sockio.h>
#endif
#ifdef HAVE_SYS_SYSCTL_H
#include <sys/sysctl.h>
#endif
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#ifdef HAVE_SYS_MODULE_H
#include <sys/module.h>
#endif
#ifdef HAVE_SYS_LINKER_H
#include <sys/linker.h>
#endif
#ifdef HAVE_SYS_MAC_H
#include <sys/mac.h>
#endif
#ifdef HAVE_NETAX25_AX25_H
#include <netax25/ax25.h>
#endif
#ifdef HAVE_LINUX_AX25_H
#include <linux/ax25.h>
#endif
#ifdef HAVE_LINUX_TYPES_H
#include <linux/types.h>
#endif
#ifdef HAVE_LINUX_IF_STRIP_H
#include <linux/if_strip.h>
#endif
#ifdef HAVE_LINUX_X25_H
#include <linux/x25.h>
#endif
#ifdef HAVE_LINUX_IF_ARP_H
#include <linux/if_arp.h>
#endif
#ifdef HAVE_SYS_IOCTL_H
#include <sys/ioctl.h>
#endif
#ifdef HAVE_LIBC_INTERNAL_H
#include <libc-internal.h>
#endif
#ifdef HAVE_SIGNAL_H
#include <signal.h>
#endif
#ifdef HAVE_NET_IF_H
#include <net/if.h>
#endif
#ifdef HAVE_NETATALK_AT_H
#include <netatalk/at.h>
#endif
#ifdef HAVE_NET_PFVAR_H
#include <net/pfvar.h>
#endif
#ifdef HAVE_NET_IF_PFSYNC_H
#include <net/if_pfsync.h>
#endif
#ifdef HAVE_NETPACKET_PACKET_H
#include <netpacket/packet.h>
#endif
#ifdef HAVE_STDBOOL_H
#include <stdbool.h>
#endif
#ifdef HAVE_TIME_H
#include <time.h>
#endif
#ifdef HAVE_NETINET_IN_H
#include <netinet/in.h>
#endif
#ifdef HAVE_NET_IF_VAR_H
#include <net/if_var.h>
#endif
#ifdef HAVE_NETINET_IN_VAR_H
#include <netinet/in_var.h>
#endif
#ifdef HAVE_NETIPX_IPX_H
#include <netipx/ipx.h>
#endif
#ifdef HAVE_NETIPX_IPX_IF_H
#include <netipx/ipx_if.h>
#endif
#ifdef HAVE_NET_IF_DL_H
#include <net/if_dl.h>
#endif
#ifdef HAVE_NET_IF_TYPES_H
#include <net/if_types.h>
#endif
#ifdef HAVE_NET_ROUTE_H
#include <net/route.h>
#endif
#ifdef HAVE_NETINET_ETHER_H
#include <netinet/ether.h>
#endif
#ifdef HAVE_NETINET_IF_ETHER_H
#include <netinet/if_ether.h>
#endif
#ifdef HAVE_LINUX_IF_SLIP_H
#include <linux/if_slip.h>
#endif
#ifdef HAVE_CTYPE_H
#include <ctype.h>
#endif
#ifdef HAVE_NETINET_IP_CARP_H
#include <netinet/ip_carp.h>
#endif
#ifdef HAVE_NET_IF_MEDIA_H
#include <net/if_media.h>
#endif
#ifdef HAVE_NET80211_IEEE80211_H
#include <net80211/ieee80211.h>
#endif
#ifdef HAVE_NET80211_IEEE80211_CRYPTO_H
#include <net80211/ieee80211_crypto.h>
#endif
#ifdef HAVE_NET80211_IEEE80211_IOCTL_H
#include <net80211/ieee80211_ioctl.h>
#endif
#ifdef HAVE_NET_IF_LAGG_H
#include <net/if_lagg.h>
#endif
#ifdef HAVE_NET_IF_VLAN_VAR_H
#include <net/if_vlan_var.h>
#endif
#ifdef HAVE_NET_ETHERNET_H
#include <net/ethernet.h>
#endif
#ifdef HAVE_IFADDRS_H
#include <ifaddrs.h>
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
#ifdef HAVE_NETINET6_ND6_H
#include <netinet6/nd6.h>
#endif
#ifdef HAVE_STDARG_H
#include <stdarg.h>
#endif
#ifdef HAVE_NET80211_IEEE80211_FREEBSD_H
#include <net80211/ieee80211_freebsd.h>
#endif
#ifdef HAVE_LINUX_ROSE_H
#include <linux/rose.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifndef HAVE_MALLOC_IN_STDLIB
# ifdef HAVE_MALLOC_H
# include <malloc.h>
# endif
#endif
#ifdef HAVE_ARPA_INET_H
#include <arpa/inet.h>
#endif

/*	stuff to get the hardware address	*/

#ifdef HAVE_SYS_DLPI_H
# include <sys/dlpi.h>
# if defined HAVE_STROPTS_H
#   include <stropts.h>
# endif
#endif
#ifdef HAVE_NET_NIT_IF_H
#include <net/nit_if.h>
#endif
#ifdef HAVE_NETIO_H
#include <netio.h>
#endif


#endif	/* _NI_DEFAULTS_H	*/
