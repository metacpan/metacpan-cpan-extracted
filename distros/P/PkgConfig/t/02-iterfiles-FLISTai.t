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
t/data/usr/lib/pkgconfig/pangomm-1.4.pc
t/data/usr/lib/pkgconfig/esound.pc
t/data/usr/lib/pkgconfig/xulrunner-nss.pc
t/data/usr/lib/pkgconfig/fontcacheproto.pc
t/data/usr/lib/pkgconfig/QtDesignerComponents.pc
t/data/usr/lib/pkgconfig/gtk+-2.0.pc
t/data/usr/lib/pkgconfig/gail.pc
t/data/usr/lib/pkgconfig/mtdev.pc
t/data/usr/lib/pkgconfig/pygtkglext-1.0.pc
t/data/usr/lib/pkgconfig/recordproto.pc
t/data/usr/lib/pkgconfig/libbonoboui-2.0.pc
t/data/usr/lib/pkgconfig/libusbmuxd.pc
t/data/usr/lib/pkgconfig/gmime-2.4.pc
t/data/usr/lib/pkgconfig/xmuu.pc
t/data/usr/lib/pkgconfig/theoradec.pc
t/data/usr/lib/pkgconfig/gnome-window-settings-2.0.pc
t/data/usr/lib/pkgconfig/libavcore.pc
t/data/usr/lib/pkgconfig/gstreamer-interfaces-0.10.pc
t/data/usr/lib/pkgconfig/atk.pc
t/data/usr/lib/pkgconfig/videoproto.pc
t/data/usr/lib/pkgconfig/system.web.mvc.pc
t/data/usr/lib/pkgconfig/exempi-2.0.pc
t/data/usr/lib/pkgconfig/fontenc.pc
t/data/usr/lib/pkgconfig/gio-2.0.pc
t/data/usr/lib/pkgconfig/libcrypto.pc
t/data/usr/lib/pkgconfig/xvmc.pc
t/data/usr/lib/pkgconfig/gdkmm-2.4.pc
t/data/usr/lib/pkgconfig/clutter-1.0.pc
t/data/usr/lib/pkgconfig/gmodule-2.0.pc
t/data/usr/lib/pkgconfig/gupnp-1.0.pc
t/data/usr/lib/pkgconfig/ao.pc
t/data/usr/lib/pkgconfig/gobject-2.0.pc
t/data/usr/lib/pkgconfig/libvbucket.pc
t/data/usr/lib/pkgconfig/bigreqsproto.pc
t/data/usr/lib/pkgconfig/pciaccess.pc
t/data/usr/lib/pkgconfig/mozilla-plugin.pc
t/data/usr/lib/pkgconfig/clutter-x11-1.0.pc
t/data/usr/lib/pkgconfig/pangox.pc
t/data/usr/lib/pkgconfig/jinglep2p-0.3.pc
t/data/usr/lib/pkgconfig/QtGui.pc
t/data/usr/lib/pkgconfig/gstreamer-base-0.10.pc
t/data/usr/lib/pkgconfig/xcb-event.pc
t/data/usr/lib/pkgconfig/mozilla-gtkmozembed-embedding.pc
t/data/usr/lib/pkgconfig/xdamage.pc
t/data/usr/lib/pkgconfig/poppler-cairo.pc
t/data/usr/lib/pkgconfig/libpostproc.pc
t/data/usr/lib/pkgconfig/mozilla-js.pc
t/data/usr/lib/pkgconfig/libpcrecpp.pc
t/data/usr/lib/pkgconfig/libgadu.pc
t/data/usr/lib/pkgconfig/GraphicsMagickWand.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
