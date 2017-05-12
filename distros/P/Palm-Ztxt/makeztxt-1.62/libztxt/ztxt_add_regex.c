/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_add_regex.c 412 2007-06-21 06:57:30Z foxamemnon $
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



/* Add a regular expression to the regex list */
void
ztxt_add_regex(ztxt *db, char *new_pattern)
{
  regex_node    *current = db->regex_list;

  if (new_pattern && new_pattern[0])
    {
      if (current == NULL)
        {
          db->regex_list = current = (regex_node *)malloc(sizeof(regex_node));
          current->pattern = strdup(new_pattern);
          current->bad = 0;
          current->next = NULL;
        }
      else
        {
          while (current->next !=  NULL)
            current = current->next;
          current->next = (regex_node *)malloc(sizeof(regex_node));
          current = current->next;
          current->pattern = strdup(new_pattern);
          current->bad = 0;
          current->next = NULL;
        }

      db->num_regex++;
    }
}
