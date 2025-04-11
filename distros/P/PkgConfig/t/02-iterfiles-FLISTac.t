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
t/data/usr/lib/pkgconfig/rarian.pc
t/data/usr/lib/pkgconfig/xfont.pc
t/data/usr/lib/pkgconfig/glitz-glx.pc
t/data/usr/lib/pkgconfig/gstreamer-rtp-0.10.pc
t/data/usr/lib/pkgconfig/libIDL-2.0.pc
t/data/usr/lib/pkgconfig/check.pc
t/data/usr/lib/pkgconfig/gmodule.pc
t/data/usr/lib/pkgconfig/xfixes.pc
t/data/usr/lib/pkgconfig/gio-unix-2.0.pc
t/data/usr/lib/pkgconfig/libiec61883.pc
t/data/usr/lib/pkgconfig/wcf.pc
t/data/usr/lib/pkgconfig/libgtop-2.0.pc
t/data/usr/lib/pkgconfig/audiofile.pc
t/data/usr/lib/pkgconfig/portaudio-2.0.pc
t/data/usr/lib/pkgconfig/QtCore.pc
t/data/usr/lib/pkgconfig/caca++.pc
t/data/usr/lib/pkgconfig/gtk+-x11-2.0.pc
t/data/usr/lib/pkgconfig/sane-backends.pc
t/data/usr/lib/pkgconfig/fftw3f.pc
t/data/usr/lib/pkgconfig/nautilus-python.pc
t/data/usr/lib/pkgconfig/pango.pc
t/data/usr/lib/pkgconfig/gnome-pilot-2.0.pc
t/data/usr/lib/pkgconfig/xcursor.pc
t/data/usr/lib/pkgconfig/libsysfs.pc
t/data/usr/lib/pkgconfig/libgssglue.pc
t/data/usr/lib/pkgconfig/libsoup-2.4.pc
t/data/usr/lib/pkgconfig/gnome-desktop-2.0.pc
t/data/usr/lib/pkgconfig/xrandr.pc
t/data/usr/lib/pkgconfig/esound.pc
t/data/usr/lib/pkgconfig/QtOpenGL.pc
t/data/usr/lib/pkgconfig/cairo-tee.pc
t/data/usr/lib/pkgconfig/QtDesigner.pc
t/data/usr/lib/pkgconfig/pilot-link.pc
t/data/usr/lib/pkgconfig/gstreamer-controller-0.10.pc
t/data/usr/lib/pkgconfig/cairo-gobject.pc
t/data/usr/lib/pkgconfig/libnotify.pc
t/data/usr/lib/pkgconfig/poppler-splash.pc
t/data/usr/lib/pkgconfig/xcb-aux.pc
t/data/usr/lib/pkgconfig/lcms.pc
t/data/usr/lib/pkgconfig/libIDL.pc
t/data/usr/lib/pkgconfig/libsqueeze-0.2.pc
t/data/usr/lib/pkgconfig/xfce4-icon-theme-1.0.pc
t/data/usr/lib/pkgconfig/schroedinger-1.0.pc
t/data/usr/lib/pkgconfig/ORBit-imodule-2.0.pc
t/data/usr/lib/pkgconfig/QtCLucene.pc
t/data/usr/lib/pkgconfig/QtDesignerComponents.pc
t/data/usr/lib/pkgconfig/devmapper.pc
t/data/usr/lib/pkgconfig/mtdev.pc
t/data/usr/lib/pkgconfig/gobject-2.0.pc
t/data/usr/lib/pkgconfig/QtWebKit.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
