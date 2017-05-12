/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt.h 412 2007-06-21 06:57:30Z foxamemnon $
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

#ifndef _ZTXT_H_
#define _ZTXT_H_ 1


#include <sys/types.h>
#include <regex.h>
#include "databaseHdrs.h"
#include <weasel_common.h>


/*  Palm's have an epoch of Jan. 1, 1904 */
#define PALM_CTIME_OFFSET       0x7C25B080
/*  Max size of the header.  Should be fine except for huge docs */
#define MAX_HEADER_SIZE         8192


/*  Database header attributes and record attributes */
#define dmRecAttrDirty          0x40
#define dmHdrAttrBackup         0x0008
#define dmHdrAttrLaunchableData 0x0200


/* Converts a 4 character Palm ID string to a UInt32.
 * This is more portable/changeable then using 'GPlm'. */
#define palmid_to_int(id) \
    ((((u_long)((id)[0])) << 24) \
   | (((u_long)((id)[1])) << 16) \
   | (((u_long)((id)[2])) << 8) \
   | (((u_long)((id)[3]))))


/* Our very own min macro */
#ifndef MIN
#  define MIN(x,y) ((x)<=(y) ? (x) : (y))
#endif


/* A linked list of regular expressions */
typedef struct regex_nodeType {
  char          *pattern;
#ifdef POSIX_REGEX
  regex_t       prog;
#else
  struct re_pattern_buffer prog;
#endif
  int           bad;
  struct regex_nodeType *next;
} regex_node;


/* A simple struct for bookmarks generated from the regex */
typedef struct bmrk_nodeType {
  UInt32        offset;
  char          title[MAX_BMRK_LENGTH];
  struct bmrk_nodeType *next;
} bmrk_node;


/*
 * An annotation located in a zTXT.  offset is location in decompressed
 * text where annotation is anchored.  title is the title of the annotation.
 * anno_text is a pointer to the text body of the annotation.
 */
typedef struct anno_nodeType {
  UInt32        offset;
  char          title[MAX_BMRK_LENGTH];
  char          *anno_text;
  struct anno_nodeType *next;
} anno_node;


/* This structure defines all the data and attributes of a zTXT database */
typedef struct ztxtType {
  /* Internal portions of a Palm DB */
  DatabaseHdrType *dbHeader;
  RecordEntryType *dbRecordEntries;
  zTXT_record0  record0;
  /* Used to control the compression */
  int           compression_type;
  int           wbits;
  /* zTXT bookmarks generated from regular expressions */
  short         num_regex;
  regex_node    *regex_list;
  short         num_bookmarks;
  bmrk_node     *bookmarks;
  /* zTXT annotation list */
  short         num_annotations;
  anno_node     *annotations;
  /* input text data */
  long          input_size;
  char          *input;
  /* Intermediate data used during processing */
  long          tmpsize;
  char          *tmp;
  /* Compressed buffer created by zlib */
  long          comp_size;
  char          *compressed_data;
  int           num_records;
  int           *record_offsets;
  /* Complete zTXT database */
  long          output_size;
  char          *output;
} ztxt;



/*
 * Initialize a ztxt structure.  This must be called before any other function
 * in libztxt is used.  Returns an allocated and initialized ztxt structure.
 */
extern ztxt *   ztxt_init(void);


/*
 * Frees all memory associated with a ztxt struct including
 * the struct itself.  Does not free 'input' pointer, however, so this should
 * should be done by the user *before* calling this function (in case you have
 * to use the ztxt structure to fetch the pointer with ztxt_get_input).  Of
 * course, 'input' only needs to be freed if it is non-NULL.
 */
extern void     ztxt_free(ztxt *db);


/*
 * Add a bookmark regex to the linked list to be used for bookmark generation.
 */
extern void     ztxt_add_regex(ztxt *db, char *regex);


/*
 * Add a bookmark to the linked list.  title is the title of the bookmark,
 * limited to MAX_BMRK_LENGTH characters.  offset is the absolute offset in the
 * text data where the bookmark points to.
 */
extern void     ztxt_add_bookmark(ztxt *db, char *title, long offset);


/*
 * Add an annotation to the linked list.  title is the title of the annotation,
 * limited to MAX_BMRK_LENGTH characters.  offset is the absolute offset in the
 * document's text data where the annotation points to.  annotext is the text
 * of the annotation and is limited to 4096 characters including NULL
 * terminator.
 */
extern void     ztxt_add_annotation(ztxt *db, char *title, long offset,
                                    char *annotext);

/*
 * Process a ztxt structure.  This function will reformat the text, search for
 * and add any regex generated bookmarks, and compress the text data.  method
 * controls how to reformat the input text:
 *    method #0 - strip linefeeds from all lines longer than line_length.
 *                if line_length is 0, then scan the buffer and compute the
 *                average line length and use that.
 *    method #1 - strip linefeeds from line if it contains any text at all
 *    method #2 - leave text unchanged
 *
 * Return codes:
 *     0 = success
 *     1 = error allocating zlib ouput buffer
 *     2 = unable to initialize zlib
 *     3 = compression ended, but there is still input data unused
 */
extern int      ztxt_process(ztxt *db, int method, int line_length);


/*
 * After feeding the library all the necessary information, this function
 * will generate a complete zTXT and store the result in the ztxt structure.
 * The finished database is ready for writing to disk.  A pointer to the data
 * can be obtained by using the ztxt_get_output() function.
 */
extern void     ztxt_generate_db(ztxt *db);


/*
 * To deconstruct a zTXT DB, load the whole database into memory and store it
 * in the structure using ztxt_set_output().  Calling this function will then
 * populate the rest of the structure with the components of the zTXT.
 * ztxt_set_output() can then be called again to set the output pointer back to
 * NULL.  This is optional if you do not intend to send this functions output
 * back into libztxt to generate a new DB.
 *
 * Returns false if a zlib error occurs, true otherwise.
 */
extern int      ztxt_disect(ztxt *db);


/*
 * Print a list of generated bookmarks to stdout.
 */
extern void     ztxt_list_bookmarks(ztxt *db);


/*
 * Calculates a 32 bit CRC over the input data at buf (of length len).
 * The value in crc will be used as the seed.  This function is just a wrapper
 * for the crc32 function in zlib.
 *
 * The crc should be initialized first by calling this function with
 * buf == NULL, len == 0, and crc == 0.
 */
extern int      ztxt_crc32(int crc, const void *buf, int len);



/**************************************************
 * ztxt_set_* functions are located in ztxt_set.c
 **************************************************/

/*
 * Set the title of a zTXT database.  This will also be the name of the
 * database when installed on a Palm.  Limited to 32 characters (including
 * NULL terminator).
 */
extern void     ztxt_set_title(ztxt *db, char *new_title);


/*
 * Set the input data libztxt is to operate on.  Typically this will be a
 * pointer to a buffer containing a text document.  datasize is the length
 * of the input data including NULL terminator.
 *
 * This function *must* be called for libztxt to create any database.
 */
extern void     ztxt_set_data(ztxt *db, char *new_data, long datasize);


/*
 * Set the data libztxt's disect function is to operate on.  This is stored in
 * the output pointer since when creating a DB this is where the full database
 * will be stored.  When disecting a database, the process is going in reverse,
 * so the data is stored in the output pointer.
 *
 * This data should be a complete zTXT DB file.  This function *must* be called
 * for libztxt to disect any database.
 */
extern void     ztxt_set_output(ztxt *db, char *data, long datasize);


/*
 * Set the Palm DB creator ID.  This will default to 'GPlm' and normally will
 * not need to be changed.
 */
extern void     ztxt_set_creator(ztxt *db, long new_creator);


/*
 * Set the Palm DB type ID.  This will default to 'zTXT' and normally will
 * not need to be changed.
 */
extern void     ztxt_set_type(ztxt *db, long new_type);


/*
 * Set the window bits parameter of zlib.  This controls certain compression
 * settings.  See the zlib documentation for more information.  This will
 * almost never need to be changed.
 */
extern void     ztxt_set_wbits(ztxt *db, int new_wbits);


/*
 * Set the compression type that libztxt will use for database generation.
 * The choices are type 1 (the default) which will generate a random access
 * zTXT database.  This is normally what is desired.  Type 2 databases will
 * give 10-15% more compression but must be entirely decompressed by the
 * reading software before the document can be read.
 */
extern void     ztxt_set_compressiontype(ztxt *db, int new_comptype);


/*
 * Set the Palm DB attributes.  Defaults to setting only the backup bit.
 * See the Palm API documentation for the definitions of other database
 * attributes.
 */
extern void     ztxt_set_attribs(ztxt *db, short new_attribs);




/**************************************************
 * ztxt_get_* functions are located in ztxt_get.c
 **************************************************/

/*
 * Fetch the output pointer from the ztxt structure.
 */
extern char *   ztxt_get_output(ztxt *db);


/*
 * Fetch the output data size from the ztxt structure.
 */
extern long     ztxt_get_outputsize(ztxt *db);


/*
 * Fetch the input pointer from the ztxt structure.
 */
extern char *   ztxt_get_input(ztxt *db);


/*
 * Fetch the input data size from the ztxt structure.
 */
extern long     ztxt_get_inputsize(ztxt *db);


/*
 * Fetch the number of bookmarks in the linked list from the ztxt structure.
 */
extern short    ztxt_get_num_bookmarks(ztxt *db);


/*
 * Fetch pointer to the bookmark linked list from the ztxt structure.
 */
extern bmrk_node *      ztxt_get_bookmarks(ztxt *db);


/*
 * Fetch the number of annotations in the linked list from the ztxt structure.
 */
extern short    ztxt_get_num_annotations(ztxt *db);


/*
 * Fetch pointer to the annotation linked list from the ztxt structure.
 */
extern anno_node *      ztxt_get_annotations(ztxt *db);




/**************************************************
 * Utility functions located in ztxt_util.c
 **************************************************/

/*
 * Strip the leading and trailing spaces from the given string.
 * Modifies str.  Returns str.
 */
extern char *   ztxt_strip_spaces(char *str);


/*
 * Returns true (1) if character is whitespace.
 */
extern int      ztxt_whitespace(char yoda);


/*
 * Cleans the given string to remove non-printable characters, linefeeds,
 * and carriage returns.  Modifies str.  Returns str.
 */
extern char *   ztxt_sanitize_string(char *str);





/*
 * Use these to find out version information for libztxt.  This functions
 * are in ztxt_info.c.
 */
extern const char *     ztxt_libversion(void);
extern int              ztxt_libbuild(void);




#endif
