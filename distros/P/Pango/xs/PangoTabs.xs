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

MODULE = Pango::TabArray	PACKAGE = Pango::TabArray	PREFIX = pango_tab_array_

##  PangoTabArray *pango_tab_array_new (gint initial_size, gboolean positions_in_pixels) 
###  PangoTabArray *pango_tab_array_new_with_positions (gint size, gboolean positions_in_pixels, PangoTabAlign first_alignment, gint first_position, ...) 

=for apidoc Pango::TabArray::new
=for arg ... pairs of Pango::TabAlign's and integers, the alignments and positions of the tab stops.
=cut

=for apidoc new_with_positions
=for arg ... pairs of Pango::TabAlign's and integers, the alignments and positions of the tab stops.
Alias for L<new|tabarray = Pango::TabArray-E<gt>new ($initial_size, $positions_in_pixels, ...)>.
=cut

PangoTabArray_own *
pango_tab_array_new (class, initial_size, positions_in_pixels, ...)
	gint initial_size
	gboolean positions_in_pixels
    ALIAS:
	new_with_positions = 1
    CODE:
	PERL_UNUSED_VAR (ix);
	RETVAL = pango_tab_array_new (initial_size, positions_in_pixels);
	if (items > 3) {
		int i;
		for (i = 3 ; i < items ; i += 2) {
			pango_tab_array_set_tab (RETVAL, (i - 3) / 2,
			                         SvPangoTabAlign (ST (i)),
						 SvIV (ST (i+1)));
		}
	}
    OUTPUT:
	RETVAL


 ## see Glib::Boxed
##  PangoTabArray *pango_tab_array_copy (PangoTabArray *src) 
##  void pango_tab_array_free (PangoTabArray *tab_array) 

##  gint pango_tab_array_get_size (PangoTabArray *tab_array) 
gint
pango_tab_array_get_size (tab_array)
	PangoTabArray *tab_array

##  void pango_tab_array_resize (PangoTabArray *tab_array, gint new_size) 
void
pango_tab_array_resize (tab_array, new_size)
	PangoTabArray *tab_array
	gint new_size

##  void pango_tab_array_set_tab (PangoTabArray *tab_array, gint tab_index, PangoTabAlign alignment, gint location) 
void
pango_tab_array_set_tab (tab_array, tab_index, alignment, location)
	PangoTabArray *tab_array
	gint tab_index
	PangoTabAlign alignment
	gint location

##  void pango_tab_array_get_tab (PangoTabArray *tab_array, gint tab_index, PangoTabAlign *alignment, gint *location) 
void
pango_tab_array_get_tab (PangoTabArray *tab_array, gint tab_index) 
    PREINIT:
	PangoTabAlign alignment;
	gint location;
    PPCODE:
	pango_tab_array_get_tab (tab_array, tab_index, &alignment, &location);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVPangoTabAlign (alignment)));
	PUSHs (sv_2mortal (newSViv (location)));

##  void pango_tab_array_get_tabs (PangoTabArray *tab_array, PangoTabAlign **alignments, gint **locations) 
=for apidoc
Returns a list of Pango::TabAlign's, alignments, and integers, locations. 
Even elemtents are alignments and odd elements are locations, so 0 is the first
alignment and 1 is the first location, 2 the second alignment, 3 the second 
location, etc.
=cut
void
pango_tab_array_get_tabs (tab_array)
	PangoTabArray *tab_array
    PREINIT:
	PangoTabAlign *alignments = NULL;
	gint *locations = NULL, i, n;
    PPCODE:
	pango_tab_array_get_tabs (tab_array, &alignments, &locations);
	n = pango_tab_array_get_size (tab_array);
	EXTEND (SP, 2 * n);
	for (i = 0 ; i < n ; i++) {
		PUSHs (sv_2mortal (newSVPangoTabAlign (alignments[i])));
		PUSHs (sv_2mortal (newSViv (locations[i])));
	}
	g_free (alignments);
	g_free (locations);

##  gboolean pango_tab_array_get_positions_in_pixels (PangoTabArray *tab_array) 
gboolean
pango_tab_array_get_positions_in_pixels (tab_array)
	PangoTabArray *tab_array

