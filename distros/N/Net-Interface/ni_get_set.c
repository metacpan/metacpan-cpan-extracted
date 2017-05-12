/* ********************************************************************	*
 *	ni_get_set.c	version 0.01	2-8-09				*
 *									*
 *     COPYRIGHT 2009 Michael Robinton <michael@bizsystems.com>		*
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

/* ****************************************************	*
 *	standard SIOCget functions			*
 *							*
 *	execute supported ioctl's			*
 *	where a value is requested, return it		*
 *	otherwise it is up to the user to retrieve	*
 *	information via their pointers			*
 *	returns -1 on error, sets errno			*
 * ****************************************************	*/

int32_t
ni_get_any(int fd, int cmd, void * ifr)
{
    switch (cmd) {
    case SIOCGIFMTU :
    case SIOCGIFMETRIC :
    case SIOCGIFFLAGS :
#ifdef SIOCGIFINDEX
    case SIOCGIFINDEX :
#endif
    case SIOCGIFADDR :
    case SIOCGIFNETMASK :
    case SIOCGIFBRDADDR :
    case SIOCGIFDSTADDR :
	break;
    default :
        errno = ENOSYS;
        return -1;
    }
    if (ioctl(fd,cmd,ifr) < 0)
	return -1;

    switch (cmd) {
    case SIOCGIFFLAGS :
    case SIOCGIFMETRIC :
    case SIOCGIFMTU :
#ifdef SIOCGIFINDEX
    case SIOCGIFINDEX :
#endif
	return ((struct nifreq *)ifr)->ni_int;
    }
    return 0;
}

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

#if defined (__ni_Linux) && defined (LOCAL_SIZEOF_SOCKADDR_IN6)
struct lin6_ifreq {
    struct in6_addr	lin6_addr;
    u_int32_t		lin6_prfx;
    u_int		lin6_indx;
};
# endif


/*	This routine must have ALL possible set commands
 *	Remember that ifr may need offset as is the case with LIFREQ
 *	Use with care. See $if->flags in Interface.xs
 */
 
int
ni_set_any(int fd, int cmd, struct nifreq * ifr)
{
#if defined (__ni_Linux) && defined (LOCAL_SIZEOF_SOCKADDR_IN6)
    struct lin6_ifreq ifr6;
#endif

    switch (cmd) {
    case SIOCSIFFLAGS :
#ifdef SIOCSLIFFLAGS
    case SIOCSLIFFLAGS :
#endif
    case SIOCSIFMETRIC :
    case SIOCSIFMTU :
	break;
    case SIOCSIFADDR :
    case SIOCSIFDSTADDR :
    case SIOCSIFBRDADDR :
    case SIOCSIFNETMASK :
#ifdef SIOCDIFADDR
    case SIOCDIFADDR :
#endif
#if defined (__ni_Linux) && defined (LOCAL_SIZEOF_SOCKADDR_IN6)
	if (ifr->ni_saddr.sa_family == AF_INET6) {
	    memcpy(&ifr6.lin6_addr,&ifr->ni_sin6.sin6_addr,LOCAL_SIZEOF_SOCKADDR_IN6);
	    ifr6.lin6_prfx = ifr->ni_sin6.sin6_port;	/* temporarily stored here	*/
	    if (ioctl(fd,SIOCGIFINDEX,&ifr) < 0)
		return -1;
	    ifr6.lin6_indx = ifr->ni_ushort;
	    ifr = (struct nifreq *)&ifr6;		/* lie about cast	*/
	}
#endif
	break;
    default :
        errno = ENOSYS;
        return -1;
    }
    if (ioctl(fd,cmd,ifr) < 0)
	return -1;
    return 0;
}
