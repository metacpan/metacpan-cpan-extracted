#include "perlmouth.h"

LmSSLResponse
perlmouth_lm_ssl_new_cb(LmSSL* ssl, LmSSLStatus status, gpointer callback) {
	GValue return_value = {0,};
	LmSSLResponse retval;
	g_value_init(&return_value, ((GPerlCallback*)callback)->return_type);
	gperl_callback_invoke((GPerlCallback*)callback, &return_value, ssl, status);
	retval = g_value_get_enum(&return_value);
	g_value_unset(&return_value);
	return retval;
}

MODULE = Net::Jabber::Loudmouth::SSL	PACKAGE = Net::Jabber::Loudmouth::SSL	PREFIX = lm_ssl_

LmSSL*
lm_ssl_new(class, ssl_cb, user_data=NULL, expected_fingerprint=NULL)
		SV* ssl_cb
		SV* user_data
		const gchar* expected_fingerprint
	PREINIT:
		GType param_types[2];
		GPerlCallback* callback;
	CODE:
		param_types[0] = PERLMOUTH_TYPE_SSL;
		param_types[1] = PERLMOUTH_TYPE_SSL_STATUS;

		callback = gperl_callback_new(ssl_cb, user_data, 2, param_types, PERLMOUTH_TYPE_SSL_RESPONSE);
		RETVAL = lm_ssl_new(expected_fingerprint, perlmouth_lm_ssl_new_cb, callback, (GDestroyNotify)gperl_callback_destroy);
	OUTPUT:
		RETVAL

gboolean
lm_ssl_is_supported(class)
	C_ARGS:

const gchar*
lm_ssl_get_fingerprint(ssl)
		LmSSL* ssl
