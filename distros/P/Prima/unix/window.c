/***********************************************************/
/*                                                         */
/*  System dependent window management (unix, x11)         */
/*                                                         */
/***********************************************************/

#include "unix/guts.h"
#include "Menu.h"
#include "Icon.h"
#include "Window.h"
#include "Application.h"

/* Tell a NET-compliant window manager that the window needs special treatment.
	See freedesktop.org for docs

	params - 0 - clear, 1 - set
*/
static void
set_net_hint(XWindow window, Bool state, Atom prop1, Atom prop2)
{
	XClientMessageEvent ev;

	if ( guts. icccm_only) return;

	/* Send change message to root window, it's responsible for
		on-the-fly changes. Otherwise, the properties are not re-read
		until next XMapWindow() */
	bzero( &ev, sizeof(ev));
	ev. type = ClientMessage;
	ev. display = DISP;
	ev. window = window;
	ev. message_type = NET_WM_STATE;
	ev. format = 32;

	/*
		_NET_WM_STATE_REMOVE        0    // remove/unset property
		_NET_WM_STATE_ADD           1    // add/set property
		_NET_WM_STATE_TOGGLE        2    // toggle property
	*/

	ev. data. l[0] = state ? 1 : 0;
	ev. data. l[1] = (long)prop1;
	ev. data. l[2] = (long)prop2;
	XSendEvent( DISP, guts. root, false, SubstructureRedirectMask|SubstructureNotifyMask, (XEvent*)&ev);
}

#define NETWM_SET_TASK_LISTED(xwindow,flag) set_net_hint(xwindow,flag,NET_WM_STATE_SKIP_TASKBAR,0)
#define NETWM_SET_MODAL(xwindow,flag)       set_net_hint(xwindow,flag,NET_WM_STATE_MODAL,0)
#define NETWM_SET_MAXIMIZED(xwindow,flag)   set_net_hint(xwindow,flag,NET_WM_STATE_MAXIMIZED_VERT,NET_WM_STATE_MAXIMIZED_HORZ)
#define NETWM_SET_ON_TOP(xwindow,flag)      set_net_hint(xwindow,flag,NET_WM_STATE_STAYS_ON_TOP,NET_WM_STATE_ABOVE)
#define NETWM_SET_FULLSCREEN(xwindow,flag)  set_net_hint(xwindow,flag,NET_WM_STATE_FULLSCREEN,0)

unsigned char *
prima_get_window_property(
	XWindow window, Atom property, Atom req_type, Atom * actual_type,
	int * actual_format, unsigned long * nitems
) {
	Atom a_actual_type;
	unsigned char * ret, * ptr;
	unsigned long left, n, a_nitems;
	int a_actual_format, curr_size, new_size, malloc_size, offset;

	ret = NULL;
	offset = 0;
	new_size = curr_size = malloc_size = 0;
	if ( actual_type   == NULL) actual_type   = &a_actual_type;
	if ( actual_format == NULL) actual_format = &a_actual_format;
	if ( nitems        == NULL) nitems        = &a_nitems;

	*nitems = 0;

	while ( XGetWindowProperty( DISP, window, property, offset, 2048, false, req_type,
			actual_type, actual_format, &n, &left, &ptr) == Success) {
		if ( ptr) {
			if ( n > 0) {
				if ( *actual_format == 32) *actual_format = sizeof(long) * 8; /* MUAHAHA!! That's even documented now */
				curr_size = n * *actual_format / 8;
				new_size += curr_size;
				offset += curr_size / 4;
				*nitems += n;

				if ( ret == NULL) {
					malloc_size = new_size;
					ret = malloc( malloc_size);
					if ( ret == NULL) {
						warn("Not enough memory: %d bytes\n", malloc_size);
						return NULL;
					}
				} else {
					if ( new_size > malloc_size) {
							unsigned char * p;
							malloc_size = new_size * 2;
							p = realloc( ret, malloc_size);
							if ( p) {
								ret = p;
							} else {
								free( ret);
								warn("Not enough memory: %d bytes\n", malloc_size);
								return NULL;
							}
					}
				}
				memcpy( ret + new_size - curr_size, ptr, curr_size);
			}
			XFree( ptr);
		}
		if ( left <= 0) break;
	}

	return ret;
}

Bool
prima_wm_net_state_read_maximization( XWindow window, Atom property)
/*
	reads property, returns true if it has both vertical and horizontal properties set.
*/
{
	long * prop;
	unsigned long i, n;
	int horiz = 0, vert = 0;

	if ( guts. icccm_only) return false;

	prop = ( long *) prima_get_window_property( window, property, XA_ATOM, NULL, NULL, &n);
	if ( !prop)
		return false;

	for ( i = 0; i < n; i++) {
		if ( prop[i] == NET_WM_STATE_MAXIMIZED_VERT) vert = 1;
		/* KDE v2 defines _HORIZ, KDE v3 defines _HORZ - a horrible hack follows */
		else if ( prop[i] == guts. atoms[ AI_NET_WM_STATE_MAXIMIZED_HORZ]) {
			if ( guts. net_wm_maximize_HORZ_vs_HORIZ == 0) {
				guts. net_wm_maximize_HORZ_vs_HORIZ = AI_NET_WM_STATE_MAXIMIZED_HORZ;
				Mdebug("wm: kde-3 style detected\n");
			}
			horiz = 1;
		}
		else if ( prop[i] == guts. atoms[ AI_NET_WM_STATE_MAXIMIZED_HORIZ]) {
			if ( guts. net_wm_maximize_HORZ_vs_HORIZ == 0) {
				guts. net_wm_maximize_HORZ_vs_HORIZ = AI_NET_WM_STATE_MAXIMIZED_HORIZ;
				Mdebug("wm: kde-2 style detected\n");
			}
			horiz = 1;
		}
	}

	free( prop);
	return vert && horiz;
}

static Bool
net_supports_maximization(void)
/* If WM supports customization, root.NET_SUPPORTED contains NET_WM_STATE_MAXIMIZED atoms.
	Stores result in guts. net_wm_maximization, so ConfigureEvent handler doesn't apply
	maximization heuristics. */
{
	Bool has_max;
	has_max = prima_wm_net_state_read_maximization( guts. root, NET_SUPPORTED);
	if ( has_max != guts. net_wm_maximization) {
		guts. net_wm_maximization = has_max;
		Mdebug( has_max ? "wm: supports maximization\n" : "win: WM quits supporting maximization\n");
	}
	return has_max;
}

static Bool
net_supports_fullscreen(void)
{
	long *prop;
	unsigned long n, i;
	Bool ok = false;
	if ( guts. icccm_only ) return false;

	prop = ( long *) prima_get_window_property( guts.root, NET_SUPPORTED, XA_ATOM, NULL, NULL, &n);
	if ( !prop ) return false;

	for ( i = 0; i < n; i++)
		if ( prop[i] == NET_WM_STATE_FULLSCREEN ) {
			ok = true;
			break;
		}
	if ( ok != guts. net_wm_fullscreen ) {
		guts. net_wm_fullscreen = ok;
		Mdebug( ok ? "wm: supports fullscreen\n" : "wm: quits supporting fullscreen\n");
	}

	return ok;
}

static void
apc_window_task_listed( Handle self, Bool task_list)
{
	DEFXX;
	XX-> flags. task_listed = ( task_list ? 1 : 0);
	NETWM_SET_TASK_LISTED( X_WINDOW, XX-> flags.task_listed );
}

/* Motif window hints */
#define MWM_HINTS_FUNCTIONS           (1L << 0)
#define MWM_HINTS_DECORATIONS         (1L << 1)

/* bit definitions for MwmHints.functions */
#define MWM_FUNC_ALL            (1L << 0)
#define MWM_FUNC_RESIZE         (1L << 1)
#define MWM_FUNC_MOVE           (1L << 2)
#define MWM_FUNC_MINIMIZE       (1L << 3)
#define MWM_FUNC_MAXIMIZE       (1L << 4)
#define MWM_FUNC_CLOSE          (1L << 5)

/* bit definitions for MwmHints.decorations */
#define MWM_DECOR_ALL                 (1L << 0)
#define MWM_DECOR_BORDER              (1L << 1)
#define MWM_DECOR_RESIZEH             (1L << 2)
#define MWM_DECOR_TITLE               (1L << 3)
#define MWM_DECOR_MENU                (1L << 4)
#define MWM_DECOR_MINIMIZE            (1L << 5)
#define MWM_DECOR_MAXIMIZE            (1L << 6)

static void
set_motif_hints( XWindow window, int border_style, int border_icons)
{
	struct {
	unsigned long flags, functions, decorations;
	long  input_mode;
	unsigned long status;
	} mwmhints;


#define MWMHINT_OR(field,value) mwmhints.field |= (value)

	if ( guts. icccm_only) return;

	bzero( &mwmhints, sizeof(mwmhints));
	MWMHINT_OR( flags, MWM_HINTS_DECORATIONS);
	MWMHINT_OR( flags, MWM_HINTS_FUNCTIONS);
	if ( border_style == bsSizeable) {
		MWMHINT_OR( decorations, MWM_DECOR_BORDER);
		MWMHINT_OR( decorations, MWM_DECOR_RESIZEH);
		MWMHINT_OR( functions, MWM_FUNC_RESIZE);
	}
	MWMHINT_OR( functions, MWM_FUNC_MOVE);
	MWMHINT_OR( functions, MWM_FUNC_CLOSE);
	if ( border_icons & biTitleBar)
		MWMHINT_OR( decorations, MWM_DECOR_TITLE);
	if ( border_icons & biSystemMenu)
		MWMHINT_OR( decorations, MWM_DECOR_MENU);
	if ( border_icons & biMinimize) {
		MWMHINT_OR( decorations, MWM_DECOR_MINIMIZE);
		MWMHINT_OR( functions, MWM_FUNC_MINIMIZE);
	}
	if (( border_icons & biMaximize) && ( border_style == bsSizeable)) {
		MWMHINT_OR( decorations, MWM_DECOR_MAXIMIZE);
		MWMHINT_OR( functions, MWM_FUNC_MAXIMIZE);
	}

	XChangeProperty(DISP, window, XA_MOTIF_WM_HINTS, XA_MOTIF_WM_HINTS, 32,
		PropModeReplace, (unsigned char *) &mwmhints, 5);
}

static void
set_wm_basesize_hints( Handle self )
{
	DEFXX;
	XSizeHints hints;
	bzero( &hints, sizeof( XSizeHints));
	hints. flags  = PBaseSize;
	hints. width  = hints. base_width  = XX-> size. x;
	hints. height = hints. base_height = XX-> size. y;
	XSetWMNormalHints( DISP, X_WINDOW, &hints);
}

static void
gather_old_window_data( Handle self, ViewProfile *vprf)
{
	DEFXX;
	int i, count;
	Handle * list;
	XEvent dummy_ev;
	XWindow old = X_WINDOW;

	list  = PWidget(self)-> widgets. items;
	count = PWidget(self)-> widgets. count;
	CWidget(self)-> end_paint_info( self);
	CWidget(self)-> end_paint( self);
	prima_release_gc( XX);
	for( i = 0; i < count; i++)
		prima_get_view_ex( list[ i], ( ViewProfile*)( X( list[ i])-> recreateData = malloc( sizeof( ViewProfile))));

	if ( XX-> recreateData) {
		memcpy( vprf, XX-> recreateData, sizeof( ViewProfile));
		free( XX-> recreateData);
		XX-> recreateData = NULL;
	} else
		prima_get_view_ex( self, vprf);
	if ( guts. currentMenu && PComponent( guts. currentMenu)-> owner == self) prima_end_menu();
	apc_window_set_menu( self, NULL_HANDLE);
	CWidget( self)-> end_paint_info( self);
	CWidget( self)-> end_paint( self);
	if ( XX-> flags. paint_pending) {
		TAILQ_REMOVE( &guts.paintq, XX, paintq_link);
		XX-> flags. paint_pending = false;
	}
	/* flush configure events */
	XSync( DISP, false);
	while ( XCheckIfEvent( DISP, &dummy_ev, (XIfEventProcType)prima_flush_events, (XPointer)self));
	hash_delete( guts.windows, (void*)&old, sizeof(old), false);
	hash_delete( guts.windows, (void*)&(XX->client), sizeof(XX->client), false);
}

static Bool
soft_recreate( Handle self, int border_style, int border_icons, int on_top, Bool task_list, int window_state)
{
	DEFXX;
	Bool destructive_motif_hints = 0; /* KDE 3.1: setting motif hints kills net_wm hints */
	if (
		!guts.icccm_only && (
			( border_style != ( XX-> flags. sizeable ? bsSizeable : bsDialog)) ||
			( border_icons != XX-> borderIcons) ||
		( on_top >= 0)
	)) {
		if (( border_style != ( XX-> flags. sizeable ? bsSizeable : bsDialog)) ||
			( border_icons != XX-> borderIcons))
			destructive_motif_hints = 1;
		if ( destructive_motif_hints && on_top < 0)
			on_top = apc_window_get_on_top( self);
		if ( destructive_motif_hints)
			set_motif_hints( X_WINDOW, border_style, border_icons);
		XX-> borderIcons = border_icons;
		XX-> flags. sizeable = ( border_style == bsSizeable) ? 1 : 0;
		XX-> flags. on_top = on_top != 0;
		NETWM_SET_ON_TOP( X_WINDOW, on_top != 0);
		NETWM_SET_FULLSCREEN( X_WINDOW, window_state == wsFullscreen );
		NETWM_SET_MAXIMIZED( X_WINDOW, window_state == wsMaximized);
	}

	if (
		(( task_list ? 1 : 0) != ( XX-> flags. task_listed ? 1 : 0))
		|| destructive_motif_hints
	)
		apc_window_task_listed( self, task_list);

	return true;
}

static Bool
recreate_window_data( Handle self, ViewProfile *vprf)
{
	DEFXX;
	int i;
	int  count = PWidget(self)->widgets. count;
	Handle * list = PWidget(self)->widgets. items;
	Point pos;

	pos = PWidget(self)-> pos;
	apc_window_set_menu( self, PWindow( self)-> menu);
	set_wm_basesize_hints( self );
	prima_set_view_ex( self, vprf);
	XX-> ackOrigin = pos;
	XX-> ackSize   = XX-> size;
	XX-> flags. mapped = XX-> flags. want_visible;
	for ( i = 0; i < count; i++) ((( PComponent) list[ i])-> self)-> recreate( list[ i]);
	prima_notify_sys_handle( self );
	return true;
}

static unsigned long
fill_attrs( Handle self, Bool for_toplevel, XSetWindowAttributes * attrs)
{
	DEFXX;
	unsigned long valuemask;

	attrs-> event_mask = 0
		| KeyPressMask              /* Key events unmasked for both windows, since */
		| KeyReleaseMask            /* focusing is unpredictable for some WM */
		/*| ButtonPressMask */
		/*| ButtonReleaseMask */
		/*| EnterWindowMask */
		/*| LeaveWindowMask */
		/*| PointerMotionMask */
		/* | PointerMotionHintMask */
		/* | Button1MotionMask */
		/* | Button2MotionMask */
		/* | Button3MotionMask */
		/* | Button4MotionMask */
		/* | Button5MotionMask */
		/*| ButtonMotionMask */
		/*| KeymapStateMask */
		| ExposureMask
		| VisibilityChangeMask
		| StructureNotifyMask
		/* | ResizeRedirectMask */
		/* | SubstructureNotifyMask */
		/* | SubstructureRedirectMask */
		| FocusChangeMask
		| PropertyChangeMask
		| ColormapChangeMask
		| OwnerGrabButtonMask
	;

	if ( !for_toplevel) attrs-> event_mask |= 0
		| ButtonPressMask
		| ButtonReleaseMask
		| EnterWindowMask
		| LeaveWindowMask
		| PointerMotionMask
		| ButtonMotionMask
		| KeymapStateMask
	;

	attrs-> override_redirect     = false;
	attrs-> do_not_propagate_mask = attrs-> event_mask;
	attrs-> colormap              = XX-> colormap;

	valuemask =
		0
		/* | CWBackPixmap */
		/* | CWBackPixel */
		/* | CWBorderPixmap */
		/* | CWBorderPixel */
		/* | CWBitGravity */
		/* | CWWinGravity */
		/* | CWBackingStore */
		/* | CWBackingPlanes */
		/* | CWBackingPixel */
		| CWOverrideRedirect
		/* | CWSaveUnder */
		| CWEventMask
		/* | CWDontPropagate */
		| CWColormap
		/* | CWCursor */
		;

	if ( XX->flags.layered ) {
		valuemask |= CWBackPixel | CWBorderPixel;
		attrs-> background_pixel = 0;
		attrs-> border_pixel = 0;
	}

	return valuemask;
}

static void
set_wm_hints( Handle self, Bool iconic)
{
	XWMHints wmhints;
	wmhints. flags = InputHint | StateHint;
	wmhints. input = false;
	wmhints. initial_state = iconic ? IconicState : NormalState;
	XSetWMHints( DISP, X_WINDOW, &wmhints);
	XCHECKPOINT;
}

static void
set_wm_protocols( Handle self )
{
	Atom atoms[ 2];
	atoms[ 0] = WM_DELETE_WINDOW;
	atoms[ 1] = WM_TAKE_FOCUS;
	XSetWMProtocols( DISP, X_WINDOW, atoms, 2);
	XCHECKPOINT;
}

static void
set_class_hint( Handle self)
{
	XClassHint *class_hint;
	if (( class_hint = XAllocClassHint()) != NULL) {
		class_hint-> res_class  = P_APPLICATION-> name;
		class_hint-> res_name = CObject( self)-> className;
		XSetClassHint( DISP, X_WINDOW, class_hint);
		XFree (class_hint);
	}
}

static void
set_misc_wm_hints( Handle self )
{
	if ( guts. hostname. value)
		XSetWMClientMachine(DISP, X_WINDOW, &guts. hostname);
	XSetCommand(DISP, X_WINDOW, PL_origargv, PL_origargc);
}

static Point
calculate_current_monitor_size(void)
{
	int nrects;
	Point ret;
	Box * monitors;
	monitors = apc_application_get_monitor_rects( NULL_HANDLE, &nrects);
	if ( nrects > 0 ) {
		int i, min_x = monitors[0].x, min_y = monitors[0].y;
		ret.x = monitors[0].width;
		ret.y = monitors[0].height;
		for ( i = 1; i < nrects; i++) {
			if ( min_x > monitors[i].x && min_y > monitors[i].y ) {
				min_x = monitors[i].x;
				min_y = monitors[i].y;
				ret.x = monitors[i].width;
				ret.y = monitors[i].height;
			}
		}
	} else {
		ret = guts. displaySize;
	}
	free( monitors);
	return ret;
}

static void
push_configure_event_pair( Handle self, int w, int h)
{
	DEFXX;
	ConfigureEventPair *cep;
	if (( cep = malloc( sizeof( ConfigureEventPair))) != NULL) {
		bzero( cep, sizeof( ConfigureEventPair));
		cep-> w = w;
		cep-> h = h;
		TAILQ_INSERT_TAIL( &XX-> configure_pairs, cep, link);
	}
}

static void
configure_initial_size( Handle self, int window_state )
{
	DEFXX;
	Point p0 = {0,0};
	XX-> size = calculate_current_monitor_size();
	switch (window_state) {
	case wsFullscreen:
		NETWM_SET_FULLSCREEN( X_WINDOW, 1);
		if ( !XX-> flags. fullscreen_emulated ) {
			XX-> zoomRect. right = XX-> size. x;
			XX-> zoomRect. top   = XX-> size. y;
		}
		break;
	case wsMaximized:
		XX-> flags. zoomed = 1;
		NETWM_SET_MAXIMIZED( X_WINDOW, 1);
		if ( net_supports_maximization()) {
			XX-> zoomRect. right = XX-> size. x;
			XX-> zoomRect. top   = XX-> size. y;
			XX-> size. x *= 0.75;
			XX-> size. y *= 0.75;
		}
		break;
	default:
		XX-> zoomRect. right = XX-> size. x;
		XX-> zoomRect. top   = XX-> size. y;
		XX-> size. x *= 0.75;
		XX-> size. y *= 0.75;
	}

	XX-> origin. x = XX-> origin. y =
	XX-> ackOrigin. x = XX-> ackOrigin. y =
	XX-> ackSize. x = XX-> ackSize. y =
	XX-> ackFrameSize. x = XX-> ackFrameSize.y = 0;

	set_wm_basesize_hints( self );
	XResizeWindow( DISP, XX-> client, XX-> size. x, XX-> size. y);
	XResizeWindow( DISP, X_WINDOW, XX-> size. x, XX-> size. y);

	push_configure_event_pair( self, XX->size.x, XX-> size.y);
	prima_send_cmSize( self, p0);
}

static XWindow
create_window( Handle self, XWindow parent, unsigned long valuemask, XSetWindowAttributes * attrs)
{
	DEFXX;
	return XCreateWindow( DISP, parent,
		0, 0, 1, 1, 0, XX-> visual->depth,
		InputOutput, XX->visual->visual,
		valuemask, attrs
	);
}

Bool
apc_window_create( Handle self, Handle owner, Bool sync_paint, int border_icons,
	int border_style, Bool task_list, int window_state,
	int on_top, Bool use_origin, Bool use_size, Bool layered
) {
	DEFXX;
	XSetWindowAttributes attrs;
	unsigned long valuemask;
	Bool recreate;
	ViewProfile vprf;
	XWindow old = X_WINDOW;

	if ( border_style != bsSizeable) border_style = bsDialog;
	border_icons &= biAll;

	if ( !guts. argb_visual. visual || guts. argb_visual. visualid == guts. visual. visualid)
		layered = false;

	if ( window_state == wsFullscreen )
		net_supports_fullscreen(); /* update and cache WM status */

	recreate = false;
	if ( X_WINDOW ) {
		 if (layered != XX->flags.layered)
		 	recreate = true;
		if ( !guts.net_wm_fullscreen) {
			Bool is_fs = window_state == wsFullscreen;
			if ( is_fs != XX-> flags.fullscreen)
				recreate = true;
		}
		if ( recreate ) {
			gather_old_window_data( self, &vprf);
			X_WINDOW = 0;
		} else
			return soft_recreate( self, border_style, border_icons, on_top, task_list, window_state);
	}

	XX-> visual          = layered ? &guts. argb_visual : &guts. visual;
	XX-> colormap        = layered ? guts. argbColormap : guts. defaultColormap;
	XX-> flags.layered   = !!layered;

	/* create toplevel window */
	valuemask = fill_attrs( self, true, &attrs);
	XX-> flags. fullscreen = XX-> flags. fullscreen_emulated = 0;
	if ( window_state == wsFullscreen ) {
		XX-> flags. fullscreen = 1;
		if ( !guts. net_wm_fullscreen ) {
			attrs.override_redirect = true;
			XX-> flags. fullscreen_emulated = 1;
		}
	}
	if ( !( X_WINDOW = create_window( self, guts. root, valuemask, &attrs)))
		return false;

	/* create client window */
	valuemask = fill_attrs( self, false, &attrs);
	if ( !( XX-> client = create_window( self, X_WINDOW, valuemask, &attrs))) {
		XDestroyWindow( DISP, X_WINDOW );
		X_WINDOW = 0;
		return false;
	}
	XMapWindow( DISP, XX-> client);
	XCHECKPOINT;

	hash_store( guts.windows, &XX-> client, sizeof(XX-> client), (void*)self);
	hash_store( guts.windows, &X_WINDOW, sizeof(X_WINDOW), (void*)self);

	XX-> type.drawable     = true;
	XX-> type.widget       = true;
	XX-> type.window       = true;

	XX-> parent            = guts. root;
	XX-> real_parent       = NULL_HANDLE;
	XX-> udrawable         = XX-> gdrawable = XX-> client;
	XX-> above             = NULL_HANDLE;
	XX-> owner             = prima_guts.application;

	XX-> flags.iconic      = ( window_state == wsMinimized) ? 1 : 0;
	XX-> borderIcons       = border_icons;
	XX-> flags.clip_owner  = false;
	XX-> flags.sync_paint  = sync_paint;
	XX-> flags.task_listed = 1;
	XX-> flags.layered     = XX-> flags. layered_requested = !!layered;
	XX-> flags. sizeable   = border_style == bsSizeable;

	TAILQ_INIT( &XX-> configure_pairs);

	set_wm_hints(self, XX-> flags. iconic);
	set_wm_protocols(self);
	set_class_hint(self);
	set_misc_wm_hints(self);
	set_motif_hints( X_WINDOW, border_style, border_icons);
	if ( on_top > 0) NETWM_SET_ON_TOP( X_WINDOW, 1);
	apc_window_task_listed( self, task_list);

	if (recreate) {
		Bool ok = recreate_window_data( self, &vprf);
		XDestroyWindow( DISP, old);
		XSync( DISP, false);
		return ok;
	}

	apc_component_fullname_changed_notify( self);
	prima_send_create_event( X_WINDOW);
	configure_initial_size( self, window_state );
	XSync( DISP, false);

	return true;
}

static Bool
recreate_window_with_emulated_fullscreen( Handle self, int window_state)
{
	DEFXX;
	return apc_window_create( self,
	 	PComponent(self)->owner, XX->flags.sync_paint, XX->borderIcons,
	 	XX->flags.sizeable ? bsSizeable : bsDialog, XX->flags.task_listed, window_state,
	 	XX->flags.on_top, false, false, XX->flags.layered);
}

Bool
apc_window_activate( Handle self)
{
	DEFXX;
	int rev;
	XWindow xfoc;
	XEvent ev;

	if ( !XX->flags. want_visible) return true;
	if ( guts. message_boxes) return false;
	if ( self && ( self != C_APPLICATION-> map_focus(prima_guts.application, self)))
		return false;

	XMapRaised( DISP, X_WINDOW);
	if ( XX-> flags. iconic || XX-> flags. withdrawn)
		prima_wm_sync( self, MapNotify);
	XGetInputFocus( DISP, &xfoc, &rev);
	if ( xfoc == X_WINDOW || xfoc == XX-> client) return true;
	XSetInputFocus( DISP, XX-> client, RevertToParent, guts. currentFocusTime);
	XCHECKPOINT;

	XSync( DISP, false);
	while ( XCheckMaskEvent( DISP, FocusChangeMask|ExposureMask, &ev))
		prima_handle_event( &ev, NULL);
	return true;
}

Bool
apc_window_is_active( Handle self)
{
	return apc_window_get_active() == self;
}

Bool
apc_window_close( Handle self)
{
	return prima_simple_message( self, cmClose, true);
}

Handle
apc_window_get_active( void)
{
	Handle x = guts. focused;
	while ( x && !X(x)-> type. window) x = PWidget(x)-> owner;
	return x;
}

int
apc_window_get_border_icons( Handle self)
{
	return X(self)-> borderIcons;
}

int
apc_window_get_border_style( Handle self)
{
	return X(self)-> flags. sizeable ? bsSizeable : bsDialog;
}

ApiHandle
apc_window_get_client_handle( Handle self)
{
	return X(self)-> client;
}

Point
apc_window_get_client_pos( Handle self)
{
	if ( !X(self)-> flags. configured) prima_wm_sync( self, ConfigureNotify);
	return X(self)-> origin;
}

Point
apc_window_get_client_size( Handle self)
{
	if ( !X(self)-> flags. configured) prima_wm_sync( self, ConfigureNotify);
	return X(self)-> size;
}

Bool
apc_window_get_icon( Handle self, Handle icon)
{
	XWMHints * hints;
	Pixmap xor, and;
	unsigned int xx, xy, ax, ay, xd, ad;
	Bool ret;

	if ( !icon)
		return X(self)-> flags. has_icon ? true : false;
	else
		if ( !X(self)-> flags. has_icon) return false;

	if ( !( hints = XGetWMHints( DISP, X_WINDOW))) return false;
	if ( !icon || !hints-> icon_pixmap) {
		Bool ret = hints-> icon_pixmap != NULL_HANDLE;
		XFree( hints);
		return ret;
	}
	xor = hints-> icon_pixmap;
	and = hints-> icon_mask;
	XFree( hints);

	{
		XWindow foo;
		unsigned int bar;
		int bar2;
		if ( !XGetGeometry( DISP, xor, &foo, &bar2, &bar2, &xx, &xy, &bar, &xd))
			return false;
		if ( and && (!XGetGeometry( DISP, and, &foo, &bar2, &bar2, &ax, &ay, &bar, &ad)))
			return false;
	}

	CImage( icon)-> create_empty( icon, xx, xy, ( xd == 1) ? 1 : guts. qdepth);
	if ( !prima_std_query_image( icon, xor)) return false;

	if ( and) {
		Handle mask = (Handle) create_object( "Prima::Image", "");
		CImage( mask)-> create_empty( mask, ax, ay, ( ad == 1) ? imBW : guts. qdepth);
		ret = prima_std_query_image( mask, and);
		if (( PImage( mask)-> type & imBPP) != 1)
			CImage( mask)-> type( mask, true, imBW);
		if ( ret) {
			int i;
			Byte *d = PImage(mask)-> data;
			for ( i = 0; i < PImage(mask)-> dataSize; i++, d++)
				*d = ~(*d);
		} else
			bzero( PImage( mask)-> data, PImage( mask)-> dataSize);
		if ( xx != ax || xy != ay)  {
			Point p;
			p.x = xx;
			p.y = xy;
			CImage( mask)-> size( mask, true, p);
		}
		memcpy( PIcon( icon)-> mask, PImage( mask)-> data, PIcon( icon)-> maskSize);
		Object_destroy( mask);
	}

	return true;
}

int
apc_window_get_window_state( Handle self)
{
	DEFXX;
	if (XX-> flags. iconic) return wsMinimized;
	if (XX-> flags. zoomed) return wsMaximized;
	if (XX-> flags. fullscreen) return wsFullscreen;
	return wsNormal;
}

Bool
apc_window_get_task_listed( Handle self)
{
	return X(self)-> flags. task_listed;
}

Bool
apc_window_set_caption( Handle self, const char *caption, Bool utf8)
{
	XTextProperty p;

	if ( utf8) {
		if ( Xutf8TextListToTextProperty(DISP, ( char **) &caption, 1,
#ifdef X_HAVE_UTF8_STRING
			XUTF8StringStyle,
#else
			XCompoundTextStyle,
#endif
			&p) >= Success) {
			XSetWMIconName( DISP, X_WINDOW, &p);
			XSetWMName( DISP, X_WINDOW, &p);
			XFree( p. value);
		}
		XChangeProperty( DISP, X_WINDOW, NET_WM_NAME, UTF8_STRING, 8,
			PropModeReplace, ( unsigned char*) caption, strlen( caption));
		XChangeProperty( DISP, X_WINDOW, NET_WM_ICON_NAME, UTF8_STRING, 8,
			PropModeReplace, ( unsigned char*) caption, strlen( caption));
		X(self)->flags. title_utf8 = 1;
	} else {
		XDeleteProperty( DISP, X_WINDOW, NET_WM_NAME);
		XDeleteProperty( DISP, X_WINDOW, NET_WM_ICON_NAME);
		if ( XStringListToTextProperty(( char **) &caption, 1, &p) != 0) {
			XSetWMIconName( DISP, X_WINDOW, &p);
			XSetWMName( DISP, X_WINDOW, &p);
			XFree( p. value);
		}
		X(self)->flags. title_utf8 = 0;
	}
	XFlush( DISP);
	return true;
}

static Bool
read_net_frame_extents( XWindow window, PRect r)
{
	long * prop;
	unsigned long n;

	if ( guts. icccm_only) return false;

	prop = ( long *) prima_get_window_property( window, NET_FRAME_EXTENTS, XA_CARDINAL, NULL, NULL, &n);
	if ( !prop ) return false;
	if ( n < 4 ) {
		free(prop);
		return false;
	}

	r-> left   += prop[0];
	r-> right  += prop[1];
	r-> top    += prop[2];
	r-> bottom += prop[3];

	free(prop);

	return true;
}

XWindow
prima_find_frame_window( XWindow w)
{
	XWindow r, p, *c;
	unsigned int nc;

	if ( w == None)
		return None;
	while ( XQueryTree( DISP, w, &r, &p, &c, &nc)) {
		if (c)
			XFree(c);
		if ( p == r)
			return w;
		w = p;
	}
	return None;
}

Bool
prima_get_frame_info( Handle self, PRect r)
{
	DEFXX;
	XWindow p, dummy;
	int px, py;
	unsigned int pw, ph, pb, pd;

	bzero( r, sizeof( Rect));
	if ( read_net_frame_extents( X_WINDOW, r )) {
		r-> top += XX-> menuHeight;
		return true;
	}

	p = prima_find_frame_window( X_WINDOW);
	if ( p == NULL_HANDLE) {
		r-> left = XX-> decorationSize. x;
		r-> top  = XX-> decorationSize. y;
	} else if ( p != X_WINDOW)
		if ( !XTranslateCoordinates( DISP, X_WINDOW, p, 0, 0, &r-> left, &r-> top, &dummy))
			warn( "error in XTranslateCoordinates()");
	if ( !XGetGeometry( DISP, p, &dummy, &px, &py, &pw, &ph, &pb, &pd)) {
		warn( "error in XGetGeometry()");
	} else {
		r-> top   += XX-> menuHeight;
		r-> right  = pw - r-> left - XX-> size. x;
		r-> bottom = ph - r-> top  - XX-> size. y;
	}
	return true;
}

void
apc_SetWMNormalHints( Handle self, XSizeHints * hints)
{
	DEFXX;
	hints-> flags |= PMinSize | PMaxSize;
	if ( XX-> flags. sizeable) {
		int h = PWidget(self)-> sizeMin.y;
		if ( h == 0) h = 1;
		hints-> min_width  = PWidget(self)-> sizeMin.x;
		hints-> min_height = h + XX-> menuHeight;
		hints-> max_width  = PWidget(self)-> sizeMax.x;
		hints-> max_height = PWidget(self)-> sizeMax.y + XX-> menuHeight;
		if ( !XX-> flags. sizemax_set &&
			PWidget(self)-> sizeMax.x == 16384 &&
			PWidget(self)-> sizeMax.y == 16384) {
			hints-> flags &= ~ PMaxSize;
		}
		else
			XX-> flags. sizemax_set = 1;
	} else {
		Point who;
		who. x = ( hints-> flags & USSize) ? hints-> width  : XX-> size. x;
		who. y = ( hints-> flags & USSize) ? hints-> height : XX-> size. y + XX-> menuHeight;
		hints-> min_width  = who. x;
		hints-> min_height = who. y;
		hints-> max_width  = who. x;
		hints-> max_height = who. y;
		XX-> flags. sizemax_set = 1;
	}
	XSetWMNormalHints( DISP, X_WINDOW, hints);
	XCHECKPOINT;
}

Bool
apc_window_set_client_pos( Handle self, int x, int y)
{
	DEFXX;
	XSizeHints hints;

	bzero( &hints, sizeof( XSizeHints));

	if ( XX-> flags. zoomed || XX->flags. fullscreen) {
		XX-> zoomRect. left = x;
		XX-> zoomRect. bottom = y;
		return true;
	}

	if ( x == XX-> origin. x && y == XX-> origin. y) return true;
	XX-> flags. position_determined = 1;

	if ( XX-> client == guts. grab_redirect) {
		XWindow rx;
		XTranslateCoordinates( DISP, XX-> client, guts. root, 0, 0,
			&guts. grab_translate_mouse.x, &guts. grab_translate_mouse.y, &rx);
	}

	y = guts. displaySize.y - XX-> size.y - XX-> menuHeight - y;
	hints. flags = USPosition;
	hints. x = x - XX-> decorationSize. x;
	hints. y = y - XX-> decorationSize. y;
	XMoveWindow( DISP, X_WINDOW, hints. x, hints. y);
	prima_wm_sync( self, ConfigureNotify);
	return true;
}

static void
apc_window_set_rect( Handle self, int x, int y, int szx, int szy)
{
	DEFXX;
	XSizeHints hints;
	Point psize = XX-> size;

	bzero( &hints, sizeof( XSizeHints));
	hints. flags = USPosition | USSize;
	hints. x = x - XX-> decorationSize. x;
	hints. y = guts. displaySize. y - szy - XX-> menuHeight - y - XX-> decorationSize. y;
	hints. width  = szx;
	hints. height = szy + XX-> menuHeight;
	XX-> flags. position_determined = 1;
	XX-> size. x = szx;
	XX-> size. y = szy;
	XMoveResizeWindow( DISP, XX-> client, 0, XX-> menuHeight, hints. width, hints. height - XX-> menuHeight);
	XMoveResizeWindow( DISP, X_WINDOW, hints. x, hints. y, hints. width, hints. height);
	push_configure_event_pair( self, hints.width, hints.height);
	apc_SetWMNormalHints( self, &hints);
	prima_send_cmSize( self, psize);

	if ( PObject( self)-> stage == csDead) return;
	prima_wm_sync( self, ConfigureNotify);
}

static Bool
window_set_client_size( Handle self, int width, int height)
{
	DEFXX;
	XSizeHints hints;
	PWidget widg = PWidget( self);
	Bool implicit_move = false;
	Point post, psize;

	widg-> virtualSize. x = width;
	widg-> virtualSize. y = height;

	width = ( width >= widg-> sizeMin. x)
			? (( width <= widg-> sizeMax. x)
				? width
				: widg-> sizeMax. x)
			: widg-> sizeMin. x;
	if ( width == 0) width = 1;

	height = ( height >= widg-> sizeMin. y)
			? (( height <= widg-> sizeMax. y)
				? height
				: widg-> sizeMax. y)
			: widg-> sizeMin. y;
	if ( height == 0) height = 1;

	if ( XX-> flags. zoomed || XX->flags. fullscreen) {
		XX-> zoomRect. right = width;
		XX-> zoomRect. top   = height;
		return true;
	}

	bzero( &hints, sizeof( XSizeHints));
	hints. flags = USSize | ( XX-> flags. position_determined ? USPosition : 0);
	post = XX-> origin;
	psize = XX-> size;
	hints. x = XX-> origin. x - XX-> decorationSize. x;
	hints. y = guts. displaySize.y - height - XX-> menuHeight - XX-> origin. y - XX-> decorationSize.y;
	hints. width = width;
	hints. height = height + XX-> menuHeight;
	XX-> size. x = width;
	XX-> size. y = height;
	apc_SetWMNormalHints( self, &hints);
	XMoveResizeWindow( DISP, XX-> client, 0, XX-> menuHeight, width, height);
	if ( XX-> flags. position_determined) {
		XMoveResizeWindow( DISP, X_WINDOW, hints. x, hints. y, width, height + XX-> menuHeight);
		implicit_move = true;
	} else {
		XResizeWindow( DISP, X_WINDOW, width, height + XX-> menuHeight);
	}
	XCHECKPOINT;
	prima_send_cmSize( self, psize);
	if ( PObject( self)-> stage == csDead) return false;
	prima_wm_sync( self, ConfigureNotify);
	if ( implicit_move && (( XX-> origin.x != post.x) || (XX-> origin.y != post.y))) {
		XX-> decorationSize. x =   XX-> origin.x - post. x;
		XX-> decorationSize. y = - XX-> origin.y + post. y;
	}
	push_configure_event_pair(self, hints.width, hints.height);
	return true;
}

Bool
apc_window_set_client_rect( Handle self, int x, int y, int width, int height)
{
	DEFXX;
	PWidget widg = PWidget( self);

	widg-> virtualSize. x = width;
	widg-> virtualSize. y = height;

	width = ( width >= widg-> sizeMin. x)
			? (( width <= widg-> sizeMax. x)
				? width
				: widg-> sizeMax. x)
			: widg-> sizeMin. x;
	if ( width == 0) width = 1;

	height = ( height >= widg-> sizeMin. y)
			? (( height <= widg-> sizeMax. y)
				? height
				: widg-> sizeMax. y)
			: widg-> sizeMin. y;
	if ( height == 0) height = 1;

	if ( XX-> flags. zoomed || XX->flags. fullscreen) {
		XX-> zoomRect. left = x;
		XX-> zoomRect. bottom = y;
		XX-> zoomRect. right = width;
		XX-> zoomRect. top   = height;
		return true;
	}

	if ( x == XX-> origin. x && y == XX-> origin. y &&
		width == XX-> size. x && height == XX-> size. y ) return true;

	apc_window_set_rect( self, x, y, width, height);
	return true;
}


Bool
apc_window_set_client_size( Handle self, int width, int height)
{
	DEFXX;
	if ( width == XX-> size. x && height == XX-> size. y) return true;
	return window_set_client_size( self, width, height);
}

Bool
prima_window_reset_menu( Handle self, int newMenuHeight)
{
	DEFXX;
	int ret = true;
	if ( newMenuHeight != XX-> menuHeight) {
		int oh = XX-> menuHeight;
		XX-> menuHeight = newMenuHeight;
		if ( PWindow(self)-> stage <= csNormal)
			ret = window_set_client_size( self, XX-> size.x, XX-> size.y);
		else
			XX-> size. y -= newMenuHeight - oh;

#ifdef HAVE_X11_EXTENSIONS_SHAPE_H
	if ( XX-> shape_extent. x != 0 || XX-> shape_extent. y != 0) {
		int ny = XX-> menuHeight;
		if ( XX-> shape_offset. y != ny) {
			XRectangle xr;
			XShapeOffsetShape( DISP, X_WINDOW, ShapeBounding, 0, ny - XX-> shape_offset. y);
			XX-> shape_offset. y = ny;
			xr. x = 0;
			xr. y = 0;
			xr. width  = XX->size.x;
			xr. height = XX->menuHeight;
			XShapeCombineRectangles( DISP, X_WINDOW, ShapeBounding, 0, 0, &xr, 1, ShapeUnion, 0);
		}
	}
#endif
	}
	return ret;
}

Bool
apc_window_set_visible( Handle self, Bool show)
{
	DEFXX;
	Bool want_sync;

	if ( show) {
		want_sync = !XX-> flags. mapped;
	} else {
		want_sync = XX-> flags. mapped;
	}

	XX-> flags. want_visible = show;
	if ( show) {
		Bool iconic = XX-> flags. iconic;
		if ( XX-> flags. withdrawn) {
			XWMHints wh;
			wh. initial_state = iconic ? IconicState : NormalState;
			wh. flags = StateHint;
			XSetWMHints( DISP, X_WINDOW, &wh);
			XX-> flags. withdrawn = 0;
		}
		if ( XX-> flags. zoomed )
			NETWM_SET_MAXIMIZED( X_WINDOW, true );
		if ( XX-> flags. fullscreen ) {
			NETWM_SET_FULLSCREEN( X_WINDOW, true );
			if ( !net_supports_fullscreen())
				if ( !recreate_window_with_emulated_fullscreen( self, wsFullscreen))
					return false;
		}
		XMapWindow( DISP, X_WINDOW);
		XX-> flags. iconic = iconic;
		if ( want_sync ) prima_wm_sync( self, MapNotify);
	} else {
		if ( XX-> flags. iconic) {
			XWithdrawWindow( DISP, X_WINDOW, SCREEN);
			XX-> flags. withdrawn = 1;
		} else
			XUnmapWindow( DISP, X_WINDOW);
		if ( want_sync ) prima_wm_sync( self, UnmapNotify);
	}
	XCHECKPOINT;
	return true;
}

/* apc_window_set_menu is in apc_menu.c */

Bool
apc_window_set_icon( Handle self, Handle icon)
{
	DEFXX;
	PIcon i = ( PIcon) icon;
	XIconSize * sz = NULL;
	Pixmap xor, and;
	XWMHints wmhints;
	unsigned long *p;
	int n, maxp;

	if ( !icon || i-> w == 0 || i-> h == 0) {
		if ( !XX-> flags. has_icon) return true;
		XX-> flags. has_icon = false;
		XDeleteProperty( DISP, X_WINDOW, XA_WM_HINTS);
		XDeleteProperty( DISP, X_WINDOW, NET_WM_ICON);
		wmhints. flags = InputHint;
		wmhints. input = false;
		XSetWMHints( DISP, X_WINDOW, &wmhints);
		return true;
	}

	if ( XGetIconSizes( DISP, guts.root, &sz, &n) && n > 0) {
		int zx = sz-> min_width, zy = sz-> min_height;
		while ( 1) {
			if ( i-> w <= zx || i-> h <= zy) break;
			zx += sz-> width_inc;
			zy += sz-> height_inc;
			if ( zx >= sz-> max_width || zy >= sz-> max_height) break;
		}
		if ( zx > sz-> max_width)  zx = sz-> max_width;
		if ( zy > sz-> max_height) zy = sz-> max_height;
		if (( zx != i-> w && zy != i-> h) || ( sz-> max_width != i-> w && sz-> max_height != i-> h)) {
			Point z;
			i = ( PIcon) i-> self-> dup( icon);
			z.x = zx;
			z.y = zy;
			i-> self-> size(( Handle) i, true, z);
		}
		XFree( sz);
	}

	/* NET_WM_ICON apparently wants rectangular icons */
	maxp = (i->w > i->h) ? i->w : i->h;
	if ( maxp > guts.limits.NetWMIcon ) {
		Point z = { guts.limits.NetWMIcon, guts.limits.NetWMIcon};
		if ( i == (PIcon) icon)
			i = (PIcon) CIcon((Handle)i)->dup(icon);
		i-> self-> size(( Handle) i, true, z);
		maxp = guts.limits.NetWMIcon;
	}

	if (( p = malloc( sizeof(unsigned long) * ( 2 + maxp * maxp))) != NULL ) {
		int x, y, padx, pady;
		Byte *sx, *sa;
		unsigned long *d;
		Bool is_icon = kind_of(icon, CIcon);

		if ( i->type != 24 || ( is_icon && i->maskType != imbpp8)) {
			if ( i == (PIcon) icon)
				i = (PIcon) CIcon((Handle)i)->dup(icon);
			if (i->type != 24)
				CIcon(i)->set_type((Handle) i, 24);
			if (is_icon && i->maskType != imbpp8)
				CIcon(i)->set_maskType((Handle) i, imbpp8);
		}

		bzero( p, sizeof(unsigned long) * ( 2 + maxp * maxp));
		p[0] = maxp;
		p[1] = maxp;
		d    = p + 2;
		sx   = i->data + i->lineSize * (i->h - 1);
		padx = pady = 0;
		if ( i-> w != i-> h ) {
			if ( i-> w > i-> h )
				pady = i-> w - i-> h;
			else
				padx = i-> h - i-> w;
		}
		d += maxp * (pady / 2) + padx / 2;
		if ( is_icon ) {
			for (
				y = 0, sa = i->mask + i->maskLine * (i->h - 1);
				y < i-> h;
				y++, sx -= i->lineSize, sa -= i->maskLine, d += padx
			) {
				Byte *sxx = sx, *saa = sa;
				for ( x = 0; x < i-> w; x++, sxx += 3) {
					*(d++) =
						sxx[0] |
						( sxx[1] << 8 ) |
						( sxx[2] << 16 ) |
						( *(saa++) << 24 );
				}
			}
		} else {
			for ( y = 0; y < i-> h; y++, sx -= i->lineSize, d += padx) {
				Byte *sxx = sx;
				for ( x = 0; x < i-> w; x++, sxx += 3)
					*(d++) =
						sxx[0] |
						( sxx[1] << 8 ) |
						( sxx[2] << 16 ) |
						( 0xff << 24 );
			}
		}
		XChangeProperty( DISP, X_WINDOW, NET_WM_ICON, XA_CARDINAL, 32,
			PropModeReplace, (unsigned char*) p, 2 + maxp * maxp);
		free(p);
	}

	xor = prima_std_pixmap(( Handle)i, CACHE_LOW_RES);
	if ( !xor) goto FAIL;
	{
		GC gc;
		XGCValues gcv;

		and = XCreatePixmap( DISP, guts. root, i-> w, i-> h, guts.depth);
		if ( !and) {
			XFreePixmap( DISP, xor);
			goto FAIL;
		}

		gcv. graphics_exposures = false;
		gc = XCreateGC( DISP, and, GCGraphicsExposures, &gcv);
		if ( X(i)-> image_cache. icon) {
			XSetBackground( DISP, gc, 0xffffffff);
			XSetForeground( DISP, gc, 0x00000000);
			prima_put_ximage( and, gc, X(i)-> image_cache. icon, 0, 0, 0, 0, i-> w, i-> h);
		} else {
			XSetForeground( DISP, gc, guts. monochromeMap[1]);
			XFillRectangle( DISP, and, gc, 0, 0, i-> w + 1, i-> h + 1);
		}
		XFreeGC( DISP, gc);
	}
	if (( Handle) i != icon) Object_destroy(( Handle) i);

	wmhints. flags = InputHint | IconPixmapHint | IconMaskHint;
	wmhints. icon_pixmap = xor;
	wmhints. icon_mask   = and;
	wmhints. input       = false;
	XSetWMHints( DISP, X_WINDOW, &wmhints);
	XCHECKPOINT;

	XX-> flags. has_icon = true;

	return true;
FAIL:

	if (( Handle) i != icon) Object_destroy(( Handle) i);
	return false;
}

Bool
apc_window_set_window_state( Handle self, int state)
{
	DEFXX;
	Event e;
	int sync = 0, did_net_zoom = 0,
		old_state = apc_window_get_window_state(self);

	if (old_state == state)
		return false;

	switch ( old_state) {
	case wsMinimized:
		break;
	case wsMaximized:
		NETWM_SET_MAXIMIZED( X_WINDOW, 0);
		break;
	case wsNormal:
		break;
	case wsFullscreen:
		NETWM_SET_FULLSCREEN( X_WINDOW, 0);
		if ( !net_supports_fullscreen())
			if ( !recreate_window_with_emulated_fullscreen( self, state))
				return false;
		break;
	default:
		return false;
	}

	switch ( state) {
	case wsMinimized:
		if ( !XX-> flags. withdrawn ) {
			XIconifyWindow( DISP, X_WINDOW, SCREEN);
			if ( XX-> flags. mapped) sync = UnmapNotify;
		}
		break;
	case wsMaximized: {
		Rect zoomRect;
		zoomRect.left   = XX-> origin.x;
		zoomRect.bottom = XX-> origin.y;
		zoomRect.right  = XX-> size.x;
		zoomRect.top    = XX-> size.y;
		NETWM_SET_MAXIMIZED( X_WINDOW, 1);
		if ( net_supports_maximization()) {
			if ( XX->flags.mapped) {
				prima_wm_sync( self, ConfigureNotify);
				if ( !prima_wm_net_state_read_maximization( X_WINDOW, NET_WM_STATE)) {
					/* wm denies maximization request, or we lost in the race ( see above ),
						do maximization by casual heuristic */
					goto FALL_THROUGH;
				}
			}
			did_net_zoom = 1;
			sync = 0;
		} else {
			int dx;
			int dy;
	FALL_THROUGH:
			dx = ( XX-> decorationSize. x > 0 ) ? XX-> decorationSize. x : 2;
			dy = ( XX-> decorationSize. y > 0 ) ? XX-> decorationSize. y : 20;
			apc_window_set_rect( self,
				dx * 2, dy * 2,
				guts. displaySize.x - dx * 4, guts. displaySize. y - XX-> menuHeight - dy * 4
			);
			sync = ConfigureNotify;
		}
		if ( old_state != wsFullscreen )
			XX-> zoomRect = zoomRect; /* often reset in ConfigureNotify to already maximized window */
		break;
	}
	case wsFullscreen: {
		Rect zoomRect;
		zoomRect.left   = XX-> origin.x;
		zoomRect.bottom = XX-> origin.y;
		zoomRect.right  = XX-> size.x;
		zoomRect.top    = XX-> size.y;
		NETWM_SET_FULLSCREEN( X_WINDOW, 1);
		if ( net_supports_fullscreen()) {
			if ( XX->flags.mapped)
				prima_wm_sync( self, ConfigureNotify);
			did_net_zoom = 1;
			sync = 0;
			XX-> flags.fullscreen_emulated = 0;
		} else {
			if ( !net_supports_fullscreen())
				if ( !recreate_window_with_emulated_fullscreen( self, wsFullscreen))
					return false;
			apc_window_set_rect( self, 0,0, guts. displaySize.x, guts. displaySize. y - XX-> menuHeight);
			sync = ConfigureNotify;
			XX-> flags.fullscreen_emulated = 1;
		}
		if ( old_state != wsMaximized )
			XX-> zoomRect = zoomRect; /* often reset in ConfigureNotify to already maximized window */
		break;
	}
	case wsNormal:
		if (
			!net_supports_maximization() &&
			( old_state == wsMaximized || old_state == wsFullscreen )
		) {
			apc_window_set_rect( self, XX-> zoomRect. left, XX-> zoomRect. bottom,
				XX-> zoomRect. right, XX-> zoomRect. top);
			sync = ConfigureNotify;
		}
		break;
	}

	if ( !XX-> flags. withdrawn && state != wsMinimized) {
		XMapWindow( DISP, X_WINDOW);
		if ( !XX-> flags. mapped && !did_net_zoom) sync = MapNotify;
	}

	XX-> flags.iconic     = ( state == wsMinimized) ? 1 : 0;
	XX-> flags.zoomed     = ( state == wsMaximized) ? 1 : 0;
	XX-> flags.fullscreen = ( state == wsFullscreen) ? 1 : 0;

	bzero( &e, sizeof(e));
	e. gen. source = self;
	e. cmd = cmWindowState;
	e. gen. i = state;
	apc_message( self, &e, false);

	if ( sync) prima_wm_sync( self, sync);

	XSync( DISP, false);

	return true;
}

static Bool
window_start_modal( Handle self, Bool shared, Handle insert_before)
{
	DEFXX;
	Handle selectee;
	if ( guts. grab_widget)
		apc_widget_set_capture( guts. grab_widget, 0, 0);
	if (( XX-> preexec_focus = apc_widget_get_focused()))
		protect_object( XX-> preexec_focus);
	CWindow( self)-> exec_enter_proc( self, shared, insert_before);
	apc_widget_set_enabled( self, true);
	apc_widget_set_visible( self, true);
	apc_window_activate( self);
	selectee = CWindow(self)->get_selectee( self);
	if ( selectee && selectee != self) Widget_selected( selectee, true, true);
	prima_simple_message( self, cmExecute, true);
	guts. modal_count++;
	return true;
}

Handle
prima_find_toplevel_window(Handle self)
{
	Handle toplevel = NULL_HANDLE;

	if (!prima_guts.application) return NULL_HANDLE;

	toplevel = C_APPLICATION-> get_modal_window(prima_guts.application, mtExclusive, true);
	if ( toplevel == NULL_HANDLE && self != NULL_HANDLE) {
		if (
			PWindow(self)-> owner &&
			PWindow(self)-> owner != prima_guts.application
		)
			toplevel = PWindow(self)-> owner;
	}

	/* find main window */
	if ( toplevel == NULL_HANDLE) {
		int i;
		PList l = & P_APPLICATION-> widgets;
		for ( i = 0; i < l-> count; i++) {
			if ( PObject(l-> items[i])-> options. optMainWindow && self != l->items[i]) {
				toplevel = l-> items[i];
				break;
			}
		}
	}

	return toplevel;
}

Handle
prima_find_root_parent(Handle self)
{
	while (
		self &&
		!X(self)-> type. window &&
		X(self)-> flags. clip_owner &&
		self != prima_guts.application
	)
		self = (( PWidget) self)-> owner;

	return self;
}

Bool
apc_window_execute( Handle self, Handle insert_before)
{
	DEFXX;
	Handle toplevel;

	if (!prima_guts.application) return false;

	toplevel = prima_find_toplevel_window(self);
	if ( toplevel) XSetTransientForHint( DISP, X_WINDOW, PWidget(toplevel)-> handle);

	XX-> flags.modal = true;
	NETWM_SET_MODAL( X_WINDOW, XX-> flags.modal);
	if ( !window_start_modal( self, false, insert_before))
		return false;

	protect_object( self);

	XSync( DISP, false);
	while ( prima_one_loop_round( WAIT_IF_NONE, true) && XX-> flags.modal)
		;

	if ( toplevel) XSetTransientForHint( DISP, X_WINDOW, None);
	if ( X_WINDOW) NETWM_SET_MODAL( X_WINDOW, XX-> flags.modal);
	unprotect_object( self);
	return true;
}

Bool
apc_window_execute_shared( Handle self, Handle insert_before)
{
	return window_start_modal( self, true, insert_before);
}

Bool
apc_window_end_modal( Handle self)
{
	PWindow win = PWindow(self);
	Handle modal, oldfoc;
	DEFXX;
	XX-> flags.modal = false;
	CWindow( self)-> exec_leave_proc( self);
	apc_widget_set_visible( self, false);
	if ( prima_guts.application) {
		modal = C_APPLICATION->popup_modal( prima_guts.application);
		if ( !modal && win->owner)
			CWidget( win->owner)-> set_selected( win->owner, true);
		if (( oldfoc = XX-> preexec_focus)) {
			if ( PWidget( oldfoc)-> stage == csNormal)
				CWidget( oldfoc)-> set_focused( oldfoc, true);
			unprotect_object( oldfoc);
		}
	}
	if ( guts. modal_count > 0)
		guts. modal_count--;
	return true;
}

Bool
apc_window_get_on_top( Handle self)
{
	Atom type;
	long * prop;
	int format;
	unsigned long i, n, left;
	Bool on_top = 0;

	if ( guts. icccm_only) return false;

	if ( XGetWindowProperty( DISP, X_WINDOW, NET_WM_STATE, 0, 32, false, XA_ATOM,
			&type, &format, &n, &left, (unsigned char**)&prop) == Success) {
		if ( prop) {
			for ( i = 0; i < n; i++) {
				if (
					prop[i] == NET_WM_STATE_STAYS_ON_TOP ||
					prop[i] == NET_WM_STATE_ABOVE
				) {
					on_top = 1;
					break;
				}
			}
			XFree(( unsigned char *) prop);
		}
	}

	return on_top;
}

Bool
apc_window_set_effects( Handle self, PHash effects )
{
	return false;
}

