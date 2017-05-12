# Process this file with autoconf to produce a configure script.
AC_INIT()

# AX_CHECK_INCLUDE(include/file.name, INCLUDE_FILE_NAME)
# ---------------------------------------------------------
# checks if the include file is present 
# but does not  check if it is usable
AC_DEFUN([AX_CHECK_INCLUDE],[
  AH_TEMPLATE([HAVE_$2],[Define HAVE_$2 to 1 if '<$1>' is useable.])
  AC_CHECK_HEADER([$1],[
    AC_DEFINE([HAVE_$2],[1],[define available include file])
  ],[],[
#include "confdefs.h"
])])

AC_CONFIG_HEADER([config.h])

# Checks for programs.
AC_PROG_CC

# Checks for library functions.
AC_HEADER_STDC

AX_CHECK_INCLUDE([stdio.h],[STDIO_H])
AX_CHECK_INCLUDE([sys/socket.h],[SYS_SOCKET_H])
AX_CHECK_INCLUDE([netinet/ether.h],[NETINET_ETHER_H])
AX_CHECK_INCLUDE([netinet/ip.h],[NETINET_IP_H])

AC_CHECK_TYPES([struct iphdr, struct ether_header],[],[],[
#include "confdefs.h"
#ifdef HAVE_NETINET_IP_H
#include <netinet/ip.h>
#endif
#ifdef HAVE_NETINET_ETHER_H
#include <netinet/ether.h>
#endif
])

AH_TEMPLATE([LIBS],[Extra libraries needed for this build])

AH_TEMPLATE([HAVE_PCAP],[Define to 1 if pcap lib is present])
AC_SEARCH_LIBS([pcap_close],[pcap],[
        AC_DEFINE([HAVE_PCAP])],[],[$LDDLFLAGS])

AC_PROG_GCC_TRADITIONAL

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST

AC_TYPE_INT8_T 
AC_TYPE_INT16_T
AC_TYPE_INT32_T
AC_TYPE_UINT8_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T

AC_C_BIGENDIAN

AC_CHECK_SIZEOF([uint8_t])   
AC_CHECK_SIZEOF([uint16_t])
AC_CHECK_SIZEOF([uint32_t])
AC_CHECK_SIZEOF([u_int8_t])
AC_CHECK_SIZEOF([u_int16_t])
AC_CHECK_SIZEOF([u_int32_t])

AH_TEMPLATE([LIBS],[Extra libraries needed for this build])
AC_CONFIG_COMMANDS_PRE([
	if test "$LIBS" != ""; then
	AC_DEFINE_UNQUOTED([LIBS],[$LIBS],[Extra libraries])
	fi
])

AC_OUTPUT
