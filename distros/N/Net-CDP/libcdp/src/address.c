/*
 * $Id: address.c,v 1.1 2005/07/20 13:44:13 mchapman Exp $
 */

#include <system.h>

/*
 * This tables was derived from the Cisco documentation at
 * http://www.cisco.com/univercd/cc/td/doc/product/lan/trsrb/frames.htm
 */

struct cdp_predef cdp_predefs[] = {
	/* CDP_ADDR_PROTO_CLNP      */
		{ 0x01, 1, "\x81" },
	/* CDP_ADDR_PROTO_IPV4      */
		{ 0x01, 1, "\xcc" },
	/* CDP_ADDR_PROTO_IPV6      */
		{ 0x02, 8, "\xaa\xaa\x03\x00\x00\x00\x80\xdd" },
	/* CDP_ADDR_PROTO_DECNET    */
		{ 0x02, 8, "\xaa\xaa\x03\x00\x00\x00\x60\x03" },
	/* CDP_ADDR_PROTO_APPLETALK */
		{ 0x02, 8, "\xaa\xaa\x03\x00\x00\x00\x80\x9b" },
	/* CDP_ADDR_PROTO_IPX       */
		{ 0x02, 8, "\xaa\xaa\x03\x00\x00\x00\x81\x37" },
	/* CDP_ADDR_PROTO_VINES     */
		{ 0x02, 8, "\xaa\xaa\x03\x00\x00\x00\x80\xc4" },
	/* CDP_ADDR_PROTO_XNS       */
		{ 0x02, 8, "\xaa\xaa\x03\x00\x00\x00\x06\x00" },
	/* CDP_ADDR_PROTO_APOLLO    */
		{ 0x02, 8, "\xaa\xaa\x03\x00\x00\x00\x80\x19" },
};

struct cdp_address *
cdp_address_new(uint8_t protocol_type, uint8_t protocol_length, const void *protocol, uint8_t address_length, const void *address) {
	struct cdp_address *result;

	assert(protocol);
	assert(address);

	result = MALLOC(1, struct cdp_address);
	result->protocol_type = protocol_type;
	result->protocol_length = protocol_length;
	result->protocol = MALLOC_VOIDP(protocol_length);
	memcpy(result->protocol, protocol, protocol_length);
	result->address_length = address_length;
	result->address = MALLOC_VOIDP(address_length);
	memcpy(result->address, address, address_length);
	return result;
}

struct cdp_address *
cdp_address_dup(const struct cdp_address *address) {
	assert(address);

	return cdp_address_new(
		address->protocol_type,
		address->protocol_length,
		address->protocol,
		address->address_length,
		address->address
	);
}

void
cdp_address_free(struct cdp_address *address) {
	assert(address);

	FREE(address->protocol);
	FREE(address->address);
	FREE(address);
}
