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
t/data/usr/lib/pkgconfig/x11.pc
t/data/usr/lib/pkgconfig/openssl.pc
t/data/usr/lib/pkgconfig/libexchange-storage-1.2.pc
t/data/usr/lib/pkgconfig/libsysfs.pc
t/data/usr/lib/pkgconfig/pango.pc
t/data/usr/lib/pkgconfig/gvnc-1.0.pc
t/data/usr/lib/pkgconfig/QtDesigner.pc
t/data/usr/lib/pkgconfig/directfb-internal.pc
t/data/usr/lib/pkgconfig/gio-unix-2.0.pc
t/data/usr/lib/pkgconfig/dirac.pc
t/data/usr/lib/pkgconfig/python-2.7.pc
t/data/usr/lib/pkgconfig/cairo-png.pc
t/data/usr/lib/pkgconfig/valgrind.pc
t/data/usr/lib/pkgconfig/libecal-1.2.pc
t/data/usr/lib/pkgconfig/gdk-pixbuf-xlib-2.0.pc
t/data/usr/lib/pkgconfig/sigc++-2.0.pc
t/data/usr/lib/pkgconfig/zziplib.pc
t/data/usr/lib/pkgconfig/dotnet35.pc
t/data/usr/lib/pkgconfig/camel-1.2.pc
t/data/usr/lib/pkgconfig/libdecoration.pc
t/data/usr/lib/pkgconfig/libgssglue.pc
t/data/usr/lib/pkgconfig/libcroco-0.6.pc
t/data/usr/lib/pkgconfig/gtk+-unix-print-2.0.pc
t/data/usr/lib/pkgconfig/libidn.pc
t/data/usr/lib/pkgconfig/theoradec.pc
t/data/usr/lib/pkgconfig/xv.pc
t/data/usr/lib/pkgconfig/libcdio.pc
t/data/usr/lib/pkgconfig/damageproto.pc
t/data/usr/lib/pkgconfig/glitz-glx.pc
t/data/usr/lib/pkgconfig/dmxproto.pc
t/data/usr/lib/pkgconfig/gl.pc
t/data/usr/lib/pkgconfig/glu.pc
t/data/usr/lib/pkgconfig/gnome-vfs-2.0.pc
t/data/usr/lib/pkgconfig/gdk-x11-2.0.pc
t/data/usr/lib/pkgconfig/wavpack.pc
t/data/usr/lib/pkgconfig/libmpeg2convert.pc
t/data/usr/lib/pkgconfig/xcb-shm.pc
t/data/usr/lib/pkgconfig/ORBit-CosNaming-2.0.pc
t/data/usr/lib/pkgconfig/lcms.pc
t/data/usr/lib/pkgconfig/libdv.pc
t/data/usr/lib/pkgconfig/xxf86dga.pc
t/data/usr/lib/pkgconfig/wcf.pc
t/data/usr/lib/pkgconfig/libxfcegui4-1.0.pc
t/data/usr/lib/pkgconfig/speex.pc
t/data/usr/lib/pkgconfig/atkmm-1.6.pc
t/data/usr/lib/pkgconfig/xcmiscproto.pc
t/data/usr/lib/pkgconfig/libgnomeprint-2.2.pc
t/data/usr/lib/pkgconfig/libexif.pc
t/data/usr/lib/pkgconfig/libdrm_intel.pc
t/data/usr/lib/pkgconfig/resourceproto.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
