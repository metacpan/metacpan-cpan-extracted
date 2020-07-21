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
t/data/usr/lib/pkgconfig/cairo-ft.pc
t/data/usr/lib/pkgconfig/ORBit-idl-2.0.pc
t/data/usr/lib/pkgconfig/QtAssistantClient.pc
t/data/usr/lib/pkgconfig/gnome-vfs-module-2.0.pc
t/data/usr/lib/pkgconfig/libusb-1.0.pc
t/data/usr/lib/pkgconfig/libgpod-1.0.pc
t/data/usr/lib/pkgconfig/gstreamer-rtsp-0.10.pc
t/data/usr/lib/pkgconfig/gudev-1.0.pc
t/data/usr/lib/pkgconfig/polkit-gtk-1.pc
t/data/usr/lib/pkgconfig/libproxy-1.0.pc
t/data/usr/lib/pkgconfig/pciaccess.pc
t/data/usr/lib/pkgconfig/gdk-pixbuf-xlib-2.0.pc
t/data/usr/lib/pkgconfig/libv4lconvert.pc
t/data/usr/lib/pkgconfig/opencore-amrnb.pc
t/data/usr/lib/pkgconfig/xorg-server.pc
t/data/usr/lib/pkgconfig/ORBit-2.0.pc
t/data/usr/lib/pkgconfig/gstreamer-0.10.pc
t/data/usr/lib/pkgconfig/gupnp-1.0.pc
t/data/usr/lib/pkgconfig/QtDBus.pc
t/data/usr/lib/pkgconfig/ogg.pc
t/data/usr/lib/pkgconfig/avahi-client.pc
t/data/usr/lib/pkgconfig/gio-2.0.pc
t/data/usr/lib/pkgconfig/portaudiocpp.pc
t/data/usr/lib/pkgconfig/cogl-1.0.pc
t/data/usr/lib/pkgconfig/ORBit.pc
t/data/usr/lib/pkgconfig/gnome-window-settings-2.0.pc
t/data/usr/lib/pkgconfig/libgnome-menu.pc
t/data/usr/lib/pkgconfig/gst-python-0.10.pc
t/data/usr/lib/pkgconfig/cogl-gl-1.0.pc
t/data/usr/lib/pkgconfig/e2p.pc
t/data/usr/lib/pkgconfig/hal.pc
t/data/usr/lib/pkgconfig/libdc1394-2.pc
t/data/usr/lib/pkgconfig/gnutls-extra.pc
t/data/usr/lib/pkgconfig/libxul-unstable.pc
t/data/usr/lib/pkgconfig/pyvte.pc
t/data/usr/lib/pkgconfig/gnome-keyring-1.pc
t/data/usr/lib/pkgconfig/libmetacity-private.pc
t/data/usr/lib/pkgconfig/dri.pc
t/data/usr/lib/pkgconfig/trapproto.pc
t/data/usr/lib/pkgconfig/utouch-evemu.pc
t/data/usr/lib/pkgconfig/IlmBase.pc
t/data/usr/lib/pkgconfig/QtSql.pc
t/data/usr/lib/pkgconfig/gconf-2.0.pc
t/data/usr/lib/pkgconfig/QtTest.pc
t/data/usr/lib/pkgconfig/xcmiscproto.pc
t/data/usr/lib/pkgconfig/GraphicsMagickWand.pc
t/data/usr/lib/pkgconfig/sndfile.pc
t/data/usr/lib/pkgconfig/gstreamer-plugins-base-0.10.pc
t/data/usr/lib/pkgconfig/dbus-1.pc
t/data/usr/lib/pkgconfig/fontenc.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
