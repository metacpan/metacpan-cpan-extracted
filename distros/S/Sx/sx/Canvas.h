/*

    Canvas.h - public header file for the Canvas Widget
    -  a widget that allows programmer-specified refresh procedures.
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

#ifndef _Canvas_h
#define _Canvas_h

#include <X11/Xaw/Simple.h>

/* Resources:

 Name		     Class		RepType		Default Value
 ----		     -----		-------		-------------
 background	     Background		Pixel		XtDefaultBackground
 border		     BorderColor	Pixel		XtDefaultForeground
 borderWidth	     BorderWidth	Dimension	1
 cursor		     Cursor		Cursor		None
 cursorName	     Cursor		String		NULL
 destroyCallback     Callback		XtCallbackList	NULL
 expose              Callback           XtCallbackList  NULL
 height		     Height		Dimension	text height
 insensitiveBorder   Insensitive	Pixmap		Gray
 mappedWhenManaged   MappedWhenManaged	Boolean		True
 pointerColor	     Foreground		Pixel		XtDefaultForeground
 pointerColorBackground Background	Pixel		XtDefaultBackground
 realize             Callback           XtCallbackList  NULL
 resize              Callback           XtCallbackList  NULL
 sensitive	     Sensitive		Boolean		True
 width		     Width		Dimension	text width
 x		     Position		Position	0
 y		     Position		Position	0

*/

#define	XtNexposeCallback		"exposeCallback"
#define XtNrealizeCallback              "realizeCallback"
#define XtNresizeCallback               "resizeCallback"

extern WidgetClass canvasWidgetClass;

typedef struct _CanvasClassRec *CanvasWidgetClass;
typedef struct _CanvasRec      *CanvasWidget;

#endif /* _Canvas_h */



