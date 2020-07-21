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
t/data/usr/lib/pkgconfig/freetype2.pc
t/data/usr/lib/pkgconfig/system.web.extensions_1.0.pc
t/data/usr/lib/pkgconfig/mozilla-gtkmozembed.pc
t/data/usr/lib/pkgconfig/printproto.pc
t/data/usr/lib/pkgconfig/alsa.pc
t/data/usr/lib/pkgconfig/libusbmuxd.pc
t/data/usr/lib/pkgconfig/libudev.pc
t/data/usr/lib/pkgconfig/QtHelp.pc
t/data/usr/lib/pkgconfig/cairo.pc
t/data/usr/lib/pkgconfig/xxf86misc.pc
t/data/usr/lib/pkgconfig/libscconf.pc
t/data/usr/lib/pkgconfig/fontutil.pc
t/data/usr/lib/pkgconfig/libsepol.pc
t/data/usr/lib/pkgconfig/wavpack.pc
t/data/usr/lib/pkgconfig/randrproto.pc
t/data/usr/lib/pkgconfig/gstreamer-sdp-0.10.pc
t/data/usr/lib/pkgconfig/libwnck-1.0.pc
t/data/usr/lib/pkgconfig/xt.pc
t/data/usr/lib/pkgconfig/camel-1.2.pc
t/data/usr/lib/pkgconfig/ao.pc
t/data/usr/lib/pkgconfig/poppler-cairo.pc
t/data/usr/lib/pkgconfig/avahi-glib.pc
t/data/usr/lib/pkgconfig/jinglep2p-0.3.pc
t/data/usr/lib/pkgconfig/slang.pc
t/data/usr/lib/pkgconfig/libselinux.pc
t/data/usr/lib/pkgconfig/gnome-mount.pc
t/data/usr/lib/pkgconfig/nautilus-sendto.pc
t/data/usr/lib/pkgconfig/libnautilus-extension.pc
t/data/usr/lib/pkgconfig/libxklavier.pc
t/data/usr/lib/pkgconfig/QtXml.pc
t/data/usr/lib/pkgconfig/pygobject-2.0.pc
t/data/usr/lib/pkgconfig/libxml++-2.6.pc
t/data/usr/lib/pkgconfig/system.web.extensions.design_1.0.pc
t/data/usr/lib/pkgconfig/libidn.pc
t/data/usr/lib/pkgconfig/gdk-x11-2.0.pc
t/data/usr/lib/pkgconfig/wmlib.pc
t/data/usr/lib/pkgconfig/thunarx-1.pc
t/data/usr/lib/pkgconfig/libgnomecanvas-2.0.pc
t/data/usr/lib/pkgconfig/gdk-2.0.pc
t/data/usr/lib/pkgconfig/upower-glib.pc
t/data/usr/lib/pkgconfig/notify-python.pc
t/data/usr/lib/pkgconfig/taglib.pc
t/data/usr/lib/pkgconfig/webkit-1.0.pc
t/data/usr/lib/pkgconfig/ortp.pc
t/data/usr/lib/pkgconfig/gtk+-unix-print-2.0.pc
t/data/usr/lib/pkgconfig/theora.pc
t/data/usr/lib/pkgconfig/xpm.pc
t/data/usr/lib/pkgconfig/xp.pc
t/data/usr/lib/pkgconfig/libgnomeprint-2.2.pc
t/data/usr/lib/pkgconfig/gstreamer-riff-0.10.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
