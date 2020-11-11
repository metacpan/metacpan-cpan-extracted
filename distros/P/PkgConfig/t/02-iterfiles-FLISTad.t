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
t/data/usr/lib/pkgconfig/libgcj-4.4.pc
t/data/usr/lib/pkgconfig/libgnomeprintui-2.2.pc
t/data/usr/lib/pkgconfig/libIDL-2.0.pc
t/data/usr/lib/pkgconfig/opencore-amrwb.pc
t/data/usr/lib/pkgconfig/libavcodec.pc
t/data/usr/lib/pkgconfig/fontconfig.pc
t/data/usr/lib/pkgconfig/libagg.pc
t/data/usr/lib/pkgconfig/libxul-embedding.pc
t/data/usr/lib/pkgconfig/printproto.pc
t/data/usr/lib/pkgconfig/xfont.pc
t/data/usr/lib/pkgconfig/xmuu.pc
t/data/usr/lib/pkgconfig/exo-0.3.pc
t/data/usr/lib/pkgconfig/jinglep2p-0.3.pc
t/data/usr/lib/pkgconfig/system.web.mvc.pc
t/data/usr/lib/pkgconfig/libexslt.pc
t/data/usr/lib/pkgconfig/xcursor.pc
t/data/usr/lib/pkgconfig/resourceproto.pc
t/data/usr/lib/pkgconfig/libudev.pc
t/data/usr/lib/pkgconfig/qimageblitz.pc
t/data/usr/lib/pkgconfig/pangocairo.pc
t/data/usr/lib/pkgconfig/dvdnavmini.pc
t/data/usr/lib/pkgconfig/libgadu.pc
t/data/usr/lib/pkgconfig/shout.pc
t/data/usr/lib/pkgconfig/libnautilus-extension.pc
t/data/usr/lib/pkgconfig/libpci.pc
t/data/usr/lib/pkgconfig/libvisual-0.4.pc
t/data/usr/lib/pkgconfig/gtk-vnc-1.0.pc
t/data/usr/lib/pkgconfig/libavformat.pc
t/data/usr/lib/pkgconfig/NetworkManager.pc
t/data/usr/lib/pkgconfig/QtNetwork.pc
t/data/usr/lib/pkgconfig/sdl.pc
t/data/usr/lib/pkgconfig/xf86miscproto.pc
t/data/usr/lib/pkgconfig/directfb.pc
t/data/usr/lib/pkgconfig/cairo-ps.pc
t/data/usr/lib/pkgconfig/glib.pc
t/data/usr/lib/pkgconfig/unique-1.0.pc
t/data/usr/lib/pkgconfig/pciaccess.pc
t/data/usr/lib/pkgconfig/videoproto.pc
t/data/usr/lib/pkgconfig/meanwhile.pc
t/data/usr/lib/pkgconfig/libpulse-browse.pc
t/data/usr/lib/pkgconfig/gstreamer-sdp-0.10.pc
t/data/usr/lib/pkgconfig/fontenc.pc
t/data/usr/lib/pkgconfig/libsqueeze-0.2.pc
t/data/usr/lib/pkgconfig/mozilla-gtkmozembed.pc
t/data/usr/lib/pkgconfig/libkms.pc
t/data/usr/lib/pkgconfig/libxul.pc
t/data/usr/lib/pkgconfig/gnome-js-common.pc
t/data/usr/lib/pkgconfig/libart-2.0.pc
t/data/usr/lib/pkgconfig/utouch-grail.pc
t/data/usr/lib/pkgconfig/xft.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
