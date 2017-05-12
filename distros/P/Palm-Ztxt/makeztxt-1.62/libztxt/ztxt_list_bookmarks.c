/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_list_bookmarks.c 412 2007-06-21 06:57:30Z foxamemnon $
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

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <regex.h>

#include "ztxt.h"


void
ztxt_list_bookmarks(ztxt *db)
{
  char          tmpstr[MAX_BMRK_LENGTH + 1];
  bmrk_node     *current;

  printf("Generated bookmarks\nOffset\t\tTitle\n"
         "-----------\t--------------------\n");
  current = db->bookmarks;
  while (current != NULL)
    {
      strncpy(tmpstr, current->title, MAX_BMRK_LENGTH);
      tmpstr[MAX_BMRK_LENGTH] = '\0';
      printf("%ld\t\t%s\n",current->offset, tmpstr);
      current = current->next;
    }
}
