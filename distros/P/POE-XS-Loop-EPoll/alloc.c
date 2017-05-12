#include "alloc.h"
#include <stdio.h>
#include <errno.h>
#include <stdarg.h>
#include <string.h>

/* cheap version of Imager's logging */
char const *last_file; int last_line;

static void do_log(int level, char const *fmt, ...);

#define mm_log(x) ((last_file = __FILE__), (last_line = __LINE__), do_log x )

#ifdef MEM_DEBUG

static
void
bndcheck(int idx);
void
bndcheck_all(void);

#define MAXMAL 102400
#define MAXDESC 65

#define UNDRRNVAL 10
#define OVERRNVAL 10

#define PADBYTE 0xaa

static int malloc_need_init = 1;

void
malloc_state(void);

typedef struct {
  void* ptr;
  size_t size;
  char comm[MAXDESC];
} malloc_entry;

malloc_entry malloc_pointers[MAXMAL];



/* Utility functions */


static
void
malloc_init(void) {
  int i;
  for(i=0; i<MAXMAL; i++) malloc_pointers[i].ptr = NULL;
  malloc_need_init = 0;
  atexit(malloc_state);
}


static
int 
find_ptr(void *p) {
  int i;
  for(i=0;i<MAXMAL;i++)
    if (malloc_pointers[i].ptr == p)
      return i;
  return -1;
}


/* Takes a pointer to real start of array,
 * sets the entries in the table, returns
 * the offset corrected pointer */

static
void *
set_entry(int i, char *buf, size_t size, char const *file, int line) {
  memset( buf, PADBYTE, UNDRRNVAL );
  memset( &buf[UNDRRNVAL+size], PADBYTE, OVERRNVAL );
  buf += UNDRRNVAL;
  malloc_pointers[i].ptr  = buf;
  malloc_pointers[i].size = size;
  sprintf(malloc_pointers[i].comm,"%s (%d)", file, line);
  return buf;
}

void
malloc_state(void) {
  int i, total = 0;

  mm_log((0,"malloc_state()\n"));
  bndcheck_all();
  for(i=0; i<MAXMAL; i++) if (malloc_pointers[i].ptr != NULL) {
    mm_log((0,"%d: %d (0x%x) : %s\n", i, malloc_pointers[i].size, malloc_pointers[i].ptr, malloc_pointers[i].comm));
    total += malloc_pointers[i].size;
  }
  if (total == 0) mm_log((0,"No memory currently used!\n"));
		    else mm_log((0,"total: %d\n",total));
}



void*
mymalloc_file_line(size_t size, char const* file, int line) {
  char *buf;
  int i;
  if (malloc_need_init) malloc_init();
  
  /* bndcheck_all(); Uncomment for LOTS OF THRASHING */
  
  if ( (i = find_ptr(NULL)) < 0 ) {
    mm_log((0,"more than %d segments allocated at %s (%d)\n", MAXMAL, file, line));
    exit(3);
  }

  if ( (buf = malloc(size+UNDRRNVAL+OVERRNVAL)) == NULL ) {
    mm_log((1,"Unable to allocate %i for %s (%i)\n", size, file, line));
    exit(3);
  }
  
  buf = set_entry(i, buf, size, file, line);
  mm_log((1,"mymalloc_file_line: slot <%d> %d bytes allocated at %p for %s (%d)\n", i, size, buf, file, line));
  return buf;
}

void *
(mymalloc)(int size) {
  return mymalloc_file_line(size, "unknown", 0);
}

void*
myrealloc_file_line(void *ptr, size_t newsize, char const * file, int line) {
  char *buf;
  int i;

  if (malloc_need_init) malloc_init();
  /* bndcheck_all(); ACTIVATE FOR LOTS OF THRASHING */
  
  if (!ptr) {
    mm_log((1, "realloc called with ptr = NULL, sending request to malloc\n"));
    return mymalloc_file_line(newsize, file, line);
  }
  
  if (!newsize) {
    mm_log((1, "newsize = 0, sending request to free\n"));
    myfree_file_line(ptr, file, line);
    return NULL;
  }

  if ( (i = find_ptr(ptr)) == -1) {
    mm_log((0, "Unable to find %p in realloc for %s (%i)\n", ptr, file, line));
    exit(3);
  }
  
  if ( (buf = realloc(((char *)ptr)-UNDRRNVAL, UNDRRNVAL+OVERRNVAL+newsize)) == NULL ) {
    mm_log((1,"Unable to reallocate %i bytes at %p for %s (%i)\n", newsize, ptr, file, line));
    exit(3); 
  }
  
  buf = set_entry(i, buf, newsize, file, line);
  mm_log((1,"realloc_file_line: slot <%d> %d bytes allocated at %p for %s (%d)\n", i, newsize, buf, file, line));
  return buf;
}

void *
(myrealloc)(void *ptr, size_t newsize) {
  return myrealloc_file_line(ptr, newsize, "unknown", 0);
}

static
void
bndcheck(int idx) {
  int i;
  size_t s = malloc_pointers[idx].size;
  unsigned char *pp = malloc_pointers[idx].ptr;
  if (!pp) {
    mm_log((1, "bndcheck: No pointer in slot %d\n", idx));
    return;
  }
  
  for(i=0;i<UNDRRNVAL;i++)
     if (pp[-(1+i)] != PADBYTE)
     mm_log((1,"bndcheck: UNDERRUN OF %d bytes detected: slot = %d, point = %p, size = %d\n", i+1, idx, pp, s ));
  
     for(i=0;i<OVERRNVAL;i++)
    if (pp[s+i] != PADBYTE)
      mm_log((1,"bndcheck: OVERRUN OF %d bytes detected: slot = %d, point = %p, size = %d\n", i+1, idx, pp, s ));
}

void
bndcheck_all(void) {
  int idx;
  mm_log((1, "bndcheck_all()\n"));
  for(idx=0; idx<MAXMAL; idx++)
    if (malloc_pointers[idx].ptr)
      bndcheck(idx);
}

void
myfree_file_line(void *p, char const *file, int line) {
  char  *pp = p;
  int match = 0;
  int i;
  
  for(i=0; i<MAXMAL; i++) if (malloc_pointers[i].ptr == p) {
    mm_log((1,"myfree_file_line: pointer %i (%s) freed at %s (%i)\n", i, malloc_pointers[i].comm, file, line));
    bndcheck(i);
    malloc_pointers[i].ptr = NULL;
    match++;
  }

  mm_log((1, "myfree_file_line: freeing address %p (real %p) (%s:%d)\n", pp, pp-UNDRRNVAL, file, line));
  
  if (match != 1) {
    mm_log((1, "myfree_file_line: INCONSISTENT REFCOUNT %d at %s (%i)\n", match, file, line));
    fprintf(stderr, "myfree_file_line: INCONSISTENT REFCOUNT %d at %s (%i)\n", match, file, line);
		exit(255);
  }
  
  
  free(pp-UNDRRNVAL);
}

void
(myfree)(void *block) {
  myfree_file_line(block, "unknown", 0);
}

#else 

#define malloc_comm(a,b) (mymalloc(a))

void
malloc_state() {
}

void*
mymalloc(size_t size) {
  void *buf;

  if (size < 0) {
    fprintf(stderr, "Attempt to allocate size %d\n", (int)size);
    exit(3);
  }

  if ( (buf = malloc(size)) == NULL ) {
    mm_log((1, "mymalloc: unable to malloc %d\n", (int)size));
    fprintf(stderr,"Unable to malloc %d.\n", (int)size); exit(3);
  }
  mm_log((1, "mymalloc(size %d) -> %p\n", (int)size, buf));
  return buf;
}

void *
mymalloc_file_line(size_t size, char *file, int line) {
  return mymalloc(size);
}

void
myfree(void *p) {
  mm_log((1, "myfree(p %p)\n", p));
  free(p);
}

void
myfree_file_line(void *p, char *file, int line) {
  myfree(p);
}

void *
myrealloc(void *block, size_t size) {
  void *result;

  mm_log((1, "myrealloc(block %p, size %u)\n", block, size));
  if ((result = realloc(block, size)) == NULL) {
    mm_log((1, "myrealloc: out of memory\n"));
    fprintf(stderr, "Out of memory.\n");
    exit(3);
  }
  return result;
}

void *
myrealloc_file_line(void *block, size_t newsize, char *file, int size) {
  return myrealloc(block, newsize);
}

#endif /* IMAGER_MALLOC_DEBUG */

FILE *log_file;

void
setup_log(void) {
  char *log_env = getenv("MEM_DEBUG");
  if (!log_env)
    return;

  if (strcmp(log_env, "STDERR") == 0) {
    log_file = stderr;
    return;
  }
  log_file = fopen(log_env, "w+");
  if (!log_file) {
    fprintf(stderr, "Could not open log %s: %s\n", log_env, strerror(errno));
    exit(3);
  }
}

static void
do_log(int level, char const *fmt, ...) {
  if (!log_file) setup_log();
  
  if (log_file) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(log_file, "[%s:%d] %d:", last_file, last_line, level);
    
    vfprintf(stderr, fmt, ap);
    va_end(ap);
  }
}
