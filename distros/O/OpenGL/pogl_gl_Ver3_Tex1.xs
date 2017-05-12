/*  Last saved: Sun 06 Sep 2009 02:10:11 PM */

/*  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 2009 Chris Marshall. All rights reserved.
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

#ifdef HAVE_GLX
#include "glx_util.h"
#endif /* defined HAVE_GLX */

#ifdef HAVE_GLU
#include "glu_util.h"
#endif /* defined HAVE_GLU */





MODULE = OpenGL::GL::Ver3Tex1	PACKAGE = OpenGL





#ifdef HAVE_GL

#//# glVertex3d($x, $y, $z);
void
glVertex3d(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z

#//# glVertex3dv_c((CPTR)v);
void
glVertex3dv_c(v)
	void *	v
	CODE:
	glVertex3dv(v);

#//# glVertex3dv_s((PACKED)v);
void
glVertex3dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*3);
		glVertex3dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex3d
#//# glVertex3dv_p($x, $y, $z);
void
glVertex3dv_p(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z
	CODE:
	{
		GLdouble param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertex3dv(param);
	}

#//# glVertex3f($x, $y, $z);
void
glVertex3f(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z

#//# glVertex3fv_c((CPTR)v);
void
glVertex3fv_c(v)
	void *	v
	CODE:
	glVertex3fv(v);

#//# glVertex3fv_s((PACKED)v);
void
glVertex3fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*3);
		glVertex3fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex3f
#//# glVertex3fv_p($x, $y, $z);
void
glVertex3fv_p(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z
	CODE:
	{
		GLfloat param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertex3fv(param);
	}

#//# glVertex3i(x, y, z);
void
glVertex3i(x, y, z)
	GLint	x
	GLint	y
	GLint	z

#//# glVertex3iv_c((CPTR)v);
void
glVertex3iv_c(v)
	void *	v
	CODE:
	glVertex3iv(v);

#//# glVertex3iv_s((PACKED)v);
void
glVertex3iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*3);
		glVertex3iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex3i
#//# glVertex3iv_p($x, $y, $z);
void
glVertex3iv_p(x, y, z)
	GLint	x
	GLint	y
	GLint	z
	CODE:
	{
		GLint param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertex3iv(param);
	}

#//# glVertex3s($x, $y, $z);
void
glVertex3s(x, y, z)
	GLshort	x
	GLshort	y
	GLshort	z

#//# glVertex3sv_c((CPTR)v);
void
glVertex3sv_c(v)
	void *	v
	CODE:
	glVertex3sv(v);

#//# glVertex3sv_s((PACKED)v);
void
glVertex3sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*3);
		glVertex3sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex3s
#//# glVertex3sv_p($x, $y, $z);
void
glVertex3sv_p(x, y, z)
	GLshort	x
	GLshort	y
	GLshort	z
	CODE:
	{
		GLshort param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertex3sv(param);
	}

#//# glVertex4d($x, $y, $z, $w);
void
glVertex4d(x, y, z, w)
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w

#//# glVertex4dv_c((CPTR)v);
void
glVertex4dv_c(v)
	void *	v
	CODE:
	glVertex4dv(v);

#//# glVertex4dv_s((PACKED)v);
void
glVertex4dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glVertex4dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex4d
#//# glVertex4dv_p($x, $y, $z, $w);
void
glVertex4dv_p(x, y, z, w)
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w
	CODE:
	{
		GLdouble param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertex4dv(param);
	}

#//# glVertex4f($x, $y, $z, $w);
void
glVertex4f(x, y, z, w)
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w

#//# glVertex4fv_c((CPTR)v);
void
glVertex4fv_c(v)
	void *	v
	CODE:
	glVertex4fv(v);

#//# glVertex4fv_s((PACKED)v);
void
glVertex4fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glVertex4fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex4f
#//# glVertex4fv_p($x, $y, $z, $w);
void
glVertex4fv_p(x, y, z, w)
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w
	CODE:
	{
		GLfloat param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertex4fv(param);
	}

#//# glVertex4i($x, $y, $z, $w);
void
glVertex4i(x, y, z, w)
	GLint	x
	GLint	y
	GLint	z
	GLint	w

#//# glVertex4iv_c((CPTR)v);
void
glVertex4iv_c(v)
	void *	v
	CODE:
	glVertex4iv(v);

#//# glVertex4iv_s((PACKED)v);
void
glVertex4iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glVertex4iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex4i
#//# glVertex4iv_p($x, $y, $z, $w);
void
glVertex4iv_p(x, y, z, w)
	GLint	x
	GLint	y
	GLint	z
	GLint	w
	CODE:
	{
		GLint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertex4iv(param);
	}

#//# glVertex4s($x, $y, $z, $w);
void
glVertex4s(x, y, z, w)
	GLshort	x
	GLshort	y
	GLshort	z
	GLshort	w

#//# glVertex4sv_s((PACKED)v);
void
glVertex4sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glVertex4sv(v_s);
	}

#//# glVertex4sv_c((CPTR)v);
void
glVertex4sv_c(v)
	void *	v
	CODE:
	glVertex4sv(v);

#//!!! Do we really need this?  It duplicates glVertex4s
#//# glVertex4sv_p($x, $y, $z, $w);
void
glVertex4sv_p(x, y, z, w)
	GLshort	x
	GLshort	y
	GLshort	z
	GLshort	w
	CODE:
	{
		GLshort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertex4sv(param);
	}

#//# glNormal3b($nx, $ny, $nz);
void
glNormal3b(nx, ny, nz)
	GLbyte	nx
	GLbyte	ny
	GLbyte	nz

#//# glNormal3bv_c((CPTR)v);
void
glNormal3bv_c(v)
	void *	v
	CODE:
	glNormal3bv(v);

#//# glNormal3bv_s((PACKED)v);
void
glNormal3bv_s(v)
	SV *	v
	CODE:
	{
		GLbyte * v_s = EL(v, sizeof(GLbyte)*3);
		glNormal3bv(v_s);
	}

#//!!! Do we really need this?  It duplicates glNormal3b
#//# glNormal3bv_p($nx, $ny, $nz);
void
glNormal3bv_p(nx, ny, nz)
	GLbyte	nx
	GLbyte	ny
	GLbyte	nz
	CODE:
	{
		GLbyte param[3];
		param[0] = nx;
		param[1] = ny;
		param[2] = nz;
		glNormal3bv(param);
	}

#//# glNormal3d($nx, $ny, $nz);
void
glNormal3d(nx, ny, nz)
	GLdouble	nx
	GLdouble	ny
	GLdouble	nz

#//# glNormal3dv_c((CPTR)v);
void
glNormal3dv_c(v)
	void *	v
	CODE:
	glNormal3dv(v);

#//# glNormal3dv_s((PACKED)v);
void
glNormal3dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*3);
		glNormal3dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glNormal3d
#//# glNormal3dv_p($nx, $ny, $nz);
void
glNormal3dv_p(nx, ny, nz)
	GLdouble	nx
	GLdouble	ny
	GLdouble	nz
	CODE:
	{
		GLdouble param[3];
		param[0] = nx;
		param[1] = ny;
		param[2] = nz;
		glNormal3dv(param);
	}

#//# glNormal3f($nx, $ny, $nz);
void
glNormal3f(nx, ny, nz)
	GLfloat	nx
	GLfloat	ny
	GLfloat	nz

#//# glNormal3fv_c((CPTR)v);
void
glNormal3fv_c(v)
	void *	v
	CODE:
	glNormal3fv(v);

#//# glNormal3fv_s((PACKED)v);
void
glNormal3fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*3);
		glNormal3fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glNormal3f
#//# glNormal3fv_p($nx, $ny, $nz);
void
glNormal3fv_p(nx, ny, nz)
	GLfloat	nx
	GLfloat	ny
	GLfloat	nz
	CODE:
	{
		GLfloat param[3];
		param[0] = nx;
		param[1] = ny;
		param[2] = nz;
		glNormal3fv(param);
	}

#//# glNormal3i($nx, $ny, $nz);
void
glNormal3i(nx, ny, nz)
	GLint	nx
	GLint	ny
	GLint	nz

#//# glNormal3iv_c((CPTR)v);
void
glNormal3iv_c(v)
	void *	v
	CODE:
	glNormal3iv(v);

#//# glNormal3iv_s((PACKED)v);
void
glNormal3iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*3);
		glNormal3iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glNormal3i
#//# glNormal3iv_p($nx, $ny, $nz);
void
glNormal3iv_p(nx, ny, nz)
	GLint	nx
	GLint	ny
	GLint	nz
	CODE:
	{
		GLint param[3];
		param[0] = nx;
		param[1] = ny;
		param[2] = nz;
		glNormal3iv(param);
	}

#//# glNormal3s($nx, $ny, $nz);
void
glNormal3s(nx, ny, nz)
	GLshort	nx
	GLshort	ny
	GLshort	nz

#//# glNormal3sv_c((CPTR)v);
void
glNormal3sv_c(v)
	void *	v
	CODE:
	glNormal3sv(v);

#//# glNormal3sv_s((PACKED)v);
void
glNormal3sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*3);
		glNormal3sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glNormal3s
#//# glNormal3sv_p($nx, $ny, $nz);
void
glNormal3sv_p(nx, ny, nz)
	GLshort	nx
	GLshort	ny
	GLshort	nz
	CODE:
	{
		GLshort param[3];
		param[0] = nx;
		param[1] = ny;
		param[2] = nz;
		glNormal3sv(param);
	}

#//# glColor3b($red, $green, $blue);
void
glColor3b(red, green, blue)
	GLbyte	red
	GLbyte	green
	GLbyte	blue

#//# glColor3bv_c((CPTR)v);
void
glColor3bv_c(v)
	void *	v
	CODE:
	glColor3bv(v);

#//# glColor3bv_s((PACKED)v);
void
glColor3bv_s(v)
	SV *	v
	CODE:
	{
		GLbyte * v_s = EL(v, sizeof(GLbyte)*3);
		glColor3bv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3b
#//# glColor3bv_p($red, $green, $blue);
void
glColor3bv_p(red, green, blue)
	GLbyte	red
	GLbyte	green
	GLbyte	blue
	CODE:
	{
		GLbyte param[3];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		glColor3bv(param);
	}

#//# glColor3d($red, $green, $blue);
void
glColor3d(red, green, blue)
	GLdouble	red
	GLdouble	green
	GLdouble	blue

#//# glColor3dv_c((CPTR)v);
void
glColor3dv_c(v)
	void *	v
	CODE:
	glColor3dv(v);

#//# glColor3dv_s((PACKED)v);
void
glColor3dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*3);
		glColor3dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3d
#//# glColor3dv_p($red, $green, $blue);
void
glColor3dv_p(red, green, blue)
	GLdouble	red
	GLdouble	green
	GLdouble	blue
	CODE:
	{
		GLdouble param[3];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		glColor3dv(param);
	}

#//# glColor3f($red, $green, $blue);
void
glColor3f(red, green, blue)
	GLfloat	red
	GLfloat	green
	GLfloat	blue

#//# glColor3fv_c((CPTR)v);
void
glColor3fv_c(v)
	void *	v
	CODE:
	glColor3fv(v);

#//# glColor3fv_s((PACKED)v);
void
glColor3fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*3);
		glColor3fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3s
#//# glColor3sv_p($red, $green, $blue);
void
glColor3fv_p(red, green, blue)
	GLfloat	red
	GLfloat	green
	GLfloat	blue
	CODE:
	{
		GLfloat param[3];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		glColor3fv(param);
	}

#//# glColor3i($red, $green, $blue);
void
glColor3i(red, green, blue)
	GLint	red
	GLint	green
	GLint	blue

#//# glColor3iv_c((CPTR)v);
void
glColor3iv_c(v)
	void *	v
	CODE:
	glColor3iv(v);

#//# glColor3iv_s((PACKED)v);
void
glColor3iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*3);
		glColor3iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3i
#//# glColor3iv_p($red, $green, $blue);
void
glColor3iv_p(red, green, blue)
	GLint	red
	GLint	green
	GLint	blue
	CODE:
	{
		GLint param[3];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		glColor3iv(param);
	}

#//# glColor3s($red, $green, $blue);
void
glColor3s(red, green, blue)
	GLshort	red
	GLshort	green
	GLshort	blue

#//# glColor3sv_c((CPTR)v);
void
glColor3sv_c(v)
	void *	v
	CODE:
	glColor3sv(v);

#//# glColor3sv_s((PACKED)v);
void
glColor3sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*3);
		glColor3sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3s
#//# glColor3sv_p($red, $green, $blue);
void
glColor3sv_p(red, green, blue)
	GLshort	red
	GLshort	green
	GLshort	blue
	CODE:
	{
		GLshort param[3];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		glColor3sv(param);
	}

#//# glColor3ub($red, $green, $blue);
void
glColor3ub(red, green, blue)
	GLubyte	red
	GLubyte	green
	GLubyte	blue

#//# glColor3ubv_c((CPTR)v);
void
glColor3ubv_c(v)
	void *	v
	CODE:
	glColor3ubv(v);

#//# glColor3ubv_s((PACKED)v);
void
glColor3ubv_s(v)
	SV *	v
	CODE:
	{
		GLubyte * v_s = EL(v, sizeof(GLubyte)*3);
		glColor3ubv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3ub
#//# glColor3ubv_p($red, $green, $blue);
void
glColor3ubv_p(red, green, blue)
	GLubyte	red
	GLubyte	green
	GLubyte	blue
	CODE:
	{
		GLubyte param[3];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		glColor3ubv(param);
	}

#//# glColor3ui($red, $green, $blue);
void
glColor3ui(red, green, blue)
	GLuint	red
	GLuint	green
	GLuint	blue

#//# glColor3uiv_c((CPTR)v);
void
glColor3uiv_c(v)
	void *	v
	CODE:
	glColor3uiv(v);

#//# glColor3uiv_s((PACKED)v);
void
glColor3uiv_s(v)
	SV *	v
	CODE:
	{
		GLuint * v_s = EL(v, sizeof(GLuint)*3);
		glColor3uiv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3ui
#//# glColor3uiv_p($red, $green, $blue);
void
glColor3uiv_p(red, green, blue)
	GLuint	red
	GLuint	green
	GLuint	blue
	CODE:
	{
		GLuint param[3];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		glColor3uiv(param);
	}

#//# glColor3us($red, $green, $blue);
void
glColor3us(red, green, blue)
	GLushort	red
	GLushort	green
	GLushort	blue

#//# glColor3usv_c((CPTR)v);
void
glColor3usv_c(v)
	void *	v
	CODE:
	glColor3usv(v);

#//# glColor3usv_s((PACKED)v);
void
glColor3usv_s(v)
	SV *	v
	CODE:
	{
		GLushort * v_s = EL(v, sizeof(GLushort)*3);
		glColor3usv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3us
#//# glColor3usv_p($red, $green, $blue);
void
glColor3usv_p(red, green, blue)
	GLushort	red
	GLushort	green
	GLushort	blue
	CODE:
	{
		GLushort param[3];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		glColor3usv(param);
	}

#//# glColor4b($red, $green, $blue, $alpha);
void
glColor4b(red, green, blue, alpha)
	GLbyte	red
	GLbyte	green
	GLbyte	blue
	GLbyte	alpha

#//# glColor4bv_c((CPTR)v);
void
glColor4bv_c(v)
	void *	v
	CODE:
	glColor4bv(v);

#//# glColor4bv_s((PACKED)v);
void
glColor4bv_s(v)
	SV *	v
	CODE:
	{
		GLbyte * v_s = EL(v, sizeof(GLbyte)*4);
		glColor4bv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3b
#//# glColor3bv_p($red, $green, $blue, $alpha);
void
glColor4bv_p(red, green, blue, alpha)
	GLbyte	red
	GLbyte	green
	GLbyte	blue
	GLbyte	alpha
	CODE:
	{
		GLbyte param[4];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		param[3] = alpha;
		glColor4bv(param);
	}

#//# glColor4d($red, $green, $blue, $alpha);
void
glColor4d(red, green, blue, alpha)
	GLdouble	red
	GLdouble	green
	GLdouble	blue
	GLdouble	alpha

#//# glColor4dv_c((CPTR)v);
void
glColor4dv_c(v)
	void *	v
	CODE:
	glColor4dv(v);

#//# glColor4dv_s((PACKED)v);
void
glColor4dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glColor4dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3d
#//# glColor3dv_p($red, $green, $blue, $alpha);
void
glColor4dv_p(red, green, blue, alpha)
	GLdouble	red
	GLdouble	green
	GLdouble	blue
	GLdouble	alpha
	CODE:
	{
		GLdouble param[4];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		param[3] = alpha;
		glColor4dv(param);
	}

#//# glColor4f($red, $green, $blue, $alpha);
void
glColor4f(red, green, blue, alpha)
	GLfloat	red
	GLfloat	green
	GLfloat	blue
	GLfloat	alpha

#//# glColor4fv_c((CPTR)v);
void
glColor4fv_c(v)
	void *	v
	CODE:
	glColor4fv(v);

#//# glColor4fv_s((PACKED)v);
void
glColor4fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glColor4fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3f
#//# glColor3fv_p($red, $green, $blue, $alpha);
void
glColor4fv_p(red, green, blue, alpha)
	GLfloat	red
	GLfloat	green
	GLfloat	blue
	GLfloat	alpha
	CODE:
	{
		GLfloat param[4];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		param[3] = alpha;
		glColor4fv(param);
	}

#//# glColor4i($red, $green, $blue, $alpha);
void
glColor4i(red, green, blue, alpha)
	GLint	red
	GLint	green
	GLint	blue
	GLint	alpha

#//# glColor4iv_c((CPTR)v);
void
glColor4iv_c(v)
	void *	v
	CODE:
	glColor4iv(v);

#//# glColor4iv_s((PACKED)v);
void
glColor4iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glColor4iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3i
#//# glColor3iv_p($red, $green, $blue, $alpha);
void
glColor4iv_p(red, green, blue, alpha)
	GLint	red
	GLint	green
	GLint	blue
	GLint	alpha
	CODE:
	{
		GLint param[4];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		param[3] = alpha;
		glColor4iv(param);
	}

#//# glColor4s($red, $green, $blue, $alpha);
void
glColor4s(red, green, blue, alpha)
	GLshort	red
	GLshort	green
	GLshort	blue
	GLshort	alpha

#//# glColor4sv_c((CPTR)v);
void
glColor4sv_c(v)
	void *	v
	CODE:
	glColor4sv(v);

#//# glColor4sv_s((PACKED)v);
void
glColor4sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glColor4sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3s
#//# glColor3sv_p($red, $green, $blue, $alpha);
void
glColor4sv_p(red, green, blue, alpha)
	GLshort	red
	GLshort	green
	GLshort	blue
	GLshort	alpha
	CODE:
	{
		GLshort param[4];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		param[3] = alpha;
		glColor4sv(param);
	}

#//# glColor4ub(red, green, blue, alpha);
void
glColor4ub(red, green, blue, alpha)
	GLubyte	red
	GLubyte	green
	GLubyte	blue
	GLubyte	alpha

#//# glColor4ubv_c((CPTR)v);
void
glColor4ubv_c(v)
	void *	v
	CODE:
	glColor4ubv(v);

#//# glColor4ubv_s((PACKED)v);
void
glColor4ubv_s(v)
	SV *	v
	CODE:
	{
		GLubyte * v_s = EL(v, sizeof(GLubyte)*4);
		glColor4ubv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3ub
#//# glColor3ubv_p($red, $green, $blue, $alpha);
void
glColor4ubv_p(red, green, blue, alpha)
	GLubyte	red
	GLubyte	green
	GLubyte	blue
	GLubyte	alpha
	CODE:
	{
		GLubyte param[4];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		param[3] = alpha;
		glColor4ubv(param);
	}

#//# glColor4ui($red, $green, $blue, $alpha);
void
glColor4ui(red, green, blue, alpha)
	GLuint	red
	GLuint	green
	GLuint	blue
	GLuint	alpha

#//# glColor4uiv_s((PACKED)v);
void
glColor4uiv_s(v)
	SV *	v
	CODE:
	{
		GLuint * v_s = EL(v, sizeof(GLuint)*4);
		glColor4uiv(v_s);
	}

#//# glColor4uiv_c((CPTR)v);
void
glColor4uiv_c(v)
	void *	v
	CODE:
	glColor4uiv(v);

#//!!! Do we really need this?  It duplicates glColor3ui
#//# glColor3uiv_p($red, $green, $blue, $alpha);
void
glColor4uiv_p(red, green, blue, alpha)
	GLuint	red
	GLuint	green
	GLuint	blue
	GLuint	alpha
	CODE:
	{
		GLuint param[4];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		param[3] = alpha;
		glColor4uiv(param);
	}

#//# glColor4us($red, $green, $blue, $alpha);
void
glColor4us(red, green, blue, alpha)
	GLushort	red
	GLushort	green
	GLushort	blue
	GLushort	alpha

#//# glColor4usv_c((CPTR)v);
void
glColor4usv_c(v)
	void *	v
	CODE:
	glColor4usv(v);

#//# glColor4usv_s((PACKED)v);
void
glColor4usv_s(v)
	SV *	v
	CODE:
	{
		GLushort * v_s = EL(v, sizeof(GLushort)*4);
		glColor4usv(v_s);
	}

#//!!! Do we really need this?  It duplicates glColor3us
#//# glColor3usv_p($red, $green, $blue, $alpha);
void
glColor4usv_p(red, green, blue, alpha)
	GLushort	red
	GLushort	green
	GLushort	blue
	GLushort	alpha
	CODE:
	{
		GLushort param[4];
		param[0] = red;
		param[1] = green;
		param[2] = blue;
		param[3] = alpha;
		glColor4usv(param);
	}

#//# glTexCoord1d($s);
void
glTexCoord1d(s)
	GLdouble	s

#//# glTexCoord1dv_c((CPTR)v);
void
glTexCoord1dv_c(v)
	void *	v
	CODE:
	glTexCoord1dv(v);

#//# glTexCoord1dv_c((PACKED)v);
void
glTexCoord1dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*1);
		glTexCoord1dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord1d
#//# glTexCoord1dv_p($s);
void
glTexCoord1dv_p(s)
	GLdouble	s
	CODE:
	{
		GLdouble param[1];
		param[0] = s;
		glTexCoord1dv(param);
	}

#//# glTexCoord1f($s);
void
glTexCoord1f(s)
	GLfloat	s

#//# glTexCoord1fv_c((CPTR)v);
void
glTexCoord1fv_c(v)
	void *	v
	CODE:
	glTexCoord1fv(v);

#//# glTexCoord1fv_s((PACKED)v);
void
glTexCoord1fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*1);
		glTexCoord1fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord1f
#//# glTexCoord1fv_p($s);
void
glTexCoord1fv_p(s)
	GLfloat	s
	CODE:
	{
		GLfloat param[1];
		param[0] = s;
		glTexCoord1fv(param);
	}

#//# glTexCoord1i($s);
void
glTexCoord1i(s)
	GLint	s

#//# glTexCoord1iv_c((CPTR)v);
void
glTexCoord1iv_c(v)
	void *	v
	CODE:
	glTexCoord1iv(v);

#//# glTexCoord1iv_s((PACKED)v);
void
glTexCoord1iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*1);
		glTexCoord1iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord1i
#//# glTexCoord1iv_p($s);
void
glTexCoord1iv_p(s)
	GLint	s
	CODE:
	{
		GLint param[1];
		param[0] = s;
		glTexCoord1iv(param);
	}

#//# glTexCoord1s($s);
void
glTexCoord1s(s)
	GLshort	s

#//# glTexCoord1sv_c((CPTR)v)
void
glTexCoord1sv_c(v)
	void *	v
	CODE:
	glTexCoord1sv(v);

#//# glTexCoord1sv_s((PACKED)v)
void
glTexCoord1sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*1);
		glTexCoord1sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord1s
#//# glTexCoord1sv_p($s);
void
glTexCoord1sv_p(s)
	GLshort	s
	CODE:
	{
		GLshort param[1];
		param[0] = s;
		glTexCoord1sv(param);
	}

#endif /* HAVE_GL */

