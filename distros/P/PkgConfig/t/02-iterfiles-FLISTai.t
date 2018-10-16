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
t/data/usr/lib/pkgconfig/QtSql.pc
t/data/usr/lib/pkgconfig/mono.web.pc
t/data/usr/lib/pkgconfig/cairo-ps.pc
t/data/usr/lib/pkgconfig/gnome-js-common.pc
t/data/usr/lib/pkgconfig/polkit-gobject-1.pc
t/data/usr/lib/pkgconfig/autoopts.pc
t/data/usr/lib/pkgconfig/libusb-1.0.pc
t/data/usr/lib/pkgconfig/gstreamer-cdda-0.10.pc
t/data/usr/lib/pkgconfig/unique-1.0.pc
t/data/usr/lib/pkgconfig/jinglep2p-0.3.pc
t/data/usr/lib/pkgconfig/dvdnavmini.pc
t/data/usr/lib/pkgconfig/avahi-glib.pc
t/data/usr/lib/pkgconfig/libavcodec.pc
t/data/usr/lib/pkgconfig/cairo-tee.pc
t/data/usr/lib/pkgconfig/caca.pc
t/data/usr/lib/pkgconfig/fusion.pc
t/data/usr/lib/pkgconfig/slang.pc
t/data/usr/lib/pkgconfig/QtHelp.pc
t/data/usr/lib/pkgconfig/cairomm-ps-1.0.pc
t/data/usr/lib/pkgconfig/libsoup-2.4.pc
t/data/usr/lib/pkgconfig/QtCLucene.pc
t/data/usr/lib/pkgconfig/portaudio-2.0.pc
t/data/usr/lib/pkgconfig/orc-0.4.pc
t/data/usr/lib/pkgconfig/x264.pc
t/data/usr/lib/pkgconfig/libselinux.pc
t/data/usr/lib/pkgconfig/xt.pc
t/data/usr/lib/pkgconfig/e2p.pc
t/data/usr/lib/pkgconfig/dotnet.pc
t/data/usr/lib/pkgconfig/libutouch-geis.pc
t/data/usr/lib/pkgconfig/libgdiplus.pc
t/data/usr/lib/pkgconfig/libnautilus-extension.pc
t/data/usr/lib/pkgconfig/xcb-aux.pc
t/data/usr/lib/pkgconfig/xmu.pc
t/data/usr/lib/pkgconfig/polkit.pc
t/data/usr/lib/pkgconfig/portaudiocpp.pc
t/data/usr/lib/pkgconfig/libgcj-4.4.pc
t/data/usr/lib/pkgconfig/libIDL-2.0.pc
t/data/usr/lib/pkgconfig/cecil.pc
t/data/usr/lib/pkgconfig/libvbucket.pc
t/data/usr/lib/pkgconfig/xf86driproto.pc
t/data/usr/lib/pkgconfig/vorbisfile.pc
t/data/usr/lib/pkgconfig/gtk-vnc-1.0.pc
t/data/usr/lib/pkgconfig/libxslt.pc
t/data/usr/lib/pkgconfig/libnotify.pc
t/data/usr/lib/pkgconfig/xdamage.pc
t/data/usr/lib/pkgconfig/libgtop-2.0.pc
t/data/usr/lib/pkgconfig/libagg.pc
t/data/usr/lib/pkgconfig/libyahoo2.pc
t/data/usr/lib/pkgconfig/xaw7.pc
t/data/usr/lib/pkgconfig/QtNetwork.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
