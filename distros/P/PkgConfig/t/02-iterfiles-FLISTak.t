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
t/data/usr/lib/pkgconfig/xv.pc
t/data/usr/lib/pkgconfig/xvmc.pc
t/data/usr/lib/pkgconfig/xxf86dga.pc
t/data/usr/lib/pkgconfig/xxf86misc.pc
t/data/usr/lib/pkgconfig/xxf86vm.pc
t/data/usr/lib/pkgconfig/zlib.pc
t/data/usr/lib/pkgconfig/zzip-zlib-config.pc
t/data/usr/lib/pkgconfig/zzipfseeko.pc
t/data/usr/lib/pkgconfig/zziplib.pc
t/data/usr/lib/pkgconfig/zzipmmapped.pc
t/data/usr/lib/pkgconfig/zzipwrap.pc
t/data/usr/lib/pkgconfig/python2.5/gst-python-0.10.pc
t/data/usr/lib/pkgconfig/python2.5/pygtk-2.0.pc
t/data/usr/lib/pkgconfig/python2.6/gst-python-0.10.pc
t/data/usr/lib/pkgconfig/python2.6/pygtk-2.0.pc
t/data/usr/local/lib/pkgconfig/cmph.pc
t/data/usr/local/lib/pkgconfig/codeblocks.pc
t/data/usr/local/lib/pkgconfig/dri.pc
t/data/usr/local/lib/pkgconfig/emeraldengine.pc
t/data/usr/local/lib/pkgconfig/gl.pc
t/data/usr/local/lib/pkgconfig/glu.pc
t/data/usr/local/lib/pkgconfig/libdivecomputer.pc
t/data/usr/local/lib/pkgconfig/libvirt.pc
t/data/usr/local/lib/pkgconfig/termkey.pc
t/data/usr/local/share/pkgconfig/bcop.pc
t/data/usr/local/share/pkgconfig/shared-mime-info.pc
t/data/usr/share/pkgconfig/dri2proto.pc
t/data/usr/share/pkgconfig/fixesproto.pc
t/data/usr/share/pkgconfig/glproto.pc
t/data/usr/share/pkgconfig/gnome-doc-utils.pc
t/data/usr/share/pkgconfig/gnome-icon-theme.pc
t/data/usr/share/pkgconfig/gnome-mime-data-2.0.pc
t/data/usr/share/pkgconfig/gtk-doc.pc
t/data/usr/share/pkgconfig/icon-naming-utils.pc
t/data/usr/share/pkgconfig/inputproto.pc
t/data/usr/share/pkgconfig/iso-codes.pc
t/data/usr/share/pkgconfig/libtut.pc
t/data/usr/share/pkgconfig/lxc.pc
t/data/usr/share/pkgconfig/m17n-db.pc
t/data/usr/share/pkgconfig/pthread-stubs.pc
t/data/usr/share/pkgconfig/shared-desktop-ontologies.pc
t/data/usr/share/pkgconfig/shared-mime-info.pc
t/data/usr/share/pkgconfig/udev.pc
t/data/usr/share/pkgconfig/udisks.pc
t/data/usr/share/pkgconfig/usbutils.pc
t/data/usr/share/pkgconfig/xbitmaps.pc
t/data/usr/share/pkgconfig/xcb-proto.pc
t/data/usr/share/pkgconfig/xextproto.pc
t/data/usr/share/pkgconfig/xml2po.pc
t/data/usr/share/pkgconfig/xorg-macros.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
