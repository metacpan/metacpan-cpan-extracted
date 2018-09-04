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
t/data/usr/lib/pkgconfig/libpulse.pc
t/data/usr/lib/pkgconfig/cairomm-ft-1.0.pc
t/data/usr/lib/pkgconfig/libpulse-mainloop-glib.pc
t/data/usr/lib/pkgconfig/evolution-data-server-1.2.pc
t/data/usr/lib/pkgconfig/libedataserver-1.2.pc
t/data/usr/lib/pkgconfig/evieproto.pc
t/data/usr/lib/pkgconfig/libgnomeprintui-2.2.pc
t/data/usr/lib/pkgconfig/cairo-xcb-shm.pc
t/data/usr/lib/pkgconfig/audiofile.pc
t/data/usr/lib/pkgconfig/dmx.pc
t/data/usr/lib/pkgconfig/meanwhile.pc
t/data/usr/lib/pkgconfig/xrender.pc
t/data/usr/lib/pkgconfig/QtHelp.pc
t/data/usr/lib/pkgconfig/mozilla-gtkmozembed.pc
t/data/usr/lib/pkgconfig/xdmcp.pc
t/data/usr/lib/pkgconfig/json-glib-1.0.pc
t/data/usr/lib/pkgconfig/speex.pc
t/data/usr/lib/pkgconfig/zlib.pc
t/data/usr/lib/pkgconfig/dbus-glib-1.pc
t/data/usr/lib/pkgconfig/pango.pc
t/data/usr/lib/pkgconfig/libssl.pc
t/data/usr/lib/pkgconfig/xext.pc
t/data/usr/lib/pkgconfig/GraphicsMagick.pc
t/data/usr/lib/pkgconfig/xtst.pc
t/data/usr/lib/pkgconfig/qimageblitz.pc
t/data/usr/lib/pkgconfig/xfont.pc
t/data/usr/lib/pkgconfig/gstreamer-fft-0.10.pc
t/data/usr/lib/pkgconfig/libart-2.0.pc
t/data/usr/lib/pkgconfig/libedata-book-1.2.pc
t/data/usr/lib/pkgconfig/cairo-gobject.pc
t/data/usr/lib/pkgconfig/atkmm-1.6.pc
t/data/usr/lib/pkgconfig/cucul++.pc
t/data/usr/lib/pkgconfig/libtasn1.pc
t/data/usr/lib/pkgconfig/tre.pc
t/data/usr/lib/pkgconfig/tracker.pc
t/data/usr/lib/pkgconfig/libavformat.pc
t/data/usr/lib/pkgconfig/silcclient.pc
t/data/usr/lib/pkgconfig/QtCLucene.pc
t/data/usr/lib/pkgconfig/taglib.pc
t/data/usr/lib/pkgconfig/camel-provider-1.2.pc
t/data/usr/lib/pkgconfig/cairo-ft.pc
t/data/usr/lib/pkgconfig/libgnome-menu.pc
t/data/usr/lib/pkgconfig/gthread-2.0.pc
t/data/usr/lib/pkgconfig/libdrm_radeon.pc
t/data/usr/lib/pkgconfig/nautilus-python.pc
t/data/usr/lib/pkgconfig/fontutil.pc
t/data/usr/lib/pkgconfig/resourceproto.pc
t/data/usr/lib/pkgconfig/dbus-1.pc
t/data/usr/lib/pkgconfig/xf86driproto.pc
t/data/usr/lib/pkgconfig/libgphoto2.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
