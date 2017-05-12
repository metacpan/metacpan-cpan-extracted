/* -*- c -*-
 *
 * Copyright (C) 2004-2011 Daniel P. Berrange
 *
 * This program is free software; You can redistribute it and/or modify
 * it under the same terms as Perl itself. Either:
 *
 * a) the GNU General Public License as published by the Free
 *   Software Foundation; either version 2, or (at your option) any
 *   later version,
 *
 * or
 *
 * b) the "Artistic License"
 *
 * The file "COPYING" distributed along with this file provides full
 * details of the terms and conditions of the two licenses.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <dbus/dbus.h>

#if NET_DBUS_DEBUG
static int net_dbus_debug = 0;
#define DEBUG_MSG(...) if (net_dbus_debug) fprintf(stderr, __VA_ARGS__)
#else
#define DEBUG_MSG(...)
#endif

#ifdef __GNUC__
# define ignore_value(x) (({ __typeof__ (x) __x = (x); (void) __x; }))
#else
# define ignore_value(x) x
#endif

/*
 * On 32-bit OS (and some 64-bit) Perl does not have an
 * integer type capable of storing 64 bit numbers. So
 * we serialize to/from strings on these platforms
 */

dbus_int64_t
_dbus_parse_int64(SV *sv) {
#ifdef USE_64_BIT_ALL
    return SvIV(sv);
#else
    //DEBUG_MSG("Parrse %s\n", SvPV_nolen(sv));
    return strtoll(SvPV_nolen(sv), NULL, 10);
#endif
}

dbus_uint64_t
_dbus_parse_uint64(SV *sv) {
#ifdef USE_64_BIT_ALL
    return SvUV(sv);
#else
    //DEBUG_MSG("Parrse %s\n", SvPV_nolen(sv));
    return strtoull(SvPV_nolen(sv), NULL, 10);
#endif
}


#ifndef PRId64
#define PRId64 "lld"
#endif

SV *
_dbus_format_int64(dbus_int64_t val) {
#ifdef USE_64_BIT_ALL
    return newSViv(val);
#else
    char buf[100];
    int len;
    len = snprintf(buf, 100, "%" PRId64, val);
    //DEBUG_MSG("Format i64 [%" PRId64 "] to [%s]\n", val, buf);
    return newSVpv(buf, len);
#endif
}

#ifndef PRIu64
#define PRIu64 "llu"
#endif

SV *
_dbus_format_uint64(dbus_uint64_t val) {
#ifdef USE_64_BIT_ALL
    return newSVuv(val);
#else
    char buf[100];
    int len;
    len = snprintf(buf, 100, "%" PRIu64, val);
    //DEBUG_MSG("Format u64 [%" PRIu64 "] to [%s]\n", val, buf);
    return newSVpv(buf, len);
#endif
}



/* The -1 is required by the contract for
   dbus_{server,connection}_allocate_slot
   initialization */
dbus_int32_t connection_data_slot = -1;
dbus_int32_t server_data_slot = -1;
dbus_int32_t pending_call_data_slot = -1;

void
_object_release(void *obj) {
    DEBUG_MSG("Releasing object count on %p\n", obj);
    SvREFCNT_dec((SV*)obj);
}

dbus_bool_t
_watch_generic(DBusWatch *watch, void *data, char *key, dbus_bool_t server) {
    SV *selfref;
    HV *self;
    SV **call;
    SV *h_sv;
    dSP;

    DEBUG_MSG("Watch generic callback %p %p %s %d\n", watch, data, key, server);

    if (server) {
      selfref = (SV*)dbus_server_get_data((DBusServer*)data, server_data_slot);
    } else {
      selfref = (SV*)dbus_connection_get_data((DBusConnection*)data, connection_data_slot);
    }
    self = (HV*)SvRV(selfref);

    DEBUG_MSG("Got owner %p\n", self);

    call = hv_fetch(self, key, strlen(key), 0);

    if (!call) {
      warn("Could not find watch callback %s for fd %d\n",
	   key, dbus_watch_get_unix_fd(watch));
      return FALSE;
    }

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(selfref);
    h_sv = sv_newmortal();
    sv_setref_pv(h_sv, "Net::DBus::Binding::C::Watch", (void*)watch);
    XPUSHs(h_sv);
    PUTBACK;

    call_sv(*call, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 1;
}

dbus_bool_t
_watch_server_add(DBusWatch *watch, void *data) {
    return _watch_generic(watch, data, "add_watch", 1);
}
void
_watch_server_remove(DBusWatch *watch, void *data) {
    _watch_generic(watch, data, "remove_watch", 1);
}
void
_watch_server_toggled(DBusWatch *watch, void *data) {
    _watch_generic(watch, data, "toggled_watch", 1);
}

dbus_bool_t
_watch_connection_add(DBusWatch *watch, void *data) {
    return _watch_generic(watch, data, "add_watch", 0);
}
void
_watch_connection_remove(DBusWatch *watch, void *data) {
    _watch_generic(watch, data, "remove_watch", 0);
}
void
_watch_connection_toggled(DBusWatch *watch, void *data) {
    _watch_generic(watch, data, "toggled_watch", 0);
}


dbus_bool_t
_timeout_generic(DBusTimeout *timeout, void *data, char *key, dbus_bool_t server) {
    SV *selfref;
    HV *self;
    SV **call;
    SV *h_sv;
    dSP;

    if (server) {
      selfref = (SV*)dbus_server_get_data((DBusServer*)data, server_data_slot);
    } else {
      selfref = (SV*)dbus_connection_get_data((DBusConnection*)data, connection_data_slot);
    }
    self = (HV*)SvRV(selfref);

    call = hv_fetch(self, key, strlen(key), 0);

    if (!call) {
      warn("Could not find timeout callback for %s\n", key);
      return FALSE;
    }

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs((SV*)selfref);
    h_sv = sv_newmortal();
    sv_setref_pv(h_sv, "Net::DBus::Binding::C::Timeout", (void*)timeout);
    XPUSHs(h_sv);
    PUTBACK;

    call_sv(*call, G_DISCARD);

    FREETMPS;
    LEAVE;

    return 1;
}

dbus_bool_t
_timeout_server_add(DBusTimeout *timeout, void *data) {
    return _timeout_generic(timeout, data, "add_timeout", 1);
}
void
_timeout_server_remove(DBusTimeout *timeout, void *data) {
    _timeout_generic(timeout, data, "remove_timeout", 1);
}
void
_timeout_server_toggled(DBusTimeout *timeout, void *data) {
    _timeout_generic(timeout, data, "toggled_timeout", 1);
}

dbus_bool_t
_timeout_connection_add(DBusTimeout *timeout, void *data) {
    return _timeout_generic(timeout, data, "add_timeout", 0);
}
void
_timeout_connection_remove(DBusTimeout *timeout, void *data) {
    _timeout_generic(timeout, data, "remove_timeout", 0);
}
void
_timeout_connection_toggled(DBusTimeout *timeout, void *data) {
    _timeout_generic(timeout, data, "toggled_timeout", 0);
}

void
_connection_callback (DBusServer *server,
		      DBusConnection *new_connection,
		      void *data) {
    SV *selfref = (SV*)dbus_server_get_data((DBusServer*)data, server_data_slot);
    HV *self = (HV*)SvRV(selfref);
    SV **call;
    SV *value;
    dSP;

    call = hv_fetch(self, "_callback", strlen("_callback"), 0);

    if (!call) {
      warn("Could not find new connection callback\n");
      return;
    }

    DEBUG_MSG("Created connection in callback %p\n", new_connection);
    /* The DESTROY method will de-ref it later */
    dbus_connection_ref(new_connection);

    value = sv_newmortal();
    sv_setref_pv(value, "Net::DBus::Binding::C::Connection", (void*)new_connection);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(selfref);
    XPUSHs(value);
    PUTBACK;

    call_sv(*call, G_DISCARD);

    FREETMPS;
    LEAVE;
}


DBusHandlerResult
_message_filter(DBusConnection *con,
		DBusMessage *msg,
		void *data) {
    SV *selfref;
    SV *value;
    int count;
    int handled = 0;
    dSP;

    selfref = (SV*)dbus_connection_get_data(con, connection_data_slot);

    DEBUG_MSG("Create message in filter %p\n", msg);
    DEBUG_MSG("  Type %d\n", dbus_message_get_type(msg));
    DEBUG_MSG("  Interface %s\n", dbus_message_get_interface(msg) ? dbus_message_get_interface(msg) : "");
    DEBUG_MSG("  Path %s\n", dbus_message_get_path(msg) ? dbus_message_get_path(msg) : "");
    DEBUG_MSG("  Member %s\n", dbus_message_get_member(msg) ? dbus_message_get_member(msg) : "");
    /* Will be de-refed in the DESTROY method */
    dbus_message_ref(msg);
    value = sv_newmortal();
    sv_setref_pv(value, "Net::DBus::Binding::C::Message", (void*)msg);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs((SV*)selfref);
    XPUSHs(value);
    XPUSHs(data);
    PUTBACK;

    count = call_method("_message_filter", G_SCALAR);
    SPAGAIN;
    if (count == 1) {
      handled = POPi;
    } else {
      handled = 0;
    }
    PUTBACK;
    DEBUG_MSG("Handled %d %d\n", count, handled);
    FREETMPS;
    LEAVE;

    return handled ? DBUS_HANDLER_RESULT_HANDLED : DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}

void
_pending_call_callback(DBusPendingCall *call,
		       void *data) {
    SV *selfref;
    dSP;

    DEBUG_MSG("In pending call callback %p\n", call);
    selfref = (SV*)dbus_pending_call_get_data(call, pending_call_data_slot);

    // Why was this here? It makes the call object leak. - FCS
    //dbus_pending_call_ref(call);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs((SV*)selfref);
    PUTBACK;

    call_sv(data, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
_filter_release(void *data) {
    SvREFCNT_dec(data);
}

void
_pending_call_notify_release(void *data) {
    DEBUG_MSG("In pending call notify release %p\n", data);
    SvREFCNT_dec(data);
}

void
_path_unregister_callback(DBusConnection *con,
			  void *data) {
    SvREFCNT_dec(data);
}

DBusHandlerResult
_path_message_callback(DBusConnection *con,
		       DBusMessage *msg,
		       void *data) {
    SV *self = (SV*)dbus_connection_get_data(con, connection_data_slot);
    SV *value;
    dSP;

    DEBUG_MSG("Got message in callback %p\n", msg);
    DEBUG_MSG("  Type %d\n", dbus_message_get_type(msg));
    DEBUG_MSG("  Interface %s\n", dbus_message_get_interface(msg) ? dbus_message_get_interface(msg) : "");
    DEBUG_MSG("  Path %s\n", dbus_message_get_path(msg) ? dbus_message_get_path(msg) : "");
    DEBUG_MSG("  Member %s\n", dbus_message_get_member(msg) ? dbus_message_get_member(msg) : "");
    /* Will be de-refed in the DESTROY method */
    dbus_message_ref(msg);
    value = sv_newmortal();
    sv_setref_pv(value, "Net::DBus::Binding::C::Message", (void*)msg);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(value);
    PUTBACK;

    call_sv((SV*)data, G_DISCARD);

    FREETMPS;
    LEAVE;

    return DBUS_HANDLER_RESULT_HANDLED;
}

DBusObjectPathVTable _path_callback_vtable = {
	_path_unregister_callback,
	_path_message_callback,
	NULL,
	NULL,
	NULL,
	NULL
};

SV *
_sv_from_error (DBusError *error)
{
    HV *hv;

    if (!error) {
      warn ("error is NULL");
      return &PL_sv_undef;
    }

    if (!dbus_error_is_set (error)) {
      warn ("error is unset");
      return &PL_sv_undef;
    }

    hv = newHV ();

    /* map DBusError attributes to hash keys */
    ignore_value(hv_store (hv, "name", 4, newSVpv (error->name, 0), 0));
    ignore_value(hv_store (hv, "message", 7, newSVpv (error->message, 0), 0));

    return sv_bless (newRV_noinc ((SV*) hv), gv_stashpv ("Net::DBus::Error", TRUE));
}

void
_croak_error (DBusError *error)
{
    sv_setsv (ERRSV, _sv_from_error (error));

    /* croak does not return, so we free this now to avoid leaking */
    dbus_error_free (error);

    croak (Nullch);
}

void
_populate_constant(HV *href, char *name, int val)
{
    ignore_value(hv_store(href, name, strlen(name), newSViv(val), 0));
}

#define REGISTER_CONSTANT(name, key) _populate_constant(constants, #key, name)

MODULE = Net::DBus		PACKAGE = Net::DBus

PROTOTYPES: ENABLE
BOOT:
    {
	HV *constants;

	if (getenv("NET_DBUS_DEBUG"))
	  net_dbus_debug = 1;

	/* not the 'standard' way of doing perl constants, but a lot easier to maintain */

	constants = perl_get_hv("Net::DBus::Binding::Bus::_constants", TRUE);
	REGISTER_CONSTANT(DBUS_BUS_SYSTEM, SYSTEM);
	REGISTER_CONSTANT(DBUS_BUS_SESSION, SESSION);
	REGISTER_CONSTANT(DBUS_BUS_STARTER, STARTER);

	constants = perl_get_hv("Net::DBus::Binding::Message::_constants", TRUE);
	REGISTER_CONSTANT(DBUS_TYPE_ARRAY, TYPE_ARRAY);
	REGISTER_CONSTANT(DBUS_TYPE_BOOLEAN, TYPE_BOOLEAN);
	REGISTER_CONSTANT(DBUS_TYPE_BYTE, TYPE_BYTE);
	REGISTER_CONSTANT(DBUS_TYPE_DOUBLE, TYPE_DOUBLE);
	REGISTER_CONSTANT(DBUS_TYPE_INT16, TYPE_INT16);
	REGISTER_CONSTANT(DBUS_TYPE_INT32, TYPE_INT32);
	REGISTER_CONSTANT(DBUS_TYPE_INT64, TYPE_INT64);
	REGISTER_CONSTANT(DBUS_TYPE_INVALID, TYPE_INVALID);
	REGISTER_CONSTANT(DBUS_TYPE_STRUCT, TYPE_STRUCT);
	REGISTER_CONSTANT(DBUS_TYPE_SIGNATURE, TYPE_SIGNATURE);
	REGISTER_CONSTANT(DBUS_TYPE_OBJECT_PATH, TYPE_OBJECT_PATH);
	REGISTER_CONSTANT(DBUS_TYPE_DICT_ENTRY, TYPE_DICT_ENTRY);
	REGISTER_CONSTANT(DBUS_TYPE_STRING, TYPE_STRING);
	REGISTER_CONSTANT(DBUS_TYPE_UINT16, TYPE_UINT16);
	REGISTER_CONSTANT(DBUS_TYPE_UINT32, TYPE_UINT32);
	REGISTER_CONSTANT(DBUS_TYPE_UINT64, TYPE_UINT64);
	REGISTER_CONSTANT(DBUS_TYPE_VARIANT, TYPE_VARIANT);
	REGISTER_CONSTANT(DBUS_TYPE_UNIX_FD, TYPE_UNIX_FD);

	REGISTER_CONSTANT(DBUS_MESSAGE_TYPE_METHOD_CALL, MESSAGE_TYPE_METHOD_CALL);
	REGISTER_CONSTANT(DBUS_MESSAGE_TYPE_METHOD_RETURN, MESSAGE_TYPE_METHOD_RETURN);
	REGISTER_CONSTANT(DBUS_MESSAGE_TYPE_ERROR, MESSAGE_TYPE_ERROR);
	REGISTER_CONSTANT(DBUS_MESSAGE_TYPE_SIGNAL, MESSAGE_TYPE_SIGNAL);
	REGISTER_CONSTANT(DBUS_MESSAGE_TYPE_INVALID, MESSAGE_TYPE_INVALID);

	constants = perl_get_hv("Net::DBus::Binding::Watch::_constants", TRUE);
	REGISTER_CONSTANT(DBUS_WATCH_READABLE, READABLE);
	REGISTER_CONSTANT(DBUS_WATCH_WRITABLE, WRITABLE);
	REGISTER_CONSTANT(DBUS_WATCH_ERROR, ERROR);
	REGISTER_CONSTANT(DBUS_WATCH_HANGUP, HANGUP);

	dbus_connection_allocate_data_slot(&connection_data_slot);
	dbus_server_allocate_data_slot(&server_data_slot);
	dbus_pending_call_allocate_data_slot(&pending_call_data_slot);
    }


MODULE = Net::DBus::Binding::Connection		PACKAGE = Net::DBus::Binding::Connection

PROTOTYPES: ENABLE

DBusConnection *
_open(address)
	char *address;
    PREINIT:
	DBusError error;
	DBusConnection *con;
    CODE:
	dbus_error_init(&error);
        DEBUG_MSG("Open connection shared %s\n", address);
	con = dbus_connection_open(address, &error);
	if (!con) {
	  _croak_error (&error);
	}
        dbus_connection_ref(con);
	RETVAL = con;
    OUTPUT:
	RETVAL

DBusConnection *
_open_private(address)
	char *address;
    PREINIT:
	DBusError error;
	DBusConnection *con;
    CODE:
	dbus_error_init(&error);
        DEBUG_MSG("Open connection private %s\n", address);
	con = dbus_connection_open_private(address, &error);
	if (!con) {
	  _croak_error (&error);
	}
        dbus_connection_ref(con);
	RETVAL = con;
    OUTPUT:
	RETVAL

MODULE = Net::DBus::Binding::C::Connection		PACKAGE = Net::DBus::Binding::C::Connection

void
_set_owner(con, owner)
	DBusConnection *con;
	SV *owner;
    CODE:
	SvREFCNT_inc(owner);
	dbus_connection_set_data(con, connection_data_slot, owner, _object_release);

void
dbus_connection_disconnect(con)
	DBusConnection *con;
    CODE:
	DEBUG_MSG("Closing connection %p\n", con);
	dbus_connection_close(con);

void
dbus_connection_ref(con)
	DBusConnection *con;

void
dbus_connection_unref(con)
	DBusConnection *con;

int
dbus_connection_get_is_connected(con)
	DBusConnection *con;

int
dbus_connection_get_is_authenticated(con)
	DBusConnection *con;

void
dbus_connection_flush(con)
	DBusConnection *con;

int
_send(con, msg)
	DBusConnection *con;
	DBusMessage *msg;
    PREINIT:
	dbus_uint32_t serial;
    CODE:
	if (!dbus_connection_send(con, msg, &serial)) {
	  croak("not enough memory to send message");
	}
	RETVAL = serial;
    OUTPUT:
	RETVAL

DBusMessage *
_send_with_reply_and_block(con, msg, timeout)
	DBusConnection *con;
	DBusMessage *msg;
	int timeout;
    PREINIT:
	DBusMessage *reply;
	DBusError error;
    CODE:
	dbus_error_init(&error);
	if (!(reply = dbus_connection_send_with_reply_and_block(con, msg, timeout, &error))) {
	  _croak_error(&error);
	}
	DEBUG_MSG("Create msg reply %p\n", reply);
	DEBUG_MSG("  Type %d\n", dbus_message_get_type(reply));
	DEBUG_MSG("  Interface %s\n", dbus_message_get_interface(reply) ? dbus_message_get_interface(reply) : "");
	DEBUG_MSG("  Path %s\n", dbus_message_get_path(reply) ? dbus_message_get_path(reply) : "");
	DEBUG_MSG("  Member %s\n", dbus_message_get_member(reply) ? dbus_message_get_member(reply) : "");
	RETVAL = reply;
    OUTPUT:
	RETVAL


DBusPendingCall *
_send_with_reply(con, msg, timeout)
	DBusConnection *con;
	DBusMessage *msg;
	int timeout;
    PREINIT:
	DBusPendingCall *reply;
    CODE:
	if (!dbus_connection_send_with_reply(con, msg, &reply, timeout)) {
	  croak("not enough memory to send message");
	}
	DEBUG_MSG("Create pending call %p\n", reply);
	RETVAL = reply;
    OUTPUT:
	RETVAL

DBusMessage *
dbus_connection_borrow_message(con)
	DBusConnection *con;

void
dbus_connection_return_message(con, msg)
	DBusConnection *con;
	DBusMessage *msg;

void
dbus_connection_steal_borrowed_message(con, msg)
	DBusConnection *con;
	DBusMessage *msg;

DBusMessage *
dbus_connection_pop_message(con)
	DBusConnection *con;

void
_dispatch(con)
	DBusConnection *con;
    CODE:
	DEBUG_MSG("IN dispatch\n");
	while(dbus_connection_dispatch(con) == DBUS_DISPATCH_DATA_REMAINS);
	DEBUG_MSG("Completed \n");

void
_set_watch_callbacks(con)
	DBusConnection *con;
    CODE:
	if (!dbus_connection_set_watch_functions(con,
						 _watch_connection_add,
						 _watch_connection_remove,
						 _watch_connection_toggled,
						 con, NULL)) {
	  croak("not enough memory to set watch functions on connection");
	}

void
_set_timeout_callbacks(con)
	DBusConnection *con;
    CODE:
	if (!dbus_connection_set_timeout_functions(con,
						   _timeout_connection_add,
						   _timeout_connection_remove,
						   _timeout_connection_toggled,
						   con, NULL)) {
	  croak("not enough memory to set timeout functions on connection");
	}

void
_register_object_path(con, path, code)
	DBusConnection *con;
	char *path;
	SV *code;
    CODE:
	SvREFCNT_inc(code);
	if (!(dbus_connection_register_object_path(con, path, &_path_callback_vtable, code))) {
	  croak("failure when registering object path");
	}

void
_unregister_object_path(con, path)
	DBusConnection *con;
	char *path;
    CODE:
	/* The associated data will be free'd by the previously
	   registered callback */
	if (!(dbus_connection_unregister_object_path(con, path))) {
	  croak("failure when unregistering object path");
	}

void
_register_fallback(con, path, code)
	DBusConnection *con;
	char *path;
	SV *code;
    CODE:
	SvREFCNT_inc(code);
	if (!(dbus_connection_register_fallback(con, path, &_path_callback_vtable, code))) {
	  croak("failure when registering fallback object path");
	}


void
_add_filter(con, code)
	DBusConnection *con;
	SV *code;
    CODE:
	SvREFCNT_inc(code);
	DEBUG_MSG("Adding filter %p\n", code);
	dbus_connection_add_filter(con, _message_filter, code, _filter_release);

dbus_bool_t
dbus_bus_register(con)
	DBusConnection *con;
    PREINIT:
	DBusError error;
	int reply;
    CODE:
	dbus_error_init(&error);
	if (!(reply = dbus_bus_register(con, &error))) {
	  _croak_error(&error);
	}
	RETVAL = reply;
  OUTPUT:
        RETVAL

void
dbus_bus_add_match(con, rule)
	DBusConnection *con;
	char *rule;
    PREINIT:
	DBusError error;
    CODE:
	dbus_error_init(&error);
	DEBUG_MSG("Adding match %s\n", rule);
	dbus_bus_add_match(con, rule, &error);
	if (dbus_error_is_set(&error)) {
	  _croak_error(&error);
	}

void
dbus_bus_remove_match(con, rule)
	DBusConnection *con;
	char *rule;
    PREINIT:
	DBusError error;
    CODE:
	dbus_error_init(&error);
	DEBUG_MSG("Removeing match %s\n", rule);
	dbus_bus_remove_match(con, rule, &error);
	if (dbus_error_is_set(&error)) {
	  _croak_error(&error);
	}

const char *
dbus_bus_get_unique_name(con)
	DBusConnection *con;

int
dbus_bus_request_name(con, service_name)
	DBusConnection *con;
	char *service_name;
    PREINIT:
	DBusError error;
	int reply;
    CODE:
	dbus_error_init(&error);
	if ((reply = dbus_bus_request_name(con, service_name, 0, &error)) == -1) {
	  _croak_error(&error);
	}
	RETVAL = reply;
    OUTPUT:
	RETVAL

void
DESTROY(con)
	DBusConnection *con;
    CODE:
	DEBUG_MSG("Unrefing connection %p\n", con);
	dbus_connection_unref(con);


MODULE = Net::DBus::Binding::Server		PACKAGE = Net::DBus::Binding::Server

PROTOTYPES: ENABLE

DBusServer *
_open(address)
	char *address;
    PREINIT:
	DBusError error;
	DBusServer *server;
    CODE:
	dbus_error_init(&error);
	server = dbus_server_listen(address, &error);
	DEBUG_MSG("Created server %p on address %s\n", server, address);
	if (!server) {
	  _croak_error(&error);
	}
	if (!dbus_server_set_auth_mechanisms(server, NULL)) {
	    croak("not enough memory to server auth mechanisms");
	}
	RETVAL = server;
    OUTPUT:
	RETVAL


MODULE = Net::DBus::Binding::C::Server		PACKAGE = Net::DBus::Binding::C::Server

void
_set_owner(server, owner)
	DBusServer *server;
	SV *owner;
    CODE:
	SvREFCNT_inc(owner);
	dbus_server_set_data(server, server_data_slot, owner, _object_release);

void
dbus_server_disconnect(server)
	DBusServer *server;

int
dbus_server_get_is_connected(server)
	DBusServer *server;

void
_set_watch_callbacks(server)
	DBusServer *server;
    CODE:
	if (!dbus_server_set_watch_functions(server,
					     _watch_server_add,
					     _watch_server_remove,
					     _watch_server_toggled,
					     server, NULL)) {
	  croak("not enough memory to set watch functions on server");
	}


void
_set_timeout_callbacks(server)
	DBusServer *server;
    CODE:
	if (!dbus_server_set_timeout_functions(server,
					       _timeout_server_add,
					       _timeout_server_remove,
					       _timeout_server_toggled,
					       server, NULL)) {
	  croak("not enough memory to set timeout functions on server");
	}


void
_set_connection_callback(server)
	DBusServer *server;
    CODE:
	dbus_server_set_new_connection_function(server,
						_connection_callback,
						server, NULL);

void
DESTROY(server)
	DBusServer *server;
   CODE:
	DEBUG_MSG("Destroying server %p\n", server);
	dbus_server_unref(server);


MODULE = Net::DBus::Binding::Bus		PACKAGE = Net::DBus::Binding::Bus

PROTOTYPES: ENABLE

DBusConnection *
_open(type)
	DBusBusType type;
    PREINIT:
	DBusError error;
	DBusConnection *con;
    CODE:
	dbus_error_init(&error);
        DEBUG_MSG("Open bus shared %d\n", type);
	con = dbus_bus_get(type, &error);
	if (!con) {
	  _croak_error(&error);
	}
        dbus_connection_ref(con);
	RETVAL = con;
    OUTPUT:
	RETVAL

DBusConnection *
_open_private(type)
	DBusBusType type;
    PREINIT:
	DBusError error;
	DBusConnection *con;
    CODE:
	dbus_error_init(&error);
        DEBUG_MSG("Open bus private %d\n", type);
	con = dbus_bus_get_private(type, &error);
	if (!con) {
	  _croak_error(&error);
	}
        dbus_connection_ref(con);
	RETVAL = con;
    OUTPUT:
	RETVAL

MODULE = Net::DBus::Binding::Message		PACKAGE = Net::DBus::Binding::Message

PROTOTYPES: ENABLE

DBusMessage *
_create(type)
	IV type;
    PREINIT:
	DBusMessage *msg;
    CODE:
	msg = dbus_message_new(type);
	if (!msg) {
	  croak("No memory to allocate message");
	}
	DEBUG_MSG("Create msg new %p\n", msg);
	DEBUG_MSG("  Type %d\n", dbus_message_get_type(msg));
	RETVAL = msg;
    OUTPUT:
	RETVAL


DBusMessageIter *
_iterator_append(msg)
	DBusMessage *msg;
    CODE:
	RETVAL = dbus_new(DBusMessageIter, 1);
	dbus_message_iter_init_append(msg, RETVAL);
    OUTPUT:
	RETVAL


DBusMessageIter *
_iterator(msg)
	DBusMessage *msg;
    CODE:
	RETVAL = dbus_new(DBusMessageIter, 1);
	dbus_message_iter_init(msg, RETVAL);
    OUTPUT:
	RETVAL


MODULE = Net::DBus::Binding::C::Message		PACKAGE = Net::DBus::Binding::C::Message

void
DESTROY(msg)
	DBusMessage *msg;
    CODE:
	DEBUG_MSG("De-referencing message %p\n", msg);
	DEBUG_MSG("  Type %d\n", dbus_message_get_type(msg));
	DEBUG_MSG("  Interface %s\n", dbus_message_get_interface(msg) ? dbus_message_get_interface(msg) : "");
	DEBUG_MSG("  Path %s\n", dbus_message_get_path(msg) ? dbus_message_get_path(msg) : "");
	DEBUG_MSG("  Member %s\n", dbus_message_get_member(msg) ? dbus_message_get_member(msg) : "");
	dbus_message_unref(msg);

dbus_bool_t
dbus_message_get_no_reply(msg)
	DBusMessage *msg;

void
dbus_message_set_no_reply(msg,flag)
	DBusMessage *msg;
	dbus_bool_t flag;

int
dbus_message_get_type(msg)
	DBusMessage *msg;

const char *
dbus_message_get_interface(msg)
	DBusMessage *msg;

const char *
dbus_message_get_path(msg)
	DBusMessage *msg;

const char *
dbus_message_get_destination(msg)
	DBusMessage *msg;

const char *
dbus_message_get_sender(msg)
	DBusMessage *msg;

dbus_uint32_t
dbus_message_get_serial(msg)
	DBusMessage *msg;

const char *
dbus_message_get_member(msg)
	DBusMessage *msg;

const char *
dbus_message_get_error_name(msg)
	DBusMessage *msg;

const char *
dbus_message_get_signature(msg)
	DBusMessage *msg;

void
dbus_message_set_sender(msg, sender);
	DBusMessage *msg;
	const char *sender;

void
dbus_message_set_destination(msg, dest);
	DBusMessage *msg;
	const char *dest;

MODULE = Net::DBus::Binding::Message::Signal		PACKAGE = Net::DBus::Binding::Message::Signal

PROTOTYPES: ENABLE

DBusMessage *
_create(path, interface, name)
	char *path;
	char *interface;
	char *name;
    PREINIT:
	DBusMessage *msg;
    CODE:
	msg = dbus_message_new_signal(path, interface, name);
	if (!msg) {
	  croak("No memory to allocate message");
	}
	DEBUG_MSG("Create msg new signal %p\n", msg);
	DEBUG_MSG("  Type %d\n", dbus_message_get_type(msg));
	DEBUG_MSG("  Interface %s\n", dbus_message_get_interface(msg) ? dbus_message_get_interface(msg) : "");
	DEBUG_MSG("  Path %s\n", dbus_message_get_path(msg) ? dbus_message_get_path(msg) : "");
	DEBUG_MSG("  Member %s\n", dbus_message_get_member(msg) ? dbus_message_get_member(msg) : "");
	RETVAL = msg;
    OUTPUT:
	RETVAL

MODULE = Net::DBus::Binding::Message::MethodCall		PACKAGE = Net::DBus::Binding::Message::MethodCall

PROTOTYPES: ENABLE

DBusMessage *
_create(service, path, interface, method)
	char *service;
	char *path;
	char *interface;
	char *method;
    PREINIT:
	DBusMessage *msg;
    CODE:
	msg = dbus_message_new_method_call(service, path, interface, method);
	if (!msg) {
	  croak("No memory to allocate message");
	}
	DEBUG_MSG("Create msg new method call %p\n", msg);
	DEBUG_MSG("  Type %d\n", dbus_message_get_type(msg));
	DEBUG_MSG("  Interface %s\n", dbus_message_get_interface(msg) ? dbus_message_get_interface(msg) : "");
	DEBUG_MSG("  Path %s\n", dbus_message_get_path(msg) ? dbus_message_get_path(msg) : "");
	DEBUG_MSG("  Member %s\n", dbus_message_get_member(msg) ? dbus_message_get_member(msg) : "");
	RETVAL = msg;
    OUTPUT:
	RETVAL

MODULE = Net::DBus::Binding::Message::MethodReturn		PACKAGE = Net::DBus::Binding::Message::MethodReturn

PROTOTYPES: ENABLE

DBusMessage *
_create(call)
	DBusMessage *call;
    PREINIT:
	DBusMessage *msg;
    CODE:
	msg = dbus_message_new_method_return(call);
	if (!msg) {
	  croak("No memory to allocate message");
	}
	dbus_message_set_interface(msg, dbus_message_get_interface(call));
	dbus_message_set_path(msg, dbus_message_get_path(call));
	dbus_message_set_member(msg, dbus_message_get_member(call));
	DEBUG_MSG("Create msg new method return %p\n", msg);
	DEBUG_MSG("  Type %d\n", dbus_message_get_type(msg));
	DEBUG_MSG("  Interface %s\n", dbus_message_get_interface(msg) ? dbus_message_get_interface(msg) : "");
	DEBUG_MSG("  Path %s\n", dbus_message_get_path(msg) ? dbus_message_get_path(msg) : "");
	DEBUG_MSG("  Member %s\n", dbus_message_get_member(msg) ? dbus_message_get_member(msg) : "");
	RETVAL = msg;
    OUTPUT:
	RETVAL

MODULE = Net::DBus::Binding::Message::Error		PACKAGE = Net::DBus::Binding::Message::Error

PROTOTYPES: ENABLE

DBusMessage *
_create(replyto, name, message)
	DBusMessage *replyto;
	char *name;
	char *message;
    PREINIT:
	DBusMessage *msg;
    CODE:
	msg = dbus_message_new_error(replyto, name, message);
	if (!msg) {
	  croak("No memory to allocate message");
	}
	DEBUG_MSG("Create msg new error %p\n", msg);
	DEBUG_MSG("  Type %d\n", dbus_message_get_type(msg));
	DEBUG_MSG("  Interface %s\n", dbus_message_get_interface(msg) ? dbus_message_get_interface(msg) : "");
	DEBUG_MSG("  Path %s\n", dbus_message_get_path(msg) ? dbus_message_get_path(msg) : "");
	DEBUG_MSG("  Member %s\n", dbus_message_get_member(msg) ? dbus_message_get_member(msg) : "");
	RETVAL = msg;
    OUTPUT:
	RETVAL

MODULE = Net::DBus::Binding::C::PendingCall		PACKAGE = Net::DBus::Binding::C::PendingCall

PROTOTYPES: ENABLE

DBusMessage *
_steal_reply(call)
	DBusPendingCall *call;
 PREINIT:
        DBusMessage *msg;
    CODE:
        DEBUG_MSG("Stealing pending call reply %p\n", call);
	msg = dbus_pending_call_steal_reply(call);
        dbus_message_ref(msg);
        DEBUG_MSG("Got reply message %p\n", msg);
        RETVAL = msg;
  OUTPUT:
        RETVAL

void
dbus_pending_call_block(call)
	DBusPendingCall *call;

dbus_bool_t
dbus_pending_call_get_completed(call)
	DBusPendingCall *call;

void
dbus_pending_call_cancel(call)
	DBusPendingCall *call;

void
_set_notify(call, code)
	DBusPendingCall *call;
	SV *code;
    CODE:
	SvREFCNT_inc(code);
	DEBUG_MSG("Adding pending call notify %p\n", code);
	dbus_pending_call_set_notify(call, _pending_call_callback, code, _pending_call_notify_release);

void
DESTROY (call)
	DBusPendingCall *call;
    CODE:
	DEBUG_MSG("Unrefing pending call %p\n", call);
	dbus_pending_call_unref(call);

MODULE = Net::DBus::Binding::C::Watch			PACKAGE = Net::DBus::Binding::C::Watch

int
get_fileno(watch)
	DBusWatch *watch;
    CODE:
	RETVAL = dbus_watch_get_unix_fd(watch);
    OUTPUT:
	RETVAL

unsigned int
get_flags(watch)
	DBusWatch *watch;
    CODE:
	RETVAL = dbus_watch_get_flags(watch);
    OUTPUT:
	RETVAL

dbus_bool_t
is_enabled(watch)
	DBusWatch *watch;
    CODE:
	RETVAL = dbus_watch_get_enabled(watch);
    OUTPUT:
	RETVAL

void
handle(watch, flags)
	DBusWatch *watch;
	unsigned int flags;
    CODE:
	DEBUG_MSG("Handling event %d on fd %d (%p)\n", flags, dbus_watch_get_unix_fd(watch), watch);
	dbus_watch_handle(watch, flags);


void *
get_data(watch)
	DBusWatch *watch;
    CODE:
	RETVAL = dbus_watch_get_data(watch);
    OUTPUT:
	RETVAL

void
set_data(watch, data)
	DBusWatch *watch;
	void *data;
    CODE:
	dbus_watch_set_data(watch, data, NULL);


MODULE = Net::DBus::Binding::C::Timeout			PACKAGE = Net::DBus::Binding::C::Timeout

int
get_interval(timeout)
	DBusTimeout *timeout;
    CODE:
	RETVAL = dbus_timeout_get_interval(timeout);
    OUTPUT:
	RETVAL

dbus_bool_t
is_enabled(timeout)
	DBusTimeout *timeout;
    CODE:
	RETVAL = dbus_timeout_get_enabled(timeout);
    OUTPUT:
	RETVAL

void
handle(timeout)
	DBusTimeout *timeout;
    CODE:
	DEBUG_MSG("Handling timeout event %p\n", timeout);
	dbus_timeout_handle(timeout);

void *
get_data(timeout)
	DBusTimeout *timeout;
    CODE:
	RETVAL = dbus_timeout_get_data(timeout);
    OUTPUT:
	RETVAL

void
set_data(timeout, data)
	DBusTimeout *timeout;
	void *data;
    CODE:
	dbus_timeout_set_data(timeout, data, NULL);

MODULE = Net::DBus::Binding::Iterator PACKAGE = Net::DBus::Binding::Iterator

DBusMessageIter *
_recurse(iter)
	DBusMessageIter *iter;
    CODE:
	RETVAL = dbus_new(DBusMessageIter, 1);
	dbus_message_iter_recurse(iter, RETVAL);
    OUTPUT:
	RETVAL

DBusMessageIter *
_open_container(iter, type, sig)
	DBusMessageIter *iter;
	int type;
	char *sig;
    CODE:
	RETVAL = dbus_new(DBusMessageIter, 1);
	if (!dbus_message_iter_open_container(iter, type, sig && *sig == '\0' ? NULL : sig, RETVAL)) {
		dbus_free(RETVAL);
		croak("failed to open iterator container");
	}
    OUTPUT:
	RETVAL

void
_close_container(iter, sub_iter)
	DBusMessageIter *iter;
	DBusMessageIter *sub_iter;
    CODE:
	dbus_message_iter_close_container(iter, sub_iter);

int
get_arg_type(iter)
	DBusMessageIter *iter;
    CODE:
	RETVAL = dbus_message_iter_get_arg_type(iter);
    OUTPUT:
	RETVAL

int
get_element_type(iter)
	DBusMessageIter *iter;
    CODE:
	RETVAL = dbus_message_iter_get_element_type(iter);
    OUTPUT:
	RETVAL

dbus_bool_t
has_next(iter)
	DBusMessageIter *iter;
    CODE:
	RETVAL = dbus_message_iter_has_next(iter);
    OUTPUT:
	RETVAL

dbus_bool_t
next(iter)
	DBusMessageIter *iter;
    CODE:
	RETVAL = dbus_message_iter_next(iter);
    OUTPUT:
	RETVAL

dbus_bool_t
get_boolean(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

unsigned char
get_byte(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

dbus_int16_t
get_int16(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

dbus_uint16_t
get_uint16(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

dbus_int32_t
get_int32(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

dbus_uint32_t
get_uint32(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

dbus_int64_t
_get_int64(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

dbus_uint64_t
_get_uint64(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

double
get_double(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

char *
get_string(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

char *
get_signature(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

char *
get_object_path(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL

dbus_uint32_t
get_unix_fd(iter)
	DBusMessageIter *iter;
    CODE:
	dbus_message_iter_get_basic(iter, &RETVAL);
    OUTPUT:
	RETVAL


void
append_boolean(iter, val)
	DBusMessageIter *iter;
	dbus_bool_t val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_BOOLEAN, &val)) {
	  croak("cannot append boolean");
	}

void
append_byte(iter, val)
	DBusMessageIter *iter;
	unsigned char val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_BYTE, &val)) {
	  croak("cannot append byte");
	}

void
append_int16(iter, val)
	DBusMessageIter *iter;
	dbus_int16_t val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_INT16, &val)) {
	  croak("cannot append int16");
	}

void
append_uint16(iter, val)
	DBusMessageIter *iter;
	dbus_uint16_t val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_UINT16, &val)) {
	  croak("cannot append uint16");
	}

void
append_int32(iter, val)
	DBusMessageIter *iter;
	dbus_int32_t val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_INT32, &val)) {
	  croak("cannot append int32");
	}

void
append_uint32(iter, val)
	DBusMessageIter *iter;
	dbus_uint32_t val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_UINT32, &val)) {
	  croak("cannot append uint32");
	}

void
_append_int64(iter, val)
	DBusMessageIter *iter;
	dbus_int64_t val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_INT64, &val)) {
	  croak("cannot append int64");
	}

void
_append_uint64(iter, val)
	DBusMessageIter *iter;
	dbus_uint64_t val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_UINT64, &val)) {
	  croak("cannot append uint64");
	}

void
append_double(iter, val)
	DBusMessageIter *iter;
	double val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_DOUBLE, &val)) {
	  croak("cannot append double");
	}

void
append_string(iter, val)
	DBusMessageIter *iter;
	char *val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_STRING, &val)) {
	  croak("cannot append string");
	}

void
append_object_path(iter, val)
	DBusMessageIter *iter;
	char *val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_OBJECT_PATH, &val)) {
	  croak("cannot append object path");
	}

void
append_signature(iter, val)
	DBusMessageIter *iter;
	char *val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_SIGNATURE, &val)) {
	  croak("cannot append signature");
	}

void
append_unix_fd(iter, val)
	DBusMessageIter *iter;
        dbus_uint32_t val;
    CODE:
	if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_UNIX_FD, &val)) {
	  croak("cannot append UNIX fd");
	}



void
DESTROY(iter)
	DBusMessageIter *iter;
    CODE:
	DEBUG_MSG("Destroying iterator %p\n", iter);
	dbus_free(iter);

MODULE = Net::DBus		PACKAGE = Net::DBus
