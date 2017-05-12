/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_crc32.c 412 2007-06-21 06:57:30Z foxamemnon $
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


#include <zlib.h>
#include "ztxt.h"


/*
 * Calculates a 32 bit CRC over the input data at buf (of length len).
 * The value in crc will be used as the seed.  This function is just a wrapper
 * for the crc32 function in zlib.
 *
 * The crc should be initialized first by calling this function with
 * buf == NULL, len == 0, and crc == 0.
 */
int
ztxt_crc32(int crc, const void *buf, int len)
{
  return crc32(crc, buf, len);
}
