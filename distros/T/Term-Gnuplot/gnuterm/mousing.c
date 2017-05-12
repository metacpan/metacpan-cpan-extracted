/*  mousing.c

Version 25. 10. 1999

This unit is #included by a mouse capable terminal; currently used by
  - os2/gclient
  - gplt_x11.c
It implements the common structures and routines for mousing, like 
zooming etc.

*/


#include "mousing.h"


/************************************************************************
		DECLARATIONS
************************************************************************/


/* which mouse coordinates:
	- real (coords of x1, y1 axes in gnuplot)
	- pixels (relative to the terminal window in pixels)
	- screen (relative to the terminal window normalized to (0..1,0..1))
	- x axis is date or time
*/
#define   MOUSE_COORDINATES_REAL	0
#define   MOUSE_COORDINATES_PIXELS	1
#define   MOUSE_COORDINATES_SCREEN	2
#define   MOUSE_COORDINATES_XDATE	3
#define   MOUSE_COORDINATES_XTIME	4
#define   MOUSE_COORDINATES_XDATETIME	5

/* useMouse is set to 1 when user switches mousing on, e.g. the mouse is 
   allowed
*/
static int useMouse = 0;


/* mousePolarDistance is set to 1 if user wants to see the distance between
   the ruler and mouse pointer in polar coordinates too (otherwise, distance 
   in cartesian coordinates only is shown)
*/
static int mousePolarDistance = 0;


static long mouse_mode = MOUSE_COORDINATES_REAL;

/* gnuplot's PM terminal sends 'm' message from its init routine, which
   sets the variable below to 1. Then we are sure that we talk to the
   mouseable terminal and can read the mouseable data from the pipe. 
   Non-mouseable versions of PM terminal or non-new-gnuplot programs 
   using gnupmdrv will let this variable set to 0, thus no mousing occurs.
*/
static char mouseTerminal = 0;


/* Lock (hide) mouse when building the plot (redrawing screen).
   Otherwise gnupmdrv would crash when trying to display mouse position
   in a window not yet plotted.
*/
static char lock_mouse = 1;


#ifndef GNUPMDRV /* gnupmdrv: they are available as menu items */
const  char *( MouseCoordinatesHelpStrings[] ) = {
		"real", "pixels", "screen", "x date / y real",
		"x time / y real", "x date+time / y real"
		 };
#endif


/* formats for saving the mouse position into clipboard / print to screen
   (double click of mouse button 1).
   Important: do not change this unless you update the appropriate items 
   in os2/gnupmdrv.rc
*/
#ifndef GNUPMDRV
int mouseSprintfFormat = 1;
#endif
const  int	nMouseSprintfFormats = IDM_MOUSE_FORMAT_LABEL - IDM_MOUSE_FORMAT;
const  char  *( MouseSprintfFormats[ /*nMouseSprintfFormats*/ ] ) = {
		"%g %g","%g,%g","%g;%g",
		"%g,%g,","%g,%g;",
		"[%g:%g]","[%g,%g]","[%g;%g]",
		"set label \"\" at %g,%g"
		 };

/* Zoom queue
*/
struct t_zoom {
  double xmin, ymin, xmax, ymax;
  struct t_zoom *prev, *next;
};

struct t_zoom *zoom_head = NULL,
	      *zoom_now = NULL;


/* Structure for the ruler: on/off, position,...
*/
static struct {
   int on;
   double x, y;  /* ruler position in real units of the graph */
   long px, py;  /* ruler position in the viewport units */
} ruler;


#ifdef OS2
char mouseShareMemName[40];
PVOID input_from_PM_Terminal;
  /* pointer to shared memory for storing the command to be executed */
HEV semInputReady = 0;
  /* handle to event semaphore (post an event to gnuplot that the shared 
     memory contains a command to be executed) */
int pausing = 0;
  /* avoid passing data back to gnuplot in `pause' mode */
#ifdef GNUPMDRV
  extern ULONG ppidGnu;
#else
  ULONG ppidGnu = 0;
#endif
#endif



/************************************************************************
		DECLARATION OF ROUTINES
************************************************************************/

#define OK fprintf(stderr,"LINE %3i in file %s is OK\n",(int)__LINE__,__FILE__);

#ifdef OS2
#define __PROTO(x) x
#endif

/* a debugging routine
*/
void MouseDebugShow_gp4mouse __PROTO((void));


/* main job of transformation, which is not device dependent
*/
void MousePosToGraphPosReal __PROTO(( double *x, double *y ));


/* formats the information for an annotation (middle mouse button clicked)
*/
void GetAnnotateString __PROTO(( char *s, double x, double y, int mouse_mode ));


/* Format x according to the date/time mouse mode. Uses and returns b as
   a buffer
*/
char* xDateTimeFormat __PROTO(( double x, char* b ));


/* formats the ruler information (position, distance,...) into string p
	(it must be sufficiently long)
   x, y is the current mouse position in real coords (for the calculation 
	of distance)
*/
void GetRulerString __PROTO(( char *p, double x, double y ));


/* Ruler is on, thus recalc its (px,py) from (x,y) for the current zoom and 
   log axes. Called after a new plot or zoom
*/
void recalc_ruler_pos __PROTO((void));


/* makes a zoom: update zoom history, call gnuplot to set ranges + replot
*/
void do_zoom __PROTO(( double xmin, double ymin, double xmax, double ymax ));


/* Applies the zoom rectangle of  z  by sending the appropriate command
   to gnuplot
*/
void apply_zoom __PROTO(( struct t_zoom *z ));


/* send command (e.g. "set log y; replot") to gnuplot 
*/
void gp_execute __PROTO((char *command));


/************************************************************************
		IMPLEMENTATION OF ROUTINES
************************************************************************/


#if 1
/* a debugging routine
*/
void MouseDebugShow_gp4mouse __PROTO((void))
{
fprintf(stderr,"gp4mouse: xmin=%g, ymin=%g, xmax=%g, ymax=%g\n",gp4mouse.xmin,gp4mouse.ymin,gp4mouse.xmax,gp4mouse.ymax);
fprintf(stderr,"gp4mouse: xleft=%i, ybot=%i, xright=%i, ytop=%i\n", gp4mouse.xleft,gp4mouse.ybot,gp4mouse.xright,gp4mouse.ytop);
/* 
	int is_log_x, is_log_y; 
	double base_log_x, base_log_y
	double log_base_log_x, log_base_log_y
*/
}
#endif

/* main job of transformation, which is not device dependent
*/
void MousePosToGraphPosReal ( double *x, double *y )
{
  if (gp4mouse.xright==gp4mouse.xleft) *x = 1e38; else /* protection */
  *x = gp4mouse.xmin + (*x-gp4mouse.xleft) / (gp4mouse.xright-gp4mouse.xleft)
	      * (gp4mouse.xmax-gp4mouse.xmin);
  if (gp4mouse.ytop==gp4mouse.ybot) *y = 1e38; else /* protection */
  *y = gp4mouse.ymin + (*y-gp4mouse.ybot) / (gp4mouse.ytop-gp4mouse.ybot)
	      * (gp4mouse.ymax-gp4mouse.ymin);
  /*
    Note: there is xleft+0.5 in "#define map_x" in graphics.c, which
    makes no major impact here. It seems that the mistake of the real
    coordinate is at about 0.5%, which corresponds to the screen resolution.
    It would be better to round the distance to this resolution, and thus
    *x = gp4mouse.xmin + rounded-to-screen-resolution (xdistance)
  */

  /* Now take into account possible log scales of x and y axes */
  if  (gp4mouse.is_log_x) *x = exp( *x * gp4mouse.log_base_log_x );
  if  (gp4mouse.is_log_y) *y = exp( *y * gp4mouse.log_base_log_y );
}


/* formats the ruler information (position, distance,...) into string p
	(it must be sufficiently long)
   x, y is the current mouse position in real coords (for the calculation 
	of distance)
*/
void GetRulerString ( char *p, double x, double y )
{
  if (mouse_mode != MOUSE_COORDINATES_REAL) {
      /* distance makes no sense */
      sprintf(p,"  ruler: [%g, %g]", ruler.x,ruler.y);
    }
    else {
      double dx, dy;
      if (gp4mouse.is_log_x) /* ratio for log, distance for linear */
	  dx = (ruler.x==0) ? 99999 : x / ruler.x;
        else
	  dx = x - ruler.x;
      if (gp4mouse.is_log_y)
	  dy = (ruler.y==0) ? 99999 : y / ruler.y;
	else
	  dy = y - ruler.y;
      sprintf(p,"  ruler: [%g, %g]  distance: %g, %g",ruler.x,ruler.y,dx,dy);
      if (mousePolarDistance && !gp4mouse.is_log_x && !gp4mouse.is_log_y) {
	/* polar coords of distance (axes cannot be logarithmic) */
	double rho = sqrt( (x-ruler.x)*(x-ruler.x) + (y-ruler.y)*(y-ruler.y) );
	double phi = (180/M_PI) * atan2(y-ruler.y,x-ruler.x);
	char ptmp[69];
#ifdef GNUPMDRV
	sprintf(ptmp," (%g;%.4gø)", rho,phi);
#else
	sprintf(ptmp," (%g, %.4gdeg)", rho,phi);
#endif
	strcat(p,ptmp);
      }
  }
}


/* formats the information for an annotation (middle mouse button clicked)
*/
void GetAnnotateString ( char *s, double x, double y, int mouse_mode )
{
    if (mouse_mode==MOUSE_COORDINATES_XDATE ||
	mouse_mode==MOUSE_COORDINATES_XTIME ||
	mouse_mode==MOUSE_COORDINATES_XDATETIME) { /* time is on the x axis */
	char buf[100];
	sprintf(s, "[%s, %g]", xDateTimeFormat(x,buf), y);
    } else {
	sprintf(s,"[%g, %g]",x,y); /* usual x,y values */
    }
}


/* Format x according to the date/time mouse mode. Uses and returns b as
   a buffer
*/
char* xDateTimeFormat ( double x, char* b )
{
#ifndef SEC_OFFS_SYS
#define SEC_OFFS_SYS 946684800
#endif
time_t xtime_position = SEC_OFFS_SYS + x;
struct tm *pxtime_position = gmtime(&xtime_position);
switch (mouse_mode) {
  case MOUSE_COORDINATES_XDATE:
	sprintf(b,"%d. %d. %04d",
		pxtime_position->tm_mday,
		(pxtime_position->tm_mon)+1,
#if 1
		(pxtime_position->tm_year) +
		  ((pxtime_position->tm_year <= 68) ? 2000 : 1900)
#else
		((pxtime_position->tm_year)<100) ?
		  (pxtime_position->tm_year) : (pxtime_position->tm_year)-100
/*              (pxtime_position->tm_year)+1900 */
#endif
		);
	break;
  case MOUSE_COORDINATES_XTIME:
	sprintf(b,"%d:%02d", pxtime_position->tm_hour, pxtime_position->tm_min);
	break;
  case MOUSE_COORDINATES_XDATETIME:
	sprintf(b,"%d. %d. %04d %d:%02d",
		pxtime_position->tm_mday,
		(pxtime_position->tm_mon)+1,
#if 1
		(pxtime_position->tm_year) +
		  ((pxtime_position->tm_year <= 68) ? 2000 : 1900),
#else
		((pxtime_position->tm_year)<100) ?
		  (pxtime_position->tm_year) : (pxtime_position->tm_year)-100,
/*              (pxtime_position->tm_year)+1900, */
#endif
		pxtime_position->tm_hour,
		pxtime_position->tm_min
		);
	break;
  default: sprintf(b, "%g", x);
  }
return b;
}


/* Ruler is on, thus recalc its (px,py) from (x,y) for the current zoom and 
   log axes. Called after a new plot or zoom
*/
void recalc_ruler_pos (void)
{
double P;
if (gp4mouse.is_log_x && ruler.x<0)
    ruler.px = -1;
  else {
    P = gp4mouse.is_log_x ?
	  log(ruler.x) / gp4mouse.log_base_log_x
	  : ruler.x;
    P = (P-gp4mouse.xmin) / (gp4mouse.xmax-gp4mouse.xmin);
    P *= gp4mouse.xright-gp4mouse.xleft;
    ruler.px = (long)( gp4mouse.xleft + P );
    }
if (gp4mouse.is_log_y && ruler.y<0)
    ruler.py = -1;
  else {
    P = gp4mouse.is_log_y ?
	  log(ruler.y) / gp4mouse.log_base_log_y
	  : ruler.y;
    P = (P-gp4mouse.ymin) / (gp4mouse.ymax-gp4mouse.ymin);
    P *= gp4mouse.ytop-gp4mouse.ybot;
    ruler.py = (long)( gp4mouse.ybot + P );
    }
}


/* makes a zoom: update zoom history, call gnuplot to set ranges + replot
*/

void do_zoom ( double xmin, double ymin, double xmax, double ymax )
{
struct t_zoom *z;
if (zoom_head == NULL) { /* queue not yet created, thus make its head */
    zoom_head = malloc( sizeof(struct t_zoom) );
    zoom_head->prev = NULL;
    zoom_head->next = NULL;
    }
if (zoom_now == NULL) zoom_now = zoom_head;
if (zoom_now->next == NULL) { /* allocate new item */
    z = malloc( sizeof(struct t_zoom) );
    z->prev = zoom_now;
    z->next = NULL;
    zoom_now->next = z;
    z->prev = zoom_now;
} else /* overwrite next item */
    z = zoom_now->next;
z->xmin = xmin; z->ymin = ymin;
z->xmax = xmax; z->ymax = ymax;
apply_zoom( z );
}


/* Applies the zoom rectangle of  z  by sending the appropriate command
   to gnuplot
*/
void apply_zoom ( struct t_zoom *z )
{
char s[255];
if (zoom_now != NULL) { /* remember the current zoom */
  zoom_now->xmin = (!gp4mouse.is_log_x) ? gp4mouse.xmin : exp( gp4mouse.xmin * gp4mouse.log_base_log_x );
  zoom_now->ymin = (!gp4mouse.is_log_y) ? gp4mouse.ymin : exp( gp4mouse.ymin * gp4mouse.log_base_log_y );
  zoom_now->xmax = (!gp4mouse.is_log_x) ? gp4mouse.xmax : exp( gp4mouse.xmax * gp4mouse.log_base_log_x );
  zoom_now->ymax = (!gp4mouse.is_log_y) ? gp4mouse.ymax : exp( gp4mouse.ymax * gp4mouse.log_base_log_y );
}
zoom_now = z;
if (zoom_now == NULL) {
#ifdef GNUPMDRV
    DosBeep(444,111);
#else
    fprintf(stderr,"\a");
#endif
    return;
}

#ifdef GNUPMDRV
/* update menu items in gnupmdrv */
WinEnableMenuItem( /* can this situation be zoomed back? */
  WinWindowFromID( WinQueryWindow( hApp, QW_PARENT ), FID_MENU ),
  IDM_MOUSE_ZOOMNEXT, (zoom_now->next == NULL) ? FALSE : TRUE ) ;
WinEnableMenuItem( /* can this situation be unzoomed back? */
  WinWindowFromID( WinQueryWindow( hApp, QW_PARENT ), FID_MENU ),
  IDM_MOUSE_UNZOOM, (zoom_now->prev == NULL) ? FALSE : TRUE ) ;
WinEnableMenuItem( /* can this situation be unzoomed to the beginning? */
  WinWindowFromID( WinQueryWindow( hApp, QW_PARENT ), FID_MENU ),
  IDM_MOUSE_UNZOOMALL, (zoom_now == zoom_head) ? FALSE : TRUE ) ;
#endif

/* prepare the command for gnuplot */
sprintf(s,"set xr[%g:%g]; set yr[%g:%g]; replot",
	zoom_now->xmin, zoom_now->xmax, zoom_now->ymin, zoom_now->ymax);

/* and let gnuplot execute it */
gp_execute(s);
}


#ifdef OS2

void gp_execute ( char *s )
{
/* Copy the command to the shared memory and let gnuplot execute it.
	If this routine is called during a 'pause', then the command is
   ignored (shared memory is cleared). Needed for actions launched by a
   hotkey.
	Firstly, the command is copied from shared memory to clipboard
   if this option is set on.
	Secondly, gnuplot is informed that shared memory contains a command
   by posting semInputReady event semaphore.

   OS/2 specific: if (!s), then the command has been already sprintf'ed to
   the shared memory.
*/
    APIRET rc;
    if (input_from_PM_Terminal==NULL)
	return;
    if (s) /* copy the command to shared memory */
      strcpy(input_from_PM_Terminal,s);
    if (((char*)input_from_PM_Terminal)[0]==0)
	return;
    if (pausing) { /* no communication during pause */
	DosBeep(440,111);
	((char*)input_from_PM_Terminal)[0] = 0;
	return;
    }
#ifdef GNUPMDRV
    /* write the command to clipboard */
    if (bSend2gp == TRUE)
	TextToClipboard ( input_from_PM_Terminal );
#endif
    /* let the command in the shared memory be executed... */
    if (semInputReady == 0) { /* but it must be open for the first time */
	char semInputReadyName[40];
	sprintf( semInputReadyName, "\\SEM32\\GP%i_Input_Ready", (int)ppidGnu );
	DosOpenEventSem( semInputReadyName, &semInputReady);
    }
    rc = DosPostEventSem(semInputReady);
}

#else

void
gp_execute(char *s)
{
    if(!s)
	return;
    /* fprintf(stderr,"(gp_execute) |%s|\n",s); */
    /* write the command to stdout which corresponds to the ipc_back_fd,
     * that is write the command to the ipc fd which is read by gnuplot. */
    printf("%s\n", s); /* XXX note the newline, gnuplot relies on it! XXX */ 
    fflush(stdout); /* just in case ... */
}

#endif


/* eof mousing.c */
