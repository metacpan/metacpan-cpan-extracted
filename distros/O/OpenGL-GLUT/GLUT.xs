/*  Last saved: Mon 27 Feb 2017 01:28:00 PM */

/*  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 2009 Chris Marshall. All rights reserved.
 *  Copyright (c) 2015 Bob Free. All rights reserved.
 *  Copyright (c) 2016,2017 Chris Marshall. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

#include <stdio.h>

#include "pgopogl.h"

#define IN_POGL_MAIN_XS

#ifdef IN_POGL_MAIN_XS

=head2 Miscellaneous

Various BOOT utilities defined in GLUT.xs

=over

=item PGOPOGL_CALL_BOOT(name)

call the boot code of a module by symbol rather than by name.

in a perl extension which uses several xs files but only one pm, you
need to bootstrap the other xs files in order to get their functions
exported to perl.  if the file has MODULE = Foo::Bar, the boot symbol
would be boot_Foo__Bar.

=item void _pgopogl_call_XS (pTHX_ void (*subaddr) (pTHX_ CV *), CV * cv, SV ** mark);

never use this function directly.  see C<PGOPOGLL_CALL_BOOT>.

for the curious, this calls a perl sub by function pointer rather than
by name; call_sv requires that the xsub already be registered, but we
need this to call a function which will register xsubs.  this is an
evil hack and should not be used outside of the PGOPOGL_CALL_BOOT macro.
it's implemented as a function to avoid code size bloat, and exported
so that extension modules can pull the same trick.

=back

=cut

void
_pgopogl_call_XS (pTHX_ void (*subaddr) (pTHX_ CV *), CV * cv, SV ** mark)
{
	dSP;
	PUSHMARK (mark);
	(*subaddr) (aTHX_ cv);
	PUTBACK;	/* forget return values */
}
#endif /* End IN_POGL_MAIN_XS */


/* glut_util.h is where you include the appropriate GLUT header
 * file based on what is available.  It also defines some constants
 * that may not be defined everywhere.  Replace this by user
 * specified include information for the include and compile-time
 * perl constants rather than some special cases
 */
#include "glut_util.h"


/* TODO: calculate this from the actual GLUT include file */
#ifndef GLUT_API_VERSION
#define GLUT_API_VERSION 4
#endif

static int _done_glutInit = 0;
static int _done_glutCloseFunc_warn = 0;


/* Macros for GLUT callback and handler declarations */
#  define DO_perl_call_sv(handler, flag) perl_call_sv(handler, flag)
#  define ENSURE_callback_thread
#  define GLUT_PUSH_NEW_SV(sv)		XPUSHs(sv_2mortal(newSVsv(sv)))
#  define GLUT_PUSH_NEW_IV(i)		XPUSHs(sv_2mortal(newSViv(i)))
#  define GLUT_PUSH_NEW_U8(c)		XPUSHs(sv_2mortal(newSViv((int)c)))
#  define GLUT_EXTEND_STACK(sp,n)
#  define GLUT_PUSHMARK(sp)		PUSHMARK(sp)


/* Set up for all the GLUT callback handlers */
static AV * glut_handlers = 0;

/* Attach a handler to a window */
static void set_glut_win_handler(int win, int type, SV * data)
{
	SV ** h;
	AV * a;
	
	if (!glut_handlers)
		glut_handlers = newAV();
	
	h = av_fetch(glut_handlers, win, FALSE);
	
	if (!h) {
		a = newAV();
		av_store(glut_handlers, win, newRV_inc((SV*)a));
		SvREFCNT_dec(a);
	} else if (!SvOK(*h) || !SvROK(*h))
		croak("Unable to establish glut handler");
	else 
		a = (AV*)SvRV(*h);
	
	av_store(a, type, newRV_inc(data));
	SvREFCNT_dec(data);
}

/* Get a window's handler */
static SV * get_glut_win_handler(int win, int type)
{
	SV ** h;
	
	if (!glut_handlers)
		croak("Unable to locate glut handler");
	
	h = av_fetch(glut_handlers, win, FALSE);

	if (!h || !SvOK(*h) || !SvROK(*h))
		croak("Unable to locate glut handler");
	
	h = av_fetch((AV*)SvRV(*h), type, FALSE);
	
	if (!h || !SvOK(*h) || !SvROK(*h))
		croak("Unable to locate glut handler");

	return SvRV(*h);
}

/* Release a window's handlers */
static void destroy_glut_win_handlers(int win)
{
	SV ** h;
	
	if (!glut_handlers)
		return;
	
	h = av_fetch(glut_handlers, win, FALSE);
	
	if (!h || !SvOK(*h) || !SvROK(*h))
		return;

	av_store(glut_handlers, win, newSVsv(&PL_sv_undef));
}

/* Release a handler */
static void destroy_glut_win_handler(int win, int type)
{
	SV ** h;
	AV * a;
	
	if (!glut_handlers)
		glut_handlers = newAV();
	
	h = av_fetch(glut_handlers, win, FALSE);
	
	if (!h || !SvOK(*h) || !SvROK(*h))
		return;

	a = (AV*)SvRV(*h);
	
	av_store(a, type, newSVsv(&PL_sv_undef));
}

/* Begin window callback definition */
#define begin_decl_gwh(type, params, nparam)				\
									\
static void generic_glut_ ## type ## _handler params			\
{									\
	int win = glutGetWindow();					\
	AV * handler_data = (AV*)get_glut_win_handler(win, HANDLE_GLUT_ ## type);\
	SV * handler;							\
	int i;								\
	dSP;								\
									\
	handler = *av_fetch(handler_data, 0, 0);			\
									\
	GLUT_PUSHMARK(sp);						\
	GLUT_EXTEND_STACK(sp,av_len(handler_data)+nparam);		\
	for (i=1;i<=av_len(handler_data);i++)				\
		GLUT_PUSH_NEW_SV(*av_fetch(handler_data, i, 0));

/* End window callback definition */
#define end_decl_gwh()							\
	PUTBACK;							\
	DO_perl_call_sv(handler, G_DISCARD);				\
}

/* Activate a window callback handler */
#define decl_gwh_xs(type)						\
	{								\
		int win = glutGetWindow();				\
									\
		if (!handler || !SvOK(handler)) {			\
			destroy_glut_win_handler(win, HANDLE_GLUT_ ## type);\
			glut ## type ## Func(NULL);			\
		} else {						\
			AV * handler_data = newAV();			\
									\
			PackCallbackST(handler_data, 0);		\
									\
			set_glut_win_handler(win, HANDLE_GLUT_ ## type, (SV*)handler_data);\
									\
			glut ## type ## Func(generic_glut_ ## type ## _handler);\
		}							\
	ENSURE_callback_thread;}

/* Activate a window callback handler; die on failure */
#define decl_gwh_xs_nullfail(type, fail)				\
	{								\
		int win = glutGetWindow();				\
									\
		if (!handler || !SvOK(handler)) {			\
			croak fail;					\
		} else {						\
			AV * handler_data = newAV();			\
									\
			PackCallbackST(handler_data, 0);		\
									\
			set_glut_win_handler(win, HANDLE_GLUT_ ## type, (SV*)handler_data);\
									\
			glut ## type ## Func(generic_glut_ ## type ## _handler);\
		}							\
	ENSURE_callback_thread;}


/* Activate a global state callback handler */
#define decl_ggh_xs(type)						\
	{								\
		if (glut_ ## type ## _handler_data)			\
			SvREFCNT_dec(glut_ ## type ## _handler_data);	\
									\
		if (!handler || !SvOK(handler)) {			\
			glut_ ## type ## _handler_data = 0;		\
			glut ## type ## Func(NULL);			\
		} else {						\
			AV * handler_data = newAV();			\
									\
			PackCallbackST(handler_data, 0);		\
									\
			glut_ ## type ## _handler_data = handler_data;	\
									\
			glut ## type ## Func(generic_glut_ ## type ## _handler);\
		}							\
	ENSURE_callback_thread;}


/* Begin a global state callback definition */
#define begin_decl_ggh(type, params, nparam)				\
									\
static AV * glut_ ## type ## _handler_data = 0;				\
									\
static void generic_glut_ ## type ## _handler params			\
{									\
	AV * handler_data = glut_ ## type ## _handler_data;		\
	SV * handler;							\
	int i;								\
	dSP;								\
									\
	handler = *av_fetch(handler_data, 0, 0);			\
									\
	GLUT_PUSHMARK(sp);						\
	GLUT_EXTEND_STACK(sp,av_len(handler_data)+nparam);		\
	for (i=1;i<=av_len(handler_data);i++)				\
		GLUT_PUSH_NEW_SV(*av_fetch(handler_data, i, 0));

/* End a global state callback definition */
#define end_decl_ggh()							\
	PUTBACK;							\
	DO_perl_call_sv(handler, G_DISCARD);				\
}

/* Define callbacks */
enum {
	HANDLE_GLUT_Display,
	HANDLE_GLUT_OverlayDisplay,
	HANDLE_GLUT_Reshape,
	HANDLE_GLUT_Keyboard,
	HANDLE_GLUT_KeyboardUp,
	HANDLE_GLUT_Mouse,
    HANDLE_GLUT_MouseWheel,             /* Open/FreeGLUT -chm */
	HANDLE_GLUT_Motion,
	HANDLE_GLUT_PassiveMotion,
	HANDLE_GLUT_Entry,
	HANDLE_GLUT_Visibility,
	HANDLE_GLUT_WindowStatus,
	HANDLE_GLUT_Special,
	HANDLE_GLUT_SpecialUp,
    HANDLE_GLUT_Joystick,               /* Open/FreeGLUT -chm */
	HANDLE_GLUT_SpaceballMotion,
	HANDLE_GLUT_SpaceballRotate,
	HANDLE_GLUT_SpaceballButton,
	HANDLE_GLUT_ButtonBox,
	HANDLE_GLUT_Dials,
	HANDLE_GLUT_TabletMotion,
	HANDLE_GLUT_TabletButton,
    HANDLE_GLUT_MenuDestroy,            /* Open/FreeGLUT -chm */
	HANDLE_GLUT_Close,                  /* Open/FreeGLUT -chm */
	HANDLE_GLUT_WMClose,                /* AGL GLUT      -chm */
};

/* Callback for glutDisplayFunc */
begin_decl_gwh(Display, (void), 0)
end_decl_gwh()

/* Callback for glutOverlayDisplayFunc */
begin_decl_gwh(OverlayDisplay, (void), 0)
end_decl_gwh()

/* Callback for glutReshapeFunc */
begin_decl_gwh(Reshape, (int width, int height), 2)
	GLUT_PUSH_NEW_IV(width);
	GLUT_PUSH_NEW_IV(height);
end_decl_gwh()

/* Callback for glutKeyboardFunc */
begin_decl_gwh(Keyboard, (unsigned char key, int width, int height), 3)
	GLUT_PUSH_NEW_U8(key);
	GLUT_PUSH_NEW_IV(width);
	GLUT_PUSH_NEW_IV(height);
end_decl_gwh()

/* Callback for glutKeyboardUpFunc */
begin_decl_gwh(KeyboardUp, (unsigned char key, int width, int height), 3)
	GLUT_PUSH_NEW_U8(key);
	GLUT_PUSH_NEW_IV(width);
	GLUT_PUSH_NEW_IV(height);
end_decl_gwh()

/* Callback for glutMouseFunc */
begin_decl_gwh(Mouse, (int button, int state, int x, int y), 4)
	GLUT_PUSH_NEW_IV(button);
	GLUT_PUSH_NEW_IV(state);
	GLUT_PUSH_NEW_IV(x);
	GLUT_PUSH_NEW_IV(y);
end_decl_gwh()

/* Callback for glutMouseWheelFunc */	/* Open/FreeGLUT -chm */
begin_decl_gwh(MouseWheel, (int wheel, int direction, int x, int y), 4)
	GLUT_PUSH_NEW_IV(wheel);
	GLUT_PUSH_NEW_IV(direction);
	GLUT_PUSH_NEW_IV(x);
	GLUT_PUSH_NEW_IV(y);
end_decl_gwh()

/* Callback for glutPassiveMotionFunc */
begin_decl_gwh(PassiveMotion, (int x, int y), 2)
	GLUT_PUSH_NEW_IV(x);
	GLUT_PUSH_NEW_IV(y);
end_decl_gwh()

/* Callback for glutMotionFunc */
begin_decl_gwh(Motion, (int x, int y), 2)
	GLUT_PUSH_NEW_IV(x);
	GLUT_PUSH_NEW_IV(y);
end_decl_gwh()

/* Callback for glutVisibilityFunc */
begin_decl_gwh(Visibility, (int state), 1)
	GLUT_PUSH_NEW_IV(state);
end_decl_gwh()

/* Callback for glutWindowStatusFunc */
begin_decl_gwh(WindowStatus, (int state), 1)
	GLUT_PUSH_NEW_IV(state);
end_decl_gwh()

/* Callback for glutEntryFunc */
begin_decl_gwh(Entry, (int state), 1)
	GLUT_PUSH_NEW_IV(state);
end_decl_gwh()

/* Callback for glutSpecialFunc */
begin_decl_gwh(Special, (int key, int width, int height), 3)
	GLUT_PUSH_NEW_IV(key);
	GLUT_PUSH_NEW_IV(width);
	GLUT_PUSH_NEW_IV(height);
end_decl_gwh()

/* Callback for glutSpecialUpFunc */
begin_decl_gwh(SpecialUp, (int key, int width, int height), 3)
	GLUT_PUSH_NEW_IV(key);
	GLUT_PUSH_NEW_IV(width);
	GLUT_PUSH_NEW_IV(height);
end_decl_gwh()

/* Callback for glutJoystickFunc */	/* Open/FreeGLUT -chm */
begin_decl_gwh(Joystick, (unsigned int buttons, int xaxis, int yaxis, int zaxis), 4)
	GLUT_PUSH_NEW_IV(buttons);
	GLUT_PUSH_NEW_IV(xaxis);
	GLUT_PUSH_NEW_IV(yaxis);
	GLUT_PUSH_NEW_IV(zaxis);
end_decl_gwh()


/* Callback for glutSpaceballMotionFunc */
begin_decl_gwh(SpaceballMotion, (int x, int y, int z), 3)
	GLUT_PUSH_NEW_IV(x);
	GLUT_PUSH_NEW_IV(y);
	GLUT_PUSH_NEW_IV(z);
end_decl_gwh()

/* Callback for glutSpaceballRotateFunc */
begin_decl_gwh(SpaceballRotate, (int x, int y, int z), 3)
	GLUT_PUSH_NEW_IV(x);
	GLUT_PUSH_NEW_IV(y);
	GLUT_PUSH_NEW_IV(z);
end_decl_gwh()

/* Callback for glutSpaceballButtonFunc */
begin_decl_gwh(SpaceballButton, (int button, int state), 2)
	GLUT_PUSH_NEW_IV(button);
	GLUT_PUSH_NEW_IV(state);
end_decl_gwh()

/* Callback for glutButtonBoxFunc */
begin_decl_gwh(ButtonBox, (int button, int state), 2)
	GLUT_PUSH_NEW_IV(button);
	GLUT_PUSH_NEW_IV(state);
end_decl_gwh()

/* Callback for glutDialsFunc */
begin_decl_gwh(Dials, (int dial, int value), 2)
	GLUT_PUSH_NEW_IV(dial);
	GLUT_PUSH_NEW_IV(value);
end_decl_gwh()

/* Callback for glutTabletMotionFunc */
begin_decl_gwh(TabletMotion, (int x, int y), 2)
	GLUT_PUSH_NEW_IV(x);
	GLUT_PUSH_NEW_IV(y);
end_decl_gwh()

/* Callback for glutTabletButtonFunc */
begin_decl_gwh(TabletButton, (int button, int state, int x, int y), 4)
	GLUT_PUSH_NEW_IV(button);
	GLUT_PUSH_NEW_IV(state);
	GLUT_PUSH_NEW_IV(x);
	GLUT_PUSH_NEW_IV(y);
end_decl_gwh()

/* Callback for glutIdleFunc */
begin_decl_ggh(Idle, (void), 0)
end_decl_ggh()

/* Callback for glutMenuStatusFunc */
begin_decl_ggh(MenuStatus, (int status, int x, int y), 3)
	GLUT_PUSH_NEW_IV(status);
	GLUT_PUSH_NEW_IV(x);
	GLUT_PUSH_NEW_IV(y);
end_decl_ggh()

/* Callback for glutMenuStateFunc */
begin_decl_ggh(MenuState, (int status), 1)
	GLUT_PUSH_NEW_IV(status);
end_decl_ggh()

/* Callback for glutMenuDestroyFunc */		/* Open/FreeGLUT -chm */
begin_decl_gwh(MenuDestroy, (void), 0)
end_decl_gwh()

/* Callback for glutCloseFunc */
#ifdef HAVE_AGL_GLUT
static void generic_glut_WMClose_handler(void)
#else
static void generic_glut_Close_handler(void)
#endif
{
	int win = glutGetWindow();
	AV * handler_data = (AV*)get_glut_win_handler(win, HANDLE_GLUT_Close);
	SV * handler = *av_fetch(handler_data, 0, 0);
	dSP;

	GLUT_PUSHMARK(sp);
	GLUT_EXTEND_STACK(sp,1);
	GLUT_PUSH_NEW_IV(win);

	PUTBACK;
	DO_perl_call_sv(handler, G_DISCARD);
}

/* Callback for glutTimerFunc */
static void generic_glut_timer_handler(int value)
{
	AV * handler_data = (AV*)value;
	SV * handler;
	int i;
	dSP;

	handler = *av_fetch(handler_data, 0, 0);

	GLUT_PUSHMARK(sp);
	GLUT_EXTEND_STACK(sp,av_len(handler_data));
	for (i=1;i<=av_len(handler_data);i++)
		GLUT_PUSH_NEW_SV(*av_fetch(handler_data, i, 0));

	PUTBACK;
	DO_perl_call_sv(handler, G_DISCARD);
	
	SvREFCNT_dec(handler_data);
}

static AV * glut_menu_handlers = 0;

/* Callback for glutMenuFunc */
static void generic_glut_menu_handler(int value)
{
	AV * handler_data;
	SV * handler;
	SV ** h;
	int i;
	dSP;
	
	h = av_fetch(glut_menu_handlers, glutGetMenu(), FALSE);
	if (!h || !SvOK(*h) || !SvROK(*h))
		croak("Unable to locate menu handler");
	
	handler_data = (AV*)SvRV(*h);

	handler = *av_fetch(handler_data, 0, 0);

	GLUT_PUSHMARK(sp);
	GLUT_EXTEND_STACK(sp,av_len(handler_data) + 1);
	for (i=1;i<=av_len(handler_data);i++)
		GLUT_PUSH_NEW_SV(*av_fetch(handler_data, i, 0));

	GLUT_PUSH_NEW_IV(value);

	PUTBACK;
	DO_perl_call_sv(handler, G_DISCARD);
}
/* End of set up for GLUT callback stuff */

/*  Last saved: Sun 06 Sep 2009 02:09:23 PM*/

/*  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 2009 Chris Marshall. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

/* This ends up being GLUT.pm */
#ifdef HAVE_GL
#include "gl_util.h"
#endif

#if defined(HAVE_GLUT) || defined(HAVE_FREEGLUT)
#ifndef GLUT_API_VERSION
#define GLUT_API_VERSION 4
#endif
#include "glut_util.h"
#endif


MODULE = OpenGL::GLUT		PACKAGE = OpenGL::GLUT

#// Test for done with glutInit
int
done_glutInit()
	CODE:
	RETVAL = _done_glutInit;
	OUTPUT:
	RETVAL


# GLUT

#//# glutInit();
void
glutInit()
	CODE:
	{
	int argc;
	char ** argv;
	AV * ARGV;
	SV * ARGV0;
	SV * sv;
	int i;

			if (_done_glutInit)
				croak("illegal glutInit() reinitialization attempt");

			argv  = 0;
			ARGV = perl_get_av("ARGV", FALSE);
			ARGV0 = perl_get_sv("0", FALSE);
			
			argc = av_len(ARGV)+2;
			if (argc) {
				argv = malloc(sizeof(char*)*argc);
				argv[0] = SvPV(ARGV0, PL_na);
				for(i=0;i<=av_len(ARGV);i++)
					argv[i+1] = SvPV(*av_fetch(ARGV, i, 0), PL_na);
			}
			
			i = argc;
			glutInit(&argc, argv);

			_done_glutInit = 1;

			while(argc<i--)
				sv = av_shift(ARGV);
			
			if (argv)
				free(argv);
	}

#//# glutInitWindowSize($width, $height);
void
glutInitWindowSize(width, height)
	int	width
	int	height

#//# glutInitWindowPosition($x, $y);
void
glutInitWindowPosition(x, y)
	int	x
	int	y

#//# glutInitDisplayMode($mode);
void
glutInitDisplayMode(mode)
	int	mode

#//# glutInitDisplayString($string);
void
glutInitDisplayString(string)
	char *	string

#//# glutMainLoop();
void
glutMainLoop()

#//# glutCreateWindow($name);
int
glutCreateWindow(name)
	char *	name
	CODE:
	RETVAL = glutCreateWindow(name);
	destroy_glut_win_handlers(RETVAL);
	OUTPUT:
	RETVAL

#//# glutCreateSubWindow($win, $x, $y, $width, $height);
int
glutCreateSubWindow(win, x, y, width, height)
	int	win
	int	x
	int	y
	int	width
	int	height
	CODE:
	RETVAL = glutCreateSubWindow(win, x, y, width, height);
	destroy_glut_win_handlers(RETVAL);
	OUTPUT:
	RETVAL

#//# glutSetWindow($win);
void
glutSetWindow(win)
	int	win

#//# glutGetWindow();
int
glutGetWindow()

#//# glutDestroyWindow($win);
void
glutDestroyWindow(win)
	int	win
	CODE:
	glutDestroyWindow(win);
	destroy_glut_win_handlers(win);

#//# glutPostRedisplay();
void
glutPostRedisplay()

#//# glutSwapBuffers();
void
glutSwapBuffers()

#//# glutPositionWindow($x, $y);
void
glutPositionWindow(x, y)
	int	x
	int	y

#//# glutReshapeWindow($width, $height);
void
glutReshapeWindow(width, height)
	int	width
	int	height

#if GLUT_API_VERSION >= 3

#//# glutFullScreen();
void
glutFullScreen()

#endif

#//# glutPopWindow();
void
glutPopWindow()

#//# glutPushWindow();
void
glutPushWindow()

#//# glutShowWindow();
void
glutShowWindow()

#//# glutHideWindow();
void
glutHideWindow()

#//# glutIconifyWindow();
void
glutIconifyWindow()

#//# glutSetWindowTitle($title);
void
glutSetWindowTitle(title)
	char *	title

#//# glutSetIconTitle($title);
void
glutSetIconTitle(title)
	char *	title

#if GLUT_API_VERSION >= 3

#//# glutSetCursor(cursor);
void
glutSetCursor(cursor)
	int	cursor

#endif

# Overlays


#if GLUT_API_VERSION >= 3

#//# glutEstablishOverlay(); 
void
glutEstablishOverlay()

#//# glutUseLayer(layer);
void
glutUseLayer(layer)
	GLenum	layer

#//# glutRemoveOverlay();
void
glutRemoveOverlay()

#//# glutPostOverlayRedisplay();
void
glutPostOverlayRedisplay()

#//# glutShowOverlay();
void
glutShowOverlay()

#//# glutHideOverlay();
void
glutHideOverlay()

#endif

# Menus

#//# $ID = glutCreateMenu(\&callback);
int
glutCreateMenu(handler=0, ...)
	SV *	handler
	CODE:
	{
		if (!handler || !SvOK(handler)) {
			croak("A handler must be specified");
		} else {
			AV * handler_data = newAV();
		
			PackCallbackST(handler_data, 0);

			RETVAL = glutCreateMenu(generic_glut_menu_handler);
			
			if (!glut_menu_handlers)
				glut_menu_handlers = newAV();
			
			av_store(glut_menu_handlers, RETVAL, newRV_inc((SV*)handler_data));
			
			SvREFCNT_dec(handler_data);
			
		}
	}
	OUTPUT:
	RETVAL

#//# glutSetMenu($menu);
void
glutSetMenu(menu)
	int	menu

#//# glutGetMenu();
int
glutGetMenu()

#//# glutDestroyMenu($menu);
void
glutDestroyMenu(menu)
	int	menu
	CODE:
	{
		glutDestroyMenu(menu);
		av_store(glut_menu_handlers, menu, newSVsv(&PL_sv_undef));
	}

#//# glutAddMenuEntry($name, $value);
void
glutAddMenuEntry(name, value)
	char *	name
	int	value

#//# glutAddSubMenu($name, $menu);
void
glutAddSubMenu(name, menu)
	char *	name
	int	menu

#//# glutChangeToMenuEntry($entry, $name, $value);
void
glutChangeToMenuEntry(entry, name, value)
	int	entry
	char *	name
	int	value

#//# glutChangeToSubMenu($entry, $name, $menu);
void
glutChangeToSubMenu(entry, name, menu)
	int	entry
	char *	name
	int	menu

#//# glutRemoveMenuItem($entry);
void
glutRemoveMenuItem(entry)
	int	entry

#//# glutAttachMenu(button);
void
glutAttachMenu(button)
	int	button

#//# glutDetachMenu(button);
void
glutDetachMenu(button)
	int	button

# Callbacks

#//# glutDisplayFunc(\&callback);
void
glutDisplayFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs_nullfail(Display, ("Display function must be specified"))

#if GLUT_API_VERSION >= 3

#//# glutOverlayDisplayFunc(\&callback);
void
glutOverlayDisplayFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(OverlayDisplay)

#endif

#//# glutReshapeFunc(\&callback);
void
glutReshapeFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(Reshape)

#//# glutKeyboardFunc(\&callback);
void
glutKeyboardFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(Keyboard)

#if GLUT_API_VERSION >= 4

#//# glutKeyboardUpFunc(\&callback);
void
glutKeyboardUpFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(KeyboardUp)

#//# glutWindowStatusFunc(\&callback);
void
glutWindowStatusFunc(handler=0, ...)
	SV *	handler
	CODE:
        {
#if defined HAVE_FREEGLUT
		decl_gwh_xs(WindowStatus)
#endif
	}

#endif

#//# glutMouseFunc(\&callback);
void
glutMouseFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(Mouse)

#//# glutMouseWheelFunc(\&callback);
void
glutMouseWheelFunc(handler=0, ...)
	SV *	handler
	CODE:
        {
#if defined HAVE_FREEGLUT
		decl_gwh_xs(MouseWheel)
#endif
	}

#//# glutMotionFunc(\&callback);
void
glutMotionFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(Motion)

#//# glutPassiveMotionFunc(\&callback);
void
glutPassiveMotionFunc(handler=0, ...)
	SV *	handler
	CODE:
	{
#if defined HAVE_FREEGLUT
		decl_gwh_xs(PassiveMotion)
#endif
	}

#//# glutVisibilityFunc(\&callback);
void
glutVisibilityFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(Visibility)

#//# glutEntryFunc(\&callback);
void
glutEntryFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(Entry)

#if GLUT_API_VERSION >= 2

#//# glutSpecialFunc(\&callback);
void
glutSpecialFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(Special)

#//# glutJoystickFunc(\&callback);	/* Open/FreeGLUT -chm */
# void					/* Not implemented, don't know how */
# glutJoystickFunc(handler=0, ...)
# 	SV *	handler
# 	CODE:
# 	decl_gwh_xs(Joystick)

#//# glutSpaceballMotionFunc(\&callback);
void
glutSpaceballMotionFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(SpaceballMotion)

#//# glutSpaceballRotateFunc(\&callback);
void
glutSpaceballRotateFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(SpaceballRotate)

#//# glutSpaceballButtonFunc(\&callback);
void
glutSpaceballButtonFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(SpaceballButton)

#//# glutButtonBoxFunc(\&callback);
void
glutButtonBoxFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(ButtonBox)

#//# glutDialsFunc(\&callback);
void
glutDialsFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(Dials)

#//# glutTabletMotionFunc(\&callback);
void
glutTabletMotionFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(TabletMotion)

#//# glutTabletButtonFunc(\&callback);
void
glutTabletButtonFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(TabletButton)

#endif

#if GLUT_API_VERSION >= 3

#//# glutMenuStatusFunc(\&callback);
void
glutMenuStatusFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_ggh_xs(MenuStatus)

#endif

#//# glutMenuStateFunc(\&callback);
void
glutMenuStateFunc(handler=0, ...)
	SV *	handler
	CODE:
	{
#if defined HAVE_FREEGLUT
		decl_ggh_xs(MenuState)
#endif
	}

#//# glutIdleFunc(\&callback);
void
glutIdleFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_ggh_xs(Idle)

#//# glutTimerFunc($msecs, \&callback);
void
glutTimerFunc(msecs, handler=0, ...)
	unsigned int	msecs
	SV *	handler
	CODE:
	{
		if (!handler || !SvOK(handler)) {
			croak("A handler must be specified");
		} else {
			AV * handler_data = newAV();
		
			PackCallbackST(handler_data, 1);
			
			glutTimerFunc(msecs, generic_glut_timer_handler, (int)handler_data);
		}
	ENSURE_callback_thread;}


# Colors

#//# glutSetColor($cell, $red, $green, $blue)
void
glutSetColor(cell, red, green, blue)
	int	cell
	GLfloat	red
	GLfloat	green
	GLfloat	blue

#//# glutGetColor($cell, $component);
GLfloat
glutGetColor(cell, component)
	int	cell
	int	component

#//# glutCopyColormap($win);
void
glutCopyColormap(win)
	int	win

# State

#//# glutGet($state);
int
glutGet(state)
	GLenum	state

#if GLUT_API_VERSION >= 3

#//# glutLayerGet(info);
int
glutLayerGet(info)
	GLenum	info

#endif

int
glutDeviceGet(info)
	GLenum	info

#if GLUT_API_VERSION >= 3

#//# glutGetModifiers();
int
glutGetModifiers()

#endif

#if GLUT_API_VERSION >= 2

#//# glutExtensionSupported($extension);
int
glutExtensionSupported(extension)
	char *	extension

#endif

# Font

#//# glutBitmapCharacter($font, $character);
void
glutBitmapCharacter(font, character)
	void *	font
	int	character

#//# glutStrokeCharacter($font, $character);
void
glutStrokeCharacter(font, character)
	void *	font
	int	character

#//# glutBitmapWidth($font, $character);
int
glutBitmapWidth(font, character)
	void *	font
	int	character

#//# glutStrokeWidth($font, $character);
int
glutStrokeWidth(font, character)
	void *	font
	int	character

#if GLUT_API_VERSION >= 3

#//# glutIgnoreKeyRepeat($ignore);
void
glutIgnoreKeyRepeat(ignore)
	int	ignore

#//# glutSetKeyRepeat($repeatMode);
void
glutSetKeyRepeat(repeatMode)
	int	repeatMode

#//# glutForceJoystickFunc();
void
glutForceJoystickFunc()

#endif

# Solids

#//# glutSolidSphere($radius, $slices, $stacks);
void
glutSolidSphere(radius, slices, stacks)
	GLdouble	radius
	GLint	slices
	GLint	stacks

#//# glutWireSphere($radius, $slices, $stacks);
void
glutWireSphere(radius, slices, stacks)
	GLdouble	radius
	GLint	slices
	GLint	stacks

#//# glutSolidCube($size);
void
glutSolidCube(size)
	GLdouble	size

#//# glutWireCube($size);
void
glutWireCube(size)
	GLdouble	size

#//# glutSolidCone($base, $height, $slices, $stacks);
void
glutSolidCone(base, height, slices, stacks)
	GLdouble	base
	GLdouble	height
	GLint	slices
	GLint	stacks

#//# glutWireCone($base, $height, $slices, $stacks);
void
glutWireCone(base, height, slices, stacks)
	GLdouble	base
	GLdouble	height
	GLint	slices
	GLint	stacks

#//# glutSolidTorus($innerRadius, $outerRadius, $nsides, $rings);
void
glutSolidTorus(innerRadius, outerRadius, nsides, rings)
	GLdouble	innerRadius
	GLdouble	outerRadius
	GLint	nsides
	GLint	rings

#//# glutWireTorus($innerRadius, $outerRadius, $nsides, $rings);
void
glutWireTorus(innerRadius, outerRadius, nsides, rings)
	GLdouble	innerRadius
	GLdouble	outerRadius
	GLint	nsides
	GLint	rings

#//# glutSolidDodecahedron();
void
glutSolidDodecahedron()

#//# glutWireDodecahedron();
void
glutWireDodecahedron()

#//# glutSolidOctahedron();
void
glutSolidOctahedron()

#//# glutWireOctahedron();
void
glutWireOctahedron()

#//# glutSolidTetrahedron();
void
glutSolidTetrahedron()

#//# glutWireTetrahedron();
void
glutWireTetrahedron()

#//# glutSolidIcosahedron();
void
glutSolidIcosahedron()

#//# glutWireIcosahedron();
void
glutWireIcosahedron()

#//# glutSolidTeapot(size);
void
glutSolidTeapot(size)
	GLdouble	size

#//# glutWireTeapot($size);
void
glutWireTeapot(size)
	GLdouble	size

#if GLUT_API_VERSION >= 4

#//# glutSpecialUpFunc(\&callback);
void
glutSpecialUpFunc(handler=0, ...)
	SV *	handler
	CODE:
	decl_gwh_xs(SpecialUp)

#//# glutGameModeString($string);
GLboolean
glutGameModeString(string)
	char *	string
	CODE:
	{
		char mode[1024];
		if (!string || !string[0])
		{
			int w = glutGet(0x00C8);	// GLUT_SCREEN_WIDTH
			int h = glutGet(0x00C9);	// GLUT_SCREEN_HEIGHT

			sprintf(mode,"%dx%d:%d@%d",w,h,32,60);
			string = mode;
		}

		glutGameModeString(string);
		RETVAL = glutGameModeGet(0x0001);	// GLUT_GAME_MODE_POSSIBLE
	}
	OUTPUT:
		RETVAL

#//# glutEnterGameMode();
int
glutEnterGameMode()

#//# glutLeaveGameMode();
void
glutLeaveGameMode()

#//# glutGameModeGet($mode);
int
glutGameModeGet(mode)
	GLenum	mode

#//# FreeGLUT/OpenGLUT feature
#//# int  glutBitmapHeight (void *font)
int
glutBitmapHeight(font)
	void * font
	CODE:
	{
#if defined HAVE_FREEGLUT
		RETVAL = glutBitmapHeight(font);
#endif
	}
	OUTPUT:
		RETVAL

#//# FreeGLUT/OpenGLUT feature
#//# int  glutBitmapLength (void *font, const unsigned char *string)
int
glutBitmapLength(font, string)
	void * font
	const unsigned char * string
	CODE:
	{
#if defined HAVE_FREEGLUT
		RETVAL = glutBitmapLength(font, string);
#endif
	}
	OUTPUT:
		RETVAL

#//# FreeGLUT/OpenGLUT feature
#//# void  glutBitmapString (void *font, const unsigned char *string)
void
glutBitmapString(font, string)
	void * font
	const unsigned char * string
	CODE:
    {
#if defined HAVE_FREEGLUT
	    glutBitmapString(font, string);
#else
    	int len, i;
    	len = (int) strlen((char *)string);
    	for (i = 0; i < len; i++) {
    		glutBitmapCharacter(font, string[i]);
    	}
#endif
    }

#//# FreeGLUT/OpenGLUT feature
#//# void *  glutGetProcAddress (const char *procName)
# void *
# glutGetProcAddress(procName)
# 	const char * procName

#//# FreeGLUT/OpenGLUT feature
#//# void  glutMainLoopEvent (void)
void
glutMainLoopEvent()
	CODE:
	{
#if defined HAVE_AGL_GLUT
		glutCheckLoop();
#elif defined HAVE_FREEGLUT
		glutMainLoopEvent();
#endif
	}

#//# void  glutPostWindowOverlayRedisplay (int windowID)
void
glutPostWindowOverlayRedisplay(windowID)
	int windowID

#//# void  glutPostWindowRedisplay (int windowID)
void
glutPostWindowRedisplay(windowID)
	int windowID

#//# void  glutReportErrors (void)
void
glutReportErrors()

#//# void  glutSolidCylinder (GLdouble radius, GLdouble height, GLint slices, GLint stacks)
void
glutSolidCylinder(radius, height, slices, stacks)
	GLdouble radius
	GLdouble height
	GLint slices
	GLint stacks
	CODE:
	{
#if defined HAVE_FREEGLUT
		glutSolidCylinder(radius, height, slices, stacks);
#endif
	}

#//# void  glutSolidRhombicDodecahedron (void)
void
glutSolidRhombicDodecahedron()
	CODE:
	{
#if defined HAVE_FREEGLUT
		glutSolidRhombicDodecahedron();
#endif
	}

#//# float  glutStrokeHeight (void *font)
GLfloat
glutStrokeHeight(font)
	void * font
	CODE:
	{
#if defined HAVE_FREEGLUT
		RETVAL = glutStrokeHeight(font);
#endif
	}
	OUTPUT:
		RETVAL


#//# float  glutStrokeLength (void *font, const unsigned char *string)
GLfloat
glutStrokeLength(font, string)
	void * font
	const unsigned char * string
	CODE:
	{
#if defined HAVE_FREEGLUT
		glutStrokeLength(font, string);
#endif
	}
	OUTPUT:
		RETVAL

#//# void  glutStrokeString (void *fontID, const unsigned char *string)
void
glutStrokeString(font, string)
	void * font
	const unsigned char * string
	CODE:
	{
#if defined HAVE_FREEGLUT
		glutStrokeString(font, string);
#endif
	}

#//# void  glutWarpPointer (int x, int y)
void
glutWarpPointer(x, y)
	int x
	int y

#//# void  glutWireCylinder (GLdouble radius, GLdouble height, GLint slices, GLint stacks)
void
glutWireCylinder(radius, height, slices, stacks)
	GLdouble radius
	GLdouble height
	GLint slices
	GLint stacks
	CODE:
	{
#if defined HAVE_FREEGLUT
		glutWireCylinder(radius, height, slices, stacks);
#endif
	}

#//# void  glutWireRhombicDodecahedron (void)
void
glutWireRhombicDodecahedron()
	CODE:
	{
#if defined HAVE_FREEGLUT
		glutWireRhombicDodecahedron();
#endif
	}

#endif

# /* FreeGLUT APIs */

#//# glutSetOption($option_flag, $value);
void
glutSetOption(option_flag, value)
	GLenum		option_flag
	int		value
	CODE:
	{
#if defined HAVE_FREEGLUT
		glutSetOption(option_flag, value);
#endif
	}

#//# glutLeaveMainLoop();
void
glutLeaveMainLoop()
	CODE:
	{
#if defined HAVE_FREEGLUT
		glutLeaveMainLoop();
#else
		int win = glutGetWindow();
		glutDestroyWindow(win);
		destroy_glut_win_handlers(win);
#endif
	}

#//# glutMenuDestroyFunc(\&callback);
void
glutMenuDestroyFunc(handler=0, ...)
	SV *	handler
	CODE:
    {
#if defined HAVE_FREEGLUT
		decl_gwh_xs(MenuDestroy)
#endif
	}

#//# glutCloseFunc(\&callback);
void
glutCloseFunc(handler=0, ...)
	SV *	handler
	CODE:
        {
	    if (_done_glutCloseFunc_warn == 0) {
	        warn("glutCloseFunc: not implemented\n");
	        _done_glutCloseFunc_warn++;
            }
        }


BOOT:
  PGOPOGL_CALL_BOOT(boot_OpenGL__GLUT__Const);
  PGOPOGL_CALL_BOOT(boot_OpenGL__GLUT__GL__Top);


