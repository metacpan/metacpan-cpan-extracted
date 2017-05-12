/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_init.c 412 2007-06-21 06:57:30Z foxamemnon $
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
#include <time.h>
#include <sys/types.h>
#include <netinet/in.h>
#include "ztxt.h"



/*
 * Create and initialize a ztxt structure.  Sets the database title to the
 * one specified, other values set to defaults.
 */
ztxt *
ztxt_init(void)
{
  ztxt  *ztxtdb;
  DatabaseHdrType *header;

  /* First allocate memory for the ztxt structure */
  ztxtdb = (ztxt *)calloc(1, sizeof(ztxt));
  if (!ztxtdb)
    return NULL;

  /* Allocate a chunk of memory to hold the DB header */
  ztxtdb->dbHeader = (DatabaseHdrType *)calloc(1, MAX_HEADER_SIZE);
  if (!ztxtdb->dbHeader)
    {
      free(ztxtdb);
      return NULL;
    }

  /* Initialize the Palm DB header structure */
  header = ztxtdb->dbHeader;
  strcpy((char *)header->name, "New zTXT database");
  header->attributes = htons(dmHdrAttrBackup);
  header->version = htons(ZTXT_VERSION);
  header->creationDate = htonl(time(NULL) + PALM_CTIME_OFFSET);
  header->modificationDate = htonl(time(NULL) + PALM_CTIME_OFFSET);
  header->lastBackupDate = 0;
  header->modificationNumber = 0;
  header->appInfoID = 0;
  header->sortInfoID = 0;
  header->type = htonl(palmid_to_int(ZTXT_TYPE_ID_STR));
  header->creator = htonl(palmid_to_int(GPLM_CREATOR_ID_STR));
  header->uniqueIDSeed = 0;
  header->recordList.nextRecordListID = 0;

  /* Set default window bits */
  ztxtdb->wbits = MAXWBITS;

  /* Set default compression method */
  ztxtdb->compression_type = 1;

  return ztxtdb;
}
