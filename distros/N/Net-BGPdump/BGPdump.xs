/*
** Use of the Net-BGPdump library and related source code is subject to
** the terms of the following licenses:
** 
** GNU Public License (GPL) Rights pursuant to Version 2, June 1991
** Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
** 
** NO WARRANTY
** 
** ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER 
** PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY 
** PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN 
** "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY 
** KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT 
** LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE, 
** MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE 
** OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT, 
** SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY 
** TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF 
** WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES. 
** LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF 
** CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON 
** CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE 
** DELIVERABLES UNDER THIS LICENSE.
** 
** Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie 
** Mellon University, its trustees, officers, employees, and agents from 
** all claims or demands made against them (and any related losses, 
** expenses, or attorney's fees) arising out of, or relating to Licensee's 
** and/or its sub licensees' negligent use or willful misuse of or 
** negligent conduct or willful misconduct regarding the Software, 
** facilities, or other rights or assistance granted by Carnegie Mellon 
** University under this License, including, but not limited to, any 
** claims of product liability, personal injury, death, damage to 
** property, or violation of any laws or regulations.
** 
** Carnegie Mellon University Software Engineering Institute authored 
** documents are sponsored by the U.S. Department of Defense under 
** Contract FA8721-05-C-0003. Carnegie Mellon University retains 
** copyrights in all material produced under this contract. The U.S. 
** Government retains a non-exclusive, royalty-free license to publish or 
** reproduce these documents, or allow others to do so, for U.S. 
** Government purposes only pursuant to the copyright license under the 
** contract clause at 252.227.7013.
*/

#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "cfile_tools.h"
#include "bgpdump_lib.h"

#ifdef __cplusplus
}
#endif

typedef BGPDUMP *Net__BGPdump;

// from libbgpdump util.h/inet_ntop.c
char *fmt_ipv6(BGPDUMP_IP_ADDRESS addr, char *buffer);
char *fmt_ipv4(BGPDUMP_IP_ADDRESS addr, char *buffer);

const char *bgp_state_name[] = {
    "Unknown",
    "Idle",
    "Connect",
    "Active",
    "Opensent",
    "Openconfirm",
    "Established",
    NULL
};

static void
_xs_add_prefixes(pTHX_ int count, struct prefix *prefix, AV *av) {
    char cdr[BGPDUMP_ADDRSTRLEN + 3];
    int i;
    for (i = 0; i < count; i++) {
        sprintf(cdr, "%s/%d", inet_ntoa(prefix[i].address.v4_addr),
                prefix[i].len);
        av_push(av, newSVpv(cdr, 0));
    }
}

#ifdef BGPDUMP_HAVE_IPV6
static void
_xs_add_prefixes6(pTHX_ int count, struct prefix *prefix, AV *av) {
    char buf[128];
    char cdr[128 + 4];
    int i;
    for (i = 0; i < count; i++) {
        sprintf(cdr, "%s/%d", fmt_ipv6(prefix[i].address, buf),
                prefix[i].len);
        av_push(av, newSVpv(cdr, 0));
    }
}
#endif

static SV *
_xs_zebra_source_ip(pTHX_ BGPDUMP_ENTRY *entry) {
    SV *sv;
    char pfx[BGPDUMP_ADDRSTRLEN];
    switch(entry->body.zebra_message.address_family)
    {
#ifdef BGPDUMP_HAVE_IPV6
        case AFI_IP6:
            sv = newSVpv(fmt_ipv6(entry->body.zebra_message.source_ip, pfx), 0);
            break;
#endif
        case AFI_IP:
        default:
            if (entry->body.zebra_message.source_ip.v4_addr.s_addr != 0x00000000L)
                sv = newSVpv(inet_ntoa(entry->body.zebra_message.source_ip.v4_addr), 0);
            else
                sv = newSV(0);
    }
    return sv;
}

static SV *
_xs_zebra_dest_ip(pTHX_ BGPDUMP_ENTRY *entry) {
    SV *sv;
    char pfx[BGPDUMP_ADDRSTRLEN];
    switch(entry->body.zebra_message.address_family)
    {
#ifdef BGPDUMP_HAVE_IPV6
        case AFI_IP6:
            sv = newSVpv(fmt_ipv6(entry->body.zebra_message.destination_ip, pfx), 0);
            break;
#endif
        case AFI_IP:
        default:
            if (entry->body.zebra_message.destination_ip.v4_addr.s_addr != 0x00000000L)
                sv = newSVpv(inet_ntoa(entry->body.zebra_message.destination_ip.v4_addr), 0);
            else
                sv = newSV(0);
    }
    return sv;
}

static void
_xs_attr_build(pTHX_ attributes_t *attr, HV *hv) {
    AV *av;
    int i;

    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_ORIGIN) ) != 0) {
        switch (attr->origin) {
            case 0:
                hv_store(hv, "origin", 6, newSVpv("IGP", 0), 0);
                break;
            case 1:
                hv_store(hv, "origin", 6, newSVpv("EGP", 0), 0);
                break;
            case 2:
                hv_store(hv, "origin", 6, newSVpv("INCOMPLETE", 0), 0);
                break;
        }
    }
    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_AS_PATH) ) != 0)
        hv_store(hv, "as_path", 7, newSVpv(attr->aspath->str, 0), 0);
    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_NEXT_HOP) ) != 0)
        hv_store(hv, "next_hop", 8,
                 newSVpv(inet_ntoa(attr->nexthop), 0), 0);
    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_MULTI_EXIT_DISC) ) != 0)
        hv_store(hv, "multi_exit_disc", 15, newSVuv(attr->med), 0);
    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_LOCAL_PREF) ) != 0)
        hv_store(hv, "local_pref", 10, newSVuv(attr->local_pref), 0);
    if (attr->flag & ATTR_FLAG_BIT(BGP_ATTR_ATOMIC_AGGREGATE))
        hv_store(hv, "atomic_aggregate", 16, newSVuv(1), 0);
    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_AGGREGATOR) ) != 0) {
        hv_store(hv, "aggregator_as", 13, newSVuv(attr->aggregator_as), 0);
        hv_store(hv, "aggregator_addr", 15,
                 newSVpv(inet_ntoa(attr->aggregator_addr), 0), 0);
        if (!ATTR_FLAG_BIT(BGP_ATTR_ATOMIC_AGGREGATE))
            hv_store(hv, "atomic_aggregate", 16, newSVuv(0), 0);
    }
    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_ORIGINATOR_ID) ) != 0)
        hv_store(hv, "originator_id", 13,
                 newSVpv(inet_ntoa(attr->originator_id), 0), 0);
    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_CLUSTER_LIST) ) != 0) {
        av = newAV();
        for (i = 0; i < attr->cluster->length; i++) {
            av_push(av, newSVpv(inet_ntoa(attr->cluster->list[i]), 0));
        }
        hv_store(hv, "cluster_list", 12, newRV_noinc(MUTABLE_SV(av)), 0); 
    }
    if (attr->unknown_num) {
        av = newAV();
        for (i = 0; i < attr->unknown_num; i++) {
            struct unknown_attr *unk = attr->unknown + i;
            AV *ava = newAV();
            av_push(ava, newSViv(unk->flag));
            av_push(ava, newSViv(unk->type));
            av_push(ava, newSViv(unk->len));
            av_push(av, newRV_noinc(MUTABLE_SV(ava)));
        }
        hv_store(hv, "unknown_attr", 12, newRV_noinc(MUTABLE_SV(av)), 0);
    }
    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_MP_REACH_NLRI) ) != 0) {
        HV *hve = newHV();
        hv_store(hv, "mp_reach_nlri", 13, newRV_noinc(MUTABLE_SV(hve)), 0);
#ifdef BGPDUMP_HAVE_IPV6
        if (attr->mp_info->announce[AFI_IP6][SAFI_UNICAST]   ||
            attr->mp_info->announce[AFI_IP6][SAFI_MULTICAST] ||
            attr->mp_info->announce[AFI_IP6][SAFI_UNICAST_MULTICAST]) {
            char buf[128];
            if (attr->mp_info->announce[AFI_IP6][SAFI_UNICAST]) {
                hv_store(hve, "unicast", 7, newSVuv(1), 0);
                hv_store(hve, "multicast", 9, newSVuv(0), 0);
                fmt_ipv6(attr->mp_info->announce[AFI_IP6][SAFI_UNICAST]->nexthop, buf);
                hv_store(hve, "next_hop", 8, newSVpv(buf, 0), 0);
                if (attr->mp_info->announce[AFI_IP6][SAFI_UNICAST]->nexthop_len == 32) {
                    fmt_ipv6(attr->mp_info->announce[AFI_IP6][SAFI_UNICAST]->nexthop_local, buf);
                    hv_store(hve, "next_hop_local", 14, newSVpv(buf, 0), 0);
                }
            }
            else if (attr->mp_info->announce[AFI_IP6][SAFI_MULTICAST]) {
                hv_store(hve, "unicast", 7, newSVuv(0), 0);
                hv_store(hve, "multicast", 9, newSVuv(1), 0);
                fmt_ipv6(attr->mp_info->announce[AFI_IP6][SAFI_MULTICAST]->nexthop, buf);
                hv_store(hve, "next_hop", 8, newSVpv(buf, 0), 0);
                if (attr->mp_info->announce[AFI_IP6][SAFI_MULTICAST]->nexthop_len == 32) {
                    fmt_ipv6(attr->mp_info->announce[AFI_IP6][SAFI_UNICAST]->nexthop_local, buf);
                    hv_store(hve, "next_hop_local", 14, newSVpv(buf, 0), 0);
                }
            }
            else {
                hv_store(hve, "unicast", 7, newSVuv(1), 0);
                hv_store(hve, "multicast", 9, newSVuv(1), 0);
                fmt_ipv6(attr->mp_info->announce[AFI_IP6][SAFI_UNICAST_MULTICAST]->nexthop, buf);
                hv_store(hve, "next_hop", 8, newSVpv(buf, 0), 0);
                if (attr->mp_info->announce[AFI_IP6][SAFI_UNICAST_MULTICAST]->nexthop_len == 32) {
                    fmt_ipv6(attr->mp_info->announce[AFI_IP6][SAFI_UNICAST_MULTICAST]->nexthop_local, buf);
                    hv_store(hve, "next_hop_local", 14, newSVpv(buf, 0), 0);
                }
            }
        }
        else
#endif
        {
            if (attr->mp_info->announce[AFI_IP][SAFI_UNICAST]) {
                hv_store(hve, "unicast", 7, newSVuv(1), 0);
                hv_store(hve, "multicast", 9, newSVuv(0), 0);
                hv_store(hve, "next_hop", 8,
                         newSVpv(inet_ntoa(attr->mp_info->announce[AFI_IP][SAFI_UNICAST]->nexthop.v4_addr), 0), 0);
                if (attr->mp_info->announce[AFI_IP][SAFI_UNICAST]->nexthop_len == 32) {
                    hv_store(hve, "next_hop_local", 14,
                    newSVpv(inet_ntoa(attr->mp_info->announce[AFI_IP][SAFI_UNICAST]->nexthop_local.v4_addr), 0), 0);
                }
            } else if (attr->mp_info->announce[AFI_IP][SAFI_MULTICAST]) {
                hv_store(hve, "unicast", 7, newSVuv(0), 0);
                hv_store(hve, "multicast", 9, newSVuv(1), 0);
                hv_store(hve, "next_hop", 8,
                         newSVpv(inet_ntoa(attr->mp_info->announce[AFI_IP][SAFI_MULTICAST]->nexthop.v4_addr), 0), 0);
                if (attr->mp_info->announce[AFI_IP][SAFI_MULTICAST]->nexthop_len == 32) {
                    hv_store(hve, "next_hop_local", 14,
                    newSVpv(inet_ntoa(attr->mp_info->announce[AFI_IP][SAFI_MULTICAST]->nexthop_local.v4_addr), 0), 0);
                }
            }
            else {
                hv_store(hve, "unicast", 7, newSVuv(1), 0);
                hv_store(hve, "multicast", 9, newSVuv(1), 0);
                hv_store(hve, "next_hop", 8,
                         newSVpv(inet_ntoa(attr->mp_info->announce[AFI_IP][SAFI_UNICAST_MULTICAST]->nexthop.v4_addr), 0), 0);
                if (attr->mp_info->announce[AFI_IP][SAFI_UNICAST_MULTICAST]->nexthop_len == 32) {
                    hv_store(hve, "next_hop_local", 14,
                    newSVpv(inet_ntoa(attr->mp_info->announce[AFI_IP][SAFI_UNICAST_MULTICAST]->nexthop_local.v4_addr), 0), 0);
                }
            }
        }
    }
    if ((attr->flag & ATTR_FLAG_BIT(BGP_ATTR_MP_UNREACH_NLRI) ) != 0) {
        HV *hve = newHV();
        hv_store(hv, "mp_unreach_nlri", 15, newRV_noinc(MUTABLE_SV(hve)), 0);
#ifdef BGPDUMP_HAVE_IPV6
        if (attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST]   ||
            attr->mp_info->withdraw[AFI_IP6][SAFI_MULTICAST] ||
            attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST_MULTICAST]) {
            if (attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST]) {
                hv_store(hve, "unicast", 7, newSVuv(1), 0);
                hv_store(hve, "multicast", 9, newSVuv(0), 0);
            } else if (attr->mp_info->withdraw[AFI_IP6][SAFI_MULTICAST]) {
                hv_store(hve, "unicast", 7, newSVuv(0), 0);
                hv_store(hve, "multicast", 9, newSVuv(1), 0);
            }
            else {
                hv_store(hve, "unicast", 7, newSVuv(1), 0);
                hv_store(hve, "multicast", 9, newSVuv(1), 0);
            }
        }
        else
#endif
        {
            if (attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST]) {
                hv_store(hve, "unicast", 7, newSVuv(1), 0);
                hv_store(hve, "multicast", 9, newSVuv(0), 0);
            } else if (attr->mp_info->withdraw[AFI_IP][SAFI_MULTICAST]) {
                hv_store(hve, "unicast", 7, newSVuv(0), 0);
                hv_store(hve, "multicast", 9, newSVuv(1), 0);
            }
            else {
                hv_store(hve, "unicast", 7, newSVuv(1), 0);
                hv_store(hve, "multicast", 9, newSVuv(1), 0);
            }
        }
    }
    if( (attr->flag & ATTR_FLAG_BIT(BGP_ATTR_COMMUNITIES) ) != 0) {
        char *com = attr->community->str;
        if (*com == ' ')
            com += 1;
        hv_store(hv, "community", 9, newSVpv(com, 0), 0);
    }
}

static SV *
_xs_mrtd_table_dump_build(pTHX_ BGPDUMP_ENTRY *entry) {
    HV *hv;
    SV *subtype_sv;
    SV *from_sv;
    char pfx[BGPDUMP_ADDRSTRLEN];
    char cdr[BGPDUMP_ADDRSTRLEN + 3];
    const char *addr_str = NULL;

    hv = newHV();

    hv_store(hv, "time", 4, newSVuv(entry->time), 0);
    hv_store(hv, "type", 4, newSVpv("TABLE_DUMP", 0), 0);
    hv_store(hv, "type_id", 7, newSVuv(entry->type), 0);
    hv_store(hv, "subtype_id", 10, newSVuv(entry->subtype), 0);
    hv_store(hv, "route_uptime", 12,
                 newSVuv(entry->body.mrtd_table_dump.uptime), 0);
    switch(entry->subtype) {
#ifdef BGPDUMP_HAVE_IPV6
        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6:
            subtype_sv = newSVpv("INET6", 0);
            addr_str = fmt_ipv6(entry->body.mrtd_table_dump.prefix, pfx);
        break;
        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6_32BIT_AS:
            subtype_sv = newSVpv("INET6_32BIT_AS", 0);
            addr_str = fmt_ipv6(entry->body.mrtd_table_dump.prefix, pfx);
        break;
#endif
        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP:
            subtype_sv = newSVpv("INET", 0);
            addr_str = inet_ntoa(entry->body.mrtd_table_dump.prefix.v4_addr);
        break;
        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP_32BIT_AS:
            subtype_sv = newSVpv("INET_32BIT_AS", 0);
            addr_str = inet_ntoa(entry->body.mrtd_table_dump.prefix.v4_addr);
        break;
        default:
            warn("error: unknown table type %d\n", entry->subtype);
            return newRV_noinc(MUTABLE_SV(hv));
    }
    sprintf(cdr, "%s/%d", pfx, entry->body.mrtd_table_dump.mask);
    hv_store(hv, "prefix", 6, newSVpv(cdr, 0), 0);
    hv_store(hv, "subtype", 7, subtype_sv, 0);
    hv_store(hv, "view", 4, newSVuv(entry->body.mrtd_table_dump.view), 0);
    hv_store(hv, "sequence", 8,
             newSVuv(entry->body.mrtd_table_dump.sequence), 0);
    switch(entry->subtype) {
#ifdef BGPDUMP_HAVE_IPV6
        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6:
        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6_32BIT_AS:
            fmt_ipv6(entry->body.mrtd_table_dump.peer_ip, pfx);
            from_sv = newSVpv(pfx, 0);
            break;
#endif
        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP:
        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP_32BIT_AS:
            if (entry->body.mrtd_table_dump.peer_ip.v4_addr.s_addr \
                != 0x00000000L) {
                addr_str = \
                    inet_ntoa(entry->body.mrtd_table_dump.peer_ip.v4_addr);
                from_sv = newSVpv(addr_str, 0);
            } else
                from_sv = newSV(0);
    }
    hv_store(hv, "peer_addr", 9, from_sv, 0);
    hv_store(hv, "peer_as", 7, newSVuv(entry->body.mrtd_table_dump.peer_as), 0);
    hv_store(hv, "originated", 10,
             newSVuv(entry->body.mrtd_table_dump.uptime), 0); 
    hv_store(hv, "status", 6, newSVuv(entry->body.mrtd_table_dump.status), 0);
    if (entry->attr && entry->attr->len)
        _xs_attr_build(aTHX_ entry->attr, hv);

    return newRV_noinc(MUTABLE_SV(hv));
}

static SV *
_xs_table_dump_v2_build(pTHX_ BGPDUMP_ENTRY *entry) {
    HV *hv;
    AV *av;
    HV *hve;
    char pfx[BGPDUMP_ADDRSTRLEN];
    char cdr[BGPDUMP_ADDRSTRLEN + 3];
    char peer[BGPDUMP_ADDRSTRLEN];
    SV *peer_sv;
    int i;

    hv = newHV();

    hv_store(hv, "time", 4, newSVuv(entry->time), 0);
    hv_store(hv, "type", 4, newSVpv("TABLE_DUMP_V2", 0), 0);
    hv_store(hv, "type_id", 7, newSVuv(entry->type), 0);
    hv_store(hv, "subtype_id", 10, newSVuv(entry->subtype), 0);

    BGPDUMP_TABLE_DUMP_V2_PREFIX *e;
    e = &entry->body.mrtd_table_dump_v2_prefix;
    if (e->afi == AFI_IP) {
        strncpy(pfx, inet_ntoa(e->prefix.v4_addr), BGPDUMP_ADDRSTRLEN);
#ifdef BGPDUMP_HAVE_IPV6
    }
    else if (e->afi == AFI_IP6) {
        fmt_ipv6(e->prefix, pfx);
#endif
    }
    sprintf(cdr, "%s/%d", pfx, e->prefix_length);
    hv_store(hv, "prefix", 6, newSVpv(cdr, 0), 0);
    hv_store(hv, "sequence", 8, newSViv(e->seq), 0);
    if (e->afi == AFI_IP) {
        hv_store(hv, "subtype", 7, newSVpv("IPV4_UNICAST", 0), 0);
#ifdef BGPDUMP_HAVE_IPV6
    } else if (e->afi == AFI_IP6) {
        hv_store(hv, "subtype", 7, newSVpv("IPV6_UNICAST", 0), 0);
#endif
    }
    av = newAV();
    hv_store(hv, "entries", 7, newRV_noinc(MUTABLE_SV(av)), 0);
    for (i = 0; i < e->entry_count; i++) {
        hve = newHV();
        av_push(av, newRV_noinc(MUTABLE_SV(hve)));
        if (e->entries[i].peer->afi == AFI_IP) {
            fmt_ipv4(e->entries[i].peer->peer_ip, peer);
            peer_sv = newSVpv(peer, 0);
#ifdef BGPDUMP_HAVE_IPV6
        } else if (e->entries[i].peer->afi == AFI_IP6) {
            fmt_ipv6(e->entries[i].peer->peer_ip, peer);
            peer_sv = newSVpv(peer, 0);
#endif
        } else {
            peer_sv = newSV(0);
        }
        hv_store(hve, "peer_addr", 9, peer_sv, 0);
        hv_store(hve, "peer_as", 7, newSVuv(e->entries[i].peer->peer_as), 0);
        hv_store(hve, "originated", 10,
                 newSVuv((e->entries[i]).originated_time), 0);
        if (e->entries[i].attr && e->entries[i].attr->len)
            _xs_attr_build(aTHX_ e->entries[i].attr, hve);
    }

    return newRV_noinc(MUTABLE_SV(hv));
}

static SV *
_xs_mrtd_bgp_build(pTHX_ BGPDUMP_ENTRY *entry) {
    HV *hv;

    hv = newHV();

    hv_store(hv, "time", 4, newSVuv(entry->time), 0);
    hv_store(hv, "type", 4, newSVpv("BGP", 0), 0);
    hv_store(hv, "type_id", 7, newSVuv(entry->type), 0);
    hv_store(hv, "subtype_id", 10, newSVuv(entry->subtype), 0);

    switch(entry->subtype) {
        case BGPDUMP_SUBTYPE_MRTD_BGP_UPDATE:
        case BGPDUMP_SUBTYPE_MRTD_BGP_KEEPALIVE:
            if (entry->subtype == BGPDUMP_SUBTYPE_MRTD_BGP_UPDATE)
                hv_store(hv, "subtype", 7, newSVpv("MESSAGE/Update", 0), 0);
            else
                hv_store(hv, "subtype", 7,
                         newSVpv("MESSAGE/Keepalive", 0), 0);
            if (entry->body.mrtd_message.source_as) {
                hv_store(hv, "peer_addr", 9,
                    newSVpv(inet_ntoa(
                        entry->body.mrtd_message.source_ip), 0), 0);
                hv_store(hv, "peer_as", 7,
                    newSVuv(entry->body.mrtd_message.source_as), 0);
            }
            if (entry->body.mrtd_message.destination_as) {
                hv_store(hv, "dest_addr", 9,
                    newSVpv(inet_ntoa(
                        entry->body.mrtd_message.destination_ip), 0), 0);
                hv_store(hv, "dest_as", 7,
                    newSVuv(entry->body.mrtd_message.destination_as), 0);
            }
            if (entry->attr && entry->attr->len)
                _xs_attr_build(aTHX_ entry->attr, hv);
            if (entry->body.mrtd_message.withdraw_count) {
                AV *av = newAV();
                hv_store(hv, "withdraw", 8, newRV_noinc(MUTABLE_SV(av)), 0);
                _xs_add_prefixes(aTHX_
                    entry->body.mrtd_message.withdraw_count,
                    entry->body.mrtd_message.withdraw, av);
            }
            if (entry->body.mrtd_message.announce_count) {
                AV *av = newAV();
                hv_store(hv, "announce", 8, newRV_noinc(MUTABLE_SV(av)), 0);
                _xs_add_prefixes(aTHX_
                    entry->body.mrtd_message.announce_count,
                    entry->body.mrtd_message.announce, av);
            }
            break;
        case BGPDUMP_SUBTYPE_MRTD_BGP_STATE_CHANGE:
            hv_store(hv, "subtype", 7, newSVpv("STATE_CHANGE", 0), 0);
            hv_store(hv, "peer_addr", 9,
                newSVpv(inet_ntoa(
                    entry->body.mrtd_state_change.destination_ip), 0), 0);
            hv_store(hv, "peer_as", 7,
                newSVuv(entry->body.mrtd_state_change.destination_as), 0);
            hv_store(hv, "old_state", 9, newSVuv(
                entry->body.mrtd_state_change.old_state), 0);
            hv_store(hv, "new_state", 9, newSVuv(
                entry->body.mrtd_state_change.new_state), 0);
            hv_store(hv, "old_state_name", 14, newSVpv(
                bgp_state_name[entry->body.mrtd_state_change.old_state], 0), 0);
            hv_store(hv, "new_state_name", 14, newSVpv(
                bgp_state_name[entry->body.mrtd_state_change.new_state], 0), 0);
            break;
        default:
            warn("TYPE: Subtype %d not supported yet\n", entry->subtype);
    }

    return newRV_noinc(MUTABLE_SV(hv));
}
    
static SV *
_xs_zebra_bgp_build(pTHX_ BGPDUMP_ENTRY *entry) {
    HV *hv;
    SV *addr_sv;
    char pfx[BGPDUMP_ADDRSTRLEN];

    hv = newHV();

    hv_store(hv, "time", 4, newSVuv(entry->time), 0);
    hv_store(hv, "type", 4, newSVpv("BGP4MP", 0), 0);
    hv_store(hv, "type_id", 7, newSVuv(entry->type), 0);
    hv_store(hv, "subtype_id", 10, newSVuv(entry->subtype), 0);

    switch(entry->subtype) {
        case BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE:
        case BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE_AS4:
            hv_store(hv, "msg_type_id", 11,
                     newSViv(entry->body.zebra_message.type), 0);
            switch (entry->body.zebra_message.type) {
                case BGP_MSG_UPDATE:
                    hv_store(hv, "subtype", 7,
                             newSVpv("MESSAGE/Update", 0), 0);
                    if (entry->body.zebra_message.source_as) {
                        hv_store(hv, "peer_addr", 9,
                                 _xs_zebra_source_ip(aTHX_ entry), 0);
                        hv_store(hv, "peer_as", 7,
                                 newSVuv(entry->body.zebra_message.source_as),
                                 0);
                    }
                    if (entry->body.zebra_message.destination_as) {
                        hv_store(hv, "dest_addr", 9,\
                                 _xs_zebra_dest_ip(aTHX_ entry), 0);
                        hv_store(hv, "dest_as", 7,
                                 newSVuv(entry->body.zebra_message.destination_as),
                                 0);
                    }
                    if (entry->attr && entry->attr->len)
                        _xs_attr_build(aTHX_ entry->attr, hv);
                    if (entry->body.zebra_message.cut_bytes) {
                        u_int16_t cutted;
                        u_int8_t  buf[128];
                        hv_store(hv, "incomplete_cut_bytes", 20,
                                 newSVuv(entry->body.zebra_message.cut_bytes),
                                 0);
                        cutted = entry->body.zebra_message.incomplete.prefix.len/8+1;
                        buf[0] = entry->body.zebra_message.incomplete.orig_len;
                        memcpy(buf + 1, &entry->body.zebra_message.incomplete.prefix.address,cutted - 1);
                        hv_store(hv, "incomplete_part", 15,
                                 newSVpv(buf, cutted), 0);
                    }
                    if (entry->attr) {
                        if ((entry->body.zebra_message.withdraw_count) || (entry->attr->flag & ATTR_FLAG_BIT(BGP_ATTR_MP_UNREACH_NLRI))) {
#ifdef BGPDUMP_HAVE_IPV6
                            if ((entry->body.zebra_message.withdraw_count) || (entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST] && entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST]->prefix_count) || (entry->attr->mp_info->withdraw[AFI_IP][SAFI_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP][SAFI_MULTICAST]->prefix_count) || (entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST_MULTICAST]->prefix_count) || (entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST] && entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST]->prefix_count) || (entry->attr->mp_info->withdraw[AFI_IP6][SAFI_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP6][SAFI_MULTICAST]->prefix_count) || (entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST_MULTICAST]->prefix_count))
#else
                            if ((entry->body.zebra_message.withdraw_count) || (entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST] && entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST]->prefix_count) || (entry->attr->mp_info->withdraw[AFI_IP][SAFI_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP][SAFI_MULTICAST]->prefix_count) || (entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST_MULTICAST]->prefix_count))
#endif
                            {
                                AV *av = newAV();
                                hv_store(hv, "withdraw", 8, newRV_noinc(MUTABLE_SV(av)), 0);
                                if (entry->body.zebra_message.withdraw_count)
                                    _xs_add_prefixes(aTHX_ entry->body.zebra_message.withdraw_count, entry->body.zebra_message.withdraw, av);
                                if (entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST] && entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST]->prefix_count)
                                    _xs_add_prefixes(aTHX_ entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST]->prefix_count,entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST]->nlri, av);
                                if (entry->attr->mp_info->withdraw[AFI_IP][SAFI_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP][SAFI_MULTICAST]->prefix_count)
                                    _xs_add_prefixes(aTHX_ entry->attr->mp_info->withdraw[AFI_IP][SAFI_MULTICAST]->prefix_count,entry->attr->mp_info->withdraw[AFI_IP][SAFI_MULTICAST]->nlri, av);
                                if (entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST_MULTICAST]->prefix_count)
                                    _xs_add_prefixes(aTHX_ entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST_MULTICAST]->prefix_count,entry->attr->mp_info->withdraw[AFI_IP][SAFI_UNICAST_MULTICAST]->nlri, av);
#ifdef BGPDUMP_HAVE_IPV6
                                if (entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST] && entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST]->prefix_count)
                                    _xs_add_prefixes6(aTHX_ entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST]->prefix_count,entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST]->nlri, av);
                                if (entry->attr->mp_info->withdraw[AFI_IP6][SAFI_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP6][SAFI_MULTICAST]->prefix_count)
                                    _xs_add_prefixes6(aTHX_ entry->attr->mp_info->withdraw[AFI_IP6][SAFI_MULTICAST]->prefix_count,entry->attr->mp_info->withdraw[AFI_IP6][SAFI_MULTICAST]->nlri, av);
                                if (entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST_MULTICAST] && entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST_MULTICAST]->prefix_count)
                                    _xs_add_prefixes6(aTHX_ entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST_MULTICAST]->prefix_count,entry->attr->mp_info->withdraw[AFI_IP6][SAFI_UNICAST_MULTICAST]->nlri, av);
#endif
                            }
                        }
                        if ( (entry->body.zebra_message.announce_count) || (entry->attr->flag & ATTR_FLAG_BIT(BGP_ATTR_MP_REACH_NLRI)))
                        {
                            AV *av = newAV();
                            hv_store(hv, "announce", 8, newRV_noinc(MUTABLE_SV(av)), 0);

                            if (entry->body.zebra_message.announce_count)
                                _xs_add_prefixes(aTHX_ entry->body.zebra_message.announce_count,entry->body.zebra_message.announce, av);
                            if (entry->attr->mp_info->announce[AFI_IP][SAFI_UNICAST] && entry->attr->mp_info->announce[AFI_IP][SAFI_UNICAST]->prefix_count)
                                _xs_add_prefixes(aTHX_ entry->attr->mp_info->announce[AFI_IP][SAFI_UNICAST]->prefix_count,entry->attr->mp_info->announce[AFI_IP][SAFI_UNICAST]->nlri, av);
                            if (entry->attr->mp_info->announce[AFI_IP][SAFI_MULTICAST] && entry->attr->mp_info->announce[AFI_IP][SAFI_MULTICAST]->prefix_count)
                                _xs_add_prefixes(aTHX_ entry->attr->mp_info->announce[AFI_IP][SAFI_MULTICAST]->prefix_count,entry->attr->mp_info->announce[AFI_IP][SAFI_MULTICAST]->nlri, av);
                            if (entry->attr->mp_info->announce[AFI_IP][SAFI_UNICAST_MULTICAST] && entry->attr->mp_info->announce[AFI_IP][SAFI_UNICAST_MULTICAST]->prefix_count)
                                _xs_add_prefixes(aTHX_ entry->attr->mp_info->announce[AFI_IP][SAFI_UNICAST_MULTICAST]->prefix_count,entry->attr->mp_info->announce[AFI_IP][SAFI_UNICAST_MULTICAST]->nlri, av);
#ifdef BGPDUMP_HAVE_IPV6
                            if (entry->attr->mp_info->announce[AFI_IP6][SAFI_UNICAST] && entry->attr->mp_info->announce[AFI_IP6][SAFI_UNICAST]->prefix_count)
                                _xs_add_prefixes6(aTHX_ entry->attr->mp_info->announce[AFI_IP6][SAFI_UNICAST]->prefix_count,entry->attr->mp_info->announce[AFI_IP6][SAFI_UNICAST]->nlri, av);
                            if (entry->attr->mp_info->announce[AFI_IP6][SAFI_MULTICAST] && entry->attr->mp_info->announce[AFI_IP6][SAFI_MULTICAST]->prefix_count)
                                _xs_add_prefixes6(aTHX_ entry->attr->mp_info->announce[AFI_IP6][SAFI_MULTICAST]->prefix_count,entry->attr->mp_info->announce[AFI_IP6][SAFI_MULTICAST]->nlri, av);
                            if (entry->attr->mp_info->announce[AFI_IP6][SAFI_UNICAST_MULTICAST] && entry->attr->mp_info->announce[AFI_IP6][SAFI_UNICAST_MULTICAST]->prefix_count)
                                _xs_add_prefixes6(aTHX_ entry->attr->mp_info->announce[AFI_IP6][SAFI_UNICAST_MULTICAST]->prefix_count,entry->attr->mp_info->announce[AFI_IP6][SAFI_UNICAST_MULTICAST]->nlri, av);
#endif
                        }
                    }
                    break;
                case BGP_MSG_OPEN:
                    hv_store(hv, "subtype", 7,
                             newSVpv("MESSAGE/Open", 0), 0);
                    if (entry->body.zebra_message.source_as)
                    {
                        hv_store(hv, "peer_addr", 9,
                                 _xs_zebra_source_ip(aTHX_ entry), 0);
                        hv_store(hv, "peer_as", 7,
                                 newSVuv(entry->body.zebra_message.source_as),
                                 0);
                    }
                    if (entry->body.zebra_message.destination_as)
                    {
                        hv_store(hv, "dest_addr", 9,
                                 _xs_zebra_dest_ip(aTHX_ entry), 0);
                        hv_store(hv, "dest_as", 7,
                                 newSVuv(entry->body.zebra_message.destination_as),
                                 0);
                    }
                    hv_store(hv, "version", 7,
                             newSViv(entry->body.zebra_message.version), 0);
                    hv_store(hv, "as", 2,
                             newSVuv(entry->body.zebra_message.my_as), 0);
                    hv_store(hv, "hold_time", 9,
                             newSViv(entry->body.zebra_message.hold_time), 0);
                    hv_store(hv, "opt_parm_len", 12,
                             newSViv(entry->body.zebra_message.opt_len), 0);
                    hv_store(hv, "id", 2,
                             newSVpv(inet_ntoa(entry->body.zebra_message.bgp_id), 0), 0);
                    break;
                case BGP_MSG_NOTIFY:
                    hv_store(hv, "subtype", 7,
                             newSVpv("MESSAGE/Notify", 0), 0);
                    if (entry->body.zebra_message.source_as)
                    {
                        hv_store(hv, "peer_addr", 9,
                                 _xs_zebra_source_ip(aTHX_ entry), 0);
                        hv_store(hv, "peer_as", 7,
                                 newSVuv(entry->body.zebra_message.source_as),
                                 0);
                    }
                    if (entry->body.zebra_message.destination_as)
                    {
                        hv_store(hv, "dest_addr", 9,
                                 _xs_zebra_dest_ip(aTHX_ entry), 0);
                        hv_store(hv, "dest_as", 7,
                                 newSVuv(entry->body.zebra_message.destination_as),
                                 0);
                    }
                    hv_store(hv, "error_code", 10,
                             newSViv(entry->body.zebra_message.error_code),
                             0);
                    hv_store(hv, "sub_error_code", 14,
                             newSViv(entry->body.zebra_message.sub_error_code),
                             0);
                    switch (entry->body.zebra_message.error_code)
                    {
                        case 1:
                            hv_store(hv, "error", 5,
                                     newSVpv("Message Header Error", 0), 0);
                            switch (entry->body.zebra_message.sub_error_code)
                            {
                                case 1:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Connection Not Synchronized", 0), 0);
                                    break;
                                case 2:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Bad Message Length", 0), 0);
                                    break;
                                case 3:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Bad Message Type", 0), 0);
                                    break;
                                default:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Unknown", 0), 0);
                                    break;
                            }
                            break;
                        case 2:
                            hv_store(hv, "error", 5,
                                     newSVpv("OPEN Message Error", 0), 0);
                            switch (entry->body.zebra_message.sub_error_code)
                            {
                                case 1:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Unsupported Version Number", 0), 0);
                                    break;
                                case 2:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Bad Peer AS", 0), 0);
                                    break;
                                case 3:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Bad BGP Identifier", 0), 0);
                                    break;
                                case 4:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Unsupported Optional Parameter", 0), 0);
                                    break;
                                case 5:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Authentication Failure", 0), 0);
                                    break;
                                case 6:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Unacceptable Hold Time", 0), 0);
                                    break;
                                default:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Unknown", 0), 0);
                                    break;
                            }
                            break;
                        case 3:
                            hv_store(hv, "error", 5,
                                     newSVpv("UPDATE Message Error", 0), 0);
                            switch (entry->body.zebra_message.sub_error_code)
                            {
                                case 1:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Malformed Attribute List", 0), 0);
                                    break;
                                case 2:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Unrecognized Well-known Attribute", 0), 0);
                                    break;
                                case 3:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Missing Well-known Attribute", 0), 0);
                                    break;
                                case 4:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Attribute Flags Error", 0), 0);
                                    break;
                                case 5:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Attribute Length Error", 0), 0);
                                    break;
                                case 6:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Invalid ORIGIN Attribute", 0), 0);
                                    break;
                                case 7:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("AS Routing Loop", 0), 0);
                                    break;
                                case 8:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Invalid NEXT-HOP Attribute", 0), 0);
                                    break;
                                case 9:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Optional Attribute Error", 0), 0);
                                    break;
                                case 10:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Invalid Network Field", 0), 0);
                                    break;
                                case 11:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Malformed AS-PATH", 0), 0);
                                    break;
                                default:
                                    hv_store(hv, "sub_error", 9,
                                             newSVpv("Unknown", 0), 0);
                                    break;
                            }
                            break;
                        case 4:
                            hv_store(hv, "error", 5,
                                     newSVpv("Hold Timer Expired", 0), 0);
                            break;
                        case 5:
                            hv_store(hv, "error", 5,
                                     newSVpv("Finite State Machine Error", 0), 0);
                            break;
                        case 6:
                            hv_store(hv, "error", 5,
                                     newSVpv("Cease", 0), 0);
                            break;
                        default:
                            hv_store(hv, "error", 5,
                                     newSVpv("Unknown", 0), 0);
                            break;
                         
                    }
                    break;
                case BGP_MSG_KEEPALIVE:
                    hv_store(hv, "subtype", 7,
                             newSVpv("MESSAGE/Keepalive", 0), 0);
                    if (entry->body.zebra_message.source_as)
                    {
                        hv_store(hv, "peer_addr", 9,
                                 _xs_zebra_source_ip(aTHX_ entry), 0);
                        hv_store(hv, "peer_as", 7,
                                 newSVuv(entry->body.zebra_message.source_as),
                                 0);
                    }
                    if (entry->body.zebra_message.destination_as)
                    {
                        hv_store(hv, "dest_addr", 9,
                                 _xs_zebra_dest_ip(aTHX_ entry), 0);
                        hv_store(hv, "dest_as", 7,
                                 newSVuv(entry->body.zebra_message.destination_as),
                                 0);
                    }
                    break;
            }
            break;
        case BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE:
        case BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE_AS4:
            hv_store(hv, "subtype", 7,
                     newSVpv("STATE_CHANGE", 0), 0);
            switch(entry->body.zebra_state_change.address_family)
            {
#ifdef BGPDUMP_HAVE_IPV6
                case AFI_IP6:
                    addr_sv = newSVpv(fmt_ipv6(entry->body.zebra_state_change.source_ip, pfx), 0);
                    break;
#endif
                case AFI_IP:
                default:
                    if (entry->body.zebra_state_change.source_ip.v4_addr.s_addr != 0x00000000L)
                        addr_sv = newSVpv(inet_ntoa(entry->body.zebra_state_change.source_ip.v4_addr), 0);
                    else
                        addr_sv = newSV(0);
            }
            hv_store(hv, "peer_addr", 9, addr_sv, 0);
            hv_store(hv, "peer_as", 7,
                     newSViv(entry->body.zebra_state_change.source_as), 0);
            hv_store(hv, "old_state", 9,
                     newSVuv(entry->body.zebra_state_change.old_state), 0);
            hv_store(hv, "new_state", 9,
                     newSVuv(entry->body.zebra_state_change.new_state), 0);
            hv_store(hv, "old_state", 9, newSVpv(
                bgp_state_name[entry->body.zebra_state_change.old_state], 0), 0);
            hv_store(hv, "new_state", 9, newSVpv(
                bgp_state_name[entry->body.zebra_state_change.new_state], 0), 0);
            break;
    }

    return newRV_noinc(MUTABLE_SV(hv));
}


MODULE = Net::BGPdump           PACKAGE = Net::BGPdump

PROTOTYPES: ENABLE

BOOT:
#define MC(cc) \
    newCONSTSUB(stash, #cc, newSViv( cc ))
//
#define MCE(name, ce) \
    newCONSTSUB(stash, #name, newSViv( ce ))
// BOOT ends after first blank line outside of a block
{
    HV *stash;

    stash = gv_stashpv("Net::BGPdump", TRUE);

    MC(BGPDUMP_TYPE_MRTD_BGP);
    MC(BGPDUMP_TYPE_MRTD_TABLE_DUMP);
    MC(BGPDUMP_TYPE_TABLE_DUMP_V2);
    MC(BGPDUMP_TYPE_ZEBRA_BGP);

    // BGPDUMP_TYPE_MRTD_BGP
    MC(BGPDUMP_SUBTYPE_MRTD_BGP_NULL);
    MC(BGPDUMP_SUBTYPE_MRTD_BGP_UPDATE);
    MC(BGPDUMP_SUBTYPE_MRTD_BGP_PREFUPDATE);
    MC(BGPDUMP_SUBTYPE_MRTD_BGP_STATE_CHANGE);
    MC(BGPDUMP_SUBTYPE_MRTD_BGP_SYNC);
    MC(BGPDUMP_SUBTYPE_MRTD_BGP_OPEN);
    MC(BGPDUMP_SUBTYPE_MRTD_BGP_NOTIFICATION);
    MC(BGPDUMP_SUBTYPE_MRTD_BGP_KEEPALIVE);
    MC(BGPDUMP_SUBTYPE_MRTD_BGP_ROUT_REFRESH);

    // BGPDUMP_TYPE_MRTD_TABLE_DUMP
    MC(BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6);
    MC(BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6_32BIT_AS);
    MC(BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP);
    MC(BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP_32BIT_AS);
    MC(BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6);
    MC(BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6_32BIT_AS);
    MC(BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP);
    MC(BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP_32BIT_AS);

    // BGPDUMP_TYPE_TABLE_DUMP_V2
    MC(BGPDUMP_SUBTYPE_TABLE_DUMP_V2_PEER_INDEX_TABLE);
    MC(BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_UNICAST);
    MC(BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_MULTICAST);
    MC(BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_UNICAST);
    MC(BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_MULTICAST);
    MC(BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_GENERIC);
    MC(BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP);
    MC(BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP6);
    MC(BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AS2);
    MC(BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AS4);

    // BGPDUMP_TYPE_ZEBRA_BGP
    MC(BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE);
    MC(BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE_AS4);
    MC(BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE);
    MC(BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE_AS4);

    // BGP states
    MC(BGP_STATE_IDLE);
    MC(BGP_STATE_CONNECT);
    MC(BGP_STATE_ACTIVE);
    MC(BGP_STATE_OPENSENT);
    MC(BGP_STATE_OPENCONFIRM);
    MC(BGP_STATE_ESTABLISHED);

    // zebra message types
    MC(BGP_MSG_UPDATE);
    MC(BGP_MSG_OPEN);
    MC(BGP_MSG_NOTIFY);
    MC(BGP_MSG_KEEPALIVE);
    MC(BGP_MSG_ROUTE_REFRESH_01);
    MC(BGP_MSG_ROUTE_REFRESH);
}

Net::BGPdump
_open(class, filename)
    char *class
    char *filename
    CODE:
    PERL_UNUSED_VAR(class);
    RETVAL = bgpdump_open_dump(filename);
    OUTPUT:
    RETVAL

void
close(THIS)
    Net::BGPdump THIS
    CODE:
    cfr_close(THIS->f);

void
_destroy(THIS)
    Net::BGPdump THIS
    CODE:
    bgpdump_close_dump(THIS);

int
closed(THIS)
    Net::BGPdump THIS
    CODE:
    RETVAL = THIS->f->closed;
    OUTPUT:
    RETVAL

int
eof(THIS)
    Net::BGPdump THIS
    CODE:
    RETVAL = THIS->eof;
    OUTPUT:
    RETVAL

void
file_type(THIS)
    Net::BGPdump THIS
    PPCODE:
    switch (THIS->f->format) {
        case 0:
            // not opened
            break;
        case 1:
            mXPUSHs(newSVpv("uncompressed", 0));
            break;
        case 2:
            mXPUSHs(newSVpv("bzip2", 0));
            break;
        case 3:
            mXPUSHs(newSVpv("gzip", 0));
            break;
        default:
            croak("unknown file format: %d", THIS->f->format);
    }

int
records(THIS)
    Net::BGPdump THIS
    CODE:
    RETVAL = THIS->parsed;
    OUTPUT:
    RETVAL

int
parsed_ok(THIS)
    Net::BGPdump THIS
    CODE:
    RETVAL = THIS->parsed_ok;
    OUTPUT:
    RETVAL

int
parsed_fail(THIS)
    Net::BGPdump THIS
    CODE:
    RETVAL = THIS->parsed - THIS->parsed_ok;
    OUTPUT:
    RETVAL

char *
filename(THIS)
    Net::BGPdump THIS
    CODE:
    RETVAL = THIS->filename;
    OUTPUT:
    RETVAL

void
filter_read(THIS, ipv6, lo_time, hi_time)
    Net::BGPdump THIS
    int    ipv6
    time_t lo_time
    time_t hi_time
    PREINIT:
    BGPDUMP_ENTRY *entry;
    PPCODE:
    do {
        entry = bgpdump_read_next(THIS);
        if (entry == NULL)
            continue;
        if (lo_time > 0 && entry->time < lo_time)
            goto next_entry;
        if (hi_time > 0 && entry->time >= hi_time)
            goto next_entry;
        switch(entry->type) {
            case BGPDUMP_TYPE_MRTD_BGP:
                mXPUSHs(_xs_mrtd_bgp_build(aTHX_ entry));
                break;
            case BGPDUMP_TYPE_ZEBRA_BGP:
                if (ipv6 >= 0) {
                    switch(entry->subtype)
                    {
                        case BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE:
                        case BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE_AS4:
                            switch(entry->body.zebra_message.address_family)
                            {
#ifdef BGPDUMP_HAVE_IPV6
                                case AFI_IP6:
                                    if (ipv6 == 0)
                                        goto next_entry;
                                    break;
#endif
                                case AFI_IP:
                                default:
                                    if (ipv6 != 0)
                                        goto next_entry;
                                    break;
                            }
                            break;
                        case BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE:
                        case BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE_AS4:
                            switch(entry->body.zebra_state_change.address_family)
                            {
#ifdef BGPDUMP_HAVE_IPV6
                                case AFI_IP6:
                                    if (ipv6 == 0)
                                        goto next_entry;
                                    break;
#endif
                                case AFI_IP:
                                default:
                                    if (ipv6 != 0)
                                        goto next_entry;
                                    break;
                            }
                            break;
                    }
                }
                mXPUSHs(_xs_zebra_bgp_build(aTHX_ entry));
                break;
            case BGPDUMP_TYPE_TABLE_DUMP_V2:
                if (ipv6 >= 0) {
                    switch (entry->subtype)
                    {
                        case BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_UNICAST:
                        case BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_MULTICAST:
                        case BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP6:
                            if (ipv6 == 0)
                                goto next_entry;
                            break;
                        case BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_UNICAST:
                        case BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_MULTICAST:
                        case BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP:
                            if (ipv6 != 0)
                                goto next_entry;
                            break;
                    }
                    BGPDUMP_TABLE_DUMP_V2_PREFIX *e;
                    e = &entry->body.mrtd_table_dump_v2_prefix;
                    if (e->afi == AFI_IP) {
                        if (ipv6 != 0)
                            goto next_entry;
#ifdef BGPDUMP_HAVE_IPV6
                    }
                    else if (e->afi == AFI_IP6) {
                        if (ipv6 == 0)
                            goto next_entry;
#endif
                    }
                }
                mXPUSHs(_xs_table_dump_v2_build(aTHX_ entry));
                break;
            case BGPDUMP_TYPE_MRTD_TABLE_DUMP:
                if (ipv6 >= 0) {
                    switch(entry->subtype) {
#ifdef BGPDUMP_HAVE_IPV6
                        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6:
                        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6_32BIT_AS:
                            if (ipv6 == 0)
                                goto next_entry;
                            break;
#endif
                        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP:
                        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP_32BIT_AS:
                            if (ipv6 != 0)
                                goto next_entry;
                            break;
                    }
                }
                mXPUSHs(_xs_mrtd_table_dump_build(aTHX_ entry));
                break;
            default:
                warn("error: unknown entry type %d\n", entry->type);
        }
        bgpdump_free_mem(entry);
        entry = NULL;
        break;
      next_entry:
        bgpdump_free_mem(entry);
        entry = NULL;
        continue;
    } while (THIS->eof == 0);
    entry = NULL;
    // return

void
filter_message_read(THIS, ipv6, lo_time, hi_time)
    Net::BGPdump THIS
    int    ipv6
    time_t lo_time
    time_t hi_time
    PREINIT:
    BGPDUMP_ENTRY *entry;
    PPCODE:
    do {
        entry = bgpdump_read_next(THIS);
        if (entry == NULL)
            continue;
        if (lo_time > 0 && entry->time < lo_time)
            goto next_entry;
        if (hi_time > 0 && entry->time >= hi_time)
            goto next_entry;
        switch(entry->type) {
            case BGPDUMP_TYPE_MRTD_BGP:
                if (entry->subtype != BGPDUMP_SUBTYPE_MRTD_BGP_UPDATE)
                    goto next_entry;
                mXPUSHs(_xs_mrtd_bgp_build(aTHX_ entry));
                break;
            case BGPDUMP_TYPE_ZEBRA_BGP:
                if ((entry->subtype == BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE) || 
                    (entry->subtype == BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE_AS4))
                {
                    if (entry->body.zebra_message.type != BGP_MSG_UPDATE)
                        goto next_entry;
                }
                else
                    goto next_entry;
                if (ipv6 >= 0) {
                    switch(entry->body.zebra_message.address_family) {
#ifdef BGPDUMP_HAVE_IPV6
                        case AFI_IP6:
                            if (ipv6 == 0)
                                goto next_entry;
                            break;
#endif
                            case AFI_IP:
                            default:
                                if (ipv6 != 0)
                                    goto next_entry;
                                break;
                    }
                }
                mXPUSHs(_xs_zebra_bgp_build(aTHX_ entry));
                break;
            case BGPDUMP_TYPE_TABLE_DUMP_V2:
                if (ipv6 >= 0) {
                    switch (entry->subtype)
                    {
                        case BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_UNICAST:
                        case BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_MULTICAST:
                        case BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP6:
                            if (ipv6 == 0)
                                goto next_entry;
                            break;
                        case BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_UNICAST:
                        case BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_MULTICAST:
                        case BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP:
                            if (ipv6 != 0)
                                goto next_entry;
                            break;
                    }
                    BGPDUMP_TABLE_DUMP_V2_PREFIX *e;
                    e = &entry->body.mrtd_table_dump_v2_prefix;
                    if (e->afi == AFI_IP) {
                        if (ipv6 != 0)
                            goto next_entry;
#ifdef BGPDUMP_HAVE_IPV6
                    }
                    else if (e->afi == AFI_IP6) {
                        if (ipv6 == 0)
                            goto next_entry;
#endif
                    }
                }
                mXPUSHs(_xs_table_dump_v2_build(aTHX_ entry));
                break;
            case BGPDUMP_TYPE_MRTD_TABLE_DUMP:
                if (ipv6 >= 0) {
                    switch(entry->subtype) {
#ifdef BGPDUMP_HAVE_IPV6
                        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6:
                        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6_32BIT_AS:
                            if (ipv6 == 0)
                                goto next_entry;
                            break;
#endif
                        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP:
                        case BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP_32BIT_AS:
                            if (ipv6 != 0)
                                goto next_entry;
                            break;
                    }
                }
                mXPUSHs(_xs_mrtd_table_dump_build(aTHX_ entry));
                break;
            default:
                goto next_entry;
        }
        bgpdump_free_mem(entry);
        entry = NULL;
        break;
      next_entry:
        bgpdump_free_mem(entry);
        entry = NULL;
        continue;
    } while (THIS->eof == 0);
    entry = NULL;
    // return

void
log_to_stderr(CLASS, mode)
    char *CLASS
    bool mode
    CODE:
    PERL_UNUSED_VAR(CLASS);
    if (mode)
        log_to_stderr();
    else
        log_to_syslog();
