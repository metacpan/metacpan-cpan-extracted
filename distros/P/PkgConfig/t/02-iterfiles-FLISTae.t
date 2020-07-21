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
t/data/usr/lib/pkgconfig/xf86vidmodeproto.pc
t/data/usr/lib/pkgconfig/fontsproto.pc
t/data/usr/lib/pkgconfig/xvmc.pc
t/data/usr/lib/pkgconfig/libavcodec.pc
t/data/usr/lib/pkgconfig/libpulse.pc
t/data/usr/lib/pkgconfig/pangomm-1.4.pc
t/data/usr/lib/pkgconfig/libdrm_intel.pc
t/data/usr/lib/pkgconfig/x11-xcb.pc
t/data/usr/lib/pkgconfig/libcurl.pc
t/data/usr/lib/pkgconfig/gvnc-1.0.pc
t/data/usr/lib/pkgconfig/xorg-evdev.pc
t/data/usr/lib/pkgconfig/cairomm-ps-1.0.pc
t/data/usr/lib/pkgconfig/json-glib-1.0.pc
t/data/usr/lib/pkgconfig/gstreamer-interfaces-0.10.pc
t/data/usr/lib/pkgconfig/sm.pc
t/data/usr/lib/pkgconfig/xkbui.pc
t/data/usr/lib/pkgconfig/mono-lineeditor.pc
t/data/usr/lib/pkgconfig/cairo-xlib-xrender.pc
t/data/usr/lib/pkgconfig/system.web.mvc.pc
t/data/usr/lib/pkgconfig/libgcj-4.4.pc
t/data/usr/lib/pkgconfig/exo-0.3.pc
t/data/usr/lib/pkgconfig/jinglexmpp-0.3.pc
t/data/usr/lib/pkgconfig/libexslt.pc
t/data/usr/lib/pkgconfig/libgcj.pc
t/data/usr/lib/pkgconfig/cairomm-pdf-1.0.pc
t/data/usr/lib/pkgconfig/fontcacheproto.pc
t/data/usr/lib/pkgconfig/gstreamer-audio-0.10.pc
t/data/usr/lib/pkgconfig/libplist.pc
t/data/usr/lib/pkgconfig/libbonoboui-2.0.pc
t/data/usr/lib/pkgconfig/mono.web.pc
t/data/usr/lib/pkgconfig/QtSvg.pc
t/data/usr/lib/pkgconfig/libavformat.pc
t/data/usr/lib/pkgconfig/libquicktime.pc
t/data/usr/lib/pkgconfig/atk.pc
t/data/usr/lib/pkgconfig/evieproto.pc
t/data/usr/lib/pkgconfig/glib-2.0.pc
t/data/usr/lib/pkgconfig/eventlog.pc
t/data/usr/lib/pkgconfig/libconfig.pc
t/data/usr/lib/pkgconfig/QtScript.pc
t/data/usr/lib/pkgconfig/videoproto.pc
t/data/usr/lib/pkgconfig/gmime-2.4.pc
t/data/usr/lib/pkgconfig/jinglesession-0.3.pc
t/data/usr/lib/pkgconfig/fftw3l.pc
t/data/usr/lib/pkgconfig/mutter-plugins.pc
t/data/usr/lib/pkgconfig/zzipwrap.pc
t/data/usr/lib/pkgconfig/libical.pc
t/data/usr/lib/pkgconfig/cairo-fc.pc
t/data/usr/lib/pkgconfig/gnome-vfs-2.0.pc
t/data/usr/lib/pkgconfig/libedata-book-1.2.pc
t/data/usr/lib/pkgconfig/libvbucket.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
