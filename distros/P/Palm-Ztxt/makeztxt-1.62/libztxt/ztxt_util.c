/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_util.c 412 2007-06-21 06:57:30Z foxamemnon $
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


#include <stdlib.h>
#include <string.h>
#include "ztxt.h"



/*
 * Removes all whitespace from the beginning and end of a string.
 *
 * This function modifies str.
 */
char *
ztxt_strip_spaces(char *str)
{
  int   x;

  if (!str)
    return NULL;

  x = 0;
  while (ztxt_whitespace(str[x]) && (str[x] != '\0'))
    x++;

  if (x != 0)
    memmove(str, str+x, strlen(str)-x+1);

  x = strlen(str)-1;
  while (ztxt_whitespace(str[x]) && (x != 0))
    x--;

  str[x+1] = '\0';

  return str;
}


/*
 * True if char argument is whitespace
 */
int
ztxt_whitespace(char yoda)
{
  switch (yoda)
    {
      case ' ':
      case '\t':
      case '\n':
      case '\r':
        return 1;
      default:
        return 0;
    }
}


/*
 * Sanitizes bookmark titles by removing linefeeds and control characters and
 * replacing them with spaces.
 *
 * This function will modify str.
 */
char *
ztxt_sanitize_string(char *str)
{
  int   x;
  int   len;

  if (!str)
    return NULL;

  len = strlen(str);
  for (x = 0; x < len; x++)
    {
      if ((str[x] > 0) && (str[x] < 0x20))
        str[x] = ' ';
    }

  return str;
}
