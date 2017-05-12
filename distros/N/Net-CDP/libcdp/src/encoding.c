/*
 * $Id: encoding.c,v 1.1 2005/07/20 13:44:13 mchapman Exp $
 */

#include <system.h>

#include <encoding.h>

#define GRAB(target, type, func) \
	((length >= sizeof(type)) && \
		( \
			target = func(*((type *)data)), \
			length -= sizeof(type), \
			data += sizeof(type), \
			1 \
		))
#define SKIP(bytes) \
	((length >= (bytes)) && \
		( \
			length -= (bytes), \
			data += (bytes), \
			1 \
		))
#define GRAB_UINT8(target) GRAB(target, uint8_t, )
#define GRAB_UINT16(target) GRAB(target, uint16_t, ntohs)
#define GRAB_UINT32(target) GRAB(target, uint32_t, ntohl)
#define GRAB_STRING(target, bytes) \
	((length >= (bytes)) && \
		( \
			target = SALLOC((bytes) + 1), \
			memcpy((target), data, (bytes) * sizeof(char)), \
			length -= (bytes), \
			data += (bytes), \
			1 \
		))

/* Hmm, egcs doesn't have variadic macros... */
#define _DECODE_ERROR(e)      sprintf(errors, "Corrupt CDP packet: " e)
#define _DECODE_ERROR2(e, e2) sprintf(errors, "Corrupt CDP packet: " e, e2)
#define _EOP(e)           _DECODE_ERROR("end-of-packet while reading " e)
#define _EOP2(e, e2)      _DECODE_ERROR2("end-of-packet while reading " e, e2)
#define _INVALID(e)       _DECODE_ERROR("invalid " e)
#define _INVALID2(e, e2)  _DECODE_ERROR2("invalid " e, e2)
#define _DUPLICATE(e)     _DECODE_ERROR("duplicate " e);

#define EOP(e)          do { _EOP(e);          goto fail; } while (0)
#define EOP2(e, e2)     do { _EOP2(e, e2);     goto fail; } while (0)
#define INVALID(e)      do { _INVALID(e);      goto fail; } while (0)
#define INVALID2(e, e2) do { _INVALID2(e, e2); goto fail; } while (0)
#define DUPLICATE(e)    do { _DUPLICATE(e);    goto fail; } while (0)

struct cdp_packet *
cdp_decode(const void *data, size_t length, char *errors) {
	struct cdp_packet *packet;

	assert(data);
	assert(errors);

	if (!SKIP(LIBNET_802_2SNAP_H + LIBNET_802_3_H)) {
		_EOP("ethernet header");
		return NULL;
	}
	if (cdp_checksum(data, length)) {
		_INVALID("checksum");
		return NULL;
	}

	packet = CALLOC(1, struct cdp_packet);
	packet->packet_length = length;

	/*
	 * We allocate BUFSIZ here, not length, so that cdp_packet_update
	 * can work reliably.
	 */
	packet->packet = MALLOC_VOIDP(BUFSIZ);
	memcpy(packet->packet, data, length);

	if (!GRAB_UINT8(packet->version)) EOP("version"); 
	if (!GRAB_UINT8(packet->ttl)) EOP("TTL");
	if (!GRAB_UINT16(packet->checksum)) EOP("checksum");
	if ((1 > packet->version) || (packet->version > 2))
		INVALID("version (not 1 or 2)");

	while (length) {
		uint16_t tlv_type;
		uint16_t tlv_length;

		if (!GRAB_UINT16(tlv_type)) EOP("TLV type");
		if (!GRAB_UINT16(tlv_length)) EOP("TLV length");
		tlv_length -= 2 * sizeof(uint16_t);

		switch (tlv_type) {
			uint32_t i, count;
		case CDP_TYPE_DEVICE_ID:
			if (packet->device_id) DUPLICATE("Device-ID TLV");
			if (!GRAB_STRING(packet->device_id, tlv_length))
				EOP("Device-ID TLV");
			break;
		case CDP_TYPE_ADDRESS:
			if (packet->addresses) DUPLICATE("Address TLV");
			if (!GRAB_UINT32(count))
				EOP("number of addresses in Address TLV");
			packet->addresses = cdp_llist_new(
				(cdp_dup_fn_t)cdp_address_dup,
				(cdp_free_fn_t)cdp_address_free
			);
			for (i = 0; i < count; i++) {
				uint8_t protocol_type, protocol_length;
				uint16_t address_length;
				const void *protocol, *address;
				if (!GRAB_UINT8(protocol_type))
					EOP2("protocol type for address %d in Address TLV", i);
				if (!GRAB_UINT8(protocol_length))
					EOP2("protocol length for address %d in Address TLV", i);
				protocol = data;
				if (!SKIP(protocol_length))
					EOP2("protocol for address %d in Address TLV", i);
				if (!GRAB_UINT16(address_length))
					EOP2("address length for address %d in Address TLV", i);
				address = data;
				if (!SKIP(address_length))
					EOP2("address for address %d in Address TLV", i);
				cdp_llist_append(packet->addresses,
					cdp_address_new(
						protocol_type, protocol_length,
						protocol, address_length,
						address
					)
				);
			}
			break;
		case CDP_TYPE_PORT_ID:
			if (packet->port_id) DUPLICATE("Port-ID TLV");
			if (!GRAB_STRING(packet->port_id, tlv_length))
				EOP("Port-ID TLV");
			break;
		case CDP_TYPE_CAPABILITIES:
			if (packet->capabilities) DUPLICATE("Capabilities TLV");
			if (tlv_length != sizeof(uint32_t))
				INVALID2("Capabilities TLV length (not %d)",
					sizeof(uint32_t));
			{
				uint32_t capabilities;
				if (!GRAB_UINT32(capabilities))
					EOP("Capabilities TLV");
				NEW(packet->capabilities, capabilities, uint32_t);
			}
			break;
		case CDP_TYPE_IOS_VERSION:
			if (packet->ios_version) DUPLICATE("Version TLV");
			if (!GRAB_STRING(packet->ios_version, tlv_length))
				EOP("Version TLV");
			break;
		case CDP_TYPE_PLATFORM:
			if (packet->platform) DUPLICATE("Platform TLV");
			if (!GRAB_STRING(packet->platform, tlv_length))
				EOP("Platform TLV");
			break;
		case CDP_TYPE_IP_PREFIX:
			if (packet->ip_prefixes) DUPLICATE("IP Prefixes TLV");
			
			/*
			 * Yuck... apparently the TLV length can be 0 to
			 * represent no data. At least, that's the impression
			 * I got upon reading
			 * http://www.cisco.com/univercd/cc/td/doc/product/lan/trsrb/frames.htm#21923
			 */
			if (tlv_length == 0xfffc) tlv_length = 0;
			
			if (tlv_length % 5) INVALID("IP Prefixes TLV length (not a multiple of 5)");
			
			count = tlv_length / 5;
			packet->ip_prefixes = cdp_llist_new(
				(cdp_dup_fn_t)cdp_ip_prefix_dup,
				(cdp_free_fn_t)cdp_ip_prefix_free
			);
			for (i = 0; i < count; i++) {
				struct in_addr network;
				uint8_t length;
				if (!GRAB_UINT32(network.s_addr))
					EOP2("network for IP prefix %d in IP Prefixes TLV", i);
				if (!GRAB_UINT8(length))
					EOP2("length for IP prefix %d in IP Prefixes TLV", i);
				if (length > 32)
					INVALID2("length for IP prefix %d in IP Prefixes TLV (should be no more than 32)", i);
				cdp_llist_append(
					packet->ip_prefixes,
					cdp_ip_prefix_new(network, length)
				);
			}
			break;
/*
		FIXME -- not documented
		
		case CDP_TYPE_PROTOCOL_HELLO:
*/
		case CDP_TYPE_VTP_MGMT_DOMAIN:
			if (packet->vtp_mgmt_domain)
				DUPLICATE("VTP Management Domain TLV");
			if (!GRAB_STRING(packet->vtp_mgmt_domain, tlv_length))
				EOP("VTP Management Domain TLV");
			break;
		case CDP_TYPE_NATIVE_VLAN:
			if (packet->native_vlan) DUPLICATE("Native VLAN TLV");
			if (tlv_length != sizeof(uint16_t))
				INVALID2("Native VLAN TLV length (not %d)",
					sizeof(uint16_t));
			{
				uint16_t native_vlan;
				if (!GRAB_UINT16(native_vlan))
					EOP("Native VLAN TLV");
				NEW(packet->native_vlan, native_vlan, uint16_t);
			}
			break;
		case CDP_TYPE_DUPLEX:
			if (packet->duplex) DUPLICATE("Duplex Mode TLV");
			if (tlv_length != sizeof(uint8_t))
				INVALID2("Duplex Mode TLV length (not %d)",
					sizeof(uint8_t));
			{
				uint8_t duplex;
				if (!GRAB_UINT8(duplex)) EOP("Duplex Mode TLV");
				NEW(packet->duplex, duplex, uint8_t);
			}
			break;
/*
		FIXME -- not documented
		
		case CDP_TYPE_UNKNOWN_0x000c:
*/
/*
		FIXME -- not documented
		
		case CDP_TYPE_UNKNOWN_0x000d:
*/
		case CDP_TYPE_APPLIANCE_REPLY:
			if (packet->appliance)
				DUPLICATE("Appliance VLAN-ID Reply TLV");
			if (tlv_length != sizeof(uint8_t) + sizeof(uint16_t))
				INVALID2("Appliance VLAN-ID Reply TLV length (not %d)",
					sizeof(uint8_t) + sizeof(uint16_t));
			{
				uint8_t id;
				uint16_t vlan;
				if (!GRAB_UINT8(id))
					EOP("appliance ID in Appliance VLAN-ID Reply TLV");
				if (!GRAB_UINT16(vlan))
					EOP("appliance VLAN in Appliance VLAN-ID Reply TLV");
				packet->appliance = cdp_appliance_new(id, vlan);
			}
			break;
		case CDP_TYPE_APPLIANCE_QUERY:
			if (packet->appliance_query)
				DUPLICATE("Appliance VLAN-ID Query TLV");
			if (tlv_length != sizeof(uint8_t) + sizeof(uint16_t))
				INVALID2("Appliance VLAN-ID TLV Query length (not %d)",
					sizeof(uint8_t) + sizeof(uint16_t));
			{
				uint8_t id;
				uint16_t vlan;
				if (!GRAB_UINT8(id))
					EOP("appliance ID in Appliance VLAN-ID Query TLV");
				if (!GRAB_UINT16(vlan))
					EOP("appliance VLAN in Appliance VLAN-ID Query TLV");
				packet->appliance_query =
					cdp_appliance_new(id, vlan);
			}
			break;
		case CDP_TYPE_POWER_CONSUMPTION:
			if (packet->power_consumption)
				DUPLICATE("Power Consumption TLV");
			if (tlv_length != sizeof(uint16_t))
				INVALID2("Power Consumption TLV length (not %d)", sizeof(uint16_t));
			{
				uint16_t power_consumption;
				if (!GRAB_UINT16(power_consumption))
					EOP("Power Consumption TLV");
				NEW(packet->power_consumption,
					power_consumption, uint16_t);
			}
			break;
		case CDP_TYPE_MTU:
			if (packet->mtu) DUPLICATE("MTU TLV");
			if (tlv_length != sizeof(uint32_t))
				INVALID2("MTU TLV length (not %d)",
					sizeof(uint32_t));
			{
				uint32_t mtu;
				if (!GRAB_UINT32(mtu))
					EOP("MTU TLV");
				NEW(packet->mtu, mtu, uint32_t);
			}
			break;
		case CDP_TYPE_EXTENDED_TRUST:
			if (packet->extended_trust)
				DUPLICATE("Extended Trust TLV");
			if (tlv_length != sizeof(uint8_t))
				INVALID2("Extended Trust TLV length (not %d)",
					sizeof(uint8_t));
			{
				uint8_t extended_trust;
				if (!GRAB_UINT8(extended_trust))
					EOP("Extended Trust TLV");
				NEW(packet->extended_trust,
					extended_trust, uint8_t);
			}
			break;
		case CDP_TYPE_UNTRUSTED_COS:
			if (packet->untrusted_cos)
				DUPLICATE("COS for Untrusted Ports TLV");
			if (tlv_length != sizeof(uint8_t))
				INVALID2("COS for Untrusted Ports TLV length (not %d)",
					sizeof(uint8_t));
			{
				uint8_t untrusted_cos;
				if (!GRAB_UINT8(untrusted_cos))
					EOP("COS for Untrusted Ports TLV");
				NEW(packet->untrusted_cos,
					untrusted_cos, uint8_t);
			}
			break;
		case CDP_TYPE_MGMT_ADDRESS:
			if (packet->mgmt_addresses)
				DUPLICATE("Management Address TLV");
			if (!GRAB_UINT32(count))
				EOP("number of addresses in Management Address TLV");
			packet->mgmt_addresses = cdp_llist_new(
				(cdp_dup_fn_t)cdp_address_dup,
				(cdp_free_fn_t)cdp_address_free
			);
			for (i = 0; i < count; i++) {
				uint8_t protocol_type;
				uint8_t protocol_length;
				const void *protocol;
				uint16_t address_length;
				const void *address;
				if (!GRAB_UINT8(protocol_type))
					EOP2("protocol type for address %d in Management Address TLV", i);
				if (!GRAB_UINT8(protocol_length))
					EOP2("protocol length for address %d in Management Address TLV", i);
				protocol = data;
				if (!SKIP(protocol_length))
					EOP2("protocol for address %d in Management Address TLV", i);
				if (!GRAB_UINT16(address_length))
					EOP2("address length for address %d in Management Address TLV", i);
				address = data;
				if (!SKIP(address_length))
					EOP2("address value for address %d in Management Address TLV", i);
				cdp_llist_append(packet->mgmt_addresses,
					cdp_address_new(
						protocol_type, protocol_length,
						protocol, address_length,
						address
					)
				);
			}
			break;
		default:
			/*
			 * Ignore the TLV. If it's an error, it will most
			 * likely get picked up here (remaining length isn't
			 * long enough), or the next TLV will be invalid.
			 */
			if (!SKIP(tlv_length)) EOP("unknown TLV");
			break;
		}
	}
	
	return packet;

fail:
	cdp_packet_free(packet);
	
	return NULL;
}

/*
 * Decode enough of the buffer to determine the checksum. This is so
 * cdp_packet_update can do its stuff.
 */
uint16_t
cdp_decode_checksum(const void *data, size_t length) {
	if (length >= 2 + sizeof(uint16_t))
		return ntohs(*(uint16_t *)(((uint8_t *)data) + 2));
	else
		return 0;
}

#define PUSH(value, type, func) \
	((length >= sizeof(type)) && \
		( \
			*((type*)pos) = func(value), \
			length -= sizeof(type), \
			pos += sizeof(type), \
			1 \
		))
#define PUSH_UINT8(value) PUSH(value, uint8_t, )
#define PUSH_UINT16(value) PUSH(value, uint16_t, htons)
#define PUSH_UINT32(value) PUSH(value, uint32_t, htonl)
#define PUSH_BYTES(value, bytes) \
	((length >= (bytes)) && \
		( \
			memcpy(pos, value, (bytes) * sizeof(uint8_t)), \
			length -= (bytes), \
			pos += (bytes), \
			1 \
		))

#define START_TLV(type) \
	( \
		tlv = pos, \
		PUSH_UINT16(type) && PUSH_UINT16(0) \
	)
#define END_TLV \
	( \
		*((uint16_t *)tlv + 1) = htons(pos - tlv) \
	)

size_t
cdp_encode(const struct cdp_packet *packet, void *data, size_t length) {
	uint8_t *pos;
	void *checksum_pos;
	uint8_t *tlv;
	
	pos = data;
	
	PUSH_UINT8(packet->version);
	if (!PUSH_UINT8(packet->ttl))
		return 0;

	/*
	 * Save the current position, then leave enough space for the
	 * checksum.
	 */
	checksum_pos = pos;
	if (!PUSH_UINT16(0))
		return 0;
	
	if (packet->device_id && !(
		START_TLV(CDP_TYPE_DEVICE_ID) &&
		PUSH_BYTES(packet->device_id, strlen(packet->device_id))
	))
		return 0;
	END_TLV;
	
	if (packet->addresses) {
		cdp_llist_iter_t iter;
		if (!(
			START_TLV(CDP_TYPE_ADDRESS) &&
			PUSH_UINT32(cdp_llist_count(packet->addresses))
		))
			return 0;
		for (
			iter = cdp_llist_iter(packet->addresses);
			iter;
			iter = cdp_llist_next(iter)
		) {
			struct cdp_address *address =
				(struct cdp_address *)cdp_llist_get(iter);
			if (!(
				PUSH_UINT8(address->protocol_type) &&
				PUSH_UINT8(address->protocol_length) &&
				PUSH_BYTES(address->protocol,
					address->protocol_length) &&
				PUSH_UINT16(address->address_length) &&
				PUSH_BYTES(address->address,
					address->address_length)
			))
				return 0;
		}
		END_TLV;
	}
	
	if (packet->port_id && !(
		START_TLV(CDP_TYPE_PORT_ID) &&
		PUSH_BYTES(packet->port_id, strlen(packet->port_id))
	))
		return 0;
	END_TLV;
	
	if (packet->capabilities && !(
		START_TLV(CDP_TYPE_CAPABILITIES) &&
		PUSH_UINT32(*packet->capabilities)
	))
		return 0;
	END_TLV;
	
	if (packet->ios_version && !(
		START_TLV(CDP_TYPE_IOS_VERSION) &&
		PUSH_BYTES(packet->ios_version, strlen(packet->ios_version))
	))
		return 0;
	END_TLV;
	
	if (packet->platform && !(
		START_TLV(CDP_TYPE_PLATFORM) &&
		PUSH_BYTES(packet->platform, strlen(packet->platform))
	))
		return 0;
	END_TLV;
	
	if (packet->ip_prefixes) {
		cdp_llist_iter_t iter;
		if (!START_TLV(CDP_TYPE_IP_PREFIX))
			return 0;
		for (
			iter = cdp_llist_iter(packet->ip_prefixes);
			iter;
			iter = cdp_llist_next(iter)
		) {
			struct cdp_ip_prefix *ip_prefix =
				(struct cdp_ip_prefix *)cdp_llist_get(iter);
			if (!(
				PUSH_UINT32(ip_prefix->network.s_addr) &&
				PUSH_UINT8(ip_prefix->length)
			))
				return 0;
		}
		END_TLV;
	}
	
	if (packet->vtp_mgmt_domain && !(
		START_TLV(CDP_TYPE_VTP_MGMT_DOMAIN) &&
		PUSH_BYTES(packet->vtp_mgmt_domain,
			strlen(packet->vtp_mgmt_domain))
	))
		return 0;
	END_TLV;
	
	if (packet->native_vlan && !(
		START_TLV(CDP_TYPE_NATIVE_VLAN) &&
		PUSH_UINT16(*packet->native_vlan)
	))
		return 0;
	END_TLV;
	
	if (packet->duplex && !(
		START_TLV(CDP_TYPE_DUPLEX) &&
		PUSH_UINT8(*packet->duplex)
	))
		return 0;
	END_TLV;
	
	if (packet->appliance && !(
		START_TLV(CDP_TYPE_APPLIANCE_REPLY) &&
		PUSH_UINT8(packet->appliance->id) &&
		PUSH_UINT16(packet->appliance->vlan)
	))
		return 0;
	END_TLV;
	
	if (packet->appliance_query && !(
		START_TLV(CDP_TYPE_APPLIANCE_QUERY) &&
		PUSH_UINT8(packet->appliance_query->id) &&
		PUSH_UINT16(packet->appliance_query->vlan)
	))
		return 0;
	END_TLV;
	
	if (packet->power_consumption && !(
		START_TLV(CDP_TYPE_POWER_CONSUMPTION) &&
		PUSH_UINT16(*packet->power_consumption)
	))
		return 0;
	END_TLV;
	
	if (packet->mtu && !(
		START_TLV(CDP_TYPE_MTU) &&
		PUSH_UINT32(*packet->mtu)
	))
		return 0;
	END_TLV;
	
	if (packet->extended_trust && !(
		START_TLV(CDP_TYPE_EXTENDED_TRUST) &&
		PUSH_UINT8(*packet->extended_trust)
	))
		return 0;
	END_TLV;
	
	if (packet->untrusted_cos && !(
		START_TLV(CDP_TYPE_UNTRUSTED_COS) &&
		PUSH_UINT8(*packet->untrusted_cos)
	))
		return 0;
	END_TLV;
	
	if (packet->mgmt_addresses) {
		cdp_llist_iter_t iter;
		if (!(
			START_TLV(CDP_TYPE_MGMT_ADDRESS) &&
			PUSH_UINT32(cdp_llist_count(packet->mgmt_addresses))
		))
			return 0;
		for (
			iter = cdp_llist_iter(packet->mgmt_addresses);
			iter;
			iter = cdp_llist_next(iter)
		) {
			struct cdp_address *address =
				(struct cdp_address *)cdp_llist_get(iter);
			if (!(
				PUSH_UINT8(address->protocol_type) &&
				PUSH_UINT8(address->protocol_length) &&
				PUSH_BYTES(address->protocol, address->protocol_length) &&
				PUSH_UINT16(address->address_length) &&
				PUSH_BYTES(address->address, address->address_length)
			))
				return 0;
		}
		END_TLV;
	}
	
	*(uint16_t *)checksum_pos = cdp_checksum(data, VOIDP_DIFF(pos, data));

	return VOIDP_DIFF(pos, data);
}
