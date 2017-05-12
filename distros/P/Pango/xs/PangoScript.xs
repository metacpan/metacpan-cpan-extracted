/*
 * Copyright (c) 2004, 2014 by the gtk2-perl team (see the AUTHORS
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

#if PANGO_CHECK_VERSION (1, 4, 0)

static gpointer
gtk2perl_pango_script_iter_copy (gpointer boxed)
{
	croak ("Can't copy a PangoScriptIter");
	return boxed;
}

GType
gtk2perl_pango_script_iter_get_type (void)
{
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static ("PangoScriptIter",
		      (GBoxedCopyFunc) gtk2perl_pango_script_iter_copy,
		      (GBoxedFreeFunc) pango_script_iter_free);
	return t;
}

#endif

/* ------------------------------------------------------------------------- */

MODULE = Pango::Script	PACKAGE = Pango::Script	PREFIX = pango_script_

BOOT:
	PERL_UNUSED_VAR (file);

#if PANGO_CHECK_VERSION (1, 4, 0)

##  PangoScript pango_script_for_unichar (gunichar ch)
PangoScript
pango_script_for_unichar (class, ch)
	gunichar ch
    C_ARGS:
	ch

##  PangoLanguage * pango_script_get_sample_language (PangoScript script)
PangoLanguage_ornull *
pango_script_get_sample_language (class, script)
	PangoScript script
    C_ARGS:
	script

MODULE = Pango::Script	PACKAGE = Pango::ScriptIter	PREFIX = pango_script_iter_

##  Using gchar instead of char here all over the place to enforce utf8.

##  PangoScriptIter * pango_script_iter_new (const char *text, int length)
PangoScriptIter *
pango_script_iter_new (class, text)
	const gchar *text
    CODE:
	RETVAL = pango_script_iter_new (text, strlen (text));
    OUTPUT:
	RETVAL

=for apidoc

Returns the bounds and the script for the region pointed to by I<$iter>.

=cut
##  void pango_script_iter_get_range (PangoScriptIter *iter, G_CONST_RETURN char **start, G_CONST_RETURN char **end, PangoScript *script)
void
pango_script_iter_get_range (iter)
	PangoScriptIter *iter
    PREINIT:
	gchar *start = NULL;
	gchar *end = NULL;
	PangoScript script;
    PPCODE:
	pango_script_iter_get_range (iter,
	                             (const char **) &start,
	                             (const char **) &end,
	                             &script);
	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSVGChar (start)));
	PUSHs (sv_2mortal (newSVGChar (end)));
	PUSHs (sv_2mortal (newSVPangoScript (script)));

##  gboolean pango_script_iter_next (PangoScriptIter *iter)
gboolean
pango_script_iter_next (iter)
	PangoScriptIter *iter

##  void pango_script_iter_free (PangoScriptIter *iter)

MODULE = Pango::Script	PACKAGE = Pango::Language	PREFIX = pango_language_

##  gboolean pango_language_includes_script (PangoLanguage *language, PangoScript script)
gboolean
pango_language_includes_script (language, script)
	PangoLanguage *language
	PangoScript script

#endif /* 1.4.0 */
