/*	rblf_defines.h	*/

#ifndef RBLF_DEFINES_H
#define RBLF_DEFINESH 1

/* DNS packet:
 * bytes comment */
/* 0:1   identifier (client supplied) */
#define p_id1 0
#define p_id2 1
/* 2     flags1 */
#define p_f1 2
#define pf1_qr     0x80 /* query response flag */
#define pf1_opcode 0x78 /* opcode, 0 = query */
#define pf1_aa     0x04 /* auth answer */
#define pf1_tc     0x02 /* truncation flag */
#define pf1_rd     0x01 /* recursion desired (may be set in query) */
/* 3     flags2 */
#define p_f2 3
#define pf2_ra     0x80 /* recursion available */
#define pf2_z      0x70 /* reserved */
#define pf2_rcode  0x0f /* response code */
  /* 0 ok, 1 format error, 2 servfail, 3 nxdomain, 4 notimpl, 5 refused */
/* 4:5   qdcount (numqueries) */
#define p_qdcnt1 4
#define p_qdcnt2 5
/* 6:7   ancount (numanswers) */
#define p_ancnt1 6
#define p_ancnt2 7
/* 8:9   nscount (numauthority) */
#define p_nscnt1 8
#define p_nscnt2 9
/* 10:11 arcount (numadditional) */
#define p_arcnt1 10
#define p_arcnt2 11
#define p_hdrsize 12    /* size of packet header */
/* next is a DN name, a series of labels with first byte is label's length,
 *  terminated by zero-length label (i.e. at least one zero byte is here)
 * next two bytes are query type (A, SOA etc)
 * next two bytes are query class (IN, HESIOD etc)
 */
#define p_qoff1 0	/* question offset from DN	*/
#define p_qoff2 1
#define p_coff1 2	/* class offset from DN		*/
#define p_coff2 3

#endif
