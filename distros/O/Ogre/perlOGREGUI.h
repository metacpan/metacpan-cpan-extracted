#ifndef _PERLOGRE_GUI_H_
#define _PERLOGRE_GUI_H_


#ifdef PERLOGRE_HAS_GTK2

#include "perlOGRE.h"

#include <gtk/gtkwidget.h>

#if defined( __WIN32__ ) || defined( _WIN32 )
#  include <gdk/gdkwin32.h>
#else
#  include <gdk/gdkx.h>
#endif


// typemap for GtkWidget* (shortcut version of what Gtk2/Glib does)
#define TMOGRE_GTKWIDGET_IN(arg, var, package, func) \
MAGIC *mg; \
	if (!arg || !SvOK(arg) || !SvROK(arg) || !sv_derived_from(arg, "Gtk2::Widget")) \
		croak(#package "::" #func "():" #var " is not a Gtk2::Widget object\n"); \
	if (!(mg = mg_find(SvRV(arg), PERL_MAGIC_ext))) \
		croak(#package "::" #func "():" #var " has no magic!\n"); \
	var = (GtkWidget *) mg->mg_ptr;



// For Gtk2: pass an object that "isa" Gtk2::Widget.
// For Wx: pass the result of GetHandle() on an object
// that "isa" Wx::Window.  (note: wxPerl >= 0.12)
// Returns "parentWindowHandle" for &params arg to createRenderWindow
Ogre::String getWindowHandleString(GtkWidget *widget);


#endif  /* PERLOGRE_HAS_GTK2 */


#endif  /* _PERLOGRE_GUI_H_ */

