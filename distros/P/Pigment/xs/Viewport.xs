#include "perl-pigment.h"

MODULE = Pigment::Viewport  PACKAGE = Pigment::Viewport  PREFIX = pgm_viewport_

NO_OUTPUT PgmError
pgm_viewport_set_title (PgmViewport *viewport, const gchar *title)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_title (PgmViewport *viewport, OUTLIST gchar *title)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_show (PgmViewport *viewport)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_hide (PgmViewport *viewport)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_is_visible (PgmViewport *viewport, OUTLIST gboolean visible)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_decorated (PgmViewport *viewport, gboolean decorated)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_decorated (PgmViewport *viewport, OUTLIST gboolean decorated)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_cursor (PgmViewport *viewport, PgmViewportCursor cursor)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_cursor (PgmViewport *viewport, OUTLIST PgmViewportCursor cursor)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_icon (PgmViewport *viewport, GdkPixbuf *icon)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_icon (PgmViewport *viewport, OUTLIST GdkPixbuf *icon)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_size (PgmViewport *viewport, gint width, gint height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_size (PgmViewport *viewport, OUTLIST gint width, OUTLIST gint height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_alpha_blending (PgmViewport *viewport, gboolean alpha_blending)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_alpha_blending (PgmViewport *viewport, OUTLIST gboolean alpha_blending)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_opacity (PgmViewport *viewport, guchar opacity)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_opacity (PgmViewport *viewport, OUTLIST guchar opacity)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_fullscreen (PgmViewport *viewport, gboolean fullscreen)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_fullscreen (PgmViewport *viewport, OUTLIST gboolean fullscreen)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_iconified (PgmViewport *viewport, gboolean iconified)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_iconified (PgmViewport *viewport, OUTLIST gboolean iconified)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_focus (PgmViewport *viewport)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_screen_resolution (PgmViewport *viewport, gint width, gint height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_screen_resolution (PgmViewport *viewport, OUTLIST gint width, OUTLIST gint height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_screen_size_mm (PgmViewport *viewport, gint width, gint height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_screen_size_mm (PgmViewport *viewport, OUTLIST gint width, OUTLIST gint height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_push_event (PgmViewport *viewport, PgmEvent *event)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_canvas (PgmViewport *viewport, OUTLIST PgmCanvas *canvas)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_canvas (PgmViewport *viewport, PgmCanvas *canvas)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_canvas_rotation (PgmViewport *viewport, PgmViewportRotation rotation)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_canvas_rotation (PgmViewport *viewport, OUTLIST PgmViewportRotation rotation)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_set_canvas_reflection (PgmViewport *viewport, PgmViewportReflection reflection)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_canvas_reflection (PgmViewport *viewport, OUTLIST PgmViewportReflection reflection)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

#TODO:
# PgmError pgm_viewport_set_message_filter (PgmViewport *viewport, GList *filter)
# PgmError pgm_viewport_get_message_filter (PgmViewport *viewport, GList **filter)

NO_OUTPUT PgmError
pgm_viewport_update_projection (PgmViewport *viewport)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_to_canvas (PgmViewport *viewport, OUTLIST gfloat canvas_x, OUTLIST gfloat canvas_y, OUTLIST gfloat canvas_z, gfloat viewport_x, gfloat viewport_y, gfloat viewport_z)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_from_canvas (PgmViewport *viewport, OUTLIST gfloat viewport_x, OUTLIST gfloat viewport_y, OUTLIST gfloat viewport_z, gfloat canvas_x, gfloat canvas_y, gfloat canvas_z)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_embedding_id (PgmViewport *viewport, OUTLIST gulong embedding_id)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_pixel_formats (PgmViewport *viewport, OUTLIST PgmImagePixelFormat formats_mask)
    C_ARGS:
        viewport, (gulong *)&formats_mask
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_caps_mask (PgmViewport *viewport, OUTLIST gulong caps_mask)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_get_frame_rate (PgmViewport *viewport, OUTLIST guint frame_rate)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

# TODO:
# PgmError pgm_viewport_read_pixels (PgmViewport *viewport, guint x, guint y, guint width, guint height, guint8 *pixels)
# PgmError pgm_viewport_push_pixels (PgmViewport *viewport, gint width, gint height, guint8 *pixels)

NO_OUTPUT PgmError
pgm_viewport_emit_update_pass (PgmViewport *viewport)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);
