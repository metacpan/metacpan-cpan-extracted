/* Imager's memory allocation debugging code */
#ifndef XSQUEUE_ALLOC_H
#define XSQUEUE_ALLOC_H

#include <stddef.h>
#include <stdlib.h>

/*#define MEM_DEBUG*/

#ifdef MEM_DEBUG

extern void *mymalloc_file_line(size_t size, char const *file, int line);
extern void myfree_file_line(void *block, char const *file, int line);
extern void *myrealloc_file_line(void *block, size_t new_size, char const *file, int line);

#define mymalloc(size) (mymalloc_file_line((size), __FILE__, __LINE__))
#define myfree(block) (myfree_file_line((block), __FILE__, __LINE__))
#define myrealloc(block, size) (myrealloc_file_line((block), (size), __FILE__, __LINE__))

extern void bndcheck_all(void);

#else

extern void *mymalloc(size_t size);
extern void myfree(void *block);
extern void *myrealloc(void *block, size_t new_size);

#endif

#endif
