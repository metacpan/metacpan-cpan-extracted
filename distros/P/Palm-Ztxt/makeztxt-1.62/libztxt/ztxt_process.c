/*
 * libztxt:  A library for creating zTXT databases
 *
 * $Id: ztxt_process.c 412 2007-06-21 06:57:30Z foxamemnon $
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
#include <regex.h>
#include <zlib.h>
#include "ztxt.h"


/* Local functions */
static void     reformat_ztxt(ztxt *db, int method, int line_length);
static void     process_regex(ztxt *db);
static int      compress_ztxt(ztxt *db);
static void     add_bmrk(ztxt *db, u_long bmrk_pos, u_long title_pos, int len);
static char *   getline_nocr(char *out, char *in, long *offset,
                             long outsize, long insize);



/*
 * Process a ztxt structure.  This will first process the input buffer to
 * properly format the lines with the specified method and line_length:
 *    method #0 - strip linefeeds from all lines longer than line_length.
 *                if line_length is 0, then scan the buffer and compute the
 *                average line length and use that.
 *    method #1 - strip linefeeds from line if it contains any text at all
 *    method #2 - leave text unchanged
 *
 * After the buffer has been formatted, compile all regex and run them
 * through the buffer to generate any bookmarks.
 *
 * Finally, compress the buffer storing the result in db->output. db->input
 * is left unchanged through all of this.
 *
 * Return codes:
 *     0 = success
 *     1 = error allocating zlib ouput buffer
 *   2,3 = zlib errors.  See comments for compress_ztxt()
 */
int
ztxt_process(ztxt *db, int method, int line_length)
{
  reformat_ztxt(db, method, line_length);

  process_regex(db);

  return compress_ztxt(db);
}


/*
 * Scan the input buffer and adjust the newlines for the Palm.
 */
static void
reformat_ztxt(ztxt *db, int method, int line_length)
{
  long  offset = 0;
  long  total_length = 0;
  long  num_lines = 0;
  int   len;
  int   pos = 0;
  char  instr[255];

  if ((line_length == 0) && (method == 0))
    {
      /* If line_length is 0 we autodetect.  This involves computing the
       * average line length of the entire file and then subtracting 5 */
      while (getline_nocr(instr, db->input, &offset, 255, db->input_size))
        {
          num_lines++;
          total_length += strlen(instr);
        }
      line_length = (total_length / num_lines) - 5;

      /* Probably shouldn't strip linefeeds of lines shorter than 20 characters
       * under any circumstances (unless explicity told to). */
      if (line_length < 20)
        line_length = 20;
    }

  /* Allocate the temporary data buffer */
  db->tmp = (char *)malloc(db->input_size + 1);
  db->tmp[0] = '\0';

  offset = 0;
  while (getline_nocr(instr, db->input, &offset, 255, db->input_size))
    {
      len = strlen(instr);

      switch (method)
        {
          case 0:
            /* A newline by itself is okay.  For normal text, strip the
               newline unless the line is less than options.line_length
               chars, then leave it alone. */
            if ((len > line_length) && (instr[len-1] == '\n'))
              instr[len-1] = ' ';
            break;

          case 1:
            /* A newline by itself is okay.  For other lines, remove all
               linefeeds */
            if ((len != 1) && (instr[len-1] == '\n'))
              instr[len-1] = ' ';
            break;

          case 2:
          default:
            /* Just leave the next alone.  No linefeed stripping. */
            break;
        }

      /* Append the input string to the input buffer */
      memcpy(&(db->tmp[pos]), instr, len);
      pos += len;
    }
  db->tmp[pos] = '\0';
  db->tmpsize = pos;
}


/*
 * Compile regex and then run them through the input buffer
 */
static void
process_regex(ztxt *db)
{
  regex_node    *current = db->regex_list;
  long          start_pos;
  int           i;
#ifdef POSIX_REGEX
  regmatch_t    matches[3];
  char          *err_string;
  int           str_len;
  int           err;
#else /* GNU regex */
  const char    *err;
  struct re_registers regs;     /* For picking up exactly what is matched. */
#endif


  /* This should be a good enough regex syntax to use.  Several features
   * without anything that might confuse people */
#ifndef POSIX_REGEX
  re_syntax_options = RE_SYNTAX_POSIX_EXTENDED | RE_CHAR_CLASSES;
#endif

  /* Compile the regular expressions */
  while (current != NULL)
    {
#ifdef POSIX_REGEX
      err = regcomp(&current->prog, current->pattern,
                    REG_EXTENDED | REG_NEWLINE);
      if (err)
        {
          str_len = regerror(err, &current->prog, NULL, 0);
          err_string = (char *)malloc(str_len);
          regerror(err, &current->prog, err_string, str_len);
          fprintf(stderr, "\nregular expression generated errors:\n"
                  "\t%s\n"
                  "\t%s\n", current->pattern, err_string);
          free(err_string);
          current->bad = 1;
        }
#else /* GNU regex */
      current->prog.buffer = NULL;
      current->prog.allocated = 0;
      current->prog.translate = NULL;
      current->prog.fastmap = (char *)malloc(1024);

      err = re_compile_pattern(current->pattern, strlen(current->pattern),
                               &current->prog);
      if (err)
        {
          fprintf(stderr, "\nregular expression generated errors:\n"
                  "\t%s\n"
                  "\t%s\n", current->pattern, err);
          free(current->prog.fastmap);
          current->prog.fastmap = NULL;
          current->bad = 1;
        }
#endif
      current = current->next;
    }

  /* Run the regex over the input buffer */
  current = db->regex_list;
  for (i = 0; ((i < db->num_regex) && (current != NULL)); i++)
    {
      if (!current->bad)
        {
#ifdef POSIX_REGEX
          start_pos = 0;
          while (regexec(&current->prog, db->tmp+start_pos,
                         3, matches, 0) != REG_NOMATCH)
            {
              if (matches[2].rm_so == -1)
                /* No subexpression to match. */
                add_bmrk(db, start_pos + matches[0].rm_so, start_pos +
                         matches[0].rm_so,
                         matches[0].rm_eo - matches[0].rm_so );
              else
                /* Subexpression to match. */
                add_bmrk(db, start_pos + matches[0].rm_so,
                         start_pos + matches[2].rm_so,
                         matches[0].rm_eo - matches[2].rm_so );
              start_pos += matches[0].rm_eo;
            }
#else /* GNU regex */
          start_pos = re_search(&current->prog, db->tmp, db->tmpsize,
                                0, db->tmpsize, &regs);
          while (start_pos >= 0)
            {
              if ((regs.num_regs >= 2) && (regs.start[1] != -1))
                {
                  add_bmrk(db, start_pos, regs.start[1],
                           regs.end[1] - regs.start[1]);
                  start_pos = re_search(&current->prog, db->tmp, db->tmpsize,
                                        (start_pos
                                         + regs.end[1] - regs.start[1]),
                                        db->tmpsize, &regs);
                }
              else
                {
                  add_bmrk(db, start_pos, start_pos, MAX_BMRK_LENGTH * 2);
                  start_pos = re_search(&current->prog, db->tmp, db->tmpsize,
                                        start_pos + 1, db->tmpsize, &regs);
                }
            }
#endif
        }

      /* Don't need the compiled regex anymore */
      regfree(&current->prog);

      current = current->next;
    }
}


/*
 * Compress the data in the temp buffer, db->tmp, and put the result
 * in db->compressed_data.
 *   Returns:
 *      0 on success
 *      1 if unable to allocate zlib buffer
 *      2 if unable to initialize zlib
 *      3 if compression ended, but there is still input data
 */
static int
compress_ztxt(ztxt *db)
{
  char          *zbuf;
  char          buf[RECORD_SIZE];
  u_int         zpos = 0;
  u_int         zbuf_size;
  z_stream      zstream;
  int           x;
  int           bytesleft;
  int           *offsets;
  int           done = 0;

  /* Allocate the compression buffer.  Large than the input to be safe */
  zbuf_size = db->tmpsize + (db->tmpsize / 50) + 50;
  zbuf = (char *)malloc(zbuf_size);
  if (!zbuf)
    {
      free (db->tmp);
      return 1;
    }

  /* Allocate space for the record index */
  offsets = db->record_offsets = (int *)malloc(8192);

  /* These values must be set before using Zlib */
  zstream.zalloc = Z_NULL;
  zstream.zfree = Z_NULL;
  zstream.opaque = Z_NULL;

  /* Initialize the compression stream */
  x = deflateInit2(&zstream, Z_BEST_COMPRESSION, Z_DEFLATED,
                   db->wbits, 9, Z_DEFAULT_STRATEGY);
  if (x != Z_OK)
    {
      free(db->tmp);
      db->tmp = NULL;
      free(zbuf);
      return 2;
    }

  switch (db->compression_type)
    {
      case 1:
        /* Method 1 allows for random access in the compressed data */

        /* Set buffer pointers */
        zstream.next_in = (u_char *)buf;
        zstream.next_out = (u_char *)zbuf;
        zstream.avail_in = RECORD_SIZE;
        zstream.avail_out = zbuf_size;

        offsets[0] = 0;
        db->num_records = 0;
        if (db->tmpsize < RECORD_SIZE)
          {
            memcpy(buf, db->tmp, db->tmpsize);
            bytesleft = 0;
            zpos = db->tmpsize;
            zstream.avail_in = db->tmpsize;
          }
        else
          {
            memcpy(buf, db->tmp, RECORD_SIZE);
            bytesleft = db->tmpsize - RECORD_SIZE;
            zpos = RECORD_SIZE;
          }

        /* Compress the input file into one big buffer */
        x = deflate(&zstream, Z_FULL_FLUSH);
        while ((x == Z_OK) && (!done))
          {
            if (zstream.avail_in == 0)
              {
                /* input buffer is empty */
                if (bytesleft >= RECORD_SIZE)
                  {
                    memcpy(buf, &(db->tmp[zpos]), RECORD_SIZE);
                    zpos += RECORD_SIZE;
                    bytesleft -= RECORD_SIZE;
                    zstream.next_in = (u_char *)buf;
                    zstream.avail_in = RECORD_SIZE;
                    db->num_records++;
                    offsets[db->num_records] = zstream.total_out;
                    /* Deflate the next block of data */
                    x = deflate(&zstream, Z_FULL_FLUSH);
                  }
                else if (bytesleft > 0)
                  {
                    memcpy(buf, &(db->tmp[zpos]), bytesleft);
                    zpos += bytesleft;
                    zstream.next_in = (u_char *)buf;
                    zstream.avail_in = bytesleft;
                    db->num_records++;
                    offsets[db->num_records] = zstream.total_out;
                    x = deflate(&zstream, Z_FULL_FLUSH);
                    done = 1;
                  }
                else
                  done = 1;
              }
          }

        db->num_records++;

        if (x != Z_OK)
          {
            fprintf(stderr,
                    "Input still pending...\n"
                    "\t zlib ret = %d\n"
                    "\tbytesleft = %d\n"
                    "\t avail_in = %d\n"
                    "\tavail_out = %d\n",
                    x, bytesleft, zstream.avail_in, zstream.avail_out);
            free(db->tmp);
            db->tmp = NULL;
            free(offsets);
            db->record_offsets = NULL;
            free(zbuf);
            return 3;
          }
        break;


      case 2:
        /* Method 2 gives about 10% - 15% more compression */

        /* Set buffer pointers */
        zstream.next_in = (u_char *)db->tmp;
        zstream.next_out = (u_char *)zbuf;
        zstream.avail_in = db->tmpsize;
        zstream.avail_out = zbuf_size;

        /* Compress the input file into one big buffer */
        x = deflate(&zstream, Z_FINISH);
        if (x != Z_STREAM_END)
          {
            fprintf(stderr,
                    "Input still pending...\n"
                    "\t avail_in = %d\n"
                    "\tavail_out = %d\n", zstream.avail_in, zstream.avail_out);
            free(db->tmp);
            db->tmp = NULL;
            free(offsets);
            db->record_offsets = NULL;
            free(zbuf);
            return 3;
          }

        /* Generate the offset list */
        db->num_records = zstream.total_out / RECORD_SIZE;
        if ((db->num_records * RECORD_SIZE) != zstream.total_out)
          db->num_records++;
        for (x = 0; x < db->num_records; x++)
          offsets[x] = x * RECORD_SIZE;

        break;
    }

  deflateEnd(&zstream);

  db->comp_size = zstream.total_out;
  db->compressed_data = zbuf;

  free(db->tmp);
  db->tmp = NULL;

  return 0;
}


/*
 * Adds a bookmark entry to the linked list in sorted order
 */
static void
add_bmrk(ztxt *db, u_long bmrk_pos, u_long title_pos, int len)
{
  char          title_buf[(MAX_BMRK_LENGTH * 2) + 1];

  strncpy(title_buf, &(db->tmp[title_pos]), MIN(len, MAX_BMRK_LENGTH * 2));
  title_buf[MIN(len, MAX_BMRK_LENGTH * 2)] = '\0';

  ztxt_strip_spaces(title_buf);
  ztxt_sanitize_string(title_buf);
  title_buf[MAX_BMRK_LENGTH] = '\0';
  ztxt_strip_spaces(title_buf);

  ztxt_add_bookmark(db, title_buf, bmrk_pos);
}


/*
 * Get a line of input from the input buffer.
 * Strip off the CR if there is one.
 */
static char *
getline_nocr(char *out, char *in, long *offset, long outsize, long insize)
{
  char  *buf = (in + *offset);
  int   i = 0;

  if (*offset >= insize - 1)
    return NULL;

  while ((buf[i] != '\n') && (*offset < insize-1) && (i < outsize-1))
    {
      i++;
      (*offset)++;
    }
  (*offset)++;
  i++;

  strncpy(out, buf, i);
  out[i] = '\0';

  if (i >= 2)
    {
      if (out[i - 2] == '\r')
        {
          out[i - 2] = '\n';
          out[i - 1] = '\0';
        }
    }

  return out;
}
