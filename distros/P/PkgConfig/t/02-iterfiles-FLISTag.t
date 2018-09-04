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
t/data/usr/lib/pkgconfig/libnautilus-extension.pc
t/data/usr/lib/pkgconfig/QtDesigner.pc
t/data/usr/lib/pkgconfig/fftw3f.pc
t/data/usr/lib/pkgconfig/enchant.pc
t/data/usr/lib/pkgconfig/cairo.pc
t/data/usr/lib/pkgconfig/lcms.pc
t/data/usr/lib/pkgconfig/QtDBus.pc
t/data/usr/lib/pkgconfig/xcb-atom.pc
t/data/usr/lib/pkgconfig/QtSvg.pc
t/data/usr/lib/pkgconfig/xfixes.pc
t/data/usr/lib/pkgconfig/libpci.pc
t/data/usr/lib/pkgconfig/thunar-vfs-1.pc
t/data/usr/lib/pkgconfig/SDL_image.pc
t/data/usr/lib/pkgconfig/cairo-xlib-xrender.pc
t/data/usr/lib/pkgconfig/xi.pc
t/data/usr/lib/pkgconfig/gdk-2.0.pc
t/data/usr/lib/pkgconfig/gthread.pc
t/data/usr/lib/pkgconfig/gstreamer-sdp-0.10.pc
t/data/usr/lib/pkgconfig/rarian.pc
t/data/usr/lib/pkgconfig/libgcj10.pc
t/data/usr/lib/pkgconfig/pyvte.pc
t/data/usr/lib/pkgconfig/mono-nunit.pc
t/data/usr/lib/pkgconfig/dvdnavmini.pc
t/data/usr/lib/pkgconfig/avahi-glib.pc
t/data/usr/lib/pkgconfig/libpcre.pc
t/data/usr/lib/pkgconfig/glib.pc
t/data/usr/lib/pkgconfig/xcomposite.pc
t/data/usr/lib/pkgconfig/xcmiscproto.pc
t/data/usr/lib/pkgconfig/ORBit-2.0.pc
t/data/usr/lib/pkgconfig/fftw3l.pc
t/data/usr/lib/pkgconfig/xkbfile.pc
t/data/usr/lib/pkgconfig/libarchive.pc
t/data/usr/lib/pkgconfig/xau.pc
t/data/usr/lib/pkgconfig/ORBit-CosNaming-2.0.pc
t/data/usr/lib/pkgconfig/nautilus-sendto.pc
t/data/usr/lib/pkgconfig/jinglexmpp-0.3.pc
t/data/usr/lib/pkgconfig/utouch-frame.pc
t/data/usr/lib/pkgconfig/zziplib.pc
t/data/usr/lib/pkgconfig/imlib.pc
t/data/usr/lib/pkgconfig/libtpl.pc
t/data/usr/lib/pkgconfig/gstreamer-net-0.10.pc
t/data/usr/lib/pkgconfig/libusb-1.0.pc
t/data/usr/lib/pkgconfig/poppler-splash.pc
t/data/usr/lib/pkgconfig/GraphicsMagick++.pc
t/data/usr/lib/pkgconfig/speexdsp.pc
t/data/usr/lib/pkgconfig/sigc++-2.0.pc
t/data/usr/lib/pkgconfig/libproxy-1.0.pc
t/data/usr/lib/pkgconfig/pangoft2.pc
t/data/usr/lib/pkgconfig/xcb.pc
t/data/usr/lib/pkgconfig/cogl-1.0.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
