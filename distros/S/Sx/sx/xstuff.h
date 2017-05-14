#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include <X11/Xutil.h>
#include <X11/Shell.h>
#ifdef XAW3D
#include <X11/Xaw3d/Form.h>
#include <X11/Xaw3d/Label.h>
#else
#include <X11/Xaw/Form.h>
#include <X11/Xaw/Label.h>
#endif

#ifdef    OPENGL_SUPPORT
#include <GL/gl.h>
#include <GL/glx.h>
#endif /* OPENGL_SUPPORT */
