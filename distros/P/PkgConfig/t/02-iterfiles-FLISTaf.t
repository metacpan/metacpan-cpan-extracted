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
t/data/usr/lib/pkgconfig/fftw3l.pc
t/data/usr/lib/pkgconfig/zzipfseeko.pc
t/data/usr/lib/pkgconfig/pangomm-1.4.pc
t/data/usr/lib/pkgconfig/poppler.pc
t/data/usr/lib/pkgconfig/wrlib.pc
t/data/usr/lib/pkgconfig/libdca.pc
t/data/usr/lib/pkgconfig/exo-0.3.pc
t/data/usr/lib/pkgconfig/vorbisenc.pc
t/data/usr/lib/pkgconfig/xtst.pc
t/data/usr/lib/pkgconfig/openal.pc
t/data/usr/lib/pkgconfig/pangoft2.pc
t/data/usr/lib/pkgconfig/QtOpenGL.pc
t/data/usr/lib/pkgconfig/xtrap.pc
t/data/usr/lib/pkgconfig/gst-python-0.10.pc
t/data/usr/lib/pkgconfig/nspr.pc
t/data/usr/lib/pkgconfig/libxul-unstable.pc
t/data/usr/lib/pkgconfig/ORBit-2.0.pc
t/data/usr/lib/pkgconfig/gtkmm-2.4.pc
t/data/usr/lib/pkgconfig/sndfile.pc
t/data/usr/lib/pkgconfig/gdk-2.0.pc
t/data/usr/lib/pkgconfig/fontsproto.pc
t/data/usr/lib/pkgconfig/gnome-screensaver.pc
t/data/usr/lib/pkgconfig/libdrm_radeon.pc
t/data/usr/lib/pkgconfig/glitz.pc
t/data/usr/lib/pkgconfig/gobject-introspection-no-export-1.0.pc
t/data/usr/lib/pkgconfig/schroedinger-1.0.pc
t/data/usr/lib/pkgconfig/qimageblitz.pc
t/data/usr/lib/pkgconfig/QtXml.pc
t/data/usr/lib/pkgconfig/devkit-power-gobject.pc
t/data/usr/lib/pkgconfig/libpng12.pc
t/data/usr/lib/pkgconfig/IlmBase.pc
t/data/usr/lib/pkgconfig/gmodule.pc
t/data/usr/lib/pkgconfig/gnome-mount.pc
t/data/usr/lib/pkgconfig/xcb.pc
t/data/usr/lib/pkgconfig/libgpod-1.0.pc
t/data/usr/lib/pkgconfig/avahi-client.pc
t/data/usr/lib/pkgconfig/QtWebKit.pc
t/data/usr/lib/pkgconfig/json-glib-1.0.pc
t/data/usr/lib/pkgconfig/trapproto.pc
t/data/usr/lib/pkgconfig/libnl-1.pc
t/data/usr/lib/pkgconfig/poppler-splash.pc
t/data/usr/lib/pkgconfig/xulrunner-nss.pc
t/data/usr/lib/pkgconfig/evolution-data-server-1.2.pc
t/data/usr/lib/pkgconfig/fontconfig.pc
t/data/usr/lib/pkgconfig/libpulse-browse.pc
t/data/usr/lib/pkgconfig/libcap-ng.pc
t/data/usr/lib/pkgconfig/libpulse-mainloop-glib.pc
t/data/usr/lib/pkgconfig/directfb.pc
t/data/usr/lib/pkgconfig/sdl.pc
t/data/usr/lib/pkgconfig/xp.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
