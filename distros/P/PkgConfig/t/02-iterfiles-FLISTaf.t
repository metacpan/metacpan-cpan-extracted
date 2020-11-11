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
t/data/usr/lib/pkgconfig/libcdio.pc
t/data/usr/lib/pkgconfig/libmetacity-private.pc
t/data/usr/lib/pkgconfig/mono.pc
t/data/usr/lib/pkgconfig/gvnc-1.0.pc
t/data/usr/lib/pkgconfig/system.web.extensions.design_1.0.pc
t/data/usr/lib/pkgconfig/damageproto.pc
t/data/usr/lib/pkgconfig/avahi-glib.pc
t/data/usr/lib/pkgconfig/libxfcegui4-1.0.pc
t/data/usr/lib/pkgconfig/portaudio-2.0.pc
t/data/usr/lib/pkgconfig/gmime-2.4.pc
t/data/usr/lib/pkgconfig/vorbis.pc
t/data/usr/lib/pkgconfig/pangomm-1.4.pc
t/data/usr/lib/pkgconfig/thunarx-1.pc
t/data/usr/lib/pkgconfig/farsight2-0.10.pc
t/data/usr/lib/pkgconfig/gstreamer-floatcast-0.10.pc
t/data/usr/lib/pkgconfig/libpng12.pc
t/data/usr/lib/pkgconfig/hal.pc
t/data/usr/lib/pkgconfig/cairo.pc
t/data/usr/lib/pkgconfig/glu.pc
t/data/usr/lib/pkgconfig/gstreamer-interfaces-0.10.pc
t/data/usr/lib/pkgconfig/libxfce4util-1.0.pc
t/data/usr/lib/pkgconfig/libxine.pc
t/data/usr/lib/pkgconfig/imlib2.pc
t/data/usr/lib/pkgconfig/libdrm.pc
t/data/usr/lib/pkgconfig/cairo-png.pc
t/data/usr/lib/pkgconfig/libpostproc.pc
t/data/usr/lib/pkgconfig/speexdsp.pc
t/data/usr/lib/pkgconfig/libssl.pc
t/data/usr/lib/pkgconfig/fusion.pc
t/data/usr/lib/pkgconfig/libmutter-private.pc
t/data/usr/lib/pkgconfig/libdecoration.pc
t/data/usr/lib/pkgconfig/fribidi.pc
t/data/usr/lib/pkgconfig/gail.pc
t/data/usr/lib/pkgconfig/openssl.pc
t/data/usr/lib/pkgconfig/cairo-xlib-xrender.pc
t/data/usr/lib/pkgconfig/libavcore.pc
t/data/usr/lib/pkgconfig/libpkcs15init.pc
t/data/usr/lib/pkgconfig/ice.pc
t/data/usr/lib/pkgconfig/liboil-0.3.pc
t/data/usr/lib/pkgconfig/ext2fs.pc
t/data/usr/lib/pkgconfig/audiofile.pc
t/data/usr/lib/pkgconfig/QtDesigner.pc
t/data/usr/lib/pkgconfig/libmpg123.pc
t/data/usr/lib/pkgconfig/zlib.pc
t/data/usr/lib/pkgconfig/libffi.pc
t/data/usr/lib/pkgconfig/cogl-1.0.pc
t/data/usr/lib/pkgconfig/theoraenc.pc
t/data/usr/lib/pkgconfig/nunit.pc
t/data/usr/lib/pkgconfig/gst-python-0.10.pc
t/data/usr/lib/pkgconfig/IlmBase.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
