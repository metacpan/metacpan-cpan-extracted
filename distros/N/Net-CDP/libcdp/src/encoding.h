/*
 * $Id: encoding.h,v 1.1 2005/07/20 13:44:13 mchapman Exp $
 */

#ifndef _CDP_ENCODING_H
#define _CDP_ENCODING_H

#include <system.h>

/*
 * CDP chunk types.
 */
#define CDP_TYPE_DEVICE_ID         0x0001
#define CDP_TYPE_ADDRESS           0x0002
#define CDP_TYPE_PORT_ID           0x0003
#define CDP_TYPE_CAPABILITIES      0x0004
#define CDP_TYPE_IOS_VERSION       0x0005
#define CDP_TYPE_PLATFORM          0x0006
#define CDP_TYPE_IP_PREFIX         0x0007
#define CDP_TYPE_PROTOCOL_HELLO    0x0008
#define CDP_TYPE_VTP_MGMT_DOMAIN   0x0009
#define CDP_TYPE_NATIVE_VLAN       0x000a
#define CDP_TYPE_DUPLEX            0x000b
#define CDP_TYPE_UNKNOWN_0x000c    0x000c
#define CDP_TYPE_UNKNOWN_0x000d    0x000d
#define CDP_TYPE_APPLIANCE_REPLY   0x000e
#define CDP_TYPE_APPLIANCE_QUERY   0x000f
#define CDP_TYPE_POWER_CONSUMPTION 0x0010
#define CDP_TYPE_MTU               0x0011
#define CDP_TYPE_EXTENDED_TRUST    0x0012
#define CDP_TYPE_UNTRUSTED_COS     0x0013
#define CDP_TYPE_SYSTEM_NAME       0x0014
#define CDP_TYPE_SYSTEM_OID        0x0015
#define CDP_TYPE_MGMT_ADDRESS      0x0016
#define CDP_TYPE_LOCATION          0x0017

struct cdp_packet * cdp_decode(const void *, size_t, char *);
uint16_t cdp_decode_checksum(const void *, size_t);
size_t cdp_encode(const struct cdp_packet *, void *, size_t);

#endif /* _CDP_ENCODING_H */
