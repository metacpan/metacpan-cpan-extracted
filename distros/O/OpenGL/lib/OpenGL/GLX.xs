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

#ifdef HAVE_GLU
#include "glu_util.h"
#endif

#ifdef HAVE_GLX
#include "glx_util.h"
#endif /* defined HAVE_GLX */

#ifdef HAVE_GLX
#  define nativeWindowId(d, w)	(w)
static Bool WaitForNotify(Display *d, XEvent *e, char *arg) {
    return (e->type == MapNotify) && (e->xmap.window == (Window)arg);
}
#  define glpResizeWindow(s1,s2,w,d)	XResizeWindow(d,w,s1,s2)
#  define glpMoveWindow(s1,s2,w,d)		XMoveWindow(d,w,s1,s2)
#  define glpMoveResizeWindow(s1,s2,s3,s4,w,d)	XMoveResizeWindow(d,w,s1,s2,s3,s4)
#endif	/* defined HAVE_GLX */ 

static int debug = 0;

#ifdef HAVE_GLX

#  define NUM_ARG 7			/* Number of mandatory args to glpcOpenWindow */

Display *dpy;
int dpy_open;
XVisualInfo *vi;
Colormap cmap;
XSetWindowAttributes swa;
Window win;
GLXContext ctx;

static int default_attributes[] = { GLX_DOUBLEBUFFER, GLX_RGBA, None };

#endif	/* defined HAVE_GLX */

static int DBUFFER_HACK = 0;
#define __had_dbuffer_hack() (DBUFFER_HACK)


MODULE = OpenGL::GLX		PACKAGE = OpenGL::GLX



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
#ifdef HAVE_GLX
	RETVAL = 1;
#else
	RETVAL = 0;
#endif /* defined HAVE_GLX */
	OUTPUT:
	RETVAL

# /* The following material is directly copied from Stan Melax's original OpenGL-0.4 */

int
__had_dbuffer_hack()

#ifdef HAVE_GLX			/* GLX */

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
        printf("Display open %p\n", dpy);
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
        printf("Visual open %p\n", vi);
    }		

    /* A blank line here will confuse xsubpp ;-) */
#ifdef HAVE_GLX
    /* create a GLX context */
    ctx = glXCreateContext(dpy, vi, 0, GL_TRUE);
    if (!ctx) {
        croak("ERROR: failed to get an X Context");
    } else if (debug) {
        printf("Context Created %p\n", ctx);
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
        if (debug) printf("Using root as parent window 0x%lx\n", pwin);
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
        if (debug) printf("win = 0x%lx\n", win);
    }
    XMapWindow(dpy, win);
    if ( (event_mask & StructureNotifyMask) && !steal ) {
        XIfEvent(dpy, &event, WaitForNotify, (char*)win);
    }

    /* connect the context to the window */
    if (!glXMakeCurrent(dpy, win, ctx))
        croak("Non current");

    if (debug)
        printf("Display=%p Window=0x%lx Context=%p\n",dpy, win, ctx);

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
		if (!d) croak("ERROR: called XPending with null X connection");
		RETVAL = XPending(d);
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

#endif /* defined HAVE_GLX */


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

BOOT:
{
   HV *stash = gv_stashpvn("OpenGL::GLX", strlen("OpenGL::GLX"), TRUE);
#include "glx_const.h"
}
