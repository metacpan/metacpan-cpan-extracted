/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_add_bookmark.c 412 2007-06-21 06:57:30Z foxamemnon $
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
#include <stdio.h>
#include <string.h>
#include "ztxt.h"



/*
 * Add a bookmark to the linked list
 */
void
ztxt_add_bookmark(ztxt *db, char *title, long offset)
{
  bmrk_node     *current = db->bookmarks;
  bmrk_node     *prev = NULL;

  if (current == NULL)
    {
      db->bookmarks = current = (bmrk_node *)malloc(sizeof(bmrk_node));
      current->next = NULL;
    }
  else
    {
      while((current != NULL) && (current->offset < offset))
        {
          prev = current;
          current = current->next;
        }

      if (current == NULL)
        {
          /* Adding to the end of the list */
          prev->next = current = (bmrk_node *)malloc(sizeof(bmrk_node));
          current->next = NULL;
        }
      else if (prev == NULL)
        {
          /* Adding at the beginning of the list */
          current = (bmrk_node *)malloc(sizeof(bmrk_node));
          current->next = db->bookmarks;
          db->bookmarks = current;
        }
      else
        {
          /* Adding in the middle of the list */
          prev->next = (bmrk_node *)malloc(sizeof(bmrk_node));
          prev = prev->next;
          prev->next = current;
          current = prev;
        }
    }

  ztxt_strip_spaces(title);
  strncpy(current->title, title, MAX_BMRK_LENGTH);
  if (current->title[0] == '\0')
    sprintf(current->title, "Position %ld", offset);

  current->offset = offset;
  db->num_bookmarks++;
}
