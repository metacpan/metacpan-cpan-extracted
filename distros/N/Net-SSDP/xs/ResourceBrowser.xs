#include "perl_gssdp.h"
#include <gperl_marshal.h>

STATIC SV *
string_list_to_arrayref (GList *list)
{
	GList *i;
	AV *av = newAV ();

	for (i = list; i; i = g_list_next (i)) {
		av_push (av, newSVGChar (i->data));
	}

	return newRV_noinc ((SV *)av);
}

STATIC void
marshal_resource_available (GClosure *closure,
                            GValue *return_value,
                            guint n_param_values,
                            const GValue *param_values,
                            gpointer invocant_hint,
                            gpointer marshal_data)
{
	dGPERL_CLOSURE_MARSHAL_ARGS;

	PERL_UNUSED_ARG (return_value);
	PERL_UNUSED_ARG (n_param_values);
	PERL_UNUSED_ARG (invocant_hint);

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);

	XPUSHs (sv_2mortal (newSVGChar (g_value_get_string (param_values + 1))));
	XPUSHs (sv_2mortal (string_list_to_arrayref ((GList *)g_value_get_pointer (param_values + 2))));

	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_VOID);

	FREETMPS;
	LEAVE;
}

MODULE = Net::SSDP::ResourceBrowser  PACKAGE = Net::SSDP::ResourceBrowser  PREFIX = gssdp_resource_browser_

PROTOTYPES: DISABLE

GSSDPResourceBrowser *
gssdp_resource_browser_new (class, client, target=GSSDP_ALL_RESOURCES)
		GSSDPClient *client
		const char *target
	INIT:
		if (!target || !strchr (target, ':')) {
			croak ("Net::SSDP::ResourceBrowser->new: target needs to be defined and contain a colon");
	}
	C_ARGS:
		client, target

GSSDPClient *
gssdp_resource_browser_get_client (resource_browser)
		GSSDPResourceBrowser *resource_browser

void
gssdp_resource_browser_set_target (resource_browser, target)
		GSSDPResourceBrowser *resource_browser
		const char *target

const char *
gssdp_resource_browser_get_target (resource_browser)
		GSSDPResourceBrowser *resource_browser

void
gssdp_resource_browser_set_mx (resource_browser, mx)
		GSSDPResourceBrowser *resource_browser
		gushort mx

void
gssdp_resource_browser_set_active (resource_browser, active)
		GSSDPResourceBrowser *resource_browser
		gboolean active

gboolean
gssdp_resource_browser_get_active (resource_browser)
		GSSDPResourceBrowser *resource_browser

BOOT:
	gperl_signal_set_marshaller_for (GSSDP_TYPE_RESOURCE_BROWSER,
	                                 "resource-available",
	                                 marshal_resource_available);
