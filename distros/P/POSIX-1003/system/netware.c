/*
 * NetWare OS
 */

#undef HAS_POLL
#undef HAS_ULIMIT
#undef HAS_STRSIGNAL
#undef HAS_FCNTL_OWN_EX

#ifndef NGROUPS_MAX
#define NGROUPS_MAX 1
#endif

/* defines makedev(),major(),minor() */
#include <sys/sysmacros.h>
