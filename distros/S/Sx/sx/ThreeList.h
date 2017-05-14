/* $XConsortium: ThreeList.h,v 1.22 94/04/17 20:12:17 kaleb Exp $ */

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

/*  This is the ThreeList widget, it is useful to display a threeList, without the
 *  overhead of having a widget for each item in the threeList.  It allows 
 *  the user to select an item in a threeList and notifies the application through
 *  a callback function.
 *
 *	Created: 	8/13/88
 *	By:		Chris D. Peterson
 *                      MIT X Consortium
 */

#ifndef _XawThreeList_h
#define _XawThreeList_h

/***********************************************************************
 *
 * ThreeList Widget
 *
 ***********************************************************************/

#ifdef XAW3D
#include <X11/Xaw3d/Simple.h>
#else
#include <X11/Xaw/Simple.h>
#endif

/* Resources:

 Name		     Class		RepType		Default Value
 ----		     -----		-------		-------------
 background	     Background		Pixel		XtDefaultBackground
 border		     BorderColor	Pixel		XtDefaultForeground
 borderWidth	     BorderWidth	Dimension	1
 callback            Callback           XtCallbackList  NULL       **6
 columnSpacing       Spacing            Dimension       6
 cursor		     Cursor		Cursor		left_ptr
 cursorName	     Cursor		String		NULL
 defaultColumns      Columns            int             2          **5
 destroyCallback     Callback		Pointer		NULL 
 font		     Font		XFontStruct*	XtDefaultFont
 forceColumns        Columns            Boolean         False      **5
 foreground	     Foreground		Pixel		XtDefaultForeground
 height		     Height		Dimension	0          **1
 insensitiveBorder   Insensitive	Pixmap		Gray
 internalHeight	     Height		Dimension	2
 internalWidth	     Width		Dimension	4
 threeList                List               String *        NULL       **2
 longest             Longest            int             0          **3  **4
 mappedWhenManaged   MappedWhenManaged	Boolean		True
 numberStrings       NumberStrings      int             0          **4
 pasteBuffer         Boolean            Boolean         False
 pointerColor	     Foreground		Pixel		XtDefaultForeground
 pointerColorBackground Background	Pixel		XtDefaultBackground
 rowSpacing          Spacing            Dimension       4
 sensitive	     Sensitive		Boolean		True
 verticalList        Boolean            Boolean         False
 width		     Width		Dimension	0          **1
 x		     Position		Position	0
 y		     Position		Position	0

 **1 - If the Width or Height of the threeList widget is zero (0) then the value
       is set to the minimum size necessay to fit the entire threeList.

       If both Width and Height are zero then they are adjusted to fit the
       entire threeList that is created width the number of default columns 
       specified in the defaultColumns resource.

 **2 - This is an array of strings the specify elements of the threeList.
       This resource must be specified. 
       (What good is a threeList widget without a threeList??  :-)

 **3 - Longest is the length of the widest string in pixels.

 **4 - If either of these values are zero (0) then the threeList widget calculates
       the correct value. 

       (This allows you to make startup faster if you already have 
        this information calculated)

       NOTE: If the numberStrings value is zero the threeList must 
             be NULL terminated.

 **5 - By setting the ThreeList.Columns resource you can force the application to
       have a given number of columns.	     
        
 **6 - This returns the name and index of the item selected in an 
       XawThreeListReturnStruct that is pointed to by the client_data
       in the CallbackProc.

*/


/*
 * Value returned when there are no highlighted objects. 
 */

#define XAW_LIST_NONE -1	

#define XtCList "ThreeList"
#define XtCSpacing "Spacing"
#define XtCColumns "Columns"
#define XtCLongest "Longest"
#define XtCNumberStrings "NumberStrings"

#define XtNcursor "cursor"
#define XtNcolumnSpacing "columnSpacing"
#define XtNdefaultColumns "defaultColumns"
#define XtNforceColumns "forceColumns"
#define XtNlist "threeList"
#define XtNlongest "longest"
#define XtNnumberStrings "numberStrings"
#define XtNpasteBuffer "pasteBuffer"
#define XtNrowSpacing "rowSpacing"
#define XtNverticalList "verticalList"
 
#ifndef XtNfontSet
#define XtNfontSet "fontSet"
#endif

#ifndef XtCFontSet
#define XtCFontSet "FontSet"
#endif

/* Class record constants */

extern WidgetClass threeListWidgetClass;

typedef struct _ThreeListClassRec *ThreeListWidgetClass;
typedef struct _ThreeListRec      *ThreeListWidget;

/* The threeList return structure. */

typedef struct _XawThreeListReturnStruct {
  String string;
  int threeList_index;
  unsigned int event;
} XawThreeListReturnStruct;

/******************************************************************
 *
 * Exported Functions
 *
 *****************************************************************/

_XFUNCPROTOBEGIN

/*	Function Name: XawThreeListChange.
 *	Description: Changes the threeList being used and shown.
 *	Arguments: w - the threeList widget.
 *                 list - the new list.
 *                 nitems - the number of items in the list.
 *                 longest - the length (in Pixels) of the longest element
 *                           in the list.
 *                 resize - if TRUE the the list widget will
 *                          try to resize itself.
 *	Returns: none.
 *      NOTE:      If nitems of longest are <= 0 then they will be caluculated.
 *                 If nitems is <= 0 then the list needs to be NULL terminated.
 */

extern void XawThreeListChange(
#if NeedFunctionPrototypes
    Widget		/* w */,
    String*		/* list */,
    int			/* nitems */,
    int			/* longest */,
#if NeedWidePrototypes
    /* Boolean */ int	/* resize */
#else
    Boolean		/* resize */
#endif
#endif
);

/*	Function Name: XawThreeListUnhighlight
 *	Description: unlights the current highlighted element.
 *	Arguments: w - the widget.
 *	Returns: none.
 */

extern void XawThreeListUnhighlight(
#if NeedFunctionPrototypes
    Widget		/* w */
#endif
);

/*	Function Name: XawThreeListHighlight
 *	Description: Highlights the given item.
 *	Arguments: w - the list widget.
 *                 item - the item to highlight.
 *	Returns: none.
 */

extern void XawThreeListHighlight(
#if NeedFunctionPrototypes
    Widget		/* w */,
    int			/* item */
#endif
);


/*	Function Name: XawThreeListShowCurrent
 *	Description: returns the currently highlighted object.
 *	Arguments: w - the list widget.
 *	Returns: the info about the currently highlighted object.
 */

extern XawThreeListReturnStruct * XawThreeListShowCurrent(
#if NeedFunctionPrototypes
    Widget		/* w */
#endif
);

_XFUNCPROTOEND

#endif /* _XawThreeList_h */
