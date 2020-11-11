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
t/data/usr/lib/pkgconfig/cairo-svg.pc
t/data/usr/lib/pkgconfig/libgphoto2.pc
t/data/usr/lib/pkgconfig/GraphicsMagickWand.pc
t/data/usr/lib/pkgconfig/xdmcp.pc
t/data/usr/lib/pkgconfig/libegroupwise-1.2.pc
t/data/usr/lib/pkgconfig/mad.pc
t/data/usr/lib/pkgconfig/gnutls.pc
t/data/usr/lib/pkgconfig/dotnet.pc
t/data/usr/lib/pkgconfig/dmx.pc
t/data/usr/lib/pkgconfig/libidn.pc
t/data/usr/lib/pkgconfig/gobject-introspection-1.0.pc
t/data/usr/lib/pkgconfig/GraphicsMagick++.pc
t/data/usr/lib/pkgconfig/libfs.pc
t/data/usr/lib/pkgconfig/xfce4-icon-theme-1.0.pc
t/data/usr/lib/pkgconfig/gkrellm.pc
t/data/usr/lib/pkgconfig/xcb-util.pc
t/data/usr/lib/pkgconfig/vorbisfile.pc
t/data/usr/lib/pkgconfig/giomm-2.4.pc
t/data/usr/lib/pkgconfig/gstreamer-0.10.pc
t/data/usr/lib/pkgconfig/GraphicsMagick.pc
t/data/usr/lib/pkgconfig/clutter-glx-1.0.pc
t/data/usr/lib/pkgconfig/thunar-vfs-1.pc
t/data/usr/lib/pkgconfig/trapproto.pc
t/data/usr/lib/pkgconfig/xp.pc
t/data/usr/lib/pkgconfig/zzipmmapped.pc
t/data/usr/lib/pkgconfig/bigreqsproto.pc
t/data/usr/lib/pkgconfig/tre.pc
t/data/usr/lib/pkgconfig/libproxy-1.0.pc
t/data/usr/lib/pkgconfig/OpenEXR.pc
t/data/usr/lib/pkgconfig/gweather.pc
t/data/usr/lib/pkgconfig/libgnome-2.0.pc
t/data/usr/lib/pkgconfig/polkit.pc
t/data/usr/lib/pkgconfig/sndfile.pc
t/data/usr/lib/pkgconfig/xaw7.pc
t/data/usr/lib/pkgconfig/pilot-link.pc
t/data/usr/lib/pkgconfig/ORBit-idl-2.0.pc
t/data/usr/lib/pkgconfig/valgrind.pc
t/data/usr/lib/pkgconfig/caca++.pc
t/data/usr/lib/pkgconfig/gmodule-2.0.pc
t/data/usr/lib/pkgconfig/gdkmm-2.4.pc
t/data/usr/lib/pkgconfig/utouch-evemu.pc
t/data/usr/lib/pkgconfig/wavpack.pc
t/data/usr/lib/pkgconfig/libmpeg2.pc
t/data/usr/lib/pkgconfig/libusb.pc
t/data/usr/lib/pkgconfig/gnome-keyring-1.pc
t/data/usr/lib/pkgconfig/silcclient.pc
t/data/usr/lib/pkgconfig/taglib.pc
t/data/usr/lib/pkgconfig/xv.pc
t/data/usr/lib/pkgconfig/system.web.extensions_1.0.pc
t/data/usr/lib/pkgconfig/libpng.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
