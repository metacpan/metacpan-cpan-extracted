/*
 * Copyright (c) 2007, 2014 by the gtk2-perl team (see the AUTHORS
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

MODULE = Pango::Gravity	PACKAGE = Pango::Gravity	PREFIX = pango_gravity_

=for apidoc __function__
=cut
gboolean
is_vertical (PangoGravity gravity)
    CODE:
	RETVAL = PANGO_GRAVITY_IS_VERTICAL (gravity);
    OUTPUT:
	RETVAL

=for apidoc __function__
=cut
double pango_gravity_to_rotation (PangoGravity gravity);

=for apidoc __function__
=cut
PangoGravity pango_gravity_get_for_matrix (const PangoMatrix *matrix);

=for apidoc __function__
=cut
PangoGravity pango_gravity_get_for_script (PangoScript script, PangoGravity base_gravity, PangoGravityHint hint);
