/* -*- c -*-
 *
 * Copyright (C) 2004-2008 Daniel P. Berrange
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
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <dbus/dbus.h>
#include <dbus/dbus-glib-lowlevel.h>


MODULE = Net::DBus::GLib           PACKAGE = Net::DBus::GLib

PROTOTYPES: ENABLE

BOOT:
  {
  }

void
_dbus_connection_setup_with_g_main(con, ctx)
         DBusConnection *con;
	 GMainContext *ctx;
     CODE:
	 dbus_connection_setup_with_g_main(con, ctx);
