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
t/data/usr/lib/pkgconfig/imlib.pc
t/data/usr/lib/pkgconfig/libgnomeui-2.0.pc
t/data/usr/lib/pkgconfig/libbonobo-2.0.pc
t/data/usr/lib/pkgconfig/QtNetwork.pc
t/data/usr/lib/pkgconfig/libgdiplus.pc
t/data/usr/lib/pkgconfig/dbus-python.pc
t/data/usr/lib/pkgconfig/gssdp-1.0.pc
t/data/usr/lib/pkgconfig/cairomm-svg-1.0.pc
t/data/usr/lib/pkgconfig/sdl.pc
t/data/usr/lib/pkgconfig/libcrypto.pc
t/data/usr/lib/pkgconfig/scrnsaverproto.pc
t/data/usr/lib/pkgconfig/libart-2.0.pc
t/data/usr/lib/pkgconfig/gdu.pc
t/data/usr/lib/pkgconfig/gstreamer-check-0.10.pc
t/data/usr/lib/pkgconfig/libdrm_radeon.pc
t/data/usr/lib/pkgconfig/fftw3.pc
t/data/usr/lib/pkgconfig/libgphoto2_port.pc
t/data/usr/lib/pkgconfig/mjpegtools.pc
t/data/usr/lib/pkgconfig/GraphicsMagick++.pc
t/data/usr/lib/pkgconfig/libtasn1.pc
t/data/usr/lib/pkgconfig/ORBit-CosNaming-2.0.pc
t/data/usr/lib/pkgconfig/meanwhile.pc
t/data/usr/lib/pkgconfig/sqlite3.pc
t/data/usr/lib/pkgconfig/devkit-power-gobject.pc
t/data/usr/lib/pkgconfig/libexchange-storage-1.2.pc
t/data/usr/lib/pkgconfig/gmodule-no-export-2.0.pc
t/data/usr/lib/pkgconfig/orc-0.4.pc
t/data/usr/lib/pkgconfig/giomm-2.4.pc
t/data/usr/lib/pkgconfig/kbproto.pc
t/data/usr/lib/pkgconfig/libtpl.pc
t/data/usr/lib/pkgconfig/gthread.pc
t/data/usr/lib/pkgconfig/camel-provider-1.2.pc
t/data/usr/lib/pkgconfig/xtrap.pc
t/data/usr/lib/pkgconfig/libebook-1.2.pc
t/data/usr/lib/pkgconfig/dvdnavmini.pc
t/data/usr/lib/pkgconfig/libmpeg2convert.pc
t/data/usr/lib/pkgconfig/pm-utils.pc
t/data/usr/lib/pkgconfig/xf86driproto.pc
t/data/usr/lib/pkgconfig/fontconfig.pc
t/data/usr/lib/pkgconfig/polkit.pc
t/data/usr/lib/pkgconfig/gnome-settings-daemon.pc
t/data/usr/lib/pkgconfig/libxml-2.0.pc
t/data/usr/lib/pkgconfig/nunit.pc
t/data/usr/lib/pkgconfig/libexif.pc
t/data/usr/lib/pkgconfig/hal-storage.pc
t/data/usr/lib/pkgconfig/direct.pc
t/data/usr/lib/pkgconfig/x264.pc
t/data/usr/lib/pkgconfig/cally-1.0.pc
t/data/usr/lib/pkgconfig/libraw1394.pc
t/data/usr/lib/pkgconfig/libsoup-gnome-2.4.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
