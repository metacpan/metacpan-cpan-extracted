/* ToolKit.xs
 *
 *    Copyright 2003 - 2011, Michael Robinton <michael@bizsystems.com>
 *
 * Michael Robinton <michael@bizsystems.com>
 *
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of either:
 *
 *  a) the GNU General Public License as published by the Free
 *  Software Foundation; either version 2, or (at your option) any
 *  later version, or
 *
 *  b) the "Artistic License" which comes with this distribution.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either    
 * the GNU General Public License or the Artistic License for more details.
 *
 * You should have received a copy of the Artistic License with this
 * distribution, in the file named "Artistic".  If not, I'll be glad to provide
 * one.
 *
 * You should also have received a copy of the GNU General Public License
 * along with this program in the file named "Copying". If not, write to the
 *
 *       Free Software Foundation, Inc.                        
 *       59 Temple Place, Suite 330
 *       Boston, MA  02111-1307, USA                                     
 *
 * or visit their web page on the internet at:                      
 *
 *       http://www.gnu.org/copyleft/gpl.html.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "u_intxx.h"

/* for size of string buffer below	*/
#include <netdb.h>
#include <resolv.h>
#include <arpa/nameser.h>
#ifdef  BIND_4_COMPAT
#include <arpa/nameser_compat.h>
#endif
#include "ToolKit.h"

/* for clock	*/
#include <time.h>

/* for resolver	*/
struct __res_state res;

#ifdef RES_XINIT
#define RES_Init RES_INIT | RES_XINIT
#else
#define RES_Init RES_INIT
#endif

/* from	/usr/include/arpa/nameser_compat.h, modified a little	*/
typedef struct {
	unsigned	id :16;	 /* query identification number */
#ifdef host_is_BIG_ENDIAN
			/* fields in third byte */
	unsigned	qr :1;		/* response flag */
	unsigned	opcode :4;	/* purpose of message */
	unsigned	aa :1;		/* authoritive answer */
	unsigned	tc :1;		/* truncated message */
	unsigned	rd :1;		/* recursion desired */
			/* fields in fourth byte */
	unsigned	ra :1;		/* recursion available */
	unsigned	z :1;		/* unused bits (MBZ as of 4.9.3a3) */
	unsigned	ad :1;		/* authentic data from named */
	unsigned	cd :1;		/* checking disabled by resolver */
	unsigned	rcode :4;	/* response code */
#else
# ifdef host_is_LITTLE_ENDIAN
			/* fields in third byte */
	unsigned	rd :1;		/* recursion desired */
	unsigned	tc :1;		/* truncated message */
	unsigned	aa :1;		/* authoritive answer */
	unsigned	opcode :4;	/* purpose of message */
	unsigned	qr :1;		/* response flag */
			/* fields in fourth byte */
	unsigned	rcode :4;	/* response code */
	unsigned	cd :1;		/* checking disabled by resolver */
	unsigned	ad :1;		/* authentic data from named */
	unsigned	z :1;		/* unused bits (MBZ as of 4.9.3a3) */
	unsigned	ra :1;		/* recursion available */
# else
# error ENDIANness is not defined
# endif
#endif
			/* remaining bytes */
	unsigned	qdcount :16;    /* number of question entries */
	unsigned	ancount :16;    /* number of answer entries */
	unsigned	nscount :16;    /* number of authority entries */
	unsigned	arcount :16;    /* number of resource entries */
} MY_HEADER;

u_char * dnptrs[20];

struct in_addr i2p;

struct timeval tv;

#ifdef lastchanceTEST
#ifndef NO_RESOLV_CONF
#define NO_RESOLV_CONF
#endif
#endif

struct __res_state my_res_state;
struct sockaddr_in mysa;

#ifdef _PATH_RESCONF
char *path = _PATH_RESCONF;
size_t pathz = sizeof(_PATH_RESCONF);
#else
char *path = NULL;
size_t pathz = 0;
#endif

/* ****************************	*
 *	return int's, long's	*
 *	from char string	*
 * ****************************	*
 */

u_short
gint16(u_char * cp)
{
  u_short i;
  NS_GET16(i,cp);
  return(i);
}

u_int32_t
gint32(u_char * cp)
{
  u_int32_t i;
  NS_GET32(i,cp);
  return(i);
}

void
gput16(u_char * cp, unsigned int i)
{
  NS_PUT16(i,cp);
}

void
gput32(u_char * cp, u_int32_t v)
{
  NS_PUT32(v,cp);
}

u_char *
ns_ptr(int i)
{
  i2p.s_addr = _res.nsaddr_list[i].sin_addr.s_addr;
  return((u_char *)&i2p.s_addr);
}

void
mysin()
{
#ifdef USELOOPBACK
	mysa.sin_addr = inet_makeaddr(IN_LOOPBACKNET, 1);
#else
	mysa.sin_addr.s_addr = INADDR_ANY;
#endif
}

int
lchance()
{
#ifndef NO_RESOLV_CONF
  return 0;
#else
#ifdef lastchanceTEST
  my_res_state.options = RES_INIT;
  if (res_ninit(&my_res_state) != 0)		/* punt if we can not initialize resolver interface */
    return 0;
  return my_res_state.nscount;
#else
  memset(&my_res_state,0,sizeof(my_res_state));
  return get_nameservers(&my_res_state);
#endif
#endif
}

MODULE = Net::DNS::ToolKit	PACKAGE = Net::DNS::ToolKit

PROTOTYPES: DISABLE

 # include functions for inet_aton, inet_ntoa, dn_expand

INCLUDE: xs_include/dn_expand.inc

 # int dn_comp(unsigned char *exp_dn, unsigned char *comp_dn, 
 #	int length, unsigned char **dnptrs, unsigned char **lastdnptr);
 #
 # dn_comp
 #	dn_comp() compresses the domain name exp_dn and stores it in 
 #	the buffer comp_dn of length 'length'. The  compression  uses  
 #	an  array of pointers dnptrs to previously compressed names 
 #	in the current message.  The first pointer points to the 
 #	beginning of the message and the list ends with NULL.  The 
 #	limit  of  the  array  is specified  by  lastdnptr.  if dnptr 
 #	is NULL, domain names are not compressed.  If lastdnptr is 
 #	NULL, the list of labels is not updated.
 #

void
dn_comp(buffer, offset, name,...)
	SV * buffer
	int offset
	SV * name
    PROTOTYPE: $$$;@ 
    PREINIT:
	AV * dptr;
	SV **aptrs;
	STRLEN len, size, bsize;
	u_char **lastdnptr, **aoff;
	u_char * exp_dn, * msg, * comp_dn;
	int i, v, dnsize;
    PPCODE:
	if (! SvROK(buffer) || ! SvROK(name))
	    XSRETURN_EMPTY;

 # see: perlapi on 'svtype' and /usr/lib/perl5/i386-linux/CORE/sv.h

	name = SvRV(name);

	if (SvTYPE(name) == SVt_PVGV)		/* debugging, skip dn_comp	*/
	    exp_dn = (u_char *)SvPV(GvSV(name), len);
        if (SvPOK(name))                        /* normal	*/
	    exp_dn = (u_char *)SvPV(name, len);
	else					/* punt, not scalar or glob	*/
	    XSRETURN_EMPTY;

	buffer = SvRV(buffer);
	if (! SvPOK(buffer))
	    XSRETURN_EMPTY;

		# get the size of the buffer
	(void)SvPV(buffer,size);

	if (size != offset)			/* punt if it does not match offset	*/
	    XSRETURN_EMPTY;

		# add some space at the end of the string, get pointer
	msg = (u_char *)SvGROW(buffer, (STRLEN)(size + MAXDNAME));
	comp_dn = msg + offset;

		# setup dnptrs from outside or init them to zero
	dnsize = sizeof dnptrs/sizeof dnptrs[0];
	lastdnptr = dnptrs + dnsize;

	if (items > 3 && SvTRUE(ST(3)) && SvROK(ST(3))) {	/* defined, should be \@dnptrs	*/

	    dptr = (AV *)SvRV(ST(3));	/* array pointer	*/

		# external array must be exactly the same size as internal one
	    i = av_len(dptr);
	    if ( i != dnsize -1)
		XSRETURN_EMPTY;

	    for(i=0;i<dnsize;i++) {
		aptrs = av_fetch(dptr,i,0);
		if (aptrs == NULL)	/* should never happen	*/
		    XSRETURN_EMPTY;

		v = SvIV(*aptrs);
		if (i == 0 || v)
		    dnptrs[i] = msg + v;
		else
		    dnptrs[i] = NULL;
	    }
	} else {
	    memset(dnptrs,0,sizeof(dnptrs));
	    dnptrs[0] = msg;
	}

	if (SvTYPE(name) == SVt_PVGV)
	    dnptrs[0] = NULL;			/* do not compress	*/
	len = dn_comp((char *)exp_dn,comp_dn,MAXDNAME,dnptrs,lastdnptr);

		# set the string length to the new real length	
	SvCUR_set(buffer, (I32)(size + len));

	EXTEND(SP, dnsize + 1);
	PUSHs(sv_2mortal(newSViv(size + len )));
	for(i=0;i<dnsize;i++) {
	    if (dnptrs[i] == NULL)
		PUSHs(sv_2mortal(newSViv(0)));
	    else
		PUSHs(sv_2mortal(newSViv(dnptrs[i] - msg)));
	}
	XSRETURN(dnsize + 1);

 # return the header values
 # ID, QR, Opcode, AA, TC, RD, RA, MBZ, AD, CD, RCODE, QDCOUNT, ANCOUNT, NSCOUNT, ARCOUNT

void
gethead(header)
	SV * header
    PROTOTYPE: $
    PREINIT:
	STRLEN len;
	MY_HEADER * hp;
    PPCODE:
	if (! SvROK(header))
	    XSRETURN_EMPTY;

	hp = (MY_HEADER *)SvPV(SvRV(header),len);
	EXTEND(SP, 16);
	PUSHs(sv_2mortal(newSViv(NS_HFIXEDSZ)));
	PUSHs(sv_2mortal(newSViv(ntohs(hp->id))));
	PUSHs(sv_2mortal(newSViv(hp->qr)));
	PUSHs(sv_2mortal(newSViv(hp->opcode)));
	PUSHs(sv_2mortal(newSViv(hp->aa)));
	PUSHs(sv_2mortal(newSViv(hp->tc)));
	PUSHs(sv_2mortal(newSViv(hp->rd)));
	PUSHs(sv_2mortal(newSViv(hp->ra)));
	PUSHs(sv_2mortal(newSViv(hp->z)));
	PUSHs(sv_2mortal(newSViv(hp->ad)));
	PUSHs(sv_2mortal(newSViv(hp->cd)));
	PUSHs(sv_2mortal(newSViv(hp->rcode)));
	PUSHs(sv_2mortal(newSViv(ntohs(hp->qdcount))));
	PUSHs(sv_2mortal(newSViv(ntohs(hp->ancount))));
	PUSHs(sv_2mortal(newSViv(ntohs(hp->nscount))));
	PUSHs(sv_2mortal(newSViv(ntohs(hp->arcount))));
	XSRETURN(16);

void
parse_char(ch)
	unsigned char ch
    PROTOTYPE: $
    PREINIT:
	u_char bmask[] = {128,64,32,16,8,4,2,1};
	unsigned int i, hi, lo, tens[] = {1000,100,10,1, 1000,100,10,1};
	char out[15];
    PPCODE:
	hi = lo = 0;
	for(i=0;i<4;i++) {
	  if (ch & bmask[i])
		hi += tens[i];
	}
	for(i=4;i<8;i++) {
	  if (ch & bmask[i])
		lo += tens[i];
	}
	EXTEND(SP,4);
	sprintf(out,"%04d_%04d",hi,lo);
	PUSHs(sv_2mortal(newSVpv(out,0)));
	i = (int)ch;
	sprintf(out,"0x%02X",i);
	PUSHs(sv_2mortal( newSVpv(out,0)));
	sprintf(out,"%3d",i);
	PUSHs(sv_2mortal(newSVpv(out,0)));
	if (i < 0x20 || i > 0x7E) {
	    sprintf(out,"%s","");
	    PUSHs(sv_2mortal(newSVpv(out,0)));
	} else {
	    sprintf(out,"%c",ch);
	    PUSHs(sv_2mortal(newSVpv(out,0)));
	}
	XSRETURN(4);

unsigned char
get1char(buffer,off)
	SV * buffer
	unsigned int off
    PROTOTYPE: $$
    PREINIT:
	STRLEN size;
	unsigned char * cp;
    CODE:
	if (!SvROK(buffer))	/* not a pointer	*/
	    XSRETURN_UNDEF;

	cp = (u_char *)(SvPV(SvRV(buffer),size) + off);

	if (size <= off)	/* offset beyond end	*/
	    XSRETURN_UNDEF;

	RETVAL = *cp;
    OUTPUT:
	RETVAL

void
getstring(buffer,off,len)
	SV * buffer
	unsigned int off
	unsigned int len
    PROTOTYPE: $$$
    PREINIT:
	STRLEN size;
	unsigned char * cp;
	SV * out;
    PPCODE:
	if (!SvROK(buffer))	/* not a pointer	*/
	    XSRETURN_EMPTY;

	cp = (u_char *)(SvPV(SvRV(buffer),size) + off);

	if (off + len > size)	/* offset beyond end	*/
	    XSRETURN_EMPTY;

	out = sv_newmortal();
	sv_setpvn(out, (char *)cp, len );
	XPUSHs(out);
	if (GIMME_V == G_ARRAY) {
	    XPUSHs(sv_2mortal(newSViv(off + len)));
	    XSRETURN(2);
	}
	    XSRETURN(1);

unsigned int
putstring(buffer,off,string)
	SV * buffer
	unsigned int off
	SV * string
    PROTOTYPE: $$$
    PREINIT:
	SV * buf;
	STRLEN size, len;
	unsigned char * cp, * bp;
    CODE:
	if (!SvROK(buffer))	/* not a pointer	*/
	    XSRETURN_UNDEF;

	if (!SvROK(string))	/* not a pointer	*/
	    XSRETURN_UNDEF;

	buf = SvRV(buffer);

	(void)SvPV(buf,size);

	if (off > size)		/* not a valid offset	*/
	    XSRETURN_UNDEF;

	cp = (u_char *)SvPV(SvRV(string),len);

	if (off + len > MAXDNAME)	/* too big to add	*/
	    XSRETURN_UNDEF;

	if (off < size)
	    SvCUR_set(buf,off);

	sv_catpvn(buf, (char *)cp, len);

	SvCUR_set(buf, (I32)(off + len));
	RETVAL = off + len;
    OUTPUT:
	RETVAL

 # void
 # get32
void
get16(buffer,off)
	SV * buffer
	unsigned int off
    ALIAS:
	Net::DNS::ToolKit::get32 = 1
    PREINIT:
	SV * out;
	STRLEN size;
	u_char * cp;
    PPCODE:
	if (GIMME_V == G_VOID)
	    XSRETURN_UNDEF;		/* punt, nothing to return	*/

	if (!SvROK(buffer)) {
	bail:
	    if (GIMME_V != G_ARRAY)
		XSRETURN_UNDEF;
	    else
		XSRETURN_EMPTY;
	}
	cp = (u_char *)(SvPV(SvRV(buffer),size) + off);

	if (ix) {
	    off += NS_INT32SZ;
	    if (off > size)			/* punt if pointing beyond end of buff	*/
		goto bail;
	    XPUSHs(sv_2mortal(newSViv(gint32(cp))));
	} else {
	    off += NS_INT16SZ;
	    if (off > size)			/* punt if pointing beyond end of buff	*/
		goto bail;
	    XPUSHs(sv_2mortal(newSViv(gint16(cp))));
	}
	if (GIMME_V == G_ARRAY) {
	    XPUSHs(sv_2mortal(newSViv(off)));
	    XSRETURN(2);
	}
	    XSRETURN(1);

 # void
 # put1char, put32
unsigned int
put16(buffer,off,val_long)
	SV * buffer
	unsigned int off
	SV * val_long
    ALIAS:
	Net::DNS::ToolKit::put32 = 1
	Net::DNS::ToolKit::put1char = 2
    PREINIT:
	STRLEN size;
	U32 val;
	unsigned int i, ns_size = NS_INT16SZ;
	u_char c, * cp, blank[NS_INT32SZ];
    CODE:
	if (!SvROK(buffer))
	    XSRETURN_UNDEF;

	buffer = SvRV(buffer);
 	(void)SvPV(buffer,size);			/* get size of buffer	*/

	if (off > size)					/* punt if pointing beyond end of buff	*/
	    XSRETURN_UNDEF;

	val = SvUV(val_long);

	if (ix == 1)
	    ns_size = NS_INT32SZ;
	else if (ix == 2) {
	    if (val > 255)
		XSRETURN_UNDEF;
		ns_size = 1;
		c = (u_char)val;
	}
	else {
	    if (val > 65535)
		XSRETURN_UNDEF;
	    i = (unsigned int)val;
	}

	if (off + ns_size > size)			/* add space at end if needed	*/
	    sv_catpvn(buffer,(char *)blank,ns_size);

	cp = (u_char *)(SvPV(buffer,size) + off);

	if (ix == 1)
	    gput32(cp,val);
	else if (ix == 2)
	    *cp = c;
	else
	    gput16(cp,i);

	RETVAL = off + ns_size;
    OUTPUT:
	RETVAL

void
getIPv4(buffer,off)
	SV * buffer
	unsigned int off
    PREINIT:
	SV * netaddr;
	STRLEN size;
	u_char * cp, out[NS_INADDRSZ];
    PPCODE:
	if (GIMME_V == G_VOID)
	    XSRETURN_UNDEF;		/* punt, nothing to return	*/

	if (!SvROK(buffer)) {
	bail:
	    if (GIMME_V != G_ARRAY)
		XSRETURN_UNDEF;
	    else
		XSRETURN_EMPTY;
	}
	cp = (u_char *)(SvPV(SvRV(buffer),size) + off);

	off += NS_INADDRSZ;
	if (off > size)			/* punt if pointing beyond end of buff	*/
	    goto bail;
	
	netaddr = sv_newmortal();
	sv_setpvn(netaddr, (char *)cp, NS_INADDRSZ );
	XPUSHs(netaddr);
	if (GIMME_V == G_ARRAY) {
	    XPUSHs(sv_2mortal(newSViv( off)));
	    XSRETURN(2);
	}
	    XSRETURN(1);

unsigned int
putIPv4(buffer,off,netaddr)
	SV * buffer
	unsigned int off
	unsigned char * netaddr
    PREINIT:
	STRLEN size, discard;
	u_char * cp, blank[NS_INADDRSZ];
    CODE:
	if (!SvROK(buffer))
	    XSRETURN_UNDEF;

	buffer = SvRV(buffer);
 	(void)SvPV(buffer,size);			/* get size of buffer	*/

	if (off > size)					/* punt if pointing beyond end of buff	*/
	    XSRETURN_UNDEF;

	if (off + NS_INADDRSZ > size)
	    sv_catpvn(buffer,(char *)blank,NS_INADDRSZ);	/* extend buffer if needed	*/

	cp = (u_char *)(SvPV(buffer, discard) + size);

	memcpy(cp,netaddr,NS_INADDRSZ);

	RETVAL = (int)(size + NS_INADDRSZ);
    OUTPUT:
	RETVAL

void
getIPv6(buffer,off)
	SV * buffer
	unsigned int off
    PREINIT:
	SV * ipv6addr;
	STRLEN size;
	u_char * cp, out[NS_IN6ADDRSZ];
    PPCODE:
	if (GIMME_V == G_VOID)
	    XSRETURN_UNDEF;		/* punt, nothing to return	*/

	if (!SvROK(buffer)) {
	bail:
	    if (GIMME_V != G_ARRAY)
		XSRETURN_UNDEF;
	    else
		XSRETURN_EMPTY;
	}
	cp = (u_char *)(SvPV(SvRV(buffer),size) + off);

	off += NS_IN6ADDRSZ;
	if (off > size)			/* punt if pointing beyond end of buff	*/
	    goto bail;
	
	ipv6addr = sv_newmortal();
	sv_setpvn(ipv6addr, (char *)cp, NS_IN6ADDRSZ );
	XPUSHs(ipv6addr);
	if (GIMME_V == G_ARRAY) {
	    XPUSHs(sv_2mortal(newSViv( off)));
	    XSRETURN(2);
	}
	    XSRETURN(1);

unsigned int
putIPv6(buffer,off,ipv6addr)
	SV * buffer
	unsigned int off
	unsigned char * ipv6addr
    PREINIT:
	STRLEN size, discard;
	u_char * cp, blank[NS_IN6ADDRSZ];
    CODE:
	if (!SvROK(buffer))
	    XSRETURN_UNDEF;

	buffer = SvRV(buffer);
	(void)SvPV(buffer,size);			/* get size of buffer	*/

	if (off > size)					/* punt if pointing beyond end of buff	*/
	    XSRETURN_UNDEF;

	if (off + NS_IN6ADDRSZ > size)
	    sv_catpvn(buffer,(char *)blank,NS_IN6ADDRSZ);	/* extend buffer if needed	*/

	cp = (u_char *)(SvPV(buffer, discard) + size);

	memcpy(cp,ipv6addr,NS_IN6ADDRSZ);

	RETVAL = (int)(size + NS_IN6ADDRSZ);
    OUTPUT:
	RETVAL

void
gettimeofday()
    PREINIT:
	SV * tmp;				/* older perl does not know about newSVuv */
    PPCODE:
	if (gettimeofday(&tv,NULL)) {		/* any error	*/
	    if (GIMME_V == G_ARRAY)
		XSRETURN_EMPTY;
	    else
		XSRETURN_UNDEF;
	}
	tmp = newSViv(tv.tv_sec);
	sv_setuv(tmp,tv.tv_sec);
	XPUSHs(sv_2mortal(tmp));
	if (GIMME_V == G_ARRAY) {
	    tmp = newSViv(tv.tv_usec);
	    sv_setuv(tmp,tv.tv_usec);
	    XPUSHs(sv_2mortal(tmp));
	    XSRETURN(2);
	}
	XSRETURN(1);

void
get_default()
    PPCODE:
	mysin();
	XPUSHs(sv_2mortal(newSVpvn((char *)&mysa.sin_addr, NS_INADDRSZ)));
	XSRETURN(1);

void
get_path()
    PREINIT:
	SV * out;
    PPCODE:
	if (path == NULL)
	    XSRETURN_UNDEF;
	out = sv_newmortal();
	sv_setpvn(out, path, (STRLEN)pathz);    
	XPUSHs(out);
	XSRETURN(1);

void
lastchance()
    PREINIT:
	int i, nscount;
	u_char * netptr;
    PPCODE:
	if ((nscount = lchance()) < 1) {
	    if (GIMME_V != G_ARRAY)
		XSRETURN_UNDEF;
	    else
		XSRETURN_EMPTY;
	}
	if (GIMME_V != G_ARRAY)
	    nscount = 1;

	for(i=0;i<nscount;i++) {
	    netptr = ns_ptr(i); 
	    XPUSHs(sv_2mortal(newSVpvn((char *)netptr, NS_INADDRSZ)));
	}
	XSRETURN(nscount);
