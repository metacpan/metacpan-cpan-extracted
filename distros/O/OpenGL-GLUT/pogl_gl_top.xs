/*  Last saved: Mon 27 Feb 2017 01:28:45 PM */

/*  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 2009,2017 Chris Marshall. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

/* OpenGL GLX bindings */
#define IN_POGL_GLX_XS

#include <stdio.h>

#include "pgopogl.h"

#ifdef HAVE_GL
#include "gl_util.h"

/* Note: this is caching procs once for all contexts */
/* !!! This should instead cache per context */
#if defined(_WIN32) || (defined(__CYGWIN__) && defined(HAVE_W32API))
#define loadProc(proc,name) \
{ \
  if (!proc) \
  { \
    proc = (void *)wglGetProcAddress(name); \
    if (!proc) croak(name " is not supported by this renderer"); \
  } \
}
#define testProc(proc,name) ((proc) ? 1 : !!(proc = (void *)wglGetProcAddress(name)))
#else /* not using WGL */
#define loadProc(proc,name)
#define testProc(proc,name) 1
#endif /* not defined _WIN32, __CYGWIN__, and HAVE_W32API */
#endif /* defined HAVE_GL */


MODULE = OpenGL::GLUT::GL::Top		PACKAGE = OpenGL::GLUT


#// Test for GL
int
_have_gl()
	CODE:
#ifdef HAVE_GL
	RETVAL = 1;
#else
	RETVAL = 0;
#endif /* defined HAVE_GL */
	OUTPUT:
	RETVAL

#// Test for GLU
int
_have_glu()
	CODE:
#ifdef HAVE_GLU
	RETVAL = 1;
#else
	RETVAL = 0;
#endif /* defined HAVE_GLU */
	OUTPUT:
	RETVAL

#// Test for GLUT
int
_have_glut()
	CODE:
#if defined(HAVE_GLUT) || defined(HAVE_FREEGLUT)
	RETVAL = 1;
#else
	RETVAL = 0;
#endif /* defined HAVE_GLUT or HAVE_FREEGLUT */
	OUTPUT:
	RETVAL

#// Test for FreeGLUT
int
_have_freeglut()
	CODE:
#if defined(HAVE_FREEGLUT)
	RETVAL = 1;
#else
	RETVAL = 0;
#endif /* defined HAVE_FREEGLUT */
	OUTPUT:
	RETVAL

#// Test for GLX
int
_have_glx()
	CODE:
#ifdef HAVE_GLX
	RETVAL = 1;
#else
	RETVAL = 0;
#endif /* defined HAVE_GLX */
	OUTPUT:
	RETVAL

#// Test for GLpc
int
_have_glp()
	CODE:
#ifdef HAVE_GLpc
	RETVAL = 1;
#else
	RETVAL = 0;
#endif /* defined HAVE_GLpc */
	OUTPUT:
	RETVAL





# /* 13000 lines snipped */

##################### GLU #########################


############################## GLUT #########################


# /* This is assigned to GLX for now.  The glp*() functions should be split out */
