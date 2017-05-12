#include "perl-pigment.h"

MODULE = Pigment::ImageSink  PACKAGE = Pigment::ImageSink  PREFIX = pgm_image_sink_

GstElement *
pgm_image_sink_new (class, const gchar *name)
	C_ARGS:
		name

NO_OUTPUT PgmError
pgm_image_sink_set_image (PgmImageSink *sink, PgmImage *image)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_sink_get_image (PgmImageSink *sink, OUTLIST PgmImage *image)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_sink_set_events (PgmImageSink *sink, PgmImageSinkEventMask events)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_image_sink_get_events (PgmImageSink *sink, OUTLIST PgmImageSinkEventMask events)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);
