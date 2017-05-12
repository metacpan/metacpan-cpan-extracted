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

MODULE = Pango::Types	PACKAGE = Pango	PREFIX = pango_

#if PANGO_CHECK_VERSION (1, 4, 0)

=for object Pango::Language
=cut

##  PangoDirection pango_find_base_dir (const gchar *text, gint length)
PangoDirection
pango_find_base_dir (class, text)
	const gchar *text
    C_ARGS:
	text, strlen (text)

#endif

#if PANGO_CHECK_VERSION (1, 16, 0)

=for object Pango::Font
=cut

=for apidoc __function__
=cut
int pango_units_from_double (double d);

=for apidoc __function__
=cut
double pango_units_to_double (int i);

=for apidoc __function__
=cut
##  void pango_extents_to_pixels (PangoRectangle *inclusive, PangoRectangle *nearest)
void
pango_extents_to_pixels (PangoRectangle *inclusive, PangoRectangle *nearest)
    PPCODE:
	pango_extents_to_pixels (inclusive, nearest);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVPangoRectangle (inclusive)));
	PUSHs (sv_2mortal (newSVPangoRectangle (nearest)));

#endif

MODULE = Pango::Types	PACKAGE = Pango::Language	PREFIX = pango_language_

##  PangoLanguage * pango_language_from_string (const char *language)
PangoLanguage *
pango_language_from_string (class, language)
	const char *language
    CODE:
	RETVAL = pango_language_from_string (language);
    OUTPUT:
	RETVAL

##  const char * pango_language_to_string (PangoLanguage *language)
const char *
pango_language_to_string (language)
	PangoLanguage *language

# FIXME: WTF is the Gnome2::Pango::Language::matches alias doing here?  It's
# totally bogus, but has been in a stable release already ...
##  gboolean pango_language_matches (PangoLanguage *language, const char *range_list)
gboolean
pango_language_matches (language, range_list)
	PangoLanguage *language
	const char *range_list
    ALIAS:
	Gnome2::Pango::Language::matches = 0
    CLEANUP:
	PERL_UNUSED_VAR (ix);

#if PANGO_CHECK_VERSION (1, 16, 0)

##  PangoLanguage * pango_language_get_default (void)
PangoLanguage *
pango_language_get_default (class)
    C_ARGS:
	/* void */

#endif
