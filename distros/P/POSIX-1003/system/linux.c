/* __UL names are not defined to exist... and those names are
 * incompatible so we rename them. (kernel 2.6.37)
 */

#ifndef UL_GETMAXBRK
#define UL_GETMAXBRK  __UL_GETMAXBRK
#endif

#ifndef UL_GETOPENMAX
#define UL_GETOPENMAX __UL_GETOPENMAX
#endif

#if defined __GNUC__ && defined __USE_LARGEFILE64
#define HAS_RLIMIT_64
#endif
