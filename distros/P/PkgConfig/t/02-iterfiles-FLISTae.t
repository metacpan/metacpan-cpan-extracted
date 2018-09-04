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
t/data/usr/lib/pkgconfig/libopensc.pc
t/data/usr/lib/pkgconfig/gconf-2.0.pc
t/data/usr/lib/pkgconfig/NetworkManager.pc
t/data/usr/lib/pkgconfig/gtk+-unix-print-2.0.pc
t/data/usr/lib/pkgconfig/webkit-1.0.pc
t/data/usr/lib/pkgconfig/cecil.pc
t/data/usr/lib/pkgconfig/libplist.pc
t/data/usr/lib/pkgconfig/gstreamer-check-0.10.pc
t/data/usr/lib/pkgconfig/sdl.pc
t/data/usr/lib/pkgconfig/libIDL.pc
t/data/usr/lib/pkgconfig/xmu.pc
t/data/usr/lib/pkgconfig/gnome-screensaver.pc
t/data/usr/lib/pkgconfig/cairo-xcb.pc
t/data/usr/lib/pkgconfig/dmxproto.pc
t/data/usr/lib/pkgconfig/gnome-mount.pc
t/data/usr/lib/pkgconfig/libglade-2.0.pc
t/data/usr/lib/pkgconfig/gdk-pixbuf-xlib-2.0.pc
t/data/usr/lib/pkgconfig/theora.pc
t/data/usr/lib/pkgconfig/xf86miscproto.pc
t/data/usr/lib/pkgconfig/deskbar-applet.pc
t/data/usr/lib/pkgconfig/xxf86vm.pc
t/data/usr/lib/pkgconfig/openal.pc
t/data/usr/lib/pkgconfig/gnutls.pc
t/data/usr/lib/pkgconfig/poppler.pc
t/data/usr/lib/pkgconfig/pygtk-2.0.pc
t/data/usr/lib/pkgconfig/gstreamer-tag-0.10.pc
t/data/usr/lib/pkgconfig/libpulse-browse.pc
t/data/usr/lib/pkgconfig/valgrind.pc
t/data/usr/lib/pkgconfig/gamin.pc
t/data/usr/lib/pkgconfig/direct.pc
t/data/usr/lib/pkgconfig/libfs.pc
t/data/usr/lib/pkgconfig/cairomm-png-1.0.pc
t/data/usr/lib/pkgconfig/gkrellm.pc
t/data/usr/lib/pkgconfig/QtMultimedia.pc
t/data/usr/lib/pkgconfig/libgssglue.pc
t/data/usr/lib/pkgconfig/flac.pc
t/data/usr/lib/pkgconfig/xaw7.pc
t/data/usr/lib/pkgconfig/talloc.pc
t/data/usr/lib/pkgconfig/vorbisfile.pc
t/data/usr/lib/pkgconfig/system.web.extensions_1.0.pc
t/data/usr/lib/pkgconfig/libnotify.pc
t/data/usr/lib/pkgconfig/libpkcs15init.pc
t/data/usr/lib/pkgconfig/pyside.pc
t/data/usr/lib/pkgconfig/gstreamer-dataprotocol-0.10.pc
t/data/usr/lib/pkgconfig/ortp.pc
t/data/usr/lib/pkgconfig/QtCore.pc
t/data/usr/lib/pkgconfig/wmlib.pc
t/data/usr/lib/pkgconfig/gstreamer-app-0.10.pc
t/data/usr/lib/pkgconfig/utouch-grail.pc
t/data/usr/lib/pkgconfig/libcroco-0.6.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
