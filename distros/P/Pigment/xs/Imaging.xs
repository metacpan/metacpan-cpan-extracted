#include "perl-pigment.h"

MODULE = Pigment::Imaging  PACKAGE = Pigment::Imaging  PREFIX = pgm_imaging_

GdkPixbuf *
pgm_imaging_linear_alpha_gradient (const GdkPixbuf *pixbuf, gfloat start_x, gfloat start_y, gfloat start_alpha, gfloat end_x, gfloat end_y, gfloat end_alpha)
