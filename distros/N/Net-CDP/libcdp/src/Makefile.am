noinst_LTLIBRARIES = libcdp.la

libcdp_la_CPPFLAGS = $(LIBPCAP_CPPFLAGS) $(LIBNET_CPPFLAGS) -I$(top_srcdir)/lib
libcdp_la_SOURCES = \
	address.c \
	appliance.c \
	cdp.c cdp.h \
	checksum.c checksum.h \
	encoding.c encoding.h \
	ip_prefix.c \
	llist.c \
	packet.c \
	system.h
libcdp_la_LIBADD = $(LIBPCAP_LIBS) $(LIBNET_LIBS)

AUTOMAKE_OPTIONS = $(top_builddir)/lib/ansi2knr
