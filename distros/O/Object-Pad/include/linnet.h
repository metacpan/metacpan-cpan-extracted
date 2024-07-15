#ifndef __LINNET_H__
#define __LINNET_H__

/* A linnet is a bird in the finch family, similar to a canary. */

/* Here, a linnet a debugging feature. We put a field at the start of every
 * kind of struct, which is always initialised to a unique static value per
 * type. Whenever we cast a pointer to this type, we also assert that the
 * linnet field has the right value. In this way we hope to detect invalid 
 * pointer accesses.
 */

#ifdef DEBUGGING
#  define DEBUG_LINNETS
#endif

#ifdef DEBUG_LINNETS
#  define LINNET_FIELD          U32 debug_linnet;
#  define LINNET_INIT(val)      .debug_linnet = (val),
#  define LINNET_CHECK_CAST(ptr, type, val) \
                                ({ type castptr = (type)ptr; assert(castptr->debug_linnet == val), castptr;})
#else
#  define LINNET_FIELD
#  define LINNET_INIT(val)
#  define LINNET_CHECK_CAST(ptr, type, val) \
                                ((type)ptr)
#endif

#endif
