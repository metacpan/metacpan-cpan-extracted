#include "perlmouth.h"

MODULE = Net::Jabber::Loudmouth::MessageNode	PACKAGE = Net::Jabber::Loudmouth::MessageNode	PREFIX = lm_message_node_

const gchar*
lm_message_node_get_value(node)
		LmMessageNode* node

void
lm_message_node_set_value(node, value)
		LmMessageNode* node
		const gchar* value

const gchar*
get_name(node)
		LmMessageNode* node
	CODE:
		RETVAL = node->name;
	OUTPUT:
		RETVAL

void
set_name(node, name)
		LmMessageNode* node
		gchar* name
	CODE:
		node->name = name;

LmMessageNode*
lm_message_node_add_child(node, name, value=NULL)
		LmMessageNode* node
		const gchar* name
		const gchar* value

void
lm_message_node_set_attributes(node, ...)
		LmMessageNode* node
	PREINIT:
		int i;
	CODE:
		if (((items - 1) % 2) != 0)
			croak("set_attributes expects name => value pairs "
					"(odd number of arguments detected)");

		for (i = 1; i < items; i += 2) {
			const gchar *name, *value;
			sv_utf8_upgrade(ST(i));
			name = (const gchar*)SvPV_nolen(ST(i));

			sv_utf8_upgrade(ST(i+1));
			value = (const gchar*)SvPV_nolen(ST(i+1));

			lm_message_node_set_attribute(node, name, value);
		}

void
lm_message_node_set_attribute(node, name, value)
		LmMessageNode* node
		const gchar* name
		const gchar* value

const gchar*
lm_message_node_get_attribute(node, name)
		LmMessageNode* node
		const gchar* name

LmMessageNode*
lm_message_node_get_child_by_name(node, child_name)
		LmMessageNode* node
		const gchar* child_name
	CODE:
		RETVAL = lm_message_node_get_child(node, child_name);
	OUTPUT:
		RETVAL

LmMessageNode*
lm_message_node_find_child(node, child_name)
		LmMessageNode* node
		const gchar* child_name


gboolean
lm_message_node_get_raw_mode(node)
		LmMessageNode* node

void
lm_message_node_set_raw_mode(node, raw_mode)
		LmMessageNode* node
		gboolean raw_mode

gchar*
lm_message_node_to_string(node)
		LmMessageNode* node

LmMessageNode*
get_child(node)
		LmMessageNode* node
	CODE:
		RETVAL = node->children;
	OUTPUT:
		RETVAL

LmMessageNode*
get_parent(node)
		LmMessageNode* node
	CODE:
		RETVAL = node->parent;
	OUTPUT:
		RETVAL

LmMessageNode*
get_next(node)
		LmMessageNode* node
	CODE:
		RETVAL = node->next;
	OUTPUT:
		RETVAL

LmMessageNode*
get_prev(node)
		LmMessageNode* node
	CODE:
		RETVAL = node->prev;
	OUTPUT:
		RETVAL
