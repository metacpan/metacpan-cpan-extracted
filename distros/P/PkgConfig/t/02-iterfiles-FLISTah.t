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
t/data/usr/lib/pkgconfig/glitz.pc
t/data/usr/lib/pkgconfig/dirac.pc
t/data/usr/lib/pkgconfig/opencore-amrnb.pc
t/data/usr/lib/pkgconfig/libcap-ng.pc
t/data/usr/lib/pkgconfig/eventlog.pc
t/data/usr/lib/pkgconfig/xorg-evdev.pc
t/data/usr/lib/pkgconfig/alsa.pc
t/data/usr/lib/pkgconfig/ogg.pc
t/data/usr/lib/pkgconfig/x264.pc
t/data/usr/lib/pkgconfig/libavutil.pc
t/data/usr/lib/pkgconfig/upower-glib.pc
t/data/usr/lib/pkgconfig/glib-2.0.pc
t/data/usr/lib/pkgconfig/gtkhotkey-1.0.pc
t/data/usr/lib/pkgconfig/renderproto.pc
t/data/usr/lib/pkgconfig/gobject-introspection-no-export-1.0.pc
t/data/usr/lib/pkgconfig/mad.pc
t/data/usr/lib/pkgconfig/librpcsecgss.pc
t/data/usr/lib/pkgconfig/sofia-sip-ua.pc
t/data/usr/lib/pkgconfig/farsight2-0.10.pc
t/data/usr/lib/pkgconfig/gl.pc
t/data/usr/lib/pkgconfig/caca++.pc
t/data/usr/lib/pkgconfig/libxslt.pc
t/data/usr/lib/pkgconfig/python-2.7.pc
t/data/usr/lib/pkgconfig/nspr.pc
t/data/usr/lib/pkgconfig/mutter-plugins.pc
t/data/usr/lib/pkgconfig/libxml++-2.6.pc
t/data/usr/lib/pkgconfig/pangocairo.pc
t/data/usr/lib/pkgconfig/libpcreposix.pc
t/data/usr/lib/pkgconfig/cucul.pc
t/data/usr/lib/pkgconfig/xcursor.pc
t/data/usr/lib/pkgconfig/dbus-python.pc
t/data/usr/lib/pkgconfig/libidn.pc
t/data/usr/lib/pkgconfig/xft.pc
t/data/usr/lib/pkgconfig/gmodule.pc
t/data/usr/lib/pkgconfig/gio-unix-2.0.pc
t/data/usr/lib/pkgconfig/unique-1.0.pc
t/data/usr/lib/pkgconfig/exo-hal-0.3.pc
t/data/usr/lib/pkgconfig/damageproto.pc
t/data/usr/lib/pkgconfig/x11-xcb.pc
t/data/usr/lib/pkgconfig/portaudiocpp.pc
t/data/usr/lib/pkgconfig/mono-lineeditor.pc
t/data/usr/lib/pkgconfig/libscconf.pc
t/data/usr/lib/pkgconfig/dvdread.pc
t/data/usr/lib/pkgconfig/QtOpenGL.pc
t/data/usr/lib/pkgconfig/libudev.pc
t/data/usr/lib/pkgconfig/directfb.pc
t/data/usr/lib/pkgconfig/gtk-vnc-1.0.pc
t/data/usr/lib/pkgconfig/libegroupwise-1.2.pc
t/data/usr/lib/pkgconfig/sm.pc
t/data/usr/lib/pkgconfig/gstreamer-0.10.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
