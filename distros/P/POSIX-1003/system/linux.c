/* __UL names are not defined to exist... and those names are
 * incompatible so we rename them. (kernel 2.6.37)
 */

#ifndef UL_GETMAXBRK
#define UL_GETMAXBRK  __UL_GETMAXBRK
#endif

#ifndef UL_GETOPENMAX
#define UL_GETOPENMAX __UL_GETOPENMAX
#endif

#ifdef __USE_FILE_OFFSET64
#define HAS_RLIMIT_64
#endif
