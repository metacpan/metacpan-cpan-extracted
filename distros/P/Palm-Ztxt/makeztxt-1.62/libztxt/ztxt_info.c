/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_info.c 412 2007-06-21 06:57:30Z foxamemnon $
 *
 * Copyright (C) 2000-2007 John Gruenenfelder
 *   johng@as.arizona.edu
 *   http://gutenpalm.sourceforge.net
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 */

#include "build.h"



/*
 * Return the libztxt version as a string.  This is a constant so no free'ing
 * it when done, okay?
 */
const char *
ztxt_libversion(void)
{
  return LIBZTXT_VERSION;
}


/*
 * Return the libztxt build number as an integer
 */
int
ztxt_libbuild(void)
{
  return LIBZTXT_BUILDNUM;
}
