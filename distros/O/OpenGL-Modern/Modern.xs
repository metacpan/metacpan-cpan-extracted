#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define GLEW_STATIC
/* This makes memory requirements balloon but makes building so much easier*/
#include <include/GL/glew.h>
#include <src/glew.c>
#include <src/glew-context.c>

#include "gl_errors.h"
#include "const-c.inc"

static int _done_glewInit = 0;
static int _auto_check_errors = 0;

/*
  Maybe one day we'll allow Perl callbacks for GLDEBUGPROCARB
*/

MODULE = OpenGL::Modern		PACKAGE = OpenGL::Modern		

GLboolean
glewCreateContext()
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
    0,   /* major */
    0,   /* minor */
    0,   /* profile mask */
    0    /* flags */
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

SV*
glewGetErrorString(err)
    GLenum err
CODE:
    RETVAL = newSVpv(glewGetErrorString(err),0);
OUTPUT:
    RETVAL

SV*
glewGetString(what)
    GLenum what;
CODE:
    RETVAL = newSVpv(glewGetString(what),0);
OUTPUT:
    RETVAL

SV*
glGetString(what)
    GLenum what;
CODE:
    RETVAL = newSVpv(glGetString(what),0);
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
    int err = GL_NO_ERROR;
    int error_count = 0;
    while ( ( err = glGetError() ) != GL_NO_ERROR ) {
        /* warn( "OpenGL error: %d", err ); */
        warn( "glpCheckErrors: OpenGL error: %d %s", err, gl_error_string(err) );
	error_count++;
    }
    if( error_count )
      croak( "glpCheckErrors: %d OpenGL errors encountered.", error_count );

# This isn't a bad idea, but I postpone this API and the corresponding
# typemap hackery until later
#GLboolean
#glAreProgramsResidentNV_p(GLuint* ids);
#PPCODE:
#     SV* buf_res = sv_2mortal(newSVpv("",items * sizeof(GLboolean)));
#     GLboolean* residences = (GLboolean*) SvPV_nolen(buf_res);
#     glAreProgramsResidentNV(items, ids, residences);
#     EXTEND(SP, items);
#     int i2;
#     for( i2 = 0; i2 < items; i2++ ) {
#        PUSHs(sv_2mortal(newSViv(residences[i2])));
#	 };

# Manual implementations go here
#

#//# glShaderSource_p($shaderObj, @string);
void
glShaderSource_p(shader, ...);
     GLuint shader;
INIT:
    int i;
    GLsizei count = items - 1;
CODE:
    if(! __glewShaderSource) {
    	croak("glShaderSource not available on this machine");
    };
    
    GLchar** string = malloc(sizeof(GLchar *) * count);
    GLint *length = malloc(sizeof(GLint) * count);
    
    for(i=0; i<count; i++) {
    	string[i] = (GLchar *)SvPV(ST(i+1),PL_na);
    	length[i] = strlen(string[i]);
    }
    
    glShaderSource(shader, count, (const GLchar *const*)string, (const GLint *)length);
    
    free(string);
    free(length);


INCLUDE: const-xs.inc
INCLUDE: auto-xs.inc
