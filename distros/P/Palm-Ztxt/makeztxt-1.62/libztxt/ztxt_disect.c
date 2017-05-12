/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_disect.c 412 2007-06-21 06:57:30Z foxamemnon $
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
#include <zlib.h>
#include "ztxt.h"



/*
 * These are the type definitions for the in-database bookmark and
 * annotation structures as of Weasel 1.60.
 */
typedef struct GPlmMarkType {
  UInt32        offset;
  char          title[MAX_BMRK_LENGTH];
} GPlmMark;

typedef struct GPlmAnnotationType {
  UInt32        offset;
  char          title[MAX_BMRK_LENGTH];
} GPlmAnnotation;



/*
 * Given the data from a complete zTXT database in db->output, this function
 * will disect that DB into its component elements and store them into the
 * other members of the ztxt structure.
 *
 * In particular, it will place the decompressed text data into db->input.
 * Bookmarks, if any, will be placed into the db->bookmarks linked list.
 * Annotations, if any, will be placed into the db->annotations linked list.
 *
 * Values in db->dbHeader, db->dbRecordEntries, and db->record0 will be kept
 * in Big Endian notation as they are found in the DB itself.
 *
 * Returns 1 on success.  Returns 0 on invalid DB.  Returns -1 if compressed
 * data is invalid (libz error).
 */
int
ztxt_disect(ztxt *db)
{
  GPlmMark      *mark;
  int           mark_record;
  int           num_orig_marks;
  GPlmAnnotation *anno;
  int           anno_record;
  int           num_orig_annos;
  int           i;
  char          *anno_text;
  z_stream      zstream;
  int           data_size;

  /* Set Palm DB header pointers */
  memcpy(db->dbHeader, db->output, sizeof(DatabaseHdrType));
  db->dbRecordEntries =
    (RecordEntryType *)malloc(sizeof(RecordEntryType)
                              * ntohs(db->dbHeader->recordList.numRecords));
  memcpy(db->dbRecordEntries,
         &((DatabaseHdrType *)db->output)->recordList.firstEntry,
         sizeof(RecordEntryType) * ntohs(db->dbHeader->recordList.numRecords));

  /* Set record 0 pointer */
  memcpy(&db->record0, &db->output[ntohl(db->dbRecordEntries[0].localChunkID)],
         sizeof(zTXT_record0));

  /* Set DB attributes */
  if (ntohs(db->record0.flags) & ZTXT_RANDOMACCESS)
    db->compression_type = 1;
  else
    db->compression_type = 2;

  num_orig_marks = ntohs(db->record0.numBookmarks);
  mark_record = ntohs(db->record0.bookmarkRecord);
  num_orig_annos = ntohs(db->record0.numAnnotations);
  anno_record = ntohs(db->record0.annotationRecord);

  db->input_size = ntohl(db->record0.size);


  /* Store bookmarks into bookmark linked list */
  if (num_orig_marks)
    {
      mark = (GPlmMark *)&db->output[
        ntohl(db->dbRecordEntries[mark_record].localChunkID)];
      for (i = 0; i < num_orig_marks; i++)
        ztxt_add_bookmark(db, mark[i].title, ntohl(mark[i].offset));
    }


  /* Store annotations into annotation linked list */
  if (num_orig_annos)
    {
      anno = (GPlmAnnotation *)&db->output[
        ntohl(db->dbRecordEntries[anno_record].localChunkID)];
      for (i = 0; i < num_orig_annos; i++)
        {
          anno_text = (char *)&db->output[
            ntohl(db->dbRecordEntries[anno_record + 1 + i].localChunkID)];
          ztxt_add_annotation(db, anno[i].title, ntohl(anno[i].offset),
                              anno_text);
        }
    }


  /* Decompress text data and store in db->input */
  db->input = (char *)malloc(db->input_size + 1);

  /* Calculate compressed data size */
  if (num_orig_marks)
    data_size =
      (&db->output[ntohl(db->dbRecordEntries[mark_record].localChunkID)]
       - &db->output[ntohl(db->dbRecordEntries[1].localChunkID)]);
  else if (num_orig_annos)
    data_size =
      (&db->output[ntohl(db->dbRecordEntries[anno_record].localChunkID)]
       - &db->output[ntohl(db->dbRecordEntries[1].localChunkID)]);
  else
    data_size = db->output_size - ntohl(db->dbRecordEntries[1].localChunkID);

  zstream.zalloc = Z_NULL;
  zstream.zfree = Z_NULL;
  zstream.opaque = Z_NULL;
  zstream.next_in =
    (u_char *)&db->output[ntohl(db->dbRecordEntries[1].localChunkID)];
  zstream.next_out = (u_char *)db->input;
  zstream.avail_in = data_size;
  zstream.avail_out = db->input_size + 1;

  if (inflateInit2(&zstream, MAXWBITS) != Z_OK)
    {
      free(db->input);
      free(db->dbRecordEntries);
      return 0;
    }

  i = inflate(&zstream, Z_SYNC_FLUSH);
  if ((i != Z_STREAM_END) && (i != Z_OK))
    {
      free(db->input);
      free(db->dbRecordEntries);
      return 0;
    }

  inflateEnd(&zstream);


  /* Free memory */
  free(db->dbRecordEntries);
  db->dbRecordEntries = NULL;

  return 1;
}
