// Windows 8.1+
#define _WIN32_WINNT 0x0603

#include "spvm_native.h"

#include <errno.h>
#include <assert.h>

#ifdef _WIN32
  #include <ws2tcpip.h>
  #include <winsock2.h>
  #include <io.h>
#else
  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <netinet/ip.h>
  #include <netinet/tcp.h>
  #include <netinet/udp.h>
  #include <sys/un.h>
  #include <arpa/inet.h>
  #include <netdb.h>
#endif

static const char* FILE_NAME = "Sys/Socket/Constant.c";


int32_t SPVM__Sys__Socket__Constant__AF_ALG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_ALG
  stack[0].ival = AF_ALG;
  return 0;
#else
  env->die(env, stack, "AF_ALG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_APPLETALK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_APPLETALK
  stack[0].ival = AF_APPLETALK;
  return 0;
#else
  env->die(env, stack, "AF_APPLETALK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_AX25(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_AX25
  stack[0].ival = AF_AX25;
  return 0;
#else
  env->die(env, stack, "AF_AX25 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_BLUETOOTH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_BLUETOOTH
  stack[0].ival = AF_BLUETOOTH;
  return 0;
#else
  env->die(env, stack, "AF_BLUETOOTH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_CAN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_CAN
  stack[0].ival = AF_CAN;
  return 0;
#else
  env->die(env, stack, "AF_CAN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_DEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_DEC
  stack[0].ival = AF_DEC;
  return 0;
#else
  env->die(env, stack, "AF_DEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_IB(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_IB
  stack[0].ival = AF_IB;
  return 0;
#else
  env->die(env, stack, "AF_IB is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_INET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_INET
  stack[0].ival = AF_INET;
  return 0;
#else
  env->die(env, stack, "AF_INET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_INET6(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_INET6
  stack[0].ival = AF_INET6;
  return 0;
#else
  env->die(env, stack, "AF_INET6 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_IPX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_IPX
  stack[0].ival = AF_IPX;
  return 0;
#else
  env->die(env, stack, "AF_IPX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_KCM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_KCM
  stack[0].ival = AF_KCM;
  return 0;
#else
  env->die(env, stack, "AF_KCM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_KEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_KEY
  stack[0].ival = AF_KEY;
  return 0;
#else
  env->die(env, stack, "AF_KEY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_LLC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_LLC
  stack[0].ival = AF_LLC;
  return 0;
#else
  env->die(env, stack, "AF_LLC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_LOCAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_LOCAL
  stack[0].ival = AF_LOCAL;
  return 0;
#else
  env->die(env, stack, "AF_LOCAL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_MPLS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_MPLS
  stack[0].ival = AF_MPLS;
  return 0;
#else
  env->die(env, stack, "AF_MPLS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_NETLINK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_NETLINK
  stack[0].ival = AF_NETLINK;
  return 0;
#else
  env->die(env, stack, "AF_NETLINK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_PACKET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_PACKET
  stack[0].ival = AF_PACKET;
  return 0;
#else
  env->die(env, stack, "AF_PACKET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_PPPOX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_PPPOX
  stack[0].ival = AF_PPPOX;
  return 0;
#else
  env->die(env, stack, "AF_PPPOX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_RDS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_RDS
  stack[0].ival = AF_RDS;
  return 0;
#else
  env->die(env, stack, "AF_RDS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_TIPC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_TIPC
  stack[0].ival = AF_TIPC;
  return 0;
#else
  env->die(env, stack, "AF_TIPC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_UNIX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_UNIX
  stack[0].ival = AF_UNIX;
  return 0;
#else
  env->die(env, stack, "AF_UNIX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_UNSPEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_UNSPEC
  stack[0].ival = AF_UNSPEC;
  return 0;
#else
  env->die(env, stack, "AF_UNSPEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_VSOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_VSOCK
  stack[0].ival = AF_VSOCK;
  return 0;
#else
  env->die(env, stack, "AF_VSOCK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_X25(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_X25
  stack[0].ival = AF_X25;
  return 0;
#else
  env->die(env, stack, "AF_X25 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__AF_XDP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AF_XDP
  stack[0].ival = AF_XDP;
  return 0;
#else
  env->die(env, stack, "AF_XDP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__INADDR_ANY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef INADDR_ANY
  stack[0].ival = INADDR_ANY;
  return 0;
#else
  env->die(env, stack, "INADDR_ANY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__INADDR_BROADCAST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef INADDR_BROADCAST
  stack[0].ival = INADDR_BROADCAST;
  return 0;
#else
  env->die(env, stack, "INADDR_BROADCAST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__INADDR_LOOPBACK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef INADDR_LOOPBACK
  stack[0].ival = INADDR_LOOPBACK;
  return 0;
#else
  env->die(env, stack, "INADDR_LOOPBACK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__INADDR_NONE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef INADDR_NONE
  stack[0].ival = INADDR_NONE;
  return 0;
#else
  env->die(env, stack, "INADDR_NONE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPPROTO_IP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPPROTO_IP
  stack[0].ival = IPPROTO_IP;
  return 0;
#else
  env->die(env, stack, "IPPROTO_IP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPPROTO_SCTP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPPROTO_SCTP
  stack[0].ival = IPPROTO_SCTP;
  return 0;
#else
  env->die(env, stack, "IPPROTO_SCTP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPPROTO_TCP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPPROTO_TCP
  stack[0].ival = IPPROTO_TCP;
  return 0;
#else
  env->die(env, stack, "IPPROTO_TCP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPPROTO_UDP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPPROTO_UDP
  stack[0].ival = IPPROTO_UDP;
  return 0;
#else
  env->die(env, stack, "IPPROTO_UDP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPPROTO_UDPLITE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPPROTO_UDPLITE
  stack[0].ival = IPPROTO_UDPLITE;
  return 0;
#else
  env->die(env, stack, "IPPROTO_UDPLITE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPTOS_LOWDELAY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPTOS_LOWDELAY
  stack[0].ival = IPTOS_LOWDELAY;
  return 0;
#else
  env->die(env, stack, "IPTOS_LOWDELAY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPTOS_MINCOST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPTOS_MINCOST
  stack[0].ival = IPTOS_MINCOST;
  return 0;
#else
  env->die(env, stack, "IPTOS_MINCOST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPTOS_RELIABILITY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPTOS_RELIABILITY
  stack[0].ival = IPTOS_RELIABILITY;
  return 0;
#else
  env->die(env, stack, "IPTOS_RELIABILITY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPTOS_THROUGHPUT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPTOS_THROUGHPUT
  stack[0].ival = IPTOS_THROUGHPUT;
  return 0;
#else
  env->die(env, stack, "IPTOS_THROUGHPUT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_ADD_MEMBERSHIP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_ADD_MEMBERSHIP
  stack[0].ival = IP_ADD_MEMBERSHIP;
  return 0;
#else
  env->die(env, stack, "IP_ADD_MEMBERSHIP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_ADD_SOURCE_MEMBERSHIP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_ADD_SOURCE_MEMBERSHIP
  stack[0].ival = IP_ADD_SOURCE_MEMBERSHIP;
  return 0;
#else
  env->die(env, stack, "IP_ADD_SOURCE_MEMBERSHIP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_BIND_ADDRESS_NO_PORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_BIND_ADDRESS_NO_PORT
  stack[0].ival = IP_BIND_ADDRESS_NO_PORT;
  return 0;
#else
  env->die(env, stack, "IP_BIND_ADDRESS_NO_PORT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_BLOCK_SOURCE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_BLOCK_SOURCE
  stack[0].ival = IP_BLOCK_SOURCE;
  return 0;
#else
  env->die(env, stack, "IP_BLOCK_SOURCE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_DROP_MEMBERSHIP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_DROP_MEMBERSHIP
  stack[0].ival = IP_DROP_MEMBERSHIP;
  return 0;
#else
  env->die(env, stack, "IP_DROP_MEMBERSHIP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_DROP_SOURCE_MEMBERSHIP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_DROP_SOURCE_MEMBERSHIP
  stack[0].ival = IP_DROP_SOURCE_MEMBERSHIP;
  return 0;
#else
  env->die(env, stack, "IP_DROP_SOURCE_MEMBERSHIP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_FREEBIND(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_FREEBIND
  stack[0].ival = IP_FREEBIND;
  return 0;
#else
  env->die(env, stack, "IP_FREEBIND is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_HDRINCL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_HDRINCL
  stack[0].ival = IP_HDRINCL;
  return 0;
#else
  env->die(env, stack, "IP_HDRINCL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_MSFILTER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_MSFILTER
  stack[0].ival = IP_MSFILTER;
  return 0;
#else
  env->die(env, stack, "IP_MSFILTER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_MTU(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_MTU
  stack[0].ival = IP_MTU;
  return 0;
#else
  env->die(env, stack, "IP_MTU is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_MTU_DISCOVER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_MTU_DISCOVER
  stack[0].ival = IP_MTU_DISCOVER;
  return 0;
#else
  env->die(env, stack, "IP_MTU_DISCOVER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_MULTICAST_ALL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_MULTICAST_ALL
  stack[0].ival = IP_MULTICAST_ALL;
  return 0;
#else
  env->die(env, stack, "IP_MULTICAST_ALL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_MULTICAST_IF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_MULTICAST_IF
  stack[0].ival = IP_MULTICAST_IF;
  return 0;
#else
  env->die(env, stack, "IP_MULTICAST_IF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_MULTICAST_LOOP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_MULTICAST_LOOP
  stack[0].ival = IP_MULTICAST_LOOP;
  return 0;
#else
  env->die(env, stack, "IP_MULTICAST_LOOP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_MULTICAST_TTL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_MULTICAST_TTL
  stack[0].ival = IP_MULTICAST_TTL;
  return 0;
#else
  env->die(env, stack, "IP_MULTICAST_TTL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_NODEFRAG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_NODEFRAG
  stack[0].ival = IP_NODEFRAG;
  return 0;
#else
  env->die(env, stack, "IP_NODEFRAG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_OPTION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_OPTION
  stack[0].ival = IP_OPTION;
  return 0;
#else
  env->die(env, stack, "IP_OPTION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_OPTIONS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_OPTIONS
  stack[0].ival = IP_OPTIONS;
  return 0;
#else
  env->die(env, stack, "IP_OPTIONS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_ORIGDSTADDR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_ORIGDSTADDR
  stack[0].ival = IP_ORIGDSTADDR;
  return 0;
#else
  env->die(env, stack, "IP_ORIGDSTADDR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_PASSSEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_PASSSEC
  stack[0].ival = IP_PASSSEC;
  return 0;
#else
  env->die(env, stack, "IP_PASSSEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_PKTINFO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_PKTINFO
  stack[0].ival = IP_PKTINFO;
  return 0;
#else
  env->die(env, stack, "IP_PKTINFO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_PMTUDISC_DO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_PMTUDISC_DO
  stack[0].ival = IP_PMTUDISC_DO;
  return 0;
#else
  env->die(env, stack, "IP_PMTUDISC_DO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_PMTUDISC_DONT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_PMTUDISC_DONT
  stack[0].ival = IP_PMTUDISC_DONT;
  return 0;
#else
  env->die(env, stack, "IP_PMTUDISC_DONT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_PMTUDISC_PROBE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_PMTUDISC_PROBE
  stack[0].ival = IP_PMTUDISC_PROBE;
  return 0;
#else
  env->die(env, stack, "IP_PMTUDISC_PROBE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_PMTUDISC_WANT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_PMTUDISC_WANT
  stack[0].ival = IP_PMTUDISC_WANT;
  return 0;
#else
  env->die(env, stack, "IP_PMTUDISC_WANT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_RCVDSTADDR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_RCVDSTADDR
  stack[0].ival = IP_RCVDSTADDR;
  return 0;
#else
  env->die(env, stack, "IP_RCVDSTADDR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_RECVERR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_RECVERR
  stack[0].ival = IP_RECVERR;
  return 0;
#else
  env->die(env, stack, "IP_RECVERR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_RECVIF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_RECVIF
  stack[0].ival = IP_RECVIF;
  return 0;
#else
  env->die(env, stack, "IP_RECVIF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_RECVOPTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_RECVOPTS
  stack[0].ival = IP_RECVOPTS;
  return 0;
#else
  env->die(env, stack, "IP_RECVOPTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_RECVORIGDSTADDR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_RECVORIGDSTADDR
  stack[0].ival = IP_RECVORIGDSTADDR;
  return 0;
#else
  env->die(env, stack, "IP_RECVORIGDSTADDR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_RECVTOS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_RECVTOS
  stack[0].ival = IP_RECVTOS;
  return 0;
#else
  env->die(env, stack, "IP_RECVTOS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_RECVTTL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_RECVTTL
  stack[0].ival = IP_RECVTTL;
  return 0;
#else
  env->die(env, stack, "IP_RECVTTL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_RETOPTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_RETOPTS
  stack[0].ival = IP_RETOPTS;
  return 0;
#else
  env->die(env, stack, "IP_RETOPTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_ROUTER_ALERT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_ROUTER_ALERT
  stack[0].ival = IP_ROUTER_ALERT;
  return 0;
#else
  env->die(env, stack, "IP_ROUTER_ALERT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_TOS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_TOS
  stack[0].ival = IP_TOS;
  return 0;
#else
  env->die(env, stack, "IP_TOS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_TRANSPARENT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_TRANSPARENT
  stack[0].ival = IP_TRANSPARENT;
  return 0;
#else
  env->die(env, stack, "IP_TRANSPARENT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_TTL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_TTL
  stack[0].ival = IP_TTL;
  return 0;
#else
  env->die(env, stack, "IP_TTL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IP_UNBLOCK_SOURCE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IP_UNBLOCK_SOURCE
  stack[0].ival = IP_UNBLOCK_SOURCE;
  return 0;
#else
  env->die(env, stack, "IP_UNBLOCK_SOURCE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MCAST_EXCLUDE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MCAST_EXCLUDE
  stack[0].ival = MCAST_EXCLUDE;
  return 0;
#else
  env->die(env, stack, "MCAST_EXCLUDE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MCAST_INCLUDE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MCAST_INCLUDE
  stack[0].ival = MCAST_INCLUDE;
  return 0;
#else
  env->die(env, stack, "MCAST_INCLUDE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_CMSG_CLOEXEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_CMSG_CLOEXEC
  stack[0].ival = MSG_CMSG_CLOEXEC;
  return 0;
#else
  env->die(env, stack, "MSG_CMSG_CLOEXEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_CONFIRM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_CONFIRM
  stack[0].ival = MSG_CONFIRM;
  return 0;
#else
  env->die(env, stack, "MSG_CONFIRM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_CTRUNC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_CTRUNC
  stack[0].ival = MSG_CTRUNC;
  return 0;
#else
  env->die(env, stack, "MSG_CTRUNC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_DONTROUTE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_DONTROUTE
  stack[0].ival = MSG_DONTROUTE;
  return 0;
#else
  env->die(env, stack, "MSG_DONTROUTE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_DONTWAIT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_DONTWAIT
  stack[0].ival = MSG_DONTWAIT;
  return 0;
#else
  env->die(env, stack, "MSG_DONTWAIT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_EOR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_EOR
  stack[0].ival = MSG_EOR;
  return 0;
#else
  env->die(env, stack, "MSG_EOR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_ERRQUEUE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_ERRQUEUE
  stack[0].ival = MSG_ERRQUEUE;
  return 0;
#else
  env->die(env, stack, "MSG_ERRQUEUE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_ERRQUIE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_ERRQUIE
  stack[0].ival = MSG_ERRQUIE;
  return 0;
#else
  env->die(env, stack, "MSG_ERRQUIE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_MORE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_MORE
  stack[0].ival = MSG_MORE;
  return 0;
#else
  env->die(env, stack, "MSG_MORE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_NOSIGNAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_NOSIGNAL
  stack[0].ival = MSG_NOSIGNAL;
  return 0;
#else
  env->die(env, stack, "MSG_NOSIGNAL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_OOB(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_OOB
  stack[0].ival = MSG_OOB;
  return 0;
#else
  env->die(env, stack, "MSG_OOB is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_PEEK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_PEEK
  stack[0].ival = MSG_PEEK;
  return 0;
#else
  env->die(env, stack, "MSG_PEEK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_TRUNC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_TRUNC
  stack[0].ival = MSG_TRUNC;
  return 0;
#else
  env->die(env, stack, "MSG_TRUNC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__MSG_WAITALL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_WAITALL
  stack[0].ival = MSG_WAITALL;
  return 0;
#else
  env->die(env, stack, "MSG_WAITALL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__PF_INET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef PF_INET
  stack[0].ival = PF_INET;
  return 0;
#else
  env->die(env, stack, "PF_INET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__PF_UNIX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef PF_UNIX
  stack[0].ival = PF_UNIX;
  return 0;
#else
  env->die(env, stack, "PF_UNIX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SCM_RIGHTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SCM_RIGHTS
  stack[0].ival = SCM_RIGHTS;
  return 0;
#else
  env->die(env, stack, "SCM_RIGHTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SCM_SECURITY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SCM_SECURITY
  stack[0].ival = SCM_SECURITY;
  return 0;
#else
  env->die(env, stack, "SCM_SECURITY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOCK_CLOEXEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOCK_CLOEXEC
  stack[0].ival = SOCK_CLOEXEC;
  return 0;
#else
  env->die(env, stack, "SOCK_CLOEXEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOCK_DGRAM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOCK_DGRAM
  stack[0].ival = SOCK_DGRAM;
  return 0;
#else
  env->die(env, stack, "SOCK_DGRAM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOCK_NONBLOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOCK_NONBLOCK
  stack[0].ival = SOCK_NONBLOCK;
  return 0;
#else
  env->die(env, stack, "SOCK_NONBLOCK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOCK_PACKET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOCK_PACKET
  stack[0].ival = SOCK_PACKET;
  return 0;
#else
  env->die(env, stack, "SOCK_PACKET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOCK_RAW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOCK_RAW
  stack[0].ival = SOCK_RAW;
  return 0;
#else
  env->die(env, stack, "SOCK_RAW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOCK_RDM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOCK_RDM
  stack[0].ival = SOCK_RDM;
  return 0;
#else
  env->die(env, stack, "SOCK_RDM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOCK_SEQPACKET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOCK_SEQPACKET
  stack[0].ival = SOCK_SEQPACKET;
  return 0;
#else
  env->die(env, stack, "SOCK_SEQPACKET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOCK_STREAM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOCK_STREAM
  stack[0].ival = SOCK_STREAM;
  return 0;
#else
  env->die(env, stack, "SOCK_STREAM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOL_IP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOL_IP
  stack[0].ival = SOL_IP;
  return 0;
#else
  env->die(env, stack, "SOL_IP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOL_SOCKET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOL_SOCKET
  stack[0].ival = SOL_SOCKET;
  return 0;
#else
  env->die(env, stack, "SOL_SOCKET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SOMAXCONN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SOMAXCONN
  stack[0].ival = SOMAXCONN;
  return 0;
#else
  env->die(env, stack, "SOMAXCONN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_BROADCAST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_BROADCAST
  stack[0].ival = SO_BROADCAST;
  return 0;
#else
  env->die(env, stack, "SO_BROADCAST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_EE_OFFENDER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_EE_OFFENDER
  stack[0].ival = SO_EE_OFFENDER;
  return 0;
#else
  env->die(env, stack, "SO_EE_OFFENDER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_EE_ORIGIN_ICMP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_EE_ORIGIN_ICMP
  stack[0].ival = SO_EE_ORIGIN_ICMP;
  return 0;
#else
  env->die(env, stack, "SO_EE_ORIGIN_ICMP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_EE_ORIGIN_ICMP6(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_EE_ORIGIN_ICMP6
  stack[0].ival = SO_EE_ORIGIN_ICMP6;
  return 0;
#else
  env->die(env, stack, "SO_EE_ORIGIN_ICMP6 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_EE_ORIGIN_LOCAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_EE_ORIGIN_LOCAL
  stack[0].ival = SO_EE_ORIGIN_LOCAL;
  return 0;
#else
  env->die(env, stack, "SO_EE_ORIGIN_LOCAL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_EE_ORIGIN_NONE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_EE_ORIGIN_NONE
  stack[0].ival = SO_EE_ORIGIN_NONE;
  return 0;
#else
  env->die(env, stack, "SO_EE_ORIGIN_NONE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_ERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_ERROR
  stack[0].ival = SO_ERROR;
  return 0;
#else
  env->die(env, stack, "SO_ERROR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_KEEPALIVE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_KEEPALIVE
  stack[0].ival = SO_KEEPALIVE;
  return 0;
#else
  env->die(env, stack, "SO_KEEPALIVE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_PEERSEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_PEERSEC
  stack[0].ival = SO_PEERSEC;
  return 0;
#else
  env->die(env, stack, "SO_PEERSEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__SO_REUSEADDR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_REUSEADDR
  stack[0].ival = SO_REUSEADDR;
  return 0;
#else
  env->die(env, stack, "SO_REUSEADDR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__TCP_CORK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_CORK
  stack[0].ival = TCP_CORK;
  return 0;
#else
  env->die(env, stack, "TCP_CORK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__UDP_CORK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef UDP_CORK
  stack[0].ival = UDP_CORK;
  return 0;
#else
  env->die(env, stack, "UDP_CORK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__INET_ADDRSTRLEN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef INET_ADDRSTRLEN
  stack[0].ival = INET_ADDRSTRLEN;
  return 0;
#else
  env->die(env, stack, "INET_ADDRSTRLEN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__INET6_ADDRSTRLEN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef INET6_ADDRSTRLEN
  stack[0].ival = INET6_ADDRSTRLEN;
  return 0;
#else
  env->die(env, stack, "INET6_ADDRSTRLEN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__Socket__Constant__IPPROTO_IPV6(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPPROTO_IPV6
  stack[0].ival = IPPROTO_IPV6;
  return 0;
#else
  env->die(env, stack, "IPPROTO_IPV6 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPPROTO_ICMP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPPROTO_ICMP
  stack[0].ival = IPPROTO_ICMP;
  return 0;
#else
  env->die(env, stack, "IPPROTO_ICMP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_ADDRFORM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_ADDRFORM
  stack[0].ival = IPV6_ADDRFORM;
  return 0;
#else
  env->die(env, stack, "IPV6_ADDRFORM is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_ADD_MEMBERSHIP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_ADD_MEMBERSHIP
  stack[0].ival = IPV6_ADD_MEMBERSHIP;
  return 0;
#else
  env->die(env, stack, "IPV6_ADD_MEMBERSHIP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_AUTHHDR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_AUTHHDR
  stack[0].ival = IPV6_AUTHHDR;
  return 0;
#else
  env->die(env, stack, "IPV6_AUTHHDR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_DROP_MEMBERSHIP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_DROP_MEMBERSHIP
  stack[0].ival = IPV6_DROP_MEMBERSHIP;
  return 0;
#else
  env->die(env, stack, "IPV6_DROP_MEMBERSHIP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_DSTOPS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_DSTOPS
  stack[0].ival = IPV6_DSTOPS;
  return 0;
#else
  env->die(env, stack, "IPV6_DSTOPS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_DSTOPTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_DSTOPTS
  stack[0].ival = IPV6_DSTOPTS;
  return 0;
#else
  env->die(env, stack, "IPV6_DSTOPTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_FLOWINFO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_FLOWINFO
  stack[0].ival = IPV6_FLOWINFO;
  return 0;
#else
  env->die(env, stack, "IPV6_FLOWINFO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_HOPLIMIT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_HOPLIMIT
  stack[0].ival = IPV6_HOPLIMIT;
  return 0;
#else
  env->die(env, stack, "IPV6_HOPLIMIT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_HOPOPTS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_HOPOPTS
  stack[0].ival = IPV6_HOPOPTS;
  return 0;
#else
  env->die(env, stack, "IPV6_HOPOPTS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_MTU(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_MTU
  stack[0].ival = IPV6_MTU;
  return 0;
#else
  env->die(env, stack, "IPV6_MTU is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_MTU_DISCOVER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_MTU_DISCOVER
  stack[0].ival = IPV6_MTU_DISCOVER;
  return 0;
#else
  env->die(env, stack, "IPV6_MTU_DISCOVER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_MULTICAST_HOPS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_MULTICAST_HOPS
  stack[0].ival = IPV6_MULTICAST_HOPS;
  return 0;
#else
  env->die(env, stack, "IPV6_MULTICAST_HOPS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_MULTICAST_IF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_MULTICAST_IF
  stack[0].ival = IPV6_MULTICAST_IF;
  return 0;
#else
  env->die(env, stack, "IPV6_MULTICAST_IF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_MULTICAST_LOOP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_MULTICAST_LOOP
  stack[0].ival = IPV6_MULTICAST_LOOP;
  return 0;
#else
  env->die(env, stack, "IPV6_MULTICAST_LOOP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_PKTINFO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_PKTINFO
  stack[0].ival = IPV6_PKTINFO;
  return 0;
#else
  env->die(env, stack, "IPV6_PKTINFO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_RECVERR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_RECVERR
  stack[0].ival = IPV6_RECVERR;
  return 0;
#else
  env->die(env, stack, "IPV6_RECVERR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_ROUTER_ALERT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_ROUTER_ALERT
  stack[0].ival = IPV6_ROUTER_ALERT;
  return 0;
#else
  env->die(env, stack, "IPV6_ROUTER_ALERT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_RTHDR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_RTHDR
  stack[0].ival = IPV6_RTHDR;
  return 0;
#else
  env->die(env, stack, "IPV6_RTHDR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_UNICAST_HOPS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_UNICAST_HOPS
  stack[0].ival = IPV6_UNICAST_HOPS;
  return 0;
#else
  env->die(env, stack, "IPV6_UNICAST_HOPS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IPV6_V6ONLY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IPV6_V6ONLY
  stack[0].ival = IPV6_V6ONLY;
  return 0;
#else
  env->die(env, stack, "IPV6_V6ONLY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__PF_INET6(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef PF_INET6
  stack[0].ival = PF_INET6;
  return 0;
#else
  env->die(env, stack, "PF_INET6 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_ACCEPTCONN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_ACCEPTCONN
  stack[0].ival = SO_ACCEPTCONN;
  return 0;
#else
  env->die(env, stack, "SO_ACCEPTCONN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_ATTACH_BPF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_ATTACH_BPF
  stack[0].ival = SO_ATTACH_BPF;
  return 0;
#else
  env->die(env, stack, "SO_ATTACH_BPF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_ATTACH_FILTER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_ATTACH_FILTER
  stack[0].ival = SO_ATTACH_FILTER;
  return 0;
#else
  env->die(env, stack, "SO_ATTACH_FILTER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_ATTACH_REUSEPORT_CBPF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_ATTACH_REUSEPORT_CBPF
  stack[0].ival = SO_ATTACH_REUSEPORT_CBPF;
  return 0;
#else
  env->die(env, stack, "SO_ATTACH_REUSEPORT_CBPF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_ATTACH_REUSEPORT_EBPF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_ATTACH_REUSEPORT_EBPF
  stack[0].ival = SO_ATTACH_REUSEPORT_EBPF;
  return 0;
#else
  env->die(env, stack, "SO_ATTACH_REUSEPORT_EBPF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_BINDTODEVICE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_BINDTODEVICE
  stack[0].ival = SO_BINDTODEVICE;
  return 0;
#else
  env->die(env, stack, "SO_BINDTODEVICE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_BSDCOMPAT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_BSDCOMPAT
  stack[0].ival = SO_BSDCOMPAT;
  return 0;
#else
  env->die(env, stack, "SO_BSDCOMPAT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_BUSY_POLL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_BUSY_POLL
  stack[0].ival = SO_BUSY_POLL;
  return 0;
#else
  env->die(env, stack, "SO_BUSY_POLL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_DEBUG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_DEBUG
  stack[0].ival = SO_DEBUG;
  return 0;
#else
  env->die(env, stack, "SO_DEBUG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_DETACH_BPF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_DETACH_BPF
  stack[0].ival = SO_DETACH_BPF;
  return 0;
#else
  env->die(env, stack, "SO_DETACH_BPF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_DETACH_FILTER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_DETACH_FILTER
  stack[0].ival = SO_DETACH_FILTER;
  return 0;
#else
  env->die(env, stack, "SO_DETACH_FILTER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_DOMAIN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_DOMAIN
  stack[0].ival = SO_DOMAIN;
  return 0;
#else
  env->die(env, stack, "SO_DOMAIN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_DONTROUTE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_DONTROUTE
  stack[0].ival = SO_DONTROUTE;
  return 0;
#else
  env->die(env, stack, "SO_DONTROUTE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_INCOMING_CPU(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_INCOMING_CPU
  stack[0].ival = SO_INCOMING_CPU;
  return 0;
#else
  env->die(env, stack, "SO_INCOMING_CPU is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_INCOMING_NAPI_ID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_INCOMING_NAPI_ID
  stack[0].ival = SO_INCOMING_NAPI_ID;
  return 0;
#else
  env->die(env, stack, "SO_INCOMING_NAPI_ID is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_LINGER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_LINGER
  stack[0].ival = SO_LINGER;
  return 0;
#else
  env->die(env, stack, "SO_LINGER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_LOCK_FILTER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_LOCK_FILTER
  stack[0].ival = SO_LOCK_FILTER;
  return 0;
#else
  env->die(env, stack, "SO_LOCK_FILTER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_MARK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_MARK
  stack[0].ival = SO_MARK;
  return 0;
#else
  env->die(env, stack, "SO_MARK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_OOBINLINE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_OOBINLINE
  stack[0].ival = SO_OOBINLINE;
  return 0;
#else
  env->die(env, stack, "SO_OOBINLINE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_PASSCRED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_PASSCRED
  stack[0].ival = SO_PASSCRED;
  return 0;
#else
  env->die(env, stack, "SO_PASSCRED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_PASSSEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_PASSSEC
  stack[0].ival = SO_PASSSEC;
  return 0;
#else
  env->die(env, stack, "SO_PASSSEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_PEEK_OFF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_PEEK_OFF
  stack[0].ival = SO_PEEK_OFF;
  return 0;
#else
  env->die(env, stack, "SO_PEEK_OFF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_PEERCRED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_PEERCRED
  stack[0].ival = SO_PEERCRED;
  return 0;
#else
  env->die(env, stack, "SO_PEERCRED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_PRIORITY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_PRIORITY
  stack[0].ival = SO_PRIORITY;
  return 0;
#else
  env->die(env, stack, "SO_PRIORITY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_PROTOCOL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_PROTOCOL
  stack[0].ival = SO_PROTOCOL;
  return 0;
#else
  env->die(env, stack, "SO_PROTOCOL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_RCVBUF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_RCVBUF
  stack[0].ival = SO_RCVBUF;
  return 0;
#else
  env->die(env, stack, "SO_RCVBUF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_RCVBUFFORCE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_RCVBUFFORCE
  stack[0].ival = SO_RCVBUFFORCE;
  return 0;
#else
  env->die(env, stack, "SO_RCVBUFFORCE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_RCVLOWAT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_RCVLOWAT
  stack[0].ival = SO_RCVLOWAT;
  return 0;
#else
  env->die(env, stack, "SO_RCVLOWAT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_RCVTIMEO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_RCVTIMEO
  stack[0].ival = SO_RCVTIMEO;
  return 0;
#else
  env->die(env, stack, "SO_RCVTIMEO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_REUSEPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_REUSEPORT
  stack[0].ival = SO_REUSEPORT;
  return 0;
#else
  env->die(env, stack, "SO_REUSEPORT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_RXQ_OVFL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_RXQ_OVFL
  stack[0].ival = SO_RXQ_OVFL;
  return 0;
#else
  env->die(env, stack, "SO_RXQ_OVFL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_SELECT_ERR_QUEUE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_SELECT_ERR_QUEUE
  stack[0].ival = SO_SELECT_ERR_QUEUE;
  return 0;
#else
  env->die(env, stack, "SO_SELECT_ERR_QUEUE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_SNDBUF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_SNDBUF
  stack[0].ival = SO_SNDBUF;
  return 0;
#else
  env->die(env, stack, "SO_SNDBUF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_SNDBUFFORCE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_SNDBUFFORCE
  stack[0].ival = SO_SNDBUFFORCE;
  return 0;
#else
  env->die(env, stack, "SO_SNDBUFFORCE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_SNDLOWAT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_SNDLOWAT
  stack[0].ival = SO_SNDLOWAT;
  return 0;
#else
  env->die(env, stack, "SO_SNDLOWAT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_SNDTIMEO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_SNDTIMEO
  stack[0].ival = SO_SNDTIMEO;
  return 0;
#else
  env->die(env, stack, "SO_SNDTIMEO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_TIMESTAMP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_TIMESTAMP
  stack[0].ival = SO_TIMESTAMP;
  return 0;
#else
  env->die(env, stack, "SO_TIMESTAMP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_TIMESTAMPNS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_TIMESTAMPNS
  stack[0].ival = SO_TIMESTAMPNS;
  return 0;
#else
  env->die(env, stack, "SO_TIMESTAMPNS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__SO_TYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SO_TYPE
  stack[0].ival = SO_TYPE;
  return 0;
#else
  env->die(env, stack, "SO_TYPE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__MSG_BCAST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_BCAST
  stack[0].ival = MSG_BCAST;
  return 0;
#else
  env->die(env, stack, "MSG_BCAST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__MSG_COPY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_COPY
  stack[0].ival = MSG_COPY;
  return 0;
#else
  env->die(env, stack, "MSG_COPY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__MSG_EXCEPT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_EXCEPT
  stack[0].ival = MSG_EXCEPT;
  return 0;
#else
  env->die(env, stack, "MSG_EXCEPT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__MSG_MCAST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_MCAST
  stack[0].ival = MSG_MCAST;
  return 0;
#else
  env->die(env, stack, "MSG_MCAST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__MSG_NOERROR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef MSG_NOERROR
  stack[0].ival = MSG_NOERROR;
  return 0;
#else
  env->die(env, stack, "MSG_NOERROR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}


int32_t SPVM__Sys__Socket__Constant__SHUT_RD(SPVM_ENV* env, SPVM_VALUE* stack) {

  stack[0].ival = 0;
  
  return 0;
}


int32_t SPVM__Sys__Socket__Constant__SHUT_WR(SPVM_ENV* env, SPVM_VALUE* stack) {

  stack[0].ival = 1;
  
  return 0;
}


int32_t SPVM__Sys__Socket__Constant__SHUT_RDWR(SPVM_ENV* env, SPVM_VALUE* stack) {

  stack[0].ival = 2;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Constant__TCP_CONGESTION(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_CONGESTION
  stack[0].ival = TCP_CONGESTION;
  return 0;
#else
  env->die(env, stack, "TCP_CONGESTION is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_DEFER_ACCEPT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_DEFER_ACCEPT
  stack[0].ival = TCP_DEFER_ACCEPT;
  return 0;
#else
  env->die(env, stack, "TCP_DEFER_ACCEPT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_INFO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_INFO
  stack[0].ival = TCP_INFO;
  return 0;
#else
  env->die(env, stack, "TCP_INFO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_KEEPCNT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_KEEPCNT
  stack[0].ival = TCP_KEEPCNT;
  return 0;
#else
  env->die(env, stack, "TCP_KEEPCNT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_KEEPIDLE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_KEEPIDLE
  stack[0].ival = TCP_KEEPIDLE;
  return 0;
#else
  env->die(env, stack, "TCP_KEEPIDLE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_KEEPINTVL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_KEEPINTVL
  stack[0].ival = TCP_KEEPINTVL;
  return 0;
#else
  env->die(env, stack, "TCP_KEEPINTVL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_LINGER2(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_LINGER2
  stack[0].ival = TCP_LINGER2;
  return 0;
#else
  env->die(env, stack, "TCP_LINGER2 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_MAXSEG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_MAXSEG
  stack[0].ival = TCP_MAXSEG;
  return 0;
#else
  env->die(env, stack, "TCP_MAXSEG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_NODELAY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_NODELAY
  stack[0].ival = TCP_NODELAY;
  return 0;
#else
  env->die(env, stack, "TCP_NODELAY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_QUICKACK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_QUICKACK
  stack[0].ival = TCP_QUICKACK;
  return 0;
#else
  env->die(env, stack, "TCP_QUICKACK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_SYNCNT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_SYNCNT
  stack[0].ival = TCP_SYNCNT;
  return 0;
#else
  env->die(env, stack, "TCP_SYNCNT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_SYNQ_HSIZE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_SYNQ_HSIZE
  stack[0].ival = TCP_SYNQ_HSIZE;
  return 0;
#else
  env->die(env, stack, "TCP_SYNQ_HSIZE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_USER_TIMEOUT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_USER_TIMEOUT
  stack[0].ival = TCP_USER_TIMEOUT;
  return 0;
#else
  env->die(env, stack, "TCP_USER_TIMEOUT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__TCP_WINDOW_CLAMP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TCP_WINDOW_CLAMP
  stack[0].ival = TCP_WINDOW_CLAMP;
  return 0;
#else
  env->die(env, stack, "TCP_WINDOW_CLAMP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IN6ADDR_ANY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IN6ADDR_ANY_INIT
  struct in6_addr address_init = IN6ADDR_ANY_INIT;
  
  struct in6_addr* address = env->new_memory_stack(env, stack, sizeof(struct in6_addr));
  
  int32_t e = 0;
  void* obj_address = env->new_pointer_by_name(env, stack, "Sys::Socket::In6_addr", address, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_address;
  return 0;
#else
  env->die(env, stack, "IN6ADDR_ANY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__IN6ADDR_LOOPBACK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef IN6ADDR_LOOPBACK_INIT
  struct in6_addr address_init = IN6ADDR_LOOPBACK_INIT;
  
  struct in6_addr* address = env->new_memory_stack(env, stack, sizeof(struct in6_addr));
  
  int32_t e = 0;
  void* obj_address = env->new_pointer_by_name(env, stack, "Sys::Socket::In6_addr", address, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_address;
  return 0;
#else
  env->die(env, stack, "IN6ADDR_LOOPBACK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__NI_MAXHOST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NI_MAXHOST
  stack[0].ival = NI_MAXHOST;
  return 0;
#else
  env->die(env, stack, "NI_MAXHOST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__NI_MAXSERV(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef NI_MAXSERV
  stack[0].ival = NI_MAXSERV;
  return 0;
#else
  env->die(env, stack, "NI_MAXSERV is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_ADDRESS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_ADDRESS
  stack[0].ival = ICMP_ADDRESS;
  return 0;
#else
  env->die(env, stack, "ICMP_ADDRESS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_DEST_UNREACH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_DEST_UNREACH
  stack[0].ival = ICMP_DEST_UNREACH;
  return 0;
#else
  env->die(env, stack, "ICMP_DEST_UNREACH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_ECHO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_ECHO
  stack[0].ival = ICMP_ECHO;
  return 0;
#else
  env->die(env, stack, "ICMP_ECHO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_ECHOREPLY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_ECHOREPLY
  stack[0].ival = ICMP_ECHOREPLY;
  return 0;
#else
  env->die(env, stack, "ICMP_ECHOREPLY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_ECHOREQUEST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_ECHOREQUEST
  stack[0].ival = ICMP_ECHOREQUEST;
  return 0;
#else
  env->die(env, stack, "ICMP_ECHOREQUEST is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_FILTER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_FILTER
  stack[0].ival = ICMP_FILTER;
  return 0;
#else
  env->die(env, stack, "ICMP_FILTER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_FRAG_NEEDED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_FRAG_NEEDED
  stack[0].ival = ICMP_FRAG_NEEDED;
  return 0;
#else
  env->die(env, stack, "ICMP_FRAG_NEEDED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_PARAMETERPROB(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_PARAMETERPROB
  stack[0].ival = ICMP_PARAMETERPROB;
  return 0;
#else
  env->die(env, stack, "ICMP_PARAMETERPROB is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_REDIRECT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_REDIRECT
  stack[0].ival = ICMP_REDIRECT;
  return 0;
#else
  env->die(env, stack, "ICMP_REDIRECT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_SOURCE_QUENCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_SOURCE_QUENCH
  stack[0].ival = ICMP_SOURCE_QUENCH;
  return 0;
#else
  env->die(env, stack, "ICMP_SOURCE_QUENCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_TIMESTAMP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_TIMESTAMP
  stack[0].ival = ICMP_TIMESTAMP;
  return 0;
#else
  env->die(env, stack, "ICMP_TIMESTAMP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Socket__Constant__ICMP_TIME_EXCEEDED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ICMP_TIME_EXCEEDED
  stack[0].ival = ICMP_TIME_EXCEEDED;
  return 0;
#else
  env->die(env, stack, "ICMP_TIME_EXCEEDED is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}
