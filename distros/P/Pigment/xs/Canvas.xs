#include "perl-pigment.h"

MODULE = Pigment::Canvas  PACKAGE = Pigment::Canvas  PREFIX = pgm_canvas_

PgmCanvas *
pgm_canvas_new (class)
	C_ARGS:

NO_OUTPUT PgmError
pgm_canvas_set_size (PgmCanvas *canvas, gfloat width, gfloat height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_canvas_get_size (PgmCanvas *canvas, OUTLIST gfloat width, OUTLIST gfloat height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_canvas_add (PgmCanvas *canvas, PgmDrawableLayer layer, PgmDrawable *drawable)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_canvas_remove (PgmCanvas *canvas, PgmDrawable *drawable)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_canvas_set_order (PgmCanvas *canvas, PgmDrawable *drawable, gint order)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_canvas_get_order (PgmCanvas *canvas, PgmDrawable *drawable, OUTLIST PgmDrawableLayer layer, OUTLIST gint order)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_canvas_get_layer_count (PgmCanvas *canvas, PgmDrawableLayer layer, OUTLIST gint count)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_canvas_regenerate (PgmCanvas *canvas)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_canvas_get_pixel_formats (PgmCanvas *canvas, OUTLIST gulong pixel_formats);
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);
