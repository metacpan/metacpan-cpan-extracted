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
t/data/usr/lib/pkgconfig/cairomm-svg-1.0.pc
t/data/usr/lib/pkgconfig/gweather.pc
t/data/usr/lib/pkgconfig/libconfig.pc
t/data/usr/lib/pkgconfig/gobject-introspection-1.0.pc
t/data/usr/lib/pkgconfig/glitz-glx.pc
t/data/usr/lib/pkgconfig/jinglexmllite-0.3.pc
t/data/usr/lib/pkgconfig/gnome-js-common.pc
t/data/usr/lib/pkgconfig/libdc1394-2.pc
t/data/usr/lib/pkgconfig/opencore-amrwb.pc
t/data/usr/lib/pkgconfig/xcb-util.pc
t/data/usr/lib/pkgconfig/cairo-pdf.pc
t/data/usr/lib/pkgconfig/libagg.pc
t/data/usr/lib/pkgconfig/cairomm-xlib-1.0.pc
t/data/usr/lib/pkgconfig/gnutls-extra.pc
t/data/usr/lib/pkgconfig/thunarx-1.pc
t/data/usr/lib/pkgconfig/gdk-pixbuf-2.0.pc
t/data/usr/lib/pkgconfig/glu.pc
t/data/usr/lib/pkgconfig/libxul-embedding-unstable.pc
t/data/usr/lib/pkgconfig/libwnck-1.0.pc
t/data/usr/lib/pkgconfig/xf86vidmodeproto.pc
t/data/usr/lib/pkgconfig/libquicktime.pc
t/data/usr/lib/pkgconfig/gvnc-1.0.pc
t/data/usr/lib/pkgconfig/sqlite3.pc
t/data/usr/lib/pkgconfig/sane-backends.pc
t/data/usr/lib/pkgconfig/libgcj.pc
t/data/usr/lib/pkgconfig/cairomm-ps-1.0.pc
t/data/usr/lib/pkgconfig/libnl-1.pc
t/data/usr/lib/pkgconfig/mono-options.pc
t/data/usr/lib/pkgconfig/zzipfseeko.pc
t/data/usr/lib/pkgconfig/libIDL-2.0.pc
t/data/usr/lib/pkgconfig/librtmp.pc
t/data/usr/lib/pkgconfig/orc-0.4.pc
t/data/usr/lib/pkgconfig/gnome-pilot-2.0.pc
t/data/usr/lib/pkgconfig/xtrap.pc
t/data/usr/lib/pkgconfig/sndfile.pc
t/data/usr/lib/pkgconfig/libxul.pc
t/data/usr/lib/pkgconfig/giomm-2.4.pc
t/data/usr/lib/pkgconfig/dotnet35.pc
t/data/usr/lib/pkgconfig/pixman-1.pc
t/data/usr/lib/pkgconfig/libselinux.pc
t/data/usr/lib/pkgconfig/gupnp-igd-1.0.pc
t/data/usr/lib/pkgconfig/libffi.pc
t/data/usr/lib/pkgconfig/libdrm_intel.pc
t/data/usr/lib/pkgconfig/check.pc
t/data/usr/lib/pkgconfig/xxf86dga.pc
t/data/usr/lib/pkgconfig/fuse.pc
t/data/usr/lib/pkgconfig/QtNetwork.pc
t/data/usr/lib/pkgconfig/libdecoration.pc
t/data/usr/lib/pkgconfig/libxine.pc
t/data/usr/lib/pkgconfig/vorbis.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
