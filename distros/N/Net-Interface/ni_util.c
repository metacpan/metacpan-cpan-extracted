
/* ********************************************************************	*
 * ni_util.c	version 0.01 1-12-09					*
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
 
/* duplicate allocate memory and return pointer **** memory must be freed */

void *
ni_memdup(void * memp, int size)
{
    void * newmp;
    if ((newmp = malloc(size)) == NULL) {
        errno = ENOMEM;
	return NULL;
    }
    return memcpy(newmp,memp,size);
}

/* two functions to conditionally close and reopen an ifconf socket
 *
 * if fd is < 0 it is ignored
 * af is modified if required
 */
 
int
ni_clos_reopn_dgrm(int fd, u_int af)
{
    if (fd >= 0)
    	close(fd);
    af == AF_UNSPEC ? AF_INET : af;
    return socket(af,SOCK_DGRAM,0);
}

/* ****************************************************	*
 *	provide _SIZEOF_ADDR_IFREQ(ifr) equivalent	*
 *	that will cover our use of in6_ifreq, lifreq	*
 * ****************************************************	*/

#ifdef _SIZEOF_ADDR_IFREQ
int
ni_SIZEOF_ADDR_IFREQ(struct ifreq * ifrp,struct sockaddr * sa,int size)
{
    struct ifreq ifr;
    
    memcpy(&ifr,ifrp,sizeof(struct ifreq));
    return _SIZEOF_ADDR_IFREQ(ifr);
}
#endif

/* ****************************************************	*
 *	on systems with embedded scope, get it 		*
 * 	and correct the bits in the addrsess		*
 * ****************************************************	*/
 
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6

u_int
ni_get_scopeid(struct sockaddr_in6 * sin6)
{
    unsigned int scopeid = 0;
# ifdef __KAME__
    if (IN6_IS_ADDR_LINKLOCAL(&sin6->sin6_addr)) {
    	scopeid = ntohs(*(u_int16_t *)&sin6->sin6_addr.s6_addr[2]);
    	sin6->sin6_addr.s6_addr[2] = sin6->sin6_addr.s6_addr[3] = 0;
    }
# elif defined HAVE_SIN6_SCOPEID
    scopeid =  sin6->sin6_scopeid;
# endif
    return scopeid;
}

#endif

/* ****************************************************	*
 *	generate a netmask from a prefix length		*
 * ****************************************************	*/
 
void
ni_plen2mask(void * in_addr, int plen, int sizeofaddr)
{
    char * mask = in_addr;
    int ffs, rm, i;
    
    ffs	= plen / 8;
    rm	= plen % 8;

    if (rm != 0) {
    	rm = 8 - rm;
    	rm = 0xFFu << rm;
    }
    for (i = 0; i < ffs; i++)
    	mask[i] = 0xFFu;

    if (rm != 0) {
	mask[i] = rm;
	i++;
    }
    for (; i < sizeofaddr; i++)
        mask[i] = 0;
}

/* ****************************************************	*
 *	calculate the length of netmask prefix		*
 * ****************************************************	*/
 
int
ni_prefix(void * ap, int sz)
{
    unsigned char byte, * addr = (unsigned char *)ap;
    int bit, bp, plen = 0;

    for (bp = 0; bp < sz; bp++) {
      if (addr[bp] != 0xFFu)
          break;
      plen += 8;
    }

    if (bp == sz)
	return plen;

    byte = addr[bp];

    for (bit = 0x80u; bit != 0; bit >>= 1) {	/*  for (bit = 7; bit != 0; bit--, plen++)	*/
        if (byte & bit)	{			/*	if (!(name[byte] & (1 << bit)))		*/
            byte ^= bit;			/*	    break;				*/
            plen++;
        }
        else if (byte != 0)			/*  for (; bit != 0; bit--)			*/
	    return 0;				/*	if (name[byte] & (1 << bit))		*/
        else					/*	    return 0;				*/
            break;
    }

    bp++;
    for (; bp < sz; bp++) {
        if (addr[bp] != 0)
	    return 0;
    }
     return plen;
}

/* ****************************************************	*
 *		constructor registration		*
 * ****************************************************	*/

/*	for ifreq or equivalent flavor support		*/

struct ni_ifconf_flavor * nifcf = NULL;

void
ni_ifcf_register(struct ni_ifconf_flavor * nifp)
{
    nifp->ni_ifcf_next = nifcf;
    nifcf = nifp;
}

struct ni_ifconf_flavor *
ni_ifcf_get(enum ni_FLAVOR type)
{
    struct ni_ifconf_flavor * nifp;
    for (nifp = nifcf; nifp != NULL; nifp = nifp->ni_ifcf_next)
        if (nifp->ni_type == type)
            return nifp;
    errno = ENOSYS;
    return NULL;
}

struct ni_ifconf_flavor *
ni_safe_ifcf_get(enum ni_FLAVOR type)
{
    struct ni_ifconf_flavor * nifp;

    if ((nifp = ni_ifcf_get(type)) != NULL)
	return nifp;
    return ni_ifcf_get(NI_IFREQ);
}

/* ****************************************************	*
 *	developer support, not for production		*
 * ****************************************************	*/

int
ni_developer(enum ni_FLAVOR type)
{
    void * notused = NULL;
    struct ni_ifconf_flavor * nifp = ni_ifcf_get(type);
    if (nifp == NULL)
    	return ENOSYS;
    return nifp->developer(notused);
}

/* ****************************************************	*
 *	IPV6 support for linux like type info		*
 * ****************************************************	*/

/* does not have to be ifdef'd #ifdef LOCAL_SIZEOF_SOCKADDR_IN6	*/

/*	scope flags	rfc-2373
 *
	0 	  reserved
	1	node-local
	2	link-local
	3	  unassigned
	4	  unassigned
	5	site-local
	6	  unassigned
	7	  unassigned
	8	organization-local
	9	  unassigned
	A	  unassigned
	B	  unassigned
	C	  unassigned
	D	  unassigned
	E	global scope
	F	  reserved
 */

# ifdef ___NEVER_DEFINED___for_info
/*			      0x0000	  0xe
#define IPV6_ADDR_LOOPBACK      0x0010u /*      0x1     aka NODELOCAL, INTERFACELOCAL */
#define IPV6_ADDR_LINKLOCAL     0x0020u /*      0x2     */
#define IPV6_ADDR_SITELOCAL     0x0040u /*      0x5     */
#define IPV6_ADDR_COMPATv4	0x0080u /*	0x10	mapped back out of range */
# endif

int
ni_lx_type2scope(int lscope)
{
    lscope &= 0xF0u;
    switch (lscope) {
    case 0 :
	return 0xEu;
    case 0x10 :
	return 0x1;
    case 0x20 :
	return 0x2;
    case 0x40 :
	return 0x5;
    case 0x80:
    	return 0x10;	/* linux compat-v4	*/
    }
    return 0;
}

const ni_iff_t ni_lx_type2txt[] = {
	{ IPV6_ADDR_ANY,		"addr-any" },
	{ IPV6_ADDR_UNICAST,		"unicast" },
	{ IPV6_ADDR_MULTICAST,		"multicast" },
	{ IPV6_ADDR_ANYCAST,		"anycast" },
	{ IPV6_ADDR_LOOPBACK,		"loopback" },
	{ IPV6_ADDR_LINKLOCAL,		"link-local" },
	{ IPV6_ADDR_SITELOCAL,		"site-local" },
	{ IPV6_ADDR_COMPATv4,		"compat-v4" },
	{ IPV6_ADDR_SCOPE_MASK,		"scope-mask" },
	{ IPV6_ADDR_MAPPED,		"mapped" },
	{ IPV6_ADDR_RESERVED,		"reserved" },
	{ IPV6_ADDR_ULUA,		"uniq-lcl-unicast" },
	{ IPV6_ADDR_6TO4,		"6to4" },
	{ IPV6_ADDR_6BONE,		"6bone" },
	{ IPV6_ADDR_AGU,		"global-unicast" },
	{ IPV6_ADDR_UNSPECIFIED,	"unspecified" },
	{ IPV6_ADDR_SOLICITED_NODE,	"solicited-node" },
	{ IPV6_ADDR_ISATAP,		"ISATAP" },
	{ IPV6_ADDR_PRODUCTIVE,		"productive" },
	{ IPV6_ADDR_6TO4_MICROSOFT,	"6to4-ms" },
	{ IPV6_ADDR_TEREDO,		"teredo" },
	{ IPV6_ADDR_ORCHID,		"orchid" },
	{ IPV6_ADDR_NON_ROUTE_DOC,	"non-routeable-doc" }
};

int
ni_sizeof_type2txt()
{
    return sizeof(ni_lx_type2txt);
}

void
ni_linux_scope2txt(uint32_t flags)
{
    int i, n = sizeof(ni_lx_type2txt) / sizeof(ni_iff_t);
    
    for (i=0; i < n; i++)
    	if (flags & ni_lx_type2txt[i].iff_val)
    	    printf("%s ",ni_lx_type2txt[i].iff_nam);
}

/* does not have to be ifdef'd #endif	LOCAL_SIZEOF_SOCKADDR_IN6 */
