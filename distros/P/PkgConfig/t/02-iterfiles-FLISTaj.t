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
t/data/usr/lib/pkgconfig/xinerama.pc
t/data/usr/lib/pkgconfig/speexdsp.pc
t/data/usr/lib/pkgconfig/libgphoto2.pc
t/data/usr/lib/pkgconfig/glitz.pc
t/data/usr/lib/pkgconfig/xf86dgaproto.pc
t/data/usr/lib/pkgconfig/dbus-glib-1.pc
t/data/usr/lib/pkgconfig/ext2fs.pc
t/data/usr/lib/pkgconfig/xevie.pc
t/data/usr/lib/pkgconfig/libpulse-mainloop-glib.pc
t/data/usr/lib/pkgconfig/gupnp-igd-1.0.pc
t/data/usr/lib/pkgconfig/GraphicsMagick.pc
t/data/usr/lib/pkgconfig/gstreamer-base-0.10.pc
t/data/usr/lib/pkgconfig/gstreamer-video-0.10.pc
t/data/usr/lib/pkgconfig/theoraenc.pc
t/data/usr/lib/pkgconfig/OpenEXR.pc
t/data/usr/lib/pkgconfig/libglade-2.0.pc
t/data/usr/lib/pkgconfig/bigreqsproto.pc
t/data/usr/lib/pkgconfig/x11.pc
t/data/usr/lib/pkgconfig/pangoxft.pc
t/data/usr/lib/pkgconfig/libv4l1.pc
t/data/usr/lib/pkgconfig/shout.pc
t/data/usr/lib/pkgconfig/libcdio.pc
t/data/usr/lib/pkgconfig/resourceproto.pc
t/data/usr/lib/pkgconfig/cecil.pc
t/data/usr/lib/pkgconfig/zziplib.pc
t/data/usr/lib/pkgconfig/xcb-render.pc
t/data/usr/lib/pkgconfig/libssh2.pc
t/data/usr/lib/pkgconfig/cairo-ps.pc
t/data/usr/lib/pkgconfig/clutter-x11-1.0.pc
t/data/usr/lib/pkgconfig/libcdio_paranoia.pc
t/data/usr/lib/pkgconfig/gobject-introspection-1.0.pc
t/data/usr/lib/pkgconfig/QtMultimedia.pc
t/data/usr/lib/pkgconfig/xf86miscproto.pc
t/data/usr/lib/pkgconfig/vte.pc
t/data/usr/lib/pkgconfig/libecal-1.2.pc
t/data/usr/lib/pkgconfig/libxfcegui4-1.0.pc
t/data/usr/lib/pkgconfig/dirac.pc
t/data/usr/lib/pkgconfig/cucul++.pc
t/data/usr/lib/pkgconfig/libvisual-0.4.pc
t/data/usr/lib/pkgconfig/xrender.pc
t/data/usr/lib/pkgconfig/gtkhotkey-1.0.pc
t/data/usr/lib/pkgconfig/gmodule-2.0.pc
t/data/usr/lib/pkgconfig/xcb-util.pc
t/data/usr/lib/pkgconfig/libxul.pc
t/data/usr/lib/pkgconfig/opencore-amrwb.pc
t/data/usr/lib/pkgconfig/gstreamer-cdda-0.10.pc
t/data/usr/lib/pkgconfig/libpostproc.pc
t/data/usr/lib/pkgconfig/gobject-introspection-no-export-1.0.pc
t/data/usr/lib/pkgconfig/libgcj10.pc
t/data/usr/lib/pkgconfig/libdca.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
