#if defined(IS_STRAWBERRY)

#undef exit
#include <GL/freeglut.h>

#elif defined(HAVE_FREEGLUT) && (defined(_WIN32) || defined(HAVE_W32API))

#define GLUT_DISABLE_ATEXIT_HACK

#include "./include/GL/freeglut.h"

#elif defined(HAVE_FREEGLUT_H)

#include <GL/freeglut.h>

#else

#if defined(HAVE_AGL_GLUT)
#include <GLUT/glut.h>
#else
#include <GL/glut.h>
#endif

#if 0
#   define GLUT_ACTION_EXIT                         0
#   define GLUT_ACTION_GLUTMAINLOOP_RETURNS         1
#   define GLUT_ACTION_CONTINUE_EXECUTION           2
#   define GLUT_CREATE_NEW_CONTEXT                  0
#   define GLUT_USE_CURRENT_CONTEXT                 1
#   define GLUT_FORCE_INDIRECT_CONTEXT              0
#   define GLUT_ALLOW_DIRECT_CONTEXT                1
#   define GLUT_TRY_DIRECT_CONTEXT                  2
#   define GLUT_FORCE_DIRECT_CONTEXT                3
#   define GLUT_ACTION_ON_WINDOW_CLOSE         0x01F9
#   define GLUT_WINDOW_BORDER_WIDTH            0x01FA
#   define GLUT_WINDOW_HEADER_HEIGHT           0x01FB
#   define GLUT_VERSION                        0x01FC
#   define GLUT_RENDERING_CONTEXT              0x01FD
#   define GLUT_DIRECT_RENDERING               0x01FE
#endif

#endif
