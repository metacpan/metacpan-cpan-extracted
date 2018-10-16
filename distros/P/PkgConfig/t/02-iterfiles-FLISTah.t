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
t/data/usr/lib/pkgconfig/libconfig.pc
t/data/usr/lib/pkgconfig/QtDesignerComponents.pc
t/data/usr/lib/pkgconfig/librsvg-2.0.pc
t/data/usr/lib/pkgconfig/libxine.pc
t/data/usr/lib/pkgconfig/libsoup-gnome-2.4.pc
t/data/usr/lib/pkgconfig/gstreamer-pbutils-0.10.pc
t/data/usr/lib/pkgconfig/libv4l1.pc
t/data/usr/lib/pkgconfig/libxfce4util-1.0.pc
t/data/usr/lib/pkgconfig/xulrunner-nspr.pc
t/data/usr/lib/pkgconfig/gthread.pc
t/data/usr/lib/pkgconfig/xscrnsaver.pc
t/data/usr/lib/pkgconfig/sqlite3.pc
t/data/usr/lib/pkgconfig/system.web.extensions.design_1.0.pc
t/data/usr/lib/pkgconfig/xorg-evdev.pc
t/data/usr/lib/pkgconfig/cairomm-xlib-1.0.pc
t/data/usr/lib/pkgconfig/libvisual-0.4.pc
t/data/usr/lib/pkgconfig/gstreamer-sdp-0.10.pc
t/data/usr/lib/pkgconfig/xkbui.pc
t/data/usr/lib/pkgconfig/mozilla-gtkmozembed-embedding.pc
t/data/usr/lib/pkgconfig/cally-1.0.pc
t/data/usr/lib/pkgconfig/thunar-vfs-1.pc
t/data/usr/lib/pkgconfig/libgphoto2_port.pc
t/data/usr/lib/pkgconfig/audiofile.pc
t/data/usr/lib/pkgconfig/x11-xcb.pc
t/data/usr/lib/pkgconfig/printproto.pc
t/data/usr/lib/pkgconfig/tre.pc
t/data/usr/lib/pkgconfig/gstreamer-dataprotocol-0.10.pc
t/data/usr/lib/pkgconfig/libbonoboui-2.0.pc
t/data/usr/lib/pkgconfig/mono-nunit.pc
t/data/usr/lib/pkgconfig/gudev-1.0.pc
t/data/usr/lib/pkgconfig/system.web.extensions_1.0.pc
t/data/usr/lib/pkgconfig/cairomm-1.0.pc
t/data/usr/lib/pkgconfig/zzipmmapped.pc
t/data/usr/lib/pkgconfig/QtXmlPatterns.pc
t/data/usr/lib/pkgconfig/cogl-gl-1.0.pc
t/data/usr/lib/pkgconfig/gmime-2.4.pc
t/data/usr/lib/pkgconfig/xext.pc
t/data/usr/lib/pkgconfig/gssdp-1.0.pc
t/data/usr/lib/pkgconfig/glib.pc
t/data/usr/lib/pkgconfig/gthread-2.0.pc
t/data/usr/lib/pkgconfig/cairo-pdf.pc
t/data/usr/lib/pkgconfig/libproxy-1.0.pc
t/data/usr/lib/pkgconfig/mono-cairo.pc
t/data/usr/lib/pkgconfig/gtk+-x11-2.0.pc
t/data/usr/lib/pkgconfig/GraphicsMagick++.pc
t/data/usr/lib/pkgconfig/gnome-keyring-1.pc
t/data/usr/lib/pkgconfig/mono-lineeditor.pc
t/data/usr/lib/pkgconfig/vorbis.pc
t/data/usr/lib/pkgconfig/check.pc
t/data/usr/lib/pkgconfig/sm.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
