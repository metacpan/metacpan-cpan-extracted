/* $XConsortium: ThreeCom.c,v 1.77 91/10/16 21:32:53 eswu Exp $ */

/***********************************************************
Copyright 1987, 1988 by Digital Equipment Corporation, Maynard, Massachusetts,
and the Massachusetts Institute of Technology, Cambridge, Massachusetts.

                        All Rights Reserved

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose and without fee is hereby granted, 
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in 
supporting documentation, and that the names of Digital or MIT not be
used in advertising or publicity pertaining to distribution of the
software without specific, written prior permission.  

DIGITAL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL
DIGITAL BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR
ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
SOFTWARE.

******************************************************************/

/*
 * ThreeCom.c - ThreeCom button widget
 */

/*#include <stdio.h>*/
#include <X11/IntrinsicP.h>
#include <X11/StringDefs.h>
#include <X11/Xmu/Misc.h>

#ifdef XAW3D
#include <X11/Xaw3d/XawInit.h>
#else
#include <X11/Xaw/XawInit.h>
#endif

#include "ThreeComP.h"

#include <X11/Xmu/Converters.h>
#include <X11/extensions/shape.h>

#include "libsx.h"
#include "libsx_private.h"


extern WindowState *lsx_curwin;   /* global handle for the current window */

#define DEFAULT_HIGHLIGHT_THICKNESS 2
#define DEFAULT_SHAPE_HIGHLIGHT 32767

/****************************************************************
 *
 * Full class record constant
 *
 ****************************************************************/

/* Private Data */

static char defaultTranslations[] =
    "<EnterWindow>:	highlight()		\n\
     <LeaveWindow>:	reset()			\n\
     <Btn1Down>:	set()			\n\
     <Btn1Up>:		notify1() unset()	\n\
     <Btn2Down>:	set()			\n\
     <Btn2Up>:		notify2() unset()	\n\
     <Btn3Down>:	set()			\n\
     <Btn3Up>:		notify3() unset()	";

#define offset(field) XtOffsetOf(ThreeComRec, field)
static XtResource resources[] = { 
   {"callback1", XtCCallback, XtRCallback, sizeof(XtPointer), 
      offset(threeCom.callbacks1), XtRCallback, (XtPointer)NULL},
   {"callback2", XtCCallback, XtRCallback, sizeof(XtPointer), 
      offset(threeCom.callbacks2), XtRCallback, (XtPointer)NULL},
   {"callback3", XtCCallback, XtRCallback, sizeof(XtPointer), 
      offset(threeCom.callbacks3), XtRCallback, (XtPointer)NULL},
    {XtNhighlightThickness, XtCThickness, XtRDimension, sizeof(Dimension),
	offset(threeCom.highlight_thickness), XtRImmediate,
	(XtPointer) DEFAULT_SHAPE_HIGHLIGHT},
    {XtNshapeStyle, XtCShapeStyle, XtRShapeStyle, sizeof(int),
	offset(threeCom.shape_style), XtRImmediate, 
	(XtPointer)XawShapeRectangle},
    {XtNcornerRoundPercent, XtCCornerRoundPercent, 
	XtRDimension, sizeof(Dimension),
	offset(threeCom.corner_round), XtRImmediate, (XtPointer) 25},
#ifdef XAW3D
    {XtNshadowWidth, XtCShadowWidth, XtRDimension, sizeof(Dimension),
	offset(threeD.shadow_width), XtRImmediate, (XtPointer) 2},
#endif
    {XtNborderWidth, XtCBorderWidth, XtRDimension, sizeof(Dimension),
	XtOffsetOf(RectObjRec,rectangle.border_width), XtRImmediate,
	(XtPointer)0}
};
#undef offset

static Boolean SetValues();
static void Initialize(), Redisplay(), Set(), Reset(), Unset();
static void Notify1(), Notify2(), Notify3();
static void Highlight(), Unhighlight(), Destroy(), PaintThreeComWidget();
static void ClassInitialize();
static Boolean ShapeButton();
static void Realize(), Resize();

static XtActionsRec actionsList[] = {
  {"set",		Set},
  {"notify1",		Notify1},
  {"notify2",		Notify2},
  {"notify3",		Notify3},
  {"highlight",		Highlight},
  {"reset",		Reset},
  {"unset",		Unset},
  {"unhighlight",	Unhighlight}
};

#define SuperClass ((LabelWidgetClass)&labelClassRec)

ThreeComClassRec threeComClassRec = {
  {
    (WidgetClass) SuperClass,		/* superclass		  */	
    "ThreeCom",				/* class_name		  */
    sizeof(ThreeComRec),			/* size			  */
    ClassInitialize,			/* class_initialize	  */
    NULL,				/* class_part_initialize  */
    FALSE,				/* class_inited		  */
    Initialize,				/* initialize		  */
    NULL,				/* initialize_hook	  */
    Realize,				/* realize		  */
    actionsList,			/* actions		  */
    XtNumber(actionsList),		/* num_actions		  */
    resources,				/* resources		  */
    XtNumber(resources),		/* resource_count	  */
    NULLQUARK,				/* xrm_class		  */
    FALSE,				/* compress_motion	  */
    TRUE,				/* compress_exposure	  */
    TRUE,				/* compress_enterleave    */
    FALSE,				/* visible_interest	  */
    Destroy,				/* destroy		  */
    Resize,				/* resize		  */
    Redisplay,				/* expose		  */
    SetValues,				/* set_values		  */
    NULL,				/* set_values_hook	  */
    XtInheritSetValuesAlmost,		/* set_values_almost	  */
    NULL,				/* get_values_hook	  */
    NULL,				/* accept_focus		  */
    XtVersion,				/* version		  */
    NULL,				/* callback_private	  */
    defaultTranslations,		/* tm_table		  */
    XtInheritQueryGeometry,		/* query_geometry	  */
    XtInheritDisplayAccelerator,	/* display_accelerator	  */
    NULL				/* extension		  */
  },  /* CoreClass fields initialization */
  {
    XtInheritChangeSensitive		/* change_sensitive	*/
  },  /* SimpleClass fields initialization */
#ifdef XAW3D
  {
    XtInheritXaw3dShadowDraw,           /* shadowdraw           */
  },  /* ThreeD Class fields initialization */
#endif
  {
    0,                                     /* field not used    */
  },  /* LabelClass fields initialization */
  {
    0,                                     /* field not used    */
  },  /* ThreeComClass fields initialization */
};

  /* for public consumption */
WidgetClass threeComWidgetClass = (WidgetClass) &threeComClassRec;

/****************************************************************
 *
 * Private Procedures
 *
 ****************************************************************/

static GC 
Get_GC(cbw, fg, bg)
ThreeComWidget cbw;
Pixel fg, bg;
{
  XGCValues	values;
  
  values.foreground   = fg;
  values.background	= bg;
  values.font		= cbw->label.font->fid;
  values.cap_style = CapProjecting;
  
  if (cbw->threeCom.highlight_thickness > 1 )
    values.line_width   = cbw->threeCom.highlight_thickness;
  else 
    values.line_width   = 0;
  
  return XtGetGC((Widget)cbw,
		 (GCForeground|GCBackground|GCFont|GCLineWidth|GCCapStyle),
		 &values);
}


/* ARGSUSED */
static void 
Initialize(request, new, args, num_args)
Widget request, new;
ArgList args;			/* unused */
Cardinal *num_args;		/* unused */
{
    ThreeComWidget cbw = (ThreeComWidget) new;
    int shape_event_base, shape_error_base;

    if (cbw->threeCom.shape_style != XawShapeRectangle
	&& !XShapeQueryExtension(XtDisplay(new), &shape_event_base, 
			       &shape_error_base))
	cbw->threeCom.shape_style = XawShapeRectangle;
    if (cbw->threeCom.highlight_thickness == DEFAULT_SHAPE_HIGHLIGHT) {
	if (cbw->threeCom.shape_style != XawShapeRectangle)
	    cbw->threeCom.highlight_thickness = 0;
	else
	    cbw->threeCom.highlight_thickness = DEFAULT_HIGHLIGHT_THICKNESS;
    }
    if (cbw->threeCom.shape_style != XawShapeRectangle) {
#ifdef XAW3D
	cbw->threeD.shadow_width = 0;
#endif
	cbw->core.border_width = 1;
    }

    cbw->threeCom.normal_GC = Get_GC(cbw, cbw->label.foreground, 
				  cbw->core.background_pixel);
    cbw->threeCom.inverse_GC = Get_GC(cbw, cbw->core.background_pixel, 
				   cbw->label.foreground);
    XtReleaseGC(new, cbw->label.normal_GC);
    cbw->label.normal_GC = cbw->threeCom.normal_GC;

    cbw->threeCom.set = FALSE;
    cbw->threeCom.highlighted = HighlightNone;
}

static Region 
HighlightRegion(cbw)
ThreeComWidget cbw;
{
    static Region outerRegion = NULL, innerRegion, emptyRegion;
    XRectangle rect;

    if (cbw->threeCom.highlight_thickness == 0 ||
      cbw->threeCom.highlight_thickness >
      (Dimension) ((Dimension) Min(cbw->core.width, cbw->core.height)/2))
	return(NULL);

    if (outerRegion == NULL) {
	/* save time by allocating scratch regions only once. */
	outerRegion = XCreateRegion();
	innerRegion = XCreateRegion();
	emptyRegion = XCreateRegion();
    }

    rect.x = rect.y = 0;
    rect.width = cbw->core.width;
    rect.height = cbw->core.height;
    XUnionRectWithRegion( &rect, emptyRegion, outerRegion );
    rect.x = rect.y = cbw->threeCom.highlight_thickness;
    rect.width -= cbw->threeCom.highlight_thickness * 2;
    rect.height -= cbw->threeCom.highlight_thickness * 2;
    XUnionRectWithRegion( &rect, emptyRegion, innerRegion );
    XSubtractRegion( outerRegion, innerRegion, outerRegion );
    return outerRegion;
}

/***************************
*
*  Action Procedures
*
***************************/

/* ARGSUSED */
static void 
Set(w,event,params,num_params)
Widget w;
XEvent *event;
String *params;		/* unused */
Cardinal *num_params;	/* unused */
{
    ThreeComWidget cbw = (ThreeComWidget)w;

    if (cbw->threeCom.set)
	return;

    cbw->threeCom.set= TRUE;
    if (XtIsRealized(w))
	PaintThreeComWidget(w, event, (Region) NULL, TRUE);
}

/* ARGSUSED */
static void
Unset(w,event,params,num_params)
Widget w;
XEvent *event;
String *params;		/* unused */
Cardinal *num_params;
{
    ThreeComWidget cbw = (ThreeComWidget)w;

    if (!cbw->threeCom.set)
	return;

    cbw->threeCom.set = FALSE;
    if (XtIsRealized(w)) {
	XClearWindow(XtDisplay(w), XtWindow(w));
	PaintThreeComWidget(w, event, (Region) NULL, TRUE);
    }
}

/* ARGSUSED */
static void 
Reset(w,event,params,num_params)
Widget w;
XEvent *event;
String *params;		/* unused */
Cardinal *num_params;   /* unused */
{
    ThreeComWidget cbw = (ThreeComWidget)w;

    if (cbw->threeCom.set) {
	cbw->threeCom.highlighted = HighlightNone;
	Unset(w, event, params, num_params);
    } else
	Unhighlight(w, event, params, num_params);
}

/* ARGSUSED */
static void 
Highlight(w,event,params,num_params)
Widget w;
XEvent *event;
String *params;		
Cardinal *num_params;	
{
    ThreeComWidget cbw = (ThreeComWidget)w;

    if ( *num_params == (Cardinal) 0) 
	cbw->threeCom.highlighted = HighlightWhenUnset;
    else {
	if ( *num_params != (Cardinal) 1) 
	    XtWarning("Too many parameters passed to highlight action table.");
	switch (params[0][0]) {
	case 'A':
	case 'a':
	    cbw->threeCom.highlighted = HighlightAlways;
	    break;
	default:
	    cbw->threeCom.highlighted = HighlightWhenUnset;
	    break;
	}
    }

    if (XtIsRealized(w))
	PaintThreeComWidget(w, event, HighlightRegion(cbw), TRUE);
}

/* ARGSUSED */
static void 
Unhighlight(w,event,params,num_params)
Widget w;
XEvent *event;
String *params;		/* unused */
Cardinal *num_params;	/* unused */
{
    ThreeComWidget cbw = (ThreeComWidget)w;

    cbw->threeCom.highlighted = HighlightNone;
    if (XtIsRealized(w))
	PaintThreeComWidget(w, event, HighlightRegion(cbw), TRUE);
}

/* ARGSUSED */
static void 
Notify1(w,event,params,num_params)
Widget w;
XEvent *event;
String *params;		/* unused */
Cardinal *num_params;	/* unused */
{
  ThreeComWidget cbw = (ThreeComWidget)w; 

  /* check to be sure state is still Set so that user can cancel
     the action (e.g. by moving outside the window, in the default
     bindings.
  */
  if (cbw->threeCom.set)
    XtCallCallbackList(w, cbw->threeCom.callbacks1, NULL);
}

/* ARGSUSED */
static void 
Notify2(w,event,params,num_params)
Widget w;
XEvent *event;
String *params;		/* unused */
Cardinal *num_params;	/* unused */
{
  ThreeComWidget cbw = (ThreeComWidget)w; 

  /* check to be sure state is still Set so that user can cancel
     the action (e.g. by moving outside the window, in the default
     bindings.
  */
  if (cbw->threeCom.set)
    XtCallCallbackList(w, cbw->threeCom.callbacks2, NULL);
}

/* ARGSUSED */
static void 
Notify3(w,event,params,num_params)
Widget w;
XEvent *event;
String *params;		/* unused */
Cardinal *num_params;	/* unused */
{
  ThreeComWidget cbw = (ThreeComWidget)w; 

  /* check to be sure state is still Set so that user can cancel
     the action (e.g. by moving outside the window, in the default
     bindings.
  */
  if (cbw->threeCom.set)
    XtCallCallbackList(w, cbw->threeCom.callbacks3, NULL);
}

/*
 * Repaint the widget window
 */

/************************
*
*  REDISPLAY (DRAW)
*
************************/

/* ARGSUSED */
static void 
Redisplay(w, event, region)
Widget w;
XEvent *event;
Region region;
{
    PaintThreeComWidget(w, event, region, FALSE);
}

/*	Function Name: PaintThreeComWidget
 *	Description: Paints the threeCom widget.
 *	Arguments: w - the threeCom widget.
 *                 region - region to paint (passed to the superclass).
 *                 change - did it change either set or highlight state?
 *	Returns: none
 */

static void 
PaintThreeComWidget(gw, event, region, change)
Widget gw;
XEvent *event;
Region region;
Boolean change;
{
    ThreeComWidget w = (ThreeComWidget) gw;
    ThreeComWidgetClass cwclass = (ThreeComWidgetClass) XtClass (gw);
    Boolean very_thick;
    GC norm_gc, rev_gc;
#ifdef XAW3D
    Dimension	s = w->threeD.shadow_width;
#else
    Dimension	s = 0;
#endif
    very_thick = w->threeCom.highlight_thickness >
               (Dimension)((Dimension) Min(w->core.width, w->core.height)/2);

    if (w->threeCom.set) {
	w->label.normal_GC = w->threeCom.inverse_GC;
	XFillRectangle(XtDisplay(gw), XtWindow(gw), w->threeCom.normal_GC,
		   s, s, w->core.width - 2 * s, w->core.height - 2 * s);
	region = NULL;		/* Force label to repaint text. */
    }
    else
	w->label.normal_GC = w->threeCom.normal_GC;

    if (w->threeCom.highlight_thickness <= 0) {
	(*SuperClass->core_class.expose) (gw, event, region);
#ifdef XAW3D
	(*cwclass->threeD_class.shadowdraw) (gw, event, region, !w->threeCom.set);
#endif
	return;
    }

/*
 * If we are set then use the same colors as if we are not highlighted. 
 */

    if (w->threeCom.set == (w->threeCom.highlighted == HighlightNone)) {
	norm_gc = w->threeCom.inverse_GC;
	rev_gc = w->threeCom.normal_GC;
    } else {
	norm_gc = w->threeCom.normal_GC;
	rev_gc = w->threeCom.inverse_GC;
    }

    if ( !( (!change && (w->threeCom.highlighted == HighlightNone)) ||
	  ((w->threeCom.highlighted == HighlightWhenUnset) &&
	   (w->threeCom.set))) ) {
	if (very_thick) {
	    w->label.normal_GC = norm_gc; /* Give the label the right GC. */
	    XFillRectangle(XtDisplay(gw),XtWindow(gw), rev_gc,
		    s, s, 
		    w->core.width - 2 * s, w->core.height - 2 * s);
	} else {
	    /* wide lines are centered on the path, so indent it */
	    int offset = w->threeCom.highlight_thickness/2;
	    XDrawRectangle(XtDisplay(gw),XtWindow(gw), rev_gc, 
		    s + offset, s + offset, 
		    w->core.width - w->threeCom.highlight_thickness - 2 * s,
		    w->core.height - w->threeCom.highlight_thickness - 2 * s);
	}
    }
    (*SuperClass->core_class.expose) (gw, event, region);
#ifdef XAW3D
    (*cwclass->threeD_class.shadowdraw) (gw, event, region, !w->threeCom.set);
#endif
}

static void 
Destroy(gw)
Widget gw;
{
    ThreeComWidget w = (ThreeComWidget) gw;
/*fprintf(stderr, "+++threeCom widget %p will be destroyed\n",w);*/

    /* so Label can release it */
    if (w->label.normal_GC == w->threeCom.normal_GC)
	XtReleaseGC( gw, w->threeCom.inverse_GC );
    else
	XtReleaseGC( gw, w->threeCom.normal_GC );

/*fprintf(stderr, "+++threeCom widget %p has been destroyed\n",w);*/
}

/*
 * Set specified arguments into widget
 */

/* ARGSUSED */
static Boolean 
SetValues (current, request, new, args, num_args)
Widget current, request, new;
ArgList args;
Cardinal *num_args;
{
  ThreeComWidget oldcbw = (ThreeComWidget) current;
  ThreeComWidget cbw = (ThreeComWidget) new;
  Boolean redisplay = False;

  if ( oldcbw->core.sensitive != cbw->core.sensitive && !cbw->core.sensitive) {
    /* about to become insensitive */
    cbw->threeCom.set = FALSE;
    cbw->threeCom.highlighted = HighlightNone;
    redisplay = TRUE;
  }
  
  if ( (oldcbw->label.foreground != cbw->label.foreground)           ||
       (oldcbw->core.background_pixel != cbw->core.background_pixel) ||
       (oldcbw->threeCom.highlight_thickness != 
                                   cbw->threeCom.highlight_thickness) ||
       (oldcbw->label.font != cbw->label.font) ) 
  {
    if (oldcbw->label.normal_GC == oldcbw->threeCom.normal_GC)
	/* Label has release one of these */
      XtReleaseGC(new, cbw->threeCom.inverse_GC);
    else
      XtReleaseGC(new, cbw->threeCom.normal_GC);

    cbw->threeCom.normal_GC = Get_GC(cbw, cbw->label.foreground, 
				    cbw->core.background_pixel);
    cbw->threeCom.inverse_GC = Get_GC(cbw, cbw->core.background_pixel, 
				     cbw->label.foreground);
    XtReleaseGC(new, cbw->label.normal_GC);
    cbw->label.normal_GC = (cbw->threeCom.set
			    ? cbw->threeCom.inverse_GC
			    : cbw->threeCom.normal_GC);
    
    redisplay = True;
  }

  if ( XtIsRealized(new)
       && oldcbw->threeCom.shape_style != cbw->threeCom.shape_style
       && !ShapeButton(cbw, TRUE))
  {
      cbw->threeCom.shape_style = oldcbw->threeCom.shape_style;
  }

  return (redisplay);
}

static void ClassInitialize()
{
    XawInitializeWidgetSet();
    XtSetTypeConverter( XtRString, XtRShapeStyle, XmuCvtStringToShapeStyle,
		        (XtConvertArgList)NULL, 0, XtCacheNone, (XtDestructor)NULL );
}


static Boolean
ShapeButton(cbw, checkRectangular)
ThreeComWidget cbw;
Boolean checkRectangular;
{
    Dimension corner_size;

    if ( (cbw->threeCom.shape_style == XawShapeRoundedRectangle) ) {
	corner_size = (cbw->core.width < cbw->core.height) ? cbw->core.width 
	                                                   : cbw->core.height;
	corner_size = (int) (corner_size * cbw->threeCom.corner_round) / 100;
    }

    if (checkRectangular || cbw->threeCom.shape_style != XawShapeRectangle) {
	if (!XmuReshapeWidget((Widget) cbw, cbw->threeCom.shape_style,
			      corner_size, corner_size)) {
	    cbw->threeCom.shape_style = XawShapeRectangle;
	    return(False);
	}
    }
    return(TRUE);
}

static void Realize(w, valueMask, attributes)
    Widget w;
    Mask *valueMask;
    XSetWindowAttributes *attributes;
{
    (*threeComWidgetClass->core_class.superclass->core_class.realize)
	(w, valueMask, attributes);

    ShapeButton( (ThreeComWidget) w, FALSE);
}

static void Resize(w)
    Widget w;
{
    if (XtIsRealized(w)) 
	ShapeButton( (ThreeComWidget) w, FALSE);

    (*threeComWidgetClass->core_class.superclass->core_class.resize)(w);
}

Widget Make3Com(txt, func1, func2, func3, data, name)
char *txt;
ButtonCB func1;
ButtonCB func2;
ButtonCB func3;
void *data;
char *name;
{
  int    n = 0;
  Arg    wargs[5];		/* Used to set widget resources */
  Widget button;

  if (lsx_curwin->toplevel == NULL && OpenDisplay(0, NULL) == 0)
    return NULL;

  n = 0;
  if (txt)
   {
     XtSetArg(wargs[n], XtNlabel, txt);	 	          n++;
   }


  button = XtCreateManagedWidget(name, threeComWidgetClass,
				 lsx_curwin->form_widget,wargs,n);
  if (button == NULL)
    return NULL;

  if (func1)
    XtAddCallback(button, "callback1", (XtCallbackProc)func1, data);

  if (func2)
    XtAddCallback(button, "callback2", (XtCallbackProc)func2, data);

  if (func3)
    XtAddCallback(button, "callback3", (XtCallbackProc)func3, data);

  return button;
}    /* end of MakeButton() */
