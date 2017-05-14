/*

    Canvas.c - a widget that allows programmer-specified refresh procedures.
    Copyright (C) 1990 Robert H. Forsman Jr.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 */

#include <X11/IntrinsicP.h>
#include <X11/StringDefs.h>

#include <stdio.h>

#include "CanvasP.h"

#define offset(field) XtOffset(CanvasWidget, canvas.field)

static XtResource resources[] = {
    {XtNexposeCallback, XtCCallback, XtRCallback, sizeof(XtCallbackList),
     offset(redraw), XtRPointer, NULL},
    {XtNrealizeCallback, XtCCallback, XtRCallback, sizeof(XtCallbackList),
     offset(realize), XtRPointer, NULL},
    {XtNresizeCallback, XtCCallback, XtRCallback, sizeof(XtCallbackList),
     offset(resize), XtRPointer, NULL},
#ifdef    XAW3D
# undef offset /* field */
# define offset(field) XtOffsetOf(RectObjRec, rectangle.field)
    { XtNborderWidth, XtCBorderWidth, XtRDimension, sizeof(Dimension),
          offset(border_width), XtRImmediate, (XtPointer) 1},
#endif /* XAW3D */
};

static void Initialize(CanvasWidget req, CanvasWidget new);
static void Realize();
static void Redisplay(Widget w, XExposeEvent *event, Region region);
static void Resize();
static GC setup_gc();

CanvasClassRec canvasClassRec = {
    {
/* core_class fields	 */
#ifndef XAW3D
# define SuperClass               ((SimpleWidgetClass)&simpleClassRec)
#else  /* XAW3D */
# define SuperClass               ((ThreeDWidgetClass)&threeDClassRec)
#endif /* XAW3D */
    /* superclass                */ (WidgetClass) SuperClass,
    /* class_name	  	 */ "Canvas",
    /* widget_size	  	 */ sizeof(CanvasRec),
    /* class_initialize   	 */ NULL,
    /* class_part_initialize	 */ NULL,
    /* class_inited       	 */ False,
    /* initialize	  	 */ (XtInitProc) Initialize,
    /* initialize_hook		 */ NULL,
    /* realize		  	 */ Realize,
    /* actions		  	 */ NULL,
    /* num_actions	  	 */ 0,
    /* resources	  	 */ resources,
    /* num_resources	  	 */ XtNumber(resources),
    /* xrm_class	  	 */ NULLQUARK,
    /* compress_motion	  	 */ True,
    /* compress_exposure  	 */ XtExposeCompressMultiple,
    /* compress_enterleave	 */ True,
    /* visible_interest	  	 */ True,
    /* destroy		  	 */ NULL,
    /* resize		  	 */ Resize,
    /* expose		  	 */ (XtExposeProc) Redisplay,
    /* set_values	  	 */ NULL,
    /* set_values_hook		 */ NULL,
    /* set_values_almost	 */ XtInheritSetValuesAlmost,
    /* get_values_hook		 */ NULL,
    /* accept_focus	 	 */ NULL,
    /* version			 */ XtVersion,
    /* callback_private   	 */ NULL,
    /* tm_table		   	 */ NULL,
    /* query_geometry		 */ NULL,
    /* display_accelerator       */ XtInheritDisplayAccelerator,
    /* extension                 */ NULL
    },
/* Simple class fields initialization */
    {
        /* change_sensitive      */  XtInheritChangeSensitive
    },
#ifdef  XAW3D
/* threeD class fields initialization */
    {
        /* ignore		 */  0
    },
#endif /* XAW3D */
};

WidgetClass canvasWidgetClass = (WidgetClass) & canvasClassRec;

static void Initialize(CanvasWidget req, CanvasWidget new)
{
    if (req->core.height <= 0)
        new->core.height = 200; /* a resonable default */

    if (req->core.width <= 0)
        new->core.width = 200;
}

static void Realize(w, valueMask, attributes)
Widget w;
Mask *valueMask;
XSetWindowAttributes *attributes;
{
  printf("Realize Canvas widget (%d %d)\n",((CanvasWidget)w)->core.height,
	 ((CanvasWidget)w)->core.width);
    (*SuperClass->core_class.realize) (w, valueMask, attributes);
    XtCallCallbacks(w, XtNrealizeCallback, NULL);
} /* Realize */

static void Redisplay(Widget w, XExposeEvent *event, Region region)
{
    if (SuperClass->core_class.expose)
        (*SuperClass->core_class.expose)(w, (XEvent *) event, region);

/*
    if (!XtIsRealized(w))
        return;
*/
    XtCallCallbacks(w, XtNexposeCallback, region);
}

static void Resize(w)
Widget w;
{
    XtCallCallbacks(w, XtNresizeCallback, NULL);
}

#include "libsx.h"
#include "libsx_private.h"


extern WindowState *lsx_curwin;   /* global handle for the current window */

#define MAXARGS 5

struct Edata
{
    Widget w;
    void *data;
    void *mysv;
    char *fun[MAXARGS];
    void *cvcache[MAXARGS];
#define CB_GENFUN 0
#define CB_BU_IDX 1
#define CB_BUTT_1 1
#define CB_BD_IDX 2
#define CB_BUTT_2 2
#define CB_KP_IDX 3
#define CB_BUTT_3 3
#define CB_MM_IDX 4
};

/* Called when a DrawingArea is resized.
 */
static void _realize(w, call_data)
Widget w;
void *call_data;
{
  struct Edata *dd = call_data;

  printf("In realize (%x): data %x (dd->w %x)\n\n", w, call_data, dd->w);

}

/* Called when a DrawingArea is resized.
 */
static void _resize(w, call_data)
Widget w;
void *call_data;
{

  struct Edata *dd = call_data;

  printf("In resize (%x): data %x (dd->w %x)\n\n", w, call_data, dd->w);

}

/* Called when a DrawingArea is resized.
 */

typedef struct {
  short x1, y1, x2, y2;
} mbox;

struct XRegion {
  long size;
  long numRects;
  mbox *rects;
  mbox extents;
} mregion;

static void _redisplay(w, data, region)
Widget w;
DrawInfo *data;
struct XRegion *region;
{
  struct Edata *dd = data->user_data;
  int i;

  printf("In redisplay (%x): data %x %x (dd->w %x)\n\n", w, data, dd, region);
  printf("region: %ld %ld\n",region->size, region->numRects);
  for (i = 0; i < region->numRects; i++) {
    mbox *b = region->rects + i;
    printf ("    R%d [%d %d %d %d]\n", i, b->x1, b->y1, b->x2, b->y2);
  }
  printf ("  X[%d %d %d %d]\n", region->extents.x1, region->extents.y1,
	  region->extents.x2, region->extents.y2);

/*
  while (region) {
    printf("region %x, rect: %d %d %d %d   -> %x\n", 
	   region,region->x,region->y,region->width,
	   region->height,region->next);
    region = region->next;
  }
*/
}

Widget
MakeCanvas(width, height, expose, realize, resize, data)
int width, height;
void expose(), realize(), resize();
void *data; {
  int    n = 0;
  Arg    wargs[5];		/* Used to set widget resources */
  Widget draw_widget;
  struct _CanvasRec *cw;
  DrawInfo *di;

  if (lsx_curwin->toplevel == NULL && OpenDisplay(0, NULL) == 0)
    return NULL;

  di = (DrawInfo *)calloc(sizeof(DrawInfo), 1);
  if (di == NULL)
    return NULL;

  n = 0;
  XtSetArg(wargs[n], XtNwidth, width);		n++; 
  XtSetArg(wargs[n], XtNheight,height);		n++; 

  draw_widget = XtCreateManagedWidget("canvas_area", canvasWidgetClass,
				      lsx_curwin->form_widget,wargs,n);

  if (draw_widget == NULL)
   {
     free(di);
     return NULL;
   }

  cw = (struct _CanvasRec *) draw_widget;
  printf ("Canvas created (%d %d) [%d %d]\n", cw->core.height, cw->core.width, 
	  height, width);


  cw->core.height = height;
  cw->core.width = width;

  di->drawgc     = setup_gc(draw_widget);
  di->foreground = BlackPixel(lsx_curwin->display, lsx_curwin->screen);
  di->background = WhitePixel(lsx_curwin->display, lsx_curwin->screen);
  di->mask       = 0xf1f2f3f4;

  di->user_data   = data;
  di->redisplay   = expose;

  XtAddCallback(draw_widget, XtNrealizeCallback, (XtCallbackProc)_realize, di);
  XtAddCallback(draw_widget, XtNresizeCallback, (XtCallbackProc)_resize,   di);
  XtAddCallback(draw_widget, XtNexposeCallback, (XtCallbackProc)_redisplay,di);
/*
  XtAddCallback(draw_widget, XtNinputCallback,  (XtCallbackProc)_do_input, di);
  XtAddCallback(draw_widget, XtNmotionCallback, (XtCallbackProc)_do_motion,di);
*/

  lsx_curwin->last_draw_widget = draw_widget;

  di->widget = draw_widget;
/*
  di->next = draw_info_head;
  draw_info_head = di;
  cur_di = di;
*/
  /*
   * Make sure the font is set to something sane.
   */
  if (lsx_curwin->font == NULL)
    lsx_curwin->font = GetFont("fixed");
  SetWidgetFont(draw_widget, lsx_curwin->font);

  return draw_widget;
}  

/*
 * Internal function for getting a graphics context so we can draw.
 */
static GC setup_gc(w)
Widget w;
{
  int fore_g,back_g;      /* Fore and back ground pixels */
  GC  drawgc;

  back_g = WhitePixel(XtDisplay(w),DefaultScreen(XtDisplay(w)));
  fore_g = BlackPixel(XtDisplay(w),DefaultScreen(XtDisplay(w)));

  /* Create drawing GC */
  drawgc = XCreateGC(XtDisplay(w), DefaultRootWindow(XtDisplay(w)), 0, 0);

  XSetBackground(XtDisplay(w), drawgc, back_g);
  XSetForeground(XtDisplay(w), drawgc, fore_g);
  XSetFunction(XtDisplay(w),   drawgc, GXcopy);

  return drawgc;
} /* end of setup_gc() */


