#include "perlmouth.h"

LmHandlerResult
perlmouth_lm_message_handler_new_cb(LmMessageHandler* handler, LmConnection* connection, LmMessage* message, gpointer callback) {
	GValue return_value = {0,};
	LmHandlerResult retval;
	g_value_init(&return_value, ((GPerlCallback*)callback)->return_type);
	gperl_callback_invoke((GPerlCallback*)callback, &return_value, handler, connection, message);
	retval = g_value_get_enum(&return_value);
	g_value_unset(&return_value);
	return retval;
}

MODULE = Net::Jabber::Loudmouth::MessageHandler	PACKAGE = Net::Jabber::Loudmouth::MessageHandler	PREFIX = lm_message_handler_

LmMessageHandler*
lm_message_handler_new(class, handler_cb, user_data=NULL)
		SV* handler_cb
		SV* user_data
	PREINIT:
		GType param_types[3];
		GPerlCallback* callback;
	CODE:
		param_types[0] = PERLMOUTH_TYPE_MESSAGE_HANDLER;
		param_types[1] = PERLMOUTH_TYPE_CONNECTION;
		param_types[2] = PERLMOUTH_TYPE_MESSAGE;

		callback = gperl_callback_new(handler_cb, user_data, 3, param_types, PERLMOUTH_TYPE_HANDLER_RESULT);
		RETVAL = lm_message_handler_new(perlmouth_lm_message_handler_new_cb, callback, (GDestroyNotify)gperl_callback_destroy);
	OUTPUT:
		RETVAL

void
lm_message_handler_invalidate(handler)
		LmMessageHandler* handler

gboolean
lm_message_handler_is_valid(handler)
		LmMessageHandler* handler
