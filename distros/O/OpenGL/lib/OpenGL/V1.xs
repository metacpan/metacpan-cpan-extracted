/*  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 2009 Chris Marshall. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

#include <stdio.h>

#include "pgopogl.h"

#ifdef HAVE_GL
#include "gl_util.h"
#endif /* defined HAVE_GL */

MODULE = OpenGL::V1	PACKAGE = OpenGL

#ifdef HAVE_GL

#// 1.0
#//# glAccum($op, $value);
void
glAccum(op, value)
	GLenum	op
	GLfloat	value

#// 1.0
#//# glAlphaFunc($func, $ref);
void
glAlphaFunc(func, ref)
	GLenum	func
	GLclampf	ref

#ifdef GL_VERSION_1_1

#//# glAreTexturesResident_c($n, (CPTR)textures, (CPTR)residences);
void
glAreTexturesResident_c(n, textures, residences)
	GLsizei	n
	void *	textures
	void *	residences
	CODE:
	glAreTexturesResident(n, textures, residences);

#//# glAreTexturesResident_s($n, (PACKED)textures, (PACKED)residences);
void
glAreTexturesResident_s(n, textures, residences)
	GLsizei	n
	SV *	textures
	SV *	residences
	CODE:
	{
	void * textures_s = EL(textures, sizeof(GLuint)*n);
	void * residences_s = EL(residences, sizeof(GLboolean)*n);
	glAreTexturesResident(n, textures_s, residences_s);
	}

#// 1.1
#//# (result,@residences) = glAreTexturesResident_p(@textureIDs);
void
glAreTexturesResident_p(...)
	PPCODE:
	{
		GLsizei n = items;
		GLuint * textures = malloc(sizeof(GLuint) * (n+1));
		GLboolean * residences = malloc(sizeof(GLboolean) * (n+1));
		GLboolean result;
		int i;

		for (i=0;i<n;i++)
			textures[i] = SvIV(ST(i));

		result = glAreTexturesResident(n, textures, residences);

		if ((result == GL_TRUE) || (GIMME != G_ARRAY))
			PUSHs(sv_2mortal(newSViv(result)));
		else {
			EXTEND(sp, n+1);
			PUSHs(sv_2mortal(newSViv(result)));
			for(i=0;i<n;i++)
				PUSHs(sv_2mortal(newSViv(residences[i])));
		}

		free(textures);
		free(residences);
	}

#// 1.1
#//# glArrayElement($i);
void
glArrayElement(i)
	GLint	i

#endif

#// 1.0
#//# glBegin($mode);
void
glBegin(mode)
	GLenum	mode

#// 1.0
#//# glEnd()
void
glEnd()

#ifdef GL_VERSION_1_1

#//# glBindTexture($target, $texture);
void
glBindTexture(target, texture)
	GLenum	target
	GLuint	texture

#endif


#// 1.0
#//# glBitmap_c($width, $height, $xorig, $yorig, $xmove, $ymove, (CPTR)bitmap);
void
glBitmap_c(width, height, xorig, yorig, xmove, ymove, bitmap)
	GLsizei	width
	GLsizei	height
	GLfloat	xorig
	GLfloat	yorig
	GLfloat	xmove
	GLfloat	ymove
	void *	bitmap
	CODE:
	glBitmap(width, height, xorig, yorig, xmove, ymove, bitmap);

#//# glBitmap_s($width, $height, $xorig, $yorig, $xmove, $ymove, (PACKED)bitmap);
void
glBitmap_s(width, height, xorig, yorig, xmove, ymove, bitmap)
	GLsizei	width
	GLsizei	height
	GLfloat	xorig
	GLfloat	yorig
	GLfloat	xmove
	GLfloat	ymove
	SV *	bitmap
	CODE:
	{
	GLubyte * bitmap_s = ELI(bitmap, width, height,
		GL_COLOR_INDEX, GL_BITMAP, gl_pixelbuffer_unpack);
	glBitmap(width, height, xorig, yorig, xmove, ymove, bitmap_s);
	}

#//# glBitmap_p($width, $height, $xorig, $yorig, $xmove, $ymove, @bitmap);
void
glBitmap_p(width, height, xorig, yorig, xmove, ymove, ...)
	GLsizei	width
	GLsizei	height
	GLfloat	xorig
	GLfloat	yorig
	GLfloat	xmove
	GLfloat	ymove
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(6)), items-6, width, height,
		1, GL_COLOR_INDEX, GL_BITMAP, 0);
	glBitmap(width, height, xorig, yorig, xmove, ymove, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#// 1.0
#//# glBlendFunc($sfactor, $dfactor);
void
glBlendFunc(sfactor, dfactor)
	GLenum	sfactor
	GLenum	dfactor

#// 1.0
#//# glCallList($list);
void
glCallList(list)
	GLuint	list

#// 1.0
#//# glCallLists_c($n, $type, (CPTR)lists);
void
glCallLists_c(n, type, lists)
	GLsizei	n
	GLenum	type
	void *	lists
	CODE:
	glCallLists(n, type, lists);

#// 1.0
#//# glCallLists_s($n, $type, (PACKED)lists);
void
glCallLists_s(n, type, lists)
	GLsizei	n
	GLenum	type
	SV *	lists
	CODE:
	{
	void * lists_s = EL(lists, gl_type_size(type) * n);
	glCallLists(n, type, lists_s);
	}

#// 1.0
#//# glCallLists_p(@lists);
#//- Assumes GLint type
void
glCallLists_p(...)
	CODE:
	if (items) {
		int * list = malloc(sizeof(int) * items);
		int i;
		for(i=0;i<items;i++)
			list[i] = SvIV(ST(i));
		glCallLists(items, GL_INT, list);
		free(list);
	}

#// 1.0
#//# glClear($mask);
void
glClear(mask)
	GLbitfield	mask

#// 1.0
#//# glClearAccum($red, $green, $blue, $alpha);
void
glClearAccum(red, green, blue, alpha)
	GLfloat	red
	GLfloat	green
	GLfloat	blue
	GLfloat	alpha

#// 1.0
#//# glClearColor($red, $green, $blue, $alpha);
void
glClearColor(red, green, blue, alpha)
	GLclampf	red
	GLclampf	green
	GLclampf	blue
	GLclampf	alpha

#// 1.0
#//# glClearDepth($depth);
void
glClearDepth(depth)
	GLclampd	depth

#// 1.0
#//# glClearIndex($c);
void
glClearIndex(c)
	GLfloat	c

#// 1.0
#//# glClearStencil($s);
void
glClearStencil(s)
	GLint	s

#// 1.0
#//# glClipPlane_c($plane, (CPTR)eqn);
void
glClipPlane_c(plane, eqn)
	GLenum	plane
	void *	eqn
	CODE:
	glClipPlane(plane, eqn);

#// 1.0
#//# glClipPlane_s($plane, (PACKED)eqn);
void
glClipPlane_s(plane, eqn)
	GLenum	plane
	SV *	eqn
	CODE:
	{
		GLdouble * eqn_s = EL(eqn, sizeof(GLdouble) * 4);
		glClipPlane(plane, eqn_s);
	}

#// 1.0
#//# glClipPlane_p($plane, $eqn0, $eqn1, $eqn2, $eqn3);
void
glClipPlane_p(plane, eqn0, eqn1, eqn2, eqn3)
	GLenum	plane
	double	eqn0
	double	eqn1
	double	eqn2
	double	eqn3
	CODE:
	{
		double eqn[4];
		eqn[0] = eqn0;
		eqn[1] = eqn1;
		eqn[2] = eqn2;
		eqn[3] = eqn3;
		glClipPlane(plane, &eqn[0]);
	}

#// 1.0
#//# glColorMask($red, $green, $blue, $alpha);
void
glColorMask(red, green, blue, alpha)
	GLboolean	red
	GLboolean	green
	GLboolean	blue
	GLboolean	alpha

#// 1.0
#//# glColorMaterial($face, $mode);
void
glColorMaterial(face, mode)
	GLenum	face
	GLenum	mode


#// 1.0
#//# glCopyPixels($x, $y, $width, $height, $type);
void
glCopyPixels(x, y, width, height, type)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	GLenum	type

#ifdef GL_VERSION_1_1

#// 1.1
#//# glCopyTexImage1D($target, $level, $internalFormat, $x, $y, $width, $border);
void
glCopyTexImage1D(target, level, internalFormat, x, y, width, border)
	GLenum	target
	GLint	level
	GLenum	internalFormat
	GLint	x
	GLint	y
	GLsizei	width
	GLint	border

#// 1.1
#//# glCopyTexImage2D($target, $level, $internalFormat, $x, $y, $width, $height, $border);
void
glCopyTexImage2D(target, level, internalFormat, x, y, width, height, border)
	GLenum	target
	GLint	level
	GLenum	internalFormat
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	GLint	border

#// 1.1
#//# glCopyTexSubImage1D($target, $level, $xoffset, $x, $y, $width);
void
glCopyTexSubImage1D(target, level, xoffset, x, y, width)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	x
	GLint	y
	GLsizei	width

#// 1.1
#//# glCopyTexSubImage2D($target, $level, $xoffset, $yoffset, $x, $y, $width, $height);
void
glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height

#ifdef GL_VERSION_1_2

#// 1.2
#//# glCopyTexSubImage3D($target, $level, $xoffset, $yoffset, $zoffset, $x, $y, $width, $height);
void
glCopyTexSubImage3D(target, level, xoffset, yoffset, zoffset, x, y, width, height)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	INIT:
		loadProc(glCopyTexSubImage3D,"glCopyTexSubImage3D");
	CODE:
	{
		glCopyTexSubImage3D(target, level, xoffset, yoffset, zoffset,
			x, y, width, height);
	}

#endif

#endif

#// 1.0
#//# glCullFace($mode);
void
glCullFace(mode)
	GLenum	mode

#// 1.0
#//# glDeleteLists($list, $range);
void
glDeleteLists(list, range)
	GLenum	list
	GLsizei	range

#ifdef GL_VERSION_1_1

#// 1.1
#//# glDeleteTextures_c($items, (CPTR)list);
void
glDeleteTextures_c(items, list)
	GLint	items
	void *	list
	CODE:
	glDeleteTextures(items,list);

#// 1.1
#//# glDeleteTextures_s($items, (PACKED)list);
void
glDeleteTextures_s(items, list)
	GLint	items
	SV *	list
	CODE:
	{
	void * list_s = EL(list, sizeof(GLuint) * items);
	glDeleteTextures(items,list_s);
	}

#// 1.1
#//# glDeleteTextures_p(@textureIDs);
void
glDeleteTextures_p(...)
	CODE:
	if (items) {
		GLuint * list = malloc(sizeof(GLuint) * items);
		int i;

		for(i=0;i<items;i++)
			list[i] = SvIV(ST(i));

		glDeleteTextures(items, list);
		free(list);
	}

#endif

#// 1.0
#//# glDepthFunc($func);
void
glDepthFunc(func)
	GLenum	func

#// 1.0
#//# glDepthMask($flag);
void
glDepthMask(flag)
	GLboolean	flag

#// 1.0
#//# glDepthRange($zNear, $zFar);
void
glDepthRange(zNear, zFar)
	GLclampd	zNear
	GLclampd	zFar

#ifdef GL_VERSION_1_1

#// 1.1
#//# glDrawArrays($mode, $first, $count);
void
glDrawArrays(mode, first, count)
	GLenum	mode
	GLint	first
	GLsizei	count

#endif

#// 1.0
#//# glDrawBuffer($mode);
void
glDrawBuffer(mode)
	GLenum	mode

#ifdef GL_VERSION_1_1

#// 1.1
#//# glDrawElements_c($mode, $count, $type, (CPTR)indices);
void
glDrawElements_c(mode, count, type, indices)
	GLenum	mode
	GLint	count
	GLenum	type
	void *	indices
	CODE:
		glDrawElements(mode, count, type, indices);

#// 1.1
#//# glDrawElements_s($mode, $count, $type, (PACKED)indices);
void
glDrawElements_s(mode, count, type, indices)
	GLenum	mode
	GLint	count
	GLenum	type
	SV *	indices
	CODE:
	{
		void * indices_s = EL(indices, gl_type_size(type)*count);
		glDrawElements(mode, count, type, indices_s);
	}

#//# glDrawElements_p($mode, @indices);
#//- Assumes GLuint for indices
void
glDrawElements_p(mode, ...)
	GLenum	mode
	CODE:
	{
		GLuint * indices = malloc(sizeof(GLuint) * items);
		int i;

		for (i=1; i<items; i++)
			indices[i-1] = SvIV(ST(i));

		glDrawElements(mode, items-1, GL_UNSIGNED_INT, indices);

		free(indices);
	}

#endif

#// 1.0
#//# glDrawPixels_c($width, $height, $format, $type, (CPTR)pixels);
void
glDrawPixels_c(width, height, format, type, pixels)
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glDrawPixels(width, height, format, type, pixels);

#// 1.0
#//# glDrawPixels_s($width, $height, $format, $type, (PACKED)pixels);
void
glDrawPixels_s(width, height, format, type, pixels)
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
	GLvoid * ptr = ELI(pixels, width, height,
		format, type, gl_pixelbuffer_unpack);
	glDrawPixels(width, height, format, type, ptr);
	}

#// 1.0
#//# glDrawPixels_p($width, $height, $format, $type, @pixels);
void
glDrawPixels_p(width, height, format, type, ...)
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(4)), items-4, width, height, 1, format, type, 0);
	glDrawPixels(width, height, format, type, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#ifdef GL_VERSION_1_2

#// 1.2
#//# glDrawRangeElements_c($mode, $start, $end, $count, $type, (CPTR)indices);
void
glDrawRangeElements_c(mode, start, end, count, type, indices)
	GLenum	mode
	GLuint	start
	GLuint	end
	GLsizei	count
	GLenum	type
	void *	indices
	INIT:
		loadProc(glDrawRangeElements,"glDrawRangeElements");
	CODE:
		glDrawRangeElements(mode, start, end, count, type, indices);

#//# glDrawRangeElements_s($mode, $start, $end, $count, $type, (PACKED)indices);
void
glDrawRangeElements_s(mode, start, end, count, type, indices)
	GLenum	mode
	GLuint	start
	GLuint	end
	GLsizei	count
	GLenum	type
	SV *	indices
	INIT:
		loadProc(glDrawRangeElements,"glDrawRangeElements");
	CODE:
	{
		void * indices_s = EL(indices, gl_type_size(type) * count);
		glDrawRangeElements(mode, start, end, count, type, indices_s);
	}

#//# glDrawRangeElements_p($mode, $start, $end, $count, $type, @indices);
#//- Assumes GLuint indices
void
glDrawRangeElements_p(mode, start, count, ...)
	GLenum	mode
	GLuint	start
	GLuint	count
	INIT:
		loadProc(glDrawRangeElements,"glDrawRangeElements");
	CODE:
	{
		if (items > 3)
		{
			if (start < (GLuint)items-3)
			{
				GLuint * indices;
				GLuint i;

				if (start+count > (GLuint)(items-3))
					count = (GLuint)items-(start+3);

				indices = malloc(sizeof(GLuint) * count);

				for (i=start; i<count; i++)
					indices[i] = SvIV(ST(i+3));

				glDrawRangeElements(mode, start, start+count-1,
					count, GL_UNSIGNED_INT, indices);

				free(indices);
			}
		}
		else
		{
			glDrawRangeElements(mode, start, start+count-1,
				count, GL_UNSIGNED_INT, 0);
		}
	}

#endif

#// 1.0
#//# glEdgeFlag($flag);
void
glEdgeFlag(flag)
	GLboolean	flag


#// 1.0
#//# glEnable($cap);
void
glEnable(cap)
	GLenum	cap

#// 1.0
#//# glDisable($cap);
void
glDisable(cap)
	GLenum	cap

#ifdef GL_VERSION_1_1

#// 1.1
#//# glEnableClientState($cap);
void
glEnableClientState(cap)
	GLenum	cap

#// 1.1
#//# glDisableClientState($cap);
void
glDisableClientState(cap)
	GLenum	cap

#endif

#// 1.0
#//# glEvalCoord1d($u);
void
glEvalCoord1d(u)
	GLdouble	u

#// 1.0
#//# glEvalCoord1f($u);
void
glEvalCoord1f(u)
	GLfloat	u

#// 1.0
#//# glEvalCoord2d($u, $v);
void
glEvalCoord2d(u, v)
	GLdouble	u
	GLdouble	v

#// 1.0
#//# glEvalCoord2f($u, $v);
void
glEvalCoord2f(u, v)
	GLfloat	u
	GLfloat	v

#// 1.0
#//# glEvalMesh1($mode, $i1, $i2);
void
glEvalMesh1(mode, i1, i2)
	GLenum	mode
	GLint	i1
	GLint	i2

#// 1.0
#//# glEvalMesh2($mode, $i1, $i2, $j1, $j2);
void
glEvalMesh2(mode, i1, i2, j1, j2)
	GLenum	mode
	GLint	i1
	GLint	i2
	GLint	j1
	GLint	j2

#// 1.0
#//# glEvalPoint1($i);
void
glEvalPoint1(i)
	GLint	i

#// 1.0
#//# glEvalPoint2($i, $j);
void
glEvalPoint2(i, j)
	GLint	i
	GLint	j

#// 1.0
#//# glFeedbackBuffer_c($size, $type, (CPTR)buffer);
void
glFeedbackBuffer_c(size, type, buffer)
	GLsizei	size
	GLenum	type
	void *	buffer
	CODE:
	glFeedbackBuffer(size, type, (GLfloat*)(buffer));

#// 1.0
#//# glFinish();
void
glFinish()

#// 1.0
#//# glFlush();
void
glFlush()

#// 1.0
#//# glFogf($pname, $param);
void
glFogf(pname, param)
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glFogi($pname, $param);
void
glFogi(pname, param)
	GLenum	pname
	GLint	param

#// 1.0
#//# glFogfv_c($pname, (CPTR)params);
void
glFogfv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glFogfv(pname, params);

#// 1.0
#//# glFogiv_c($pname, (CPTR)params);
void
glFogiv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glFogiv(pname, params);

#// 1.0
#//# glFogfv_s($pname, (PACKED)params);
void
glFogfv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat)*gl_fog_count(pname));
	glFogfv(pname, params_s);
	}

#// 1.0
#//# glFogiv_s($pname, (PACKED)params);
void
glFogiv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*gl_fog_count(pname));
	glFogiv(pname, params_s);
	}

#// 1.0
#//# glFogfv_p($pname, $param1, $param2=0, $param3=0, $param4=0);
void
glFogfv_p(pname, param1, param2=0, param3=0, param4=0)
	GLenum	pname
	GLfloat	param1
	GLfloat	param2
	GLfloat	param3
	GLfloat	param4
	CODE:
	{
		GLfloat p[4];
		p[0] = param1;
		p[1] = param2;
		p[2] = param3;
		p[3] = param4;
		glFogfv(pname, &p[0]);
	}

#// 1.0
#//# glFogiv_p($pname, $param1, $param2=0, $param3=0, $param4=0);
void
glFogiv_p(pname, param1, param2=0, param3=0, param4=0)
	GLenum	pname
	GLint	param1
	GLint	param2
	GLint	param3
	GLint	param4
	CODE:
	{
		GLint p[4];
		p[0] = param1;
		p[1] = param2;
		p[2] = param3;
		p[3] = param4;
		glFogiv(pname, &p[0]);
	}

#// 1.0
#//# glFrontFace($mode);
void
glFrontFace(mode)
	GLenum	mode

#// 1.0
#//# glFrustum($left, $right, $bottom, $top, $zNear, $zFar);
void
glFrustum(left, right, bottom, top, zNear, zFar)
	GLdouble	left
	GLdouble	right
	GLdouble	bottom
	GLdouble	top
	GLdouble	zNear
	GLdouble	zFar

#// 1.0
#//# glGenLists($range);
GLuint
glGenLists(range)
	GLsizei	range

#ifdef GL_VERSION_1_1

#// 1.1
#//# glGenTextures_c($n, (CPTR)textures);
void
glGenTextures_c(n, textures)
	GLint	n
	void *	textures
	CODE:
	glGenTextures(n, textures);

#// 1.1
#//# glGenTextures_s($n, (PACKED)textures);
void
glGenTextures_s(n, textures)
	GLint	n
	SV *	textures
	CODE:
	{
	void * textures_s = EL(textures, sizeof(GLuint)*n);
	glGenTextures(n, textures_s);
	}

#// 1.1
#//# @textureIDs = glGenTextures_p($n);
void
glGenTextures_p(n)
	GLint	n
	PPCODE:
	if (n) {
		GLuint * textures = malloc(sizeof(GLuint) * n);
		int i;

		glGenTextures(n, textures);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(textures[i])));

		free(textures);
	}

#endif

#// 1.0
#//# glGetDoublev_c($pname, (CPTR)params);
void
glGetDoublev_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glGetDoublev(pname, params);

#// 1.0
#//# glGetDoublev_c($pname, (PACKED)params);
void
glGetDoublev_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
	void * params_s = EL(params, sizeof(GLdouble) * gl_get_count(pname));
	glGetDoublev(pname, params_s);
	}

#// 1.0
#//# glGetBooleanv_c($pname, (CPTR)params);
void
glGetBooleanv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glGetBooleanv(pname, params);

#// 1.0
#//# glGetBooleanv_s($pname, (PACKED)params);
void
glGetBooleanv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
	void * params_s = EL(params, sizeof(GLboolean) * gl_get_count(pname));
	glGetBooleanv(pname, params_s);
	}

#// 1.0
#//# glGetIntegerv_c($pname, (CPTR)params);
void
glGetIntegerv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glGetIntegerv(pname, params);

#// 1.0
#//# glGetIntegerv_s($pname, (PACKED)params);
void
glGetIntegerv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
	void * params_s = EL(params, sizeof(GLint) * gl_get_count(pname));
	glGetIntegerv(pname, params_s);
	}

#// 1.0
#//# glGetFloatv_c($pname, (CPTR)params);
void
glGetFloatv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glGetFloatv(pname, params);

#// 1.0
#//# glGetFloatv_s($pname, (PACKED)params);
void
glGetFloatv_s(pname, params)
	GLenum	pname
	void *	params
	CODE:
	{
	void * params_s = EL(params, sizeof(GLfloat) * gl_get_count(pname));
	glGetFloatv(pname, params_s);
	}

#// 1.0
#//# @data = glGetDoublev_p($param);
void
glGetDoublev_p(param)
	GLenum	param
	PPCODE:
	{
		GLdouble	ret[MAX_GL_GET_COUNT];
		int n = gl_get_count(param);
		int i;
		glGetDoublev(param, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @data = glGetBooleanv_p($param);
void
glGetBooleanv_p(param)
	GLenum	param
	PPCODE:
	{
		GLboolean	ret[MAX_GL_GET_COUNT];
		int n = gl_get_count(param);
		int i;
		glGetBooleanv(param, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# @data = glGetIntegerv_p($param);
void
glGetIntegerv_p(param)
	GLenum	param
	PPCODE:
	{
		GLint	ret[MAX_GL_GET_COUNT];
		int n = gl_get_count(param);
		int i;
		glGetIntegerv(param, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# @data = glGetFloatv_p($param);
void
glGetFloatv_p(param)
	GLenum	param
	PPCODE:
	{
		GLfloat	ret[MAX_GL_GET_COUNT];
		int n = gl_get_count(param);
		int i;
		glGetFloatv(param, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# glGetClipPlane_c($plane, (CPTR)eqn);
void
glGetClipPlane_c(plane, eqn)
	GLenum	plane
	void *	eqn
	CODE:
	glGetClipPlane(plane, eqn);

#// 1.0
#//# glGetClipPlane_s($plane, (PACKED)eqn);
void
glGetClipPlane_s(plane, eqn)
	GLenum	plane
	SV *	eqn
	CODE:
	{
	GLdouble * eqn_s = EL(eqn, sizeof(GLdouble)*4);
	glGetClipPlane(plane, eqn_s);
	}

#// 1.0
#//# @data = glGetClipPlane_p($plane);
void
glGetClipPlane_p(plane)
	GLenum	plane
	PPCODE:
	{
		int i;
		GLdouble	eqn[4];
		eqn[0] = eqn[1] = eqn[2] = eqn[3] = 0;
		glGetClipPlane(plane, &eqn[0]);
		EXTEND(sp, 4);
		for(i=0;i<4;i++)
			PUSHs(sv_2mortal(newSVnv(eqn[i])));
	}

#// 1.0
#//# glGetError();
GLenum
glGetError()

#// 1.0
#//# glGetLightfv_c($light, $pname, (CPTR)p);
void
glGetLightfv_c(light, pname, p)
	GLenum	light
	GLenum	pname
	void *	p
	CODE:
	glGetLightfv(light, pname, p);

#// 1.0
#//# glGetLightiv_c($light, $pname, (CPTR)p);
void
glGetLightiv_c(light, pname, p)
	GLenum	light
	GLenum	pname
	void *	p
	CODE:
	glGetLightiv(light, pname, p);

#// 1.0
#//# glGetLightfv_s($light, $pname, (PACKED)p);
void
glGetLightfv_s(light, pname, p)
	GLenum	light
	GLenum	pname
	SV *	p
	CODE:
	{
	void * p_s = EL(p, sizeof(GLfloat)*gl_light_count(pname));
	glGetLightfv(light, pname, p_s);
	}

#// 1.0
#//# glGetLightiv_s($light, $pname, (PACKED)p);
void
glGetLightiv_s(light, pname, p)
	GLenum	light
	GLenum	pname
	SV *	p
	CODE:
	{
	void * p_s = EL(p, sizeof(GLint)*gl_light_count(pname));
	glGetLightiv(light, pname, p_s);
	}

#// 1.0
#//# @data = glGetLightfv_p($light, $pname);
void
glGetLightfv_p(light, pname)
	GLenum	light
	GLenum	pname
	PPCODE:
	{
		GLfloat	ret[MAX_GL_LIGHT_COUNT];
		int n = gl_light_count(pname);
		int i;
		glGetLightfv(light, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @data = glGetLightiv_p($light, $pname);
void
glGetLightiv_p(light, pname)
	GLenum	light
	GLenum	pname
	PPCODE:
	{
		GLint	ret[MAX_GL_LIGHT_COUNT];
		int n = gl_light_count(pname);
		int i;
		glGetLightiv(light, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glGetMapiv_c($target, $query, (CPTR)v);
void
glGetMapiv_c(target, query, v)
	GLenum	target
	GLenum	query
	void *	v
	CODE:
	glGetMapiv(target, query, (GLint*)v);

#// 1.0
#//# glGetMapfv_c($target, $query, (CPTR)v);
void
glGetMapfv_c(target, query, v)
	GLenum	target
	GLenum	query
	void *	v
	CODE:
	glGetMapfv(target, query, (GLfloat*)v);

#// 1.0
#//# glGetMapdv_c($target, $query, (CPTR)v);
void
glGetMapdv_c(target, query, v)
	GLenum	target
	GLenum	query
	void *	v
	CODE:
	glGetMapdv(target, query, (GLdouble*)v);

#// 1.0
#//# glGetMapdv_s($target, $query, (PACKED)v);
void
glGetMapdv_s(target, query, v)
	GLenum	target
	GLenum	query
	SV * v
	CODE:
	{
		GLdouble * v_s = EL(v,
			sizeof(GLdouble)*gl_map_count(target, query));
		glGetMapdv(target, query, v_s);
	}

#// 1.0
#//# glGetMapfv_s($target, $query, (PACKED)v);
void
glGetMapfv_s(target, query, v)
	GLenum	target
	GLenum	query
	SV * v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*gl_map_count(target, query));
		glGetMapfv(target, query, v_s);
	}

#// 1.0
#//# glGetMapiv_s($target, $query, (PACKED)v);
void
glGetMapiv_s(target, query, v)
	GLenum	target
	GLenum	query
	SV * v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*gl_map_count(target, query));
		glGetMapiv(target, query, v_s);
	}

#// 1.0
#//# @data = glGetMapfv_p($target, $query);
void
glGetMapfv_p(target, query)
	GLenum	target
	GLenum	query
	PPCODE:
	{
		GLfloat	ret[MAX_GL_MAP_COUNT];
		int n = gl_map_count(target, query);
		int i;
		glGetMapfv(target, query, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @data = glGetMapdv_p($target, $query);
void
glGetMapdv_p(target, query)
	GLenum	target
	GLenum	query
	PPCODE:
	{
		GLdouble	ret[MAX_GL_MAP_COUNT];
		int n = gl_map_count(target, query);
		int i;
		glGetMapdv(target, query, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @data = glGetMapiv_p($target, $query);
void
glGetMapiv_p(target, query)
	GLenum	target
	GLenum	query
	PPCODE:
	{
		GLint	ret[MAX_GL_MAP_COUNT];
		int n = gl_map_count(target, query);
		int i;
		glGetMapiv(target, query, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glGetMaterialfv_c($face, $query, (CPTR)params);
void
glGetMaterialfv_c(face, query, params)
	GLenum	face
	GLenum	query
	void *	params
	CODE:
	glGetMaterialfv(face, query, params);

#// 1.0
#//# glGetMaterialiv_c($face, $query, (CPTR)params);
void
glGetMaterialiv_c(face, query, params)
	GLenum	face
	GLenum	query
	void *	params
	CODE:
	glGetMaterialiv(face, query, params);

#// 1.0
#//# glGetMaterialfv_s($face, $query, (PACKED)params);
void
glGetMaterialfv_s(face, query, params)
	GLenum	face
	GLenum	query
	SV *	params
	CODE:
	{
		GLfloat * params_s = EL(params,
			sizeof(GLfloat)*gl_material_count(query));
		glGetMaterialfv(face, query, params_s);
	}

#// 1.0
#//# glGetMaterialiv_s($face, $query, (PACKED)params);
void
glGetMaterialiv_s(face, query, params)
	GLenum	face
	GLenum	query
	SV *	params
	CODE:
	{
		GLint * params_s = EL(params,
			sizeof(GLfloat)*gl_material_count(query));
		glGetMaterialiv(face, query, params_s);
	}

#// 1.0
#//# @params = glGetMaterialfv_p($face, $query);
void
glGetMaterialfv_p(face, query)
	GLenum	face
	GLenum	query
	PPCODE:
	{
		GLfloat	ret[MAX_GL_MATERIAL_COUNT];
		int n = gl_material_count(query);
		int i;
		glGetMaterialfv(face, query, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @params = glGetMaterialiv_p($face, $query);
void
glGetMaterialiv_p(face, query)
	GLenum	face
	GLenum	query
	PPCODE:
	{
		GLint	ret[MAX_GL_MATERIAL_COUNT];
		int n = gl_material_count(query);
		int i;
		glGetMaterialiv(face, query, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glGetPixelMapfv_c($map, (CPTR)values);
void
glGetPixelMapfv_c(map, values)
	GLenum	map
	void *	values
	CODE:
	glGetPixelMapfv(map, values);

#// 1.0
#//# glGetPixelMapuiv_c($map, (CPTR)values);
void
glGetPixelMapuiv_c(map, values)
	GLenum	map
	void *	values
	CODE:
	glGetPixelMapuiv(map, values);

#// 1.0
#//# glGetPixelMapusv_c($map, (CPTR)values);
void
glGetPixelMapusv_c(map, values)
	GLenum	map
	void *	values
	CODE:
	glGetPixelMapusv(map, values);

#// 1.0
#//# glGetPixelMapfv_s($map, (PACKED)values);
void
glGetPixelMapfv_s(map, values)
	GLenum	map
	SV *	values
	CODE:
	{
	GLfloat * values_s = EL(values, sizeof(GLfloat)* gl_pixelmap_size(map));
	glGetPixelMapfv(map, values_s);
	}

#// 1.0
#//# glGetPixelMapuiv_s($map, (PACKED)values);
void
glGetPixelMapuiv_s(map, values)
	GLenum	map
	SV *	values
	CODE:
	{
	GLuint * values_s = EL(values, sizeof(GLuint)* gl_pixelmap_size(map));
	glGetPixelMapuiv(map, values_s);
	}

#// 1.0
#//# glGetPixelMapusv_s($map, (PACKED)values);
void
glGetPixelMapusv_s(map, values)
	GLenum	map
	SV *	values
	CODE:
	{
	GLushort * values_s = EL(values, sizeof(GLushort)* gl_pixelmap_size(map));
	glGetPixelMapusv(map, values_s);
	}

#// 1.0
#//# @data = glGetPixelMapfv_p($map);
void
glGetPixelMapfv_p(map)
	GLenum	map
	CODE:
	{
		int count = gl_pixelmap_size(map);
		GLfloat * values;
		int i;

		values = malloc(sizeof(GLfloat) * count);

		glGetPixelMapfv(map, values);

		EXTEND(sp, count);

		for(i=0; i<count; i++)
			PUSHs(sv_2mortal(newSVnv(values[i])));

		free(values);
	}

#// 1.0
#//# @data = glGetPixelMapuiv_p($map);
void
glGetPixelMapuiv_p(map)
	GLenum	map
	CODE:
	{
		int count = gl_pixelmap_size(map);
		GLuint * values;
		int i;
		values = malloc(sizeof(GLuint) * count);
		glGetPixelMapuiv(map, values);
		EXTEND(sp, count);
		for(i=0; i<count; i++)
			PUSHs(sv_2mortal(newSViv(values[i])));
		free(values);
	}

#// 1.0
#//# @data = glGetPixelMapusv_p($map);
void
glGetPixelMapusv_p(map)
	GLenum	map
	CODE:
	{
		int count = gl_pixelmap_size(map);
		GLushort * values;
		int i;
		values = malloc(sizeof(GLushort) * count);
		glGetPixelMapusv(map, values);
		EXTEND(sp, count);
		for(i=0; i<count; i++)
			PUSHs(sv_2mortal(newSViv(values[i])));
		free(values);
	}

#// 1.0
#//# glGetPolygonStipple_c((CPTR)mask);
void
glGetPolygonStipple_c(mask)
	void *	mask
	CODE:
	glGetPolygonStipple(mask);

#// 1.0
#//# glGetPolygonStipple_s((PACKED)mask);
void
glGetPolygonStipple_s(mask)
	SV *	mask
	CODE:
	{
	GLubyte * ptr = ELI(mask, 32, 32, GL_COLOR_INDEX, GL_BITMAP, gl_pixelbuffer_unpack);
	glGetPolygonStipple(ptr);
	}

#// 1.0
#//# @mask = glGetPolygonStipple_p();
void
glGetPolygonStipple_p()
	PPCODE:
	{
		void * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_PACK_ROW_LENGTH, 0);
		glPixelStorei(GL_PACK_ALIGNMENT, 1);
		ptr = allocate_image_ST(32, 32, 1, GL_COLOR_INDEX, GL_BITMAP, 0);
		glGetPolygonStipple(ptr);
		sp = unpack_image_ST(sp, ptr, 32, 32, 1,
			GL_COLOR_INDEX, GL_BITMAP, 0);
		free(ptr);
		glPopClientAttrib();
	}

#ifdef GL_VERSION_1_1

#// 1.1
#//# glGetPointerv_c($pname, (CPTR)params);
void
glGetPointerv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glGetPointerv(pname,&params);

#// 1.1
#//# glGetPointerv_s($pname, (PACKED)params);
void
glGetPointerv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
		void ** params_s = EL(params, sizeof(void*));
		glGetPointerv(pname, params_s);
	}

#// 1.1
#//# @params = glGetPointerv_p($pname);
void *
glGetPointerv_p(pname)
	GLenum	pname
	CODE:
	glGetPointerv(pname, &RETVAL);
	OUTPUT:
	RETVAL

#endif

#// 1.0
#//# $string = glGetString($name);
SV *
glGetString(name)
	GLenum	name
	CODE:
	{
		char * c = (char*)glGetString(name);
		if (c)
			RETVAL = newSVpv(c, 0);
		else
			RETVAL = newSVsv(&PL_sv_undef);
	}
	OUTPUT:
	RETVAL

#// 1.0
#//# glGetTexEnvfv_c($target, $pname, (CPTR)params);
void
glGetTexEnvfv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void * params
	CODE:
	glGetTexEnvfv(target, pname, params);

#// 1.0
#//# glGetTexEnviv_c($target, $pname, (CPTR)params);
void
glGetTexEnviv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void * params
	CODE:
	glGetTexEnviv(target, pname, params);

#// 1.0
#//# glGetTexEnvfv_s($target, $pname, (PACKED)params);
void
glGetTexEnvfv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV * params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat) * gl_texenv_count(pname));
	glGetTexEnvfv(target, pname, params_s);
	}

#// 1.0
#//# glGetTexEnviv_s($target, $pname, (PACKED)params);
void
glGetTexEnviv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV * params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint) * gl_texenv_count(pname));
	glGetTexEnviv(target, pname, params_s);
	}

#// 1.0
#//# @parames = glGetTexEnvfv_p($target, $pname);
void
glGetTexEnvfv_p(target, pname)
	GLenum	target
	GLenum	pname
	PPCODE:
	{
		GLfloat	ret[MAX_GL_TEXENV_COUNT];
		int n = gl_texenv_count(pname);
		int i;
		glGetTexEnvfv(target, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @parames = glGetTexEnviv_p($target, $pname);
void
glGetTexEnviv_p(target, pname)
	GLenum	target
	GLenum	pname
	PPCODE:
	{
		GLint	ret[MAX_GL_TEXENV_COUNT];
		int n = gl_texenv_count(pname);
		int i;
		glGetTexEnviv(target, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glGetTexGenfv_c($coord, $pname, (CPTR)params);
void
glGetTexGenfv_c(coord, pname, params)
	GLenum	coord
	GLenum	pname
	void *	params
	CODE:
	glGetTexGenfv(coord, pname, params);

#// 1.0
#//# glGetTexGendv_c($coord, $pname, (CPTR)params);
void
glGetTexGendv_c(coord, pname, params)
	GLenum	coord
	GLenum	pname
	void *	params
	CODE:
	glGetTexGendv(coord, pname, params);

#// 1.0
#//# glGetTexGeniv_c($coord, $pname, (CPTR)params);
void
glGetTexGeniv_c(coord, pname, params)
	GLenum	coord
	GLenum	pname
	void *	params
	CODE:
	glGetTexGeniv(coord, pname, params);

#// 1.0
#//# glGetTexGendv_c($coord, $pname, (CPTR)params);
void
glGetTexGendv_s(coord, pname, params)
	GLenum	coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLdouble * params_s = EL(params, sizeof(GLdouble)*gl_texgen_count(pname));
	glGetTexGendv(coord, pname, params_s);
	}

#// 1.0
#//# glGetTexGenfv_s($coord, $pname, (PACKED)params);
void
glGetTexGenfv_s(coord, pname, params)
	GLenum	coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat)*gl_texgen_count(pname));
	glGetTexGenfv(coord, pname, params_s);
	}

#// 1.0
#//# glGetTexGeniv_s($coord, $pname, (PACKED)params);
void
glGetTexGeniv_s(coord, pname, params)
	GLenum	coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*gl_texgen_count(pname));
	glGetTexGeniv(coord, pname, params_s);
	}

#// 1.0
#//# @params = glGetTexGenfv_p($coord, $pname);
void
glGetTexGenfv_p(coord, pname)
	GLenum	coord
	GLenum	pname
	PPCODE:
	{
		GLfloat	ret[MAX_GL_TEXGEN_COUNT];
		int n = gl_texgen_count(pname);
		int i;
		glGetTexGenfv(coord, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @params = glGetTexGendv_p($coord, $pname);
void
glGetTexGendv_p(coord, pname)
	GLenum	coord
	GLenum	pname
	PPCODE:
	{
		GLdouble	ret[MAX_GL_TEXGEN_COUNT];
		int n = gl_texgen_count(pname);
		int i;
		glGetTexGendv(coord, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @params = glGetTexGeniv_p($coord, $pname);
void
glGetTexGeniv_p(coord, pname)
	GLenum	coord
	GLenum	pname
	PPCODE:
	{
		GLint	ret[MAX_GL_TEXGEN_COUNT];
		int n = gl_texgen_count(pname);
		int i;
		glGetTexGeniv(coord, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glGetTexImage_c($target, $level, $format, $type, (CPTR)pixels);
void
glGetTexImage_c(target, level, format, type, pixels)
	GLenum	target
	GLint	level
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glGetTexImage(target, level, format, type, pixels);

#// 1.0
#//# glGetTexImage_s($target, $level, $format, $type, (PACKED)pixels);
void
glGetTexImage_s(target, level, format, type, pixels)
	GLenum	target
	GLint	level
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
		GLint width, height;
		GLvoid * ptr;

		glGetTexLevelParameteriv(target, level,
			GL_TEXTURE_WIDTH, &width);
		glGetTexLevelParameteriv(target, level,
			GL_TEXTURE_HEIGHT, &height);

		ptr = ELI(pixels, width, height, format, type,
			gl_pixelbuffer_unpack);
		glGetTexImage(target, level, format, type, pixels);
	}

#// 1.0
#//# @pixels = glGetTexImage_c($target, $level, $format, $type);
void
glGetTexImage_p(target, level, format, type)
	GLenum	target
	GLint	level
	GLenum	format
	GLenum	type
	PPCODE:
	{
		GLint width, height;
		GLvoid * ptr;

		glGetTexLevelParameteriv(target, level,
			GL_TEXTURE_WIDTH, &width);
		glGetTexLevelParameteriv(target, level,
			GL_TEXTURE_HEIGHT, &height);

		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_PACK_ROW_LENGTH, 0);
		glPixelStorei(GL_PACK_ALIGNMENT, 1);

		ptr = allocate_image_ST(width, height, 1, format, type, 0);
		glGetTexImage(target, level, format, type, ptr);
		sp = unpack_image_ST(sp, ptr, width, height, 1, format, type, 0);

		free(ptr);
		glPopClientAttrib();
	}

#// 1.0
#//# glGetTexLevelParameterfv_c($target, $level, $pname, (CPTR)params);
void
glGetTexLevelParameterfv_c(target, level, pname, params)
	GLenum	target
	GLint	level
	GLenum	pname
	void *	params
	CODE:
	glGetTexLevelParameterfv(target, level, pname, params);

#// 1.0
#//# glGetTexLevelParameteriv_c($target, $level, $pname, (CPTR)params);
void
glGetTexLevelParameteriv_c(target, level, pname, params)
	GLenum	target
	GLint	level
	GLenum	pname
	void *	params
	CODE:
	glGetTexLevelParameteriv(target, level, pname, params);

#// 1.0
#//# glGetTexLevelParameterfv_s($target, $level, $pname, (PACKED)params);
void
glGetTexLevelParameterfv_s(target, level, pname, params)
	GLenum	target
	GLint	level
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat)*1);
	glGetTexLevelParameterfv(target, level, pname, params_s);
	}

#// 1.0
#//# glGetTexLevelParameteriv_s($target, $level, $pname, (PACKED)params);
void
glGetTexLevelParameteriv_s(target, level, pname, params)
	GLenum	target
	GLint	level
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*1);
	glGetTexLevelParameteriv(target, level, pname, params_s);
	}

#// 1.0
#//# @params = glGetTexLevelParameterfv_p($target, $level, $pname);
void
glGetTexLevelParameterfv_p(target, level, pname)
	GLenum	target
	GLint	level
	GLenum	pname
	PPCODE:
	{
		GLfloat	ret;
		glGetTexLevelParameterfv(target, level, pname, &ret);
		PUSHs(sv_2mortal(newSVnv(ret)));
	}

#// 1.0
#//# @params = glGetTexLevelParameteriv_p($target, $level, $pname);
void
glGetTexLevelParameteriv_p(target, level, pname)
	GLenum	target
	GLint	level
	GLenum	pname
	PPCODE:
	{
		GLint	ret;
		glGetTexLevelParameteriv(target, level, pname, &ret);
		PUSHs(sv_2mortal(newSViv(ret)));
	}

#// 1.0
#//# glGetTexParameterfv_c($target, $pname, (CPTR)params);
void
glGetTexParameterfv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
	glGetTexParameterfv(target, pname, params);

#// 1.0
#//# glGetTexParameteriv_c($target, $pname, (CPTR)params);
void
glGetTexParameteriv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
	glGetTexParameteriv(target, pname, params);

#// 1.0
#//# glGetTexParameterfv_s($target, $pname, (PACKED)params);
void
glGetTexParameterfv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params,
		sizeof(GLfloat)*gl_texparameter_count(pname));
	glGetTexParameterfv(target, pname, params_s);
	}

#// 1.0
#//# glGetTexParameteriv_s($target, $pname, (PACKED)params);
void
glGetTexParameteriv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params,
		sizeof(GLint)*gl_texparameter_count(pname));
	glGetTexParameteriv(target, pname, params_s);
	}

#// 1.0
#//# @params = glGetTexParameterfv_p($target, $pname);
void
glGetTexParameterfv_p(target, pname)
	GLenum	target
	GLenum	pname
	PPCODE:
	{
		GLfloat	ret[MAX_GL_TEXPARAMETER_COUNT];
		int n = gl_texparameter_count(pname);
		int i;
		glGetTexParameterfv(target, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @params = glGetTexParameteriv_p($target, $pname);
void
glGetTexParameteriv_p(target, pname)
	GLenum	target
	GLenum	pname
	PPCODE:
	{
		GLint	ret[MAX_GL_TEXPARAMETER_COUNT];
		int n = gl_texparameter_count(pname);
		int i;
		glGetTexParameteriv(target, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glHint($target, $mode);
void
glHint(target, mode)
	GLenum	target
	GLenum	mode

#// 1.0
#//# glIndexd($c);
void
glIndexd(c)
	GLdouble	c

#// 1.0
#//# glIndexi($c);
void
glIndexi(c)
	GLint	c

#// 1.0
#//# glIndexMask($mask)
void
glIndexMask(mask)
	GLuint	mask


#// 1.0
#//# glInitNames();
void
glInitNames()

#ifdef GL_VERSION_1_1

#// 1.1
#//# glInterleavedArrays_c($format, $stride, (CPTR)pointer);
void
glInterleavedArrays_c(format, stride, pointer)
	GLenum	format
	GLsizei	stride
	void *	pointer
	CODE:
	glInterleavedArrays(format, stride, pointer);

#endif

#// 1.0
#//# glIsEnabled($cap);
GLboolean
glIsEnabled(cap)
	GLenum	cap

#// 1.0
#//# glIsList(list);
GLboolean
glIsList(list)
	GLuint	list

#ifdef GL_VERSION_1_1

#// 1.1
#//# glIsTexture($list);
GLboolean
glIsTexture(list)
	GLuint	list

#endif


#// 1.0
#//# glLightf($light, $pname, $param);
void
glLightf(light, pname, param)
	GLenum	light
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glLighti($light, $pname, $param);
void
glLighti(light, pname, param)
	GLenum	light
	GLenum	pname
	GLint	param

#// 1.0
#//# glLightfv_c($light, $pname, (CPTR)params);
void
glLightfv_c(light, pname, params)
	GLenum	light
	GLenum	pname
	void *	params
	CODE:
	glLightfv(light, pname, params);

#// 1.0
#//# glLightiv_c($light, $pname, (CPTR)params);
void
glLightiv_c(light, pname, params)
	GLenum	light
	GLenum	pname
	void *	params
	CODE:
	glLightiv(light, pname, params);

#// 1.0
#//# glLightfv_s($light, $pname, (PACKED)params);
void
glLightfv_s(light, pname, params)
	GLenum	light
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat)*gl_light_count(pname));
	glLightfv(light, pname, params_s);
	}

#// 1.0
#//# glLightiv_s($light, $pname, (PACKED)params);
void
glLightiv_s(light, pname, params)
	GLenum	light
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*gl_light_count(pname));
	glLightiv(light, pname, params_s);
	}

#// 1.0
#//# glLightfv_p($light, $pname, @params);
void
glLightfv_p(light, pname, ...)
	GLenum	light
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_LIGHT_COUNT];
		int i;
		if ((items-2) != gl_light_count(pname))
			croak("Incorrect number of arguments");
		for(i=2;i<items;i++)
			p[i-2] = (GLfloat)SvNV(ST(i));
		glLightfv(light, pname, &p[0]);
	}

#// 1.0
#//# glLightiv_p($light, $pname, @params);
void
glLightiv_p(light, pname, ...)
	GLenum	light
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_LIGHT_COUNT];
		int i;
		if ((items-2) != gl_light_count(pname))
			croak("Incorrect number of arguments");
		for(i=2;i<items;i++)
			p[i-2] = SvIV(ST(i));
		glLightiv(light, pname, &p[0]);
	}

#// 1.0
#//# glLightModelf($pname, $param);
void
glLightModelf(pname, param)
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glLightModeli($pname, $param);
void
glLightModeli(pname, param)
	GLenum	pname
	GLint	param

#// 1.0
#//# glLightModeliv_c($pname, (CPTR)params);
void
glLightModeliv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glLightModeliv(pname, params);

#// 1.0
#//# glLightModelfv_c($pname, (CPTR)params);
void
glLightModelfv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glLightModelfv(pname, params);

#// 1.0
#//# glLightModeliv_s($pname, (PACKED)params);
void
glLightModeliv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*gl_lightmodel_count(pname));
	glLightModeliv(pname, params_s);
	}

#// 1.0
#//# glLightModelfv_s($pname, (PACKED)params);
void
glLightModelfv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params,
		sizeof(GLfloat)*gl_lightmodel_count(pname));
	glLightModelfv(pname, params_s);
	}

#// 1.0
#//# glLightModelfv_p($pname, @params);
void
glLightModelfv_p(pname, ...)
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_LIGHTMODEL_COUNT];
		int i;
		if ((items-1) != gl_lightmodel_count(pname))
			croak("Incorrect number of arguments");
		for(i=1;i<items;i++)
			p[i-1] = (GLfloat)SvNV(ST(i));
		glLightModelfv(pname, &p[0]);
	}

#// 1.0
#//# glLightModeliv_p($pname, @params);
void
glLightModeliv_p(pname, ...)
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_LIGHTMODEL_COUNT];
		int i;
		if ((items-1) != gl_lightmodel_count(pname))
			croak("Incorrect number of arguments");
		for(i=1;i<items;i++)
			p[i-1] = SvIV(ST(i));
		glLightModeliv(pname, &p[0]);
	}

#// 1.0
#//# glLineStipple($factor, $pattern);
void
glLineStipple(factor, pattern)
	GLint	factor
	GLushort	pattern

#// 1.0
#//# glLineWidth($width);
void
glLineWidth(width)
	GLfloat	width

#// 1.0
#//# glListBase($base);
void
glListBase(base)
	GLuint	base

#// 1.0
#//# glLoadIdentity();
void
glLoadIdentity()

#// 1.0
#//# glLoadMatrixf_c((CPTR)m);
void
glLoadMatrixf_c(m)
	void *	m
	CODE:
	glLoadMatrixf(m);

#// 1.0
#//# glLoadMatrixd_c((CPTR)m);
void
glLoadMatrixd_c(m)
	void *	m
	CODE:
	glLoadMatrixd(m);

#// 1.0
#//# glLoadMatrixf_s((PACKED)m);
void
glLoadMatrixf_s(m)
	SV *	m
	CODE:
	{
	GLfloat * m_s = EL(m, sizeof(GLfloat)*16);
	glLoadMatrixf(m_s);
	}

#// 1.0
#//# glLoadMatrixd_s((PACKED)m);
void
glLoadMatrixd_s(m)
	SV *	m
	CODE:
	{
	GLdouble * m_s = EL(m, sizeof(GLdouble)*16);
	glLoadMatrixd(m_s);
	}

#// 1.0
#//# glLoadMatrixd_p(@m);
void
glLoadMatrixd_p(...)
	CODE:
	{
		GLdouble m[16];
		int i;
		if (items != 16)
			croak("Incorrect number of arguments");
		for (i=0;i<16;i++)
			m[i] = SvNV(ST(i));
		glLoadMatrixd(&m[0]);
	}

#// 1.0
#//# glLoadMatrixf_p(@m);
void
glLoadMatrixf_p(...)
	CODE:
	{
		GLfloat m[16];
		int i;
		if (items != 16)
			croak("Incorrect number of arguments");
		for (i=0;i<16;i++)
			m[i] = (GLfloat)SvNV(ST(i));
		glLoadMatrixf(&m[0]);
	}

#// 1.0
#//# glLoadName($name);
void
glLoadName(name)
	GLuint	name

#// 1.0
#//# glLogicOp($opcode);
void
glLogicOp(opcode)
	GLenum	opcode

#// 1.0
#//# glMap1d_c($target, $u1, $u2, $stride, $order, (CPTR)points);
void
glMap1d_c(target, u1, u2, stride, order, points)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	stride
	GLint	order
	void *	points
	CODE:
	glMap1d(target, u1, u2, stride, order, points);

#// 1.0
#//# glMap1f_c($target, $u1, $u2, $stride, $order, (CPTR)points);
void
glMap1f_c(target, u1, u2, stride, order, points)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	stride
	GLint	order
	void *	points
	CODE:
	glMap1f(target, u1, u2, stride, order, points);

#// 1.0
#//# glMap1d_s($target, $u1, $u2, $stride, $order, (PACKED)points);
void
glMap1d_s(target, u1, u2, stride, order, points)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	stride
	GLint	order
	SV *	points
	CODE:
	{
	GLdouble * points_s = EL(points, 0 /*FIXME*/);
	glMap1d(target, u1, u2, stride, order, points_s);
	}

#// 1.0
#//# glMap1f_s($target, $u1, $u2, $stride, $order, (PACKED)points);
void
glMap1f_s(target, u1, u2, stride, order, points)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	stride
	GLint	order
	SV *	points
	CODE:
	{
	GLfloat * points_s = EL(points, 0 /*FIXME*/);
	glMap1f(target, u1, u2, stride, order, points_s);
	}

#// 1.0
#//# glMap1d_p($target, $u1, $u2, @points);
#//- Assumes 0 stride
void
glMap1d_p(target, u1, u2, ...)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	CODE:
	{
		int count = items-3;
		GLint order = (items - 3) / gl_map_count(target, GL_COEFF);
		GLdouble * points = malloc(sizeof(GLdouble) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = SvNV(ST(i+3));
		glMap1d(target, u1, u2, 0, order, points);
		free(points);
	}

#// 1.0
#//# glMap1f_p($target, $u1, $u2, @points);
#//- Assumes 0 stride
void
glMap1f_p(target, u1, u2, ...)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	CODE:
	{
		int count = items-3;
		GLint order = (items - 3) / gl_map_count(target, GL_COEFF);
		GLfloat * points = malloc(sizeof(GLfloat) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = (GLfloat)SvNV(ST(i+3));
		glMap1f(target, u1, u2, 0, order, points);
		free(points);
	}

#// 1.0
#//# glMap2d_c($target, $u1, $u2, $ustride, $uorder, $v1, $v2, $vstride, $vorder, (CPTR)points);
void
glMap2d_c(target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	ustride
	GLint	uorder
	GLdouble	v1
	GLdouble	v2
	GLint	vstride
	GLint	vorder
	void *	points
	CODE:
	glMap2d(target, u1, u2, ustride, uorder, v1, v2,
		vstride, vorder, points);

#// 1.0
#//# glMap2f_c($target, $u1, $u2, $ustride, $uorder, $v1, $v2, $vstride, $vorder, (CPTR)points);
void
glMap2f_c(target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	ustride
	GLint	uorder
	GLfloat	v1
	GLfloat	v2
	GLint	vstride
	GLint	vorder
	void *	points
	CODE:
	glMap2f(target, u1, u2, ustride, uorder, v1, v2,
		vstride, vorder, points);

#// 1.0
#//# glMap2d_s($target, $u1, $u2, $ustride, $uorder, $v1, $v2, $vstride, $vorder, (PACKED)points);
void
glMap2d_s(target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	ustride
	GLint	uorder
	GLdouble	v1
	GLdouble	v2
	GLint	vstride
	GLint	vorder
	SV *	points
	CODE:
	{
	GLdouble * points_s = EL(points, 0 /*FIXME*/);
	glMap2d(target, u1, u2, ustride, uorder, v1, v2,
		vstride, vorder, points_s);
	}

#// 1.0
#//# glMap2f_s($target, $u1, $u2, $ustride, $uorder, $v1, $v2, $vstride, $vorder, (PACKED)points);
void
glMap2f_s(target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	ustride
	GLint	uorder
	GLfloat	v1
	GLfloat	v2
	GLint	vstride
	GLint	vorder
	SV *	points
	CODE:
	{
	GLfloat * points_s = EL(points, 0 /*FIXME*/);
	glMap2f(target, u1, u2, ustride, uorder, v1, v2,
		vstride, vorder, points_s);
	}

#// 1.0
#//# glMap2d_p($target, $u1, $u2, $uorder, $v1, $v2, @points);
#//- Assumes 0 ustride and vstride
void
glMap2d_p(target, u1, u2, uorder, v1, v2, ...)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	uorder
	GLdouble	v1
	GLdouble	v2
	CODE:
	{
		int count = items-6;
		GLint vorder = (count / uorder) / gl_map_count(target, GL_COEFF);
		GLdouble * points = malloc(sizeof(GLdouble) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = SvNV(ST(i+6));
		glMap2d(target, u1, u2, 0, uorder, v1, v2, 0, vorder, points);
		free(points);
	}

#// 1.0
#//# glMap2f_p($target, $u1, $u2, $uorder, $v1, $v2, @points);
#//- Assumes 0 ustride and vstride
void
glMap2f_p(target, u1, u2, uorder, v1, v2, ...)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	uorder
	GLfloat	v1
	GLfloat	v2
	CODE:
	{
		int count = items-6;
		GLint vorder = (count / uorder) / gl_map_count(target, GL_COEFF);
		GLfloat * points = malloc(sizeof(GLfloat) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = (GLfloat)SvNV(ST(i+6));
		glMap2f(target, u1, u2, 0, uorder, v1, v2, 0, vorder, points);
		free(points);
	}

#// 1.0
#//# glMapGrid1d($un, $u1, $u2);
void
glMapGrid1d(un, u1, u2)
	GLint	un
	GLdouble	u1
	GLdouble	u2

#// 1.0
#//# glMapGrid1f($un, $u1, $u2);
void
glMapGrid1f(un, u1, u2)
	GLint	un
	GLfloat	u1
	GLfloat	u2

#// 1.0
#//# glMapGrid2d($un, $u1, $u2, $vn, $v1, $v2);
void
glMapGrid2d(un, u1, u2, vn, v1, v2)
	GLint	un
	GLdouble	u1
	GLdouble	u2
	GLint	vn
	GLdouble	v1
	GLdouble	v2

#// 1.0
#//# glMapGrid2f($un, $u1, $u2, $vn, $v1, $v2);
void
glMapGrid2f(un, u1, u2, vn, v1, v2)
	GLint	un
	GLfloat	u1
	GLfloat	u2
	GLint	vn
	GLfloat	v1
	GLfloat	v2

#// 1.0
#//# glMaterialf($face, $pname, $param);
void
glMaterialf(face, pname, param)
	GLenum	face
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glMateriali($face, $pname, $param);
void
glMateriali(face, pname, param)
	GLenum	face
	GLenum	pname
	GLint	param

#// 1.0
#//# glMaterialfv_c($face, $pname, (CPTR)param);
void
glMaterialfv_c(face, pname, param)
	GLenum	face
	GLenum	pname
	void *	param
	CODE:
	glMaterialfv(face, pname, param);

#// 1.0
#//# glMaterialiv_c($face, $pname, (CPTR)param);
void
glMaterialiv_c(face, pname, param)
	GLenum	face
	GLenum	pname
	void *	param
	CODE:
	glMaterialiv(face, pname, param);

#// 1.0
#//# glMaterialfv_s($face, $pname, (PACKED)param);
void
glMaterialfv_s(face, pname, param)
	GLenum	face
	GLenum	pname
	SV *	param
	CODE:
	{
	GLfloat * param_s = EL(param, sizeof(GLfloat)*gl_material_count(pname));
	glMaterialfv(face, pname, param_s);
	}

#// 1.0
#//# glMaterialiv_s($face, $pname, (PACKED)param);
void
glMaterialiv_s(face, pname, param)
	GLenum	face
	GLenum	pname
	SV *	param
	CODE:
	{
	GLint * param_s = EL(param, sizeof(GLint)*gl_material_count(pname));
	glMaterialiv(face, pname, param_s);
	}

#// 1.0
#//# glMaterialfv_s($face, $pname, @param);
void
glMaterialfv_p(face, pname, ...)
	GLenum	face
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_MATERIAL_COUNT];
		int i;
		if ((items-2) != gl_material_count(pname))
			croak("Incorrect number of arguments");
		for(i=2;i<items;i++)
			p[i-2] = (GLfloat)SvNV(ST(i));
		glMaterialfv(face, pname, &p[0]);
	}

#// 1.0
#//# glMaterialiv_s($face, $pname, @param);
void
glMaterialiv_p(face, pname, ...)
	GLenum	face
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_MATERIAL_COUNT];
		int i;
		if ((items-2) != gl_material_count(pname))
			croak("Incorrect number of arguments");
		for(i=2;i<items;i++)
			p[i-2] = SvIV(ST(i));
		glMaterialiv(face, pname, &p[0]);
	}

#// 1.0
#//# glMatrixMode($mode);
void
glMatrixMode(mode)
	GLenum	mode

#// 1.0
#//# glMultMatrixd_p(@m);
void
glMultMatrixd_p(...)
	CODE:
	{
		GLdouble m[16];
		int i;
		if (items != 16)
			croak("Incorrect number of arguments");
		for (i=0;i<16;i++)
			m[i] = SvNV(ST(i));
		glMultMatrixd(&m[0]);
	}

#// 1.0
#//# glMultMatrixf_p(@m);
void
glMultMatrixf_p(...)
	CODE:
	{
		GLfloat m[16];
		int i;
		if (items != 16)
			croak("Incorrect number of arguments");
		for (i=0;i<16;i++)
			m[i] = (GLfloat)SvNV(ST(i));
		glMultMatrixf(&m[0]);
	}

#// 1.0
#//# glNewList($list, $mode);
void
glNewList(list, mode)
	GLuint	list
	GLenum	mode

#// 1.0
#//# glEndList();
void
glEndList()


#// 1.0
#//# glOrtho($left, $right, $bottom, $top, $zNear, $zFar);
void
glOrtho(left, right, bottom, top, zNear, zFar)
	GLdouble	left
	GLdouble	right
	GLdouble	bottom
	GLdouble	top
	GLdouble	zNear
	GLdouble	zFar

#// 1.0
#//# glPassThrough($token);
void
glPassThrough(token)
	GLfloat	token

#// 1.0
#//# glPixelMapfv_c($map, $mapsize, (CPTR)values);
void
glPixelMapfv_c(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	void *	values
	CODE:
	glPixelMapfv(map, mapsize, values);

#// 1.0
#//# glPixelMapuiv_c($map, $mapsize, (CPTR)values);
void
glPixelMapuiv_c(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	void *	values
	CODE:
	glPixelMapuiv(map, mapsize, values);

#// 1.0
#//# glPixelMapusv_c($map, $mapsize, (CPTR)values);
void
glPixelMapusv_c(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	void *	values
	CODE:
	glPixelMapusv(map, mapsize, values);

#// 1.0
#//# glPixelMapfv_s($map, $mapsize, (PACKED)values);
void
glPixelMapfv_s(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	SV *	values
	CODE:
	{
	GLfloat * values_s = EL(values, sizeof(GLfloat)*mapsize);
	glPixelMapfv(map, mapsize, values_s);
	}

#// 1.0
#//# glPixelMapuiv_s($map, $mapsize, (PACKED)values);
void
glPixelMapuiv_s(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	SV *	values
	CODE:
	{
	GLuint * values_s = EL(values, sizeof(GLuint)*mapsize);
	glPixelMapuiv(map, mapsize, values_s);
	}

#// 1.0
#//# glPixelMapusv_s($map, $mapsize, (PACKED)values);
void
glPixelMapusv_s(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	SV *	values
	CODE:
	{
	GLushort * values_s = EL(values, sizeof(GLushort)*mapsize);
	glPixelMapusv(map, mapsize, values_s);
	}

#// 1.0
#//# glPixelMapfv_p($map, @values);
void
glPixelMapfv_p(map, ...)
	GLenum	map
	CODE:
	{
		GLint mapsize = items-1;
		GLfloat * values;
		int i;
		values = malloc(sizeof(GLfloat) * (mapsize+1));
		for (i=0;i<mapsize;i++)
			values[i] = (GLfloat)SvNV(ST(i+1));
		glPixelMapfv(map, mapsize, values);
		free(values);
	}

#// 1.0
#//# glPixelMapuiv_p($map, @values);
void
glPixelMapuiv_p(map, ...)
	GLenum	map
	CODE:
	{
		GLint mapsize = items-1;
		GLuint * values;
		int i;
		values = malloc(sizeof(GLuint) * (mapsize+1));
		for (i=0;i<mapsize;i++)
			values[i] = SvIV(ST(i+1));
		glPixelMapuiv(map, mapsize, values);
		free(values);
	}

#// 1.0
#//# glPixelMapusv_p($map, @values);
void
glPixelMapusv_p(map, ...)
	GLenum	map
	CODE:
	{
		GLint mapsize = items-1;
		GLushort * values;
		int i;
		values = malloc(sizeof(GLushort) * (mapsize+1));
		for (i=0;i<mapsize;i++)
			values[i] = (GLushort)SvIV(ST(i+1));
		glPixelMapusv(map, mapsize, values);
		free(values);
	}

#// 1.0
#//# glPixelStoref($pname, $param);
void
glPixelStoref(pname, param)
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glPixelStorei($pname, $param);
void
glPixelStorei(pname, param)
	GLenum	pname
	GLint	param

#// 1.0
#//# glPixelTransferf($pname, $param);
void
glPixelTransferf(pname, param)
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glPixelTransferi($pname, $param);
void
glPixelTransferi(pname, param)
	GLenum	pname
	GLint	param

#// 1.0
#//# glPixelZoom($xfactor, $yfactor);
void
glPixelZoom(xfactor, yfactor)
	GLfloat	xfactor
	GLfloat	yfactor

#// 1.0
#//# glPointSize($size);
void
glPointSize(size)
	GLfloat	size

#// 1.0
#//# glPolygonMode($face, $mode);
void
glPolygonMode(face, mode)
	GLenum	face
	GLenum	mode

#ifdef GL_VERSION_1_1

#// 1.1
#//# glPolygonOffset($factor, $units);
void
glPolygonOffset(factor, units)
	GLfloat	factor
	GLfloat	units

#endif

#// 1.0
#//# glPolygonStipple_c((CPTR)mask);
void
glPolygonStipple_c(mask)
	void *	mask
	CODE:
	glPolygonStipple(mask);

#// 1.0
#//# glPolygonStipple_s((PACKED)mask);
void
glPolygonStipple_s(mask)
	SV *	mask
	CODE:
	{
	GLubyte * ptr = ELI(mask, 32, 32, GL_COLOR_INDEX, GL_BITMAP, 0);
	glPolygonStipple(ptr);
	}

#//# glPolygonStipple_p(@mask);
void
glPolygonStipple_p(...)
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(0)), items, 32, 32, 1,
		GL_COLOR_INDEX, GL_BITMAP, 0);
	glPolygonStipple(ptr);
	glPopClientAttrib();
	free(ptr);
	}

#ifdef GL_VERSION_1_1

#// 1.1
#//# glPrioritizeTextures_c($n, (CPTR)textures, (CPTR)priorities);
void
glPrioritizeTextures_c(n, textures, priorities)
	GLsizei	n
	void *	textures
	void *	priorities
	CODE:
	glPrioritizeTextures(n, textures, priorities);

#// 1.1
#//# glPrioritizeTextures_s($n, (PACKED)textures, (PACKED)priorities);
void
glPrioritizeTextures_s(n, textures, priorities)
	GLsizei	n
	SV *	textures
	SV *	priorities
	CODE:
	{
	GLuint * textures_s = EL(textures, sizeof(GLuint) * n);
	GLclampf * priorities_s = EL(priorities, sizeof(GLclampf) * n);
	glPrioritizeTextures(n, textures_s, priorities_s);
	}

#// 1.1
#//# glPrioritizeTextures_p(@textureIDs, @priorities);
void
glPrioritizeTextures_p(...)
	CODE:
	{
		GLsizei n = items/2;
		GLuint * textures = malloc(sizeof(GLuint) * (n+1));
		GLclampf * prior = malloc(sizeof(GLclampf) * (n+1));
		int i;

		for (i=0;i<n;i++) {
			textures[i] = SvIV(ST(i * 2 + 0));
			prior[i] = (GLclampf)SvNV(ST(i * 2 + 1));
		}

		glPrioritizeTextures(n, textures, prior);

		free(textures);
		free(prior);
	}

#endif

#// 1.0
#//# glPushAttrib($mask);
void
glPushAttrib(mask)
	GLbitfield	mask

#// 1.0
#//# glPopAttrib();
void
glPopAttrib()

#// 1.0
#//# glPushClientAttrib($mask);
void
glPushClientAttrib(mask)
	GLbitfield	mask

#// 1.0
#//# glPopClientAttrib();
void
glPopClientAttrib()

#// 1.0
#//# glPushMatrix();
void
glPushMatrix()

#// 1.0
#//# glPopMatrix();
void
glPopMatrix()

#// 1.0
#//# glPushName($name);
void
glPushName(name)
	GLuint	name

#// 1.0
#//# glPopName();
void
glPopName()


#// 1.0
#//# glReadBuffer($mode);
void
glReadBuffer(mode)
	GLenum	mode

#// 1.0
#//# glReadPixels_c($x, $y, $width, $height, $format, $type, (CPTR)pixels);
void
glReadPixels_c(x, y, width, height, format, type, pixels)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glReadPixels(x, y, width, height, format, type, pixels);

#// 1.0
#//# glReadPixels_s($x, $y, $width, $height, $format, $type, (PACKED)pixels);
void
glReadPixels_s(x, y, width, height, format, type, pixels)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
		void * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_pack);
		glReadPixels(x, y, width, height, format, type, ptr);
	}

#// 1.0
#//# @pixels = glReadPixels_p($x, $y, $width, $height, $format, $type);
void
glReadPixels_p(x, y, width, height, format, type)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	PPCODE:
	{
		void * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_PACK_ROW_LENGTH, 0);
		glPixelStorei(GL_PACK_ALIGNMENT, 1);
		ptr = allocate_image_ST(width, height, 1, format, type, 0);
		glReadPixels(x, y, width, height, format, type, ptr);
		sp = unpack_image_ST(sp, ptr, width, height, 1, format, type, 0);
		free(ptr);
		glPopClientAttrib();
	}

#// 1.0
#//# glRecti($x1, $y1, $x2, $y2);
void
glRecti(x1, y1, x2, y2)
	GLint	x1
	GLint	y1
	GLint	x2
	GLint	y2
	ALIAS:
		glRectiv_p = 1


#// 1.0
#//# glRects($x1, $y1, $x2, $y2);
void
glRects(x1, y1, x2, y2)
	GLshort	x1
	GLshort	y1
	GLshort	x2
	GLshort	y2
	ALIAS:
		glRectsv_p = 1

#// 1.0
#//# glRectd($x1, $y1, $x2, $y2);
void
glRectd(x1, y1, x2, y2)
	GLdouble	x1
	GLdouble	y1
	GLdouble	x2
	GLdouble	y2
	ALIAS:
		glRectdv_p = 1

#// 1.0
#//# glRectf($x1, $y1, $x2, $y2);
void
glRectf(x1, y1, x2, y2)
	GLfloat	x1
	GLfloat	y1
	GLfloat	x2
	GLfloat	y2
	ALIAS:
		glRectfv_p = 1


#// 1.0
#//# glRectsv_c((CPTR)v1, (CPTR)v2);
void
glRectsv_c(v1, v2)
	void *	v1
	void *	v2
	CODE:
	glRectsv(v1, v2);

#// 1.0
#//# glRectiv_c((CPTR)v1, (CPTR)v2);
void
glRectiv_c(v1, v2)
	void *	v1
	void *	v2
	CODE:
	glRectiv(v1, v2);

#// 1.0
#//# glRectfv_c((CPTR)v1, (CPTR)v2);
void
glRectfv_c(v1, v2)
	void *	v1
	void *	v2
	CODE:
	glRectfv(v1, v2);

#// 1.0
#//# glRectdv_c((CPTR)v1, (CPTR)v2);
void
glRectdv_c(v1, v2)
	void *	v1
	void *	v2
	CODE:
	glRectdv(v1, v2);

#// 1.0
#//# glRectdv_s((PACKED)v1, (PACKED)v2);
void
glRectdv_s(v1, v2)
	SV *	v1
	SV *	v2
	CODE:
	{
	GLdouble * v1_s = EL(v1, sizeof(GLdouble)*2);
	GLdouble * v2_s = EL(v2, sizeof(GLdouble)*2);
	glRectdv(v1_s, v2_s);
	}

#// 1.0
#//# glRectfv_s((PACKED)v1, (PACKED)v2);
void
glRectfv_s(v1, v2)
	SV *	v1
	SV *	v2
	CODE:
	{
	GLfloat * v1_s = EL(v1, sizeof(GLfloat)*2);
	GLfloat * v2_s = EL(v2, sizeof(GLfloat)*2);
	glRectfv(v1_s, v2_s);
	}

#// 1.0
#//# glRectiv_s((PACKED)v1, (PACKED)v2);
void
glRectiv_s(v1, v2)
	SV *	v1
	SV *	v2
	CODE:
	{
	GLint * v1_s = EL(v1, sizeof(GLint)*2);
	GLint * v2_s = EL(v2, sizeof(GLint)*2);
	glRectiv(v1_s, v2_s);
	}

#// 1.0
#//# glRectsv_s((PACKED)v1, (PACKED)v2);
void
glRectsv_s(v1, v2)
	SV *	v1
	SV *	v2
	CODE:
	{
	GLshort * v1_s = EL(v1, sizeof(GLshort)*2);
	GLshort * v2_s = EL(v2, sizeof(GLshort)*2);
	glRectsv(v1_s, v2_s);
	}

#// 1.0
#//# glRenderMode($mode);
GLint
glRenderMode(mode)
	GLenum	mode

#// 1.0
#//# glRotated($angle, $x, $y, $z);
void
glRotated(angle, x, y, z)
	GLdouble	angle
	GLdouble	x
	GLdouble	y
	GLdouble	z

#// 1.0
#//# glRotatef($angle, $x, $y, $z);
void
glRotatef(angle, x, y, z)
	GLfloat	angle
	GLfloat	x
	GLfloat	y
	GLfloat	z

#// 1.0
#//# glScaled($x, $y, $z);
void
glScaled(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z

#// 1.0
#//# glScalef($x, $y, $z);
void
glScalef(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z

#// 1.0
#//# glScissor($x, $y, $width, $height);
void
glScissor(x, y, width, height)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height

#// 1.0
#//# glSelectBuffer_c($size, (CPTR)list);
void
glSelectBuffer_c(size, list)
	GLsizei	size
	void *	list
	CODE:
	glSelectBuffer(size, list);

#// 1.0
#//# glShadeModel($mode);
void
glShadeModel(mode)
	GLenum	mode

#// 1.0
#//# glStencilFunc($func, $ref, $mask);
void
glStencilFunc(func, ref, mask)
	GLenum	func
	GLint	ref
	GLuint	mask

#// 1.0
#//# glStencilMask($mask);
void
glStencilMask(mask)
	GLuint	mask

#// 1.0
#//# glStencilOp($fail, $zfail, $zpass);
void
glStencilOp(fail, zfail, zpass)
	GLenum	fail
	GLenum	zfail
	GLenum	zpass



#// 1.0
#//# glTexEnvf($target, $pname, $param);
void
glTexEnvf(target, pname, param)
	GLenum	target
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glTexEnvi($target, $pname, $param);
void
glTexEnvi(target, pname, param)
	GLenum	target
	GLenum	pname
	GLint	param

#// 1.0
#//# glTexEnvfv_s(target, pname, (PACKED)params);
void
glTexEnvfv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat)*gl_texenv_count(pname));
	glTexEnvfv(target, pname, params_s);
	}

#// 1.0
#//# glTexEnviv_s(target, pname, (PACKED)params);
void
glTexEnviv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*gl_texenv_count(pname));
	glTexEnviv(target, pname, params_s);
	}

#// 1.0
#//# glTexEnvfv_p(target, pname, @params);
void
glTexEnvfv_p(target, pname, ...)
	GLenum	target
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_TEXENV_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texenv_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = (GLfloat)SvNV(ST(i));
		glTexEnvfv(target, pname, &p[0]);
	}

#// 1.0
#//# glTexEnviv_p(target, pname, @params);
void
glTexEnviv_p(target, pname, ...)
	GLenum	target
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_TEXENV_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texenv_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = SvIV(ST(i));
		glTexEnviv(target, pname, &p[0]);
	}

#// 1.0
#//# glTexGend($Coord, $pname, $param);
void
glTexGend(Coord, pname, param)
	GLenum	Coord
	GLenum	pname
	GLdouble	param

#// 1.0
#//# glTexGenf($Coord, $pname, $param);
void
glTexGenf(Coord, pname, param)
	GLenum	Coord
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glTexGeni($Coord, $pname, $param);
void
glTexGeni(Coord, pname, param)
	GLenum	Coord
	GLenum	pname
	GLint	param

#// 1.0
#//# glTexGendv_c($Coord, $pname, (CPTR)params);
void
glTexGendv_c(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	void *	params
	CODE:
	glTexGendv(Coord, pname, params);

#// 1.0
#//# glTexGenfv_c($Coord, $pname, (CPTR)params);
void
glTexGenfv_c(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	void *	params
	CODE:
	glTexGenfv(Coord, pname, params);

#// 1.0
#//# glTexGeniv_c($Coord, $pname, (CPTR)params);
void
glTexGeniv_c(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	void *	params
	CODE:
	glTexGeniv(Coord, pname, params);

#// 1.0
#//# glTexGendv_s($Coord, $pname, (PACKED)params);
void
glTexGendv_s(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLdouble * params_s = EL(params,
		sizeof(GLdouble)* gl_texgen_count(pname));
	glTexGendv(Coord, pname, params_s);
	}

#// 1.0
#//# glTexGenfv_s($Coord, $pname, (PACKED)params);
void
glTexGenfv_s(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params,
		sizeof(GLfloat)* gl_texgen_count(pname));
	glTexGenfv(Coord, pname, params_s);
	}

#// 1.0
#//# glTexGeniv_s($Coord, $pname, (PACKED)params);
void
glTexGeniv_s(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params,
		sizeof(GLint)* gl_texgen_count(pname));
	glTexGeniv(Coord, pname, params_s);
	}

#// 1.0
#//# glTexGendv_p($Coord, $pname, @params);
void
glTexGendv_p(Coord, pname, ...)
	GLenum	Coord
	GLenum	pname
	CODE:
	{
		GLdouble p[MAX_GL_TEXGEN_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texgen_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = SvNV(ST(i));
		glTexGendv(Coord, pname, &p[0]);
	}

#// 1.0
#//# glTexGenfv_p($Coord, $pname, @params);
void
glTexGenfv_p(Coord, pname, ...)
	GLenum	Coord
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_TEXGEN_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texgen_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = (GLfloat)SvNV(ST(i));
		glTexGenfv(Coord, pname, &p[0]);
	}

#// 1.0
#//# glTexGeniv_p($Coord, $pname, @params);
void
glTexGeniv_p(Coord, pname, ...)
	GLenum	Coord
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_TEXGEN_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texgen_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = SvIV(ST(i));
		glTexGeniv(Coord, pname, &p[0]);
	}

#// 1.0
#//# glTexImage1D_c($target, $level, $internalformat, $width, $border, $format, $type, (CPTR)pixels);
void
glTexImage1D_c(target, level, internalformat, width, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLint	border
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glTexImage1D(target, level, internalformat,
		width, border, format, type, pixels);

#// 1.0
#//# glTexImage1D_s($target, $level, $internalformat, $width, $border, $format, $type, (PACKED)pixels);
void
glTexImage1D_s(target, level, internalformat, width, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLint	border
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
	GLvoid * ptr = ELI(pixels, width, 1, format, type,
		gl_pixelbuffer_unpack);
	glTexImage1D(target, level, internalformat,
		width, border, format, type, ptr);
	}

#// 1.2
#//# glTexImage1D_p($target, $level, $internalformat, $width, $border, $format, $type, @pixels);
void
glTexImage1D_p(target, level, internalformat, width, border, format, type, ...)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLint	border
	GLenum	format
	GLenum	type
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(7)), items-7, width, 1, 1, format, type, 0);
	glTexImage1D(target, level, internalformat,
		width, border, format, type, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#// 1.0
#//# glTexImage2D_c($target, $level, $internalformat, $width, $height, $border, $format, $type, (CPTR)pixels);
void
glTexImage2D_c(target, level, internalformat, width, height, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLint	border
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glTexImage2D(target, level, internalformat,
		width, height, border, format, type, pixels);

#// 1.0
#//# glTexImage2D_s($target, $level, $internalformat, $width, $height, $border, $format, $type, (PACKED)pixels);
void
glTexImage2D_s(target, level, internalformat, width, height, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLint	border
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
		GLvoid * ptr = NULL;
		if (pixels)
		{
			ptr = ELI(pixels, width, height,
				format, type, gl_pixelbuffer_unpack);
		}
		glTexImage2D(target, level, internalformat,
			width, height, border, format, type, ptr);
	}

#// 1.2
#//# glTexImage2D_p($target, $level, $internalformat, $width, $height, $border, $format, $type, @pixels);
void
glTexImage2D_p(target, level, internalformat, width, height, border, format, type, ...)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLint	border
	GLenum	format
	GLenum	type
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(8)), items-8, width, height,
		1, format, type, 0);
	glTexImage2D(target, level, internalformat,
		width, height, border, format, type, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#ifdef GL_VERSION_1_2

#// 1.2
#//# glTexImage3D_c($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, (CPTR)pixels);
void
glTexImage3D_c(target, level, internalformat, width, height, depth, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	void *	pixels
	INIT:
		loadProc(glTexImage3D,"glTexImage3D");
	CODE:
		glTexImage3D(target, level, internalformat,
			width, height, depth, border, format, type, pixels);

#// 1.2
#//# glTexImage3D_s($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, (PACKED)pixels);
void
glTexImage3D_s(target, level, internalformat, width, height, depth, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	SV *	pixels
	INIT:
		loadProc(glTexImage3D,"glTexImage3D");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height, format,
			type, gl_pixelbuffer_unpack);
		glTexImage3D(target, level, internalformat,
			width, height, depth, border, format, type, ptr);
	}

#// 1.2
#//# glTexImage3D_p($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, @pixels);
void
glTexImage3D_p(target, level, internalformat, width, height, depth, border, format, type, ...)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	INIT:
		loadProc(glTexImage3D,"glTexImage3D");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(9)), items-9, width, height,
			depth, format, type, 0);
		glTexImage3D(target, level, internalformat,
			width, height, depth, border, format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#endif

#// 1.0
#//# glTexParameterf($target, $pname, $param);
void
glTexParameterf(target, pname, param)
	GLenum	target
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glTexParameteri($target, $pname, $param);
void
glTexParameteri(target, pname, param)
	GLenum	target
	GLenum	pname
	GLint	param

#// 1.0
#//# glTexParameterfv_c($target, $pname, (CPTR)params);
void
glTexParameterfv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
	glTexParameterfv(target, pname, params);

#// 1.0
#//# glTexParameteriv_c($target, $pname, (CPTR)params);
void
glTexParameteriv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
	glTexParameteriv(target, pname, params);

#// 1.0
#//# glTexParameterfv_s($target, $pname, (PACKED)params);
void
glTexParameterfv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params,
		sizeof(GLfloat)*gl_texparameter_count(pname));
	glTexParameterfv(target, pname, params_s);
	}

#// 1.0
#//# glTexParameteriv_s($target, $pname, (PACKED)params);
void
glTexParameteriv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params,
		sizeof(GLint)*gl_texparameter_count(pname));
	glTexParameteriv(target, pname, params_s);
	}

#// 1.0
#//# glTexParameterfv_p($target, $pname, @params);
void
glTexParameterfv_p(target, pname, ...)
	GLenum	target
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_TEXPARAMETER_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texparameter_count(pname))
			croak("Incorrect number of arguments");
		for(i=0;i<n;i++)
			p[i] = (GLfloat)SvNV(ST(i+2));
		glTexParameterfv(target, pname, &p[0]);
	}

#// 1.0
#//# glTexParameteriv_p($target, $pname, @params);
void
glTexParameteriv_p(target, pname, ...)
	GLenum	target
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_TEXPARAMETER_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texparameter_count(pname))
			croak("Incorrect number of arguments");
		for(i=0;i<n;i++)
			p[i] = SvIV(ST(i+2));
		glTexParameteriv(target, pname, &p[0]);
	}

#ifdef GL_VERSION_1_1

#// 1.1
#//# glTexSubImage1D_c($target, $level, $xoffset, $width, $border, $format, $type, (CPTR)pixels);
void
glTexSubImage1D_c(target, level, xoffset, width, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLsizei	width
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glTexSubImage1D(target, level, xoffset, width, format, type, pixels);

#// 1.1
#//# glTexSubImage1D_s($target, $level, $xoffset, $width, $border, $format, $type, (PACKED)pixels);
void
glTexSubImage1D_s(target, level, xoffset, width, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLsizei	width
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
	GLvoid * ptr = ELI(pixels, width, 1, format, type, gl_pixelbuffer_unpack);
	glTexSubImage1D(target, level, xoffset, width, format, type, ptr);
	}

#// 1.1
#//# glTexSubImage1D_p($target, $level, $xoffset, $width, $border, $format, $type, @pixels);
void
glTexSubImage1D_p(target, level, xoffset, width, format, type, ...)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLsizei	width
	GLenum	format
	GLenum	type
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(7)), items-7, width, 1, 1, format, type, 0);
	glTexSubImage1D(target, level, xoffset, width, format, type, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#// 1.1
#//# glTexSubImage2D_c($target, $level, $xoffset, $yoffset, $width, $height, $border, $format, $type, (CPTR)pixels);
void
glTexSubImage2D_c(target, level, xoffset, yoffset, width, height, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glTexSubImage2D(target, level, xoffset, yoffset,
		width, height, format, type, pixels);

#// 1.1
#//# glTexSubImage2D_s($target, $level, $xoffset, $yoffset, $width, $height, $border, $format, $type, (PACKED)pixels);
void
glTexSubImage2D_s(target, level, xoffset, yoffset, width, height, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
	GLvoid * ptr = ELI(pixels, width, height,
		format, type, gl_pixelbuffer_unpack);
	glTexSubImage2D(target, level, xoffset, yoffset,
		width, height, format, type, ptr);
	}

#// 1.1
#//# glTexSubImage2D_c($target, $level, $xoffset, $yoffset, $width, $height, $border, $format, $type, @pixels);
void
glTexSubImage2D_p(target, level, xoffset, yoffset, width, height, format, type, ...)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(8)), items-8, width, height, 1,
		format, type, 0);
	glTexSubImage2D(target, level, xoffset, yoffset,
		width, height, format, type, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#ifdef GL_VERSION_1_2

#// 1.2
#//# glTexSubImage3D_c($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $border, $format, $type, (CPTR)pixels);
void
glTexSubImage3D_c(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLenum	format
	GLenum	type
	void *	pixels
	INIT:
		loadProc(glTexSubImage3D,"glTexSubImage3D");
	CODE:
		glTexSubImage3D(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, pixels);

#// 1.2
#//# glTexSubImage3D_s($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $border, $format, $type, (PACKED)pixels);
void
glTexSubImage3D_s(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLenum	format
	GLenum	type
	SV *	pixels
	INIT:
		loadProc(glTexSubImage3D,"glTexSubImage3D");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_unpack);
		glTexSubImage3D(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, ptr);
	}

#// 1.1
#//# glTexSubImage3D_p($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $border, $format, $type, @pixels);
void
glTexSubImage3D_p(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, ...)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLenum	format
	GLenum	type
	INIT:
		loadProc(glTexSubImage3D,"glTexSubImage3D");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(10)), items-10, width, height,
			depth, format, type, 0);
		glTexSubImage3D(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#endif

#endif

#// 1.0
#//# glTranslated($x, $y, $z);
void
glTranslated(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z

#// 1.0
#//# glTranslatef($x, $y, $z);
void
glTranslatef(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z


#// 1.0
#//# glViewport($x, $y, $width, $height);
void
glViewport(x, y, width, height)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height

# Generated declarations

#//# glVertex2d($x, $y);
void
glVertex2d(x, y)
	GLdouble	x
	GLdouble	y

#//# glVertex2dv_c((CPTR)v);
void
glVertex2dv_c(v)
	void *	v
	CODE:
	glVertex2dv(v);

#//# glVertex2dv_s((PACKED)v);
void
glVertex2dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*2);
		glVertex2dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex2d
#//# glVertex2dv_p($x, $y);
void
glVertex2dv_p(x, y)
	GLdouble	x
	GLdouble	y
	CODE:
	{
		GLdouble param[2];
		param[0] = x;
		param[1] = y;
		glVertex2dv(param);
	}

#//# glVertex2f($x, $y);
void
glVertex2f(x, y)
	GLfloat	x
	GLfloat	y

#//# glVertex2f_s((PACKED)v);
void
glVertex2fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*2);
		glVertex2fv(v_s);
	}

#//# glVertex2f_s((CPTR)v);
void
glVertex2fv_c(v)
	void *	v
	CODE:
	glVertex2fv(v);

#//!!! Do we really need this?  It duplicates glVertex2f
#//# glVertex2fv_p($x, $y);
void
glVertex2fv_p(x, y)
	GLfloat	x
	GLfloat	y
	CODE:
	{
		GLfloat param[2];
		param[0] = x;
		param[1] = y;
		glVertex2fv(param);
	}

#//# glVertex2i($x, $y);
void
glVertex2i(x, y)
	GLint	x
	GLint	y

#//# glVertex2iv_c((CPTR)v);
void
glVertex2iv_c(v)
	void *	v
	CODE:
	glVertex2iv(v);

#//# glVertex2iv_s((PACKED)v);
void
glVertex2iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*2);
		glVertex2iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex2i
#//# glVertex2iv_p($x, $y);
void
glVertex2iv_p(x, y)
	GLint	x
	GLint	y
	CODE:
	{
		GLint param[2];
		param[0] = x;
		param[1] = y;
		glVertex2iv(param);
	}

#//# glVertex2s($x, $y);
void
glVertex2s(x, y)
	GLshort	x
	GLshort	y

#//# glVertex2sv_c((CPTR)v);
void
glVertex2sv_c(v)
	void *	v
	CODE:
	glVertex2sv(v);

#//# glVertex2sv_c((PACKED)v);
void
glVertex2sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*2);
		glVertex2sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex2s
#//# glVertex2sv_p($x, $y);
void
glVertex2sv_p(x, y)
	GLshort	x
	GLshort	y
	CODE:
	{
		GLshort param[2];
		param[0] = x;
		param[1] = y;
		glVertex2sv(param);
	}

#//# glTexCoord2d($s, $t);
void
glTexCoord2d(s, t)
	GLdouble	s
	GLdouble	t

#//# glTexCoord2dv_c((CPTR)v);
void
glTexCoord2dv_c(v)
	void *	v
	CODE:
	glTexCoord2dv(v);

#//# glTexCoord2dv_s((PACKED)v);
void
glTexCoord2dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*2);
		glTexCoord2dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord2d
#//# glTexCoord2dv_p($s, $t);
void
glTexCoord2dv_p(s, t)
	GLdouble	s
	GLdouble	t
	CODE:
	{
		GLdouble param[2];
		param[0] = s;
		param[1] = t;
		glTexCoord2dv(param);
	}

#//# glTexCoord2f($s, $t);
void
glTexCoord2f(s, t)
	GLfloat	s
	GLfloat	t

#//# glTexCoord2fv_c((CPTR)v);
void
glTexCoord2fv_c(v)
	void *	v
	CODE:
	glTexCoord2fv(v);

#//# glTexCoord2fv_s((PACKED)v);
void
glTexCoord2fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*2);
		glTexCoord2fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord2f
#//# glTexCoord2fv_p($s, $t);
void
glTexCoord2fv_p(s, t)
	GLfloat	s
	GLfloat	t
	CODE:
	{
		GLfloat param[2];
		param[0] = s;
		param[1] = t;
		glTexCoord2fv(param);
	}

#//# glTexCoord2i($s, $t);
void
glTexCoord2i(s, t)
	GLint	s
	GLint	t

#//# glTexCoord2iv_c((CPTR)v);
void
glTexCoord2iv_c(v)
	void *	v
	CODE:
	glTexCoord2iv(v);

#//# glTexCoord2iv_s((PACKED)v);
void
glTexCoord2iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*2);
		glTexCoord2iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord2i
#//# glTexCoord2iv_p($s, $t);
void
glTexCoord2iv_p(s, t)
	GLint	s
	GLint	t
	CODE:
	{
		GLint param[2];
		param[0] = s;
		param[1] = t;
		glTexCoord2iv(param);
	}

#//# glTexCoord2s($s, $t);
void
glTexCoord2s(s, t)
	GLshort	s
	GLshort	t

#//# glTexCoord2sv_c((CPTR)v);
void
glTexCoord2sv_c(v)
	void *	v
	CODE:
	glTexCoord2sv(v);

#//# glTexCoord2sv_c((PACKED)v);
void
glTexCoord2sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*2);
		glTexCoord2sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord2s
#//# glTexCoord2sv_p($s, $t);
void
glTexCoord2sv_p(s, t)
	GLshort	s
	GLshort	t
	CODE:
	{
		GLshort param[2];
		param[0] = s;
		param[1] = t;
		glTexCoord2sv(param);
	}

#//# glTexCoord3d($s, $t, $r);
void
glTexCoord3d(s, t, r)
	GLdouble	s
	GLdouble	t
	GLdouble	r

#//# glTexCoord3dv_c((CPTR)v);
void
glTexCoord3dv_c(v)
	void *	v
	CODE:
	glTexCoord3dv(v);

#//# glTexCoord3dv_s((PACKED)v);
void
glTexCoord3dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*3);
		glTexCoord3dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord3d
#//# glTexCoord3dv_p($s, $t, $r);
void
glTexCoord3dv_p(s, t, r)
	GLdouble	s
	GLdouble	t
	GLdouble	r
	CODE:
	{
		GLdouble param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glTexCoord3dv(param);
	}

#//# glTexCoord3f($s, $t, $r);
void
glTexCoord3f(s, t, r)
	GLfloat	s
	GLfloat	t
	GLfloat	r

#//# glTexCoord3fv_c((CPTR)v);
void
glTexCoord3fv_c(v)
	void *	v
	CODE:
	glTexCoord3fv(v);

#//# glTexCoord3fv_s((PACKED)v);
void
glTexCoord3fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*3);
		glTexCoord3fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord3f
#//# glTexCoord3fv_p($s, $t, $r);
void
glTexCoord3fv_p(s, t, r)
	GLfloat	s
	GLfloat	t
	GLfloat	r
	CODE:
	{
		GLfloat param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glTexCoord3fv(param);
	}

#//# glTexCoord3i($s, $t, $r);
void
glTexCoord3i(s, t, r)
	GLint	s
	GLint	t
	GLint	r

#//# glTexCoord3iv_c((CPTR)v);
void
glTexCoord3iv_c(v)
	void *	v
	CODE:
	glTexCoord3iv(v);

#//# glTexCoord3iv_s((PACKED)v);
void
glTexCoord3iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*3);
		glTexCoord3iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord3i
#//# glTexCoord3iv_p($s, $t, $r);
void
glTexCoord3iv_p(s, t, r)
	GLint	s
	GLint	t
	GLint	r
	CODE:
	{
		GLint param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glTexCoord3iv(param);
	}

#//# glTexCoord3s($s, $t, $r);
void
glTexCoord3s(s, t, r)
	GLshort	s
	GLshort	t
	GLshort	r

#//# glTexCoord3sv_s((PACKED)v);
void
glTexCoord3sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*3);
		glTexCoord3sv(v_s);
	}

#//# glTexCoord3sv_c((CPTR)v);
void
glTexCoord3sv_c(v)
	void *	v
	CODE:
	glTexCoord3sv(v);

#//!!! Do we really need this?  It duplicates glTexCoord3s
#//# glTexCoord3sv_p($s, $t, $r);
void
glTexCoord3sv_p(s, t, r)
	GLshort	s
	GLshort	t
	GLshort	r
	CODE:
	{
		GLshort param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glTexCoord3sv(param);
	}

#//# glTexCoord4d($s, $t, $r, $q);
void
glTexCoord4d(s, t, r, q)
	GLdouble	s
	GLdouble	t
	GLdouble	r
	GLdouble	q

#//# glTexCoord4dv_c((CPTR)v);
void
glTexCoord4dv_c(v)
	void *	v
	CODE:
	glTexCoord4dv(v);

#//# glTexCoord4dv_s((PACKED)v);
void
glTexCoord4dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glTexCoord4dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord4d
#//# glTexCoord4dv_p($s, $t, $r, $q);
void
glTexCoord4dv_p(s, t, r, q)
	GLdouble	s
	GLdouble	t
	GLdouble	r
	GLdouble	q
	CODE:
	{
		GLdouble param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glTexCoord4dv(param);
	}

#//# glTexCoord4f($s, $t, $r, $q);
void
glTexCoord4f(s, t, r, q)
	GLfloat	s
	GLfloat	t
	GLfloat	r
	GLfloat	q

#//# glTexCoord4fv_c((CPTR)v);
void
glTexCoord4fv_c(v)
	void *	v
	CODE:
	glTexCoord4fv(v);

#//# glTexCoord4fv_s((PACKED)v);
void
glTexCoord4fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glTexCoord4fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord4f
#//# glTexCoord4fv_p($s, $t, $r, $q);
void
glTexCoord4fv_p(s, t, r, q)
	GLfloat	s
	GLfloat	t
	GLfloat	r
	GLfloat	q
	CODE:
	{
		GLfloat param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glTexCoord4fv(param);
	}

#//# glTexCoord4i($s, $t, $r, $q);
void
glTexCoord4i(s, t, r, q)
	GLint	s
	GLint	t
	GLint	r
	GLint	q

#//# glTexCoord4iv_c((CPTR)v);
void
glTexCoord4iv_c(v)
	void *	v
	CODE:
	glTexCoord4iv(v);

#//# glTexCoord4iv_s((PACKED)v);
void
glTexCoord4iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glTexCoord4iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord4i
#//# glTexCoord4iv_p($s, $t, $r, $q);
void
glTexCoord4iv_p(s, t, r, q)
	GLint	s
	GLint	t
	GLint	r
	GLint	q
	CODE:
	{
		GLint param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glTexCoord4iv(param);
	}

#//# glTexCoord4s($s, $t, $r, $q);
void
glTexCoord4s(s, t, r, q)
	GLshort	s
	GLshort	t
	GLshort	r
	GLshort	q

#//# glTexCoord4sv_c((CPTR)v);
void
glTexCoord4sv_c(v)
	void *	v
	CODE:
	glTexCoord4sv(v);

#//# glTexCoord4sv_s((PACKED)v);
void
glTexCoord4sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glTexCoord4sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord4s
#//# glTexCoord4sv_p($s, $t, $r, $q);
void
glTexCoord4sv_p(s, t, r, q)
	GLshort	s
	GLshort	t
	GLshort	r
	GLshort	q
	CODE:
	{
		GLshort param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glTexCoord4sv(param);
	}

#//# glRasterPos2d(x, y);
void
glRasterPos2d(x, y)
	GLdouble	x
	GLdouble	y

#//# glRasterPos2dv_c((CPTR)v);
void
glRasterPos2dv_c(v)
	void *	v
	CODE:
	glRasterPos2dv(v);

#//# glRasterPos2dv_s((PACKED)v);
void
glRasterPos2dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*2);
		glRasterPos2dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos2d
#//# glRasterPos2dv_p($x, $y);
void
glRasterPos2dv_p(x, y)
	GLdouble	x
	GLdouble	y
	CODE:
	{
		GLdouble param[2];
		param[0] = x;
		param[1] = y;
		glRasterPos2dv(param);
	}

#//# glRasterPos2f($x, $y);
void
glRasterPos2f(x, y)
	GLfloat	x
	GLfloat	y

#//# glRasterPos2fv_c((CPTR)v);
void
glRasterPos2fv_c(v)
	void *	v
	CODE:
	glRasterPos2fv(v);

#//# glRasterPos2fv_s((PACKED)v);
void
glRasterPos2fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*2);
		glRasterPos2fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos2f
#//# glRasterPos2fv_p($x, $y);
void
glRasterPos2fv_p(x, y)
	GLfloat	x
	GLfloat	y
	CODE:
	{
		GLfloat param[2];
		param[0] = x;
		param[1] = y;
		glRasterPos2fv(param);
	}

#//# glRasterPos2i($x, $y);
void
glRasterPos2i(x, y)
	GLint	x
	GLint	y

#//# glRasterPos2iv_c((CPTR)v);
void
glRasterPos2iv_c(v)
	void *	v
	CODE:
	glRasterPos2iv(v);

#//# glRasterPos2iv_s((PACKED)v);
void
glRasterPos2iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*2);
		glRasterPos2iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos2i
#//# glRasterPos2iv_p($x, $y);
void
glRasterPos2iv_p(x, y)
	GLint	x
	GLint	y
	CODE:
	{
		GLint param[2];
		param[0] = x;
		param[1] = y;
		glRasterPos2iv(param);
	}

#//# glRasterPos2s($x, $y);
void
glRasterPos2s(x, y)
	GLshort	x
	GLshort	y

#//# glRasterPos2sv_c((CPTR)v);
void
glRasterPos2sv_c(v)
	void *	v
	CODE:
	glRasterPos2sv(v);

#//# glRasterPos2sv_s((PACKED)v);
void
glRasterPos2sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*2);
		glRasterPos2sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos2s
#//# glRasterPos2sv_p($x, $y);
void
glRasterPos2sv_p(x, y)
	GLshort	x
	GLshort	y
	CODE:
	{
		GLshort param[2];
		param[0] = x;
		param[1] = y;
		glRasterPos2sv(param);
	}

#//# glRasterPos3d($x, $y, $z);
void
glRasterPos3d(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z

#//# glRasterPos3dv_c((CPTR)v);
void
glRasterPos3dv_c(v)
	void *	v
	CODE:
	glRasterPos3dv(v);

#//# glRasterPos3dv_s((PACKED)v);
void
glRasterPos3dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*3);
		glRasterPos3dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos3d
#//# glRasterPos3dv_p($x, $y, $z);
void
glRasterPos3dv_p(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z
	CODE:
	{
		GLdouble param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glRasterPos3dv(param);
	}

#//# glRasterPos3f($x, $y, $z);
void
glRasterPos3f(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z

#//# glRasterPos3fv_c((CPTR)v);
void
glRasterPos3fv_c(v)
	void *	v
	CODE:
	glRasterPos3fv(v);

#//# glRasterPos3fv_s((PACKED)v);
void
glRasterPos3fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*3);
		glRasterPos3fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos3f
#//# glRasterPos3fv_p($x, $y, $z);
void
glRasterPos3fv_p(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z
	CODE:
	{
		GLfloat param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glRasterPos3fv(param);
	}

#//# glRasterPos3i($x, $y, $z);
void
glRasterPos3i(x, y, z)
	GLint	x
	GLint	y
	GLint	z

#//# glRasterPos3iv_c((CPTR)v);
void
glRasterPos3iv_c(v)
	void *	v
	CODE:
	glRasterPos3iv(v);

#//# glRasterPos3iv_s((PACKED)v);
void
glRasterPos3iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*3);
		glRasterPos3iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos3i
#//# glRasterPos3iv_p($x, $y, $z);
void
glRasterPos3iv_p(x, y, z)
	GLint	x
	GLint	y
	GLint	z
	CODE:
	{
		GLint param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glRasterPos3iv(param);
	}

#//# glRasterPos3s($x, $y, $z);
void
glRasterPos3s(x, y, z)
	GLshort	x
	GLshort	y
	GLshort	z

#//# glRasterPos3sv_c((CPTR)v);
void
glRasterPos3sv_c(v)
	void *	v
	CODE:
	glRasterPos3sv(v);

#//# glRasterPos3sv_s((PACKED)v);
void
glRasterPos3sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*3);
		glRasterPos3sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos3s
#//# glRasterPos3sv_p($x, $y, $z);
void
glRasterPos3sv_p(x, y, z)
	GLshort	x
	GLshort	y
	GLshort	z
	CODE:
	{
		GLshort param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glRasterPos3sv(param);
	}

#//# glRasterPos4d($x, $y, $z, $w);
void
glRasterPos4d(x, y, z, w)
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w

#//# glRasterPos4dv_c((CPTR)v);
void
glRasterPos4dv_c(v)
	void *	v
	CODE:
	glRasterPos4dv(v);

#//# glRasterPos4dv_s((PACKED)v);
void
glRasterPos4dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glRasterPos4dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos4d
#//# glRasterPos4dv_p($x, $y, $z, $w);
void
glRasterPos4dv_p(x, y, z, w)
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
		glRasterPos4dv(param);
	}

#//# glRasterPos4f($x, $y, $z, $w);
void
glRasterPos4f(x, y, z, w)
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w

#//# glRasterPos4fv_c((CPTR)v);
void
glRasterPos4fv_c(v)
	void *	v
	CODE:
	glRasterPos4fv(v);

#//# glRasterPos4fv_s((PACKED)v);
void
glRasterPos4fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glRasterPos4fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos4f
#//# glRasterPos4fv_p($x, $y, $z, $w);
void
glRasterPos4fv_p(x, y, z, w)
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
		glRasterPos4fv(param);
	}

#//# glRasterPos4i($x, $y, $z, $w);
void
glRasterPos4i(x, y, z, w)
	GLint	x
	GLint	y
	GLint	z
	GLint	w

#//# glRasterPos4iv_c((CPTR)v);
void
glRasterPos4iv_c(v)
	void *	v
	CODE:
	glRasterPos4iv(v);

#//# glRasterPos4iv_s((PACKED)v);
void
glRasterPos4iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glRasterPos4iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos4i
#//# glRasterPos4iv_p($x, $y, $z, $w);
void
glRasterPos4iv_p(x, y, z, w)
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
		glRasterPos4iv(param);
	}

#//# glRasterPos4s($x, $y, $z, $w);
void
glRasterPos4s(x, y, z, w)
	GLshort	x
	GLshort	y
	GLshort	z
	GLshort	w

#//# glRasterPos4sv_c((CPTR)v);
void
glRasterPos4sv_c(v)
	void *	v
	CODE:
	glRasterPos4sv(v);

#//# glRasterPos4sv_s((PACKED)v);
void
glRasterPos4sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glRasterPos4sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos4s
#//# glRasterPos4sv_p($x, $y, $z, $w);
void
glRasterPos4sv_p(x, y, z, w)
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
		glRasterPos4sv(param);
	}

#ifdef GL_VERSION_1_4

#//# glBlendColor($red, $green, $blue, $alpha);
void
glBlendColor(red, green, blue, alpha)
	GLclampf	red
	GLclampf	green
	GLclampf	blue
	GLclampf	alpha
	INIT:
		loadProc(glBlendColor,"glBlendColor");
	CODE:
		glBlendColor(red, green, blue, alpha);

#//# glBlendEquation($mode);
void
glBlendEquation(mode)
	GLenum	mode
	INIT:
		loadProc(glBlendEquation,"glBlendEquation");
	CODE:
		glBlendEquation(mode);

#endif

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

#if defined(GL_VERSION_1_1) || defined(GL_EXT_vertex_array)

#//# glVertexPointerEXT_c($size, $type, $stride, $count, (CPTR)pointer);
void
glVertexPointerEXT_c(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	void *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glVertexPointerEXT,"glVertexPointerEXT");
#endif
	CODE:
#ifdef GL_VERSION_1_1
		glVertexPointer(size, type, stride, pointer);
#else // GL_EXT_vertex_array
		glVertexPointerEXT(size, type, stride, count, pointer);
#endif

#//# glVertexPointerEXT_s($size, $type, $stride, $count, (PACKED)pointer);
void
glVertexPointerEXT_s(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	SV *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glVertexPointerEXT,"glVertexPointerEXT");
#endif
	CODE:
	{
		int width = stride ? stride : (sizeof(type)*size);
		void * pointer_s = EL(pointer, width*count);
#ifdef GL_VERSION_1_1
		glVertexPointer(size, type, stride, pointer_s);
#else // GL_EXT_vertex_array
		glVertexPointerEXT(size, type, stride, count, pointer_s);
#endif
	}

#//# glVertexPointerEXT_p($size, (OGA)pointer);
void
glVertexPointerEXT_p(size, oga)
	GLint	size
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glVertexPointerEXT,"glVertexPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glVertexPointer(size, oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glVertexPointerEXT(size, oga->types[0], 0, oga->item_count/size, data);
#endif
	}

#//# glVertexPointer_p($size, (OGA)pointer);
void
glVertexPointer_p(size, oga)
	GLint	size
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glVertexPointerEXT,"glVertexPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glVertexPointer(size, oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glVertexPointerEXT(size, oga->types[0], 0, oga->item_count/size, data);
#endif
	}

#//# glNormalPointerEXT_c($size, $type, $stride, $count, (CPTR)pointer);
void
glNormalPointerEXT_c(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	void *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glNormalPointerEXT,"glNormalPointerEXT");
#endif
	CODE:
#ifdef GL_VERSION_1_1
		glNormalPointer(type, stride, pointer);
#else // GL_EXT_vertex_array
		glNormalPointerEXT(type, stride, count, pointer);
#endif

#//# glNormalPointerEXT_s($size, $type, $stride, $count, (PACKED)pointer);
void
glNormalPointerEXT_s(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	SV *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glNormalPointerEXT,"glNormalPointerEXT");
#endif
	CODE:
	{
		int width = stride ? stride : (sizeof(type)*size);
		void * pointer_s = EL(pointer, width*count);
#ifdef GL_VERSION_1_1
		glNormalPointer(type, stride, pointer_s);
#else // GL_EXT_vertex_array
		glNormalPointerEXT(type, stride, count, pointer_s);
#endif
	}

#//# glNormalPointerEXT_p((OGA)pointer);
void
glNormalPointerEXT_p(oga)
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glNormalPointerEXT,"glNormalPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glNormalPointer(oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glNormalPointerEXT(oga->types[0], 0, oga->item_count/3, data);
#endif
	}

#//# glNormalPointer_p((OGA)pointer);
void
glNormalPointer_p(oga)
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glNormalPointerEXT,"glNormalPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glNormalPointer(oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glNormalPointerEXT(oga->types[0], 0, oga->item_count/3, data);
#endif
	}

#//# glColorPointerEXT_c($size, $type, $stride, $count, (CPTR)pointer);
void
glColorPointerEXT_c(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	void *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glColorPointerEXT,"glColorPointerEXT");
#endif
	CODE:
#ifdef GL_VERSION_1_1
		glColorPointer(size, type, stride, pointer);
#else // GL_EXT_vertex_array
		glColorPointerEXT(size, type, stride, count, pointer);
#endif

#//# glColorPointerEXT_s($size, $type, $stride, $count, (PACKED)pointer);
void
glColorPointerEXT_s(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	SV *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glColorPointerEXT,"glColorPointerEXT");
#endif
	CODE:
	{
		int width = stride ? stride : (sizeof(type)*size);
		void * pointer_s = EL(pointer, width*count);
#ifdef GL_VERSION_1_1
		glColorPointer(size, type, stride, pointer_s);
#else // GL_EXT_vertex_array
		glColorPointerEXT(size, type, stride, count, pointer_s);
#endif
	}

#//# glColorPointerEXT_p($size, (OGA)pointer);
void
glColorPointerEXT_p(size, oga)
	GLint	size
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glColorPointerEXT,"glColorPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glColorPointer(size, oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glColorPointerEXT(size, oga->types[0], 0, oga->item_count/size, data);
#endif
	}

#//# glColorPointer_p($size, (OGA)pointer);
void
glColorPointer_p(size, oga)
	GLint	size
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glColorPointerEXT,"glColorPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glColorPointer(size, oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glColorPointerEXT(size, oga->types[0], 0, oga->item_count/size, data);
#endif
	}

#//# glIndexPointerEXT_c($size, $type, $stride, $count, (CPTR)pointer);
void
glIndexPointerEXT_c(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	void *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glIndexPointerEXT,"glIndexPointerEXT");
#endif
	CODE:
#ifdef GL_VERSION_1_1
		glIndexPointer(type, stride, pointer);
#else // GL_EXT_vertex_array
		glIndexPointerEXT(type, stride, count, pointer);
#endif

#//# glIndexPointerEXT_s($size, $type, $stride, $count, (PACKED)pointer);
void
glIndexPointerEXT_s(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	SV *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glIndexPointerEXT,"glIndexPointerEXT");
#endif
	CODE:
	{
		int width = stride ? stride : (sizeof(type)*size);
		void * pointer_s = EL(pointer, width*count);
#ifdef GL_VERSION_1_1
		glIndexPointer(type, stride, pointer_s);
#else // GL_EXT_vertex_array
		glIndexPointerEXT(type, stride, count, pointer_s);
#endif
	}

#//# glIndexPointerEXT_p((OGA)pointer);
void
glIndexPointerEXT_p(oga)
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glIndexPointerEXT,"glIndexPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glIndexPointer(oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glIndexPointerEXT(oga->types[0], 0, oga->item_count, data);
#endif
	}

#//# glIndexPointer_p((OGA)pointer);
void
glIndexPointer_p(oga)
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glIndexPointerEXT,"glIndexPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glIndexPointer(oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glIndexPointerEXT(oga->types[0], 0, oga->item_count, data);
#endif
	}

#//# glTexCoordPointerEXT_c($size, $type, $stride, $count, (CPTR)pointer);
void
glTexCoordPointerEXT_c(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	void *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glTexCoordPointerEXT");
#endif
	CODE:
#ifdef GL_VERSION_1_1
		glTexCoordPointer(size, type, stride, pointer);
#else // GL_EXT_vertex_array
		glTexCoordPointerEXT(size, type, stride, count, pointer);
#endif

#//# glTexCoordPointerEXT_s($size, $type, $stride, $count, (PACKED)pointer);
void
glTexCoordPointerEXT_s(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	SV *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glTexCoordPointerEXT");
#endif
	CODE:
	{
		int width = stride ? stride : (sizeof(type)*size);
		void * pointer_s = EL(pointer, width*count);
#ifdef GL_VERSION_1_1
		glTexCoordPointer(size, type, stride, pointer_s);
#else // GL_EXT_vertex_array
		glTexCoordPointerEXT(size, type, stride, count, pointer_s);
#endif
	}

#//# glTexCoordPointerEXT_p($size, (OGA)pointer);
void
glTexCoordPointerEXT_p(size, oga)
	GLint	size
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glTexCoordPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glTexCoordPointer(size, oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glTexCoordPointerEXT(size, oga->types[0], 0, oga->item_count/size, data);
#endif
	}

#//# glTexCoordPointer_p($size, (OGA)pointer);
void
glTexCoordPointer_p(size, oga)
	GLint	size
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glTexCoordPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glTexCoordPointer(size, oga->types[0], 0, data);
#else // GL_EXT_vertex_array
		glTexCoordPointerEXT(size, oga->types[0], 0, oga->item_count/size, data);
#endif
	}

#//# glEdgeFlagPointerEXT_c($size, $type, $stride, $count, (CPTR)pointer);
void
glEdgeFlagPointerEXT_c(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	void *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glEdgeFlagPointerEXT");
#endif
	CODE:
#ifdef GL_VERSION_1_1
		glEdgeFlagPointer(stride, pointer);
#else // GL_EXT_vertex_array
		glEdgeFlagPointerEXT(stride, count, pointer);
#endif

#//# glEdgeFlagPointerEXT_s($size, $type, $stride, $count, (PACKED)pointer);
void
glEdgeFlagPointerEXT_s(size, type, stride, count, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	GLsizei	count
	SV *	pointer
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glEdgeFlagPointerEXT");
#endif
	CODE:
	{
		int width = stride ? stride : (sizeof(type)*size);
		void * pointer_s = EL(pointer, width*count);
#ifdef GL_VERSION_1_1
		glEdgeFlagPointer(stride, pointer_s);
#else // GL_EXT_vertex_array
		glEdgeFlagPointerEXT(stride, count, pointer_s);
#endif
	}

#//# glEdgeFlagPointerEXT_p((OGA)pointer);
void
glEdgeFlagPointerEXT_p(oga)
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glEdgeFlagPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glEdgeFlagPointer(0, data);
#else // GL_EXT_vertex_array
		glEdgeFlagPointerEXT(0, oga->item_count, data);
#endif
	}

#//# glEdgeFlagPointer_p((OGA)pointer);
void
glEdgeFlagPointer_p(oga)
	OpenGL::Array oga
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glEdgeFlagPointerEXT");
#endif
	CODE:
	{
		GLvoid * data = oga->data;
#ifdef GL_VERSION_2_0
		glBindBufferARB(GL_ARRAY_BUFFER, oga->bind);
		if (oga->bind) data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			if (oga->bind) data = NULL;
		}
#endif
#ifdef GL_VERSION_1_1
		glEdgeFlagPointer(0, data);
#else // GL_EXT_vertex_array
		glEdgeFlagPointerEXT(0, oga->item_count, data);
#endif
	}

#endif // GL_EXT_vertex_array || GL_VERSION_1_1


#ifdef GL_VERSION_1_1

#// 1.1
#//# glVertexPointer_c($size, $type, $stride, (CPTR)pointer);
void
glVertexPointer_c(size, type, stride, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	void *	pointer
	CODE:
		glVertexPointer(size, type, stride, pointer);

#//# glVertexPointer_s($size, $type, $stride, (PACKED)pointer);
void
glVertexPointer_s(size, type, stride, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	SV *	pointer
	CODE:
	{
		int width = stride ? stride : (sizeof(type)*size);
		void * pointer_s = NULL;
		if ( pointer ) {
			pointer_s = EL(pointer, width);
		}
		glVertexPointer(size, type, stride, pointer_s);
	}

#//# glNormalPointer_c($type, $stride, (CPTR)pointer);
void
glNormalPointer_c(type, stride, pointer)
	GLenum	type
	GLsizei	stride
	void *	pointer
	CODE:
		glNormalPointer(type, stride, pointer);

#//# glNormalPointer_s($type, $stride, (PACKED)pointer);
void
glNormalPointer_s(type, stride, pointer)
	GLenum	type
	GLsizei	stride
	SV *	pointer
	CODE:
	{
		int width = stride ? stride : (gl_type_size(type)*3);
		void * pointer_s = NULL;
		if ( pointer ) {
			pointer_s = EL(pointer, width);
		}
		glNormalPointer(type, stride, pointer_s);
	}

#//# glColorPointer_c($size, $type, $stride, (CPTR)pointer);
void
glColorPointer_c(size, type, stride, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	void *	pointer
	CODE:
		glColorPointer(size, type, stride, pointer);

#//# glColorPointer_s($size, $type, $stride, (PACKED)pointer);
void
glColorPointer_s(size, type, stride, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	SV *	pointer
	CODE:
	{
		int width = stride ? stride : (sizeof(type)*size);
		void * pointer_s = NULL;
		if ( pointer ) {
			pointer_s = EL(pointer, width);
		}
		glColorPointer(size, type, stride, pointer_s);
	}

#//# glIndexPointer_c($type, $stride, (CPTR)pointer);
void
glIndexPointer_c(type, stride, pointer)
	GLenum	type
	GLsizei	stride
	void *	pointer
	CODE:
		glIndexPointer(type, stride, pointer);

#//# glIndexPointer_s($type, $stride, (PACKED)pointer);
void
glIndexPointer_s(type, stride, pointer)
	GLenum	type
	GLsizei	stride
	SV *	pointer
	CODE:
	{
		int width = stride ? stride : gl_type_size(type);
		void * pointer_s = NULL;
		if ( pointer ) {
			pointer_s = EL(pointer, width);
		}
		glIndexPointer(type, stride, pointer_s);
	}

#//# glTexCoordPointer_c($size, $type, $stride, (CPTR)pointer);
void
glTexCoordPointer_c(size, type, stride, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	void *	pointer
	CODE:
		glTexCoordPointer(size, type, stride, pointer);

#//# glTexCoordPointer_s($size, $type, $stride, (PACKED)pointer);
void
glTexCoordPointer_s(size, type, stride, pointer)
	GLint	size
	GLenum	type
	GLsizei	stride
	SV *	pointer
	CODE:
	{
		int width = stride ? stride : (sizeof(type)*size);
		void * pointer_s = NULL;
		if ( pointer ) {
			pointer_s = EL(pointer, width);
		}
		glTexCoordPointer(size, type, stride, pointer_s);
	}

#//# glEdgeFlagPointer_c($stride, (CPTR)pointer);
void
glEdgeFlagPointer_c(stride, pointer)
	GLsizei	stride
	void *	pointer
	CODE:
		glEdgeFlagPointer(stride, pointer);

#//# glEdgeFlagPointer_s($stride, (PACKED)pointer);
void
glEdgeFlagPointer_s(stride, pointer)
	GLsizei	stride
	SV *	pointer
	CODE:
	{
		int width = stride ? stride : sizeof(GLboolean);
		void * pointer_s = NULL;
		if ( pointer ) {
			pointer_s = EL(pointer, width);
		}
		glEdgeFlagPointer(stride, pointer_s);
	}

#endif // GL_VERSION_1_1

#ifdef GL_VERSION_1_4

#//# glBindBuffer($target,$buffer);
void
glBindBuffer(target,buffer)
	GLenum target
	GLuint buffer
	CODE:
	{
		glBindBuffer(target,buffer);
	}

#//# glDeleteBuffers_c($n,(CPTR)buffers);
void
glDeleteBuffers_c(n,buffers)
	GLsizei	n
	void *	buffers
	CODE:
	{
		glDeleteBuffers(n,buffers);
	}

#//# glDeleteBuffers_s($n,(PACKED)buffers);
void
glDeleteBuffers_s(n,buffers)
	GLsizei n
	SV *	buffers
	CODE:
	{
		void * buffers_s = EL(buffers, sizeof(GLuint)*n);
		glDeleteBuffers(n,buffers_s);
	}

#//# glDeleteBuffers_p(@buffers);
void
glDeleteBuffers_p(...)
	CODE:
	{
		if (items) {
			GLuint * list = malloc(sizeof(GLuint) * items);
			int i;

			for (i=0;i<items;i++)
				list[i] = SvIV(ST(i));

			glDeleteBuffers(items, list);
			free(list);
		}
	}

#//# glGenBuffers_c($n,(CPTR)buffers);
void
glGenBuffers_c(n,buffers)
	GLsizei n
	void *	buffers
	CODE:
	{
		glGenBuffers(n, buffers);
	}

#//# glGenBuffers_s($n,(PACKED)buffers);
void
glGenBuffers_s(n,buffers)
	GLsizei n
	SV *	buffers
	CODE:
	{
		void * buffers_s = EL(buffers, sizeof(GLuint)*n);
		glGenBuffers(n, buffers_s);
	}

#//# @buffers = glGenBuffers_p($n);
void
glGenBuffers_p(n)
	GLsizei n
	PPCODE:
	if (n)
	{
		GLuint * buffers = malloc(sizeof(GLuint) * n);
		int i;

		glGenBuffers(n, buffers);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(buffers[i])));

		free(buffers);
	}

#//# glIsBuffer($buffer);
GLboolean
glIsBuffer(buffer)
	GLuint buffer
	CODE:
	{
		RETVAL = glIsBuffer(buffer);
	}
	OUTPUT:
		RETVAL

#//# glBufferData_c($target,$size,(CPTR)data,$usage);
void
glBufferData_c(target,size,data,usage)
	GLenum	target
	GLsizei	size
	void *	data
	GLenum	usage
	CODE:
	{
		glBufferData(target,size,data,usage);
	}

#//# glBufferData_s($target,$size,(PACKED)data,$usage);
void
glBufferData_s(target,size,data,usage)
	GLenum	target
	GLsizei	size
	SV *	data
	GLenum	usage
	CODE:
	{
		void * data_s = EL(data, size);
		glBufferData(target,size,data_s,usage);
	}

#//# glBufferData_p($target,(OGA)data,$usage);
void
glBufferData_p(target,oga,usage)
	GLenum target
	OpenGL::Array oga
	GLenum usage
	CODE:
	{
		glBufferData(target,oga->data_length,oga->data,usage);
	}

#//# glBufferSubData_c($target,$offset,$size,(CPTR)data);
void
glBufferSubData_c(target,offset,size,data)
	GLenum	target
	GLint	offset
	GLsizei	size
	void *	data
	CODE:
	{
		glBufferSubData(target,offset,size,data);
	}

#//# glBufferSubData_s($target,$offset,$size,(PACKED)data);
void
glBufferSubData_s(target,offset,size,data)
	GLenum	target
	GLint	offset
	GLsizei	size
	SV *	data
	CODE:
	{
		void * data_s = EL(data, size);
		glBufferSubData(target,offset,size,data);
	}

#//# glBufferSubData_p($target,$offset,(OGA)data);
void
glBufferSubData_p(target,offset,oga)
	GLenum	target
	GLint	offset
	OpenGL::Array oga
	CODE:
	{
		glBufferSubData(target,offset*oga->total_types_width,oga->data_length,oga->data);
	}

#//# glGetBufferSubData_c($target,$offset,$size,(CPTR)data)
void
glGetBufferSubData_c(target,offset,size,data)
	GLenum	target
	GLint	offset
	GLsizei	size
	void *	data
	CODE:
		glGetBufferSubData(target,offset,size,data);

#//# glGetBufferSubData_s($target,$offset,$size,(PACKED)data)
void
glGetBufferSubData_s(target,offset,size,data)
	GLenum	target
	GLint	offset
	GLsizei	size
	SV *	data
	CODE:
	{
		GLubyte * data_s = EL(data,size);
		glGetBufferSubData(target,offset,size,data_s);
	}

#//# $oga = glGetBufferSubData_p($target,$offset,$count,@types);
#//- If no types are provided, GLubyte is assumed
OpenGL::Array
glGetBufferSubData_p(target,offset,count,...)
	GLenum	target
	GLint	offset
	GLsizei	count
	CODE:
	{
		oga_struct * oga = malloc(sizeof(oga_struct));
		GLint size;

		oga->item_count = count;
		oga->type_count = (items - 3);

				if (oga->type_count)
		{
			int i,j;

			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
			for(i=0,j=0;i<oga->type_count;i++) {
				oga->types[i] = SvIV(ST(i+3));
				oga->type_offset[i] = j;
				j += gl_type_size(oga->types[i]);
			}
			oga->total_types_width = j;
		}
		else
		{
			oga->type_count = 1;
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);

			oga->types[0] = GL_UNSIGNED_BYTE;
			oga->type_offset[0] = 0;
			oga->total_types_width = gl_type_size(oga->types[0]);
		}
		if (!oga->total_types_width) croak("Unable to determine type sizes\n");

		glGetBufferParameteriv(target,GL_BUFFER_SIZE,&size);
		size /= oga->total_types_width;
		if (offset > size) croak("Offset is greater than elements in buffer: %d\n",size);

		if ((offset+count) > size) count = size - offset;

		oga->data_length = oga->total_types_width * count;
		oga->data = malloc(oga->data_length);

		glGetBufferSubData(target,offset*oga->total_types_width,
			oga->data_length,oga->data);

		oga->free_data = 1;

		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#//# (CPTR)buffer = glMapBuffer_c($target,$access);
void *
glMapBuffer_c(target,access)
	GLenum	target
	GLenum	access
	CODE:
		RETVAL = glMapBuffer(target,access);
	OUTPUT:
		RETVAL

#define FIXME /* !!! Need to refactor with glGetBufferPointerv_p */

#//# $oga = glMapBuffer_p($target,$access,@types);
#//- If no types are provided, GLubyte is assumed
OpenGL::Array
glMapBuffer_p(target,access,...)
	GLenum	target
	GLenum	access
	CODE:
	{
		GLsizeiptr size;
		oga_struct * oga;
		int i,j;

		void * buffer =	glMapBuffer(target,access);
		if (!buffer) croak("Unable to map buffer\n");

		glGetBufferParameteriv(target,GL_BUFFER_SIZE,(GLint*)&size);
		if (!size) croak("Buffer has no size\n");

		oga = malloc(sizeof(oga_struct));

		oga->type_count = (items - 2);

				if (oga->type_count)
		{
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
			for(i=0,j=0;i<oga->type_count;i++) {
				oga->types[i] = SvIV(ST(i+2));
				oga->type_offset[i] = j;
				j += gl_type_size(oga->types[i]);
			}
			oga->total_types_width = j;
		}
		else
		{
			oga->type_count = 1;
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);

			oga->types[0] = GL_UNSIGNED_BYTE;
			oga->type_offset[0] = 0;
			oga->total_types_width = gl_type_size(oga->types[0]);
		}

		if (!oga->total_types_width) croak("Unable to determine type sizes\n");
		oga->item_count = size / oga->total_types_width;

		oga->data_length = oga->total_types_width * oga->item_count;

		oga->data = buffer;

		oga->free_data = 0;

		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#//# glUnmapBuffer($target);
GLboolean
glUnmapBuffer(target)
	GLenum	target
	CODE:
		RETVAL = glUnmapBuffer(target);
	OUTPUT:
		RETVAL

#//# glGetBufferParameteriv_c($target,$pname,(CPTR)params);
void
glGetBufferParameteriv_c(target,pname,params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
		glGetBufferParameteriv(target,pname,params);

#//# glGetBufferParameteriv_s($target,$pname,(PACKED)params);
void
glGetBufferParameteriv_s(target,pname,params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint)*1);
		glGetBufferParameteriv(target,pname,params_s);
	}

#//# @params = glGetBufferParameteriv_p($target,$pname);
void
glGetBufferParameteriv_p(target,pname)
	GLenum	target
	GLenum	pname
	PPCODE:
	{
		GLint	ret;
		glGetBufferParameteriv(target,pname,&ret);
		PUSHs(sv_2mortal(newSViv(ret)));
	}

#//# glGetBufferPointerv_c($target,$pname,(CPTR)params);
void
glGetBufferPointerv_c(target,pname,params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
		glGetBufferPointerv(target,pname,&params);

#//# glGetBufferPointerv_s($target,$pname,(PACKED)params);
void
glGetBufferPointerv_s(target,pname,params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
		void ** params_s = EL(params, sizeof(void*));
		glGetBufferPointerv(target,pname,params_s);
	}

#//# $oga = glGetBufferPointerv_p($target,$pname,@types);
#//- If no types are provided, GLubyte is assumed
OpenGL::Array
glGetBufferPointerv_p(target,pname,...)
	GLenum	target
	GLenum	pname
	CODE:
	{
		GLsizeiptr size;
		oga_struct * oga;
		void * buffer;
		int i,j;

		glGetBufferPointerv(target,pname,&buffer);
		if (!buffer) croak("Buffer is not mapped\n");

		glGetBufferParameteriv(target,GL_BUFFER_SIZE,(GLint*)&size);
		if (!size) croak("Buffer has no size\n");

		oga = malloc(sizeof(oga_struct));

		oga->type_count = (items - 2);

				if (oga->type_count)
		{
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
			for(i=0,j=0;i<oga->type_count;i++) {
				oga->types[i] = SvIV(ST(i+2));
				oga->type_offset[i] = j;
				j += gl_type_size(oga->types[i]);
			}
			oga->total_types_width = j;
		}
		else
		{
			oga->type_count = 1;
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);

			oga->types[0] = GL_UNSIGNED_BYTE;
			oga->type_offset[0] = 0;
			oga->total_types_width = gl_type_size(oga->types[0]);
		}

		if (!oga->total_types_width) croak("Unable to determine type sizes\n");
		oga->item_count = size / oga->total_types_width;

		oga->data_length = oga->total_types_width * oga->item_count;

		oga->data = buffer;

		oga->free_data = 0;

		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#endif // GL_VERSION_1_4

#if defined(GL_VERSION_1_2_1) || defined(GL_VERSION_1_3)

#//# glActiveTexture($texture);
void
glActiveTexture(texture)
	GLenum texture
	CODE:
		glActiveTexture(texture);

#//# glClientActiveTexture($texture);
void
glClientActiveTexture(texture)
	GLenum texture
	CODE:
		glClientActiveTexture(texture);

#//# glMultiTexCoord1d($target,$s)
void
glMultiTexCoord1d(target,s)
	GLenum target
	GLdouble s
	CODE:
		glMultiTexCoord1d(target,s);

#//# glMultiTexCoord1dv_c($target,(CPTR)v);
void
glMultiTexCoord1dv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord1dv(target,v);

#//# glMultiTexCoord1dv_s($target,(PACKED)v);
void
glMultiTexCoord1dv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble));
		glMultiTexCoord1dv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord1d
#//# glMultiTexCoord1dv_p($target,$s);
void
glMultiTexCoord1dv_p(target,s)
	GLenum target
	GLdouble s
	CODE:
	{
		glMultiTexCoord1dv(target,&s);
	}

#//# glMultiTexCoord1f($target,$s);
void
glMultiTexCoord1f(target,s)
	GLenum target
	GLfloat s
	CODE:
		glMultiTexCoord1f(target,s);

#//# glMultiTexCoord1fv_c($target,(CPTR)v);
void
glMultiTexCoord1fv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord1fv(target,v);

#//# glMultiTexCoord1fv_s($target,(PACKED)v);
void
glMultiTexCoord1fv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat));
		glMultiTexCoord1fv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord1f
#//# glMultiTexCoord1fv_p($target,$s);
void
glMultiTexCoord1fv_p(target,s)
	GLenum target
	GLfloat s
	CODE:
	{
		glMultiTexCoord1fv(target,&s);
	}

#//# glMultiTexCoord1i($target,$s);
void
glMultiTexCoord1i(target,s)
	GLenum target
	GLint s
	CODE:
		glMultiTexCoord1i(target,s);

#//# glMultiTexCoord1iv_c($target,(CPTR)v);
void
glMultiTexCoord1iv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord1iv(target,v);

#//# glMultiTexCoord1iv_s($target,(PACKED)v);
void
glMultiTexCoord1iv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint));
		glMultiTexCoord1iv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord1i
#//# glMultiTexCoord1iv_p($target,$s);
void
glMultiTexCoord1iv_p(target,s)
	GLenum target
	GLint s
	CODE:
	{
		glMultiTexCoord1iv(target,&s);
	}

#//# glMultiTexCoord1s($target,$s);
void
glMultiTexCoord1s(target,s)
	GLenum target
	GLshort s
	CODE:
		glMultiTexCoord1s(target,s);

#//# glMultiTexCoord1sv_c($target,(CPTR)v);
void
glMultiTexCoord1sv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord1sv(target,v);

#//# glMultiTexCoord1sv_s($target,(PACKED)v);
void
glMultiTexCoord1sv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort));
		glMultiTexCoord1sv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord1s
#//# glMultiTexCoord1sv_p($target,$s);
void
glMultiTexCoord1sv_p(target,s)
	GLenum target
	GLshort s
	CODE:
	{
		glMultiTexCoord1sv(target,&s);
	}

#//# glMultiTexCoord2d($target,$s,$t);
void
glMultiTexCoord2d(target,s,t)
	GLenum target
	GLdouble s
	GLdouble t
	CODE:
		glMultiTexCoord2d(target,s,t);

#//# glMultiTexCoord2dv_c(target,(CPTR)v);
void
glMultiTexCoord2dv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord2dv(target,v);

#//# glMultiTexCoord2dv_s(target,(PACKED)v);
void
glMultiTexCoord2dv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble));
		glMultiTexCoord2dv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord2d
#//# glMultiTexCoord2dv_p($target,$s,$t);
void
glMultiTexCoord2dv_p(target,s,t)
	GLenum target
	GLdouble s
	GLdouble t
	CODE:
	{
		GLdouble param[2];
		param[0] = s;
		param[1] = t;
		glMultiTexCoord2dv(target,param);
	}

#//# glMultiTexCoord2f($target,$s,$t);
void
glMultiTexCoord2f(target,s,t)
	GLenum target
	GLfloat s
	GLfloat t
	CODE:
		glMultiTexCoord2f(target,s,t);

#//# glMultiTexCoord2fv_c($target,(CPTR)v);
void
glMultiTexCoord2fv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord2fv(target,v);

#//# glMultiTexCoord2fv_s($target,(PACKED)v);
void
glMultiTexCoord2fv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat));
		glMultiTexCoord2fv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord2f
#//# glMultiTexCoord2fv_p($target,$s,$t);
void
glMultiTexCoord2fv_p(target,s,t)
	GLenum target
	GLfloat s
	GLfloat t
	CODE:
	{
		GLfloat param[2];
		param[0] = s;
		param[1] = t;
		glMultiTexCoord2fv(target,param);
	}

#//# glMultiTexCoord2i($target,$s,$t);
void
glMultiTexCoord2i(target,s,t)
	GLenum target
	GLint s
	GLint t
	CODE:
		glMultiTexCoord2i(target,s,t);

#//# glMultiTexCoord2iv_c($target,(CPTR)v);
void
glMultiTexCoord2iv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord2iv(target,v);

#//# glMultiTexCoord2iv_s($target,(PACKED)v);
void
glMultiTexCoord2iv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint));
		glMultiTexCoord2iv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord2i
#//# glMultiTexCoord2iv_p($target,$s,$t);
void
glMultiTexCoord2iv_p(target,s,t)
	GLenum target
	GLint s
	GLint t
	CODE:
	{
		GLint param[2];
		param[0] = s;
		param[1] = t;
		glMultiTexCoord2iv(target,param);
	}

#//# glMultiTexCoord2s($target,$s,$t);
void
glMultiTexCoord2s(target,s,t)
	GLenum target
	GLshort s
	GLshort t
	CODE:
		glMultiTexCoord2s(target,s,t);

#//# glMultiTexCoord2sv_c($target,(CPTR)v);
void
glMultiTexCoord2sv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord2sv(target,v);

#//# glMultiTexCoord2sv_s($target,(PACKED)v);
void
glMultiTexCoord2sv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort));
		glMultiTexCoord2sv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord2s
#//# glMultiTexCoord2sv_p($target,$s,$t);
void
glMultiTexCoord2sv_p(target,s,t)
	GLenum target
	GLshort s
	GLshort t
	CODE:
	{
		GLshort param[2];
		param[0] = s;
		param[1] = t;
		glMultiTexCoord2sv(target,param);
	}

#//# glMultiTexCoord3d($target,$s,$t,$r);
void
glMultiTexCoord3d(target,s,t,r)
	GLenum target
	GLdouble s
	GLdouble t
	GLdouble r
	CODE:
		glMultiTexCoord3d(target,s,t,r);

#//# glMultiTexCoord3dv_c(target,(CPTR)v);
void
glMultiTexCoord3dv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord3dv(target,v);

#//# glMultiTexCoord3dv_s(target,(PACKED)v);
void
glMultiTexCoord3dv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble));
		glMultiTexCoord3dv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord3d
#//# glMultiTexCoord3dv_p($target,$s,$t,$r);
void
glMultiTexCoord3dv_p(target,s,t,r)
	GLenum target
	GLdouble s
	GLdouble t
	GLdouble r
	CODE:
	{
		GLdouble param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glMultiTexCoord3dv(target,param);
	}

#//# glMultiTexCoord3f($target,$s,$t,$r);
void
glMultiTexCoord3f(target,s,t,r)
	GLenum target
	GLfloat s
	GLfloat t
	GLfloat r
	CODE:
		glMultiTexCoord3f(target,s,t,r);

#//# glMultiTexCoord3fv_c($target,(CPTR)v);
void
glMultiTexCoord3fv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord3fv(target,v);

#//# glMultiTexCoord3fv_s($target,(PACKED)v);
void
glMultiTexCoord3fv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat));
		glMultiTexCoord3fv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord3f
#//# glMultiTexCoord3fv_p($target,$s,$t,$r);
void
glMultiTexCoord3fv_p(target,s,t,r)
	GLenum target
	GLfloat s
	GLfloat t
	GLfloat r
	CODE:
	{
		GLfloat param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glMultiTexCoord3fv(target,param);
	}

#//# glMultiTexCoord3i($target,$s,$t,$r);
void
glMultiTexCoord3i(target,s,t,r)
	GLenum target
	GLint s
	GLint t
	GLint r
	CODE:
		glMultiTexCoord3i(target,s,t,r);

#//# glMultiTexCoord3iv_c($target,(CPTR)v);
void
glMultiTexCoord3iv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord3iv(target,v);

#//# glMultiTexCoord3iv_s($target,(PACKED)v);
void
glMultiTexCoord3iv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint));
		glMultiTexCoord3iv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord3i
#//# glMultiTexCoord3iv_p($target,$s,$t,$r);
void
glMultiTexCoord3iv_p(target,s,t,r)
	GLenum target
	GLint s
	GLint t
	GLint r
	CODE:
	{
		GLint param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glMultiTexCoord3iv(target,param);
	}

#//# glMultiTexCoord3s($target,$s,$t,$r);
void
glMultiTexCoord3s(target,s,t,r)
	GLenum target
	GLshort s
	GLshort t
	GLshort r
	CODE:
		glMultiTexCoord3s(target,s,t,r);

#//# glMultiTexCoord3sv_c($target,(CPTR)v);
void
glMultiTexCoord3sv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord3sv(target,v);

#//# glMultiTexCoord3sv_s($target,(PACKED)v);
void
glMultiTexCoord3sv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort));
		glMultiTexCoord3sv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord3s
#//# glMultiTexCoord3sv_p($target,$s,$t,$r);
void
glMultiTexCoord3sv_p(target,s,t,r)
	GLenum target
	GLshort s
	GLshort t
	GLshort r
	CODE:
	{
		GLshort param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glMultiTexCoord3sv(target,param);
	}

#//# glMultiTexCoord4d($target,$s,$t,$r,$q);
void
glMultiTexCoord4d(target,s,t,r,q)
	GLenum target
	GLdouble s
	GLdouble t
	GLdouble r
	GLdouble q
	CODE:
		glMultiTexCoord4d(target,s,t,r,q);

#//# glMultiTexCoord4dv_c($target,(CPTR)v);
void
glMultiTexCoord4dv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord4dv(target,v);

#//# glMultiTexCoord4dv_s($target,(PACKED)v);
void
glMultiTexCoord4dv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble));
		glMultiTexCoord4dv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord4d
#//# glMultiTexCoord4dv_p($target,$s,$t,$r,$q);
void
glMultiTexCoord4dv_p(target,s,t,r,q)
	GLenum target
	GLdouble s
	GLdouble t
	GLdouble r
	GLdouble q
	CODE:
	{
		GLdouble param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glMultiTexCoord4dv(target,param);
	}

#//# glMultiTexCoord4f($target,$s,$t,$r,$q);
void
glMultiTexCoord4f(target,s,t,r,q)
	GLenum target
	GLfloat s
	GLfloat t
	GLfloat r
	GLfloat q
	CODE:
		glMultiTexCoord4f(target,s,t,r,q);

#//# glMultiTexCoord4fv_c($target,(CPTR)v);
void
glMultiTexCoord4fv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord4fv(target,v);

#//# glMultiTexCoord4fv_s($target,(PACKED)v);
void
glMultiTexCoord4fv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat));
		glMultiTexCoord4fv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord4f
#//# glMultiTexCoord4fv_p($target,$s,$t,$r,$q);
void
glMultiTexCoord4fv_p(target,s,t,r,q)
	GLenum target
	GLfloat s
	GLfloat t
	GLfloat r
	GLfloat q
	CODE:
	{
		GLfloat param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glMultiTexCoord4fv(target,param);
	}

#//# glMultiTexCoord4i($target,$s,$t,$r,$q)
void
glMultiTexCoord4i(target,s,t,r,q)
	GLenum target
	GLint s
	GLint t
	GLint r
	GLint q
	CODE:
		glMultiTexCoord4i(target,s,t,r,q);

#//# glMultiTexCoord4iv_c($target,(CPTR)v);
void
glMultiTexCoord4iv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord4iv(target,v);

#//# glMultiTexCoord4iv_s($target,(PACKED)v);
void
glMultiTexCoord4iv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint));
		glMultiTexCoord4iv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord4i
#//# glMultiTexCoord4iv_p($target,$s,$t,$r,$q);
void
glMultiTexCoord4iv_p(target,s,t,r,q)
	GLenum target
	GLint s
	GLint t
	GLint r
	GLint q
	CODE:
	{
		GLint param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glMultiTexCoord4iv(target,param);
	}

#//# glMultiTexCoord4s($target,$s,$t,$r,$q);
void
glMultiTexCoord4s(target,s,t,r,q)
	GLenum target
	GLshort s
	GLshort t
	GLshort r
	GLshort q
	CODE:
		glMultiTexCoord4s(target,s,t,r,q);

#//# glMultiTexCoord4sv_c($target,(CPTR)v);
void
glMultiTexCoord4sv_c(target,v)
	GLenum target
	void *v
	CODE:
		glMultiTexCoord4sv(target,v);

#//# glMultiTexCoord4sv_s($target,(PACKED)v);
void
glMultiTexCoord4sv_s(target,v)
	GLenum target
	void *v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort));
		glMultiTexCoord4sv(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord4s
#//# glMultiTexCoord4sv_p($target,$s,$t,$r,$q);
void
glMultiTexCoord4sv_p(target,s,t,r,q)
	GLenum target
	GLshort s
	GLshort t
	GLshort r
	GLshort q
	CODE:
	{
		GLshort param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glMultiTexCoord4sv(target,param);
	}

#endif // defined(GL_VERSION_1_2_1) || defined(GL_VERSION_1_3)

#ifdef GL_VERSION_1_5

#//# @queryIDs = glGenQueries_p($n);
void
glGenQueries_p(n)
	GLint	n
	INIT:
		loadProc(glGenQueries,"glGenQueries");
	PPCODE:
	if (n) {
		GLuint * ids = malloc(sizeof(GLuint) * n);
		int i;

		glGenQueries(n, ids);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ids[i])));

		free(ids);
	}

#//# glDeleteQueries(@textureIDs);
void
glDeleteQueries(...)
	INIT:
		loadProc(glDeleteQueries,"glDeleteQueries");
	PPCODE:
	{
		GLsizei n = items;
		GLuint * ids = malloc(sizeof(GLuint) * (n+1));
		int i;

		for (i=0;i<n;i++)
			ids[i] = SvIV(ST(i));

		glDeleteQueries(n, ids);

		free(ids);
	}

#//# $result = glGetQueryObjectiv($id, $pname);
GLint
glGetQueryObjectiv(id, pname)
	GLuint	id
	GLenum	pname
	INIT:
		loadProc(glGetQueryObjectiv,"glGetQueryObjectiv");
	CODE:
		{
		GLuint result;
		glGetQueryObjectiv(id, pname, &result);
		RETVAL = result;
		}
	OUTPUT:
	    RETVAL

#//# $result = glGetQueryObjectuiv($id, $pname);
GLuint
glGetQueryObjectuiv(id, pname)
	GLuint	id
	GLenum	pname
	INIT:
		loadProc(glGetQueryObjectuiv,"glGetQueryObjectuiv");
	CODE:
		{
		GLuint result;
		glGetQueryObjectuiv(id, pname, &result);
		RETVAL = result;
		}
	OUTPUT:
	    RETVAL

#//# $result = glGetQueryiv($target, $pname);
GLint
glGetQueryiv(target, pname)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetQueryiv,"glGetQueryiv");
	CODE:
		{
		GLint result;
		glGetQueryiv(target, pname, &result);
		RETVAL = result;
		}
	OUTPUT:
	    RETVAL

#//# glBeginQuery($target, $id);
void
glBeginQuery(target, id)
	GLenum	target
	GLuint id
	INIT:
		loadProc(glBeginQuery,"glBeginQuery");

#//# glEndQuery($target, $id);
void
glEndQuery(target)
	GLenum	target
	INIT:
		loadProc(glEndQuery,"glEndQuery");

#endif // GL_VERSION_1_5

#ifdef GL_MESA_resize_buffers

#// glResizeBuffersMESA();
void
glResizeBuffersMESA()

#endif // GL_MESA_resize_buffers

#ifndef NO_GL_EXT_vertex_array
#ifdef GL_EXT_vertex_array

#//# glArrayElementEXT($i);
void
glArrayElementEXT(i)
	GLint	i
	INIT:
		loadProc(glArrayElementEXT,"glArrayElementEXT");

#//# glDrawArraysEXT($mode, $first, $count);
void
glDrawArraysEXT(mode, first, count)
	GLenum	mode
	GLint	first
	GLsizei	count
	INIT:
		loadProc(glDrawArraysEXT,"glDrawArraysEXT");

#endif // GL_EXT_vertex_array
#endif // !NO_GL_EXT_vertex_array

#ifdef GL_ARB_vertex_buffer_object

#//# glBindBufferARB($target,$buffer);
void
glBindBufferARB(target,buffer)
	GLenum target
	GLuint buffer
	INIT:
		loadProc(glBindBufferARB,"glBindBufferARB");
	CODE:
	{
		glBindBufferARB(target,buffer);
	}

#//# glDeleteBuffersARB_c($n,(CPTR)buffers);
void
glDeleteBuffersARB_c(n,buffers)
	GLsizei	n
	void *	buffers
	INIT:
		loadProc(glDeleteBuffersARB,"glDeleteBuffersARB");
	CODE:
	{
		glDeleteBuffersARB(n,buffers);
	}

#//# glDeleteBuffersARB_s($n,(PACKED)buffers);
void
glDeleteBuffersARB_s(n,buffers)
	GLsizei n
	SV *	buffers
	INIT:
		loadProc(glDeleteBuffersARB,"glDeleteBuffersARB");
	CODE:
	{
		void * buffers_s = EL(buffers, sizeof(GLuint)*n);
		glDeleteBuffersARB(n,buffers_s);
	}

#//# glDeleteBuffersARB_p(@buffers);
void
glDeleteBuffersARB_p(...)
	INIT:
		loadProc(glDeleteBuffersARB,"glDeleteBuffersARB");
	CODE:
	{
		if (items) {
			GLuint * list = malloc(sizeof(GLuint) * items);
			int i;

			for (i=0;i<items;i++)
				list[i] = SvIV(ST(i));

			glDeleteBuffersARB(items, list);
			free(list);
		}
	}

#//# glGenBuffersARB_c($n,(CPTR)buffers);
void
glGenBuffersARB_c(n,buffers)
	GLsizei n
	void *	buffers
	INIT:
		loadProc(glGenBuffersARB,"glGenBuffersARB");
	CODE:
	{
		glGenBuffersARB(n, buffers);
	}

#//# glGenBuffersARB_s($n,(PACKED)buffers);
void
glGenBuffersARB_s(n,buffers)
	GLsizei n
	SV *	buffers
	INIT:
		loadProc(glGenBuffersARB,"glGenBuffersARB");
	CODE:
	{
		void * buffers_s = EL(buffers, sizeof(GLuint)*n);
		glGenBuffersARB(n, buffers_s);
	}

#//# @buffers = glGenBuffersARB_p($n);
void
glGenBuffersARB_p(n)
	GLsizei n
	INIT:
		loadProc(glGenBuffersARB,"glGenBuffersARB");
	PPCODE:
	if (n)
	{
		GLuint * buffers = malloc(sizeof(GLuint) * n);
		int i;

		glGenBuffersARB(n, buffers);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(buffers[i])));

		free(buffers);
	}

#//# glIsBufferARB($buffer);
GLboolean
glIsBufferARB(buffer)
	GLuint buffer
	INIT:
		loadProc(glIsBufferARB,"glIsBufferARB");
	CODE:
	{
		RETVAL = glIsBufferARB(buffer);
        }
	OUTPUT:
		RETVAL

#//# glBufferDataARB_c($target,$size,(CPTR)data,$usage);
void
glBufferDataARB_c(target,size,data,usage)
	GLenum	target
	GLsizei	size
	void *	data
	GLenum	usage
	INIT:
		loadProc(glBufferDataARB,"glBufferDataARB");
	CODE:
	{
		glBufferDataARB(target,size,data,usage);
	}

#//# glBufferDataARB_s($target,$size,(PACKED)data,$usage);
void
glBufferDataARB_s(target,size,data,usage)
	GLenum	target
	GLsizei	size
	SV *	data
	GLenum	usage
	INIT:
		loadProc(glBufferDataARB,"glBufferDataARB");
	CODE:
	{
		void * data_s = EL(data, size);
		glBufferDataARB(target,size,data_s,usage);
	}

#//# glBufferDataARB_p($target,(OGA)data,$usage);
void
glBufferDataARB_p(target,oga,usage)
	GLenum target
	OpenGL::Array oga
	GLenum usage
	INIT:
		loadProc(glBufferDataARB,"glBufferDataARB");
	CODE:
	{
		glBufferDataARB(target,oga->data_length,oga->data,usage);
	}

#//# glBufferSubDataARB_c($target,$offset,$size,(CPTR)data);
void
glBufferSubDataARB_c(target,offset,size,data)
	GLenum	target
	GLint	offset
	GLsizei	size
	void *	data
	INIT:
		loadProc(glBufferSubDataARB,"glBufferSubDataARB");
	CODE:
	{
		glBufferSubDataARB(target,offset,size,data);
	}

#//# glBufferSubDataARB_s($target,$offset,$size,(PACKED)data);
void
glBufferSubDataARB_s(target,offset,size,data)
	GLenum	target
	GLint	offset
	GLsizei	size
	SV *	data
	INIT:
		loadProc(glBufferSubDataARB,"glBufferSubDataARB");
	CODE:
	{
		void * data_s = EL(data, size);
		glBufferSubDataARB(target,offset,size,data);
	}

#//# glBufferSubDataARB_p($target,$offset,(OGA)data);
void
glBufferSubDataARB_p(target,offset,oga)
	GLenum	target
	GLint	offset
	OpenGL::Array oga
	INIT:
		loadProc(glBufferSubDataARB,"glBufferSubDataARB");
	CODE:
	{
		glBufferSubDataARB(target,offset*oga->total_types_width,oga->data_length,oga->data);
	}

#//# glGetBufferSubDataARB_c($target,$offset,$size,(CPTR)data)
void
glGetBufferSubDataARB_c(target,offset,size,data)
	GLenum	target
	GLint	offset
	GLsizei	size
	void *	data
	INIT:
		loadProc(glGetBufferSubDataARB,"glBufferSubDataARB");
	CODE:
		glGetBufferSubDataARB(target,offset,size,data);

#//# glGetBufferSubDataARB_s($target,$offset,$size,(PACKED)data)
void
glGetBufferSubDataARB_s(target,offset,size,data)
	GLenum	target
	GLint	offset
	GLsizei	size
	SV *	data
	INIT:
		loadProc(glGetBufferSubDataARB,"glBufferSubDataARB");
	CODE:
	{
		GLubyte * data_s = EL(data,size);
		glGetBufferSubDataARB(target,offset,size,data_s);
	}

#//# $oga = glGetBufferSubDataARB_p($target,$offset,$count,@types);
#//- If no types are provided, GLubyte is assumed
OpenGL::Array
glGetBufferSubDataARB_p(target,offset,count,...)
	GLenum	target
	GLint	offset
	GLsizei	count
	INIT:
		loadProc(glGetBufferSubDataARB,"glGetBufferSubDataARB");
		loadProc(glGetBufferParameterivARB,"glGetBufferParameterivARB");
	CODE:
	{
		oga_struct * oga = malloc(sizeof(oga_struct));
		GLint size;

		oga->item_count = count;
		oga->type_count = (items - 3);

                if (oga->type_count)
		{
			int i,j;

			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
			for(i=0,j=0;i<oga->type_count;i++) {
				oga->types[i] = SvIV(ST(i+3));
				oga->type_offset[i] = j;
				j += gl_type_size(oga->types[i]);
			}
			oga->total_types_width = j;
		}
		else
		{
			oga->type_count = 1;
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);

			oga->types[0] = GL_UNSIGNED_BYTE;
			oga->type_offset[0] = 0;
			oga->total_types_width = gl_type_size(oga->types[0]);
		}
		if (!oga->total_types_width) croak("Unable to determine type sizes\n");

		glGetBufferParameterivARB(target,GL_BUFFER_SIZE_ARB,&size);
		size /= oga->total_types_width;
		if (offset > size) croak("Offset is greater than elements in buffer: %d\n",size);

		if ((offset+count) > size) count = size - offset;

		oga->data_length = oga->total_types_width * count;
		oga->data = malloc(oga->data_length);

		glGetBufferSubDataARB(target,offset*oga->total_types_width,
			oga->data_length,oga->data);

		oga->free_data = 1;

		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#//# (CPTR)buffer = glMapBufferARB_c($target,$access);
void *
glMapBufferARB_c(target,access)
	GLenum	target
	GLenum	access
	INIT:
		loadProc(glMapBufferARB,"glMapBufferARB");
	CODE:
		RETVAL = glMapBufferARB(target,access);
	OUTPUT:
		RETVAL

#define FIXME /* !!! Need to refactor with glGetBufferPointervARB_p */

#//# $oga = glMapBufferARB_p($target,$access,@types);
#//- If no types are provided, GLubyte is assumed
OpenGL::Array
glMapBufferARB_p(target,access,...)
	GLenum	target
	GLenum	access
	INIT:
		loadProc(glMapBufferARB,"glMapBufferARB");
		loadProc(glGetBufferParameterivARB,"glGetBufferParameterivARB");
	CODE:
	{
		GLsizeiptrARB size = 0;
		oga_struct * oga;
		int i,j;

		void * buffer =	glMapBufferARB(target,access);
		if (!buffer) croak("Unable to map buffer\n");

		glGetBufferParameterivARB(target,GL_BUFFER_SIZE_ARB,(GLint*)&size);
		if (!size) croak("Buffer has no size\n");

		oga = malloc(sizeof(oga_struct));

		oga->type_count = (items - 2);

                if (oga->type_count)
		{
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
			for(i=0,j=0;i<oga->type_count;i++) {
				oga->types[i] = SvIV(ST(i+2));
				oga->type_offset[i] = j;
				j += gl_type_size(oga->types[i]);
			}
			oga->total_types_width = j;
		}
		else
		{
			oga->type_count = 1;
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);

			oga->types[0] = GL_UNSIGNED_BYTE;
			oga->type_offset[0] = 0;
			oga->total_types_width = gl_type_size(oga->types[0]);
		}

		if (!oga->total_types_width) croak("Unable to determine type sizes\n");
		oga->item_count = size / oga->total_types_width;

		oga->data_length = oga->total_types_width * oga->item_count;

		oga->data = buffer;

		oga->free_data = 0;

		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#//# glUnmapBufferARB($target);
GLboolean
glUnmapBufferARB(target)
	GLenum	target
	INIT:
		loadProc(glUnmapBufferARB,"glUnmapBufferARB");
	CODE:
		RETVAL = glUnmapBufferARB(target);
	OUTPUT:
		RETVAL

#//# glGetBufferParameterivARB_c($target,$pname,(CPTR)params);
void
glGetBufferParameterivARB_c(target,pname,params)
	GLenum	target
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetBufferParameterivARB,"glGetBufferParameterivARB");
	CODE:
		glGetBufferParameterivARB(target,pname,params);

#//# glGetBufferParameterivARB_s($target,$pname,(PACKED)params);
void
glGetBufferParameterivARB_s(target,pname,params)
	GLenum	target
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetBufferParameterivARB,"glGetBufferParameterivARB");
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint)*1);
		glGetBufferParameterivARB(target,pname,params_s);
	}

#//# @params = glGetBufferParameterivARB_p($target,$pname);
void
glGetBufferParameterivARB_p(target,pname)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetBufferParameterivARB,"glGetBufferParameterivARB");
	PPCODE:
	{
		GLint	ret;
		glGetBufferParameterivARB(target,pname,&ret);
		PUSHs(sv_2mortal(newSViv(ret)));
	}

#//# glGetBufferPointervARB_c($target,$pname,(CPTR)params);
void
glGetBufferPointervARB_c(target,pname,params)
	GLenum	target
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetBufferPointervARB,"glGetBufferPointervARB");
	CODE:
		glGetBufferPointervARB(target,pname,&params);

#//# glGetBufferPointervARB_s($target,$pname,(PACKED)params);
void
glGetBufferPointervARB_s(target,pname,params)
	GLenum	target
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetBufferPointervARB,"glGetBufferPointervARB");
	CODE:
	{
		void ** params_s = EL(params, sizeof(void*));
		glGetBufferPointervARB(target,pname,params_s);
	}

#//# $oga = glGetBufferPointervARB_p($target,$pname,@types);
#//- If no types are provided, GLubyte is assumed
OpenGL::Array
glGetBufferPointervARB_p(target,pname,...)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetBufferPointervARB,"glGetBufferPointervARB");
		loadProc(glGetBufferParameterivARB,"glGetBufferParameterivARB");
	CODE:
	{
		GLsizeiptrARB size;
		oga_struct * oga;
		void * buffer;
		int i,j;

		glGetBufferPointervARB(target,pname,&buffer);
		if (!buffer) croak("Buffer is not mapped\n");

		glGetBufferParameterivARB(target,GL_BUFFER_SIZE_ARB,(GLint*)&size);
		if (!size) croak("Buffer has no size\n");

		oga = malloc(sizeof(oga_struct));

		oga->type_count = (items - 2);

                if (oga->type_count)
		{
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
			for(i=0,j=0;i<oga->type_count;i++) {
				oga->types[i] = SvIV(ST(i+2));
				oga->type_offset[i] = j;
				j += gl_type_size(oga->types[i]);
			}
			oga->total_types_width = j;
		}
		else
		{
			oga->type_count = 1;
			oga->types = malloc(sizeof(GLenum) * oga->type_count);
			oga->type_offset = malloc(sizeof(GLint) * oga->type_count);

			oga->types[0] = GL_UNSIGNED_BYTE;
			oga->type_offset[0] = 0;
			oga->total_types_width = gl_type_size(oga->types[0]);
		}

		if (!oga->total_types_width) croak("Unable to determine type sizes\n");
		oga->item_count = size / oga->total_types_width;

		oga->data_length = oga->total_types_width * oga->item_count;

		oga->data = buffer;

		oga->free_data = 0;

		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#endif // GL_ARB_vertex_buffer_object

#ifdef GL_ARB_multitexture

#//# glActiveTextureARB($texture);
void
glActiveTextureARB(texture)
	GLenum texture
	INIT:
		loadProc(glActiveTextureARB,"glActiveTextureARB");
	CODE:
		glActiveTextureARB(texture);

#//# glClientActiveTextureARB($texture);
void
glClientActiveTextureARB(texture)
	GLenum texture
	INIT:
		loadProc(glClientActiveTextureARB,"glClientActiveTextureARB");
	CODE:
		glClientActiveTextureARB(texture);

#//# glMultiTexCoord1dARB($target,$s)
void
glMultiTexCoord1dARB(target,s)
	GLenum target
	GLdouble s
	INIT:
		loadProc(glMultiTexCoord1dARB,"glMultiTexCoord1dARB");
	CODE:
		glMultiTexCoord1dARB(target,s);

#//# glMultiTexCoord1dvARB_c($target,(CPTR)v);
void
glMultiTexCoord1dvARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord1dvARB,"glMultiTexCoord1dvARB");
	CODE:
		glMultiTexCoord1dvARB(target,v);

#//# glMultiTexCoord1dvARB_s($target,(PACKED)v);
void
glMultiTexCoord1dvARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord1dvARB,"glMultiTexCoord1dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble));
		glMultiTexCoord1dvARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord1dARB
#//# glMultiTexCoord1dvARB_p($target,$s);
void
glMultiTexCoord1dvARB_p(target,s)
	GLenum target
	GLdouble s
	INIT:
		loadProc(glMultiTexCoord1dvARB,"glMultiTexCoord1dvARB");
	CODE:
	{
		glMultiTexCoord1dvARB(target,&s);
	}

#//# glMultiTexCoord1fARB($target,$s);
void
glMultiTexCoord1fARB(target,s)
	GLenum target
	GLfloat s
	INIT:
		loadProc(glMultiTexCoord1fARB,"glMultiTexCoord1fARB");
	CODE:
		glMultiTexCoord1fARB(target,s);

#//# glMultiTexCoord1fvARB_c($target,(CPTR)v);
void
glMultiTexCoord1fvARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord1fvARB,"glMultiTexCoord1fvARB");
	CODE:
		glMultiTexCoord1fvARB(target,v);

#//# glMultiTexCoord1fvARB_s($target,(PACKED)v);
void
glMultiTexCoord1fvARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord1fvARB,"glMultiTexCoord1fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat));
		glMultiTexCoord1fvARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord1fARB
#//# glMultiTexCoord1fvARB_p($target,$s);
void
glMultiTexCoord1fvARB_p(target,s)
	GLenum target
	GLfloat s
	INIT:
		loadProc(glMultiTexCoord1fvARB,"glMultiTexCoord1fvARB");
	CODE:
	{
		glMultiTexCoord1fvARB(target,&s);
	}

#//# glMultiTexCoord1iARB($target,$s);
void
glMultiTexCoord1iARB(target,s)
	GLenum target
	GLint s
	INIT:
		loadProc(glMultiTexCoord1iARB,"glMultiTexCoord1iARB");
	CODE:
		glMultiTexCoord1iARB(target,s);

#//# glMultiTexCoord1ivARB_c($target,(CPTR)v);
void
glMultiTexCoord1ivARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord1ivARB,"glMultiTexCoord1ivARB");
	CODE:
		glMultiTexCoord1ivARB(target,v);

#//# glMultiTexCoord1ivARB_s($target,(PACKED)v);
void
glMultiTexCoord1ivARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord1ivARB,"glMultiTexCoord1ivARB");
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint));
		glMultiTexCoord1ivARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord1iARB
#//# glMultiTexCoord1ivARB_p($target,$s);
void
glMultiTexCoord1ivARB_p(target,s)
	GLenum target
	GLint s
	INIT:
		loadProc(glMultiTexCoord1ivARB,"glMultiTexCoord1ivARB");
	CODE:
	{
		glMultiTexCoord1ivARB(target,&s);
	}

#//# glMultiTexCoord1sARB($target,$s);
void
glMultiTexCoord1sARB(target,s)
	GLenum target
	GLshort s
	INIT:
		loadProc(glMultiTexCoord1sARB,"glMultiTexCoord1sARB");
	CODE:
		glMultiTexCoord1sARB(target,s);

#//# glMultiTexCoord1svARB_c($target,(CPTR)v);
void
glMultiTexCoord1svARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord1svARB,"glMultiTexCoord1svARB");
	CODE:
		glMultiTexCoord1svARB(target,v);

#//# glMultiTexCoord1svARB_s($target,(PACKED)v);
void
glMultiTexCoord1svARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord1svARB,"glMultiTexCoord1svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort));
		glMultiTexCoord1svARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord1sARB
#//# glMultiTexCoord1svARB_p($target,$s);
void
glMultiTexCoord1svARB_p(target,s)
	GLenum target
	GLshort s
	INIT:
		loadProc(glMultiTexCoord1svARB,"glMultiTexCoord1svARB");
	CODE:
	{
		glMultiTexCoord1svARB(target,&s);
	}

#//# glMultiTexCoord2dARB($target,$s,$t);
void
glMultiTexCoord2dARB(target,s,t)
	GLenum target
	GLdouble s
	GLdouble t
	INIT:
		loadProc(glMultiTexCoord2dARB,"glMultiTexCoord2dARB");
	CODE:
		glMultiTexCoord2dARB(target,s,t);

#//# glMultiTexCoord2dvARB_c(target,(CPTR)v);
void
glMultiTexCoord2dvARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord2dvARB,"glMultiTexCoord2dvARB");
	CODE:
		glMultiTexCoord2dvARB(target,v);

#//# glMultiTexCoord2dvARB_s(target,(PACKED)v);
void
glMultiTexCoord2dvARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord2dvARB,"glMultiTexCoord2dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble));
		glMultiTexCoord2dvARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord2dARB
#//# glMultiTexCoord2dvARB_p($target,$s,$t);
void
glMultiTexCoord2dvARB_p(target,s,t)
	GLenum target
	GLdouble s
	GLdouble t
	INIT:
		loadProc(glMultiTexCoord2dvARB,"glMultiTexCoord2dvARB");
	CODE:
	{
		GLdouble param[2];
		param[0] = s;
		param[1] = t;
		glMultiTexCoord2dvARB(target,param);
	}

#//# glMultiTexCoord2fARB($target,$s,$t);
void
glMultiTexCoord2fARB(target,s,t)
	GLenum target
	GLfloat s
	GLfloat t
	INIT:
		loadProc(glMultiTexCoord2fARB,"glMultiTexCoord2fARB");
	CODE:
		glMultiTexCoord2fARB(target,s,t);

#//# glMultiTexCoord2fvARB_c($target,(CPTR)v);
void
glMultiTexCoord2fvARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord2fvARB,"glMultiTexCoord2fvARB");
	CODE:
		glMultiTexCoord2fvARB(target,v);

#//# glMultiTexCoord2fvARB_s($target,(PACKED)v);
void
glMultiTexCoord2fvARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord2fvARB,"glMultiTexCoord2fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat));
		glMultiTexCoord2fvARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord2fARB
#//# glMultiTexCoord2fvARB_p($target,$s,$t);
void
glMultiTexCoord2fvARB_p(target,s,t)
	GLenum target
	GLfloat s
	GLfloat t
	INIT:
		loadProc(glMultiTexCoord2fvARB,"glMultiTexCoord2fvARB");
	CODE:
	{
		GLfloat param[2];
		param[0] = s;
		param[1] = t;
		glMultiTexCoord2fvARB(target,param);
	}

#//# glMultiTexCoord2iARB($target,$s,$t);
void
glMultiTexCoord2iARB(target,s,t)
	GLenum target
	GLint s
	GLint t
	INIT:
		loadProc(glMultiTexCoord2iARB,"glMultiTexCoord2iARB");
	CODE:
		glMultiTexCoord2iARB(target,s,t);

#//# glMultiTexCoord2ivARB_c($target,(CPTR)v);
void
glMultiTexCoord2ivARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord2ivARB,"glMultiTexCoord2ivARB");
	CODE:
		glMultiTexCoord2ivARB(target,v);

#//# glMultiTexCoord2ivARB_s($target,(PACKED)v);
void
glMultiTexCoord2ivARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord2ivARB,"glMultiTexCoord2ivARB");
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint));
		glMultiTexCoord2ivARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord2iARB
#//# glMultiTexCoord2ivARB_p($target,$s,$t);
void
glMultiTexCoord2ivARB_p(target,s,t)
	GLenum target
	GLint s
	GLint t
	INIT:
		loadProc(glMultiTexCoord2ivARB,"glMultiTexCoord2ivARB");
	CODE:
	{
		GLint param[2];
		param[0] = s;
		param[1] = t;
		glMultiTexCoord2ivARB(target,param);
	}

#//# glMultiTexCoord2sARB($target,$s,$t);
void
glMultiTexCoord2sARB(target,s,t)
	GLenum target
	GLshort s
	GLshort t
	INIT:
		loadProc(glMultiTexCoord2sARB,"glMultiTexCoord2sARB");
	CODE:
		glMultiTexCoord2sARB(target,s,t);

#//# glMultiTexCoord2svARB_c($target,(CPTR)v);
void
glMultiTexCoord2svARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord2svARB,"glMultiTexCoord2svARB");
	CODE:
		glMultiTexCoord2svARB(target,v);

#//# glMultiTexCoord2svARB_s($target,(PACKED)v);
void
glMultiTexCoord2svARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord2svARB,"glMultiTexCoord2svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort));
		glMultiTexCoord2svARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord2sARB
#//# glMultiTexCoord2svARB_p($target,$s,$t);
void
glMultiTexCoord2svARB_p(target,s,t)
	GLenum target
	GLshort s
	GLshort t
	INIT:
		loadProc(glMultiTexCoord2svARB,"glMultiTexCoord2svARB");
	CODE:
	{
		GLshort param[2];
		param[0] = s;
		param[1] = t;
		glMultiTexCoord2svARB(target,param);
	}

#//# glMultiTexCoord3dARB($target,$s,$t,$r);
void
glMultiTexCoord3dARB(target,s,t,r)
	GLenum target
	GLdouble s
	GLdouble t
	GLdouble r
	INIT:
		loadProc(glMultiTexCoord3dARB,"glMultiTexCoord3dARB");
	CODE:
		glMultiTexCoord3dARB(target,s,t,r);

#//# glMultiTexCoord3dvARB_c(target,(CPTR)v);
void
glMultiTexCoord3dvARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord3dvARB,"glMultiTexCoord3dvARB");
	CODE:
		glMultiTexCoord3dvARB(target,v);

#//# glMultiTexCoord3dvARB_s(target,(PACKED)v);
void
glMultiTexCoord3dvARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord3dvARB,"glMultiTexCoord3dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble));
		glMultiTexCoord3dvARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord3dARB
#//# glMultiTexCoord3dvARB_p($target,$s,$t,$r);
void
glMultiTexCoord3dvARB_p(target,s,t,r)
	GLenum target
	GLdouble s
	GLdouble t
	GLdouble r
	INIT:
		loadProc(glMultiTexCoord3dvARB,"glMultiTexCoord3dvARB");
	CODE:
	{
		GLdouble param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glMultiTexCoord3dvARB(target,param);
	}

#//# glMultiTexCoord3fARB($target,$s,$t,$r);
void
glMultiTexCoord3fARB(target,s,t,r)
	GLenum target
	GLfloat s
	GLfloat t
	GLfloat r
	INIT:
		loadProc(glMultiTexCoord3fARB,"glMultiTexCoord3fARB");
	CODE:
		glMultiTexCoord3fARB(target,s,t,r);

#//# glMultiTexCoord3fvARB_c($target,(CPTR)v);
void
glMultiTexCoord3fvARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord3fvARB,"glMultiTexCoord3fvARB");
	CODE:
		glMultiTexCoord3fvARB(target,v);

#//# glMultiTexCoord3fvARB_s($target,(PACKED)v);
void
glMultiTexCoord3fvARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord3fvARB,"glMultiTexCoord3fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat));
		glMultiTexCoord3fvARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord3fARB
#//# glMultiTexCoord3fvARB_p($target,$s,$t,$r);
void
glMultiTexCoord3fvARB_p(target,s,t,r)
	GLenum target
	GLfloat s
	GLfloat t
	GLfloat r
	INIT:
		loadProc(glMultiTexCoord3fvARB,"glMultiTexCoord3fvARB");
	CODE:
	{
		GLfloat param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glMultiTexCoord3fvARB(target,param);
	}

#//# glMultiTexCoord3iARB($target,$s,$t,$r);
void
glMultiTexCoord3iARB(target,s,t,r)
	GLenum target
	GLint s
	GLint t
	GLint r
	INIT:
		loadProc(glMultiTexCoord3iARB,"glMultiTexCoord3iARB");
	CODE:
		glMultiTexCoord3iARB(target,s,t,r);

#//# glMultiTexCoord3ivARB_c($target,(CPTR)v);
void
glMultiTexCoord3ivARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord3ivARB,"glMultiTexCoord3ivARB");
	CODE:
		glMultiTexCoord3ivARB(target,v);

#//# glMultiTexCoord3ivARB_s($target,(PACKED)v);
void
glMultiTexCoord3ivARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord3ivARB,"glMultiTexCoord3ivARB");
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint));
		glMultiTexCoord3ivARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord3iARB
#//# glMultiTexCoord3ivARB_p($target,$s,$t,$r);
void
glMultiTexCoord3ivARB_p(target,s,t,r)
	GLenum target
	GLint s
	GLint t
	GLint r
	INIT:
		loadProc(glMultiTexCoord3ivARB,"glMultiTexCoord3ivARB");
	CODE:
	{
		GLint param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glMultiTexCoord3ivARB(target,param);
	}

#//# glMultiTexCoord3sARB($target,$s,$t,$r);
void
glMultiTexCoord3sARB(target,s,t,r)
	GLenum target
	GLshort s
	GLshort t
	GLshort r
	INIT:
		loadProc(glMultiTexCoord3sARB,"glMultiTexCoord3sARB");
	CODE:
		glMultiTexCoord3sARB(target,s,t,r);

#//# glMultiTexCoord3svARB_c($target,(CPTR)v);
void
glMultiTexCoord3svARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord3svARB,"glMultiTexCoord3svARB");
	CODE:
		glMultiTexCoord3svARB(target,v);

#//# glMultiTexCoord3svARB_s($target,(PACKED)v);
void
glMultiTexCoord3svARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord3svARB,"glMultiTexCoord3svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort));
		glMultiTexCoord3svARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord3sARB
#//# glMultiTexCoord3svARB_p($target,$s,$t,$r);
void
glMultiTexCoord3svARB_p(target,s,t,r)
	GLenum target
	GLshort s
	GLshort t
	GLshort r
	INIT:
		loadProc(glMultiTexCoord3svARB,"glMultiTexCoord3svARB");
	CODE:
	{
		GLshort param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glMultiTexCoord3svARB(target,param);
	}

#//# glMultiTexCoord4dARB($target,$s,$t,$r,$q);
void
glMultiTexCoord4dARB(target,s,t,r,q)
	GLenum target
	GLdouble s
	GLdouble t
	GLdouble r
	GLdouble q
	INIT:
		loadProc(glMultiTexCoord4dARB,"glMultiTexCoord4dARB");
	CODE:
		glMultiTexCoord4dARB(target,s,t,r,q);

#//# glMultiTexCoord4dvARB_c($target,(CPTR)v);
void
glMultiTexCoord4dvARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord4dvARB,"glMultiTexCoord4dvARB");
	CODE:
		glMultiTexCoord4dvARB(target,v);

#//# glMultiTexCoord4dvARB_s($target,(PACKED)v);
void
glMultiTexCoord4dvARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord4dvARB,"glMultiTexCoord4dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble));
		glMultiTexCoord4dvARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord4dARB
#//# glMultiTexCoord4dvARB_p($target,$s,$t,$r,$q);
void
glMultiTexCoord4dvARB_p(target,s,t,r,q)
	GLenum target
	GLdouble s
	GLdouble t
	GLdouble r
	GLdouble q
	INIT:
		loadProc(glMultiTexCoord4dvARB,"glMultiTexCoord4dvARB");
	CODE:
	{
		GLdouble param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glMultiTexCoord4dvARB(target,param);
	}

#//# glMultiTexCoord4fARB($target,$s,$t,$r,$q);
void
glMultiTexCoord4fARB(target,s,t,r,q)
	GLenum target
	GLfloat s
	GLfloat t
	GLfloat r
	GLfloat q
	INIT:
		loadProc(glMultiTexCoord4fARB,"glMultiTexCoord4fARB");
	CODE:
		glMultiTexCoord4fARB(target,s,t,r,q);

#//# glMultiTexCoord4fvARB_c($target,(CPTR)v);
void
glMultiTexCoord4fvARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord4fvARB,"glMultiTexCoord4fvARB");
	CODE:
		glMultiTexCoord4fvARB(target,v);

#//# glMultiTexCoord4fvARB_s($target,(PACKED)v);
void
glMultiTexCoord4fvARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord4fvARB,"glMultiTexCoord4fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat));
		glMultiTexCoord4fvARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord4fARB
#//# glMultiTexCoord4fvARB_p($target,$s,$t,$r,$q);
void
glMultiTexCoord4fvARB_p(target,s,t,r,q)
	GLenum target
	GLfloat s
	GLfloat t
	GLfloat r
	GLfloat q
	INIT:
		loadProc(glMultiTexCoord4fvARB,"glMultiTexCoord4fvARB");
	CODE:
	{
		GLfloat param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glMultiTexCoord4fvARB(target,param);
	}

#//# glMultiTexCoord4iARB($target,$s,$t,$r,$q)
void
glMultiTexCoord4iARB(target,s,t,r,q)
	GLenum target
	GLint s
	GLint t
	GLint r
	GLint q
	INIT:
		loadProc(glMultiTexCoord4iARB,"glMultiTexCoord4iARB");
	CODE:
		glMultiTexCoord4iARB(target,s,t,r,q);

#//# glMultiTexCoord4ivARB_c($target,(CPTR)v);
void
glMultiTexCoord4ivARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord4ivARB,"glMultiTexCoord4ivARB");
	CODE:
		glMultiTexCoord4ivARB(target,v);

#//# glMultiTexCoord4ivARB_s($target,(PACKED)v);
void
glMultiTexCoord4ivARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord4ivARB,"glMultiTexCoord4ivARB");
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint));
		glMultiTexCoord4ivARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord4iARB
#//# glMultiTexCoord4ivARB_p($target,$s,$t,$r,$q);
void
glMultiTexCoord4ivARB_p(target,s,t,r,q)
	GLenum target
	GLint s
	GLint t
	GLint r
	GLint q
	INIT:
		loadProc(glMultiTexCoord4ivARB,"glMultiTexCoord4ivARB");
	CODE:
	{
		GLint param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glMultiTexCoord4ivARB(target,param);
	}

#//# glMultiTexCoord4sARB($target,$s,$t,$r,$q);
void
glMultiTexCoord4sARB(target,s,t,r,q)
	GLenum target
	GLshort s
	GLshort t
	GLshort r
	GLshort q
	INIT:
		loadProc(glMultiTexCoord4sARB,"glMultiTexCoord4sARB");
	CODE:
		glMultiTexCoord4sARB(target,s,t,r,q);

#//# glMultiTexCoord4svARB_c($target,(CPTR)v);
void
glMultiTexCoord4svARB_c(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord4svARB,"glMultiTexCoord4svARB");
	CODE:
		glMultiTexCoord4svARB(target,v);

#//# glMultiTexCoord4svARB_s($target,(PACKED)v);
void
glMultiTexCoord4svARB_s(target,v)
	GLenum target
	void *v
	INIT:
		loadProc(glMultiTexCoord4svARB,"glMultiTexCoord4svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort));
		glMultiTexCoord4svARB(target,v_s);
	}

#//!!! Do we really need this?  It duplicates glMultiTexCoord4sARB
#//# glMultiTexCoord4svARB_p($target,$s,$t,$r,$q);
void
glMultiTexCoord4svARB_p(target,s,t,r,q)
	GLenum target
	GLshort s
	GLshort t
	GLshort r
	GLshort q
	INIT:
		loadProc(glMultiTexCoord4svARB,"glMultiTexCoord4svARB");
	CODE:
	{
		GLshort param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glMultiTexCoord4svARB(target,param);
	}

#endif // GL_ARB_multitexture

#ifdef GL_ARB_point_parameters

#//# glPointParameterfARB($pname,$param);
void
glPointParameterfARB(pname,param)
	GLenum pname
	GLfloat param
	INIT:
		loadProc(glPointParameterfARB,"glPointParameterfARB");
	CODE:
	{
		glPointParameterfARB(pname,param);
	}

#//# glPointParameterfvARB_c($pname,(CPTR)params);
void
glPointParameterfvARB_c(pname,params)
	GLenum pname
	void *	params
	INIT:
		loadProc(glPointParameterfvARB,"glPointParameterfvARB");
	CODE:
		glPointParameterfvARB(pname,(GLfloat*)params);

#//# glPointParameterfvARB_s($pname,(PACKED)params);
void
glPointParameterfvARB_s(pname,params)
	GLenum pname
	SV *	params
	INIT:
		loadProc(glPointParameterfvARB,"glPointParameterfvARB");
	CODE:
	{
		int count = gl_get_count(pname);
		GLfloat * params_s = EL(params, sizeof(GLfloat)*count);
		glPointParameterfvARB(pname,params_s);
	}

#//!!! This implementation doesn't look right
#//# glPointParameterfvARB_p($pname,@params);
void
glPointParameterfvARB_p(pname, ...)
	GLenum pname
	INIT:
		loadProc(glPointParameterfvARB,"glPointParameterfvARB");
	CODE:
	{
		GLfloat params[4];
		int i;
		if ((items-1) != gl_get_count(pname))
			croak("Incorrect number of arguments");
		for(i=1;i<items;i++)
			params[i-1] = (GLfloat)SvNV(ST(i));
		glPointParameterfvARB(pname,params);
	}

#endif


#ifdef GL_ARB_multisample

#//# glSampleCoverageARB($value,$invert);
void
glSampleCoverageARB(value,invert)
	GLclampf value
	GLboolean invert
	INIT:
		loadProc(glSampleCoverageARB,"glSampleCoverageARB");
	CODE:
	{
		glSampleCoverageARB(value,invert);
	}

#endif

#ifdef GL_EXT_texture3D

#//# glTexImage3DEXT_c($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, (CPTR)pixels);
void
glTexImage3DEXT_c(target, level, internalformat, width, height, depth, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLenum	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	void *	pixels
	INIT:
		loadProc(glTexImage3DEXT,"glTexImage3DEXT");
	CODE:
	{
		glTexImage3DEXT(target, level, internalformat, width, height,
			depth, border, format, type, pixels);
	}

#//# glTexImage3DEXT_s($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, (PACKED)pixels);
void
glTexImage3DEXT_s(target, level, internalformat, width, height, depth, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLenum	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	SV *	pixels
	INIT:
		loadProc(glTexImage3DEXT,"glTexImage3DEXT");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_unpack);
		glTexImage3DEXT(target, level, internalformat, width, height,
			depth, border, format, type, ptr);
	}

#//# glTexImage3DEXT_p($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, @pixels);
void
glTexImage3DEXT_p(target, level, internalformat, width, height, depth, border, format, type, ...)
	GLenum	target
	GLint	level
	GLenum	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	INIT:
		loadProc(glTexImage3DEXT,"glTexImage3DEXT");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(4)), items-4, width, height, 1, format, type, 0);
		glTexImage3DEXT(target, level, internalformat, width, height,
			depth, border, format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#//# glTexSubImage3DEXT_c($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $format, $type, (CPTR)pixels);
void
glTexSubImage3DEXT_c(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLenum	format
	GLenum	type
	void *	pixels
	INIT:
		loadProc(glTexSubImage3DEXT,"glTexSubImage3DEXT");
	CODE:
	{
		glTexSubImage3DEXT(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, pixels);
	}

#//# glTexSubImage3DEXT_s($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $format, $type, (PACKED)pixels);
void
glTexSubImage3DEXT_s(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLenum	format
	GLenum	type
	SV *	pixels
	INIT:
		loadProc(glTexSubImage3DEXT,"glTexSubImage3DEXT");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_unpack);
		glTexSubImage3DEXT(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, ptr);
	}

#//# glTexSubImage3DEXT_p($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $format, $type, @pixels);
void
glTexSubImage3DEXT_p(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, ...)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLenum	format
	GLenum	type
	INIT:
		loadProc(glTexSubImage3DEXT,"glTexSubImage3DEXT");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(4)), items-4, width, height, 1, format, type, 0);
		glTexSubImage3DEXT(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#endif

#if defined(GL_EXT_blend_minmax) && (!defined(GL_SRC_ALPHA_SATURATE) || defined(GL_CONSTANT_COLOR))

#//# glBlendEquationEXT($mode);
void
glBlendEquationEXT(mode)
	GLenum	mode
	INIT:
		loadProc(glBlendEquationEXT,"glBlendEquationEXT");
	CODE:
		glBlendEquationEXT(mode);

#endif

#ifdef GL_EXT_blend_color

#//# glBlendColorEXT($red, $green, $blue, $alpha);
void
glBlendColorEXT(red, green, blue, alpha)
	GLclampf	red
	GLclampf	green
	GLclampf	blue
	GLclampf	alpha
	INIT:
		loadProc(glBlendColorEXT,"glBlendColorEXT");
	CODE:
		glBlendColorEXT(red, green, blue, alpha);

#endif

#endif /* HAVE_GL */
