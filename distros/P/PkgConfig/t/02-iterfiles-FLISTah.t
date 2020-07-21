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
t/data/usr/lib/pkgconfig/libkms.pc
t/data/usr/lib/pkgconfig/gamin.pc
t/data/usr/lib/pkgconfig/gthread-2.0.pc
t/data/usr/lib/pkgconfig/zzipfseeko.pc
t/data/usr/lib/pkgconfig/libavcore.pc
t/data/usr/lib/pkgconfig/mozilla-plugin.pc
t/data/usr/lib/pkgconfig/libxul-embedding-unstable.pc
t/data/usr/lib/pkgconfig/libxfce4util-1.0.pc
t/data/usr/lib/pkgconfig/liblircclient0.pc
t/data/usr/lib/pkgconfig/libpcrecpp.pc
t/data/usr/lib/pkgconfig/libopensc.pc
t/data/usr/lib/pkgconfig/libdecoration.pc
t/data/usr/lib/pkgconfig/fusion.pc
t/data/usr/lib/pkgconfig/xaw7.pc
t/data/usr/lib/pkgconfig/bluez.pc
t/data/usr/lib/pkgconfig/xau.pc
t/data/usr/lib/pkgconfig/clutter-1.0.pc
t/data/usr/lib/pkgconfig/libedataserver-1.2.pc
t/data/usr/lib/pkgconfig/bonobo-activation-2.0.pc
t/data/usr/lib/pkgconfig/directfb-internal.pc
t/data/usr/lib/pkgconfig/cucul.pc
t/data/usr/lib/pkgconfig/clutter-glx-1.0.pc
t/data/usr/lib/pkgconfig/libimobiledevice-1.0.pc
t/data/usr/lib/pkgconfig/imlib2.pc
t/data/usr/lib/pkgconfig/libxul-embedding.pc
t/data/usr/lib/pkgconfig/nss.pc
t/data/usr/lib/pkgconfig/glib.pc
t/data/usr/lib/pkgconfig/utouch-frame.pc
t/data/usr/lib/pkgconfig/gkrellm.pc
t/data/usr/lib/pkgconfig/cairo-xcb-shm.pc
t/data/usr/lib/pkgconfig/utouch-grail.pc
t/data/usr/lib/pkgconfig/polkit-gobject-1.pc
t/data/usr/lib/pkgconfig/libmutter-private.pc
t/data/usr/lib/pkgconfig/cairo-svg.pc
t/data/usr/lib/pkgconfig/gnutls.pc
t/data/usr/lib/pkgconfig/libgnome-2.0.pc
t/data/usr/lib/pkgconfig/xscrnsaver.pc
t/data/usr/lib/pkgconfig/thunar-vfs-1.pc
t/data/usr/lib/pkgconfig/libutouch-geis.pc
t/data/usr/lib/pkgconfig/libxml++-1.0.pc
t/data/usr/lib/pkgconfig/gstreamer-net-0.10.pc
t/data/usr/lib/pkgconfig/libdts.pc
t/data/usr/lib/pkgconfig/python-2.7.pc
t/data/usr/lib/pkgconfig/xcb.pc
t/data/usr/lib/pkgconfig/libdrm_nouveau.pc
t/data/usr/lib/pkgconfig/gstreamer-app-0.10.pc
t/data/usr/lib/pkgconfig/pixman-1.pc
t/data/usr/lib/pkgconfig/gstreamer-netbuffer-0.10.pc
t/data/usr/lib/pkgconfig/gail.pc
t/data/usr/lib/pkgconfig/xxf86dga.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
