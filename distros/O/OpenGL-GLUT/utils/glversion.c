#include <stdio.h>

#if defined(HAVE_FREEGLUT)

#ifdef WIN32
#include "../include/GL/freeglut.h"
#else
#include <GL/freeglut.h>
#endif

#else

#ifdef __APPLE__
/* NB: not ideal -- this assumes that we always build with AGL interface on Mac OS X
 * Ideally, the flag HAVE_AGL_GLUT should be set appropriately by Makefile.PL when building glversion
 * and used to check here, but this will require substantial changes to the get_extensions() there
 */
#include <GLUT/glut.h>
#else
#include <GL/glut.h>
#endif

#endif

#define PROGRAM "glversion"

int main(int argc, char **argv)
{
  char *version = NULL;
  char *vendor = NULL;
  char *renderer = NULL;
  char *extensions = NULL;
  GLuint idWindow = 0;
  int	freeglutVersion;

  glutInit(&argc, argv);
  glutInitWindowSize(1,1);
  glutInitDisplayMode(GLUT_RGBA);
  idWindow = glutCreateWindow(PROGRAM);
  glutHideWindow();

  version =     (char*)glGetString(GL_VERSION);
  vendor =      (char*)glGetString(GL_VENDOR);
  renderer =    (char*)glGetString(GL_RENDERER);
  extensions =  (char*)glGetString(GL_EXTENSIONS);

  freeglutVersion = glutGet(0x01FC);
  if(freeglutVersion != -1) {
    printf("FREEGLUT=%d\n", freeglutVersion);
  }
  printf("GLUT=%d\n", GLUT_API_VERSION);

  printf("VERSION=%s\nVENDOR=%s\nRENDERER=%s\nEXTENSIONS=%s\n", version, vendor, renderer, extensions);

  glutDestroyWindow(idWindow);
  return(0);
}
