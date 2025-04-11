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
t/data/usr/lib/pkgconfig/libcdio_cdda.pc
t/data/usr/lib/pkgconfig/uuid.pc
t/data/usr/lib/pkgconfig/libnfsidmap.pc
t/data/usr/lib/pkgconfig/libpcre.pc
t/data/usr/lib/pkgconfig/autoopts.pc
t/data/usr/lib/pkgconfig/xxf86vm.pc
t/data/usr/lib/pkgconfig/gstreamer-fft-0.10.pc
t/data/usr/lib/pkgconfig/dotnet.pc
t/data/usr/lib/pkgconfig/libpng.pc
t/data/usr/lib/pkgconfig/libxslt.pc
t/data/usr/lib/pkgconfig/cairomm-ft-1.0.pc
t/data/usr/lib/pkgconfig/libavc1394.pc
t/data/usr/lib/pkgconfig/mono-nunit.pc
t/data/usr/lib/pkgconfig/fuse.pc
t/data/usr/lib/pkgconfig/xf86bigfontproto.pc
t/data/usr/lib/pkgconfig/fribidi.pc
t/data/usr/lib/pkgconfig/gtk+-2.0.pc
t/data/usr/lib/pkgconfig/exo-hal-0.3.pc
t/data/usr/lib/pkgconfig/xulrunner-nspr.pc
t/data/usr/lib/pkgconfig/gtkmm-2.4.pc
t/data/usr/lib/pkgconfig/cairo-xcb.pc
t/data/usr/lib/pkgconfig/xineramaproto.pc
t/data/usr/lib/pkgconfig/python2.5/gst-python-0.10.pc
t/data/usr/lib/pkgconfig/python2.5/pygtk-2.0.pc
t/data/usr/lib/pkgconfig/python2.6/gst-python-0.10.pc
t/data/usr/lib/pkgconfig/python2.6/pygtk-2.0.pc
t/data/usr/share/pkgconfig/xml2po.pc
t/data/usr/share/pkgconfig/xbitmaps.pc
t/data/usr/share/pkgconfig/shared-mime-info.pc
t/data/usr/share/pkgconfig/gnome-doc-utils.pc
t/data/usr/share/pkgconfig/gnome-mime-data-2.0.pc
t/data/usr/share/pkgconfig/gnome-icon-theme.pc
t/data/usr/share/pkgconfig/glproto.pc
t/data/usr/share/pkgconfig/inputproto.pc
t/data/usr/share/pkgconfig/lxc.pc
t/data/usr/share/pkgconfig/iso-codes.pc
t/data/usr/share/pkgconfig/usbutils.pc
t/data/usr/share/pkgconfig/udisks.pc
t/data/usr/share/pkgconfig/xcb-proto.pc
t/data/usr/share/pkgconfig/gtk-doc.pc
t/data/usr/share/pkgconfig/xorg-sgml-doctools.pc
t/data/usr/share/pkgconfig/pthread-stubs.pc
t/data/usr/share/pkgconfig/fixesproto.pc
t/data/usr/share/pkgconfig/xextproto.pc
t/data/usr/share/pkgconfig/m17n-db.pc
t/data/usr/share/pkgconfig/xorg-macros.pc
t/data/usr/share/pkgconfig/xtrans.pc
t/data/usr/share/pkgconfig/icon-naming-utils.pc
t/data/usr/share/pkgconfig/shared-desktop-ontologies.pc
t/data/usr/share/pkgconfig/udev.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
