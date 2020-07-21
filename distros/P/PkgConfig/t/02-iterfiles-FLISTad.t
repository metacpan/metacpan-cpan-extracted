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
t/data/usr/lib/pkgconfig/cairomm-1.0.pc
t/data/usr/lib/pkgconfig/vorbisfile.pc
t/data/usr/lib/pkgconfig/xmu.pc
t/data/usr/lib/pkgconfig/speex.pc
t/data/usr/lib/pkgconfig/QtUiTools.pc
t/data/usr/lib/pkgconfig/damageproto.pc
t/data/usr/lib/pkgconfig/Qt.pc
t/data/usr/lib/pkgconfig/libpkcs15init.pc
t/data/usr/lib/pkgconfig/valgrind.pc
t/data/usr/lib/pkgconfig/libpulse-browse.pc
t/data/usr/lib/pkgconfig/libstartup-notification-1.0.pc
t/data/usr/lib/pkgconfig/gtkspell-2.0.pc
t/data/usr/lib/pkgconfig/xcb-shm.pc
t/data/usr/lib/pkgconfig/xulrunner-nss.pc
t/data/usr/lib/pkgconfig/xext.pc
t/data/usr/lib/pkgconfig/farsight2-0.10.pc
t/data/usr/lib/pkgconfig/gl.pc
t/data/usr/lib/pkgconfig/pyside.pc
t/data/usr/lib/pkgconfig/liblzma.pc
t/data/usr/lib/pkgconfig/cairo-pdf.pc
t/data/usr/lib/pkgconfig/pangox.pc
t/data/usr/lib/pkgconfig/zzip-zlib-config.pc
t/data/usr/lib/pkgconfig/libcroco-0.6.pc
t/data/usr/lib/pkgconfig/cairo-xlib.pc
t/data/usr/lib/pkgconfig/gdk-pixbuf-2.0.pc
t/data/usr/lib/pkgconfig/dmx.pc
t/data/usr/lib/pkgconfig/recordproto.pc
t/data/usr/lib/pkgconfig/libdrm.pc
t/data/usr/lib/pkgconfig/gnome-js-common.pc
t/data/usr/lib/pkgconfig/xdamage.pc
t/data/usr/lib/pkgconfig/libpci.pc
t/data/usr/lib/pkgconfig/jinglebase-0.3.pc
t/data/usr/lib/pkgconfig/mozilla-js.pc
t/data/usr/lib/pkgconfig/librtmp.pc
t/data/usr/lib/pkgconfig/libgnomekbdui.pc
t/data/usr/lib/pkgconfig/vorbis.pc
t/data/usr/lib/pkgconfig/gstreamer-tag-0.10.pc
t/data/usr/lib/pkgconfig/xcb-atom.pc
t/data/usr/lib/pkgconfig/qimageblitz.pc
t/data/usr/lib/pkgconfig/xv.pc
t/data/usr/lib/pkgconfig/QtXmlPatterns.pc
t/data/usr/lib/pkgconfig/gtk-vnc-1.0.pc
t/data/usr/lib/pkgconfig/libmpeg2.pc
t/data/usr/lib/pkgconfig/libavdevice.pc
t/data/usr/lib/pkgconfig/cairomm-xlib-1.0.pc
t/data/usr/lib/pkgconfig/libgadu.pc
t/data/usr/lib/pkgconfig/libnl-1.pc
t/data/usr/lib/pkgconfig/glibmm-2.4.pc
t/data/usr/lib/pkgconfig/deskbar-applet.pc
t/data/usr/lib/pkgconfig/gstreamer-dataprotocol-0.10.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
