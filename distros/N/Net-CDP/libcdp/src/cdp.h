/*
 * $Id: cdp.h,v 1.3 2005/07/20 13:44:13 mchapman Exp $
 */

#ifndef _CDP_H
#define _CDP_H

#include <stddef.h>
#include <stdint.h>
#include <netinet/in.h>

#ifdef __cplusplus
extern "C" {
#endif

/******************************************************************************/

/*
 * The size of the error buffer to be passed to functions that expect one.
 */
#define CDP_ERRBUF_SIZE 256

/******************************************************************************/

/*
 * Dup and free operators for data stored in linked lists.
 */
typedef void * (*cdp_dup_fn_t)(const void *);
typedef void (*cdp_free_fn_t)(void *);

/*
 * Opaque container for a linked list node.
 */
typedef struct _cdp_llist_item {
	struct _cdp_llist_item *next;
	void *x;
} cdp_llist_item_t;

/*
 * Opaque linked list. Items on a linked list must have a "void *next"
 * member.
 */
typedef struct {
	cdp_dup_fn_t dup_fn;
	cdp_free_fn_t free_fn;
	uint32_t count;
	
	cdp_llist_item_t *head;
	cdp_llist_item_t *tail;
} cdp_llist_t;

/*
 * Linked lists are append-only. This means they only ever grow, and
 * elements will appear in the list in the order in which they were
 * added.
 *
 * The cdp_llist_dup function makes a deep copy of the specified llist
 * using the cdp_dup_fn_t that was provided when the llist was created.
 *
 * Similarly, cdp_llist_free deeply frees the llist using the cdp_free_fn_t
 * provided when the llist was created.
 */
cdp_llist_t * cdp_llist_new(cdp_dup_fn_t, cdp_free_fn_t);
cdp_llist_t * cdp_llist_dup(const cdp_llist_t *);
void cdp_llist_append(cdp_llist_t *, void *);
void cdp_llist_transfer(cdp_llist_t *, cdp_llist_t *);
void cdp_llist_free(cdp_llist_t *);

#define cdp_llist_count(LLIST) ((const uint32_t)((LLIST)->count))

/*
 * Linked list iterator.
 *
 * void frobnicate(item_t *);
 *
 * void frobnicate_all(const cdp_llist_t *llist) {
 *     cdp_llist_iter_t iter;
 * 
 *     for (iter = cdp_llist_iter(llist); iter; iter = cdp_llist_next(iter))
 *         frobnicate(cdp_llist_get(iter));
 * }
 */
typedef const cdp_llist_item_t *cdp_llist_iter_t;
#define cdp_llist_iter(LLIST) ((cdp_llist_iter_t)((LLIST)->head))
#define cdp_llist_get(ITER) ((ITER)->x)
#define cdp_llist_next(ITER) ((ITER)->next)

/******************************************************************************/

/*
 * Get a list of strings representing available ports.
 */
cdp_llist_t * cdp_get_ports(char *);

/*
 * Opaque CDP listener/advertiser object.
 */
typedef struct _cdp cdp_t;

/******************************************************************************/

/*
 * Predefined protocol_type/protocol_length/protocol combinations.
 */
#define CDP_ADDR_PROTO_CLNP      0
#define CDP_ADDR_PROTO_IPV4      1
#define CDP_ADDR_PROTO_IPV6      2
#define CDP_ADDR_PROTO_DECNET    3
#define CDP_ADDR_PROTO_APPLETALK 4
#define CDP_ADDR_PROTO_IPX       5
#define CDP_ADDR_PROTO_VINES     6
#define CDP_ADDR_PROTO_XNS       7
#define CDP_ADDR_PROTO_APOLLO    8

#define CDP_ADDR_PROTO_MAX       CDP_ADDR_PROTO_APOLLO

struct cdp_predef {
	uint8_t protocol_type;
	uint8_t protocol_length;
	void *protocol;
};

extern struct cdp_predef cdp_predefs[];

/*
 * CDP address object.
 */
struct cdp_address {
	uint8_t protocol_type;
	uint8_t protocol_length;
	void *protocol;
	uint16_t address_length;
	void *address;
};

struct cdp_address * cdp_address_new(
	uint8_t, uint8_t, const void *, uint8_t, const void *
);
struct cdp_address * cdp_address_dup(const struct cdp_address *);
void cdp_address_free(struct cdp_address *);

/******************************************************************************/

/*
 * CDP IP Prefix object.
 */
struct cdp_ip_prefix {
	struct in_addr network;
	uint8_t length;
};

struct cdp_ip_prefix * cdp_ip_prefix_new(struct in_addr, uint8_t);
struct cdp_ip_prefix * cdp_ip_prefix_dup(const struct cdp_ip_prefix *);
void cdp_ip_prefix_free(struct cdp_ip_prefix *);

/******************************************************************************/

struct cdp_appliance {
	uint8_t id;
	uint16_t vlan;
};

struct cdp_appliance * cdp_appliance_new(uint8_t, uint16_t);
struct cdp_appliance * cdp_appliance_dup(const struct cdp_appliance *);
void cdp_appliance_free(struct cdp_appliance *);

/******************************************************************************/

/*
 * CDP capabilities.
 */
#define CDP_CAP_ROUTER             0x01
#define CDP_CAP_TRANSPARENT_BRIDGE 0x02
#define CDP_CAP_SOURCE_BRIDGE      0x04
#define CDP_CAP_SWITCH             0x08
#define CDP_CAP_HOST               0x10
#define CDP_CAP_IGMP               0x20
#define CDP_CAP_REPEATER           0x40

/*
 * CDP packet.
 *
 * The packet field must always exist. It is always preallocated with
 * at least BUFSIZ bytes of space -- don't shrink it to less than this.
 *
 * packet_length indicates the number of bytes actually used in packet to
 * represent the CDP packet in encoded form. You don't need to touch this
 * since cdp_packet_update will update it as necessary.
 * 
 * You can fiddle with the fields directly. Any field which is a pointer can
 * also be NULL, indicating that the field does not "exist" in the packet,
 * ie. it wasn't received and it won't be sent.
 *
 * cdp_generate will generate a packet with most values filled out for you.
 * Pass a cdp_t * object in as the first argument to associate the packet with
 * the device used by that object.
 */
struct cdp_packet {
	void *packet;
	uint16_t packet_length;

	uint8_t version;
	uint8_t ttl;
	uint16_t checksum;
	char *device_id;
	cdp_llist_t *addresses;
	char *port_id;
	uint32_t *capabilities;
	char *ios_version;
	char *platform;
	cdp_llist_t *ip_prefixes;
	char *vtp_mgmt_domain;
	uint16_t *native_vlan;
	uint8_t *duplex;
	struct cdp_appliance *appliance;
	struct cdp_appliance *appliance_query;
	uint16_t *power_consumption;
	uint32_t *mtu;
	uint8_t *extended_trust;
	uint8_t *untrusted_cos;
	cdp_llist_t *mgmt_addresses;
};

struct cdp_packet * cdp_packet_generate(const cdp_t *);
struct cdp_packet * cdp_packet_dup(const struct cdp_packet *);
void cdp_packet_free(struct cdp_packet *);

/*
 * Update the packet, packet_length and checksum fields. You'll need to
 * call this before sending the packet, otherwise it will send the old data
 * stored in packet.
 */
int cdp_packet_update(struct cdp_packet *, char *);

/******************************************************************************/

/*
 * cdp_new flags.
 */
#define CDP_PROMISCUOUS        0x01
#define CDP_DISABLE_RECV       0x02
#define CDP_DISABLE_SEND       0x04

/*
 * cdp_recv flags.
 */
#define CDP_RECV_NONBLOCK      0x01
#define CDP_RECV_DECODE_ERRORS 0x02

cdp_t * cdp_new(const char *, int, char *);
void cdp_free(cdp_t *);

const char * cdp_get_port(const cdp_t *);
const cdp_llist_t * cdp_get_addresses(const cdp_t *);
const uint8_t * cdp_get_duplex(const cdp_t *);
int cdp_get_fd(const cdp_t *);

struct cdp_packet * cdp_recv(cdp_t *, int, char *);
int cdp_send(cdp_t *, const struct cdp_packet *, char *);

#ifdef __cplusplus
}
#endif

#endif /* _CDP_H */
