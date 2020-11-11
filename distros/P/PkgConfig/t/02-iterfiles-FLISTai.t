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
t/data/usr/lib/pkgconfig/cucul++.pc
t/data/usr/lib/pkgconfig/mozilla-js.pc
t/data/usr/lib/pkgconfig/sm.pc
t/data/usr/lib/pkgconfig/glib-2.0.pc
t/data/usr/lib/pkgconfig/librpcsecgss.pc
t/data/usr/lib/pkgconfig/QtCLucene.pc
t/data/usr/lib/pkgconfig/freetype2.pc
t/data/usr/lib/pkgconfig/libglade-2.0.pc
t/data/usr/lib/pkgconfig/portaudiocpp.pc
t/data/usr/lib/pkgconfig/bluez.pc
t/data/usr/lib/pkgconfig/libxml++-1.0.pc
t/data/usr/lib/pkgconfig/libavdevice.pc
t/data/usr/lib/pkgconfig/xau.pc
t/data/usr/lib/pkgconfig/ORBit-CosNaming-2.0.pc
t/data/usr/lib/pkgconfig/libssh2.pc
t/data/usr/lib/pkgconfig/atkmm-1.6.pc
t/data/usr/lib/pkgconfig/gobject-introspection-no-export-1.0.pc
t/data/usr/lib/pkgconfig/cairo-xcb.pc
t/data/usr/lib/pkgconfig/gnome-mount.pc
t/data/usr/lib/pkgconfig/wrlib.pc
t/data/usr/lib/pkgconfig/xcmiscproto.pc
t/data/usr/lib/pkgconfig/mono-cairo.pc
t/data/usr/lib/pkgconfig/fuse.pc
t/data/usr/lib/pkgconfig/gtk+-unix-print-2.0.pc
t/data/usr/lib/pkgconfig/python-2.7.pc
t/data/usr/lib/pkgconfig/SDL_image.pc
t/data/usr/lib/pkgconfig/libedataserver-1.2.pc
t/data/usr/lib/pkgconfig/xt.pc
t/data/usr/lib/pkgconfig/upower-glib.pc
t/data/usr/lib/pkgconfig/xi.pc
t/data/usr/lib/pkgconfig/libselinux.pc
t/data/usr/lib/pkgconfig/hal-storage.pc
t/data/usr/lib/pkgconfig/libbonoboui-2.0.pc
t/data/usr/lib/pkgconfig/gstreamer-controller-0.10.pc
t/data/usr/lib/pkgconfig/libv4l1.pc
t/data/usr/lib/pkgconfig/json-glib-1.0.pc
t/data/usr/lib/pkgconfig/libxslt.pc
t/data/usr/lib/pkgconfig/gamin.pc
t/data/usr/lib/pkgconfig/Qt3Support.pc
t/data/usr/lib/pkgconfig/gstreamer-tag-0.10.pc
t/data/usr/lib/pkgconfig/libpcreposix.pc
t/data/usr/lib/pkgconfig/e2p.pc
t/data/usr/lib/pkgconfig/gstreamer-plugins-base-0.10.pc
t/data/usr/lib/pkgconfig/gconf-2.0.pc
t/data/usr/lib/pkgconfig/xfixes.pc
t/data/usr/lib/pkgconfig/libexif.pc
t/data/usr/lib/pkgconfig/QtScriptTools.pc
t/data/usr/lib/pkgconfig/gssdp-1.0.pc
t/data/usr/lib/pkgconfig/gupnp-1.0.pc
t/data/usr/lib/pkgconfig/xinerama.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
