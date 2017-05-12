/* $Id: Libdnet.xs 57 2012-11-02 16:39:39Z gomor $ */

/*
 * Copyright (c) 2004 Vlad Manilici
 * Copyright (c) 2008-2012 Patrice <GomoR> Auffret
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <dnet.h>

#ifdef DNET_BLOB_H
typedef blob_t              Blob;
#endif

#ifdef DNET_ETH_H
typedef eth_t               EthHandle;
typedef eth_addr_t          EthAddr;
#endif

#ifdef DNET_INTF_H
typedef intf_t              IntfHandle;
#endif

#ifdef DNET_ARP_H
typedef arp_t               ArpHandle;
#endif

#ifdef DNET_FW_H
typedef fw_t                FwHandle;
#endif

#ifdef DNET_ROUTE_H
typedef route_t             RouteHandle;
#endif

#ifdef DNET_TUN_H
typedef tun_t               TunHandle;
#endif

#ifdef DNET_IP_H
typedef ip_t                IpHandle;
#endif

typedef struct intf_entry   IntfEntry;
typedef struct arp_entry    ArpEntry;
typedef struct fw_rule      FwRule;
typedef struct route_entry  RouteEntry;

#include "c/intf_entry.c"
#include "c/arp_entry.c"
#include "c/route_entry.c"
#include "c/fw_rule.c"

static SV * keepSub = (SV *)NULL;

static int
intf_callback(IntfEntry *entry, SV *data)
{
   dSP;
   int ret;
   SV *e = intf_c2sv(entry);
   ENTER; SAVETMPS; PUSHMARK(SP);
   XPUSHs(e);
   XPUSHs(data);
   PUTBACK;
   call_sv(keepSub, G_DISCARD);
   SPAGAIN;
   FREETMPS; LEAVE;
   return 0;
}

static int
route_callback(RouteEntry *entry, SV *data)
{
   dSP;
   int ret;
   SV *e = route_c2sv(entry);
   ENTER; SAVETMPS; PUSHMARK(SP);
   XPUSHs(e);
   XPUSHs(data);
   //XPUSHs(sv_setref_pv(sv_newmortal(), "RouteEntryPtr", entry));
   //XPUSHs(sv_setref_pv(sv_newmortal(), Nullch, data));
   PUTBACK;
   call_sv(keepSub, G_DISCARD);
   SPAGAIN;
   //ret = POPi;
   FREETMPS; LEAVE;
   //return ret;
   return 0;
}

static int
arp_callback(ArpEntry *entry, SV *data)
{
   dSP;
   int ret;
   SV *e = arp_c2sv(entry);
   ENTER; SAVETMPS; PUSHMARK(SP);
   XPUSHs(e);
   XPUSHs(data);
   PUTBACK;
   call_sv(keepSub, G_DISCARD);
   SPAGAIN;
   FREETMPS; LEAVE;
   return 0;
}

static int
fw_callback(FwRule *rule, SV *data)
{
   dSP;
   int ret;
   SV *e = fw_c2sv(rule);
   ENTER; SAVETMPS; PUSHMARK(SP);
   XPUSHs(e);
   XPUSHs(data);
   PUTBACK;
   call_sv(keepSub, G_DISCARD);
   SPAGAIN;
   FREETMPS; LEAVE;
   return 0;
}

HV * intf2hash(struct intf_entry *IeInt){
        HV *HvInt, *HvUndef;
        SV *SvData, *SvKey;
        char *StrAddr;

        /* prepare undefined hash */
        HvUndef = newHV();
        hv_undef(HvUndef);

        HvInt = newHV();

        /* intf_len */
        SvKey = newSVpv("len", 0);
        SvData = newSVnv((double) IeInt->intf_len);
        if( hv_store_ent(HvInt, SvKey, SvData, 0) == NULL ){
                warn("intf2hash: error: intf_len\n");
                return HvUndef;
        }

        /* intf_name */
        SvKey = newSVpv("name", 0);
        SvData = newSVpv(IeInt->intf_name, 0);
        if( hv_store_ent(HvInt, SvKey, SvData, 0) == NULL ){
                warn("intf2hash: error: int_name\n");
                return HvUndef;
        }

        /* intf_type */
        SvKey = newSVpv("type", 0);
        SvData = newSVnv((double) IeInt->intf_type);
        if( hv_store_ent(HvInt, SvKey, SvData, 0) == NULL ){
                warn("intf2hash: error: intf_type\n");
                return HvUndef;
        }

        /* intf_flags */
        SvKey = newSVpv("flags", 0);
        SvData = newSVnv((double) IeInt->intf_flags);
        if( hv_store_ent(HvInt, SvKey, SvData, 0) == NULL ){
                warn("intf2hash: error: intf_flags\n");
                return HvUndef;
        }

        /* intf_mtu */
        SvKey = newSVpv("mtu", 0);
        SvData = newSVnv((double) IeInt->intf_mtu);
        if( hv_store_ent(HvInt, SvKey, SvData, 0) == NULL ){
                warn("intf2hash: error: intf_mtu\n");
                return HvUndef;
        }

        /* intf_addr */
        SvKey = newSVpv("addr", 0);
        /* does not allways exist */
        StrAddr = addr_ntoa(&(IeInt->intf_addr));
        if( StrAddr == NULL ){
                SvData = &PL_sv_undef;
        }else{
                SvData = newSVpv(addr_ntoa(&(IeInt->intf_addr)), 0);
        }
        if( hv_store_ent(HvInt, SvKey, SvData, 0) == NULL ){
                warn("intf2hash: error: intf_addr\n");
                return HvUndef;
        }

        /* intf_dst_addr */
        SvKey = newSVpv("dst_addr", 0);
        /* does not allways exist */
        StrAddr = addr_ntoa(&(IeInt->intf_dst_addr));
        if( StrAddr == NULL ){
                SvData = &PL_sv_undef;
        }else{
                SvData = newSVpv(addr_ntoa(&(IeInt->intf_dst_addr)), 0);
        }
        if( hv_store_ent(HvInt, SvKey, SvData, 0) == NULL ){
                warn("intf2hash: error: intf_dst_addr\n");
                return HvUndef;
        }

        /* intf_link_addr */
        SvKey = newSVpv("link_addr", 0);
        /* does not allways exist */
        StrAddr = addr_ntoa(&(IeInt->intf_link_addr));
        if( StrAddr == NULL ){
                SvData = &PL_sv_undef;
        }else{
                SvData = newSVpv(addr_ntoa(&(IeInt->intf_link_addr)), 0);
        }
        if( hv_store_ent(HvInt, SvKey, SvData, 0) == NULL ){
                warn("intf2hash: error: intf_link_addr\n");
                return HvUndef;
        }

        /* XXX skipped the aliases problematic */

        return HvInt;
}

MODULE = Net::Libdnet  PACKAGE = Net::Libdnet
PROTOTYPES: DISABLE

#
# The following are obsolete functions, but stills there for compatibility reasons
#

SV *
_obsolete_addr_cmp(SvA, SvB)
		SV *SvA;
		SV *SvB;
	PROTOTYPE: $$
	CODE:
		char *StrA, *StrB;
		struct addr SadA, SadB;
		int len;

		/*
		we cannot avoid ugly nesting, because
		return and goto are out of scope
		*/

		/* check input */
		if( !SvOK(SvA) ){
			warn("addr_cmp: undef input (1)\n");
			RETVAL = &PL_sv_undef;
		}else if( !SvOK(SvB) ){
			warn("addr_cmp: undef input (2)\n");
			RETVAL = &PL_sv_undef;
		}else{
			/* A: SV -> string */
			StrA = (char *) SvPV(SvA, len);
			/* A: string -> struct addr */
			if( addr_aton(StrA, &SadA) < 0 ){
				warn("addr_cmp: addr_aton: error (1)\n");
				RETVAL = &PL_sv_undef; 
			}else{
				/* B: SV -> string */
				StrB = (char *) SvPV(SvB, len);
				/* B: string -> struct addr */
				if( addr_aton(StrB, &SadB) < 0 ){
					warn("addr_cmp: addr_aton: error (2)\n");
					RETVAL = &PL_sv_undef; 
				}else{
					/* compute output */
					RETVAL = newSVnv((double) addr_cmp(&SadA, &SadB));
				}
			}
		}
	OUTPUT:
	RETVAL

SV *
_obsolete_addr_bcast(SvAd)
		SV *SvAd;
	PROTOTYPE: $
	CODE:
		char *StrAd;
		struct addr SadAd, SadBc;
		int len;

		/* check input */
		if( !SvOK(SvAd) ){
			warn("addr_bcast: undef input\n");
			RETVAL = &PL_sv_undef;
		}else{
			/* address: SV -> string */
			StrAd = (char *) SvPV(SvAd, len);
			/* address: string -> struct addr */
			if( addr_aton(StrAd, &SadAd) < 0 ){
				warn("addr_bcast: addr_aton: error\n");
				RETVAL = &PL_sv_undef; 
			/* compute output */
			}else if( addr_bcast(&SadAd, &SadBc) < 0 ){
				warn("addr_bcast: error\n");
				RETVAL = &PL_sv_undef;	
			}else{
				/* broadcast: struct addr -> SV */
				if( (StrAd = addr_ntoa((struct addr *) &SadBc)) == NULL){
					warn("addr_bcast: addr_ntoa: error\n");
					RETVAL = &PL_sv_undef;
				}else{
					/* 0 means Perl does strlen() itself */
					RETVAL = newSVpv(StrAd, 0);
				}
			}
		}
	OUTPUT:
	RETVAL

SV *
_obsolete_addr_net(SvAd)
		SV *SvAd;
	PROTOTYPE: $
	CODE:
		char *StrAd;
		struct addr SadAd, SadBc;
		int len;

		/* check input */
		if( !SvOK(SvAd) ){
			warn("addr_net: undef input\n");
			RETVAL = &PL_sv_undef;
		}else{
			/* address: SV -> string */
			StrAd = (char *) SvPV(SvAd, len);
			/* address: string -> struct addr */
			if( addr_aton(StrAd, &SadAd) < 0 ){
				warn("addr_net: addr_aton: error\n");
				RETVAL = &PL_sv_undef; 
			/* compute output */
			}else if( addr_net(&SadAd, &SadBc) < 0 ){
				warn("addr_net: error\n");
				RETVAL = &PL_sv_undef;	
			}else{
				/* broadcast: struct addr -> SV */
				if( (StrAd = addr_ntoa((struct addr *) &SadBc)) == NULL){
					warn("addr_net: addr_ntoa: error\n");
					RETVAL = &PL_sv_undef;
				}else{
					/* 0 means Perl does strlen() itself */
					RETVAL = newSVpv(StrAd, 0);
				}
			}
		}
	OUTPUT:
	RETVAL

SV*
_obsolete_arp_add(SvProtoAddr, SvHwAddr)
		SV *SvProtoAddr;
		SV *SvHwAddr;
	PROTOTYPE: $$
	CODE:
		arp_t *AtArp;
		struct arp_entry SarEntry;
		struct addr SadAddr;
		char *StrAddr;
		int len;

		/* check input */
		if( !SvOK(SvProtoAddr) ){
			warn("arp_add: undef input(1)\n");
			RETVAL = &PL_sv_undef;
		}else if( !SvOK(SvHwAddr) ){
			warn("arp_add: undef input(2)\n");
			RETVAL = &PL_sv_undef;
		}else{
			/* open arp handler */
			if( (AtArp = arp_open()) == NULL ){
				warn("arp_add: arp_open: error\n");
				RETVAL = &PL_sv_undef;
			}else{

				/* protocol address: SV -> string  */
				StrAddr = (char *) SvPV(SvProtoAddr, len);

				/* protocol address: string -> struct addr */
				if( addr_aton(StrAddr, &SadAddr) < 0 ){
					warn("arp_add: addr_aton: error (1)\n");
					RETVAL = &PL_sv_undef;
				}else{
					/* protocol address -> arp_entry */
					memcpy(&SarEntry.arp_pa, &SadAddr, sizeof(struct addr));

					/* hardware address: SV -> string  */
					StrAddr = (char *) SvPV(SvHwAddr, len);

					/* hardware address: string -> struct addr */
					if( addr_aton(StrAddr, &SadAddr) < 0 ){
						warn("arp_add: addr_aton: error (2)\n");
						RETVAL = &PL_sv_undef;
					}else{
						memcpy(&SarEntry.arp_ha, &SadAddr, sizeof(struct addr));

						/* add to ARP table */
						if( arp_add(AtArp, &SarEntry) < 0 ){
							warn("arp_add: error\n");
							RETVAL = &PL_sv_undef;
						}else{
							RETVAL = newSVnv(1);
						}
					}
				}

				/* close arp handler */
				arp_close(AtArp);
			}
		}
	OUTPUT:
	RETVAL

SV*
_obsolete_arp_delete(SvProtoAddr)
		SV *SvProtoAddr;
	PROTOTYPE: $
	CODE:
		arp_t *AtArp;
		struct arp_entry SarEntry;
		struct addr SadAddr;
		char *StrAddr;
		int len;

		/* check input */
		if( !SvOK(SvProtoAddr) ){
			warn("arp_delete: undef input\n");
			RETVAL = &PL_sv_undef;
		}else{
			/* open arp handler */
			if( (AtArp = arp_open()) == NULL ){
				warn("arp_get: arp_open: error\n");
				RETVAL = &PL_sv_undef;
			}else{

				/* convert input to string */
				StrAddr = (char *) SvPV(SvProtoAddr, len);

				/* convert input to struct addr */
				if( addr_aton(StrAddr, &SadAddr) < 0 ){
					warn("arp_delete: addr_aton: error\n");
					RETVAL = &PL_sv_undef;
				}else{
					memcpy(&SarEntry.arp_pa, &SadAddr, sizeof(struct addr));

					/* resolve protocol address with arp */
					if( arp_delete(AtArp, &SarEntry) < 0 ){
						/* do not warn: a request for a nonexistant address is valid */
						RETVAL = &PL_sv_undef;
					}else{
						RETVAL = newSVnv(1);
					}

				}

				/* close arp handler */
				arp_close(AtArp);
			}
		}
	OUTPUT:
	RETVAL

SV*
_obsolete_arp_get(SvProtoAddr)
		SV *SvProtoAddr;
	PROTOTYPE: $
	CODE:
		arp_t *AtArp;
		struct arp_entry SarEntry;
		struct addr SadAddr;
		char *StrAddr;
		int len;

		/* check input */
		if( !SvOK(SvProtoAddr) ){
			warn("arp_get: undef input\n");
			RETVAL = &PL_sv_undef;
		}else{
			/* open arp handler */
			if( (AtArp = arp_open()) == NULL ){
				warn("arp_get: arp_open: error\n");
				RETVAL = &PL_sv_undef;
			}else{

				/* convert input to string */
				StrAddr = (char *) SvPV(SvProtoAddr, len);

				/* convert input to struct addr */
				if( addr_aton(StrAddr, &SadAddr) < 0 ){
					warn("arp_get: addr_aton: error\n");
					RETVAL = &PL_sv_undef;
				}else{
					memcpy(&SarEntry.arp_pa, &SadAddr, sizeof(struct addr));

					/* resolve protocol address with arp */
					if( arp_get(AtArp, &SarEntry) < 0 ){
						/* do not warn: a request for a nonexistant address is valid */
						RETVAL = &PL_sv_undef;
					}else{

						/* convert output to string */
						if( (StrAddr = addr_ntoa( (struct addr *) &SarEntry.arp_ha)) == NULL){
							warn("arp_get: addr_ntoa: error\n");
							RETVAL = &PL_sv_undef;
						}else{
							/* 0 means Perl does strlen() itself */
							RETVAL = newSVpv(StrAddr, 0);
						}
					}
				}

				/* close arp handler */
				arp_close(AtArp);
			}
		}
	OUTPUT:
	RETVAL

HV *
_obsolete_intf_get(SvName)
		SV *SvName;
	PROTOTYPE: $
	CODE:
		HV *HvUndef;
		intf_t *ItIntf;
		struct intf_entry SieEntry;
		char *StrName;
		int len;

		/* prepare undefined hash */
		HvUndef = newHV();
		hv_undef(HvUndef);

		/* check input */
		if( !SvOK(SvName) ){
			warn("intf_get: undef input\n");
			RETVAL = HvUndef;
		}else{
			/* open intf handler */
			if( (ItIntf = intf_open()) == NULL ){
				warn("intf_get: intf_open: error\n");
				RETVAL = HvUndef;
			}else{
				/* name: SV -> string */
				StrName = (char *) SvPV(SvName, len);

				/* request interface */
				SieEntry.intf_len = sizeof(SieEntry);
				strncpy(SieEntry.intf_name, StrName, INTF_NAME_LEN);
				if( intf_get(ItIntf, &SieEntry) < 0 ){
					/* cannot warn, since the name may not exist */
					RETVAL = HvUndef;
				}else{
					RETVAL = intf2hash(&SieEntry);
				}

				/* close intf handler */
				intf_close(ItIntf);
			}
		}
	OUTPUT:
	RETVAL

HV *
_obsolete_intf_get_src(SvAddr)
		SV *SvAddr;
	PROTOTYPE: $
	CODE:
		HV *HvUndef;
		intf_t *ItIntf;
		struct intf_entry SieEntry;
		struct addr SaAddr;
		char *StrAddr;
		int len;

		/* prepare undefined hash */
		HvUndef = newHV();
		hv_undef(HvUndef);

		/* check input */
		if( !SvOK(SvAddr) ){
			warn("intf_get_src: undef input\n");
			RETVAL = HvUndef;
		}else{
			/* open intf handler */
			if( (ItIntf = intf_open()) == NULL ){
				warn("intf_get_src: intf_open: error\n");
				RETVAL = HvUndef;
			}else{
				/* addr: SV -> string */
				StrAddr = (char *) SvPV(SvAddr, len);

				/* addr: string -> struct addr */
				if( addr_aton(StrAddr, &SaAddr) < 0 ){
					warn("intf_get_src: addr_aton: error\n");
					RETVAL = HvUndef;
				}else{
					/* request interface */
					SieEntry.intf_len = sizeof(SieEntry);
					if( intf_get_src(ItIntf, &SieEntry, &SaAddr) < 0 ){
						/* cannot warn, since the name may not exist */
						RETVAL = HvUndef;
					}else{
						RETVAL = intf2hash(&SieEntry);
					}
				}

				/* close intf handler */
				intf_close(ItIntf);
			}
		}
	OUTPUT:
	RETVAL

HV *
_obsolete_intf_get_dst(SvAddr)
		SV *SvAddr;
	PROTOTYPE: $
	CODE:
		HV *HvUndef;
		intf_t *ItIntf;
		struct intf_entry SieEntry;
		struct addr SaAddr;
		char *StrAddr;
		int len;

		/* prepare undefined hash */
		HvUndef = newHV();
		hv_undef(HvUndef);

		/* check input */
		if( !SvOK(SvAddr) ){
			warn("intf_get_dst: undef input\n");
			RETVAL = HvUndef;
		}else{
			/* open intf handler */
			if( (ItIntf = intf_open()) == NULL ){
				warn("intf_get_dst: intf_open: error\n");
				RETVAL = HvUndef;
			}else{
				/* addr: SV -> string */
				StrAddr = (char *) SvPV(SvAddr, len);

				/* addr: string -> struct addr */
				if( addr_aton(StrAddr, &SaAddr) < 0 ){
					warn("intf_get_dst: addr_aton: error\n");
					RETVAL = HvUndef;
				}else{
					/* request interface */
					SieEntry.intf_len = sizeof(SieEntry);
					if( intf_get_dst(ItIntf, &SieEntry, &SaAddr) < 0 ){
						/* cannot warn, since the name may not exist */
						RETVAL = HvUndef;
					}else{
						RETVAL = intf2hash(&SieEntry);
					}
				}

				/* close intf handler */
				intf_close(ItIntf);
			}
		}
	OUTPUT:
	RETVAL

SV*
_obsolete_route_add(SvDstAddr, SvGwAddr)
		SV *SvDstAddr;
		SV *SvGwAddr;
	PROTOTYPE: $$
	CODE:
		route_t *RtRoute;
		struct route_entry SrtEntry;
		struct addr SadAddr;
		char *StrAddr;
		int len;

		/* check input */
		if( !SvOK(SvDstAddr) ){
			warn("route_add: undef input(1)\n");
			RETVAL = &PL_sv_undef;
		}else if( !SvOK(SvGwAddr) ){
			warn("route_add: undef input(2)\n");
			RETVAL = &PL_sv_undef;
		}else{
			/* open route handler */
			if( (RtRoute = route_open()) == NULL ){
				warn("route_add: route_open: error\n");
				RETVAL = &PL_sv_undef;
			}else{

				/* destination address: SV -> string  */
				StrAddr = (char *) SvPV(SvDstAddr, len);

				/* destination address: string -> struct addr */
				if( addr_aton(StrAddr, &SadAddr) < 0 ){
					warn("route_add: addr_aton: error (1)\n");
					RETVAL = &PL_sv_undef;
				}else{
					/* destination address -> route_entry */
					memcpy(&SrtEntry.route_dst, &SadAddr, sizeof(struct addr));

					/* gateway address: SV -> string  */
					StrAddr = (char *) SvPV(SvGwAddr, len);

					/* gateway address: string -> struct addr */
					if( addr_aton(StrAddr, &SadAddr) < 0 ){
						warn("route_add: addr_aton: error (2)\n");
						RETVAL = &PL_sv_undef;
					}else{
						memcpy(&SrtEntry.route_gw, &SadAddr, sizeof(struct addr));

						/* add to route table */
						if( route_add(RtRoute, &SrtEntry) < 0 ){
							warn("route_add: error\n");
							RETVAL = &PL_sv_undef;
						}else{
							RETVAL = newSVnv(1);
						}
					}
				}

				/* close route handler */
				route_close(RtRoute);
			}
		}
	OUTPUT:
	RETVAL

SV*
_obsolete_route_delete(SvDstAddr)
		SV *SvDstAddr;
	PROTOTYPE: $
	CODE:
		route_t *RtRoute;
		struct route_entry SrtEntry;
		struct addr SadAddr;
		char *StrAddr;
		int len;

		/* check input */
		if( !SvOK(SvDstAddr) ){
			warn("route_delete: undef input\n");
			RETVAL = &PL_sv_undef;
		}else{
			/* open route handler */
			if( (RtRoute = route_open()) == NULL ){
				warn("route_get: route_open: error\n");
				RETVAL = &PL_sv_undef;
			}else{

				/* convert input to string */
				StrAddr = (char *) SvPV(SvDstAddr, len);

				/* convert input to struct addr */
				if( addr_aton(StrAddr, &SadAddr) < 0 ){
					warn("route_delete: addr_aton: error\n");
					RETVAL = &PL_sv_undef;
				}else{
					memcpy(&SrtEntry.route_dst, &SadAddr, sizeof(struct addr));

					/* remove route */
					if( route_delete(RtRoute, &SrtEntry) < 0 ){
						/* do not warn: a request for a nonexistant address is valid */
						RETVAL = &PL_sv_undef;
					}else{
						RETVAL = newSVnv(1);
					}

				}

				/* close route handler */
				route_close(RtRoute);
			}
		}
	OUTPUT:
	RETVAL

SV*
_obsolete_route_get(SvDstAddr)
		SV *SvDstAddr;
	PROTOTYPE: $
	CODE:
		route_t *RtRoute;
		struct route_entry SrtEntry;
		struct addr SadAddr;
		char *StrAddr;
		int len;

		/* check input */
		if( !SvOK(SvDstAddr) ){
			warn("route_get: undef input\n");
			RETVAL = &PL_sv_undef;
		}else{
			/* open route handler */
			if( (RtRoute = route_open()) == NULL ){
				warn("route_get: route_open: error\n");
				RETVAL = &PL_sv_undef;
			}else{

				/* convert input to string */
				StrAddr = (char *) SvPV(SvDstAddr, len);

				/* convert input to struct addr */
				if( addr_aton(StrAddr, &SadAddr) < 0 ){
					warn("route_get: addr_aton: error\n");
					RETVAL = &PL_sv_undef;
				}else{
					memcpy(&SrtEntry.route_dst, &SadAddr, sizeof(struct addr));

					/* resolve protocol address with route */
					if( route_get(RtRoute, &SrtEntry) < 0 ){
						/* do not warn: a request for a nonexistant address is valid */
						RETVAL = &PL_sv_undef;
					}else{

						/* convert output to string */
						if( (StrAddr = addr_ntoa( (struct addr *) &SrtEntry.route_gw)) == NULL){
							warn("route_get: addr_ntoa: error\n");
							RETVAL = &PL_sv_undef;
						}else{
							/* 0 means Perl does strlen() itself */
							RETVAL = newSVpv(StrAddr, 0);
						}
					}
				}

				/* close route handler */
				route_close(RtRoute);
			}
		}
	OUTPUT:
	RETVAL

#
# The following are the new XS implementation.
# I prefixed with dnet_ in order to not clash with libdnet C functions used by 
# obsolete XS implementation.
#

#if defined DNET_INTF_H

IntfHandle *
dnet_intf_open()
   CODE:
      RETVAL = intf_open();
   OUTPUT:
      RETVAL

SV *
dnet_intf_get(handle, entry)
      IntfHandle *handle
      SV         *entry
   PREINIT:
      char        buf[1024];
      IntfEntry  *intfEntry;
      IntfEntry  *intfEntryPtr;
   INIT:
      intfEntry    = (IntfEntry *)buf;
      intfEntryPtr = NULL;
      memset(buf, 0, sizeof(buf));
      intfEntryPtr = intf_sv2c(entry, intfEntry);
      intfEntry->intf_len = sizeof(buf);
   CODE:
      if (intf_get(handle, intfEntryPtr) == -1) { XSRETURN_UNDEF; }
      else { RETVAL = intf_c2sv(intfEntry); }
   OUTPUT:
      RETVAL

SV *
dnet_intf_get_src(handle, src)
      IntfHandle *handle
      SV         *src
   PREINIT:
      char        buf[1024];
      IntfEntry  *intfEntry; 
      struct addr aSrc;
      int ret;
   INIT:
      intfEntry = (IntfEntry *)buf;
      memset(buf, 0, sizeof(buf));
      intfEntry->intf_len = sizeof(buf);
      memset(&aSrc, 0, sizeof(struct addr));
      ret = addr_aton(SvPV(src, PL_na), &aSrc);
   CODE:
      if (! ret && intf_get_src(handle, intfEntry, &aSrc) == -1) {
         XSRETURN_UNDEF;
      }
      else { RETVAL = intf_c2sv(intfEntry); }
   OUTPUT:
      RETVAL

SV *
dnet_intf_get_dst(handle, dst)
      IntfHandle *handle
      SV         *dst
   PREINIT:
      char        buf[1024];
      struct addr aDst;
      int ret;
      IntfEntry  *intfEntry;
   INIT:
      intfEntry = (IntfEntry *)buf;
      memset(buf, 0, sizeof(buf));
      intfEntry->intf_len = sizeof(buf);
      memset(&aDst, 0, sizeof(struct addr));
      ret = addr_aton(SvPV(dst, PL_na), &aDst);
   CODE:
      if (! ret && intf_get_dst(handle, intfEntry, &aDst) == -1) {
         XSRETURN_UNDEF;
      }
      else { RETVAL = intf_c2sv(intfEntry); }
   OUTPUT:
      RETVAL

int
dnet_intf_set(handle, entry)
      IntfHandle *handle
      SV         *entry
   PREINIT:
         IntfEntry *intfEntryPtr;
      IntfEntry  intfEntry;
   INIT:
      intfEntryPtr = NULL;
      intfEntryPtr = intf_sv2c(entry, &intfEntry);
   CODE:
      if (intf_set(handle, &intfEntry) == -1) { XSRETURN_UNDEF; }
      else { RETVAL = 1; }
   OUTPUT:
      RETVAL

int
dnet_intf_loop(handle, callback, data)
      IntfHandle *handle
      SV         *callback
      SV         *data
   CODE:
      if (keepSub == (SV *)NULL)
         keepSub = newSVsv(callback);
      else
         SvSetSV(keepSub, callback);
      RETVAL = intf_loop(handle, (intf_handler)intf_callback, data);
   OUTPUT:
      RETVAL

IntfHandle *
dnet_intf_close(handle)
      IntfHandle *handle
   CODE:
      RETVAL = intf_close(handle);
   OUTPUT:
      RETVAL

#endif

#if defined DNET_ARP_H

ArpHandle *
dnet_arp_open()
   CODE:
      RETVAL = arp_open();
   OUTPUT:
      RETVAL

int
dnet_arp_add(handle, entry)
      ArpHandle *handle
      SV        *entry
   PREINIT:
      ArpEntry  arpEntry;
      ArpEntry *arpEntryPtr;
   INIT:
      arpEntryPtr = NULL;
      arpEntryPtr = arp_sv2c(entry, &arpEntry);
   CODE:
      RETVAL = arp_add(handle, arpEntryPtr);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
      else { RETVAL = 1; }
   OUTPUT:
      RETVAL

int
dnet_arp_delete(handle, entry)
      ArpHandle *handle
      SV        *entry
   PREINIT:
      ArpEntry  arpEntry;
      ArpEntry *arpEntryPtr;
   INIT:
      arpEntryPtr = NULL;
      arpEntryPtr = arp_sv2c(entry, &arpEntry);
   CODE:
      RETVAL = arp_delete(handle, arpEntryPtr);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
      else { RETVAL = 1; }
   OUTPUT:
      RETVAL

SV *
dnet_arp_get(handle, entry)
      ArpHandle *handle
      SV        *entry
   PREINIT:
      ArpEntry *arpEntryPtr;
      ArpEntry  arpEntry;
   INIT:
      arpEntryPtr = NULL;
      arpEntryPtr = arp_sv2c(entry, &arpEntry);
   CODE:
      if (arp_get(handle, arpEntryPtr) == -1) { XSRETURN_UNDEF; }
      else { RETVAL = arp_c2sv(arpEntryPtr); }
   OUTPUT:
      RETVAL 

int
dnet_arp_loop(handle, callback, data)
      ArpHandle *handle
      SV        *callback
      SV        *data
   CODE:
      if (keepSub == (SV *)NULL)
         keepSub = newSVsv(callback);
      else
         SvSetSV(keepSub, callback);
      RETVAL = arp_loop(handle, (arp_handler)arp_callback, data);
   OUTPUT:
      RETVAL

ArpHandle *
dnet_arp_close(handle)
      ArpHandle *handle
   CODE:
      RETVAL = arp_close(handle);
   OUTPUT:
      RETVAL

#endif

#if defined DNET_ROUTE_H

RouteHandle *
dnet_route_open()
   CODE:
      RETVAL = route_open();
   OUTPUT:
      RETVAL

int
dnet_route_add(handle, entry)
      RouteHandle *handle
      SV          *entry
   PREINIT:
      RouteEntry  routeEntry;
      RouteEntry *routeEntryPtr;
   INIT:
      routeEntryPtr = NULL;
      routeEntryPtr = route_sv2c(entry, &routeEntry);
   CODE:
      RETVAL = route_add(handle, routeEntryPtr);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
      else { RETVAL = 1; }
   OUTPUT:
      RETVAL

int
dnet_route_delete(handle, entry)
      RouteHandle *handle
      SV          *entry
   PREINIT:
      RouteEntry  routeEntry;
      RouteEntry *routeEntryPtr;
   INIT:
      routeEntryPtr = NULL;
      routeEntryPtr = route_sv2c(entry, &routeEntry);
   CODE:
      RETVAL = route_delete(handle, routeEntryPtr);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
      else { RETVAL = 1; }
   OUTPUT:
      RETVAL

SV *
dnet_route_get(handle, entry)
      RouteHandle *handle
      SV          *entry
   PREINIT:
      RouteEntry  routeEntry;
      RouteEntry *routeEntryPtr;
   INIT:
      routeEntryPtr = NULL;
      routeEntryPtr = route_sv2c(entry, &routeEntry);
   CODE:
      if (route_get(handle, routeEntryPtr) == -1) { XSRETURN_UNDEF; }
      else { RETVAL = route_c2sv(routeEntryPtr); }
   OUTPUT:
      RETVAL 

int
dnet_route_loop(handle, callback, data)
      RouteHandle *handle
      SV          *callback
      SV          *data
   CODE:
      if (keepSub == (SV *)NULL)
         keepSub = newSVsv(callback);
      else
         SvSetSV(keepSub, callback);
      RETVAL = route_loop(handle, (route_handler)route_callback, data);
      //printf("RETVAL: %d\n", RETVAL);
   OUTPUT:
      RETVAL

RouteHandle *
dnet_route_close(handle)
      RouteHandle *handle
   CODE:
      RETVAL = route_close(handle);
   OUTPUT:
      RETVAL

#endif

#if defined DNET_FW_H

FwHandle *
dnet_fw_open()
   CODE:
      RETVAL = fw_open();
   OUTPUT:
      RETVAL

int
dnet_fw_add(handle, rule)
      FwHandle *handle
      SV       *rule
   PREINIT:
      FwRule  fwRule;
      FwRule *fwRulePtr;
   INIT:
      fwRulePtr = NULL;
      fwRulePtr = fw_sv2c(rule, &fwRule);
   CODE:
      RETVAL = fw_add(handle, fwRulePtr);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
      else { RETVAL = 1; }
   OUTPUT:
      RETVAL

int
dnet_fw_delete(handle, rule)
      FwHandle *handle
      SV       *rule
   PREINIT:
      FwRule  fwRule;
      FwRule *fwRulePtr;
   INIT:
      fwRulePtr = NULL;
      fwRulePtr = fw_sv2c(rule, &fwRule);
   CODE:
      RETVAL = fw_delete(handle, fwRulePtr);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
      else { RETVAL = 1; }
   OUTPUT:
      RETVAL

int
dnet_fw_loop(handle, callback, data)
      FwHandle *handle
      SV       *callback
      SV       *data
   CODE:
      if (keepSub == (SV *)NULL)
         keepSub = newSVsv(callback);
      else
         SvSetSV(keepSub, callback);
      RETVAL = fw_loop(handle, (fw_handler)fw_callback, data);
   OUTPUT:
      RETVAL

FwHandle *
dnet_fw_close(handle)
      FwHandle *handle
   CODE:
      RETVAL = fw_close(handle);
   OUTPUT:
      RETVAL

#endif

#if defined DNET_TUN_H

TunHandle *
dnet_tun_open(src, dst, size)
      SV *src
      SV *dst
      int size
   INIT:
      struct addr aSrc;
      struct addr aDst;
      memset(&aSrc, 0, sizeof(struct addr));
      memset(&aDst, 0, sizeof(struct addr));
   CODE:
      if (addr_aton(SvPV(src, PL_na), &aSrc)) { XSRETURN_UNDEF; }
      if (addr_aton(SvPV(dst, PL_na), &aDst)) { XSRETURN_UNDEF; }
      RETVAL = tun_open(&aSrc, &aDst, size);
   OUTPUT:
      RETVAL

int
dnet_tun_fileno(handle)
      TunHandle *handle
   CODE:
      RETVAL = tun_fileno(handle);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
   OUTPUT:
      RETVAL

const char *
dnet_tun_name(handle)
      TunHandle *handle
   CODE:
      RETVAL = tun_name(handle);
      if (RETVAL == NULL) { XSRETURN_UNDEF; }
   OUTPUT:
      RETVAL

int
dnet_tun_send(handle, buf, size)
      TunHandle *handle
      SV        *buf
      int        size
   CODE:
      RETVAL = tun_send(handle, SvPV(buf, PL_na), size);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
   OUTPUT:
      RETVAL

SV *
dnet_tun_recv(handle, size)
      TunHandle *handle
      int        size
   PREINIT:
      int read;
      unsigned char buf[size+1];
   INIT:
      memset(buf, 0, size+1);
   CODE:
      if ((read = tun_recv(handle, buf, size)) > 0) {
         RETVAL = newSVpv(buf, read);
      }
      else { XSRETURN_UNDEF; }
   OUTPUT:
      RETVAL

TunHandle *
dnet_tun_close(handle)
      TunHandle *handle
   CODE:
      RETVAL = tun_close(handle);
   OUTPUT:
      RETVAL

#endif

#if defined DNET_ETH_H

EthHandle *
dnet_eth_open(device)
      SV *device
   CODE:
      RETVAL = eth_open(SvPV(device, PL_na));
   OUTPUT:
      RETVAL

SV *
dnet_eth_get(handle)
      EthHandle *handle
   PREINIT:
      char *addr;
      EthAddr a;
   INIT:
      memset(&a, 0, sizeof(EthAddr));
   CODE:
      if (eth_get(handle, &a) == -1)     { XSRETURN_UNDEF; }
      if ((addr = eth_ntoa(&a)) == NULL) { XSRETURN_UNDEF; }
      else { RETVAL = newSVpv(addr, 0); }
   OUTPUT:
      RETVAL

int
dnet_eth_set(handle, addr)
      EthHandle *handle
      SV        *addr
   CODE:
      RETVAL = eth_set(handle, (const EthAddr *)SvPV(addr, PL_na));
      if (RETVAL == -1) { XSRETURN_UNDEF; }
   OUTPUT:
      RETVAL

int
dnet_eth_send(handle, buf, size)
      EthHandle *handle
      SV        *buf
      int        size
   CODE:
      RETVAL = eth_send(handle, SvPV(buf, PL_na), size);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
   OUTPUT:
      RETVAL

EthHandle *
dnet_eth_close(handle)
      EthHandle *handle
   CODE:
      RETVAL = eth_close(handle);
   OUTPUT:
      RETVAL

#endif

#if defined DNET_IP_H

IpHandle *
dnet_ip_open()
   CODE:
      RETVAL = ip_open();
   OUTPUT:
      RETVAL

int
dnet_ip_send(handle, buf, size)
      IpHandle *handle
      SV       *buf
      int       size
   CODE:
      RETVAL = ip_send(handle, SvPV(buf, PL_na), size);
      if (RETVAL == -1) { XSRETURN_UNDEF; }
   OUTPUT:
      RETVAL

void
dnet_ip_checksum(buf, size)
      SV *buf
      int size
   CODE:
      ip_checksum(SvPV(buf, PL_na), size);

IpHandle *
dnet_ip_close(handle)
      IpHandle *handle
   CODE:
      RETVAL = ip_close(handle);
   OUTPUT:
      RETVAL

#endif
