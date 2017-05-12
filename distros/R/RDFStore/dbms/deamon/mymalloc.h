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
 *
 * $Id: mymalloc.h,v 1.6 2006/06/19 10:10:22 areggiori Exp $
 */ 
char * memdup( void * data, size_t size );

#ifdef RDFSTORE_DBMS_DEBUG_MALLOC
void * debug_malloc( size_t len, char * file, int line); 
void debug_free( void * addr, char * file, int line );
void debug_malloc_dump(FILE * file);

#define mymalloc(x) debug_malloc(x,__FILE__,__LINE__)
#define myfree(x) debug_free(x,__FILE__,__LINE__)
#else
#define mymalloc(x) malloc(x)
#define myfree(x) free(x)
#endif
