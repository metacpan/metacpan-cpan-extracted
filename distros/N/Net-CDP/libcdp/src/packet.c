/*
 * $Id: packet.c,v 1.2 2005/07/21 07:08:23 mchapman Exp $
 */

#include <system.h>

#include <encoding.h>

#ifdef HAVE_SYS_UTSNAME_H
# include <sys/utsname.h>
#endif /* HAVE_SYS_UTSNAME_H */

struct cdp_packet *
cdp_packet_generate(const cdp_t *cdp) {
	struct cdp_packet *packet;
	char *device_id;
	char *ios_version;
	char *platform;
	struct utsname uts;

	assert(cdp);

	if (!uname(&uts)) {
		device_id = strdup(uts.nodename);
		ios_version = SALLOC(
			strlen(uts.sysname) +
			strlen(uts.release) +
			strlen(uts.version) +
			strlen(uts.machine) +
			10
		);
		sprintf(ios_version, "%s %s %s %s",
			uts.sysname,
			uts.release,
			uts.version,
			uts.machine
		);
		platform = strdup(uts.sysname);
	} else
		device_id = ios_version = platform = NULL;

	packet = CALLOC(1, struct cdp_packet);
	packet->packet = MALLOC_VOIDP(BUFSIZ);
	packet->packet_length = BUFSIZ;
	packet->version = 1;
	packet->ttl = 180;
	packet->device_id = device_id;
	NEW(packet->capabilities, CDP_CAP_HOST, uint32_t);
	packet->ios_version = ios_version;
	packet->platform = platform;
	if (cdp) {
		if (cdp->addresses)
			packet->addresses = cdp_llist_dup(cdp->addresses);
		packet->port_id = strdup(cdp->port);
		if (cdp->duplex)
			DUP(packet->duplex, cdp->duplex, uint8_t);
	}

	return packet;
}

struct cdp_packet *
cdp_packet_dup(const struct cdp_packet *packet) {
	struct cdp_packet *dup;

	assert(packet);

	dup = CALLOC(1, struct cdp_packet);
	dup->packet = MALLOC_VOIDP(BUFSIZ);
	dup->packet_length = BUFSIZ;
	dup->version = packet->version;
	dup->ttl = packet->ttl;
	if (packet->device_id) dup->device_id = strdup(packet->device_id);
	if (packet->addresses)
		dup->addresses = cdp_llist_dup(packet->addresses);
	if (packet->port_id) dup->port_id = strdup(packet->port_id);
	if (packet->capabilities)
		DUP(dup->capabilities, packet->capabilities, uint32_t);
	if (packet->ios_version) dup->ios_version = strdup(packet->ios_version);
	if (packet->platform) dup->platform = strdup(packet->platform);
	if (packet->ip_prefixes)
		dup->ip_prefixes = cdp_llist_dup(packet->ip_prefixes);
	if (packet->vtp_mgmt_domain)
		dup->vtp_mgmt_domain = strdup(packet->vtp_mgmt_domain);
	if (packet->native_vlan)
		DUP(dup->native_vlan, packet->native_vlan, uint16_t);
	if (packet->duplex) DUP(dup->duplex, packet->duplex, uint8_t);
	if (packet->appliance)
		DUP(dup->appliance, packet->appliance, struct cdp_appliance);
	if (packet->appliance_query)
		DUP(dup->appliance_query, packet->appliance_query,
			 struct cdp_appliance);
	if (packet->power_consumption)
		DUP(dup->power_consumption, packet->power_consumption,
			uint16_t);
	if (packet->mtu) DUP(dup->mtu, packet->mtu, uint32_t);
	if (packet->extended_trust)
		DUP(dup->extended_trust, packet->extended_trust, uint8_t);
	if (packet->untrusted_cos)
		DUP(dup->untrusted_cos, packet->untrusted_cos, uint8_t);
	if (packet->mgmt_addresses)
		dup->mgmt_addresses = cdp_llist_dup(packet->mgmt_addresses);

	return dup;
}

void
cdp_packet_free(struct cdp_packet *packet) {
	assert(packet);

	if (packet->packet) FREE(packet->packet);
	if (packet->device_id) FREE(packet->device_id);
	if (packet->addresses) cdp_llist_free(packet->addresses);
	if (packet->port_id) FREE(packet->port_id);
	if (packet->capabilities) FREE(packet->capabilities);
	if (packet->ios_version) FREE(packet->ios_version);
	if (packet->platform) FREE(packet->platform);
	if (packet->ip_prefixes) cdp_llist_free(packet->ip_prefixes);
	if (packet->vtp_mgmt_domain) FREE(packet->vtp_mgmt_domain);
	if (packet->native_vlan) FREE(packet->native_vlan);
	if (packet->duplex) FREE(packet->duplex);
	if (packet->appliance) FREE(packet->appliance);
	if (packet->appliance_query) FREE(packet->appliance_query);
	if (packet->power_consumption) FREE(packet->power_consumption);
	if (packet->mtu) FREE(packet->mtu);
	if (packet->extended_trust) FREE(packet->extended_trust);
	if (packet->untrusted_cos) FREE(packet->untrusted_cos);
	if (packet->mgmt_addresses) cdp_llist_free(packet->mgmt_addresses);

	FREE(packet);
}

int
cdp_packet_update(struct cdp_packet *packet, char *errors) {
	assert(packet);
	assert(errors);

	if ((packet->packet_length = cdp_encode(packet, packet->packet, BUFSIZ)) == 0) {
		strcpy(errors, "Generated packet too large");
		return -1;
	}

	/* Update my own concept of checksum */
	packet->checksum = cdp_decode_checksum(packet->packet, packet->packet_length);

	return 0;
}
