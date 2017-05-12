/* $Id: Gnuplot.h,v 1.13 + edits $

Copyright (C) 2006  The PARI group.

This file is part of the PARI/GP package.

PARI/GP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation. It is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY WHATSOEVER.

Check the License for details. You should have received a copy of it, along
with the package; see the file 'COPYING'. If not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */

/* This header should be included in one C file only! */

#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>

#ifdef __cplusplus
  extern "C" {
#endif

/* CAT2:
 *      This macro catenates 2 tokens together.
 */
/* STRINGIFY:
 *      This macro surrounds its token with double quotes.
 */
#ifndef CAT2
# if 42 == 1
#  define CAT2(a,b)a/**/b
#  define CAT3(a,b,c)a/**/b/**/c
#  define CAT4(a,b,c,d)a/**/b/**/c/**/d
#  define CAT5(a,b,c,d,e)a/**/b/**/c/**/d/**/e
#  define STRINGIFY(a)"a"
                /* If you can get stringification with catify, tell me how! */
# endif
# if 42 == 42
#  define CAT2(a,b)a ## b
#  define CAT3(a,b,c)a ## b ## c
#  define CAT4(a,b,c,d)a ## b ## c ## d
#  define CAT5(a,b,c,d,e)a ## b ## c ## d ## e
#  define StGiFy(a)# a
#  define STRINGIFY(a)StGiFy(a)
#  define SCAT2(a,b)StGiFy(a) StGiFy(b)
#  define SCAT3(a,b,c)StGiFy(a) StGiFy(b) StGiFy(c)
#  define SCAT4(a,b,c,d)StGiFy(a) StGiFy(b) StGiFy(c) StGiFy(d)
#  define SCAT5(a,b,c,d,e)StGiFy(a) StGiFy(b) StGiFy(c) StGiFy(d) StGiFy(e)
# endif
# ifndef CAT2
#   include "Bletch: How does this C preprocessor catenate tokens?"
# endif
#endif /* CAT2 */


#define TERgM_CAN_MULTIPLOT    1  /* tested if stdout not redirected */
#define TERgM_CANNOT_MULTIPLOT 2  /* tested if stdout is redirected  */
#define TERgM_BINARY           4  /* open output file with "b"       */

#ifndef NO_JUNK_SMALL

/* Compatibility with the old gnuplot: */
extern  FILE *outfile;
extern  FILE *gpoutfile;
extern int encoding;

extern float                   xoffset;  /* x origin */
extern float                   yoffset;  /* y origin */
extern int		multiplot;

#define SET_OUTFILE (outfile_set++ ? 1 : (set_gpoutfile(), 1))

extern char *outstr;
#define MAX_ID_LEN 50
/* char        outstr[MAX_ID_LEN+1] = "STDOUT"; */
/* char        *outstr = NULL; */
extern double ticscale; /* scale factor for tic marks (was (0..1])*/
typedef int TBOOLEAN;
extern char     default_font[];

enum DATA_TYPES {
	INTGR, CMPLX
};

#if !(defined(ATARI)&&defined(__GNUC__)&&defined(_MATH_H)) &&  !(defined(MTOS)&&defined(__GNUC__)&&defined(_MATH_H)) /* FF's math.h has the type already */
struct cmplx {
	double real, imag;
};
#endif

struct value {
	enum DATA_TYPES type;
	union {
		int int_val;
		struct cmplx cmplx_val;
	} v;
};

struct lexical_unit {	/* produced by scanner */
	TBOOLEAN is_token;	/* true if token, false if a value */
	struct value l_val;
	int start_index;	/* index of first char in token */
	int length;			/* length of token in chars */
};

/* char *token; */
#define MAX_TOKENS 20
extern struct lexical_unit *token;
extern long c_token;
extern long num_tokens;
extern char *input_line;
/* char term_options[200] = ""; */

/* New with 3.7.1: */

#define FIRST_Z_AXIS 0
#define FIRST_Y_AXIS 1
#define FIRST_X_AXIS 2
#define SECOND_Z_AXIS 4 /* for future expansion ;-) */
#define SECOND_Y_AXIS 5
#define SECOND_X_AXIS 6
/* extend list for datatype[] for t,u,v,r though IMHO
 * they are not relevant to time data [being parametric dummies]
 */
#define T_AXIS 3  /* fill gap */
#define R_AXIS 7  /* never used ? */
#define U_AXIS 8
#define V_AXIS 9

#define AXIS_ARRAY_SIZE 10
#define DATATYPE_ARRAY_SIZE 10

extern double base_array[], log_base_array[];
extern TBOOLEAN log_array[];
/* graphics.c */
extern TBOOLEAN is_3d_plot;
extern float xsize, ysize;

/* End of 3.7.1 additions */

/* 3.7.0-devel additions */

extern float surface_rot_z;
extern TBOOLEAN polar;
extern double			base_log_x, base_log_y, base_log_z;
extern TBOOLEAN			is_log_x, is_log_y, is_log_z;
extern double			log_base_log_x2, log_base_log_y2;
extern double base_z;
extern TBOOLEAN screen_ok;

/* End of 3.7.0-devel additions */

#ifndef GNUPLOT_NO_CODE_EMIT
FILE *outfile = NULL;
FILE *gpoutfile = NULL;
static int outfile_set;
static void
set_gpoutfile(void)
{
  outfile = stdout;
  gpoutfile = stdout;
}

int        encoding = 0;
float                   xoffset = 0.0;  /* x origin */
float                   yoffset = 0.0;  /* y origin */
/* int		multiplot		= 0; */

double        ticscale = 1.0; /* scale factor for tic mark */

char *input_line = NULL;
int inline_num;          /* from command.c */

float xsize=1.0, ysize=1.0;
double pointsize=1.0;		/* During test! */

int interactive;    /* from plot.c */
char *infile_name;       /* from plot.c */
char            default_font[MAX_ID_LEN+1] = "\0"; /* Entry added by DJL */

struct lexical_unit tokens[MAX_TOKENS];	/* We only process options,
					   there should not be many */
struct lexical_unit *token = tokens;
long c_token = 0, num_tokens = 0;
/* char term_options[200] = ""; */

/* New with 3.7.1: */

double min_array[AXIS_ARRAY_SIZE], max_array[AXIS_ARRAY_SIZE], base_array[AXIS_ARRAY_SIZE], log_base_array[AXIS_ARRAY_SIZE];
TBOOLEAN log_array[AXIS_ARRAY_SIZE];
int xleft, xright, ybot, ytop;
TBOOLEAN is_3d_plot;

/* End of 3.7.1 additions */

/* 3.7.0-devel additions */

float surface_rot_z = 30.0;
TBOOLEAN polar = 0;
TBOOLEAN is_log_x = 0;
TBOOLEAN is_log_y = 0;
TBOOLEAN is_log_z = 0;
double base_log_x = 0.0;
double base_log_y = 0.0;
double base_log_z = 0.0;
double log_base_log_x = 0.0;
double log_base_log_y = 0.0;
double log_base_log_z = 0.0;
double base_z = 0.0;
TBOOLEAN screen_ok;

void map3d_xy (double x, double y, double z, unsigned int *xt, unsigned int *yt)
{
  (void)x; (void)y; (void)z; (void)xt; (void)yt;
    croak("Unsupported function map3d_xy called");
}

/* End of 3.7.0-devel additions */

/* Here are the only missing functions: */

struct value*
const_express(struct value*v)
{
    if (token[c_token].is_token)
	croak("Expect a number, got a string");
    *v = token[c_token++].l_val;
    return v;
}

void
df_showdata(void) {}

void*
gp_alloc(unsigned long size, char *usage)
{
  (void)usage;
  return malloc(size);
}

void*
gp_realloc(void *old, unsigned long size, char *usage)
{
  (void)usage;
  return realloc(old,size);
}

void
bail_to_command_line()
{
  croak("panic: gnuplot");
}

#endif /* !GNUPLOT_NO_CODE_EMIT */

#endif	/* NO_JUNK_SMALL */ 

/* Cannot pull the whole plot.h, too many contradictions. */

#ifdef __ZTC__
typedef int (*FUNC_PTR)(...);
#else
typedef int (*FUNC_PTR)();
#endif

#ifndef __PROTO
#  define __PROTO(proto) proto
#endif

#if 1
/* this order means we can use  x-(just*strlen(text)*t->h_char)/2 if
 * term cannot justify
 */
typedef enum JUSTIFY {
    LEFT,
    CENTRE,
    RIGHT
} JUSTIFY;

/*
 *    color modes
 */
typedef enum { 
    SMPAL_COLOR_MODE_NONE = '0',
    SMPAL_COLOR_MODE_GRAY = 'g',      /* grayscale only */
    SMPAL_COLOR_MODE_RGB = 'r',       /* one of several fixed transforms */ 
    SMPAL_COLOR_MODE_FUNCTIONS = 'f', /* user definded transforms */
    SMPAL_COLOR_MODE_GRADIENT = 'd'   /* interpolated table: 
				       * explicitly defined or read from file */
} palette_color_mode;

/* Contains a colour in RGB scheme.
   Values of  r, g and b  are all in range [0;1] */
typedef struct {
    double r, g, b;
} rgb_color;

/* to build up gradients:  whether it is really red, green and blue or maybe
 * hue saturation and value in col depends on cmodel */
typedef struct {
  double pos;
  rgb_color col;
} gradient_struct;

typedef struct value t_value;

# define MAX_NUM_VAR	5

/* user-defined function table entry */
typedef struct udft_entry {
    struct udft_entry *next_udf; /* pointer to next udf in linked list */
    char *udf_name;		/* name of this function entry */
    struct at_type *at;		/* pointer to action table to execute */
    char *definition;		/* definition of function as typed */
    t_value dummy_values[MAX_NUM_VAR]; /* current value of dummy variables */
} udft_entry;

typedef struct {
  /** Constants: **/

  /* (Fixed) number of formulae implemented for gray index to RGB
   * mapping in color.c.  Usage: somewhere in `set' command to check
   * that each of the below-given formula R,G,B are lower than this
   * value. */
  int colorFormulae;

  /** Values that can be changed by `set' and shown by `show' commands: **/

  /* can be SMPAL_COLOR_MODE_GRAY or SMPAL_COLOR_MODE_RGB */
  palette_color_mode colorMode;
  /* mapping formulae for SMPAL_COLOR_MODE_RGB */
  int formulaR, formulaG, formulaB;
  char positive;		/* positive or negative figure */

  /* Now the variables that contain the discrete approximation of the
   * desired palette of smooth colours as created by make_palette in
   * pm3d.c.  This is then passed into terminal's make_palette, who
   * transforms this [0;1] into whatever it supports.  */

  /* Only this number of colour positions will be used even though
   * there are some more available in the discrete palette of the
   * terminal.  Useful for multiplot.  Max. number of colours is taken
   * if this value equals 0.  Unused by: PostScript */
  int use_maxcolors;
  /* Number of colours used for the discrete palette. Equals to the
   * result from term->make_palette(NULL), or restricted by
   * use_maxcolor.  Used by: pm, gif. Unused by: PostScript */
  int colors;
  /* Table of RGB triplets resulted from applying the formulae. Used
   * in the 2nd call to term->make_palette for a terminal with
   * discrete colours. Unused by PostScript which has calculates them
   * analytically. */
  rgb_color *color;

  /** Variables used by some terminals **/
  
  /* Option unique for output to PostScript file.  By default,
   * ps_allcF=0 and only the 3 selected rgb color formulae are written
   * into the header preceding pm3d map in the file.  If ps_allcF is
   * non-zero, then print there all color formulae, so that it is easy
   * to play with choosing manually any color scheme in the PS file
   * (see the definition of "/g"). Like that you can get the
   * Rosenbrock multiplot figure on my gnuplot.html#pm3d demo page.
   * Note: this option is used by all terminals of the postscript
   * family, i.e. postscript, pslatex, epslatex, so it will not be
   * comfortable to move it to the particular .trm files. */
  char ps_allcF;

  /* These variables are used to define interpolated color palettes:
   * gradient is an array if (gray,color) pairs.  This array is 
   * gradient_num entries big.  
   * Interpolated tables are used if colorMode==SMPAL_COLOR_MODE_GRADIENT */
  int gradient_num;
  gradient_struct *gradient;

  /* the used color model: RGB, HSV, XYZ, etc. */
  int cmodel;  
  
  /* Three mapping function for gray->RGB/HSV/XYZ/etc. mapping
   * used if colorMode == SMPAL_COLOR_MODE_FUNCTIONS */
  struct udft_entry Afunc;  /* R for RGB, H for HSV, C for CMY, ... */
  struct udft_entry Bfunc;  /* G for RGB, S for HSV, M for CMY, ... */
  struct udft_entry Cfunc;  /* B for RGB, V for HSV, Y for CMY, ... */

  /* gamma for gray scale palettes only */
  double gamma;
} t_sm_palette;

/* a point (with integer coordinates) for use in polygon drawing */
typedef struct {
    unsigned int x, y;
#ifdef EXTENDED_COLOR_SPECS
    double z;
    colorspec_t spec;
#endif
} gpiPoint;

typedef struct TERMENTRY {
    const char *name;
#ifdef WIN16
    const char GPFAR description[80];  /* to make text go in FAR segment */
#else
    const char *description;
#endif
    unsigned int xmax,ymax,v_char,h_char,v_tic,h_tic;

    void (*options) __PROTO((void));
    void (*init) __PROTO((void));
    void (*reset) __PROTO((void));
    void (*text) __PROTO((void));
    int (*scale) __PROTO((double, double));
    void (*graphics) __PROTO((void));
    void (*move) __PROTO((unsigned int, unsigned int));
    void (*vector) __PROTO((unsigned int, unsigned int));
    void (*linetype) __PROTO((int));
    void (*put_text) __PROTO((unsigned int, unsigned int, const char*));
    /* the following are optional. set term ensures they are not NULL */
    int (*text_angle) __PROTO((int));
    int (*justify_text) __PROTO((enum JUSTIFY));
    void (*point) __PROTO((unsigned int, unsigned int,int));
    void (*arrow) __PROTO((unsigned int, unsigned int, unsigned int, unsigned int, TBOOLEAN));
    int (*set_font) __PROTO((const char *font));
    void (*pointsize) __PROTO((double)); /* change pointsize */
    int flags;
    void (*suspend) __PROTO((void)); /* called after one plot of multiplot */
    void (*resume)  __PROTO((void)); /* called before plots of multiplot */
    void (*fillbox) __PROTO((int, unsigned int, unsigned int, unsigned int, unsigned int)); /* clear in multiplot mode */
    void (*linewidth) __PROTO((double linewidth));
#ifdef USE_MOUSE
    int (*waitforinput) __PROTO((void));     /* used for mouse input */
    void (*put_tmptext) __PROTO((int, const char []));   /* draws temporary text; int determines where: 0=statusline, 1,2: at corners of zoom box, with \r separating text above and below the point */
    void (*set_ruler) __PROTO((int, int));    /* set ruler location; x<0 switches ruler off */
    void (*set_cursor) __PROTO((int, int, int));   /* set cursor style and corner of rubber band */
    void (*set_clipboard) __PROTO((const char[]));  /* write text into cut&paste buffer (clipboard) */
#endif
#ifdef PM3D
    int (*make_palette) __PROTO((t_sm_palette *palette));
    /* 1. if palette==NULL, then return nice/suitable
       maximal number of colours supported by this terminal.
       Returns 0 if it can make colours without palette (like 
       postscript).
       2. if palette!=NULL, then allocate its own palette
       return value is undefined
       3. available: some negative values of max_colors for whatever 
       can be useful
     */
    void (*previous_palette) __PROTO((void));  
    /* release the palette that the above routine allocated and get 
       back the palette that was active before.
       Some terminals, like displays, may draw parts of the figure
       using their own palette. Those terminals that possess only 
       one palette for the whole plot don't need this routine.
     */

    void (*set_color) __PROTO((double gray));
    /* gray is from [0;1], terminal uses its palette or another way
       to transform in into gray or r,g,b
       This routine (for each terminal separately) remembers or not
       this colour so that it can apply it for the subsequent drawings
     */
    void (*filled_polygon) __PROTO((int points, gpiPoint *corners));
#endif
} TERMENTRY;
#else
struct TERMENTRY {
        char *name;
#if defined(_Windows) && !defined(WIN32)
        char GPFAR description[80];     /* to make text go in FAR segment */
#else
        char *description;
#endif
        unsigned int xmax,ymax,v_char,h_char,v_tic,h_tic;
        FUNC_PTR options,init,reset,text,scale,graphics,move,vector,linetype,
                put_text,text_angle,justify_text,point,arrow,set_font,
		pointsize;
	int flags;
        FUNC_PTR suspend,resume,fillbox,linewidth;
};
#endif

#ifdef _Windows
#  define termentry TERMENTRY far
#else
#  define termentry TERMENTRY
#endif

extern struct termentry *term;

#ifndef GNUPLOT_NO_CODE_EMIT
struct termentry *term;
#endif /* !GNUPLOT_NO_CODE_EMIT */

#define RETVOID
#define RETINT , 1

#define F_0 void(*)()
#define F_1 void(*)(int)
#define F_1I int(*)(int)
#define F_1D void(*)(double)
#define F_1IP int(*)(char*)
#define F_1IV int(*)(void*)
#define F_2 void(*)(unsigned int,unsigned int)
#define F_2D int(*)(double,double)
#define F_2T void(*)(int,void*)
#define F_3 void(*)(unsigned int,unsigned int,int)
#define F_3T void(*)(int,int,char*)
#define F_4 void(*)(int,int,int,int)
#define F_5 void(*)(int,int,int,int,int)

#define CALL_G_METH0(method) CALL_G_METH(method,0,(),RETVOID)
#define CALL_G_METH1(method,arg1) CALL_G_METH(method,1,(arg1),RETVOID)
#define CALL_G_METH1I(method,arg1) CALL_G_METH(method,1I,(arg1),RETINT)
#define CALL_G_METH1D(method,arg1) CALL_G_METH(method,1D,(arg1),RETVOID)
#define CALL_G_METH1IP(method,arg1) CALL_G_METH(method,1IP,(arg1),RETINT)
#define CALL_G_METH1IV(method,arg1) CALL_G_METH(method,1IV,(arg1),RETINT)
#define CALL_G_METH2(method,arg1,arg2) \
		CALL_G_METH(method,2,((arg1),(arg2)),RETVOID)
#define CALL_G_METH2D(method,arg1,arg2) \
		CALL_G_METH(method,2D,((arg1),(arg2)),RETINT)
#define CALL_G_METH2T(method,arg1,arg2) \
		CALL_G_METH(method,2T,((arg1),(arg2)),RETVOID)
#define CALL_G_METH3(method,arg1,arg2,arg3) \
		CALL_G_METH(method,3,((arg1),(arg2),(arg3)),RETVOID)
#define CALL_G_METH3T(method,arg1,arg2,arg3) \
		CALL_G_METH(method,3T,((arg1),(arg2),(arg3)),RETVOID)
#define CALL_G_METH4(method,arg1,arg2,arg3,arg4) \
		CALL_G_METH(method,4,((arg1),(arg2),(arg3),(arg4)),RETVOID)
#define CALL_G_METH5(method,arg1,arg2,arg3,arg4,arg5) \
		CALL_G_METH(method,5,((arg1),(arg2),(arg3),(arg4),(arg5)),RETVOID)

#define CALL_G_METH(method,mult,args,returnval)    (		\
       (term==0) ? (						\
	 croak("No terminal specified") returnval		\
       ) :							\
         ((term->method==0) ? (					\
	   croak("Terminal does not define " STRINGIFY(method)) returnval \
         ) :							\
           (*(CAT2(F_,mult))term->method)args			\
     ))

#define GET_G_FLAG(mask)    (					\
       (term==0) ? (						\
	 croak("No terminal specified") RETINT			\
       ) :							\
       (term->flags & (mask)))

#ifdef DONT_POLLUTE_INIT
#  define gptable_init()	CALL_G_METH0(init)
#else
#  define init()		CALL_G_METH0(init)
#  define gptable_init		init
#endif
#define reset()		CALL_G_METH0(reset)
#define text()		CALL_G_METH0(text)
#define t_options()	CALL_G_METH0(options)
#define graphics()	CALL_G_METH0(graphics)
#define linetype(lt)	CALL_G_METH1(linetype,lt)
#define justify_text(mode)	CALL_G_METH1I(justify_text,mode)
#define text_angle(ang)	CALL_G_METH1I(text_angle,ang)
#define scale(xs,ys)	CALL_G_METH2D(scale,xs,ys)
#define move(x,y)	CALL_G_METH2(move,x,y)
#define vector(x,y)	CALL_G_METH2(vector,x,y)
#define put_text(x,y,str)	CALL_G_METH3T(put_text,x,y,str)
#define point(x,y,p)	CALL_G_METH3(point,x,y,p)
#define arrow(sx,sy,ex,ey,head)	CALL_G_METH5(arrow,sx,sy,ex,ey,head)
#define set_font(font)	CALL_G_METH1IP(set_font,font)
#define setpointsize(size)	CALL_G_METH1D(pointsize,size)
#define suspend()	CALL_G_METH0(suspend)
#define resume()	CALL_G_METH0(resume)
#define fillbox(sx,sy,ex,ey,head)	CALL_G_METH5(fillbox,sx,sy,ex,ey,head)
#define linewidth(size)	CALL_G_METH1D(linewidth,size)
#define can_multiplot()	GET_G_FLAG(TERgM_CAN_MULTIPLOT)
#define cannot_multiplot()	GET_G_FLAG(TERgM_CANNOT_MULTIPLOT)
#define is_binary()	GET_G_FLAG(TERgM_BINARY)

#ifdef PM3D
#define term_make_palette(palette)	CALL_G_METH1IV(make_palette,palette)
    /* 1. if palette==NULL, then return nice/suitable
       maximal number of colours supported by this terminal.
       Returns 0 if it can make colours without palette (like 
       postscript).
       2. if palette!=NULL, then allocate its own palette
       return value is undefined
       3. available: some negative values of max_colors for whatever 
       can be useful
     */
#define previous_palette()	CALL_G_METH0(previous_palette)
    /* release the palette that the above routine allocated and get 
       back the palette that was active before.
       Some terminals, like displays, may draw parts of the figure
       using their own palette. Those terminals that possess only 
       one palette for the whole plot don't need this routine.
     */

#define set_color(size)	CALL_G_METH1D(set_color,size)
    /* gray is from [0;1], terminal uses its palette or another way
       to transform in into gray or r,g,b
       This routine (for each terminal separately) remembers or not
       this colour so that it can apply it for the subsequent drawings
     */
#define filled_polygon(num,corners)	CALL_G_METH2T(filled_polygon,num,corners)

extern t_sm_palette sm_palette;

#endif


#define termprop(prop) (term->prop)
#define termset(term) my_change_term(term,strlen(term))

struct termentry * change_term(char*,int);

#define TTABLE_STARTPLOT	0
#define TTABLE_ENDPLOT		1
#define TTABLE_STARTMPLOT	2
#define TTABLE_ENDMPLOT		3
#define TTABLE_INIT		4
#define TTABLE_LIST		5
#define TTABLE_COUNT		6

typedef void (*TSET_FP)(char *s);
typedef void (*TST_END_FP)(void);
typedef void (*SET_SIZES_t)(double x, double y);
typedef double (*GET_SIZES_t)(int flag);
typedef void (*SET_MOUSE_FEEDBACK_RECTAGLE_t)(int term_xmin, int term_xmax, 
			     int term_ymin, int term_ymax,
			     double plot_xmin, double plot_xmax,
			     double plot_ymin, double plot_ymax);
typedef void (*SET_TOKENS_t)(struct lexical_unit *toks, int ntoks, char *s);

typedef int (*START_END_OUTPUT_t)(void);
typedef int (*DO_OUTPUT_LINE_t)(char *s);
typedef struct {
  START_END_OUTPUT_t start_output_fun, end_output_fun;
  DO_OUTPUT_LINE_t output_line_fun;
} OUTPUT_FUNC_t;
#define HAVE_SET_OUTPUT_FUNCS

typedef int (set_output_routines_t)(OUTPUT_FUNC_t *funcs);
typedef OUTPUT_FUNC_t * (get_output_routines_t)(void);

typedef int (*GET_TERMS_t)(int n, const char **namep, const char **descrp);

struct t_ftable {
  int loaded;
  FUNC_PTR change_term_p;
  TSET_FP term_set_outputp;
  SET_SIZES_t set_sizesp;
  GET_SIZES_t get_sizesp;
  TST_END_FP term_funcs[TTABLE_COUNT];
  SET_MOUSE_FEEDBACK_RECTAGLE_t mouse_feedback_func;
  TSET_FP setup_exe_path_func;
  SET_TOKENS_t set_tokens_func;
  set_output_routines_t *set_output_routines_func;
  get_output_routines_t *get_output_routines_func;
  GET_TERMS_t get_terms_func;
};

#define HAVE_SETUP_EXE_PATH_FUNC

#ifdef DYNAMIC_PLOTTING			/* Can load plotting DLL later */

int
UNKNOWN_null()
{
    croak("gnuplot-like plotting environment not loaded yet");
    return 0;
}

static void myterm_table_not_loaded_v(void);
static void myterm_table_not_loaded(char*);
static int myterm_table_not_loaded_u();
static void myterm_table_not_loaded_vdd(double x, double y);
static double myterm_table_not_loaded_di(int flag);
static void myterm_table_not_loaded_v4i4d(int term_xmin, int term_xmax, 
			     int term_ymin, int term_ymax,
			     double plot_xmin, double plot_xmax,
			     double plot_ymin, double plot_ymax);
static void myterm_table_not_loaded_v1t1i1p(struct lexical_unit *toks, int ntoks, char *s);
#if 0
static int ftable_warned;
static void
tmp_my_term_init
{
  if (!warned++)
     warn("This runtime link with gnuplot-shim does not implement midlevel start/end functions");
  shim_myinit();
}
#endif

static struct t_ftable my_term_ftable = 
{
	0, &myterm_table_not_loaded_u, &myterm_table_not_loaded,
	&myterm_table_not_loaded_vdd,
	&myterm_table_not_loaded_di,
	{&myterm_table_not_loaded_v, &myterm_table_not_loaded_v, 
	 &myterm_table_not_loaded_v, &myterm_table_not_loaded_v,
	 &myterm_table_not_loaded_v, &myterm_table_not_loaded_v},
	myterm_table_not_loaded_v4i4d, &myterm_table_not_loaded,
	myterm_table_not_loaded_v1t1i1p
};

static struct t_ftable *my_term_ftablep = &my_term_ftable;

static void
myterm_table_not_loaded_v(void)
{
    if (!my_term_ftablep->loaded) {
        UNKNOWN_null();
	return;
    }
    croak("This runtime link with gnuplot-shim does not implement midlevel start/end functions");
}

static void
myterm_table_not_loaded(char *s)
{
  (void)s;
  myterm_table_not_loaded_v();
}

static void
myterm_table_not_loaded_vdd(double x, double y)
{
  (void)x; (void)y;
  myterm_table_not_loaded_v();
}

static double
myterm_table_not_loaded_di(int flag)
{
  (void)flag;
  myterm_table_not_loaded_v();
  return 0;			/* NOT REACHED */
}

static int
myterm_table_not_loaded_u()
{
  myterm_table_not_loaded_v();
  return 0;
}

static void myterm_table_not_loaded_v4i4d(int term_xmin, int term_xmax, 
			     int term_ymin, int term_ymax,
			     double plot_xmin, double plot_xmax,
			     double plot_ymin, double plot_ymax)
{
  (void)term_xmin; (void)term_xmax; (void)term_ymin; (void)term_ymax;
  (void)plot_xmin; (void)plot_xmax; (void)plot_ymin; (void)plot_ymax;
  myterm_table_not_loaded_v();
}

static void myterm_table_not_loaded_v1t1i1p(struct lexical_unit *toks, int ntoks, char *s)
{
  (void)toks; (void)ntoks; (void)s;
  myterm_table_not_loaded_v();
}


#  define change_term		(*my_term_ftablep->change_term_p)
#  define term_set_output	(*my_term_ftablep->term_set_outputp)
#  define term_start_plot	(*my_term_ftablep->term_funcs[TTABLE_STARTPLOT])
#  define term_end_plot	(*my_term_ftablep->term_funcs[TTABLE_ENDPLOT])
#  define term_start_multiplot	(*my_term_ftablep->term_funcs[TTABLE_STARTMPLOT])
#  define term_end_multiplot	(*my_term_ftablep->term_funcs[TTABLE_ENDMPLOT])
#  define term_init		(*my_term_ftablep->term_funcs[TTABLE_INIT])
#  define list_terms		(*my_term_ftablep->term_funcs[TTABLE_LIST])
#  define plotsizes_scale	(*my_term_ftablep->set_sizesp)
#  define plotsizes_scale_get	(*my_term_ftablep->get_sizesp)

#ifdef USE_SET_FEEDBACK_RECTANGLE
/* If DLL has it, but was compiled with older Gnuplot.h */
#  define set_mouse_feedback_rectangle	(*my_term_ftablep->mouse_feedback_func)
#else
#  define set_mouse_feedback_rectangle(term_xmin, term_xmax, term_ymin, term_ymax, plot_xmin, plot_xmax, plot_ymin, plot_ymax)	\
	((my_term_ftablep->loaded & 2) ?	\
	 ((*my_term_ftablep->mouse_feedback_func)(term_xmin, term_xmax, term_ymin, term_ymax, plot_xmin, plot_xmax, plot_ymin, plot_ymax), 0) : 0)
#endif	/* defined USE_SET_FEEDBACK_RECTANGLE */

#define my_setup_exe_path(dir)	\
	((my_term_ftablep->loaded & 4) ?	\
	 ((*my_term_ftablep->setup_exe_path_func)(dir), 0) : 0)

#define run_do_options()			\
	((my_term_ftablep->loaded & 8) ?	\
	 ((*my_term_ftablep->set_tokens_func)(tokens,num_tokens,input_line), 0) :	\
	 (t_options(), 0))

#define set_output_routines(f)					\
	((my_term_ftablep->loaded & 8) ?			\
	 ((*my_term_ftablep->set_output_routines_func)(f)) :	\
	 (0))

#define get_output_routines()		\
	((my_term_ftablep->loaded & 8) ?	\
	 ((*my_term_ftablep->get_output_routines_func)()) :	\
	 ((OUTPUT_FUNC_t*)0))

#define get_terms(n,p1,p2)					\
	((my_term_ftablep->loaded & 8) ?			\
	 ((*my_term_ftablep->get_terms_func)(n,p1,p2)) :	\
	 (0))

#  define scaled_xmax()	((int)(termprop(xmax)*plotsizes_scale_get(0)))
#  define scaled_ymax()	((int)(termprop(ymax)*plotsizes_scale_get(1)))

#define USE_FUNCTION_FROM_TABLE

static struct termentry *
my_change_term(char*s,int l)
{
    SET_OUTFILE;
    if (!my_term_ftablep->change_term_p)
	UNKNOWN_null();
    return term = (*((struct termentry *(*)(char *s,int l))(my_term_ftablep->change_term_p)))(s,l);
}

#if 0
static struct termentry dummy_term_tbl[] = {
    {"unknown", "Unknown terminal type - not a plotting device",
	  100, 100, 1, 1,
	  1, 1, UNKNOWN_null, UNKNOWN_null, UNKNOWN_null,
	  UNKNOWN_null, UNKNOWN_null, UNKNOWN_null, UNKNOWN_null, UNKNOWN_null,
	  UNKNOWN_null, UNKNOWN_null, UNKNOWN_null,
     UNKNOWN_null, UNKNOWN_null, UNKNOWN_null, UNKNOWN_null, UNKNOWN_null, 0,
	  UNKNOWN_null, UNKNOWN_null, UNKNOWN_null, UNKNOWN_null},
};
#endif

#define set_term_funcp(change_p, term_p) set_term_funcp2((change_p), 0)
/* #define set_term_funcp3(change_p, term_p, tchange) \
			set_term_funcp2((change_p), (tchange)) */

/* This function should be called before any graphic code can be used... */
void
set_term_funcp2(FUNC_PTR change_p, TSET_FP tchange)
{
    SET_OUTFILE;
    my_term_ftable.change_term_p = change_p;
    my_term_ftable.loaded = 1;
    if (tchange) {
	my_term_ftable.term_set_outputp = tchange;
    }
}

/* Used from Math::Pari */
void
set_term_funcp3(FUNC_PTR change_p, void *term_p, TSET_FP tchange)
{
  (void)term_p;
  set_term_funcp2(change_p, tchange);
}

void
set_term_ftable(struct t_ftable *p)
{
  SET_OUTFILE;
  my_term_ftablep = p;
}

extern struct t_ftable *get_term_ftable();

#define options() run_do_options()

#else /* !DYNAMIC_PLOTTING */

#define set_mouse_feedback_rectangle  mys_mouse_feedback_rectangle
#define my_setup_exe_path setup_exe_paths
extern void setup_exe_paths(char *path);

#define options()	t_options()

extern int my_set_output_routines(OUTPUT_FUNC_t *func);
extern OUTPUT_FUNC_t * my_get_output_routines(void);
#define set_output_routines		my_set_output_routines
#define get_output_routines		my_get_output_routines
#define get_terms			my_get_terms

extern int my_get_terms(int n, const char **namep, const char **descrp);

extern struct termentry term_tbl[];
extern double min_array[], max_array[];
extern int xleft, xright, ybot, ytop;

extern void mys_mouse_feedback_rectangle(int term_xmin, int term_xmax, 
			     int term_ymin, int term_ymax,
			     double plot_xmin, double plot_xmax,
			     double plot_ymin, double plot_ymax);

#ifndef GNUPLOT_NO_CODE_EMIT
void
mys_mouse_feedback_rectangle(int term_xmin, int term_xmax, 
			     int term_ymin, int term_ymax,
			     double plot_xmin, double plot_xmax,
			     double plot_ymin, double plot_ymax)
{
#ifdef DEFINE_GP4MOUSE
	gp4mouse.xleft  = term_xmin;
	gp4mouse.xright = term_xmax;
	gp4mouse.ybot   = term_ymin;
	gp4mouse.ytop   = term_ymax;
	gp4mouse.xmin   = plot_xmin;
	gp4mouse.xmax   = plot_xmax;
	gp4mouse.ymin   = plot_ymin;
	gp4mouse.ymax   = plot_ymax;
	gp4mouse.is_log_x = 0;
	gp4mouse.is_log_y = 0;
	gp4mouse.log_base_log_x = 10;
	gp4mouse.log_base_log_y = 10;
	gp4mouse.graph  = graph2d;
#endif
}
#endif /* !GNUPLOT_NO_CODE_EMIT */

#  define my_change_term	change_term
#  define my_term_tbl		term_tbl

extern void term_set_output(char *s);
extern void term_start_plot(void);
extern void term_end_plot(void);
extern void term_start_multiplot(void);
extern void term_end_multiplot(void);
extern void term_init(void);
extern void list_terms(void);
extern int  term_count(void);

extern void plotsizes_scale(double x, double y);
extern double plotsizes_get(int flag);

extern DO_OUTPUT_LINE_t output_line_p;

#ifndef GNUPLOT_NO_CODE_EMIT
void
plotsizes_scale(double x, double y)	{ xsize=x; ysize=y; }

double
plotsizes_get(int flag)	{ return (flag ? ysize : xsize); }

static void
my_do_options(struct lexical_unit *toks, int ntoks, char *s)
{
  int i = -1;
  char *ol = input_line;

  num_tokens = ntoks;
  while (++i < MAX_TOKENS)
    tokens[i] = toks[i];
  c_token = 0;
  input_line = s;
  options();
  input_line = ol;
}

OUTPUT_FUNC_t output_functions;

#define OUTPUT_FUNCTIONS(field) (output_functions.field)

int
my_set_output_routines(OUTPUT_FUNC_t *f)
{
  if (f->start_output_fun)
	output_functions.start_output_fun = f->start_output_fun;
  if (f->end_output_fun)
	output_functions.end_output_fun = f->end_output_fun;
  if (f->output_line_fun)
	output_functions.output_line_fun = f->output_line_fun;
  return 1;
}

OUTPUT_FUNC_t *
my_get_output_routines(void)
{
  return(&output_functions);
}

struct t_ftable my_term_ftable =
{
	/* bits 0x2: has mys_mouse_feedback_rectangle;
		0x4: setup_exe_path
		0x8: do_options & [gs]et_output_routines & get_terms */
	0x2 | 0x4 | 0x08,
	(FUNC_PTR)&change_term, &term_set_output,
	&plotsizes_scale, &plotsizes_get,
	{&term_start_plot, &term_end_plot, 
	 &term_start_multiplot, &term_end_multiplot, &term_init, &list_terms},
	&mys_mouse_feedback_rectangle, &setup_exe_paths,
	&my_do_options,	&my_set_output_routines, &my_get_output_routines,
	&my_get_terms
};

int
my_get_terms(int n, const char **namep, const char **descrp)
{
  int termc;

  if (n < 0) return 0;
  termc = term_count();
  if (n >= termc) return 0;
  *namep = term_tbl[n].name;
  *descrp = term_tbl[n].description;
  return 1;
}

struct t_ftable *get_term_ftable()	{ SET_OUTFILE; return &my_term_ftable; }
void set_term_ftable()	{ SET_OUTFILE; }

void
set_term_funcp3(FUNC_PTR change_p, void *term_p, TSET_FP tchange)
{
    SET_OUTFILE;
    (void)term_p;
    my_term_ftable.change_term_p = change_p;
    my_term_ftable.loaded = 1;
    if (tchange) {
	my_term_ftable.term_set_outputp = tchange;
    }
}
#endif /* !GNUPLOT_NO_CODE_EMIT */

#define scaled_xmax()	((int)termprop(xmax)*xsize)
#define scaled_ymax()	((int)termprop(ymax)*ysize)

#endif /* !DYNAMIC_PLOTTING */

#define int_get_term_ftable()	((IV)get_term_ftable())
#define int_set_term_ftable(a) (v_set_term_ftable((void*)a))

#ifndef GNUPLOT_NO_CODE_EMIT
void
v_set_term_ftable(void *a) { set_term_ftable((struct t_ftable*)a); }

#endif /* !GNUPLOT_NO_CODE_EMIT */

typedef void (*set_term_ftable_t)(struct t_ftable *p);
typedef struct t_ftable *(get_term_ftable_t)(void);

extern get_term_ftable_t *get_term_ftable_get(void);

#ifndef GNUPLOT_NO_CODE_EMIT
static int shim_set;

void
setup_gpshim(void) {
#if 0
  if (shim_set++)
    return;
#endif

  if (!shim_set++) {
#ifdef DYNAMIC_PLOTTING_RUNTIME_LINK
    get_term_ftable_t *f = get_term_ftable_get(); /* Resolve the getter */

    if (f)
	v_set_term_ftable(f());			/* Get the external table */
#endif

#ifdef DYNAMIC_PLOTTING_STATIC_LINK
    void *a = get_term_ftable();		/* Get the external one */
    v_set_term_ftable(get_term_ftable());
#endif
  }
  SET_OUTFILE;
}
#endif /* !GNUPLOT_NO_CODE_EMIT */

#ifdef SET_OPTIONS_FROM_STRING
/* This sets the tokens for the options */
void
set_tokens_string(char *start)
{
    char *s = start;
    char *tstart;
    int is_real, is_integer, is_string, has_exp;
    
    num_tokens = 0;
    while (num_tokens < MAX_TOKENS) {
	while (*s == ' ' || *s == '\t' || *s == '\n')
	    s++;
	if (!*s)
	    return;
	tstart = s;
	if (*s == ',') {
	    s++;
	    is_integer = is_real = 0;
	    goto process;
	}
	is_string = ((*tstart == '"') || (*tstart == '\''));
	is_integer = is_real = (((*s) != 0) && !is_string);
	if (is_string)
	    s += 2;
	else if (*s == '+' || *s == '-')
	    s++;
	has_exp = 0;
	while ( *s &&
		(is_string
		 ? (s[-1] != *tstart)
		 : !(*s == ' ' || *s == '\t' || *s == '\n')) ) {
	    if (is_string) /* DO NOTHING */;
	    else if (!(*s <= '9' && *s >= '0')) {
		if (*s == '.') {		
		    if (!is_integer)
			is_real = 0;
		    else if (is_integer == 1 && !(s[1] <= '9' && s[1] >= '0'))
			is_real = 0;
		} else if (*s == 'e' || *s == 'E') {
		    if (has_exp)
			is_real = 0;
		    has_exp = 1;
		    if (s[1] == '+' || s[1] == '-')
			s++;
		} else if (*s == ',' && (is_integer || is_real))
		    break;
		else
		    is_real = 0;
		is_integer = 0;
	    } else if (is_integer)
		is_integer++;
	    s++;	    
	}
      process:
	token[num_tokens].start_index = tstart - input_line;
	token[num_tokens].length = s - tstart;
	if (is_integer) {
	    token[num_tokens].is_token = 0;
	    token[num_tokens].l_val.type = INTGR;
	    token[num_tokens].l_val.v.int_val = atoi(tstart);
	} else if (is_real) {
	    token[num_tokens].is_token = 0;
	    token[num_tokens].l_val.type = CMPLX;
	    token[num_tokens].l_val.v.cmplx_val.real = atof(tstart);
	    token[num_tokens].l_val.v.cmplx_val.imag = 0;
	} else {
	    token[num_tokens].is_token = 1;
/* printf("Token `%.*s'\n", token[num_tokens].length, input_line + token[num_tokens].start_index); */
	}
	num_tokens++;
    }
    if (num_tokens >= MAX_TOKENS) {
	char buf[80];
	sprintf(buf, "panic: more than %d tokens for options", MAX_TOKENS);
	croak(buf);    
    }
}

void
set_options_from(char *s)
{
    char *o = input_line;

    input_line = s;		/* for error reports */
    set_tokens_string(s);
    options();
    input_line = o;
    c_token = num_tokens = 0;
}
#endif

#ifdef GNUPLOT_OUTLINE_STDOUT

int
StartOutput() {
#ifdef OUTPUT_FUNCTIONS
  if (output_functions.start_output_fun)
	return( (output_functions.start_output_fun)() );
#endif
  return 0;
}

int
EndOutput() {
#ifdef OUTPUT_FUNCTIONS
  if (output_functions.end_output_fun)
	return( (output_functions.end_output_fun)() );
#endif
  return 0;
}

int
OutLine(char *s)
{
#ifdef OUTPUT_FUNCTIONS
  if (output_functions.output_line_fun)
	return( (output_functions.output_line_fun)(s) );
#endif
   return fprintf(stdout, "%s", s);
}
#endif

#ifdef __cplusplus
  }
#endif
