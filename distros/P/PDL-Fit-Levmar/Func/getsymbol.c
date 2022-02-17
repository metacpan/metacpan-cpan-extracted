/*  Routines to open and close shared library containing fit functions,
 *  and get pointers to fit functions.
 *  Each library typically contains just two routines.
 * 
 *  John Lapeyre
 */

#include <stdio.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#include <string.h>

/* Open shared library and get one symbol pointer from it.
 * lib_name : file name of shared library (prefer fqpn)
 * func_name : name of symbol to find
 * The following 3 pointers must have storage allocated before calling this routine
 * (ie, allocation handled in perl code.)
 * lib_handle : pointer to pointer to library, but cast as pointer to int
 * func_pointer: pointer to pointer to function
 * error_message: empty string or error_message
 * nchar  : must <=  number of bytes allocated for error_message,
 *  to avoid buffer overrun. This is only here to prevent overrun.
 */
void _open_and_find (  char * lib_name, char * func_name, void ** lib_handle ,
		       void ** func_pointer, char * error_message, int nchar ) {

#ifdef _WIN32
   HINSTANCE dllHandle = NULL;              
   void *fp = NULL;
   dllHandle = LoadLibrary(lib_name);
   if (NULL != dllHandle) 
   { 
     fp  = (void *)GetProcAddress(dllHandle, func_name);
     if ( NULL == fp ) {
       int err = GetLastError();
       fprintf(stderr, "*** GetProcAddress error %d\n", err);
       memccpy(error_message, "*** GetProcAddress error\n" , 0, nchar);
     }
     else {
       strcpy( error_message, "" );
     }
     *func_pointer =  fp;
     *lib_handle = dllHandle;
   }
   else {
     fprintf(stderr, "*** LoadLibrary failed to get handle\n");
     memccpy(error_message, "*** LoadLibrary failed to get handle\n", 0, nchar);
   }
#else
  void * ret_lib;
  void * fp;
  const char *errmsg = NULL;
  ret_lib = dlopen( lib_name, RTLD_NOW);
  * lib_handle =  ret_lib;
  if ( ret_lib != NULL ) {
    fp =  dlsym( ret_lib, func_name);
    errmsg = dlerror();
    *func_pointer =  fp;
  }
  else {
    errmsg = dlerror();
  }
  if ( errmsg == NULL ) {
    strcpy( error_message, "" );
  }
  else {
    fprintf(stderr,"*** dlopen '%s'\n", errmsg);
    memccpy( error_message, errmsg , 0, nchar);
  }
#endif 
}

void   _close_shared_object_file( void ** lib_handle, int * rval, char * error_message, int nchar ) {
#ifdef _WIN32
  if ( *lib_handle != NULL ) *rval = FreeLibrary( (HINSTANCE)  *lib_handle );
  if ( NULL == *rval ) {
       int err = GetLastError();
       fprintf(stderr, "*** FreeLibrary error %d\n", err);
       memccpy( error_message, "*** FreeLibrary error\n" , 0, nchar);
  }
  else {
    strcpy( error_message, "" );
    *rval = 0;
  }  
#else
  const char *errmsg = NULL;
  if ( *lib_handle != NULL ) *rval = dlclose( (void *) *lib_handle );
  errmsg = dlerror();
  if ( errmsg == NULL ) {
    strcpy( error_message, "" );
  }
  else {
    memccpy( error_message, errmsg , 0, nchar);
  }
#endif
}
