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
t/data/usr/lib/pkgconfig/autoopts.pc
t/data/usr/lib/pkgconfig/xulrunner-nspr.pc
t/data/usr/lib/pkgconfig/libdts.pc
t/data/usr/lib/pkgconfig/libxul-unstable.pc
t/data/usr/lib/pkgconfig/libmpeg2convert.pc
t/data/usr/lib/pkgconfig/libgcj-4.4.pc
t/data/usr/lib/pkgconfig/freetype2.pc
t/data/usr/lib/pkgconfig/xcb-aux.pc
t/data/usr/lib/pkgconfig/QtXmlPatterns.pc
t/data/usr/lib/pkgconfig/libgnomeprint-2.2.pc
t/data/usr/lib/pkgconfig/xxf86misc.pc
t/data/usr/lib/pkgconfig/hal.pc
t/data/usr/lib/pkgconfig/libsysfs.pc
t/data/usr/lib/pkgconfig/libgnomecanvas-2.0.pc
t/data/usr/lib/pkgconfig/vte.pc
t/data/usr/lib/pkgconfig/libsoup-2.4.pc
t/data/usr/lib/pkgconfig/glibmm-2.4.pc
t/data/usr/lib/pkgconfig/cairomm-1.0.pc
t/data/usr/lib/pkgconfig/libusb.pc
t/data/usr/lib/pkgconfig/libavcodec.pc
t/data/usr/lib/pkgconfig/libnfsidmap.pc
t/data/usr/lib/pkgconfig/xres.pc
t/data/usr/lib/pkgconfig/xt.pc
t/data/usr/lib/pkgconfig/libavdevice.pc
t/data/usr/lib/pkgconfig/libsoup-gnome-2.4.pc
t/data/usr/lib/pkgconfig/libcdio.pc
t/data/usr/lib/pkgconfig/libpng12.pc
t/data/usr/lib/pkgconfig/fribidi.pc
t/data/usr/lib/pkgconfig/hal-storage.pc
t/data/usr/lib/pkgconfig/directfb-internal.pc
t/data/usr/lib/pkgconfig/gtk+-x11-2.0.pc
t/data/usr/lib/pkgconfig/nunit.pc
t/data/usr/lib/pkgconfig/notify-python.pc
t/data/usr/lib/pkgconfig/libgpod-1.0.pc
t/data/usr/lib/pkgconfig/fftw3.pc
t/data/usr/lib/pkgconfig/libxul-embedding.pc
t/data/usr/lib/pkgconfig/zzip-zlib-config.pc
t/data/usr/lib/pkgconfig/libdca.pc
t/data/usr/lib/pkgconfig/xineramaproto.pc
t/data/usr/lib/pkgconfig/shout.pc
t/data/usr/lib/pkgconfig/mono-cairo.pc
t/data/usr/lib/pkgconfig/mono.pc
t/data/usr/lib/pkgconfig/wavpack.pc
t/data/usr/lib/pkgconfig/wcf.pc
t/data/usr/lib/pkgconfig/libexif.pc
t/data/usr/lib/pkgconfig/libsqueeze-0.2.pc
t/data/usr/lib/pkgconfig/gstreamer-pbutils-0.10.pc
t/data/usr/lib/pkgconfig/caca.pc
t/data/usr/lib/pkgconfig/fontsproto.pc
t/data/usr/lib/pkgconfig/gmodule-no-export-2.0.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
