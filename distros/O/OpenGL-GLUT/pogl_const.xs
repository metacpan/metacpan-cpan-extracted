/*  Last saved: Mon 27 Feb 2017 01:28:31 PM */

/*  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 2009,2017 Chris Marshall. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

/* All OpenGL constants---should split */
#define IN_POGL_CONST_XS

/* This ends up being OpenGL.pm */
/* #define IN_POGL_MAIN_XS */

#include <stdio.h>

#include "pgopogl.h"


#ifdef HAVE_GL
#include "gl_util.h"
#endif

#if defined(HAVE_GLUT) || defined(HAVE_FREEGLUT)
#ifndef GLUT_API_VERSION
#define GLUT_API_VERSION 4
#endif
#include "glut_util.h"
#endif

#ifdef IN_POGL_CONST_XS

/* These macros used in neoconstant */
#define i(test) if (strEQ(name, #test)) return newSViv((int)test);
#define f(test) if (strEQ(name, #test)) return newSVnv((double)test);
#define p(test) if (strEQ(name, #test)) return newSViv(PTR2IV(test));

static SV *
neoconstant(char * name, int arg)
{
#include "glut_const.h"
	;
	return 0;
}

#undef i
#undef f

#endif /* defined IN_POGL_CONST_XS */


MODULE = OpenGL::GLUT::Const		PACKAGE = OpenGL::GLUT

#ifdef IN_POGL_CONST_XS

#// Define a POGL Constant
SV *
constant(name,arg)
	char *	name
	int	arg
	CODE:
	{
		RETVAL = neoconstant(name, arg);
		if (!RETVAL)
			RETVAL = newSVsv(&PL_sv_undef);
	}
	OUTPUT:
	RETVAL

#endif /* End IN_POGL_CONST_XS */
