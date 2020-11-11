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
t/data/usr/lib/pkgconfig/polkit-gtk-1.pc
t/data/usr/lib/pkgconfig/cairo-xcb-shm.pc
t/data/usr/lib/pkgconfig/sofia-sip-ua.pc
t/data/usr/lib/pkgconfig/dbus-python.pc
t/data/usr/lib/pkgconfig/ORBit-imodule-2.0.pc
t/data/usr/lib/pkgconfig/xkbui.pc
t/data/usr/lib/pkgconfig/cairo-xlib.pc
t/data/usr/lib/pkgconfig/x264.pc
t/data/usr/lib/pkgconfig/gstreamer-cdda-0.10.pc
t/data/usr/lib/pkgconfig/libgpod-1.0.pc
t/data/usr/lib/pkgconfig/alsa.pc
t/data/usr/lib/pkgconfig/QtOpenGL.pc
t/data/usr/lib/pkgconfig/com_err.pc
t/data/usr/lib/pkgconfig/xpm.pc
t/data/usr/lib/pkgconfig/libgnomekbdui.pc
t/data/usr/lib/pkgconfig/libplist.pc
t/data/usr/lib/pkgconfig/zzip-zlib-config.pc
t/data/usr/lib/pkgconfig/gstreamer-app-0.10.pc
t/data/usr/lib/pkgconfig/silc.pc
t/data/usr/lib/pkgconfig/libgcj.pc
t/data/usr/lib/pkgconfig/gnome-desktop-2.0.pc
t/data/usr/lib/pkgconfig/fontsproto.pc
t/data/usr/lib/pkgconfig/gio-unix-2.0.pc
t/data/usr/lib/pkgconfig/pangoft2.pc
t/data/usr/lib/pkgconfig/QtSvg.pc
t/data/usr/lib/pkgconfig/libutouch-geis.pc
t/data/usr/lib/pkgconfig/librtmp.pc
t/data/usr/lib/pkgconfig/cucul.pc
t/data/usr/lib/pkgconfig/libdrm_intel.pc
t/data/usr/lib/pkgconfig/dbus-glib-1.pc
t/data/usr/lib/pkgconfig/pygtkglext-1.0.pc
t/data/usr/lib/pkgconfig/gdk-2.0.pc
t/data/usr/lib/pkgconfig/libpulse.pc
t/data/usr/lib/pkgconfig/libebook-1.2.pc
t/data/usr/lib/pkgconfig/cecil.pc
t/data/usr/lib/pkgconfig/jinglebase-0.3.pc
t/data/usr/lib/pkgconfig/libcrypto.pc
t/data/usr/lib/pkgconfig/nautilus-python.pc
t/data/usr/lib/pkgconfig/libsysfs.pc
t/data/usr/lib/pkgconfig/gdu.pc
t/data/usr/lib/pkgconfig/cogl-gl-1.0.pc
t/data/usr/lib/pkgconfig/libiec61883.pc
t/data/usr/lib/pkgconfig/gstreamer-fft-0.10.pc
t/data/usr/lib/pkgconfig/libcap-ng.pc
t/data/usr/lib/pkgconfig/dmxproto.pc
t/data/usr/lib/pkgconfig/libv4lconvert.pc
t/data/usr/lib/pkgconfig/mono-nunit.pc
t/data/usr/lib/pkgconfig/xdamage.pc
t/data/usr/lib/pkgconfig/libyahoo2.pc
t/data/usr/lib/pkgconfig/fftw3l.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
