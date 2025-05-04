#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <GL/glew.h>

#define OGL_CONST_i(test) newCONSTSUB(stash, #test, newSViv((IV)test));

MODULE = OpenGL::Modern::Const		PACKAGE = OpenGL::Modern

BOOT:
  HV *stash = gv_stashpvn("OpenGL::Modern", strlen("OpenGL::Modern"), TRUE);
#include "const.h"
