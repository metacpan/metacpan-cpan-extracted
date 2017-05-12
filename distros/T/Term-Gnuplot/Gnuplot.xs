#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef newSVpvn			/* 5.005_62 or so */
#  define newSVpvn newSVpv
#endif

#ifdef USE_ACTIVE_EVENTS
#  define DEFINE_GP4MOUSE
#  include "mousing.h"
#endif

#define DONT_POLLUTE_INIT
#define GNUPLOT_NO_CODE_EMIT
#include "Gnuplot.h"



#define change_term_address() ((IV)&change_term)
/* #define term_tbl_address() ((IV)term_tbl) */  /* Not used any more */
#define term_tbl_address() 0

/* #define set_gnuplot_fh(file) (outfile = PerlIO_exportFILE(file,0)) */

#define int_change_term(s,l) (change_term(s,l) != 0)
typedef PerlIO *OutputStream;

/* This sets the tokens for the options */
static void
set_tokens(SV **svp, int n, SV* acc)
{
    int tk = 0;

    c_token = 0;
    num_tokens = n;
    if (num_tokens > MAX_TOKENS) {
	char buf[80];
	sprintf(buf, "panic: more than %d tokens for options: %d",
		MAX_TOKENS, num_tokens);
	croak(buf);
    }
    while (num_tokens > tk) {
	SV *elt = *svp++;
	char buf[80];

	sv_catpvn(acc, " ", 1);
        token[tk].start_index = SvCUR(acc);
	if (SvIOKp(elt)) {
	    token[tk].is_token = 0;
	    token[tk].l_val.type = INTGR;
	    token[tk].l_val.v.int_val = SvIV(elt);
	    sprintf(buf, "%d", SvIV(elt));
	    sv_catpv(acc, buf);
	    token[tk].length = strlen(buf);
	} else if (SvNOKp(elt)) {
	    token[tk].is_token = 0;
	    token[tk].l_val.type = CMPLX;
	    token[tk].l_val.v.cmplx_val.real = SvNV(elt);
	    token[tk].l_val.v.cmplx_val.imag = 0;
	    sprintf(buf, "%g", SvNV(elt));
	    sv_catpv(acc, buf);
	    token[tk].length = strlen(buf);
	} else {
	    token[tk].is_token = 1;
	    token[tk].length = SvCUR(elt);
	    sv_catsv(acc, elt);
	}
	tk++;
    }
}

void
set_options(SV **svp, int n)
{
    SV *sv = newSVpvn("", 0);	/* For error reporting in options() only */

    sv_2mortal(sv);
    set_tokens(svp,n,sv);
    input_line = SvPVX(sv);
    options();
    input_line = Nullch;
    c_token = num_tokens = 0;
}

long
plot_outfile_set(char *s) { 
    int normal = (strcmp(s,"-") == 0);

    /* Delegate all the hard work to term_set_output() */

    if (normal) 
	term_set_output(NULL);
    else {	/* term_set_output() needs a malloced string */
	static char *last_s;
	char *s1 = (char*) malloc(strlen(s) + 1);
        int do_free = 0;

	if (outstr == last_s)
	    do_free = 1;
	strcpy(s1,s);
	term_set_output(s1);
	if (do_free && outstr != last_s && 0)
	    free(last_s);
	last_s = s1;
    }
    return 1; 
}

/* TK Canvas directdraw */

static SV *canvas;
static int ptk_init = 0;
static int xborder;
static int yborder;
static SV *fontsv;

static void
do_init()
{
    if (!canvas || !SvROK(canvas) || !SvOBJECT(SvRV(canvas)))
	croak("setcanvas should be set before a call to option()!");
    ptk_init = 1;
    fontsv = newSVpv("",0);
    SvOK_off(fontsv);
}

static void
pTK_setcanvas( SV *sv )
{
    SvREFCNT_dec(canvas);
    canvas = SvREFCNT_inc(sv);
}

#define CANVAS_PARAMETERS	8

void
pTK_getsizes( int arr[CANVAS_PARAMETERS] )
{
    /*
     * takes the actual width and height
     * of the defined canvas
     * => NOTE: this makes 'set size' useless !!!
     * unless the original width and height is taken into account
     * by some tcl or perl code, that's why the 'gnuplot_plotarea' and
     * 'gnuplot_axisranges' procedures are supplied.
     */
    dSP ;
    int count ;
    SV *arg = sv_newmortal();
    static char *types[] = { "width", "height", "border" };
    int i;

    if (!ptk_init)
	do_init();

    ENTER ;
    SAVETMPS;

    EXTEND(SP,3);
#if 1
    PUSHMARK(SP) ;
    PUSHs(canvas);
    PUTBACK ;

    count = perl_call_pv("Term::Gnuplot::canvas_sizes", G_ARRAY);

    SPAGAIN ;

    if (count != CANVAS_PARAMETERS)
	croak("graphics: error in getting canvas parameters") ;

    i = CANVAS_PARAMETERS;
    while (--i >= 0)
	arr[i] = POPi ;
    xborder = arr[2];
    yborder = arr[3];
    PUTBACK ;
#else
    for (i = 0; i < sizeof(types)/sizeof(char*); i++) {
	PUSHMARK(SP) ;
	PUSHs(canvas);
	sv_setpv(arg, types[i]);
	PUSHs(arg);
	PUTBACK ;

	count = perl_call_method(i < 2 ? "winfo" : "cget", G_SCALAR);

	SPAGAIN ;

	if (count != 1)
	    croak("graphics: error in cget") ;

	arr[i] = POPi ;
	PUTBACK ;
    }
#endif
    FREETMPS ;
    LEAVE ;
}

SV *
pTK_putline( unsigned int px, unsigned int py, unsigned int x,
	     unsigned int y, char *color, double w )
{
    /*
     * takes the actual width and height
     * of the defined canvas
     * => NOTE: this makes 'set size' useless !!!
     * unless the original width and height is taken into account
     * by some tcl or perl code, that's why the 'gnuplot_plotarea' and
     * 'gnuplot_axisranges' procedures are supplied.
     */
    dSP ;
    SV *ret;
    I32 count;

    ENTER ;
    SAVETMPS;

    EXTEND(SP,11);			/* 10 args */
    PUSHMARK(SP) ;
    PUSHs(canvas);
    PUSHs(sv_2mortal(newSViv(px + xborder + 1))); /* Tested: +1 needed */
    PUSHs(sv_2mortal(newSViv(py + yborder))); /* Likewise */
    PUSHs(sv_2mortal(newSViv(x + xborder + 1)));
    PUSHs(sv_2mortal(newSViv(y + yborder)));
    PUSHs(sv_2mortal(newSVpv("-fill", 5)));
    PUSHs(sv_2mortal(newSVpv(color, 0)));
    PUSHs(sv_2mortal(newSVpv("-width", 6)));
    PUSHs(sv_2mortal(newSVnv(w)));
    PUSHs(sv_2mortal(newSVpv("-capstyle", 9)));
    PUSHs(sv_2mortal(newSVpv("round", 5)));
    PUTBACK ;

    count = perl_call_method("createLine", G_SCALAR);

    SPAGAIN ;

    if (count != 1)
	croak("vector: error in createLine") ;

    ret = SvREFCNT_inc(POPs) ;
    PUTBACK ;
    FREETMPS ;
    LEAVE ;
    SvREFCNT_dec(ret);
    return ret;
}

void
pTK_puttext( unsigned int x, unsigned int y, char *s, char *color, char *anchor)
{
    dSP ;
    ENTER ;
    SAVETMPS;

    EXTEND(SP,11);			/* 10 args */
    PUSHMARK(SP) ;
    PUSHs(canvas);
    PUSHs(sv_2mortal(newSViv(x + xborder + 1)));
    PUSHs(sv_2mortal(newSViv(y + yborder)));
    PUSHs(sv_2mortal(newSVpv("-text", 5)));
    PUSHs(sv_2mortal(newSVpv(s, 0)));
    PUSHs(sv_2mortal(newSVpv("-fill", 5)));
    PUSHs(sv_2mortal(newSVpv(color, 0)));
    PUSHs(sv_2mortal(newSVpv("-anchor", 7)));
    PUSHs(sv_2mortal(newSVpv(anchor, 0)));
    if (SvOK(fontsv)) {
	PUSHs(sv_2mortal(newSVpv("-font", 5)));
	PUSHs(fontsv);
    }
    PUTBACK ;

    perl_call_method("createText", G_SCALAR | G_DISCARD);

    FREETMPS ;
    LEAVE ;
}

void
pTK_setfont( char *font )
{
    if (font && *font)
	sv_setpv(fontsv, font);
    else
	SvOK_off(fontsv);
}

static SV* tmp_output_sv;
int no_start_end_out(void) {return 1;}
int tmp_output_line(char *s) { sv_catpv(tmp_output_sv, s); return 1;}

static OUTPUT_FUNC_t tmp_output_f
    = {&no_start_end_out, &no_start_end_out, &tmp_output_line};

static SV *
my_list_terms(void)
{
    OUTPUT_FUNC_t old;
    OUTPUT_FUNC_t *oldp = get_output_routines();

    old = *oldp;
    if (!set_output_routines(&tmp_output_f))
	croak("Cannot reset output routines to copy term list to a variable");
#if 0			/* We mortalize it now */
    if (tmp_output_sv)
	SvREFCNT_dec(tmp_output_sv);
#endif
    tmp_output_sv = newSVpvn("", 0);
    list_terms();
    if (!set_output_routines(&old))
	warn("Cannot reset output routines back; expect problems...");
    return tmp_output_sv;
}

#define make_gray_palette	make_palette
#define filled_polygon_raw	filled_polygon
#define _term_start_plot	term_start_plot
#define _justify_text		justify_text
#define _text_angle		text_angle

MODULE = Term::Gnuplot		PACKAGE = Term::Gnuplot		PREFIX = pTK_

void
pTK_setcanvas( sv )
    SV *sv

MODULE = Term::Gnuplot		PACKAGE = Term::Gnuplot		PREFIX = int_

long
plot_outfile_set(s)
    char *s

IV
change_term_address()

IV
term_tbl_address()

int
test_term()

void
list_terms()

void
_term_start_plot()

void
term_end_plot()

void
term_start_multiplot()

void
term_end_multiplot()

void
term_init()

int
int_change_term(name,length=strlen(name))
char *	name
int	length

IV
int_get_term_ftable()

void
int_set_term_ftable(a)
	IV a

int
init_terminal()

# set_term is unsupported without junk

MODULE = Term::Gnuplot	PACKAGE = Term::Gnuplot  PREFIX=gptable_

void
gptable_init()

MODULE = Term::Gnuplot	PACKAGE = Term::Gnuplot

void
reset()

void
text()

void
graphics()

void
set_options(...)
    CODE:
    {
	set_options(&(ST(0)),items);
    }

void
linetype(lt)
     int	lt

int
_justify_text(mode)
     int	mode

int
_text_angle(ang)
     int	ang

int
scale(xs,ys)
     double	xs
     double	ys

void
move(x,y)
     unsigned int	x
     unsigned int	y

void
vector(x,y)
     unsigned int	x
     unsigned int	y

void
put_text(x,y,str)
     int	x
     int	y
     char *	str

void
point(x,y,point)
     unsigned int	x
     unsigned int	y
     int	point

void
arrow(sx,sy,ex,ey,head)
     int	sx
     int	sy
     int	ex
     int	ey
     int	head

void
resume()

void
suspend()

void
linewidth(w)
    double w

void
setpointsize(w)
    double w

int
set_font(s)
    char *s

void
fillbox(sx,sy,ex,ey,head)
     int	sx
     unsigned int	sy
     unsigned int	ex
     unsigned int	ey
     unsigned int	head

void
getdata()
   PPCODE:
    {
      if (!term) {
	croak("No terminal specified");
      }
      EXTEND(SP, 8);
      PUSHs(sv_2mortal(newSVpv(term->name,0)));
      PUSHs(sv_2mortal(newSVpv(term->description,0)));
      PUSHs(sv_2mortal(newSViv(term->xmax)));
      PUSHs(sv_2mortal(newSViv(term->ymax)));
      PUSHs(sv_2mortal(newSViv(term->v_char)));
      PUSHs(sv_2mortal(newSViv(term->h_char)));
      PUSHs(sv_2mortal(newSViv(term->v_tic)));
      PUSHs(sv_2mortal(newSViv(term->h_tic)));
    }

bool
cannot_multiplot()

bool
can_multiplot()

bool
is_binary()

void
plotsizes_scale(x,y)
    double x
    double y

double
scaled_xmax()

double
scaled_ymax()

SV*
_term_descrs()
    PPCODE:
    {
	int c = term_count(), i;
	
	EXTEND(SP, 2*c);
	for (i = 0; i < c; i++) {
	    PUSHs(sv_2mortal(newSVpv(term_tbl[i].name,0)));
	    PUSHs(sv_2mortal(newSVpv(term_tbl[i].description,0)));
	}
    }

int
term_count()

void
get_terms(int n)
    PPCODE:
    {
	const char *name, *descr;

	if (!get_terms(n, &name, &descr))
	    XSRETURN_EMPTY;
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSVpv(name,0)));
	PUSHs(sv_2mortal(newSVpv(descr,0)));
    }

BOOT:
    setup_gpshim();
    plot_outfile_set("-");
#ifdef PM3D
    init_color();
#endif

void
setup_exe_paths(path)
	char *path

SV *
my_list_terms()

#ifdef PM3D

int
term_make_palette(palette = (char*)&sm_palette)
	char *palette

int
make_gray_palette()

void
previous_palette()

void
set_color(gray)
	double gray

void
filled_polygon_raw(points, corners)
	int points
	char *corners

#endif

#ifdef USE_ACTIVE_EVENTS____NOT_NEEDED

void
enable_mousetracking()

#endif

#ifdef USE_ACTIVE_EVENTS

void
set_mouse_feedback_rectangle(term_xmin, term_xmax, term_ymin, term_ymax, plot_xmin, plot_xmax, plot_ymin, plot_ymax)
	int term_xmin
	int term_xmax
	int term_ymin
	int term_ymax
	double plot_xmin
	double plot_xmax
	double plot_ymin
	double plot_ymax

#endif
