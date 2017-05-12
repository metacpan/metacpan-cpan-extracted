
#include <sys/types.h>
#include <sys/mkdev.h>
#include <libdevinfo.h>

/*
int
devinfo_test( char *in ) {
  return in[ 0 ];
}

void    sdi_prop_devt( di_prop_t prop, unsigned int *major, unsigned int *minor ) {
  dev_t devt = di_prop_devt( prop );
  *major = major( devt );
  *minor = minor( devt );
}
*/

void devt_majorminor( dev_t devt, unsigned int *major, unsigned int *minor ) {
  *major = major( devt );
  *minor = minor( devt );
}

/*
int isDevidNull( ddi_devid_t devid ) {
  return ( devid == 0 ? 1 : 0 );
}
*/
