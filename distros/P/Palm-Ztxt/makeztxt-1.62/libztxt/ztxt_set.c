/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_set.c 412 2007-06-21 06:57:30Z foxamemnon $
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

#include <string.h>
#include <sys/types.h>
#include <netinet/in.h>
#include "ztxt.h"



/*
 * Set the database title
 */
void
ztxt_set_title(ztxt *db, char *new_title)
{
  strncpy((char *)db->dbHeader->name, new_title, dmDBNameLength);
  db->dbHeader->name[dmDBNameLength - 1] = '\0';
}


/*
 * Set the data pointer and data size
 */
void
ztxt_set_data(ztxt *db, char *new_data, long datasize)
{
  db->input = new_data;
  db->input_size = datasize;
}


/*
 * Set the output data pointer and output data size.
 * This is used when populating the ztxt structure with an already created
 * zTXT DB (as when deconstructing one).
 */
void
ztxt_set_output(ztxt *db, char *data, long datasize)
{
  db->output = data;
  db->output_size = datasize;
}


/*
 * Set the DB creator to something other than the default.
 * The default, as set in ztxt_init() is 'GPlm'
 */
void
ztxt_set_creator(ztxt *db, long new_creator)
{
  db->dbHeader->creator = htonl(new_creator);
}


/*
 * Set the DB type to something other than the default.
 * The default, as set in ztxt_init() is 'zTXT'
 */
void
ztxt_set_type(ztxt *db, long new_type)
{
  db->dbHeader->type = htonl(new_type);
}


/*
 * Set the zlib window bits value.  This can affect the amount of memory
 * used by zlib.  Valid range is 10-15, with 15 as the default.
 * The default should be fine.
 */
void
ztxt_set_wbits(ztxt *db, int new_wbits)
{
  db->wbits = new_wbits;
}


/*
 * Set the method of compression.  Type 1 (default), uses Z_FULL_FLUSH when
 * compressing, thus allowing random access of the compressed data (on
 * recordSize boundaries).  Type 2 give approx. 10% more compression, but must
 * be decompressed all at once, using more storage space.
 */
void
ztxt_set_compressiontype(ztxt *db, int new_comptype)
{
  db->compression_type = new_comptype;
}


/*
 * Sets new header attributes in the generated database.
 */
void
ztxt_set_attribs(ztxt *db, short new_attribs)
{
  DatabaseHdrType *header;

  header = db->dbHeader;
  header->attributes = htons(new_attribs);
}
