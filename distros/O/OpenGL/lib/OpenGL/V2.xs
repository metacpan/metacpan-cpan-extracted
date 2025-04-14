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

MODULE = OpenGL::V2	PACKAGE = OpenGL

#ifdef HAVE_GL

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

#//# glAttachShader($program,$shader);
void
glAttachShader(program,shader)
	GLuint	program
	GLuint	shader
	INIT:
		loadProc(glAttachShader,"glAttachShader");
	CODE:
	{
		glAttachShader(program,shader);
	}

#//# glDeleteShader($shader);
void
glDeleteShader(shader)
	GLuint	shader
	INIT:
		loadProc(glDeleteShader,"glDeleteShader");
	CODE:
	{
		glDeleteShader(shader);
	}

#//# $value = glGetShaderiv_p($target,$pname);
GLuint
glGetShaderiv_p(target,pname)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetShaderiv,"glGetShaderiv");
	CODE:
	{
		GLuint param;
		glGetShaderiv(target,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# $infoLog = glGetShaderInfoLog_p($shader);
SV *
glGetShaderInfoLog_p(shader)
	GLuint shader
	INIT:
		loadProc(glGetShaderiv,"glGetShaderiv");
		loadProc(glGetShaderInfoLog,"glGetShaderInfoLog");
	CODE:
	{
		GLint infoLogLength;
		glGetShaderiv(shader,GL_INFO_LOG_LENGTH,(GLvoid *)&infoLogLength);
		if (infoLogLength)
		{
			GLint length;
			GLchar * infoLog = malloc(infoLogLength+1);
			glGetShaderInfoLog(shader,infoLogLength,&length,infoLog);
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

#//# $value = glGetProgramiv_p($target,$pname);
GLuint
glGetProgramiv_p(target,pname)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetProgramiv,"glGetProgramiv");
	CODE:
	{
		GLuint param;
		glGetProgramiv(target,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#endif // GL_VERSION_2_0

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

#//# glProgramLocalParameter4dARB($target,$index,$x,$y,$z,$w);
void
glProgramLocalParameter4dARB(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLdouble x
	GLdouble y
	GLdouble z
	GLdouble w
	INIT:
		loadProc(glProgramLocalParameter4dARB,"glProgramLocalParameter4dARB");

#//# glProgramLocalParameter4dvARB_c($target,$index,(CPTR)v);
void
glProgramLocalParameter4dvARB_c(target,index,v)
	GLenum target
	GLuint index
	void *	v
	INIT:
		loadProc(glProgramLocalParameter4dvARB,"glProgramLocalParameter4dvARB");
	CODE:
		glProgramLocalParameter4dvARB(target,index,(GLdouble*)v);

#//# glProgramLocalParameter4dvARB_s($target,$index,(PACKED)v);
void
glProgramLocalParameter4dvARB_s(target,index,v)
	GLenum target
	GLuint index
	SV *	v
	INIT:
		loadProc(glProgramLocalParameter4dvARB,"glProgramLocalParameter4dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glProgramLocalParameter4dvARB(target,index,v_s);
	}

#//!!! Do we really need this?  It duplicates glProgramLocalParameter4dARB
#//# glProgramLocalParameter4dvARB_p($target,$index,$x,$y,$z,$w);
void
glProgramLocalParameter4dvARB_p(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w
	INIT:
		loadProc(glProgramLocalParameter4dvARB,"glProgramLocalParameter4dvARB");
	CODE:
	{
		GLdouble param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glProgramLocalParameter4dvARB(target,index,param);
	}

#//# glProgramLocalParameter4fARB($target,$index,$x,$y,$z,$w);
void
glProgramLocalParameter4fARB(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLfloat x
	GLfloat y
	GLfloat z
	GLfloat w
	INIT:
		loadProc(glProgramLocalParameter4fARB,"glProgramLocalParameter4fARB");

#//# glProgramLocalParameter4fvARB_c($target,$index,(CPTR)v);
void
glProgramLocalParameter4fvARB_c(target,index,v)
	GLenum target
	GLuint index
	void *	v
	INIT:
		loadProc(glProgramLocalParameter4fvARB,"glProgramLocalParameter4fvARB");
	CODE:
		glProgramLocalParameter4fvARB(target,index,(GLfloat*)v);

#//# glProgramLocalParameter4fvARB_s($target,$index,(PACKED)v);
void
glProgramLocalParameter4fvARB_s(target,index,v)
	GLenum target
	GLuint index
	SV *	v
	INIT:
		loadProc(glProgramLocalParameter4fvARB,"glProgramLocalParameter4fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glProgramLocalParameter4fvARB(target,index,v_s);
	}

#//!!! Do we really need this?  It duplicates glProgramLocalParameter4fARB
#//# glProgramLocalParameter4fvARB_p($target,$index,$x,$y,$z,$w);
void
glProgramLocalParameter4fvARB_p(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w
	INIT:
		loadProc(glProgramLocalParameter4fvARB,"glProgramLocalParameter4fvARB");
	CODE:
	{
		GLfloat param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glProgramLocalParameter4fvARB(target,index,param);
	}

#//# glGetProgramEnvParameterdvARB_c($target,$index,(CPTR)params);
void
glGetProgramEnvParameterdvARB_c(target,index,params)
	GLenum	target
	GLint	index
	void *	params
	INIT:
		loadProc(glGetProgramEnvParameterdvARB,"glGetProgramEnvParameterdvARB");
	CODE:
		glGetProgramEnvParameterdvARB(target,index,(GLdouble*)params);

#//# glGetProgramEnvParameterdvARB_s($target,$index,(PACKED)params);
void
glGetProgramEnvParameterdvARB_s(target,index,params)
	GLenum	target
	GLint	index
	SV *	params
	INIT:
		loadProc(glGetProgramEnvParameterdvARB,"glGetProgramEnvParameterdvARB");
	CODE:
	{
		GLdouble * params_s = EL(params, sizeof(GLdouble) * 4);
		glGetProgramEnvParameterdvARB(target,index,params_s);
	}

#//# @params = glGetProgramEnvParameterdvARB_p($target,$index);
void
glGetProgramEnvParameterdvARB_p(target,index)
	GLenum	target
	GLint	index
	INIT:
		loadProc(glGetProgramEnvParameterdvARB,"glGetProgramEnvParameterdvARB");
	PPCODE:
	{
		GLdouble params[4];
		glGetProgramEnvParameterdvARB(target,index,params);

		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(params[0])));
		PUSHs(sv_2mortal(newSVnv(params[1])));
		PUSHs(sv_2mortal(newSVnv(params[2])));
		PUSHs(sv_2mortal(newSVnv(params[3])));
	}

#//# glGetProgramEnvParameterfvARB_c($target,$index,(CPTR)params);
void
glGetProgramEnvParameterfvARB_c(target,index,params)
	GLenum	target
	GLint	index
	void *	params
	INIT:
		loadProc(glGetProgramEnvParameterfvARB,"glGetProgramEnvParameterfvARB");
	CODE:
		glGetProgramEnvParameterfvARB(target,index,(GLfloat*)params);

#//# glGetProgramEnvParameterfvARB_s($target,$index,(PACKED)params);
void
glGetProgramEnvParameterfvARB_s(target,index,params)
	GLenum	target
	GLint	index
	SV *	params
	INIT:
		loadProc(glGetProgramEnvParameterfvARB,"glGetProgramEnvParameterfvARB");
	CODE:
	{
		GLfloat * params_s = EL(params, sizeof(GLfloat) * 4);
		glGetProgramEnvParameterfvARB(target,index,params_s);
	}

#//# @params = glGetProgramEnvParameterfvARB_p($target,$index);
void
glGetProgramEnvParameterfvARB_p(target,index)
	GLenum	target
	GLint	index
	INIT:
		loadProc(glGetProgramEnvParameterfvARB,"glGetProgramEnvParameterfvARB");
	PPCODE:
	{
		GLfloat params[4];
		glGetProgramEnvParameterfvARB(target,index,params);

		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(params[0])));
		PUSHs(sv_2mortal(newSVnv(params[1])));
		PUSHs(sv_2mortal(newSVnv(params[2])));
		PUSHs(sv_2mortal(newSVnv(params[3])));
	}

#//# glGetProgramLocalParameterdvARB_c($target,$index,(CPTR)params);
void
glGetProgramLocalParameterdvARB_c(target,index,params)
	GLenum	target
	GLint	index
	void *	params
	INIT:
		loadProc(glGetProgramLocalParameterdvARB,"glGetProgramLocalParameterdvARB");
	CODE:
		glGetProgramLocalParameterdvARB(target,index,(GLdouble*)params);

#//# glGetProgramLocalParameterdvARB_s($target,$index,(PACKED)params);
void
glGetProgramLocalParameterdvARB_s(target,index,params)
	GLenum	target
	GLint	index
	SV *	params
	INIT:
		loadProc(glGetProgramLocalParameterdvARB,"glGetProgramLocalParameterdvARB");
	CODE:
	{
		GLdouble * params_s = EL(params, sizeof(GLdouble) * 4);
		glGetProgramLocalParameterdvARB(target,index,params_s);
	}

#//# @params = glGetProgramLocalParameterdvARB_p($target,$index);
void
glGetProgramLocalParameterdvARB_p(target,index)
	GLenum	target
	GLint	index
	INIT:
		loadProc(glGetProgramLocalParameterdvARB,"glGetProgramLocalParameterdvARB");
	PPCODE:
	{
		GLdouble params[4];
		glGetProgramLocalParameterdvARB(target,index,params);

		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(params[0])));
		PUSHs(sv_2mortal(newSVnv(params[1])));
		PUSHs(sv_2mortal(newSVnv(params[2])));
		PUSHs(sv_2mortal(newSVnv(params[3])));
	}

#//# glGetProgramLocalParameterfvARB_c($target,$index,(CPTR)params);
void
glGetProgramLocalParameterfvARB_c(target,index,params)
	GLenum	target
	GLint	index
	void *	params
	INIT:
		loadProc(glGetProgramLocalParameterfvARB,"glGetProgramLocalParameterfvARB");
	CODE:
		glGetProgramLocalParameterfvARB(target,index,(GLfloat*)params);

#//# glGetProgramLocalParameterfvARB_s($target,$index,(PACKED)params);
void
glGetProgramLocalParameterfvARB_s(target,index,params)
	GLenum	target
	GLint	index
	SV *	params
	INIT:
		loadProc(glGetProgramLocalParameterfvARB,"glGetProgramLocalParameterfvARB");
	CODE:
	{
		GLfloat * params_s = EL(params, sizeof(GLfloat) * 4);
		glGetProgramLocalParameterfvARB(target,index,params_s);
	}

#//# @params = glGetProgramLocalParameterfvARB_p($target,$index);
void
glGetProgramLocalParameterfvARB_p(target,index)
	GLenum	target
	GLint	index
	INIT:
		loadProc(glGetProgramLocalParameterfvARB,"glGetProgramLocalParameterfvARB");
	PPCODE:
	{
		GLfloat params[4];
		glGetProgramLocalParameterfvARB(target,index,params);

		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(params[0])));
		PUSHs(sv_2mortal(newSVnv(params[1])));
		PUSHs(sv_2mortal(newSVnv(params[2])));
		PUSHs(sv_2mortal(newSVnv(params[3])));
	}

#//# glGetProgramivARB_c($target,$pname,(CPTR)params);
void
glGetProgramivARB_c(target,pname,params)
	GLenum	target
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
	CODE:
		glGetProgramivARB(target,pname,params);

#//# glGetProgramivARB_s($target,$pname,(PACKED)params);
void
glGetProgramivARB_s(target,pname,params)
	GLenum	target
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint)*gl_get_count(pname));
		glGetProgramivARB(target,pname,params_s);
	}

#//# $value = glGetProgramivARB_p($target,$pname);
GLuint
glGetProgramivARB_p(target,pname)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
	CODE:
	{
		GLuint param;
		glGetProgramivARB(target,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# glGetProgramStringARB_c(target,pname,(CPTR)string);
void
glGetProgramStringARB_c(target,pname,string)
	GLenum	target
	GLenum	pname
	void *	string
	INIT:
		loadProc(glGetProgramStringARB,"glGetProgramStringARB");
	CODE:
		glGetProgramStringARB(target,pname,string);

#//# glGetProgramStringARB_s(target,pname,(PACKED)string);
void
glGetProgramStringARB_s(target,pname,string)
	GLenum	target
	GLenum	pname
	SV *	string
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
		loadProc(glGetProgramStringARB,"glGetProgramStringARB");
	CODE:
	{
		GLint len;
		glGetProgramivARB(target,GL_PROGRAM_LENGTH_ARB,(GLvoid *)&len);
		if (len)
		{
			GLubyte * string_s = EL(string, sizeof(GLubyte)*len);
			glGetProgramStringARB(target,pname,string_s);
		}
	}

#//# $string = glGetProgramStringARB_p(target[,pname]);
#//- Defaults to GL_PROGRAM_STRING_ARB
SV *
glGetProgramStringARB_p(target,pname=GL_PROGRAM_STRING_ARB)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
		loadProc(glGetProgramStringARB,"glGetProgramStringARB");
	CODE:
	{
		GLint len;
		glGetProgramivARB(target,GL_PROGRAM_LENGTH_ARB,(GLvoid *)&len);
		if (len)
		{
			char * string = malloc(len+1);
			glGetProgramStringARB(target,pname,(GLubyte*)string);
			string[len] = 0;
			if (*string)
				RETVAL = newSVpv(string, 0);
			else
				RETVAL = newSVsv(&PL_sv_undef);

			free(string);
		}
		else
		{
			RETVAL = newSVsv(&PL_sv_undef);
		}
	}
	OUTPUT:
		RETVAL

#//# glIsProgramARB(program);
GLboolean
glIsProgramARB(program)
	GLuint	program
	INIT:
		loadProc(glIsProgramARB,"glIsProgramARB");
	CODE:
	{
		RETVAL = glIsProgramARB(program);
	}
	OUTPUT:
		RETVAL

#endif // GL_ARB_vertex_program


#if defined(GL_ARB_vertex_program) || defined(GL_ARB_vertex_shader)

#//# glVertexAttrib1dARB($index,$x);
void
glVertexAttrib1dARB(index,x)
	GLuint index
	GLdouble x
	INIT:
		loadProc(glVertexAttrib1dARB,"glVertexAttrib1dARB");

#//# glVertexAttrib1dvARB_c($index,(CPTR)v);
void
glVertexAttrib1dvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib1dvARB,"glVertexAttrib1dvARB");
	CODE:
		glVertexAttrib1dvARB(index,(GLdouble*)v);

#//# glVertexAttrib1dvARB_s($index,(PACKED)v);
void
glVertexAttrib1dvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib1dvARB,"glVertexAttrib1dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*1);
		glVertexAttrib1dvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib1dARB
#//# glVertexAttrib1dvARB_p($index,$x);
void
glVertexAttrib1dvARB_p(index,x)
	GLuint index
	GLdouble	x
	INIT:
		loadProc(glVertexAttrib1dvARB,"glVertexAttrib1dvARB");
	CODE:
	{
		GLdouble param[1];
		param[0] = x;
		glVertexAttrib1dvARB(index,param);
	}

#//# glVertexAttrib1fARB($index,$x);
void
glVertexAttrib1fARB(index,x)
	GLuint index
	GLfloat x
	INIT:
		loadProc(glVertexAttrib1fARB,"glVertexAttrib1fARB");

#//# glVertexAttrib1sARB($index,$x);
void
glVertexAttrib1sARB(index,x)
	GLuint index
	GLshort x
	INIT:
		loadProc(glVertexAttrib1sARB,"glVertexAttrib1sARB");

#//# glVertexAttrib1svARB_c($index,(CPTR)v);
void
glVertexAttrib1svARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib1svARB,"glVertexAttrib1svARB");
	CODE:
		glVertexAttrib1svARB(index,(GLshort*)v);

#//# glVertexAttrib1svARB_s($index,(PACKED)v);
void
glVertexAttrib1svARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib1svARB,"glVertexAttrib1svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*1);
		glVertexAttrib1svARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib1sARB
#//# glVertexAttrib1svARB_p($index,$x);
void
glVertexAttrib1svARB_p(index,x)
	GLuint index
	GLshort	x
	INIT:
		loadProc(glVertexAttrib1svARB,"glVertexAttrib1svARB");
	CODE:
	{
		GLshort param[1];
		param[0] = x;
		glVertexAttrib1svARB(index,param);
	}

#//# glVertexAttrib2dARB($index,$x,$y);
void
glVertexAttrib2dARB(index,x,y)
	GLuint index
	GLdouble x
	GLdouble y
	INIT:
		loadProc(glVertexAttrib2dARB,"glVertexAttrib2dARB");

#//# glVertexAttrib2dvARB_c($index,(CPTR)v);
void
glVertexAttrib2dvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib2dvARB,"glVertexAttrib2dvARB");
	CODE:
		glVertexAttrib2dvARB(index,(GLdouble*)v);

#//# glVertexAttrib2dvARB_s($index,(PACKED)v);
void
glVertexAttrib2dvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib2dvARB,"glVertexAttrib2dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*2);
		glVertexAttrib2dvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib2dARB
#//# glVertexAttrib2dvARB_p($index,$x,$y);
void
glVertexAttrib2dvARB_p(index,x,y)
	GLuint index
	GLdouble	x
	GLdouble	y
	INIT:
		loadProc(glVertexAttrib2dvARB,"glVertexAttrib2dvARB");
	CODE:
	{
		GLdouble param[2];
		param[0] = x;
		param[1] = y;
		glVertexAttrib2dvARB(index,param);
	}

#//# glVertexAttrib2fARB($index,$x,$y);
void
glVertexAttrib2fARB(index,x,y)
	GLuint index
	GLfloat x
	GLfloat y
	INIT:
		loadProc(glVertexAttrib2fARB,"glVertexAttrib2fARB");

#//# glVertexAttrib2sARB($index,$x,$y);
void
glVertexAttrib2sARB(index,x,y)
	GLuint index
	GLshort x
	GLshort y
	INIT:
		loadProc(glVertexAttrib2sARB,"glVertexAttrib2sARB");

#//# glVertexAttrib2svARB_c($index,(CPTR)v);
void
glVertexAttrib2svARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib2svARB,"glVertexAttrib2svARB");
	CODE:
		glVertexAttrib2svARB(index,(GLshort*)v);

#//# glVertexAttrib2svARB_s($index,(PACKED)v);
void
glVertexAttrib2svARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib2svARB,"glVertexAttrib2svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*2);
		glVertexAttrib2svARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib2sARB
#//# glVertexAttrib2svARB_p($index,$x,$y);
void
glVertexAttrib2svARB_p(index,x,y)
	GLuint index
	GLshort	x
	GLshort	y
	INIT:
		loadProc(glVertexAttrib2svARB,"glVertexAttrib2svARB");
	CODE:
	{
		GLshort param[2];
		param[0] = x;
		param[1] = y;
		glVertexAttrib2svARB(index,param);
	}

#//# glVertexAttrib3dARB($index,$x,$y,$z);
void
glVertexAttrib3dARB(index,x,y,z)
	GLuint index
	GLdouble x
	GLdouble y
	GLdouble z
	INIT:
		loadProc(glVertexAttrib3dARB,"glVertexAttrib3dARB");

#//# glVertexAttrib3dvARB_c($index,(CPTR)v);
void
glVertexAttrib3dvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib3dvARB,"glVertexAttrib3dvARB");
	CODE:
		glVertexAttrib3dvARB(index,(GLdouble*)v);

#//# glVertexAttrib3dvARB_s($index,(PACKED)v);
void
glVertexAttrib3dvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib3dvARB,"glVertexAttrib3dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*3);
		glVertexAttrib3dvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib3dARB
#//# glVertexAttrib3dvARB_p($index,$x,$y,$z);
void
glVertexAttrib3dvARB_p(index,x,y,z)
	GLuint index
	GLdouble	x
	GLdouble	y
	GLdouble	z
	INIT:
		loadProc(glVertexAttrib3dvARB,"glVertexAttrib3dvARB");
	CODE:
	{
		GLdouble param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertexAttrib3dvARB(index,param);
	}

#//# glVertexAttrib3fARB($index,$x,$y,$z);
void
glVertexAttrib3fARB(index,x,y,z)
	GLuint index
	GLfloat x
	GLfloat y
	GLfloat z
	INIT:
		loadProc(glVertexAttrib3fARB,"glVertexAttrib3fARB");

#//# glVertexAttrib3fvARB_c($index,(CPTR)v);
void
glVertexAttrib3fvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib3fvARB,"glVertexAttrib3fvARB");
	CODE:
		glVertexAttrib3fvARB(index,(GLfloat*)v);

#//# glVertexAttrib3fvARB_s($index,(PACKED)v);
void
glVertexAttrib3fvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib3fvARB,"glVertexAttrib3fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*3);
		glVertexAttrib3fvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib3fARB
#//# glVertexAttrib3fvARB_p($index,$x,$y,$z);
void
glVertexAttrib3fvARB_p(index,x,y,z)
	GLuint index
	GLfloat	x
	GLfloat	y
	GLfloat	z
	INIT:
		loadProc(glVertexAttrib3fvARB,"glVertexAttrib3fvARB");
	CODE:
	{
		GLfloat param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertexAttrib3fvARB(index,param);
	}

#//# glVertexAttrib3sARB($index,$x,$y,$z);
void
glVertexAttrib3sARB(index,x,y,z)
	GLuint index
	GLshort x
	GLshort y
	GLshort z
	INIT:
		loadProc(glVertexAttrib3sARB,"glVertexAttrib3sARB");

#//# glVertexAttrib3svARB_c($index,(CPTR)v);
void
glVertexAttrib3svARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib3svARB,"glVertexAttrib3svARB");
	CODE:
		glVertexAttrib3svARB(index,(GLshort*)v);

#//# glVertexAttrib3svARB_s($index,(PACKED)v);
void
glVertexAttrib3svARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib3svARB,"glVertexAttrib3svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*3);
		glVertexAttrib3svARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib3sARB
#//# glVertexAttrib3svARB_p($index,$x,$y,$z);
void
glVertexAttrib3svARB_p(index,x,y,z)
	GLuint index
	GLshort	x
	GLshort	y
	GLshort	z
	INIT:
		loadProc(glVertexAttrib3svARB,"glVertexAttrib3svARB");
	CODE:
	{
		GLshort param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertexAttrib3svARB(index,param);
	}

#//# glVertexAttrib4NbvARB_c($index,(CPTR)v);
void
glVertexAttrib4NbvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NbvARB,"glVertexAttrib4NbvARB");
	CODE:
		glVertexAttrib4NbvARB(index,(GLbyte*)v);

#//# glVertexAttrib4NbvARB_s($index,(PACKED)v);
void
glVertexAttrib4NbvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NbvARB,"glVertexAttrib4NbvARB");
	CODE:
	{
		GLbyte * v_s = EL(v, sizeof(GLbyte)*4);
		glVertexAttrib4NbvARB(index,v_s);
	}

#//# glVertexAttrib4NbvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NbvARB_p(index,x,y,z,w)
	GLuint index
	GLbyte	x
	GLbyte	y
	GLbyte	z
	GLbyte	w
	INIT:
		loadProc(glVertexAttrib4NbvARB,"glVertexAttrib4NbvARB");
	CODE:
	{
		GLbyte param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NbvARB(index,param);
	}

#//# glVertexAttrib4NivARB_c($index,(CPTR)v);
void
glVertexAttrib4NivARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NivARB,"glVertexAttrib4NivARB");
	CODE:
		glVertexAttrib4NivARB(index,(GLint*)v);

#//# glVertexAttrib4NivARB_s($index,(PACKED)v);
void
glVertexAttrib4NivARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NivARB,"glVertexAttrib4NivARB");
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glVertexAttrib4NivARB(index,v_s);
	}

#//# glVertexAttrib4NivARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NivARB_p(index,x,y,z,w)
	GLuint index
	GLint	x
	GLint	y
	GLint	z
	GLint	w
	INIT:
		loadProc(glVertexAttrib4NivARB,"glVertexAttrib4NivARB");
	CODE:
	{
		GLint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NivARB(index,param);
	}

#//# glVertexAttrib4NsvARB_c($index,(CPTR)v);
void
glVertexAttrib4NsvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NsvARB,"glVertexAttrib4NsvARB");
	CODE:
		glVertexAttrib4NsvARB(index,(GLshort*)v);

#//# glVertexAttrib4NsvARB_s($index,(PACKED)v);
void
glVertexAttrib4NsvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NsvARB,"glVertexAttrib4NsvARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glVertexAttrib4NsvARB(index,v_s);
	}

#//# glVertexAttrib4NsvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NsvARB_p(index,x,y,z,w)
	GLuint index
	GLshort	x
	GLshort	y
	GLshort	z
	GLshort	w
	INIT:
		loadProc(glVertexAttrib4NsvARB,"glVertexAttrib4NsvARB");
	CODE:
	{
		GLshort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NsvARB(index,param);
	}

#//# glVertexAttrib4NubARB($index,$x,$y,$z,$w);
void
glVertexAttrib4NubARB(index,x,y,z,w)
	GLuint index
	GLubyte x
	GLubyte y
	GLubyte z
	GLubyte w
	INIT:
		loadProc(glVertexAttrib4NubARB,"glVertexAttrib4NubARB");

#//# glVertexAttrib4NubvARB_c($index,(CPTR)v);
void
glVertexAttrib4NubvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NubvARB,"glVertexAttrib4NubvARB");
	CODE:
		glVertexAttrib4NubvARB(index,(GLubyte*)v);

#//# glVertexAttrib4NubvARB_s($index,(PACKED)v);
void
glVertexAttrib4NubvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NubvARB,"glVertexAttrib4NubvARB");
	CODE:
	{
		GLubyte * v_s = EL(v, sizeof(GLubyte)*4);
		glVertexAttrib4NubvARB(index,v_s);
	}

#//# glVertexAttrib4NubvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NubvARB_p(index,x,y,z,w)
	GLuint index
	GLubyte	x
	GLubyte	y
	GLubyte	z
	GLubyte	w
	INIT:
		loadProc(glVertexAttrib4NubvARB,"glVertexAttrib4NubvARB");
	CODE:
	{
		GLubyte param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NubvARB(index,param);
	}

#//# glVertexAttrib4NuivARB_c($index,(CPTR)v);
void
glVertexAttrib4NuivARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NuivARB,"glVertexAttrib4NuivARB");
	CODE:
		glVertexAttrib4NuivARB(index,(GLuint*)v);

#//# glVertexAttrib4NuivARB_s($index,(PACKED)v);
void
glVertexAttrib4NuivARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NuivARB,"glVertexAttrib4NuivARB");
	CODE:
	{
		GLuint * v_s = EL(v, sizeof(GLuint)*4);
		glVertexAttrib4NuivARB(index,v_s);
	}

#//# glVertexAttrib4NuivARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NuivARB_p(index,x,y,z,w)
	GLuint index
	GLuint	x
	GLuint	y
	GLuint	z
	GLuint	w
	INIT:
		loadProc(glVertexAttrib4NuivARB,"glVertexAttrib4NuivARB");
	CODE:
	{
		GLuint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NuivARB(index,param);
	}

#//# glVertexAttrib4NusvARB_c($index,(CPTR)v);
void
glVertexAttrib4NusvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NusvARB,"glVertexAttrib4NusvARB");
	CODE:
		glVertexAttrib4NusvARB(index,(GLushort*)v);

#//# glVertexAttrib4NusvARB_s($index,(PACKED)v);
void
glVertexAttrib4NusvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NusvARB,"glVertexAttrib4NusvARB");
	CODE:
	{
		GLushort * v_s = EL(v, sizeof(GLushort)*4);
		glVertexAttrib4NusvARB(index,v_s);
	}

#//# glVertexAttrib4NusvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NusvARB_p(index,x,y,z,w)
	GLuint index
	GLushort	x
	GLushort	y
	GLushort	z
	GLushort	w
	INIT:
		loadProc(glVertexAttrib4NusvARB,"glVertexAttrib4NusvARB");
	CODE:
	{
		GLushort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NusvARB(index,param);
	}

#//# glVertexAttrib4bvARB_c($index,(CPTR)v);
void
glVertexAttrib4bvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4bvARB,"glVertexAttrib4bvARB");
	CODE:
		glVertexAttrib4bvARB(index,(GLbyte*)v);

#//# glVertexAttrib4bvARB_s($index,(PACKED)v);
void
glVertexAttrib4bvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4bvARB,"glVertexAttrib4bvARB");
	CODE:
	{
		GLbyte * v_s = EL(v, sizeof(GLbyte)*4);
		glVertexAttrib4bvARB(index,v_s);
	}

#//# glVertexAttrib4bvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4bvARB_p(index,x,y,z,w)
	GLuint index
	GLbyte	x
	GLbyte	y
	GLbyte	z
	GLbyte	w
	INIT:
		loadProc(glVertexAttrib4bvARB,"glVertexAttrib4bvARB");
	CODE:
	{
		GLbyte param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4bvARB(index,param);
	}

#//# glVertexAttrib4dARB($index,$x,$y,$z,$w);
void
glVertexAttrib4dARB(index,x,y,z,w)
	GLuint index
	GLdouble x
	GLdouble y
	GLdouble z
	GLdouble w
	INIT:
		loadProc(glVertexAttrib4dARB,"glVertexAttrib4dARB");

#//# glVertexAttrib4dvARB_c($index,(CPTR)v);
void
glVertexAttrib4dvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4dvARB,"glVertexAttrib4dvARB");
	CODE:
		glVertexAttrib4dvARB(index,(GLdouble*)v);

#//# glVertexAttrib4dvARB_s($index,(PACKED)v);
void
glVertexAttrib4dvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4dvARB,"glVertexAttrib4dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glVertexAttrib4dvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib4dARB
#//# glVertexAttrib4dvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4dvARB_p(index,x,y,z,w)
	GLuint index
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w
	INIT:
		loadProc(glVertexAttrib4dvARB,"glVertexAttrib4dvARB");
	CODE:
	{
		GLdouble param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4dvARB(index,param);
	}

#//# glVertexAttrib4fARB($index,$x,$y,$z,$w);
void
glVertexAttrib4fARB(index,x,y,z,w)
	GLuint index
	GLfloat x
	GLfloat y
	GLfloat z
	GLfloat w
	INIT:
		loadProc(glVertexAttrib4fARB,"glVertexAttrib4fARB");

#//# glVertexAttrib4fvARB_c($index,(CPTR)v);
void
glVertexAttrib4fvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4fvARB,"glVertexAttrib4fvARB");
	CODE:
		glVertexAttrib4fvARB(index,(GLfloat*)v);

#//# glVertexAttrib4fvARB_s($index,(PACKED)v);
void
glVertexAttrib4fvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4fvARB,"glVertexAttrib4fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glVertexAttrib4fvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib4fARB
#//# glVertexAttrib4fvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4fvARB_p(index,x,y,z,w)
	GLuint index
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w
	INIT:
		loadProc(glVertexAttrib4fvARB,"glVertexAttrib4fvARB");
	CODE:
	{
		GLfloat param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4fvARB(index,param);
	}

#//# glVertexAttrib4ivARB_c($index,(CPTR)v);
void
glVertexAttrib4ivARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4ivARB,"glVertexAttrib4ivARB");
	CODE:
		glVertexAttrib4ivARB(index,(GLint*)v);

#//# glVertexAttrib4ivARB_s($index,(PACKED)v);
void
glVertexAttrib4ivARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4ivARB,"glVertexAttrib4ivARB");
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glVertexAttrib4ivARB(index,v_s);
	}

#//# glVertexAttrib4ivARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4ivARB_p(index,x,y,z,w)
	GLuint index
	GLint	x
	GLint	y
	GLint	z
	GLint	w
	INIT:
		loadProc(glVertexAttrib4ivARB,"glVertexAttrib4ivARB");
	CODE:
	{
		GLint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4ivARB(index,param);
	}

#//# glVertexAttrib4sARB($index,$x,$y,$z,$w);
void
glVertexAttrib4sARB(index,x,y,z,w)
	GLuint index
	GLshort x
	GLshort y
	GLshort z
	GLshort w
	INIT:
		loadProc(glVertexAttrib4sARB,"glVertexAttrib4sARB");

#//# glVertexAttrib4svARB_c($index,(CPTR)v);
void
glVertexAttrib4svARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4svARB,"glVertexAttrib4svARB");
	CODE:
		glVertexAttrib4svARB(index,(GLshort*)v);

#//# glVertexAttrib4svARB_s($index,(PACKED)v);
void
glVertexAttrib4svARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4svARB,"glVertexAttrib4svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glVertexAttrib4svARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib4sARB
#//# glVertexAttrib4svARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4svARB_p(index,x,y,z,w)
	GLuint index
	GLshort	x
	GLshort	y
	GLshort	z
	GLshort	w
	INIT:
		loadProc(glVertexAttrib4svARB,"glVertexAttrib4svARB");
	CODE:
	{
		GLshort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4svARB(index,param);
	}

#//# glVertexAttrib4ubvARB_c($index,(CPTR)v);
void
glVertexAttrib4ubvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4ubvARB,"glVertexAttrib4ubvARB");
	CODE:
		glVertexAttrib4ubvARB(index,(GLubyte*)v);

#//# glVertexAttrib4ubvARB_s($index,(PACKED)v);
void
glVertexAttrib4ubvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4ubvARB,"glVertexAttrib4ubvARB");
	CODE:
	{
		GLubyte * v_s = EL(v, sizeof(GLubyte)*4);
		glVertexAttrib4ubvARB(index,v_s);
	}

#//# glVertexAttrib4ubvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4ubvARB_p(index,x,y,z,w)
	GLuint index
	GLubyte	x
	GLubyte	y
	GLubyte	z
	GLubyte	w
	INIT:
		loadProc(glVertexAttrib4ubvARB,"glVertexAttrib4ubvARB");
	CODE:
	{
		GLubyte param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4ubvARB(index,param);
	}

#//# glVertexAttrib4uivARB_c($index,(CPTR)v);
void
glVertexAttrib4uivARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4uivARB,"glVertexAttrib4uivARB");
	CODE:
		glVertexAttrib4uivARB(index,(GLuint*)v);

#//# glVertexAttrib4uivARB_s($index,(PACKED)v);
void
glVertexAttrib4uivARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4uivARB,"glVertexAttrib4uivARB");
	CODE:
	{
		GLuint * v_s = EL(v, sizeof(GLuint)*4);
		glVertexAttrib4uivARB(index,v_s);
	}

#//# glVertexAttrib4uivARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4uivARB_p(index,x,y,z,w)
	GLuint index
	GLuint	x
	GLuint	y
	GLuint	z
	GLuint	w
	INIT:
		loadProc(glVertexAttrib4uivARB,"glVertexAttrib4uivARB");
	CODE:
	{
		GLuint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4uivARB(index,param);
	}

#//# glVertexAttrib4usvARB_c($index,(CPTR)v);
void
glVertexAttrib4usvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4usvARB,"glVertexAttrib4usvARB");
	CODE:
		glVertexAttrib4usvARB(index,(GLushort*)v);

#//# glVertexAttrib4usvARB_c($index,(PACKED)v);
void
glVertexAttrib4usvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4usvARB,"glVertexAttrib4usvARB");
	CODE:
	{
		GLushort * v_s = EL(v, sizeof(GLushort)*4);
		glVertexAttrib4usvARB(index,v_s);
	}

#//# glVertexAttrib4usvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4usvARB_p(index,x,y,z,w)
	GLuint index
	GLushort	x
	GLushort	y
	GLushort	z
	GLushort	w
	INIT:
		loadProc(glVertexAttrib4usvARB,"glVertexAttrib4usvARB");
	CODE:
	{
		GLushort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4usvARB(index,param);
	}

#//# glVertexAttribPointerARB_c($index,$size,$type,$normalized,$stride,(CPTR)pointer);
void
glVertexAttribPointerARB_c(index,size,type,normalized,stride,pointer)
	GLuint index
	GLint size
	GLenum type
	GLboolean normalized
	GLsizei stride
	void * pointer
	INIT:
		loadProc(glVertexAttribPointerARB,"glVertexAttribPointerARB");
	CODE:
		glVertexAttribPointerARB(index,size,type,
			normalized,stride,pointer);

#//# glVertexAttribPointerARB_p($index,$type,$normalized,$stride,@attribs);
void
glVertexAttribPointerARB_p(index,type,normalized,stride,...)
	GLuint index
	GLenum type
	GLboolean normalized
	GLsizei stride
	INIT:
		loadProc(glVertexAttribPointerARB,"glVertexAttribPointerARB");
	CODE:
	{
		GLuint count = items - 4;
		GLuint size = gl_type_size(type);
		void * pointer = malloc(count * size);

		SvItems(type,4,count,pointer);

		glVertexAttribPointerARB(index,count,type,
			normalized,stride,pointer);

		free(pointer);
	}

#//# glEnableVertexAttribArrayARB($index);
void
glEnableVertexAttribArrayARB(index)
	GLuint index
	INIT:
		loadProc(glEnableVertexAttribArrayARB,"glEnableVertexAttribArrayARB");

#//# glDisableVertexAttribArrayARB($index);
void
glDisableVertexAttribArrayARB(index)
	GLuint index
	INIT:
		loadProc(glDisableVertexAttribArrayARB,"glDisableVertexAttribArrayARB");

#//# glGetVertexAttribdvARB_c($index,$pname,(CPTR)params);
void
glGetVertexAttribdvARB_c(index,pname,params)
	GLuint	index
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetVertexAttribdvARB,"glGetVertexAttribdvARB");
	CODE:
		glGetVertexAttribdvARB(index,pname,(GLdouble*)params);

#//# glGetVertexAttribdvARB_s($index,$pname,(PACKED)params);
void
glGetVertexAttribdvARB_s(index,pname,params)
	GLuint	index
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetVertexAttribdvARB,"glGetVertexAttribdvARB");
	CODE:
	{
		GLdouble * params_s = EL(params, sizeof(GLdouble) * 4);
		glGetVertexAttribdvARB(index,pname,params_s);
	}

#//# $param = glGetVertexAttribdvARB_p($index,$pname);
GLdouble
glGetVertexAttribdvARB_p(index,pname)
	GLuint	index
	GLenum	pname
	INIT:
		loadProc(glGetVertexAttribdvARB,"glGetVertexAttribdvARB");
	CODE:
	{
		GLdouble param;
		glGetVertexAttribdvARB(index,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# glGetVertexAttribfvARB_c($index,$pname,(CPTR)params);
void
glGetVertexAttribfvARB_c(index,pname,params)
	GLuint	index
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetVertexAttribfvARB,"glGetVertexAttribfvARB");
	CODE:
		glGetVertexAttribfvARB(index,pname,(GLfloat*)params);

#//# glGetVertexAttribfvARB_s($index,$pname,(PACKED)params);
void
glGetVertexAttribfvARB_s(index,pname,params)
	GLuint	index
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetVertexAttribfvARB,"glGetVertexAttribfvARB");
	CODE:
	{
		GLfloat * params_s = EL(params, sizeof(GLfloat) * 4);
		glGetVertexAttribfvARB(index,pname,params_s);
	}

#//# $param = glGetVertexAttribfvARB_p($index,$pname);
GLfloat
glGetVertexAttribfvARB_p(index,pname)
	GLuint	index
	GLenum	pname
	INIT:
		loadProc(glGetVertexAttribfvARB,"glGetVertexAttribfvARB");
	CODE:
	{
		GLfloat param;
		glGetVertexAttribfvARB(index,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# glGetVertexAttribivARB_c($index,$pname,(CPTR)params);
void
glGetVertexAttribivARB_c(index,pname,params)
	GLuint	index
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetVertexAttribivARB,"glGetVertexAttribivARB");
	CODE:
		glGetVertexAttribivARB(index,pname,(GLint*)params);

#//# glGetVertexAttribivARB_s($index,$pname,(PACKED)params);
void
glGetVertexAttribivARB_s(index,pname,params)
	GLuint	index
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetVertexAttribivARB,"glGetVertexAttribivARB");
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint) * 4);
		glGetVertexAttribivARB(index,pname,params_s);
	}

#//# $param = glGetVertexAttribivARB_p($index,$pname);
GLuint
glGetVertexAttribivARB_p(index,pname)
	GLuint	index
	GLenum	pname
	INIT:
		loadProc(glGetVertexAttribivARB,"glGetVertexAttribivARB");
	CODE:
	{
		GLuint param;
		glGetVertexAttribivARB(index,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# glGetVertexAttribPointervARB_c($index,$pname,(CPTR)pointer);
void
glGetVertexAttribPointervARB_c(index,pname,pointer)
	GLuint	index
	GLenum	pname
	void *	pointer
	INIT:
		loadProc(glGetVertexAttribPointervARB,"glGetVertexAttribPointervARB");
	CODE:
		glGetVertexAttribPointervARB(index,pname,pointer);

#//# $param = glGetVertexAttribPointervARB_p($index,$pname);
void
glGetVertexAttribPointervARB_p(index,pname)
	GLuint	index
	GLenum	pname
	INIT:
		loadProc(glGetVertexAttribPointervARB,"glGetVertexAttribPointervARB");
		loadProc(glGetVertexAttribivARB,"glGetVertexAttribivARB");
	PPCODE:
	{
		void * pointer;
		GLuint i,count,type;

		glGetVertexAttribPointervARB(index,pname,&pointer);

		glGetVertexAttribivARB(index,GL_VERTEX_ATTRIB_ARRAY_SIZE_ARB,(void *)&count);
		glGetVertexAttribivARB(index,GL_VERTEX_ATTRIB_ARRAY_TYPE_ARB,(void *)&type);

		EXTEND(sp, count);

		switch (type)
		{
#ifdef GL_VERSION_1_2
			case GL_UNSIGNED_BYTE_3_3_2:
			case GL_UNSIGNED_BYTE_2_3_3_REV:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLubyte*)pointer)[i])));
				}
				break;
			case GL_UNSIGNED_SHORT_5_6_5:
			case GL_UNSIGNED_SHORT_5_6_5_REV:
			case GL_UNSIGNED_SHORT_4_4_4_4:
			case GL_UNSIGNED_SHORT_4_4_4_4_REV:
			case GL_UNSIGNED_SHORT_5_5_5_1:
			case GL_UNSIGNED_SHORT_1_5_5_5_REV:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLushort*)pointer)[i])));
				}
				break;
			case GL_UNSIGNED_INT_8_8_8_8:
			case GL_UNSIGNED_INT_8_8_8_8_REV:
			case GL_UNSIGNED_INT_10_10_10_2:
			case GL_UNSIGNED_INT_2_10_10_10_REV:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLuint*)pointer)[i])));
				}
				break;
#endif
			case GL_UNSIGNED_BYTE:
			case GL_BITMAP:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLubyte*)pointer)[i])));
				}
				break;
			case GL_BYTE:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLbyte*)pointer)[i])));
				}
				break;
			case GL_UNSIGNED_SHORT:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLushort*)pointer)[i])));
				}
				break;
			case GL_SHORT:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLushort*)pointer)[i])));
				}
				break;
			case GL_UNSIGNED_INT:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLuint*)pointer)[i])));
				}
				break;
			case GL_INT:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLint*)pointer)[i])));
				}
				break;
			case GL_FLOAT:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSVnv(((GLfloat*)pointer)[i])));
				}
				break;
			case GL_DOUBLE:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSVnv(((GLdouble*)pointer)[i])));
				}
				break;
			default:
				croak("unknown type");
		}
	}

#endif


#ifdef GL_ARB_vertex_shader

#//# glBindAttribLocationARB($programObj, $index, $name);
void
glBindAttribLocationARB(programObj, index, name)
	GLhandleARB programObj
	GLuint index
	void *name
	INIT:
		loadProc(glBindAttribLocationARB,"glBindAttribLocationARB");
	CODE:
		glBindAttribLocationARB(programObj,index,name);

#//# glGetActiveAttribARB_c($programObj, $index, $maxLength, (CPTR)length, (CPTR)size, (CPTR)type, (CPTR)name);
void
glGetActiveAttribARB_c(programObj, index, maxLength, length, size, type, name)
	GLhandleARB programObj
	GLuint	index
	GLsizei	maxLength
	void	*length
	void	*size
	void	*type
	void	*name
	INIT:
		loadProc(glGetActiveAttribARB,"glGetActiveAttribARB");
	CODE:
		glGetActiveAttribARB(programObj,index,maxLength,length,size,type,name);

#//# glGetActiveAttribARB_s($programObj, $index, $maxLength, (PACKED)length, (PACKED)size, (PACKED)type, (PACKED)name);
void
glGetActiveAttribARB_s(programObj, index, maxLength, length, size, type, name)
	GLhandleARB programObj
	GLuint	index
	GLsizei	maxLength
	SV	*length
	SV	*size
	SV	*type
	SV	*name
	INIT:
		loadProc(glGetActiveAttribARB,"glGetActiveAttribARB");
	CODE:
	{
		GLsizei	  *length_s = EL(length, sizeof(GLsizei));
		GLint	  *size_s = EL(size, sizeof(GLint));
		GLenum	  *type_s = EL(type, sizeof(GLenum));
		GLcharARB *name_s = EL(name, sizeof(GLcharARB));
		glGetActiveAttribARB(programObj,index,maxLength,length_s,size_s,type_s,name_s);
	}

#//# ($name,$type,$size) = glGetActiveAttribARB_p($programObj, $index);
void
glGetActiveAttribARB_p(programObj, index)
	GLhandleARB programObj
	GLuint index
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
		loadProc(glGetActiveAttribARB,"glGetActiveAttribARB");
	PPCODE:
	{
		GLsizei maxLength;
		glGetObjectParameterivARB(programObj,GL_OBJECT_ACTIVE_ATTRIBUTES_ARB,
			(GLvoid *)&maxLength);
		if (maxLength)
		{
			GLsizei length;
			GLint size;
			GLenum type;
			GLcharARB *name;

			name = malloc(maxLength+1);
			glGetActiveAttribARB(programObj,index,maxLength,
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

#//# glGetAttribLocationARB_c($programObj, (CPTR)name);
GLint
glGetAttribLocationARB_c(programObj, name)
	GLhandleARB programObj
	void	*name
	INIT:
		loadProc(glGetAttribLocationARB,"glGetAttribLocationARB");
	CODE:
		RETVAL = glGetAttribLocationARB(programObj, name);
	OUTPUT:
		RETVAL

#//!!! Since pointer is string, should combine _C and _p
#//# $value = glGetAttribLocationARB_p(programObj, $name);
GLint
glGetAttribLocationARB_p(programObj, ...)
	GLhandleARB programObj
	INIT:
		loadProc(glGetAttribLocationARB,"glGetAttribLocationARB");
	CODE:
	{
		GLcharARB *name = (GLcharARB *)SvPV(ST(1),PL_na);
		RETVAL = glGetAttribLocationARB(programObj, name);
	}
	OUTPUT:
		RETVAL

#endif

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
			PUSHs(sv_2mortal(newSViv((IV)obj[i])));

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

#endif /* HAVE_GL */
