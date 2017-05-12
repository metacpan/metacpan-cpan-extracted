/*
 * $Id: ip_prefix.c,v 1.1 2005/07/20 13:44:13 mchapman Exp $
 */

#include <system.h>

struct cdp_ip_prefix *
cdp_ip_prefix_new(struct in_addr network, uint8_t length) {
	struct cdp_ip_prefix *result;

	assert(length <= 32);

	result = MALLOC(1, struct cdp_ip_prefix);
	result->network = network;
	result->length = length;
	return result;
}

struct cdp_ip_prefix *
cdp_ip_prefix_dup(const struct cdp_ip_prefix *ip_prefix) {
	assert(ip_prefix);

	return cdp_ip_prefix_new(
		ip_prefix->network,
		ip_prefix->length
	);
}

void
cdp_ip_prefix_free(struct cdp_ip_prefix *ip_prefix) {
	FREE(ip_prefix);
}
