/*
 * Copyright (C) 2003-2008, 2014 by the gtk2-perl team (see the file AUTHORS
 * for the full list)
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at your
 * option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top-level directory of this distribution for
 * the full license terms.
 *
 */

#ifndef _PANGO_PERL_H_
#define _PANGO_PERL_H_

#include <gperl.h>
#include <pango/pango.h>

#include "pango-perl-versions.h"

#if PANGO_CHECK_VERSION (1, 10, 0)
# include <pango/pangocairo.h>
#endif

/* custom GType for PangoAttribute */
#ifndef PANGO_TYPE_ATTRIBUTE
# define PANGO_TYPE_ATTRIBUTE (gtk2perl_pango_attribute_get_type ())
  GType gtk2perl_pango_attribute_get_type (void) G_GNUC_CONST;
#endif

/* custom GType for PangoAttrIter */
#ifndef PANGO_TYPE_ATTR_ITERATOR
# define PANGO_TYPE_ATTR_ITERATOR (gtk2perl_pango_attr_iterator_get_type ())
  GType gtk2perl_pango_attr_iterator_get_type (void) G_GNUC_CONST;
#endif

/* custom GType for PangoLayoutIter */
#ifndef PANGO_TYPE_LAYOUT_ITER
# define PANGO_TYPE_LAYOUT_ITER (gtk2perl_pango_layout_iter_get_type ())
  GType gtk2perl_pango_layout_iter_get_type (void) G_GNUC_CONST;
#endif

/* custom GType for PangoLayoutLine */
#ifndef PANGO_TYPE_LAYOUT_LINE
# define PANGO_TYPE_LAYOUT_LINE (gtk2perl_pango_layout_line_get_type ())
  GType gtk2perl_pango_layout_line_get_type (void) G_GNUC_CONST;
#endif

/* custom GType for PangoScriptIter */
#if PANGO_CHECK_VERSION (1, 4, 0)
# ifndef PANGO_TYPE_SCRIPT_ITER
#  define PANGO_TYPE_SCRIPT_ITER (gtk2perl_pango_script_iter_get_type ())
   GType gtk2perl_pango_script_iter_get_type (void) G_GNUC_CONST;
# endif
#endif

#include "pango-perl-autogen.h"

/* exported for various other parts of pango */
SV * newSVPangoRectangle (PangoRectangle * rectangle);
PangoRectangle * SvPangoRectangle (SV * sv);

/* for registering custom attribute types */
void gtk2perl_pango_attribute_register_custom_type (PangoAttrType type, const char *package);

#endif /* _PANGO_PERL_H_ */
