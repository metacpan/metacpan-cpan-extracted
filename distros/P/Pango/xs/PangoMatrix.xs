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

MODULE = Pango::Matrix	PACKAGE = Pango::Matrix	PREFIX = pango_matrix_

double
xx (matrix, new = 0)
	PangoMatrix *matrix
	double new
    ALIAS:
	Pango::Matrix::xy = 1
	Pango::Matrix::yx = 2
	Pango::Matrix::yy = 3
	Pango::Matrix::x0 = 4
	Pango::Matrix::y0 = 5
    CODE:
	RETVAL = 0.0;

	switch (ix) {
		case 0: RETVAL = matrix->xx; break;
		case 1: RETVAL = matrix->xy; break;
		case 2: RETVAL = matrix->yx; break;
		case 3: RETVAL = matrix->yy; break;
		case 4: RETVAL = matrix->x0; break;
		case 5: RETVAL = matrix->y0; break;
		default: g_assert_not_reached ();
	}

	if (items == 2) {
		switch (ix) {
			case 0: matrix->xx = new; break;
			case 1: matrix->xy = new; break;
			case 2: matrix->yx = new; break;
			case 3: matrix->yy = new; break;
			case 4: matrix->x0 = new; break;
			case 5: matrix->y0 = new; break;
			default: g_assert_not_reached ();
		}
	}
    OUTPUT:
	RETVAL

PangoMatrix_own *
pango_matrix_new (class, xx = 1., xy = 0., yx = 0., yy = 1., x0 = 0., y0 = 0.)
	double xx
	double xy
	double yx
	double yy
	double x0
	double y0
    CODE:
#if PANGO_CHECK_VERSION (1, 12, 0)
	RETVAL = g_slice_new0 (PangoMatrix);
#else
	RETVAL = g_new0 (PangoMatrix, 1);
#endif
	RETVAL->xx = xx;
	RETVAL->xy = xy;
	RETVAL->yx = yx;
	RETVAL->yy = yy;
	RETVAL->x0 = x0;
	RETVAL->y0 = y0;
    OUTPUT:
	RETVAL

##  void pango_matrix_translate (PangoMatrix *matrix, double tx, double ty)
void
pango_matrix_translate (matrix, tx, ty)
	PangoMatrix *matrix
	double tx
	double ty

##  void pango_matrix_scale (PangoMatrix *matrix, double scale_x, double scale_y)
void
pango_matrix_scale (matrix, scale_x, scale_y)
	PangoMatrix *matrix
	double scale_x
	double scale_y

##  void pango_matrix_rotate (PangoMatrix *matrix, double degrees)
void
pango_matrix_rotate (matrix, degrees)
	PangoMatrix *matrix
	double degrees

##  void pango_matrix_concat (PangoMatrix *matrix, PangoMatrix *new_matrix)
void
pango_matrix_concat (matrix, new_matrix)
	PangoMatrix *matrix
	PangoMatrix *new_matrix

#if PANGO_CHECK_VERSION (1, 16, 0)

void pango_matrix_transform_distance (const PangoMatrix *matrix, IN_OUTLIST double dx, IN_OUTLIST double dy);

void pango_matrix_transform_point (const PangoMatrix *matrix, IN_OUTLIST double x, IN_OUTLIST double y);

# void pango_matrix_transform_rectangle (const PangoMatrix *matrix, PangoRectangle *rect)
PangoRectangle *
pango_matrix_transform_rectangle (const PangoMatrix *matrix, PangoRectangle *rect)
    ALIAS:
	transform_pixel_rectangle = 1
    CODE:
	switch (ix) {
		case 0: pango_matrix_transform_rectangle (matrix, rect); break;
		case 1: pango_matrix_transform_pixel_rectangle (matrix, rect); break;
		default: g_assert_not_reached ();
	}
	RETVAL = rect;
    OUTPUT:
	RETVAL

#endif
