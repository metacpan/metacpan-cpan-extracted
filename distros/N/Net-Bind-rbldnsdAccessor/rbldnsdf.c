/*
	rbldnsdf.c	version 1.00

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

#include "rbldnsd/config.h"
#include "rbldnsd/rbldnsd.h"
#include "rblf_base.h"
#include "rblf_isc_result.h"
#include "rblf_defines.h"
#include "rbldnsd_import.h"

extern int lazy;
extern int logto;;

time_t next = 0;

struct dnspacket pkt;
/*	init just one zone	*/
void
rblf_init_zones_cache(struct zone * zonelist)
{
/*	walk down to most recently added zone	*/
  while (zonelist->z_next != NULL) {
    zonelist = zonelist->z_next;
  }
  init_zones_caches(zonelist);
}

unsigned int
rblf_query(const char *name, struct dnspacket * pkt)
{
  struct zone ** zonep;	/*	pointer to zonelist	*/
  register unsigned char *d, * e, * q = pkt->p_buf, * x;
  struct dnsquery qry;	/* query structure */
  struct dnsqinfo qi;			/* query info structure */
  unsigned int qlab, dnlen;
  struct zone my_zone, * zone;
  const struct dslist * dsl;
  int found;
  time_t now;

/*	initialize dummy packet with question, this is eye candy	*/
  bzero(pkt,sizeof(struct dnspacket));

#ifdef RBLF_EYE_CANDY
  q[p_id1]	= 0x12;
  q[p_id2]	= 0x34;
  q[p_f1]	= 0x85;	/*	query response, auth ans, recursion desired	*/
  q[p_f2]	= 0x80;	/*	recursion available, will be overwritten	*/
#endif
/*	counts are all zero from bzero above	*/

/*	lookup name to rbldnsd format, dummy up query	*/
  q += p_hdrsize;
  x = q + DNS_MAXDN -1;			/*	constrain query DN to DNS_MAXDN	*/
  dnlen = dns_ptodn(name,q,DNS_MAXDN);

  if (!dnlen)
    return (ISC_R_FAILURE);

#ifdef RBLF_EYE_CANDY
  q[dnlen + p_qoff2] = DNS_C_IN;
  q[dnlen + p_coff2] = DNS_T_ANY;
#endif

/*	see rbldnsd_packet.c	parsequery	*/
  qlab = 0;
  d = qry.q_dn;

/*	directly from parsequery		*/
  while((*d = *q) != 0) {       /* loop by DN lables */
    qry.q_lptr[qlab++] = d++;  /* another label */
    e = q + *q + 1;             /* end of this label */
    if (*q > DNS_MAXLABEL       /* too long label? */
        || e > x)               /* or it ends past packet? */
      return 0;
    /* lowercase it */
    ++q;                        /* length */
    do *d++ = dns_dnlc(*q);     /* lowercase each char */
    while(++q < e);             /* until end of label */
  }

/* d points to qDN terminator now */
  qry.q_dnlen = d - qry.q_dn +1;
  qry.q_dnlab = qlab;

/* these don't appear to be used by us	*/
  qry.q_type = NSQUERY_ANY;
  qry.q_class = DNS_C_IN;

  q += 5;

  pkt->p_sans = (unsigned char *)q; /* answers will start here */
  pkt->p_cur = (unsigned char *)q;  /* and current answer pointer is here */
  pkt->p_endp = pkt->p_buf + DNS_MAXPACKET;
  pkt->p_buf[p_f2] = DNS_R_NOERROR;

  zonep = fetchzonelist();

  if (*zonep == NULL)
    goto NOT_FOUND;

  now = time(NULL);
  if (now > next) {
    next = now -1 + RBLF_RELOAD_CHECK_INTERVAL;
    rblf_do_reload();
  }
  zone = (struct zone *)findqzone(*zonep,qry.q_dnlen, qry.q_dnlab, qry.q_lptr, &qi);
  if (!zone)
    goto NOT_FOUND;

  if (!zone->z_stamp)   /* do not answer if not loaded */
    return (ISC_R_FAILURE);

  qi.qi_tflag = NSQUERY_ANY;	/* always	*/
  
  if (qi.qi_dnlab == 0)	{	/* query to base zone: SOA and NS */
    found = NSQUERY_FOUND;

/* NS and SOA with auth=0 will only touch answer section */
    if ((qi.qi_tflag & NSQUERY_SOA) && !rblf_addrr_soa(pkt, zone, 0))
      found = 0;
    else
    if ((qi.qi_tflag & NSQUERY_NS) && !rblf_addrr_ns(pkt, zone, 0))
      found = 0;
    if (!found)
      goto NOT_FOUND;
  }
  else		/* not to zone base DN */
    found = 0;

  /* search the datasets */
  for(dsl = zone->z_dsl; dsl; dsl = dsl->dsl_next)
    found |= dsl->dsl_queryfn(dsl->dsl_ds, &qi, pkt);

  if (!found) {	/* negative result */
  NOT_FOUND:
    pkt->p_cur = pkt->p_sans;
    return (ISC_R_NOTFOUND);
  }

  pkt->p_endp = pkt->p_cur;
  pkt->p_cur = pkt->p_sans;
  return (ISC_R_SUCCESS);
}

int
rblf_answer(struct rblf_info * ri, unsigned char **ptrptr, unsigned char * bom, unsigned char * eom)
{
  unsigned char * cp = *ptrptr;
  
  if (cp >= eom || rblf_skip(&cp,eom) < 0)
    return (-1);

  bzero(ri,sizeof(struct rblf_info));
  GETSHORT(ri->type,cp);	/*	numeric TYPE	*/
  cp += 2;			/*	skip over class	*/
  GETLONG(ri->ttl,cp);		/*	TTL		*/
  GETSHORT(ri->rdl,cp);		/*	RDLENGTH	*/

  if (rblf_case(ri,&cp,bom,eom) < 0)
    return (-1);

  *ptrptr = cp;
  return (0);
}

unsigned int
rblf_isc_lookup(char * name, void * lookup, rblf_dns_sdb_putrdata_t put_rr_callback)
{
  struct rblf_info ri;
  unsigned int result;
  unsigned char * cp;
  int answers;

  result = rblf_query(name,&pkt);
  if (result != ISC_R_SUCCESS)
    return (result);

  answers = (int)pkt.p_buf[p_ancnt2];
  cp = pkt.p_sans;			/* start of answers	*/

  while (answers > 0) {

    if ((result = rblf_answer(&ri,&cp,pkt.p_buf,pkt.p_endp)) != ISC_R_SUCCESS)
      break;

    if ((result = (*put_rr_callback)(lookup, ri.type, ri.ttl, ri.rdata, ri.rdl)) != ISC_R_SUCCESS)
      break;

    answers--;
  }
  return (result);
}
  
void
rblf_zone_init(void)
{
  lazy = 1;			/* init stuff in rbldnsd library */
  logto = 0;
}

void
rblf_zonelist_init(void)
{
  struct zone ** zonep;		/*	pointer to zonelist	*/
  
  rblf_zone_init();
  zonep = fetchzonelist();
  *zonep = NULL;
}

/*	drop all memory, reset to initial state	*/
void
rblf_drop(void)
{
  rblf_mtfree_all();
  rblf_zonelist_init();
}

unsigned int
rblf_create_zone(const char *zone, int argc, char **argv, void *driverdata, void **dbdata)
{
  struct zone ** zonep;		/*	pointer to zonelist	*/

  char tmp_buf[2000];		/*	zone:type:file,list,...	*/
  int i;

  rblf_zone_init();		
  
  B_UNUSED(driverdata);
  B_UNUSED(dbdata);
  
  if (argc < 2)
    return (ISC_R_FAILURE);

#ifdef RBLF_NO_CODE_HERE
  i = rblfdb_alloc(&ri,sizeof(struct rblf_info));
    if (i != ISC_R_SUCCESS) {
      return (i);
#endif

/*	zone:type:firstfile	*/
  sprintf(tmp_buf,"%s:%s:%s",zone,argv[0],argv[1]);

  i = 2;
  while (i < argc) {
    strncat(tmp_buf,",",1);
    strcat(tmp_buf,argv[i++]);
  }

  zonep = fetchzonelist();
  *zonep = addzone(*zonep,tmp_buf);	/* where zone name is the format name:type:file	*/
  rblf_init_zones_cache(*zonep);		/* init just this zone	*/
  rblf_do_reload();				/* load this dataset	*/

/*  *dbdata = NULL;	*/
  return (ISC_R_SUCCESS);
}

#ifdef RBLF_NO_CODE_HERE

##############
struct dnsquery {       /* q */
  unsigned q_type;                      /* query RR type */
  unsigned q_class;                     /* query class */
  unsigned char q_dn[DNS_MAXDN];        /* original query DN, lowercased */
  unsigned q_dnlen;                     /* length of q_dn */
  unsigned q_dnlab;                     /* number of labels in q_dn */
  unsigned char *q_lptr[DNS_MAXLABELS]; /* pointers to labels */
};
struct dnsqinfo {       /* qi */
  unsigned char *const *qi_dnlptr;
  const unsigned char *qi_dn;           /* cached query DN */
  unsigned qi_tflag;                    /* query RR type flag (NSQUERY_XX) */
  unsigned qi_dnlen0;                   /* length of qi_dn - 1 */
  unsigned qi_dnlab;                    /* number of labels in q_dn */
  ip4addr_t qi_ip4;                     /* parsed IP4 address */
  int qi_ip4valid;                      /* true if qi_ip4 is valid */
};
struct dnspacket {              /* private structure */
  unsigned char p_buf[DNS_EDNS0_MAXPACKET]; /* packet buffer */
  unsigned char *p_endp;        /* end of packet buffer */
  unsigned char *p_cur;         /* current pointer */
  unsigned char *p_sans;        /* start of answers */
  const char *p_substrr;        /* for always-listed queries */
  const struct dataset *p_substds;
  const struct sockaddr *p_peer;/* address of the requesting client */
  unsigned p_peerlen;
};
struct zone {   /* zone, list of zones */
  unsigned z_stamp;                     /* timestamp, 0 if not loaded */
  time_t z_expires;                     /* when the zone expires if any */
  unsigned char z_dn[DNS_MAXDN+1];      /* zone domain name */
  unsigned z_dnlen;                     /* length of z_dn */  
  unsigned z_dnlab;                     /* number of dn labels */
  unsigned z_dstflags;                  /* flags of all datasets */
  struct dslist *z_dsl;                 /* list of datasets */
  struct dslist **z_dslp;               /* last z_dsl in list */
  struct dataset *z_dsacl;              /* zone ACL */
  /* SOA record */
  const struct dssoa *z_dssoa;          /* original SOA from a dataset */
  struct zonesoa *z_zsoa;               /* pre-packed SOA record */
  const unsigned char *z_nsdna[MAX_NS]; /* array of nameserver DNs */
  unsigned z_nns;                       /* number of NSes in z_dsnsa[] */
  unsigned z_nsttl;                     /* ttl for NS records */
  unsigned z_cns;                       /* current NS in rotation */
  unsigned z_nglue;                     /* number of glue records */
  struct zonens *z_zns;                 /* pre-packed NS records */ 
#ifndef NO_STATS
  struct dnsstats z_stats;              /* statistic counters */
  struct dnsstats z_pstats;             /* for stats monitoring: prev values */
#endif
  struct zone *z_next;                  /* next in list */
};
##################

#endif
