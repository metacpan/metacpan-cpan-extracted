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
t/data/usr/lib/pkgconfig/libffi.pc
t/data/usr/lib/pkgconfig/glib-2.0.pc
t/data/usr/lib/pkgconfig/libmpg123.pc
t/data/usr/lib/pkgconfig/dmx.pc
t/data/usr/lib/pkgconfig/libmetacity-private.pc
t/data/usr/lib/pkgconfig/libopensc.pc
t/data/usr/lib/pkgconfig/upower-glib.pc
t/data/usr/lib/pkgconfig/fuse.pc
t/data/usr/lib/pkgconfig/gstreamer-0.10.pc
t/data/usr/lib/pkgconfig/xf86dgaproto.pc
t/data/usr/lib/pkgconfig/libical.pc
t/data/usr/lib/pkgconfig/libkms.pc
t/data/usr/lib/pkgconfig/gobject-2.0.pc
t/data/usr/lib/pkgconfig/xmuu.pc
t/data/usr/lib/pkgconfig/xineramaproto.pc
t/data/usr/lib/pkgconfig/liblircclient0.pc
t/data/usr/lib/pkgconfig/mtdev.pc
t/data/usr/lib/pkgconfig/librpcsecgss.pc
t/data/usr/lib/pkgconfig/cairo-xlib-xrender.pc
t/data/usr/lib/pkgconfig/alsa.pc
t/data/usr/lib/pkgconfig/libraw1394.pc
t/data/usr/lib/pkgconfig/libssl.pc
t/data/usr/lib/pkgconfig/gstreamer-rtsp-0.10.pc
t/data/usr/lib/pkgconfig/libcdio_cdda.pc
t/data/usr/lib/pkgconfig/dbus-1.pc
t/data/usr/lib/pkgconfig/gstreamer-net-0.10.pc
t/data/usr/lib/pkgconfig/gstreamer-plugins-base-0.10.pc
t/data/usr/lib/pkgconfig/kbproto.pc
t/data/usr/lib/pkgconfig/xf86vidmodeproto.pc
t/data/usr/lib/pkgconfig/QtCore.pc
t/data/usr/lib/pkgconfig/ice.pc
t/data/usr/lib/pkgconfig/xf86miscproto.pc
t/data/usr/lib/pkgconfig/ORBit.pc
t/data/usr/lib/pkgconfig/deskbar-applet.pc
t/data/usr/lib/pkgconfig/gnutls-extra.pc
t/data/usr/lib/pkgconfig/thunarx-1.pc
t/data/usr/lib/pkgconfig/gnome-vfs-module-2.0.pc
t/data/usr/lib/pkgconfig/compositeproto.pc
t/data/usr/lib/pkgconfig/gupnp-1.0.pc
t/data/usr/lib/pkgconfig/libpostproc.pc
t/data/usr/lib/pkgconfig/xi.pc
t/data/usr/lib/pkgconfig/xvmc.pc
t/data/usr/lib/pkgconfig/libegroupwise-1.2.pc
t/data/usr/lib/pkgconfig/pangoxft.pc
t/data/usr/lib/pkgconfig/gdkmm-2.4.pc
t/data/usr/lib/pkgconfig/poppler-cairo.pc
t/data/usr/lib/pkgconfig/Qt3Support.pc
t/data/usr/lib/pkgconfig/ORBit-idl-2.0.pc
t/data/usr/lib/pkgconfig/libcdio_paranoia.pc
t/data/usr/lib/pkgconfig/python2.6/pygtk-2.0.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
