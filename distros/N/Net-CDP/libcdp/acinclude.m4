#
# MAC_LIB_PCAP
#
AC_DEFUN([MAC_LIB_PCAP], [
	AC_ARG_WITH(libpcap-includes,
		AC_HELP_STRING([--with-libpcap-includes=DIR], [prefix for libpcap header files [[guessed]]]))
	AC_ARG_WITH(libpcap-libs,
		AC_HELP_STRING([--with-libpcap-libs=DIR], [prefix for libpcap library [[guessed]]]))
	
	with_libpcap=yes
	HAVE_LIB_PCAP=yes
	
	if test "$with_libpcap_includes" != no; then
		if test "$with_libpcap_includes" = yes; then
			with_libpcap_includes=
		fi
	else
		with_libpcap=no
		HAVE_LIB_PCAP=
	fi
	
	if test "$with_libpcap_libs" != no; then
		if test "$with_libpcap_libs" = yes; then
			with_libpcap_libs=
		fi
	else
		with_libpcap=no
		HAVE_LIB_PCAP=
	fi
	
	LIBPCAP_CPPFLAGS=
	LIBPCAP_LDFLAGS=
	LIBPCAP_LIBS=
	
	if test "$with_libpcap" != no; then
		if test "$with_libpcap_includes"; then
			unset mac_cv_header_pcap
			LIBPCAP_CPPFLAGS="-I$with_libpcap_includes"
		fi
		AC_CACHE_CHECK([[for pcap.h]], mac_cv_header_pcap, [
			mac_save_CPPFLAGS="$CPPFLAGS"
			if test "$with_libpcap_includes"; then
				CPPFLAGS="$CPPFLAGS -I$with_libpcap_includes"
			fi
			AC_COMPILE_IFELSE([
				AC_LANG_SOURCE([[
@%:@include <pcap.h>
				]])
			], [
				mac_cv_header_pcap=yes
			], [
				mac_cv_header_pcap=no
			])
			CPPFLAGS="$mac_save_CPPFLAGS"
		])
		if test "$mac_cv_header_pcap" = no -a -z "$with_libpcap_includes"; then
			unset mac_cv_header_pcap
			LIBPCAP_CPPFLAGS="-I/usr/include/pcap"
			AC_CACHE_CHECK([[for pcap.h (-I/usr/include/pcap)]],
					mac_cv_header_pcap, [
				mac_save_CPPFLAGS="$CPPFLAGS"
				CPPFLAGS="$CPPFLAGS -I/usr/include/pcap"
				AC_COMPILE_IFELSE([
					AC_LANG_SOURCE([[
@%:@include <pcap.h>
					]])
				], [
					mac_cv_header_pcap=yes
				], [
					mac_cv_header_pcap=no
				])
				CPPFLAGS="$mac_save_CPPFLAGS"
			])
		fi

		if test "$mac_cv_header_pcap" = yes; then
			AC_DEFINE(HAVE_PCAP_H, 1, [Define to 1 if you have the <pcap.h> header file.])
			AC_MSG_CHECKING([for pcap.h preprocessor flags])
			if test "$LIBPCAP_CPPFLAGS"; then
				AC_MSG_RESULT([$LIBPCAP_CPPFLAGS])
			else
				AC_MSG_RESULT([none needed])
			fi
		else
			with_libpcap=no
			HAVE_LIB_PCAP=no
		fi
	fi
	
	if test "$with_libpcap" != no; then
		LIBPCAP_LIBS=-lpcap
		if test "$with_libpcap_libs"; then
			unset mac_cv_lib_pcap
			LIBPCAP_LDFLAGS="-L$with_libpcap_libs"
		fi
		AC_CACHE_CHECK([[for pcap_open_live in -lpcap]], mac_cv_lib_pcap, [
			mac_save_CPPFLAGS="$CPPFLAGS"
			mac_save_LDFLAGS="$LDFLAGS"
			mac_save_LIBS="$LIBS"
			CPPFLAGS="$CPPFLAGS $LIBPCAP_CPPFLAGS"
			LDFLAGS="$LDFLAGS $LIBPCAP_LDFLAGS"
			LIBS="$LIBS -lpcap"
			AC_LINK_IFELSE([
				AC_LANG_PROGRAM([[
@%:@include <pcap.h>
				]], [[
pcap_open_live(NULL, 0, 0, 0, NULL);
				]])
			], [
				mac_cv_lib_pcap=yes
			], [
				mac_cv_lib_pcap=no
			])
			CPPFLAGS="$mac_save_CPPFLAGS"
			LDFLAGS="$mac_save_LDFLAGS"
			LIBS="$mac_save_LIBS"
		])
		if test "$mac_cv_lib_pcap" = no; then
			LIBPCAP_LIBS="-lpcap -lcfg -lodm"
			unset mac_cv_lib_pcap
			AC_CACHE_CHECK([[for pcap_open_live in -lpcap -lcfg -lodm]],
					mac_cv_lib_pcap, [
				mac_save_CPPFLAGS="$CPPFLAGS"
				mac_save_LDFLAGS="$LDFLAGS"
				mac_save_LIBS="$LIBS"
				CPPFLAGS="$CPPFLAGS $LIBPCAP_CPPFLAGS"
				LDFLAGS="$LDFLAGS $LIBPCAP_LDFLAGS"
				LIBS="$LIBS -lpcap -lcfg -lodm"
				AC_LINK_IFELSE([
					AC_LANG_PROGRAM([[
@%:@include <pcap.h>
					]], [[
pcap_open_live(NULL, 0, 0, 0, NULL);
					]])
				], [
					mac_cv_lib_pcap=yes
				], [
					mac_cv_lib_pcap=no
				])
				CPPFLAGS="$mac_save_CPPFLAGS"
				LDFLAGS="$mac_save_LDFLAGS"
				LIBS="$mac_save_LIBS"
			])
		fi
		
		if test "$mac_cv_lib_pcap" = yes; then
			AC_DEFINE(HAVE_LIBPCAP, 1, [Define to 1 if you have the `pcap' library (-lpcap).])
			AC_MSG_CHECKING([for -lpcap linker flags])
			if test "$LIBPCAP_LDFLAGS"; then
				AC_MSG_RESULT([$LIBPCAP_LDFLAGS])
			else
				AC_MSG_RESULT([none needed])
			fi
		else
			with_libpcap=no
			HAVE_LIB_PCAP=no
		fi
	fi
	
	if test "$with_libpcap" != no; then
		mac_save_CPPFLAGS="$CPPFLAGS"
		mac_save_LDFLAGS="$LDFLAGS"
		mac_save_LIBS="$LIBS"
		CPPFLAGS="$CPPFLAGS $LIBPCAP_CPPFLAGS"
		LDFLAGS="$CPPFLAGS $LIBPCAP_LDFLAGS"
		LIBS="$LIBS $LIBPCAP_LIBS"
		AC_CHECK_FUNCS(pcap_setnonblock)
		CPPFLAGS="$mac_save_CPPFLAGS"
		LDFLAGS="$mac_save_LDFLAGS"
		LIBS="$mac_save_LIBS"
	fi
	
	AC_SUBST(LIBPCAP_CPPFLAGS)
	AC_SUBST(LIBPCAP_LDFLAGS)
	AC_SUBST(LIBPCAP_LIBS)
])

#
# MAC_LIB_NET
#
AC_DEFUN([MAC_LIB_NET], [
	AC_ARG_WITH(libnet-includes,
		AC_HELP_STRING([--with-libnet-includes=DIR], [prefix for libnet header files [[guessed]]]))
	AC_ARG_WITH(libnet-libs,
		AC_HELP_STRING([--with-libnet-libs=DIR], [prefix for libnet library [[guessed]]]))
	
	with_libnet=yes
	HAVE_LIB_NET=yes
	
	if test "$with_libnet_includes" != no; then
		if test "$with_libnet_includes" = yes; then
			with_libnet_includes=
		fi
	else
		with_libnet=no
		HAVE_LIB_NET=
	fi
	
	if test "$with_libnet_libs" != no; then
		if test "$with_libnet_libs" = yes; then
			with_libnet_libs=
		fi
	else
		with_libnet=no
		HAVE_LIB_NET=
	fi
	
	LIBNET_CPPFLAGS=
	LIBNET_LDFLAGS=
	LIBNET_LIBS=
	
	if test "$with_libnet" != no; then
		mac_save_CPPFLAGS="$CPPFLAGS"
		if test "$with_libnet_includes"; then
			CPPFLAGS="$CPPFLAGS -I$with_libnet_includes"
			LIBNET_CPPFLAGS="-I$with_libnet_includes"
		fi
		AC_CHECK_HEADER(libnet.h, [
			AC_DEFINE(HAVE_LIBNET_H, 1, [Define to 1 if you have the <libnet.h> header file.])
		], [
			with_libnet=no
			HAVE_LIB_NET=no
		], [-])
		CPPFLAGS="$mac_save_CPPFLAGS"
	fi
	
	if test "$with_libnet" != no; then
		mac_save_CPPFLAGS="$CPPFLAGS"
		mac_save_LDFLAGS="$LDFLAGS"
		CPPFLAGS="$CPPFLAGS $LIBNET_CPPFLAGS"
		if test "$with_libnet_libs"; then
			LDFLAGS="$LDFLAGS -L$with_libnet_libs"
			LIBNET_LDFLAGS="-L$with_libnet_libs"
		fi
		
		AC_CHECK_LIB(net, libnet_init, [
			LIBNET_LIBS=-lnet
		], [
			AC_CHECK_LIB(net, libnet_init_packet, [
				LIBNET_LIBS=-lnet
			], [
				with_libnet=no
				HAVE_LIB_NET=no
			])
		])
		
		CPPFLAGS="$mac_save_CPPFLAGS"
		LDFLAGS="$mac_save_LDFLAGS"
	fi

	AC_SUBST(LIBNET_CPPFLAGS)
	AC_SUBST(LIBNET_LDFLAGS)
	AC_SUBST(LIBNET_LIBS)
	HAVE_LIB_NET="$with_libnet"
])

#
# MAC_SYS_MULTICAST
#
AC_DEFUN([MAC_SYS_MULTICAST], [
	AC_ARG_ENABLE(multicast,
		AC_HELP_STRING([--disable-multicast], [do not attempt to use multicast membership]))
	
	if test "$enable_multicast" != no; then
		if test "$enable_multicast" != yes; then
			enable_multicast=yes
		fi
	fi

	HAVE_SYS_MULTICAST=
	if test "$enable_multicast" = yes; then
		AC_CHECK_HEADERS([netpacket/packet.h], , , [-])
		
		AC_CACHE_CHECK([[for multicast membership options in setsockopt]], mac_cv_sys_multicast, [
			AC_COMPILE_IFELSE(
				AC_LANG_PROGRAM([[
@%:@ifdef HAVE_SYS_SOCKET_H
@%:@ include <sys/socket.h>
@%:@endif /* HAVE_SYS_SOCKET_H */
@%:@ifdef HAVE_NETPACKET_PACKET_H
@%:@ include <netpacket/packet.h>
@%:@endif /* HAVE_NETPACKET_PACKET_H */
				]], [[
struct packet_mreq mreq;
setsockopt(0, SOL_PACKET, PACKET_ADD_MEMBERSHIP, &mreq, sizeof(struct packet_mreq));
setsockopt(0, SOL_PACKET, PACKET_DROP_MEMBERSHIP, &mreq, sizeof(struct packet_mreq));
				]]), mac_cv_sys_multicast=yes, mac_cv_sys_multicast=no
			)
		])
		if test "$mac_cv_sys_multicast" = yes; then
			AC_DEFINE(HAVE_MULTICAST, 1, [Define to use multicasting])
		fi
		HAVE_SYS_MULTICAST="$mac_cv_sys_multicast"
	fi
])

#
# MAC_HEADER_ETHTOOL
#
AC_DEFUN([MAC_HEADER_ETHTOOL], [
	AC_CACHE_CHECK([for linux/ethtool.h], mac_cv_header_ethtool_h, [
		AC_COMPILE_IFELSE([
			AC_LANG_SOURCE([
AC_INCLUDES_DEFAULT
@%:@include <linux/ethtool.h>
			])
		], [mac_cv_header_ethtool_h=yes], [mac_cv_header_ethtool_h=no]
		)
		if test "$mac_cv_header_ethtool_h" = no; then
			AC_COMPILE_IFELSE([
				AC_LANG_SOURCE([
AC_INCLUDES_DEFAULT
@%:@define u8  uint8_t
@%:@define s8  int8_t
@%:@define u16 uint16_t
@%:@define s16 int16_t
@%:@define u32 uint32_t
@%:@define s32 int32_t
@%:@define u64 uint64_t
@%:@define s64 int64_t
@%:@include <linux/ethtool.h>
				])
			],
			[mac_cv_header_ethtool_h="yes (with type munging)"],
			[mac_cv_header_ethtool_h=no]
			)
		])
	fi
	if test "$mac_cv_header_ethtool_h" = "yes (with type munging)"; then
		AC_DEFINE(u8,  uint8_t,  [Define to the type u8 should expand to.])
		AC_DEFINE(s8,  int8_t,   [Define to the type u8 should expand to.])
		AC_DEFINE(u16, uint16_t, [Define to the type u16 should expand to.])
		AC_DEFINE(s16, int16_t,  [Define to the type u16 should expand to.])
		AC_DEFINE(u32, uint32_t, [Define to the type u32 should expand to.])
		AC_DEFINE(s32, int32_t,  [Define to the type u32 should expand to.])
		AC_DEFINE(u64, uint64_t, [Define to the type u64 should expand to.])
		AC_DEFINE(s64, int64_t,  [Define to the type u64 should expand to.])
	fi
	if test "$mac_cv_header_ethtool_h" = no; then
		:
	else
		AC_DEFINE(HAVE_ETHTOOL_H, 1, [Define to 1 if you have the <linux/ethtool.h> header file.])
	fi
])
