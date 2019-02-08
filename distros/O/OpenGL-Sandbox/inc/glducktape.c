#include <GL/gl.h>
#include <GL/glext.h>
extern void* glducktape_initProcAddress(const char *name, void **fnptr);
#ifdef GL_VERSION_2_0
 extern PFNGLBINDBUFFERPROC glducktape_glBindBuffer;
 #define glBindBuffer (glducktape_glBindBuffer? glducktape_glBindBuffer : (PFNGLBINDBUFFERPROC)glducktape_initProcAddress("glBindBuffer",(void**)&glducktape_glBindBuffer))

 extern PFNGLBUFFERDATAPROC glducktape_glBufferData;
 #define glBufferData (glducktape_glBufferData? glducktape_glBufferData : (PFNGLBUFFERDATAPROC)glducktape_initProcAddress("glBufferData",(void**)&glducktape_glBufferData))

 extern PFNGLBUFFERSUBDATAPROC glducktape_glBufferSubData;
 #define glBufferSubData (glducktape_glBufferSubData? glducktape_glBufferSubData : (PFNGLBUFFERSUBDATAPROC)glducktape_initProcAddress("glBufferSubData",(void**)&glducktape_glBufferSubData))

 extern PFNGLDELETEBUFFERSPROC glducktape_glDeleteBuffers;
 #define glDeleteBuffers (glducktape_glDeleteBuffers? glducktape_glDeleteBuffers : (PFNGLDELETEBUFFERSPROC)glducktape_initProcAddress("glDeleteBuffers",(void**)&glducktape_glDeleteBuffers))

 extern PFNGLGENBUFFERSPROC glducktape_glGenBuffers;
 #define glGenBuffers (glducktape_glGenBuffers? glducktape_glGenBuffers : (PFNGLGENBUFFERSPROC)glducktape_initProcAddress("glGenBuffers",(void**)&glducktape_glGenBuffers))

 extern PFNGLGETACTIVEUNIFORMPROC glducktape_glGetActiveUniform;
 #define glGetActiveUniform (glducktape_glGetActiveUniform? glducktape_glGetActiveUniform : (PFNGLGETACTIVEUNIFORMPROC)glducktape_initProcAddress("glGetActiveUniform",(void**)&glducktape_glGetActiveUniform))

 extern PFNGLGETBUFFERPARAMETERIVPROC glducktape_glGetBufferParameteriv;
 #define glGetBufferParameteriv (glducktape_glGetBufferParameteriv? glducktape_glGetBufferParameteriv : (PFNGLGETBUFFERPARAMETERIVPROC)glducktape_initProcAddress("glGetBufferParameteriv",(void**)&glducktape_glGetBufferParameteriv))

 extern PFNGLGETPROGRAMIVPROC glducktape_glGetProgramiv;
 #define glGetProgramiv (glducktape_glGetProgramiv? glducktape_glGetProgramiv : (PFNGLGETPROGRAMIVPROC)glducktape_initProcAddress("glGetProgramiv",(void**)&glducktape_glGetProgramiv))

 extern PFNGLGETUNIFORMLOCATIONPROC glducktape_glGetUniformLocation;
 #define glGetUniformLocation (glducktape_glGetUniformLocation? glducktape_glGetUniformLocation : (PFNGLGETUNIFORMLOCATIONPROC)glducktape_initProcAddress("glGetUniformLocation",(void**)&glducktape_glGetUniformLocation))

 extern PFNGLMAPBUFFERPROC glducktape_glMapBuffer;
 #define glMapBuffer (glducktape_glMapBuffer? glducktape_glMapBuffer : (PFNGLMAPBUFFERPROC)glducktape_initProcAddress("glMapBuffer",(void**)&glducktape_glMapBuffer))

 extern PFNGLUNIFORM1FVPROC glducktape_glUniform1fv;
 #define glUniform1fv (glducktape_glUniform1fv? glducktape_glUniform1fv : (PFNGLUNIFORM1FVPROC)glducktape_initProcAddress("glUniform1fv",(void**)&glducktape_glUniform1fv))

 extern PFNGLUNIFORM1IVPROC glducktape_glUniform1iv;
 #define glUniform1iv (glducktape_glUniform1iv? glducktape_glUniform1iv : (PFNGLUNIFORM1IVPROC)glducktape_initProcAddress("glUniform1iv",(void**)&glducktape_glUniform1iv))

 extern PFNGLUNIFORM2FVPROC glducktape_glUniform2fv;
 #define glUniform2fv (glducktape_glUniform2fv? glducktape_glUniform2fv : (PFNGLUNIFORM2FVPROC)glducktape_initProcAddress("glUniform2fv",(void**)&glducktape_glUniform2fv))

 extern PFNGLUNIFORM2IVPROC glducktape_glUniform2iv;
 #define glUniform2iv (glducktape_glUniform2iv? glducktape_glUniform2iv : (PFNGLUNIFORM2IVPROC)glducktape_initProcAddress("glUniform2iv",(void**)&glducktape_glUniform2iv))

 extern PFNGLUNIFORM3FVPROC glducktape_glUniform3fv;
 #define glUniform3fv (glducktape_glUniform3fv? glducktape_glUniform3fv : (PFNGLUNIFORM3FVPROC)glducktape_initProcAddress("glUniform3fv",(void**)&glducktape_glUniform3fv))

 extern PFNGLUNIFORM3IVPROC glducktape_glUniform3iv;
 #define glUniform3iv (glducktape_glUniform3iv? glducktape_glUniform3iv : (PFNGLUNIFORM3IVPROC)glducktape_initProcAddress("glUniform3iv",(void**)&glducktape_glUniform3iv))

 extern PFNGLUNIFORM4FVPROC glducktape_glUniform4fv;
 #define glUniform4fv (glducktape_glUniform4fv? glducktape_glUniform4fv : (PFNGLUNIFORM4FVPROC)glducktape_initProcAddress("glUniform4fv",(void**)&glducktape_glUniform4fv))

 extern PFNGLUNIFORM4IVPROC glducktape_glUniform4iv;
 #define glUniform4iv (glducktape_glUniform4iv? glducktape_glUniform4iv : (PFNGLUNIFORM4IVPROC)glducktape_initProcAddress("glUniform4iv",(void**)&glducktape_glUniform4iv))

 extern PFNGLUNIFORMMATRIX2FVPROC glducktape_glUniformMatrix2fv;
 #define glUniformMatrix2fv (glducktape_glUniformMatrix2fv? glducktape_glUniformMatrix2fv : (PFNGLUNIFORMMATRIX2FVPROC)glducktape_initProcAddress("glUniformMatrix2fv",(void**)&glducktape_glUniformMatrix2fv))

 extern PFNGLUNIFORMMATRIX3FVPROC glducktape_glUniformMatrix3fv;
 #define glUniformMatrix3fv (glducktape_glUniformMatrix3fv? glducktape_glUniformMatrix3fv : (PFNGLUNIFORMMATRIX3FVPROC)glducktape_initProcAddress("glUniformMatrix3fv",(void**)&glducktape_glUniformMatrix3fv))

 extern PFNGLUNIFORMMATRIX4FVPROC glducktape_glUniformMatrix4fv;
 #define glUniformMatrix4fv (glducktape_glUniformMatrix4fv? glducktape_glUniformMatrix4fv : (PFNGLUNIFORMMATRIX4FVPROC)glducktape_initProcAddress("glUniformMatrix4fv",(void**)&glducktape_glUniformMatrix4fv))

 extern PFNGLUNMAPBUFFERPROC glducktape_glUnmapBuffer;
 #define glUnmapBuffer (glducktape_glUnmapBuffer? glducktape_glUnmapBuffer : (PFNGLUNMAPBUFFERPROC)glducktape_initProcAddress("glUnmapBuffer",(void**)&glducktape_glUnmapBuffer))

#endif /* GL_VERSION_2_0 */
#ifdef GL_VERSION_2_1
 extern PFNGLUNIFORMMATRIX2X3FVPROC glducktape_glUniformMatrix2x3fv;
 #define glUniformMatrix2x3fv (glducktape_glUniformMatrix2x3fv? glducktape_glUniformMatrix2x3fv : (PFNGLUNIFORMMATRIX2X3FVPROC)glducktape_initProcAddress("glUniformMatrix2x3fv",(void**)&glducktape_glUniformMatrix2x3fv))

 extern PFNGLUNIFORMMATRIX2X4FVPROC glducktape_glUniformMatrix2x4fv;
 #define glUniformMatrix2x4fv (glducktape_glUniformMatrix2x4fv? glducktape_glUniformMatrix2x4fv : (PFNGLUNIFORMMATRIX2X4FVPROC)glducktape_initProcAddress("glUniformMatrix2x4fv",(void**)&glducktape_glUniformMatrix2x4fv))

 extern PFNGLUNIFORMMATRIX3X2FVPROC glducktape_glUniformMatrix3x2fv;
 #define glUniformMatrix3x2fv (glducktape_glUniformMatrix3x2fv? glducktape_glUniformMatrix3x2fv : (PFNGLUNIFORMMATRIX3X2FVPROC)glducktape_initProcAddress("glUniformMatrix3x2fv",(void**)&glducktape_glUniformMatrix3x2fv))

 extern PFNGLUNIFORMMATRIX3X4FVPROC glducktape_glUniformMatrix3x4fv;
 #define glUniformMatrix3x4fv (glducktape_glUniformMatrix3x4fv? glducktape_glUniformMatrix3x4fv : (PFNGLUNIFORMMATRIX3X4FVPROC)glducktape_initProcAddress("glUniformMatrix3x4fv",(void**)&glducktape_glUniformMatrix3x4fv))

 extern PFNGLUNIFORMMATRIX4X2FVPROC glducktape_glUniformMatrix4x2fv;
 #define glUniformMatrix4x2fv (glducktape_glUniformMatrix4x2fv? glducktape_glUniformMatrix4x2fv : (PFNGLUNIFORMMATRIX4X2FVPROC)glducktape_initProcAddress("glUniformMatrix4x2fv",(void**)&glducktape_glUniformMatrix4x2fv))

 extern PFNGLUNIFORMMATRIX4X3FVPROC glducktape_glUniformMatrix4x3fv;
 #define glUniformMatrix4x3fv (glducktape_glUniformMatrix4x3fv? glducktape_glUniformMatrix4x3fv : (PFNGLUNIFORMMATRIX4X3FVPROC)glducktape_initProcAddress("glUniformMatrix4x3fv",(void**)&glducktape_glUniformMatrix4x3fv))

#endif /* GL_VERSION_2_1 */
#ifdef GL_VERSION_3_0
 extern PFNGLDELETEVERTEXARRAYSPROC glducktape_glDeleteVertexArrays;
 #define glDeleteVertexArrays (glducktape_glDeleteVertexArrays? glducktape_glDeleteVertexArrays : (PFNGLDELETEVERTEXARRAYSPROC)glducktape_initProcAddress("glDeleteVertexArrays",(void**)&glducktape_glDeleteVertexArrays))

 extern PFNGLGENERATEMIPMAPPROC glducktape_glGenerateMipmap;
 #define glGenerateMipmap (glducktape_glGenerateMipmap? glducktape_glGenerateMipmap : (PFNGLGENERATEMIPMAPPROC)glducktape_initProcAddress("glGenerateMipmap",(void**)&glducktape_glGenerateMipmap))

 extern PFNGLGENVERTEXARRAYSPROC glducktape_glGenVertexArrays;
 #define glGenVertexArrays (glducktape_glGenVertexArrays? glducktape_glGenVertexArrays : (PFNGLGENVERTEXARRAYSPROC)glducktape_initProcAddress("glGenVertexArrays",(void**)&glducktape_glGenVertexArrays))

 extern PFNGLMAPBUFFERRANGEPROC glducktape_glMapBufferRange;
 #define glMapBufferRange (glducktape_glMapBufferRange? glducktape_glMapBufferRange : (PFNGLMAPBUFFERRANGEPROC)glducktape_initProcAddress("glMapBufferRange",(void**)&glducktape_glMapBufferRange))

 extern PFNGLUNIFORM1UIVPROC glducktape_glUniform1uiv;
 #define glUniform1uiv (glducktape_glUniform1uiv? glducktape_glUniform1uiv : (PFNGLUNIFORM1UIVPROC)glducktape_initProcAddress("glUniform1uiv",(void**)&glducktape_glUniform1uiv))

 extern PFNGLUNIFORM2UIVPROC glducktape_glUniform2uiv;
 #define glUniform2uiv (glducktape_glUniform2uiv? glducktape_glUniform2uiv : (PFNGLUNIFORM2UIVPROC)glducktape_initProcAddress("glUniform2uiv",(void**)&glducktape_glUniform2uiv))

 extern PFNGLUNIFORM3UIVPROC glducktape_glUniform3uiv;
 #define glUniform3uiv (glducktape_glUniform3uiv? glducktape_glUniform3uiv : (PFNGLUNIFORM3UIVPROC)glducktape_initProcAddress("glUniform3uiv",(void**)&glducktape_glUniform3uiv))

 extern PFNGLUNIFORM4UIVPROC glducktape_glUniform4uiv;
 #define glUniform4uiv (glducktape_glUniform4uiv? glducktape_glUniform4uiv : (PFNGLUNIFORM4UIVPROC)glducktape_initProcAddress("glUniform4uiv",(void**)&glducktape_glUniform4uiv))

#endif /* GL_VERSION_3_0 */
#ifdef GL_VERSION_4_5
 extern PFNGLGETNAMEDBUFFERPARAMETERIVPROC glducktape_glGetNamedBufferParameteriv;
 #define glGetNamedBufferParameteriv (glducktape_glGetNamedBufferParameteriv? glducktape_glGetNamedBufferParameteriv : (PFNGLGETNAMEDBUFFERPARAMETERIVPROC)glducktape_initProcAddress("glGetNamedBufferParameteriv",(void**)&glducktape_glGetNamedBufferParameteriv))

 extern PFNGLMAPNAMEDBUFFERRANGEPROC glducktape_glMapNamedBufferRange;
 #define glMapNamedBufferRange (glducktape_glMapNamedBufferRange? glducktape_glMapNamedBufferRange : (PFNGLMAPNAMEDBUFFERRANGEPROC)glducktape_initProcAddress("glMapNamedBufferRange",(void**)&glducktape_glMapNamedBufferRange))

 extern PFNGLUNMAPNAMEDBUFFERPROC glducktape_glUnmapNamedBuffer;
 #define glUnmapNamedBuffer (glducktape_glUnmapNamedBuffer? glducktape_glUnmapNamedBuffer : (PFNGLUNMAPNAMEDBUFFERPROC)glducktape_initProcAddress("glUnmapNamedBuffer",(void**)&glducktape_glUnmapNamedBuffer))

#endif /* GL_VERSION_4_5 */
#ifdef GL_VERSION_2_0
  PFNGLBINDBUFFERPROC glducktape_glBindBuffer = NULL;
  PFNGLBUFFERDATAPROC glducktape_glBufferData = NULL;
  PFNGLBUFFERSUBDATAPROC glducktape_glBufferSubData = NULL;
  PFNGLDELETEBUFFERSPROC glducktape_glDeleteBuffers = NULL;
  PFNGLGENBUFFERSPROC glducktape_glGenBuffers = NULL;
  PFNGLGETACTIVEUNIFORMPROC glducktape_glGetActiveUniform = NULL;
  PFNGLGETBUFFERPARAMETERIVPROC glducktape_glGetBufferParameteriv = NULL;
  PFNGLGETPROGRAMIVPROC glducktape_glGetProgramiv = NULL;
  PFNGLGETUNIFORMLOCATIONPROC glducktape_glGetUniformLocation = NULL;
  PFNGLMAPBUFFERPROC glducktape_glMapBuffer = NULL;
  PFNGLUNIFORM1FVPROC glducktape_glUniform1fv = NULL;
  PFNGLUNIFORM1IVPROC glducktape_glUniform1iv = NULL;
  PFNGLUNIFORM2FVPROC glducktape_glUniform2fv = NULL;
  PFNGLUNIFORM2IVPROC glducktape_glUniform2iv = NULL;
  PFNGLUNIFORM3FVPROC glducktape_glUniform3fv = NULL;
  PFNGLUNIFORM3IVPROC glducktape_glUniform3iv = NULL;
  PFNGLUNIFORM4FVPROC glducktape_glUniform4fv = NULL;
  PFNGLUNIFORM4IVPROC glducktape_glUniform4iv = NULL;
  PFNGLUNIFORMMATRIX2FVPROC glducktape_glUniformMatrix2fv = NULL;
  PFNGLUNIFORMMATRIX3FVPROC glducktape_glUniformMatrix3fv = NULL;
  PFNGLUNIFORMMATRIX4FVPROC glducktape_glUniformMatrix4fv = NULL;
  PFNGLUNMAPBUFFERPROC glducktape_glUnmapBuffer = NULL;
#endif /* GL_VERSION_2_0 */
#ifdef GL_VERSION_2_1
  PFNGLUNIFORMMATRIX2X3FVPROC glducktape_glUniformMatrix2x3fv = NULL;
  PFNGLUNIFORMMATRIX2X4FVPROC glducktape_glUniformMatrix2x4fv = NULL;
  PFNGLUNIFORMMATRIX3X2FVPROC glducktape_glUniformMatrix3x2fv = NULL;
  PFNGLUNIFORMMATRIX3X4FVPROC glducktape_glUniformMatrix3x4fv = NULL;
  PFNGLUNIFORMMATRIX4X2FVPROC glducktape_glUniformMatrix4x2fv = NULL;
  PFNGLUNIFORMMATRIX4X3FVPROC glducktape_glUniformMatrix4x3fv = NULL;
#endif /* GL_VERSION_2_1 */
#ifdef GL_VERSION_3_0
  PFNGLDELETEVERTEXARRAYSPROC glducktape_glDeleteVertexArrays = NULL;
  PFNGLGENERATEMIPMAPPROC glducktape_glGenerateMipmap = NULL;
  PFNGLGENVERTEXARRAYSPROC glducktape_glGenVertexArrays = NULL;
  PFNGLMAPBUFFERRANGEPROC glducktape_glMapBufferRange = NULL;
  PFNGLUNIFORM1UIVPROC glducktape_glUniform1uiv = NULL;
  PFNGLUNIFORM2UIVPROC glducktape_glUniform2uiv = NULL;
  PFNGLUNIFORM3UIVPROC glducktape_glUniform3uiv = NULL;
  PFNGLUNIFORM4UIVPROC glducktape_glUniform4uiv = NULL;
#endif /* GL_VERSION_3_0 */
#ifdef GL_VERSION_4_5
  PFNGLGETNAMEDBUFFERPARAMETERIVPROC glducktape_glGetNamedBufferParameteriv = NULL;
  PFNGLMAPNAMEDBUFFERRANGEPROC glducktape_glMapNamedBufferRange = NULL;
  PFNGLUNMAPNAMEDBUFFERPROC glducktape_glUnmapNamedBuffer = NULL;
#endif /* GL_VERSION_4_5 */

#if defined(_WIN32) || defined(__CYGWIN__)
#include <windows.h>
static HMODULE glducktape_libGL;

typedef void* (APIENTRYP PFNWGLGETPROCADDRESSPROC_PRIVATE)(const char*);
static PFNWGLGETPROCADDRESSPROC_PRIVATE glducktape_GetProcAddressPtr;

#ifdef _MSC_VER
#ifdef __has_include
  #if __has_include(<winapifamily.h>)
    #define HAVE_WINAPIFAMILY 1
  #endif
#elif _MSC_VER >= 1700 && !_USING_V110_SDK71_
  #define HAVE_WINAPIFAMILY 1
#endif
#endif

#ifdef HAVE_WINAPIFAMILY
  #include <winapifamily.h>
  #if !WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_DESKTOP) && WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_APP)
    #define IS_UWP 1
  #endif
#endif

static
int open_gl(void) {
#ifndef IS_UWP
    glducktape_libGL = LoadLibraryW(L"opengl32.dll");
    if(glducktape_libGL != NULL) {
        void (* tmp)(void);
        tmp = (void(*)(void)) GetProcAddress(glducktape_libGL, "wglGetProcAddress");
        glducktape_GetProcAddressPtr = (PFNWGLGETPROCADDRESSPROC_PRIVATE) tmp;
        return glducktape_GetProcAddressPtr != NULL;
    }
#endif

    return 0;
}

#else
#include <dlfcn.h>
static void* glducktape_libGL;

#if !defined(__APPLE__) && !defined(__HAIKU__)
typedef void* (APIENTRYP PFNGLXGETPROCADDRESSPROC_PRIVATE)(const char*);
static PFNGLXGETPROCADDRESSPROC_PRIVATE glducktape_GetProcAddressPtr;
#endif

static
int open_gl(void) {
#ifdef __APPLE__
    static const char *NAMES[] = {
        "../Frameworks/OpenGL.framework/OpenGL",
        "/Library/Frameworks/OpenGL.framework/OpenGL",
        "/System/Library/Frameworks/OpenGL.framework/OpenGL",
        "/System/Library/Frameworks/OpenGL.framework/Versions/Current/OpenGL"
    };
#else
    static const char *NAMES[] = {"libGL.so.1", "libGL.so"};
#endif

    unsigned int index = 0;
    for(index = 0; index < (sizeof(NAMES) / sizeof(NAMES[0])); index++) {
        glducktape_libGL = dlopen(NAMES[index], RTLD_NOW | RTLD_GLOBAL);

        if(glducktape_libGL != NULL) {
#if defined(__APPLE__) || defined(__HAIKU__)
            return 1;
#else
            glducktape_GetProcAddressPtr = (PFNGLXGETPROCADDRESSPROC_PRIVATE)dlsym(glducktape_libGL,
                "glXGetProcAddressARB");
            return glducktape_GetProcAddressPtr != NULL;
#endif
        }
    }

    return 0;
}

#endif

void* glducktape_initProcAddress(const char *name, void **fnptr) {
    void* result = NULL;
	if (!glducktape_libGL) {
		open_gl();
		if (!glducktape_libGL)
			croak("Can't load OpenGL library");
	}

#if !defined(__APPLE__) && !defined(__HAIKU__)
    if(glducktape_GetProcAddressPtr != NULL) {
        result = glducktape_GetProcAddressPtr(name);
    }
#endif
    if(result == NULL) {
#if defined(_WIN32) || defined(__CYGWIN__)
        result = (void*)GetProcAddress((HMODULE) glducktape_libGL, name);
#else
        result = dlsym(glducktape_libGL, name);
#endif
    }
	if (!result)
		croak("Can't look up address of %s", name);
	*fnptr= result;
    return result;
}
