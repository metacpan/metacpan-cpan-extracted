
/* ********************************************************************	*
 * ni_funct.h	version 0.04 3-7-09					*
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

#ifndef _NI_FUNC_H
#define _NI_FUNC_H 1

#ifndef _NI_FIXUPS_H
#error NEED 'ni_fixups' first
#endif

/* **************************************************** *
 *	checking and printing the MAC address		*
 * **************************************************** */

#define NI_PRINT_MAC(__macp) printf("MAC addr %02X:%02X:%02X:%02X:%02X:%02X", \
            (u_char)__macp[0],(u_char)__macp[1],(u_char)__macp[2], \
            (u_char)__macp[3],(u_char)__macp[4],(u_char)__macp[5])

#define NI_MAC_NOT_ZERO(__macp) (((u_int32_t *)(__macp))[0] != 0 || ((u_int16_t *)(__macp))[2] != 0)

/* **************************************************** *
 *		text table definition			*
 * **************************************************** */

typedef struct ni_IFF_table_entry {
	u_int64_t	iff_val;
	char		*iff_nam;
} ni_iff_t;

/* **************************************************** *
 *	print ipV6 address - full length		*
 * **************************************************** */
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
#define NI_PRINT_IPV6(__sin6_addr) \
	printf("%02X%02X:%02X%02X:%02X%02X:%02X%02X:%02X%02X:%02X%02X:%02X%02X:%02X%02X", \
		(__sin6_addr).s6_addr[0], \
		(__sin6_addr).s6_addr[1], \
		(__sin6_addr).s6_addr[2], \
		(__sin6_addr).s6_addr[3], \
		(__sin6_addr).s6_addr[4], \
		(__sin6_addr).s6_addr[5], \
		(__sin6_addr).s6_addr[6], \
		(__sin6_addr).s6_addr[7], \
		(__sin6_addr).s6_addr[8], \
		(__sin6_addr).s6_addr[9], \
		(__sin6_addr).s6_addr[10], \
		(__sin6_addr).s6_addr[11], \
		(__sin6_addr).s6_addr[12], \
		(__sin6_addr).s6_addr[13], \
		(__sin6_addr).s6_addr[14], \
		(__sin6_addr).s6_addr[15])
#endif

/* **************************************************** *
 *	free the appropriate mememory for getifaddrs	*
 * **************************************************** */

void
ni_free_gifa(struct ifaddrs * ifap, int flavor);

/* **************************************************** *
 *	local multi-platform get_ifaddrs function	*
 * **************************************************** */

int  
ni_getifaddrs(struct ifaddrs **ifap, int flavor);

/* **************************************************** *
 *	conditionally close and reopen socket		*
 * **************************************************** */
int
ni_clos_reopn_dgrm(int fd, u_int af);


/* **************************************************** *
 *	allocate memory for a duplicate of the		*
 *	memory chunck at 'memp' of 'size' and		*
 * 	return a pointer. MUST free(newptr)		*
 *	On error returns NULL and sets ENOMEM		*
 * **************************************************** */

void *
ni_memdup(void * memp, int size);

/* **************************************************** *
 *      generate a netmask from a prefix length         *
 * **************************************************** */
   
void
ni_plen2mask(void * in_addr, int plen, int sizeofaddr);

/* ****************************************************	*
 *	calculate the length of netmask prefix		*
 * ****************************************************	*/
/*	pointer to bytes, size in bytes of address	*/

int
ni_prefix(void * ap, int sz);

/* **************************************************** *
 * some OS lose scope on the particular device/addr     *
 * handle when certain ioctl's are performed. this      *
 * function refreshs the ifconf chain and positions     *
 * the pointers in the exact same spot with fresh scope *
 * **************************************************** */

struct ni_ifconf_flavor;

int
ni_refresh_ifreq(int fd, struct ifconf * ifc, void ** ifr, void ** lifr, struct ni_ifconf_flavor * nip);

/* **************************************************** *
 *	define access to various types of fields	*
 *	in 'ifreq', 'in6_ifreq', and 'lifreq'		*
 *	structures					*
 * **************************************************** */

/* ******************************************** *
 *   function to return MAC address if it	*
 *   is not present in a DL or LL record	*
 * ******************************************** */
  
unsigned char *
ni_fallbackhwaddr(u_int af, void * ifr);

/* ******************************************** *
 *   the semi-standard version of getifaddrs    *
 * ******************************************** */
  
int
nifreq_gifaddrs(struct ifaddrs **ifap, struct ni_ifconf_flavor * nifp);
  
/* a sane amount of memory for interface descriptors	*/
#define NI_IFREQ_MEM_MAX 1048576

struct nifreq {
	char	ni_ifr_name[IFNAMSIZ];
	union {
		struct	sockaddr	 ifr_saddr;
		struct	sockaddr_in	 ifr_sin;
		struct	sockaddr_storage ifr_stor;
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
		struct	sockaddr_in6	 ifr_sin6;
#endif
		short			 ifr_short;
		unsigned short		 ifr_ushort;
		int			 ifr_int;
		char			 ifr_char[2];
/*	this is really a char *		*/
		caddr_t			 ifr_cadt_data;
		unsigned char		 ifr_uchar[2];
		int			 ifr_iary[2];
		unsigned int		 ifr_uint;
		u_int32_t		 ifr_uint32;
		u_int64_t		 ifr_uint64;
		u_int32_t		 ifr_uiary[2];
#ifdef HAVE_STRUCT_IN6_IFREQ
		struct in6_addrlifetime  ifru_lifetime;
		struct in6_ifstat 	 ifru_stat;
		struct icmp6_ifstat 	 ifru_icmp6stat;
#endif
#ifdef HAVE_STRUCT_LIFREQ
		char lifreq_pad[NI_LIFREQ_PAD];
#endif
	} ni_ifru;

/*	convenience definitions		*/
#
#define ni_saddr	ni_ifru.ifr_saddr	/* any sockaddr		*/
#define ni_sin		ni_ifru.ifr_sin		/* any sockaddr_in	*/
#define ni_stor		ni_ifru.ifr_stor	/* and sockaddr_storage	*/
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
# define ni_sin6	ni_ifru.ifr_sin6	/* any sockaddr_in6	*/
#endif
#define ni_short	ni_ifru.ifr_short	/* any short		*/
#define ni_ushort	ni_ifru.ifr_ushort	/* any unsigned short	*/
#define ni_int		ni_ifru.ifr_int		/* any int		*/
#define ni_char		ni_ifru.ifr_char	/* any char array	*/
#define ni_data		ni_ifru.ifr_cadt_data	/* device specific data pointer	*/
#define ni_uchar	ni_ifru.ifr_uchar	/* any unsigned char array - hardware mac	*/
#define ni_iary		ni_ifru.ifr_iary	/* any int array	*/
#define ni_uint		ni_ifru.ifr_uint	/* any uint		*/
#define ni_uint32	ni_ifru.ifr_uint32	/* any uint32		*/
#define ni_uint64	ni_ifru.ifr_uint64	/* any uint64		*/
#define ni_uiary	ni_ifru.ifr_uiary	/* any uint32 array	*/
#ifdef HAVE_STRUCT_IN6_IFREQ
# define ni_lifetime	ni_ifru.ifru_lifetime
# define ni_stat	ni_ifru.ifru_stat
# define ni_icmp6	ni_ifru.ifru_icmp6stat
#endif
};

/* ****************************************************	*
 *	standard SIOCget functions			*
 *							*
 *	execute supported ioctl's			*
 *	where a value is requested, return it		*
 *	otherwise it is up to the user to retireve	*
 *	information via their pointers			*
 *	returns -1 on error, sets errno			*
 * ****************************************************	*/

int32_t
ni_get_any(int fd, int cmd, void * ifr);

/* ****************************************************	*
 *	standard SIOCset functions			*
 *							*
 *	execute supported ioctl's			*
 *	returns -1 on error, sets errno			*
 *							*
 *	struct nifreq ifr should be prepared, for	*
 *	add/modify of a Linux  ipV6 address, the 	*
 *	PREFIX/CIDR value should be stored at:		*
 *							*
 *		ifr->ni_sin6.sin6_port			*
 *							*
 * ****************************************************	*/

int
ni_set_any(int fd, int cmd, struct nifreq * ifr);

#ifdef LOCAL_SIZEOF_SOCKADDR_IN6

/* ********************************************	*
 *	get scope id from struct scope index	*
 *	or KAME bits, correct bits as needed	*
 * ********************************************	*/
 
u_int
ni_get_scopeid(struct sockaddr_in6 * sin6);

#endif

/* ********************************************	*
 *	IPV6_ADDR_xxxx definitions from		*
 *	linux kernel	include/net/ipv6.h	*
 *	these are the bits for the byte in	*
 *		/proc/net/if_net6		*
 * ********************************************	*
 *
 * with credits to kernel and USAGI developer team
 * basic information was taken from "kernel/include/net/ipv6.h"
 *

 *	Addr type
 *	
 *	type	-	unicast | multicast | anycast
 *	scope	-	local	| site	    | global
 *	v4	-	compat
 *	v4mapped
 *	any
 *	loopback
 */

/*
 *	make sure and include changes to this table in the
 *	_lx_types function in Interfaces.xs
 */

#define IPV6_ADDR_ANY			(u_int32_t) 0x0000u
#define IPV6_ADDR_UNICAST		(u_int32_t) 0x0001u	
#define IPV6_ADDR_MULTICAST		(u_int32_t) 0x0002u	
#define IPV6_ADDR_ANYCAST		(u_int32_t) 0x0004u
#define IPV6_ADDR_LOOPBACK		(u_int32_t) 0x0010u
#define IPV6_ADDR_LINKLOCAL		(u_int32_t) 0x0020u
#define IPV6_ADDR_SITELOCAL		(u_int32_t) 0x0040u
#define IPV6_ADDR_COMPATv4		(u_int32_t) 0x0080u
#define IPV6_ADDR_SCOPE_MASK		(u_int32_t) 0x00f0u
#define IPV6_ADDR_MAPPED		(u_int32_t) 0x1000u
#define IPV6_ADDR_RESERVED		(u_int32_t) 0x2000u	/* reserved address space */
#define IPV6_ADDR_ULUA			(u_int32_t) 0x4000u	/* Unique Local Unicast Address */
#define IPV6_ADDR_6TO4			(u_int32_t) 0x00010000u
#define IPV6_ADDR_6BONE			(u_int32_t) 0x00020000u
#define IPV6_ADDR_AGU			(u_int32_t) 0x00040000u
#define IPV6_ADDR_UNSPECIFIED		(u_int32_t) 0x00080000u
#define IPV6_ADDR_SOLICITED_NODE	(u_int32_t) 0x00100000u
#define IPV6_ADDR_ISATAP		(u_int32_t) 0x00200000u	/* RFC 4214 */
#define IPV6_ADDR_PRODUCTIVE		(u_int32_t) 0x00400000u
#define IPV6_ADDR_6TO4_MICROSOFT	(u_int32_t) 0x00800000u
#define IPV6_ADDR_TEREDO		(u_int32_t) 0x01000000u	/* RFC 4380 */
#define IPV6_ADDR_ORCHID		(u_int32_t) 0x02000000u /* RFC 4843 */
#define IPV6_ADDR_NON_ROUTE_DOC		(u_int32_t) 0x08000000u	/* RFC 3849 */

/* ****************************************************	*
 *   return size of format table for linux_scope2txt	*
 * ****************************************************	*/

int
ni_sizeof_type2txt();

/* ****************************************************	*
 *	This function maps I<Linux> style scope 	*
 *	bits to their RFC-2373 equivalent.		*
 *							*
 *  scope flags	rfc-2373				*
 *	0 	reserved				*
 *	1    node-local (aka loopback, interface-local)	*
 *	2    link-local					*
 *	3	unassigned				*
 *	4	unassigned				*
 *	5    site-local					*
 *	6	unassigned				*
 *	7	unassigned				*
 *	8    organization-local				*
 *	9	unassigned				*
 *	A	unassigned				*
 *	B	unassigned				*
 *	C	unassigned				*
 *	D	unassigned				*
 *	E    global scope				*
 *	F	reserved				*
 *							*
 *    Linux   rfc-2373					*
 *   0x0000	0xe	GLOBAL				*
 *   0x0010u	0x1 NODELOCAL, LOOPBACK, INTERFACELOCAL	*
 *   0x0020u	0x2	LINKLOCAL			*
 *   0x0040u	0x5	SITELOCAL			*
 *   0x0080u is mapped out of range to 0x10		*
 * ****************************************************	*/

int 
ni_lx_type2scope(int lscope);

/* ****************************************************	*
 *	      value definitions for above		*
 * ****************************************************	*/
 
#define RFC2373_GLOBAL		0xeu
#define RFC2373_ORGLOCAL	0x8u
#define RFC2373_SITELOCAL	0x5u
#define RFC2373_LINKLOCAL	0x2u
#define RFC2373_NODELOCAL	0x1u
#define LINUX_COMPATv4		0x10u

/* ****************************************************	*
 *    print statement for internal linux format flags	*
 * ****************************************************	*/

void
ni_linux_scope2txt(u_int32_t flags);

/* ****************************************************	*
 *    returns attribute bits for extended linux scope	*
 * ****************************************************	*/
 
u_int32_t
ni_in6_classify(unsigned char * s6_bytes);

/* ****************************************************	*
 *	support for variants of ifreq			*
 * ****************************************************	*/

/*
 *	    IF / WHEN YOU CHANGE THIS STRUCT,
 *	UPDATE IT IN THE SUPPORTED FLAVOR MODULES!
 *
 * Currently support flavors:
 */

enum ni_FLAVOR {
	NI_NULL,
	NI_IFREQ,
	NI_LIFREQ,
	NI_IN6_IFREQ,
	NI_LINUXPROC
};

static int
developer(void * ifr);

struct ni_ifconf_flavor {
    enum ni_FLAVOR 		ni_type;
    int				siocgifindex;
    int				siocsifaddr;
    int				siocgifaddr;
    int				siocdifaddr;
    int				siocaifaddr;
    int				siocsifdstaddr;
    int				siocgifdstaddr;
    int				siocsifflags;
    int				siocgifflags;
    int				siocsifmtu;
    int				siocgifmtu;
    int				siocsifbrdaddr;
    int				siocgifbrdaddr;
    int				siocsifnetmask;
    int				siocgifnetmask;
    int				siocsifmetric;
    int				siocgifmetric;
    int				ifr_offset;
    int				(*gifaddrs)(struct ifaddrs **ifap, struct ni_ifconf_flavor * nifp);
    void			(*fifaddrs)(struct ifaddrs *ifa);
    int				(*refreshifr)(int fd, struct ifconf * ifc, void ** oifr, void ** olifr, struct ni_ifconf_flavor * nip);
    void *			(*getifreqs)(int fd, void * ifc);
    int				(*developer)(void * whatever);
    struct ni_ifconf_flavor * 	ni_ifcf_next;
};

struct ni_ifconf_flavor *       
ni_ifcf_get(enum ni_FLAVOR type);

/* return flavor pointer for NI_IFREQ if flavor is unknown	*/
struct ni_ifconf_flavor *
ni_safe_ifcf_get(enum ni_FLAVOR type);

void
ni_ifcf_register(struct ni_ifconf_flavor * nip);

struct ni_af_flavor;
struct ni_af_flavor {
    int				ni_af_family;
    int32_t			(*af_get_any)(int fd, int cmd, void * ifr);
    int				(*af_getifaddrs)(int fd, struct ifaddrs * thisif, struct nifreq * ifr,...);
    struct ni_af_flavor *	ni_aff_next;
};

struct ni_af_flavor *
ni_af_get(int af);

void
ni_af_register(struct ni_af_flavor * nafp);

/* ************************************************************	*
 *	Certain broken Solaris headers cause build		*
 *	errors with the syntax for constructors.		*
 *  i.e.							*
 *	void __attribute__((constructor))			*
 *	constructor_function () 				*
 *	{							*
 *		code....					*
 *	};							*
 *								*
 * line 249: syntax error before or at: (			*
 * line 251: warning: old-style declaration or incorrect type	*
 * cc: acomp failed [filename.c]				*
 * *** Error code 2						*
 * make: Fatal error: Command failed for target 'filename.o'	*
 *								*
 *	The various constructors are declared here and called	*
 *	during module load as a work-around to this problem	*
 * ************************************************************	*/
 
void ni_ifreq_ctor();
void ni_in6_ifreq_ctor();
void ni_lifreq_ctor();
void ni_linuxproc_ctor();

/* ****************************************************	*
 *	developer support, not for production		*
 * ****************************************************	*/

int
ni_developer(enum ni_FLAVOR type);

void
ni_getifaddrs_dump(int flavor, struct ifaddrs * ifap);

#endif
