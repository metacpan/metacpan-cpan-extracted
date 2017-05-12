
/* ********************************************************************	*
 * Interface.xs		version 1.06	9-21-16				*
 *									*
 *     COPYRIGHT 2008-2010 Michael Robinton <michael@bizsystems.com>	*
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

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "localconf.h"

#ifdef __cplusplus
}
#endif

#include "inet_aton.c"
#include "ni_XStabs_inc.c"

extern const ni_iff_t ni_lx_type2txt[];
const ni_iff_t ni_lx_scope_txt[] = {
	{ RFC2373_GLOBAL,	"global-scope" },
	{ RFC2373_ORGLOCAL,	"org-local" },
	{ RFC2373_SITELOCAL,	"site-local" },
	{ RFC2373_LINKLOCAL,	"link-local" },
	{ RFC2373_NODELOCAL,	"loopback" },
	{ LINUX_COMPATv4,	"lx-compat-v4" }
};

/*
 # make a GV from scratch and return a reference - see gv.c newGVgen
 # delete the GV's name from the stash so it is inaccessible
 #
 # originally written with "rv = sv_newmortal()", now caller must mortalize
 */
#define NI_newGV_ref(rv,gv,stash,tmpstash) \
	rv = newSV(0); \
	gv = gv_fetchpv(Perl_form(aTHX_ "%s::_ifa::_IF_DEV_%ld",HvNAME((HV *)stash),(long)PL_gensym++),TRUE, SVt_PVGV); \
	GvSV(gv) = newSV(0); \
	GvHV(gv) = newHV(); \
	sv_setsv(rv, sv_bless(newRV_noinc((SV*)gv), stash)); \
	tmpstash = GvSTASH(gv); \
	(void)hv_delete(tmpstash, GvNAME(gv), GvNAMELEN(gv), G_DISCARD)

#define niKEYsz 4

#define NI_REF_CHECK(ref) \
        if (!SvROK (ref) || !SvOBJECT (SvRV(ref)) || !SvREADONLY (SvRV(ref))) \
          croak ("Can't call method \"%s\" without a valid object reference", GvNAME (CvGV (cv)));

	/* ********************************************	*
	 *  The information for each interface (IF) is	*
	 *  contained in an HV. The name slot of the	*
	 *  HV holds the IF name. The args slot points	*
	 *  to a hash whose key values represent the	*
	 *  last interrogated state of the IF.		*
	 *						*
	 *   HV {					*
	 *	   indx =>  IV				*
	 *	   flav	=>  IV,				*
	 *	   name	=>  interface name;		*
	 *	   args	=>  {				*
	 *		maci	=> bin string,		*
	 *		mtui	=> IV,			*
	 *		metk	=> IV,			*
	 *		flag	=> NV,			*
	 *		afk	=> {			*
	 *			size	=> IV,		*
	 *			addr	=> [],		*
	 *			netm	=> [],		*
	 *			dsta	=> [],		*
	 *		},				*
	 *		afk	=> {			*
	 *			size	=> IV,		*
	 *			addr	=> [],		*
	 *			netm	=> [],		*
	 *			dsta	=> [],		*
	 *		},				*
	 *	    }					*
	 *	};					*
	 *  Note: for ease of coding, all keys=4 chars	*
	 *	  except for 'afk' which is computed	*
	 * ********************************************	*/

static u_int32_t
afk_len(u_int af, char * key)
{
    sprintf(key,"%d",af);
    return (u_int32_t)strlen(key);
}

static int
af_common(HV * hface, HV * family, struct ifaddrs * ifap, int offset, int addrsz, int *fd, u_int af, int flavor)
{
	struct nifreq ifr;
	char afk[16], * addrptr;
	const char * addr = "addr", * netmask = "netm", * dstaddr = "dsta";
	const char * flags = "flag", * size = "size", * mtu = "mtui", * metric = "metk", * ifindex = "indx";
	int i;
	AV * anyaddr;
	u_int64_t fgs;
	struct ni_ifconf_flavor * nifp = ni_ifcf_get(flavor);
#ifdef HAVE_STRUCT_LIFREQ
	struct lifreq lifr;
#endif

/*	is status needed or has it been saved already? if not, save flags, mtu, metric	*/
		if (! hv_exists(hface,flags,niKEYsz)) {
/*	flags		*/
		    fgs = ifap->ifa_flags;
#ifdef HAVE_STRUCT_LIFREQ
		    if (flavor == NI_LIFREQ) {
			strlcpy(lifr.lifr_name,ifap->ifa_name,IFNAMSIZ);
			if ((*fd = ni_clos_reopn_dgrm(*fd,af)) < 0)
	        	    goto no_xflags;
        		if (ioctl(*fd,nifp->siocgifflags,&lifr) != -1)
        		    fgs = lifr.lifr_flags;
		    }
    	no_xflags:
#endif
		    hv_store(hface,flags,niKEYsz,newSVnv(fgs),0);
		    if ((*fd = ni_clos_reopn_dgrm(*fd,AF_INET)) < 0)
			return -1;

		    strlcpy(ifr.ni_ifr_name,ifap->ifa_name,IFNAMSIZ);
/*	save MTU	*/
		    if ((i = ni_get_any(*fd,nifp->siocgifmtu,&ifr)) < 0)
			i = 0;
		    hv_store(hface,mtu,niKEYsz,newSViv(i),0);
/*	save METRIC	*/
		    if ((i = ni_get_any(*fd,nifp->siocgifmetric,&ifr)) < 0)
			i = 0;
		    hv_store(hface,metric,niKEYsz,newSViv(i),0);
/*	save INDEX if defined for this platform	*/
		    if (nifp->siocgifindex != 0) {
			if ((i = ni_get_any(*fd,nifp->siocgifindex,&ifr)) < 0)
			    i = -1;
			hv_store(hface,ifindex,niKEYsz,newSViv(i),0);
		    }
		    if ((*fd = ni_clos_reopn_dgrm(*fd,af)) < 0)
			return -1;
		}

/*	if the address arrays are populated, get pointer	*/
		if (hv_exists(hface,afk,afk_len(af,afk)))
		    family = (HV*)SvRV(*hv_fetch(hface,afk,afk_len(af,afk),0));
		else {
		    family = newHV();
		    hv_store(hface,afk,afk_len(af,afk),newRV_noinc((SV*)family),0);
/*	save address size for user	*/
		    hv_store(family,size,niKEYsz,newSViv(addrsz),0);
/*	populate the address arrays	*/
		    hv_store(family,addr,niKEYsz,   newRV_noinc((SV*)newAV()),0);
		    hv_store(family,netmask,niKEYsz,newRV_noinc((SV*)newAV()),0);
		    hv_store(family,dstaddr,niKEYsz,newRV_noinc((SV*)newAV()),0);
		}
/*	addr	*/
		anyaddr = (AV*)SvRV(*hv_fetch(family,addr,niKEYsz,0));
		if (ifap->ifa_addr == NULL)
		    av_push(anyaddr,newSV(0));
		else {
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
		    if (af == AF_INET6)
	/* waste the scopeid if KAME	*/
			(void) ni_get_scopeid((struct sockaddr_in6 *)(ifap->ifa_addr));
#endif	
		    addrptr = ((char *)ifap->ifa_addr) + offset;
		    av_push(anyaddr,newSVpvn(addrptr,addrsz));
		}
/*	netmask	*/
		anyaddr = (AV*)SvRV(*hv_fetch(family,netmask,niKEYsz,0));
		if (ifap->ifa_netmask == NULL)
		    av_push(anyaddr,newSV(0));
		else {
		    addrptr = ((char *)ifap->ifa_netmask) + offset;
		    av_push(anyaddr,newSVpvn(addrptr,addrsz));
		}
/*	dstaddr	*/
		anyaddr = (AV*)SvRV(*hv_fetch(family,dstaddr,niKEYsz,0));
		if (ifap->ifa_dstaddr == NULL)
		    av_push(anyaddr,newSV(0));
		else {
		    addrptr = ((char *)ifap->ifa_dstaddr) + offset;
		    av_push(anyaddr,newSVpvn(addrptr,addrsz));
		}
		return 0;
}

static int
getheifs(SV ** sp, I32 ax, I32 items, SV * ref, HV * stash, int ix, char * keyname)
{
	int flavor, forcflavor, i, fd = -1, n = 1, ic, need_mac_addr = 1;
	u_int af;
	struct ifaddrs * ifap = NULL, * ifapbase = NULL;
	const char * mac = "maci", * name = "name", * args = "args", * flags = "flag", * flav = "flav", * ifindex = "indx";
	char nbuf[IFNAMSIZ], afk[16];
	u_char * macp;
	struct nifreq ifr;
	struct ni_lnk_names {
	    char niln_name[IFNAMSIZ];
	    int niln_len;
	} name_link, * nlbase = NULL, * nl;
	struct sockaddr_in sin;
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
	struct sockaddr_in6 sin6;
#endif
#ifdef LOCAL_SIZEOF_SOCKADDR_DL
	struct sockaddr_dl * sadl;
#elif defined LOCAL_SIZEOF_SOCKADDR_LL
	struct sockaddr_ll *sall;
#endif  
	STRLEN	len;
	I32	klen;
	SV * rv;
	GV * gvface;
	AV * anyaddr;
	HV * ifaces, * hface, * family, * wrapr, * owrap;

/* if new	*/
	if (keyname != NULL) {		/* this is a redo, not IF rqst	*/
	    klen = strlen(keyname);
	    owrap = (HV *)SvRV(ref);
	}
	else if (ix == 1) {
	    if (items == 1) {		/* refresh of existing IF	*/
		if (!SvROK(ref))
		    goto iferror1;
		owrap = (HV *)SvRV(ref);
		if (! hv_exists(owrap,name,niKEYsz))
		    goto iferror1;
		rv = *hv_fetch(owrap,name,niKEYsz,0);
		if (!SvPOK(rv))
		    goto iferror1;
		strlcpy(nbuf,SvPV(rv,len),len +1);
		keyname = nbuf;
		klen = len;
	    }
	    else if (items == 2) {	/* new or update IF w/ hash ref	*/
		if (! SvPOK(ST(1)))
		    goto iferror1;
		keyname = SvPV(ST(1),len);
		klen = len;
	    }
	    else {			/* new or update IF with hash	*/
		goto iferror1;		/* not yet implemented		*/
	    }
	}
/* get the data about interfaces from the default getifaddrs	*/
	forcflavor = flavor = ni_getifaddrs(&ifap, 0);
	if (flavor < 0)
	    goto iferror1;
	else if (flavor == 0)
	    forcflavor = NI_IFREQ;
/* belt and suspenders test for failed fetch of ifaddrs data	*/
	if (ifap == NULL)		/* there are no addresses to check */
	    goto iferror1;

	ifapbase = ifap;

/*
 *	hash ifaces is for temporary aggregation by interface
 *	seems that a plain hv_undef at the end leaks
 *	mortalization stops the leak
 *	decrementing the REFCNT instead causes a segfault, puzzling!
 */
	ifaces = (HV*)sv_2mortal((SV*)newHV());
/*	ifaces = newHV();
 *	SvREFCNT_dec(ifaces);
 *
 *	storage conventions
 *
 *	ifaces	=> temporary interface hash keyed by name
 *	hface	=> hash for a particular interface
 *	family	=> family within an hface
 *	anyaddr	=> an address array within a family
 */

	if ((nl = nlbase = (struct ni_lnk_names *)calloc(1,sizeof(struct ni_lnk_names))) == NULL)
	    goto iferror2;

	while (ifap != NULL) {
	    len = strlen(ifap->ifa_name);
/* this is sub 'new', target only the 'name'	*/
	    if (ix && strncmp(ifap->ifa_name,keyname,len))
		goto nextname;
/* interface is known?				*/
	    if (hv_exists(ifaces,ifap->ifa_name,len))
/* fetch reference to interface ref		*/
		hface = (HV*)SvRV(*hv_fetch(ifaces,ifap->ifa_name,len,0));
	    else {
/* skip invalids */
		if (ifap->ifa_addr == NULL) goto nextname;
/* create an HV to hold this interface		*/
		hface = newHV();
/* and insert ref into unique/tmp storage hash	*/
		hv_store(ifaces,ifap->ifa_name,len,newRV_noinc((SV*)hface),0);
/* add name to the list to preserve kernel ordering
 * can use memcpy here because struct is bzero'd and will have terminating null
 */
		memcpy(nl->niln_name,ifap->ifa_name,len);
		nl->niln_len = len;
		n++;
		if ((nl = (struct ni_lnk_names *)realloc(nlbase,n * sizeof(struct ni_lnk_names))) == NULL)
		    goto iferror2;
		nlbase = nl;
		nl = nlbase + n -1;
		bzero(nl,sizeof(struct ni_lnk_names));
	    }

/* check for improperly truncated entry		*/
	    if (ifap->ifa_addr == NULL)
		goto iferror2;
/*
 * only store 'ifa_flags' for families where we store the address since
 * we don't know if 'ifa_flags' is consistently populated for link/packet
 */
	    af = ((struct sockaddr *)(ifap->ifa_addr))->sa_family;
/* AF_INET					*/
	    if (af == AF_INET) {
		if (af_common(hface,family,ifap,
/*			(u_char *)&((struct sockaddr_in *)ifap->ifa_addr)->sin_addr, */
			((char *)&sin.sin_addr) - (char *)&sin,
			sizeof(struct in_addr),&fd,af,forcflavor) != 0) {
    iferror3:
		    free(ifapbase);
		    goto iferror2;
		}
	    }

#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
/* AF_IFNET6					*/
	    else if (af == AF_INET6) {
		if (af_common(hface,family,ifap,
/*			(u_char *)&((struct sockaddr_in6 *)ifap->ifa_addr)->sin6_addr, */
			((char *)&sin6.sin6_addr) - (char *)&sin6,
			sizeof(struct in6_addr),&fd,af,forcflavor) != 0)
		    goto iferror3;
	    }

#endif	/* SOCKADDR_IN6	*/
#ifdef LOCAL_SIZEOF_SOCKADDR_DL

	    else if (af == AF_LINK) {
		if (ifap->ifa_addr != NULL) {
		    sadl = (struct sockaddr_dl *)ifap->ifa_addr;
		    macp = (unsigned char *)(sadl->sdl_data + sadl->sdl_nlen);
		    if (NI_MAC_NOT_ZERO(macp)) {
			need_mac_addr = 0;
			hv_store(hface,mac,niKEYsz,newSVpvn((char *)macp,6),0);
		    }
		    if (sadl->sdl_index != 0 && (! hv_exists(hface,ifindex,niKEYsz)))
			hv_store(hface,ifindex,niKEYsz,newSViv(sadl->sdl_index),0);
		}
	    }

#elif defined LOCAL_SIZEOF_SOCKADDR_LL

	    else if (af == AF_PACKET) {
		if (ifap->ifa_addr != NULL) {
		    sall = (struct sockaddr_ll *)ifap->ifa_addr;
		    macp = (unsigned char *)sall->sll_addr;
		    if (NI_MAC_NOT_ZERO(macp)) {
			need_mac_addr = 0;
			hv_store(hface,mac,niKEYsz,newSVpvn((char *)macp,6),0);
		    }
		    if (sall->sll_ifindex != 0 && (! hv_exists(hface,ifindex,niKEYsz)))
			hv_store(hface,ifindex,niKEYsz,newSViv(sall->sll_ifindex),0);
		}
	    }

#endif

    nextname:
	    ifap = ifap->ifa_next;
	}
	close(fd);
	ni_free_gifa(ifapbase,flavor);
	nl = nlbase;
	if (GIMME == G_ARRAY)
	    i = 0;
	else
	    i = -1;

	while(nl->niln_name[0] != '\0') {
	    if (hv_exists(ifaces,nl->niln_name,nl->niln_len)) {
		if (ix < 2) {		/* if this is a redo skip wrapr operation	*/
		    wrapr = newHV();
		    hv_store(wrapr,name,niKEYsz,newSVpvn((char *)nl->niln_name,nl->niln_len),0);
		    hv_store(wrapr,flav,niKEYsz,newSViv(flavor),0);
		}
		rv = hv_delete(ifaces,nl->niln_name,nl->niln_len,0);
		if (need_mac_addr) {
#ifdef __ni_Linux
/* do not add mac to alias's				*/
		    if (index(nl->niln_name,':') != NULL)
			goto no_mac;
#endif
/* skip this interface if it is the loopback device	*/
		    hface = (HV*)SvRV(rv);
		    if (IFF_LOOPBACK & (u_int64_t)SvNV((SV*)(*hv_fetch(hface,flags,niKEYsz,0))))
			goto no_mac;
		    if (hv_exists(hface,afk,afk_len(AF_INET,afk)))
			    goto mac_continue;
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
		    else if(hv_exists(hface,afk,afk_len(AF_INET6,afk)))
			    goto mac_continue;
#endif
		    else
			goto no_mac;
    mac_continue:
		    strlcpy(ifr.ni_ifr_name,nl->niln_name,IFNAMSIZ);
		    if ((macp = ni_fallbackhwaddr(af,&ifr)) != NULL)
			hv_store(hface,mac,niKEYsz,newSVpvn((char *)macp,6),0);
		}
    no_mac:

/* don't want the ref to be mortal, only the wrapper	*/
		SvREFCNT_inc(rv);
		if (ix > 1)
		    hv_store(owrap,args,niKEYsz,rv,0);
		else {
		    hv_store(wrapr,args,niKEYsz,rv,0);
		    XPUSHs(sv_2mortal(sv_bless(newRV_noinc((SV*)wrapr),stash)));
		}
	    	if (i < 0) {
		    i = 1;
		    break;
		}
		i++;
		nl++;
	    }
/* should never do the else!				*/
	    else {
    iferror2:
		free(nlbase);
		hv_undef(ifaces);
    iferror1:
		return -1;
	    }
	}
	free(nlbase);
	hv_undef(ifaces);
	return i;
}

/*	return NULL or pointer to first available address	*/
static SV *
get_first_address(SV * ref, char * key, int sixonly)
{
    HV * hv, * family;
    AV * av;
    SV * sv;
    char afk[16], * args = "args";

    hv = (HV *)SvRV(ref);		/* wrapper	*/
    if (! hv_exists(hv,args,niKEYsz))
	return NULL;
    sv = *hv_fetch(hv,args,niKEYsz,0);	/* hface	*/
    if (!SvROK(sv))
	return NULL;
    hv = (HV *)SvRV(sv);
    if (! sixonly && hv_exists(hv,afk,afk_len(AF_INET,afk)))
	family = (HV*)SvRV(*hv_fetch(hv,afk,afk_len(AF_INET,afk),0));
#ifdef LOCAL_SIZEOF_SOCKADDR_IN6
    else if (hv_exists(hv,afk,afk_len(AF_INET6,afk)))
	family = (HV*)SvRV(*hv_fetch(hv,afk,afk_len(AF_INET6,afk),0));
#endif
    else
	return NULL;
    av = (AV*)SvRV(*hv_fetch(family,key,niKEYsz,0));
    return *av_fetch(av,0,0);		/* first addy	*/
}


MODULE = Net::Interface	PACKAGE = Net::Interface PREFIX = NIP_

INCLUDE: miniSocketXS.c


void
interfaces(ref,...)
	SV * ref
    PROTOTYPE: $;$
    ALIAS:
	new = 1
    PREINIT:
	HV * stash = SvROK (ref)
		? SvSTASH (SvRV (ref)) : gv_stashsv (ref, 0);
	int rv;
    PPCODE:
	if ((rv = getheifs(sp,ax,items,ref,stash,(int)ix,NULL)) < 0) {
	    if (GIMME == G_ARRAY)
		XSRETURN_EMPTY;
	    else
		XSRETURN_UNDEF;
	}
	XSRETURN(rv);


void
dtest(ref)
	SV * ref
    PREINIT:
	char * myname = "my name", * one = "one", * two = "two", * array = "array";
	SV * rv, *arv, *mn;
	GV * gv;
	AV * av;
	HV * stash, * tstash;
    PPCODE:
	stash = SvROK (ref) ? SvSTASH (SvRV (ref)) : gv_stashsv (ref, 0);
	NI_newGV_ref(rv,gv,stash,tstash);
 #	mn = newSVpv(myname,0);
 #	GvSV(gv) = mn;
 #	hv_store(GvHV(gv),one,strlen(one),newSViv(1),0);
 #	hv_store(GvHV(gv),two,strlen(two),newSViv(2),0);
 #	av = newAV();
 #	arv = newRV_noinc((SV *)av);
 #	av = (AV*)SvRV(*hv_store(GvHV(gv),array,strlen(array),arv,0));
 #	av_push(av,newSViv(55));
	XPUSHs(sv_2mortal(rv));
	XSRETURN(1);


void
dtest2(ref)
	SV * ref
    PREINIT:
	SV * sv, * pv;
	HV * hv;
	char * name = "Sv Name";
	char * n2 = "LOGO";
	char * myname = "my name", * one = "one", * two = "two", * array = "array";
    PPCODE:
	hv = newHV();
	hv_store(hv,one,strlen(one),newSViv(1),0);
	hv_store(hv,two,strlen(two),newSViv(2),0);
	sv = (SV*)newRV_noinc((SV*)hv);
	XPUSHs(sv_2mortal(sv));
	XSRETURN(1);


void
__developer(ref)
	SV *ref
    ALIAS:
	d_ni_ifreq	= NI_IFREQ
	d_ni_lifreq	= NI_LIFREQ
	d_ni_in6_ifreq	= NI_IN6_IFREQ
	d_ni_linuxproc	= NI_LINUXPROC
    PREINIT:
	char * process;
	int er = ni_developer(ix);
    CODE:
	if (er == 0)
	    XSRETURN_EMPTY;

	switch (ix) {
	case NI_IFREQ :
	    process = "NI_FREQ";
	    break;
	case NI_LIFREQ :
	    process = "NI_LIFREQ";
	    break;
	case NI_IN6_IFREQ :
	    process = "NI_IN6_IFREQ";
	    break;
	case NI_LINUXPROC :
	    process = "NI_LINUXPROC";
	    break;
	default :
	    process = "UNDEFINED";
	}
	printf("%s: %s\n",process,strerror(er));


void
gifaddrs_base(ref)
	SV * ref
    ALIAS:
 #	base		= 0
	gifa_ifreq	= NI_IFREQ
	gifa_lifreq	= NI_LIFREQ
	gifa_in6_ifreq	= NI_IN6_IFREQ
	gifa_linuxproc	= NI_LINUXPROC
    PREINIT:
	struct ifaddrs * ifap;
	int rv;
    CODE:
	if ((rv = ni_getifaddrs(&ifap,ix)) == -1) {
	    printf("failed PUNT!\n");
	    XSRETURN_EMPTY;
	}
	ni_getifaddrs_dump(rv,ifap);
	ni_free_gifa(ifap,rv);


void
cidr2mask(prefix, size)
	int	prefix
	int	size
    PREINIT:
	unsigned char mask[16];
    PPCODE:
	if (!(size == 4 || size == 16))
	    croak("Bad arg for %s, requested mask size is %d, should be 4 or 16",
			GvNAME (CvGV (cv)),size);
	if (prefix < 0 || prefix > (size * 8))
	    croak ("Bad arg for %s, mask length is %d, should be 0 to <= %d",
			GvNAME (CvGV (cv)),size * 8);

	ni_plen2mask(mask,prefix,size);
	XPUSHs(sv_2mortal(newSVpvn((char *)mask,size)));
	XSRETURN(1);


int
mask2cidr(ref,...)
	SV * ref;
    PROTOTYPE: $;$
    PREINIT:
	unsigned char * mp;
	STRLEN len;
	char * netmask = "netm";
	SV * sv;
    CODE:
 #	called as method with argument
	if (items == 2)
	    mp = (unsigned char *)SvPV(ST(1),len);
 #	called as a function
	else if (! SvROK(ref))
	    mp = (unsigned char *)SvPV(ST(0),len);
 #	called as method
	else {
	    if ((sv = get_first_address(ref,netmask,0)) == NULL)
		len = 0;
	    else
		mp = (unsigned char *)SvPV(sv,len);
	}
	if (!(len == 4 || len == 16))
	    croak("Bad arg length for %s, mask length is %d, should be 4 or 16",
			GvNAME (CvGV (cv)),len);
	RETVAL = ni_prefix(mp,len);
    OUTPUT:
	RETVAL


void
NIP_type(ref,...)
	SV * ref
    PROTOTYPE: $;$
    ALIAS:
	scope = 1
    PREINIT:
	unsigned char * s6bytes;
	char * addr = "addr";
	UV type;
	STRLEN len;
	HV * hv;
	SV * sv;
    PPCODE:
 #	called as method with argument
	if (items == 2)
	    s6bytes = (unsigned char *)SvPV(ST(1),len);
 #	called as a function
	else if (! SvROK(ref))
	    s6bytes = (unsigned char *)SvPV(ST(0),len);
 #	called as method
	else {
	    if ((sv = get_first_address(ref,addr,1)) == NULL)
		len = 0;
	    else
		s6bytes = (unsigned char *)SvPV(sv,len);
	}
	if (! len == 16)
	    croak("Bad arg length for %s, address length is %d, should be 16",
			GvNAME (CvGV (cv)),len);

	type = ni_in6_classify(s6bytes);

	if (ix == 0)
	    XPUSHs(sv_2mortal(newSVuv(type)));
	else
	    XPUSHs(sv_2mortal(newSViv(ni_lx_type2scope((int)type))));

	XSRETURN(1);


void
mac_bin2hex(ref,...)
	SV * ref
    PROTOTYPE: $;$
    PREINIT:
	unsigned char * macbin;
	char macbuf[18], * format, * args = "args", * mac = "maci";
	STRLEN len;
	HV * hv;
	SV * sv;
    PPCODE:
 #	called as method with argument
	if (items == 2)
	    macbin = (unsigned char *)SvPV(ST(1),len);
 #	called as a function
	else if (! SvROK(ref))
	    macbin = (unsigned char *)SvPV(ST(0),len);
 #	called as method
	else {
	    hv = (HV *)SvRV(ref);
	    if (! hv_exists(hv,args,niKEYsz))
		XSRETURN_UNDEF;
	    sv = *hv_fetch(hv,args,niKEYsz,0);
	    if (!SvROK(sv))
		XSRETURN_UNDEF;
	    hv = (HV *)SvRV(sv);
	    if (! hv_exists(hv,mac,niKEYsz))
		XSRETURN_UNDEF;
	    sv = *hv_fetch(hv,mac,niKEYsz,0);
	    if (! SvPOK(sv))
		XSRETURN_UNDEF;
	    macbin = (unsigned char *)SvPV(sv,len);
	}
	if (len != 6)
	    croak("Bad arg length for %s, MAC length is %d, should be 6",
			GvNAME (CvGV (cv)),len);

	format = SvPV(get_sv("Net::Interface::mac_format", FALSE),len);
	sprintf(macbuf,format,
		macbin[0],macbin[1],macbin[2],macbin[3],macbin[4],macbin[5]);

	XPUSHs(sv_2mortal(newSVpv(macbuf,0)));
	XSRETURN(1);


void
full_inet_ntop(neta)
	SV * neta
    PREINIT:
	unsigned char * naddr;
	char mask[40], * format;
	STRLEN len;
    PPCODE:
	naddr = (unsigned char *)SvPV(neta,len);
	if (len != 16)
	    croak("Bad arg length for %s, ipV6 length is %d, should be 16 bytes",
			GvNAME (CvGV (cv)),len);

	format = SvPV(get_sv("Net::Interface::full_format", FALSE),len);
	sprintf(mask,format,
		naddr[0],naddr[1],naddr[2],naddr[3],
		naddr[4],naddr[5],naddr[6],naddr[7],
		naddr[8],naddr[9],naddr[10],naddr[11],
		naddr[12],naddr[13],naddr[14],naddr[15]);

	XPUSHs(sv_2mortal(newSVpvn((char *)mask,39)));
	XSRETURN(1);


void
_lx_types()
    ALIAS:
	IPV6_ADDR_ANY			= IPV6_ADDR_ANY
	IPV6_ADDR_UNICAST		= IPV6_ADDR_UNICAST
	IPV6_ADDR_MULTICAST		= IPV6_ADDR_MULTICAST
	IPV6_ADDR_ANYCAST		= IPV6_ADDR_ANYCAST
	IPV6_ADDR_LOOPBACK		= IPV6_ADDR_LOOPBACK
	IPV6_ADDR_LINKLOCAL		= IPV6_ADDR_LINKLOCAL
	IPV6_ADDR_SITELOCAL		= IPV6_ADDR_SITELOCAL
	IPV6_ADDR_COMPATv4		= IPV6_ADDR_COMPATv4
	IPV6_ADDR_SCOPE_MASK		= IPV6_ADDR_SCOPE_MASK
	IPV6_ADDR_MAPPED		= IPV6_ADDR_MAPPED
	IPV6_ADDR_RESERVED		= IPV6_ADDR_RESERVED
	IPV6_ADDR_ULUA			= IPV6_ADDR_ULUA
	IPV6_ADDR_6TO4			= IPV6_ADDR_6TO4
	IPV6_ADDR_6BONE			= IPV6_ADDR_6BONE
	IPV6_ADDR_AGU			= IPV6_ADDR_AGU
	IPV6_ADDR_UNSPECIFIED		= IPV6_ADDR_UNSPECIFIED
	IPV6_ADDR_SOLICITED_NODE	= IPV6_ADDR_SOLICITED_NODE
	IPV6_ADDR_ISATAP		= IPV6_ADDR_ISATAP
	IPV6_ADDR_PRODUCTIVE		= IPV6_ADDR_PRODUCTIVE
	IPV6_ADDR_6TO4_MICROSOFT	= IPV6_ADDR_6TO4_MICROSOFT
	IPV6_ADDR_TEREDO		= IPV6_ADDR_TEREDO
	IPV6_ADDR_ORCHID		= IPV6_ADDR_ORCHID
	IPV6_ADDR_NON_ROUTE_DOC		= IPV6_ADDR_NON_ROUTE_DOC
    PREINIT:
	SV * rv;
	int n, i;
    PPCODE:
	rv = sv_2mortal(newSViv(ix));
	n = ni_sizeof_type2txt();
	for (i=0; i<n; i++) {
	    if (ni_lx_type2txt[i].iff_val == ix) {
		sv_setpv(rv,ni_lx_type2txt[i].iff_nam);
		break;
	    }
	}
	SvIOK_on(rv);
	XPUSHs(rv);
	XSRETURN(1);


void
_lx_scope()
    ALIAS:
	RFC2373_GLOBAL		= RFC2373_GLOBAL
	RFC2373_ORGLOCAL	= RFC2373_ORGLOCAL
	RFC2373_SITELOCAL	= RFC2373_SITELOCAL
	RFC2373_LINKLOCAL	= RFC2373_LINKLOCAL
	RFC2373_NODELOCAL	= RFC2373_NODELOCAL
	LINUX_COMPATv4		= LINUX_COMPATv4
    PREINIT:
	SV * rv;
	int n, i;
    PPCODE:
	rv = sv_2mortal(newSViv(ix));
	n = sizeof(ni_lx_scope_txt) / sizeof(ni_iff_t);
	for (i=0; i<n; i++) {
	    if (ni_lx_scope_txt[i].iff_val == ix) {
		sv_setpv(rv,ni_lx_scope_txt[i].iff_nam);
		break;
	    }
	}
	SvIOK_on(rv);
	XPUSHs(rv);
	XSRETURN(1);


size_t
NIP_strlcpy(...)
    PROTOTYPE: $$$
    PREINIT:
	char * d = NULL;
	char * s = SvPV_nolen(ST(1));
	size_t size = (size_t)SvIV(ST(2));
    CODE:
	if ((int)size > 0) {
	    d = New(1234,d,2 * size,char);
	    memset(d,'X',2 * size);
	    *(d + (2*size) -1) = 0;
	    RETVAL = strlcpy(d,s,size);
	    sv_setpv(ST(0),d);
	    Safefree(d);
	} else
	    RETVAL = 0;
    OUTPUT:
	RETVAL


int
_sets(ref,...)
	SV * ref
    ALIAS:
	mtu	= 0
	metric	= 1
	flags	= 2
	index	= 3
    PREINIT:
	int cmd, fd, rv, flavor;
	struct nifreq ifr, * ofifr;
	struct ni_ifconf_flavor * nifp;
	HV * hv;
	SV * sv;
	char * key, * args = "args", * name = "name", * flav = "flav";
	STRLEN len;
    CODE:
        if (!SvROK (ref) || !SvOBJECT(SvRV(ref)))
	    croak ("Can't call method \"%s\" without a valid object reference", GvNAME (CvGV (cv)));

	if (items > 2) {
    not_found:
	    croak ("Invalid or corrupted arguments passed to \"%s\"", GvNAME (CvGV (cv)));
	}
	hv = (HV *)SvRV(ref);
	if (! hv_exists(hv,name,niKEYsz))
	    goto not_found;
	if (! hv_exists(hv,args,niKEYsz))
	    goto not_found;
	if (! hv_exists(hv,flav,niKEYsz)) {
    no_data:
	    XSRETURN_UNDEF;
	}
	sv = *hv_fetch(hv,name,niKEYsz,0);
	if (!SvPOK(sv))
	    goto no_data;
	strlcpy(ifr.ni_ifr_name,SvPV(sv,len),len +1);
	sv = *hv_fetch(hv,flav,niKEYsz,0);
	if (!SvIOK(sv))
	    goto no_data;
 # flavor and offset if present
	flavor = SvIV(sv);
	nifp = ni_safe_ifcf_get(flavor);
	ofifr = (struct nifreq *)((char *)&ifr + nifp->ifr_offset);

	sv = *hv_fetch(hv,args,niKEYsz,0);
	if (!SvROK(sv))
	    goto no_data;

	switch (ix)
	{
	case 0 :
	    cmd = nifp->siocsifmtu;
	    key = "mtui";
	    break;
	case 1 :
	    cmd = nifp->siocsifmetric;
	    key = "metk";
	    break;
	case 2 :
	    cmd = nifp->siocsifflags;
	    key = "flag";
	    break;
	case 3 :
	    cmd = 0;
	    key = "indx";
	    break;
	default :
	    goto not_found;
	}

 # args hash
	hv = (HV *)SvRV(sv);
	if (! hv_exists(hv,key,niKEYsz))
	    goto no_data;
 # value
	sv = *hv_fetch(hv,key,niKEYsz,0);
	if (ix == 2) {
	    if (! SvNOK(sv))
		goto no_data;
	    RETVAL = SvNV(sv);
	}
	else {
	    if (! SvIOK(sv))
		goto no_data;
	    RETVAL = SvIV(sv);
	}
	if (cmd && items > 1) {
	    if (!(SvIOK(ST(1)) || SvNOK(ST(1))))
		goto no_data;

	    if (flavor == NI_LIFREQ)
		ofifr->ni_uint64 = (u_int64_t)SvNV(ST(1));
	    else
		ifr.ni_uint = (u_int)((u_int64_t)SvNV(ST(1)) & 0x1ffffu);

	    if ((fd = ni_clos_reopn_dgrm(-1,AF_INET)) < 0)
		goto no_data;
	    if ((rv = ni_set_any(fd,cmd,&ifr)) < 0) {
		close(fd);
		goto no_data;
	    }
	    close(fd);
 #	items == 2 and ix == 2 for this call
	    if (getheifs(sp,ax,2,ref,NULL,2,ifr.ni_ifr_name) < 0)
		goto not_found;
	}
    sets_done:
    OUTPUT:
	RETVAL


 # ############################################################	#
 #	Certain broken Solaris headers cause build		#
 #	errors with the syntax for constructors.		#
 #  i.e.							#
 #	void __attribute__((constructor))			#
 #	constructor_function () 				#
 #	{							#
 #		code....					#
 #	};							#
 #								#
 # line 249: syntax error before or at: (			#
 # line 251: warning: old-style declaration or incorrect type	#
 # cc: acomp failed [filename.c]				#
 # *** Error code 2						#
 # make: Fatal error: Command failed for target 'filename.o'	#
 #								#
 #	The various constructors are declared here and called	#
 #	during module load as a work-around to this problem	#
 # ############################################################	#
 
void
conreg()
    CODE:
	ni_ifreq_ctor();
	ni_in6_ifreq_ctor();
	ni_lifreq_ctor();
	ni_linuxproc_ctor();


void
macstuff(dev)
	SV * dev
    PREINIT:
	struct nifreq ifr;
	char * name;
	u_char * x;
	STRLEN len;
    CODE:
	name = SvPV(dev,len);
	strlcpy(ifr.ni_ifr_name,name,IFNAMSIZ);
 	x = ni_fallbackhwaddr(AF_INET,&ifr);
	if (x == NULL)
	    printf("got NULL\n");
	else {
	    NI_PRINT_MAC(x);
	    printf("\n");
	}




INCLUDE: netsymbolXS.inc

