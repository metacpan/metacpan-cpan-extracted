#include "perl-pigment.h"

MODULE = Pigment::Text  PACKAGE = Pigment::Text  PREFIX = pgm_text_

PgmDrawable *
pgm_text_new (class, const gchar *markup=NULL)
	C_ARGS:
		markup

NO_OUTPUT PgmError
pgm_text_set_label (PgmText *text, const gchar *label)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_markup (PgmText *text, const gchar *markup)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_label (PgmText *text, OUTLIST gchar *label)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_font_family (PgmText *text, const gchar *font_family)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_font_family (PgmText *text, OUTLIST gchar *font_family)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_font_height (PgmText *text, gfloat font_height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_font_height (PgmText *text, OUTLIST gfloat font_height)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_ellipsize (PgmText *text, PgmTextEllipsize ellipsize)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_ellipsize (PgmText *text, OUTLIST PgmTextEllipsize ellipsize)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_justify (PgmText *text, gboolean justify)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_justify (PgmText *text, OUTLIST gboolean justify)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_alignment (PgmText *text, PgmTextAlignment alignment)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_alignment (PgmText *text, OUTLIST PgmTextAlignment alignment)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_wrap (PgmText *text, PgmTextWrap wrap)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_wrap (PgmText *text, OUTLIST PgmTextWrap wrap)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_gravity (PgmText *text, PgmTextGravity gravity)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_gravity (PgmText *text, OUTLIST PgmTextGravity gravity)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_stretch (PgmText *text, PgmTextStretch stretch)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_stretch (PgmText *text, OUTLIST PgmTextStretch stretch)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_style (PgmText *text, PgmTextStyle style)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_style (PgmText *text, OUTLIST PgmTextStyle style)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_variant (PgmText *text, PgmTextVariant variant)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_variant (PgmText *text, OUTLIST PgmTextVariant variant)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_weight (PgmText *text, PgmTextWeight weight)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_weight (PgmText *text, OUTLIST PgmTextWeight weight)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_line_spacing (PgmText *text, gfloat line_spacing)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_line_spacing (PgmText *text, OUTLIST gfloat line_spacing)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_outline_color (PgmText *text, guchar red, guchar green, guchar blue, guchar alpha)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_outline_color (PgmText *text, OUTLIST guchar red, OUTLIST guchar green, OUTLIST guchar blue, OUTLIST guchar alpha)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_set_outline_width (PgmText *text, gfloat width)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);

NO_OUTPUT PgmError
pgm_text_get_outline_width (PgmText *text, OUTLIST gfloat width)
	POSTCALL:
		PERL_PIGMENT_ASSERT_ERROR (RETVAL);
