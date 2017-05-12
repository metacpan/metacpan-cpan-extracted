#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef PERL_DARWIN
#include <GL/glut.h>
#else
#include <GLUT/glut.h>
#endif

#include "const-c.inc"

HV *TimerFuncs = NULL;
AV *MenuFuncs = NULL;


/*
 * There now follows some CPP macrology in order to reduce cut-and-paste
 * coding to generate the code to handle GLUT callbacks.
 *
 * Most glutFooFunc() callback-setting routines, with the notable
 * exception of glutTimerFunc(), take a single argument: a pointer to
 * the callback function. This function will take a number of arguments
 * which depends on precisely which callback it is handling.
 *
 * However, most of these callbacks are not global: they are per-window.
 * The way this is handled in XS is as follows: take glutDisplayFunc as
 * an example.
 *
 * Define an AV, DisplayFuncs. If glutDisplayFunc() is called, the id
 * of the current window is found from glutGetWindow(); this will be a
 * small integer. This integer is used as an index into DisplayFuncs,
 * and the coderef passed to glutDisplayFuncs is stored at this index.
 *
 * Now, define the function void DisplayCallback(void) , which finds
 * the current window ID, and then calls the appropriate coderef stored
 * in DisplayFuncs. Set *this* function to be the callback, as far as
 * GLUT is concerned.
 *
 * Since there are many callbacks of many types, this procedure has
 * been automated using cpp. The register_callback() macro defines the
 * appropriate AV and FooCallback() function; it takes some code as an
 * argument to set up the perl argument stack.
 *
 * This is in turn called from the macros register_callback_noargs(),
 * register_callback_2i(), etc. These take one argument, the callback ID
 * (such as "Display" to define DisplayFuncs, DisplayCallback() etc),
 * and make the appropriate calls to register_callback to define a
 * callback function which takes no arguments, two integer arguments,
 * etc.
 *
 * To summarize, say you have a new kind of callback, Foo, which is called
 * with two integer arguments. To set this up in XS, you do:
 *
 * (1) in the plain-C section:
 *
 *     register_callback_2i(Foo)
 *
 * (2) in the XS section:
 *
 *      void glutFooFunc(SV *cb)
 *           CODE:
 *                register_callback_xs(Foo)
 *
 *  That's it!
 *
 *
 */

#define register_callback(cbname,prototype,xscode,callflags) \
AV * cbname ## Funcs=NULL; \
void cbname ## Callback prototype \
{ \
	int id; \
	SV **fetchval; \
\
	dSP; \
	id = glutGetWindow(); \
	if (NULL== cbname ## Funcs) { \
	  croak(#cbname "Callback called with id=%d but " \
		#cbname "Funcs is NULL!", id); \
	} \
\
	if (NULL==(fetchval=av_fetch( cbname ## Funcs,id,FALSE))) { \
		croak("No " #cbname "Func defined for id=%d",id); \
	} \
\
	ENTER; \
	SAVETMPS; \
	PUSHMARK(SP); \
	xscode	\
\
 	PUTBACK; \
\
	call_sv((SV *)*fetchval,G_DISCARD|callflags); \
\
	FREETMPS; \
	LEAVE; \
	 \
\
	return; \
\
}

#define register_callback_noargs(cbname) \
	register_callback(cbname,(void),,G_NOARGS)

#define register_callback_1i(cbname) \
	register_callback(cbname,(int a), \
		XPUSHs(sv_2mortal(newSViv(a))); ,0)\

#define register_callback_2i(cbname) \
	register_callback(cbname,(int a, int b), \
		XPUSHs(sv_2mortal(newSViv(a))); \
		XPUSHs(sv_2mortal(newSViv(b))); ,0)\

#define register_callback_3i(cbname) \
	register_callback(cbname,(int a, int b, int c), \
		XPUSHs(sv_2mortal(newSViv(a))); \
		XPUSHs(sv_2mortal(newSViv(b))); \
		XPUSHs(sv_2mortal(newSViv(c))); ,0)\

#define register_callback_4i(cbname) \
	register_callback(cbname,(int a, int b, int c, int d), \
		XPUSHs(sv_2mortal(newSViv(a))); \
		XPUSHs(sv_2mortal(newSViv(b))); \
		XPUSHs(sv_2mortal(newSViv(c))); \
		XPUSHs(sv_2mortal(newSViv(d))); ,0)\

#define register_callback_uc2i(cbname) \
	register_callback(cbname,(unsigned char uc, int a, int b), \
		XPUSHs(sv_2mortal(newSVuv(uc))); \
		XPUSHs(sv_2mortal(newSViv(a))); \
		XPUSHs(sv_2mortal(newSViv(b))); ,0)\

#define register_callback_xs(cbname) \
		if (!SvROK(cb)) { \
                        if (SVt_IV == SvTYPE(cb)) { \
                                if (0==SvIV(cb)) { \
                                        glut ## cbname ## Func(NULL); \
		av_store( cbname ## Funcs,glutGetWindow(),newSViv(0)); \
                                        return; \
                                } \
                        } \
                        croak("Callback must be code reference"); \
                        return; \
		} \
		if (SVt_PVCV != SvTYPE(SvRV(cb))) { \
			croak("Callback must be code reference"); \
			return; \
		} \
\
		if (NULL== cbname ## Funcs) { \
			 cbname ## Funcs = newAV(); \
		} \
\
		av_store( cbname ## Funcs,glutGetWindow(),newSVsv(cb)); \
		glut ## cbname ## Func( cbname ## Callback); \

/*********** End of macro definitions *************/


/* Callback definitions */

register_callback_noargs(Display)
register_callback_noargs(OverlayDisplay)
register_callback_2i(Reshape)
register_callback_uc2i(Keyboard)
register_callback_4i(Mouse)
register_callback_2i(Motion)
register_callback_2i(PassiveMotion)
register_callback_1i(Visibility)
register_callback_1i(Entry)
register_callback_3i(Special)
register_callback_3i(SpaceballMotion)
register_callback_3i(SpaceballRotate)
register_callback_2i(SpaceballButton)
register_callback_2i(ButtonBox)
register_callback_2i(Dials)
register_callback_2i(TabletMotion)
register_callback_4i(TabletButton)
register_callback_3i(MenuStatus)
register_callback_1i(MenuState)
register_callback_noargs(Idle)


/* Plain C code */


void TimerCallback(int value)
{
	HE *hashent;
	SV *hashvalue,*callback,*realvalue;
	AV *myarr;
	dSP;

	hashent = hv_fetch_ent(TimerFuncs,newSViv(value),FALSE,0);

	if (NULL==hashent) {
		croak("TimerCallback(value=%d) has no hash entry!",value);
	}

	hashvalue = HeVAL(hashent);

	/*
	 * Be really anal about what we get back from the hash.
	 * To start with, make sure we're holding a reference to an array.
	 * */

	if (!SvROK(hashvalue)) {
		croak("TimerCallback: hash entry is not a reference!");
		return;
	}
	if (SVt_PVAV != SvTYPE(SvRV(hashvalue))) {
		croak("TimerCallback: hash entry is not an array reference!");
		return;
	}

	myarr = (AV *)SvRV(hashvalue);
	if (1!=av_len(myarr)) {
		croak("TimerCallback: av_len(myarr)=%d not 1!\n",av_len(myarr));
	}

	/* OK, finally grab the coderef and value out of the array */
	callback = *av_fetch(myarr,0,FALSE);
	realvalue = *av_fetch(myarr,1,FALSE);

	/* Delete the hash entry now that we've finished with it */

	hv_delete_ent(TimerFuncs,newSViv(value),G_DISCARD,0);


	ENTER;
	SAVETMPS;
	PUSHMARK(SP);	/* Set up stack frame for routine we'll call */

	XPUSHs(sv_2mortal(newSVsv(realvalue))); /* dump "value" arg on stack */
	PUTBACK;
	call_sv((SV *)callback,G_DISCARD);	/* Call callback */

	FREETMPS;
	LEAVE;

}

void MenuCallback(int value)
{
	int id;
	SV **fetchval;

	dSP;
	id = glutGetMenu();
	if (NULL==MenuFuncs) {
	  croak("MenuCallback called with id=%d but MenuFuncs is NULL!", id);
	}

	if (NULL==(fetchval=av_fetch(MenuFuncs,id,FALSE))) {
		croak("No MenuFunc defined for id=%d",id);
	}

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSViv(value)));

 	PUTBACK;

	call_sv((SV *)*fetchval,G_DISCARD);

	FREETMPS;
	LEAVE;

	return;

}

MODULE = OpenGL::Simple::GLUT		PACKAGE = OpenGL::Simple::GLUT		

INCLUDE: const-xs.inc

# ###### Initialization

void glutInit()
	PREINIT:
		int argc;
		int i;
		char **argv;
		AV *ARGV;
		SV *ARGV0;
	CODE:
		ARGV = perl_get_av("ARGV",FALSE);
		ARGV0= perl_get_sv("0",FALSE);

		argc = 2 + av_len(ARGV);

		if (NULL==(argv=malloc(sizeof(char *)*argc))) {
			perror("malloc()");
			croak("malloc() failed");
		}

		argv[0] = SvPV_nolen(ARGV0);
		for (i=0;i<(argc-1);i++) {
			argv[i+1] = SvPV_nolen(*av_fetch(ARGV,i,FALSE));
		}

		glutInit(&argc,argv);

		free(argv);


void glutInitWindowSize(int width, int height);

void glutInitWindowPosition(int x, int y);

void glutInitDisplayMode(unsigned int mode);

# ######## Beginning Event Processing

void glutMainLoop();

# ######## Window Management

int glutCreateWindow(char *name);

int glutCreateSubWindow(int win, int x, int y, int width, int height);

void glutSetWindow(int win);

int glutGetWindow();

void glutDestroyWindow(int win);

void glutPostRedisplay();

void glutSwapBuffers();

void glutPositionWindow(int x, int y);

void glutReshapeWindow(int width, int height);

void glutFullScreen();

void glutPopWindow();

void glutPushWindow();

void glutShowWindow();

void glutHideWindow();

void glutIconifyWindow();

void glutSetWindowTitle(char *name);

void glutSetIconTitle(char *name);

void glutSetCursor(int cursor);


# ######## Overlay Management

void glutEstablishOverlay();

void glutUseLayer(GLenum layer)

void glutRemoveOverlay();

void glutPostOverlayRedisplay();

void glutShowOverlay();

void glutHideOverlay();


# ######## Menu Management

int glutCreateMenu (SV *cb)
	PREINIT:
		int newid; /* ID of newly created menu */
	CODE:

		/* Make sure we've been passed a coderef */
		if (!SvROK(cb)) {
			croak("Callback must be code reference");
			return;
		}
		if (SVt_PVCV != SvTYPE(SvRV(cb))) {
			croak("Callback must be code reference");
			return;
		}

		if (NULL== MenuFuncs) { MenuFuncs = newAV(); }

		if (0==(newid = glutCreateMenu(MenuCallback))) {
			croak("glutCreateMenu() failed");
		}

		av_store( MenuFuncs,newid,newSVsv(cb));
		RETVAL = newid;
	OUTPUT:
		RETVAL


void glutSetMenu(int menu);

int glutGetMenu();

void glutDestroyMenu(int menu);

void glutAddMenuEntry(char *name, int value);

void glutAddSubMenu(char *name, int menu);

void glutChangeToMenuEntry(int entry, char *name, int value);

void glutChangeToSubMenu(int entry, char *name, int menu);

void glutRemoveMenuItem(int entry);

void glutAttachMenu(int button);

void glutDetachMenu(int button);



# ######## Callback Registration.

# Register a display callback.
# There can be at most one display callback for each GLUT window.
# We keep an array, DisplayFuncs, such that the Nth element of
# Displayfuncs, if defined, contains a coderef for the Nth window
# display callback.


void glutDisplayFunc(SV *cb)
	CODE:
		register_callback_xs(Display)

void glutOverlayDisplayFunc(SV *cb)
	CODE:
		register_callback_xs(OverlayDisplay)

void glutReshapeFunc(SV *cb)
	CODE:
		register_callback_xs(Reshape)

void glutKeyboardFunc(SV *cb)
	CODE:
		register_callback_xs(Keyboard)

void glutMouseFunc(SV *cb)
	CODE:
		register_callback_xs(Mouse)

void glutMotionFunc(SV *cb)
	CODE:
		register_callback_xs(Motion)

void glutPassiveMotionFunc(SV *cb)
	CODE:
		register_callback_xs(PassiveMotion)

void glutVisibilityFunc(SV *cb)
	CODE:
		register_callback_xs(Visibility)

void glutEntryFunc(SV *cb)
	CODE:
		register_callback_xs(Entry)

void glutSpecialFunc(SV *cb)
	CODE:
		register_callback_xs(Special)

void glutSpaceballMotionFunc(SV *cb)
	CODE:
		register_callback_xs(SpaceballMotion)

void glutSpaceballRotateFunc(SV *cb)
	CODE:
		register_callback_xs(SpaceballRotate)

void glutSpaceballButtonFunc(SV *cb)
	CODE:
		register_callback_xs(SpaceballButton)

void glutButtonBoxFunc(SV *cb)
	CODE:
		register_callback_xs(ButtonBox)

void glutDialsFunc(SV *cb)
	CODE:
		register_callback_xs(Dials)

void glutTabletMotionFunc(SV *cb)
	CODE:
		register_callback_xs(TabletMotion)

void glutTabletButtonFunc(SV *cb)
	CODE:
		register_callback_xs(TabletButton)

void glutMenuStatusFunc(SV *cb)
	CODE:
		register_callback_xs(MenuStatus)

void glutMenuStateFunc(SV *cb)
	CODE:
		register_callback_xs(MenuState)

	
void glutIdleFunc(SV *cb)
	CODE:
		register_callback_xs(Idle)




# glutTimerFunc doesn't care about window IDs, and the callback can be
# called at any time. However, the callback is passed an ID number ("value"),
# which can be used to tell which callback is being called.
# So, we actually create our own unique ID for each timer callback.
# We use that as an index into the TimerFuncs hash, which gives back
# an array containing: (1) the coderef for the callback, and (2) the value
# which the user passed in.

		
void glutTimerFunc(unsigned int msecs, SV *cb, int value)
	PREINIT:
		AV *myav;
		SV *myrv;
		int key;
		SV *keysv;
		int i;
	CODE:
		if (!SvROK(cb)) {
			croak("Callback must be code reference");
			return;
		}
		if (SVt_PVCV != SvTYPE(SvRV(cb))) {
			croak("Callback must be code reference");
			return;
		}

		/* Everything looks OK, so store it in the callback array */
		if (NULL==TimerFuncs) {
			TimerFuncs = newHV();
		}

		/* Create an anonymous array to hold the coderef and value */
		myav = newAV();
		av_store(myav,0,newSVsv(cb));
		av_store(myav,1,newSViv(value));
		myrv = newRV( (SV *)myav ); /* Reference to the array */

		/* Generate a new ID. This algorithm sucks. */

		key=0;
		keysv = newSViv(key);
		while (NULL != hv_fetch_ent(TimerFuncs,keysv,FALSE,0)) {
			key++;
			keysv = newSViv(key);
		}
		/* key is an unique integer ID, and keySV is an SV
		 * containing it.
		 * Store the array in the hash. Effectively, we've just done:
		 *
		 * sub timerfunc {
		 * 	my ($coderef,$val) = @_;
		 * 	my $i;
		 * 	while (exists($TimerFuncs{$i})) {
		 * 		$i++;
		 * 	}
		 * 	$TimerFuncs{$i} = [ $coderef, $val ];
		 * }
		 * 
		 */

		hv_store_ent(TimerFuncs,keysv,myrv,0);

		/* Now register our timer callback handler with glut. */

		glutTimerFunc(msecs,TimerCallback,key);



		 
# ######## Color Index Colormap Management

void glutSetColor(int cell, GLfloat red, GLfloat green, GLfloat blue);

GLfloat glutGetColor(int cell, int component);

void glutCopyColormap(int win);

# ########  State Retrieval

int glutGet(GLenum state);

int glutLayerGet(GLenum info);

int glutDeviceGet(GLenum info);

int glutGetModifiers();

int glutExtensionSupported(char *extension);


# ########   Geometric Object Rendering

void glutSolidSphere(GLdouble radius, GLint slices, GLint stacks);

void glutWireSphere(GLdouble radius, GLint slices, GLint stacks);

void glutSolidCube(GLdouble size);

void glutWireCube(GLdouble size);

void glutSolidCone(GLdouble base, GLdouble height, GLint slices, GLint stacks);

void glutWireCone(GLdouble base, GLdouble height, GLint slices, GLint stacks);

void glutSolidTorus(GLdouble innerRadius, GLdouble outerRadius, GLint nsides, GLint rings);

void glutWireTorus(GLdouble innerRadius, GLdouble outerRadius, GLint nsides, GLint rings);


void glutSolidDodecahedron();

void glutWireDodecahedron();

void glutSolidOctahedron();

void glutWireOctahedron();

void glutSolidTetrahedron();

void glutWireTetrahedron();

void glutSolidIcosahedron();

void glutWireIcosahedron();

void glutSolidTeapot(GLdouble size);

void glutWireTeapot(GLdouble size);


