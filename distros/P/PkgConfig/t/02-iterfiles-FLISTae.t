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
t/data/usr/lib/pkgconfig/wmlib.pc
t/data/usr/lib/pkgconfig/vorbisenc.pc
t/data/usr/lib/pkgconfig/QtDBus.pc
t/data/usr/lib/pkgconfig/Qt.pc
t/data/usr/lib/pkgconfig/QtXml.pc
t/data/usr/lib/pkgconfig/wcf.pc
t/data/usr/lib/pkgconfig/vte.pc
t/data/usr/lib/pkgconfig/nice.pc
t/data/usr/lib/pkgconfig/libdca.pc
t/data/usr/lib/pkgconfig/zzipfseeko.pc
t/data/usr/lib/pkgconfig/pygobject-2.0.pc
t/data/usr/lib/pkgconfig/fftw3.pc
t/data/usr/lib/pkgconfig/xcb-render.pc
t/data/usr/lib/pkgconfig/QtMultimedia.pc
t/data/usr/lib/pkgconfig/notify-python.pc
t/data/usr/lib/pkgconfig/libusb-1.0.pc
t/data/usr/lib/pkgconfig/cairomm-png-1.0.pc
t/data/usr/lib/pkgconfig/cairo-gobject.pc
t/data/usr/lib/pkgconfig/gstreamer-rtsp-0.10.pc
t/data/usr/lib/pkgconfig/cairomm-ps-1.0.pc
t/data/usr/lib/pkgconfig/poppler-splash.pc
t/data/usr/lib/pkgconfig/flac.pc
t/data/usr/lib/pkgconfig/libxml-2.0.pc
t/data/usr/lib/pkgconfig/gnome-settings-daemon.pc
t/data/usr/lib/pkgconfig/openal.pc
t/data/usr/lib/pkgconfig/libxul-embedding-unstable.pc
t/data/usr/lib/pkgconfig/xineramaproto.pc
t/data/usr/lib/pkgconfig/libgdiplus.pc
t/data/usr/lib/pkgconfig/pangox.pc
t/data/usr/lib/pkgconfig/libical.pc
t/data/usr/lib/pkgconfig/gstreamer-net-0.10.pc
t/data/usr/lib/pkgconfig/gstreamer-netbuffer-0.10.pc
t/data/usr/lib/pkgconfig/gnome-vfs-module-2.0.pc
t/data/usr/lib/pkgconfig/gobject-2.0.pc
t/data/usr/lib/pkgconfig/xvmc.pc
t/data/usr/lib/pkgconfig/QtWebKit.pc
t/data/usr/lib/pkgconfig/libnfsidmap.pc
t/data/usr/lib/pkgconfig/check.pc
t/data/usr/lib/pkgconfig/libdrm_radeon.pc
t/data/usr/lib/pkgconfig/gstreamer-audio-0.10.pc
t/data/usr/lib/pkgconfig/polkit-gobject-1.pc
t/data/usr/lib/pkgconfig/libavutil.pc
t/data/usr/lib/pkgconfig/gstreamer-dataprotocol-0.10.pc
t/data/usr/lib/pkgconfig/eventlog.pc
t/data/usr/lib/pkgconfig/gnome-screensaver.pc
t/data/usr/lib/pkgconfig/libstartup-notification-1.0.pc
t/data/usr/lib/pkgconfig/enchant.pc
t/data/usr/lib/pkgconfig/exo-hal-0.3.pc
t/data/usr/lib/pkgconfig/xcb-aux.pc
t/data/usr/lib/pkgconfig/mjpegtools.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
