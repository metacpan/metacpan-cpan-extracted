#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <X11/Xlib.h>
#include <GL/glx.h>

static Display *dpy = 0;
static Window win;
static XVisualInfo *vi;
static GLXContext cx;

MODULE = OpenGL::XScreenSaver          PACKAGE = OpenGL::XScreenSaver

PROTOTYPES: DISABLE

int
xss_connect()
	CODE:
		if (!dpy)
			dpy = XOpenDisplay(0);

		if (!dpy) {
			XSRETURN_NO;
		} else {
			XSRETURN_YES;
		}

int
xss_init_gl(wid)
	int wid
	CODE:
		win = wid;

		vi = glXChooseVisual(dpy, DefaultScreen(dpy), (int[]){ GLX_RGBA, GLX_DOUBLEBUFFER, None });
		cx = glXCreateContext(dpy, vi, 0, GL_TRUE);

		if (!win) {
			win = XCreateSimpleWindow(dpy, RootWindow(dpy, vi->screen), 0, 0, 640, 480, 0, 0, 0);
			XMapWindow(dpy, win);
		}

		glXMakeCurrent(dpy, win, cx);

		XSRETURN_YES;

void
xss_update_frame()
	CODE:
		glXSwapBuffers(dpy, win);

void
xss_update_viewport()
	CODE:
		XWindowAttributes xwa;
		XGetWindowAttributes(dpy, win, &xwa);
		glXMakeCurrent(dpy, win, cx);
		glViewport(0, 0, xwa.width, xwa.height);

int
xss_root_window()
	CODE:
		RETVAL = DefaultRootWindow(dpy);
	OUTPUT:
		RETVAL

void
xss_viewport_dimensions()
	PPCODE:
		XWindowAttributes xwa;
		XGetWindowAttributes(dpy, win, &xwa);
		XPUSHs(sv_2mortal(newSVnv(xwa.width)));
		XPUSHs(sv_2mortal(newSVnv(xwa.height)));

