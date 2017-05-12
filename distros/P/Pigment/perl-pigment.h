#include <gtk2perl.h>
#include <gst2perl.h>
#include <pgm/pgm.h>
#include <pgm/imaging/pgmimaging.h>
#include <pgm/gtk/pgmgtk.h>
#include "pigment-autogen.h"

#define PERL_PIGMENT_ASSERT_ERROR(error) \
	if (error != PGM_ERROR_OK) { \
		croak ("Generic pigment error"); \
	}

GPerlBoxedWrapperClass *perl_pigment_get_element_wrapper_class (void);
