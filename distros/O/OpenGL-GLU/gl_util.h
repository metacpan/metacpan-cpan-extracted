#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#if defined(__APPLE__)
#include <OpenGL/gl.h>
#else
#include <GL/gl.h>
#endif

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

extern GLvoid * ELI(SV * sv, GLsizei width, GLsizei height, GLenum format, GLenum type, int mode);

extern GLvoid * EL(SV * sv, int needlen);

extern int gl_type_size(GLenum type);

extern int gl_component_count(GLenum format, GLenum type);
