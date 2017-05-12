#include "perlmouth.h"

MODULE = Net::Jabber::Loudmouth::Message	PACKAGE = Net::Jabber::Loudmouth::Message	PREFIX = lm_message_

LmMessage*
lm_message_new(class, to, type)
		const gchar* to
		LmMessageType type
	C_ARGS:
		to, type

LmMessage*
lm_message_new_with_sub_type(class, to, type, sub_type)
		const gchar* to
		LmMessageType type
		LmMessageSubType sub_type
	C_ARGS:
		to, type, sub_type

LmMessageType
lm_message_get_type(message)
		LmMessage* message

LmMessageSubType
lm_message_get_sub_type(message)
		LmMessage* message

LmMessageNode*
lm_message_get_node(message)
		LmMessage* message
