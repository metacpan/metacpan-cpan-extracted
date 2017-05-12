#include <sys/types.h>
#include <dirent.h>
#include <string.h>
#include "util.h"
#include "tables.h"

/* From tables.c */
int
lookup_table(tbl, find_token)
struct gen_table *tbl;
int find_token;
{
    while (tbl->key) {
	if (almost_equals(find_token, tbl->key))
	    return tbl->value;
	tbl++;
    }
    return tbl->value; /* *_INVALID */
}

extern int can_accept_commands;
int can_accept_commands = 0;

/*#include "gp_types.h"*/
#include "util.h"
#include "alloc.h"

double
real(val)			/* returns the real part of val */
    struct value *val;
{
    switch (val->type) {
    case INTGR:
	return ((double) val->v.int_val);
    case CMPLX:
	return (val->v.cmplx_val.real);
    }
    int_error(NO_CARET, "unknown type in real()");
    /* NOTREACHED */
    return ((double) 0.0);
}

/* expand tilde in path
 * path cannot be a static array!
 * tilde must be the first character in *pathp;
 * we may change that later
 */
void
gp_expand_tilde(pathp)
    char **pathp;
{
    char *user_homedir = getenv("HOME");

    if (!*pathp)
	int_error(NO_CARET, "Cannot expand empty path");

    if ((*pathp)[0] == '~' && (*pathp)[1] == DIRSEP1) {
	if (user_homedir) {
	    size_t n = strlen(*pathp);

	    *pathp = gp_realloc(*pathp, n + strlen(user_homedir), "tilde expansion");
	    /* include null at the end ... */
	    memmove(*pathp + strlen(user_homedir) - 1, *pathp, n + 1);
	    memcpy(*pathp, user_homedir, strlen(user_homedir));
	} else
	    int_warn(NO_CARET, "HOME not set - cannot expand tilde");
    }
}

#include "axis.h"
#include "dirent.h"

AXIS axis_array[AXIS_ARRAY_SIZE]
    = AXIS_ARRAY_INITIALIZER(DEFAULT_AXIS_STRUCT);

#define get_fontpath() getenv("GNUPLOT_FONTPATH")

/* Harald Harders <h.harders@tu-bs.de> */
/* Thanks to John Bollinger <jab@bollingerbands.com> who has tested the
   windows part */
static char *
recursivefullname(const char *path, const char *filename, TBOOLEAN recursive)
{
    char *fullname = NULL;
    FILE *fp;

    /* length of path, dir separator, filename, \0 */
    fullname = gp_alloc(strlen(path) + 1 + strlen(filename) + 1,
			"recursivefullname");
    strcpy(fullname, path);
    PATH_CONCAT(fullname, filename);

    if ((fp = fopen(fullname, "r")) != NULL) {
	fclose(fp);
	return fullname;
    } else {
	free(fullname);
	fullname = NULL;
    }

    if (recursive) {
#ifdef HAVE_DIRENT_H
	DIR *dir;
	struct dirent *direntry;
	struct stat buf;

	dir = opendir(path);
	if (dir) {
	    while ((direntry = readdir(dir)) != NULL) {
		char *fulldir = gp_alloc(strlen(path) + 1 + strlen(direntry->d_name) + 1,
					 "fontpath_fullname");
		strcpy(fulldir, path);
#  if defined(VMS)
		if (fulldir[strlen(fulldir) - 1] == ']')
		    fulldir[strlen(fulldir) - 1] = '\0';
		strcpy(&(fulldir[strlen(fulldir)]), ".");
		strcpy(&(fulldir[strlen(fulldir)]), direntry->d_name);
		strcpy(&(fulldir[strlen(fulldir)]), "]");
#  else
		PATH_CONCAT(fulldir, direntry->d_name);
#  endif
		stat(fulldir, &buf);
		if ((S_ISDIR(buf.st_mode)) &&
		    (strcmp(direntry->d_name, ".") != 0) &&
		    (strcmp(direntry->d_name, "..") != 0)) {
		    fullname = recursivefullname(fulldir, filename, TRUE);
		    if (fullname != NULL)
			break;
		}
		free(fulldir);
	    }
	    closedir(dir);
	}
#elif defined(_Windows) || defined(MY_Windows)
	HANDLE filehandle;
	WIN32_FIND_DATA finddata;
	char *pathwildcard = gp_alloc(strlen(path) + 2, "fontpath_fullname");

	strcpy(pathwildcard, path);
	PATH_CONCAT(pathwildcard, "*");

	filehandle = FindFirstFile(pathwildcard, &finddata);
	free(pathwildcard);
	if (filehandle != INVALID_HANDLE_VALUE)
	    do {
		if ((finddata.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) &&
		    (strcmp(finddata.cFileName, ".") != 0) &&
		    (strcmp(finddata.cFileName, "..") != 0)) {
		    char *fulldir = gp_alloc(strlen(path) + 1 + strlen(finddata.cFileName) + 1,
					     "fontpath_fullname");
		    strcpy(fulldir, path);
		    PATH_CONCAT(fulldir, finddata.cFileName);

		    fullname = recursivefullname(fulldir, filename, TRUE);
		    free(fulldir);
		    if (fullname != NULL)
			break;
		}
	    } while (FindNextFile(filehandle, &finddata) != 0);
	FindClose(filehandle);

#else
	int_warn(NO_CARET, "Recursive directory search not supported\n\t('%s!')", path);
#endif
    }
    return fullname;
}


/* may return NULL */
char *
fontpath_fullname(const char *filename)
{
    FILE *fp;
    char *fullname = NULL;

#if defined(PIPES)
    if (*filename == '<') {
	os_error(NO_CARET, "fontpath_fullname: No Pipe allowed");
    } else
#endif /* PIPES */
    if ((fp = fopen(filename, "r")) == (FILE *) NULL) {
	/* try 'fontpath' variable */
	char *tmppath, *path = NULL;

	while ((tmppath = get_fontpath()) != NULL) {
	    TBOOLEAN subdirs = FALSE;
	    path = gp_strdup(tmppath);
	    if (path[strlen(path) - 1] == '!') {
		path[strlen(path) - 1] = '\0';
		subdirs = TRUE;
	    }			/* if */
	    fullname = recursivefullname(path, filename, subdirs);
	    if (fullname != NULL) {
		while (get_fontpath());
		free(path);
		break;
	    }
	    free(path);
	}

    } else
	fullname = gp_strdup(filename);

    return fullname;
}

/* COLOUR MODES - GLOBAL VARIABLES */
t_sm_palette sm_palette;  /* initialized in init_color() */

#include "getcolor.h"

void
init_color()
{
  /* initialize global palette */
  sm_palette.colorFormulae = 37;  /* const */
  sm_palette.formulaR = 7;
  sm_palette.formulaG = 5;
  sm_palette.formulaB = 15;
  sm_palette.positive = SMPAL_POSITIVE;
  sm_palette.use_maxcolors = 0;
  sm_palette.colors = 0;
  sm_palette.color = NULL;
  sm_palette.ps_allcF = 0;
  sm_palette.gradient_num = 0;
  sm_palette.gradient = NULL;
  sm_palette.cmodel = C_MODEL_RGB;
  sm_palette.Afunc.at = sm_palette.Bfunc.at = sm_palette.Cfunc.at = NULL;
  sm_palette.gamma = 1.5;


  sm_palette.colorMode = SMPAL_COLOR_MODE_GRAY;

#if 0
  /* initialisation of smooth color box */
  color_box.where = SMCOLOR_BOX_DEFAULT;
  color_box.rotation = 'v';
  color_box.border = 1;
  color_box.border_lt_tag = -1;
  color_box.xorigin = 0.9;
  color_box.yorigin = 0.2;
  color_box.xsize = 0.1;
  color_box.ysize = 0.63;
#endif
}

static const int interactive = 0;

/*
   Make the colour palette. Return 0 on success
   Put number of allocated colours into sm_palette.colors
 */
int
make_palette(void)
{
    int i;
    double gray;

    /* this is simpy for deciding, if we print
     * a message after allocating new colors */
    static t_sm_palette save_pal = {
	-1, -1, -1, -1, -1, -1, -1, -1,
	(rgb_color *) 0, -1
    };

#if 0
    GIF_show_current_palette();
#endif

    if (!term->make_palette) {
	fprintf(stderr, "Error: terminal \"%s\" does not support continous colors.\n",term->name);
	return 1;
    }

    /* ask for suitable number of colours in the palette */
    i = term->make_palette(NULL);
    if (i == 0) {
	/* terminal with its own mapping (PostScript, for instance)
	   It will not change palette passed below, but non-NULL has to be
	   passed there to create the header or force its initialization
	 */
	term->make_palette(&sm_palette);
	return 0;
    }

    /* set the number of colours to be used (allocated) */
    sm_palette.colors = i;
    if (sm_palette.use_maxcolors > 0 && i > sm_palette.use_maxcolors)
	sm_palette.colors = sm_palette.use_maxcolors;

    if (save_pal.colorFormulae < 0
	|| sm_palette.colorFormulae != save_pal.colorFormulae
	|| sm_palette.colorMode != save_pal.colorMode
	|| sm_palette.formulaR != save_pal.formulaR
	|| sm_palette.formulaG != save_pal.formulaG
	|| sm_palette.formulaB != save_pal.formulaB
	|| sm_palette.positive != save_pal.positive 
	|| sm_palette.colors != save_pal.colors) {
	/* print the message only if colors have changed */
	if (interactive)
	fprintf(stderr, "smooth palette in %s: available %i color positions; using %i of them\n", term->name, i, sm_palette.colors);
    }

    save_pal = sm_palette;

    if (sm_palette.color != NULL) {
	free(sm_palette.color);
	sm_palette.color = NULL;
    }
    sm_palette.color = gp_alloc( sm_palette.colors * sizeof(rgb_color), 
				 "pm3d palette color");

    /*  fill sm_palette.color[]  */
    for (i = 0; i < sm_palette.colors; i++) {
	gray = (double) i / (sm_palette.colors - 1);	/* rescale to [0;1] */
	color_from_gray( gray, &(sm_palette.color[i]) );
    }
    
    /* let the terminal make the palette from the supplied RGB triplets */
    term->make_palette(&sm_palette);

#if 0
    GIF_show_current_palette();
#endif

    return 0;
}

#ifdef OS2
extern char PM_path[256];
#endif

#ifdef X11
extern char *X11_forced_path;
int extern X11_args(int argc, char *argv[]);
#endif

void
setup_exe_paths(char *path)
{
#ifdef X11
    char *s = "dummy";

    X11_forced_path = (char*)malloc(1 + strlen(path));
    strcpy(X11_forced_path, path);
    X11_args(1,&s);
#endif
#ifdef OS2
    if (strlen(path) >= sizeof(PM_path))
	fprintf(stderr, "Error: setup_exe_paths('%s'): path too long (%d chars).\n", path, (int)strlen(path));
    else
	strcpy(PM_path,path);
#endif
}
