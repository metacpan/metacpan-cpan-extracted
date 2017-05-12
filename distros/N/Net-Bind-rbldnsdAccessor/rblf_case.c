/*

 rblf_case.c version 1.00

 Copyright 2006, Michael Robinton, michael@bizsystems.com
   
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include "rblf_base.h"
#include "rblf_name.h"

/*
RFC 3597            Handling of Unknown DNS RR Types      September 2003

   This requirement was stated in [RFC1123] without defining the
   term "well-known"; it is hereby specified that only the RR types
   defined in [RFC1035] are to be considered "well-known".

  A               1 a host address

  NS              2 an authoritative name server

  MD              3 a mail destination (Obsolete - use MX)

  MF              4 a mail forwarder (Obsolete - use MX)

  CNAME           5 the canonical name for an alias

  SOA             6 marks the start of a zone of authority

  MB              7 a mailbox domain name (EXPERIMENTAL)

  MG              8 a mail group member (EXPERIMENTAL)

  MR              9 a mail rename domain name (EXPERIMENTAL)

  NULL            10 a null RR (EXPERIMENTAL)

  WKS             11 a well known service description

  PTR             12 a domain name pointer

  HINFO           13 host information

  MINFO           14 mailbox or mail list information

  MX              15 mail exchange

  TXT             16 text strings

  should decompress

  RP              17
  AFSDB           18
  RT              21
  SIG             24
  PX              26
  NXT             30
  SRV             33
  NAPTR           35

RFC 3597            Handling of Unknown DNS RR Types      September 2003

   The specifications of a few existing RR types have explicitly allowed
   compression contrary to this specification: [RFC2163] specified that
   compression applies to the PX RR, and [RFC2535] allowed compression
   in SIG RRs and NXT RRs records.  Since this specification disallows
   compression in these cases, it is an update to [RFC2163] (section 4)
   and [RFC2535] (sections 4.1.7 and 5.2).

   Receiving servers MUST decompress domain names in RRs of well-known
   type, and SHOULD also decompress RRs of type RP, AFSDB, RT, SIG, PX,
   NXT, NAPTR, and SRV (although the current specification of the SRV RR
   in [RFC2782] prohibits compression, [RFC2052] mandated it, and some
   servers following that earlier specification are still in use).

   The RDATA section of an RR of unknown type is represented as a
   sequence of white space separated words as follows:

      The special token \# (a backslash immediately followed by a hash
      sign), which identifies the RDATA as having the generic encoding
      defined herein rather than a traditional type-specific encoding.

      An unsigned decimal integer specifying the RDATA length in octets.

      Zero or more words of hexadecimal data encoding the actual RDATA
      field, each containing an even number of hexadecimal digits.

   If the RDATA is of zero length, the text representation contains only
   the \# token and the single zero representing the length.

	i.e.	example.com	IN	TYPE1	\# 4 0A000001
		example.com	IN	A	10.0.0.1
 */

/*	safe memory copy
 *	returns -1 on failure, returns the number of bytes copied
 */
 
int
rblf_safemcpy(unsigned char * dst, unsigned char * src, size_t size, unsigned char * dstlim)
{
  if (dstlim - dst <  size)
    return (-1);
    
  memcpy(dst,src,size);
  return (size);
}

/*	null terminated strncpy replacement	
 *	returns the number of bytes transferred
 */
int
rblf_strncpy(char * dst, char * src, size_t max)
{
  int start = max;
  while (max > 0) {
    if (*src == 0)
      break;
    *dst++ = *src++;
    max--;
  }
  *dst = 0;
  return (start - max);
}




/********************************************************
*********************************************************
	There are only 6 basic record TYPE's to 
	deal with, they are as follows:
	
  1) RDATA is NOT compressed. 
	A,TXT,NULL,WKS,HINFO,X25,ISDN,NSAP,NSAP_PTR,
	KEY,GPOS,AAAA,LOC,EID,NIMLOC,ATMA,KX,CERT,
	A6,DNAME,SINK,OPT,DS  ...and default:

  2) RDATA has exactly ONE (1) compressed name
	NS,MD,MF,CNAME,MB,MG,MR,PTR

  3) RDATA with a SHORT (16 bits) and ONE (1) 
     compressed name
	MX,AFSDB,RT

  4) types that should not be in a UDP response for
     which our return value is (-1) server fail.
	TKEY,TSIG,IXFR,AXFR,MAILA,MAILB,ANY

  5) RDATA with exactly TWO (2) compressed names
	MINFO,RP,

  6) special case RDATA with compression, all different
  	SOA,SIG,PX,NXT,SRV,NAPTR

*********************************************************
*********************************************************/

/********************************************************
*********************************************************
**	Case out the response for each TYPE
**	The TYPE's are ordered in the most common
**	occurence with the records used by rbldnsd
**	at the beginning and the rest in order to
**	cluster the responses according to the needs
**	of any necessary RDATA decompression
*********************************************************
*********************************************************/

int
rblf_case(struct rblf_info * ri, unsigned char **ptrptr, unsigned char * bom, unsigned char * eom)
{
  int i, k, j;
  unsigned char * cp = *ptrptr , * cend = cp + ri->rdl, * dstlim = ri->rdata + RBLF_DLEN;

/*	case out type		*/
  switch (ri->type) {
/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                    ADDRESS                    |
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * ADDRESS         A 32 bit Internet address.
 */
      case T_A:             /* 1	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   TXT-DATA                    /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * TXT-DATA        One or more <character-string>s.
 */
      case T_TXT:           /* 16	*/
      {
    NOCOMPRESSION:
	i = rblf_safemcpy(ri->rdata,cp,ri->rdl,dstlim);
	if (i < 0)
	  return (-1); 
	cp += i;
	break;
      }
/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   NSDNAME                     /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * NSDNAME       A <domain-name> which specifies a host which should be
 *               authoritative for the specified class and domain.
 */
      case T_NS:            /* 2	*/
      {
	j = 0;
/*	enter here with j set to offset from ri->rdata	*/
      DECOMPRESS1:
	i =  rblf_unpack(bom, eom, &(unsigned char *)cp, (ri->rdata +j), dstlim);
	if (i < 0)
	  return (-1);
	ri->rdl = i + j;
	break;
      }
/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                  PREFERENCE                   |
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   EXCHANGE                    /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * PREFERENCE   A 16 bit integer which specifies the preference given to
 *              this RR among others at the same owner.  Lower values
 *              are preferred.
 *
 * EXCHANGE     A <domain-name> which specifies a host willing to act as
 *              a mail exchange for the owner name.
 */
      case T_MX:            /* 15	*/
      {
    LIKE_MX:
	j = 2;				/*	a 16 bit SHORT	*/
/*	branch to here with the xfer size in 'j'		*/
    MEMandDECOMPRESS:
	memcpy(ri->rdata,cp,j);		/*	PREFERENCE	*/
	cp += j;
	goto DECOMPRESS1;
      }
/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                     MNAME                     /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                     RNAME                     /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                    SERIAL                     |
 *  |                                               |
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                    REFRESH                    |
 *  |                                               |
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                     RETRY                     |
 *  |                                               |
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                    EXPIRE                     |
 *  |                                               |
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                    MINIMUM                    |
 *  |                                               |
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * MNAME        The <domain-name> of the name server that was the
 *              original or primary source of data for this zone.
 *
 * RNAME        A <domain-name> which specifies the mailbox of the
 *              person responsible for this zone.
 *
 * SERIAL       The unsigned 32 bit version number of the original copy
 *              of the zone.  Zone transfers preserve this value.  This
 *              value wraps and should be compared using sequence space
 *              arithmetic.
 *
 * REFRESH      A 32 bit time interval before the zone should be
 *              refreshed.
 *
 * RETRY        A 32 bit time interval that should elapse before a
 *              failed refresh should be retried.
 *
 * EXPIRE       A 32 bit time value that specifies the upper limit on
 *              the time interval that can elapse before the zone is no
 *              longer authoritative.
 *
 * MINIMUM      The unsigned 32 bit minimum TTL field that should be
 *              exported with any RR from this zone.
 */
      case T_SOA:           /* 6	*/
      {
	j =  rblf_unpack(bom, eom, &(unsigned char *)cp, ri->rdata, dstlim);	/*	MNAME	*/
	if (j < 0)
	  return (-1);
/*	enter here with ri->rdata offset in 'j'	*/
    DECOMPRESSandMEM:
	i =  rblf_unpack(bom, eom, &(unsigned char *)cp, (ri->rdata +j), dstlim);
	if (i < 0)
	  return (-1);
	ri->rdl = cend - cp + i + j;
	if (rblf_safemcpy((ri->rdata + j + i),cp,(cend - cp),dstlim) < 0)
	  return (-1);
	break;
      }

/************************************************************
*************************************************************
**
**	What follows is uncommon usage or unsupported
**	by rbldnsd. Some are just here for completeness.
**
*************************************************************
*************************************************************/

/************************************************************
*************************************************************
**	TYPE's with RDATA consisting of a single 
**	compressed name.
*************************************************************
*************************************************************/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   MADNAME                     /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:

 * MADNAME       A <domain-name> which specifies a host which has a mail
 *              agent for the domain which should be able to deliver
 *              mail for the domain.
 */
      case T_MD:            /* 3	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   MADNAME                     /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * MADNAME      A <domain-name> which specifies a host which has a mail
 *              agent for the domain which will accept mail for
 *              forwarding to the domain.
 */
      case T_MF:            /* 4	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                     CNAME                     /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * CNAME        A <domain-name> which specifies the canonical or primary
 *              name for the owner.  The owner name is an alias.
 */
      case T_CNAME:         /* 5	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   MADNAME                     /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * MADNAME      A <domain-name> which specifies a host which has the
 *              specified mailbox.
 */
      case T_MB:            /* 7	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   MGMNAME                     /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * MGMNAME      A <domain-name> which specifies a mailbox which is a
 *              member of the mail group specified by the domain name.
 */
      case T_MG:            /* 8	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   NEWNAME                     /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * NEWNAME      A <domain-name> which specifies a mailbox which is the
 *              proper rename of the specified mailbox.
 */
      case T_MR:            /* 9	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   PTRDNAME                    /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * PTRDNAME     A <domain-name> which points to some location in the
 *              domain name space.
 */
      case T_PTR:           /* 12	*/
      {
	j = 0;
	goto DECOMPRESS1;
      }


/************************************************************
*************************************************************
**	TYPE's with RDATA exactly like type MX
**	with a SHORT (16 bits) and one compressed name
*************************************************************
*************************************************************/

/*
 * AFSDB has the following format:
 *
 * <owner> <ttl> <class> AFSDB <subtype> <hostname>
 *
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                   SUBTYPE                     |   
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   HOSTNAME                    / 
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * Both RDATA fields are required in all AFSDB RRs.  The <subtype> field
 * is a 16 bit integer.  The <hostname> field is a domain name of a host
 * that has a server for the cell named by the owner name of the RR.
 *
 * The format of the AFSDB RR is class insensitive.  AFSDB records cause
 * type A additional section processing for <hostname>.  This, in fact,
 * is the rationale for using a new type code, rather than trying to
 * build the same functionality with TXT RRs.
 *
 * Note that the format of AFSDB in a master file is identical to MX.
 * For purposes of the DNS itself, the subtype is merely an integer.
 */
      case T_AFSDB:         /* 18	*/

/*
 * RT has the following format:
 *
 * <owner> <ttl> <class> RT <preference> <intermediate-host>
 *
 * Both RDATA fields are required in all RT RRs.
 *
 * The first field, <preference>, is a 16 bit integer, representing the
 * preference of the route.  Smaller numbers indicate more preferred
 * routes.
 *
 * <intermediate-host> is the domain name of a host which will serve as
 * an intermediate in reaching the host specified by <owner>.  The DNS
 * RRs associated with <intermediate-host> are expected to include at
 */
      case T_RT:            /* 21	*/
      {
	goto LIKE_MX;
      }

/******************************************************************
*******************************************************************
**	These TYPES never appear in responses that
**	will be handled by this routine
*******************************************************************
*******************************************************************/
 
      case T_TKEY:	/* partially undefined record specification, handle as unknown	249	*/

      case T_TSIG:	/* variable? record format, handle as unknown			250	*/
 
      case T_IXFR:	/* variable record format, handle as unknown			251	*/
 
      case T_AXFR:	/* variable record format, handle as unknown			252	*/
 
      case T_MAILB:	/* rarely used, handle as unknown				253	*/
 
      case T_MAILA:	/* rarely used, handle as unknown				254	*/

      case T_ANY:	/* will never be a return record, ignore			255	*/
      {
	return (-1);	/*	server fail	*/
      }

/************************************************************
*************************************************************
**	TYPE's with RDATA containing 2 compressed names
*************************************************************
*************************************************************/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                    RMAILBX                    /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                    EMAILBX                    /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * RMAILBX      A <domain-name> which specifies a mailbox which is
 *              responsible for the mailing list or mailbox.  If this
 *              domain name names the root, the owner of the MINFO RR is
 *              responsible for itself.  Note that many existing mailing
 *              lists use a mailbox X-request for the RMAILBX field of
 *              mailing list X, e.g., Msgroup-request for Msgroup.  This
 *              field provides a more general mechanism.
 *
 * EMAILBX      A <domain-name> which specifies a mailbox which is to
 *              receive error messages related to the mailing list or
 *              mailbox specified by the owner of the MINFO RR (similar
 *              to the ERRORS-TO: field which has been proposed).  If
 *              this domain name names the root, errors should be
 *              returned to the sender of the message.
 */
      case T_MINFO:         /* 14	*/

/*
 * RP has the following format:
 *
 * <owner> <ttl> <class> RP <mbox-dname> <txt-dname>
 *
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   MBOX-DNAME                  /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   TXT-DNAME                   /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * Both RDATA fields are required in all RP RRs.
 *
 * The first field, <mbox-dname>, is a domain name that specifies the
 * mailbox for the responsible person.  Its format in master files uses
 * the DNS convention for mailbox encoding, identical to that used for
 * the RNAME mailbox field in the SOA RR.  The root domain name (just
 * ".") may be specified for <mbox-dname> to indicate that no mailbox is
 * available.
 *
 * The second field, <txt-dname>, is a domain name for which TXT RR's
 * exist.  A subsequent query can be performed to retrieve the
 * associated TXT resource records at <txt-dname>.  This provides a
 * level of indirection so that the entity can be referred to from
 * multiple places in the DNS.  The root domain name (just ".") may be
 * specified for <txt-dname> to indicate that the TXT_DNAME is absent,
 * and no associated TXT RR exists.
 */
      case T_RP:            /* 17	*/
      {
    DECOMPRESS2:
	j =  rblf_unpack(bom, eom, &(unsigned char *)cp, ri->rdata, dstlim);	/*	RMAILBX	*/
	if (j < 0)
	  return (-1);
	goto DECOMPRESS1;					/*	EMAILBX	*/
      }

/************************************************************
*************************************************************
**	TYPE's with RDATA containing special formats
*************************************************************
*************************************************************/


/*
 *                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
 *     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *    |        type covered           |  algorithm    |     labels    |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *    |                         original TTL                          |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *    |                      signature expiration                     |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *    |                      signature inception                      |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *    |            key  tag           |                               |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+         signer's name         +
 *    |                                                               /
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-/
 *    /                                                               /
 *    /                            signature                          /
 *    /                                                               /
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 */
      case T_SIG:           /* 24	see rfc2535	*/
      {
	j = 18;
/*	enter here with mem to copy in 'j'	*/
    MEMandDECOMPRESSandMEM:
	memcpy(ri->rdata,cp,j);		/* 9 16 bit chunks		*
	cp += j;
/*	enter here with ri->rdata offset in 'j'	*/
	goto DECOMPRESSandMEM;
      }
/*
 * The PX RDATA format is:
 *
 *        +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *        |                  PREFERENCE                   |
 *        +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *        /                    MAP822                     /
 *        /                                               /
 *        +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *        /                    MAPX400                    /
 *        /                                               /
 *        +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * PREFERENCE   A 16 bit integer which specifies the preference given to
 *              this RR among others at the same owner.  Lower values
 *              are preferred;
 *
 * MAP822       A <domain-name> element containing <rfc822-domain>, the
 *              RFC822 part of the RFC1327 mapping information;
 *
 * MAPX400      A <domain-name> element containing the value of
 *              <x400-in-domain-syntax> derived from the X.400 part of
 *              the RFC1327 mapping information (see sect. 4.2);
 */
      case T_PX:            /* 26	*/
      {
	j = 2;
	goto MEMandDECOMPRESSandMEM;
      }
/*
 * The RDATA for an NXT RR consists simply of a domain name followed by
 * a bit map.
 *                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
 *     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *    |         next domain name                                      /
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *    |                    type bit map                               /
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *
 * The NXT RR type bit map is one bit per RR type present for the owner
 * name similar to the WKS socket bit map.  The first bit represents RR
 * type zero (an illegal type which should not be present.) A one bit
 * indicates that at least one RR of that type is present for the owner
 * name.  A zero indicates that no such RR is present.  All bits not
 * specified because they are beyond the end of the bit map are assumed
 * to be zero.  Note that bit 30, for NXT, will always be on so the
 * minimum bit map length is actually four octets.  The NXT bit map
 * should be printed as a list of RR type mnemonics or decimal numbers
 * similar to the WKS RR.
 *
 * The domain name may be compressed with standard DNS name compression
 * when being transmitted over the network.  The size of the bit map can
 * be inferred from the RDLENGTH and the length of the next domain name.
 *
 * Example
 *
 * big.foo.tld. NXT medium.foo.tld. A MX SIG NXT
 */
      case T_NXT:           /* 30	*/
      {
	j = 0;
	goto DECOMPRESSandMEM;
      }

/*
 *
 * The format of the SRV RR
 *
 * Here is the format of the SRV RR, whose DNS type code is 33:
 *
 *      Service.Proto.Name TTL Class SRV Priority Weight Port Target
 *
 *      (There is an example near the end of this document.)
 *
 * Priority
 *      As for MX, the priority of this target host.  A client MUST
 *      attempt to contact the target host with the lowest-numbered
 *      priority it can reach; target hosts with the same priority
 *      SHOULD be tried in pseudorandom order.  The range is 0-65535.
 *
 * Weight
 *      Load balancing mechanism.  When selecting a target host among
 *      the those that have the same priority, the chance of trying this
 *      one first SHOULD be proportional to its weight.  The range of
 *      this number is 1-65535.  Domain administrators are urged to use
 *      Weight 0 when there isn't any load balancing to do, to make the
 *      RR easier to read for humans (less noisy).
 *
 * Port
 *      The port on this target host of this service.  The range is
 *      0-65535.  This is often as specified in Assigned Numbers but
 *      need not be.
 *
 * Target
 *      As for MX, the domain name of the target host.  There MUST be
 *      one or more A records for this name. Implementors are urged, but
 *      not required, to return the A record(s) in the Additional Data
 *      section.  Name compression is to be used for this field.
 */
      case T_SRV:           /* 33	*/
      {
/*
 *	name compression is not allowed in SRV records per rfc2782
 *	but is required by RFC2052 which has been implemented. sigh...
 */
	memcpy(ri->rdata,cp,6);		/*	3 shorts	*/
	cp += 6;
	j = 6;
	goto MEMandDECOMPRESS;
      }

/*
 *    NAPTR order        16 bits
 *          preference   16 bits
 *          flags        character-string
 *          service      character-string
 *          regexp       character-string
 *          replacement  domain-name
 */
      case T_NAPTR:         /* 35	*/
      {
	memcpy(ri->rdata,cp,4);		/*	2 shorts	*/
	cp += 4;
	ri->rdl = 4;
	k = 0;
	while (k < 3) {
	  GETSHORT(j,cp);
	  i = rblf_strncpy((ri->rdata + ri->rdl),cp,j);
	  cp += i;
	  ri->rdl += i;
	  k++;
	}
	j = ri->rdl;
	goto DECOMPRESS1;
      }

/************************************************************
*************************************************************
**	TYPE's with RDATA that are not compressed
*************************************************************
*************************************************************/

#ifdef RBLF_NO_CODE_HERE	/*	fall into default: - no compression	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                  <anything>                   /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * Anything at all may be in the RDATA field so long as it is 65535 octets
 * or less.
 */
      case T_NULL:          /* 10	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                    ADDRESS                    |
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |       PROTOCOL        |                       |
 *  +--+--+--+--+--+--+--+--+                       |
 *  |                                               |
 *  /                   <BIT MAP>                   /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * The WKS record is used to describe the well known services supported by
 * a particular protocol on a particular internet address.  The PROTOCOL
 * field specifies an IP protocol number, and the bit map has one bit per
 * port of the specified protocol.  The first bit corresponds to port 0,
 * the second to port 1, etc.  If the bit map does not include a bit for a
 * protocol of interest, that bit is assumed zero.  The appropriate values
 * and mnemonics for ports and protocols are specified in [RFC-1010].
 *
 * For example, if PROTOCOL=TCP (6), the 26th bit corresponds to TCP port
 * 25 (SMTP).  If this bit is set, a SMTP server should be listening on TCP
 * port 25; if zero, SMTP service is not supported on the specified
 * address.
 *
 * i.e.     IN	      WKS   128.32.0.10   UDP	     who route timed domain
 */
      case T_WKS:           /* 11	*/

/*
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                      CPU                      /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                       OS                      /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * CPU          A <character-string> which specifies the CPU type.
 *
 * OS           A <character-string> which specifies the operating
 *              system type.
 */
      case T_HINFO:         /* 13	*/

/*
 * The X25 RR is defined with mnemonic X25 and type code 19 (decimal).
 *
 * X25 has the following format:
 *
 * <owner> <ttl> <class> X25 <PSDN-address>
 *
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                     CLASS                     /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                  PSDN-address                 /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * <PSDN-address> is required in all X25 RRs.
 *
 * <PSDN-address> identifies the PSDN (Public Switched Data Network)
 * address in the X.121 [10] numbering plan associated with <owner>.
 * Its format in master files is a <character-string> syntactically
 * identical to that used in TXT and HINFO.
 * [optional]
 */
      case T_X25:           /* 19	*/

/*
 * ISDN has the following format:
 *
 * <owner> <ttl> <class> ISDN <ISDN-address> <sa>
 *
 * The <ISDN-address> field is required; <sa> is optional.
 *
 * <ISDN-address> identifies the ISDN number of <owner> and DDI (Direct
 * Dial In) if any, as defined by E.164 [8] and E.163 [7], the ISDN and
 * PSTN (Public Switched Telephone Network) numbering plan.  E.163
 * defines the country codes, and E.164 the form of the addresses.  Its
 * format in master files is a <character-string> syntactically
 * identical to that used in TXT and HINFO.
 * [optional]
 */
      case T_ISDN:          /* 20	*/

/*
 * NSAP has the following format:
 *
 * <owner> <ttl> <class> NSAP <length> <NSAP-address>
 *
 * All fields are required.
 *
 * <length> identifies the number of octets in the <NSAP-address> as
 * defined by the various national and international authorities.
 *
 * <NSAP-address> enumerates the actual octet values assigned by the
 * assigning authority.  Its format in master files is a <character-
 * string> syntactically identical to that used in TXT and HINFO.
 *
 * The format of NSAP is class insensitive.  NSAP RR causes no
 * additional section processing.
 *
 * For example:
 *
 * foo.bar.com.    IN  NSAP   21 47000580ffff000000321099991111222233334444
 * host.school.de  IN  NSAP   17 39276f3100111100002222333344449876
 *
 * The RR data is the ASCII representation of the digits.  It is encoded
 * as two <character-strings>, i.e., count followed by characters.
 * [optional]
 */
      case T_NSAP:          /* 22	*/

/*
 * NSAP-PTR has the following format:
 *
 * <NSAP-suffix> <ttl> <class> NSAP-PTR <owner>
 *
 * All fields are required.
 *
 * <NSAP-suffix> enumerates the actual octet values assigned by the
 * assigning authority for the LOCAL network.  Its format in master
 * files is a <character-string> syntactically identical to that used in
 * TXT and HINFO.
 *
 * The format of NSAP-PTR is class insensitive.  NSAP-PTR RR causes no
 * additional section processing.
 *
 * For example:
 *
 * In net ff08000574.nsap-in-addr.arpa:
 *
 * 444433332222111199990123000000ff    NSAP-PTR   foo.bar.com.
 *
 * Or in net 11110031f67293.nsap-in-addr.arpa:
 *
 * 67894444333322220000  NSAP-PTR        host.school.de.
 *
 * The RR data is the ASCII representation of the digits.  It is encoded
 * as a <character-string>.
 * [optional]
 */
      case T_NSAP_PTR:      /* 23	*/

/*
 *                      1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
 *  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |             flags             |    protocol   |   algorithm   |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |                                                               /
 * /                          public key                           /
 * /                                                               /
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
 * Bits 3 is reserved as a flag extension bit.  If it is a one, a second
 *        16 bit flag field is added after the algorithm octet and
 *        before the key data.  This bit MUST NOT be set unless one or
 *        more such additional bits have been defined and are non-zero.
 *
 * KEY RRs may appear as lines in a zone data master file.
 *
 * The flag field, protocol, and algorithm number octets are then
 * represented as unsigned integers.  Note that if the type field has
 * the "no key" value or the algorithm specified is 253, nothing appears
 * after the algorithm octet.
 *
 * The remaining public key portion is represented in base 64 (see
 * Appendix) and may be divided up into any number of white space
 * separated substrings, down to single base 64 digits, which are
 * concatenated to obtain the full signature.  These substrings can span
 * lines using the standard parenthesis.
 * [optional]
 */
      case T_KEY:           /* 25	see rfc2535	*/

/*
 *      MSB                                        LSB
 *      +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *      /                 LONGITUDE                  /
 *      +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *      /                  LATITUDE                  /
 *      +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *      /                  ALTITUDE                  /
 *      +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * LONGITUDE The real number describing the longitude encoded as a
 *           printable string. The precision is limited by 256 charcters
 *           within the range -90..90 degrees. Positive numbers
 *           indicate locations north of the equator.
 *
 * LATITUDE The real number describing the latitude encoded as a
 *          printable string. The precision is limited by 256 charcters
 *          within the range -180..180 degrees. Positive numbers
 *          indicate locations east of the prime meridian.
 *
 * ALTITUDE The real number describing the altitude (in meters) from
 *          mean sea-level encoded as a printable string. The precision
 *          is limited by 256 charcters. Positive numbers indicate
 *          locations above mean sea-level.
 *
 * Latitude/Longitude/Altitude values are encoded as strings as to avoid
 * the precision limitations imposed by encoding as unsigned integers.
 * Although this might not be considered optimal, it allows for a very
 * high degree of precision with an acceptable average encoded record
 * length.
 * [optional]
 */
      case T_GPOS:          /* 27	*/

/*
 * A 128 bit IPv6 address is encoded in the data portion of an AAAA
 * resource record in network byte order (high-order byte first).
 * [optional]
 */
      case T_AAAA:          /* 28	*/

      case T_LOC:	/* ambigious, handle as NOCOMPRESSION	29	*/

      case T_EID:	/* expired draft, handle as unknown 31	*/

      case T_NIMLOC:	/* expired draft, handle as unknown 32	*/

      case T_ATMA:	/* complex, handle as unknown 34	*/

/*
 * The KX DNS record has the following RDATA format:
 *
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  |                  PREFERENCE                   |
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *  /                   EXCHANGER                   /
 *  /                                               /
 *  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
 *
 * where:
 *
 * PREFERENCE      A 16 bit non-negative integer which specifies the
 *                 preference given to this RR among other KX records
 *                 at the same owner.  Lower values are preferred.
 *
 * EXCHANGER       A <domain-name> which specifies a host willing to
 *                 act as a mail exchange for the owner name.
 *
 * The KX RDATA field MUST NOT be compressed.
 * [optional]
 */
      case T_KX:            /* 36	*/

      case T_CERT:	/* multiple formats, handle as unknown 37	*/
/*
 * The RDATA portion of the A6 record contains two or three fields.
 *
 *         +-----------+------------------+-------------------+
 *         |Prefix len.|  Address suffix  |    Prefix name    |
 *         | (1 octet) |  (0..16 octets)  |  (0..255 octets)  |
 *         +-----------+------------------+-------------------+
 *
 * o  A prefix length, encoded as an eight-bit unsigned integer with
 *    value between 0 and 128 inclusive.
 *
 * o  An IPv6 address suffix, encoded in network order (high-order octet
 *    first).  There MUST be exactly enough octets in this field to
 *    contain a number of bits equal to 128 minus prefix length, with 0
 *    to 7 leading pad bits to make this field an integral number of
 *    octets.  Pad bits, if present, MUST be set to zero when loading a
 *    zone file and ignored (other than for SIG [DNSSEC] verification)
 *    on reception.
 *
 * o  The name of the prefix, encoded as a domain name.  By the rules of
 *    [DNSIS], this name MUST NOT be compressed.
 *
 * The domain name component SHALL NOT be present if the prefix length
 * is zero.  The address suffix component SHALL NOT be present if the
 * prefix length is 128.
 *
 * $ORIGIN EXAMPLE.            ; first option
 * X               NS NS1.X
 *                 NS NS2.X
 * NS1.X           A6 64 ::1:11:111:1111 SUBNET-1.IP6.X
 * NS2.X           A6 64 ::2:22:222:2222 SUBNET-2.IP6.X
 * SUBNET-1.IP6.X  A6 48 0:0:0:1::       IP6.X
 * SUBNET-2.IP6.X  A6 48 0:0:0:2::       IP6.X
 * IP6.X           A6 48 0::0            SUBSCRIBER-X.IP6.A.NET.
 * IP6.X           A6 48 0::0            SUBSCRIBER-X.IP6.B.NET.
 *
 * $ORIGIN EXAMPLE.            ; second option
 * X               NS NS1.X
 *                 NS NS2.X
 * NS1.X           A6 48 ::1:1:11:111:1111 SUBSCRIBER-X.IP6.A.NET.
 *                 A6 48 ::1:1:11:111:1111 SUBSCRIBER-X.IP6.B.NET.
 * NS2.X           A6 48 ::2:2:22:222:2222 SUBSCRIBER-X.IP6.A.NET.
 *                 A6 48 ::2:2:22:222:2222 SUBSCRIBER-X.IP6.B.NET.
 *
 * $ORIGIN EXAMPLE.            ; third option
 * X               NS NS1.X
 *                 NS NS2.X
 * NS1.X           A6 0  2345:00C1:CA11:1:1:11:111:1111
 *                 A6 0  2345:00D2:DA11:1:1:11:111:1111
 *                 A6 0  2345:000E:EB22:1:1:11:111:1111
 * NS2.X           A6 0  2345:00C1:CA11:2:2:22:222:2222
 *                 A6 0  2345:00D2:DA11:2:2:22:222:2222
 *                 A6 0  2345:000E:EB22:2:2:22:222:2222
 *
 * The textual representation of the RDATA portion of the A6 resource
 * record in a zone file comprises two or three fields separated by
 * whitespace.
 *
 * o  A prefix length, represented as a decimal number between 0 and 128
 *    inclusive,
 *
 * o  the textual representation of an IPv6 address as defined in
 *    [AARCH] (although some leading and/or trailing bits may not be
 *    significant),
 *
 * o  a domain name, if the prefix length is not zero.
 *
 * The domain name MUST be absent if the prefix length is zero.  The
 * IPv6 address MAY be be absent if the prefix length is 128.  A number
 * of leading address bits equal to the prefix length SHOULD be zero,
 * either implicitly (through the :: notation) or explicitly, as
 * specified above.
 * [optional]
 */
      case T_A6:            /* 38	*/

/*
 * DNAME has the following format:
 *
 *    <owner> <ttl> <class> DNAME <target>
 *
 * The format is not class-sensitive.  All fields are required.  The
 * RDATA field <target> is a <domain-name> [DNSIS].
 *
 * The compression scheme of [DNSIS] MUST NOT be applied to the RDATA
 * portion of a DNAME record unless the sending server has some way of
 * knowing that the receiver understands the DNAME record format.
 * Signalling such understanding is expected to be the subject of future
 * DNS Extensions.
 * [optional]
 */
      case T_DNAME:         /* 39	*/

      case T_SINK:	/* expired, variable format, handle as unknown 40	*/

      case T_OPT:	/* unknown RDATA format, handle as unknown	    41	*/

/*
 *                      1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
 *  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |           Key Tag             |  Algorithm    |  Digest Type  |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * /                                                               /
 * /                            Digest                             /
 * /                                                               /
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *
 * dskey.example.com. 86400 IN DS 60485 5 1 ( 2BB183AF5F22588179A53B0A
 *                                            98631FAD1A292118 )
 * [optional]
 */
      case T_DS:            /* 43	*/

#endif		/*	RBLF_NO_CODE_HERE	*/

      default:
      {
      goto NOCOMPRESSION;
      }
  }
  *ptrptr = cend;
  return (0);
}
