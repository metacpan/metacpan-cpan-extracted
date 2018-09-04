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
t/data/usr/lib/pkgconfig/xcb-shm.pc
t/data/usr/lib/pkgconfig/dri.pc
t/data/usr/lib/pkgconfig/ORBit-imodule-2.0.pc
t/data/usr/lib/pkgconfig/libyahoo2.pc
t/data/usr/lib/pkgconfig/gudev-1.0.pc
t/data/usr/lib/pkgconfig/fusion.pc
t/data/usr/lib/pkgconfig/cogl-gl-1.0.pc
t/data/usr/lib/pkgconfig/fontconfig.pc
t/data/usr/lib/pkgconfig/libutouch-geis.pc
t/data/usr/lib/pkgconfig/gstreamer-video-0.10.pc
t/data/usr/lib/pkgconfig/libexchange-storage-1.2.pc
t/data/usr/lib/pkgconfig/xv.pc
t/data/usr/lib/pkgconfig/gssdp-1.0.pc
t/data/usr/lib/pkgconfig/scrnsaverproto.pc
t/data/usr/lib/pkgconfig/cairo-fc.pc
t/data/usr/lib/pkgconfig/compositeproto.pc
t/data/usr/lib/pkgconfig/libecal-1.2.pc
t/data/usr/lib/pkgconfig/libv4lconvert.pc
t/data/usr/lib/pkgconfig/pilot-link.pc
t/data/usr/lib/pkgconfig/libpulse-simple.pc
t/data/usr/lib/pkgconfig/libv4l2.pc
t/data/usr/lib/pkgconfig/mjpegtools.pc
t/data/usr/lib/pkgconfig/jinglebase-0.3.pc
t/data/usr/lib/pkgconfig/ORBit.pc
t/data/usr/lib/pkgconfig/cairo-ps.pc
t/data/usr/lib/pkgconfig/libgtop-2.0.pc
t/data/usr/lib/pkgconfig/cally-1.0.pc
t/data/usr/lib/pkgconfig/gnome-keyring-1.pc
t/data/usr/lib/pkgconfig/libmutter-private.pc
t/data/usr/lib/pkgconfig/libkms.pc
t/data/usr/lib/pkgconfig/libpng.pc
t/data/usr/lib/pkgconfig/gstreamer-controller-0.10.pc
t/data/usr/lib/pkgconfig/cairo-tee.pc
t/data/usr/lib/pkgconfig/libxml++-1.0.pc
t/data/usr/lib/pkgconfig/zzipmmapped.pc
t/data/usr/lib/pkgconfig/libxfcegui4-1.0.pc
t/data/usr/lib/pkgconfig/libxklavier.pc
t/data/usr/lib/pkgconfig/devkit-power-gobject.pc
t/data/usr/lib/pkgconfig/libdrm.pc
t/data/usr/lib/pkgconfig/IlmBase.pc
t/data/usr/lib/pkgconfig/xf86bigfontproto.pc
t/data/usr/lib/pkgconfig/libbonobo-2.0.pc
t/data/usr/lib/pkgconfig/ice.pc
t/data/usr/lib/pkgconfig/libgnomeui-2.0.pc
t/data/usr/lib/pkgconfig/libmpeg2.pc
t/data/usr/lib/pkgconfig/cairo-svg.pc
t/data/usr/lib/pkgconfig/QtScript.pc
t/data/usr/lib/pkgconfig/polkit-gtk-1.pc
t/data/usr/lib/pkgconfig/gstreamer-floatcast-0.10.pc
t/data/usr/lib/pkgconfig/imlib2.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
