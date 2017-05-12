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

/* ------------------------------------------------------------------------- */

#if !PANGO_CHECK_VERSION (1, 20, 0)

static gpointer
gtk2perl_pango_layout_iter_copy (gpointer boxed)
{
	croak ("Can't copy a PangoLayoutIter");
	return boxed;
}

#endif

GType
gtk2perl_pango_layout_iter_get_type (void)
{
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static ("PangoLayoutIter",
#if PANGO_CHECK_VERSION (1, 20, 0)
		      (GBoxedCopyFunc) pango_layout_iter_copy,
#else
		      (GBoxedCopyFunc) gtk2perl_pango_layout_iter_copy,
#endif
		      (GBoxedFreeFunc) pango_layout_iter_free);
	return t;
}

/* ------------------------------------------------------------------------- */

GType
gtk2perl_pango_layout_line_get_type (void)
{
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static ("PangoLayoutLine",
		      (GBoxedCopyFunc) pango_layout_line_ref,
		      (GBoxedFreeFunc) pango_layout_line_unref);
	return t;
}

/* ------------------------------------------------------------------------- */

SV *
newSVPangoRectangle (PangoRectangle * rectangle)
{
	HV * hv;

	if (!rectangle)
		return &PL_sv_undef;

	hv = newHV ();

	hv_store (hv, "x", 1, newSViv (rectangle->x), 0);
	hv_store (hv, "y", 1, newSViv (rectangle->y), 0);
	hv_store (hv, "width", 5, newSViv (rectangle->width), 0);
	hv_store (hv, "height", 6, newSViv (rectangle->height), 0);

	return newRV_noinc ((SV *) hv);
}

PangoRectangle *
SvPangoRectangle (SV * sv)
{
	PangoRectangle *rectangle;
	SV ** v;

	if (!gperl_sv_is_defined (sv))
		return NULL;

	rectangle = gperl_alloc_temp (sizeof (PangoRectangle));

	if (gperl_sv_is_hash_ref (sv)) {
		HV * hv = (HV *) SvRV (sv);

		v = hv_fetch (hv, "x", 1, 0);
		if (v && gperl_sv_is_defined (*v))
			rectangle->x = SvIV (*v);

		v = hv_fetch (hv, "y", 1, 0);
		if (v && gperl_sv_is_defined (*v))
			rectangle->y = SvIV (*v);

		v = hv_fetch (hv, "width", 5, 0);
		if (v && gperl_sv_is_defined (*v))
			rectangle->width = SvIV (*v);

		v = hv_fetch (hv, "height", 6, 0);
		if (v && gperl_sv_is_defined (*v))
			rectangle->height = SvIV (*v);
	} else if (gperl_sv_is_array_ref (sv)) {
		AV * av = (AV *) SvRV (sv);

		v = av_fetch (av, 0, 0);
		if (v && gperl_sv_is_defined (*v))
			rectangle->x = SvIV (*v);

		v = av_fetch (av, 1, 0);
		if (v && gperl_sv_is_defined (*v))
			rectangle->y = SvIV (*v);

		v = av_fetch (av, 2, 0);
		if (v && gperl_sv_is_defined (*v))
			rectangle->width = SvIV (*v);

		v = av_fetch (av, 3, 0);
		if (v && gperl_sv_is_defined (*v))
			rectangle->height = SvIV (*v);
	} else {
		croak ("a PangoRectangle must be a reference to a hash "
		       "or a reference to an array");
	}

	return rectangle;
}

/* ------------------------------------------------------------------------- */

static SV *
newSVPangoLogAttr (PangoLogAttr * logattr)
{
	HV * hv = newHV ();

#define STORE_BIT(key) \
	hv_store (hv, #key, sizeof (#key) - 1, newSVuv (logattr->key), 0)

	STORE_BIT (is_line_break);
	STORE_BIT (is_mandatory_break);
	STORE_BIT (is_char_break);
	STORE_BIT (is_white);
	STORE_BIT (is_cursor_position);
	STORE_BIT (is_word_start);
	STORE_BIT (is_word_end);
	STORE_BIT (is_sentence_boundary);
	STORE_BIT (is_sentence_start);
	STORE_BIT (is_sentence_end);
#if PANGO_CHECK_VERSION (1, 4, 0)
	STORE_BIT (backspace_deletes_character);
#endif
#if PANGO_CHECK_VERSION (1, 18, 0)
	STORE_BIT (is_expandable_space);
#endif

#undef STORE_BIT

	return newRV_noinc ((SV*) hv);
}

MODULE = Pango::Layout	PACKAGE = Pango::Layout	PREFIX = pango_layout_

##  PangoLayout *pango_layout_new (PangoContext *context) 
PangoLayout_noinc *
pango_layout_new (class, context)
	PangoContext * context
    C_ARGS:
	context

##  PangoLayout *pango_layout_copy (PangoLayout *src) 
PangoLayout_noinc *
pango_layout_copy (src)
	PangoLayout *src

##  PangoContext *pango_layout_get_context (PangoLayout *layout) 
PangoContext *
pango_layout_get_context (layout)
	PangoLayout *layout

##  void pango_layout_set_attributes (PangoLayout *layout, PangoAttrList *attrs) 
void
pango_layout_set_attributes (layout, attrs)
	PangoLayout *layout
	PangoAttrList_ornull *attrs

##  PangoAttrList *pango_layout_get_attributes (PangoLayout *layout) 
PangoAttrList_ornull *
pango_layout_get_attributes (layout)
	PangoLayout *layout

##  void pango_layout_set_text (PangoLayout *layout, const char *text, int length) 
void
pango_layout_set_text (PangoLayout *layout, const gchar_length *text, int length(text))

##  const char * pango_layout_get_text (PangoLayout *layout);
const gchar *
pango_layout_get_text (layout)
	PangoLayout * layout

##  void pango_layout_set_markup (PangoLayout *layout, const char *markup, int length) 
void
pango_layout_set_markup (PangoLayout * layout, const gchar_length * markup, int length(markup))

##  void pango_layout_set_markup_with_accel (PangoLayout *layout, const char *markup, int length, gunichar accel_marker, gunichar *accel_char) 
void
pango_layout_set_markup_with_accel (PangoLayout * layout, const char * markup, int length(markup), gunichar accel_marker, OUTLIST gunichar accel_char)

##  void pango_layout_set_font_description (PangoLayout *layout, const PangoFontDescription *desc) 
void
pango_layout_set_font_description (layout, desc)
	PangoLayout *layout
	PangoFontDescription_ornull *desc

#if PANGO_CHECK_VERSION (1, 8, 0)

const PangoFontDescription_ornull * pango_layout_get_font_description (PangoLayout *layout);

#endif

##  int pango_layout_get_width (PangoLayout *layout) 
##  int pango_layout_get_indent (PangoLayout *layout) 
##  int pango_layout_get_spacing (PangoLayout *layout) 
##  gboolean pango_layout_get_justify (PangoLayout *layout) 
##  gboolean pango_layout_get_single_paragraph_mode (PangoLayout *layout) 
int
pango_layout_get_width (layout)
	PangoLayout * layout
    ALIAS:
	Pango::Layout::get_indent = 1
	Pango::Layout::get_spacing = 2
	Pango::Layout::get_justify = 3
	Pango::Layout::get_single_paragraph_mode = 4
    CODE:
	switch (ix) {
		case 0: RETVAL = pango_layout_get_width (layout); break;
		case 1: RETVAL = pango_layout_get_indent (layout); break;
		case 2: RETVAL = pango_layout_get_spacing (layout); break;
		case 3: RETVAL = pango_layout_get_justify (layout); break;
		case 4: RETVAL = pango_layout_get_single_paragraph_mode (layout); break;
		default:
			RETVAL = 0;
			g_assert_not_reached ();
	}
   OUTPUT:
	RETVAL

##  void pango_layout_set_width (PangoLayout *layout, int width) 
##  void pango_layout_set_indent (PangoLayout *layout, int indent) 
##  void pango_layout_set_spacing (PangoLayout *layout, int spacing) 
##  void pango_layout_set_justify (PangoLayout *layout, gboolean justify) 
##  void pango_layout_set_single_paragraph_mode (PangoLayout *layout, gboolean setting) 
void
pango_layout_set_width (layout, newval)
	PangoLayout * layout
	int newval
    ALIAS:
	Pango::Layout::set_indent = 1
	Pango::Layout::set_spacing = 2
	Pango::Layout::set_justify = 3
	Pango::Layout::set_single_paragraph_mode = 4
    CODE:
	switch (ix) {
		case 0: pango_layout_set_width (layout, newval); break;
		case 1: pango_layout_set_indent (layout, newval); break;
		case 2: pango_layout_set_spacing (layout, newval); break;
		case 3: pango_layout_set_justify (layout, newval); break;
		case 4: pango_layout_set_single_paragraph_mode (layout, newval); break;
		default:
			g_assert_not_reached ();
	}


##  void pango_layout_set_wrap (PangoLayout *layout, PangoWrapMode wrap) 
void
pango_layout_set_wrap (layout, wrap)
	PangoLayout *layout
	PangoWrapMode wrap

##  PangoWrapMode pango_layout_get_wrap (PangoLayout *layout) 
PangoWrapMode
pango_layout_get_wrap (layout)
	PangoLayout *layout

#if PANGO_CHECK_VERSION (1, 6, 0)

##  void pango_layout_set_ellipsize (PangoLayout *layout, PangoEllipsizeMode ellipsize)
void
pango_layout_set_ellipsize (layout, ellipsize)
	PangoLayout *layout
	PangoEllipsizeMode ellipsize

##  PangoEllipsizeMode pango_layout_get_ellipsize (PangoLayout *layout)
PangoEllipsizeMode
pango_layout_get_ellipsize (layout)
	PangoLayout *layout

#endif

#if PANGO_CHECK_VERSION (1, 4, 0)

##  void pango_layout_set_auto_dir (PangoLayout *layout, gboolean auto_dir)
void
pango_layout_set_auto_dir (layout, auto_dir)
	PangoLayout *layout
	gboolean auto_dir

##  gboolean pango_layout_get_auto_dir (PangoLayout *layout)
gboolean
pango_layout_get_auto_dir (layout)
	PangoLayout *layout

#endif

##  void pango_layout_set_alignment (PangoLayout *layout, PangoAlignment alignment) 
void
pango_layout_set_alignment (layout, alignment)
	PangoLayout *layout
	PangoAlignment alignment

##  PangoAlignment pango_layout_get_alignment (PangoLayout *layout) 
PangoAlignment
pango_layout_get_alignment (layout)
	PangoLayout *layout

##  void pango_layout_set_tabs (PangoLayout *layout, PangoTabArray *tabs) 
void
pango_layout_set_tabs (layout, tabs)
	PangoLayout *layout
	PangoTabArray_ornull *tabs

##  PangoTabArray* pango_layout_get_tabs (PangoLayout *layout) 
PangoTabArray_own_ornull *
pango_layout_get_tabs (layout)
	PangoLayout *layout


##  void pango_layout_context_changed (PangoLayout *layout) 
void
pango_layout_context_changed (layout)
	PangoLayout *layout

##  void pango_layout_get_log_attrs (PangoLayout *layout, PangoLogAttr **attrs, gint *n_attrs) 
=for apidoc
Returns a list of Pango::LogAttr's
=cut
void
pango_layout_get_log_attrs (layout)
	PangoLayout * layout
    PREINIT:
	PangoLogAttr * attrs = NULL;
	gint n_attrs;
    PPCODE:
	pango_layout_get_log_attrs (layout, &attrs, &n_attrs);
	if (n_attrs) {
		int i;
		EXTEND (SP, n_attrs);
		for (i = 0 ; i < n_attrs; i++)
			PUSHs (sv_2mortal (newSVPangoLogAttr (attrs+i)));
		g_free (attrs);
	}

##  void pango_layout_index_to_pos (PangoLayout *layout, int index_, PangoRectangle *pos) 
PangoRectangle *
pango_layout_index_to_pos (layout, index_) 
	PangoLayout *layout
	int index_
    PREINIT:
	PangoRectangle pos;
    CODE:
	pango_layout_index_to_pos (layout, index_, &pos);
	RETVAL = &pos;
    OUTPUT:
	RETVAL

##  void pango_layout_get_cursor_pos (PangoLayout *layout, int index_, PangoRectangle *strong_pos, PangoRectangle *weak_pos) 
=for apidoc
=for signature (strong_pos, weak_pos) = $layout->get_cursor_pos ($index)
=cut
void
pango_layout_get_cursor_pos (layout, index_) 
	PangoLayout *layout
	int index_
    PREINIT:
	PangoRectangle strong_pos;
	PangoRectangle weak_pos;
    PPCODE:
	pango_layout_get_cursor_pos (layout, index_, &strong_pos, &weak_pos);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVPangoRectangle (&strong_pos)));
	PUSHs (sv_2mortal (newSVPangoRectangle (&weak_pos)));

##  void pango_layout_move_cursor_visually (PangoLayout *layout, gboolean strong, int old_index, int old_trailing, int direction, int *new_index, int *new_trailing) 
void pango_layout_move_cursor_visually (PangoLayout *layout, gboolean strong, int old_index, int old_trailing, int direction, OUTLIST int new_index, OUTLIST int new_trailing) 

##  gboolean pango_layout_xy_to_index (PangoLayout *layout, int x, int y, int *index_, int *trailing) 
=for apidoc
=for signature (index, trailing) = $layout->xy_to_index ($x, $y)
=cut
void
pango_layout_xy_to_index (layout, x, y)
	PangoLayout *layout
	int x
	int y
    PREINIT:
	int index_;
	int trailing;
    PPCODE:
	if (pango_layout_xy_to_index (layout, x, y, &index_, &trailing)) {
		EXTEND (SP, 2);
		PUSHs (sv_2mortal (newSViv (index_)));
		PUSHs (sv_2mortal (newSViv (trailing)));
	}

##  void pango_layout_get_extents (PangoLayout *layout, PangoRectangle *ink_rect, PangoRectangle *logical_rect) 
=for apidoc
=for signature (ink_rect, logical_rect) = $layout->get_extents
=for signature (ink_rect, logical_rect) = $layout->get_pixel_extents
=cut
void
pango_layout_get_extents (layout) 
	PangoLayout *layout
    ALIAS:
	Pango::Layout::get_pixel_extents = 1
    PREINIT:
	PangoRectangle ink_rect;
	PangoRectangle logical_rect;
    PPCODE:
	switch (ix) {
		case 0:
			pango_layout_get_extents (layout, &ink_rect, &logical_rect);
			break;
		case 1:
			pango_layout_get_pixel_extents (layout, &ink_rect, &logical_rect);
			break;
		default:
			g_assert_not_reached ();
	}
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVPangoRectangle (&ink_rect)));
	PUSHs (sv_2mortal (newSVPangoRectangle (&logical_rect)));

##  void pango_layout_get_size (PangoLayout *layout, int *width, int *height) 
void pango_layout_get_size (PangoLayout *layout, OUTLIST int width, OUTLIST int height) 

##  void pango_layout_get_pixel_size (PangoLayout *layout, int *width, int *height) 
void pango_layout_get_pixel_size (PangoLayout *layout, OUTLIST int width, OUTLIST int height) 

##  int pango_layout_get_line_count (PangoLayout *layout) 
int
pango_layout_get_line_count (layout)
	PangoLayout *layout

##  PangoLayoutLine *pango_layout_get_line (PangoLayout *layout, int line) 
PangoLayoutLine_ornull *
pango_layout_get_line (layout, line)
	PangoLayout *layout
	int line

##  GSList * pango_layout_get_lines (PangoLayout *layout) 
void
pango_layout_get_lines (layout)
	PangoLayout *layout
    PREINIT:
	GSList * lines, * i;
    PPCODE:
	lines = pango_layout_get_lines (layout);
	for (i = lines ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVPangoLayoutLine (i->data)));
	/* the list is owned by the layout. */

#if PANGO_CHECK_VERSION (1, 16, 0)

##  PangoLayoutLine *pango_layout_get_line_readonly (PangoLayout *layout, int line) 
PangoLayoutLine_ornull *
pango_layout_get_line_readonly (layout, line)
	PangoLayout *layout
	int line

##  GSList * pango_layout_get_lines_readonly (PangoLayout *layout) 
void
pango_layout_get_lines_readonly (layout)
	PangoLayout *layout
    PREINIT:
	GSList * lines, * i;
    PPCODE:
	lines = pango_layout_get_lines_readonly (layout);
	for (i = lines ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVPangoLayoutLine (i->data)));
	/* the list is owned by the layout. */

#endif

##  PangoLayoutIter *pango_layout_get_iter (PangoLayout *layout)
PangoLayoutIter_own *
pango_layout_get_iter (layout)
	PangoLayout *layout

#if PANGO_CHECK_VERSION (1, 16, 0)

gboolean pango_layout_is_wrapped (PangoLayout *layout);

gboolean pango_layout_is_ellipsized (PangoLayout *layout);

int pango_layout_get_unknown_glyphs_count (PangoLayout *layout);

#endif

#if PANGO_CHECK_VERSION (1, 20, 0)

void pango_layout_set_height (PangoLayout *layout, int height);

int pango_layout_get_height (PangoLayout *layout);

#endif

#if PANGO_CHECK_VERSION (1, 22, 0)

int pango_layout_get_baseline (PangoLayout*layout)

#endif

# --------------------------------------------------------------------------- #

MODULE = Pango::Layout	PACKAGE = Pango::LayoutLine	PREFIX = pango_layout_line_

##  gboolean pango_layout_line_x_to_index (PangoLayoutLine *line, int x_pos, int *index_, int *trailing)
void
pango_layout_line_x_to_index (PangoLayoutLine *line, int x_pos)
    PREINIT:
	gboolean retval;
	int index_;
	int trailing;
    PPCODE:
	retval = pango_layout_line_x_to_index (line, x_pos, &index_, &trailing);
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (boolSV (retval)));
	PUSHs (sv_2mortal (newSViv (index_)));
	PUSHs (sv_2mortal (newSViv (trailing)));

##  void pango_layout_line_index_to_x (PangoLayoutLine *line, int index_, gboolean trailing, int *x_pos)
void pango_layout_line_index_to_x (PangoLayoutLine *line, int index_, gboolean trailing, OUTLIST int x_pos);

##  void pango_layout_line_get_x_ranges (PangoLayoutLine *line, int start_index, int end_index, int **ranges, int *n_ranges)
void
pango_layout_line_get_x_ranges (line, start_index, end_index)
	PangoLayoutLine *line
	int start_index
	int end_index
    PREINIT:
	int *ranges;
	int n_ranges, i;
    PPCODE:
	pango_layout_line_get_x_ranges (line, start_index, end_index, &ranges, &n_ranges);
	EXTEND (SP, n_ranges);
	for (i = 0; i < 2*n_ranges; i += 2) {
		AV *av = newAV ();
		av_push (av, newSViv (ranges[i]));
		av_push (av, newSViv (ranges[i + 1]));
		PUSHs (sv_2mortal (newRV_noinc ((SV *) av)));
	}
	g_free (ranges);


####  void pango_layout_line_get_extents (PangoLayoutLine *line, PangoRectangle *ink_rect, PangoRectangle *logical_rect)
####  void pango_layout_line_get_pixel_extents (PangoLayoutLine *layout_line, PangoRectangle *ink_rect, PangoRectangle *logical_rect)
=for apidoc
=for signature (ink_rect, logical_rect) = $line->get_extents
=for signature (ink_rect, logical_rect) = $line->get_pixel_extents
=cut
void
pango_layout_line_get_extents (line)
	PangoLayoutLine *line
    ALIAS:
	Pango::LayoutLine::get_pixel_extents = 1
    PREINIT:
	PangoRectangle ink_rect;
	PangoRectangle logical_rect;
    PPCODE:
	switch (ix) {
		case 0:
			pango_layout_line_get_extents (line, &ink_rect, &logical_rect);
			break;
		case 1:
			pango_layout_line_get_pixel_extents (line, &ink_rect, &logical_rect);
			break;
		default:
			g_assert_not_reached ();
	}
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVPangoRectangle (&ink_rect)));
	PUSHs (sv_2mortal (newSVPangoRectangle (&logical_rect)));

# --------------------------------------------------------------------------- #

MODULE = Pango::Layout	PACKAGE = Pango::LayoutIter	PREFIX = pango_layout_iter_

##  void pango_layout_iter_free (PangoLayoutIter *iter) 

##  int pango_layout_iter_get_index (PangoLayoutIter *iter) 
int
pango_layout_iter_get_index (iter)
	PangoLayoutIter *iter

# FIXME: no typemap for PangoLayoutRun / PangoGlyphItem.
# ##  PangoLayoutRun *pango_layout_iter_get_run (PangoLayoutIter *iter) 
# PangoLayoutRun *
# pango_layout_iter_get_run (iter)
# 	PangoLayoutIter *iter

##  PangoLayoutLine *pango_layout_iter_get_line (PangoLayoutIter *iter) 
PangoLayoutLine *
pango_layout_iter_get_line (iter)
	PangoLayoutIter *iter

#if PANGO_CHECK_VERSION (1, 16, 0)

# FIXME: no typemap for PangoLayoutRun / PangoGlyphItem.
# ##  PangoLayoutRun *pango_layout_iter_get_run_readonly (PangoLayoutIter *iter) 
# PangoLayoutRun *
# pango_layout_iter_get_run_readonly (iter)
# 	PangoLayoutIter *iter

##  PangoLayoutLine *pango_layout_iter_get_line_readonly (PangoLayoutIter *iter) 
PangoLayoutLine *
pango_layout_iter_get_line_readonly (iter)
	PangoLayoutIter *iter

#endif

##  gboolean pango_layout_iter_at_last_line (PangoLayoutIter *iter) 
gboolean
pango_layout_iter_at_last_line (iter)
	PangoLayoutIter *iter

##  gboolean pango_layout_iter_next_char (PangoLayoutIter *iter) 
gboolean
pango_layout_iter_next_char (iter)
	PangoLayoutIter *iter

##  gboolean pango_layout_iter_next_cluster (PangoLayoutIter *iter) 
gboolean
pango_layout_iter_next_cluster (iter)
	PangoLayoutIter *iter

##  gboolean pango_layout_iter_next_run (PangoLayoutIter *iter) 
gboolean
pango_layout_iter_next_run (iter)
	PangoLayoutIter *iter

##  gboolean pango_layout_iter_next_line (PangoLayoutIter *iter) 
gboolean
pango_layout_iter_next_line (iter)
	PangoLayoutIter *iter

##  void pango_layout_iter_get_char_extents (PangoLayoutIter *iter, PangoRectangle *logical_rect) 
PangoRectangle *
pango_layout_iter_get_char_extents (iter)
	PangoLayoutIter *iter
    PREINIT:
	PangoRectangle logical_rect;
    CODE:
	pango_layout_iter_get_char_extents (iter, &logical_rect);
	RETVAL = &logical_rect;
    OUTPUT:
	RETVAL

##  void pango_layout_iter_get_cluster_extents (PangoLayoutIter *iter, PangoRectangle *ink_rect, PangoRectangle *logical_rect) 
void
pango_layout_iter_get_cluster_extents (iter)
	PangoLayoutIter *iter
    ALIAS:
	Pango::LayoutIter::get_run_extents = 1
	Pango::LayoutIter::get_line_extents = 2
	Pango::LayoutIter::get_layout_extents = 3
    PREINIT:
	PangoRectangle ink_rect;
	PangoRectangle logical_rect;
    PPCODE:
	switch (ix) {
		case 0:
			pango_layout_iter_get_cluster_extents (iter, &ink_rect, &logical_rect);
			break;
		case 1:
			pango_layout_iter_get_run_extents (iter, &ink_rect, &logical_rect);
			break;
		case 2:
			pango_layout_iter_get_line_extents (iter, &ink_rect, &logical_rect);
			break;
		case 3:
			pango_layout_iter_get_layout_extents (iter, &ink_rect, &logical_rect);
			break;
		default:
			g_assert_not_reached ();
	}
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVPangoRectangle (&ink_rect)));
	PUSHs (sv_2mortal (newSVPangoRectangle (&logical_rect)));

##  void pango_layout_iter_get_line_yrange (PangoLayoutIter *iter, int *y0_, int *y1_) 
void pango_layout_iter_get_line_yrange (PangoLayoutIter *iter, OUTLIST int y0_, OUTLIST int y1_)

##  int pango_layout_iter_get_baseline (PangoLayoutIter *iter) 
int
pango_layout_iter_get_baseline (iter)
	PangoLayoutIter *iter

#if PANGO_CHECK_VERSION (1, 20, 0)

PangoLayout * pango_layout_iter_get_layout (PangoLayoutIter *iter);

#endif
