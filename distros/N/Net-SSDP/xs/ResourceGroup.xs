#include "perl_gssdp.h"

MODULE = Net::SSDP::ResourceGroup  PACKAGE = Net::SSDP::ResourceGroup  PREFIX = gssdp_resource_group_

PROTOTYPES: DISABLE

GSSDPResourceGroup *
gssdp_resource_group_new (class, client)
		GSSDPClient *client
	C_ARGS:
		client

GSSDPClient *
gssdp_resource_group_get_client (resource_group)
		GSSDPResourceGroup *resource_group

void
gssdp_resource_group_set_max_age (resource_group, max_age)
		GSSDPResourceGroup *resource_group
		guint max_age

guint
gssdp_resource_group_get_max_age (resource_group)
		GSSDPResourceGroup *resource_group

void
gssdp_resource_group_set_available (resource_group, available)
		GSSDPResourceGroup *resource_group
		gboolean available

gboolean
gssdp_resource_group_get_available (resource_group)
		GSSDPResourceGroup *resource_group

void
gssdp_resource_group_set_message_delay (resource_group, message_delay)
		GSSDPResourceGroup *resource_group
		guint message_delay

guint
gssdp_resource_group_get_message_delay (resource_group)
		GSSDPResourceGroup *resource_group

guint
gssdp_resource_group_add_resource (resource_group, target, usn, location1, ...)
		GSSDPResourceGroup *resource_group
		const char *target
		const char *usn
		const char *location1
	PREINIT:
		GList *locations = NULL;
		IV i = 4;
	INIT:
		if (!target || !strchr (target, ':')) {
			croak ("Net::SSDP::ResourceGroup->add_resource: target needs to be defined and contain a colon");
		}

		locations = g_list_append (locations, (gpointer)location1);
		while (i < items) {
			locations = g_list_append (locations, SvPV_nolen (ST (i)));
			i++;
		}
	C_ARGS:
		resource_group, target, usn, locations
	POSTCALL:
		g_list_free (locations);

void
gssdp_resource_group_remove_resource (resource_group, resource_id)
		GSSDPResourceGroup *resource_group
		guint resource_id
