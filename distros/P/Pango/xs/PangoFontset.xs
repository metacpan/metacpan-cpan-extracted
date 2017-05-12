/*
 * Copyright (c) 2003, 2014 by the gtk2-perl team (see the AUTHORS
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

#if PANGO_CHECK_VERSION (1, 4, 0)

static GPerlCallback *
gtk2perl_pango_fontset_foreach_func_create (SV *func, SV *data)
{
	GType param_types[2];
	param_types[0] = PANGO_TYPE_FONTSET;
	param_types[1] = PANGO_TYPE_FONT;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
	                           param_types, G_TYPE_BOOLEAN);
}

static gboolean
gtk2perl_pango_fontset_foreach_func (PangoFontset *fontset, PangoFont *font, GPerlCallback *callback)
{
	GValue value = {0,};
	gboolean retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, fontset, font);
	retval = g_value_get_boolean (&value);
	g_value_unset (&value);

	return retval;
}

#endif /* 1.4.0 */

MODULE = Pango::Fontset	PACKAGE = Pango::Fontset	PREFIX = pango_fontset_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (PANGO_TYPE_FONTSET, TRUE);

##  PangoFont * pango_fontset_get_font (PangoFontset *fontset, guint wc) 
PangoFont *
pango_fontset_get_font (fontset, wc)
	PangoFontset *fontset
	guint wc

##  PangoFontMetrics *pango_fontset_get_metrics (PangoFontset *fontset) 
PangoFontMetrics *
pango_fontset_get_metrics (fontset)
	PangoFontset *fontset

#if PANGO_CHECK_VERSION (1, 4, 0)

##  void pango_fontset_foreach (PangoFontset *fontset, PangoFontsetForeachFunc func, gpointer data) 
void
pango_fontset_foreach (fontset, func, data=NULL)
	PangoFontset *fontset
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_pango_fontset_foreach_func_create (func, data);
	pango_fontset_foreach (fontset,
	                       (PangoFontsetForeachFunc)
	                         gtk2perl_pango_fontset_foreach_func,
	                       callback);
	gperl_callback_destroy (callback);

#endif /* 1.4.0 */
