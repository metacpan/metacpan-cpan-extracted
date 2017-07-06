#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Component.h>
#include "prima_gl.h"
#include <unix/guts.h>

#define Drawable        XDrawable
#define Font            XFont
#define Window          XWindow
#include <GL/gl.h>
#include <GL/glx.h>

#ifdef __cplusplus
extern "C" {
#endif

#define var (( PComponent) widget)
#define ctx (( Context*) context)
#define sys (( PDrawableSysData) var-> sysData)

typedef struct {
	Drawable drawable;
	GLXContext context;
	int pixmap;
} Context;

typedef struct {
	GLXDrawable drawable;
	GLXContext  context;
} ContextStackEntry;

ContextStackEntry stack[CONTEXT_STACK_SIZE];
int               stack_ptr = 0;


#define ERROR_CHOOSE_VISUAL   1
#define ERROR_CREATE_CONTEXT  2
#define ERROR_OTHER           3 
#define ERROR_NO_PRINTER      4
#define ERROR_NO_PIXMAPS      5
#define ERROR_STACK_UNDERFLOW 6
#define ERROR_STACK_OVERFLOW  7

int last_error = 0;
UnixGuts * pguts;

#define CLEAR_ERROR  last_error = 0
#define SET_ERROR(s) last_error = s

Handle
gl_context_create( Handle widget, GLRequest * request)
{
	int attr_list[64], *attr = attr_list;
	XVisualInfo * visual;
	GLXContext context;
	Context * ret;

	if ( pguts == NULL )
		pguts = (UnixGuts*) apc_system_action("unix_guts");

	CLEAR_ERROR;
	XCHECKPOINT;

#define ATTR(in,out) \
	if ( request-> in) { \
		*(attr++) = out; \
		*(attr++) = request-> in; \
	}

	*(attr++) = GLX_USE_GL;
	if ( request-> pixels         == GLREQ_PIXEL_RGBA) *(attr++) = GLX_RGBA;
	if ( request-> double_buffer  == GLREQ_TRUE) *(attr++) = GLX_DOUBLEBUFFER;
	if ( request-> stereo         == GLREQ_TRUE) *(attr++) = GLX_STEREO;
	ATTR( layer           , GLX_LEVEL            )
	ATTR( color_bits      , GLX_BUFFER_SIZE      )
	ATTR( aux_buffers     , GLX_AUX_BUFFERS      )
	ATTR( red_bits        , GLX_RED_SIZE         )
	ATTR( green_bits      , GLX_GREEN_SIZE       )
	ATTR( blue_bits       , GLX_BLUE_SIZE        )
	ATTR( alpha_bits      , GLX_ALPHA_SIZE       )
	ATTR( depth_bits      , GLX_DEPTH_SIZE       )
	ATTR( stencil_bits    , GLX_STENCIL_SIZE     )
	ATTR( accum_red_bits  , GLX_ACCUM_RED_SIZE   )
	ATTR( accum_green_bits, GLX_ACCUM_GREEN_SIZE )
	ATTR( accum_blue_bits , GLX_ACCUM_BLUE_SIZE  )
	ATTR( accum_alpha_bits, GLX_ACCUM_ALPHA_SIZE )
	*(attr++) = 0;

	if ( request-> target == GLREQ_TARGET_WINDOW && sys-> flags. layered) {
		visual = sys-> visual;
	} else if ( !( visual = glXChooseVisual( DISP, SCREEN, attr_list ))) {
		if ( request-> pixels != GLREQ_PIXEL_RGBA) {
			/* emulate win32 which does it softly, i.e. if RGBA fails, it proposes PALETTED */
			request-> pixels = GLREQ_PIXEL_RGBA;
			return gl_context_create( widget, request);
		}
		if ( request-> double_buffer == GLREQ_DONTCARE) {
			request-> double_buffer = GLREQ_TRUE;
			return gl_context_create( widget, request );
		}
		SET_ERROR( ERROR_CHOOSE_VISUAL );
		return (Handle) 0;
	}

	XCHECKPOINT;
	if ( !( context = glXCreateContext( DISP, visual, 0, request-> render != GLREQ_RENDER_XSERVER))) {
		SET_ERROR( ERROR_CREATE_CONTEXT );
		return (Handle) 0;
	}

	ret = malloc( sizeof( Context ));
	memset( ret, 0, sizeof( Context));
	ret-> context  = context;

	switch ( request-> target) {
	case GLREQ_TARGET_WINDOW:
		ret-> drawable   = var-> handle;
		break;
	case GLREQ_TARGET_APPLICATION:
		/* doesn't work with gnome and kde anyway */
		ret-> drawable   = RootWindow( DISP, SCREEN);
		break;
	case GLREQ_TARGET_BITMAP:
	case GLREQ_TARGET_IMAGE: 
	{
		GLXContext  old_context;
		GLXDrawable old_drawable;
		Bool success;
		XCHECKPOINT;

		ret-> drawable = glXCreateGLXPixmap( DISP, visual, sys-> gdrawable);
		ret-> pixmap   = 1;

		/* check if pixmaps are supported on this visual at all */
		old_context  = glXGetCurrentContext();
		old_drawable = glXGetCurrentDrawable();
		success = glXMakeCurrent( DISP, ret-> drawable, ret-> context);
		glXMakeCurrent( DISP, old_drawable, old_context);
		if ( !success ) {
			SET_ERROR( ERROR_NO_PIXMAPS );
			glXDestroyGLXPixmap( DISP, ret-> drawable);
			glXDestroyContext( DISP, ret-> context );
			free(ret);
			return 0;
		}


		break;
	}
	case GLREQ_TARGET_PRINTER:
		SET_ERROR(ERROR_NO_PRINTER);
		free(ret);
		return 0;
	}

	return (Handle) ret;
}

void
gl_context_destroy( Handle context)
{
	CLEAR_ERROR;
	XCHECKPOINT;
	if ( glXGetCurrentContext() == ctx-> context) 
		glXMakeCurrent( DISP, 0, NULL);
	if ( ctx-> pixmap)
		glXDestroyGLXPixmap( DISP, ctx-> drawable);
	glXDestroyContext( DISP, ctx-> context );
	free(( void*)  ctx );
}

Bool
gl_context_make_current( Handle context)
{
	Bool ret;
	CLEAR_ERROR;
	XCHECKPOINT;
	if ( context ) {
		ret = glXMakeCurrent( DISP, ctx-> drawable, ctx-> context);
	} else {
		ret = glXMakeCurrent( DISP, 0, NULL );
	}
	if ( !ret ) SET_ERROR( ERROR_OTHER );
	return ret;
}

Bool
gl_flush( Handle context)
{
	CLEAR_ERROR;
	XCHECKPOINT;
	glXSwapBuffers( DISP, ctx-> drawable );
	return true;
}

int 
gl_context_push(void)
{
	CLEAR_ERROR;
	if ( stack_ptr >= CONTEXT_STACK_SIZE ) {
		SET_ERROR( ERROR_STACK_OVERFLOW );
		return 0;
	}
	stack[stack_ptr].context  = glXGetCurrentContext();
	stack[stack_ptr].drawable = glXGetCurrentDrawable();
	stack_ptr++;
	return 1;
}

int 
gl_context_pop(void)
{
	CLEAR_ERROR;
	if ( stack_ptr <= 0) {
		SET_ERROR( ERROR_STACK_UNDERFLOW );
		return 0;
	}
	stack_ptr--;
	return glXMakeCurrent( DISP, stack[stack_ptr].drawable, stack[stack_ptr].context);
}

char *
gl_error_string(char * buf, int len)
{
	switch ( last_error ) {
	case 0:
		return NULL;
	case ERROR_CHOOSE_VISUAL:
		return "glXChooseVisual: cannot find a requested GL visual";
	case ERROR_CREATE_CONTEXT:
		return "glXCreateContext error";
	case ERROR_OTHER:
		return "unknown error";
	case ERROR_NO_PRINTER:
		return "No printer support on X11";
	case ERROR_NO_PIXMAPS:
		return "Pixmaps are unsupported on this GL visual";
	case ERROR_STACK_UNDERFLOW:
		return "No GL contexts on stack";
	case ERROR_STACK_OVERFLOW:
		return "No more space for GL contexts on stack";
	}
}

Bool
gl_is_direct(Handle context)
{
	CLEAR_ERROR;
	XCHECKPOINT;
	return glXIsDirect( DISP, ctx-> context );
}

#ifdef __cplusplus
}
#endif

