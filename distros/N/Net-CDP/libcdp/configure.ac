# Process this file with autoconf to produce a configure script.

AC_INIT([libcdp], [0.09], [libcdp@very.puzzling.org])
AC_CONFIG_SRCDIR([src/cdp.c])
AC_CONFIG_HEADER([config.h])
AM_INIT_AUTOMAKE([-Wall std-options])

AC_CONFIG_MACRO_DIR(m4)
AC_CONFIG_LIBOBJ_DIR(lib)

gl_MODULES([calloc free malloc memcpy memset stdint strdup strerror xalloc])
gl_SOURCE_BASE([lib])
gl_M4_BASE([m4])
gl_LIB([libmisc])

# Checks for programs.
AC_PROG_CC
AM_PROG_CC_C_O

# Yes, I'm building a static library, but the code will be used in a
# shared library...
AM_DISABLE_STATIC

AM_PROG_LIBTOOL
gl_EARLY

# Checks for libraries.
MAC_LIB_PCAP
case "$HAVE_LIB_PCAP" in
no)
	AC_MSG_FAILURE([[libpcap could not be found]])
	;;
"")
	AC_MSG_ERROR([[libpcap is required by this module]])
	;;
esac

MAC_LIB_NET
case "$HAVE_LIB_NET" in
no)
	AC_MSG_FAILURE([[libnet (version 1.1.0 or later) could not be found]])
	;;
"")
	AC_MSG_ERROR([[libnet (version 1.1.0 or later) is required by this module]])
	;;
esac

# Checks for header files.
AC_HEADER_STDC
MAC_HEADER_ETHTOOL
AC_CHECK_HEADERS_ONCE([
	fcntl.h
	linux/sockios.h
	sys/socket.h
	net/if.h
	netinet/if_ether.h
	netpacket/packet.h
	sys/ioctl.h
	sys/time.h
	sys/utsname.h
])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AM_C_PROTOTYPES
AC_TYPE_SIZE_T

# Checks for library functions.
gl_INIT
AC_PROG_GCC_TRADITIONAL
MAC_SYS_MULTICAST

AC_ARG_ENABLE(debug,
	AS_HELP_STRING(--enable-debug, [include debug code (e.g. assertions)]))
case "$enable_debug" in
no|"")
	AC_DEFINE(NDEBUG, 1, [Define to 1 to disable assertions])
	;;
*)
	;;
esac

AC_CONFIG_FILES([
	Makefile
	lib/Makefile
	src/Makefile
	config.pl
])
AC_OUTPUT
