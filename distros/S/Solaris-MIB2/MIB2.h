#if !defined __MIB2_H__
#    define  __MIB2_H__

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdarg.h>
#include <string.h>
#include <stropts.h>
#include <fcntl.h>
#include <errno.h>

#include <sys/stream.h>
#include <sys/stropts.h>
#include <sys/socket.h>

#include <sys/tihdr.h>
#include <sys/tiuser.h>

#include <inet/led.h>
#include <inet/mib2.h>
#include <netinet/igmp_var.h>

#define  DEV_DEFAULT	"/dev/arp"

#define  ARP_MODULE	"arp"
#define  TCP_MODULE	"tcp"
#define  UDP_MODULE	"udp"
#define  ICMP_MODULE	"icmp"

#if !defined T_CURRENT
#    define  T_CURRENT    0x080
#endif
#if !defined MI_T_CURRENT
#    define  MI_T_CURRENT 0x100
#endif

#define MIB2_GROUP_SYSTEM		"system"
#define MIB2_GROUP_INTERFACES		"interfaces"
#define MIB2_GROUP_AT			"at"
#define MIB2_GROUP_IP			"ip"
#define MIB2_GROUP_ICMP			"icmp"
#define MIB2_GROUP_TCP			"tcp"
#define MIB2_GROUP_UDP			"udp"
#define MIB2_GROUP_EGP			"egp"
#define MIB2_GROUP_TRANSMISSION		"transmission"
#define MIB2_GROUP_SNMP 		"snmp"

#define MIB2_GROUP_IP_ROUTE_ENTRY	"ipRouteEntry"
#define MIB2_GROUP_IP_ADDR_ENTRY	"ipAddrEntry"
#define MIB2_GROUP_IP_NET2MEDIA_ENTRY	"ipNetToMediaEntry"
				
#define MIB2_GROUP_TCP_CONN_ENTRY	"tcpConnEntry"

#define MIB2_GROUP_UDP_ENTRY		"udpEntry"

#define MIB2_GROUP_RAWIP		"rawip"

#define MIB2_GROUP_IP_MEMBER		"ip_member"

#define NEW_UIV(V) \
   (V <= IV_MAX ? newSViv(V) : newSVnv((double)V))
#define NEW_HRTIME(V) \
   newSVnv((double)(V / 1000000000.0))

#define SAVE_FNP(H, F, K) \
   hv_store(H, K, sizeof(K) - 1, newSViv((long)&F),0)
#define SAVE_STRING(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, newSVpv((S)->K,0),0)
#define SAVE_STRING_BUFFER(H, K, B) \
   hv_store(H, #K, sizeof(#K) - 1, newSVpv(B,0),0)
#define SAVE_INT32(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, newSViv((S)->K),0)
#define SAVE_UINT32(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV((S)->K),0) 
#define SAVE_INT64(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV((S)->K),0)
#define SAVE_UINT64(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_UIV((S)->K),0)
#define SAVE_HRTIME(H, S, K) \
   hv_store(H, #K, sizeof(#K) - 1, NEW_HRTIME((S)->K),0)

/*** struct mib2_icmp ***/
#define SAVE_MIB2_ICMP(H,P)			\
   SAVE_UINT32(H,P,icmpInMsgs);	    		\
   SAVE_UINT32(H,P,icmpInErrors);		\
   SAVE_UINT32(H,P,icmpInDestUnreachs);		\
   SAVE_UINT32(H,P,icmpInTimeExcds);		\
   SAVE_UINT32(H,P,icmpInParmProbs);		\
   SAVE_UINT32(H,P,icmpInSrcQuenchs);		\
   SAVE_UINT32(H,P,icmpInRedirects);		\
   SAVE_UINT32(H,P,icmpInEchos);		\
   SAVE_UINT32(H,P,icmpInEchoReps);		\
   SAVE_UINT32(H,P,icmpInTimestamps);		\
   SAVE_UINT32(H,P,icmpInTimestampReps);	\
   SAVE_UINT32(H,P,icmpInAddrMasks);		\
   SAVE_UINT32(H,P,icmpInAddrMaskReps);		\
   SAVE_UINT32(H,P,icmpOutMsgs);		\
   SAVE_UINT32(H,P,icmpOutErrors);		\
   SAVE_UINT32(H,P,icmpOutDestUnreachs);	\
   SAVE_UINT32(H,P,icmpOutTimeExcds);		\
   SAVE_UINT32(H,P,icmpOutParmProbs);		\
   SAVE_UINT32(H,P,icmpOutSrcQuenchs);		\
   SAVE_UINT32(H,P,icmpOutRedirects);		\
   SAVE_UINT32(H,P,icmpOutEchos);		\
   SAVE_UINT32(H,P,icmpOutEchoReps);		\
   SAVE_UINT32(H,P,icmpOutTimestamps);		\
   SAVE_UINT32(H,P,icmpOutTimestampReps);	\
   SAVE_UINT32(H,P,icmpOutAddrMasks);		\
   SAVE_UINT32(H,P,icmpOutAddrMaskReps);	\
   SAVE_UINT32(H,P,icmpInCksumErrs);		\
   SAVE_UINT32(H,P,icmpInUnknowns);		\
   SAVE_UINT32(H,P,icmpInFragNeeded);		\
   SAVE_UINT32(H,P,icmpOutFragNeeded);		\
   SAVE_UINT32(H,P,icmpOutDrops);		\
   SAVE_UINT32(H,P,icmpInOverflows);		\
   SAVE_UINT32(H,P,icmpInBadRedirects);

/*** struct mib2_ip ***/
#define SAVE_MIB2_IP(H,P)			\
   SAVE_INT32(H,P,ipForwarding);		\
   SAVE_INT32(H,P,ipDefaultTTL);		\
   SAVE_UINT32(H,P,ipInReceives);		\
   SAVE_UINT32(H,P,ipInHdrErrors);		\
   SAVE_UINT32(H,P,ipInAddrErrors);		\
   SAVE_UINT32(H,P,ipForwDatagrams);		\
   SAVE_UINT32(H,P,ipInUnknownProtos);		\
   SAVE_UINT32(H,P,ipInDiscards);		\
   SAVE_UINT32(H,P,ipInDelivers);		\
   SAVE_UINT32(H,P,ipOutRequests);		\
   SAVE_UINT32(H,P,ipOutDiscards);		\
   SAVE_UINT32(H,P,ipOutNoRoutes);		\
   SAVE_INT32(H,P,ipReasmTimeout);		\
   SAVE_UINT32(H,P,ipReasmReqds);		\
   SAVE_UINT32(H,P,ipReasmOKs);			\
   SAVE_UINT32(H,P,ipReasmFails);		\
   SAVE_UINT32(H,P,ipFragOKs);			\
   SAVE_UINT32(H,P,ipFragFails);		\
   SAVE_UINT32(H,P,ipFragCreates);		\
   SAVE_INT32(H,P,ipAddrEntrySize);		\
   SAVE_INT32(H,P,ipRouteEntrySize);		\
   SAVE_INT32(H,P,ipNetToMediaEntrySize);	\
   SAVE_UINT32(H,P,ipRoutingDiscards);		\
   SAVE_UINT32(H,P,tcpInErrs);			\
   SAVE_UINT32(H,P,udpNoPorts);			\
   SAVE_UINT32(H,P,ipInCksumErrs);		\
   SAVE_UINT32(H,P,ipReasmDuplicates);		\
   SAVE_UINT32(H,P,ipReasmPartDups);		\
   SAVE_UINT32(H,P,ipForwProhibits);		\
   SAVE_UINT32(H,P,udpInCksumErrs);		\
   SAVE_UINT32(H,P,udpInOverflows);		\
   SAVE_UINT32(H,P,rawipInOverflows);		\
   SAVE_UINT32(H,P,ipsecInSucceeded);		\
   SAVE_UINT32(H,P,ipsecInFailed);		\
   SAVE_INT32(H,P,ipMemberEntrySize);		\
   SAVE_UINT32(H,P,ipInIPv6);			\
   SAVE_UINT32(H,P,ipOutIPv6);			\
   SAVE_UINT32(H,P,ipOutSwitchIPv6);

/*** struct mib2_tcp ***/
#define SAVE_MIB2_TCP(H,P)			\
   SAVE_INT32(H,P,tcpRtoAlgorithm);		\
   SAVE_INT32(H,P,tcpRtoMin);			\
   SAVE_INT32(H,P,tcpRtoMax);			\
   SAVE_INT32(H,P,tcpMaxConn);			\
   SAVE_UINT32(H,P,tcpActiveOpens);		\
   SAVE_UINT32(H,P,tcpPassiveOpens);		\
   SAVE_UINT32(H,P,tcpAttemptFails);		\
   SAVE_UINT32(H,P,tcpEstabResets);		\
   SAVE_UINT32(H,P,tcpCurrEstab);		\
   SAVE_UINT32(H,P,tcpInSegs);			\
   SAVE_UINT32(H,P,tcpOutSegs);			\
   SAVE_UINT32(H,P,tcpRetransSegs);		\
   SAVE_INT32(H,P,tcpConnTableSize);		\
   SAVE_UINT32(H,P,tcpOutRsts);			\
   SAVE_UINT32(H,P,tcpOutDataSegs);		\
   SAVE_UINT32(H,P,tcpOutDataBytes);		\
   SAVE_UINT32(H,P,tcpRetransBytes);		\
   SAVE_UINT32(H,P,tcpOutAck);			\
   SAVE_UINT32(H,P,tcpOutAckDelayed);		\
   SAVE_UINT32(H,P,tcpOutUrg);			\
   SAVE_UINT32(H,P,tcpOutWinUpdate);		\
   SAVE_UINT32(H,P,tcpOutWinProbe);		\
   SAVE_UINT32(H,P,tcpOutControl);		\
   SAVE_UINT32(H,P,tcpOutFastRetrans);		\
   SAVE_UINT32(H,P,tcpInAckSegs);		\
   SAVE_UINT32(H,P,tcpInAckBytes);		\
   SAVE_UINT32(H,P,tcpInDupAck);		\
   SAVE_UINT32(H,P,tcpInAckUnsent);		\
   SAVE_UINT32(H,P,tcpInDataInorderSegs);	\
   SAVE_UINT32(H,P,tcpInDataInorderBytes);	\
   SAVE_UINT32(H,P,tcpInDataUnorderSegs);	\
   SAVE_UINT32(H,P,tcpInDataUnorderBytes);	\
   SAVE_UINT32(H,P,tcpInDataDupSegs);		\
   SAVE_UINT32(H,P,tcpInDataDupBytes);		\
   SAVE_UINT32(H,P,tcpInDataPartDupSegs);	\
   SAVE_UINT32(H,P,tcpInDataPartDupBytes);	\
   SAVE_UINT32(H,P,tcpInDataPastWinSegs);	\
   SAVE_UINT32(H,P,tcpInDataPastWinBytes);	\
   SAVE_UINT32(H,P,tcpInWinProbe);		\
   SAVE_UINT32(H,P,tcpInWinUpdate);		\
   SAVE_UINT32(H,P,tcpInClosed);		\
   SAVE_UINT32(H,P,tcpRttNoUpdate);		\
   SAVE_UINT32(H,P,tcpRttUpdate);		\
   SAVE_UINT32(H,P,tcpTimRetrans);		\
   SAVE_UINT32(H,P,tcpTimRetransDrop);		\
   SAVE_UINT32(H,P,tcpTimKeepalive);		\
   SAVE_UINT32(H,P,tcpTimKeepaliveProbe);	\
   SAVE_UINT32(H,P,tcpTimKeepaliveDrop);	\
   SAVE_UINT32(H,P,tcpListenDrop);		\
   SAVE_UINT32(H,P,tcpListenDropQ0);		\
   SAVE_UINT32(H,P,tcpHalfOpenDrop);		\
   SAVE_UINT32(H,P,tcpOutSackRetransSegs);	\
   SAVE_INT32(H,P,tcp6ConnTableSize);

/*** struct mib2_udp ***/
#define SAVE_MIB2_UDP(H,P)			\
   SAVE_UINT32(H,P,udpInDatagrams);		\
   SAVE_UINT32(H,P,udpInErrors);		\
   SAVE_UINT32(H,P,udpOutDatagrams);		\
   SAVE_INT32(H,P,udpEntrySize);		\
   SAVE_INT32(H,P,udp6EntrySize);		\
   SAVE_UINT32(H,P,udpOutErrors);

/*** struct mib2_tcpConnEntry ***/
#define SAVE_MIB2_TCP_CONN_ENTRY(H,P,B)			\
   SAVE_INT32(H,P,tcpConnState);			\
   ipdot(P->tcpConnLocalAddress,B);			\
   SAVE_STRING_BUFFER(H,tcpConnLocalAddress,B);		\
   SAVE_INT32(H,P,tcpConnLocalPort);			\
   ipdot(P->tcpConnRemAddress,B);			\
   SAVE_STRING_BUFFER(H,tcpConnRemAddress,B);		\
   SAVE_INT32(H,P,tcpConnRemPort);			\
   SAVE_UINT32(H,&(P->tcpConnEntryInfo),ce_snxt);	\
   SAVE_UINT32(H,&(P->tcpConnEntryInfo),ce_suna);	\
   SAVE_UINT32(H,&(P->tcpConnEntryInfo),ce_swnd);	\
   SAVE_UINT32(H,&(P->tcpConnEntryInfo),ce_rnxt);	\
   SAVE_UINT32(H,&(P->tcpConnEntryInfo),ce_rack);	\
   SAVE_UINT32(H,&(P->tcpConnEntryInfo),ce_rwnd);	\
   SAVE_UINT32(H,&(P->tcpConnEntryInfo),ce_rto);	\
   SAVE_UINT32(H,&(P->tcpConnEntryInfo),ce_mss);	\
   SAVE_INT32(H,&(P->tcpConnEntryInfo),ce_state);

/*** struct mib2_ipNetToMedia ***/
#define SAVE_MIB2_IP_NET2MEDIA_ENTRY(H,P,B)		\
   strncpy(B,P->ipNetToMediaIfIndex.o_bytes,		\
      P->ipNetToMediaIfIndex.o_length);			\
   B[P->ipNetToMediaIfIndex.o_length] = '\0';		\
   SAVE_STRING_BUFFER(H,ipNetToMediaIfIndex,B);		\
   ipmac(P->ipNetToMediaPhysAddress,B,BUFSIZ);		\
   SAVE_STRING_BUFFER(H,ipNetToMediaPhysAddress,B);	\
   ipdot(P->ipNetToMediaNetAddress,B);			\
   SAVE_STRING_BUFFER(H,ipNetToMediaNetAddress,B);	\
   SAVE_INT32(H,P,ipNetToMediaType);			\
   ipnmsk(P->ipNetToMediaInfo.ntm_mask,B,BUFSIZ);	\
   SAVE_STRING_BUFFER(H,ntm_mask,B);			\
   SAVE_INT32(H,&(P->ipNetToMediaInfo),ntm_flags);

/*** struct mib2_ipAddrEntry ***/
#define SAVE_MIB2_IP_ADDR_ENTRY(H,P,B)			\
   ipdot(P->ipAdEntAddr,B);				\
   SAVE_STRING_BUFFER(H,ipAdEntAddr,B);			\
   strncpy(B,P->ipAdEntIfIndex.o_bytes,			\
      P->ipAdEntIfIndex.o_length);			\
   B[P->ipAdEntIfIndex.o_length] = '\0';		\
   SAVE_STRING_BUFFER(H,ipAdEntIfIndex,B);		\
   ipdot(P->ipAdEntNetMask,B);				\
   SAVE_STRING_BUFFER(H,ipAdEntNetMask,B);		\
   SAVE_INT32(H,P,ipAdEntBcastAddr);			\
   SAVE_INT32(H,P,ipAdEntReasmMaxSize);			\
   SAVE_UINT32(H,&(P->ipAdEntInfo),ae_mtu);		\
   SAVE_INT32(H,&(P->ipAdEntInfo),ae_metric);		\
   ipdot(P->ipAdEntInfo.ae_broadcast_addr,B);		\
   SAVE_STRING_BUFFER(H,ae_broadcast_addr,B);		\
   ipdot(P->ipAdEntInfo.ae_pp_dst_addr,B);		\
   SAVE_STRING_BUFFER(H,ae_pp_dst_addr,B);		\
   SAVE_INT32(H,&(P->ipAdEntInfo),ae_flags);		\
   SAVE_UINT32(H,&(P->ipAdEntInfo),ae_ibcnt);		\
   SAVE_UINT32(H,&(P->ipAdEntInfo),ae_obcnt);		\
   SAVE_UINT32(H,&(P->ipAdEntInfo),ae_focnt);		\
   ipdot(P->ipAdEntInfo.ae_subnet,B);			\
   SAVE_STRING_BUFFER(H,ae_subnet,B);			\
   SAVE_INT32(H,&(P->ipAdEntInfo),ae_subnet_len);	\
   ipdot(P->ipAdEntInfo.ae_src_addr,B);			\
   SAVE_STRING_BUFFER(H,ae_src_addr,B);

/*** struct mib2_ipRouteEntry ***/
#define SAVE_MIB2_IP_ROUTE_ENTRY(H,P,B)			\
   ipdot(P->ipRouteDest,B);				\
   SAVE_STRING_BUFFER(H,ipRouteDest,B);			\
   strncpy(B,P->ipRouteIfIndex.o_bytes,			\
      P->ipRouteIfIndex.o_length);			\
   B[P->ipRouteIfIndex.o_length] = '\0';		\
   SAVE_STRING_BUFFER(H,ipRouteIfIndex,B);		\
   SAVE_INT32(H,P,ipRouteMetric1);			\
   SAVE_INT32(H,P,ipRouteMetric2);			\
   SAVE_INT32(H,P,ipRouteMetric3);			\
   SAVE_INT32(H,P,ipRouteMetric4);			\
   ipdot(P->ipRouteNextHop,B);				\
   SAVE_STRING_BUFFER(H,ipRouteNextHop,B);		\
   SAVE_INT32(H,P,ipRouteType);				\
   SAVE_INT32(H,P,ipRouteProto);			\
   SAVE_INT32(H,P,ipRouteAge);				\
   ipdot(P->ipRouteMask,B);				\
   SAVE_STRING_BUFFER(H,ipRouteMask,B);			\
   SAVE_INT32(H,P,ipRouteMetric5);			\
   SAVE_UINT32(H,&(P->ipRouteInfo),re_max_frag);	\
   SAVE_UINT32(H,&(P->ipRouteInfo),re_rtt);		\
   SAVE_UINT32(H,&(P->ipRouteInfo),re_ref);		\
   SAVE_INT32(H,&(P->ipRouteInfo),re_frag_flag);	\
   ipdot(P->ipRouteInfo.re_src_addr,B);			\
   SAVE_STRING_BUFFER(H,re_src_addr,B);			\
   SAVE_INT32(H,&(P->ipRouteInfo),re_ire_type);		\
   SAVE_UINT32(H,&(P->ipRouteInfo),re_obpkt);		\
   SAVE_UINT32(H,&(P->ipRouteInfo),re_ibpkt);		\
   SAVE_INT32(H,&(P->ipRouteInfo),re_flags);

/*** struct mib2_udpEntry ***/ 
#define SAVE_MIB2_UDP_ENTRY(H,P,B)			\
   ipdot(P->udpLocalAddress,B);				\
   SAVE_STRING_BUFFER(H,udpLocalAddress,B);		\
   SAVE_INT32(H,P,udpLocalPort);			\
   SAVE_INT32(H,&(P->udpEntryInfo),ue_state);		\
   ipdot(P->udpEntryInfo.ue_RemoteAddress,B);		\
   SAVE_STRING_BUFFER(H,ue_RemoteAddress,B);		\
   SAVE_INT32(H,&(P->udpEntryInfo),ue_RemotePort);
   
#define SAVE_MIB2_RAWIP(H,P)				\
   SAVE_UINT32(H,P,rawipInDatagrams);			\
   SAVE_UINT32(H,P,rawipInCksumErrs);			\
   SAVE_UINT32(H,P,rawipInErrors);			\
   SAVE_UINT32(H,P,rawipOutDatagrams);			\
   SAVE_UINT32(H,P,rawipOutErrors);
 
#define SAVE_MIB2_IP_MEMBER(H,P,B)			\
   strncpy(B,P->ipGroupMemberIfIndex.o_bytes,		\
      P->ipGroupMemberIfIndex.o_length);		\
   B[P->ipGroupMemberIfIndex.o_length] = '\0';		\
   SAVE_STRING_BUFFER(H,ipGroupMemberIfIndex,B);	\
   ipdot(P->ipGroupMemberAddress,B);			\
   SAVE_STRING_BUFFER(H,ipGroupMemberAddress,B);	\
   SAVE_UINT32(H,P,ipGroupMemberRefCnt)

#define fatal(msg)					\
   croak("%s(%d): %s",strerror(errno),errno,msg) 

#endif
