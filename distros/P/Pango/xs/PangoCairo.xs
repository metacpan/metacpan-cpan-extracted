/*
 * Copyright (c) 2005, 2014 by the gtk2-perl team (see the AUTHORS
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
#include <cairo-perl.h>
#include <gperl_marshal.h>

/* ------------------------------------------------------------------------- */

#if PANGO_CHECK_VERSION (1, 17, 0)

static void
gtk2perl_pango_cairo_shape_renderer_func (cairo_t        *cr,
					  PangoAttrShape *attr,
					  gboolean        do_path,
					  gpointer        data)
{
	GPerlCallback *callback = (GPerlCallback *) data;
	dGPERL_CALLBACK_MARSHAL_SP;

	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVCairo (cr)));
	PUSHs (sv_2mortal (newSVPangoAttribute (attr)));
	PUSHs (sv_2mortal (newSVuv (do_path)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

#endif

/* ------------------------------------------------------------------------- */

MODULE = Pango::Cairo	PACKAGE = Pango::Cairo::FontMap	PREFIX = pango_cairo_font_map_

# PangoFontMap *pango_cairo_font_map_new (void);
PangoFontMap_noinc * pango_cairo_font_map_new (class)
    C_ARGS:
	/* void */

# PangoFontMap *pango_cairo_font_map_get_default (void);
PangoFontMap * pango_cairo_font_map_get_default (class)
    C_ARGS:
	/* void */

void pango_cairo_font_map_set_resolution (PangoCairoFontMap *fontmap, double dpi);

double pango_cairo_font_map_get_resolution (PangoCairoFontMap *fontmap);

# PangoContext *pango_cairo_font_map_create_context (PangoCairoFontMap *fontmap);
SV *
pango_cairo_font_map_create_context (PangoCairoFontMap *fontmap)
    PREINIT:
	PangoContext *context;
	HV *stash;
    CODE:
	context = pango_cairo_font_map_create_context (fontmap);
	if (!context)
		XSRETURN_UNDEF;
	RETVAL = newSVPangoContext (context);
	stash = gv_stashpv ("Pango::Cairo::Context", TRUE);
	sv_bless (RETVAL, stash);
    OUTPUT:
	RETVAL

#if PANGO_CHECK_VERSION (1, 18, 0)

# PangoFontMap *pango_cairo_font_map_new_for_font_type (cairo_font_type_t fonttype);
PangoFontMap_noinc * pango_cairo_font_map_new_for_font_type (class, cairo_font_type_t fonttype)
    C_ARGS:
	fonttype

cairo_font_type_t pango_cairo_font_map_get_font_type (PangoCairoFontMap *fontmap);

#endif

# --------------------------------------------------------------------------- #

MODULE = Pango::Cairo	PACKAGE = Pango::Cairo::Font	PREFIX = pango_cairo_font_

#if PANGO_CHECK_VERSION (1, 18, 0)

cairo_scaled_font_t *pango_cairo_font_get_scaled_font (PangoCairoFont *font);

#endif

# --------------------------------------------------------------------------- #

MODULE = Pango::Cairo	PACKAGE = Pango::Cairo	PREFIX = pango_cairo_

=for position DESCRIPTION
I<Pango::Cairo> contains a few functions that help integrate pango and
cairo.  Since they aren't methods of a particular object, they are bound as
plain functions.
=cut

=for apidoc __function__
=cut
void pango_cairo_update_context (cairo_t *cr, PangoContext *context);

=for apidoc __function__
=cut
PangoLayout *pango_cairo_create_layout (cairo_t *cr);

=for apidoc __function__
=cut
void pango_cairo_update_layout (cairo_t *cr, PangoLayout *layout);

=for apidoc __function__
=cut
void pango_cairo_show_glyph_string (cairo_t *cr, PangoFont *font, PangoGlyphString *glyphs);

=for apidoc __function__
=cut
void pango_cairo_show_layout_line (cairo_t *cr, PangoLayoutLine *line);

=for apidoc __function__
=cut
void pango_cairo_show_layout (cairo_t *cr, PangoLayout *layout);

=for apidoc __function__
=cut
void pango_cairo_glyph_string_path (cairo_t *cr, PangoFont *font, PangoGlyphString *glyphs);

=for apidoc __function__
=cut
void pango_cairo_layout_line_path (cairo_t *cr, PangoLayoutLine *line);

=for apidoc __function__
=cut
void pango_cairo_layout_path (cairo_t *cr, PangoLayout *layout);

#if PANGO_CHECK_VERSION (1, 14, 0)

=for apidoc __function__
=cut
void pango_cairo_show_error_underline (cairo_t *cr, double x, double y, double width, double height);

=for apidoc __function__
=cut
void pango_cairo_error_underline_path (cairo_t *cr, double x, double y, double width, double height);

#endif

# --------------------------------------------------------------------------- #

MODULE = Pango::Cairo	PACKAGE = Pango::Cairo::Context	PREFIX = pango_cairo_context_

BOOT:
	gperl_set_isa ("Pango::Cairo::Context", "Pango::Context");

=for position post_hierarchy

=head1 HIERARCHY

  Glib::Object
  +----Pango::Context
       +----Pango::Cairo::Context

=cut

=for apidoc __function__
=cut
void pango_cairo_context_set_font_options (PangoContext *context, const cairo_font_options_t *options);

=for apidoc __function__
=cut
# const cairo_font_options_t *pango_cairo_context_get_font_options (PangoContext *context);
const cairo_font_options_t *pango_cairo_context_get_font_options (PangoContext *context);
    CODE:
	RETVAL = cairo_font_options_copy (
			pango_cairo_context_get_font_options (context));
    OUTPUT:
	RETVAL

=for apidoc __function__
=cut
void pango_cairo_context_set_resolution (PangoContext *context, double dpi);

=for apidoc __function__
=cut
double pango_cairo_context_get_resolution (PangoContext *context);

#if PANGO_CHECK_VERSION (1, 18, 0)

=for apidoc __function__
=cut
# void pango_cairo_context_set_shape_renderer (PangoContext *context, PangoCairoShapeRendererFunc func, gpointer data, GDestroyNotify dnotify)
void
pango_cairo_context_set_shape_renderer (PangoContext *context, SV *func=NULL, SV *data=NULL)
    PREINIT:
	GPerlCallback *callback;
	GDestroyNotify dnotify;
    CODE:
	if (gperl_sv_is_defined (func)) {
		callback = gperl_callback_new (func, data, 0, NULL, 0);
		dnotify = (GDestroyNotify) gperl_callback_destroy;
	} else {
		callback = NULL;
		dnotify = NULL;
	}
	pango_cairo_context_set_shape_renderer (
		context,
		gtk2perl_pango_cairo_shape_renderer_func,
		callback,
		dnotify);

# Is this useful?  You can't use it to store away the old renderer while you
# temporarily install your own, since when you call set_shape_renderer(), the
# old renderer's destruction notification is executed.  So the stuff you got
# from get_shape_renderer() is now garbage.
# PangoCairoShapeRendererFunc pango_cairo_context_get_shape_renderer (PangoContext *context, gpointer *data)

#endif
