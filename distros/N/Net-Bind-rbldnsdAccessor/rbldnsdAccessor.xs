/* rbldnsdAccessor.xs
 *
 * Copyright 2006, Michael Robinton <michael@bizsystems.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "rbldnsd/rbldnsd.h"
#include "rblf_base.h"
#include "rblf_isc_result.h"
#include "rblf_defines.h"

#include "rbldnsdaccessor.c"	/*	memory allocation routines	*/

extern struct dnspacket pkt;

struct rblf_info rblfi;
int invalid_pkt = 1;

char abuf[RBLF_DLEN];

MODULE = Net::Bind::rbldnsdAccessor	PACKAGE = Net::Bind::rbldnsdAccessor

PROTOTYPES: DISABLE

int
return_constants()

    ALIAS:
	Net::Bind::rbldnsdAccessor::RBLF_DLEN			= RBLF_DLEN
	Net::Bind::rbldnsdAccessor::ISC_R_SUCCESS		= ISC_R_SUCCESS
	Net::Bind::rbldnsdAccessor::ISC_R_NOMEMORY		= ISC_R_NOMEMORY
	Net::Bind::rbldnsdAccessor::ISC_R_TIMEDOUT		= ISC_R_TIMEDOUT
	Net::Bind::rbldnsdAccessor::ISC_R_NOTHREADS		= ISC_R_NOTHREADS
	Net::Bind::rbldnsdAccessor::ISC_R_ADDRNOTAVAIL		= ISC_R_ADDRNOTAVAIL
	Net::Bind::rbldnsdAccessor::ISC_R_ADDRINUSE		= ISC_R_ADDRINUSE
	Net::Bind::rbldnsdAccessor::ISC_R_NOPERM		= ISC_R_NOPERM
	Net::Bind::rbldnsdAccessor::ISC_R_NOCONN		= ISC_R_NOCONN
	Net::Bind::rbldnsdAccessor::ISC_R_NETUNREACH		= ISC_R_NETUNREACH
	Net::Bind::rbldnsdAccessor::ISC_R_HOSTUNREACH		= ISC_R_HOSTUNREACH
	Net::Bind::rbldnsdAccessor::ISC_R_NETDOWN		= ISC_R_NETDOWN
	Net::Bind::rbldnsdAccessor::ISC_R_HOSTDOWN		= ISC_R_HOSTDOWN
	Net::Bind::rbldnsdAccessor::ISC_R_CONNREFUSED		= ISC_R_CONNREFUSED
	Net::Bind::rbldnsdAccessor::ISC_R_NORESOURCES		= ISC_R_NORESOURCES
	Net::Bind::rbldnsdAccessor::ISC_R_EOF			= ISC_R_EOF
	Net::Bind::rbldnsdAccessor::ISC_R_BOUND			= ISC_R_BOUND
	Net::Bind::rbldnsdAccessor::ISC_R_RELOAD		= ISC_R_RELOAD
	Net::Bind::rbldnsdAccessor::ISC_R_LOCKBUSY		= ISC_R_LOCKBUSY
	Net::Bind::rbldnsdAccessor::ISC_R_EXISTS		= ISC_R_EXISTS
	Net::Bind::rbldnsdAccessor::ISC_R_NOSPACE		= ISC_R_NOSPACE
	Net::Bind::rbldnsdAccessor::ISC_R_CANCELED		= ISC_R_CANCELED
	Net::Bind::rbldnsdAccessor::ISC_R_NOTBOUND		= ISC_R_NOTBOUND
	Net::Bind::rbldnsdAccessor::ISC_R_SHUTTINGDOWN		= ISC_R_SHUTTINGDOWN
	Net::Bind::rbldnsdAccessor::ISC_R_NOTFOUND		= ISC_R_NOTFOUND
	Net::Bind::rbldnsdAccessor::ISC_R_UNEXPECTEDEND		= ISC_R_UNEXPECTEDEND
	Net::Bind::rbldnsdAccessor::ISC_R_FAILURE		= ISC_R_FAILURE
	Net::Bind::rbldnsdAccessor::ISC_R_IOERROR		= ISC_R_IOERROR
	Net::Bind::rbldnsdAccessor::ISC_R_NOTIMPLEMENTED	= ISC_R_NOTIMPLEMENTED
	Net::Bind::rbldnsdAccessor::ISC_R_UNBALANCED		= ISC_R_UNBALANCED
	Net::Bind::rbldnsdAccessor::ISC_R_NOMORE		= ISC_R_NOMORE
	Net::Bind::rbldnsdAccessor::ISC_R_INVALIDFILE		= ISC_R_INVALIDFILE
	Net::Bind::rbldnsdAccessor::ISC_R_BADBASE64		= ISC_R_BADBASE64
	Net::Bind::rbldnsdAccessor::ISC_R_UNEXPECTEDTOKEN	= ISC_R_UNEXPECTEDTOKEN
	Net::Bind::rbldnsdAccessor::ISC_R_QUOTA			= ISC_R_QUOTA
	Net::Bind::rbldnsdAccessor::ISC_R_UNEXPECTED		= ISC_R_UNEXPECTED
	Net::Bind::rbldnsdAccessor::ISC_R_ALREADYRUNNING	= ISC_R_ALREADYRUNNING
	Net::Bind::rbldnsdAccessor::ISC_R_IGNORE		= ISC_R_IGNORE
	Net::Bind::rbldnsdAccessor::ISC_R_MASKNONCONTIG		= ISC_R_MASKNONCONTIG
	Net::Bind::rbldnsdAccessor::ISC_R_FILENOTFOUND		= ISC_R_FILENOTFOUND
	Net::Bind::rbldnsdAccessor::ISC_R_FILEEXISTS		= ISC_R_FILEEXISTS
	Net::Bind::rbldnsdAccessor::ISC_R_NOTCONNECTED		= ISC_R_NOTCONNECTED
	Net::Bind::rbldnsdAccessor::ISC_R_RANGE			= ISC_R_RANGE
	Net::Bind::rbldnsdAccessor::ISC_R_NOENTROPY		= ISC_R_NOENTROPY
	Net::Bind::rbldnsdAccessor::ISC_R_MULTICAST		= ISC_R_MULTICAST
	Net::Bind::rbldnsdAccessor::ISC_R_NOTFILE		= ISC_R_NOTFILE
	Net::Bind::rbldnsdAccessor::ISC_R_NOTDIRECTORY		= ISC_R_NOTDIRECTORY
	Net::Bind::rbldnsdAccessor::ISC_R_QUEUEFULL		= ISC_R_QUEUEFULL
	Net::Bind::rbldnsdAccessor::ISC_R_FAMILYMISMATCH	= ISC_R_FAMILYMISMATCH
	Net::Bind::rbldnsdAccessor::ISC_R_FAMILYNOSUPPORT	= ISC_R_FAMILYNOSUPPORT
	Net::Bind::rbldnsdAccessor::ISC_R_BADHEX		= ISC_R_BADHEX
	Net::Bind::rbldnsdAccessor::ISC_R_TOOMANYOPENFILES	= ISC_R_TOOMANYOPENFILES
	Net::Bind::rbldnsdAccessor::ISC_R_NOTBLOCKING		= ISC_R_NOTBLOCKING
	Net::Bind::rbldnsdAccessor::ISC_R_UNBALANCEDQUOTES	= ISC_R_UNBALANCEDQUOTES
	Net::Bind::rbldnsdAccessor::ISC_R_INPROGRESS		= ISC_R_INPROGRESS
	Net::Bind::rbldnsdAccessor::ISC_R_CONNECTIONRESET	= ISC_R_CONNECTIONRESET
	Net::Bind::rbldnsdAccessor::ISC_R_SOFTQUOTA		= ISC_R_SOFTQUOTA
	Net::Bind::rbldnsdAccessor::ISC_R_BADNUMBER		= ISC_R_BADNUMBER
	Net::Bind::rbldnsdAccessor::ISC_R_DISABLED		= ISC_R_DISABLED
	Net::Bind::rbldnsdAccessor::ISC_R_MAXSIZE		= ISC_R_MAXSIZE
	Net::Bind::rbldnsdAccessor::ISC_R_BADADDRESSFORM	= ISC_R_BADADDRESSFORM
	Net::Bind::rbldnsdAccessor::ISC_R_NRESULTS		= ISC_R_NRESULTS

    CODE:
	RETVAL = ix;

    OUTPUT:
	RETVAL


void
rblf_strncpy(src,max,c)
        char * src
        int max
        char c

    PREINIT:
        SV * len;

    PPCODE:
        if (max >= RBLF_DLEN)
          croak ("maximum transfer length exceeds internal buffer %d\n",RBLF_DLEN);

        memset(abuf,c,RBLF_DLEN);
        XPUSHs(sv_2mortal(newSViv(rblf_strncpy(abuf,src,max))));

        if (GIMME != G_ARRAY)
          XSRETURN(1);

        XPUSHs(sv_2mortal(newSVpv((char *)abuf,RBLF_DLEN)));
        XSRETURN(2);


void
rblf_load_dnstest(buffer)
	SV * buffer

    PREINIT:
	STRLEN len;
	unsigned char * cp;
	int rv;

    PPCODE:
	invalid_pkt = 1;
	cp = (unsigned char *)SvPV(buffer,len);
	bzero(&pkt,sizeof(struct dnspacket));
	rv = rblf_safemcpy(pkt.p_buf, cp, (size_t)len,(pkt.p_buf + DNS_MAXPACKET));
	if (rv < 0) {
	bail:
	  if (GIMME_V != G_ARRAY)
	    XSRETURN_UNDEF;
	  XSRETURN_EMPTY;
	}
	cp = pkt.p_buf;
	pkt.p_endp = cp + len;
	cp += p_hdrsize + 4;			/*	point to question	*/
	if (rblf_skip(&cp,pkt.p_endp) < 0)	/*	skip over question	*/
	  goto bail;
	invalid_pkt = 0;
	pkt.p_cur = pkt.p_sans = cp +4;
	XPUSHs(sv_2mortal(newSViv(pkt.p_buf[p_ancnt2])));	/*	answer count		*/

	if (GIMME != G_ARRAY)
	  XSRETURN(1);

	XPUSHs(sv_2mortal(newSViv(rv)));	/*	offset		*/
	XSRETURN(2);


void
rblf_next_answer()
    PREINIT:
	SV * rd;

    PPCODE:
	if (invalid_pkt) {
	bail:
	  if (GIMME_V != G_ARRAY)
	    XSRETURN_UNDEF;
	  XSRETURN_EMPTY;
	}

	if (rblf_answer(&rblfi,&(pkt.p_cur),pkt.p_buf,pkt.p_endp) < 0)
	  goto bail;

	XPUSHs(sv_2mortal(newSViv(rblfi.type)));

	if (GIMME != G_ARRAY)
	  XSRETURN(1);

	XPUSHs(sv_2mortal(newSViv(rblfi.ttl)));
	XPUSHs(sv_2mortal(newSViv(rblfi.rdl)));
	rd = sv_newmortal();
	sv_setpvn(rd, (char *)rblfi.rdata,rblfi.rdl);
	XPUSHs(rd);
	XPUSHs(sv_2mortal(newSViv(pkt.p_cur - pkt.p_buf)));
	XSRETURN(5);


unsigned int
rblf_create_zone(zone,...)
	char * zone

    PREINIT:
	int i;
	char * argv[256];
	STRLEN len;

    CODE:
	if (items < 3)
	  croak("ERROR: not enough arguments");

	if (items > 256)
	  croak("ERROR: to many arguments");

	for (i=1; i<items;i++) {
	  argv[i -1] = SvPV(ST(i),len);
	}
	RETVAL = rblf_create_zone(zone,(int)(items -1),argv,NULL,NULL);

    OUTPUT:
	RETVAL


void
rblf_query(name)
	char * name

    PREINIT:
	int answers = 0;

    PPCODE:
	invalid_pkt = rblf_query(name,&pkt);
	if (!invalid_pkt)
	  answers = (int)(pkt.p_buf[p_ancnt2]);

	XPUSHs(sv_2mortal(newSViv(answers)));
	if (GIMME == G_ARRAY) {
	  XPUSHs(sv_2mortal(newSViv(invalid_pkt)));
	  XSRETURN(2);
	}

	XSRETURN(1);


void
rblf_dump_packet()

    PREINIT:
	STRLEN len;

    PPCODE:
	if (pkt.p_endp == NULL) {
	bail:
	  if (GIMME != G_ARRAY)
	    XSRETURN_UNDEF;
	  XSRETURN_EMPTY;
	}

	if ((len = pkt.p_endp - pkt.p_buf) > DNS_MAXPACKET || len <= 0)
	  goto bail;

	XPUSHs(sv_2mortal(newSViv(len)));
	if (GIMME != G_ARRAY)
	  XSRETURN(1);

	XPUSHs(sv_2mortal(newSVpvn((char *)pkt.p_buf,len)));
	XPUSHs(sv_2mortal(newSViv((I32)pkt.p_buf)));
	XPUSHs(sv_2mortal(newSViv((I32)pkt.p_cur)));
	XPUSHs(sv_2mortal(newSViv((I32)pkt.p_sans)));
	XPUSHs(sv_2mortal(newSViv((I32)pkt.p_endp)));
	XPUSHs(sv_2mortal(newSViv(pkt.p_cur - pkt.p_buf)));
	XPUSHs(sv_2mortal(newSViv(pkt.p_sans - pkt.p_buf)));
	XSRETURN(8);


void
rblf_reinit()

    CODE:
	rblf_drop();
