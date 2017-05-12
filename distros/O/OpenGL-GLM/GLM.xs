#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <glm.h>

#include "const-c.inc"

MODULE = OpenGL::GLM    PACKAGE = OpenGL::GLM

INCLUDE: const-xs.inc

GLMmodel *
new( class, ....);
        char *class;
        PREINIT:
            GLMmodel *model=NULL;
            char *filename=NULL;
        CODE:
            if (2!=items) {
                Perl_croak(aTHX_ "Usage: OpenGL::GLM::new($filename)");
                XSRETURN_UNDEF;
            }
            filename = SvPV_nolen(ST(1));
            if (NULL==(model=glmReadOBJ(filename))) {
                Perl_croak(aTHX_ "glmReadObj() failed.");
                XSRETURN_UNDEF;
            }
            RETVAL = model;
        OUTPUT:
            RETVAL

MODULE = OpenGL::GLM    PACKAGE = GLMmodelPtr  PREFIX = glm

void DESTROY(GLMmodel *model)
    CODE:
        glmDelete(model);

GLfloat
glmUnitize(GLMmodel* model);

void
glmScale(GLMmodel* model, GLfloat scale);

void
glmReverseWinding(GLMmodel* model);

void
glmFacetNormals(GLMmodel* model);

void
glmVertexNormals(GLMmodel* model, GLfloat angle, GLboolean keep_existing);

void
glmLinearTexture(GLMmodel* model);

void
glmSpheremapTexture(GLMmodel* model);

void
glmDelete(GLMmodel* model);

void
glmWriteOBJ(GLMmodel* model, char* filename, GLuint mode);

void
glmDraw(GLMmodel* model, GLuint mode);

GLuint
glmList(GLMmodel* model, GLuint mode);

void
glmWeld(GLMmodel* model, GLfloat epsilon);


