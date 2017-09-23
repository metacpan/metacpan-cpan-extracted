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
t/data/usr/share/pkgconfig/xbitmaps.pc
t/data/usr/share/pkgconfig/xextproto.pc
t/data/usr/share/pkgconfig/gnome-icon-theme.pc
t/data/usr/share/pkgconfig/gnome-mime-data-2.0.pc
t/data/usr/share/pkgconfig/udev.pc
t/data/usr/share/pkgconfig/xml2po.pc
t/data/usr/share/pkgconfig/libtut.pc
t/data/usr/share/pkgconfig/shared-desktop-ontologies.pc
t/data/usr/share/pkgconfig/gtk-doc.pc
t/data/usr/share/pkgconfig/shared-mime-info.pc
t/data/usr/share/pkgconfig/fixesproto.pc
t/data/usr/share/pkgconfig/iso-codes.pc
t/data/usr/share/pkgconfig/inputproto.pc
t/data/usr/share/pkgconfig/xproto.pc
t/data/usr/share/pkgconfig/dri2proto.pc
t/data/usr/share/pkgconfig/xorg-macros.pc
t/data/usr/share/pkgconfig/xcb-proto.pc
t/data/usr/share/pkgconfig/usbutils.pc
t/data/usr/share/pkgconfig/pthread-stubs.pc
t/data/usr/share/pkgconfig/gnome-doc-utils.pc
t/data/usr/share/pkgconfig/icon-naming-utils.pc
t/data/usr/share/pkgconfig/udisks.pc
t/data/usr/share/pkgconfig/glproto.pc
t/data/usr/share/pkgconfig/lxc.pc
t/data/usr/share/pkgconfig/xtrans.pc
t/data/usr/share/pkgconfig/xorg-sgml-doctools.pc
t/data/usr/share/pkgconfig/m17n-db.pc
t/data/usr/lib/pkgconfig/gstreamer-net-0.10.pc
t/data/usr/lib/pkgconfig/fftw3l.pc
t/data/usr/lib/pkgconfig/gio-2.0.pc
t/data/usr/lib/pkgconfig/libraw1394.pc
t/data/usr/lib/pkgconfig/ortp.pc
t/data/usr/lib/pkgconfig/gssdp-1.0.pc
t/data/usr/lib/pkgconfig/libdecoration.pc
t/data/usr/lib/pkgconfig/xcb.pc
t/data/usr/lib/pkgconfig/xmuu.pc
t/data/usr/lib/pkgconfig/cairomm-xlib-1.0.pc
t/data/usr/lib/pkgconfig/x264.pc
t/data/usr/lib/pkgconfig/openssl.pc
t/data/usr/lib/pkgconfig/glu.pc
t/data/usr/lib/pkgconfig/libart-2.0.pc
t/data/usr/lib/pkgconfig/gthread.pc
t/data/usr/lib/pkgconfig/sdl.pc
t/data/usr/lib/pkgconfig/ORBit-imodule-2.0.pc
t/data/usr/lib/pkgconfig/libpulse-simple.pc
t/data/usr/lib/pkgconfig/libgphoto2.pc
t/data/usr/lib/pkgconfig/dirac.pc
t/data/usr/lib/pkgconfig/xp.pc
t/data/usr/lib/pkgconfig/zzip-zlib-config.pc
t/data/usr/lib/pkgconfig/esound.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
