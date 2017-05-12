/* declarations for time_r.c

   Copyright (C) 2003, 2006-2007, 2010-2012 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with this program; if not, see <http://www.gnu.org/licenses/>.  */

#include "gnu_config.h"
#include <time.h>

#ifndef HAVE_GMTIME_R
struct tm * gmtime_r (time_t const * restrict t, struct tm * restrict tp);
#endif
#ifndef HAVE_LOCALTIME_R
struct tm * localtime_r (time_t const * restrict t, struct tm * restrict tp);
#endif
