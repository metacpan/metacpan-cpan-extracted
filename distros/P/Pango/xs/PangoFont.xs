/*
 * Copyright (c) 2003-2005, 2014 by the gtk2-perl team (see the AUTHORS
 * file for a full list of authors)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top-level directory of this distribution for
 * the full license terms.
 *
 */

#include "pango-perl.h"

MODULE = Pango::Font	PACKAGE = Pango

=for object Pango::FontDescription
=cut

### some constants...
double
scale (class)
    ALIAS:
	Pango::scale_xx_small = 1
	Pango::scale_x_small  = 2
	Pango::scale_small    = 3
	Pango::scale_medium   = 4
	Pango::scale_large    = 5
	Pango::scale_x_large  = 6
	Pango::scale_xx_large = 7
    CODE:
	switch (ix) {
		case 0: RETVAL = (double)PANGO_SCALE; break;
		case 1: RETVAL = PANGO_SCALE_XX_SMALL; break;
		case 2: RETVAL = PANGO_SCALE_X_SMALL; break;
		case 3: RETVAL = PANGO_SCALE_SMALL; break;
		case 4: RETVAL = PANGO_SCALE_MEDIUM; break;
		case 5: RETVAL = PANGO_SCALE_LARGE; break;
		case 6: RETVAL = PANGO_SCALE_X_LARGE; break;
		case 7: RETVAL = PANGO_SCALE_XX_LARGE; break;
		default:
			RETVAL = 0.0;
			g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

double
PANGO_PIXELS (class, d)
	double d
    ALIAS:
	Pango::pixels = 1
    C_ARGS:
	d
    CLEANUP:
	PERL_UNUSED_VAR (ix);

MODULE = Pango::Font	PACKAGE = Pango::FontDescription	PREFIX = pango_font_description_

##PangoFontDescription* pango_font_description_new (void)
PangoFontDescription_own *
pango_font_description_new (class)
    C_ARGS:
	/* void */

## guint pango_font_description_hash (const PangoFontDescription *desc)
guint
pango_font_description_hash (desc)
	PangoFontDescription *desc

## gboolean pango_font_description_equal (const PangoFontDescription *desc1, const PangoFontDescription *desc2)
gboolean
pango_font_description_equal (desc1, desc2)
	PangoFontDescription *desc1
	PangoFontDescription *desc2

# should be taken care of automagically
## void pango_font_description_free (PangoFontDescription *desc)
## void pango_font_descriptions_free (PangoFontDescription **descs, int n_descs)

## void pango_font_description_set_family (PangoFontDescription *desc, const char *family)
void
pango_font_description_set_family (desc, family)
	PangoFontDescription *desc
	const char *family

## void pango_font_description_set_family_static (PangoFontDescription *desc, const char *family)
void
pango_font_description_set_family_static (desc, family)
	PangoFontDescription *desc
	const char *family

## void pango_font_description_get_family (PangoFontDescription *desc, )
const char *
pango_font_description_get_family (desc)
	PangoFontDescription *desc

## void pango_font_description_set_style (PangoFontDescription *desc, PangoStyle style)
void
pango_font_description_set_style (desc, style)
	PangoFontDescription *desc
	PangoStyle style

## PangoStyle pango_font_description_get_style (const PangoFontDescription *desc)
PangoStyle
pango_font_description_get_style (desc)
	PangoFontDescription *desc

## void pango_font_description_set_variant (PangoFontDescription *desc, PangoVariant variant)
void
pango_font_description_set_variant (desc, variant)
	PangoFontDescription *desc
	PangoVariant variant

## PangoVariant pango_font_description_get_variant (const PangoFontDescription *desc)
PangoVariant
pango_font_description_get_variant (desc)
	PangoFontDescription *desc

## void pango_font_description_set_weight (PangoFontDescription *desc, PangoWeight weight)
void
pango_font_description_set_weight (desc, weight)
	PangoFontDescription *desc
	PangoWeight weight

## PangoWeight pango_font_description_get_weight (const PangoFontDescription *desc)
PangoWeight
pango_font_description_get_weight (desc)
	PangoFontDescription *desc

## void pango_font_description_set_stretch (PangoFontDescription *desc, PangoStretch stretch)
void
pango_font_description_set_stretch (desc, stretch)
	PangoFontDescription *desc
	PangoStretch stretch

## PangoStretch pango_font_description_get_stretch (const PangoFontDescription *desc)
PangoStretch
pango_font_description_get_stretch (desc)
	PangoFontDescription *desc

## void pango_font_description_set_size (PangoFontDescription *desc, gint size)
void
pango_font_description_set_size (desc, size)
	PangoFontDescription *desc
	gint size

## gint pango_font_description_get_size (const PangoFontDescription *desc)
gint
pango_font_description_get_size (desc)
	PangoFontDescription *desc

## PangoFontMask pango_font_description_get_set_fields (const PangoFontDescription *desc)
PangoFontMask
pango_font_description_get_set_fields (desc)
	PangoFontDescription *desc

## void pango_font_description_unset_fields (PangoFontDescription *desc, PangoFontMask to_unset)
void
pango_font_description_unset_fields (desc, to_unset)
	PangoFontDescription *desc
	PangoFontMask to_unset

## void pango_font_description_merge (PangoFontDescription *desc, const PangoFontDescription *desc_to_merge, gboolean replace_existing)
void
pango_font_description_merge (desc, desc_to_merge, replace_existing)
	PangoFontDescription *desc
	PangoFontDescription *desc_to_merge
	gboolean replace_existing

## void pango_font_description_merge_static (PangoFontDescription *desc, const PangoFontDescription *desc_to_merge, gboolean replace_existing)
void
pango_font_description_merge_static (desc, desc_to_merge, replace_existing)
	PangoFontDescription *desc
	PangoFontDescription *desc_to_merge
	gboolean replace_existing

## gboolean pango_font_description_better_match (const PangoFontDescription *desc, const PangoFontDescription *old_match, const PangoFontDescription *new_match)
gboolean
pango_font_description_better_match (desc, old_match, new_match)
	PangoFontDescription *desc
	PangoFontDescription_ornull *old_match
	PangoFontDescription *new_match


##PangoFontDescription *pango_font_description_from_string (const char *str)
PangoFontDescription_own *
pango_font_description_from_string (class, str)
	const char * str
    C_ARGS:
	str

## char * pango_font_description_to_string (const PangoFontDescription *desc)
char *
pango_font_description_to_string (desc)
	PangoFontDescription *desc
    CLEANUP:
	g_free (RETVAL);

## char * pango_font_description_to_filename (const PangoFontDescription *desc)
char *
pango_font_description_to_filename (desc)
	PangoFontDescription *desc
    CLEANUP:
	g_free (RETVAL);

#if PANGO_CHECK_VERSION (1, 8, 0)

void pango_font_description_set_absolute_size (PangoFontDescription *desc, double size);

gboolean pango_font_description_get_size_is_absolute (const PangoFontDescription *desc);

#endif

#if PANGO_CHECK_VERSION (1, 16, 0)

void pango_font_description_set_gravity (PangoFontDescription *desc, PangoGravity gravity);

PangoGravity pango_font_description_get_gravity (const PangoFontDescription *desc);

#endif

MODULE = Pango::Font	PACKAGE = Pango::FontMetrics	PREFIX = pango_font_metrics_

# should happen automagicly
## void pango_font_metrics_unref (PangoFontMetrics *metrics)

## int pango_font_metrics_get_ascent (PangoFontMetrics *metrics)
int
pango_font_metrics_get_ascent (metrics)
	PangoFontMetrics *metrics

## int pango_font_metrics_get_descent (PangoFontMetrics *metrics)
int
pango_font_metrics_get_descent (metrics)
	PangoFontMetrics *metrics

## int pango_font_metrics_get_approximate_char_width (PangoFontMetrics *metrics)
int
pango_font_metrics_get_approximate_char_width (metrics)
	PangoFontMetrics *metrics

## int pango_font_metrics_get_approximate_digit_width (PangoFontMetrics *metrics)
int
pango_font_metrics_get_approximate_digit_width (metrics)
	PangoFontMetrics *metrics

#if PANGO_CHECK_VERSION (1, 6, 0)

## int pango_font_metrics_get_underline_position (PangoFontMetrics *metrics)
int
pango_font_metrics_get_underline_position (metrics)
	PangoFontMetrics *metrics

## int pango_font_metrics_get_underline_thickness (PangoFontMetrics *metrics)
int
pango_font_metrics_get_underline_thickness (metrics)
	PangoFontMetrics *metrics

## int pango_font_metrics_get_strikethrough_position (PangoFontMetrics *metrics)
int
pango_font_metrics_get_strikethrough_position (metrics)
	PangoFontMetrics *metrics

## int pango_font_metrics_get_strikethrough_thickness (PangoFontMetrics *metrics)
int
pango_font_metrics_get_strikethrough_thickness (metrics)
	PangoFontMetrics *metrics

#endif

MODULE = Pango::Font	PACKAGE = Pango::FontFamily	PREFIX = pango_font_family_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (PANGO_TYPE_FONT_FAMILY, TRUE);

## void pango_font_family_list_faces (PangoFontFamily *family, PangoFontFace ***faces, int *n_faces)
=for apidoc
=for apidoc @faces = $family->list_faces
Lists the different font faces that make up family. The faces in a family
share a common design, but differ in slant, weight, width and other aspects.
=cut
void
pango_font_family_list_faces (family)
	PangoFontFamily *family
    PREINIT:
	PangoFontFace ** faces = NULL;
	int n_faces;
    PPCODE:
	pango_font_family_list_faces(family, &faces, &n_faces);
	if (n_faces > 0) {
		int i;
		EXTEND(SP,n_faces);
		for (i = 0 ; i < n_faces ; i++)
			PUSHs(sv_2mortal(newSVPangoFontFace(faces[i])));
		g_free (faces);
	}


const char * pango_font_family_get_name (PangoFontFamily * family)

#if PANGO_CHECK_VERSION(1, 4, 0)

gboolean pango_font_family_is_monospace (PangoFontFamily * family)

#endif

MODULE = Pango::Font	PACKAGE = Pango::FontFace	PREFIX = pango_font_face_

#
# PangoFontFace
#

BOOT:
	gperl_object_set_no_warn_unreg_subclass (PANGO_TYPE_FONT_FACE, TRUE);

 ## PangoFontDescription *pango_font_face_describe (PangoFontFace *face);
PangoFontDescription_own * pango_font_face_describe (PangoFontFace *face);

 ## G_CONST_RETURN char *pango_font_face_get_face_name (PangoFontFace *face);
const char *pango_font_face_get_face_name (PangoFontFace *face);

#if PANGO_CHECK_VERSION(1, 4, 0)

 ## void pango_font_face_list_sizes (PangoFontFace  *face, int **sizes, int *n_sizes);
=for apidoc
=for signature @sizes = $face->list_sizes
List the sizes available for a bitmapped font.  For scalable fonts, this will
return an empty list.
=cut
void
pango_font_face_list_sizes (PangoFontFace *face)
    PREINIT:
	int *sizes=NULL, n_sizes, i;
    PPCODE:
	pango_font_face_list_sizes (face, &sizes, &n_sizes);
	if (n_sizes > 0) {
		EXTEND (SP, n_sizes);
		for (i = 0 ; i < n_sizes ; i++)
			PUSHs (sv_2mortal (newSViv (sizes[i])));
		g_free (sizes);
	}

#endif

#if PANGO_CHECK_VERSION(1, 18, 0)

gboolean pango_font_face_is_synthesized (PangoFontFace *face);

#endif

MODULE = Pango::Font	PACKAGE = Pango::Font	PREFIX = pango_font_

## PangoFontMetrics * pango_font_get_metrics (PangoFont *font, PangoLanguage *language)
PangoFontMetrics *
pango_font_get_metrics (font, language)
	PangoFont *font
	PangoLanguage *language

## PangoFontDescription* pango_font_describe (PangoFont *font)
PangoFontDescription_own *
pango_font_describe (font)
	PangoFont *font

#if PANGO_CHECK_VERSION(1, 14, 0)

 ## PangoFontDescription *pango_font_describe_with_absolute_size (PangoFont *font);
PangoFontDescription_own *pango_font_describe_with_absolute_size (PangoFont *font);

#endif

## void pango_font_get_glyph_extents (PangoFont *font, PangoGlyph glyph, PangoRectangle *ink_rect, PangoRectangle *logical_rect)
void
pango_font_get_glyph_extents (font, glyph)
	PangoFont *font
	PangoGlyph glyph
    PREINIT:
	PangoRectangle ink_rect;
	PangoRectangle logical_rect;
    PPCODE:
	pango_font_get_glyph_extents (font, glyph, &ink_rect, &logical_rect);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVPangoRectangle (&ink_rect)));
	PUSHs (sv_2mortal (newSVPangoRectangle (&logical_rect)));

#if PANGO_CHECK_VERSION(1, 10, 0)

PangoFontMap * pango_font_get_font_map (PangoFont *font);

#endif

### no typemaps for this stuff.
### it looks like it would only be useful from C, though.
### PangoCoverage * pango_font_get_coverage (PangoFont *font, PangoLanguage *language)
### PangoEngineShape * pango_font_find_shaper (PangoFont *font, PangoLanguage *language, guint32 ch)
