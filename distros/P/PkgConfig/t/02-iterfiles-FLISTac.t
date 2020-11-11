#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib $FindBin::Bin;
use PkgConfigTest;

plan skip_all => 'skip long running tests on ActiveState PPM build'
  if $ENV{ACTIVESTATE_PPM_BUILD};

my $flist = [qw(
t/data/usr/lib/pkgconfig/recordproto.pc
t/data/usr/lib/pkgconfig/nspr.pc
t/data/usr/lib/pkgconfig/libimobiledevice-1.0.pc
t/data/usr/lib/pkgconfig/libpulse-mainloop-glib.pc
t/data/usr/lib/pkgconfig/mono.web.pc
t/data/usr/lib/pkgconfig/libgnome-menu.pc
t/data/usr/lib/pkgconfig/xcb-event.pc
t/data/usr/lib/pkgconfig/dirac.pc
t/data/usr/lib/pkgconfig/gthread-2.0.pc
t/data/usr/lib/pkgconfig/QtUiTools.pc
t/data/usr/lib/pkgconfig/xf86vidmodeproto.pc
t/data/usr/lib/pkgconfig/QtSql.pc
t/data/usr/lib/pkgconfig/xcb.pc
t/data/usr/lib/pkgconfig/xtrap.pc
t/data/usr/lib/pkgconfig/xcb-shm.pc
t/data/usr/lib/pkgconfig/libconfig.pc
t/data/usr/lib/pkgconfig/mozilla-gtkmozembed-embedding.pc
t/data/usr/lib/pkgconfig/gstreamer-pbutils-0.10.pc
t/data/usr/lib/pkgconfig/libxul-unstable.pc
t/data/usr/lib/pkgconfig/xtst.pc
t/data/usr/lib/pkgconfig/nautilus-sendto.pc
t/data/usr/lib/pkgconfig/kbproto.pc
t/data/usr/lib/pkgconfig/gtkspell-2.0.pc
t/data/usr/lib/pkgconfig/uuid.pc
t/data/usr/lib/pkgconfig/libopensc.pc
t/data/usr/lib/pkgconfig/clutter-1.0.pc
t/data/usr/lib/pkgconfig/mono-options.pc
t/data/usr/lib/pkgconfig/QtCore.pc
t/data/usr/lib/pkgconfig/xf86bigfontproto.pc
t/data/usr/lib/pkgconfig/libbonobo-2.0.pc
t/data/usr/lib/pkgconfig/esound.pc
t/data/usr/lib/pkgconfig/libxklavier.pc
t/data/usr/lib/pkgconfig/libwnck-1.0.pc
t/data/usr/lib/pkgconfig/cairomm-1.0.pc
t/data/usr/lib/pkgconfig/xxf86dga.pc
t/data/usr/lib/pkgconfig/libtasn1.pc
t/data/usr/lib/pkgconfig/libgnomecanvas-2.0.pc
t/data/usr/lib/pkgconfig/libusbmuxd.pc
t/data/usr/lib/pkgconfig/gstreamer-base-0.10.pc
t/data/usr/lib/pkgconfig/pixman-1.pc
t/data/usr/lib/pkgconfig/opencore-amrnb.pc
t/data/usr/lib/pkgconfig/gnome-window-settings-2.0.pc
t/data/usr/lib/pkgconfig/zziplib.pc
t/data/usr/lib/pkgconfig/exempi-2.0.pc
t/data/usr/lib/pkgconfig/xf86dgaproto.pc
t/data/usr/lib/pkgconfig/libcdio_paranoia.pc
t/data/usr/lib/pkgconfig/QtAssistantClient.pc
t/data/usr/lib/pkgconfig/xmu.pc
t/data/usr/lib/pkgconfig/libgnomeprint-2.2.pc
t/data/usr/lib/pkgconfig/libavc1394.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
