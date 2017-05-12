#include "perl-pigment.h"

MODULE = Pigment::Image  PACKAGE = Pigment::Image  PREFIX = pgm_image_

PgmDrawable *
pgm_image_new (class)
	C_ARGS:

PgmDrawable *
pgm_image_new_from_file (class, const gchar *filename, guint max_size=0)
	C_ARGS:
		filename, max_size

PgmDrawable *
pgm_image_new_from_pixbuf (class, GdkPixbuf *pixbuf)
	C_ARGS:
		pixbuf

PgmDrawable *
pgm_image_new_from_image (class, PgmImage *src_image)
	C_ARGS:
		src_image

NO_OUTPUT PgmError
pgm_image_set_from_file (PgmImage *image, const gchar *filename, guint max_size)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_from_pixbuf (PgmImage *image, GdkPixbuf *pixbuf)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_from_gst_buffer (PgmImage *image, PgmImagePixelFormat format, guint width, guint height, guint stride, GstBuffer *buffer)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_from_image (PgmImage *image, PgmImage *src_image)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_to_pixbuf (PgmImage *image, OUTLIST GdkPixbuf *pixbuf)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_clear (PgmImage *image)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_get_storage_type (PgmImage *image, OUTLIST PgmImageStorageType storage)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_system_buffer_lock (PgmImage *image)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_system_buffer_unlock (PgmImage *image)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

# TODO:
# PgmError pgm_image_set_mapping_matrix (PgmImage *image, PgmMat4x4 *mapping_matrix);
# PgmError pgm_image_get_mapping_matrix (PgmImage *image, PgmMat4x4 **mapping_matrix);

NO_OUTPUT PgmError
pgm_image_set_alignment (PgmImage *image, PgmImageAlignment align)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_get_alignment (PgmImage *image, OUTLIST PgmImageAlignment align)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_layout (PgmImage *image, PgmImageLayoutType layout)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_get_layout (PgmImage *image, OUTLIST PgmImageLayoutType layout)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_interp (PgmImage *image, PgmImageInterpType interp)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_get_interp (PgmImage *image, OUTLIST PgmImageInterpType interp)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_wrapping (PgmImage *image, PgmImageWrapping wrap_s, PgmImageWrapping wrap_t)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_get_wrapping (PgmImage *image, OUTLIST PgmImageWrapping wrap_s, OUTLIST PgmImageWrapping wrap_t)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_aspect_ratio (PgmImage *image, guint numerator, guint denominator)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_get_aspect_ratio (PgmImage *image, OUTLIST guint numerator, OUTLIST guint denominator)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_border_width (PgmImage *image, gfloat width)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_get_border_width (PgmImage *image, OUTLIST gfloat width)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_border_inner_color (PgmImage *image, guchar red, guchar green, guchar blue, guchar alpha)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_get_border_inner_color (PgmImage *image, OUTLIST guchar red, OUTLIST guchar green, OUTLIST guchar blue, OUTLIST guchar alpha)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_set_border_outer_color (PgmImage *image, guchar red, guchar green, guchar blue, guchar alpha)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_get_border_outer_color (PgmImage *image, OUTLIST guchar red, OUTLIST guchar green, OUTLIST guchar blue, OUTLIST guchar alpha)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_from_drawable (PgmImage *image, OUTLIST gint x_image, OUTLIST gint y_image, gfloat x_drawable, gfloat y_drawable)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_to_drawable (PgmImage *image, OUTLIST gfloat x_drawable, OUTLIST gfloat y_drawable, gint x_image, gint y_image)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);
