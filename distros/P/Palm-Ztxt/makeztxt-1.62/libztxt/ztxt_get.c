/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_get.c 412 2007-06-21 06:57:30Z foxamemnon $
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


#include "ztxt.h"


/*
 * Fetch the output pointer from the ztxt structure.
 */
char *
ztxt_get_output(ztxt *db)
{
  return db->output;
}


/*
 * Fetch the output data size from the ztxt structure.
 */
long
ztxt_get_outputsize(ztxt *db)
{
  return db->output_size;
}


/*
 * Fetch the input pointer from the ztxt structure.
 */
char *
ztxt_get_input(ztxt *db)
{
  return db->input;
}


/*
 * Fetch the input data size from the ztxt structure.
 */
long
ztxt_get_inputsize(ztxt *db)
{
  return db->input_size;
}


/*
 * Fetch the number of bookmarks in the linked list from the ztxt structure.
 */
short
ztxt_get_num_bookmarks(ztxt *db)
{
  return db->num_bookmarks;
}


/*
 * Fetch pointer to the bookmark linked list from the ztxt structure.
 */
bmrk_node *
ztxt_get_bookmarks(ztxt *db)
{
  return db->bookmarks;
}


/*
 * Fetch the number of annotations in the linked list from the ztxt structure.
 */
short
ztxt_get_num_annotations(ztxt *db)
{
  return db->num_annotations;
}


/*
 * Fetch pointer to the annotation linked list from the ztxt structure.
 */
anno_node *
ztxt_get_annotations(ztxt *db)
{
  return db->annotations;
}
