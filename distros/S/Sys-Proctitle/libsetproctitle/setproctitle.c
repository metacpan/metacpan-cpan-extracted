#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdarg.h>
#include <sys/prctl.h>

#include "setproctitle.h"

# ifndef DEBUG
# define DEBUG 0
# endif

extern char *__progname, *__progname_full;
extern char **environ;

static char *title_buffer=0;
static size_t title_buffer_size=0;
static char *saved_argv=0;
# if defined(PR_SET_NAME) && defined(PR_GET_NAME)
static char saved_kernel_name[16];
# endif

int
proctitle_kernel_support( void )
{
# if defined(PR_SET_NAME) && defined(PR_GET_NAME)
  return 1;
# else
  return 0;
# endif
}

int
setproctitle_max( void )
{
  return title_buffer_size;
}

int
setproctitle( const char *buf, int len )
{
  if( !title_buffer || !title_buffer_size ) {
    errno = ENOMEM;
    return -1;
  }

  if( buf ) {
    len=len<title_buffer_size?len:title_buffer_size-1;
    memcpy( title_buffer, buf, len );
    memset( title_buffer+len, 0, title_buffer_size-len );
#   if defined(PR_SET_NAME) && defined(PR_GET_NAME)
      prctl(PR_SET_NAME, (unsigned long)title_buffer, 0, 0, 0);
#   endif
  } else {
    memcpy( title_buffer, saved_argv, title_buffer_size );
#   if defined(PR_SET_NAME) && defined(PR_GET_NAME)
      prctl(PR_SET_NAME, (unsigned long)saved_kernel_name, 0, 0, 0);
#   endif
  }

  return 0;
}

int
getproctitle( char *buf, int len )
{
  if( !title_buffer || !title_buffer_size ) {
    errno = ENOMEM;
    return -1;
  }

  memcpy( buf, title_buffer, len<title_buffer_size?len:title_buffer_size );

  return 0;
}

/* on Linux main()'s parameter argv and envp are arranged on the stack */
/* this way: */
/*                  +-----------------------+ |    */
/*     argv[0]      | 1lahblah\0            | | h  */
/*                  +-----------------------+ | i  */
/*     argv[1]      | 2lahblah\0            | | g  */
/*                  +-----------------------+ | h  */
/*     argv[2]      | 3lahblah\0            | | e  */
/*                  +-----------------------+ | r  */
/*     argv[...]    | 4lahblah\0            | |    */
/*                  +-----------------------+ | a  */
/*     argv[argc-1] | 5lahblah\0            | | d  */
/*                  +-----------------------+ | d  */
/*     envp[0]      | 6lahblah\0            | | r  */
/*                  +-----------------------+ | e  */
/*     envp[1]      | 7lahblah\0            | | s  */
/*                  +-----------------------+ | s  */
/*     envp[2]      | 8lahblah\0            | | e  */
/*                  +-----------------------+ | s  */
/*     envp[...]    | 9lahblah\0            | |    */
/*                  +-----------------------+ |    */
/*     envp[X]      | 0lahblah\0            | |    */
/*                  +-----------------------+ v    */
/* all that space can be used to set the proctitle. Overwriting it */
/* changes a process' /proc/self/cmdline and /proc/self/environ. */

/* the argv and envp pointer arrays are also laid out consecutively: */
/*                  +-----------------------+ |    */
/*     argv[0]      | pointer to 1lahblah\0 | | h  */
/*                  +-----------------------+ | i  */
/*     argv[1]      | pointer to 2lahblah\0 | | g  */
/*                  +-----------------------+ | h  */
/*     argv[...]    | pointer to ...        | | e  */
/*                  +-----------------------+ | r  */
/*     argv[argc]   | NULL                  | |    */
/*                  +-----------------------+ | a  */
/*     envp[0]      | pointer to 6lahblah\0 | | d  */
/*                  +-----------------------+ | d  */
/*     envp[1]      | pointer to 7lahblah\0 | | r  */
/*                  +-----------------------+ | e  */
/*     envp[...]    | pointer to ...        | | s  */
/*                  +-----------------------+ | s  */
/*     envp[X]      | pointer to 0lahblah\0 | | e  */
/*                  +-----------------------+ | s  */
/*     envp[X+1     | NULL                  | |    */
/*                  +-----------------------+ v    */
/* libc initializes "environ" to point to "envp" to be used by getenv(), */
/* exec(), etc. functions. */

/* Thus, first we find the space that can be used. Then we check whether */
/* a copy of the environment should be made (it is not necessary if the */
/* has already set one up by itself). Third we make a copy of the whole */
/* title buffer in case setproctitle is called to reset the original title. */

int
_init( int argc, char *argv[], char *envp[] )
{
  char *bob=0, *eob=0;
  int i;
  int build_new_env=0;
  char **new_environ;

# if DEBUG==1
  fprintf( stderr, "_init: start\n" );
# endif
  if( argc ) {
    bob=argv[0];
    eob=bob+strlen(argv[0])+1;
    for( i=1; i<argc && eob==argv[i]; i++ ) {
      eob=argv[i]+strlen(argv[i])+1;
    }

    for( i++; argv[i] && eob==argv[i]; i++ ) {
      eob=argv[i]+strlen(argv[i])+1;
    }
  } else return 0;

  if( !eob ) return 0;

  if( environ==envp ) {
# if DEBUG==1
    fprintf( stderr, "environ=%p\n", environ );
# endif

    /* this is the hard way of copying the environment but it */
    /* makes glibc's getenv/putenv/setenv/... happy */

    clearenv();
    for( i=0; envp[i]; i++ ) {
      char *cp=strchr( envp[i], '=' );
      if( cp ) {
	*cp++='\0';
	setenv( envp[i], cp, 1 );
      }
    }
# if DEBUG==1
    fprintf( stderr, "new environ=%p\n", environ );
# endif
  }

  if( __progname_full ) {
    char *title_progname_full=strdup( __progname_full );
# if DEBUG==1
    fprintf( stderr, "title_progname_full=%p\n", title_progname_full );
# endif

    if( !title_progname_full ) goto err;

    char *p=strrchr( title_progname_full, '/' );

    __progname=p ? p+1 : title_progname_full;
    __progname_full=title_progname_full;
  }

  if( build_new_env ) environ = new_environ;

  char *newargv=malloc( eob-bob );
# if DEBUG==1
  fprintf( stderr, "newargv=%p\n", newargv );
# endif
  if( !newargv ) goto err;

  memcpy( newargv, argv[0], eob-bob );

  saved_argv=newargv;

  title_buffer=bob;
  title_buffer_size=eob-bob;

# if defined(PR_SET_NAME) && defined(PR_GET_NAME)
  prctl(PR_GET_NAME, (unsigned long)saved_kernel_name, 0, 0, 0);
# endif

# if DEBUG==1
  fprintf( stderr, "_init: finished\n" );
# endif

  return 0;

 err:
  for( i--; i>=0; i--) free( new_environ[i] );
  free (new_environ);
  return 0;
}
