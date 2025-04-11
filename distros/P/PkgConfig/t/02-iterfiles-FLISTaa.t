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
t/data/usr/local/lib/pkgconfig/glu.pc
t/data/usr/local/lib/pkgconfig/cmph.pc
t/data/usr/local/lib/pkgconfig/dri.pc
t/data/usr/local/lib/pkgconfig/libvirt.pc
t/data/usr/local/lib/pkgconfig/gl.pc
t/data/usr/local/lib/pkgconfig/libdivecomputer.pc
t/data/usr/local/lib/pkgconfig/termkey.pc
t/data/usr/local/lib/pkgconfig/codeblocks.pc
t/data/usr/local/lib/pkgconfig/emeraldengine.pc
t/data/usr/local/share/pkgconfig/shared-mime-info.pc
t/data/usr/local/share/pkgconfig/bcop.pc
t/data/usr/lib/pkgconfig/libpcreposix.pc
t/data/usr/lib/pkgconfig/dvdread.pc
t/data/usr/lib/pkgconfig/mono-options.pc
t/data/usr/lib/pkgconfig/pygtkglext-1.0.pc
t/data/usr/lib/pkgconfig/QtScriptTools.pc
t/data/usr/lib/pkgconfig/libgnomekbd.pc
t/data/usr/lib/pkgconfig/QtGui.pc
t/data/usr/lib/pkgconfig/tre.pc
t/data/usr/lib/pkgconfig/poppler.pc
t/data/usr/lib/pkgconfig/theoradec.pc
t/data/usr/lib/pkgconfig/pangoft2.pc
t/data/usr/lib/pkgconfig/gstreamer-pbutils-0.10.pc
t/data/usr/lib/pkgconfig/silcclient.pc
t/data/usr/lib/pkgconfig/xtst.pc
t/data/usr/lib/pkgconfig/libpng12.pc
t/data/usr/lib/pkgconfig/atkmm-1.6.pc
t/data/usr/lib/pkgconfig/libv4l2.pc
t/data/usr/lib/pkgconfig/glu.pc
t/data/usr/lib/pkgconfig/xmuu.pc
t/data/usr/lib/pkgconfig/openssl.pc
t/data/usr/lib/pkgconfig/mono.pc
t/data/usr/lib/pkgconfig/talloc.pc
t/data/usr/lib/pkgconfig/sigc++-2.0.pc
t/data/usr/lib/pkgconfig/gnome-screensaver.pc
t/data/usr/lib/pkgconfig/libarchive.pc
t/data/usr/lib/pkgconfig/exempi-2.0.pc
t/data/usr/lib/pkgconfig/xdmcp.pc
t/data/usr/lib/pkgconfig/zzipmmapped.pc
t/data/usr/lib/pkgconfig/dvdnav.pc
t/data/usr/lib/pkgconfig/nspr.pc
t/data/usr/lib/pkgconfig/mad.pc
t/data/usr/lib/pkgconfig/jinglexmllite-0.3.pc
t/data/usr/lib/pkgconfig/compositeproto.pc
t/data/usr/lib/pkgconfig/evolution-data-server-1.2.pc
t/data/usr/lib/pkgconfig/flac.pc
t/data/usr/lib/pkgconfig/librpcsecgss.pc
t/data/usr/lib/pkgconfig/dmxproto.pc
t/data/usr/lib/pkgconfig/gdkmm-2.4.pc
t/data/usr/lib/pkgconfig/librsvg-2.0.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
