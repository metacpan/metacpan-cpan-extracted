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
t/data/usr/lib/pkgconfig/libyahoo2.pc
t/data/usr/lib/pkgconfig/libpulse-simple.pc
t/data/usr/lib/pkgconfig/xkbfile.pc
t/data/usr/lib/pkgconfig/libffi.pc
t/data/usr/lib/pkgconfig/libavutil.pc
t/data/usr/lib/pkgconfig/zlib.pc
t/data/usr/lib/pkgconfig/sofia-sip-ua.pc
t/data/usr/lib/pkgconfig/directfb.pc
t/data/usr/lib/pkgconfig/caca.pc
t/data/usr/lib/pkgconfig/libfs.pc
t/data/usr/lib/pkgconfig/NetworkManager.pc
t/data/usr/lib/pkgconfig/unique-1.0.pc
t/data/usr/lib/pkgconfig/libxine.pc
t/data/usr/lib/pkgconfig/ice.pc
t/data/usr/lib/pkgconfig/tracker.pc
t/data/usr/lib/pkgconfig/libdv.pc
t/data/usr/lib/pkgconfig/liboil-0.3.pc
t/data/usr/lib/pkgconfig/libgnomeprintui-2.2.pc
t/data/usr/lib/pkgconfig/pangocairo.pc
t/data/usr/lib/pkgconfig/gstreamer-floatcast-0.10.pc
t/data/usr/lib/pkgconfig/xi.pc
t/data/usr/lib/pkgconfig/libegroupwise-1.2.pc
t/data/usr/lib/pkgconfig/mono-cairo.pc
t/data/usr/lib/pkgconfig/xcomposite.pc
t/data/usr/lib/pkgconfig/libcap-ng.pc
t/data/usr/lib/pkgconfig/libmpg123.pc
t/data/usr/lib/pkgconfig/enchant.pc
t/data/usr/lib/pkgconfig/nice.pc
t/data/usr/lib/pkgconfig/gmodule-export-2.0.pc
t/data/usr/lib/pkgconfig/mozilla-gtkmozembed-embedding.pc
t/data/usr/lib/pkgconfig/xres.pc
t/data/usr/lib/pkgconfig/libagg.pc
t/data/usr/lib/pkgconfig/xcb-event.pc
t/data/usr/lib/pkgconfig/dotnet35.pc
t/data/usr/lib/pkgconfig/xft.pc
t/data/usr/lib/pkgconfig/com_err.pc
t/data/usr/lib/pkgconfig/wrlib.pc
t/data/usr/lib/pkgconfig/libusb.pc
t/data/usr/lib/pkgconfig/libssl.pc
t/data/usr/lib/pkgconfig/cairomm-png-1.0.pc
t/data/usr/lib/pkgconfig/gweather.pc
t/data/usr/lib/pkgconfig/cairo-png.pc
t/data/usr/lib/pkgconfig/Qt3Support.pc
t/data/usr/lib/pkgconfig/alsaplayer.pc
t/data/usr/lib/pkgconfig/openal.pc
t/data/usr/lib/pkgconfig/SDL_image.pc
t/data/usr/lib/pkgconfig/silc.pc
t/data/usr/lib/pkgconfig/pygtk-2.0.pc
t/data/usr/lib/pkgconfig/vorbisenc.pc
t/data/usr/lib/pkgconfig/renderproto.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
