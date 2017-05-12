/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_generate_db.c 412 2007-06-21 06:57:30Z foxamemnon $
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
#include <sys/types.h>
#include <netinet/in.h>
#include <regex.h>
#include "ztxt.h"
#include "build.h"


/* Local functions */
static long     output_bookmarks(ztxt *db, long offset);
static long     output_annotations(ztxt *db, long offset);



/*
 * Compose an entire ztxt database from the headers, bookmarks, annotations,
 * and compressed data.  Store the new database in db->output.
 * This also frees db->compressed_data.
 */
void
ztxt_generate_db(ztxt *db)
{
  long          data_offset;
  int           num_data_records;
  int           curr_record;
  int           x;
  char          *y;
  long          offset;
  RecordEntryType *dbRecordEntries;
  int           sub;
  long          recdata_offset;
  long          anno_totalsize;
  anno_node     *anno;
  int           crc;


  /* Calculate the offset in the DB where the data will go */
  data_offset = sizeof(DatabaseHdrType) - sizeof(UInt16);

  /* One extra for record #0 */
  db->num_records++;
  /* Add a record for the bookmarks if there are any */
  if (db->num_bookmarks > 0)
    db->num_records++;
  /* Add records for the annotations if there are any */
  if (db->num_annotations > 0)
    db->num_records += db->num_annotations + 1;
  data_offset += db->num_records * sizeof(RecordEntryType);
  /* UInt32 align the actual data */
  if (data_offset % 4)
    data_offset += data_offset % 4;
  db->dbHeader->recordList.numRecords = htons(db->num_records);

  /* Initialize entries for record 0 */
  memset(&(db->record0), 0, sizeof(zTXT_record0));
  db->record0.version = htons(ZTXT_VERSION);
  /* numRecords should only count the number of compressed text records */
  sub = 1;
  if (db->num_bookmarks > 0)
    sub++;
  if (db->num_annotations > 0)
    sub += db->num_annotations + 1;
  db->record0.numRecords = htons(db->num_records - sub);

  db->record0.size = htonl(db->tmpsize);
  db->record0.recordSize = htons(RECORD_SIZE);

  /* Add a CRC32 into record 0.  This CRC includes all text records. */
  crc = ztxt_crc32(0, NULL, 0);
  crc = ztxt_crc32(crc, db->compressed_data, db->comp_size);
  db->record0.crc32 = htonl(crc);

  db->record0.numBookmarks = htons(db->num_bookmarks);
  db->record0.numAnnotations = htons(db->num_annotations);

  if (db->num_bookmarks > 0)
    {
      if (db->num_annotations > 0)
        db->record0.bookmarkRecord =
          htons(db->num_records - 2 - db->num_annotations);
      else
        db->record0.bookmarkRecord = htons(db->num_records - 1);
    }
  else
    db->record0.bookmarkRecord = 0;

  if (db->num_annotations > 0)
    db->record0.annotationRecord =
      htons(db->num_records - 1 - db->num_annotations);
  else
    db->record0.annotationRecord = 0;

  /* Only compression type 1 allows for random access seeking */
  if (db->compression_type == 1)
    db->record0.flags |= ZTXT_RANDOMACCESS;


  dbRecordEntries = (RecordEntryType *)&(db->dbHeader->recordList.firstEntry);

  /* Stick record 0 into the record list */
  dbRecordEntries->localChunkID = htonl(data_offset);
  dbRecordEntries->attributes = dmRecAttrDirty;
  x = htonl(0x00424200);
  y = (char *)&x;
  dbRecordEntries->uniqueID[0] = y[1];
  dbRecordEntries->uniqueID[1] = y[2];
  dbRecordEntries->uniqueID[2] = y[3];
  dbRecordEntries += 1;

  /* Fill out the database record entries */
  num_data_records = db->num_records;
  if (db->num_bookmarks > 0)
    num_data_records--;
  if (db->num_annotations > 0)
    num_data_records -= 1 + db->num_annotations;
  curr_record = 1;
  do
    {
      dbRecordEntries->localChunkID =
        htonl(data_offset + sizeof(zTXT_record0)
              + db->record_offsets[curr_record - 1]);
      dbRecordEntries->attributes = dmRecAttrDirty;
      x = htonl(0x00424200 + curr_record);
      y = (char *)&x;
      dbRecordEntries->uniqueID[0] = y[1];
      dbRecordEntries->uniqueID[1] = y[2];
      dbRecordEntries->uniqueID[2] = y[3];
      dbRecordEntries++;
      curr_record++;
    }
  while (curr_record < num_data_records);

  /* Add bookmark record.  This is done separately because the last record of
   * compressed text is probably not exactly recordSize bytes in length */
  if (db->num_bookmarks > 0)
    {
      dbRecordEntries->localChunkID =
        htonl(data_offset + sizeof(zTXT_record0) + db->comp_size);
      dbRecordEntries->attributes = dmRecAttrDirty;
      x = htonl(0x00424200 + curr_record);
      y = (char *)&x;
      dbRecordEntries->uniqueID[0] = y[1];
      dbRecordEntries->uniqueID[1] = y[2];
      dbRecordEntries->uniqueID[2] = y[3];
      dbRecordEntries++;
      curr_record++;
    }

  /* Add annotation records */
  anno_totalsize = 0;
  if (db->num_annotations > 0)
    {
      /* Add annotation index */
      recdata_offset =
        (data_offset + sizeof(zTXT_record0) + db->comp_size
         + ((sizeof(UInt32) + MAX_BMRK_LENGTH) * db->num_bookmarks));
      dbRecordEntries->localChunkID = htonl(recdata_offset);
      dbRecordEntries->attributes = dmRecAttrDirty;
      x = htonl(0x00424200 + curr_record);
      y = (char *)&x;
      dbRecordEntries->uniqueID[0] = y[1];
      dbRecordEntries->uniqueID[1] = y[2];
      dbRecordEntries->uniqueID[2] = y[3];
      dbRecordEntries++;
      curr_record++;

      anno = db->annotations;
      recdata_offset =
        (data_offset + sizeof(zTXT_record0) + db->comp_size
         + ((sizeof(UInt32) + MAX_BMRK_LENGTH) * db->num_bookmarks)
         + ((sizeof(UInt32) + MAX_BMRK_LENGTH) * db->num_annotations));
      while (anno)
        {
          /* Add record entry for each annotation */
          dbRecordEntries->localChunkID = htonl(recdata_offset
                                                + anno_totalsize);
          dbRecordEntries->attributes = dmRecAttrDirty;
          x = htonl(0x00424200 + curr_record);
          y = (char *)&x;
          dbRecordEntries->uniqueID[0] = y[1];
          dbRecordEntries->uniqueID[1] = y[2];
          dbRecordEntries->uniqueID[2] = y[3];
          dbRecordEntries++;
          curr_record++;

          anno_totalsize += strlen(anno->anno_text) + 1;
          anno = anno->next;
        }
    }


  /*
   * The database header is now complete, so we assemble the pieces
   * in the output buffer.
   */
  db->output = (char *)malloc(data_offset + db->comp_size
                              + ((sizeof(UInt32) + MAX_BMRK_LENGTH)
                                 * db->num_bookmarks)
                              + anno_totalsize + 1024);
  offset = 0;
  memcpy(db->output, db->dbHeader, data_offset);
  offset += data_offset;
  memcpy(db->output + offset, &(db->record0), sizeof(zTXT_record0));
  offset += sizeof(zTXT_record0);
  memcpy(db->output + offset, db->compressed_data, db->comp_size);
  offset += db->comp_size;
  if (db->num_bookmarks > 0)
    offset += output_bookmarks(db, offset);
  if (db->num_annotations > 0)
    offset += output_annotations(db, offset);

  db->output_size = offset;
}


/*
 * Output the bookmarks to the output data area
 */
static long
output_bookmarks(ztxt *db, long offset)
{
  char          *buf = db->output + offset;
  bmrk_node     *cur = db->bookmarks;
  long          bytes = 0;

  while (cur)
    {
      *((UInt32 *)buf) = htonl(cur->offset);
      strncpy(&buf[sizeof(UInt32)], cur->title, MAX_BMRK_LENGTH);
      bytes += MAX_BMRK_LENGTH + sizeof(UInt32);
      buf += MAX_BMRK_LENGTH + sizeof(UInt32);
      cur = cur->next;
    }

  return bytes;
}


/*
 * Output the annotation index and annotation text records to the
 * output data area.
 */
static long
output_annotations(ztxt *db, long offset)
{
  char          *buf = db->output + offset;
  anno_node     *cur;
  long          bytes = 0;
  int           len;

  /* First output the index */
  cur = db->annotations;
  while (cur)
    {
      *((UInt32 *)buf) = htonl(cur->offset);
      strncpy(&buf[sizeof(UInt32)], cur->title, MAX_BMRK_LENGTH);
      bytes += MAX_BMRK_LENGTH + sizeof(UInt32);
      buf += MAX_BMRK_LENGTH + sizeof(UInt32);
      cur = cur->next;
    }

  /* Next output the annotation text records */
  cur = db->annotations;
  while (cur)
    {
      len = strlen(cur->anno_text) + 1;
      memcpy(buf, cur->anno_text, len);
      bytes += len;
      buf += len;
      cur = cur->next;
    }

  return bytes;
}
