/*  Last saved: Sun 06 Sep 2009 02:09:59 PM */

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





MODULE = OpenGL::GL::MultProg	PACKAGE = OpenGL





#ifdef HAVE_GL


#ifdef GL_ARB_shader_objects

#//# glDeleteObjectARB($obj);
void
glDeleteObjectARB(obj)
	GLhandleARB	obj
	INIT:
		loadProc(glDeleteObjectARB,"glDeleteObjectARB");
	CODE:
	{
		glDeleteObjectARB(obj);
	}

#//# glGetHandleARB($pname);
GLhandleARB
glGetHandleARB(pname)
	GLenum	pname
	INIT:
		loadProc(glGetHandleARB,"glGetHandleARB");
	CODE:
	{
		RETVAL = glGetHandleARB(pname);
	}
	OUTPUT:
		RETVAL

#//# glDetachObjectARB($containerObj, $attachedObj);
void
glDetachObjectARB(containerObj, attachedObj)
	GLhandleARB containerObj
	GLhandleARB attachedObj
	INIT:
		loadProc(glDetachObjectARB,"glDetachObjectARB");
	CODE:
	{
		glDetachObjectARB(containerObj, attachedObj);
	}

#//# glCreateShaderObjectARB($shaderType);
GLhandleARB
glCreateShaderObjectARB(shaderType)
	GLenum shaderType
	INIT:
		loadProc(glCreateShaderObjectARB,"glCreateShaderObjectARB");
	CODE:
	{
		RETVAL = glCreateShaderObjectARB(shaderType);
	}
	OUTPUT:
		RETVAL

#//# glShaderSourceARB_c($shaderObj, $count, (CPTR)string, (CPTR)length);
void
glShaderSourceARB_c(shaderObj, count, string, length)
	GLhandleARB shaderObj
	GLsizei count
	void	*string
	void	*length
	INIT:
		loadProc(glShaderSourceARB,"glShaderSourceARB");
	CODE:
	{
		glShaderSourceARB(shaderObj, count, string, length);
	}

#//# glShaderSourceARB_p($shaderObj, @string);
void
glShaderSourceARB_p(shaderObj, ...)
	GLhandleARB shaderObj
	INIT:
		loadProc(glShaderSourceARB,"glShaderSourceARB");
	CODE:
	{
		int i;
		int count = items - 1;
		GLcharARB **string = malloc(sizeof(GLcharARB *) * count);
		GLint *length = malloc(sizeof(GLint) * count);

		for(i=0;i<count;i++) {
			string[i] = (GLcharARB *)SvPV(ST(i+1),PL_na);
			length[i] = strlen(string[i]);
		}

		glShaderSourceARB(shaderObj, count, (const GLcharARB**)string,
			(const GLint *)length);

		free(length);
                free(string);
	}

#//# glCompileShaderARB($shaderObj);
void
glCompileShaderARB(shaderObj)
	GLhandleARB shaderObj
	INIT:
		loadProc(glCompileShaderARB,"glCompileShaderARB");
	CODE:
	{
		glCompileShaderARB(shaderObj);
	}

#//# $obj = glCreateProgramObjectARB();
GLhandleARB
glCreateProgramObjectARB()
	INIT:
		loadProc(glCreateProgramObjectARB,"glCreateProgramObjectARB");
	CODE:
	{
		RETVAL = glCreateProgramObjectARB();
	}
	OUTPUT:
		RETVAL

#//# glAttachObjectARB($containerObj, $obj);
void
glAttachObjectARB(containerObj, obj)
	GLhandleARB containerObj
	GLhandleARB obj
	INIT:
		loadProc(glAttachObjectARB,"glAttachObjectARB");
	CODE:
	{
		glAttachObjectARB(containerObj, obj);
	}

#//# glLinkProgramARB($programObj);
void
glLinkProgramARB(programObj)
	GLhandleARB programObj
	INIT:
		loadProc(glLinkProgramARB,"glLinkProgramARB");
	CODE:
	{
		glLinkProgramARB(programObj);
	}

#//# glUseProgramObjectARB($programObj);
void
glUseProgramObjectARB(programObj)
	GLhandleARB programObj
	INIT:
		loadProc(glUseProgramObjectARB,"glUseProgramObjectARB");
	CODE:
	{
		glUseProgramObjectARB(programObj);
	}

#//# glValidateProgramARB($programObj);
void
glValidateProgramARB(programObj)
	GLhandleARB programObj
	INIT:
		loadProc(glValidateProgramARB,"glValidateProgramARB");
	CODE:
	{
		glValidateProgramARB(programObj);
	}

#//# glUniform1fARB($location, $v0);
void
glUniform1fARB(location, v0)
	GLint location
	GLfloat v0
	INIT:
		loadProc(glUniform1fARB,"glUniform1fARB");
	CODE:
	{
		glUniform1fARB(location, v0);
	}

#//# glUniform2fARB($location, $v0, $v1);
void
glUniform2fARB(location, v0, v1)
	GLint location
	GLfloat v0
	GLfloat v1
	INIT:
		loadProc(glUniform2fARB,"glUniform2fARB");
	CODE:
	{
		glUniform2fARB(location, v0, v1);
	}

#//# glUniform3fARB($location, $v0, $v1, $v2);
void
glUniform3fARB(location, v0, v1, v2)
	GLint location
	GLfloat v0
	GLfloat v1
	GLfloat v2
	INIT:
		loadProc(glUniform3fARB,"glUniform3fARB");
	CODE:
	{
		glUniform3fARB(location, v0, v1, v2);
	}

#//# glUniform4fARB($location, $v0, $v1, $v2, $v3);
void
glUniform4fARB(location, v0, v1, v2, v3)
	GLint location
	GLfloat v0
	GLfloat v1
	GLfloat v2
	GLfloat v3
	INIT:
		loadProc(glUniform4fARB,"glUniform4fARB");
	CODE:
	{
		glUniform4fARB(location, v0, v1, v2, v3);
	}

#//# glUniform1iARB($location, $v0);
void
glUniform1iARB(location, v0)
	GLint location
	GLint v0
	INIT:
		loadProc(glUniform1iARB,"glUniform1iARB");
	CODE:
	{
		glUniform1iARB(location, v0);
	}

#//# glUniform2iARB($location, $v0, $v1);
void
glUniform2iARB(location, v0, v1)
	GLint location
	GLint v0
	GLint v1
	INIT:
		loadProc(glUniform2iARB,"glUniform2iARB");
	CODE:
	{
		glUniform2iARB(location, v0, v1);
	}

#//# glUniform3iARB($location, $v0, $v1, $v2);
void
glUniform3iARB(location, v0, v1, v2)
	GLint location
	GLint v0
	GLint v1
	GLint v2
	INIT:
		loadProc(glUniform3iARB,"glUniform3iARB");
	CODE:
	{
		glUniform3iARB(location, v0, v1, v2);
	}

#//# glUniform4iARB($location, $v0, $v1, $v2, $v3);
void
glUniform4iARB(location, v0, v1, v2, v3)
	GLint location
	GLint v0
	GLint v1
	GLint v2
	GLint v3
	INIT:
		loadProc(glUniform4iARB,"glUniform4iARB");
	CODE:
	{
		glUniform4iARB(location, v0, v1, v2, v3);
	}

#//# glUniform1fvARB_c($location, $count, (CPTR)value);
void
glUniform1fvARB_c(location, count, value)
	GLint	location
	GLsizei	count
	void	*value
	INIT:
		loadProc(glUniform1fvARB,"glUniform1fvARB");
	CODE:
		glUniform1fvARB(location, count, value);

#//# glUniform1fvARB_s($location, $count, (PACKED)value);
void
glUniform1fvARB_s(location, count, value)
	GLint	location
	GLsizei count
	SV	*value
	INIT:
		loadProc(glUniform1fvARB,"glUniform1fvARB");
	CODE:
	{
		GLfloat * value_s = EL(value, sizeof(GLfloat));
		glUniform1fvARB(location, count, value_s);
	}

#//# glUniform1fvARB_p(location, @value);
void
glUniform1fvARB_p(location, ...)
	GLint location
	INIT:
		loadProc(glUniform1fvARB,"glUniform1fvARB");
	CODE:
	{
		int i;
		GLsizei count = items - 1;
		GLfloat *value = malloc(sizeof(GLfloat) * count);

		for(i=0;i<count;i++) {
			value[i] = (GLfloat)SvNV(ST(i+1));
		}

		glUniform1fvARB(location, count, value);

		free(value);
	}

#//# glUniform2fvARB_c($location, $count, (CPTR)value);
void
glUniform2fvARB_c(location, count, value)
	GLint	location
	GLsizei	count
	void	*value
	INIT:
		loadProc(glUniform2fvARB,"glUniform2fvARB");
	CODE:
		glUniform2fvARB(location, count, value);

#//# glUniform2fvARB_s($location, $count, (PACKED)value);
void
glUniform2fvARB_s(location, count, value)
	GLint	location
	GLsizei	count
	SV	*value
	INIT:
		loadProc(glUniform2fvARB,"glUniform2fvARB");
	CODE:
	{
		GLfloat * value_s = EL(value, sizeof(GLfloat));
		glUniform2fvARB(location, count, value_s);
	}

#//# glUniform2fvARB_p($location, @value);
void
glUniform2fvARB_p(location, ...)
	GLint location
	INIT:
		loadProc(glUniform2fvARB,"glUniform2fvARB");
	CODE:
	{
		int i;
		GLsizei elements = items - 1;
		GLsizei count = elements >> 1;
		GLfloat *value = malloc(sizeof(GLfloat) * elements);

		for(i=0;i<elements;i++) {
			value[i] = (GLfloat)SvNV(ST(i+1));
		}

		glUniform2fvARB(location, count, value);

		free(value);
	}

#//# glUniform3fvARB_c($location, $count, (CPTR)value);
void
glUniform3fvARB_c(location, count, value)
	GLint	location
	GLsizei	count
	void	*value
	INIT:
		loadProc(glUniform3fvARB,"glUniform3fvARB");
	CODE:
		glUniform3fvARB(location, count, value);

#//# glUniform3fvARB_s($location, $count, (PACKED)value);
void
glUniform3fvARB_s(location, count, value)
	GLint	location
	GLsizei	count
	SV	*value
	INIT:
		loadProc(glUniform3fvARB,"glUniform3fvARB");
	CODE:
	{
		GLfloat * value_s = EL(value, sizeof(GLfloat));
		glUniform3fvARB(location, count, value_s);
	}

#//# glUniform3fvARB_p($location, @value);
void
glUniform3fvARB_p(location, ...)
	GLint location
	INIT:
		loadProc(glUniform3fvARB,"glUniform3fvARB");
	CODE:
	{
		int i;
		GLsizei elements = items - 1;
		GLsizei count = elements / 3;
		GLfloat *value = malloc(sizeof(GLfloat) * elements);

		for(i=0;i<elements;i++) {
			value[i] = (GLfloat)SvNV(ST(i+1));
		}

		glUniform3fvARB(location, count, value);

		free(value);
	}

#//# glUniform4fvARB_c($location, $count, (CPTR)value);
void
glUniform4fvARB_c(location, count, value)
	GLint	location
	GLsizei	count
	void	*value
	INIT:
		loadProc(glUniform4fvARB,"glUniform4fvARB");
	CODE:
		glUniform4fvARB(location, count, value);

#//# glUniform4fvARB_s($location, $count, (PACKED)value);
void
glUniform4fvARB_s(location, count, value)
	GLint	location
	GLsizei	count
	SV	*value
	INIT:
		loadProc(glUniform4fvARB,"glUniform4fvARB");
	CODE:
	{
		GLfloat * value_s = EL(value, sizeof(GLfloat));
		glUniform4fvARB(location, count, value_s);
	}

#//# glUniform4fvARB_p($location, @value);
void
glUniform4fvARB_p(location, ...)
	GLint location
	INIT:
		loadProc(glUniform4fvARB,"glUniform4fvARB");
	CODE:
	{
		int i;
		GLsizei elements = items - 1;
		GLsizei count = elements >> 2;
		GLfloat *value = malloc(sizeof(GLfloat) * elements);

		for(i=0;i<elements;i++) {
			value[i] = (GLfloat)SvNV(ST(i+1));
		}

		glUniform4fvARB(location, count, value);

		free(value);
	}

#//# glUniform1ivARB_c($location, $count, (CPTR)value);
void
glUniform1ivARB_c(location, count, value)
	GLint	location
	GLsizei	count
	void	*value
	INIT:
		loadProc(glUniform1ivARB,"glUniform1ivARB");
	CODE:
		glUniform1ivARB(location, count, value);

#//# glUniform1ivARB_s($location, $count, (PACKED)value);
void
glUniform1ivARB_s(location, count, value)
	GLint	location
	GLsizei	count
	SV	*value
	INIT:
		loadProc(glUniform1ivARB,"glUniform1ivARB");
	CODE:
	{
		GLint * value_s = EL(value, sizeof(GLint));
		glUniform1ivARB(location, count, value_s);
	}

#//# glUniform1ivARB_p($location, @value);
void
glUniform1ivARB_p(location, ...)
	GLint location
	INIT:
		loadProc(glUniform1ivARB,"glUniform1ivARB");
	CODE:
	{
		int i;
		GLsizei count = items - 1;
		GLint *value = malloc(sizeof(GLint) * count);

		for(i=0;i<count;i++) {
			value[i] = SvIV(ST(i+1));
		}

		glUniform1ivARB(location, count, value);

		free(value);
	}

#//# glUniform2ivARB_c($location, $count, (CPTR)value);
void
glUniform2ivARB_c(location, count, value)
	GLint	location
	GLsizei	count
	void	*value
	INIT:
		loadProc(glUniform2ivARB,"glUniform2ivARB");
	CODE:
		glUniform2ivARB(location, count, value);

#//# glUniform2ivARB_s($location, $count, (PACKED)value);
void
glUniform2ivARB_s(location, count, value)
	GLint	location
	GLsizei	count
	SV	*value
	INIT:
		loadProc(glUniform2ivARB,"glUniform2ivARB");
	CODE:
	{
		GLint * value_s = EL(value, sizeof(GLint));
		glUniform2ivARB(location, count, value_s);
	}

#//# glUniform2ivARB_p($location, @value);
void
glUniform2ivARB_p(location, ...)
	GLint location
	INIT:
		loadProc(glUniform2ivARB,"glUniform2ivARB");
	CODE:
	{
		int i;
		GLsizei elements = items - 1;
		GLsizei count = elements >> 1;
		GLint *value = malloc(sizeof(GLint) * elements);

		for(i=0;i<elements;i++) {
			value[i] = SvIV(ST(i+1));
		}

		glUniform2ivARB(location, count, value);

		free(value);
	}

#//# glUniform3ivARB_c($location, $count, (CPTR)value);
void
glUniform3ivARB_c(location, count, value)
	GLint	location
	GLsizei	count
	void	*value
	INIT:
		loadProc(glUniform3ivARB,"glUniform3ivARB");
	CODE:
		glUniform3ivARB(location, count, value);

#//# glUniform3ivARB_s($location, $count, (PACKED)value);
void
glUniform3ivARB_s(location, count, value)
	GLint	location
	GLsizei	count
	SV	*value
	INIT:
		loadProc(glUniform3ivARB,"glUniform3ivARB");
	CODE:
	{
		GLint * value_s = EL(value, sizeof(GLint));
		glUniform3ivARB(location, count, value_s);
	}

#//# glUniform3ivARB_p($location, @value);
void
glUniform3ivARB_p(location, ...)
	GLint location
	INIT:
		loadProc(glUniform3ivARB,"glUniform3ivARB");
	CODE:
	{
		int i;
		GLsizei elements = items - 1;
		GLsizei count = elements / 3;
		GLint *value = malloc(sizeof(GLint) * elements);

		for(i=0;i<elements;i++) {
			value[i] = SvIV(ST(i+1));
		}

		glUniform3ivARB(location, count, value);

		free(value);
	}

#//# glUniform4ivARB_c($location, $count, (CPTR)value);
void
glUniform4ivARB_c(location, count, value)
	GLint	location
	GLsizei	count
	void	*value
	INIT:
		loadProc(glUniform4ivARB,"glUniform4ivARB");
	CODE:
		glUniform4ivARB(location, count, value);

#//# glUniform4ivARB_s($location, $count, (PACKED)value);
void
glUniform4ivARB_s(location, count, value)
	GLint	location
	GLsizei	count
	SV	*value
	INIT:
		loadProc(glUniform4ivARB,"glUniformifvARB");
	CODE:
	{
		GLint * value_s = EL(value, sizeof(GLint));
		glUniform4ivARB(location, count, value_s);
	}

#//# glUniform4ivARB_p($location, @value);
void
glUniform4ivARB_p(location, ...)
	GLint location
	INIT:
		loadProc(glUniform4ivARB,"glUniform4ivARB");
	CODE:
	{
		int i;
		GLsizei elements = items - 1;
		GLsizei count = elements >> 2;
		GLint *value = malloc(sizeof(GLint) * elements);

		for(i=0;i<elements;i++) {
			value[i] = SvIV(ST(i+1));
		}

		glUniform4ivARB(location, count, value);

		free(value);
	}

#//# glUniformMatrix2fvARB_c($location, $count, $transpose, (CPTR)value);
void
glUniformMatrix2fvARB_c(location, count, transpose, value)
	GLint	location
	GLsizei	count
	GLboolean transpose
	void	*value
	INIT:
		loadProc(glUniformMatrix2fvARB,"glUniformMatrix2fvARB");
	CODE:
		glUniformMatrix2fvARB(location, count, transpose, value);

#//# glUniformMatrix2fvARB_s($location, $count, $transpose, (PACKED)value);
void
glUniformMatrix2fvARB_s(location, count, transpose, value)
	GLint	location
	GLsizei	count
	GLboolean transpose
	SV	*value
	INIT:
		loadProc(glUniformMatrix2fvARB,"glUniformMatrix2fvARB");
	CODE:
	{
		GLfloat * value_s = EL(value, sizeof(GLfloat));
		glUniformMatrix2fvARB(location, count, transpose, value_s);
	}

#//# glUniformMatrix2fvARB_p($location, $transpose, @matrix);
void
glUniformMatrix2fvARB_p(location, transpose, ...)
	GLint location
	GLboolean transpose
	INIT:
		loadProc(glUniformMatrix2fvARB,"glUniformMatrix2fvARB");
	CODE:
	{
		int i;
		GLsizei elements = items - 2;
		GLsizei count = elements / 4;
		GLfloat *value = malloc(sizeof(GLfloat) * elements);

		for(i=0;i<elements;i++) {
			value[i] = (GLfloat)SvNV(ST(i+2));
		}

		glUniformMatrix2fvARB(location, count, transpose, value);

		free(value);
	}

#//# glUniformMatrix3fvARB_c($location, $count, $transpose, (CPTR)value);
void
glUniformMatrix3fvARB_c(location, count, transpose, value)
	GLint	location
	GLsizei	count
	GLboolean transpose
	void	*value
	INIT:
		loadProc(glUniformMatrix3fvARB,"glUniformMatrix2fvARB");
	CODE:
		glUniformMatrix3fvARB(location, count, transpose, value);

#//# glUniformMatrix3fvARB_s($location, $count, $transpose, (PACKED)value);
void
glUniformMatrix3fvARB_s(location, count, transpose, value)
	GLint	location
	GLsizei	count
	GLboolean transpose
	SV	*value
	INIT:
		loadProc(glUniformMatrix3fvARB,"glUniformMatrix3fvARB");
	CODE:
	{
		GLfloat * value_s = EL(value, sizeof(GLfloat));
		glUniformMatrix3fvARB(location, count, transpose, value_s);
	}

#//# glUniformMatrix3fvARB_p($location, $transpose, @matrix);
void
glUniformMatrix3fvARB_p(location, transpose, ...)
	GLint location
	GLboolean transpose
	INIT:
		loadProc(glUniformMatrix3fvARB,"glUniformMatrix3fvARB");
	CODE:
	{
		int i;
		GLsizei elements = items - 2;
		GLsizei count = elements / 9;
		GLfloat *value = malloc(sizeof(GLfloat) * elements);

		for(i=0;i<elements;i++) {
			value[i] = (GLfloat)SvNV(ST(i+2));
		}

		glUniformMatrix3fvARB(location, count, transpose, value);

		free(value);
	}

#//# glUniformMatrix4fvARB_c($location, $count, $transpose, (CPTR)value);
void
glUniformMatrix4fvARB_c(location, count, transpose, value)
	GLint	location
	GLsizei	count
	GLboolean transpose
	void	*value
	INIT:
		loadProc(glUniformMatrix4fvARB,"glUniformMatrix4fvARB");
	CODE:
		glUniformMatrix4fvARB(location, count, transpose, value);

#//# glUniformMatrix4fvARB_s($location, $count, $transpose, (PACKED)value);
void
glUniformMatrix4fvARB_s(location, count, transpose, value)
	GLint	location
	GLsizei	count
	GLboolean transpose
	SV	*value
	INIT:
		loadProc(glUniformMatrix4fvARB,"glUniformMatrix4fvARB");
	CODE:
	{
		GLfloat * value_s = EL(value, sizeof(GLfloat));
		glUniformMatrix4fvARB(location, count, transpose, value_s);
	}

#//# glUniformMatrix4fvARB_p($location, $transpose, @matrix);
void
glUniformMatrix4fvARB_p(location, transpose, ...)
	GLint location
	GLboolean transpose
	INIT:
		loadProc(glUniformMatrix4fvARB,"glUniformMatrix4fvARB");
	CODE:
	{
		int i;
		GLsizei elements = items - 2;
		GLsizei count = elements / 16;
		GLfloat *value = malloc(sizeof(GLfloat) * elements);

		for(i=0;i<elements;i++) {
			value[i] = (GLfloat)SvNV(ST(i+2));
		}

		glUniformMatrix4fvARB(location, count, transpose, value);

		free(value);
	}

#//# glGetObjectParameterfvARB_c($obj,$pname,(CPTR)params);
void
glGetObjectParameterfvARB_c(obj,pname,params)
	GLhandleARB obj
	GLenum	pname
	void	*params
	INIT:
		loadProc(glGetObjectParameterfvARB,"glGetObjectParameterfvARB");
	CODE:
		glGetObjectParameterfvARB(obj,pname,params);

#//# glGetObjectParameterfvARB_s($obj,$pname,(PACKED)params);
void
glGetObjectParameterfvARB_s(obj,pname,params)
	GLhandleARB obj
	GLenum	pname
	SV	*params
	INIT:
		loadProc(glGetObjectParameterfvARB,"glGetObjectParameterfvARB");
	CODE:
	{
		GLfloat * params_s = EL(params, sizeof(GLfloat));
		glGetObjectParameterfvARB(obj,pname,params_s);
	}

#//# $param = glGetObjectParameterfvARB_p($obj,$pname);
GLfloat
glGetObjectParameterfvARB_p(obj,pname)
	GLhandleARB obj
	GLenum pname
	INIT:
		loadProc(glGetObjectParameterfvARB,"glGetObjectParameterfvARB");
	CODE:
	{
		GLfloat	ret;
		glGetObjectParameterfvARB(obj,pname,&ret);
		RETVAL = ret;
	}
	OUTPUT:
		RETVAL

#//# glGetObjectParameterivARB_c($obj,$pname,(CPTR)params);
void
glGetObjectParameterivARB_c(obj,pname,params)
	GLhandleARB obj
	GLenum	pname
	void	*params
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
	CODE:
		glGetObjectParameterivARB(obj,pname,params);

#//# glGetObjectParameterivARB_s($obj,$pname,(PACKED)params);
void
glGetObjectParameterivARB_s(obj,pname,params)
	GLhandleARB obj
	GLenum	pname
	SV	*params
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint));
		glGetObjectParameterivARB(obj,pname,params_s);
	}

#//# $param = glGetObjectParameterivARB_c($obj,$pname);
GLint
glGetObjectParameterivARB_p(obj,pname)
	GLhandleARB obj
	GLenum pname
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
	CODE:
	{
		GLint	ret;
		glGetObjectParameterivARB(obj,pname,&ret);
		RETVAL = ret;
	}
	OUTPUT:
		RETVAL

#//# glGetInfoLogARB_c($obj, $maxLength, (CPTR)length, (CPTR)infoLog);
void
glGetInfoLogARB_c(obj, maxLength, length, infoLog)
	GLhandleARB obj
	GLsizei	maxLength
	void	*length
	void	*infoLog
	INIT:
		loadProc(glGetInfoLogARB,"glGetInfoLogARB");
	CODE:
		glGetInfoLogARB(obj, maxLength, length, infoLog);

#//# $infoLog = glGetInfoLogARB_c($obj);
SV *
glGetInfoLogARB_p(obj)
	GLhandleARB obj
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
		loadProc(glGetInfoLogARB,"glGetInfoLogARB");
	CODE:
	{
		GLint maxLength;
		glGetObjectParameterivARB(obj,GL_OBJECT_INFO_LOG_LENGTH_ARB,(GLvoid *)&maxLength);
		if (maxLength)
		{
			GLint length;
			GLcharARB * infoLog = malloc(maxLength+1);
			glGetInfoLogARB(obj,maxLength,&length,infoLog);
			infoLog[length] = 0;
			if (*infoLog)
				RETVAL = newSVpv(infoLog, 0);
			else
				RETVAL = newSVsv(&PL_sv_undef);

			free(infoLog);
		}
		else
		{
			RETVAL = newSVsv(&PL_sv_undef);
		}
	}
	OUTPUT:
		RETVAL

#//# glGetAttachedObjectsARB_c($containerObj, $maxCount, (CPTR)count, (CPTR)obj);
void
glGetAttachedObjectsARB_c(containerObj, maxCount, count, obj)
	GLhandleARB containerObj
	GLsizei	maxCount
	void	*count
	void	*obj
	INIT:
		loadProc(glGetAttachedObjectsARB,"glGetAttachedObjectsARB");
	CODE:
		glGetAttachedObjectsARB(containerObj, maxCount, count, obj);

#//# glGetAttachedObjectsARB_s($containerObj, $maxCount, (PACKED)count, (PACKED)obj);
void
glGetAttachedObjectsARB_s(containerObj, maxCount, count, obj)
	GLhandleARB containerObj
	GLsizei	maxCount
	void	*count
	SV	*obj
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
		loadProc(glGetAttachedObjectsARB,"glGetAttachedObjectsARB");
	CODE:
	{
		GLint len;
		glGetObjectParameterivARB(containerObj,GL_OBJECT_ATTACHED_OBJECTS_ARB,
			(GLvoid *)&len);
		if (len)
		{
			GLsizei * count_s = EL(count, sizeof(GLsizei));
			GLhandleARB * obj_s = EL(obj, sizeof(GLhandleARB)*len);
			glGetAttachedObjectsARB(containerObj, maxCount, count_s, obj_s);
		}
	}

#//# @objs = glGetAttachedObjectsARB_p($containerObj);
void
glGetAttachedObjectsARB_p(containerObj)
	GLhandleARB containerObj
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
		loadProc(glGetAttachedObjectsARB,"glGetAttachedObjectsARB");
	PPCODE:
	{
		GLsizei maxCount;
		GLsizei count;
		GLhandleARB *obj;
		int i;

		glGetObjectParameterivARB(containerObj,GL_OBJECT_ATTACHED_OBJECTS_ARB,
			(GLvoid *)&maxCount);
		obj = malloc(sizeof(GLhandleARB)*maxCount);

		glGetAttachedObjectsARB(containerObj, maxCount, &count, obj);

		EXTEND(sp, count);
		for(i=0;i<count;i++)
			PUSHs(sv_2mortal(newSViv(obj[i])));

		free(obj);
	}

#//# glGetUniformLocationARB_c($programObj, (CPTR)name);
GLint
glGetUniformLocationARB_c(programObj, name)
	GLhandleARB programObj
	void	*name
	INIT:
		loadProc(glGetUniformLocationARB,"glGetUniformLocationARB");
	CODE:
		RETVAL = glGetUniformLocationARB(programObj, name);
	OUTPUT:
		RETVAL

#//# $value = glGetUniformLocationARB_p($programObj, $name);
GLint
glGetUniformLocationARB_p(programObj, ...)
	GLhandleARB programObj
	INIT:
		loadProc(glGetUniformLocationARB,"glGetUniformLocationARB");
	CODE:
	{
		GLcharARB *name = (GLcharARB *)SvPV(ST(1),PL_na);
		RETVAL = glGetUniformLocationARB(programObj, name);
	}
	OUTPUT:
		RETVAL

#//# glGetActiveUniformARB_c($programObj, $index, $maxLength, (CPTR)length, (CPTR)size, (CPTR)type, (CPTR)name);
void
glGetActiveUniformARB_c(programObj, index, maxLength, length, size, type, name)
	GLhandleARB programObj
	GLuint	index
	GLsizei	maxLength
	void	*length
	void	*size
	void	*type
	void	*name
	INIT:
		loadProc(glGetActiveUniformARB,"glGetActiveUniformARB");
	CODE:
		glGetActiveUniformARB(programObj,index,maxLength,length,size,type,name);

#//# glGetActiveUniformARB_s($programObj, $index, $maxLength, (PACKED)length, (PACKED)size, (PACKED)type, (PACKED)name);
void
glGetActiveUniformARB_s(programObj, index, maxLength, length, size, type, name)
	GLhandleARB programObj
	GLuint	index
	GLsizei	maxLength
	SV	*length
	SV	*size
	SV	*type
	SV	*name
	INIT:
		loadProc(glGetActiveUniformARB,"glGetActiveUniformARB");
	CODE:
	{
		GLsizei	  *length_s = EL(length, sizeof(GLsizei));
		GLint	  *size_s = EL(size, sizeof(GLint));
		GLenum	  *type_s = EL(type, sizeof(GLenum));
		GLcharARB *name_s = EL(name, sizeof(GLcharARB));
		glGetActiveUniformARB(programObj,index,maxLength,length_s,size_s,type_s,name_s);
	}

#//# ($name,$type,$size) = glGetActiveUniformARB_p($programObj, $index);
void
glGetActiveUniformARB_p(programObj, index)
	GLhandleARB programObj
	GLuint index
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
		loadProc(glGetActiveUniformARB,"glGetActiveUniformARB");
	PPCODE:
	{
		GLsizei maxLength;
		glGetObjectParameterivARB(programObj,GL_OBJECT_ACTIVE_UNIFORM_MAX_LENGTH_ARB,
			(GLvoid *)&maxLength);
		if (maxLength)
		{
			GLsizei length;
			GLint size;
			GLenum type;
			GLcharARB *name;

			name = malloc(maxLength+1);
			glGetActiveUniformARB(programObj,index,maxLength,
				&length,&size,&type,name);
			name[length] = 0;

			if (*name)
			{
				EXTEND(sp,3);
				PUSHs(sv_2mortal(newSVpv(name,0)));
				PUSHs(sv_2mortal(newSViv(type)));
				PUSHs(sv_2mortal(newSViv(size)));
			}
			else
			{
				EXTEND(sp,1);
				PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
			}

			free(name);
		}
		else
		{
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
		}
	}

#//# glGetUniformfvARB_c($programObj, $location, (CPTR)params);
void
glGetUniformfvARB_c(programObj, location, params)
	GLhandleARB programObj
	GLint	location
	void	*params
	INIT:
		loadProc(glGetUniformfvARB,"glGetUniformfvARB");
	CODE:
		glGetUniformfvARB(programObj, location, params);

#//# @params = glGetUniformfvARB_p($programObj, $location[, $count]);
void
glGetUniformfvARB_p(programObj, location, count=1)
	GLhandleARB programObj
	GLint location
	int count
	INIT:
		loadProc(glGetUniformfvARB,"glGetUniformfvARB");
	CODE:
	{
		int i;
		GLfloat	*ret = malloc(sizeof(GLfloat)*count);
		glGetUniformfvARB(programObj, location, ret);

		for(i=0;i<count;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#//# glGetUniformivARB_c($programObj, $location, (CPTR)params);
void
glGetUniformivARB_c(programObj, location, params)
	GLhandleARB programObj
	GLint	location
	void	*params
	INIT:
		loadProc(glGetUniformivARB,"glGetUniformivARB");
	CODE:
		glGetUniformivARB(programObj, location, params);

#//# @params = glGetUniformivARB_p($programObj, $location[, $count]);
void
glGetUniformivARB_p(programObj, location, count=1)
	GLhandleARB programObj
	GLint	location
	int count
	INIT:
		loadProc(glGetUniformivARB,"glGetUniformivARB");
	CODE:
	{
		int i;
		GLint	*ret = malloc(sizeof(GLint)*count);
		glGetUniformivARB(programObj, location, ret);

		for(i=0;i<count;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#//# glGetShaderSourceARB_c($obj, $maxLength, (CPTR)length, (CPTR)source);
void
glGetShaderSourceARB_c(obj, maxLength, length, source)
	GLhandleARB obj
	GLsizei	maxLength
	void	*length
	void	*source
	INIT:
		loadProc(glGetShaderSourceARB,"glGetShaderSourceARB");
	CODE:
		glGetShaderSourceARB(obj, maxLength, length, source);

#//# $source = glGetShaderSourceARB_p($obj);
void
glGetShaderSourceARB_p(obj)
	GLhandleARB obj
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
		loadProc(glGetShaderSourceARB,"glGetShaderSourceARB");
	PPCODE:
	{
		GLsizei maxLength;
		glGetObjectParameterivARB(obj,GL_OBJECT_SHADER_SOURCE_LENGTH_ARB,
			(GLvoid *)&maxLength);

		EXTEND(sp,1);

		if (maxLength)
		{
			GLsizei length;
			GLcharARB *source;

			source = malloc(maxLength+1);
			glGetShaderSourceARB(obj,maxLength,&length,source);
			source[length] = 0;

			if (*source)
			{
				PUSHs(sv_2mortal(newSVpv(source,0)));
			}
			else
			{
				PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
			}

			free(source);
		}
		else
		{
			PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
		}
	}

#endif // GL_ARB_shader_objects


#ifdef GL_ARB_vertex_program

#//# glProgramStringARB_c($target,$format,$len,(CPTR)string);
void
glProgramStringARB_c(target,format,len,string)
	GLenum target
	GLenum format
	GLsizei len
	void * string
	INIT:
		loadProc(glProgramStringARB,"glProgramStringARB");
	CODE:
		glProgramStringARB(target,format,len,string);

#//# glProgramStringARB_s($target,$format,$len,(PACKED)string);
void
glProgramStringARB_s(target,format,len,string)
	GLenum target
	GLenum format
	GLsizei len
	SV *	string
	INIT:
		loadProc(glProgramStringARB,"glProgramStringARB");
	CODE:
	{
		GLvoid * string_s = EL(string, len);
		glProgramStringARB(target,format,len,string_s);
	}

#//# glProgramStringARB_p($target,$string);
#//- Assumes GL_PROGRAM_FORMAT_ASCII_ARB
void
glProgramStringARB_p(target,string)
	GLenum target
	char * string
	INIT:
		loadProc(glProgramStringARB,"glProgramStringARB");
	CODE:
	{
		int len = strlen(string);
		glProgramStringARB(target,GL_PROGRAM_FORMAT_ASCII_ARB,len,string);
	}

#//# glBindProgramARB($target,$program);
void
glBindProgramARB(target,program)
	GLenum target
	GLuint program
	INIT:
		loadProc(glBindProgramARB,"glBindProgramARB");

#//# glDeleteProgramsARB_c($n,(CPTR)programs);
void
glDeleteProgramsARB_c(n,programs)
	GLsizei n
	void *	programs
	INIT:
		loadProc(glDeleteProgramsARB,"glDeleteProgramsARB");
	CODE:
	{
		glDeleteProgramsARB(n,(GLuint*)programs);
	}

#//# glDeleteProgramsARB_c($n,(PACKED)programs);
void
glDeleteProgramsARB_s(n,programs)
	GLsizei n
	SV *	programs
	INIT:
		loadProc(glDeleteProgramsARB,"glDeleteProgramsARB");
	CODE:
	{
		GLuint * programs_s = EL(programs, sizeof(GLuint)*n);
		glDeleteProgramsARB(n,programs_s);
	}

#//# glDeleteProgramsARB_p(@programIDs);
void
glDeleteProgramsARB_p(...)
	INIT:
		loadProc(glDeleteProgramsARB,"glDeleteProgramsARB");
	CODE:
	{
		if (items) {
			GLuint * list = malloc(sizeof(GLuint) * items);
			int i;

			for (i=0;i<items;i++)
				list[i] = SvIV(ST(i));

			glDeleteProgramsARB(items, list);
			free(list);
		}
	}

#//# glGenProgramsARB_c($n,(CPTR)programs);
void
glGenProgramsARB_c(n,programs)
	GLsizei n
	void *	programs
	INIT:
		loadProc(glGenProgramsARB,"glGenProgramsARB");
	CODE:
	{
		glGenProgramsARB(n,(GLuint*)programs);
	}

#//# glGenProgramsARB_s($n,(PACKED)programs);
void
glGenProgramsARB_s(n,programs)
	GLsizei n
	SV *	programs
	INIT:
		loadProc(glGenProgramsARB,"glGenProgramsARB");
	CODE:
	{
		GLuint * programs_s = EL(programs, sizeof(GLuint)*n);
		glGenProgramsARB(n, programs_s);
	}

#//# @programIDs = glGenProgramsARB_c($n);
void
glGenProgramsARB_p(n)
	GLsizei n
	INIT:
		loadProc(glGenProgramsARB,"glGenProgramsARB");
	PPCODE:
	if (n)
	{
		GLuint * programs = malloc(sizeof(GLuint) * n);
		int i;

		glGenProgramsARB(n, programs);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(programs[i])));

		free(programs);
	} 

#//# glProgramEnvParameter4dARB($target,$index,$x,$y,$z,$w);
void
glProgramEnvParameter4dARB(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLdouble x
	GLdouble y
	GLdouble z
	GLdouble w
	INIT:
		loadProc(glProgramEnvParameter4dARB,"glProgramEnvParameter4dARB");

#//# glProgramEnvParameter4dvARB_c($target,$index,(CPTR)v);
void
glProgramEnvParameter4dvARB_c(target,index,v)
	GLenum target
	GLuint index
	void *	v
	INIT:
		loadProc(glProgramEnvParameter4dvARB,"glProgramEnvParameter4dvARB");
	CODE:
		glProgramEnvParameter4dvARB(target,index,(GLdouble*)v);

#//# glProgramEnvParameter4dvARB_s($target,$index,(PACKED)v);
void
glProgramEnvParameter4dvARB_s(target,index,v)
	GLenum target
	GLuint index
	SV *	v
	INIT:
		loadProc(glProgramEnvParameter4dvARB,"glProgramEnvParameter4dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glProgramEnvParameter4dvARB(target,index,v_s);
	}

#//!!! Do we really need this?  It duplicates glProgramEnvParameter4dARB
#//# glProgramEnvParameter4dvARB_p($target,$index,$x,$y,$z,$w);
void
glProgramEnvParameter4dvARB_p(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w
	INIT:
		loadProc(glProgramEnvParameter4dvARB,"glProgramEnvParameter4dvARB");
	CODE:
	{
		GLdouble param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glProgramEnvParameter4dvARB(target,index,param);
	}

#//# glProgramEnvParameter4fARB($target,$index,$x,$y,$z,$w);
void
glProgramEnvParameter4fARB(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLfloat x
	GLfloat y
	GLfloat z
	GLfloat w
	INIT:
		loadProc(glProgramEnvParameter4fARB,"glProgramEnvParameter4fARB");

#//# glProgramEnvParameter4fvARB_c($target,$index,(CPTR)v);
void
glProgramEnvParameter4fvARB_c(target,index,v)
	GLenum target
	GLuint index
	void *	v
	INIT:
		loadProc(glProgramEnvParameter4fvARB,"glProgramEnvParameter4fvARB");
	CODE:
		glProgramEnvParameter4fvARB(target,index,(GLfloat*)v);

#//# glProgramEnvParameter4fvARB_s($target,$index,(PACKED)v);
void
glProgramEnvParameter4fvARB_s(target,index,v)
	GLenum target
	GLuint index
	SV *	v
	INIT:
		loadProc(glProgramEnvParameter4fvARB,"glProgramEnvParameter4fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glProgramEnvParameter4fvARB(target,index,v_s);
	}

#//!!! Do we really need this?  It duplicates glProgramEnvParameter4fARB
#//# glProgramEnvParameter4fvARB_p($target,$index,$x,$y,$z,$w);
void
glProgramEnvParameter4fvARB_p(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w
	INIT:
		loadProc(glProgramEnvParameter4fvARB,"glProgramEnvParameter4fvARB");
	CODE:
	{
		GLfloat param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glProgramEnvParameter4fvARB(target,index,param);
	}

#endif // GL_ARB_vertex_program
 
 
#endif /* HAVE_GL */

