#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <GL/glew.h>
#include <glew-context.c>

#include "gl_counts.h"
#include "gl_errors.h"
#include "oglm.h"

/*
  Maybe one day we'll allow Perl callbacks for GLDEBUGPROCARB
*/

MODULE = OpenGL::Modern		PACKAGE = OpenGL::Modern

GLboolean
glewCreateContext(int major=0, int minor=0, int profile_mask=0, int flags=0)
CODE:
  struct createParams params =
  {
#if defined(GLEW_OSMESA)
#elif defined(GLEW_EGL)
#elif defined(_WIN32)
    -1,  /* pixelformat */
#elif !defined(__HAIKU__) && !defined(__APPLE__) || defined(GLEW_APPLE_GLX)
    "",  /* display */
    -1,  /* visual */
#endif
    major,
    minor,
    profile_mask,
    flags
  };
    RETVAL = glewCreateContext(&params);
OUTPUT:
    RETVAL


void
glewDestroyContext()
CODE:
    glewDestroyContext();

UV
glewInit()
CODE:
    glewExperimental = GL_TRUE; /* We want everything that is available on this machine */
    if (_done_glewInit>0) {
        warn("glewInit() called %dX already", _done_glewInit);
    }
    RETVAL = glewInit();
    if ( !RETVAL )
        _done_glewInit++;
OUTPUT:
    RETVAL

char *
glewGetErrorString(err)
    GLenum err
CODE:
    RETVAL = (void *)glewGetErrorString(err);
OUTPUT:
    RETVAL

char *
glewGetString(what)
    GLenum what;
CODE:
    RETVAL = (void *)glewGetString(what);
OUTPUT:
    RETVAL

GLboolean
glewIsSupported(name);
    char* name;
CODE:
    RETVAL = glewIsSupported(name);
OUTPUT:
    RETVAL

#// Test for done with glutInit
int
done_glewInit()
CODE:
    RETVAL = _done_glewInit;
OUTPUT:
    RETVAL

int
glpSetAutoCheckErrors(...)
CODE:
    int state;
    if (items == 1) {
        state = (int)SvIV(ST(0));
        if (state != 0 && state != 1 )
            croak( "Usage: glpSetAutoCheckErrors(1|0)\n" );
        _auto_check_errors = state;
    }
    RETVAL = _auto_check_errors;
OUTPUT:
    RETVAL

void
glpCheckErrors()
CODE:
  OGLM_CROAK_IF_ERR(glpCheckErrors, )

const char *
glpErrorString(err)
  int err
CODE:
  RETVAL = gl_error_string(err);
OUTPUT:
  RETVAL

INCLUDE: ../../auto-xs.inc
