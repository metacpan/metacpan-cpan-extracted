#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <GLFW/glfw3.h>

#include <stdio.h>

// AV index values for callbacks which are stored as an *AV
// in the GLFW user pointer.  The first element of the array
// is used to hold the user pointer (a.k.a. perl user ref).
//
enum AVindex {
    userpointer = 0,
    charfun,
    charmodsfun,
    cursorenterfun,
    cursorposfun,
    dropfun,
    framebuffersizefun,
    keyfun,
    mousebuttonfun,
    scrollfun,
    windowclosefun,
    windowfocusfun,
    windowiconifyfun,
    windowposfun,
    windowrefreshfun,
    windowsizefun,
    AVlen
};

static int done_non_void_callback_warn = 0;

void callback_warn(void) {
   if (! done_non_void_callback_warn ) {
      warn("Callback set in non-void context!  Return values not implemented");
      done_non_void_callback_warn++;
   }
}

//----------------------------------------------------------------
// Global callbacks
//----------------------------------------------------------------
static SV * errorfunsv    = (SV*) NULL;
void errorfun_callback(int error, const char* description)
{
    dTHX;

    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newSViv(error)));
    XPUSHs(sv_2mortal(newSVpv(description, 0)));

    PUTBACK;

    if ( SvOK(errorfunsv) ) {
       call_sv(errorfunsv, G_VOID);
    }

    SPAGAIN;

    FREETMPS;
    LEAVE;

}

static SV * monitorfunsv  = (SV*) NULL;
void monitorfun_callback(GLFWmonitor* monitor, int event)
{
    dTHX;

    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(monitor)))));
    XPUSHs(sv_2mortal(newSViv(event)));

    PUTBACK;

    if ( SvOK(monitorfunsv) ) {
       call_sv(monitorfunsv, G_VOID);
    }

    SPAGAIN;

    FREETMPS;
    LEAVE;

}

static SV * joystickfunsv = (SV*) NULL;
void joystickfun_callback(int joy_id, int event)
{
    dTHX;

    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newSViv(joy_id)));
    XPUSHs(sv_2mortal(newSViv(event)));

    PUTBACK;

    if ( SvOK(joystickfunsv) ) {
       call_sv(joystickfunsv, G_VOID);
    }

    SPAGAIN;

    FREETMPS;
    LEAVE;

}

//----------------------------------------------------------------
// Per-window callbacks
//
// The per-window callbacks are stored in a perl array
// whose reference is kept in the User Pointer.
//----------------------------------------------------------------

// (* GLFWcharfun)(GLFWwindow*,unsigned int);
void charfun_callback (GLFWwindow* window, unsigned int codepoint)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = charfun;
    SV** fetchval;
    SV* charfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("charfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("charfun_callback: winav[charfun] is NULL");

    charfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSVuv(codepoint)));

    PUTBACK;

    call_sv(charfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWcharmodsfun)(GLFWwindow*,unsigned int,int);
void charmodsfun_callback (GLFWwindow* window, unsigned int codepoint, int mods)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = charmodsfun;
    SV** fetchval;
    SV* charmodsfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("charmodsfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("charmodsfun_callback: winav[charmodsfun] is NULL");

    charmodsfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSVuv(codepoint)));
    XPUSHs(sv_2mortal(newSViv(mods)));

    PUTBACK;

    call_sv(charmodsfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWcursorenterfun)(GLFWwindow*,int);
void cursorenterfun_callback (GLFWwindow* window, int entered)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = cursorenterfun;
    SV** fetchval;
    SV* cursorenterfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("cursorenterfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("cursorenterfun_callback: winav[cursorenterfun] is NULL");

    cursorenterfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSViv(entered)));

    PUTBACK;

    call_sv(cursorenterfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWcursorposfun)(GLFWwindow*,double,double);
void cursorposfun_callback (GLFWwindow* window, double xpos, double ypos)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = cursorposfun;
    SV** fetchval;
    SV* cursorposfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("cursorposfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("cursorposfun_callback: winav[cursorposfun] is NULL");

    cursorposfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSVnv(xpos)));
    XPUSHs(sv_2mortal(newSVnv(ypos)));

    PUTBACK;

    call_sv(cursorposfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWdropfun)(GLFWwindow*,int,const char**);
void dropfun_callback (GLFWwindow* window, int count, const char** paths)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = dropfun;
    SV** fetchval;
    SV* dropfunsv;
    int npath;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("dropfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("dropfun_callback: winav[dropfun] is NULL");

    dropfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    // XPUSHs(sv_2mortal(newSViv(count)));
    for (npath=0; npath<count; npath++)
       XPUSHs(sv_2mortal(newSVpv(paths[npath],0)));

    PUTBACK;

    call_sv(dropfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWframebuffersizefun)(GLFWwindow*,int,int);
void framebuffersizefun_callback (GLFWwindow* window, int width, int height)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = framebuffersizefun;
    SV** fetchval;
    SV* framebuffersizefunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("framebuffersizefun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("framebuffersizefun_callback: winav[framebuffersizefun] is NULL");

    framebuffersizefunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSViv(width)));
    XPUSHs(sv_2mortal(newSViv(height)));

    PUTBACK;

    call_sv(framebuffersizefunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
void keyfun_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = keyfun;
    SV** fetchval;
    SV* keyfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("keyfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("keyfun_callback: winav[keyfun] is NULL");

    keyfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSViv(key)));
    XPUSHs(sv_2mortal(newSViv(scancode)));
    XPUSHs(sv_2mortal(newSViv(action)));
    XPUSHs(sv_2mortal(newSViv(mods)));

    PUTBACK;

    call_sv(keyfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWmousebuttonfun)(GLFWwindow*,int,int,int);
void mousebuttonfun_callback (GLFWwindow* window, int button, int action, int mods)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = mousebuttonfun;
    SV** fetchval;
    SV* mousebuttonfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("mousebuttonfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("mousebuttonfun_callback: winav[mousebuttonfun] is NULL");

    mousebuttonfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSViv(button)));
    XPUSHs(sv_2mortal(newSViv(action)));
    XPUSHs(sv_2mortal(newSViv(mods)));

    PUTBACK;

    call_sv(mousebuttonfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWscrollfun)(GLFWwindow*,double,double);
void scrollfun_callback (GLFWwindow* window, double xoffset, double yoffset)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = scrollfun;
    SV** fetchval;
    SV* scrollfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("scrollfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("scrollfun_callback: winav[scrollfun] is NULL");

    scrollfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSVnv(xoffset)));
    XPUSHs(sv_2mortal(newSVnv(yoffset)));

    PUTBACK;

    call_sv(scrollfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWwindowclosefun)(GLFWwindow*);
void windowclosefun_callback (GLFWwindow* window)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = windowclosefun;
    SV** fetchval;
    SV* windowclosefunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("windowclosefun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("windowclosefun_callback: winav[windowclosefun] is NULL");

    windowclosefunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));

    PUTBACK;

    call_sv(windowclosefunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWwindowfocusfun)(GLFWwindow*,int);
void windowfocusfun_callback (GLFWwindow* window, int focused)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = windowfocusfun;
    SV** fetchval;
    SV* windowfocusfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("windowfocusfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("windowfocusfun_callback: winav[windowfocusfun] is NULL");

    windowfocusfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSViv(focused)));

    PUTBACK;

    call_sv(windowfocusfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWwindowiconifyfun)(GLFWwindow*,int);
void windowiconifyfun_callback (GLFWwindow* window, int iconified)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = windowiconifyfun;
    SV** fetchval;
    SV* windowiconifyfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("windowiconifyfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("windowiconifyfun_callback: winav[windowiconifyfun] is NULL");

    windowiconifyfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSViv(iconified)));

    PUTBACK;

    call_sv(windowiconifyfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWwindowposfun)(GLFWwindow*,int,int);
void windowposfun_callback (GLFWwindow* window, int xpos, int ypos)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = windowposfun;
    SV** fetchval;
    SV* windowposfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("windowposfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("windowposfun_callback: winav[windowposfun] is NULL");

    windowposfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSViv(xpos)));
    XPUSHs(sv_2mortal(newSViv(ypos)));

    PUTBACK;

    call_sv(windowposfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWwindowrefreshfun)(GLFWwindow*);
void windowrefreshfun_callback (GLFWwindow* window)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = windowrefreshfun;
    SV** fetchval;
    SV* windowrefreshfunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("windowrefreshfun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("windowrefreshfun_callback: winav[windowrefreshfun] is NULL");

    windowrefreshfunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));

    PUTBACK;

    call_sv(windowrefreshfunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}

// (* GLFWwindowsizefun)(GLFWwindow*,int,int);
void windowsizefun_callback (GLFWwindow* window, int width, int height)
{ 
    dTHX;

    dSP;

    AV* winav;
    int cvind = windowsizefun;
    SV** fetchval;
    SV* windowsizefunsv;

    winav = glfwGetWindowUserPointer(window);
    if (winav == (AV*) NULL)
       croak("windowsizefun_callback: winav is NULL");

    fetchval = av_fetch(winav, cvind, 0);

    if (! fetchval)
       croak("windowsizefun_callback: winav[windowsizefun] is NULL");

    windowsizefunsv = *fetchval;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(window)))));
    XPUSHs(sv_2mortal(newSViv(width)));
    XPUSHs(sv_2mortal(newSViv(height)));

    PUTBACK;

    call_sv(windowsizefunsv, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
}


MODULE = OpenGL::GLFW           PACKAGE = OpenGL::GLFW


#//----------------------------------------------------
#// Set Per-window callbacks
#//----------------------------------------------------

#// want SV*
void
glfwSetWindowPosCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = windowposfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,windowposfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper windowposfun callback
     fpstatus = glfwSetWindowPosCallback(window, windowposfun_callback);


#// want SV*
void
glfwSetWindowSizeCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = windowsizefun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,windowsizefun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper windowsizefun callback
     fpstatus = glfwSetWindowSizeCallback(window, windowsizefun_callback);

#// want SV*
void
glfwSetWindowCloseCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = windowclosefun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,windowclosefun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper windowclosefun callback
     fpstatus = glfwSetWindowCloseCallback(window, windowclosefun_callback);

#// want SV*
void
glfwSetWindowRefreshCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = windowrefreshfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,windowrefreshfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper windowrefreshfun callback
     fpstatus = glfwSetWindowRefreshCallback(window, windowrefreshfun_callback);

#// want SV*
void
glfwSetWindowFocusCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = windowfocusfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,windowfocusfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper windowfocusfun callback
     fpstatus = glfwSetWindowFocusCallback(window, windowfocusfun_callback);

#// want SV*
void
glfwSetWindowIconifyCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = windowiconifyfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,windowiconifyfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper windowiconifyfun callback
     fpstatus = glfwSetWindowIconifyCallback(window, windowiconifyfun_callback);

#// want SV*
void
glfwSetFramebufferSizeCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = framebuffersizefun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,framebuffersizefun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper framebuffersizefun callback
     fpstatus = glfwSetFramebufferSizeCallback(window, framebuffersizefun_callback);

#// want SV*
void
glfwSetKeyCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = keyfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,keyfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper keyfun callback
     fpstatus = glfwSetKeyCallback(window, keyfun_callback);


#// want SV*
void
glfwSetCharCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = charfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,charfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper charfun callback
     fpstatus = glfwSetCharCallback(window, charfun_callback);

#// want SV*
void
glfwSetCharModsCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = charmodsfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,charmodsfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper charmodsfun callback
     fpstatus = glfwSetCharModsCallback(window, charmodsfun_callback);

#// want SV*
void
glfwSetMouseButtonCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = mousebuttonfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,mousebuttonfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper mousebuttonfun callback
     fpstatus = glfwSetMouseButtonCallback(window, mousebuttonfun_callback);

#// want SV*
void
glfwSetCursorPosCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = cursorposfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,cursorposfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper cursorposfun callback
     fpstatus = glfwSetCursorPosCallback(window, cursorposfun_callback);

#// want SV*
void
glfwSetCursorEnterCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = cursorenterfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,cursorenterfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper cursorenterfun callback
     fpstatus = glfwSetCursorEnterCallback(window, cursorenterfun_callback);

#// want SV*
void
glfwSetScrollCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = scrollfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,scrollfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper scrollfun callback
     fpstatus = glfwSetScrollCallback(window, scrollfun_callback);

#// want SV*
void
glfwSetDropCallback(window, cbfun);
      GLFWwindow* window
      SV * cbfun
   CODE:
     void (*fpstatus)();
     void * upoint;
     int cvind = dropfun;
     int i;
     SV** fetchval;
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (NULL == av_store((AV*)upoint,dropfun,SvREFCNT_inc(cbfun)))
	SvREFCNT_dec(cbfun);
     // Enable the C wrapper dropfun callback
     fpstatus = glfwSetDropCallback(window, dropfun_callback);


#//----------------------------------------------------
#// Set Global callbacks
#//----------------------------------------------------

#// want to return SV*
void
glfwSetErrorCallback(cbfun)
     SV * cbfun
   CODE:
     void (*fpstatus)();
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     //
     // Need to fix return of previous CV
     // which was causing a segfault in re.pl
     //
     if (errorfunsv == (SV*) NULL) {
        errorfunsv = newSVsv(cbfun);
     } else {
        SvSetSV(errorfunsv, cbfun);
     }
     // Enable the C wrapper errorfun callback
     fpstatus = glfwSetErrorCallback(errorfun_callback);

#// want to return SV*
void
glfwSetMonitorCallback(cbfun)
     SV * cbfun
   CODE:
     void (*fpstatus)();
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Need to fix return of previous CV
     // which was causing a segfault in re.pl
     //
     if (monitorfunsv == (SV*) NULL) {
        monitorfunsv = newSVsv(cbfun);
     } else {
        SvSetSV(monitorfunsv, cbfun);
     }
     // Enable the C wrapper errorfun callback
     fpstatus = glfwSetMonitorCallback(monitorfun_callback);

#// want to return SV*
void
glfwSetJoystickCallback(cbfun)
     SV * cbfun
   CODE:
     void (*fpstatus)();
     // Warn if used in non-void context
     if (GIMME_V != G_VOID) callback_warn();
     // Need to fix return of previous CV
     // which was causing a segfault in re.pl
     //
     if (joystickfunsv == (SV*) NULL) {
        joystickfunsv = newSVsv(cbfun);
     } else {
        SvSetSV(joystickfunsv, cbfun);
     }
     // Enable the C wrapper errorfun callback
     fpstatus = glfwSetJoystickCallback(joystickfun_callback);


#//-------------------------------------------------------------------
#// Uses GLFWimage
#//-------------------------------------------------------------------

#// void
#// glfwSetWindowIcon(GLFWwindow* window, int count, const GLFWimage* images);
void
glfwSetWindowIcon(GLFWwindow* window, ...);
   PREINIT:
     GLFWimage* imgstruct;
     GLFWimage* images[10];
     SV * image;
     HV * imghv;
     SV** svp;
     int width, height, n, numimages;
     unsigned char* pixels;
   CODE:
     // printf("glfwSetWindowIcon got %d items\n", items);
     if (items == 1) {
        glfwSetWindowIcon(window, 0, NULL);
     } else if (1 < items && items < 10) {
        // loop over input image structure hashes
        // to generate in input images array for
        // the call to glfwSetWindowIcon().
        //
        numimages = items - 1;
        New(0, imgstruct, numimages*sizeof(GLFWimage), GLFWimage);
        SAVEFREEPV(imgstruct);
        for (n=0; n<numimages; n++) {
           image = ST(n+1);
           if ( SvROK(image) && SvTYPE(SvRV(image))==SVt_PVHV) {
              imghv = (HV *)SvRV(image);
              if (svp = hv_fetch(imghv, "width", 5, 0))
                 (imgstruct+n)->width = width = SvIV(*svp);
              if (svp = hv_fetch(imghv, "height", 6, 0))
                 (imgstruct+n)->height = height = SvIV(*svp);
              if (svp = hv_fetch(imghv, "pixels", 6, 0))
                 (imgstruct+n)->pixels = pixels = (unsigned char *)SvPV_nolen(*svp);
              images[n] = imgstruct+n;
           } else {
              croak("Invalid image argument type\n");
           }
        }
        // for (n=0; n<numimages; n++) {
        //    printf("images[%d].width = %d\n", n, images[n]->width);
        //    printf("images[%d].height = %d\n", n, images[n]->height);
        //    printf("images[%d].pixels = %p\n", n, images[n]->pixels);
        // }
        glfwSetWindowIcon(window, numimages, *images);
     } else if (items > 10) {
        croak("glfwSetWindowIcon got too many images (max is 10)\n");
     }


#//-------------------------------------------------------------------
#// GLFWcursor routines
#//-------------------------------------------------------------------
#// GLFWcursor*
#// glfwCreateCursor(const GLFWimage* image, int xhot, int yhot);
GLFWcursor*
glfwCreateCursor(SV* image, int xhot, int yhot);
   PREINIT:
     GLFWimage imgstruct;
     HV * imghv;
     SV** svp;
     int width, height;
     unsigned char* pixels;
   CODE:
     if ( SvROK(image) && SvTYPE(SvRV(image))==SVt_PVHV) {
        imghv = (HV *)SvRV(image);
     }
     if (svp = hv_fetch(imghv, "width", 5, 0))
        imgstruct.width = width = SvIV(*svp);
     if (svp = hv_fetch(imghv, "height", 6, 0))
        imgstruct.height = height = SvIV(*svp);
     if (svp = hv_fetch(imghv, "pixels", 6, 0))
        imgstruct.pixels = pixels = (unsigned char *)SvPV_nolen(*svp);
     RETVAL = glfwCreateCursor(&imgstruct, xhot, yhot);
   OUTPUT:
     RETVAL

GLFWcursor*
glfwCreateStandardCursor(int shape);

void
glfwDestroyCursor(GLFWcursor* cursor);

void
glfwSetCursor(GLFWwindow* window, GLFWcursor* cursor);

#//-------------------------------------------------------------------
#// GLFWmonitor routines
#//-------------------------------------------------------------------
GLFWmonitor*
glfwGetPrimaryMonitor();

#// GLFWmonitor**
#// glfwGetMonitors(OUTLIST int count);
void
glfwGetMonitors();
   PREINIT:
     GLFWmonitor** monitors = NULL;
     int n, count;
   PPCODE:
     monitors = glfwGetMonitors(&count);
     printf("glfwGetMonitors() returns %d values\n",count);
     for (n=0; n<count; n++)
        XPUSHs(sv_2mortal(newRV_noinc(newSViv(PTR2IV(monitors+n)))));


const char*
glfwGetMonitorName(GLFWmonitor* monitor);

void
glfwGetMonitorPhysicalSize(GLFWmonitor* monitor, OUTLIST int widthMM, OUTLIST int heightMM);

void
glfwGetMonitorPos(GLFWmonitor* monitor, OUTLIST int xpos, OUTLIST int ypos);

void
glfwGetMonitorWorkarea(GLFWmonitor* monitor, OUTLIST int xpos, OUTLIST int ypos, OUTLIST int width, OUTLIST int height);

void
glfwSetGamma(GLFWmonitor* monitor, float gamma);

#// const GLFWgammaramp*
HV*
glfwGetGammaRamp(GLFWmonitor* monitor);
   PREINIT:
     HV * hash;
     const GLFWgammaramp * gramp = NULL;
   CODE:
     // get video mode
     gramp = glfwGetGammaRamp(monitor);
     if (!gramp) croak("null pointer as GLFWgammaramp");

     // pack gammaramp into hash
     hash = (HV*)sv_2mortal((SV*)newHV());
     hv_store(hash, "size",  4, newSViv(gramp->size),  0);   // implict
     hv_store(hash, "red",   3, newSVpvn((char*)gramp->red,  2*gramp->size), 0);
     hv_store(hash, "green", 5, newSVpvn((char*)gramp->green,2*gramp->size), 0);
     hv_store(hash, "blue",  4, newSVpvn((char*)gramp->blue, 2*gramp->size), 0);

     // return hash reference
     RETVAL = hash;
   OUTPUT:
     RETVAL

#// void
#// glfwSetGammaRamp(GLFWmonitor* monitor, const GLFWgammaramp* ramp);
void
glfwSetGammaRamp(GLFWmonitor* monitor, SV* ramp);
   PREINIT:
     GLFWgammaramp rampstruct;
     HV * ramphv;
     SV** svp;
     int size;
   CODE:
   if ( SvROK(ramp) && SvTYPE(SvRV(ramp))==SVt_PVHV) {
      ramphv = (HV *)SvRV(ramp);
   }
   if (svp = hv_fetch(ramphv, "size",  4, 0))
      rampstruct.size = size = SvIV(*svp);
   if (svp = hv_fetch(ramphv, "red",   3, 0))
      rampstruct.red = (unsigned short *)SvPV_nolen(*svp);
   if (svp = hv_fetch(ramphv, "green", 5, 0))
      rampstruct.green = (unsigned short *)SvPV_nolen(*svp);
   if (svp = hv_fetch(ramphv, "blue",  4, 0))
      rampstruct.blue = (unsigned short *)SvPV_nolen(*svp);
   glfwSetGammaRamp(monitor,&rampstruct);
     


#// const GLFWvidmode*
HV*
glfwGetVideoMode(GLFWmonitor* monitor);
   PREINIT:
     HV * hash;
     const GLFWvidmode* vidm = NULL;
   CODE:
     // get video mode
     vidm = glfwGetVideoMode(monitor);
     if (!vidm) croak("null pointer as GLFWvidmode");

     // pack vidmode into hash
     hash = (HV*)sv_2mortal((SV*)newHV());
     hv_store(hash, "width",        5, newSViv(vidm->width),       0);
     hv_store(hash, "height",       6, newSViv(vidm->height),      0);
     hv_store(hash, "redBits",      7, newSViv(vidm->redBits),     0);
     hv_store(hash, "greenBits",    9, newSViv(vidm->greenBits),   0);
     hv_store(hash, "blueBits",     8, newSViv(vidm->blueBits),    0);
     hv_store(hash, "refreshRate", 11, newSViv(vidm->refreshRate), 0);

     // return hash reference
     RETVAL = hash;
   OUTPUT:
     RETVAL


#// const GLFWvidmode*
void
glfwGetVideoModes(GLFWmonitor* monitor);
   PREINIT:
     HV * hash;
     const GLFWvidmode* vidms = NULL;
     int nmodes = -1;
     int n;
   PPCODE:
     // get video modes
     vidms = glfwGetVideoModes(monitor,&nmodes);
     if (!vidms) croak("null pointer as GLFWvidmode-s");
     if (nmodes <= 0) croak("no GLFWvidmode-s returned");

     for (n=0; n<nmodes; n++) {
        // pack vidmode into hash
        hash = (HV*)sv_2mortal((SV*)newHV());
        hv_store(hash, "width",        5, newSViv((vidms+n)->width),       0);
        hv_store(hash, "height",       6, newSViv((vidms+n)->height),      0);
        hv_store(hash, "redBits",      7, newSViv((vidms+n)->redBits),     0);
        hv_store(hash, "greenBits",    9, newSViv((vidms+n)->greenBits),   0);
        hv_store(hash, "blueBits",     8, newSViv((vidms+n)->blueBits),    0);
        hv_store(hash, "refreshRate", 11, newSViv((vidms+n)->refreshRate), 0);

        // push onto output stack
        XPUSHs( newRV_noinc((SV*)hash) );
     }


#//-------------------------------------------------------------------
#// GLFWmonitor with GLFWwindow routines
#//-------------------------------------------------------------------
GLFWmonitor*
glfwGetWindowMonitor(GLFWwindow* window);

GLFWwindow*
glfwCreateWindow(int width, int height, const char* title, GLFWmonitor* monitor, GLFWwindow* share);

void
glfwSetWindowMonitor(GLFWwindow* window, GLFWmonitor* monitor, int xpos, int ypos, int width, int height, int refreshRate);

#//-------------------------------------------------------------------
#// GLFWwindow routines
#//-------------------------------------------------------------------
GLFWwindow*
glfwGetCurrentContext();

int
glfwGetInputMode(GLFWwindow* window, int mode);

int
glfwGetKey(GLFWwindow* window, int key);

int
glfwGetMouseButton(GLFWwindow* window, int button);

int
glfwGetWindowAttrib(GLFWwindow* window, int attrib);

int
glfwWindowShouldClose(GLFWwindow* window);

void
glfwDestroyWindow(GLFWwindow* window);

void
glfwFocusWindow(GLFWwindow* window);

const char*
glfwGetClipboardString(GLFWwindow* window);

void
glfwGetCursorPos(GLFWwindow* window, OUTLIST double xpos, OUTLIST double ypos);

void
glfwGetFramebufferSize(GLFWwindow* window, OUTLIST int width, OUTLIST int height);

void
glfwGetWindowFrameSize(GLFWwindow* window, OUTLIST int left, OUTLIST int top, OUTLIST int right, OUTLIST int bottom);

void
glfwGetWindowPos(GLFWwindow* window, OUTLIST int xpos, OUTLIST int ypos);

void
glfwGetWindowSize(GLFWwindow* window, OUTLIST int width, OUTLIST int height);

void
glfwHideWindow(GLFWwindow* window);

void
glfwIconifyWindow(GLFWwindow* window);

void
glfwMakeContextCurrent(GLFWwindow* window);

void
glfwMaximizeWindow(GLFWwindow* window);

void
glfwRestoreWindow(GLFWwindow* window);

void
glfwSetClipboardString(GLFWwindow* window, const char* string);

void
glfwSetCursorPos(GLFWwindow* window, double xpos, double ypos);

void
glfwSetInputMode(GLFWwindow* window, int mode, int value);

void
glfwSetWindowAspectRatio(GLFWwindow* window, int numer, int denom);

void
glfwSetWindowPos(GLFWwindow* window, int xpos, int ypos);

void
glfwSetWindowShouldClose(GLFWwindow* window, int value);

void
glfwSetWindowSize(GLFWwindow* window, int width, int height);

void
glfwSetWindowSizeLimits(GLFWwindow* window, int minwidth, int minheight, int maxwidth, int maxheight);

void
glfwSetWindowTitle(GLFWwindow* window, const char* title);

void
glfwSetWindowUserPointer(GLFWwindow* window, SV* reference);
   PREINIT:
     void* upoint;
     int i;
   CODE:
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
     }
     if (!SvROK(reference))
        croak("glfwSetWindowUserPointer: pointer must be a perl reference\n");
     av_store((AV*)upoint,userpointer,newSVsv(reference));

void
glfwShowWindow(GLFWwindow* window);

void
glfwSwapBuffers(GLFWwindow* window);

SV*
glfwGetWindowUserPointer(GLFWwindow* window);
   PREINIT:
     SV* upoint;
     SV** sav;
     int i;
   CODE:
     // Get user pointer
     upoint = glfwGetWindowUserPointer(window);
     if (NULL == upoint) {
        upoint = (SV *)newAV();
        av_fill((AV*)upoint,AVlen);
        for (i=0; i<AVlen; i++)
           av_store((AV*)upoint,i,&PL_sv_undef);
        glfwSetWindowUserPointer(window,upoint);
	RETVAL = &PL_sv_undef;
     } else {
        sav = av_fetch((AV*)upoint,userpointer,0);
	RETVAL = newSVsv(*sav);
     }
   OUTPUT:
     RETVAL

#//-------------------------------------------------------------------
#// Standard types routines
#//-------------------------------------------------------------------
void
glfwDefaultWindowHints();

void
glfwGetVersion(OUTLIST int major, OUTLIST int minor, OUTLIST int rev);

void
glfwPollEvents();

void
glfwPostEmptyEvent();

void
glfwSetTime(double time);

void
glfwSwapInterval(int interval);

void
glfwTerminate();

void
glfwWaitEvents();

void
glfwWaitEventsTimeout(double timeout);

void
glfwWindowHint(int hint, int value);

const char*
glfwGetJoystickName(int joy);

const char*
glfwGetKeyName(int key, int scancode);

const char*
glfwGetVersionString();

#// const float*
#// glfwGetJoystickAxes(int joy, OUTLIST int count);
void
glfwGetJoystickAxes(int joy);
   PREINIT:
     const float* axes = NULL;
     int n, count;
   PPCODE:
     axes = glfwGetJoystickAxes(joy,&count);
     printf("glfwGetJoystickAxes() returns %d values\n",count);
     for (n=0; n<count; n++)
        XPUSHs(sv_2mortal(newSVnv(*(axes+n))));

#// const unsigned char*
#// glfwGetJoystickButtons(int joy, OUTLIST int count);
void
glfwGetJoystickButtons(int joy);
   PREINIT:
     const unsigned char* buttons = NULL;
     int n, count;
   PPCODE:
     buttons = glfwGetJoystickButtons(joy,&count);
     printf("glfwGetJoystickButtons() returns %d values\n",count);
     for (n=0; n<count; n++)
        XPUSHs(sv_2mortal(newSViv(*(buttons+n))));

int
glfwInit();

int
glfwJoystickPresent(int joy);

double
glfwGetTime();

uint64_t
glfwGetTimerFrequency();

uint64_t
glfwGetTimerValue();

#if (GLFW_VERSION_MAJOR*10000 + GLFW_VERSION_MINOR*100) >= 30300

void
glfwRequestWindowAttention(GLFWwindow* window);

#endif

#if (GLFW_VERSION_MAJOR*10000 + GLFW_VERSION_MINOR*100) >= 30400

int
glfwPlatformSupported(int platform);

int
glfwGetPlatform();

#endif

void
glfwGetError();
PREINIT:
  int errcode;
  char* description;
PPCODE:
  errcode = glfwGetError((const char**)&description);
  EXTEND(SP, 2);
  PUSHs(sv_2mortal(newSViv(errcode)));
  PUSHs(!description ? &PL_sv_undef : sv_2mortal(newSVpv(description, 0)));

void
glfwInitHint(int hint, int value);

#//-------------------------------------------------------------------
#// OpenGL not supported (use GLEW)
#//-------------------------------------------------------------------
int
glfwExtensionSupported(const char* extension);
   CODE:
     croak("glfwExtensionSupported not implemented (use glewIsSupported)");

void
glfwGetProcAddress(const char* procname);
   CODE:
     croak("glfwGetProcAddress not implemented (use GLEW)");

#//-------------------------------------------------------------------
#// Vulkan not supported
#//-------------------------------------------------------------------
int
glfwVulkanSupported();
   CODE:
     RETVAL = 0;
   OUTPUT:
     RETVAL

void
glfwGetRequiredInstanceExtensions(...)
   CODE:
     croak("No Vulkan Support: glfwGetRequiredInstanceExtensions not implemented!");

void
glfwGetInstanceProcAddress(...)
   CODE:
     croak("No Vulkan Support: glfwGetInstanceProcAddress not implemented!");

void
glfwGetPhysicalDevicePresentationSupport(...)
   CODE:
     croak("No Vulkan Support: glfwGetPhysicalDevicePresentationSupport not implemented!");

void
glfwCreateWindowSurface(...)
   CODE:
     croak("No Vulkan Support: glfwCreateWindowSurface not implemented!");
