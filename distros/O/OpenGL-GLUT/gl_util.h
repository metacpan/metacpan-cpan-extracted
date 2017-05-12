#include "pgopogl.h"

#ifndef CALLBACK
#define CALLBACK
#endif


/* Include prototype flag */
#if (defined(_WIN32) || defined(HAVE_W32API))
#define GL_GLEXT_PROCS
#else
#define GL_GLEXT_PROTOTYPES
#endif

/* Provide GL header files for Windows and Apple */
#define INCLUDE_LOCAL_HEADER defined(HAVE_W32API) || defined(__APPLE__)
#if INCLUDE_LOCAL_HEADER
#include "./include/GL/gl.h"
#else
#include <GL/gl.h>
#endif

/* Use version-detection if available */
#if defined(HAVE_VER)
#include "glext_types.h"
#include "gl_exclude.h"
#include "glext_procs.h"
#else
#endif

/* Get a Perl parameter, cast to C type */
#define SvItems(type,offset,count,dst)					\
{									\
	GLuint i;							\
	switch (type)							\
	{								\
		case GL_UNSIGNED_BYTE:					\
		case GL_BITMAP:						\
			for (i=0;i<(count);i++)				\
			{						\
			  ((GLubyte*)(dst))[i] = (GLubyte)SvIV(ST(i+(offset)));	\
			}						\
			break;						\
		case GL_BYTE:						\
			for (i=0;i<(count);i++)				\
			{						\
			  ((GLbyte*)(dst))[i] = (GLbyte)SvIV(ST(i+(offset)));	\
			}						\
			break;						\
		case GL_UNSIGNED_SHORT:					\
			for (i=0;i<(count);i++)				\
			{						\
			  ((GLushort*)(dst))[i] = (GLushort)SvIV(ST(i+(offset)));	\
			}						\
			break;						\
		case GL_SHORT:						\
			for (i=0;i<(count);i++)				\
			{						\
			  ((GLshort*)(dst))[i] = (GLshort)SvIV(ST(i+(offset)));	\
			}						\
			break;						\
		case GL_UNSIGNED_INT:					\
			for (i=0;i<(count);i++)				\
			{						\
			  ((GLuint*)(dst))[i] = (GLuint)SvIV(ST(i+(offset)));	\
			}						\
			break;						\
		case GL_INT:						\
			for (i=0;i<(count);i++)				\
			{						\
			  ((GLint*)(dst))[i] = (GLint)SvIV(ST(i+(offset)));	\
			}						\
			break;						\
		case GL_FLOAT:						\
			for (i=0;i<(count);i++)				\
			{						\
			  ((GLfloat*)(dst))[i] = (GLfloat)SvNV(ST(i+(offset)));	\
			}						\
			break;						\
		case GL_DOUBLE:						\
			for (i=0;i<(count);i++)				\
			{						\
			  ((GLdouble*)(dst))[i] = (GLdouble)SvNV(ST(i+(offset)));	\
			}						\
			break;						\
		default:						\
			croak("unknown type");				\
	}								\
}


#ifndef GL_ADD
#define GL_ADD 0x0104
#endif

#ifndef GL_ADD_SIGNED_ARB
#define GL_ADD_SIGNED_ARB GL_ADD_SIGNED_EXT
#endif

#ifndef GL_SUBTRACT_ARB
#define GL_SUBTRACT_ARB GL_SUBTRACT_EXT
#endif

#ifndef GL_INTERPOLATE_ARB
#define GL_INTERPOLATE_ARB GL_INTERPOLATE_EXT
#endif

#ifndef GL_VERSION_1_0
#define GL_VERSION_1_0 1
#endif

#ifndef GL_TEXTURE_BINDING_3D
#define GL_TEXTURE_BINDING_3D 0x806A
#endif

/* Remap 1.1 extensions */
#ifdef GL_VERSION_1_1
#ifndef GL_VERSION_1_2

#ifndef GL_EXT_polygon_offset
#define GL_EXT_polygon_offset 1
#define GL_EXT_polygon_offset_is_faked 1
#define GL_POLYGON_OFFSET_EXT             0x8037
#define GL_POLYGON_OFFSET_FACTOR_EXT      0x8038
#define GL_POLYGON_OFFSET_BIAS_EXT        0x8039
#define glPolygonOffsetEXT(factor,units) glPolygonOffset((factor),(units)*(float)0x10000)
#endif

#ifndef GL_EXT_texture_object
#define GL_EXT_texture_object 1
#define GL_EXT_texture_object_is_faked 1
#define GL_TEXTURE_PRIORITY_EXT           GL_TEXTURE_PRIORITY
#define GL_TEXTURE_RESIDENT_EXT           GL_TEXTURE_RESIDENT
#define GL_TEXTURE_1D_BINDING_EXT         GL_TEXTURE_BINDING_1D
#define GL_TEXTURE_2D_BINDING_EXT         GL_TEXTURE_BINDING_2D
#define GL_TEXTURE_3D_BINDING_EXT         GL_TEXTURE_BINDING_3D
#define glAreTexturesResidentEXT(n,textures,residences) glAreTexturesResident(n,textures,residences)
#define glBindTextureEXT(target,texture) glBindTexture((target),(texture))
#define glDeleteTexturesEXT(n,textures) glDeleteTextures((n),(textures))
#define glGenTexturesEXT(n,textures) glGenTextures((n),(textures))
#define glIsTextureEXT(list) glIsTexture(list)
#define glPrioritizeTexturesEXT(n,textures,priorities) glPrioritizeTextures((n),(textures),(priorities))
#endif

#ifndef GL_EXT_copy_texture
#define GL_EXT_copy_texture 1
#define GL_EXT_copy_texture_is_faked 1
#define glCopyTexImage1DEXT(target,level,internalFormat,x,y,width,border) \
  glCopyTexImage1D((target),(level),(internalFormat),(x),(y),(width),(border))
#define glCopyTexImage2DEXT(target,level,internalFormat,x,y,width,height,border) \
  glCopyTexImage2D((target),(level),(internalFormat),(x),(y),(width),(height),(border))
#define glCopyTexSubImage1DEXT(target,level,xoffset,x,y,width) \
  glCopyTexSubImage1D((target),(level),(xoffset),(x),(y),(width))
#define glCopyTexSubImage2DEXT(target,level,xoffset,yoffset,x,y,width,height) \
  glCopyTexSubImage2D((target),(level),(xoffset),(yoffset),(x),(y),(width),(height))
#if defined(HAVE_VER) || defined(_WIN32)
#define glCopyTexSubImage3DEXT(target,level,xoffset,yoffset,zoffset,x,y,width,height) \
  glCopyTexSubImage3D((target),(level),(xoffset),(yoffset),(zoffset),(x),(y),(width),(height))
#else
#define glCopyTexSubImage3DEXT(target,level,xoffset,yoffset,zoffset,x,y,width,height)
#endif
#endif

#ifndef GL_EXT_vertex_array
#define GL_EXT_vertex_array 1
#define GL_EXT_vertex_array_is_faked 1
#define GL_VERTEX_ARRAY_COUNT_EXT         0x807D
#define GL_NORMAL_ARRAY_COUNT_EXT         0x8080
#define GL_COLOR_ARRAY_COUNT_EXT          0x8084
#define GL_INDEX_ARRAY_COUNT_EXT          0x8087
#define GL_TEXTURE_COORD_ARRAY_COUNT_EXT  0x808B
#define GL_EDGE_FLAG_ARRAY_COUNT_EXT      0x808D
#define GL_VERTEX_ARRAY_EXT		GL_VERTEX_ARRAY
#define GL_NORMAL_ARRAY_EXT		GL_NORMAL_ARRAY
#define GL_COLOR_ARRAY_EXT		GL_COLOR_ARRAY
#define GL_INDEX_ARRAY_EXT		GL_INDEX_ARRAY
#define GL_TEXCOORD_ARRAY_EXT		GL_TEXCOORD_ARRAY
#define GL_EDGEFLAG_ARRAY_EXT		GL_EDGEFLAG_ARRAY
#define GL_TEXTURE_COORD_ARRAY_EXT	GL_TEXTURE_COORD_ARRAY
#define GL_EDGE_FLAG_ARRAY_EXT		GL_EDGE_FLAG_ARRAY
#define GL_VERTEX_ARRAY_SIZE_EXT	GL_VERTEX_ARRAY_SIZE
#define GL_VERTEX_ARRAY_TYPE_EXT	GL_VERTEX_ARRAY_TYPE
#define GL_VERTEX_ARRAY_STRIDE_EXT	GL_VERTEX_ARRAY_STRIDE
#define GL_NORMAL_ARRAY_TYPE_EXT	GL_NORMAL_ARRAY_TYPE
#define GL_NORMAL_ARRAY_STRIDE_EXT	GL_NORMAL_ARRAY_STRIDE
#define GL_COLOR_ARRAY_SIZE_EXT		GL_COLOR_ARRAY_SIZE
#define GL_COLOR_ARRAY_TYPE_EXT		GL_COLOR_ARRAY_TYPE
#define GL_COLOR_ARRAY_STRIDE_EXT	GL_COLOR_ARRAY_STRIDE
#define GL_INDEX_ARRAY_TYPE_EXT		GL_INDEX_ARRAY_TYPE
#define GL_INDEX_ARRAY_STRIDE_EXT	GL_INDEX_ARRAY_STRIDE
#define GL_TEXTURE_COORD_ARRAY_SIZE_EXT	GL_TEXTURE_COORD_ARRAY_SIZE
#define GL_TEXTURE_COORD_ARRAY_TYPE_EXT	GL_TEXTURE_COORD_ARRAY_TYPE
#define GL_TEXTURE_COORD_ARRAY_STRIDE_EXT	GL_TEXTURE_COORD_ARRAY_STRIDE
#define GL_EDGE_FLAG_ARRAY_STRIDE_EXT	GL_EDGE_FLAG_ARRAY_STRIDE
#define GL_VERTEX_ARRAY_POINTER_EXT	GL_VERTEX_ARRAY_POINTER
#define GL_NORMAL_ARRAY_POINTER_EXT	GL_NORMAL_ARRAY_POINTER
#define GL_COLOR_ARRAY_POINTER_EXT	GL_COLOR_ARRAY_POINTER
#define GL_INDEX_ARRAY_POINTER_EXT	GL_INDEX_ARRAY_POINTER
#define GL_TEXTURE_COORD_ARRAY_POINTER_EXT	GL_TEXTURE_COORD_ARRAY_POINTER
#define GL_EDGE_FLAG_ARRAY_POINTER_EXT	GL_EDGE_FLAG_ARRAY_POINTER
#define glArrayElementEXT(i) glArrayElement(i)
#define glDrawArraysEXT(mode,first,count) glDrawArrays((mode),(first),(count))
#define glVertexPointerEXT(size,type,stride,count,pointer) \
  glVertexPointer((size),(type),(stride),(pointer))
#define glNormalPointerEXT(type,stride,count,pointer) \
  glNormalPointer((type),(stride),(pointer))
#define glColorPointerEXT(size,type,stride,count,pointer) \
  glColorPointer((size),(type),(stride),(pointer))
#define glIndexPointerEXT(type,stride,count,pointer) \
  glIndexPointer((type),(stride),(pointer))
#define glTexCoordPointerEXT(size,type,stride,count,pointer) \
  glTexCoordPointer((size),(type),(stride),(pointer))
#define glEdgeFlagPointerEXT(stride,count,pointer) \
  glEdgeFlagPointer((stride),(pointer))
#endif

#endif
#endif /* Remap 1.1 extensions */

#ifndef GL_EXT_Cg_shader
#define GL_EXT_Cg_shader 1
#define GL_CG_VERTEX_SHADER_EXT           0x890E
#define GL_CG_FRAGMENT_SHADER_EXT         0x890F
#endif

/* missing defs */
#ifndef GL_CMYK
#define GL_CMYK GL_CMYK_EXT
#endif

#ifndef GL_CMYKA
#define GL_CMYKA GL_CMYKA_EXT
#endif

#ifndef GL_PACK_CMYK_HINT
#define GL_PACK_CMYK_HINT GL_PACK_CMYK_HINT_EXT
#endif

#ifndef GL_UNPACK_CMYK_HINT
#define GL_UNPACK_CMYK_HINT GL_UNPACK_CMYK_HINT_EXT
#endif

#ifndef GL_BLEND_EQUATION_EXT
#define GL_BLEND_EQUATION_EXT 0x8009
#endif

#ifndef GL_BLEND_COLOR_EXT
#define GL_BLEND_COLOR_EXT 0x8005
#endif

// fake bgr constants so OpenGL::Image::Targa will work on GL1.1
#if !defined(GL_VERSION_1_2) && defined(GL_EXT_bgra)
#define GL_BGR                            GL_BGR_EXT
#define GL_BGRA                           GL_BGRA_EXT
#endif

#define MAX_GL_TEXPARAMETER_COUNT	4

extern int gl_texparameter_count(GLenum pname);

#define MAX_GL_TEXENV_COUNT	4

extern int gl_texenv_count(GLenum pname);

#define MAX_GL_TEXGEN_COUNT	4

extern int gl_texgen_count(GLenum pname);

#define MAX_GL_MATERIAL_COUNT	4

extern int gl_material_count(GLenum pname);

#define MAX_GL_MAP_COUNT	4

extern int gl_map_count(GLenum target, GLenum query);

#define MAX_GL_LIGHT_COUNT	4

extern int gl_light_count(GLenum pname);

#define MAX_GL_LIGHTMODEL_COUNT	4

extern int gl_lightmodel_count(GLenum pname);

#define MAX_GL_FOG_COUNT	4

extern int gl_fog_count(GLenum pname);

#define MAX_GL_GET_COUNT	16

extern int gl_get_count(GLenum param);

extern int gl_pixelmap_size(GLenum map);

extern int gl_state_count(GLenum state);

enum {
	gl_pixelbuffer_pack = 1,
	gl_pixelbuffer_unpack = 2,
};

extern unsigned long gl_pixelbuffer_size(
	GLenum format,
	GLsizei	width,
	GLsizei	height,
	GLenum	type,
	int mode);

extern GLvoid * pack_image_ST(SV ** stack, int count, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, int mode);
extern GLvoid * allocate_image_ST(GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, int mode);

extern SV ** unpack_image_ST(SV ** SP, void * data, 
GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, int mode);

extern int gl_type_size(GLenum type);

extern int gl_component_count(GLenum format, GLenum type);

// Only support 2 for now
#define MAX_ARRAY_DIMENSIONS	2

struct oga_struct {
	int type_count, item_count;
	GLint bind;
	GLenum * types;
	GLint * type_offset;
	int total_types_width;
	void * data;
	int data_length;
  int dimension_count;
  int dimensions[MAX_ARRAY_DIMENSIONS];

	GLuint target, pixel_type, pixel_format, element_size;
	GLuint affine_handle;
	GLuint tex_handle[2];
	GLuint fbo_handle;
	int fbo_w, fbo_h;

	int free_data;
};

typedef struct oga_struct oga_struct;

typedef oga_struct * OpenGL__Array;
typedef oga_struct * OpenGL__Matrix;
