/*  Last saved: Sun 06 Sep 2009 02:10:16 PM*/

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





MODULE = OpenGL::GL::VertMulti	PACKAGE = OpenGL





#ifdef HAVE_GL


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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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
		glBindBuffer(GL_ARRAY_BUFFER, oga->bind);
		data = NULL;
#elif defined(GL_ARB_vertex_buffer_object)
		if (testProc(glBindBufferARB,"glBindBufferARB"))
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, oga->bind);
			data = NULL;
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


#ifdef GL_MESA_resize_buffers

#// glResizeBuffersMESA();
void
glResizeBuffersMESA()

#endif // GL_MESA_resize_buffers


#ifdef GL_VERSION_2_0

#//# glDrawBuffers_c($n,(CPTR)buffers);
void
glDrawBuffers_c(n,buffers)
	GLsizei n
	void *	buffers
	CODE:
	{
		glDrawBuffers(n,buffers);
	}

#//# glDrawBuffers_s($n,(PACKED)buffers);
void
glDrawBuffers_s(n,buffers)
	GLsizei n
	SV *	buffers
	CODE:
	{
		void * buffers_s = EL(buffers, sizeof(GLuint)*n);
		glDrawBuffers(n,buffers_s);
	}

#//# glDrawBuffers_p(@buffers);
void
glDrawBuffers_p(...)
	CODE:
	{
		if (items) {
			GLuint * list = malloc(sizeof(GLuint) * items);
			int i;

			for (i=0;i<items;i++)
				list[i] = SvIV(ST(i));

			glDrawBuffers(items, list);
			free(list);
		}
	}

#endif // GL_VERSION_2_0


#ifdef GL_ARB_draw_buffers

#//# glDrawBuffersARB_c($n,(CPTR)buffers);
void
glDrawBuffersARB_c(n,buffers)
	GLsizei n
	void *	buffers
	INIT:
		loadProc(glDrawBuffersARB,"glDrawBuffersARB");
	CODE:
	{
		glDrawBuffersARB(n,buffers);
	}

#//# glDrawBuffersARB_s($n,(PACKED)buffers);
void
glDrawBuffersARB_s(n,buffers)
	GLsizei n
	SV *	buffers
	INIT:
		loadProc(glDrawBuffersARB,"glDrawBuffersARB");
	CODE:
	{
		void * buffers_s = EL(buffers, sizeof(GLuint)*n);
		glDrawBuffersARB(n,buffers_s);
	}

#//# glDrawBuffersARB_p(@buffers);
void
glDrawBuffersARB_p(...)
	INIT:
		loadProc(glDrawBuffersARB,"glDrawBuffersARB");
	CODE:
	{
		if (items)
		{
			GLuint * list = malloc(sizeof(GLuint) * items);
			int i;
			for (i=0;i<items;i++)
				list[i] = SvIV(ST(i));
			glDrawBuffersARB(items, list);
			free(list);
		}
	}

#endif // GL_ARB_draw_buffers


#ifdef GL_VERSION_3_0

#//# glIsRenderbuffer(renderbuffer);
GLboolean
glIsRenderbuffer(renderbuffer)
	GLuint	renderbuffer
	CODE:
	{
		RETVAL = glIsRenderbuffer(renderbuffer);
	}
	OUTPUT:
		RETVAL

#//# glBindRenderbuffer(target,renderbuffer);
void
glBindRenderbuffer(target,renderbuffer)
	GLenum target
	GLuint renderbuffer
	CODE:
	{
		glBindRenderbuffer(target,renderbuffer);
	}

#//# glDeleteRenderbuffers_c($n,(CPTR)renderbuffers);
void
glDeleteRenderbuffers_c(n,renderbuffers)
	GLsizei n
	void *	renderbuffers
	CODE:
	{
		glDeleteRenderbuffers(n,renderbuffers);
	}

#//# glDeleteRenderbuffers_s($n,(PACKED)renderbuffers);
void
glDeleteRenderbuffers_s(n,renderbuffers)
	GLsizei n
	SV *	renderbuffers
	CODE:
	{
		void * renderbuffers_s = EL(renderbuffers, sizeof(GLuint)*n);
		glDeleteRenderbuffers(n,renderbuffers_s);
	}

#//# glDeleteRenderbuffers_p(@renderbuffers);
void
glDeleteRenderbuffers_p(...)
	CODE:
	{
		if (items) {
			GLuint * list = malloc(sizeof(GLuint) * items);
			int i;

			for (i=0;i<items;i++)
				list[i] = SvIV(ST(i));

			glDeleteRenderbuffers(items, list);
			free(list);
		}
	}

#//# glGenRenderbuffers_c($n,(CPTR)renderbuffers);
void
glGenRenderbuffers_c(n,renderbuffers)
	GLsizei n
	void *	renderbuffers
	CODE:
	{
		glGenRenderbuffers(n, renderbuffers);
	}

#//# glGenRenderbuffers_s($n,(PACKED)renderbuffers);
void
glGenRenderbuffers_s(n,renderbuffers)
	GLsizei n
	SV *	renderbuffers
	CODE:
	{
		void * renderbuffers_s = EL(renderbuffers, sizeof(GLuint)*n);
		glGenRenderbuffers(n, renderbuffers_s);
	}

#//# @renderbuffers = glGenRenderbuffers_c($n);
void
glGenRenderbuffers_p(n)
	GLsizei n
	PPCODE:
	if (n)
	{
		GLuint * renderbuffers = malloc(sizeof(GLuint) * n);
		int i;

		glGenRenderbuffers(n, renderbuffers);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(renderbuffers[i])));

		free(renderbuffers);
	}

#//# glRenderbufferStorage($target,$internalformat,$width,$height);
void
glRenderbufferStorage(target,internalformat,width,height)
	GLenum	target
	GLenum	internalformat
	GLsizei	width
	GLsizei	height
	CODE:
	{
		glRenderbufferStorage(target,internalformat,width,height);
	}

#//# glGetRenderbufferParameteriv_s($target,$pname,(PACKED)params);
void
glGetRenderbufferParameteriv_s(target,pname,params)
	GLenum	target
	GLenum	pname
		SV *	params
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint));
		glGetRenderbufferParameteriv(target,pname,params_s);
	}

#//# glGetRenderbufferParameteriv_c($target,$pname,(CPTR)params);
void
glGetRenderbufferParameteriv_c(target,pname,params)
	GLenum	target
	GLenum	pname
		void *	params
	CODE:
	{
		glGetRenderbufferParameteriv(target,pname,params);
	}

#//# glIsFramebuffer($framebuffer);
GLboolean
glIsFramebuffer(framebuffer)
	GLuint framebuffer
	CODE:
	{
		RETVAL = glIsFramebuffer(framebuffer);
	}
	OUTPUT:
		RETVAL

#//# glBindFramebuffer($target,$framebuffer);
void
glBindFramebuffer(target,framebuffer)
	GLenum target
	GLuint framebuffer
	CODE:
	{
		glBindFramebuffer(target,framebuffer);
	}

#//# glDeleteFramebuffers_c($n,(CPTR)framebuffers);
void
glDeleteFramebuffers_c(n,framebuffers)
	GLsizei n
	void *	framebuffers
	CODE:
	{
		glDeleteFramebuffers(n,framebuffers);
	}

#//# glDeleteFramebuffers_s($n,(PACKED)framebuffers);
void
glDeleteFramebuffers_s(n,framebuffers)
	GLsizei n
	SV *	framebuffers
	CODE:
	{
		void * framebuffers_s = EL(framebuffers, sizeof(GLuint)*n);
		glDeleteFramebuffers(n,framebuffers_s);
	}

#//# glDeleteFramebuffers_p(@framebuffers);
void
glDeleteFramebuffers_p(...)
	CODE:
	{
		if (items) {
			GLuint * list = malloc(sizeof(GLuint) * items);
			int i;

			for(i=0;i<items;i++)
				list[i] = SvIV(ST(i));

			glDeleteFramebuffers(items, list);
			free(list);
		}
	}

#//# glGenFramebuffers_c($n,(CPTR)framebuffers);
void
glGenFramebuffers_c(n,framebuffers)
	GLsizei n
	void *	framebuffers
	CODE:
	{
		glGenFramebuffers(n,framebuffers);
	}

#//# glGenFramebuffers_s($n,(PACKED)framebuffers);
void
glGenFramebuffers_s(n,framebuffers)
	GLsizei n
	SV *	framebuffers
	CODE:
	{
		void * framebuffers_s = EL(framebuffers, sizeof(GLuint)*n);
		glGenFramebuffers(n,framebuffers_s);
	}

#//# @framebuffers = glGenFramebuffers_c($n);
void
glGenFramebuffers_p(n)
	GLsizei n
	PPCODE:
	if (n)
	{
		GLuint * framebuffers = malloc(sizeof(GLuint) * n);
		int i;

		glGenFramebuffers(n, framebuffers);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(framebuffers[i])));

		free(framebuffers);
	}

#//# glCheckFramebufferStatus($target);
GLenum
glCheckFramebufferStatus(target)
	GLenum target
	CODE:
	{
		RETVAL = glCheckFramebufferStatus(target);
	}
	OUTPUT:
		RETVAL

#//# glFramebufferTexture1D($target,$attachment,$textarget,$texture,$level);
void
glFramebufferTexture1D(target,attachment,textarget,texture,level)
	GLenum target
	GLenum attachment
	GLenum textarget
	GLuint texture
	GLint level
	CODE:
	{
		glFramebufferTexture1D(target,attachment,textarget,texture,level);
	}

#//# glFramebufferTexture2D($target,$attachment,$textarget,$texture,$level);
void
glFramebufferTexture2D(target,attachment,textarget,texture,level)
	GLenum target
	GLenum attachment
	GLenum textarget
	GLuint texture
	GLint level
	CODE:
	{
		glFramebufferTexture2D(target,attachment,textarget,texture,level);
	}

#//# glFramebufferTexture3D($target,$attachment,$textarget,$texture,$level,$zoffset)'
void
glFramebufferTexture3D(target,attachment,textarget,texture,level,zoffset)
	GLenum target
	GLenum attachment
	GLenum textarget
	GLuint texture
	GLint level
	GLint zoffset
	CODE:
	{
		glFramebufferTexture3D(target,attachment,textarget,texture,level,zoffset);
	}

#//# glFramebufferRenderbuffer($target,$attachment,$renderbuffertarget,$renderbuffer);
void
glFramebufferRenderbuffer(target,attachment,renderbuffertarget,renderbuffer)
	GLenum target
	GLenum attachment
	GLenum renderbuffertarget
	GLuint renderbuffer
	CODE:
	{
		glFramebufferRenderbuffer(target,attachment,renderbuffertarget,renderbuffer);
	}

#//# glGetFramebufferAttachmentParameteriv_s($target,$attachment,$pname,(PACKED)params);
void
glGetFramebufferAttachmentParameteriv_s(target,attachment,pname,params)
	GLenum	target
	GLenum	attachment
	GLenum	pname
		SV *	params
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint));
		glGetFramebufferAttachmentParameteriv(target,attachment,pname,params_s);
	}

#//# glGetFramebufferAttachmentParameteriv_c($target,$attachment,$pname,(CPTR)params);
void
glGetFramebufferAttachmentParameteriv_c(target,attachment,pname,params)
	GLenum	target
	GLenum	attachment
	GLenum	pname
		void *	params
	CODE:
	{
		glGetFramebufferAttachmentParameteriv(target,attachment,pname,params);
	}

#//# glGenerateMipmap($target);
void
glGenerateMipmap(target)
	GLenum target
	CODE:
	{
		glGenerateMipmap(target);
	}

#endif // GL_VERSION_3_0


#ifdef GL_EXT_framebuffer_object

#//# glIsRenderbufferEXT(renderbuffer);
GLboolean
glIsRenderbufferEXT(renderbuffer)
	GLuint	renderbuffer
	INIT:
		loadProc(glIsRenderbufferEXT,"glIsRenderbufferEXT");
	CODE:
	{
		RETVAL = glIsRenderbufferEXT(renderbuffer);
	}
	OUTPUT:
		RETVAL

#//# glBindRenderbufferEXT(target,renderbuffer);
void
glBindRenderbufferEXT(target,renderbuffer)
	GLenum target
	GLuint renderbuffer
	INIT:
		loadProc(glBindRenderbufferEXT,"glBindRenderbufferEXT");
	CODE:
	{
		glBindRenderbufferEXT(target,renderbuffer);
	}

#//# glDeleteRenderbuffersEXT_c($n,(CPTR)renderbuffers);
void
glDeleteRenderbuffersEXT_c(n,renderbuffers)
	GLsizei n
	void *	renderbuffers
	INIT:
		loadProc(glDeleteRenderbuffersEXT,"glDeleteRenderbuffersEXT");
	CODE:
	{
		glDeleteRenderbuffersEXT(n,renderbuffers);
	}

#//# glDeleteRenderbuffersEXT_s($n,(PACKED)renderbuffers);
void
glDeleteRenderbuffersEXT_s(n,renderbuffers)
	GLsizei n
	SV *	renderbuffers
	INIT:
		loadProc(glDeleteRenderbuffersEXT,"glDeleteRenderbuffersEXT");
	CODE:
	{
		void * renderbuffers_s = EL(renderbuffers, sizeof(GLuint)*n);
		glDeleteRenderbuffersEXT(n,renderbuffers_s);
	}

#//# glDeleteRenderbuffersEXT_p(@renderbuffers);
void
glDeleteRenderbuffersEXT_p(...)
	INIT:
		loadProc(glDeleteRenderbuffersEXT,"glDeleteRenderbuffersEXT");
	CODE:
	{
		if (items) {
			GLuint * list = malloc(sizeof(GLuint) * items);
			int i;

			for (i=0;i<items;i++)
				list[i] = SvIV(ST(i));

			glDeleteRenderbuffersEXT(items, list);
			free(list);
		}
	}

#//# glGenRenderbuffersEXT_c($n,(CPTR)renderbuffers);
void
glGenRenderbuffersEXT_c(n,renderbuffers)
	GLsizei n
	void *	renderbuffers
	INIT:
		loadProc(glGenRenderbuffersEXT,"glGenRenderbuffersEXT");
	CODE:
	{
		glGenRenderbuffersEXT(n, renderbuffers);
	}

#//# glGenRenderbuffersEXT_s($n,(PACKED)renderbuffers);
void
glGenRenderbuffersEXT_s(n,renderbuffers)
	GLsizei n
	SV *	renderbuffers
	INIT:
		loadProc(glGenRenderbuffersEXT,"glGenRenderbuffersEXT");
	CODE:
	{
		void * renderbuffers_s = EL(renderbuffers, sizeof(GLuint)*n);
		glGenRenderbuffersEXT(n, renderbuffers_s);
	}

#//# @renderbuffers = glGenRenderbuffersEXT_c($n);
void
glGenRenderbuffersEXT_p(n)
	GLsizei n
	INIT:
		loadProc(glGenRenderbuffersEXT,"glGenRenderbuffersEXT");
	PPCODE:
	if (n)
	{
		GLuint * renderbuffers = malloc(sizeof(GLuint) * n);
		int i;

		glGenRenderbuffersEXT(n, renderbuffers);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(renderbuffers[i])));

		free(renderbuffers);
	} 

#//# glRenderbufferStorageEXT($target,$internalformat,$width,$height);
void
glRenderbufferStorageEXT(target,internalformat,width,height)
	GLenum	target
	GLenum	internalformat
	GLsizei	width
	GLsizei	height
	INIT:
		loadProc(glRenderbufferStorageEXT,"glRenderbufferStorageEXT");
	CODE:
	{
		glRenderbufferStorageEXT(target,internalformat,width,height);
	}

#//# glGetRenderbufferParameterivEXT_s($target,$pname,(PACKED)params);
void
glGetRenderbufferParameterivEXT_s(target,pname,params)
	GLenum	target
	GLenum	pname
        SV *	params
	INIT:
		loadProc(glGetRenderbufferParameterivEXT,"glGetRenderbufferParameterivEXT");
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint));
		glGetRenderbufferParameterivEXT(target,pname,params_s);
        }

#//# glGetRenderbufferParameterivEXT_c($target,$pname,(CPTR)params);
void
glGetRenderbufferParameterivEXT_c(target,pname,params)
	GLenum	target
	GLenum	pname
        void *	params
	INIT:
		loadProc(glGetRenderbufferParameterivEXT,"glGetRenderbufferParameterivEXT");
	CODE:
	{
		glGetRenderbufferParameterivEXT(target,pname,params);
        }

#//# glIsFramebufferEXT($framebuffer);
GLboolean
glIsFramebufferEXT(framebuffer)
	GLuint framebuffer
	INIT:
		loadProc(glIsFramebufferEXT,"glIsFramebufferEXT");
	CODE:
	{
		RETVAL = glIsFramebufferEXT(framebuffer);
        }
	OUTPUT:
		RETVAL

#//# glBindFramebufferEXT($target,$framebuffer);
void
glBindFramebufferEXT(target,framebuffer)
	GLenum target
	GLuint framebuffer
	INIT:
		loadProc(glBindFramebufferEXT,"glBindFramebufferEXT");
	CODE:
	{
		glBindFramebufferEXT(target,framebuffer);
        }

#//# glDeleteFramebuffersEXT_c($n,(CPTR)framebuffers);
void
glDeleteFramebuffersEXT_c(n,framebuffers)
	GLsizei n
	void *	framebuffers
	INIT:
		loadProc(glDeleteFramebuffersEXT,"glDeleteFramebuffersEXT");
	CODE:
	{
		glDeleteFramebuffersEXT(n,framebuffers);
	}

#//# glDeleteFramebuffersEXT_s($n,(PACKED)framebuffers);
void
glDeleteFramebuffersEXT_s(n,framebuffers)
	GLsizei n
	SV *	framebuffers
	INIT:
		loadProc(glDeleteFramebuffersEXT,"glDeleteFramebuffersEXT");
	CODE:
	{
		void * framebuffers_s = EL(framebuffers, sizeof(GLuint)*n);
		glDeleteFramebuffersEXT(n,framebuffers_s);
	}

#//# glDeleteFramebuffersEXT_p(@framebuffers);
void
glDeleteFramebuffersEXT_p(...)
	INIT:
		loadProc(glDeleteFramebuffersEXT,"glDeleteFramebuffersEXT");
	CODE:
	{
		if (items) {
			GLuint * list = malloc(sizeof(GLuint) * items);
			int i;

			for(i=0;i<items;i++)
				list[i] = SvIV(ST(i));
		
			glDeleteFramebuffersEXT(items, list);
			free(list);
		}
	}

#//# glGenFramebuffersEXT_c($n,(CPTR)framebuffers);
void
glGenFramebuffersEXT_c(n,framebuffers)
	GLsizei n
	void *	framebuffers
	INIT:
		loadProc(glGenFramebuffersEXT,"glGenFramebuffersEXT");
	CODE:
	{
		glGenFramebuffersEXT(n,framebuffers);
	}

#//# glGenFramebuffersEXT_s($n,(PACKED)framebuffers);
void
glGenFramebuffersEXT_s(n,framebuffers)
	GLsizei n
	SV *	framebuffers
	INIT:
		loadProc(glGenFramebuffersEXT,"glGenFramebuffersEXT");
	CODE:
	{
		void * framebuffers_s = EL(framebuffers, sizeof(GLuint)*n);
		glGenFramebuffersEXT(n,framebuffers_s);
	}

#//# @framebuffers = glGenFramebuffersEXT_c($n);
void
glGenFramebuffersEXT_p(n)
	GLsizei n
	INIT:
		loadProc(glGenFramebuffersEXT,"glGenFramebuffersEXT");
	PPCODE:
	if (n)
	{
		GLuint * framebuffers = malloc(sizeof(GLuint) * n);
		int i;
		
		glGenFramebuffersEXT(n, framebuffers);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(framebuffers[i])));

		free(framebuffers);
	} 

#//# glCheckFramebufferStatusEXT($target);
GLenum
glCheckFramebufferStatusEXT(target)
	GLenum target
	INIT:
		loadProc(glCheckFramebufferStatusEXT,"glCheckFramebufferStatusEXT");
	CODE:
	{
		RETVAL = glCheckFramebufferStatusEXT(target);
	}
	OUTPUT:
		RETVAL

#//# glFramebufferTexture1DEXT($target,$attachment,$textarget,$texture,$level);
void
glFramebufferTexture1DEXT(target,attachment,textarget,texture,level)
	GLenum target
	GLenum attachment
	GLenum textarget
	GLuint texture
	GLint level
	INIT:
		loadProc(glFramebufferTexture1DEXT,"glFramebufferTexture1DEXT");
	CODE:
	{
		glFramebufferTexture1DEXT(target,attachment,textarget,texture,level);
	}

#//# glFramebufferTexture2DEXT($target,$attachment,$textarget,$texture,$level);
void
glFramebufferTexture2DEXT(target,attachment,textarget,texture,level)
	GLenum target
	GLenum attachment
	GLenum textarget
	GLuint texture
	GLint level
	INIT:
		loadProc(glFramebufferTexture2DEXT,"glFramebufferTexture2DEXT");
	CODE:
	{
		glFramebufferTexture2DEXT(target,attachment,textarget,texture,level);
	}

#//# glFramebufferTexture3DEXT($target,$attachment,$textarget,$texture,$level,$zoffset)'
void
glFramebufferTexture3DEXT(target,attachment,textarget,texture,level,zoffset)
	GLenum target
	GLenum attachment
	GLenum textarget
	GLuint texture
	GLint level
	GLint zoffset
	INIT:
		loadProc(glFramebufferTexture3DEXT,"glFramebufferTexture3DEXT");
	CODE:
	{
		glFramebufferTexture3DEXT(target,attachment,textarget,texture,level,zoffset);
	}

#//# glFramebufferRenderbufferEXT($target,$attachment,$renderbuffertarget,$renderbuffer);
void
glFramebufferRenderbufferEXT(target,attachment,renderbuffertarget,renderbuffer)
	GLenum target
	GLenum attachment
	GLenum renderbuffertarget
	GLuint renderbuffer
	INIT:
		loadProc(glFramebufferRenderbufferEXT,"glFramebufferRenderbufferEXT");
	CODE:
	{
		glFramebufferRenderbufferEXT(target,attachment,renderbuffertarget,renderbuffer);
	}

#//# glGetFramebufferAttachmentParameterivEXT_s($target,$attachment,$pname,(PACKED)params);
void
glGetFramebufferAttachmentParameterivEXT_s(target,attachment,pname,params)
	GLenum	target
	GLenum	attachment
	GLenum	pname
        SV *	params
	INIT:
		loadProc(glGetFramebufferAttachmentParameterivEXT,"glGetFramebufferAttachmentParameterivEXT");
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint));
		glGetFramebufferAttachmentParameterivEXT(target,attachment,pname,params_s);
        }

#//# glGetFramebufferAttachmentParameterivEXT_c($target,$attachment,$pname,(CPTR)params);
void
glGetFramebufferAttachmentParameterivEXT_c(target,attachment,pname,params)
	GLenum	target
	GLenum	attachment
	GLenum	pname
        void *	params
	INIT:
		loadProc(glGetFramebufferAttachmentParameterivEXT,"glGetFramebufferAttachmentParameterivEXT");
	CODE:
	{
		glGetFramebufferAttachmentParameterivEXT(target,attachment,pname,params);
        }

#//# glGenerateMipmapEXT($target);
void
glGenerateMipmapEXT(target)
	GLenum target
	INIT:
		loadProc(glGenerateMipmapEXT,"glGenerateMipmapEXT");
	CODE:
	{
		glGenerateMipmapEXT(target);
        }

#endif // GL_EXT_framebuffer_object


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
		GLsizeiptrARB size;
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

#endif // HAVE_GL

