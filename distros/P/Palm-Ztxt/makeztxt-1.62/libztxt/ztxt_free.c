/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_free.c 412 2007-06-21 06:57:30Z foxamemnon $
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
#include "ztxt.h"



/*
 * Frees all memory associated with a ztxt struct including
 * the struct itself.  Does not free 'input' pointer, however, so this should
 * should be done by the user *before* calling this function (in case you have
 * to use the ztxt structure to fetch the pointer with ztxt_get_input).  Of
 * course, 'input' only needs to be freed if it is non-NULL.
 */
void
ztxt_free(ztxt *db)
{
  regex_node    *regex = db->regex_list;
  regex_node    *regex_tmp;
  bmrk_node     *bmrk = db->bookmarks;
  bmrk_node     *bmrk_tmp;
  anno_node     *anno = db->annotations;
  anno_node     *anno_tmp;

  if (!db)
    return;

  /* Free regex linked list */
  while (regex != NULL)
    {
      regex_tmp = regex;
      regex = regex->next;
      free(regex_tmp->pattern);
      free(regex_tmp);
    }

  /* Free bookmark linked list */
  while (bmrk != NULL)
    {
      bmrk_tmp = bmrk;
      bmrk = bmrk->next;
      free(bmrk_tmp);
    }

  /* Free annotation linked list */
  while (anno != NULL)
    {
      anno_tmp = anno;
      anno = anno->next;
      free(anno_tmp->anno_text);
      free(anno_tmp);
    }

  /* Free up buffers */
  if (db->tmp)
    free(db->tmp);
  if (db->compressed_data)
    free(db->compressed_data);
  if (db->record_offsets)
    free(db->record_offsets);
  if (db->output)
    free(db->output);

  /* Free DB header */
  if (db->dbHeader)
    free(db->dbHeader);

  free(db);
}

