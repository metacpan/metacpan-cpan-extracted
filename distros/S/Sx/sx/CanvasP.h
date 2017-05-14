/*

    CanvasP.h - private header file for the Canvas Widget
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

#ifndef _CanvasP_h
#define _CanvasP_h

#ifndef XAW3D
# include <X11/Xaw/SimpleP.h>
#else  /* XAW3D */
# include <X11/Xaw3d/ThreeDP.h>
# include <X11/Xaw3d/SimpleP.h>
#endif /* XAW3D */
#include "Canvas.h"

typedef struct _CanvasClassRec {
    CoreClassPart	core_class;
    SimpleClassPart	simple_class;
#ifdef    XAW3D
    ThreeDClassPart threeD_class;
#endif /* XAW3D */
} CanvasClassRec;

extern CanvasClassRec canvasClassRec;

typedef struct {
    XtCallbackList      realize;
    XtCallbackList	redraw;
    XtCallbackList	resize;
} CanvasPart;

typedef struct _CanvasRec {
    CorePart		core;
    SimplePart          simple;
#ifdef    XAW3D
    ThreeDPart threeD;
#endif /* XAW3D */
    CanvasPart          canvas;
} CanvasRec;

#endif /* _CanvasP_h */
