/* ********************************************************************	*
 * ni_fallbackhwaddr.c	version 0.01	2-3-09				*
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

unsigned char *
ni_fallbackhwaddr(u_int af, void * vifr)
{
    struct nifreq * ifr = (struct nifreq * )vifr;
    int i, n, dflgs, ppa, fd = -1;
    char * p;
#ifdef HAVE_STRUCT_IFDEVEA
    struct ifdevea physaddr;
#endif
#ifdef HAVE_NETIO_H
    struct fis * ioctl_arg;
#endif
#ifdef HAVE_SYS_DLPI_H
    char name[IFNAMSIZ +5], dlpbuf[DL_MAXIMUM];
    struct strbuf ctrl;
    union DL_primitives dlp;
    dl_info_ack_t * dlpi = (dl_info_ack_t *)dlpbuf;
# ifdef DL_ATTACH_REQ
    dl_ok_ack_t * dlpa = (dl_ok_ack_t *)dlpbuf;
    dl_bind_ack_t * dlpb = (dl_bind_ack_t *)dlpbuf;
    dl_phys_addr_ack_t * dlpp = (dl_phys_addr_ack_t *)dlpbuf;
# endif
#endif

#if defined (SIOCGIFHWADDR) || defined (SIOCGENADR) || (defined (HAVE_STRUCT_IFDEVEA) && defined (SIOCPHYSADDR))

    if ((fd = ni_clos_reopn_dgrm(fd,af)) < 0)
        goto dgrm_failed;

# ifdef SIOCGIFHWADDR
    if (ioctl(fd,SIOCGIFHWADDR,ifr) != -1 && NI_MAC_NOT_ZERO(&ifr->ni_saddr.sa_data)) {
	close(fd);
        return (unsigned char *)(&ifr->ni_saddr.sa_data);
    }
# endif

# ifdef SIOCGENADDR
    if (ioctl(fd,SIOCGENADDR,ifr) != -1 && NI_MAC_NOT_ZERO(&ifr->ni_char)) {
	close(fd);
    	return (unsigned char *)&ifr->ni_char;
    }
# endif

# if defined (HAVE_STRUCT_IFDEVEA) && defined (SIOCSPHYSADDR)
    bzero(phys.ifr_name,sizeof(physaddr));
    strlcpy(physaddr.ifr_name,ifr->ni_ifr_name,IFNAMSIZ);
    if (ioctl(fd,SIOCPHYSADDR,&physaddr) >= 0 && NI_MAC_NOT_ZERO(physaddr.current_pa)) {
        memcpy(&ifr->ni_char,&physaddr.current_pa[0]);
	close(fd);
        return (unsigned char *)&ifr->ni_char;
    }
# endif

    close(fd);
  dgrm_failed:

#endif	/* all that stuff above	*/

/*	ok, could not get the MAC address the easy way, try harder	*/

#ifdef HAVE_NIT_IF_H
    if ((fd = open("/dev/nit",0)) >= 0) {
    	if (ioctl(fd,NIOCBIND,ifr) >= 0 &&
    	    ioctl(fd,SIOCGIFADDR) >= 0) {
    	    close(fd);
    	    if (NI_MAC_NOT_ZERO(&ifr->ni_char))
    	        return (unsigned char *)&ifr->ni_char;
    	else
    	    close(fd);
    }
#endif

/* http://www.informatik.uni-frankfurt.de/doc/man/hpux/lan.7.html	*/

#ifdef HAVE_NETIO_H
    if ((fd = open(&ifr->ni_ifr_name,O_RDONLY)) >= 0) {
	bzero(&ioctl_arg,sizeof(struct fis));
	ioctl_arg.reqtype = LOCAL_ADDRESS;
	if (ioctl(fd,NETSTAT,&ioctl_arg) >= 0) {
	    close(fd);
	    if (ioctl_arg.vtype == 6) {
		memcpy(&ifr->ni_char,&ioctl_arg.value.s[0],6);
		return (unsigned char *)&ifr->ni_char;
	    }
	}
	close(fd);
    }
#endif

#ifdef HAVE_SYS_DLPI_H
    ppa = -1;
    sprintf(name,"/dev/%s",&ifr->ni_ifr_name);
    if ((fd = open(name,O_RDWR)) < 0) {
/*	try opening without the ppa number	*/
	n = strlen(name);
	p = name;
	p += 5;
	for(i=5;i<n;i++,p++) {
	    if (isdigit(*p)) {
		if (ppa < 0) {
		    ppa = *p - '0';	/* terminate the name at the ppa number start	*/
		    *p = '\0';		/* but continue for multi digit ppa numbers	*/
		}
		else {
		    ppa *= 10;
		    ppa += (*p - '0');
		}
	    }
	}
	if (ppa < 0 || (fd = open(name,O_RDWR)) < 0) {
/*	as a last resort, try /dev/dlpi		*/
	    if ((fd = open("/dev/dlpi",O_RDWR)) < 0)
		goto hwaddr_error;
	}
    }
/* get INFO and hardware mac address	*/
    bzero(&ctrl,sizeof(ctrl));
    dlp.dl_primitive = DL_INFO_REQ;
    ctrl.buf = (char *)&dlp;
    ctrl.len = DL_INFO_REQ_SIZE;
    if (putmsg(fd,&ctrl,NULL,0) < 0)
	goto dlpi_error;
    ctrl.buf = (char *)&dlpbuf;
    ctrl.len = 0;
    ctrl.maxlen = DL_MAXIMUM;
    i = RS_HIPRI;	/* flags */
    bzero(dlpbuf,DL_MAXIMUM);
    if (getmsg(fd,&ctrl,NULL,&i) < 0)
	goto dlpi_error;
    if (dlpi->dl_primitive != DL_INFO_ACK)
    	goto dlpi_error;
/* have hardware mac, might not be current mac	*/
    memcpy(&ifr->ni_ifr_name,(dlpbuf + dlpi->dl_addr_offset),6);

# ifdef DL_ATTACH_REQ

    if (ppa < 0 || dlpi->dl_provider_style != DL_STYLE2)
	goto dlpi_ret_hw;
    bzero(&ctrl,sizeof(ctrl));
    dlp.attach_req.dl_primitive = DL_ATTACH_REQ;
    dlp.attach_req.dl_ppa = ppa;
    ctrl.buf = (char *)&dlp;
    ctrl.len = DL_ATTACH_REQ_SIZE;
    if (putmsg(fd,&ctrl,NULL,0) < 0)
	goto dlpi_ret_hw;
    ctrl.buf = (char *)&dlpbuf;
    ctrl.len = 0;
    ctrl.maxlen = DL_MAXIMUM;
    i = RS_HIPRI;	/* flags */
    bzero(dlpbuf,DL_OK_ACK_SIZE);
    if (getmsg(fd,&ctrl,NULL,&i) < 0)
	goto dlpi_ret_hw;
    if (dlpa->dl_primitive != DL_OK_ACK)
	goto dlpi_ret_hw;

# endif	/* DL_ATTACH_REQ */

    bzero(&ctrl,sizeof(ctrl));
    dlp.dl_primitive = DL_PHYS_ADDR_REQ;
    dlp.physaddr_req.dl_addr_type = DL_CURR_PHYS_ADDR;
    ctrl.buf = (char *)&dlp;
    ctrl.len = DL_PHYS_ADDR_REQ_SIZE;
    if (putmsg(fd,&ctrl,NULL,0) < 0)
	goto dlpi_ret_hw;
    ctrl.buf = (char *)&dlpbuf;
    ctrl.len = 0;
    ctrl.maxlen = DL_MAXIMUM;
    i = RS_HIPRI;	/* flags */
    bzero(dlpbuf,DL_MAXIMUM);
    if (getmsg(fd,&ctrl,NULL,&i) < 0)
	goto dlpi_ret_hw;
    if (dlpi->dl_primitive != DL_PHYS_ADDR_ACK)
    	goto dlpi_ret_hw;
/* have current MAC address, return it	*/
    memcpy(ifr->ni_ifr_name,(dlpbuf + dlpp->dl_addr_offset),6);

  dlpi_ret_hw:
	close(fd);
        return (unsigned char *)&ifr->ni_ifr_name[0];

  dlpi_error:
	close(fd);
#endif	/* HAVE_SYS_DLPI_H	*/

  hwaddr_error:
    errno = ENOSYS;
    return NULL;
}
