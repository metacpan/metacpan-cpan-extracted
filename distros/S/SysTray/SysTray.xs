#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if WIN32
  #include <win_wrap.h>
#elif linux
  #include <kde_wrap.h>
#elif __APPLE__
  #include <osx_wrap.h>
#endif

// callback for receiving icon events
SV * systray_callback = NULL;

// execute callback if events were received during do_events()
int process_events(int result)
{
  int retval = 1;
  
  if ((result != 0) && (systray_callback != NULL)) {
    if (get_cv(SvPV_nolen(systray_callback), FALSE) != NULL) {
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSViv(result)));
      PUTBACK;
      perl_call_pv(SvPV_nolen(systray_callback), G_DISCARD);
      SPAGAIN;
      PUTBACK;
      FREETMPS;
      LEAVE;
    } else {
      retval = 0;
    }
  }
  
  return retval;
}

MODULE = SysTray		PACKAGE = SysTray		

PROTOTYPES: ENABLED


int create(callback, ...)
    char *callback  = SvOK(ST(0)) ? SvPV_nolen(ST(0)) : NULL;
    char *icon_path = SvOK(ST(1)) ? SvPV_nolen(ST(1)) : NULL;
    char *tooltip   = SvOK(ST(2)) ? SvPV_nolen(ST(2)) : NULL;
  CODE:
    if (callback != NULL) systray_callback = newSVpv(callback, 0);
    RETVAL = create(icon_path, tooltip);
  OUTPUT:
    RETVAL


int destroy()


int do_events()
  INIT:
    int result = 0;
  CODE:
    result = do_events();
    RETVAL = process_events(result);
  OUTPUT:
    RETVAL


int change_icon(icon_path)
    char *icon_path  = SvOK(ST(0)) ? SvPV_nolen(ST(0)) : NULL;
  OUTPUT:
    RETVAL


int set_tooltip(tooltip)
    char *tooltip  = SvOK(ST(0)) ? SvPV_nolen(ST(0)) : NULL;
  OUTPUT:
    RETVAL


int clear_tooltip()


int release()
