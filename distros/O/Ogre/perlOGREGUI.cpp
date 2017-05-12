#include "perlOGREGUI.h"


#ifdef PERLOGRE_HAS_GTK2


// Don't assume I know what I'm doing; please send patches.

Ogre::String getWindowHandleString(GtkWidget *widget)
{
    Ogre::String handle;
    // GTK_WIDGET_SET_FLAGS(widget, GTK_REALIZED);
    gtk_widget_realize(widget);
    GdkWindow *parent = gtk_widget_get_parent_window(widget);

//    gdk_window_show(parent);

#if defined(__WIN32__) || defined(_WIN32)

    handle = Ogre::StringConverter::toString((unsigned long) GDK_WINDOW_HWND(parent));

#else
// #elif defined(__WXGTK__)

    GdkDisplay* display = gdk_drawable_get_display(GDK_DRAWABLE(parent));
    Display *xdisplay = GDK_DISPLAY_XDISPLAY(display);
    XSync(xdisplay, false);


    GdkScreen* screen = gdk_drawable_get_screen(GDK_DRAWABLE(parent));
    Screen *xscreen = GDK_SCREEN_XSCREEN(screen);
    int screen_number = XScreenNumberOfScreen(xscreen);
//    XID xid_parent = GDK_WINDOW_XWINDOW(parent);

    // "parentWindowHandle"
//    handle =
//        Ogre::StringConverter::toString(reinterpret_cast<unsigned long>(xdisplay)) + ":" +
//        Ogre::StringConverter::toString(static_cast<unsigned int>(screen_number)) + ":" +
//        Ogre::StringConverter::toString(static_cast<unsigned long>(xid_parent));

    handle = Ogre::StringConverter::toString(static_cast<unsigned long>(GDK_WINDOW_XID(parent)));


#endif

    // dunno what MacOS needs - you tell me

    return handle;
}


#endif  /* PERLOGRE_HAS_GTK2 */
