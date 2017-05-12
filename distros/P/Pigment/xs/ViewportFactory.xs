#include "perl-pigment.h"

MODULE = Pigment::ViewportFactory  PACKAGE = Pigment::ViewportFactory  PREFIX = pgm_viewport_factory_

PgmViewportFactory *
pgm_viewport_factory_new (class, name)
		const gchar *name
	C_ARGS:
		name

NO_OUTPUT PgmError
pgm_viewport_factory_get_description (PgmViewportFactory *factory, OUTLIST gchar *description)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_factory_get_license (PgmViewportFactory *factory, OUTLIST gchar *license)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_factory_get_origin (PgmViewportFactory *factory, OUTLIST gchar *origin)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_factory_get_author (PgmViewportFactory *factory, OUTLIST gchar *author)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_factory_create (PgmViewportFactory *factory, OUTLIST PgmViewport *viewport)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_viewport_factory_make (class, const gchar *name, OUTLIST PgmViewport *viewport)
	C_ARGS:
		name, &viewport
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);
