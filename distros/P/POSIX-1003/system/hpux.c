#define _INCLUDE_XOPEN_SOURCE_EXTENDED

#include <sys/unistd.h>
#include <sys/resource.h>

#ifdef _LARGEFILE64_SOURCE
#define HAS_RLIMIT_64
#endif

#undef HAS_STRSIGNAL
