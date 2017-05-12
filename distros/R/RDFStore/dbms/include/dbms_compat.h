/*
 *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
 *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
 *
 * NOTICE
 *
 * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
 * file you should have received together with this source code. If you did not get a
 * a copy of such a license agreement you can pick up one at:
 *
 *     http://rdfstore.sourceforge.net/LICENSE
 *
 */ 

#ifndef _DBMS_COMPAT_H

#if !defined(WIN32)
#include <sys/param.h>
#endif

/* to make it compiling on Solaris basically */
#ifndef INADDR_NONE
#define INADDR_NONE     0xffffffff
#endif  /* INADDR_NONE */

#include <limits.h>
#include <sys/types.h>
#include <sys/uio.h>
#define _XPG4_2 
#include <sys/socket.h>
#undef  _XPG4_2

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#ifdef RDFSTORE_PLATFORM_DARWIN
#include <stdint.h>
#endif
#include <stdarg.h>
#include <errno.h>
#include <ctype.h>
#include <time.h>

#include <assert.h>
#include <signal.h>
#include <string.h>
/* SOLARIS */
#include <strings.h>

#include <pwd.h>

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <sys/resource.h>

#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>

#include <syslog.h>


#if 0
/* the following is needed to get rid of 'dereferencing pointer to incomplete type' error on line 144
 of this file on SuSe Linux - probably to be fixed in the dependences */
struct  hostent {
             char    *h_name;        /* official name of host */
             char    **h_aliases;    /* alias list */
             int     h_addrtype;     /* host address type */
             int     h_length;       /* length of address */
             char    **h_addr_list;  /* list of addresses from name server */
     };
#define h_addr  h_addr_list[0]  /* address, for backward compatibility */
struct hostent * gethostbyname(const char *name);
#endif

/* not using the following but euristics into main Makefile.PL to guess out paths for db.h */
#if 0
#ifdef DB1_INCLUDE
#	include <db1/db.h>
#else
#ifdef DB2_INCLUDE
#	include <db2/db.h>
#else
#ifdef DB3_INCLUDE
#       include <db3/db.h>
#else
#ifdef DB4_INCLUDE
#	include <db4/db.h>
#else
#ifdef COMPAT185
#	include <db_185.h>
#else
#	include "db.h"
#endif
#endif
#endif
#endif
#endif
#endif
/* end not used */

#ifdef COMPAT185
#	include "db_185.h"
#else
#	include "db.h"
#endif

#ifdef DB_VERSION_MAJOR
#	if DB_VERSION_MAJOR == 2
#    		define BERKELEY_DB_1_OR_2
#	endif
#	if DB_VERSION_MAJOR > 3 || (DB_VERSION_MAJOR == 3 && DB_VERSION_MINOR >= 2)
#    		define AT_LEAST_DB_3_2
#	endif
#	define R_FIRST         DB_FIRST
#	define R_NEXT          DB_NEXT
#	define R_CURSOR        DB_SET_RANGE
#else /* db version 1.x */
#	define BERKELEY_DB_1
#	define BERKELEY_DB_1_OR_2
#endif

#if defined(BSD)
#define _HAS_TIME_T
#define _HAS_SENSIBLE_SPRINTF
#endif

#if defined(_HAS_TIMESPEC)
#define TIMESPEC struct timespec
#endif

#if defined(_HAS_TIMESTRUC_T)
#define TIMESPEC timestruc_t
#endif

#if defined(_HAS_TIME_T)
#define TIMESPEC time_t
#endif

#if defined(_HAS_SENSIBLE_SPRINTF)
#define STRLEN(x) (x)
#endif

#if defined(_HAS_SILLY_SPRINTF)
#define STRLEN(x) strlen(x)
#endif


#define _DBMS_COMPAT_H 1
#endif
