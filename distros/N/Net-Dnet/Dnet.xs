/*

# Copyright 1995,1996,1997 Spider Boardman.
# All rights reserved.
#
# Automatic licensing for this software is available.  This software
# can be copied and used under the terms of the GNU Public License,
# version 1 or (at your option) any later version, or under the
# terms of the Artistic license.  Both of these can be found with
# the Perl distribution, which this software is intended to augment.
#
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

 */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/socket.h>

#include <netdnet/dn.h>
#include <netdnet/dnetdb.h>
#if defined(__osf__)
#include <netosi/nsp_addr.h>
#else
#include <netdnet/nsp_addr.h>
#endif

#ifdef __cplusplus
}
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static U32
iconst(name)
char *name;
{
    switch (*name) {
    case 'A':
#ifndef ACC_DEFER
	if (strEQ(name, "ACC_DEFER"))
	    goto not_there;
#endif
#ifndef ACC_IMMED
	if (strEQ(name, "ACC_IMMED"))
	    goto not_there;
#endif
	break;
    case 'D':
#ifndef DNOBJECT_CTERM
	if (strEQ(name, "DNOBJECT_CTERM"))
	    goto not_there;
#endif
#ifndef DNOBJECT_DTERM
	if (strEQ(name, "DNOBJECT_DTERM"))
	    goto not_there;
#endif
#ifndef DNOBJECT_DTR
	if (strEQ(name, "DNOBJECT_DTR"))
	    goto not_there;
#endif
#ifndef DNOBJECT_EVR
	if (strEQ(name, "DNOBJECT_EVR"))
	    goto not_there;
#endif
#ifndef DNOBJECT_FAL
	if (strEQ(name, "DNOBJECT_FAL"))
	    goto not_there;
#endif
#ifndef DNOBJECT_MAIL11
	if (strEQ(name, "DNOBJECT_MAIL11"))
	    goto not_there;
#endif
#ifndef DNOBJECT_MIRROR
	if (strEQ(name, "DNOBJECT_MIRROR"))
	    goto not_there;
#endif
#ifndef DNOBJECT_NICE
	if (strEQ(name, "DNOBJECT_NICE"))
	    goto not_there;
#endif
#ifndef DNOBJECT_PHONE
	if (strEQ(name, "DNOBJECT_PHONE"))
	    goto not_there;
#endif
#ifndef DNPROTO_EVL
	if (strEQ(name, "DNPROTO_EVL"))
	    goto not_there;
#endif
#ifndef DNPROTO_EVR
	if (strEQ(name, "DNPROTO_EVR"))
	    goto not_there;
#endif
#ifndef DNPROTO_NML
	if (strEQ(name, "DNPROTO_NML"))
	    goto not_there;
#endif
#ifndef DNPROTO_NSP
	if (strEQ(name, "DNPROTO_NSP"))
	    goto not_there;
#endif
#ifndef DNPROTO_NSPT
	if (strEQ(name, "DNPROTO_NSPT"))
	    goto not_there;
#endif
#ifndef DNPROTO_ROU
	if (strEQ(name, "DNPROTO_ROU"))
	    goto not_there;
#endif
#ifndef DN_MAXADDL
	if (strEQ(name, "DN_MAXADDL"))
	    goto not_there;
#endif
#ifndef DSO_ACCEPTMODE
	if (strEQ(name, "DSO_ACCEPTMODE"))
	    goto not_there;
#endif
#ifndef DSO_CONACCEPT
	if (strEQ(name, "DSO_CONACCEPT"))
	    goto not_there;
#endif
#ifndef DSO_CONACCESS
	if (strEQ(name, "DSO_CONACCESS"))
	    goto not_there;
#endif
#ifndef DSO_CONDATA
	if (strEQ(name, "DSO_CONDATA"))
	    goto not_there;
#endif
#ifndef DSO_CONREJECT
	if (strEQ(name, "DSO_CONREJECT"))
	    goto not_there;
#endif
#ifndef DSO_DISDATA
	if (strEQ(name, "DSO_DISDATA"))
	    goto not_there;
#endif
#ifndef DSO_LINKINFO
	if (strEQ(name, "DSO_LINKINFO"))
	    goto not_there;
#endif
#ifndef DSO_MAX
	if (strEQ(name, "DSO_MAX"))
	    goto not_there;
#endif
#ifndef DSO_SEQPACKET
	if (strEQ(name, "DSO_SEQPACKET"))
	    goto not_there;
#endif
#ifndef DSO_STREAM
	if (strEQ(name, "DSO_STREAM"))
	    goto not_there;
#endif
	break;
    case 'L':
#ifndef LL_CONNECTING
	if (strEQ(name, "LL_CONNECTING"))
	    goto not_there;
#endif
#ifndef LL_DISCONNECTING
	if (strEQ(name, "LL_DISCONNECTING"))
	    goto not_there;
#endif
#ifndef LL_INACTIVE
	if (strEQ(name, "LL_INACTIVE"))
	    goto not_there;
#endif
#ifndef LL_RUNNING
	if (strEQ(name, "LL_RUNNING"))
	    goto not_there;
#endif
	break;
    case 'N':
#ifndef ND_MAXNODE
	if (strEQ(name, "ND_MAXNODE"))
	    goto not_there;
#endif
#ifndef ND_PERMANENT
	if (strEQ(name, "ND_PERMANENT"))
	    goto not_there;
#endif
#ifndef ND_VERSION
	if (strEQ(name, "ND_VERSION"))
	    goto not_there;
#endif
#ifndef ND_VOLATILE
	if (strEQ(name, "ND_VOLATILE"))
	    goto not_there;
#endif
	break;
    case 'O':
#ifndef OB_MAXFILE
	if (strEQ(name, "OB_MAXFILE"))
	    goto not_there;
#endif
#ifndef OB_MAXNAME
	if (strEQ(name, "OB_MAXNAME"))
	    goto not_there;
#endif
#ifndef OB_MAXUSER
	if (strEQ(name, "OB_MAXUSER"))
	    goto not_there;
#endif
#ifndef OF_DEFER
	if (strEQ(name, "OF_DEFER"))
	    goto not_there;
#endif
#ifndef OF_STREAM
	if (strEQ(name, "OF_STREAM"))
	    goto not_there;
#endif
#ifndef OSIOCGNETADDR
	if (strEQ(name, "OSIOCGNETADDR"))
	    goto not_there;
#endif
#ifndef OSIOCSNETADDR
	if (strEQ(name, "OSIOCSNETADDR"))
	    goto not_there;
#endif
	break;
    case 'S':
#ifndef SDF_PROXY
	if (strEQ(name, "SDF_PROXY"))
	    goto not_there;
#endif
#ifndef SDF_UICPROXY
	if (strEQ(name, "SDF_UICPROXY"))
	    goto not_there;
#endif
#ifndef SDF_WILD
	if (strEQ(name, "SDF_WILD"))
	    goto not_there;
#endif
#ifndef SIOCGNETADDR
	if (strEQ(name, "SIOCGNETADDR"))
	    goto not_there;
#endif
#ifndef SIOCSNETADDR
	if (strEQ(name, "SIOCSNETADDR"))
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static char *
sconst(name)
char *name;
{
    switch (name[sizeof "DNOBJ_" - 1]) {
    case 'C':
#ifndef DNOBJ_CTERM
	if (strEQ(name, "DNOBJ_CTERM"))
	    goto not_there;
#endif
	break;
    case 'D':
#ifndef DNOBJ_DTERM
	if (strEQ(name, "DNOBJ_DTERM"))
	    goto not_there;
#endif
#ifndef DNOBJ_DTR
	if (strEQ(name, "DNOBJ_DTR"))
	    goto not_there;
#endif
	break;
    case 'E':
#ifndef DNOBJ_EVR
	if (strEQ(name, "DNOBJ_EVR"))
	    goto not_there;
#endif
	break;
    case 'F':
#ifndef DNOBJ_FAL
	if (strEQ(name, "DNOBJ_FAL"))
	    goto not_there;
#endif
	break;
    case 'M':
#ifndef DNOBJ_MAIL11
	if (strEQ(name, "DNOBJ_MAIL11"))
	    goto not_there;
#endif
#ifndef DNOBJ_MIRROR
	if (strEQ(name, "DNOBJ_MIRROR"))
	    goto not_there;
#endif
	break;
    case 'N':
#ifndef DNOBJ_NICE
	if (strEQ(name, "DNOBJ_NICE"))
	    goto not_there;
#endif
	break;
    case 'P':
#ifndef DNOBJ_PHONE
	if (strEQ(name, "DNOBJ_PHONE"))
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static SV *
constant(name, arg)
char *name;
{
    U32 uv;
    char *cp;
    SV *svp;

    svp = sv_newmortal();
    errno = 0;
    if (strnEQ(name, "DNOBJ_", 6)) {
	cp = sconst(name);
	if (!errno && cp) {
	    sv_setpv(svp, cp);
	}
    }
    else {
	uv = iconst(name);
	if (!errno) {
	    sv_setuv(svp, (UV)uv);
	}
    }
    return svp;
}


MODULE = Net::Dnet		PACKAGE = Net::Dnet	PREFIX = f_sc_

PROTOTYPES: ENABLE


#ifdef DNOBJ_CTERM
#define	f_sc_DNOBJ_CTERM()	DNOBJ_CTERM
char *
f_sc_DNOBJ_CTERM()

#endif

#ifdef DNOBJ_DTERM
#define	f_sc_DNOBJ_DTERM()	DNOBJ_DTERM
char *
f_sc_DNOBJ_DTERM()

#endif

#ifdef DNOBJ_DTR
#define	f_sc_DNOBJ_DTR()	DNOBJ_DTR
char *
f_sc_DNOBJ_DTR()

#endif

#ifdef DNOBJ_EVR
#define	f_sc_DNOBJ_EVR()	DNOBJ_EVR
char *
f_sc_DNOBJ_EVR()

#endif

#ifdef DNOBJ_FAL
#define	f_sc_DNOBJ_FAL()	DNOBJ_FAL
char *
f_sc_DNOBJ_FAL()

#endif

#ifdef DNOBJ_MAIL11
#define	f_sc_DNOBJ_MAIL11()	DNOBJ_MAIL11
char *
f_sc_DNOBJ_MAIL11()

#endif

#ifdef DNOBJ_MIRROR
#define	f_sc_DNOBJ_MIRROR()	DNOBJ_MIRROR
char *
f_sc_DNOBJ_MIRROR()

#endif

#ifdef DNOBJ_NICE
#define	f_sc_DNOBJ_NICE()	DNOBJ_NICE
char *
f_sc_DNOBJ_NICE()

#endif

#ifdef DNOBJ_PHONE
#define	f_sc_DNOBJ_PHONE()	DNOBJ_PHONE
char *
f_sc_DNOBJ_PHONE()

#endif


MODULE = Net::Dnet		PACKAGE = Net::Dnet	PREFIX = f_ic_

#ifdef ACC_DEFER
#define	f_ic_ACC_DEFER()	ACC_DEFER
U32
f_ic_ACC_DEFER()

#endif

#ifdef ACC_IMMED
#define	f_ic_ACC_IMMED()	ACC_IMMED
U32
f_ic_ACC_IMMED()

#endif

#ifdef DNOBJECT_CTERM
#define	f_ic_DNOBJECT_CTERM()	DNOBJECT_CTERM
U32
f_ic_DNOBJECT_CTERM()

#endif

#ifdef DNOBJECT_DTERM
#define	f_ic_DNOBJECT_DTERM()	DNOBJECT_DTERM
U32
f_ic_DNOBJECT_DTERM()

#endif

#ifdef DNOBJECT_DTR
#define	f_ic_DNOBJECT_DTR()	DNOBJECT_DTR
U32
f_ic_DNOBJECT_DTR()

#endif

#ifdef DNOBJECT_EVR
#define	f_ic_DNOBJECT_EVR()	DNOBJECT_EVR
U32
f_ic_DNOBJECT_EVR()

#endif

#ifdef DNOBJECT_FAL
#define	f_ic_DNOBJECT_FAL()	DNOBJECT_FAL
U32
f_ic_DNOBJECT_FAL()

#endif

#ifdef DNOBJECT_MAIL11
#define	f_ic_DNOBJECT_MAIL11()	DNOBJECT_MAIL11
U32
f_ic_DNOBJECT_MAIL11()

#endif

#ifdef DNOBJECT_MIRROR
#define	f_ic_DNOBJECT_MIRROR()	DNOBJECT_MIRROR
U32
f_ic_DNOBJECT_MIRROR()

#endif

#ifdef DNOBJECT_NICE
#define	f_ic_DNOBJECT_NICE()	DNOBJECT_NICE
U32
f_ic_DNOBJECT_NICE()

#endif

#ifdef DNOBJECT_PHONE
#define	f_ic_DNOBJECT_PHONE()	DNOBJECT_PHONE
U32
f_ic_DNOBJECT_PHONE()

#endif

#ifdef DNPROTO_EVL
#define	f_ic_DNPROTO_EVL()	DNPROTO_EVL
U32
f_ic_DNPROTO_EVL()

#endif

#ifdef DNPROTO_EVR
#define	f_ic_DNPROTO_EVR()	DNPROTO_EVR
U32
f_ic_DNPROTO_EVR()

#endif

#ifdef DNPROTO_NML
#define	f_ic_DNPROTO_NML()	DNPROTO_NML
U32
f_ic_DNPROTO_NML()

#endif

#ifdef DNPROTO_NSP
#define	f_ic_DNPROTO_NSP()	DNPROTO_NSP
U32
f_ic_DNPROTO_NSP()

#endif

#ifdef DNPROTO_NSPT
#define	f_ic_DNPROTO_NSPT()	DNPROTO_NSPT
U32
f_ic_DNPROTO_NSPT()

#endif

#ifdef DNPROTO_ROU
#define	f_ic_DNPROTO_ROU()	DNPROTO_ROU
U32
f_ic_DNPROTO_ROU()

#endif

#ifdef DN_MAXADDL
#define	f_ic_DN_MAXADDL()	DN_MAXADDL
U32
f_ic_DN_MAXADDL()

#endif

#ifdef DSO_ACCEPTMODE
#define	f_ic_DSO_ACCEPTMODE()	DSO_ACCEPTMODE
U32
f_ic_DSO_ACCEPTMODE()

#endif

#ifdef DSO_CONACCEPT
#define	f_ic_DSO_CONACCEPT()	DSO_CONACCEPT
U32
f_ic_DSO_CONACCEPT()

#endif

#ifdef DSO_CONACCESS
#define	f_ic_DSO_CONACCESS()	DSO_CONACCESS
U32
f_ic_DSO_CONACCESS()

#endif

#ifdef DSO_CONDATA
#define	f_ic_DSO_CONDATA()	DSO_CONDATA
U32
f_ic_DSO_CONDATA()

#endif

#ifdef DSO_CONREJECT
#define	f_ic_DSO_CONREJECT()	DSO_CONREJECT
U32
f_ic_DSO_CONREJECT()

#endif

#ifdef DSO_DISDATA
#define	f_ic_DSO_DISDATA()	DSO_DISDATA
U32
f_ic_DSO_DISDATA()

#endif

#ifdef DSO_LINKINFO
#define	f_ic_DSO_LINKINFO()	DSO_LINKINFO
U32
f_ic_DSO_LINKINFO()

#endif

#ifdef DSO_MAX
#define	f_ic_DSO_MAX()	DSO_MAX
U32
f_ic_DSO_MAX()

#endif

#ifdef DSO_SEQPACKET
#define	f_ic_DSO_SEQPACKET()	DSO_SEQPACKET
U32
f_ic_DSO_SEQPACKET()

#endif

#ifdef DSO_STREAM
#define	f_ic_DSO_STREAM()	DSO_STREAM
U32
f_ic_DSO_STREAM()

#endif

#ifdef LL_CONNECTING
#define	f_ic_LL_CONNECTING()	LL_CONNECTING
U32
f_ic_LL_CONNECTING()

#endif

#ifdef LL_DISCONNECTING
#define	f_ic_LL_DISCONNECTING()	LL_DISCONNECTING
U32
f_ic_LL_DISCONNECTING()

#endif

#ifdef LL_INACTIVE
#define	f_ic_LL_INACTIVE()	LL_INACTIVE
U32
f_ic_LL_INACTIVE()

#endif

#ifdef LL_RUNNING
#define	f_ic_LL_RUNNING()	LL_RUNNING
U32
f_ic_LL_RUNNING()

#endif

#ifdef ND_MAXNODE
#define	f_ic_ND_MAXNODE()	ND_MAXNODE
U32
f_ic_ND_MAXNODE()

#endif

#ifdef ND_PERMANENT
#define	f_ic_ND_PERMANENT()	ND_PERMANENT
U32
f_ic_ND_PERMANENT()

#endif

#ifdef ND_VERSION
#define	f_ic_ND_VERSION()	ND_VERSION
U32
f_ic_ND_VERSION()

#endif

#ifdef ND_VOLATILE
#define	f_ic_ND_VOLATILE()	ND_VOLATILE
U32
f_ic_ND_VOLATILE()

#endif

#ifdef OB_MAXFILE
#define	f_ic_OB_MAXFILE()	OB_MAXFILE
U32
f_ic_OB_MAXFILE()

#endif

#ifdef OB_MAXNAME
#define	f_ic_OB_MAXNAME()	OB_MAXNAME
U32
f_ic_OB_MAXNAME()

#endif

#ifdef OB_MAXUSER
#define	f_ic_OB_MAXUSER()	OB_MAXUSER
U32
f_ic_OB_MAXUSER()

#endif

#ifdef OF_DEFER
#define	f_ic_OF_DEFER()	OF_DEFER
U32
f_ic_OF_DEFER()

#endif

#ifdef OF_STREAM
#define	f_ic_OF_STREAM()	OF_STREAM
U32
f_ic_OF_STREAM()

#endif

#ifdef OSIOCGNETADDR
#define	f_ic_OSIOCGNETADDR()	OSIOCGNETADDR
U32
f_ic_OSIOCGNETADDR()

#endif

#ifdef OSIOCSNETADDR
#define	f_ic_OSIOCSNETADDR()	OSIOCSNETADDR
U32
f_ic_OSIOCSNETADDR()

#endif

#ifdef SDF_PROXY
#define	f_ic_SDF_PROXY()	SDF_PROXY
U32
f_ic_SDF_PROXY()

#endif

#ifdef SDF_UICPROXY
#define	f_ic_SDF_UICPROXY()	SDF_UICPROXY
U32
f_ic_SDF_UICPROXY()

#endif

#ifdef SDF_WILD
#define	f_ic_SDF_WILD()	SDF_WILD
U32
f_ic_SDF_WILD()

#endif

#ifdef SIOCGNETADDR
#define	f_ic_SIOCGNETADDR()	SIOCGNETADDR
U32
f_ic_SIOCGNETADDR()

#endif

#ifdef SIOCSNETADDR
#define	f_ic_SIOCSNETADDR()	SIOCSNETADDR
U32
f_ic_SIOCSNETADDR()

#endif


MODULE = Net::Dnet		PACKAGE = Net::Dnet


SV *
constant(name)
	char *		name

SV *
pack_sockaddr_dn(family=AF_DECnet,flags=0,object=&sv_no,naddr=NULL)
	U8	family
	U8	flags
	SV *	object
	SV *	naddr
    PREINIT:
	struct sockaddr_dn sdn;
	char *	pvptr;
	STRLEN	pvlen;
	struct dn_naddr dnaddr;
    CODE:
	Zero(&sdn, 1, struct sockaddr_dn);
	sdn.sdn_family = family;
	sdn.sdn_flags = flags;
	ST(0) = sv_newmortal();
	if (naddr) {
	    pvptr = SvPV(naddr, pvlen);
	    if ((pvlen < 4) || (pvlen > sizeof dnaddr)) {
		pvptr = "";
		pvlen = 1;	/* keep the warning in one place */
	    }
	    Copy(pvptr, &dnaddr, pvlen, char);
	    if ((dnaddr.a_len < 2) || (dnaddr.a_len > DN_MAXADDL)) {
		gv_efullname3(ST(0), CvGV(cv), Nullch);
		warn("Invalid address parameter passed to %s",
		     SvPVX(ST(0)));
		XSRETURN_UNDEF;
	    }
	    StructCopy(&dnaddr, &sdn.sdn_add, struct dn_naddr);
	}
	/* what about SDF_UICPROXY in flags vs. sdn_objname? */
	if ((SvIOK(object) || SvNOK(object)) && !SvPOK(object)) {
	    sdn.sdn_objnum = SvIV(object);
	}
	else {
	    pvptr = SvPV(object, pvlen);
	    if (pvlen) {
		if (strnNE(pvptr, "#0=", 3) && '#' == *pvptr && pvlen > 1) {
		    char *sbeg = pvptr + 1;
		    char *send = pvptr + pvlen;
		    while (sbeg < send) {
			if (!isDIGIT(*sbeg))
			    break;
			sbeg++;
		    }
		    if (sbeg == send) {
			UV obnum;
			obnum = atol(pvptr+1);
			if (((U8)obnum) != obnum) {
			    gv_efullname3(ST(0), CvGV(cv), Nullch);
			    warn("Object number %s truncated in %s",
				 pvptr, SvPVX(ST(0)));
			}
			sdn.sdn_objnum = obnum;
			pvlen = 0;
		    }
		    else {
			gv_efullname3(ST(0), CvGV(cv), Nullch);
			warn("Malformed object number %s in %s, %s",
			     pvptr, SvPVX(ST(0)), "used as an object name");
		    }
		}
		else if (strnEQ(pvptr, "#0=", 3)) {
		    pvlen -= 3;
		    pvptr += 3;
		}
	    }
	    if (pvlen) {
		if (pvlen > sizeof(sdn.sdn_objname)) {
		    gv_efullname3(ST(0), CvGV(cv), Nullch);
		    warn("Object name %s truncated in %s",
			 pvptr, SvPVX(ST(0)));
		    pvlen = sizeof(sdn.sdn_objname);
		}
		Copy(pvptr, sdn.sdn_objname, pvlen, char);
		sdn.sdn_objnamel = pvlen;
	    }
	}
	sv_setpvn(ST(0), (char *)&sdn, sizeof sdn);


