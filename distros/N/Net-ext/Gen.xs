/*

# Copyright 1995,2002 Spider Boardman.
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

/*
 * Can't rely on #ifdef to keep some compilers from griping about a #pragma
 * which they don't recognize, so do it the old-fashioned way.
 */

static char const rcsid[] = "@(#) $Id: Gen.xs,v 1.24 2002/04/10 11:05:58 spider Exp $";

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef I_FCNTL
#include <fcntl.h>
#endif
#ifdef I_SYS_FILE
#include <sys/file.h>
#endif

#ifndef VMS
# ifdef I_SYS_TYPES
#  include <sys/types.h>
# endif
#include <sys/socket.h>
#ifdef I_SYS_UN
#include <sys/un.h>
#endif
# ifdef I_NETINET_IN
#  include <netinet/in.h>
# endif
#include <netdb.h>
#else
#include "sockadapt.h"
#endif

#include "netgen.h"

#ifdef BAD_TCP_MSS
# undef TCP_MSS
# define TCP_MSS TCP_MSS_IETF
#endif

#ifndef	SHUT_RD
#ifdef	O_RDONLY
#define	SHUT_RD	O_RDONLY
#else
#define	SHUT_RD	0
#endif
#endif

#ifndef	SHUT_WR
#ifdef	O_WRONLY
#define	SHUT_WR	O_WRONLY
#else
#define	SHUT_WR	1
#endif
#endif

#ifndef	SHUT_RDWR
#ifdef	O_RDWR
#define	SHUT_RDWR	O_RDWR
#else
#define	SHUT_RDWR	2
#endif
#endif

#if !defined(PATCHLEVEL)
#include <patchlevel.h>
#endif
#if (PATCHLEVEL < 5)
#ifndef PL_sv_undef
#define	PL_dowarn	dowarn
#define	PL_sv_no	sv_no
#define	PL_sv_undef	sv_undef
#endif
#endif

#ifndef dTHX
#define dTHX	dTHR
#define pTHX_
#define _pTHX
#define pTHX
#define aTHX
#define aTHX_
#define _aTHX
#define NV double
#endif

#ifndef dTHR
#define dTHR extern int Perl___notused
#endif

#ifdef __cplusplus
}
#endif

/* Just in case still don't have MIN and we need it for TCP_MSS.... */
#ifndef MIN
#define	MIN(_A,_B)	(((_A)<(_B))?(_A):(_B))
#endif

/* Default EAGAIN and EWOULDBLOCK from each other, punting to 0 if neither
 * is available.
 */
#ifndef	EAGAIN
#ifndef	EWOULDBLOCK
#define	EWOULDBLOCK	0
#endif
#define	EAGAIN		EWOULDBLOCK
#endif
#ifndef	EWOULDBLOCK
#define	EWOULDBLOCK	EAGAIN
#endif

static void
#ifdef CAN_PROTOTYPE
#define newmissing(_hv,_nm,_fl) S_newmissing(aTHX_ _hv, _nm, _fl)
S_newmissing(pTHX_ HV *missing, char *name, char *file)
#else
newmissing(missing, name, file)
HV *missing;
char *name;
char *file;
#endif
{
    STRLEN klen;
    CV *cv;
    klen = strlen(name);
    (void) hv_fetch(missing, name, klen, TRUE);
    cv = newXS(name, NULL, file); /* newSUB with no block */
    sv_setsv((SV*)cv, &PL_sv_no); /* prototype it as "()" */
}

#ifndef CVf_CONST
/*
 * cv_constant() exists so that the constant XSUBs will return their
 * proper values even when not inlined.
 */

static
XS(cv_constant)
{
    dXSARGS;
    if (items != 0) {
	ST(0) = sv_newmortal();
	gv_efullname3(ST(0), CvGV(cv), Nullch);
	croak("Usage: %s()", SvPVX(ST(0)));
    }
    if (CvSTART(cv)) {
	ST(0) = ((SVOP*)CvSTART(cv))->op_sv;
	XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

/*
 * Create a new 'constant' XSUB, suitable for inlining as a constant.
 * Depends on the behaviour of cv_const_sv().
 */

static void
#ifdef CAN_PROTOTYPE
#define newXSconst(_nm,_vsv,_fl) S_newXSconst(aTHX_ _nm, _vsv, _fl)
S_newXSconst(pTHX_ char *name, SV *valsv, char *file)
#else
newXSconst(name, valsv, file)
char * name;
SV * valsv;
char * file;
#endif
{
    CV *cv;
    OP *svop;
    cv = newXS(name, cv_constant, file);
    sv_setsv((SV*)cv, &PL_sv_no);	/* prototype it as () */
    if (SvTEMP(valsv))			/* Don't let mortality get you down. */
	SvREFCNT_inc(valsv);		/* Give it an afterlife.  :-> */
    svop = newSVOP(OP_CONST, 0, valsv);	/* does SvREADONLY_on */
    svop->op_next = Nullop;		/* terminate search in cv_const_sv() */
    CvSTART(cv) = svop;			/* voila!  we're a constant! */
}
#else	/* !defined CVf_CONST, now defined */
#define newXSconst(_nm,_vsv,_fl) Perl_newCONSTSUB(aTHX_ Nullhv, _nm, _vsv)
#endif	/* defined CVf_CONST */

/*
 * Auxiliary routines to create constant XSUBs of various types.
 */

static void
#ifdef CAN_PROTOTYPE
#define newXSconstPV(_nm,_st,_fl) S_newXSconstPV(aTHX_ _nm, _st, _fl)
S_newXSconstPV(pTHX_ char *name, char *string, char *file)
#else
newXSconstPV(name, string, file)
char *name;
char *string;
char *file;
#endif
{
    SV *valsv = newSVpv(string, strlen(string));
    newXSconst(name, valsv, file);
}

static void
#ifdef CAN_PROTOTYPE
#define newXSconstPVN(_nm,_st,_ln,_fl) S_newXSconstPVN(aTHX_ _nm, _st, _ln, _fl)
S_newXSconstPVN(pTHX_ char *name, char *string, STRLEN len, char *file)
#else
newXSconstPVN(name, string, len, file)
char *name;
char *string;
STRLEN len;
char *file;
#endif
{
    SV *valsv = newSVpv(string, len);
    newXSconst(name, valsv, file);
}

static void
#ifdef CAN_PROTOTYPE
#define newXSconstIV(_nm,_iv,_fl) S_newXSconstIV(aTHX_ _nm, _iv, _fl)
S_newXSconstIV(pTHX_ char *name, IV ival, char *file)
#else
newXSconstIV(name, ival, file)
char *name;
IV ival;
char *file;
#endif
{
    newXSconst(name, newSViv(ival), file);
}

static void
#ifdef CAN_PROTOTYPE
#define newXSconstUV(_nm,_uv,_fl) S_newXSconstUV(aTHX_ _nm, _uv, _fl)
S_newXSconstUV(pTHX_ char *name, UV uval, char *file)
#else
newXSconstUV(name, uval, file)
char *	name;
UV	uval;
char *	file;
#endif
{
    SV * valsv = newSVsv(&PL_sv_undef);	/* missing newSVuv()! */
    sv_setuv(valsv, uval);
    newXSconst(name, valsv, file);
}

static void
#ifdef CAN_PROTOTYPE
#define newXSconstNV(_nm,_nv,_fl) S_newXSconstNV(aTHX_ _nm, _nv, _fl)
S_newXSconstNV(pTHX_ char *name, NV nval, char *file)
#else
newXSconstNV(name, nval, file)
char *	name;
double	nval;
char *	file;
#endif
{
    newXSconst(name, newSVnv(nval), file);
}


typedef U32 sv_inaddr_t;
/*
 * typemap helper for T_INADDR inputs
 */

static sv_inaddr_t
#ifdef CAN_PROTOTYPE
#define sv2inaddr(_sv) S_sv2inaddr(aTHX_ _sv)
S_sv2inaddr(pTHX_ SV *sv)
#else
sv2inaddr(sv)
SV *sv;
#endif
{
    struct in_addr ina;
    char *cp;
    STRLEN len;
    if (!sv)
	return 0;
    if (SvGMAGICAL(sv)) {
	mg_get(sv);
	if (SvIOKp(sv))
	    return (sv_inaddr_t)SvUVX(sv);
	if (SvNOKp(sv))
	    return (sv_inaddr_t)U_V(SvNVX(sv));
	if (!SvPOKp(sv) || SvCUR(sv) != sizeof ina)
	    return (sv_inaddr_t)sv_2uv(sv);
    }
    else if (SvROK(sv))
	return (sv_inaddr_t)sv_2uv(sv);
    else if (SvNIOK(sv)) {
	if (SvIOK(sv))
	    return (sv_inaddr_t)SvUVX(sv);
	return (sv_inaddr_t)U_V(SvNVX(sv));
    }
    else if (!SvPOK(sv) || SvCUR(sv) != sizeof ina)
	return (sv_inaddr_t)sv_2uv(sv);
    /* Here for apparent inaddr's, perhaps from unpack_sockaddr_in(). */
    cp = SvPV(sv,len);
    Copy(cp, (char*)&ina, len, char);
    return (sv_inaddr_t)ntohl(ina.s_addr);
}


/*
 * In the XS sections which follow, the sections with f_?c_ prefixes
 * are generated from the list of exportable constants.
 */

MODULE = Net::Gen		PACKAGE = Net::Gen

PROTOTYPES: ENABLE

BOOT:
    {
	HV *missing = perl_get_hv("Net::Gen::_missing", GV_ADDMULTI);


MODULE = Net::Gen		PACKAGE = Net::TCP	PREFIX = f_uc_

BOOT:
	newXSconstUV("Net::TCP::TCPOPT_EOL", TCPOPT_EOL, file);
	newXSconstUV("Net::TCP::TCPOPT_MAXSEG", TCPOPT_MAXSEG, file);
	newXSconstUV("Net::TCP::TCPOPT_NOP", TCPOPT_NOP, file);
	newXSconstUV("Net::TCP::TCPOPT_WINDOW", TCPOPT_WINDOW, file);
#ifdef TCP_MAXSEG
	newXSconstUV("Net::TCP::TCP_MAXSEG", TCP_MAXSEG, file);
#else
	newmissing(missing, "Net::TCP::TCP_MAXSEG", file);
#endif
	newXSconstUV("Net::TCP::TCP_MAXWIN", TCP_MAXWIN, file);
	newXSconstUV("Net::TCP::TCP_MAX_WINSHIFT", TCP_MAX_WINSHIFT, file);
	newXSconstUV("Net::TCP::TCP_MSS", TCP_MSS, file);
#ifdef TCP_NODELAY
	newXSconstUV("Net::TCP::TCP_NODELAY", TCP_NODELAY, file);
#else
	newmissing(missing, "Net::TCP::TCP_NODELAY", file);
#endif
#ifdef TCP_RPTR2RXT
	newXSconstUV("Net::TCP::TCP_RPTR2RXT", TCP_RPTR2RXT, file);
#else
	newmissing(missing, "Net::TCP::TCP_RPTR2RXT", file);
#endif
	newXSconstUV("Net::TCP::TH_ACK", TH_ACK, file);
	newXSconstUV("Net::TCP::TH_FIN", TH_FIN, file);
	newXSconstUV("Net::TCP::TH_PUSH", TH_PUSH, file);
	newXSconstUV("Net::TCP::TH_RST", TH_RST, file);
	newXSconstUV("Net::TCP::TH_SYN", TH_SYN, file);
	newXSconstUV("Net::TCP::TH_URG", TH_URG, file);


MODULE = Net::Gen		PACKAGE = Net::Inet	PREFIX = f_uc_

BOOT:
	newXSconstUV("Net::Inet::DEFTTL", DEFTTL, file);
	newXSconstUV("Net::Inet::ICMP_ADVLENMIN", ICMP_ADVLENMIN, file);
	newXSconstUV("Net::Inet::ICMP_ECHO", ICMP_ECHO, file);
	newXSconstUV("Net::Inet::ICMP_ECHOREPLY", ICMP_ECHOREPLY, file);
	newXSconstUV("Net::Inet::ICMP_IREQ", ICMP_IREQ, file);
	newXSconstUV("Net::Inet::ICMP_IREQREPLY", ICMP_IREQREPLY, file);
	newXSconstUV("Net::Inet::ICMP_MASKLEN", ICMP_MASKLEN, file);
	newXSconstUV("Net::Inet::ICMP_MASKREPLY", ICMP_MASKREPLY, file);
	newXSconstUV("Net::Inet::ICMP_MASKREQ", ICMP_MASKREQ, file);
	newXSconstUV("Net::Inet::ICMP_MAXTYPE", ICMP_MAXTYPE, file);
	newXSconstUV("Net::Inet::ICMP_MINLEN", ICMP_MINLEN, file);
	newXSconstUV("Net::Inet::ICMP_PARAMPROB", ICMP_PARAMPROB, file);
	newXSconstUV("Net::Inet::ICMP_REDIRECT", ICMP_REDIRECT, file);
	newXSconstUV("Net::Inet::ICMP_REDIRECT_HOST", ICMP_REDIRECT_HOST, file);
	newXSconstUV("Net::Inet::ICMP_REDIRECT_NET", ICMP_REDIRECT_NET, file);
	newXSconstUV("Net::Inet::ICMP_REDIRECT_TOSHOST", ICMP_REDIRECT_TOSHOST, file);
	newXSconstUV("Net::Inet::ICMP_REDIRECT_TOSNET", ICMP_REDIRECT_TOSNET, file);
	newXSconstUV("Net::Inet::ICMP_SOURCEQUENCH", ICMP_SOURCEQUENCH, file);
	newXSconstUV("Net::Inet::ICMP_TIMXCEED", ICMP_TIMXCEED, file);
	newXSconstUV("Net::Inet::ICMP_TIMXCEED_INTRANS", ICMP_TIMXCEED_INTRANS, file);
	newXSconstUV("Net::Inet::ICMP_TIMXCEED_REASS", ICMP_TIMXCEED_REASS, file);
	newXSconstUV("Net::Inet::ICMP_TSLEN", ICMP_TSLEN, file);
	newXSconstUV("Net::Inet::ICMP_TSTAMP", ICMP_TSTAMP, file);
	newXSconstUV("Net::Inet::ICMP_TSTAMPREPLY", ICMP_TSTAMPREPLY, file);
	newXSconstUV("Net::Inet::ICMP_UNREACH", ICMP_UNREACH, file);
	newXSconstUV("Net::Inet::ICMP_UNREACH_HOST", ICMP_UNREACH_HOST, file);
	newXSconstUV("Net::Inet::ICMP_UNREACH_NEEDFRAG", ICMP_UNREACH_NEEDFRAG, file);
	newXSconstUV("Net::Inet::ICMP_UNREACH_NET", ICMP_UNREACH_NET, file);
	newXSconstUV("Net::Inet::ICMP_UNREACH_PORT", ICMP_UNREACH_PORT, file);
	newXSconstUV("Net::Inet::ICMP_UNREACH_PROTOCOL", ICMP_UNREACH_PROTOCOL, file);
	newXSconstUV("Net::Inet::ICMP_UNREACH_SRCFAIL", ICMP_UNREACH_SRCFAIL, file);
	newXSconstUV("Net::Inet::IN_CLASSA_HOST", IN_CLASSA_HOST, file);
	newXSconstUV("Net::Inet::IN_CLASSA_MAX", IN_CLASSA_MAX, file);
	newXSconstUV("Net::Inet::IN_CLASSA_NET", IN_CLASSA_NET, file);
	newXSconstUV("Net::Inet::IN_CLASSA_NSHIFT", IN_CLASSA_NSHIFT, file);
#ifdef IN_CLASSA_SUBHOST
	newXSconstUV("Net::Inet::IN_CLASSA_SUBHOST", IN_CLASSA_SUBHOST, file);
#else
	newmissing(missing, "Net::Inet::IN_CLASSA_SUBHOST", file);
#endif
#ifdef IN_CLASSA_SUBNET
	newXSconstUV("Net::Inet::IN_CLASSA_SUBNET", IN_CLASSA_SUBNET, file);
#else
	newmissing(missing, "Net::Inet::IN_CLASSA_SUBNET", file);
#endif
#ifdef IN_CLASSA_SUBNSHIFT
	newXSconstUV("Net::Inet::IN_CLASSA_SUBNSHIFT", IN_CLASSA_SUBNSHIFT, file);
#else
	newmissing(missing, "Net::Inet::IN_CLASSA_SUBNSHIFT", file);
#endif
	newXSconstUV("Net::Inet::IN_CLASSB_HOST", IN_CLASSB_HOST, file);
	newXSconstUV("Net::Inet::IN_CLASSB_MAX", IN_CLASSB_MAX, file);
	newXSconstUV("Net::Inet::IN_CLASSB_NET", IN_CLASSB_NET, file);
	newXSconstUV("Net::Inet::IN_CLASSB_NSHIFT", IN_CLASSB_NSHIFT, file);
#ifdef IN_CLASSB_SUBHOST
	newXSconstUV("Net::Inet::IN_CLASSB_SUBHOST", IN_CLASSB_SUBHOST, file);
#else
	newmissing(missing, "Net::Inet::IN_CLASSB_SUBHOST", file);
#endif
#ifdef IN_CLASSB_SUBNET
	newXSconstUV("Net::Inet::IN_CLASSB_SUBNET", IN_CLASSB_SUBNET, file);
#else
	newmissing(missing, "Net::Inet::IN_CLASSB_SUBNET", file);
#endif
#ifdef IN_CLASSB_SUBNSHIFT
	newXSconstUV("Net::Inet::IN_CLASSB_SUBNSHIFT", IN_CLASSB_SUBNSHIFT, file);
#else
	newmissing(missing, "Net::Inet::IN_CLASSB_SUBNSHIFT", file);
#endif
	newXSconstUV("Net::Inet::IN_CLASSC_HOST", IN_CLASSC_HOST, file);
	newXSconstUV("Net::Inet::IN_CLASSC_MAX", IN_CLASSC_MAX, file);
	newXSconstUV("Net::Inet::IN_CLASSC_NET", IN_CLASSC_NET, file);
	newXSconstUV("Net::Inet::IN_CLASSC_NSHIFT", IN_CLASSC_NSHIFT, file);
	newXSconstUV("Net::Inet::IN_CLASSD_HOST", IN_CLASSD_HOST, file);
	newXSconstUV("Net::Inet::IN_CLASSD_NET", IN_CLASSD_NET, file);
	newXSconstUV("Net::Inet::IN_CLASSD_NSHIFT", IN_CLASSD_NSHIFT, file);
	newXSconstUV("Net::Inet::IN_LOOPBACKNET", IN_LOOPBACKNET, file);
#ifdef IPFRAGTTL
	newXSconstUV("Net::Inet::IPFRAGTTL", IPFRAGTTL, file);
#else
	newmissing(missing, "Net::Inet::IPFRAGTTL", file);
#endif
	newXSconstUV("Net::Inet::IPOPT_CIPSO", IPOPT_CIPSO, file);
	newXSconstUV("Net::Inet::IPOPT_CONTROL", IPOPT_CONTROL, file);
	newXSconstUV("Net::Inet::IPOPT_DEBMEAS", IPOPT_DEBMEAS, file);
	newXSconstUV("Net::Inet::IPOPT_EOL", IPOPT_EOL, file);
	newXSconstUV("Net::Inet::IPOPT_LSRR", IPOPT_LSRR, file);
	newXSconstUV("Net::Inet::IPOPT_MINOFF", IPOPT_MINOFF, file);
	newXSconstUV("Net::Inet::IPOPT_NOP", IPOPT_NOP, file);
	newXSconstUV("Net::Inet::IPOPT_OFFSET", IPOPT_OFFSET, file);
	newXSconstUV("Net::Inet::IPOPT_OLEN", IPOPT_OLEN, file);
	newXSconstUV("Net::Inet::IPOPT_OPTVAL", IPOPT_OPTVAL, file);
	newXSconstUV("Net::Inet::IPOPT_RESERVED1", IPOPT_RESERVED1, file);
	newXSconstUV("Net::Inet::IPOPT_RESERVED2", IPOPT_RESERVED2, file);
	newXSconstUV("Net::Inet::IPOPT_RIPSO_AUX", IPOPT_RIPSO_AUX, file);
	newXSconstUV("Net::Inet::IPOPT_RR", IPOPT_RR, file);
	newXSconstUV("Net::Inet::IPOPT_SATID", IPOPT_SATID, file);
	newXSconstUV("Net::Inet::IPOPT_SECURITY", IPOPT_SECURITY, file);
	newXSconstUV("Net::Inet::IPOPT_SECUR_CONFID", IPOPT_SECUR_CONFID, file);
	newXSconstUV("Net::Inet::IPOPT_SECUR_EFTO", IPOPT_SECUR_EFTO, file);
	newXSconstUV("Net::Inet::IPOPT_SECUR_MMMM", IPOPT_SECUR_MMMM, file);
	newXSconstUV("Net::Inet::IPOPT_SECUR_RESTR", IPOPT_SECUR_RESTR, file);
	newXSconstUV("Net::Inet::IPOPT_SECUR_SECRET", IPOPT_SECUR_SECRET, file);
	newXSconstUV("Net::Inet::IPOPT_SECUR_TOPSECRET", IPOPT_SECUR_TOPSECRET, file);
	newXSconstUV("Net::Inet::IPOPT_SECUR_UNCLASS", IPOPT_SECUR_UNCLASS, file);
	newXSconstUV("Net::Inet::IPOPT_SSRR", IPOPT_SSRR, file);
	newXSconstUV("Net::Inet::IPOPT_TS", IPOPT_TS, file);
	newXSconstUV("Net::Inet::IPOPT_TS_PRESPEC", IPOPT_TS_PRESPEC, file);
	newXSconstUV("Net::Inet::IPOPT_TS_TSANDADDR", IPOPT_TS_TSANDADDR, file);
	newXSconstUV("Net::Inet::IPOPT_TS_TSONLY", IPOPT_TS_TSONLY, file);
	newXSconstUV("Net::Inet::IPPORT_RESERVED", IPPORT_RESERVED, file);
#ifdef IPPORT_TIMESERVER
	newXSconstUV("Net::Inet::IPPORT_TIMESERVER", IPPORT_TIMESERVER, file);
#else
	newmissing(missing, "Net::Inet::IPPORT_TIMESERVER", file);
#endif
	newXSconstUV("Net::Inet::IPPORT_USERRESERVED", IPPORT_USERRESERVED, file);
	newXSconstUV("Net::Inet::IPPROTO_EGP", IPPROTO_EGP, file);
	newXSconstUV("Net::Inet::IPPROTO_EON", IPPROTO_EON, file);
	newXSconstUV("Net::Inet::IPPROTO_GGP", IPPROTO_GGP, file);
	newXSconstUV("Net::Inet::IPPROTO_HELLO", IPPROTO_HELLO, file);
	newXSconstUV("Net::Inet::IPPROTO_ICMP", IPPROTO_ICMP, file);
	newXSconstUV("Net::Inet::IPPROTO_IDP", IPPROTO_IDP, file);
	newXSconstUV("Net::Inet::IPPROTO_IGMP", IPPROTO_IGMP, file);
	newXSconstUV("Net::Inet::IPPROTO_IP", IPPROTO_IP, file);
	newXSconstUV("Net::Inet::IPPROTO_IPIP", IPPROTO_IPIP, file);
	newXSconstUV("Net::Inet::IPPROTO_MAX", IPPROTO_MAX, file);
	newXSconstUV("Net::Inet::IPPROTO_PUP", IPPROTO_PUP, file);
	newXSconstUV("Net::Inet::IPPROTO_RAW", IPPROTO_RAW, file);
	newXSconstUV("Net::Inet::IPPROTO_RSVP", IPPROTO_RSVP, file);
	newXSconstUV("Net::Inet::IPPROTO_TCP", IPPROTO_TCP, file);
	newXSconstUV("Net::Inet::IPPROTO_TP", IPPROTO_TP, file);
	newXSconstUV("Net::Inet::IPPROTO_UDP", IPPROTO_UDP, file);
	newXSconstUV("Net::Inet::IPTOS_LOWDELAY", IPTOS_LOWDELAY, file);
	newXSconstUV("Net::Inet::IPTOS_PREC_CRITIC_ECP", IPTOS_PREC_CRITIC_ECP, file);
	newXSconstUV("Net::Inet::IPTOS_PREC_FLASH", IPTOS_PREC_FLASH, file);
	newXSconstUV("Net::Inet::IPTOS_PREC_FLASHOVERRIDE", IPTOS_PREC_FLASHOVERRIDE, file);
	newXSconstUV("Net::Inet::IPTOS_PREC_IMMEDIATE", IPTOS_PREC_IMMEDIATE, file);
	newXSconstUV("Net::Inet::IPTOS_PREC_INTERNETCONTROL", IPTOS_PREC_INTERNETCONTROL, file);
	newXSconstUV("Net::Inet::IPTOS_PREC_NETCONTROL", IPTOS_PREC_NETCONTROL, file);
	newXSconstUV("Net::Inet::IPTOS_PREC_PRIORITY", IPTOS_PREC_PRIORITY, file);
	newXSconstUV("Net::Inet::IPTOS_PREC_ROUTINE", IPTOS_PREC_ROUTINE, file);
	newXSconstUV("Net::Inet::IPTOS_RELIABILITY", IPTOS_RELIABILITY, file);
	newXSconstUV("Net::Inet::IPTOS_THROUGHPUT", IPTOS_THROUGHPUT, file);
	newXSconstUV("Net::Inet::IPTTLDEC", IPTTLDEC, file);
	newXSconstUV("Net::Inet::IPVERSION", IPVERSION, file);
#ifdef IP_ADD_MEMBERSHIP
	newXSconstUV("Net::Inet::IP_ADD_MEMBERSHIP", IP_ADD_MEMBERSHIP, file);
#else
	newmissing(missing, "Net::Inet::IP_ADD_MEMBERSHIP", file);
#endif
#ifdef IP_DEFAULT_MULTICAST_LOOP
	newXSconstUV("Net::Inet::IP_DEFAULT_MULTICAST_LOOP", IP_DEFAULT_MULTICAST_LOOP, file);
#else
	newmissing(missing, "Net::Inet::IP_DEFAULT_MULTICAST_LOOP", file);
#endif
#ifdef IP_DEFAULT_MULTICAST_TTL
	newXSconstUV("Net::Inet::IP_DEFAULT_MULTICAST_TTL", IP_DEFAULT_MULTICAST_TTL, file);
#else
	newmissing(missing, "Net::Inet::IP_DEFAULT_MULTICAST_TTL", file);
#endif
	newXSconstUV("Net::Inet::IP_DF", IP_DF, file);
#ifdef IP_DROP_MEMBERSHIP
	newXSconstUV("Net::Inet::IP_DROP_MEMBERSHIP", IP_DROP_MEMBERSHIP, file);
#else
	newmissing(missing, "Net::Inet::IP_DROP_MEMBERSHIP", file);
#endif
#ifdef IP_HDRINCL
	newXSconstUV("Net::Inet::IP_HDRINCL", IP_HDRINCL, file);
#else
	newmissing(missing, "Net::Inet::IP_HDRINCL", file);
#endif
	newXSconstUV("Net::Inet::IP_MAXPACKET", IP_MAXPACKET, file);
#ifdef IP_MAX_MEMBERSHIPS
	newXSconstUV("Net::Inet::IP_MAX_MEMBERSHIPS", IP_MAX_MEMBERSHIPS, file);
#else
	newmissing(missing, "Net::Inet::IP_MAX_MEMBERSHIPS", file);
#endif
	newXSconstUV("Net::Inet::IP_MF", IP_MF, file);
	newXSconstUV("Net::Inet::IP_MSS", IP_MSS, file);
#ifdef IP_MULTICAST_IF
	newXSconstUV("Net::Inet::IP_MULTICAST_IF", IP_MULTICAST_IF, file);
#else
	newmissing(missing, "Net::Inet::IP_MULTICAST_IF", file);
#endif
#ifdef IP_MULTICAST_LOOP
	newXSconstUV("Net::Inet::IP_MULTICAST_LOOP", IP_MULTICAST_LOOP, file);
#else
	newmissing(missing, "Net::Inet::IP_MULTICAST_LOOP", file);
#endif
#ifdef IP_MULTICAST_TTL
	newXSconstUV("Net::Inet::IP_MULTICAST_TTL", IP_MULTICAST_TTL, file);
#else
	newmissing(missing, "Net::Inet::IP_MULTICAST_TTL", file);
#endif
#ifdef IP_OPTIONS
	newXSconstUV("Net::Inet::IP_OPTIONS", IP_OPTIONS, file);
#else
	newmissing(missing, "Net::Inet::IP_OPTIONS", file);
#endif
#ifdef IP_RECVDSTADDR
	newXSconstUV("Net::Inet::IP_RECVDSTADDR", IP_RECVDSTADDR, file);
#else
	newmissing(missing, "Net::Inet::IP_RECVDSTADDR", file);
#endif
#ifdef IP_RECVOPTS
	newXSconstUV("Net::Inet::IP_RECVOPTS", IP_RECVOPTS, file);
#else
	newmissing(missing, "Net::Inet::IP_RECVOPTS", file);
#endif
#ifdef IP_RECVRETOPTS
	newXSconstUV("Net::Inet::IP_RECVRETOPTS", IP_RECVRETOPTS, file);
#else
	newmissing(missing, "Net::Inet::IP_RECVRETOPTS", file);
#endif
#ifdef IP_RETOPTS
	newXSconstUV("Net::Inet::IP_RETOPTS", IP_RETOPTS, file);
#else
	newmissing(missing, "Net::Inet::IP_RETOPTS", file);
#endif
#ifdef IP_TOS
	newXSconstUV("Net::Inet::IP_TOS", IP_TOS, file);
#else
	newmissing(missing, "Net::Inet::IP_TOS", file);
#endif
#ifdef IP_TTL
	newXSconstUV("Net::Inet::IP_TTL", IP_TTL, file);
#else
	newmissing(missing, "Net::Inet::IP_TTL", file);
#endif
	newXSconstUV("Net::Inet::MAXTTL", MAXTTL, file);
	newXSconstUV("Net::Inet::MAX_IPOPTLEN", MAX_IPOPTLEN, file);
	newXSconstUV("Net::Inet::MINTTL", MINTTL, file);
#ifdef SUBNETSHIFT
	newXSconstUV("Net::Inet::SUBNETSHIFT", SUBNETSHIFT, file);
#else
	newmissing(missing, "Net::Inet::SUBNETSHIFT", file);
#endif
    {
	struct in_addr ina;
	ina.s_addr = htonl(INADDR_ALLHOSTS_GROUP);
	newXSconstPVN("Net::Inet::INADDR_ALLHOSTS_GROUP",
		      (char*)&ina, sizeof ina, file);
	ina.s_addr = htonl(INADDR_ALLRTRS_GROUP);
	newXSconstPVN("Net::Inet::INADDR_ALLRTRS_GROUP",
		      (char*)&ina, sizeof ina, file);
	ina.s_addr = htonl(INADDR_MAX_LOCAL_GROUP);
	newXSconstPVN("Net::Inet::INADDR_MAX_LOCAL_GROUP",
		      (char*)&ina, sizeof ina, file);
	ina.s_addr = htonl(INADDR_UNSPEC_GROUP);
	newXSconstPVN("Net::Inet::INADDR_UNSPEC_GROUP",
		      (char*)&ina, sizeof ina, file);
    }


MODULE = Net::Gen		PACKAGE = Net::Inet

bool
IN_CLASSA(hostaddr)
	sv_inaddr_t	hostaddr

bool
IN_CLASSB(hostaddr)
	sv_inaddr_t	hostaddr

bool
IN_CLASSC(hostaddr)
	sv_inaddr_t	hostaddr

bool
IN_CLASSD(hostaddr)
	sv_inaddr_t	hostaddr

bool
IN_MULTICAST(hostaddr)
	sv_inaddr_t	hostaddr

bool
IN_EXPERIMENTAL(hostaddr)
	sv_inaddr_t	hostaddr

bool
IN_BADCLASS(hostaddr)
	sv_inaddr_t	hostaddr

bool
IPOPT_COPIED(ipopt)
	U8	ipopt

U8
IPOPT_CLASS(ipopt)
	U8	ipopt

U8
IPOPT_NUMBER(ipopt)
	U8	ipopt

bool
ICMP_INFOTYPE(icmp_code)
	U8	icmp_code

void
_pack_sockaddr_in(family,port,address)
	U8	family
	U16	port
	SV *	address
    PREINIT:
	struct sockaddr_in sin;
	char * adata;
	STRLEN adlen;
    PPCODE:
	Zero(&sin, sizeof sin, char);
	sin.sin_family = family;
	adata = SvPV(address, adlen);
	sin.sin_port = htons(port);
	if (adlen == sizeof sin.sin_addr) {
	    Copy(adata, &sin.sin_addr, sizeof sin.sin_addr, char);
	    ST(0) = sv_2mortal(newSVpv((char*)&sin, sizeof sin));
	}
	else {
	    SV *adsv = sv_2mortal(newSVpv((char*)&sin,
					  STRUCT_OFFSET(struct sockaddr_in,
							sin_addr)));
	    sv_catpvn(adsv, adata, adlen);
	    ST(0) = adsv;
	}
	XSRETURN(1);

void
unpack_sockaddr_in(sad)
	SV *	sad
    PREINIT:
	char *	cp;
	struct sockaddr_in sin;
	STRLEN	len;
    PPCODE:
	if ((cp = SvPV(sad, len)) != (char*)0 && len >= sizeof sin) {
	    U16  family;
	    U16  port;
	    char * adata;
	    STRLEN addrlen;

	    Copy(cp, &sin, sizeof sin, char);
	    family = sin.sin_family;
	    if (family > 255) {	/* 4.4BSD anyone? */
		U8 famlen1, famlen2;
		famlen1 = family & 255;
		famlen2 = (family >> 8) & 255;
		if (famlen1 == famlen2) {
		    family = famlen1;
		}
		else if (famlen1 == len) {
		    family = famlen2;
		}
		else if (famlen2 == len) {
		    family = famlen1;
		}
		else if (famlen1 == AF_INET || famlen2 == AF_INET) {
		    family = AF_INET;
		}
		else if (famlen1 < famlen2) {
		    family = famlen1;
		}
		else {
		    family = famlen2;
		}
	    }
	    port = ntohs(sin.sin_port);
	    /* now work on the address */
	    cp += STRUCT_OFFSET(struct sockaddr_in, sin_addr);
	    addrlen = len - STRUCT_OFFSET(struct sockaddr_in, sin_addr);
	    if (family == AF_INET && len == sizeof sin)
		addrlen = sizeof sin.sin_addr;

	    EXTEND(sp,3);
	    PUSHs(sv_2mortal(newSViv((IV)family)));
	    PUSHs(sv_2mortal(newSViv((IV)port)));
	    PUSHs(sv_2mortal(newSVpv(cp, addrlen)));
	}


MODULE = Net::Gen		PACKAGE = Net::Gen	PREFIX = f_ic_

BOOT:
#ifdef	EOF_NONBLOCK
#define	f_ic_EOF_NONBLOCK	1
#else
#define	f_ic_EOF_NONBLOCK	0
#endif
	newXSconstIV("Net::Gen::EOF_NONBLOCK", f_ic_EOF_NONBLOCK, file);
#ifdef	RD_NODATA
	newXSconstIV("Net::Gen::RD_NODATA", RD_NODATA, file);
#else
	newmissing(missing, "Net::Gen::RD_NODATA", file);
#endif
	newXSconstIV("Net::Gen::SHUT_RD", SHUT_RD, file);
	newXSconstIV("Net::Gen::SHUT_WR", SHUT_WR, file);
	newXSconstIV("Net::Gen::SHUT_RDWR", SHUT_RDWR, file);


MODULE = Net::Gen		PACKAGE = Net::Gen	PREFIX = f_uc_

BOOT:
#ifdef	VAL_O_NONBLOCK
	newXSconstUV("Net::Gen::VAL_O_NONBLOCK", VAL_O_NONBLOCK, file);
#else
	newmissing(missing, "Net::Gen::VAL_O_NONBLOCK", file);
#endif
#ifdef	VAL_EAGAIN
	newXSconstUV("Net::Gen::VAL_EAGAIN", VAL_EAGAIN, file);
#else
	newmissing(missing, "Net::Gen::VAL_EAGAIN", file);
#endif
	newXSconstUV("Net::Gen::MSG_OOB", MSG_OOB, file);
#ifdef	SO_ACCEPTCONN
	newXSconstUV("Net::Gen::SO_ACCEPTCONN", SO_ACCEPTCONN, file);
#else
	newmissing(missing, "Net::Gen::SO_ACCEPTCONN", file);
#endif
#ifdef	SO_BROADCAST
	newXSconstUV("Net::Gen::SO_BROADCAST", SO_BROADCAST, file);
#else
	newmissing(missing, "Net::Gen::SO_BROADCAST", file);
#endif
#ifdef	SO_DEBUG
	newXSconstUV("Net::Gen::SO_DEBUG", SO_DEBUG, file);
#else
	newmissing(missing, "Net::Gen::SO_DEBUG", file);
#endif
#ifdef	SO_DONTROUTE
	newXSconstUV("Net::Gen::SO_DONTROUTE", SO_DONTROUTE, file);
#else
	newmissing(missing, "Net::Gen::SO_DONTROUTE", file);
#endif
#ifdef	SO_ERROR
	newXSconstUV("Net::Gen::SO_ERROR", SO_ERROR, file);
#else
	newmissing(missing, "Net::Gen::SO_ERROR", file);
#endif
#ifdef	SO_EXPANDED_RIGHTS
	newXSconstUV("Net::Gen::SO_EXPANDED_RIGHTS", SO_EXPANDED_RIGHTS, file);
#else
	newmissing(missing, "Net::Gen::SO_EXPANDED_RIGHTS", file);
#endif
#ifdef	SO_KEEPALIVE
	newXSconstUV("Net::Gen::SO_KEEPALIVE", SO_KEEPALIVE, file);
#else
	newmissing(missing, "Net::Gen::SO_KEEPALIVE", file);
#endif
#ifdef	SO_OOBINLINE
	newXSconstUV("Net::Gen::SO_OOBINLINE", SO_OOBINLINE, file);
#else
	newmissing(missing, "Net::Gen::SO_OOBINLINE", file);
#endif
#ifdef	SO_PAIRABLE
	newXSconstUV("Net::Gen::SO_PAIRABLE", SO_PAIRABLE, file);
#else
	newmissing(missing, "Net::Gen::SO_PAIRABLE", file);
#endif
#ifdef	SO_REUSEADDR
	newXSconstUV("Net::Gen::SO_REUSEADDR", SO_REUSEADDR, file);
#else
	newmissing(missing, "Net::Gen::SO_REUSEADDR", file);
#endif
#ifdef	SO_REUSEPORT
	newXSconstUV("Net::Gen::SO_REUSEPORT", SO_REUSEPORT, file);
#else
	newmissing(missing, "Net::Gen::SO_REUSEPORT", file);
#endif
#ifdef	SO_USELOOPBACK
	newXSconstUV("Net::Gen::SO_USELOOPBACK", SO_USELOOPBACK, file);
#else
	newmissing(missing, "Net::Gen::SO_USELOOPBACK", file);
#endif
#ifdef	SO_XSE
	newXSconstUV("Net::Gen::SO_XSE", SO_XSE, file);
#else
	newmissing(missing, "Net::Gen::SO_XSE", file);
#endif
#ifdef	SO_RCVBUF
	newXSconstUV("Net::Gen::SO_RCVBUF", SO_RCVBUF, file);
#else
	newmissing(missing, "Net::Gen::SO_RCVBUF", file);
#endif
#ifdef	SO_SNDBUF
	newXSconstUV("Net::Gen::SO_SNDBUF", SO_SNDBUF, file);
#else
	newmissing(missing, "Net::Gen::SO_SNDBUF", file);
#endif
#ifdef	SO_RCVTIMEO
	newXSconstUV("Net::Gen::SO_RCVTIMEO", SO_RCVTIMEO, file);
#else
	newmissing(missing, "Net::Gen::SO_RCVTIMEO", file);
#endif
#ifdef	SO_SNDTIMEO
	newXSconstUV("Net::Gen::SO_SNDTIMEO", SO_SNDTIMEO, file);
#else
	newmissing(missing, "Net::Gen::SO_SNDTIMEO", file);
#endif
#ifdef	SO_RCVLOWAT
	newXSconstUV("Net::Gen::SO_RCVLOWAT", SO_RCVLOWAT, file);
#else
	newmissing(missing, "Net::Gen::SO_RCVLOWAT", file);
#endif
#ifdef	SO_SNDLOWAT
	newXSconstUV("Net::Gen::SO_SNDLOWAT", SO_SNDLOWAT, file);
#else
	newmissing(missing, "Net::Gen::SO_SNDLOWAT", file);
#endif
#ifdef	SO_TYPE
	newXSconstUV("Net::Gen::SO_TYPE", SO_TYPE, file);
#else
	newmissing(missing, "Net::Gen::SO_TYPE", file);
#endif
#ifdef	SO_STATE
	newXSconstUV("Net::Gen::SO_STATE", SO_STATE, file);
#else
	newmissing(missing, "Net::Gen::SO_STATE", file);
#endif
#ifdef	SO_FAMILY
	newXSconstUV("Net::Gen::SO_FAMILY", SO_FAMILY, file);
#else
	newmissing(missing, "Net::Gen::SO_FAMILY", file);
#endif
#ifdef	SO_LINGER
	newXSconstUV("Net::Gen::SO_LINGER", SO_LINGER, file);
#else
	newmissing(missing, "Net::Gen::SO_LINGER", file);
#endif
#ifdef	SOL_SOCKET
	newXSconstUV("Net::Gen::SOL_SOCKET", SOL_SOCKET, file);
#else
	newmissing(missing, "Net::Gen::SOL_SOCKET", file);
#endif
#ifdef	SOCK_STREAM
	newXSconstUV("Net::Gen::SOCK_STREAM", SOCK_STREAM, file);
#else
	newmissing(missing, "Net::Gen::SOCK_STREAM", file);
#endif
#ifdef	SOCK_DGRAM
	newXSconstUV("Net::Gen::SOCK_DGRAM", SOCK_DGRAM, file);
#else
	newmissing(missing, "Net::Gen::SOCK_DGRAM", file);
#endif
#ifdef	SOCK_RAW
	newXSconstUV("Net::Gen::SOCK_RAW", SOCK_RAW, file);
#else
	newmissing(missing, "Net::Gen::SOCK_RAW", file);
#endif
#ifdef	SOCK_RDM
	newXSconstUV("Net::Gen::SOCK_RDM", SOCK_RDM, file);
#else
	newmissing(missing, "Net::Gen::SOCK_RDM", file);
#endif
#ifdef	SOCK_SEQPACKET
	newXSconstUV("Net::Gen::SOCK_SEQPACKET", SOCK_SEQPACKET, file);
#else
	newmissing(missing, "Net::Gen::SOCK_SEQPACKET", file);
#endif
#ifndef	AF_UNSPEC
#define	AF_UNSPEC	0
#endif
	newXSconstUV("Net::Gen::AF_UNSPEC", AF_UNSPEC, file);
#ifndef	PF_UNSPEC
#define	PF_UNSPEC	0
#endif
	newXSconstUV("Net::Gen::PF_UNSPEC", PF_UNSPEC, file);
#ifdef	AF_INET
	newXSconstUV("Net::Gen::AF_INET", AF_INET, file);
#else
	newmissing(missing, "Net::Gen::AF_INET", file);
#endif
#ifdef	PF_INET
	newXSconstUV("Net::Gen::PF_INET", PF_INET, file);
#else
	newmissing(missing, "Net::Gen::PF_INET", file);
#endif
#ifndef	AF_UNIX
#ifdef	AF_LOCAL
#define	AF_UNIX	AF_LOCAL
#endif
#endif
#ifndef	PF_UNIX
#ifdef	PF_LOCAL
#define	PF_UNIX	PF_LOCAL
#endif
#endif
#ifndef	AF_LOCAL
#ifdef	AF_UNIX
#define	AF_LOCAL	AF_UNIX
#endif
#endif
#ifndef	PF_LOCAL
#ifdef	PF_UNIX
#define	PF_LOCAL	PF_UNIX
#endif
#endif
#ifdef	AF_UNIX
	newXSconstUV("Net::Gen::AF_UNIX", AF_UNIX, file);
#else
	newmissing(missing, "Net::Gen::AF_UNIX", file);
#endif
#ifdef	PF_UNIX
	newXSconstUV("Net::Gen::PF_UNIX", PF_UNIX, file);
#else
	newmissing(missing, "Net::Gen::PF_UNIX", file);
#endif
#ifdef	AF_LOCAL
	newXSconstUV("Net::Gen::AF_LOCAL", AF_LOCAL, file);
#else
	newmissing(missing, "Net::Gen::AF_LOCAL", file);
#endif
#ifdef	PF_LOCAL
	newXSconstUV("Net::Gen::PF_LOCAL", PF_LOCAL, file);
#else
	newmissing(missing, "Net::Gen::PF_LOCAL", file);
#endif
#ifdef	AF_IMPLINK
	newXSconstUV("Net::Gen::AF_IMPLINK", AF_IMPLINK, file);
#else
	newmissing(missing, "Net::Gen::AF_IMPLINK", file);
#endif
#ifdef	PF_IMPLINK
	newXSconstUV("Net::Gen::PF_IMPLINK", PF_IMPLINK, file);
#else
	newmissing(missing, "Net::Gen::PF_IMPLINK", file);
#endif
#ifdef	AF_PUP
	newXSconstUV("Net::Gen::AF_PUP", AF_PUP, file);
#else
	newmissing(missing, "Net::Gen::AF_PUP", file);
#endif
#ifdef	PF_PUP
	newXSconstUV("Net::Gen::PF_PUP", PF_PUP, file);
#else
	newmissing(missing, "Net::Gen::PF_PUP", file);
#endif
#ifdef	AF_CHAOS
	newXSconstUV("Net::Gen::AF_CHAOS", AF_CHAOS, file);
#else
	newmissing(missing, "Net::Gen::AF_CHAOS", file);
#endif
#ifdef	PF_CHAOS
	newXSconstUV("Net::Gen::PF_CHAOS", PF_CHAOS, file);
#else
	newmissing(missing, "Net::Gen::PF_CHAOS", file);
#endif
#ifdef	AF_NS
	newXSconstUV("Net::Gen::AF_NS", AF_NS, file);
#else
	newmissing(missing, "Net::Gen::AF_NS", file);
#endif
#ifdef	PF_NS
	newXSconstUV("Net::Gen::PF_NS", PF_NS, file);
#else
	newmissing(missing, "Net::Gen::PF_NS", file);
#endif
#ifdef	AF_ISO
	newXSconstUV("Net::Gen::AF_ISO", AF_ISO, file);
#else
	newmissing(missing, "Net::Gen::AF_ISO", file);
#endif
#ifdef	PF_ISO
	newXSconstUV("Net::Gen::PF_ISO", PF_ISO, file);
#else
	newmissing(missing, "Net::Gen::PF_ISO", file);
#endif
#ifdef	AF_OSI
	newXSconstUV("Net::Gen::AF_OSI", AF_OSI, file);
#else
	newmissing(missing, "Net::Gen::AF_OSI", file);
#endif
#ifdef	PF_OSI
	newXSconstUV("Net::Gen::PF_OSI", PF_OSI, file);
#else
	newmissing(missing, "Net::Gen::PF_OSI", file);
#endif
#ifdef	AF_ECMA
	newXSconstUV("Net::Gen::AF_ECMA", AF_ECMA, file);
#else
	newmissing(missing, "Net::Gen::AF_ECMA", file);
#endif
#ifdef	PF_ECMA
	newXSconstUV("Net::Gen::PF_ECMA", PF_ECMA, file);
#else
	newmissing(missing, "Net::Gen::PF_ECMA", file);
#endif
#ifdef	AF_DATAKIT
	newXSconstUV("Net::Gen::AF_DATAKIT", AF_DATAKIT, file);
#else
	newmissing(missing, "Net::Gen::AF_DATAKIT", file);
#endif
#ifdef	PF_DATAKIT
	newXSconstUV("Net::Gen::PF_DATAKIT", PF_DATAKIT, file);
#else
	newmissing(missing, "Net::Gen::PF_DATAKIT", file);
#endif
#ifdef	AF_CCITT
	newXSconstUV("Net::Gen::AF_CCITT", AF_CCITT, file);
#else
	newmissing(missing, "Net::Gen::AF_CCITT", file);
#endif
#ifdef	PF_CCITT
	newXSconstUV("Net::Gen::PF_CCITT", PF_CCITT, file);
#else
	newmissing(missing, "Net::Gen::PF_CCITT", file);
#endif
#ifdef	AF_SNA
	newXSconstUV("Net::Gen::AF_SNA", AF_SNA, file);
#else
	newmissing(missing, "Net::Gen::AF_SNA", file);
#endif
#ifdef	PF_SNA
	newXSconstUV("Net::Gen::PF_SNA", PF_SNA, file);
#else
	newmissing(missing, "Net::Gen::PF_SNA", file);
#endif
#ifdef	AF_DECnet
	newXSconstUV("Net::Gen::AF_DECnet", AF_DECnet, file);
#else
	newmissing(missing, "Net::Gen::AF_DECnet", file);
#endif
#ifdef	PF_DECnet
	newXSconstUV("Net::Gen::PF_DECnet", PF_DECnet, file);
#else
	newmissing(missing, "Net::Gen::PF_DECnet", file);
#endif
#ifdef	AF_DLI
	newXSconstUV("Net::Gen::AF_DLI", AF_DLI, file);
#else
	newmissing(missing, "Net::Gen::AF_DLI", file);
#endif
#ifdef	PF_DLI
	newXSconstUV("Net::Gen::PF_DLI", PF_DLI, file);
#else
	newmissing(missing, "Net::Gen::PF_DLI", file);
#endif
#ifdef	AF_LAT
	newXSconstUV("Net::Gen::AF_LAT", AF_LAT, file);
#else
	newmissing(missing, "Net::Gen::AF_LAT", file);
#endif
#ifdef	PF_LAT
	newXSconstUV("Net::Gen::PF_LAT", PF_LAT, file);
#else
	newmissing(missing, "Net::Gen::PF_LAT", file);
#endif
#ifdef	AF_HYLINK
	newXSconstUV("Net::Gen::AF_HYLINK", AF_HYLINK, file);
#else
	newmissing(missing, "Net::Gen::AF_HYLINK", file);
#endif
#ifdef	PF_HYLINK
	newXSconstUV("Net::Gen::PF_HYLINK", PF_HYLINK, file);
#else
	newmissing(missing, "Net::Gen::PF_HYLINK", file);
#endif
#ifdef	AF_APPLETALK
	newXSconstUV("Net::Gen::AF_APPLETALK", AF_APPLETALK, file);
#else
	newmissing(missing, "Net::Gen::AF_APPLETALK", file);
#endif
#ifdef	PF_APPLETALK
	newXSconstUV("Net::Gen::PF_APPLETALK", PF_APPLETALK, file);
#else
	newmissing(missing, "Net::Gen::PF_APPLETALK", file);
#endif
#ifdef	AF_ROUTE
	newXSconstUV("Net::Gen::AF_ROUTE", AF_ROUTE, file);
#else
	newmissing(missing, "Net::Gen::AF_ROUTE", file);
#endif
#ifdef	PF_ROUTE
	newXSconstUV("Net::Gen::PF_ROUTE", PF_ROUTE, file);
#else
	newmissing(missing, "Net::Gen::PF_ROUTE", file);
#endif
#ifdef	AF_LINK
	newXSconstUV("Net::Gen::AF_LINK", AF_LINK, file);
#else
	newmissing(missing, "Net::Gen::AF_LINK", file);
#endif
#ifdef	PF_LINK
	newXSconstUV("Net::Gen::PF_LINK", PF_LINK, file);
#else
	newmissing(missing, "Net::Gen::PF_LINK", file);
#endif
#ifdef	AF_NETMAN
	newXSconstUV("Net::Gen::AF_NETMAN", AF_NETMAN, file);
#else
	newmissing(missing, "Net::Gen::AF_NETMAN", file);
#endif
#ifdef	PF_NETMAN
	newXSconstUV("Net::Gen::PF_NETMAN", PF_NETMAN, file);
#else
	newmissing(missing, "Net::Gen::PF_NETMAN", file);
#endif
#ifdef	AF_X25
	newXSconstUV("Net::Gen::AF_X25", AF_X25, file);
#else
	newmissing(missing, "Net::Gen::AF_X25", file);
#endif
#ifdef	PF_X25
	newXSconstUV("Net::Gen::PF_X25", PF_X25, file);
#else
	newmissing(missing, "Net::Gen::PF_X25", file);
#endif
#ifdef	AF_CTF
	newXSconstUV("Net::Gen::AF_CTF", AF_CTF, file);
#else
	newmissing(missing, "Net::Gen::AF_CTF", file);
#endif
#ifdef	PF_CTF
	newXSconstUV("Net::Gen::PF_CTF", PF_CTF, file);
#else
	newmissing(missing, "Net::Gen::PF_CTF", file);
#endif
#ifdef	AF_WAN
	newXSconstUV("Net::Gen::AF_WAN", AF_WAN, file);
#else
	newmissing(missing, "Net::Gen::AF_WAN", file);
#endif
#ifdef	PF_WAN
	newXSconstUV("Net::Gen::PF_WAN", PF_WAN, file);
#else
	newmissing(missing, "Net::Gen::PF_WAN", file);
#endif
#ifdef	AF_USER
	newXSconstUV("Net::Gen::AF_USER", AF_USER, file);
#else
	newmissing(missing, "Net::Gen::AF_USER", file);
#endif
#ifdef	PF_USER
	newXSconstUV("Net::Gen::PF_USER", PF_USER, file);
#else
	newmissing(missing, "Net::Gen::PF_USER", file);
#endif
#ifdef	AF_LAST
	newXSconstUV("Net::Gen::AF_LAST", AF_LAST, file);
#else
	newmissing(missing, "Net::Gen::AF_LAST", file);
#endif
#ifdef	PF_LAST
	newXSconstUV("Net::Gen::PF_LAST", PF_LAST, file);
#else
	newmissing(missing, "Net::Gen::PF_LAST", file);
#endif
	newXSconstUV("Net::Gen::ENOENT", ENOENT, file);
	newXSconstUV("Net::Gen::EINVAL", EINVAL, file);
	newXSconstUV("Net::Gen::EBADF", EBADF, file);
	newXSconstUV("Net::Gen::EAGAIN", EAGAIN, file);
	newXSconstUV("Net::Gen::EWOULDBLOCK", EWOULDBLOCK, file);
	newXSconstUV("Net::Gen::EINPROGRESS", EINPROGRESS, file);
	newXSconstUV("Net::Gen::EALREADY", EALREADY, file);
	newXSconstUV("Net::Gen::ENOTSOCK", ENOTSOCK, file);
	newXSconstUV("Net::Gen::EDESTADDRREQ", EDESTADDRREQ, file);
	newXSconstUV("Net::Gen::EMSGSIZE", EMSGSIZE, file);
	newXSconstUV("Net::Gen::EPROTOTYPE", EPROTOTYPE, file);
	newXSconstUV("Net::Gen::ENOPROTOOPT", ENOPROTOOPT, file);
	newXSconstUV("Net::Gen::EPROTONOSUPPORT", EPROTONOSUPPORT, file);
	newXSconstUV("Net::Gen::ESOCKTNOSUPPORT", ESOCKTNOSUPPORT, file);
	newXSconstUV("Net::Gen::EOPNOTSUPP", EOPNOTSUPP, file);
	newXSconstUV("Net::Gen::EPFNOSUPPORT", EPFNOSUPPORT, file);
	newXSconstUV("Net::Gen::EAFNOSUPPORT", EAFNOSUPPORT, file);
	newXSconstUV("Net::Gen::EADDRINUSE", EADDRINUSE, file);
	newXSconstUV("Net::Gen::EADDRNOTAVAIL", EADDRNOTAVAIL, file);
	newXSconstUV("Net::Gen::ENETDOWN", ENETDOWN, file);
	newXSconstUV("Net::Gen::ENETUNREACH", ENETUNREACH, file);
	newXSconstUV("Net::Gen::ENETRESET", ENETRESET, file);
	newXSconstUV("Net::Gen::ECONNABORTED", ECONNABORTED, file);
	newXSconstUV("Net::Gen::ECONNRESET", ECONNRESET, file);
	newXSconstUV("Net::Gen::ENOBUFS", ENOBUFS, file);
	newXSconstUV("Net::Gen::EISCONN", EISCONN, file);
	newXSconstUV("Net::Gen::ENOTCONN", ENOTCONN, file);
	newXSconstUV("Net::Gen::ESHUTDOWN", ESHUTDOWN, file);
	newXSconstUV("Net::Gen::ETOOMANYREFS", ETOOMANYREFS, file);
	newXSconstUV("Net::Gen::ETIMEDOUT", ETIMEDOUT, file);
	newXSconstUV("Net::Gen::ECONNREFUSED", ECONNREFUSED, file);
	newXSconstUV("Net::Gen::EHOSTDOWN", EHOSTDOWN, file);
	newXSconstUV("Net::Gen::EHOSTUNREACH", EHOSTUNREACH, file);
	newXSconstUV("Net::Gen::ENOSR", ENOSR, file);
	newXSconstUV("Net::Gen::ETIME", ETIME, file);
	newXSconstUV("Net::Gen::EBADMSG", EBADMSG, file);
	newXSconstUV("Net::Gen::EPROTO", EPROTO, file);
	newXSconstUV("Net::Gen::ENODATA", ENODATA, file);
	newXSconstUV("Net::Gen::ENOSTR", ENOSTR, file);
	newXSconstUV("Net::Gen::SOMAXCONN", SOMAXCONN, file);


MODULE = Net::Gen		PACKAGE = Net::Gen

BOOT:
    }

void
pack_sockaddr(family,address)
	U8	family
	SV *	address
    PREINIT:
	struct sockaddr sad;
	char * adata;
	STRLEN adlen;
    PPCODE:
	Zero(&sad, sizeof sad, char);
	sad.sa_family = family;
	adata = SvPV(address, adlen);
	if (adlen > sizeof(sad.sa_data)) {
	    SV * rval = sv_newmortal();
	    sv_setpvn(rval, (char*)&sad, sizeof sad - sizeof sad.sa_data);
	    sv_catpvn(rval, adata, adlen);
	    ST(0) = rval;
	}
	else {
	    Copy(adata, &sad.sa_data, adlen, char);
	    ST(0) = sv_2mortal(newSVpv((char*)&sad, sizeof sad));
	}
	XSRETURN(1);

void
unpack_sockaddr(sad)
	SV *	sad
    PREINIT:
	char * cp;
	STRLEN len;
    PPCODE:
	if ((cp = SvPV(sad, len)) != (char*)0) {
	    struct sockaddr sa;
	    U16  family;
	    SV * famsv;
	    SV * datsv;

	    if (len < sizeof sa - sizeof sa.sa_data)
		Zero(&sa, sizeof sa - sizeof sa.sa_data, char);
	    Copy(cp, &sa, len < sizeof sa ? len : sizeof sa, char);
	    family = sa.sa_family;
	    if (family > 255) {		/* 4.4bsd anyone? */
		U8 famlen1, famlen2;
		famlen1 = family & 255;
		famlen2 = family >> 8;
		if (famlen1 == famlen2)
		    family = famlen1;
		else if (famlen1 == len)
		    family = famlen2;
		else if (famlen2 == len)
		    family = famlen1;
	    }
	    famsv = sv_2mortal(newSViv(family));
	    if (len >= sizeof sa - sizeof sa.sa_data) {
		len -= sizeof sa - sizeof sa.sa_data;
		datsv = sv_2mortal(newSVpv(cp + (sizeof sa - sizeof sa.sa_data),
					   len));
	    }
	    else {
		datsv = sv_mortalcopy(&PL_sv_undef);
	    }
	    EXTEND(sp, 2);
	    PUSHs(famsv);
	    PUSHs(datsv);
	}

