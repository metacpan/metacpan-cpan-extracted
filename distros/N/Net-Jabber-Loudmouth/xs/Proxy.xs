#include "perlmouth.h"

MODULE = Net::Jabber::Loudmouth::Proxy	PACKAGE = Net::Jabber::Loudmouth::Proxy	PREFIX = lm_proxy_

LmProxy*
lm_proxy_new(class, type)
		LmProxyType type
	C_ARGS:
		type

LmProxy*
lm_proxy_new_with_server(class, type, server, port)
		LmProxyType type
		const gchar* server
		guint port
	C_ARGS:
		type, server, port

LmProxyType
lm_proxy_get_type(proxy)
		LmProxy* proxy

void
lm_proxy_set_type(proxy, type)
		LmProxy* proxy
		LmProxyType type

const gchar*
lm_proxy_get_server(proxy)
		LmProxy* proxy

void
lm_proxy_set_server(proxy, server)
		LmProxy* proxy
		const gchar* server

guint
lm_proxy_get_port(proxy)
		LmProxy* proxy

void
lm_proxy_set_port(proxy, port)
		LmProxy* proxy
		guint port

const gchar*
lm_proxy_get_username(proxy)
		LmProxy* proxy

void
lm_proxy_set_username(proxy, username)
		LmProxy* proxy
		const gchar* username

const gchar*
lm_proxy_get_password(proxy)
		LmProxy* proxy

void
lm_proxy_set_password(proxy, password)
		LmProxy* proxy
		const gchar* password
