#include "perlmouth.h"

GType
perlmouth_lm_connection_get_type(void) {
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static(
				"LmConnection",
				(GBoxedCopyFunc) g_boxed_copy,
				(GBoxedFreeFunc) g_boxed_free);
	return t;
}

GType
perlmouth_lm_message_get_type(void) {
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static(
				"LmMessage",
				(GBoxedCopyFunc) g_boxed_copy,
				(GBoxedFreeFunc) g_boxed_free);
	return t;
}

GType
perlmouth_lm_proxy_get_type(void) {
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static(
				"LmProxy",
				(GBoxedCopyFunc) g_boxed_copy,
				(GBoxedFreeFunc) g_boxed_free);
	return t;
}

GType
perlmouth_lm_ssl_get_type(void) {
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static(
				"LmSSL",
				(GBoxedCopyFunc) g_boxed_copy,
				(GBoxedFreeFunc) g_boxed_free);
	return t;
}

GType
perlmouth_lm_message_handler_get_type(void) {
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static(
				"LmMessageHandler",
				(GBoxedCopyFunc) g_boxed_copy,
				(GBoxedFreeFunc) g_boxed_free);
	return t;
}

GType
perlmouth_lm_message_node_get_type(void) {
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static(
				"LmMessageNode",
				(GBoxedCopyFunc) g_boxed_copy,
				(GBoxedFreeFunc) g_boxed_free);
	return t;
}
