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
t/data/usr/lib/pkgconfig/system.web.mvc.pc
t/data/usr/lib/pkgconfig/cairo-svg.pc
t/data/usr/lib/pkgconfig/libdrm.pc
t/data/usr/lib/pkgconfig/libv4l2.pc
t/data/usr/lib/pkgconfig/gnome-desktop-2.0.pc
t/data/usr/lib/pkgconfig/gdu.pc
t/data/usr/lib/pkgconfig/utouch-grail.pc
t/data/usr/lib/pkgconfig/libusb.pc
t/data/usr/lib/pkgconfig/fontutil.pc
t/data/usr/lib/pkgconfig/libwnck-1.0.pc
t/data/usr/lib/pkgconfig/gstreamer-rtp-0.10.pc
t/data/usr/lib/pkgconfig/shout.pc
t/data/usr/lib/pkgconfig/xcb-event.pc
t/data/usr/lib/pkgconfig/gnome-window-settings-2.0.pc
t/data/usr/lib/pkgconfig/cairomm-ft-1.0.pc
t/data/usr/lib/pkgconfig/notify-python.pc
t/data/usr/lib/pkgconfig/gstreamer-check-0.10.pc
t/data/usr/lib/pkgconfig/hal.pc
t/data/usr/lib/pkgconfig/libgadu.pc
t/data/usr/lib/pkgconfig/bigreqsproto.pc
t/data/usr/lib/pkgconfig/ortp.pc
t/data/usr/lib/pkgconfig/imlib.pc
t/data/usr/lib/pkgconfig/meanwhile.pc
t/data/usr/lib/pkgconfig/ORBit-imodule-2.0.pc
t/data/usr/lib/pkgconfig/utouch-frame.pc
t/data/usr/lib/pkgconfig/xevie.pc
t/data/usr/lib/pkgconfig/librtmp.pc
t/data/usr/lib/pkgconfig/clutter-x11-1.0.pc
t/data/usr/lib/pkgconfig/gmodule-export-2.0.pc
t/data/usr/lib/pkgconfig/theora.pc
t/data/usr/lib/pkgconfig/libavdevice.pc
t/data/usr/lib/pkgconfig/mjpegtools.pc
t/data/usr/lib/pkgconfig/dbus-python.pc
t/data/usr/lib/pkgconfig/xrender.pc
t/data/usr/lib/pkgconfig/libpcrecpp.pc
t/data/usr/lib/pkgconfig/glibmm-2.4.pc
t/data/usr/lib/pkgconfig/libebook-1.2.pc
t/data/usr/lib/pkgconfig/gnutls.pc
t/data/usr/lib/pkgconfig/mutter-plugins.pc
t/data/usr/lib/pkgconfig/xpm.pc
t/data/usr/lib/pkgconfig/mono-options.pc
t/data/usr/lib/pkgconfig/libpcreposix.pc
t/data/usr/lib/pkgconfig/xres.pc
t/data/usr/lib/pkgconfig/devmapper.pc
t/data/usr/lib/pkgconfig/QtUiTools.pc
t/data/usr/lib/pkgconfig/cairo-xcb-shm.pc
t/data/usr/lib/pkgconfig/pangox.pc
t/data/usr/lib/pkgconfig/libfs.pc
t/data/usr/lib/pkgconfig/libgnomekbdui.pc
t/data/usr/lib/pkgconfig/farsight2-0.10.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
