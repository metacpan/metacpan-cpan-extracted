/*  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 2009 Chris Marshall. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

#include <stdio.h>

#include "pgopogl.h"
#include "gl_errors.h"

#ifdef HAVE_GL
#include "gl_util.h"
#endif /* defined HAVE_GL */

MODULE = OpenGL::V1	PACKAGE = OpenGL

#ifdef HAVE_GL

#// 1.0
#//# glBitmap_c($width, $height, $xorig, $yorig, $xmove, $ymove, (CPTR)bitmap);
void
glBitmap_c(width, height, xorig, yorig, xmove, ymove, bitmap)
	GLsizei width
	GLsizei height
	GLfloat xorig
	GLfloat yorig
	GLfloat xmove
	GLfloat ymove
	void *  bitmap
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
#//# glCallLists_s($n, $type, (PACKED)lists);
void
glCallLists_s(n, type, lists)
	GLsizei	n
	GLenum	type
	SV *	lists
	CODE:
	{
	int size = gl_type_size(type);
	if (size < 0) croak("unknown type");
	void * lists_s = EL(lists, size * n);
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

#ifdef GL_VERSION_1_1

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
		int size = gl_type_size(type);
		if (size < 0) croak("unknown type");
		void * indices_s = EL(indices, size*count);
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
		int size = gl_type_size(type);
		if (size < 0) croak("unknown type");
		void * indices_s = EL(indices, size * count);
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
#//# glGetMapdv_s($target, $query, (PACKED)v);
void
glGetMapdv_s(target, query, v)
	GLenum	target
	GLenum	query
	SV * v
	CODE:
	{
		int nparams = gl_map_count(target, query);
		if (nparams < 0) croak("Unknown map query");
		GLdouble * v_s = EL(v, sizeof(GLdouble)*nparams);
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
		int nparams = gl_map_count(target, query);
		if (nparams < 0) croak("Unknown map query");
		GLfloat * v_s = EL(v, sizeof(GLfloat)*nparams);
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
		int nparams = gl_map_count(target, query);
		if (nparams < 0) croak("Unknown map query");
		GLint * v_s = EL(v, sizeof(GLint)*nparams);
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
		if (n < 0) croak("Unknown map query");
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
		if (n < 0) croak("Unknown map query");
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
		if (n < 0) croak("Unknown map query");
		int i;
		glGetMapiv(target, query, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glGetPixelMapfv_s($map, (PACKED)values);
void
glGetPixelMapfv_s(map, values)
	GLenum	map
	SV *	values
	CODE:
	{
	int nparams = gl_pixelmap_size(map);
	if (nparams < 0) croak("unknown pixelmap");
	GLfloat * values_s = EL(values, sizeof(GLfloat)* nparams);
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
	int nparams = gl_pixelmap_size(map);
	if (nparams < 0) croak("unknown pixelmap");
	GLuint * values_s = EL(values, sizeof(GLuint)* nparams);
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
	int nparams = gl_pixelmap_size(map);
	if (nparams < 0) croak("unknown pixelmap");
	GLushort * values_s = EL(values, sizeof(GLushort)* nparams);
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
		if (count < 0) croak("unknown pixelmap");
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
		if (count < 0) croak("unknown pixelmap");
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
		if (count < 0) croak("unknown pixelmap");
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
#//# glPolygonStipple_c((CPTR)mask);
void
glPolygonStipple_c(mask)
	void *  mask
	CODE:
	glPolygonStipple(mask);

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
#//# @pixels = glGetTexImage_p($target, $level, $format, $type);
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
		int nparams = gl_map_count(target, GL_COEFF);
		if (nparams < 0) croak("Unknown map query");
		GLint order = (items - 3) / nparams;
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
		int nparams = gl_map_count(target, GL_COEFF);
		if (nparams < 0) croak("Unknown map query");
		GLint order = (items - 3) / nparams;
		GLfloat * points = malloc(sizeof(GLfloat) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = (GLfloat)SvNV(ST(i+3));
		glMap1f(target, u1, u2, 0, order, points);
		free(points);
	}

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
		int nparams = gl_map_count(target, GL_COEFF);
		if (nparams < 0) croak("Unknown map query");
		GLint vorder = (count / uorder) / nparams;
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
		int nparams = gl_map_count(target, GL_COEFF);
		if (nparams < 0) croak("Unknown map query");
		GLint vorder = (count / uorder) / nparams;
		GLfloat * points = malloc(sizeof(GLfloat) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = (GLfloat)SvNV(ST(i+6));
		glMap2f(target, u1, u2, 0, uorder, v1, v2, 0, vorder, points);
		free(points);
	}

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

#ifdef GL_VERSION_1_1

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
#//# glTexSubImage2D_p($target, $level, $xoffset, $yoffset, $width, $height, $border, $format, $type, @pixels);
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

#if defined(GL_VERSION_1_1) || defined(GL_EXT_vertex_array)

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
#//# glVertexPointer_p($size, (OGA)pointer);
void
glVertexPointerEXT_p(size, oga)
	GLint	size
	OpenGL::Array oga
	ALIAS:
	glVertexPointer_p = 1
	glVertexPointer_o = 2
	glVertexPointerEXT_o = 3
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glVertexPointerEXT,"glVertexPointerEXT");
#endif
#ifdef GL_VERSION_2_0
		loadProc(glBindBufferARB,"glBindBufferARB");
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
#//# glNormalPointer_p((OGA)pointer);
void
glNormalPointer_p(oga)
	OpenGL::Array oga
	ALIAS:
	glNormalPointerEXT_p = 1
	glNormalPointer_o = 2
	glNormalPointerEXT_o = 3
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glNormalPointerEXT,"glNormalPointerEXT");
#endif
#ifdef GL_VERSION_2_0
		loadProc(glBindBufferARB,"glBindBufferARB");
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
#//# glColorPointer_p($size, (OGA)pointer);
void
glColorPointer_p(size, oga)
	GLint	size
	OpenGL::Array oga
	ALIAS:
	glColorPointerEXT_p = 1
	glColorPointerEXT_o = 2
	glColorPointer_o = 3
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glColorPointerEXT,"glColorPointerEXT");
#endif
#ifdef GL_VERSION_2_0
		loadProc(glBindBufferARB,"glBindBufferARB");
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
#//# glIndexPointer_p((OGA)pointer);
void
glIndexPointer_p(oga)
	OpenGL::Array oga
	ALIAS:
	glIndexPointerEXT_p = 1
	glIndexPointerEXT_o = 2
	glIndexPointer_o = 3
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glIndexPointerEXT,"glIndexPointerEXT");
#endif
#ifdef GL_VERSION_2_0
		loadProc(glBindBufferARB,"glBindBufferARB");
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
#//# glTexCoordPointer_p($size, (OGA)pointer);
void
glTexCoordPointer_p(size, oga)
	GLint	size
	OpenGL::Array oga
	ALIAS:
	glTexCoordPointerEXT_p = 1
	glTexCoordPointerEXT_o = 2
	glTexCoordPointer_o = 3
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glTexCoordPointerEXT");
#endif
#ifdef GL_VERSION_2_0
		loadProc(glBindBufferARB,"glBindBufferARB");
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
#//# glEdgeFlagPointer_p((OGA)pointer);
void
glEdgeFlagPointer_p(oga)
	OpenGL::Array oga
	ALIAS:
	glEdgeFlagPointerEXT_p = 1
	glEdgeFlagPointerEXT_o = 2
	glEdgeFlagPointer_o = 3
	INIT:
#ifndef GL_VERSION_1_1 // GL_EXT_vertex_array
		loadProc(glTexCoordPointerEXT,"glEdgeFlagPointerEXT");
#endif
#ifdef GL_VERSION_2_0
		loadProc(glBindBufferARB,"glBindBufferARB");
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

#//# glNormalPointer_s($type, $stride, (PACKED)pointer);
void
glNormalPointer_s(type, stride, pointer)
	GLenum	type
	GLsizei	stride
	SV *	pointer
	CODE:
	{
		int size = gl_type_size(type);
		if (size < 0) croak("unknown type");
		int width = stride ? stride : (size*3);
		void * pointer_s = NULL;
		if ( pointer ) {
			pointer_s = EL(pointer, width);
		}
		glNormalPointer(type, stride, pointer_s);
	}

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

#//# glIndexPointer_s($type, $stride, (PACKED)pointer);
void
glIndexPointer_s(type, stride, pointer)
	GLenum	type
	GLsizei	stride
	SV *	pointer
	CODE:
	{
		int size = gl_type_size(type);
		if (size < 0) croak("unknown type");
		int width = stride ? stride : size;
		void * pointer_s = NULL;
		if ( pointer ) {
			pointer_s = EL(pointer, width);
		}
		glIndexPointer(type, stride, pointer_s);
	}

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
	ALIAS:
	glBufferData_o = 1
	CODE:
	{
		glBufferData(target,oga->data_length,oga->data,usage);
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
	ALIAS:
	glBufferSubData_o = 1
	CODE:
	{
		glBufferSubData(target,offset*oga->total_types_width,oga->data_length,oga->data);
	}

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
	ALIAS:
	glGetBufferSubData_o = 1
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
				int size = gl_type_size(oga->types[i]);
				if (size < 0) croak("unknown type");
				j += size;
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
			int size = gl_type_size(oga->types[0]);
			if (size < 0) croak("unknown type");
			oga->total_types_width = size;
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

#define FIXME /* !!! Need to refactor with glGetBufferPointerv_p */

#//# $oga = glMapBuffer_p($target,$access,@types);
#//- If no types are provided, GLubyte is assumed
OpenGL::Array
glMapBuffer_p(target,access,...)
	GLenum	target
	GLenum	access
	ALIAS:
	glMapBuffer_o = 1
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
				int size = gl_type_size(oga->types[i]);
				if (size < 0) croak("unknown type");
				j += size;
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
			int size = gl_type_size(oga->types[0]);
			if (size < 0) croak("unknown type");
			oga->total_types_width = size;
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
	ALIAS:
	glGetBufferPointerv_o = 1
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
				int size = gl_type_size(oga->types[i]);
				if (size < 0) croak("unknown type");
				j += size;
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
			int size = gl_type_size(oga->types[0]);
			if (size < 0) croak("unknown type");
			oga->total_types_width = size;
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

#ifdef GL_VERSION_1_5

#//# $result = glGetQueryObjectiv($id, $pname);
GLint
glGetQueryObjectiv(id, pname)
	GLuint	id
	GLenum	pname
	INIT:
		loadProc(glGetQueryObjectiv,"glGetQueryObjectiv");
	CODE:
		{
		GLint result;
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

#endif // GL_VERSION_1_5

#ifdef GL_ARB_vertex_buffer_object

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
	ALIAS:
	glBufferDataARB_o = 1
	INIT:
		loadProc(glBufferDataARB,"glBufferDataARB");
	CODE:
	{
		glBufferDataARB(target,oga->data_length,oga->data,usage);
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
	ALIAS:
	glBufferSubDataARB_o = 1
	INIT:
		loadProc(glBufferSubDataARB,"glBufferSubDataARB");
	CODE:
	{
		glBufferSubDataARB(target,offset*oga->total_types_width,oga->data_length,oga->data);
	}

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
	ALIAS:
	glGetBufferSubDataARB_o = 1
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
				int size = gl_type_size(oga->types[i]);
				if (size < 0) croak("unknown type");
				j += size;
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
			int size = gl_type_size(oga->types[0]);
			if (size < 0) croak("unknown type");
			oga->total_types_width = size;
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

#define FIXME /* !!! Need to refactor with glGetBufferPointervARB_p */

#//# $oga = glMapBufferARB_p($target,$access,@types);
#//- If no types are provided, GLubyte is assumed
OpenGL::Array
glMapBufferARB_p(target,access,...)
	GLenum	target
	GLenum	access
	ALIAS:
	glMapBufferARB_o = 1
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
				int size = gl_type_size(oga->types[i]);
				if (size < 0) croak("unknown type");
				j += size;
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
			int size = gl_type_size(oga->types[0]);
			if (size < 0) croak("unknown type");
			oga->total_types_width = size;
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
	ALIAS:
	glGetBufferPointervARB_p = 1
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
				int size = gl_type_size(oga->types[i]);
				if (size < 0) croak("unknown type");
				j += size;
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
			int size = gl_type_size(oga->types[0]);
			if (size < 0) croak("unknown type");
			oga->total_types_width = size;
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

#ifdef GL_EXT_texture3D

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

#endif /* HAVE_GL */
