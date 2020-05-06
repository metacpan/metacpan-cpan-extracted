#ifndef EADDRINUSE
#define EADDRINUSE	WSAEADDRINUSE
#endif
#ifndef EADDRNOTAVAIL
#define EADDRNOTAVAIL	WSAEADDRNOTAVAIL
#endif
#ifndef EALREADY
#define EALREADY	WSAEALREADY
#endif
#ifndef EBADF
#define EBADF		WSAEBADF
#endif
#ifndef ECONNABORTED
#define ECONNABORTED	WSAECONNABORTED
#endif
#ifndef ECONNREFUSED
#define ECONNREFUSED	WSAECONNREFUSED
#endif
#ifndef ECONNRESET
#define ECONNRESET	WSAECONNRESET
#endif
#ifndef EDISCON
#define EDISCON		WSAEDISCON
#endif
#ifndef EINPROGRESS
#define EINPROGRESS	WSAEINPROGRESS
#endif
#ifndef EINTR
#define EINTR		WSAEINTR
#endif
#ifndef EINVAL
#define EINVAL		WSAEINVAL
#endif
#ifndef EISCONN
#define EISCONN		WSAEISCONN
#endif
#ifndef EMFILE
#define EMFILE		WSAEMFILE
#endif
#ifndef EMSGSIZE
#define EMSGSIZE	WSAEMSGSIZE
#endif
#ifndef ENETRESET
#define ENETRESET	WSAENETRESET
#endif
#ifndef ENETUNREACH
#define ENETUNREACH	WSAENETUNREACH
#endif
#ifndef ENOBUFS
#define ENOBUFS		WSAENOBUFS
#endif
#ifndef ENOTCONN
#define ENOTCONN	WSAENOTCONN
#endif
#ifndef ENOTSOCK
#define ENOTSOCK	WSAENOTSOCK
#endif
#ifndef ETIMEDOUT
#define ETIMEDOUT	WSAETIMEDOUT
#endif
#ifndef EWOULDBLOCK
#define EWOULDBLOCK	WSAEWOULDBLOCK
#endif

#undef CACHE_UID
#undef HAS_CONFSTR
#undef HAS_FCNTL
#undef HAS_FNMATCH
#undef HAS_GETGROUPS
#undef HAS_GLOB
#undef HAS_LOCKF
#undef HAS_MKNOD
#undef HAS_SETGROUPS
#undef HAS_STRSIGNAL
#undef HAS_ULIMIT
#undef HAS_WORDEXP

/* mingw has empty stub 
 * Interesting: https://nanohub.org/infrastructure/rappture/svn/tags/1.0/gui/src/RpWinResource.c
 */
#undef HAS_RLIMIT

#undef I_SYS_WAIT
