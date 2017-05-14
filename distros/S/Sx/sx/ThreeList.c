/* $XConsortium: ThreeList.c,v 1.39 94/04/17 20:12:15 kaleb Exp $ */

/*
Copyright (c) 1989, 1994  X Consortium

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
X CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of the X Consortium shall not be
used in advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization from the X Consortium.
*/

/*
 * ThreeList.c - ThreeList widget
 *
 * This is a ThreeList widget.  It allows the user to select an item in a threeList and
 * notifies the application through a callback function.
 *
 *	Created: 	8/13/88
 *	By:		Chris D. Peterson
 *                      MIT X Consortium
 */

#include <stdio.h>
#include <ctype.h>

#include <X11/IntrinsicP.h>
#include <X11/StringDefs.h>

#include <X11/Xmu/Drawing.h>

#ifdef XAW3D
#include <X11/Xaw3d/XawInit.h>
#include <X11/Xaw3d/Viewport.h>
#else 
#include <X11/Xaw/XawInit.h>
#include <X11/Xaw/Viewport.h>
#endif
#include "ThreeListP.h"

/* These added so widget knows whether its height, width are user selected.
I also added the freedoms member of the threeList widget part. */

#define HeightLock  1
#define WidthLock   2
#define LongestLock 4

#define HeightFree( w )  !(((ThreeListWidget)(w))->threeList.freedoms & HeightLock )
#define WidthFree( w )   !(((ThreeListWidget)(w))->threeList.freedoms & WidthLock )
#define LongestFree( w ) !(((ThreeListWidget)(w))->threeList.freedoms & LongestLock )


#include "libsx.h"
#include "libsx_private.h"

void XawthreeListHighlight();
void XawthreeListUnhighlight();

extern WindowState *lsx_curwin;   /* global handle to current window */

typedef void (*ThreeListCB)();

/*
 * this structure maintains some internal state information about each
 * scrolled threeList widget.
 */
typedef struct threeListInfo
{
  Widget w;
  ThreeListCB func;
/*
  void (*func)(Widget w, char *str, int index, unsigned int event, void *data);
*/
  void *data;
  struct threeListInfo *next;
}threeListInfo;

static threeListInfo *scroll_threeLists = NULL;


/* 
 * Default Translation table.
 */

static char defaultTranslations[] =  
  "<Btn1Down>:   Set()\n\
   <Btn1Up>:     Notify()\n\
   <Btn2Down>:   Set()\n\
   <Btn2Up>:     Notify()\n\
   <Btn3Down>:   Set()\n\
   <Btn3Up>:     Notify()";

/****************************************************************
 *
 * Full class record constant
 *
 ****************************************************************/

/* Private Data */

#define offset(field) XtOffset(ThreeListWidget, field)

static XtResource resources[] = {
    {XtNforeground, XtCForeground, XtRPixel, sizeof(Pixel),
	offset(threeList.foreground), XtRString, XtDefaultForeground},
    {XtNcursor, XtCCursor, XtRCursor, sizeof(Cursor),
       offset(simple.cursor), XtRString, "left_ptr"},
    {XtNfont,  XtCFont, XtRFontStruct, sizeof(XFontStruct *),
	offset(threeList.font),XtRString, XtDefaultFont},
    {XtNfontSet,  XtCFontSet, XtRFontSet, sizeof(XFontSet ),
	offset(threeList.fontset),XtRString, XtDefaultFontSet},
    {XtNlist, XtCList, XtRPointer, sizeof(char **),
       offset(threeList.threeList), XtRString, NULL},
    {XtNdefaultColumns, XtCColumns, XtRInt,  sizeof(int),
	offset(threeList.default_cols), XtRImmediate, (XtPointer)2},
    {XtNlongest, XtCLongest, XtRInt,  sizeof(int),
	offset(threeList.longest), XtRImmediate, (XtPointer)0},
    {XtNnumberStrings, XtCNumberStrings, XtRInt,  sizeof(int),
	offset(threeList.nitems), XtRImmediate, (XtPointer)0},
    {XtNpasteBuffer, XtCBoolean, XtRBoolean,  sizeof(Boolean),
	offset(threeList.paste), XtRImmediate, (XtPointer) False},
    {XtNforceColumns, XtCColumns, XtRBoolean,  sizeof(Boolean),
	offset(threeList.force_cols), XtRImmediate, (XtPointer) False},
    {XtNverticalList, XtCBoolean, XtRBoolean,  sizeof(Boolean),
	offset(threeList.vertical_cols), XtRImmediate, (XtPointer) False},
    {XtNinternalWidth, XtCWidth, XtRDimension,  sizeof(Dimension),
	offset(threeList.internal_width), XtRImmediate, (XtPointer)2},
    {XtNinternalHeight, XtCHeight, XtRDimension, sizeof(Dimension),
	offset(threeList.internal_height), XtRImmediate, (XtPointer)2},
    {XtNcolumnSpacing, XtCSpacing, XtRDimension,  sizeof(Dimension),
	offset(threeList.column_space), XtRImmediate, (XtPointer)6},
    {XtNrowSpacing, XtCSpacing, XtRDimension,  sizeof(Dimension),
	offset(threeList.row_space), XtRImmediate, (XtPointer)2},
    {XtNcallback, XtCCallback, XtRCallback, sizeof(XtPointer),
        offset(threeList.callback), XtRCallback, NULL},
};

static void Initialize();
static void ChangeSize();
static void Resize();
static void Redisplay();
static void Destroy();
static Boolean Layout();
static XtGeometryResult PreferredGeom();
static Boolean SetValues();
static void Notify(), Set(), Unset();

static XtActionsRec actions[] = {
      {"Notify",         Notify},
      {"Set",            Set},
      {"Unset",          Unset},
};

ThreeListClassRec threeListClassRec = {
  {
/* core_class fields */	
    /* superclass	  	*/	(WidgetClass) &simpleClassRec,
    /* class_name	  	*/	"ThreeList",
    /* widget_size	  	*/	sizeof(ThreeListRec),
    /* class_initialize   	*/	XawInitializeWidgetSet,
    /* class_part_initialize	*/	NULL,
    /* class_inited       	*/	FALSE,
    /* initialize	  	*/	Initialize,
    /* initialize_hook		*/	NULL,
    /* realize		  	*/	XtInheritRealize,
    /* actions		  	*/	actions,
    /* num_actions	  	*/	XtNumber(actions),
    /* resources	  	*/	resources,
    /* num_resources	  	*/	XtNumber(resources),
    /* xrm_class	  	*/	NULLQUARK,
    /* compress_motion	  	*/	TRUE,
    /* compress_exposure  	*/	FALSE,
    /* compress_enterleave	*/	TRUE,
    /* visible_interest	  	*/	FALSE,
    /* destroy		  	*/	Destroy,
    /* resize		  	*/	Resize,
    /* expose		  	*/	Redisplay,
    /* set_values	  	*/	SetValues,
    /* set_values_hook		*/	NULL,
    /* set_values_almost	*/	XtInheritSetValuesAlmost,
    /* get_values_hook		*/	NULL,
    /* accept_focus	 	*/	NULL,
    /* version			*/	XtVersion,
    /* callback_private   	*/	NULL,
    /* tm_table		   	*/	defaultTranslations,
   /* query_geometry		*/      PreferredGeom,
  },
/* Simple class fields initialization */
  {
    /* change_sensitive		*/	XtInheritChangeSensitive
  },
/* ThreeList class fields initialization */
  {
    /* not used			*/	0
  },
};

WidgetClass threeListWidgetClass = (WidgetClass)&threeListClassRec;

/****************************************************************
 *
 * Private Procedures
 *
 ****************************************************************/

static void GetGCs(w)
Widget w;
{
    XGCValues	values;
    ThreeListWidget lw = (ThreeListWidget) w;    

    values.foreground	= lw->threeList.foreground;
    values.font		= lw->threeList.font->fid;

#ifdef X11R6
    if ( lw->simple.international == True )
        lw->threeList.normgc = XtAllocateGC( w, 0, (unsigned) GCForeground,
				 &values, GCFont, 0 );
    else
#endif
        lw->threeList.normgc = XtGetGC( w, (unsigned) GCForeground | GCFont,
				 &values);

    values.foreground	= lw->core.background_pixel;

#ifdef X11R6
    if ( lw->simple.international == True )
        lw->threeList.revgc = XtAllocateGC( w, 0, (unsigned) GCForeground,
				 &values, GCFont, 0 );
    else
#endif
        lw->threeList.revgc = XtGetGC( w, (unsigned) GCForeground | GCFont,
				 &values);

    values.tile       = XmuCreateStippledPixmap(XtScreen(w), 
						lw->threeList.foreground,
						lw->core.background_pixel,
						lw->core.depth);
    values.fill_style = FillTiled;

#ifdef X11R6
    if ( lw->simple.international == True )
        lw->threeList.graygc = XtAllocateGC( w, 0, (unsigned) GCTile | GCFillStyle,
			      &values, GCFont, 0 );
    else
#endif
        lw->threeList.graygc = XtGetGC( w, (unsigned) GCFont | GCTile | GCFillStyle,
			      &values);
}


/* CalculatedValues()
 *
 * does routine checks/computations that must be done after data changes
 * but won't hurt if accidently called
 *
 * These calculations were needed in SetValues.  They were in ResetThreeList.
 * ResetThreeList called ChangeSize, which made an XtGeometryRequest.  You
 * MAY NOT change your geometry from within a SetValues. (Xt man,
 * sect. 9.7.2)  So, I factored these changes out. */

static void CalculatedValues( w )
Widget w;
{
    int i, len;

    ThreeListWidget lw = (ThreeListWidget) w;

    /* If list is NULL then the list will just be the name of the widget. */

    if (lw->threeList.threeList == NULL) {
      lw->threeList.threeList = &(lw->core.name);
      lw->threeList.nitems = 1;
    }

    /* Get number of items. */

    if (lw->threeList.nitems == 0)
        for ( ; lw->threeList.threeList[lw->threeList.nitems] != NULL ; lw->threeList.nitems++);

    /* Get column width. */

    if ( LongestFree( lw ) )  {

        lw->threeList.longest = 0; /* so it will accumulate real longest below */

        for ( i = 0 ; i < lw->threeList.nitems; i++)  {
#ifdef X11R6
            if ( lw->simple.international == True )
	        len = XmbTextEscapement(lw->threeList.fontset, lw->threeList.threeList[i],
			 			    strlen(lw->threeList.threeList[i]));
            else
#endif
                len = XTextWidth(lw->threeList.font, lw->threeList.threeList[i],
			 			    strlen(lw->threeList.threeList[i]));
            if (len > lw->threeList.longest)
                lw->threeList.longest = len;
        }
    }

    lw->threeList.col_width = lw->threeList.longest + lw->threeList.column_space;
}

/*	Function Name: ResetThreeList
 *	Description: Resets the new list when important things change.
 *	Arguments: w - the widget.
 *                 changex, changey - allow the height or width to change?
 *
 *	Returns: TRUE if width or height have been changed
 */

static void
ResetThreeList( w, changex, changey )
Widget w;
Boolean changex, changey;
{
    Dimension width = w->core.width;
    Dimension height = w->core.height;

    CalculatedValues( w );

    if( Layout( w, changex, changey, &width, &height ) )
      ChangeSize( w, width, height );
}

/*	Function Name: ChangeSize.
 *	Description: Laysout the widget.
 *	Arguments: w - the widget to try change the size of.
 *	Returns: none.
 */

static void
ChangeSize(w, width, height)
Widget w;
Dimension width, height;
{
    XtWidgetGeometry request, reply;

    request.request_mode = CWWidth | CWHeight;
    request.width = width;
    request.height = height;

    switch ( XtMakeGeometryRequest(w, &request, &reply) ) {
    case XtGeometryYes:
        break;
    case XtGeometryNo:
        break;
    case XtGeometryAlmost:
	Layout(w, (request.height != reply.height),
	          (request.width != reply.width),
	       &(reply.width), &(reply.height));
	request = reply;
	switch (XtMakeGeometryRequest(w, &request, &reply) ) {
	case XtGeometryYes:
	case XtGeometryNo:
	    break;
	case XtGeometryAlmost:
	    request = reply;
	    Layout(w, FALSE, FALSE, &(request.width), &(request.height));
	    request.request_mode = CWWidth | CWHeight;
	    XtMakeGeometryRequest(w, &request, &reply);
	    break;
	default:
	  XtAppWarning(XtWidgetToApplicationContext(w),
		       "ThreeList Widget: Unknown geometry return.");
	  break;
	}
	break;
    default:
	XtAppWarning(XtWidgetToApplicationContext(w),
		     "ThreeList Widget: Unknown geometry return.");
	break;
    }
}

/*	Function Name: Initialize
 *	Description: Function that initilizes the widget instance.
 *	Arguments: junk - NOT USED.
 *                 new  - the new widget.
 *	Returns: none
 */

/* ARGSUSED */
static void 
Initialize(junk, new, args, num_args)
Widget junk, new;
ArgList args;
Cardinal *num_args;
{
    ThreeListWidget lw = (ThreeListWidget) new;

/* 
 * Initialize all private resources.
 */

    /* record for posterity if we are free */
    lw->threeList.freedoms = (lw->core.width != 0) * WidthLock +
                        (lw->core.height != 0) * HeightLock +
                        (lw->threeList.longest != 0) * LongestLock;

    GetGCs(new);

    /* Set row height. based on font or fontset */

#ifdef X11R6
    if (lw->simple.international == True )
        lw->threeList.row_height =
                     XExtentsOfFontSet(lw->threeList.fontset)->max_ink_extent.height
                        + lw->threeList.row_space;
    else
#endif
        lw->threeList.row_height = lw->threeList.font->max_bounds.ascent
			+ lw->threeList.font->max_bounds.descent
			+ lw->threeList.row_space;

    ResetThreeList( new, WidthFree( lw ), HeightFree( lw ) );

    lw->threeList.highlight = lw->threeList.is_highlighted = NO_HIGHLIGHT;

} /* Initialize */

/*	Function Name: CvtToItem
 *	Description: Converts Xcoord to item number of item containing that
 *                   point.
 *	Arguments: w - the threeList widget.
 *                 xloc, yloc - x location, and y location.
 *	Returns: the item number.
 */

static int
CvtToItem(w, xloc, yloc, item)
Widget w;
int xloc, yloc;
int *item;
{
    int one, another;
    ThreeListWidget lw = (ThreeListWidget) w;
    int ret_val = OKAY;

    if (lw->threeList.vertical_cols) {
        one = lw->threeList.nrows * ((xloc - (int) lw->threeList.internal_width)
	    / lw->threeList.col_width);
        another = (yloc - (int) lw->threeList.internal_height) 
	        / lw->threeList.row_height;
	 /* If out of range, return minimum possible value. */
	if (another >= lw->threeList.nrows) {
	    another = lw->threeList.nrows - 1;
	    ret_val = OUT_OF_RANGE;
	}
    }
    else {
        one = (lw->threeList.ncols * ((yloc - (int) lw->threeList.internal_height) 
              / lw->threeList.row_height)) ;
	/* If in right margin handle things right. */
        another = (xloc - (int) lw->threeList.internal_width) / lw->threeList.col_width;
	if (another >= lw->threeList.ncols) {
	    another = lw->threeList.ncols - 1; 
	    ret_val = OUT_OF_RANGE;
	}
    }  
    if ((xloc < 0) || (yloc < 0))
        ret_val = OUT_OF_RANGE;
    if (one < 0) one = 0;
    if (another < 0) another = 0;
    *item = one + another;
    if (*item >= lw->threeList.nitems) return(OUT_OF_RANGE);
    return(ret_val);
}

/*	Function Name: FindCornerItems.
 *	Description: Find the corners of the rectangle in item space.
 *	Arguments: w - the threeList widget.
 *                 event - the event structure that has the rectangle it it.
 *                 ul_ret, lr_ret - the corners ** RETURNED **.
 *	Returns: none.
 */

static void
FindCornerItems(w, event, ul_ret, lr_ret)
Widget w;
XEvent * event;
int *ul_ret, *lr_ret;
{
    int xloc, yloc;

    xloc = event->xexpose.x;
    yloc = event->xexpose.y;
    CvtToItem(w, xloc, yloc, ul_ret);
    xloc += event->xexpose.width;
    yloc += event->xexpose.height;
    CvtToItem(w, xloc, yloc, lr_ret);
}

/*	Function Name: ItemInRectangle
 *	Description: returns TRUE if the item passed is in the given rectangle.
 *	Arguments: w - the threeList widget.
 *                 ul, lr - corners of the rectangle in item space.
 *                 item - item to check.
 *	Returns: TRUE if the item passed is in the given rectangle.
 */

static Boolean
ItemInRectangle(w, ul, lr, item)
Widget w;
int ul, lr, item;
{
    ThreeListWidget lw = (ThreeListWidget) w;
    int mod_item;
    int things;
    
    if (item < ul || item > lr) 
        return(FALSE);
    if (lw->threeList.vertical_cols)
        things = lw->threeList.nrows;
    else
        things = lw->threeList.ncols;

    mod_item = item % things;
    if ( (mod_item >= ul % things) && (mod_item <= lr % things ) )
        return(TRUE);
    return(FALSE);
}


/* HighlightBackground()
 *
 * Paints the color of the background for the given item.  It performs
 * clipping to the interior of internal_width/height by hand, as its a
 * simple calculation and probably much faster than using Xlib and a clip mask.
 *
 *  x, y - ul corner of the area item occupies.
 *  gc - the gc to use to paint this rectangle */

static void
HighlightBackground( w, x, y, gc )
Widget w;
int x, y;
GC gc;
{
    ThreeListWidget lw = (ThreeListWidget) w;

    /* easy to clip the rectangle by hand and probably alot faster than Xlib */

    Dimension width               = lw->threeList.col_width;
    Dimension height              = lw->threeList.row_height;
    Dimension frame_limited_width = w->core.width - lw->threeList.internal_width - x;
    Dimension frame_limited_height= w->core.height- lw->threeList.internal_height- y;

    /* Clip the rectangle width and height to the edge of the drawable area */

    if  ( width > frame_limited_width )
        width = frame_limited_width;
    if  ( height> frame_limited_height)
        height = frame_limited_height;

    /* Clip the rectangle x and y to the edge of the drawable area */

    if ( x < lw->threeList.internal_width ) {
        width = width - ( lw->threeList.internal_width - x );
        x = lw->threeList.internal_width;
    }
    if ( y < lw->threeList.internal_height) {
        height = height - ( lw->threeList.internal_height - x );
        y = lw->threeList.internal_height;
    }
    XFillRectangle( XtDisplay( w ), XtWindow( w ), gc, x, y,
		    width, height );
}


/* ClipToShadowInteriorAndLongest()
 *
 * Converts the passed gc so that any drawing done with that GC will not
 * write in the empty margin (specified by internal_width/height) (which also
 * prevents erasing the shadow.  It also clips against the value longest.
 * If the user doesn't set longest, this has no effect (as longest is the
 * maximum of all item lengths).  If the user does specify, say, 80 pixel
 * columns, though, this prevents items from overwriting other items. */

static void ClipToShadowInteriorAndLongest(lw, gc_p, x)
    ThreeListWidget lw; 
    GC* gc_p;
    Dimension x;
{
    XRectangle rect;

    rect.x = x;
    rect.y = lw->threeList.internal_height;
    rect.height = lw->core.height - lw->threeList.internal_height * 2;
    rect.width = lw->core.width - lw->threeList.internal_width - x;
    if ( rect.width > lw->threeList.longest )
        rect.width = lw->threeList.longest;

    XSetClipRectangles( XtDisplay((Widget)lw),*gc_p,0,0,&rect,1,YXBanded );
}


/*  PaintItemName()
 *
 *  paints the name of the item in the appropriate location.
 *  w - the threeList widget.
 *  item - the item to draw.
 *
 *  NOTE: no action taken on an unrealized widget. */

static void
PaintItemName(w, item)
Widget w;
int item;
{
    char * str;
    GC gc;
    int x, y, str_y;
    ThreeListWidget lw = (ThreeListWidget) w;
    XFontSetExtents *ext  = XExtentsOfFontSet(lw->threeList.fontset);

    if (!XtIsRealized(w)) return; /* Just in case... */

    if (lw->threeList.vertical_cols) {
	x = lw->threeList.col_width * (item / lw->threeList.nrows)
	  + lw->threeList.internal_width;
        y = lw->threeList.row_height * (item % lw->threeList.nrows)
	  + lw->threeList.internal_height;
    }
    else {
        x = lw->threeList.col_width * (item % lw->threeList.ncols)
	  + lw->threeList.internal_width;
        y = lw->threeList.row_height * (item / lw->threeList.ncols)
	  + lw->threeList.internal_height;
    }

#ifdef X11R6
    if ( lw->simple.international == True )
        str_y = y + abs(ext->max_ink_extent.y); 
    else
#endif
        str_y = y + lw->threeList.font->max_bounds.ascent;

    if (item == lw->threeList.is_highlighted) {
        if (item == lw->threeList.highlight) {
            gc = lw->threeList.revgc;
	    HighlightBackground(w, x, y, lw->threeList.normgc);
	}
        else {
	    if (XtIsSensitive(w)) 
	        gc = lw->threeList.normgc;
	    else
	        gc = lw->threeList.graygc;
	    HighlightBackground(w, x, y, lw->threeList.revgc);
	    lw->threeList.is_highlighted = NO_HIGHLIGHT;
        }
    }
    else {
        if (item == lw->threeList.highlight) {
            gc = lw->threeList.revgc;
	    HighlightBackground(w, x, y, lw->threeList.normgc);
	    lw->threeList.is_highlighted = item;
	}
	else {
	    if (XtIsSensitive(w)) 
	        gc = lw->threeList.normgc;
	    else
	        gc = lw->threeList.graygc;
	}
    }

    /* ThreeList's overall width contains the same number of inter-column
    column_space's as columns.  There should thus be a half
    column_width margin on each side of each column.
    The row case is symmetric. */

    x     += lw->threeList.column_space / 2;
    str_y += lw->threeList.row_space    / 2;

    str =  lw->threeList.threeList[item];	/* draw it */

    ClipToShadowInteriorAndLongest( lw, &gc, x );

#ifdef X11R6
    if ( lw->simple.international == True )
        XmbDrawString( XtDisplay( w ), XtWindow( w ), lw->threeList.fontset,
		  gc, x, str_y, str, strlen( str ) );
    else
#endif
        XDrawString( XtDisplay( w ), XtWindow( w ),
		  gc, x, str_y, str, strlen( str ) );

    XSetClipMask( XtDisplay( w ), gc, None );
}

    
/* Redisplay()
 *
 * Repaints the widget window on expose events.
 * w - the threeList widget.
 * event - the expose event for this repaint.
 * junk - not used, unless three-d patch enabled. */

/* ARGSUSED */
static void 
Redisplay(w, event, junk)
Widget w;
XEvent *event;
Region junk;
{
    int item;			/* an item to work with. */
    int ul_item, lr_item;       /* corners of items we need to paint. */
    ThreeListWidget lw = (ThreeListWidget) w;

    if (event == NULL) {	/* repaint all. */
        ul_item = 0;
	lr_item = lw->threeList.nrows * lw->threeList.ncols - 1;
	XClearWindow(XtDisplay(w), XtWindow(w));
    }
    else
        FindCornerItems(w, event, &ul_item, &lr_item);
    
    for (item = ul_item; (item <= lr_item && item < lw->threeList.nitems) ; item++)
      if (ItemInRectangle(w, ul_item, lr_item, item))
	PaintItemName(w, item);
}


/* PreferredGeom()
 *
 * This tells the parent what size we would like to be
 * given certain constraints.
 * w - the widget.
 * intended - what the parent intends to do with us.
 * requested - what we want to happen. */

static XtGeometryResult 
PreferredGeom(w, intended, requested)
Widget w;
XtWidgetGeometry *intended, *requested;
{
    Dimension new_width, new_height;
    Boolean change, width_req, height_req;
    
    width_req = intended->request_mode & CWWidth;
    height_req = intended->request_mode & CWHeight;

    if (width_req)
      new_width = intended->width;
    else
      new_width = w->core.width;

    if (height_req)
      new_height = intended->height;
    else
      new_height = w->core.height;

    requested->request_mode = 0;
    
/*
 * We only care about our height and width.
 */

    if ( !width_req && !height_req)
      return(XtGeometryYes);
    
    change = Layout(w, !width_req, !height_req, &new_width, &new_height);

    requested->request_mode |= CWWidth;
    requested->width = new_width;
    requested->request_mode |= CWHeight;
    requested->height = new_height;

    if (change)
        return(XtGeometryAlmost);
    return(XtGeometryYes);
}


/* Resize()
 *
 * resizes the widget, by changing the number of rows and columns. */

static void
Resize(w)
    Widget w;
{
    Dimension width, height;

    width = w->core.width;
    height = w->core.height;

    if (Layout(w, FALSE, FALSE, &width, &height))
	XtAppWarning(XtWidgetToApplicationContext(w),
	   "ThreeList Widget: Size changed when it shouldn't have when resising.");
}


/* Layout()
 *
 * lays out the item in the threeList.
 * w - the widget.
 * xfree, yfree - TRUE if we are free to resize the widget in
 *                this direction.
 * width, height- the is the current width and height that we are going
 *                we are going to layout the list widget to,
 *                depending on xfree and yfree of course.
 *                               
 * RETURNS: TRUE if width or height have been changed. */

static Boolean
Layout(w, xfree, yfree, width, height)
Widget w;
Boolean xfree, yfree;
Dimension *width, *height;
{
    ThreeListWidget lw = (ThreeListWidget) w;
    Boolean change = FALSE;
    
/* 
 * If force columns is set then always use number of columns specified
 * by default_cols.
 */

    if (lw->threeList.force_cols) {
        lw->threeList.ncols = lw->threeList.default_cols;
	if (lw->threeList.ncols <= 0) lw->threeList.ncols = 1;
	/* 12/3 = 4 and 10/3 = 4, but 9/3 = 3 */
	lw->threeList.nrows = ( ( lw->threeList.nitems - 1) / lw->threeList.ncols) + 1 ;
	if (xfree) {		/* If allowed resize width. */

            /* this counts the same number
            of inter-column column_space 's as columns.  There should thus be a
            half column_space margin on each side of each column...*/

	    *width = lw->threeList.ncols * lw->threeList.col_width
	           + 2 * lw->threeList.internal_width;
	    change = TRUE;
	}
	if (yfree) {		/* If allowed resize height. */
	    *height = (lw->threeList.nrows * lw->threeList.row_height)
                    + 2 * lw->threeList.internal_height;
	    change = TRUE;
	}
	return(change);
    }

/*
 * If both width and height are free to change the use default_cols
 * to determine the number columns and set new width and height to
 * just fit the window.
 */

    if (xfree && yfree) {
        lw->threeList.ncols = lw->threeList.default_cols;
	if (lw->threeList.ncols <= 0) lw->threeList.ncols = 1;
	lw->threeList.nrows = ( ( lw->threeList.nitems - 1) / lw->threeList.ncols) + 1 ;
        *width = lw->threeList.ncols * lw->threeList.col_width
	       + 2 * lw->threeList.internal_width;
	*height = (lw->threeList.nrows * lw->threeList.row_height)
                + 2 * lw->threeList.internal_height;
	change = TRUE;
    }
/* 
 * If the width is fixed then use it to determine the number of columns.
 * If the height is free to move (width still fixed) then resize the height
 * of the widget to fit the current threeList exactly.
 */
    else if (!xfree) {
        lw->threeList.ncols = ( (int)(*width - 2 * lw->threeList.internal_width)
	                    / (int)lw->threeList.col_width);
	if (lw->threeList.ncols <= 0) lw->threeList.ncols = 1;
	lw->threeList.nrows = ( ( lw->threeList.nitems - 1) / lw->threeList.ncols) + 1 ;
	if ( yfree ) {
  	    *height = (lw->threeList.nrows * lw->threeList.row_height)
		    + 2 * lw->threeList.internal_height;
	    change = TRUE;
	}
    }
/* 
 * The last case is xfree and !yfree we use the height to determine
 * the number of rows and then set the width to just fit the resulting
 * number of columns.
 */
    else if (!yfree) {		/* xfree must be TRUE. */
        lw->threeList.nrows = (int)(*height - 2 * lw->threeList.internal_height) 
	                 / (int)lw->threeList.row_height;
	if (lw->threeList.nrows <= 0) lw->threeList.nrows = 1;
	lw->threeList.ncols = (( lw->threeList.nitems - 1 ) / lw->threeList.nrows) + 1;
	*width = lw->threeList.ncols * lw->threeList.col_width 
	       + 2 * lw->threeList.internal_width;
	change = TRUE;
    }      
    return(change);
}


/* Notify() - ACTION
 *
 * Notifies the user that a button has been pressed, and
 * calls the callback; if the XtNpasteBuffer resource is true
 * then the name of the item is also put in CUT_BUFFER0.	*/

/* ARGSUSED */
static void
Notify(w, event, params, num_params)
Widget w;
XEvent * event;
String * params;
Cardinal *num_params;
{
    ThreeListWidget lw = ( ThreeListWidget ) w;
    int item, item_len;
    XawThreeListReturnStruct ret_value;

/* 
 * Find item and if out of range then unhighlight and return. 
 * 
 * If the current item is unhighlighted then the user has aborted the
 * notify, so unhighlight and return.
 */

    if ( ((CvtToItem(w, event->xbutton.x, event->xbutton.y, &item))
	  == OUT_OF_RANGE) || (lw->threeList.highlight != item) ) {
        XawThreeListUnhighlight(w);
        return;
    }

    item_len = strlen(lw->threeList.threeList[item]);

    if ( lw->threeList.paste )	/* if XtNpasteBuffer set then paste it. */
        XStoreBytes(XtDisplay(w), lw->threeList.threeList[item], item_len);

/* 
 * Call Callback function.
 */

    ret_value.string = lw->threeList.threeList[item];
    ret_value.threeList_index = item;
    ret_value.event = event->xbutton.state;
    
    XtCallCallbacks( w, XtNcallback, (XtPointer) &ret_value);
}


/* Unset() - ACTION
 *
 * unhighlights the current element. */

/* ARGSUSED */
static void
Unset(w, event, params, num_params)
Widget w;
XEvent * event;
String * params;
Cardinal *num_params;
{
  XawThreeListUnhighlight(w);
}


/* Set() - ACTION
 *
 * Highlights the current element. */

/* ARGSUSED */
static void
Set(w, event, params, num_params)
Widget w;
XEvent * event;
String * params;
Cardinal *num_params;
{
  int item;
  ThreeListWidget lw = (ThreeListWidget) w;

  if ( (CvtToItem(w, event->xbutton.x, event->xbutton.y, &item))
      == OUT_OF_RANGE)
    XawThreeListUnhighlight(w);		        /* Unhighlight current item. */
  else if ( lw->threeList.is_highlighted != item )   /* If this item is not */
    XawThreeListHighlight(w, item);	                /* highlighted then do it. */
}

/*
 * Set specified arguments into widget
 */

static Boolean 
SetValues(current, request, new, args, num_args)
Widget current, request, new;
ArgList args;
Cardinal *num_args;
{
    ThreeListWidget cl = (ThreeListWidget) current;
    ThreeListWidget rl = (ThreeListWidget) request;
    ThreeListWidget nl = (ThreeListWidget) new;
    Boolean redraw = FALSE;
    XFontSetExtents *ext = XExtentsOfFontSet(nl->threeList.fontset);

    /* If the request height/width is different, lock it.  Unless its 0. If */
    /* neither new nor 0, leave it as it was.  Not in R5. */
    if ( nl->core.width != cl->core.width )
        nl->threeList.freedoms |= WidthLock;
    if ( nl->core.width == 0 )
        nl->threeList.freedoms &= ~WidthLock;

    if ( nl->core.height != cl->core.height )
        nl->threeList.freedoms |= HeightLock;
    if ( nl->core.height == 0 )
        nl->threeList.freedoms &= ~HeightLock;

    if ( nl->threeList.longest != cl->threeList.longest )
        nl->threeList.freedoms |= LongestLock;
    if ( nl->threeList.longest == 0 )
        nl->threeList.freedoms &= ~LongestLock;

    /* _DONT_ check for fontset here - it's not in GC.*/

    if (  (cl->threeList.foreground       != nl->threeList.foreground)       ||
	  (cl->core.background_pixel != nl->core.background_pixel) ||
	  (cl->threeList.font             != nl->threeList.font)                ) {
	XGCValues values;
	XGetGCValues(XtDisplay(current), cl->threeList.graygc, GCTile, &values);
	XmuReleaseStippledPixmap(XtScreen(current), values.tile);
	XtReleaseGC(current, cl->threeList.graygc);
	XtReleaseGC(current, cl->threeList.revgc);
	XtReleaseGC(current, cl->threeList.normgc);
        GetGCs(new);
        redraw = TRUE;
    }

    if ( ( cl->threeList.font != nl->threeList.font ) 
#ifdef X11R6
	&& ( cl->simple.international == False ) 
#endif
	)
        nl->threeList.row_height = nl->threeList.font->max_bounds.ascent
	                    + nl->threeList.font->max_bounds.descent
			    + nl->threeList.row_space;

    else if ( ( cl->threeList.fontset != nl->threeList.fontset ) 
#ifdef X11R6
	     && ( cl->simple.international == True ) 
#endif
	     )
        nl->threeList.row_height = ext->max_ink_extent.height + nl->threeList.row_space;

    /* ...If the above two font(set) change checkers above both failed, check
    if row_space was altered.  If one of the above passed, row_height will
    already have been re-calculated. */

    else if ( cl->threeList.row_space != nl->threeList.row_space ) {

#ifdef X11R6
        if (cl->simple.international == True )
            nl->threeList.row_height = ext->max_ink_extent.height + nl->threeList.row_space;
        else
#endif
            nl->threeList.row_height = nl->threeList.font->max_bounds.ascent
	                        + nl->threeList.font->max_bounds.descent
			        + nl->threeList.row_space;
    }

    if ((cl->core.width           != nl->core.width)           ||
	(cl->core.height          != nl->core.height)          ||
	(cl->threeList.internal_width  != nl->threeList.internal_width)  ||
	(cl->threeList.internal_height != nl->threeList.internal_height) ||
	(cl->threeList.column_space    != nl->threeList.column_space)    ||
	(cl->threeList.row_space       != nl->threeList.row_space)       ||
	(cl->threeList.default_cols    != nl->threeList.default_cols)    ||
	(  (cl->threeList.force_cols   != nl->threeList.force_cols) &&
	   (rl->threeList.force_cols   != nl->threeList.ncols) )         ||
	(cl->threeList.vertical_cols   != nl->threeList.vertical_cols)   ||
	(cl->threeList.longest         != nl->threeList.longest)         ||
	(cl->threeList.nitems          != nl->threeList.nitems)          ||
	(cl->threeList.font            != nl->threeList.font)            ||
   /* Equiv. fontsets might have different values, but the same fonts, so the
   next comparison is sloppy but not dangerous.  */
	(cl->threeList.fontset         != nl->threeList.fontset)         ||
	(cl->threeList.threeList            != nl->threeList.threeList)          )   {

        CalculatedValues( new );
        Layout( new, WidthFree( nl ), HeightFree( nl ),
			 &nl->core.width, &nl->core.height );
        redraw = TRUE;
    }

    if (cl->threeList.threeList != nl->threeList.threeList)
	nl->threeList.is_highlighted = nl->threeList.highlight = NO_HIGHLIGHT;

    if ((cl->core.sensitive != nl->core.sensitive) ||
	(cl->core.ancestor_sensitive != nl->core.ancestor_sensitive)) {
        nl->threeList.highlight = NO_HIGHLIGHT;
	redraw = TRUE;
    }
    
    if (!XtIsRealized(current))
      return(FALSE);
      
    return(redraw);
}

static void Destroy(w)
    Widget w;
{
    ThreeListWidget lw = (ThreeListWidget) w;
    XGCValues values;
    
    XGetGCValues(XtDisplay(w), lw->threeList.graygc, GCTile, &values);
    XmuReleaseStippledPixmap(XtScreen(w), values.tile);
    XtReleaseGC(w, lw->threeList.graygc);
    XtReleaseGC(w, lw->threeList.revgc);
    XtReleaseGC(w, lw->threeList.normgc);
}

/* Exported Functions */

/*	Function Name: XawThreeListChange.
 *	Description: Changes the threeList being used and shown.
 *	Arguments: w - the threeList widget.
 *                 threeList - the new threeList.
 *                 nitems - the number of items in the threeList.
 *                 longest - the length (in Pixels) of the longest element
 *                           in the threeList.
 *                 resize - if TRUE the the threeList widget will
 *                          try to resize itself.
 *	Returns: none.
 *      NOTE:      If nitems of longest are <= 0 then they will be calculated.
 *                 If nitems is <= 0 then the threeList needs to be NULL terminated.
 */

void
#if NeedFunctionPrototypes
XawThreeListChange(Widget w, char ** threeList, int nitems, int longest,
#if NeedWidePrototypes
	      int resize_it)
#else
	      Boolean resize_it)
#endif
#else
XawThreeListChange(w, threeList, nitems, longest, resize_it)
Widget w;
char ** threeList;
int nitems, longest;
Boolean resize_it;
#endif
{
    ThreeListWidget lw = (ThreeListWidget) w;
    Dimension new_width = w->core.width;
    Dimension new_height = w->core.height;

    lw->threeList.threeList = threeList;

    if ( nitems <= 0 ) nitems = 0;
    lw->threeList.nitems = nitems;
    if ( longest <= 0 ) longest = 0;

    /* If the user passes 0 meaning "calculate it", it must be free */
    if ( longest != 0 )
        lw->threeList.freedoms |= LongestLock;
    else /* the user's word is god. */
        lw->threeList.freedoms &= ~LongestLock;

    if ( resize_it )
        lw->threeList.freedoms &= ~WidthLock & ~HeightLock;
    /* else - still resize if its not locked */

    lw->threeList.longest = longest;

    CalculatedValues( w );

    if( Layout( w, WidthFree( w ), HeightFree( w ),
		&new_width, &new_height ) )
        ChangeSize( w, new_width, new_height );

    lw->threeList.is_highlighted = lw->threeList.highlight = NO_HIGHLIGHT;
    if ( XtIsRealized( w ) )
      Redisplay( w, (XEvent *)NULL, (Region)NULL );
}

/*	Function Name: XawThreeListUnhighlight
 *	Description: unlights the current highlighted element.
 *	Arguments: w - the widget.
 *	Returns: none.
 */

void
#if NeedFunctionPrototypes
XawThreeListUnhighlight(Widget w)
#else
XawThreeListUnhighlight(w)
Widget w;
#endif
{
    ThreeListWidget lw = ( ThreeListWidget ) w;

    lw->threeList.highlight = NO_HIGHLIGHT;
    if (lw->threeList.is_highlighted != NO_HIGHLIGHT)
        PaintItemName(w, lw->threeList.is_highlighted); /* unhighlight this one. */
}

/*	Function Name: XawThreeListHighlight
 *	Description: Highlights the given item.
 *	Arguments: w - the threeList widget.
 *                 item - the item to hightlight.
 *	Returns: none.
 */

void
#if NeedFunctionPrototypes
XawThreeListHighlight(Widget w, int item)
#else
XawThreeListHighlight(w, item)
Widget w;
int item;
#endif
{
    ThreeListWidget lw = ( ThreeListWidget ) w;
    
    if (XtIsSensitive(w)) {
        lw->threeList.highlight = item;
        if (lw->threeList.is_highlighted != NO_HIGHLIGHT)
            PaintItemName(w, lw->threeList.is_highlighted);  /* Unhighlight. */
	PaintItemName(w, item); /* HIGHLIGHT this one. */ 
    }
}

/*	Function Name: XawThreeListShowCurrent
 *	Description: returns the currently highlighted object.
 *	Arguments: w - the threeList widget.
 *	Returns: the info about the currently highlighted object.
 */

XawThreeListReturnStruct *
#if NeedFunctionPrototypes
XawThreeListShowCurrent(Widget w)
#else
XawThreeListShowCurrent(w)
Widget w;
#endif
{
    ThreeListWidget lw = ( ThreeListWidget ) w;
    XawThreeListReturnStruct * ret_val;

    ret_val = (XawThreeListReturnStruct *) 
	          XtMalloc (sizeof (XawThreeListReturnStruct));/* SPARE MALLOC OK */
    
    ret_val->threeList_index = lw->threeList.highlight;
    if (ret_val->threeList_index == XAW_LIST_NONE)
      ret_val->string = "";
    else
      ret_val->string = lw->threeList.threeList[ ret_val->threeList_index ];

    return(ret_val);
}


/*
 * List Widget Creation Routines and stuff.
 */

static void list_callback(w, data, call_data)
Widget w;
XtPointer data;
XtPointer call_data;
{
  threeListInfo *li = (threeListInfo *)data;
  XawThreeListReturnStruct *list = (XawThreeListReturnStruct *)call_data;

  if (li->func)
    li->func(w, list->string, list->threeList_index, list->event, li->data);
}



Widget MakeThreeList(item_list, width, height, func, data)
char **item_list;
int width;
int height;
ThreeListCB func;
void *data;
{
  int    n = 0;
  Arg    wargs[10];		/* Used to set widget resources */
  Widget list, vport;
  threeListInfo *li;

  if (lsx_curwin->toplevel == NULL && OpenDisplay(0, NULL) == 0)
    return NULL;

  n = 0;
  XtSetArg(wargs[n], XtNwidth,  width);             n++;
  XtSetArg(wargs[n], XtNheight, height);            n++;
  XtSetArg(wargs[n], XtNallowVert, True);           n++;
  XtSetArg(wargs[n], XtNallowHoriz, True);          n++;
  XtSetArg(wargs[n], XtNuseBottom, True);           n++;

  vport = XtCreateManagedWidget("vport", viewportWidgetClass,
			       lsx_curwin->form_widget,wargs,n);
  if (vport == NULL)
    return NULL;

  n = 0;
  XtSetArg(wargs[n], XtNlist,   item_list);         n++;
  XtSetArg(wargs[n], XtNverticalList, True);        n++;
  XtSetArg(wargs[n], XtNforceColumns, True);        n++;
  XtSetArg(wargs[n], XtNdefaultColumns, 1);         n++;
  XtSetArg(wargs[n], XtNborderWidth, 1);            n++;
  
  /*
   * Here we create the list widget and make it the child of the
   * viewport widget so that the viewport will properly handle scrolling
   * it and all that jazz.
   */
  list = XtCreateManagedWidget("threeList", threeListWidgetClass,
			       vport,wargs,n);
  if (list == NULL)
   {
     XtDestroyWidget(vport);
     return NULL;
   }

  li = (threeListInfo *)malloc(sizeof(threeListInfo));
  if (li == NULL)
   {
     XtDestroyWidget(list);
     XtDestroyWidget(vport);
     return NULL;
   }

  li->func = func;
  li->data = data;
  li->w    = list;

  li->next = scroll_threeLists;
  scroll_threeLists = li;

  if (func)
    XtAddCallback(list, XtNcallback, list_callback, li);

  return list;
}    /* end of MakeScrollList() */


