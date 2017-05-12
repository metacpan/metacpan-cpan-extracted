#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "dlfcn.h"

static int (*setproctitle)(const char *buf, int len);
static int (*getproctitle)(char *buf, int len);
static int (*setproctitle_max)(void);
static int (*proctitle_kernel_support)(void);

MODULE = Sys::Proctitle		PACKAGE = Sys::Proctitle		

SV *
getproctitle()
  PROTOTYPE:
  CODE:
    {
      int len=setproctitle_max();
      char *buf=malloc( len );
      if( getproctitle( buf, len ) ) {
	XSRETURN_EMPTY;
      } else {
	RETVAL=newSVpv( buf, len );
      }
      free( buf );
    }
  OUTPUT:
    RETVAL

void
setproctitle(...)
  PROTOTYPE: @
  PPCODE:
    if( items > 0 ) {
      char *title, *buf, *cur;
      STRLEN len;
      int i, max;

      if( items==1 ) {
	title=(char *)SvPV(ST(0), len);
	setproctitle(title, len);
      } else {
	buf=malloc( max=setproctitle_max() );
	if( !buf ) XSRETURN_NO;

	for( i=0, cur=buf; i<items; i++ ) {
	  title=(char *)SvPV(ST(i), len);
	  if( cur+len+1<=buf+max ) {
	    memcpy( cur, title, len+1 );
	    cur+=len+1;
	  } else {
	    free( buf );
	    XSRETURN_NO;
	  }
	}
      
	setproctitle(buf, cur-buf);
	free(buf);
      }
    } else {
      setproctitle(NULL, 0);
    }
    XSRETURN_YES;

SV *
kernel_support()
  PROTOTYPE:
  CODE:
    {
      proctitle_kernel_support() ? XSRETURN_YES : XSRETURN_EMPTY;
    }
  OUTPUT:
    RETVAL

BOOT:
  {
    STRLEN len;
    char *lib=SvPV(get_sv("Sys::Proctitle::setproctitle_so", TRUE), len);
    void *h=dlopen( lib, RTLD_NOW );
    char *error;

    if( !h ) {
      croak( "Cannot load %s", lib );
    }
    dlerror();			/* clear existing error */
    setproctitle=dlsym( h, "setproctitle" );
    if( (error=dlerror())!=NULL ) {
      dlclose( h );
      croak( "%s was not found in %s", "setproctitle", lib );
    }
    getproctitle=dlsym( h, "getproctitle" );
    if( (error=dlerror())!=NULL ) {
      dlclose( h );
      croak( "%s was not found in %s", "getproctitle", lib );
    }
    setproctitle_max=dlsym( h, "setproctitle_max" );
    if( (error=dlerror())!=NULL ) {
      dlclose( h );
      croak( "%s was not found in %s", "setproctitle_max", lib );
    }
    proctitle_kernel_support=dlsym( h, "proctitle_kernel_support" );
    if( (error=dlerror())!=NULL ) {
      dlclose( h );
      croak( "%s was not found in %s", "proctitle_kernel_support", lib );
    }
  }

## Local Variables: ##
## mode: c ##
## End: ##
