
/* ********************************************************************	*
 * ni_in6_classify.c	version 0.01	1-23-09				*
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

/* adapted from http://cvs.deepspace6.net/view/ipv6calc/lib/libipv6addr.c?rev=1.23 */

#include "localconf.h"

#ifdef LOCAL_SIZEOF_SOCKADDR_IN6

/* ************************************************************	*
 *	http://en.wikipedia.org/wiki/IPv6			*
 *	http://www.sabi.co.uk/Notes/swIPv6Prefixes.html		*
 *	http://en.wikipedia.org/wiki/6to4			*
 *	http://www.iana.org/assignments/ipv6-address-space	*
 * ************************************************************	*/

u_int32_t
ni_in6_classify(unsigned char * s6_bytes)
{
	u_int32_t type = 0;

#define byte0 s6_bytes[0]
#define byte1 s6_bytes[1]
#define byte2 s6_bytes[2]
#define byte3 s6_bytes[3]
#define byte4 s6_bytes[4]
#define byte10 s6_bytes[10]
#define byte11 s6_bytes[11]
#define byte12 s6_bytes[12]
#define byte13 s6_bytes[13]
#define byte14 s6_bytes[14]
#define byte15 s6_bytes[15]
#define bytes0_1 (s6_bytes[0] | s6_bytes[1])
#define bytes2_3 (s6_bytes[2] | s6_bytes[3])
#define bytes4_5 (s6_bytes[4] | s6_bytes[5])
#define bytes6_7 (s6_bytes[6] | s6_bytes[7])
#define bytes8_9 (s6_bytes[8] | s6_bytes[9])
#define bytes10_11 (s6_bytes[10] | s6_bytes[11])
#define bytes12_13 (s6_bytes[12] | s6_bytes[13])
#define bytes14_15 (s6_bytes[14] | s6_bytes[15])
#define bytes0_3 (bytes0_1 | bytes2_3)
#define bytes4_7 (bytes4_5 | bytes6_7)
#define bytes8_11 (bytes8_9 | bytes10_11)
#define bytes12_15 (bytes12_13 | bytes14_15)
#define allbytes (bytes0_3 | bytes4_7 | bytes8_11 | bytes12_15)

/* ************************************************************	*
 *	unspecified address - all zeros				*
 * ************************************************************	*/

	if (allbytes == 0)
	    type |= IPV6_ADDR_UNSPECIFIED;

/* ************************************************************	*
 *	FC00::/7              Unique Local Unicast    [RFC4193]	*
 * ************************************************************	*/

	 if ((byte0 & 0xFEu) == 0xFCu)
	    type |= IPV6_ADDR_ULUA;

/* ************************************************************	*
 *	2000::/3              Global Unicast          [RFC4291]	*
 * ************************************************************	*/

	if ((byte0 & 0xE0u) == 0x20u)
	    type |= IPV6_ADDR_AGU;

/* ****************************************************************************	*
 *   ftp://ftp.isi.edu/in-notes/rfc2471.txt					*
 *   IPv6 Testing Address Allocation						*
 *   The Aggregatable Global Unicast Address Allocation format defined in	*
 *   [AGGR] is as follows:							*
 *										*
 *      | 3 |  13 |    32     |   16   |          64 bits               |	*
 *      +---+-----+-----------+--------+--------------------------------+	*
 *      |FP | TLA | NLA ID    | SLA ID |         Interface ID           |	*
 *      |   | ID  |           |        |                                |	*
 *      +---+-----+-----------+--------+--------------------------------+	*
 *										*
 *   where:									*
 *										*
 *      FP = 001 = Format Prefix						*
 *										*
 *           This is the Format Prefix used to identify aggregatable		*
 *           global unicast addresses.						*
 *										*
 *      TLA = 0x1FFE = Top-Level Aggregation Identifier				*
 *										*
 *           This is a TLA ID assigned by the IANA for 6bone testing under	*
 *           the auspices of the IETF IPng Transition Working Group 6bone	*
 *           testbed activity.							*
 *										*
 *	3ffe::/16 - experimental 6bone	- obsolete 6/6/2006			*
 * ****************************************************************************	*/

	if (byte0 == 0x3Fu && byte1 == 0xFEu)
	    type |= IPV6_ADDR_6BONE;
	
/* ****************************************************************************	*
 *	http://www.ipv6day.org/action.php?n=En.GetConnected-Teredo		*
 *	Teredo Prefix has been changed from 3ffe:831f::/32 to 2001:0000::/32 	*
 *	once the Teredo specification has been published as RFC4380		*
 *										*
 *	http://www.ietf.org/rfc/rfc4380.txt					*
 *	2.6.  Global Teredo IPv6 Service Prefix					*
 *	An IPv6 addressing prefix whose value is 2001:0000:/32			*
 * ****************************************************************************	*
 *										*
 * ****************************************************************************	*
 *				OLD TEREDO					*
 * if (byte0 == 0x3fu && byte1 == 0xfeu && byte2 == 0x83u && byte3 == 0x1f) {	*
 *	type |= IPV6_ADDR_TEREDO;						*  
 * ****************************************************************************	*/
 
	if (byte0 == 0x20 && byte1 == 0x1u) {
	    if (bytes2_3 == 0)
		type |= IPV6_ADDR_TEREDO;

/* ****************************************************************************	*
 *	http://www.iana.org/assignments/ipv6-address-space			*
 *	http://tools.ietf.org/html/rfc3849					*
 *	2001:0DB8::/32 has been assigned as a NON-ROUTABLE for documentation	*
 * ****************************************************************************	*/

	    if (byte2 == 0xDu && byte3 == 0xB8u)
		type |= IPV6_ADDR_NON_ROUTE_DOC;
	} /* 2001::/16

/* ****************************************************************************	*
 *	http://www.ietf.org/rfc/rfc3056.txt?number=3056				*
 *										*
 *   The IANA has permanently assigned one 13-bit IPv6 Top Level		*
 *   Aggregator (TLA) identifier under the IPv6 Format Prefix 001 [AARCH,	*
 *   AGGR] for the 6to4 scheme.Its numeric value is 0x0002, i.e., it is		*
 *   2002::/16 when expressed as an IPv6 address prefix.			*
 *										*
 *   The subscriber site is then deemed to have the following IPv6 address	*
 *   prefix, without any further assignment procedures being necessary:		*
 *										*
 *      Prefix length: 48 bits							*
 *      Format prefix: 001							*
 *      TLA value: 0x0002							*
 *      NLA value: V4ADDR							*
 *										*
 *   This is illustrated as follows:						*
 *										*
 *     | 3 |  13  |    32     |   16   |          64 bits               |	*
 *     +---+------+-----------+--------+--------------------------------+	*
 *     |FP | TLA  | V4ADDR    | SLA ID |         Interface ID           |	*
 *     |001|0x0002|           |        |                                |	*
 *     +---+------+-----------+--------+--------------------------------+	*
 *										*
 *   Thus, this prefix has exactly the same format as normal /48 prefixes	*
 *   assigned according to [AGGR].  It can be abbreviated as			*
 *   2002:V4ADDR::/48.  Within the subscriber site it can be used exactly	*
 * ****************************************************************************	*/

	if (byte0 == 0x20 && byte1 == 0x2u) {
	    type |= IPV6_ADDR_6TO4;

/* ************************************************************************************	*
 *	2002:<ipv4addr>::<ipv4addr> 							*
 *	http://research.microsoft.com/en-us/um/redmond/projects/msripv6/docs/6to4.htm	*
 * ************************************************************************************	*/

	    if (bytes2_3 == bytes12_13 && bytes4_5 == bytes14_15 &&
		(bytes6_7 | bytes8_9 | bytes10_11) == 0)
			type |= IPV6_ADDR_6TO4_MICROSOFT;
	}	/* 2002::/16 */

/* ****************************************************************************	*
 * http://www.iana.org/assignments/ipv6-unicast-address-assignments 2008-05-13	*
 * ****************************************************************************	*/

	if (!(type & (	IPV6_ADDR_6BONE |		/* obsolete - remove?	*/
			IPV6_ADDR_6TO4 | 		/* 2002::/16		*/
			IPV6_ADDR_NON_ROUTE_DOC | 	/* 2001:0DB8::/32	*/
			IPV6_ADDR_TEREDO		/* 2001:0000::/32	*/
		)) && (byte0 & 0xE0u) == 0x20u)
		type |= IPV6_ADDR_PRODUCTIVE;

/* ********************************************************************************************	*
 *  http://www.tcpipguide.com/free/t_IPv6MulticastandAnycastAddressing-4.htm			*
 *  http://www.ipv6tf.org/index.php?page=meet/glossary&id_palabra=SOLICITED-NODE%20ADDRESS	*
 *  http://www.soi.wide.ad.jp/class/99007/slides/24/25.html					*
 *  Requested node address is built with FF02::1:FF00:0/104 prefix 				*
 *  and latest unicast IPv6 address 24 bits.							*
 *  All solicited node addresses have their T flag set to zero and a scope ID of 2, hence they	*
 *  start with FF02. The 112 bit group ID consists of:						*
 *  79 bits of zeros, a single 1, eight 1's, and the bottom 24bits of the unicast address	*
 * ********************************************************************************************	*/

	if (byte0 == 0xFFu && byte1 == 0x2u &&
		(bytes2_3 | bytes4_5 | bytes6_7 | bytes8_9) == 0 &&
		byte10 == 0 && byte11 == 0x1u)
	    type |= IPV6_ADDR_SOLICITED_NODE;

/* ************************************************************	*
 * 	http://en.wikipedia.org/wiki/ISATAP			*			
 *	The link-local address is determined by concatenating 	*
 *		fe80:0000:0000:0000:0000:5efe:			*
 *	with the 32 bits of the host's IPv4 address		*
 * ************************************************************	*/

	if (byte0 == 0xFFu && byte1 == 0x80u &&
		(bytes2_3 | bytes4_5 | bytes6_7 | bytes8_9) == 0 &&
		byte10 == 0x5Eu && byte11 == 0xFEu)
	    type |= IPV6_ADDR_ISATAP;


/* ************************************************************	*
 *	if not local unicast, any address where the first	*
 *	three bits are not all 1's or all 0's is UNICAST	*
 * ************************************************************	*/

	if (byte0 == 0xFCu || ((byte0 & 0xE0u) != 0 && (byte0 & 0xE0u) != 0xE0u)) {
	    type |= IPV6_ADDR_UNICAST;
	    return (type);
	}
	else if (byte0 == 0xFF) {
	    type |= IPV6_ADDR_MULTICAST;
	    switch(byte1) {
		case 0x1u :
		    type |= IPV6_ADDR_LOOPBACK;
		    break;
		case 0x2u :
		    type |= IPV6_ADDR_LINKLOCAL;
		    break;
		case 0x5 :
		    type |= IPV6_ADDR_SITELOCAL;
		    break;
	    }
	    return type;
	}

/* ********************	*
 *	local stuff	*
 * ********************	*/

	if (byte0 == 0xFEu) {
	    if ((byte1 & 0xC0u) == 0x80) {
		type |=  IPV6_ADDR_LINKLOCAL | IPV6_ADDR_UNICAST;
		return type;
	    }
	    else if ((byte1 & 0xC0u) == 0xC0u) {
		type |= IPV6_ADDR_SITELOCAL | IPV6_ADDR_UNICAST;
		return type;
	    }
	}

/* ********************	*	
 *	misc		*
 * ********************	*/

	if ((bytes0_3 | bytes4_7) == 0) {
	    if (bytes8_11 == 0) {
		if (bytes12_15 == 0) {
		    type |= IPV6_ADDR_ANY;
		    return type;
		}
		else if ((bytes12_13 | byte14) == 0 && byte15 == 0x1u) {
		    type |= IPV6_ADDR_LOOPBACK | IPV6_ADDR_UNICAST;
		    return type;
		}
		type |= IPV6_ADDR_COMPATv4 | IPV6_ADDR_UNICAST;
		return type;
	    }
	    if (bytes8_9 == 0 && (byte10 & byte11) == 0xFFu) {
		type |= IPV6_ADDR_MAPPED;
		return type;
	    }
	}
	type |= IPV6_ADDR_RESERVED;
	return type;
}

#endif
