/* $XConsortium: ThreeListP.h,v 1.14 94/04/17 20:12:17 kaleb Exp $ */

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
 * ThreeListP.h - Private definitions for ThreeList widget
 * 
 * This is a ThreeList widget.  It allows the user to select an item in a threeList and
 * notifies the application through a callback function.
 *
 *	Created: 	8/13/88
 *	By:		Chris D. Peterson
 *                      MIT - Project Athena
 */

#ifndef _XawThreeListP_h
#define _XawThreeListP_h

/***********************************************************************
 *
 * ThreeList Widget Private Data
 *
 ***********************************************************************/

#ifdef XAW3D
#include <X11/Xaw3d/SimpleP.h>
#else
#include <X11/Xaw/SimpleP.h>
#endif
#include "ThreeList.h"

#define NO_HIGHLIGHT            XAW_LIST_NONE
#define OUT_OF_RANGE            -1
#define OKAY                     0

/* New fields for the ThreeList widget class record */

typedef struct {int foo;} ThreeListClassPart;

/* Full class record declaration */
typedef struct _ThreeListClassRec {
    CoreClassPart	core_class;
    SimpleClassPart	simple_class;
    ThreeListClassPart	threeList_class;
} ThreeListClassRec;

extern ThreeListClassRec threeListClassRec;

/* New fields for the ThreeList widget record */
typedef struct {
    /* resources */
    Pixel	foreground;
    Dimension	internal_width, /* if not 3d, user sets directly. */
        	internal_height,
                column_space,	/* half of *_space is add on top/bot/left of*/
                row_space;	/* each item's text bounding box. half added to longest for right */
    int         default_cols;
    Boolean     force_cols,
                paste,
                vertical_cols;
    int         longest;	/* in pixels */
    int         nitems;		/* number of items in the threeList. */
    XFontStruct	*font;
    XFontSet 	fontset;	/* Sheeran, Omron KK, 93/03/05 */
    String *    threeList;		/* for i18n, always in multibyte format */
    XtCallbackList callback;

    /* private state */
    int         is_highlighted,	/* set to the item currently highlighted. */
                highlight,	/* set to the item that should be highlighted.*/
                col_width,	/* width of each column. */
                row_height,	/* height of each row. */
                nrows,		/* number of rows in the threeList. */
                ncols;		/* number of columns in the threeList. */
    GC		normgc,		/* a couple of GC's. */
                revgc,
                graygc;		/* used when inactive. */

    int         freedoms;       /* flags for resizing height and width */

} ThreeListPart;


/****************************************************************
 *
 * Full instance record declaration
 *
 ****************************************************************/

typedef struct _ThreeListRec {
    CorePart	core;
    SimplePart	simple;
    ThreeListPart	threeList;
} ThreeListRec;

#endif /* _XawThreeListP_h */
