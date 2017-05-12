/*
 * makeztxt: Translates ASCII files into zTXT databases for use with
 *           Weasel Reader.  Also capable of deconstructing a zTXT database
 *           into its component elements.
 *
 * $Id: makeztxt.c 412 2007-06-21 06:57:30Z foxamemnon $
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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

#ifdef LONG_OPTS
#  include <getopt.h>
#endif

#include "libztxt/ztxt.h"


/*  makeztxt program version */
#define VERSION                 "1.62"
/*  makeztxt options file in user home directory or current dir */
#define REGEX_FILE              ".makeztxtrc"
/*  makeztxt options file in /etc/ system default directory */
#define REGEX_ETC_FILE          "makeztxt.conf"



/*
 * User definable options for new databases
 */
typedef struct optsType {
  int           list_bmrks;
  int           adjust_type;
  int           line_length;
  int           title_set;
  char          *output_filename;
  char          *anno_filename;
  char          *bmrk_filename;
  char          *regex_filename;
  int           deconstruct;
} opts;



/*
 * Local functions
 */

/*  Process commandline arguments  */
static int      process_arguments(ztxt *ztxtdb, int argc, char *argv[]);
/*  Read a line of text from a file and strip off CR  */
static char *   fgets_nocr(char *buffer, int bufsize, FILE *infile);
/*  Open a file in $HOME, /etc/, or current dir  */
static FILE *   fopen_system(char *file, char *etcfile, char *mode);
/*  Load list of regex  */
static int      load_regex(ztxt *ztxtdb);
/*  Fatal error if condition is true  */
static void     errorif(int error);
/*  Strip path elements and file extension from a filename  */
static char *   strip_filename(char *filename);
/*  Create a zTXT database */
static int      create_ztxt(ztxt *ztxtdb, char *inputfile);
/*  Add a list of bookmarks to a zTXT database  */
static int      add_bookmark_list(ztxt *ztxtdb);
/*  Add a list of annotations to a zTXT database  */
static int      add_annotation_list(ztxt *ztxtdb);
/*  Take apart a zTXT database */
static int      deconstruct_ztxt(ztxt *ztxtdb, char *inputfile);
/*  Store bookmark linked list in specified filename  */
static int      output_bookmarks(ztxt *ztxtdb, char *outfile);
/*  Store annotation linked list in specified filename  */
static int      output_annotations(ztxt *ztxtdb, char *outfile);




/* Global options */
opts    options;



int
main(int argc, char *argv[])
{
  int           last_arg;
  ztxt          *ztxtdb;
  int           x;

  /* Default options for a new DB */
  options.list_bmrks    = 0;
  options.adjust_type   = 0;
  options.line_length   = 0;
  options.title_set     = 0;
  options.output_filename = NULL;
  options.anno_filename = NULL;
  options.bmrk_filename = NULL;
  options.regex_filename = NULL;
  options.deconstruct   = 0;

  /* Create a new zTXT database */
  ztxtdb = ztxt_init();
  errorif(ztxtdb == NULL);

  /* Processing... */
  last_arg = process_arguments(ztxtdb, argc, argv);

  if (last_arg >= argc)
    {
      fprintf(stderr, "no input\n");
      exit(1);
    }

  /* Do something */
  if (!options.deconstruct)
    x = create_ztxt(ztxtdb, argv[last_arg]);
  else
    x = deconstruct_ztxt(ztxtdb, argv[last_arg]);

  /* Free memory */
  ztxt_free(ztxtdb);

  if (!x)
    return 1;

  return 0;
}


/*
 * Process commandline arguments
 */
static int
process_arguments(ztxt *ztxtdb, int argc, char *argv[])
{
  int   opt;
  int   w;
  int   nobackup = 0;
  short attr = 0;
  char  *usage_create =
    "usage (create):\n"
    "  makeztxt [-hlLnV] [-A annofile] [-a adjust] [-b line_length] "
    "[-m markfile]\n"
    "       [-o outfile] [-R regexfile] [-r regex] [-t title] [-z comp_type] "
    "input";
  char  *usage_deconstruct =
    "usage (deconstruct):\n"
    "  makeztxt -d [-hV] [-A annofile] [-m markfile] [-o textfile] ztxt_input";
  char  *optstr = "a:A:b:c:df:m:o:r:R:t:u:z:hlLnV";
#ifdef LONG_OPTS
  int   ind;
  static struct option long_options[] = {
    {"annofile",    1, 0, 'A'},
    {"adjust",      1, 0, 'a'},
    {"length",      1, 0, 'b'},
    {"deconstruct", 0, 0, 'd'},
    {"help",        0, 0, 'h'},
    {"list",        0, 0, 'l'},
    {"launchable",  0, 0, 'L'},
    {"markfile",    1, 0, 'm'},
    {"nobackup",    0, 0, 'n'},
    {"output",      1, 0, 'o'},
    {"regexfile",   1, 0, 'R'},
    {"regex",       1, 0, 'r'},
    {"title",       1, 0, 't'},
    {"version",     0, 0, 'V'},
    {"compression", 1, 0, 'z'},
    {0, 0, 0, 0}};
#endif

  if (argc < 2)
    {
      fprintf(stderr, "%s\n\n%s\n\n", usage_create, usage_deconstruct);
      fprintf(stderr, "Type 'makeztxt -h' for more help creating zTXT "
              "files\n");
      fprintf(stderr, "Type 'makeztxt -d -h' for more help disassembling "
              "zTXT files\n\n");
      exit(1);
    }

#ifdef LONG_OPTS
  opt = getopt_long(argc, argv, optstr, long_options, &ind);
#else
  opt = getopt(argc, argv, optstr);
#endif
  while (opt != -1)
    {
      switch (opt)
        {
          case 'A':
            options.anno_filename = optarg;
            break;
          case 'a':
            options.adjust_type = atoi(optarg);
            if ((options.adjust_type < 0) || (options.adjust_type > 2))
              {
                fprintf(stderr, "adjustment type out of range.  "
                        "Must be 0, 1, or 2\n");
                options.adjust_type = 0;
              }
            break;
          case 'b':
            options.line_length = atoi(optarg);
            break;
          case 'd':
            options.deconstruct = 1;
            break;
          case 'h':
            if (!options.deconstruct)
              {
                printf("%s\n\n", usage_create);
#ifdef LONG_OPTS
                printf(
                  "\t-A, --annofile     file containing zTXT annotations\n"
                  "\t-a, --adjust       method for linefeed stripping "
                                       "(0, 1, 2)\n"
                  "\t\t0 = strip linefeeds for lines longer than length\n"
                  "\t\t1 = strip linefeed if line has any text\n"
                  "\t\t2 = no linefeed stripping\n"
                  "\t-b, --length       lines longer than this get linefeed "
                                       "stripped\n"
                  "\t-h, --help         this help\n"
                  "\t-l, --list         list regex generated bookmarks\n"
                  "\t-L, --launchable   set the launchable bit in the "
                                       "output DB\n"
                  "\t-m, --markfile     list of bookmarks to use in zTXT\n"
                  "\t-n, --nobackup     do not set the backup bit in the DB\n"
                  "\t-o, --output       output file to be created\n"
                  "\t-R, --regexfile    file containing list of regex to use\n"
                  "\t-r, --regex        do a regex search for bookmarks\n"
                  "\t-t, --title        title of database\n"
                  "\t-V, --version      makeztxt version\n"
                  "\t-z, --compression  method of compression (1 or 2)\n"
                  "\t\t1 = allow random access (default)\n"
                  "\t\t2 = one big data stream (10%%-15%% more compression)\n"
                  "\n");
#else
                printf(
                  "\t-A   file containing zTXT annotations\n"
                  "\t-a   method for linefeed stripping (0, 1, 2)\n"
                  "\t\t0 = strip linefeeds for lines longer than length\n"
                  "\t\t1 = strip linefeed if line has any text\n"
                  "\t\t2 = no linefeed stripping\n"
                  "\t-b   lines longer than this get linefeed stripped "
                  "(default = auto)\n"
                  "\t-h   this help\n"
                  "\t-l   list regex generated bookmarks\n"
                  "\t-L   set the launchable bit in the output DB\n"
                  "\t-n   do not set the backup bit in the DB\n"
                  "\t-o   output file to be created\n"
                  "\t-R   file containing list of regex to use\n"
                  "\t-r   do a regex search for bookmarks\n"
                  "\t-t   title of database\n"
                  "\t-V   makeztxt version\n"
                  "\t-z   method of compression (1 or 2)\n"
                  "\t\t1 = allow random access (default)\n"
                  "\t\t2 = one big data stream (10%%-15%% more compression)\n"
                  "\n");
#endif
              }
            else
              {
                printf("%s\n\n", usage_deconstruct);
#ifdef LONG_OPTS
                printf(
                  "\t-A, --annofile     output file for zTXT annotations\n"
                  "\t-d, --deconstruct  take apart the input zTXT file\n"
                  "\t-h, --help         this help\n"
                  "\t-m, --markfile     output file for zTXT bookmarks\n"
                  "\t-o, --output       output file for zTXT text data\n"
                  "\t-V, --version      makeztxt version\n"
                  "\n");
#else
                printf(
                  "\t-A   output file for zTXT annotations\n"
                  "\t-d   take apart the input zTXT file\n"
                  "\t-h   this help\n"
                  "\t-m   output file for zTXT bookmarks\n"
                  "\t-o   output file for zTXT text data\n"
                  "\t-V   makeztxt version\n"
                  "\n");
#endif
              }
            exit(1);
          case 'l':
            options.list_bmrks =  1;
            break;
          case 'L':
            attr |= dmHdrAttrLaunchableData;
            break;
          case 'm':
            options.bmrk_filename = optarg;
            break;
          case 'n':
            nobackup = 1;
            break;
          case 'o':
            options.output_filename = strdup(optarg);
            break;
          case 'R':
            options.regex_filename = optarg;
            break;
          case 'r':
            ztxt_add_regex(ztxtdb, optarg);
            break;
          case 't':
            options.title_set = 1;
            ztxt_set_title(ztxtdb, optarg);
            break;
          case 'V':
            printf("makeztxt %s  (libztxt v%s - build %d)\n",
                   VERSION, ztxt_libversion(), ztxt_libbuild());
            exit(0);
            break;
          case 'z':
            w = atoi(optarg);
            if ((w != 1) && (w != 2))
              {
                fprintf(stderr, "compression_type must be 1 or 2. Setting to"
                        "default of 1.\n");
                w = 1;
              }
            ztxt_set_compressiontype(ztxtdb, w);
            break;
        }

#ifdef LONG_OPTS
      opt = getopt_long(argc, argv, optstr, long_options, &ind);
#else
      opt = getopt(argc, argv, optstr);
#endif
    }

  /* Set the database options from those accumulated on the command line */
  if (!nobackup)
    attr |= dmHdrAttrBackup;
  ztxt_set_attribs(ztxtdb, attr);

  return optind;
}


/*
 * Read a line from the file and remove CR
 */
static char *
fgets_nocr(char *buffer, int bufsize, FILE *infile)
{
  int   len;
  char  *str;

  str = fgets(buffer, bufsize, infile);
  if (str != NULL)
    {
      /* got something, remove trailing CR character */
      len = strlen(str);

      if (len >= 2)
        {
          if (str[len - 2] == '\r')
            {
              str[len - 2] = '\n';
              str[len - 1] = 0;
            }
        }
    }

  return str;
}


/*
 * Open the specified file.  First tries user's home directory, then tries
 * file in the current dir.  If these both fail, then the fuction will try to
 * open etcfile in the /etc/ directory.
 *
 * file is the file to open
 * etcfile is the system default to try last.  Pass NULL to not try at all.
 */
static FILE *
fopen_system(char *file, char *etcfile, char *mode)
{
  char  *str = getenv("HOME");
  FILE  *fd = NULL;
  char  buff[512];

  /* Try in home directory */
  if (str != NULL)
    {
      strcpy(buff, str);
      strcat(buff, "/");
      strcat(buff, file);

      fd = fopen(buff, mode);
    }

  /* Next try current dir */
  if (fd == NULL)
    fd = fopen(file, mode);

  /* Finally try in /etc/ if etcfile is not NULL */
  if ((fd == NULL) && (etcfile != NULL))
    {
      strcpy(buff, "/etc/");
      strcat(buff, etcfile);

      fd = fopen(buff, mode);
    }

  return fd;
}


/*
 * Load the regex file if it exists
 *
 * Returns true even if file cannot be opened unless file was explicitly
 * given in options.regex_filename and could not be opened.
 */
static int
load_regex(ztxt *ztxtdb)
{
  FILE  *optfd;
  char  buff[256];
  char  *ptr;
  int   len;

  if (options.regex_filename)
    {
      optfd = fopen_system(options.regex_filename, NULL, "r");
      if (optfd == NULL)
        {
          fprintf(stderr, "Could not load regex file \"%s\"\n",
                  options.regex_filename);
          return 0;
        }
    }
  else
    optfd = fopen_system(REGEX_FILE, REGEX_ETC_FILE, "r");

  if (optfd != NULL)
    {
      buff[0] = 0;

      while (fgets_nocr(buff, 255, optfd) != NULL)
        {
          ptr = buff;

          if (!buff[0])
            break;

          while (*ptr == ' ' || *ptr == '\t' || *ptr == '\n')
            ++ptr;

          if (*ptr != '#' && *ptr)
            {
              /* not a comment line and not blank - process */
              len = strlen(ptr);

              if (ptr[len - 1] == '\n')
                ptr[len - 1] = 0;

              ztxt_add_regex(ztxtdb, strdup(ptr));
            }
          buff[0] = 0;
        }
      fclose(optfd);
    }

  return 1;
}


/*
 * Print error message and exit if 'error' is true
 */
static void
errorif(int error)
{
  if (error)
    {
      perror("makeztxt");
      exit(1);
    }
}


/*
 * Strips off any path elements of a filename and take off the file extension
 */
static char *
strip_filename(char *filename)
{
  char  *y;

  /* First strip off any directory prefixes */
  y = strrchr(filename, '/');
  if (y)
    memmove(filename, y + 1, strlen(y + 1) + 1);
  else
    {
      /* No forward slashes... maybe try backslashed DOS pathnames? */
      y = strrchr(filename, '\\');
      if (y)
        memmove(filename, y + 1, strlen(y + 1) + 1);
    }

  /* Now strip off any existing extension */
  y = strrchr(filename, '.');
  if (y)
    *y = '\0';

  return filename;
}


/*
 * Create a zTXT with user supplied options and data.
 * Returns 0 on error, 1 if successful.
 */
static int
create_ztxt(ztxt *ztxtdb, char *inputfile)
{
  char          *inputbuf = NULL;
  long          insize;
  long          i;
  char          temptitle[255];
  int           x;
  int           infile;
  int           outfile;
  struct stat   instats;
  u_int         filesize;

  if (strcmp(inputfile, "-") != 0)
    {
      /* Reading a normal input file */

      if (!options.title_set)
        {
          strncpy(temptitle, inputfile, dmDBNameLength);
          strip_filename(temptitle);
          temptitle[dmDBNameLength] = '\0';
          ztxt_set_title(ztxtdb, temptitle);
        }

      if (options.output_filename == NULL)
        {
          /* Form DB filename */
          options.output_filename = strdup(inputfile);
          options.output_filename =
            (char *)realloc(options.output_filename,
                            (strlen(options.output_filename) + 10));

          strip_filename(options.output_filename);
          strcat(options.output_filename, ".pdb");
        }

      /* Allocate the input buffer */
      x = stat(inputfile, &instats);
      errorif(x == -1);
      if (instats.st_size == 0)
        {
          fprintf(stderr, "Input contains no data.  Aborting.\n");
          free(options.output_filename);
          return 0;
        }
      inputbuf = (char *)malloc(instats.st_size + 1);
      errorif(inputbuf == NULL);

      /* Load and process the input file */
      infile = open(inputfile, O_RDONLY);
      errorif(infile == -1);
      filesize = read(infile, inputbuf, instats.st_size);
      errorif(filesize == -1);
      close(infile);

      ztxt_set_data(ztxtdb, inputbuf, filesize);
    }
  else
    {
      /* Reading input from stdin */
      if (options.output_filename == NULL)
        {
          fprintf(stderr, "You must specify an output file with -o when "
                  "reading from stdin\n");
          return 0;
        }
      else if (!options.title_set)
        {
          fprintf(stderr, "You must specify a title with -t when reading "
                  "from stdin\n");
          free(options.output_filename);
          return 0;
        }

      /* Allocate the input buffer */
      inputbuf = (char *)malloc(10 * 1024);
      errorif(inputbuf == NULL);
      insize = 10 * 1024;
      i = 0;

      /* Read in all the data from stdin */
      while (!feof(stdin))
        {
          if (i >= insize - 1024)
            {
              inputbuf = (char *)realloc(inputbuf, insize + (10*1024));
              insize += 10*1024;
            }
          fgets(&(inputbuf[i]), 512, stdin);
          i += strlen(&(inputbuf[i]));
        }

      if (i == 0)
        {
          fprintf(stderr, "No data read from stdin.  Aborting.\n");
          free(inputbuf);
          free(options.output_filename);
          return 0;
        }
      inputbuf[i] = '\0';

      ztxt_set_data(ztxtdb, inputbuf, i);
    }


  /* Read in user regex file */
  if (!load_regex(ztxtdb))
    return 0;

  /* Read in bookmark list, if any */
  if (options.bmrk_filename)
    add_bookmark_list(ztxtdb);

  /* Read in annotation list, if any */
  if (options.anno_filename)
    add_annotation_list(ztxtdb);


  /***************
   * Make a zTXT *
   ***************/
  x = ztxt_process(ztxtdb, options.adjust_type, options.line_length);
  if (x > 0)
    {
      fprintf(stderr, "An error occured during the compression phase.\n"
              "Exiting...\n");
      free(inputbuf);
      free(options.output_filename);
      return 0;
    }

  if (options.list_bmrks)
    ztxt_list_bookmarks(ztxtdb);

  ztxt_generate_db(ztxtdb);


  /* Output database */
  outfile = open(options.output_filename, O_WRONLY|O_CREAT|O_TRUNC|O_BINARY,
                 S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH);
  errorif(outfile == -1);

  x = write(outfile, ztxt_get_output(ztxtdb), ztxt_get_outputsize(ztxtdb));
  errorif(x != ztxt_get_outputsize(ztxtdb));

  close(outfile);


  /* Free some memory */
  free(inputbuf);
  free(options.output_filename);

  return 1;
}


/*
 * Given a list of offset/bookmark pairs, this function will add those
 * bookmarks to a zTXT database.  The filename should be stored in
 * options.bmrk_filename and a pre-initialized zTXT DB should be given in
 * ztxtdb.
 *
 * Returns 0 if bookmark file cannot be read, 1 otherwise.
 */
static int
add_bookmark_list(ztxt *ztxtdb)
{
  FILE  *marks;
  char  buf[256];
  int   offset;
  char  *end;

  marks = fopen(options.bmrk_filename, "r");
  if (!marks)
    {
      perror("add_bookmark_list");
      return 0;
    }

  while (fgets_nocr(buf, 255, marks))
    {
      buf[255] = '\0';
      ztxt_strip_spaces(buf);
      offset = strtol(buf, &end, 10);
      ztxt_strip_spaces(end);

      if (strlen(end))
        ztxt_add_bookmark(ztxtdb, end, offset);
    }

  fclose(marks);

  return 1;
}


/*
 * Given a filename in options.anno_filename, this function will add any
 * annotations given in that file to the specified zTXT database.
 *
 * Annotation file format is:
 * "Title: " marks the beginning of a new annotation definition.  Remaining
 *   text on that line is taken as the annotation's title (required)
 * "Offset: " specifies where in the text the annotation is anchored.
 * "Annotation: " gives the text of the annotation.  Text starts just after
 *   this marker.  The annotation text ends when:
 *     1) the file ends
 *     2) annotation reaches a size of 4096 characters
 *     3) another "Title:" marker is encountered at a line beginning
 *
 * Returns 0 if annotation file cannot be read, 1 otherwise.
 */
static int
add_annotation_list(ztxt *ztxtdb)
{
  FILE  *annos;
  char  buf[5001];
  int   type = 0;
  char  title[MAX_BMRK_LENGTH + 1];
  int   offset = 0;
  char  annotext[4096];
  int   annolen = 0;
  int   startanno = 0;
  int   havetitle = 0;
  int   haveoffset = 0;
  int   haveanno = 0;

  annos = fopen(options.anno_filename, "r");
  if (!annos)
    {
      perror("add_annotation_list");
      return 0;
    }

  while (fgets_nocr(buf, 5000, annos))
    {
      buf[5000] = '\0';
      ztxt_strip_spaces(buf);

      if (type == 0)
        havetitle = haveoffset = haveanno = startanno = annolen = 0;

      if (strncmp(buf, "Title: ", 7) == 0)
        {
          type = 1;
          if (startanno)
            {
              haveanno = 1;
              startanno = 0;
            }
        }
      else if (strncmp(buf, "Offset: ", 8) == 0)
        {
          type = 2;
        }
      else if (strncmp(buf, "Annotation:", 11) == 0)
        {
          startanno = 1;
          type = 3;
        }
      else if (!startanno)
        {
           type = 0;
        }

      /* Add an anno if one is ready */
      if (havetitle && haveoffset && haveanno)
        {
          ztxt_add_annotation(ztxtdb, title, offset, annotext);
          havetitle = haveoffset = haveanno = startanno = annolen = 0;
        }

      switch (type)
        {
          case 1:
            strncpy(title, &buf[7], MAX_BMRK_LENGTH);
            title[MAX_BMRK_LENGTH] = '\0';
            havetitle = 1;
            break;

          case 2:
            offset = atol(&buf[8]);
            haveoffset = 1;
            break;

          case 3:
            if (strncmp(buf, "Annotation:", 11) == 0)
              {
                strncpy(annotext, &buf[11], 4095);
                annotext[4095] = '\0';
                annolen = strlen(annotext);
              }
            else
              {
                strncat(annotext, buf, 4095 - annolen);
                annolen += strlen(buf);
              }

            if (annolen >= 4093)
              {
                haveanno = 1;
                startanno = 0;
              }
            break;
        }
    }

  /* Add an anno if one is still unfinished */
  if (startanno)
    haveanno = 1;
  if (havetitle && haveoffset && haveanno)
    ztxt_add_annotation(ztxtdb, title, offset, annotext);


  fclose(annos);

  return 1;
}


/*
 * Take apart an input zTXT and ouput its components into separate files
 * Returns 1 on success, 0 otherwise.
 */
static int
deconstruct_ztxt(ztxt *ztxtdb, char *inputfile)
{
  char          *inputbuf = NULL;
  long          insize;
  long          i;
  int           x;
  int           infile;
  int           outfile;
  struct stat   instats;
  u_int         filesize;

  if (strcmp(inputfile, "-") != 0)
    {
      /* Reading a normal input file */

      if (options.output_filename == NULL)
        {
          /* Form output filename for text */
          options.output_filename = strdup(inputfile);
          options.output_filename =
            (char *)realloc(options.output_filename,
                            (strlen(options.output_filename) + 10));

          strip_filename(options.output_filename);
          strcat(options.output_filename, ".txt");
        }

      /* Allocate the input buffer */
      x = stat(inputfile, &instats);
      errorif(x == -1);
      if (instats.st_size == 0)
        {
          fprintf(stderr, "Input contains no data.  Aborting.\n");
          free(options.output_filename);
          return 0;
        }
      inputbuf = (char *)malloc(instats.st_size + 1);
      errorif(inputbuf == NULL);

      /* Load and process the input file */
      infile = open(inputfile, O_RDONLY|O_BINARY);
      errorif(infile == -1);
      filesize = read(infile, inputbuf, instats.st_size);
      errorif(filesize == -1);
      close(infile);

      ztxt_set_output(ztxtdb, inputbuf, filesize);
    }
  else
    {
      /* Reading input from stdin */
      if (options.output_filename == NULL)
        {
          fprintf(stderr, "You must specify an output file with -o when "
                  "reading from stdin\n");
          return 0;
        }
      else if (!options.title_set)
        {
          fprintf(stderr, "You must specify a title with -t when reading "
                  "from stdin\n");
          free(options.output_filename);
          return 0;
        }

      /* Allocate the input buffer */
      inputbuf = (char *)malloc(10 * 1024);
      errorif(inputbuf == NULL);
      insize = 10 * 1024;
      i = 0;

      /* Read in all the data from stdin */
      while (!feof(stdin))
        {
          if (i >= insize - 1024)
            {
              inputbuf = (char *)realloc(inputbuf, insize + (10 * 1024));
              insize += 10 * 1024;
            }
          inputbuf[i] = fgetc(stdin);
          i++;
        }

      if (i == 0)
        {
          fprintf(stderr, "No data read from stdin.  Aborting.\n");
          free(inputbuf);
          free(options.output_filename);
          return 0;
        }
      inputbuf[i] = '\0';

      ztxt_set_output(ztxtdb, inputbuf, i);
    }

  /* Dismantle zTXT database */
  if (!ztxt_disect(ztxtdb))
    {
      fprintf(stderr,
              "An error occured while decompressing the zTXT database.\n"
              "The zTXT file may be corrupt.\n");
      free(options.output_filename);
      return 0;
    }


  /* Output decompressed text */
  outfile = open(options.output_filename, O_WRONLY|O_CREAT|O_TRUNC,
                 S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH);
  errorif(outfile == -1);

  x = write(outfile, ztxt_get_input(ztxtdb), ztxt_get_inputsize(ztxtdb));
  errorif(x != ztxt_get_inputsize(ztxtdb));

  close(outfile);


  /* Output bookmarks to file */
  if (options.bmrk_filename)
    output_bookmarks(ztxtdb, options.bmrk_filename);


  /* Output annotations to file */
  if (options.anno_filename)
    output_annotations(ztxtdb, options.anno_filename);


  /* Free memory */
  free(options.output_filename);
  // inputbuf does not need to be freed.  It has been handed over to the ztxt
  // db structure and will be freed when that structure is.

  return 1;
}


/*
 * Store bookmark linked list in specified filename
 */
static int
output_bookmarks(ztxt *ztxtdb, char *outfile)
{
  FILE          *of;
  bmrk_node     *bmrk = ztxt_get_bookmarks(ztxtdb);
  char          title[MAX_BMRK_LENGTH + 1];

  if (!bmrk)
    {
      fprintf(stderr, "No bookmarks in zTXT database.\n");
      return 0;
    }

  of = fopen(outfile, "w");
  if (!of)
    return 0;

  while (bmrk)
    {
      strncpy(title, bmrk->title, MAX_BMRK_LENGTH);
      title[MAX_BMRK_LENGTH] = '\0';
      fprintf(of, "%9ld\t%s\n", (long)(bmrk->offset), title);
      bmrk = bmrk->next;
    }

  fclose(of);

  return 1;
}


/*
 * Store annotation linked list in specified filename
 */
static int
output_annotations(ztxt *ztxtdb, char *outfile)
{
  FILE          *of;
  anno_node     *anno = ztxt_get_annotations(ztxtdb);
  char          title[MAX_BMRK_LENGTH + 1];

  if (!anno)
    {
      fprintf(stderr, "No annotations in zTXT database.\n");
      return 0;
    }

  of = fopen(outfile, "w");
  if (!of)
    return 0;

  while (anno)
    {
      strncpy(title, anno->title, MAX_BMRK_LENGTH);
      title[MAX_BMRK_LENGTH] = '\0';
      fprintf(of, "Title: %s\n", title);
      fprintf(of, "Offset: %ld\n", (long)(anno->offset));
      fprintf(of, "Annotation:\n%s\n\n", anno->anno_text);
      anno = anno->next;
    }

  fclose(of);

  return 1;
}
