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

#endif

#if defined(HAVE_FREEGLUT)
#  include "./include/GL/freeglut_ext.h"
#endif
