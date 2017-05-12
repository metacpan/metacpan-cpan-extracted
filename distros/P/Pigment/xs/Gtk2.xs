#include "perl-pigment.h"

MODULE = Pigment::Gtk2  PACKAGE = Pigment::Gtk2  PREFIX = pgm_gtk_

GtkWidget *
pgm_gtk_new (class)
	C_ARGS:

gboolean
pgm_gtk_set_viewport (PgmGtk *gtk, PgmViewport *viewport)

NO_OUTPUT PgmError
pgm_gtk_get_viewport (PgmGtk *gtk, OUTLIST PgmViewport *viewport)
