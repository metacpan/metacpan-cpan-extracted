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

MODULE = OpenGL::V3	PACKAGE = OpenGL

#ifdef HAVE_GL

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

#//# @vertex_arrays = glGenVertexArrays_p($n);
void
glGenVertexArrays_p(n)
       GLsizei n
       INIT:
               loadProc(glGenVertexArrays,"glGenVertexArrays");
       PPCODE:
       if (n)
       {
               GLuint * vertex_arrays = malloc(sizeof(GLuint) * n);
               int i;

               glGenVertexArrays(n, vertex_arrays);

               EXTEND(sp, n);
               for(i=0;i<n;i++)
                       PUSHs(sv_2mortal(newSViv(vertex_arrays[i])));

               free(vertex_arrays);
       }

#//# glBindVertexArray(vertex_array);
void
glBindVertexArray(vertex_array)
       GLuint vertex_array
       INIT:
               loadProc(glBindVertexArray,"glBindVertexArray");
       CODE:
       {
               glBindVertexArray(vertex_array);
       }

#//# glDeleteVertexArrays_p(@renderbuffers);
void
glDeleteVertexArrays_p(...)
	INIT:
		loadProc(glDeleteVertexArrays,"glDeleteVertexArrays");
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

#endif // GL_VERSION_3_0

#ifdef GL_VERSION_3_2

#//# glDrawElementsBaseVertex_c($mode, $count, $type, (CPTR)indices, $basevertex);
void
glDrawElementsBaseVertex_c(mode, count, type, indices, basevertex)
	GLenum	mode
	GLint	count
	GLenum	type
	void *	indices
	GLint	basevertex
	INIT:
		loadProc(glDrawElementsBaseVertex,"glDrawElementsBaseVertex");
	CODE:
		glDrawElementsBaseVertex(mode, count, type, indices, basevertex);

#endif // GL_VERSION_3_2

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

#ifdef GL_ARB_color_buffer_float

#//# glClampColorARB($target,$clamp);
void
glClampColorARB(target,clamp)
	GLenum target
	GLenum clamp
	INIT:
		loadProc(glClampColorARB,"glClampColorARB");
	CODE:
	{
		glClampColorARB(target,clamp);
	}

#endif

#endif /* HAVE_GL */
