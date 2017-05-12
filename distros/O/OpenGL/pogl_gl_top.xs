/*  Last saved: Sat 10 Jul 2010 12:57:04 PM*/

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



#ifdef IN_POGL_GLX_XS
#ifdef HAVE_GLX
#  define HAVE_GLpc			/* Perl interface */
#  define nativeWindowId(d, w)	(w)
static Bool WaitForNotify(Display *d, XEvent *e, char *arg) {
    return (e->type == MapNotify) && (e->xmap.window == (Window)arg);
}
#  define glpResizeWindow(s1,s2,w,d)	XResizeWindow(d,w,s1,s2)
#  define glpMoveWindow(s1,s2,w,d)		XMoveWindow(d,w,s1,s2)
#  define glpMoveResizeWindow(s1,s2,s3,s4,w,d)	XMoveResizeWindow(d,w,s1,s2,s3,s4)
#endif	/* defined HAVE_GLX */ 



static int debug = 0;

#ifdef HAVE_GLpc

#  define NUM_ARG 7			/* Number of mandatory args to glpcOpenWindow */

Display *dpy;
int dpy_open;
XVisualInfo *vi;
Colormap cmap;
XSetWindowAttributes swa;
Window win;
GLXContext ctx;

static int default_attributes[] = { GLX_DOUBLEBUFFER, GLX_RGBA, None };

#endif	/* defined HAVE_GLpc */ 

static int DBUFFER_HACK = 0;
#define __had_dbuffer_hack() (DBUFFER_HACK)

#endif /* End IN_POGL_GLX_XS */



/********************/
/* GPGPU Utils      */
/********************/

GLint FBO_MAX = -1;

/* Get max GPGPU data size */
int gpgpu_size(void)
{
#if defined(GL_ARB_texture_rectangle) && defined(GL_ARB_texture_float) && \
  defined(GL_ARB_fragment_program) && defined(GL_EXT_framebuffer_object)
  if (FBO_MAX == -1)
  {
    if (testProc(glProgramStringARB,"glProgramStringARB") &&
      testProc(glGenProgramsARB,"glGenProgramsARB") &&
      testProc(glBindProgramARB,"glBindProgramARB") &&
      testProc(glIsProgramARB,"glIsProgramARB") &&
      testProc(glProgramLocalParameter4fvARB,"glProgramLocalParameter4fvARB") &&
      testProc(glDeleteProgramsARB,"glDeleteProgramsARB") &&
      testProc(glGenFramebuffersEXT,"glGenFramebuffersEXT") &&
      testProc(glGenRenderbuffersEXT,"glGenRenderbuffersEXT") &&
      testProc(glBindFramebufferEXT,"glBindFramebufferEXT") &&
      testProc(glFramebufferTexture2DEXT,"glFramebufferTexture2DEXT") &&
      testProc(glBindRenderbufferEXT,"glBindRenderbufferEXT") &&
      testProc(glRenderbufferStorageEXT,"glRenderbufferStorageEXT") &&
      testProc(glFramebufferRenderbufferEXT,"glFramebufferRenderbufferEXT") &&
      testProc(glCheckFramebufferStatusEXT,"glCheckFramebufferStatusEXT") &&
      testProc(glDeleteRenderbuffersEXT,"glDeleteRenderbuffersEXT") &&
      testProc(glDeleteFramebuffersEXT,"glDeleteFramebuffersEXT"))
    {
      glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE_EXT,&FBO_MAX);
    }
    else
    {
      FBO_MAX = 0;
    }
  }
  return(FBO_MAX);
#else
  return(0);
#endif
}

/* Get max square array width for a given GPGPU data size */
int gpgpu_width(int len)
{
  int max = gpgpu_size();
  if (max && len && !(len%3))
  {
    int count = len / 3;
    int w = (int)sqrt(count);

    while ((w <= count) && (w <= max))
    {
      if (!(count%w)) return(w);
      w++;
    }
  }
  return(0);
}

#ifdef GL_ARB_fragment_program
static char affine_prog[] =
  "!!ARBfp1.0\n"
  "PARAM affine[4] = {program.local[0..3]};\n"
  "TEMP decal;\n"
  "TEX decal, fragment.texcoord[0], texture[0], RECT;\n"
  "MOV decal.w, 1.0;\n"
  "DP4 result.color.x, decal, affine[0];\n"
  "DP4 result.color.y, decal, affine[1];\n"
  "DP4 result.color.z, decal, affine[2];\n"
  "END\n";

/* Enable affine shader program */
void enable_affine(oga_struct * oga)
{
  if (!oga) return;
  if (!oga->affine_handle)
  {
    /* Load shader program */
    glGenProgramsARB(1,&oga->affine_handle);
    glBindProgramARB(GL_FRAGMENT_PROGRAM_ARB,oga->affine_handle);
    glProgramStringARB(GL_FRAGMENT_PROGRAM_ARB,
      GL_PROGRAM_FORMAT_ASCII_ARB, strlen(affine_prog),affine_prog);

    /* Validate shader program */
    if (!glIsProgramARB(oga->affine_handle))
    {
      GLint errorPos;
      glGetIntegerv(GL_PROGRAM_ERROR_POSITION_ARB,&errorPos);
      if (errorPos < 0) errorPos = strlen(affine_prog);
      croak("Affine fragment program error\n%s",&affine_prog[errorPos]);
    }
  }
  glEnable(GL_FRAGMENT_PROGRAM_ARB);
}

/* Disable affine shader program */
void disable_affine(oga_struct * oga)
{
  if (!oga) return;
  if (oga->affine_handle) glDisable(GL_FRAGMENT_PROGRAM_ARB);
}
#endif

#ifdef GL_EXT_framebuffer_object
/* Unbind an FBO to an OGA */
void release_fbo(oga_struct * oga)
{
  if (oga->fbo_handle)
  {
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glDeleteFramebuffersEXT(1,&oga->fbo_handle);
  }

  if (oga->tex_handle[0] || oga->tex_handle[1])
  {
    glBindTexture(oga->target,0);	
    if (oga->tex_handle[0]) glDeleteTextures(1,&oga->tex_handle[0]);
    if (oga->tex_handle[1]) glDeleteTextures(1,&oga->tex_handle[1]);
  }
}

/* Enable an FBO bound to an OGA */
void enable_fbo(oga_struct * oga, int w, int h, GLuint target,
  GLuint pixel_type, GLuint pixel_format, GLuint element_size)
{
  if (!oga) return;

  if ((oga->fbo_w != w) || (oga->fbo_h != h) ||
    (oga->target != target) ||
    (oga->pixel_type != pixel_type) ||
    (oga->pixel_format != pixel_format) ||
    (oga->element_size != element_size)) release_fbo(oga);

  if (!oga->fbo_handle)
  {
    GLenum status;

    /* Save params */
    oga->fbo_w = w;
    oga->fbo_h = h;
    oga->target = target;
    oga->pixel_type = pixel_type;
    oga->pixel_format = pixel_format;
    oga->element_size = element_size;

    /* Set up FBO */
    glGenTextures(2,oga->tex_handle);
    glGenFramebuffersEXT(1,&oga->fbo_handle);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,oga->fbo_handle);

    glViewport(0,0,w,h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluOrtho2D(0,w,0,h);
    glMatrixMode(GL_MODELVIEW); 
    glLoadIdentity();

    glBindTexture(target,oga->tex_handle[1]);
    glTexParameteri(target,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexParameteri(target,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(target,GL_TEXTURE_WRAP_S,GL_CLAMP);
    glTexParameteri(target,GL_TEXTURE_WRAP_T,GL_CLAMP);

    glTexImage2D(target,0,pixel_type,w,h,0,
      pixel_format,element_size,0);

    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,
      GL_COLOR_ATTACHMENT0_EXT,target,oga->tex_handle[1],0);

    status = glCheckFramebufferStatusEXT(GL_RENDERBUFFER_EXT);
    if (status) croak("enable_fbo status: %04X\n",status);
  }
  else
  {
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,oga->fbo_handle);
  }

  /* Load data */
  glBindTexture(target,oga->tex_handle[0]);
  glTexImage2D(target,0,pixel_type,w,h,0,
    pixel_format,element_size,oga->data);

  glEnable(target);
  //glDrawBuffer(GL_COLOR_ATTACHMENT0_EXT);
  glBindTexture(target,oga->tex_handle[0]);
  glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);
}

/* Disable an FBO bound to an OGA */
void disable_fbo(oga_struct * oga)
{
  if (!oga) return;
  if (oga->fbo_handle)
  {
    glDisable(oga->target);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);
  }
}
#endif




MODULE = OpenGL::GL::Top		PACKAGE = OpenGL



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

#ifdef IN_POGL_GLX_XS

# /* The following material is directly copied from Stan Melax's original OpenGL-0.4 */


int
__had_dbuffer_hack()

#ifdef HAVE_GLpc			/* GLX */

#// $ID = glpcOpenWindow($x,$y,$w,$h,$pw,$steal,$event_mask,@attribs);
HV *
glpcOpenWindow(x,y,w,h,pw,event_mask,steal, ...)
    int	x
    int	y
    int	w
    int	h
    int	pw
    long	event_mask
    int	steal
    CODE:
{
    XEvent event;
    Window pwin = (Window)pw;
    unsigned int err;
    int *attributes = default_attributes + 1;
    int *a_buf = NULL;

    RETVAL = newHV(); /* Create hash to return GL Object info */

    if(items > NUM_ARG){
        int i;
        a_buf = (int *) malloc((items-NUM_ARG+2) * sizeof(int));
        a_buf[0] = GLX_DOUBLEBUFFER; /* Preallocate */
        attributes = a_buf + 1;
        for (i=NUM_ARG; i<items; i++) {
            attributes[i-NUM_ARG] = SvIV(ST(i));
        }
        attributes[items-NUM_ARG] = None;
    }
    if (debug) {
        int i;	
        for (i=0; attributes[i] != None; i++) {
            printf("att=%d %d\n", i, attributes[i]);
        }
    }
    /* get a connection */
    if (!dpy_open) {
        dpy = XOpenDisplay(NULL);
        dpy_open = 1;
    }
    if (!dpy) {
        croak("ERROR: failed to get an X connection");
    } else if (debug) {
        printf("Display open %x\n", dpy);
    }		

    /* get an appropriate visual */
    vi = glXChooseVisual(dpy, DefaultScreen(dpy), attributes);
    if (!vi) { /* Might have happened that one does not
                * *need* DOUBLEBUFFER, but the display does
                * not provide SINGLEBUFFER; and the semantic
                * of GLX_DOUBLEBUFFER is that if it misses,
                * only SINGLEBUFFER visuals are selected.  */
        attributes--; /* GLX_DOUBLEBUFFER preallocated there */
        vi = glXChooseVisual(dpy, DefaultScreen(dpy), attributes); /* Retry */
        if (vi)
            DBUFFER_HACK = 1;
    }
    if (a_buf)
        free(a_buf);
    if(!vi) {
        croak("ERROR: failed to get an X visual\n");
    } else if (debug) {
        printf("Visual open %x\n", vi);
    }		

    /* A blank line here will confuse xsubpp ;-) */
#ifdef HAVE_GLX
    /* create a GLX context */
    ctx = glXCreateContext(dpy, vi, 0, GL_TRUE);
    if (!ctx) {
        croak("ERROR: failed to get an X Context");
    } else if (debug) {
        printf("Context Created %x\n", ctx);
    }

    /* create a color map */
    cmap = XCreateColormap(dpy, RootWindow(dpy, vi->screen),
            vi->visual, AllocNone);

    /* create a window */
    swa.colormap = cmap;
    swa.border_pixel = 0;
    swa.event_mask = event_mask;
#endif	/* defined HAVE_GLX */

    if (!pwin) {
        pwin = RootWindow(dpy, vi->screen);
        if (debug) printf("Using root as parent window 0x%x\n", pwin);
    }
    if (steal) {
        win = nativeWindowId(dpy, pwin); /* What about depth/visual */
    } else {
        win = XCreateWindow(dpy, pwin, 
                x, y, w, h,
                0, vi->depth, InputOutput, vi->visual,
                CWBorderPixel|CWColormap|CWEventMask, &swa);
        /* NOTE: PDL code had CWBackPixel above */
    }
    if (!win) {
        croak("No Window");
    } else {
        if (debug) printf("win = 0x%x\n", win);
    }
    XMapWindow(dpy, win);
#ifndef HAVE_GLX  /* For OS/2 GLX emulation stuff -chm 2009.09.14 */
    /* On OS/2: cannot create a context before mapping something... */
    /* create a GLX context */
    ctx = glXCreateContext(dpy, vi, 0, GL_TRUE);
    if (!ctx)
        croak("No context!\n");

    LastEventMask = event_mask;
#else	/* HAVE_GLX, this is the default branch */
    if ( (event_mask & StructureNotifyMask) && !steal ) {
        XIfEvent(dpy, &event, WaitForNotify, (char*)win);
    }
#endif	/* not defined HAVE_GLX */

    /* connect the context to the window */
    if (!glXMakeCurrent(dpy, win, ctx))
        croak("Non current");

    if (debug)
        printf("Display=0x%x Window=0x%x Context=0x%x\n",dpy, win, ctx);

    /* Create the GL object hash information */
    hv_store(RETVAL, "Display", strlen("Display"), newSViv(PTR2IV(dpy)), 0);
    hv_store(RETVAL, "Window", strlen("Window"),   newSViv(  (IV) win ), 0);
    hv_store(RETVAL, "Context", strlen("Context"), newSViv(PTR2IV(ctx)), 0);

    hv_store(RETVAL, "GL_Version",strlen("GL_Version"), 
            newSVpv((char *) glGetString(GL_VERSION),0),0);
    hv_store(RETVAL, "GL_Vendor",strlen("GL_Vendor"), 
            newSVpv((char *) glGetString(GL_VENDOR),0),0);
    hv_store(RETVAL, "GL_Renderer",strlen("GL_Renderer"), 
            newSVpv((char *) glGetString(GL_RENDERER),0),0);

    /* clear the buffer */
    glClearColor(0,0,0,1);
    while ( (err = glGetError()) != GL_NO_ERROR ) {
        printf("ERROR issued in GL %s\n", gluErrorString(err));
    }
}
OUTPUT:
RETVAL

#// glpRasterFont(name,base,number,d)
int
glpRasterFont(name,base,number,d)
        char *name
        int base
        int number
        Display *d
        CODE:
        {
                XFontStruct *fi;
                int lb;
                fi = XLoadQueryFont(d,name);
                if(fi == NULL) {
                        die("No font %s found",name);
                }
                lb = glGenLists(number);
                if(lb == 0) {
                        die("No display lists left for font %s (need %d)",name,number);
                }
                glXUseXFont(fi->fid, base, number, lb);
                RETVAL=lb;
        }
        OUTPUT:
        RETVAL

#// glpPrintString(base,str);
void
glpPrintString(base,str)
        int base
        char *str
        CODE:
        {
                glPushAttrib(GL_LIST_BIT);
                glListBase(base);
                glCallLists(strlen(str),GL_UNSIGNED_BYTE,(GLubyte*)str);
                glPopAttrib();
        }

#// glpDisplay();
Display *
glpDisplay(name)
        char *name
	CODE:
	    /* get a connection */
	    if (!dpy_open) {
		dpy = XOpenDisplay(name);
		dpy_open = 1;
	    }
	    if (!dpy)
		croak("No display!");
	    RETVAL = dpy;
        OUTPUT:
	RETVAL

#// glpMoveResizeWindow($x, $y, $width, $height[, $winID[, $display]]);
void
glpMoveResizeWindow(x, y, width, height, w=win, d=dpy)
    void* d
    GLXDrawable w
    int x
    int y
    unsigned int width
    unsigned int height

#// glpMoveWindow($x, $y[, $winID[, $display]]);
void
glpMoveWindow(x, y, w=win, d=dpy)
    void* d
    GLXDrawable w
    int x
    int y

#// glpResizeWindow($width, $height[, $winID[, $display]])
void
glpResizeWindow(width, height, w=win, d=dpy)
    void* d
    GLXDrawable w
    unsigned int width
    unsigned int height

# If glpOpenWindow was used then glXSwapBuffers should be called
# without parameters (i.e. use the default parameters)

#// glXSwapBuffers([$winID[, $display]])
void
glXSwapBuffers(w=win,d=dpy)
	void *	d
	GLXDrawable	w
	CODE:
	{
	    glXSwapBuffers(d,w);
	}

#// XPending([$display]);
int
XPending(d=dpy)
	void *	d
	CODE:
	{
		RETVAL = XPending(d);
	}
	OUTPUT:
	RETVAL

#// glpXNextEvent([$display]);
void
glpXNextEvent(d=dpy)
	void *	d
	PPCODE:
	{
		XEvent event;
		char buf[10];
		KeySym ks;
		XNextEvent(d,&event);
		switch(event.type) {
			case ConfigureNotify:
				EXTEND(sp,3);
				PUSHs(sv_2mortal(newSViv(event.type)));
				PUSHs(sv_2mortal(newSViv(event.xconfigure.width)));
				PUSHs(sv_2mortal(newSViv(event.xconfigure.height)));				
				break;
			case KeyPress:
			case KeyRelease:
				EXTEND(sp,2);
				PUSHs(sv_2mortal(newSViv(event.type)));
				XLookupString(&event.xkey,buf,sizeof(buf),&ks,0);
				buf[0]=(char)ks;buf[1]='\0';
				PUSHs(sv_2mortal(newSVpv(buf,1)));
				break;
			case ButtonPress:
			case ButtonRelease:
				EXTEND(sp,7);
				PUSHs(sv_2mortal(newSViv(event.type)));
				PUSHs(sv_2mortal(newSViv(event.xbutton.button)));
				PUSHs(sv_2mortal(newSViv(event.xbutton.x)));
				PUSHs(sv_2mortal(newSViv(event.xbutton.y)));
				PUSHs(sv_2mortal(newSViv(event.xbutton.x_root)));
				PUSHs(sv_2mortal(newSViv(event.xbutton.y_root)));
				PUSHs(sv_2mortal(newSViv(event.xbutton.state)));
				break;
			case MotionNotify:
				EXTEND(sp,4);
				PUSHs(sv_2mortal(newSViv(event.type)));
				PUSHs(sv_2mortal(newSViv(event.xmotion.state)));
				PUSHs(sv_2mortal(newSViv(event.xmotion.x)));
				PUSHs(sv_2mortal(newSViv(event.xmotion.y)));
				break;
			case Expose:
			default:
				EXTEND(sp,1);
				PUSHs(sv_2mortal(newSViv(event.type)));
				break;
		}
	}

#// glpXQueryPointer([$winID[, $display]]);
void
glpXQueryPointer(w=win,d=dpy)
	void *	d
	GLXDrawable	w
	PPCODE:
	{
		int x,y,rx,ry;
		Window r,c;
		unsigned int m;
		XQueryPointer(d,w,&r,&c,&rx,&ry,&x,&y,&m);
		EXTEND(sp,3);
		PUSHs(sv_2mortal(newSViv(x)));
		PUSHs(sv_2mortal(newSViv(y)));
		PUSHs(sv_2mortal(newSViv(m)));
	}

#endif /* defined HAVE_GLpc */


#// glpSetDebug(flag);
void
glpSetDebug(flag)
        int flag
        CODE:
        {
        debug = flag;
        }


#//# glpReadTex($file);
void
glpReadTex(file)
	char *	file
	CODE:
	{
		GLsizei w,h;
		int d,i;
		char buf[250];
		unsigned char *image;
		FILE *fp;
		char *ret;

		fp=fopen(file,"r");

		if(!fp)	croak("couldn't open file %s",file);

		ret = fgets(buf,250,fp);		/* P3 */

		if (buf[0] != 'P' || buf[1] != '3')
			croak("Format is not P3 in file %s",file);

		ret = fgets(buf,250,fp);

		while (buf[0] == '#' && fgets(buf,250,fp));	/* Empty */

		if (2 != sscanf(buf,"%d%d",&w,&h))
			croak("couldn't read image size from file %s",file);
		if (1 != fscanf(fp,"%d",&d))
			croak("couldn't read image depth from file %s",file);
		if(d != 255)
			croak("image depth != 255 in file %s unsupported",file);
		if(w>10000 || h>10000)
			croak("suspicious size w=%d d=%d in file %s", w, d, file);

		New(1431, image, w*h*3, unsigned char);

		for(i=0;i<w*h*3;i++) {
			int v;

			if (1 != fscanf(fp,"%d",&v)) {
				Safefree(image);
				croak("Error reading number #%d of %d from file %s", i, w*h*3,file);
			}

			image[i]=(unsigned char) v;
		}

		fclose(fp);

		glTexImage2D(GL_TEXTURE_2D, 0, 3, w,h, 
			0, GL_RGB, GL_UNSIGNED_BYTE,image);
	}

#//# glpHasGLUT();
int
glpHasGLUT()
	CODE:
	{
#if defined(HAVE_GLUT) || defined(HAVE_FREEGLUT)
		RETVAL = 1;
#else
		RETVAL = 0;
#endif /* defined HAVE_GLUT or HAVE_FREEGLUT */
	}
	OUTPUT:
		RETVAL


#//# glpHasGPGPU();
int
glpHasGPGPU()
	CODE:
		RETVAL = gpgpu_size();
	OUTPUT:
		RETVAL

#endif /* End IN_POGL_GLX_XS */
