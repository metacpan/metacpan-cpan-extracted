/*
 * $Id: CDP.xs,v 1.11 2005/07/20 13:44:13 mchapman Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define MAX_VLAN_ID 4095
#define DEFAULT_APPLIANCE_ID 1

#include "libcdp/src/cdp.h"

#include "const-c.inc"

#define CHECK_VERSION \
	STMT_START { \
		if (self) \
			self->version = ( \
				self->appliance || \
				self->appliance_query || \
				self->power_consumption || \
				self->mtu || \
				self->extended_trust || \
				self->untrusted_cos || \
				self->mgmt_addresses \
			) ? 2 : 1; \
	} STMT_END

#define PUSH_llist_generic(LLIST, GEN_SV) \
	STMT_START { \
		const cdp_llist_t *__l = (LLIST); \
		if (GIMME_V == G_SCALAR) \
			XPUSHs(__l \
				? sv_2mortal(newSVuv(cdp_llist_count(__l))) \
				: &PL_sv_undef \
			); \
		else if (GIMME_V == G_ARRAY) { \
			if (__l) { \
				cdp_llist_iter_t __i; \
				EXTEND(SP, cdp_llist_count(__l)); \
				for ( \
					__i = cdp_llist_iter(__l); \
					__i; \
					__i = cdp_llist_next(__i) \
				) \
					PUSHs(GEN_SV); \
			} \
		} \
	} STMT_END

#define PUSH_llist(LLIST, CLASS) \
	PUSH_llist_generic((LLIST), sv_setref_pv( \
		sv_newmortal(), (CLASS), (__l->dup_fn)cdp_llist_get(__i) \
	))

#define PUSH_port_llist(LLIST) \
	PUSH_llist_generic((LLIST), sv_2mortal( \
		newSVpv((char *)cdp_llist_get(__i), 0) \
	))

#define PUSH_appliance(APPLIANCE) \
	STMT_START { \
		struct cdp_appliance *appliance = (APPLIANCE); \
		if (GIMME_V == G_SCALAR) { \
			if (appliance) \
				XPUSHs(sv_2mortal(newSVuv(appliance->vlan))); \
			else \
				XPUSHs(&PL_sv_undef); \
		} else if (GIMME_V == G_ARRAY) { \
			EXTEND(SP, 2); \
			if (appliance) { \
				PUSHs(sv_2mortal(newSVuv(appliance->vlan))); \
				PUSHs(sv_2mortal(newSVuv(appliance->id))); \
			} else { \
				PUSHs(&PL_sv_undef); \
				PUSHs(&PL_sv_undef); \
			} \
		} \
	} STMT_END

#define MY_CXT_KEY "Net::CDP::_guts" XS_VERSION
typedef struct {
	char errors[CDP_ERRBUF_SIZE];
} my_cxt_t;

START_MY_CXT

typedef cdp_t * Net_CDP;
typedef struct cdp_address * Net_CDP_Address;
typedef struct cdp_ip_prefix * Net_CDP_IPPrefix;
typedef struct cdp_packet * Net_CDP_Packet;
typedef int SysRet;

typedef const char * PV_UNDEF;
typedef uint8_t * BOOL_UNDEF;
typedef uint8_t * U8_UNDEF;
typedef uint16_t * U16_UNDEF;
typedef uint32_t * U32_UNDEF;

typedef cdp_llist_t * Net_CDP_Address_List;
#define Net_CDP_Address_dup cdp_address_dup
#define Net_CDP_Address_free cdp_address_free
typedef cdp_llist_t * Net_CDP_IPPrefix_List;
#define Net_CDP_IPPrefix_dup cdp_ip_prefix_dup
#define Net_CDP_IPPrefix_free cdp_ip_prefix_free

MODULE = Net::CDP		PACKAGE = Net::CDP

BOOT:
{
	MY_CXT_INIT;
	Zero(MY_CXT.errors, CDP_ERRBUF_SIZE, char);
}

void
_ports()
PROTOTYPE: 
PREINIT:
	dMY_CXT;
	UV count;
	cdp_llist_t *ports;
PPCODE:
	MY_CXT.errors[0] = '\0';
	if (GIMME_V == G_VOID) XSRETURN_EMPTY;
	ports = cdp_get_ports(MY_CXT.errors);
	if (!ports) croak(MY_CXT.errors);
	PUSH_port_llist(ports);
	cdp_llist_free(ports);

Net_CDP
_new(CLASS, device, flags)
	SV *CLASS
	const char * device
	int flags
PROTOTYPE: $$$
PREINIT:
	dMY_CXT;
CODE:
	MY_CXT.errors[0] = '\0';
	RETVAL = cdp_new(device, flags, MY_CXT.errors);
	if (!RETVAL) croak(MY_CXT.errors);
OUTPUT:
	RETVAL

const char *
port(self)
	Net_CDP self
PROTOTYPE: $
CODE:
	RETVAL = cdp_get_port(self);
OUTPUT:
	RETVAL

void
addresses(self)
	Net_CDP self
PROTOTYPE: $
PREINIT:
	const cdp_llist_t *addresses;
PPCODE:
	addresses = cdp_get_addresses(self);
	PUSH_llist(addresses, "Net::CDP::Address");

int
_fd(self)
	Net_CDP self
PROTOTYPE: $
CODE:
	RETVAL = cdp_get_fd(self);
OUTPUT:
	RETVAL

Net_CDP_Packet
_recv(self, flags)
	Net_CDP self
	int flags
PROTOTYPE: $$
PREINIT:
	dMY_CXT;
	int result;
CODE:
	MY_CXT.errors[0] = '\0';	
	RETVAL = cdp_recv(self, flags, MY_CXT.errors);
	if (!RETVAL) {
		if (!MY_CXT.errors[0])
			XSRETURN_UNDEF;
		croak(MY_CXT.errors);
	}
OUTPUT:
	RETVAL

SysRet
_send(self, packet)
	Net_CDP self
	Net_CDP_Packet packet
PROTOTYPE: $$
PREINIT:
	dMY_CXT;
CODE:
	MY_CXT.errors[0] = '\0';	
	if (cdp_packet_update(packet, MY_CXT.errors) == -1)
		croak(MY_CXT.errors);
	RETVAL = cdp_send(self, packet, MY_CXT.errors);
	if (RETVAL == -1) croak(MY_CXT.errors);
OUTPUT:
	RETVAL

void
DESTROY(self)
	Net_CDP self
PROTOTYPE: $
CODE:
	cdp_free(self);

MODULE = Net::CDP		PACKAGE = Net::CDP::Packet

Net_CDP_Packet
_new(CLASS, cdp=NULL)
	SV *CLASS
	Net_CDP cdp
PROTOTYPE: $;$
CODE:
	RETVAL = cdp_packet_generate(cdp);
OUTPUT:
	RETVAL

Net_CDP_Packet
clone(self)
	Net_CDP_Packet self
PROTOTYPE: $
CODE:
	RETVAL = cdp_packet_dup(self);
OUTPUT:
	RETVAL

void
DESTROY(self)
	Net_CDP_Packet self
PROTOTYPE: $
CODE:
	cdp_packet_free(self);

UV
version(self)
	Net_CDP_Packet self
PROTOTYPE: $
CODE:
	RETVAL = self->version;
OUTPUT:
	RETVAL

UV
ttl(self, new_ttl=0)
	Net_CDP_Packet self
	UV new_ttl
PROTOTYPE: $;$
CODE:
	if (items > 1) self->ttl = new_ttl;
	RETVAL = self->ttl;
OUTPUT:
	RETVAL

UV
checksum(self)
	Net_CDP_Packet self
PROTOTYPE: $
CODE:
	RETVAL = self->checksum;
OUTPUT:
	RETVAL

PV_UNDEF
device(self, new_device=NULL)
	Net_CDP_Packet self
	PV_UNDEF new_device
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (self->device_id) free(self->device_id);
		self->device_id = (new_device ? strdup(new_device) : NULL);
	}
	RETVAL = self->device_id;
OUTPUT:
	RETVAL

void
addresses(self, new_addresses=NULL)
	Net_CDP_Packet self
	Net_CDP_Address_List new_addresses
PROTOTYPE: $;$
PPCODE:
	if (items > 1) {
		if (self->addresses) cdp_llist_free(self->addresses);
		self->addresses = new_addresses;
	}
	PUSH_llist(self->addresses, "Net::CDP::Address");

PV_UNDEF
port(self, new_port=NULL)
	Net_CDP_Packet self
	PV_UNDEF new_port
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (self->port_id) free(self->port_id);
		self->port_id = (new_port ? strdup(new_port) : NULL);
	}
	RETVAL = self->port_id;
OUTPUT:
	RETVAL

U32_UNDEF
capabilities(self, new_capabilities=NULL)
	Net_CDP_Packet self
	U32_UNDEF new_capabilities
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (self->capabilities) free(self->capabilities);
		self->capabilities = new_capabilities;
	}
	RETVAL = self->capabilities;
OUTPUT:
	RETVAL

PV_UNDEF
ios_version(self, new_ios_version=NULL)
	Net_CDP_Packet self
	PV_UNDEF new_ios_version
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (self->ios_version) free(self->ios_version);
		self->ios_version = (new_ios_version ? strdup(new_ios_version) : NULL);
	}
	RETVAL = self->ios_version;
OUTPUT:
	RETVAL

PV_UNDEF
platform(self, new_platform=NULL)
	Net_CDP_Packet self
	PV_UNDEF new_platform
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (self->platform) free(self->platform);
		self->platform = (new_platform ? strdup(new_platform) : NULL);
	}
	RETVAL = self->platform;
OUTPUT:
	RETVAL

void
ip_prefixes(self, new_ip_prefixes=NULL)
	Net_CDP_Packet self
	Net_CDP_IPPrefix_List new_ip_prefixes
PROTOTYPE: $;$
PPCODE:
	if (items > 1) {
		if (self->ip_prefixes) cdp_llist_free(self->ip_prefixes);
		self->ip_prefixes = new_ip_prefixes;
	}
	PUSH_llist(self->ip_prefixes, "Net::CDP::IPPrefix");

PV_UNDEF
vtp_management_domain(self, new_vtp_management_domain=NULL)
	Net_CDP_Packet self
	PV_UNDEF new_vtp_management_domain
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (self->vtp_mgmt_domain) free(self->vtp_mgmt_domain);
		self->vtp_mgmt_domain = (new_vtp_management_domain ? strdup(new_vtp_management_domain) : NULL);
	}
	RETVAL = self->vtp_mgmt_domain;
OUTPUT:
	RETVAL

U16_UNDEF
native_vlan(self, new_native_vlan=NULL)
	Net_CDP_Packet self
	U16_UNDEF new_native_vlan
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (new_native_vlan && (*new_native_vlan < 1 || *new_native_vlan > MAX_VLAN_ID))
			croak("Invalid new_native_vlan (must be between 1 and %u)", MAX_VLAN_ID);
		if (self->native_vlan) free(self->native_vlan);
		self->native_vlan = new_native_vlan;
	}
	RETVAL = self->native_vlan;
OUTPUT:
	RETVAL

BOOL_UNDEF
duplex(self, new_duplex=NULL)
	Net_CDP_Packet self
	BOOL_UNDEF new_duplex
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (self->duplex) free(self->duplex);
		self->duplex = new_duplex;
	}
	RETVAL = self->duplex;
OUTPUT:
	RETVAL

void
voice_vlan(self, new_voice_vlan=NULL, new_appliance_id=NULL)
	Net_CDP_Packet self
	U16_UNDEF new_voice_vlan
	U8_UNDEF new_appliance_id
PROTOTYPE: $;$$
PPCODE:
	if (items > 1) {
		if (new_voice_vlan && (*new_voice_vlan < 1 || *new_voice_vlan > MAX_VLAN_ID))
			croak("Invalid new_voice_vlan (must be between 1 and %u)", MAX_VLAN_ID);
		if (new_appliance_id && *new_appliance_id < 1)
			croak("Invalid new_appliance_id (must be between 1 and 255)");
		if (new_voice_vlan) {
			if (self->appliance)
				self->appliance->vlan = *new_voice_vlan;
			else
				self->appliance = cdp_appliance_new(
					DEFAULT_APPLIANCE_ID, *new_voice_vlan
				);
		}
		if (new_appliance_id) {
			if (!self->appliance)
				croak("Attempt to add Appliance VLAN-ID field without setting voice VLAN");
			self->appliance->id = *new_appliance_id;
		}
		if (!new_voice_vlan && !new_appliance_id) {
			cdp_appliance_free(self->appliance);
			self->appliance = NULL;
		}
		if (new_voice_vlan) free(new_voice_vlan);
		if (new_appliance_id) free(new_appliance_id);
		CHECK_VERSION;
	}
	PUSH_appliance(self->appliance);

void
voice_vlan_query(self, new_voice_vlan=NULL, new_appliance_id=NULL)
	Net_CDP_Packet self
	U16_UNDEF new_voice_vlan
	U8_UNDEF new_appliance_id
PROTOTYPE: $;$$
PPCODE:
	if (items > 1) {
		if (new_voice_vlan && (*new_voice_vlan < 1 || *new_voice_vlan > MAX_VLAN_ID))
			croak("Invalid new_voice_vlan (must be between 1 and %u)", MAX_VLAN_ID);
		if (new_appliance_id && *new_appliance_id < 1)
			croak("Invalid new_appliance_id (must be between 1 and 255)");
		if (new_voice_vlan) {
			if (self->appliance_query)
				self->appliance_query->vlan = *new_voice_vlan;
			else
				self->appliance_query = cdp_appliance_new(
					DEFAULT_APPLIANCE_ID, *new_voice_vlan
				);
		}
		if (new_appliance_id) {
			if (!self->appliance_query)
				croak("Attempt to add Appliance VLAN-ID query field without setting voice VLAN");
			self->appliance_query->id = *new_appliance_id;
		}
		if (!new_voice_vlan && !new_appliance_id) {
			cdp_appliance_free(self->appliance_query);
			self->appliance_query = NULL;
		}
		if (new_voice_vlan) free(new_voice_vlan);
		if (new_appliance_id) free(new_appliance_id);
		CHECK_VERSION;
	}
	PUSH_appliance(self->appliance_query);

U16_UNDEF
power_consumption(self, new_power_consumption=NULL)
	Net_CDP_Packet self
	U16_UNDEF new_power_consumption
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (self->power_consumption) free(self->power_consumption);
		self->power_consumption = new_power_consumption;
		CHECK_VERSION;
	}
	RETVAL = self->power_consumption;
OUTPUT:
	RETVAL

U32_UNDEF
mtu(self, new_mtu=NULL)
	Net_CDP_Packet self
	U32_UNDEF new_mtu
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (new_mtu && *new_mtu < 1)
			croak("Invalid new_mtu (must be greater than 1)");
		if (self->mtu) free(self->mtu);
		self->mtu = new_mtu;
		CHECK_VERSION;
	}
	RETVAL = self->mtu;
OUTPUT:
	RETVAL

BOOL_UNDEF
trusted(self, new_trusted=NULL)
	Net_CDP_Packet self
	BOOL_UNDEF new_trusted
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (self->extended_trust) free(self->extended_trust);
		self->extended_trust = new_trusted;
		CHECK_VERSION;
	}
	RETVAL = self->extended_trust;
OUTPUT:
	RETVAL

U8_UNDEF
untrusted_cos(self, new_untrusted_cos=NULL)
	Net_CDP_Packet self
	U8_UNDEF new_untrusted_cos
PROTOTYPE: $;$
CODE:
	if (items > 1) {
		if (new_untrusted_cos && *new_untrusted_cos > 7)
			croak("Invalid new_untrusted_cos (must be less than 7)");
		if (self->untrusted_cos) free(self->untrusted_cos);
		self->untrusted_cos = new_untrusted_cos;
		CHECK_VERSION;
	}
	RETVAL = self->untrusted_cos;
OUTPUT:
	RETVAL

void
management_addresses(self, new_addresses=NULL)
	Net_CDP_Packet self
	Net_CDP_Address_List new_addresses
PROTOTYPE: $;$
PPCODE:
	if (items > 1) {
		if (self->mgmt_addresses) cdp_llist_free(self->mgmt_addresses);
		self->mgmt_addresses = new_addresses;
		CHECK_VERSION;
	}
	PUSH_llist(self->mgmt_addresses, "Net::CDP::Address");

MODULE = Net::CDP		PACKAGE = Net::CDP::Address

Net_CDP_Address
_new(CLASS, protocol, packed)
	SV *CLASS
	SV *protocol
	SV *packed
PROTOTYPE: $$$
INIT:
	STRLEN len1, len2;
	void *str1, *str2;
CODE:
	str1 = SvPV(protocol, len1);
	str2 = SvPV(packed, len2);
	switch (len1) {
	case 1:
		RETVAL = cdp_address_new(1, 1, str1, len2, str2);
		break;
	case 3:
	case 8:
		RETVAL = cdp_address_new(2, len1, str1, len2, str2);
	default:
		croak("Invalid protocol");
	}
OUTPUT:
	RETVAL

Net_CDP_Address
_new_by_id(CLASS, protocol_id, packed)
	SV *CLASS
	unsigned int protocol_id
	SV *packed
PROTOTYPE: $$$
INIT:
	STRLEN len;
	void *str;
CODE:
	str = SvPV(packed, len);
	if (protocol_id <= CDP_ADDR_PROTO_MAX)
		RETVAL = cdp_address_new(
			cdp_predefs[protocol_id].protocol_type,
			cdp_predefs[protocol_id].protocol_length,
			cdp_predefs[protocol_id].protocol,
			len, str
		);
	else
		croak("Invalid protocol");
OUTPUT:
	RETVAL

Net_CDP_Address
clone(self)
	Net_CDP_Address self
PROTOTYPE: $
CODE:
	RETVAL = cdp_address_dup(self);
OUTPUT:
	RETVAL

void
DESTROY(self)
	Net_CDP_Address self
PROTOTYPE: $
CODE:
	cdp_address_free(self);

UV
_protocol_type(self)
	Net_CDP_Address self
PROTOTYPE: $
CODE:
	RETVAL = self->protocol_type;
OUTPUT:
	RETVAL

SV *
_protocol(self)
	Net_CDP_Address self
PROTOTYPE: $
CODE:
	RETVAL = newSVpvn((char *)self->protocol, self->protocol_length);
OUTPUT:
	RETVAL

SV *
_protocol_id(self)
	Net_CDP_Address self
PROTOTYPE: $
PREINIT:
	UV protocol_id;
CODE:
	RETVAL = NULL;
	for (protocol_id = 0; !RETVAL && protocol_id <= CDP_ADDR_PROTO_MAX; protocol_id++) {
		if (
			self->protocol_type == cdp_predefs[protocol_id].protocol_type &&
			self->protocol_length == cdp_predefs[protocol_id].protocol_length &&
			memcmp(self->protocol, cdp_predefs[protocol_id].protocol, self->protocol_length) == 0
		)
			RETVAL = newSVuv(protocol_id);
	}
	if (!RETVAL) XSRETURN_UNDEF;
OUTPUT:
	RETVAL

SV *
_address(self)
	Net_CDP_Address self
PROTOTYPE: $
CODE:
	RETVAL = newSVpvn((char *)self->address, self->address_length);
OUTPUT:
	RETVAL

MODULE = Net::CDP		PACKAGE = Net::CDP::IPPrefix

Net_CDP_IPPrefix
_new(CLASS, packed, length)
	SV *CLASS
	SV *packed
	UV length
PROTOTYPE: $$$
INIT:
	STRLEN len;
	char *str;
	struct in_addr ip_prefix;
CODE:
	str = SvPV(packed, len);
	if (len != 4 || length > 32)
		croak("Invalid IP prefix");
	memcpy(&ip_prefix.s_addr, str, 4);
	RETVAL = cdp_ip_prefix_new(ip_prefix, length);
OUTPUT:
	RETVAL

Net_CDP_IPPrefix
clone(self)
	Net_CDP_IPPrefix self
PROTOTYPE: $
CODE:
	RETVAL = cdp_ip_prefix_dup(self);
OUTPUT:
	RETVAL

void
DESTROY(self)
	Net_CDP_IPPrefix self
PROTOTYPE: $
CODE:
	cdp_ip_prefix_free(self);

SV *
_network(self)
	Net_CDP_IPPrefix self
PROTOTYPE: $
CODE:
	RETVAL = newSVpvn((char *)&self->network, 4);
OUTPUT:
	RETVAL

UV
length(self)
	Net_CDP_IPPrefix self
PROTOTYPE: $
CODE:
	RETVAL = self->length;
OUTPUT:
	RETVAL

MODULE = Net::CDP		PACKAGE = Net::CDP::Constants

INCLUDE: const-xs.inc
