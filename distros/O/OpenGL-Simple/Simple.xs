#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PERL_DARWIN

#include <GL/gl.h>
#include <GL/glu.h>

#else

#include <OpenGL/gl.h>
#include <OpenGL/glu.h>

#endif /* DARWIN */

#include "const-c.inc"

/* Datatype to represent what glGet() can return:
 * BOOL1 = single boolean, INT2 = two integers, etc.
 */
enum toygl_rtype {
	BOOL,
	INT,
	FLOAT
};

typedef enum toygl_rtype toygl_rtype;

MODULE = OpenGL::Simple		PACKAGE = OpenGL::Simple		

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

void glAccum(GLenum op, GLfloat value);

void glAlphaFunc(GLenum func, GLclampf ref);

void glClearAccum(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);

void glClearIndex( GLfloat c );

void glClearStencil( GLint s );

void glEdgeFlag( GLboolean flag );

void glFogf( GLenum pname, GLfloat param);

void glFogi( GLenum pname, GLint param);

void glFog(...)
    CODE:
         if (2>items) { croak("Usage: glFog(pname, param)"); }

         if (GL_FOG_COLOR==SvIV(ST(0))) {
             if (5!=items) {  croak("Usage: glFog(GL_FOG_COLOR,@color)");
             } else {
                 GLfloat col[4];
                 int i;
                 for (i=0;i<4;i++) {
                     col[i] = (GLfloat) SvNV(ST(1+i));
                 }
                 glFogfv(GL_FOG_COLOR,col);
             }
         } else if (2==items) {
             glFogf(SvIV(ST(0)),(GLfloat)SvNV(ST(1)));
         } else { croak("Usage: glFog(pname, param)"); }

void glIndexMask( GLuint mask);

void glInitNames();

GLboolean glIsEnabled( GLenum cap );

void glLoadName( GLuint name );

void glPassThrough( GLfloat token );

void glPushName( GLuint name );

void glPopName();

GLint glRenderMode( GLenum mode );

void glScissor( GLint x, GLint y, GLsizei width, GLsizei height);

void glStencilFunc( GLenum func, GLint ref, GLuint mask);

void glStencilOp( GLenum fail, GLenum zfail, GLenum zpass);

const GLubyte *glGetString (GLenum name);

void glBegin(GLenum mode);

void glEnd();

void glEnable(GLenum cap);

void glDisable (GLenum cap);

void glFinish();

void glFlush();

void glClearColor( GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);

void glClear(GLbitfield mask);

void glClearDepth(GLclampd depth);

void glClipPlane(...)
	PREINIT:
                GLenum plane;
                GLdouble equation[4];
	CODE:
		if ((2==items)
                 && (SvROK(ST(1)) 
		 && (SVt_PVAV == SvTYPE(SvRV(ST(1)))))
		) {
			/* Two items, of which the second is an array ref.  */

			AV *array;
                        int i;

			array =(AV *) SvRV(ST(1));

                        if (3!=av_len(array)) {
			    croak("glClipPlane($scalar,\\@array)"
                                  "should be passed an array of "
                                  "exactly 4 elements, not %d.",
                                  1+av_len(array));
                        }

                        plane = (GLenum) SvIV(ST(0));

                        for (i=0;i<4;i++) {
                            SV **svp;
                            svp = av_fetch(array,i,0);
                            equation[i] = (GLdouble) SvNV(*svp);
                        }
                } else if (5==items) {
                    /* assume args are (plane,a,b,c,d). */
                    int i;
                    plane = (GLenum) SvIV(ST(0));
                    for (i=0;i<4;i++) {
                        equation[i] = (GLdouble) SvNV(ST(1+i));
                    }
                } else {
                    croak("Usage: glClipPlane($plane,\\@equation)");
                }

                /* plane and equation[] are defined. */

                glClipPlane(plane,equation);

void glGetClipPlane(...)
    PREINIT:
        GLdouble equation[4];
        int i;
    PPCODE:
        if (1==items) {
            /* Dump everything on the stack */

            glGetClipPlane(SvIV(ST(0)),equation);
            EXTEND(sp,4);
            for (i=0;i<4;i++) {
                PUSHs(sv_2mortal(newSVnv(equation[i])));
            }
        } else if (2==items) {
            /* Write through supplied array reference */

            if (  (SvROK(ST(1)))
                &&(SVt_PVAV==SvTYPE(SvRV(ST(1))))
            ) {
                AV *array=(AV *)SvRV(ST(1));

                glGetClipPlane(SvIV(ST(0)),equation);
                for (i=0;i<4;i++) {
                    av_store(array,i,newSVnv(equation[i]));
                }
            }
        } else {
            /* Your what's itchy? */
            croak("glGetClipPlane() takes either one or two arguments.");
        }

void glLoadIdentity();

void glMatrixMode(GLenum mode);

void glLoadMatrix(...)
	PREINIT:
		GLdouble m[16];
		int i;
	CODE:
		if (16!=items) {
			croak("glMatrixMode takes a 16-element array");
		} else {
			/* Copy arguments into matrix */
			for (i=0;i<16;i++) { m[i] = SvNV(ST(i)); }
			glLoadMatrixd(m);
		}



void glMultMatrix(...)
	PREINIT:
		GLdouble m[16];
		int i;
	CODE:
		if (16!=items) {
			croak( "glMultMatrix takes a 16-element array");
		} else {
			/* Copy arguments into matrix */
			for (i=0;i<16;i++) { m[i] = SvNV(ST(i)); }
			glMultMatrixd(m);
		}



void glPushMatrix();

void glPopMatrix();

void glPushAttrib( GLbitfield mask);

void glPopAttrib();

void glRotate(GLdouble angle, GLdouble x, GLdouble y, GLdouble z)
	CODE:
		glRotated(angle,x,y,z);

void glRotated(GLdouble angle, GLdouble x, GLdouble y, GLdouble z);

void glRotatef(GLfloat angle, GLfloat x, GLfloat y, GLfloat z);

void glTranslate(GLfloat x, GLfloat y, GLfloat z)
    CODE:
        glTranslated(x,y,z);



void glTranslatef(GLfloat x, GLfloat y, GLfloat z);

void glTranslated(GLdouble x, GLdouble y, GLdouble z);

void glScale(GLdouble x, GLdouble y, GLdouble z)
	CODE:
		glScaled(x,y,z);


void glRect(...)
	CODE:
		if (4!=items) {
			croak("glRect() takes 4 arguments, not %d",items);
		}

		glRectd(
			SvNV(ST(0)),
			SvNV(ST(1)),
			SvNV(ST(2)),
			SvNV(ST(3))
			);


void glVertex2d (GLdouble x, GLdouble y);

void glVertex2f (GLfloat x, GLfloat y);

void glVertex2i (GLint x, GLint y);

void glVertex2s (GLshort x, GLshort y);

void glVertex3d (GLdouble x, GLdouble y, GLdouble z);

void glVertex3f (GLfloat x, GLfloat y, GLfloat z);

void glVertex3i (GLint x, GLint y, GLint z);

void glVertex3s (GLshort x, GLshort y, GLshort z);

void glVertex4d (GLdouble x, GLdouble y, GLdouble z, GLdouble w);

void glVertex4f (GLfloat x, GLfloat y, GLfloat z, GLfloat w);

void glVertex4i (GLint x, GLint y, GLint z, GLint w);

# All-in-one easy-to-use shrink-to-fit version
		
void glVertex(...)
	CODE:
		switch(items) {
			case 2:
				glVertex2d( SvNV(ST(0)),SvNV(ST(1)) );
				break;
			case 3:
				glVertex3d(
					SvNV(ST(0)),
					SvNV(ST(1)),
					SvNV(ST(2))
					);
				break;
			case 4:
				glVertex4d(
					SvNV(ST(0)),
					SvNV(ST(1)),
					SvNV(ST(2)),
					SvNV(ST(3))
					);
				break;
			default:
				croak("glVertex() takes 2,3, or 4 arguments");
		}

void glNormal(GLdouble x, GLdouble y, GLdouble z)
	CODE:
		glNormal3d(x,y,z);

void glNewList(GLuint list, GLenum mode);

void glEndList();

void glCallList(GLuint list);

void glCallLists(...)
    CODE:
        if (3==items) {
            /* Do it the clunky C-like way */
            glCallLists(
                    (GLsizei)SvIV(ST(0)),
                    (GLenum)SvIV(ST(1)),
                    (const GLvoid *)SvPV_nolen(ST(2))
            );
        } else if (1==items) {
            /* Do it the nice perl way */

            int *lists=NULL;
            AV *array=NULL;
            GLsizei i,n=0;

            if (SVt_PVAV != SvTYPE(SvRV(ST(0)))) {
                croak("Must have array reference");
            }
            array = (AV *)SvRV(ST(0));

            n=1+av_len(array);
            if (NULL==(lists=malloc(sizeof(int)*n))) {
                croak("glCallLists: malloc failed");
            }
            for (i=0;i<n;i++) {
                SV **svp = av_fetch(array,i,0);
                lists[i]=(int)SvIV(*svp);
            }
            glCallLists(n,GL_INT,lists);
            free(lists);
        } else {
            croak("glCallLists() takes 1 or 3 arguments.");
        }


void glIsList(GLuint list);

void glListBase( GLuint base );

GLuint glGenLists(GLsizei range);

void glDeleteLists(GLuint list, GLsizei range);





void glColor(...)
	CODE:
		switch(items) {
			case 3:
				glColor3d(
					SvNV(ST(0)),
					SvNV(ST(1)),
					SvNV(ST(2))
				);
				break;
			case 4:
				glColor4d(
					SvNV(ST(0)),
					SvNV(ST(1)),
					SvNV(ST(2)),
					SvNV(ST(3))
				);
				break;
			default:
				croak("glColor() takes 3 or 4 arguments");
		}

void glColor3b( GLbyte red, GLbyte green, GLbyte blue );

void glColor3d( GLdouble red, GLdouble green, GLdouble blue );

void glColor3f( GLfloat red, GLfloat green, GLfloat blue );

void glColor3i( GLint red, GLint green, GLint blue );

void glColor3s( GLshort red, GLshort green, GLshort blue );

void glColor3ub( GLubyte red, GLubyte green, GLubyte blue );

void glColor3ui( GLuint red, GLuint green, GLuint blue );

void glColor3us( GLushort red, GLushort green, GLushort blue );

void glColor4b( GLbyte red, GLbyte green, GLbyte blue, GLbyte alpha );

void glColor4d( GLdouble red, GLdouble green, GLdouble blue, GLdouble alpha );

void glColor4f( GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha );

void glColor4i( GLint red, GLint green, GLint blue, GLint alpha );

void glColor4s( GLshort red, GLshort green, GLshort blue, GLshort alpha );

void glColor4ub( GLubyte red, GLubyte green, GLubyte blue, GLubyte alpha );

void glColor4ui( GLuint red, GLuint green, GLuint blue, GLuint alpha );

void glColor4us( GLushort red, GLushort green, GLushort blue, GLushort alpha );

void glColorMaterial(GLenum face, GLenum mode);

void glMaterial(GLenum face, GLenum pname, GLenum param)
	CODE:

		glMaterialf(face,pname,param);


void glLightModel(...)
	PREINIT:
		GLenum pname;
		char *badargno="Bad number of arguments to glLightModel()";
	CODE:
		if ( (2!=items) && (5!=items) ) {
			croak(badargno);
		} else {
			pname = (GLenum) SvIV(ST(0));
		}
		switch(pname) {
			case GL_LIGHT_MODEL_LOCAL_VIEWER:
			case GL_LIGHT_MODEL_TWO_SIDE:

				if (2!=items) { croak(badargno); }
				glLightModelf(pname,SvNV(ST(1)));
			break;


			case GL_LIGHT_MODEL_AMBIENT:
				if (5!=items) { croak(badargno); }
				{
					GLfloat a[4];
					int i;
					for (i=0;i<4;i++) {
						a[i] = SvNV(ST(i+1));
					}
					glLightModelfv(pname,a);
					
				}
			break;
			default:
				croak("Bad pname passed to glLightModel()");
		}

void glLight(...)
	PREINIT:
		char *badargno="Bad number of arguments to glLightModel()";
		GLenum light,pname;
		GLfloat a[4];
		int i;
	CODE:
		if (items <= 2) {
			croak(badargno);
		} else {
			light = (GLenum) SvIV(ST(0));
			pname = (GLenum) SvIV(ST(1));
		}
		switch(pname) {
			case GL_AMBIENT:
			case GL_DIFFUSE:
			case GL_SPECULAR:
			case GL_POSITION:
				/* Pop four further args off the stack */
				if (6!=items) { croak(badargno); }
				for (i=0;i<4;i++) { a[i] = SvNV(ST(i+2)); }
				glLightfv(light,pname,a);
				break;
			case GL_SPOT_DIRECTION:
				/* Pop three further args off the stack */
				if (5!=items) { croak(badargno); }
				for (i=0;i<3;i++) { a[i] = SvNV(ST(i+2)); }
				glLightfv(light,pname,a);
				break;
			case GL_SPOT_EXPONENT:
			case GL_SPOT_CUTOFF:
			case GL_CONSTANT_ATTENUATION:
			case GL_LINEAR_ATTENUATION:
			case GL_QUADRATIC_ATTENUATION:
				/* Just the one argument */
				glLightf(light,pname,SvNV(ST(2)));
				break;
			default:
				croak("Bad pname passed to glLight()");
		}
		

void glShadeModel(GLenum mode);

void glCullFace(GLenum mode);

void glDepthFunc(GLenum func);

void glDepthMask(GLboolean flag);

void glDepthRange(GLclampd near, GLclampd far);

void glColorMask( GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha );

void glPolygonMode( GLenum face, GLenum mode );

void glPolygonOffset( GLfloat factor, GLfloat units );

void glViewport( GLint x, GLint y, GLsizei width, GLsizei height );


void glBlendFunc( GLenum sfactor, GLenum dfactor);

void glHint(GLenum target, GLenum mode);

void glLineWidth(GLfloat width);

void glLineStipple(GLint factor, GLushort pattern);

void glPointSize( GLfloat size );

void glOrtho( GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble zNear, GLdouble zFar );

void glFrustum(GLdouble left,GLdouble right,GLdouble bottom,GLdouble top,GLdouble near_val,GLdouble far_val);

void glFrontFace( GLenum mode );

void glGet(...)
	PREINIT:
		toygl_rtype rtype;
		GLenum pname;
		/* Dunno if this should really be allocated on the stack. */
		GLdouble	doublearr[16];
		GLint   	intarr[4];
		GLboolean	boolarr[4];
		int nvals; /* No of values returned by glGet() */
	PPCODE:
		if ( (1!=items) && (2!=items) ) {
			croak("glGet() requires 1 or 2 arguments");
		}

		if ( (2==items) && (!SvROK(ST(1))) ) {
			croak("Second argument to glGet() must be reference");
		}

		pname = SvIV(ST(0));

		/* Determine from the pname argument what glGet() is
		 * going to hand us back.
		 */
		switch(pname) {
			case GL_ALPHA_TEST:
			case GL_AUTO_NORMAL:
			case GL_BLEND:
			case GL_CLIP_PLANE0:
			case GL_CLIP_PLANE1:
			case GL_CLIP_PLANE2:
			case GL_CLIP_PLANE3:
			case GL_CLIP_PLANE4:
			case GL_CLIP_PLANE5:
			case GL_COLOR_ARRAY:
			case GL_COLOR_LOGIC_OP:
			case GL_COLOR_MATERIAL:
			case GL_CULL_FACE:
			case GL_CURRENT_RASTER_POSITION_VALID:
			case GL_DEPTH_TEST:
			case GL_DEPTH_WRITEMASK:
			case GL_DITHER:
			case GL_DOUBLEBUFFER:
			case GL_EDGE_FLAG:
			case GL_EDGE_FLAG_ARRAY:
			case GL_FOG:
			case GL_INDEX_ARRAY:
			case GL_INDEX_LOGIC_OP:
			case GL_INDEX_MODE:
			case GL_LIGHT0:
			case GL_LIGHT1:
			case GL_LIGHT2:
			case GL_LIGHT3:
			case GL_LIGHT4:
			case GL_LIGHTING:
			case GL_LIGHT_MODEL_LOCAL_VIEWER:
			case GL_LIGHT_MODEL_TWO_SIDE:
			case GL_LINE_SMOOTH:
			case GL_LINE_STIPPLE:
			case GL_MAP1_COLOR_4:
			case GL_MAP1_INDEX:
			case GL_MAP1_NORMAL:
			case GL_MAP1_TEXTURE_COORD_1:
			case GL_MAP1_TEXTURE_COORD_2:
			case GL_MAP1_TEXTURE_COORD_3:
			case GL_MAP1_TEXTURE_COORD_4:
			case GL_MAP1_VERTEX_3:
			case GL_MAP1_VERTEX_4:
			case GL_MAP2_COLOR_4:
			case GL_MAP2_INDEX:
			case GL_MAP2_NORMAL:
			case GL_MAP2_TEXTURE_COORD_1:
			case GL_MAP2_TEXTURE_COORD_2:
			case GL_MAP2_TEXTURE_COORD_3:
			case GL_MAP2_TEXTURE_COORD_4:
			case GL_MAP2_VERTEX_3:
			case GL_MAP2_VERTEX_4:
			case GL_MAP_COLOR:
			case GL_MAP_STENCIL:
			case GL_NORMAL_ARRAY:
			case GL_NORMALIZE:
			case GL_PACK_LSB_FIRST:
			case GL_PACK_SWAP_BYTES:
			case GL_POINT_SMOOTH:
			case GL_POLYGON_OFFSET_FILL:
			case GL_POLYGON_OFFSET_LINE:
			case GL_POLYGON_OFFSET_POINT:
			case GL_POLYGON_SMOOTH:
			case GL_POLYGON_STIPPLE:
			case GL_RGBA_MODE:
			case GL_SCISSOR_TEST:
			case GL_STENCIL_TEST:
			case GL_STEREO:
			case GL_TEXTURE_1D:
			case GL_TEXTURE_2D:
			case GL_TEXTURE_COORD_ARRAY:
			case GL_TEXTURE_GEN_Q:
			case GL_TEXTURE_GEN_R:
			case GL_TEXTURE_GEN_S:
			case GL_TEXTURE_GEN_T:
			case GL_UNPACK_LSB_FIRST:
			case GL_UNPACK_SWAP_BYTES:
			case GL_VERTEX_ARRAY:
				rtype = BOOL;
				nvals = 1;
				break;
			case GL_COLOR_WRITEMASK:
				rtype = BOOL;
				nvals = 4;
				break;

			case GL_ACCUM_ALPHA_BITS:
			case GL_ACCUM_BLUE_BITS:
			case GL_ACCUM_GREEN_BITS:
			case GL_ACCUM_RED_BITS :
			case GL_ALPHA_BITS:
			case GL_ALPHA_TEST_FUNC:
			case GL_ATTRIB_STACK_DEPTH:
			case GL_AUX_BUFFERS:
			case GL_BLEND_DST:
			case GL_BLEND_SRC:
			case GL_CLIENT_ATTRIB_STACK_DEPTH:
			case GL_COLOR_ARRAY_SIZE:
			case GL_COLOR_ARRAY_STRIDE:
			case GL_COLOR_ARRAY_TYPE:
			case GL_COLOR_MATERIAL_FACE:
			case GL_COLOR_MATERIAL_PARAMETER:
			case GL_CULL_FACE_MODE:
			case GL_CURRENT_INDEX:
			case GL_CURRENT_RASTER_INDEX:
			case GL_DEPTH_BITS:
			case GL_DEPTH_FUNC:
			case GL_DRAW_BUFFER:
			case GL_EDGE_FLAG_ARRAY_STRIDE:
			case GL_FOG_HINT:
			case GL_FOG_INDEX:
			case GL_FOG_MODE:
			case GL_FRONT_FACE:
			case GL_GREEN_BITS:
			case GL_INDEX_ARRAY_STRIDE:
			case GL_INDEX_ARRAY_TYPE:
			case GL_INDEX_BITS:
			case GL_INDEX_CLEAR_VALUE:
			case GL_INDEX_OFFSET:
			case GL_INDEX_SHIFT:
			case GL_INDEX_WRITEMASK:
			case GL_LINE_SMOOTH_HINT:
			case GL_LINE_STIPPLE_PATTERN:
			case GL_LINE_STIPPLE_REPEAT:
			case GL_LIST_BASE:
			case GL_LIST_INDEX:
			case GL_LIST_MODE:
			case GL_LOGIC_OP_MODE:
			case GL_MAP1_GRID_SEGMENTS:
			case GL_MATRIX_MODE:
			case GL_MAX_CLIENT_ATTRIB_STACK_DEPTH:
			case GL_MAX_ATTRIB_STACK_DEPTH:
			case GL_MAX_CLIP_PLANES:
			case GL_MAX_EVAL_ORDER:
			case GL_MAX_LIGHTS:
			case GL_MAX_LIST_NESTING:
			case GL_MAX_MODELVIEW_STACK_DEPTH:
			case GL_MAX_NAME_STACK_DEPTH:
			case GL_MAX_PIXEL_MAP_TABLE:
			case GL_MAX_PROJECTION_STACK_DEPTH:
			case GL_MAX_TEXTURE_SIZE:
			case GL_MAX_TEXTURE_STACK_DEPTH:
			case GL_MODELVIEW_STACK_DEPTH:
			case GL_NAME_STACK_DEPTH:
			case GL_NORMAL_ARRAY_STRIDE:
			case GL_NORMAL_ARRAY_TYPE:
			case GL_PACK_ALIGNMENT:
			case GL_PACK_ROW_LENGTH:
			case GL_PACK_SKIP_PIXELS:
			case GL_PACK_SKIP_ROWS:
			case GL_PERSPECTIVE_CORRECTION_HINT:
			case GL_PIXEL_MAP_A_TO_A_SIZE:
			case GL_PIXEL_MAP_B_TO_B_SIZE:
			case GL_PIXEL_MAP_G_TO_G_SIZE:
			case GL_PIXEL_MAP_I_TO_A_SIZE:
			case GL_PIXEL_MAP_I_TO_B_SIZE:
			case GL_PIXEL_MAP_I_TO_G_SIZE:
			case GL_PIXEL_MAP_I_TO_I_SIZE:
			case GL_PIXEL_MAP_I_TO_R_SIZE:
			case GL_PIXEL_MAP_R_TO_R_SIZE:
			case GL_PIXEL_MAP_S_TO_S_SIZE:
			case GL_POINT_SMOOTH_HINT:
			case GL_POLYGON_SMOOTH_HINT:
			case GL_PROJECTION_STACK_DEPTH:
			case GL_READ_BUFFER:
			case GL_RED_BITS:
			case GL_RENDER_MODE:
			case GL_SHADE_MODEL:
			case GL_STENCIL_BITS:
			case GL_STENCIL_CLEAR_VALUE:
			case GL_STENCIL_FAIL:
			case GL_STENCIL_FUNC:
			case GL_STENCIL_PASS_DEPTH_FAIL:
			case GL_STENCIL_PASS_DEPTH_PASS:
			case GL_STENCIL_REF:
			case GL_STENCIL_VALUE_MASK:
			case GL_STENCIL_WRITEMASK:
			case GL_SUBPIXEL_BITS:
			/*
			 * These are defined as GL_TEXTURE_nD_BINDING_EXT
			 * in my nvidia headers. Need to work it out
			 * on the fly, I guess.
			case GL_TEXTURE_1D_BINDING:
			case GL_TEXTURE_2D_BINDING:
			*/
			case GL_TEXTURE_COORD_ARRAY_SIZE:
			case GL_TEXTURE_COORD_ARRAY_STRIDE:
			case GL_TEXTURE_COORD_ARRAY_TYPE:
			case GL_TEXTURE_STACK_DEPTH:
			case GL_UNPACK_ALIGNMENT:
			case GL_UNPACK_ROW_LENGTH:
			case GL_UNPACK_SKIP_PIXELS:
			case GL_UNPACK_SKIP_ROWS:
			case GL_VERTEX_ARRAY_SIZE:
			case GL_VERTEX_ARRAY_STRIDE:
			case GL_VERTEX_ARRAY_TYPE:
				rtype = INT;
				nvals = 1;
				break;
			case GL_MAP2_GRID_SEGMENTS:
			case GL_MAX_VIEWPORT_DIMS:
			case GL_POLYGON_MODE:
				rtype = INT;
				nvals = 2;
				break;
			case GL_SCISSOR_BOX:
			case GL_VIEWPORT:
				rtype = INT;
				nvals = 4;
				break;
			case GL_ALPHA_BIAS :
			case GL_ALPHA_SCALE:
			case GL_ALPHA_TEST_REF:
			case GL_BLUE_BIAS:
			case GL_BLUE_BITS:
			case GL_BLUE_SCALE:
			case GL_CURRENT_RASTER_DISTANCE:
			case GL_DEPTH_BIAS:
			case GL_DEPTH_CLEAR_VALUE:
			case GL_DEPTH_SCALE:
			case GL_FOG_DENSITY:
			case GL_FOG_END:
			case GL_FOG_START:
			case GL_GREEN_SCALE:
			case GL_GREEN_BIAS:
			case GL_LINE_WIDTH:
			case GL_LINE_WIDTH_GRANULARITY:
			case GL_POINT_SIZE:
			case GL_POINT_SIZE_GRANULARITY:
			case GL_POLYGON_OFFSET_FACTOR:
			case GL_POLYGON_OFFSET_UNITS:
			case GL_RED_BIAS:
			case GL_RED_SCALE:
			case GL_ZOOM_X:
			case GL_ZOOM_Y:
				rtype = FLOAT;
				nvals = 1;
				break;
			case GL_DEPTH_RANGE:
			case GL_MAP1_GRID_DOMAIN:
			case GL_POINT_SIZE_RANGE:
			case GL_LINE_WIDTH_RANGE:
				rtype = FLOAT;
				nvals = 2;
				break;
			case GL_CURRENT_NORMAL:
				rtype = FLOAT;
				nvals = 3;
				break;
			case GL_ACCUM_CLEAR_VALUE  :
			case GL_COLOR_CLEAR_VALUE:
			case GL_CURRENT_COLOR:
			case GL_CURRENT_RASTER_COLOR:
			case GL_CURRENT_RASTER_POSITION:
			case GL_CURRENT_TEXTURE_COORDS:
			case GL_FOG_COLOR:
			case GL_LIGHT_MODEL_AMBIENT:
			case GL_MAP2_GRID_DOMAIN:

				rtype = FLOAT;
				nvals = 4;
				break;

			case GL_MODELVIEW_MATRIX:
			case GL_PROJECTION_MATRIX:
			case GL_TEXTURE_MATRIX:
				rtype = FLOAT;
				nvals = 16;
				break;
			default:
				croak("Unknown pname %d passed to glGet()",
						pname);
		}

		/* Now we know the return type. If necessary, check
		 * whether the second argument, if it exists, is
		 * a reference to the correct type
		 */

		if (2==items) {
			svtype reftype;

			reftype = SvTYPE(SvRV(ST(1)));

			if (1==nvals) {
				if (SvOK(SvRV(ST(1)))) {
					/* ok */
				} else if (SVt_NULL==reftype) {
					/* ok */
				} else if (SVt_PV==reftype) {
					/* ok */
				} else {
					croak("Must have scalar reference");
				}
			} else {
				if (SVt_PVAV != reftype) {
				croak("Must have array reference");
				}
			}

		}

		/* Make the call to glGet() */

		switch(rtype) {
			case BOOL:
				glGetBooleanv(pname,boolarr);
				break;
			case INT:
				glGetIntegerv(pname,intarr);
				break;

			case FLOAT:
				glGetDoublev(pname,doublearr);
				break;
			default:
				croak("Can't happen in rtype!");
		}

		/* Now work out what to do with the data */

		if (1==items) {
			int i;
			/* Just dump it onto the stack.
			 */

			EXTEND(sp,nvals);

			switch(rtype) {
			case BOOL:
				for (i=0;i<nvals;i++) {
					PUSHs(sv_2mortal(newSViv(boolarr[i])));
				}
				break;
			case INT:
				for (i=0;i<nvals;i++) {
					PUSHs(sv_2mortal(newSViv(intarr[i])));
				}
				break;
			case FLOAT:
				for (i=0;i<nvals;i++) {
				 PUSHs(sv_2mortal(newSVnv(doublearr[i])));
				}
				break;
			default:
				croak("Can't happen in rtype!");
			}

		} else {
			/* We get to write through supplied references. */
			if (1==nvals) {
				/* Write into referenced scalar */
				switch(rtype) {
				case BOOL:
					sv_setiv(SvRV(ST(1)),boolarr[0]);
					break;
				case INT:
					sv_setiv(SvRV(ST(1)),intarr[0]);
					break;
				case FLOAT:
					sv_setnv(SvRV(ST(1)),doublearr[0]);
					break;
				default:
					croak("Can't happen in rtype!");
				}
			} else {
				/* Write into referenced array */
				int i;
				AV *array = (AV *)SvRV(ST(1));
				av_clear(array);
				av_fill(array,nvals-1);
				switch(rtype) {
					case BOOL:
					for (i=0;i<nvals;i++) {
						av_store(array,i,
							newSViv(boolarr[i]));
					}
					break;
					case INT:
					for (i=0;i<nvals;i++) {
						av_store(array,i,
							newSViv(intarr[i]));
					}
					break;
					case FLOAT:
					for (i=0;i<nvals;i++) {
						av_store(array,i,
							newSVnv(doublearr[i]));
					}
					break;
				}
			}


		}
		


# Texture-mapping calls

void glBindTexture( GLenum target, GLuint texture );

void glIsTexture( GLuint texture );

void glDeleteTextures(...)
	PREINIT:
		GLuint *textures=NULL;
		int n,i;
	CODE:
		if (
			   (2==items)
			&& (SvROK(ST(1)) 
			&& (SVt_PVAV == SvTYPE(SvRV(ST(1)))))
		) {
			/* Two items, of which the second is an array ref.
			 * Do things C-style, and interpret the first
			 * as the number of elements in the array to delete.
			 */

			AV *array;

			array =(AV *) SvRV(ST(1));
			n=SvIV(ST(0)); /* No of items to delete */
			if (NULL==(textures=malloc(sizeof(GLuint)*n))) {
				perror("malloc()");
				croak("Out of memory");
			}
			for (i=0;i<n;i++) {
				SV **svp;
				svp = av_fetch(array,i,0);
				textures[i] = SvUV(*svp);
			}

		} else {
			/* Assume all arguments are textures to delete */
			n=items;
			if (NULL==(textures=malloc(sizeof(GLuint)*n))) {
				perror("malloc()");
				croak("Out of memory");
			}
			for (i=0;i<n;i++) {
				textures[i] = SvUV(ST(i));
			}
		}

		glDeleteTextures(n,textures);
		free(textures);


void glGenTextures(...)
	PREINIT:
		GLuint *texture=NULL;
		int n;
		AV *array;
		SV **svpp;
	PPCODE:
		if ( (1!=items) && (2!=items) ) {
			croak("Bad number of arguments");
		}

		n = SvUV(ST(0));

		if (2==items) {
			int i;
			if (	   (!SvROK(ST(1)))
				|| (SVt_PVAV != SvTYPE(SvRV(ST(1))))
			) {
				croak("Second arg must be array ref");
			}

			array = (AV *)SvRV(ST(1));
		}

		if (NULL==(texture=malloc(sizeof(GLuint)*n))) {
			perror("malloc()");
			croak("out of memory allocating texture IDs");
		}

		glGenTextures(n,texture);

		if (1==items) {
			int i;
			/* Push the texture IDs onto the stack */
			EXTEND(SP,n);
			for (i=0;i<n;i++) {
				PUSHs(sv_2mortal(newSViv(texture[i])));
			}
		} else {
			/* Write texture IDs into the referenced array */
			int i;

			/* First, empty the array and resize it. */
			av_clear(array);
			av_fill(array,n-1);

			/* Now store the elements. */

			for (i=0;i<n;i++) {
				av_store(array,i,newSViv(texture[i]));
			}
		}

		free(texture);


void glTexParameter(...)
	PREINIT:
		GLenum pname,target;
		char *badargno="Bad number of arguments to glTexParameter()";
	CODE:

		if (items<3) { fprintf(stderr,"items=%d\n",items);fflush(stderr); croak(badargno); }

		target = (GLenum) SvIV(ST(0));
		pname = (GLenum) SvIV(ST(1));

		switch(pname) {
			case GL_TEXTURE_MIN_FILTER:
			case GL_TEXTURE_MAG_FILTER:
				if (3!=items) { croak(badargno); }
				glTexParameteri(target,pname,SvIV(ST(2)));
				break;

			case GL_TEXTURE_WRAP_R:
			case GL_TEXTURE_WRAP_S:
			case GL_TEXTURE_WRAP_T:
			case GL_TEXTURE_PRIORITY:
				if (3!=items) { croak(badargno); }
				glTexParameterf(target,pname,SvNV(ST(2)));
				break;
			case GL_TEXTURE_BORDER_COLOR:
				/* Allow 3 *or* 4 colour components to be
				 * passed; set alpha to 1.0 if 3 passed.
				 */
				if ( (items!=5) && (items!=6)) {
					croak(badargno);
				}
				{
					GLfloat c[4];
					int i;

					c[3] = 1.0;
					for (i=0;i<(items-2);i++) {
						c[i] = SvNV(ST(i+2));
					}
					glTexParameterfv(target,pname,c);

				}
				break;

			default:
				croak("Bad pname %x in glTexParameter()",pname);
		}

void glTexCoord(...)
	CODE:
		switch(items) {
			case 1:
				glTexCoord1d( SvNV(ST(0)) );
			case 2:
				glTexCoord2d( SvNV(ST(0)),SvNV(ST(1)) );
				break;
			case 3:
				glTexCoord3d(
					SvNV(ST(0)),
					SvNV(ST(1)),
					SvNV(ST(2))
					);
				break;
			case 4:
				glTexCoord4d(
					SvNV(ST(0)),
					SvNV(ST(1)),
					SvNV(ST(2)),
					SvNV(ST(3))
					);
				break;
			default:
				croak("glTexCoord() takes 1-4 arguments");
		}

void glTexEnv(...)
	PREINIT:
		GLenum pname,target;
		char *badargno="Bad number of arguments to glTexEnv()";
		GLint param;
	CODE:

		if (items<3) { croak(badargno); }
		target = (GLenum) SvIV(ST(0));
		pname = (GLenum) SvIV(ST(1));

		switch(pname) {
			case GL_TEXTURE_ENV_MODE:
				/* Take one argument in param */
				param = (GLint) SvIV(ST(2));
				if (items!=3) {
					croak(badargno);
				}

				/* param should be one of
				 * GL_MODULATE GL_DECAL GL_BLEND GL_REPLACE
				 * but we'll let anything through.
				 */

				glTexEnvi(target,pname,param);
				break;

			case GL_TEXTURE_ENV_COLOR:
				/*
				 FIXME should also take a reference to color */

				{
					GLfloat a[4];
					if (6!=items) {
						croak(badargno);
					}
					a[0] = (GLfloat) SvNV(ST(2));
					a[1] = (GLfloat) SvNV(ST(3));
					a[2] = (GLfloat) SvNV(ST(4));
					a[3] = (GLfloat) SvNV(ST(5));
					glTexEnvfv(target,pname,a);
				}

			default:
				croak("weird pname in glTexEnv()");
		}

void realglTexImage2D( GLenum target,GLint level,GLint internalformat, GLsizei width, GLsizei height,GLint border, GLenum format,GLenum type, SV *pixels )
	PREINIT:
		SV *pixdatasv;
		GLvoid *data;
	CODE:

		/* Extract pixel data first */

		if (
			(!SvROK(pixels)) ||
			(!SvPOK(pixdatasv=SvRV(pixels)))
		) {
			croak("\"pixels\" should be a reference to scalar");
		}
		data = SvPV_nolen(pixdatasv);
		/* Get yer debug output here  

		fprintf(stderr,"reference OK\n");
		fprintf(stderr,"ref data is %s\n",
				SvPV_nolen(pixdatasv));

		fprintf(stderr,"t=%d l=%d if=%d w=%d h=%d\n",
				target,level,internalformat,
				width,height);
		fprintf(stderr,"bord=%d format=%d type=%d pixels=%p\n",
				border,format,type,pixels);
		fprintf(stderr,"data=>\"%s\"\n",data);
		{
			unsigned char *p=data;
			int i;
			for (i=0;i<16;i++) {
				fprintf(stderr,"%02x",p[i]);
			}
			fprintf(stderr,"\n");
		}
		fflush(stderr);
		*/

		glTexImage2D(
			target,level,internalformat,
			width,height,border,
			format,type,data
		);

void realglTexSubImage2D( GLenum target,GLint level,GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format,GLenum type, SV *pixels )
	PREINIT:
		SV *pixdatasv;
		GLvoid *data;
	CODE:

		/* Extract pixel data first */

		if (
			(!SvROK(pixels)) ||
			(!SvPOK(pixdatasv=SvRV(pixels)))
		) {
			croak("\"pixels\" should be a reference to scalar");
		}
		data = SvPV_nolen(pixdatasv);

		glTexSubImage2D(
			target,level,
                        xoffset,yoffset,
			width,height,
			format,type,data
		);


void realglPolygonStipple( SV *pixels )
	PREINIT:
		SV *pixdatasv;
		GLubyte *data;
                size_t plen;
	CODE:
                if (!SvPOK(pixels)) {
                    croak("not a pointer value..");
                }
                if (128 > SvLEN(pixels)) {
                    croak("\"pixels\" should be 128 bytes (32x32 bits).");
                }
                data=SvPV_nolen(pixels);
                glPolygonStipple(data);


void realglReadPixels(GLint x, GLint y, GLsizei width, GLsizei height,GLenum format, GLenum type, SV *pixels)
	PREINIT:
		SV *pixdatasv;
		GLvoid *data;
	CODE:

		/* Extract pixel data first */

		if (
			(!SvROK(pixels)) ||
			(!SvPOK(pixdatasv=SvRV(pixels)))
		) {
			croak("\"pixels\" should be a reference to scalar");
		}
		data = SvPV_nolen(pixdatasv);
                glReadPixels(x,y,width,height,format,type,data);


void glDrawBuffer(GLenum mode);

void glTexImage3D( GLenum target,GLint level,GLint internalformat, GLsizei width, GLsizei height,GLsizei depth, GLint border, GLenum format,GLenum type, SV *pixels )
	PREINIT:
		SV *pixdatasv;
		GLvoid *data;
	CODE:

		/* Extract pixel data first */

		if (
			(!SvROK(pixels)) ||
			(!SvPOK(pixdatasv=SvRV(pixels)))
		) {
			croak("\"pixels\" should be a reference to scalar");
		}
		data = SvPV_nolen(pixdatasv);

		glTexImage3D(
			target,level,internalformat,
			width,height,depth,border,
			format,type,data
		);


void glPixelStorei(GLenum pname, GLint param );

void glPixelStoref(GLenum pname, GLfloat param );

void glPixelTransferi(GLenum pname, GLint param);

void glPixelTransferf(GLenum pname, GLfloat param);

void glTexGen(...)
	PREINIT:
		char *badargno="Bad number of arguments to glTexGen()";
		GLenum coord, pname;
		GLfloat a[4];
		int i;
	CODE:
		if (items <= 2) {
			croak(badargno);
		} else {
			coord = (GLenum) SvIV(ST(0));
			pname = (GLenum) SvIV(ST(1));
		}
		switch(pname) {
			case GL_AMBIENT:
				/* Pop four further args off the stack */
				if (6!=items) { croak(badargno); }
				for (i=0;i<4;i++) { a[i] = SvNV(ST(i+2)); }
				glTexGenfv(coord,pname,a);
				break;
			case GL_TEXTURE_GEN_MODE:
				/* Just the one argument */
                a[0] = SvNV(ST(2));
				glTexGenfv(coord,pname,a);
				break;
			default:
				croak("Bad pname passed to glLight()");
		}

GLenum glGetError();

# ################ GLU calls


void gluPerspective(GLdouble fovy,GLdouble aspect,GLdouble zNear,GLdouble zFar);

void gluOrtho2D(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top );

void gluLookAt( GLdouble eyeX, GLdouble eyeY, GLdouble eyeZ, GLdouble centerX, GLdouble centerY, GLdouble centerZ, GLdouble upX, GLdouble upY, GLdouble upZ );

const GLubyte *gluErrorString(GLenum error);

