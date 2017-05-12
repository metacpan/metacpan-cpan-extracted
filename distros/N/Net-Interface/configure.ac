# Process this file with autoconf to produce a configure script.
AC_INIT()

# AX_SIZEOF_SOCKFUNC(lowercase_funcname, UPPERCASE_FUNCNAME)
# ---------------------------------------------------------
# checks if the function is present in the netinet/in.h file
# and sets SIZEOF_SOCKFUNC if found
AC_DEFUN([AX_SIZEOF_SOCKFUNC],[
AH_TEMPLATE([LOCAL_SIZEOF_$2],[Define size of $1])
AC_MSG_CHECKING([for LOCAL_SIZEOF_$2])
AC_RUN_IFELSE([
#include "confdefs.h"  
#include "defaults.h"
int   
main()
{
  FILE *FP;
  struct $1 sa;
  long my_family_size = sizeof(sa);
  if (FP = fopen("conftest.data", "w")) {
    (void) fprintf(FP,"%ld\n",my_family_size);
    fclose(FP);
    return 0;
  } else
    return 1;
}],
ac_familysize=`cat conftest.data`
AC_MSG_RESULT([is $ac_familysize])
AC_DEFINE_UNQUOTED([LOCAL_SIZEOF_$2],[$ac_familysize],[define family size]),
AC_MSG_RESULT([not defined])
)])

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
#include "defaults.h"
])])

# AX_IN_STDLIB(lowercase_funcname, UPPERCASE_FUNCNAME)
# ---------------------------------------------------------
# checks if the function is present in the stdlib.h file
# and sets SIZEOF_SOCKFUNC if found
AC_DEFUN([AX_IN_STDLIB],[
AH_TEMPLATE([HAVE_$2_IN_STDLIB],[Define size of $1])
AC_MSG_CHECKING([for $2 in stdlib.h])
AC_COMPILE_IFELSE([
#include <stdlib.h>
int   
main()
{
    void * mem = malloc(8192);
    return 1;
}],
AC_MSG_RESULT([yes])
AC_DEFINE_UNQUOTED([HAVE_$2_IN_STDLIB],[1],[$2 in <stdlib.h>]),
AC_MSG_RESULT([not defined])
)])

AC_CONFIG_HEADER([config.h])

AC_CANONICAL_HOST
AC_MSG_NOTICE([Checking OS type and VERSION])
my_host_version=`uname -r`

case $host_os in
    alpha*)
	AH_TEMPLATE([__ni_ALPHA],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_ALPHA],[$my_host_version],[OS name defined to version])
	;;
    aix*)
	AH_TEMPLATE([__ni_AIX],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_AIX],[$my_host_version],[OS name defined to version])
	;;
    beos*)
	AH_TEMPLATE([__ni_BEOS],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_BEOS],[$my_host_version],[OS name defined to version])
	;;
    *bsd*)
	AH_TEMPLATE([__ni_BSD],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_BSD],[$my_host_version],[OS name defined to version])
	;;
    cygwin*)
	AH_TEMPLATE([__ni_Cygwin],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_Cygwin],[$my_host_version],[OS name defined to version])
	;;
    darwin*)
	AH_TEMPLATE([__ni_Darwin],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_Darwin],[$my_host_version],[OS name defined to version])
	;;
    dgux*)
	AH_TEMPLATE([__ni_DGUX],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_DGUX],[$my_host_version],[OS name defined to version])
	;;
    dragonfly*)
	AH_TEMPLATE([__ni_DragonFly],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_DragonFly],[$my_host_version],[OS name defined to version])
	;;
    hpux*)
	AH_TEMPLATE([__ni_HPUX],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_HPUX],[$my_host_version],[OS name defined to version])
	;;
    freebsd*)
	AH_TEMPLATE([__ni_FreeBSD],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_FreeBSD],[$my_host_version],[OS name defined to version])
	;;
    interix*)
	AH_TEMPLATE([__ni_Interix],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_Interix],[$my_host_version],[OS name defined to version])
	;;
    irix*)
	AH_TEMPLATE([__ni_IRIX],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_IRIX],[$my_host_version],[OS name defined to version])
	;;
    linux*)
	AH_TEMPLATE([__ni_Linux],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_Linux],[$my_host_version],[OS name defined to version])
	;;
    machten*)
	AH_TEMPLATE([__ni_MachTen],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_MachTen],[$my_host_version],[OS name defined to version])
	;;
    mingw*)
	AH_TEMPLATE([__ni_MingW],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_MingW],[$my_host_version],[OS name defined to version])
	;;
    msdos* | go32* | windows*)
	AH_TEMPLATE([__ni_Windows],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_Windows],[$my_host_version],[OS name defined to version])
	;;
    netbsd*)
	AH_TEMPLATE([__ni_NetBSD],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_NetBSD],[$my_host_version],[OS name defined to version])
	;;
    next2*)
	AH_TEMPLATE([__ni_Next2],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_Next2],[$my_host_version],[OS name defined to version])
	;;
    nextstep*)
	AH_TEMPLATE([__ni_NextStep],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_NextStep],[$my_host_version],[OS name defined to version])
	;;
    openbsd*)
	AH_TEMPLATE([__ni_OpenBSD],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_OpenBSD],[$my_host_version],[OS name defined to version])
	;;
    osf*)
	AH_TEMPLATE([__ni_OSF],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_OSF],[$my_host_version],[OS name defined to version])
	;;
    qnx*)
	AH_TEMPLATE([__ni_QNX4],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_QNX4],[$my_host_version],[OS name defined to version])
	;;
    sco*)
	AH_TEMPLATE([__ni_SCO],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_SCO],[$my_host_version],[OS name defined to version])
	;;
    solaris*)
	AH_TEMPLATE([__ni_SunOS],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_SunOS],[$my_host_version],[OS name defined to version])
	;;
    sunos*)
	AH_TEMPLATE([__ni_SUNOS],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_SUNOS],[$my_host_version],[OS name defined to version])
	;;
    sysv4*)
	AH_TEMPLATE([__ni_SRV4],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_SRV4],[$my_host_version],[OS name defined to version])
	;;
    sysv5uw*)
	AH_TEMPLATE([__ni_Unixware],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_Unixware],[$my_host_version],[OS name defined to version])
	;;
    unixware*)
	AC_DEFINE_UNQUOTED([__ni_Unixware],[$my_host_version],[OS name defined to version])
	;;
    ultrix*)
	AH_TEMPLATE([__ni_Ultrix],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_Ultrix],[$my_host_version],[OS name defined to version])
	;;
    win32*)
	AH_TEMPLATE([__ni_Win32],[OS name defined to version])
	AC_DEFINE_UNQUOTED([__ni_Win32],[$my_host_version],[OS name defined to version])
	;;
    *)
     echo ""
     echo "*************************************************************"
     echo "configure does not currently recognize your operating system,"
     echo "therefore you must do a manual configuration of:"
     echo "Checking host system type... $host_os"
     echo "Please contact miker@cpan.org"
     echo "including the above 'checking host system type...' line "
     echo "*************************************************************"
     echo ""
     exit;;
esac

AC_MSG_CHECKING([Operating system of this host is])

# Checks for programs.
AC_PROG_CC

# Checks for library functions.
AC_HEADER_STDC

AX_CHECK_INCLUDE([stdio.h],[STDIO_H])
AX_CHECK_INCLUDE([sys/socket.h],[SYS_SOCKET_H])
AX_CHECK_INCLUDE([linux/rtnetlink.h],[LINUX_RTNETLINK_H])
AX_CHECK_INCLUDE([linux/netlink.h],[LINUX_NETLINK_H])
AX_CHECK_INCLUDE([netinet/ip.h],[NETINET_IP_H])

AC_PROG_GCC_TRADITIONAL

AC_FUNC_MALLOC
AC_FUNC_REALLOC
AX_IN_STDLIB([malloc],[MALLOC]);

# Checks for header files.
AX_CHECK_INCLUDE([asm/types.h],[ASM_TYPES_H])
AX_CHECK_INCLUDE([features.h],[FEATURES_H])
AX_CHECK_INCLUDE([sys/param.h],[SYS_PARAM_H])
AX_CHECK_INCLUDE([sys/un.h],[SYS_UN_H])
AX_CHECK_INCLUDE([neteconet/ec.h],[NETECONET_EC_H])
AX_CHECK_INCLUDE([linux/atalk.h],[LINUX_ATALK_H])
AX_CHECK_INCLUDE([netinet/if_fddi.h],[NETINET_IF_FDDI_H])
AX_CHECK_INCLUDE([linux/if_fddi.h],[LINUX_IF_FDDI_H])
AX_CHECK_INCLUDE([linux/if_tr.h],[LINUX_IF_TR_H])
AX_CHECK_INCLUDE([net/if_arp.h],[NET_IF_ARP_H])
AX_CHECK_INCLUDE([linux/if_ether.h],[LINUX_IF_ETHER_H])
AX_CHECK_INCLUDE([endian.h],[ENDIAN_H])
AX_CHECK_INCLUDE([byteswap.h],[BYTESWAP_H])
AX_CHECK_INCLUDE([alloca.h],[ALLOCA_H])
AX_CHECK_INCLUDE([sys/sockio.h],[SYS_SOCKIO_H])
AX_CHECK_INCLUDE([sys/sysctl.h],[SYS_SYSCTL_H])
AX_CHECK_INCLUDE([sys/time.h],[SYS_TIME_H])
AX_CHECK_INCLUDE([sys/module.h],[SYS_MODULE_H])
AX_CHECK_INCLUDE([sys/linker.h],[SYS_LINKER_H])
AX_CHECK_INCLUDE([sys/mac.h],[SYS_MAC_H])
AX_CHECK_INCLUDE([netax25/ax25.h],[NETAX25_AX25_H])
AX_CHECK_INCLUDE([linux/ax25.h],[LINUX_AX25_H])
AX_CHECK_INCLUDE([linux/types.h],[LINUX_TYPES_H])
AX_CHECK_INCLUDE([linux/if_strip.h],[LINUX_IF_STRIP_H])
AX_CHECK_INCLUDE([linux/x25.h],[LINUX_X25_H])
AX_CHECK_INCLUDE([linux/if_arp.h],[LINUX_IF_ARP_H])
AX_CHECK_INCLUDE([sys/ioctl.h],[SYS_IOCTL_H])
AX_CHECK_INCLUDE([libc-internal.h],[LIBC_INTERNAL_H])
AX_CHECK_INCLUDE([signal.h],[SIGNAL_H])
AX_CHECK_INCLUDE([net/if.h],[NET_IF_H])
AX_CHECK_INCLUDE([netatalk/at.h],[NETATALK_AT_H])
AX_CHECK_INCLUDE([net/pfvar.h],[NET_PFVAR_H])
AX_CHECK_INCLUDE([net/if_pfsync.h],[NET_IF_PFSYNC_H])
AX_CHECK_INCLUDE([netpacket/packet.h],[NETPACKET_PACKET_H])
AX_CHECK_INCLUDE([stdbool.h],[STDBOOL_H])
AX_CHECK_INCLUDE([time.h],[TIME_H])
AX_CHECK_INCLUDE([netinet/in.h],[NETINET_IN_H])
AX_CHECK_INCLUDE([net/if_var.h],[NET_IF_VAR_H])
AX_CHECK_INCLUDE([netinet/in_var.h],[NETINET_IN_VAR_H])
AX_CHECK_INCLUDE([netipx/ipx.h],[NETIPX_IPX_H])
AX_CHECK_INCLUDE([netipx/ipx_if.h],[NETIPX_IPX_IF_H])
AX_CHECK_INCLUDE([net/if_dl.h],[NET_IF_DL_H])
AX_CHECK_INCLUDE([net/if_types.h],[NET_IF_TYPES_H])
AX_CHECK_INCLUDE([net/route.h],[NET_ROUTE_H])
AX_CHECK_INCLUDE([netinet/ether.h],[NETINET_ETHER_H])
AX_CHECK_INCLUDE([netinet/if_ether.h],[NETINET_IF_ETHER_H])
AX_CHECK_INCLUDE([linux/if_slip.h],[LINUX_IF_SLIP_H])
AX_CHECK_INCLUDE([ctype.h],[CTYPE_H])
AX_CHECK_INCLUDE([netinet/ip_carp.h],[NETINET_IP_CARP_H])
AX_CHECK_INCLUDE([net/if_media.h],[NET_IF_MEDIA_H])
AX_CHECK_INCLUDE([net80211/ieee80211.h],[NET80211_IEEE80211_H])
AX_CHECK_INCLUDE([net80211/ieee80211_crypto.h],[NET80211_IEEE80211_CRYPTO_H])
AX_CHECK_INCLUDE([net80211/ieee80211_ioctl.h],[NET80211_IEEE80211_IOCTL_H])
AX_CHECK_INCLUDE([net/if_lagg.h],[NET_IF_LAGG_H])
AX_CHECK_INCLUDE([net/if_vlan_var.h],[NET_IF_VLAN_VAR_H])
AX_CHECK_INCLUDE([net/ethernet.h],[NET_ETHERNET_H])
AX_CHECK_INCLUDE([ifaddrs.h],[IFADDRS_H])
AX_CHECK_INCLUDE([netdb.h],[NETDB_H])
AX_CHECK_INCLUDE([netinet6/nd6.h],[NETINET6_ND6_H])
AX_CHECK_INCLUDE([stdarg.h],[STDARG_H])
AX_CHECK_INCLUDE([net80211/ieee80211_freebsd.h],[NET80211_IEEE80211_FREEBSD_H])
AX_CHECK_INCLUDE([linux/rose.h],[LINUX_ROSE_H])
AX_CHECK_INCLUDE([fcntl.h],[FCNTL_H])
AX_CHECK_INCLUDE([malloc.h],[MALLOC_H])
AX_CHECK_INCLUDE([arpa/inet.h],[ARPA_INET_H])

# additional headers
AX_CHECK_INCLUDE([sys/dlpi.h],[SYS_DLPI_H])
AX_CHECK_INCLUDE([stropts.h],[STROPTS_H])
AX_CHECK_INCLUDE([net/nit_if.h],[NET_NIT_IF_H])
AX_CHECK_INCLUDE([netio.h],[NETIO_H])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_SIZE_T
AC_TYPE_INT8_T
AC_TYPE_INT16_T
AC_TYPE_INT32_T
AC_TYPE_INT64_T
AC_TYPE_UINT8_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T
AC_CHECK_TYPES([caddr_t])

AH_TEMPLATE([LIBS],[Extra libraries needed for this build])
AC_CHECK_FUNCS([memcmp memset memcpy bzero getpagesize memmove getnameinfo])

# my additions
AC_C_BIGENDIAN
AC_CHECK_SIZEOF([uint8_t])
AC_CHECK_SIZEOF([uint16_t])
AC_CHECK_SIZEOF([uint32_t])
AC_CHECK_SIZEOF([uint64_t])
AC_CHECK_SIZEOF([u_int8_t])
AC_CHECK_SIZEOF([u_int16_t])
AC_CHECK_SIZEOF([u_int32_t])
AC_CHECK_SIZEOF([u_int64_t])


AH_TEMPLATE([LOCAL_SIZEOF_POINTER],[Define size of pointer])
AC_MSG_CHECKING([for size of pointer])
AC_RUN_IFELSE([
#include "confdefs.h"  
#include "defaults.h"
int   
main()
{
  FILE *FP;
  long my_pointer_size = sizeof(char *);
  if (FP = fopen("conftest.data", "w")) {
    (void) fprintf(FP,"%ld\n",my_pointer_size);
    fclose(FP);
    return 0;
  } else
    return 1;
}],
# action if true
ac_pointersize=`cat conftest.data`
AC_MSG_RESULT([is $ac_pointersize])
AC_DEFINE_UNQUOTED([LOCAL_SIZEOF_POINTER],[$ac_pointersize],[define pointer size]),[
AC_MSG_RESULT([not defined])
# no action if false
])



AC_MSG_CHECKING([for PAGE_SIZE])
AC_RUN_IFELSE([
/* INPUT */
#include "confdefs.h"
#include "defaults.h"
int   
main()
{
#ifdef PAGE_SIZE
  return 0;
#else
  return 1;
#endif   
}],[
# ACTION IF TRUE
# page size is defined
    AC_MSG_RESULT([defined])],[
# ACTION IF FALSE
# page size is not define, run test
    AC_MSG_NOTICE([not defined, trying equivalent...])
    AC_RUN_IFELSE([
/*  INPUT 2 */
#   include "confdefs.h"
#   include "defaults.h"
    int
    main()
    {
      FILE *FP;
      long my_pagesize;
#   if defined (HAVE_UNISTD_H) && (defined(_SC_PAGESIZE) || defined(_SC_PAGE_SIZE) || defined(_SC_MMAP_PAGE_SIZE))
#	if defined(_SC_PAGESIZE)
	  my_pagesize = sysconf(_SC_PAGESIZE);
#	elif defined(_SC_PAGE_SIZE)
	  my_pagesize = sysconf(_SC_PAGE_SIZE);
#	else
	  my_pagesize = sysconf(_SC_MMAP_PAGE_SIZE);
#	endif
#   elif defined HAVE_GETPAGESIZE
      my_pagesize = getpagesize();
#   elif defined(PAGESIZE)
      my_pagesize = PAGESIZE;
#   else
      my_pagesize = 0;
#   endif

      if (FP = fopen("conftest.data", "w")) {
	(void) fprintf(FP,"%ld\n",my_pagesize);
	fclose(FP);
	if (my_pagesize != 0)
	  return 0;
	else
	  return 1;
	}
      return 1;
    }
    ],[
 #  ACTION IF TRUE 2
# managed to find page size, define it in our config file
    ac_pagesize=`cat conftest.data`
    AC_MSG_RESULT([found page size = $ac_pagesize])
    if test $ac_pagesize -gt 0; then
	AC_MSG_RESULT([define PAGE_SIZE $ac_pagesize])
	AC_DEFINE_UNQUOTED([PAGE_SIZE], [$ac_pagesize],[define PAGE_SIZE for this operating system])
    else
 # UGH! could not find a page size definition
	AC_MSG_ERROR([Could not find PAGE_SIZE for this OS])
    fi
    ],[
 #  ACTION IF FALSE 2
    AC_MSG_ERROR([Could not determine PAGE_SIZE for this OS])
    ])]
)

AH_TEMPLATE([HAVE_SOCKET],[Define to 1 if function 'socket' is present])
AC_SEARCH_LIBS([socket],[socket],[
	AC_DEFINE([HAVE_SOCKET])])

AH_TEMPLATE([HAVE_LINK_NTOA],[Define to 1 if function 'link_ntoa' is present])
AC_SEARCH_LIBS([link_ntoa],[socket],[
	AC_DEFINE([HAVE_LINK_NTOA])],[],[-lnsl])

AH_TEMPLATE([HAVE_INET_ATON],[Define to 1 if function 'inet_aton' is present])
AC_SEARCH_LIBS([inet_aton],[socket],[
	AC_DEFINE([HAVE_INET_ATON])],[],[-lnsl])

AH_TEMPLATE([HAVE_INET_PTON],[Define to 1 if function 'inet_pton' is present])
AC_SEARCH_LIBS([inet_pton],[socket],[
	AC_DEFINE([HAVE_INET_PTON])],[],[-lnsl])

AH_TEMPLATE([HAVE_INET_ADDR],[Define to 1 if function 'inet_addr' is present])
AC_SEARCH_LIBS([inet_addr],[socket],[
	AC_DEFINE([HAVE_INET_ADDR])],[],[-lnsl])

AH_TEMPLATE([HAVE_PCAP],[Define to 1 if pcap lib is present])
AC_SEARCH_LIBS([pcap_close],[pcap],[
	AC_DEFINE([HAVE_PCAP])],[],[$LDDLFLAGS])

AC_CHECK_TYPES([struct ifaddrs, struct ifreq, struct if_laddrreq, struct if_data, struct in6_ifreq, struct if_data, struct ifdevea],[],[],[
#include "confdefs.h"
#include "defaults.h"
])


AH_TEMPLATE([NI_LIFREQ_PAD],[Define to size of struct lifreq - struct nifreq])
AH_TEMPLATE([NI_LIFREQ_OFFSET],[Define union offset from start of lifreq])
AC_CHECK_TYPES([struct lifreq],[
	AC_MSG_CHECKING([for sizeof lifreq - nifreq])
	AC_RUN_IFELSE([
#include "confdefs.h"  
#include "defaults.h"
int   
main()
{
  FILE *FP;
  struct lifreq lifr;
  int diffsize = sizeof(lifr.lifr_lifru) + sizeof(lifr.lifr_lifru1) + sizeof(uint_t) + LIFNAMSIZ - IFNAMSIZ;
  if (FP = fopen("conftest.data", "w")) {
    (void) fprintf(FP,"%d\n",diffsize);
    fclose(FP);
    return 0;
  } else
    return 1;
}	],
# action if true
ac_lifreqpad=`cat conftest.data`
	AC_MSG_RESULT([is $ac_lifreqpad])
	AC_DEFINE_UNQUOTED([NI_LIFREQ_PAD],[$ac_lifreqpad],[define lifreq pad size]),[
	AC_MSG_RESULT([not defined])
	])
	AC_MSG_CHECKING([for lifreq union offset])
	AC_RUN_IFELSE([
#include "confdefs.h"  
#include "defaults.h"
int   
main()
{
  FILE *FP;
  struct lifreq lifr;
  int offset = LIFNAMSIZ - IFNAMSIZ + sizeof(lifr.lifr_lifru1) + sizeof(uint_t);
  if (FP = fopen("conftest.data", "w")) {
    (void) fprintf(FP,"%d\n",offset);
    fclose(FP);
    return 0;
  } else
    return 1;
}	],
# action if true
ac_lifreqoffset=`cat conftest.data`
	AC_MSG_RESULT([is $ac_lifreqoffset])
	AC_DEFINE_UNQUOTED([NI_LIFREQ_OFFSET],[$ac_lifreqoffset],[define lifreq union offset]),[
	AC_MSG_RESULT([not defined])
# action if false
	])
],[
	AC_DEFINE_UNQUOTED([NI_LIFREQ_OFFSET],[0],[define lifreq union offset])
],[               
#include "confdefs.h"
#include "defaults.h"
])

# we do not want multiple thread libraries included as
# extra LIBS so nest thread checks
AC_CHECK_HEADER([pthread.h],[
	AC_DEFINE([HAVE_PTHREAD_H],[1],[Define to 1 if you have <pthread.h>.])
	AC_SEARCH_LIBS([pthread_mutex_init],[pthreads],[],[])
	AC_MSG_NOTICE([...have pthreads, do not check for thread.h])],[
        AC_CHECK_HEADER([thread.h],[
	AC_DEFINE([HAVE_THREAD_H],[1],[Define to 1 if you have <thread.h>.])
	AC_SEARCH_LIBS([mutex_init],[thread],[],[])]
	)
])



AC_SEARCH_LIBS([ioctl],[],[])

AH_TEMPLATE([HAVE_SA_LEN],[Define to 1 if sockaddr has member 'sa_len'])
AC_CHECK_MEMBER([struct sockaddr.sa_len], [
	AC_DEFINE([HAVE_SA_LEN])],[],[
#include "confdefs.h"
#include "defaults.h"
])

AH_TEMPLATE([HAVE_SIN6_SCOPEID],[Define to 1 if sockaddr_in6 has member 'sin6_scopeid'])
AC_CHECK_MEMBER([struct sockaddr_in6.sin6_scopeid], [
	AC_DEFINE([HAVE_SIN6_SCOPEID])],[],[
#include "confdefs.h"
#include "defaults.h"
])
# add socket families as they are identified

AX_SIZEOF_SOCKFUNC([sockaddr],[SOCKADDR])
AX_SIZEOF_SOCKFUNC([sockaddr_storage],[SOCKADDR_STORAGE])
AX_SIZEOF_SOCKFUNC([sockaddr_in],[SOCKADDR_IN])
AX_SIZEOF_SOCKFUNC([sockaddr_at],[SOCKADDR_AT])
AX_SIZEOF_SOCKFUNC([sockaddr_ash],[SOCKADDR_ASH])
AX_SIZEOF_SOCKFUNC([sockaddr_ax25],[SOCKADDR_AX25])
AX_SIZEOF_SOCKFUNC([sockaddr_x25],[SOCKADDR_X25])
AX_SIZEOF_SOCKFUNC([sockaddr_ec],[SOCKADDR_EC])
AX_SIZEOF_SOCKFUNC([sockaddr_in6],[SOCKADDR_IN6])
AX_SIZEOF_SOCKFUNC([sockaddr_ipx],[SOCKADDR_IPX])
AX_SIZEOF_SOCKFUNC([sockaddr_un],[SOCKADDR_UN])
AX_SIZEOF_SOCKFUNC([sockaddr_ll],[SOCKADDR_LL])
AX_SIZEOF_SOCKFUNC([sockaddr_rose],[SOCKADDR_ROSE])
AX_SIZEOF_SOCKFUNC([sockaddr_dl],[SOCKADDR_DL])
AX_SIZEOF_SOCKFUNC([sockaddr_eon],[SOCKADDR_EON])
AX_SIZEOF_SOCKFUNC([sockaddr_inarp],[SOCKADDR_INARP])
AX_SIZEOF_SOCKFUNC([sockaddr_iso],[SOCKADDR_ISO])
AX_SIZEOF_SOCKFUNC([sockaddr_ns],[SOCKADDR_NS])
AX_SIZEOF_SOCKFUNC([sockaddr_atm],[SOCKADDR_ATM])
AX_SIZEOF_SOCKFUNC([sockaddr_dn],[SOCKADDR_DECnet])
AX_SIZEOF_SOCKFUNC([sockaddr_tp],[SOCKADDR_TP])
AX_SIZEOF_SOCKFUNC([sockaddr_ositp],[SOCKADDR_OSITP])    

AC_CONFIG_COMMANDS_PRE([
	if test "$LIBS" != ""; then
	AC_DEFINE_UNQUOTED([LIBS],[$LIBS],[Extra libraries])
	fi
])

AC_OUTPUT
