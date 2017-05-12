#include "perl-pigment.h"

MODULE = Pigment::Drawable  PACKAGE = Pigment::Drawable  PREFIX = pgm_drawable_

NO_OUTPUT PgmError
pgm_drawable_hide (PgmDrawable *drawable)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_show (PgmDrawable *drawable)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_is_visible (PgmDrawable *drawable, OUTLIST gboolean visible)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_set_size (PgmDrawable *drawable, gfloat width, gfloat height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_get_size (PgmDrawable *drawable, OUTLIST gfloat width, OUTLIST gfloat height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_set_position (PgmDrawable *drawable, gfloat x, gfloat y, gfloat z)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_get_position (PgmDrawable *drawable, OUTLIST gfloat x, OUTLIST gfloat y, OUTLIST gfloat z)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_set_rotation_x (PgmDrawable *drawable, gfloat angle)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_get_rotation_x (PgmDrawable *drawable, OUTLIST gfloat angle)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_set_rotation_y (PgmDrawable *drawable, gfloat angle)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_get_rotation_y (PgmDrawable *drawable, OUTLIST gfloat angle)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_set_rotation_z (PgmDrawable *drawable, gfloat angle)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_get_rotation_z (PgmDrawable *drawable, OUTLIST gfloat angle)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_set_fg_color (PgmDrawable *drawable, guchar r, guchar g, guchar b, guchar a)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_get_fg_color (PgmDrawable *drawable, OUTLIST guchar r, OUTLIST guchar g, OUTLIST guchar b, OUTLIST guchar a)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_set_bg_color (PgmDrawable *drawable, guchar r, guchar g, guchar b, guchar a)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_get_bg_color (PgmDrawable *drawable, OUTLIST guchar r, OUTLIST guchar g, OUTLIST guchar b, OUTLIST guchar a)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_set_opacity (PgmDrawable *drawable, guchar opacity)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_get_opacity (PgmDrawable *drawable, OUTLIST guchar opacity)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_set_drag_distance (PgmDrawable *drawable, guchar distance)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_get_drag_distance (PgmDrawable *drawable, OUTLIST guchar distance)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_regenerate (PgmDrawable *drawable)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_from_canvas (PgmDrawable *drawable, OUTLIST gfloat x_drawable, OUTLIST gfloat y_drawable, gfloat x_canvas, gfloat y_canvas, gfloat z_canvas)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_drawable_to_canvas (PgmDrawable *drawable, OUTLIST gfloat x_canvas, OUTLIST gfloat y_canvas, OUTLIST gfloat z_canvas, gfloat x_drawable, gfloat y_drawable)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);
