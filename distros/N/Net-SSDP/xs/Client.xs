#include "perl_gssdp.h"

MODULE = Net::SSDP::Client  PACKAGE = Net::SSDP::Client  PREFIX = gssdp_client_

PROTOTYPES: DISABLE

GSSDPClient *
gssdp_client_new (class, ...)
		PREINIT:
			GMainContext *main_context = NULL;
			const char *interface = NULL;
			GError *err = NULL;
		INIT:
			if (items > 1) {
				if (!gperl_sv_is_defined (ST (1)) || !SvROK (ST (1))) {
					main_context = NULL;
				}
				else {
					main_context = INT2PTR (GMainContext *, SvIV (SvRV (ST (1))));
				}
			}

			if (items > 2) {
				interface = SvPV_nolen (ST (2));
			}

			if (items > 3) {
				croak ("Usage: Net::SSDP::Client->new($interface?, $main_context?)");
			}
		C_ARGS:
			main_context, interface, &err
		POSTCALL:
			if (!RETVAL) {
				gperl_croak_gerror (NULL, err);
			}

GMainContext *
gssdp_client_get_main_context (client)
		GSSDPClient *client

void
gssdp_client_set_server_id (client, server_id)
		GSSDPClient *client
		const char *server_id

const char *
gssdp_client_get_server_id (client)
		GSSDPClient *client

const char *
gssdp_client_get_interface (client)
		GSSDPClient *client

const char *
gssdp_client_get_host_ip (client)
		GSSDPClient *client

gboolean
gssdp_client_get_active (client)
		GSSDPClient *client
