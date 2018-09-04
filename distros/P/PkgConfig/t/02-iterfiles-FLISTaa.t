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
t/data/usr/lib/pkgconfig/libgphoto2_port.pc
t/data/usr/lib/pkgconfig/QtSql.pc
t/data/usr/lib/pkgconfig/libraw1394.pc
t/data/usr/lib/pkgconfig/mono.web.pc
t/data/usr/lib/pkgconfig/polkit-gobject-1.pc
t/data/usr/lib/pkgconfig/QtTest.pc
t/data/usr/lib/pkgconfig/system.web.extensions.design_1.0.pc
t/data/usr/lib/pkgconfig/xscrnsaver.pc
t/data/usr/lib/pkgconfig/slang.pc
t/data/usr/lib/pkgconfig/pangoxft.pc
t/data/usr/lib/pkgconfig/gdk-x11-2.0.pc
t/data/usr/lib/pkgconfig/libgnomekbd.pc
t/data/usr/lib/pkgconfig/libebook-1.2.pc
t/data/usr/lib/pkgconfig/libssh2.pc
t/data/usr/lib/pkgconfig/xorg-server.pc
t/data/usr/lib/pkgconfig/libical.pc
t/data/usr/lib/pkgconfig/vorbisenc.pc
t/data/usr/lib/pkgconfig/gstreamer-riff-0.10.pc
t/data/usr/lib/pkgconfig/uuid.pc
t/data/usr/lib/pkgconfig/libv4l1.pc
t/data/usr/lib/pkgconfig/cairo-png.pc
t/data/usr/lib/pkgconfig/gnome-vfs-module-2.0.pc
t/data/usr/lib/pkgconfig/xcb-render.pc
t/data/usr/lib/pkgconfig/cairo-xlib.pc
t/data/usr/lib/pkgconfig/pm-utils.pc
t/data/usr/lib/pkgconfig/xpm.pc
t/data/usr/lib/pkgconfig/dvdnav.pc
t/data/usr/lib/pkgconfig/e2p.pc
t/data/usr/lib/pkgconfig/schroedinger-1.0.pc
t/data/usr/lib/pkgconfig/libmetacity-private.pc
t/data/usr/lib/pkgconfig/gstreamer-cdda-0.10.pc
t/data/usr/lib/pkgconfig/gstreamer-plugins-base-0.10.pc
t/data/usr/lib/pkgconfig/theoraenc.pc
t/data/usr/lib/pkgconfig/utouch-evemu.pc
t/data/usr/lib/pkgconfig/jinglesession-0.3.pc
t/data/usr/lib/pkgconfig/gstreamer-rtp-0.10.pc
t/data/usr/lib/pkgconfig/gnome-settings-daemon.pc
t/data/usr/lib/pkgconfig/gstreamer-rtsp-0.10.pc
t/data/usr/lib/pkgconfig/libimobiledevice-1.0.pc
t/data/usr/lib/pkgconfig/libiec61883.pc
t/data/usr/lib/pkgconfig/nice.pc
t/data/usr/lib/pkgconfig/xrandr.pc
t/data/usr/lib/pkgconfig/ext2fs.pc
t/data/usr/lib/pkgconfig/librsvg-2.0.pc
t/data/usr/lib/pkgconfig/com_err.pc
t/data/usr/lib/pkgconfig/QtScriptTools.pc
t/data/usr/lib/pkgconfig/clutter-glx-1.0.pc
t/data/usr/lib/pkgconfig/libavc1394.pc
t/data/usr/lib/pkgconfig/gst-python-0.10.pc
t/data/usr/lib/pkgconfig/libgnome-2.0.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
