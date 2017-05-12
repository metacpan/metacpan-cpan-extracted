%module "Solaris::DeviceTree::Libdevinfo::Impl"

%{
#include <sys/types.h>
#include <sys/mkdev.h>
#include <sys/ddi.h>
#include <libdevinfo.h>

#include <errno.h>
%}

%include Impl.h

%typemap(perl5,out) char *di_devfs_path {
  $result = sv_2mortal(newSVpv( $1, 0));
  di_devfs_path_free( $1 );
  argvi++;
}

/* We should have a char *-typemap here, which maps NULL to undef
   instead of empty string.
*/
/*
%typemap(perl5,out) char * {
*/

/*
%typemap(perl5,ignore) char **OUTPUT( char **temp ) {
  $target = &temp;
}
*/

char *di_devfs_path(di_node_t node);

%include typemaps.i
// extern void sdi_prop_devt( di_prop_t prop, int *OUTPUT, int *OUTPUT );
extern void devt_majorminor( dev_t devt, int *OUTPUT, int *OUTPUT );
extern int di_compatible_names(di_node_t node, char **OUTPUT );



%inline %{


/* 
char *getErrString() {
  return strerror( errno );
}

int getErrno() {
  return errno;
}
*/


int isDDI_DEV_T_NONE( dev_t devt ) {
  return ( devt == DDI_DEV_T_NONE ? 1 : 0 );
}

char **newStringHandle() {
  return (char **) malloc( sizeof( char * ) );
}

char *getIndexedString( char **stringArray, int index ) {
  char *start = *stringArray;
/*  printf( "Index: %d\n", index ); */

  while( index-- > 0 ) {
    /* start points to the start of the string */
    while( *start != 0 ) {
      start++;
    }
    /* start points to '\0' after the string */
    start++;
    /* start points to first character of new string */
  }

/*  printf( "String: %s\n", start ); */
  return start;
}

void freeStringHandle( char **handle ) {
  free( handle );
}

/* -- int -- */

int **newIntHandle() {
  return (int **) malloc( sizeof( int * ) );
}

int getIndexedInt( int **data, int index ) {
  return (*data)[ index ];
}

void freeIntHandle( int **handle ) {
  free( handle );
}

/* -- uchar_t -- */

uchar_t **newUCharTHandle() {
  return (uchar_t **) malloc( sizeof( uchar_t * ) );
}

int getIndexedByte( uchar_t **data, int index ) {
  int value = (*data)[ index ];
  return value;
}

void freeUCharTHandle( uchar_t **handle ) {
  free( handle );
}

char *UCharTString( uchar_t **data ) {
  return (char *) *data;
}

/* -- -- */

int isDI_NODE_NIL( di_node_t node ) {
  return ( node == DI_NODE_NIL ? 1 : 0 );
}

int isDI_PROP_NIL( di_prop_t prop ) {
  return ( prop == DI_PROP_NIL ? 1 : 0 );
}

/*
void *getProp( di_prop_t prop ) {
}
*/

di_prop_t makeDI_PROP_NIL() {
  return (di_prop_t) NULL;
}

/* -- Minor Node functions -- */

di_minor_t makeDI_MINOR_NIL() {
  return (di_minor_t) DI_MINOR_NIL;
}

int isDI_MINOR_NIL( di_minor_t minor ) {
  return ( minor == DI_MINOR_NIL ? 1 : 0 );
}

/* -- PROM Properties -- */

di_prom_prop_t makeDI_PROM_PROP_NIL() {
  return (di_prom_prop_t) DI_PROM_PROP_NIL;
}

int isDI_PROM_PROP_NIL( di_prom_prop_t minor ) {
  return ( minor == DI_PROM_PROP_NIL ? 1 : 0 );
}

int isDI_PROM_HANDLE_NIL( di_prom_handle_t prom_handle ) {
  return (prom_handle == DI_PROM_HANDLE_NIL ? 1 : 0);
}

int isDDI_DEVID_NIL( ddi_devid_t ddi_devid ) {
  return (ddi_devid == 0 ? 1 : 0);
}

%}


