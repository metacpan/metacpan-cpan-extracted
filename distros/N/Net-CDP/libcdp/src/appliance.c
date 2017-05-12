/*
 * $Id: appliance.c,v 1.1 2005/07/20 13:44:13 mchapman Exp $
 */

#include <system.h>

struct cdp_appliance *
cdp_appliance_new(uint8_t id, uint16_t vlan) {
	struct cdp_appliance *result;

	result = MALLOC(1, struct cdp_appliance);
	result->id = id;
	result->vlan = vlan;
	return result;
}

struct cdp_appliance *
cdp_appliance_dup(const struct cdp_appliance *appliance) {
	assert(appliance);

	return cdp_appliance_new(appliance->id, appliance->vlan);
}

void
cdp_appliance_free(struct cdp_appliance *appliance) {
	FREE(appliance);
}
