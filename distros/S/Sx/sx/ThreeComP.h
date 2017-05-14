/*
* $XConsortium: ThreeComP.h,v 1.30 90/12/01 13:00:10 rws Exp $
*/


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
 * ThreeComP.h - Private definitions for ThreeCom widget
 * 
 */

#ifndef _XawThreeComP_h
#define _XawThreeComP_h

#include "ThreeCom.h"
#ifdef XAW3D
#include <X11/Xaw3d/LabelP.h>
#else
#include <X11/Xaw/LabelP.h>
#endif

/***********************************************************************
 *
 * ThreeCom Widget Private Data
 *
 ***********************************************************************/

typedef enum {
  HighlightNone,		/* Do not highlight. */
  HighlightWhenUnset,		/* Highlight only when unset, this is
				   to preserve current threeCom widget 
				   functionality. */
  HighlightAlways		/* Always highlight, lets the toggle widget
				   and other subclasses do the right thing. */
} XtThreeComHighlight;

/************************************
 *
 *  Class structure
 *
 ***********************************/


   /* New fields for the ThreeCom widget class record */
typedef struct _ThreeComClass 
  {
    int makes_compiler_happy;  /* not used */
  } ThreeComClassPart;

   /* Full class record declaration */
typedef struct _ThreeComClassRec {
    CoreClassPart	core_class;
    SimpleClassPart	simple_class;
#ifdef XAW3D
    ThreeDClassPart	threeD_class;
#endif
    LabelClassPart	label_class;
    ThreeComClassPart    threeCom_class;
} ThreeComClassRec;

extern ThreeComClassRec threeComClassRec;

/***************************************
 *
 *  Instance (widget) structure 
 *
 **************************************/

    /* New fields for the ThreeCom widget record */
typedef struct {
    /* resources */
    Dimension   highlight_thickness;
    XtCallbackList callbacks1;
    XtCallbackList callbacks2;
    XtCallbackList callbacks3;

    /* private state */
    Pixmap      	gray_pixmap;
    GC          	normal_GC;
    GC          	inverse_GC;
    Boolean     	set;
    XtThreeComHighlight	highlighted;
    /* more resources */
    int			shape_style;    
    Dimension		corner_round;
} ThreeComPart;


/*    XtEventsPtr eventTable;*/


   /* Full widget declaration */
typedef struct _ThreeComRec {
    CorePart         core;
    SimplePart	     simple;
#ifdef XAW3D
    ThreeDPart       threeD;
#endif
    LabelPart	     label;
    ThreeComPart      threeCom;
} ThreeComRec;

#endif /* _XawThreeComP_h */


