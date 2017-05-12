#if defined(HAVE_AGL_GLUT)
#include <OpenGL/glu.h>
#else
#include <GL/glu.h>
#endif

#ifndef GLU_VERSION_1_0
#define GLU_VERSION_1_0 1
#endif

#ifdef GLU_VERSION_1_0
#ifndef GLU_VERSION_1_1
typedef GLUnurbs		GLUnurbsObj;
typedef GLUtriangulatorObj	GLUtriangulatorObj;
typedef GLUquadricObj		GLUquadricObjObj;
#endif
#endif

