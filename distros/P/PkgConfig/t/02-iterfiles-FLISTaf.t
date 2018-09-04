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
t/data/usr/lib/pkgconfig/QtWebKit.pc
t/data/usr/lib/pkgconfig/gnome-vfs-2.0.pc
t/data/usr/lib/pkgconfig/libcdio_cdda.pc
t/data/usr/lib/pkgconfig/libdrm_nouveau.pc
t/data/usr/lib/pkgconfig/liboil-0.3.pc
t/data/usr/lib/pkgconfig/libcdio_paranoia.pc
t/data/usr/lib/pkgconfig/libvisual-0.4.pc
t/data/usr/lib/pkgconfig/ORBit-idl-2.0.pc
t/data/usr/lib/pkgconfig/randrproto.pc
t/data/usr/lib/pkgconfig/gstreamer-netbuffer-0.10.pc
t/data/usr/lib/pkgconfig/libgdiplus.pc
t/data/usr/lib/pkgconfig/cairomm-pdf-1.0.pc
t/data/usr/lib/pkgconfig/xkbui.pc
t/data/usr/lib/pkgconfig/dotnet.pc
t/data/usr/lib/pkgconfig/portaudio-2.0.pc
t/data/usr/lib/pkgconfig/liblzma.pc
t/data/usr/lib/pkgconfig/libstartup-notification-1.0.pc
t/data/usr/lib/pkgconfig/camel-1.2.pc
t/data/usr/lib/pkgconfig/pygobject-2.0.pc
t/data/usr/lib/pkgconfig/gdu.pc
t/data/usr/lib/pkgconfig/gmodule-export-2.0.pc
t/data/usr/lib/pkgconfig/devmapper.pc
t/data/usr/lib/pkgconfig/silc.pc
t/data/usr/lib/pkgconfig/kbproto.pc
t/data/usr/lib/pkgconfig/libxfce4util-1.0.pc
t/data/usr/lib/pkgconfig/Qt3Support.pc
t/data/usr/lib/pkgconfig/exo-0.3.pc
t/data/usr/lib/pkgconfig/x11.pc
t/data/usr/lib/pkgconfig/Qt.pc
t/data/usr/lib/pkgconfig/gstreamer-audio-0.10.pc
t/data/usr/lib/pkgconfig/gnome-desktop-2.0.pc
t/data/usr/lib/pkgconfig/libdv.pc
t/data/usr/lib/pkgconfig/bonobo-activation-2.0.pc
t/data/usr/lib/pkgconfig/xinerama.pc
t/data/usr/lib/pkgconfig/trapproto.pc
t/data/usr/lib/pkgconfig/openssl.pc
t/data/usr/lib/pkgconfig/xfce4-icon-theme-1.0.pc
t/data/usr/lib/pkgconfig/bluez.pc
t/data/usr/lib/pkgconfig/libexslt.pc
t/data/usr/lib/pkgconfig/xf86dgaproto.pc
t/data/usr/lib/pkgconfig/wrlib.pc
t/data/usr/lib/pkgconfig/libxml-2.0.pc
t/data/usr/lib/pkgconfig/alsaplayer.pc
t/data/usr/lib/pkgconfig/xp.pc
t/data/usr/lib/pkgconfig/libmpg123.pc
t/data/usr/lib/pkgconfig/libgnomekbdui.pc
t/data/usr/lib/pkgconfig/libcurl.pc
t/data/usr/lib/pkgconfig/nss.pc
t/data/usr/lib/pkgconfig/zzipwrap.pc
t/data/usr/lib/pkgconfig/OpenEXR.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
