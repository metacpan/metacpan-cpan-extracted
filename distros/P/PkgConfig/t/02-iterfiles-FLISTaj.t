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
t/data/usr/lib/pkgconfig/QtScript.pc
t/data/usr/lib/pkgconfig/xext.pc
t/data/usr/lib/pkgconfig/x11-xcb.pc
t/data/usr/lib/pkgconfig/sigc++-2.0.pc
t/data/usr/lib/pkgconfig/libnl-1.pc
t/data/usr/lib/pkgconfig/libgssglue.pc
t/data/usr/lib/pkgconfig/gl.pc
t/data/usr/lib/pkgconfig/renderproto.pc
t/data/usr/lib/pkgconfig/cairo-fc.pc
t/data/usr/lib/pkgconfig/libsepol.pc
t/data/usr/lib/pkgconfig/glibmm-2.4.pc
t/data/usr/lib/pkgconfig/QtXmlPatterns.pc
t/data/usr/lib/pkgconfig/theora.pc
t/data/usr/lib/pkgconfig/libdv.pc
t/data/usr/lib/pkgconfig/nss.pc
t/data/usr/lib/pkgconfig/xevie.pc
t/data/usr/lib/pkgconfig/ao.pc
t/data/usr/lib/pkgconfig/gstreamer-rtp-0.10.pc
t/data/usr/lib/pkgconfig/gmodule-no-export-2.0.pc
t/data/usr/lib/pkgconfig/mtdev.pc
t/data/usr/lib/pkgconfig/gthread.pc
t/data/usr/lib/pkgconfig/jinglesession-0.3.pc
t/data/usr/lib/pkgconfig/gtkhotkey-1.0.pc
t/data/usr/lib/pkgconfig/xorg-server.pc
t/data/usr/lib/pkgconfig/sane-backends.pc
t/data/usr/lib/pkgconfig/randrproto.pc
t/data/usr/lib/pkgconfig/mozilla-plugin.pc
t/data/usr/lib/pkgconfig/mutter-plugins.pc
t/data/usr/lib/pkgconfig/QtHelp.pc
t/data/usr/lib/pkgconfig/slang.pc
t/data/usr/lib/pkgconfig/gnome-vfs-2.0.pc
t/data/usr/lib/pkgconfig/directfb-internal.pc
t/data/usr/lib/pkgconfig/libdc1394-2.pc
t/data/usr/lib/pkgconfig/libedata-book-1.2.pc
t/data/usr/lib/pkgconfig/fontcacheproto.pc
t/data/usr/lib/pkgconfig/clutter-x11-1.0.pc
t/data/usr/lib/pkgconfig/tracker.pc
t/data/usr/lib/pkgconfig/QtTest.pc
t/data/usr/lib/pkgconfig/libcroco-0.6.pc
t/data/usr/lib/pkgconfig/libpcrecpp.pc
t/data/usr/lib/pkgconfig/compositeproto.pc
t/data/usr/lib/pkgconfig/pyside.pc
t/data/usr/lib/pkgconfig/libgnomekbd.pc
t/data/usr/lib/pkgconfig/ORBit.pc
t/data/usr/lib/pkgconfig/libxml++-2.6.pc
t/data/usr/lib/pkgconfig/xxf86misc.pc
t/data/usr/lib/pkgconfig/dvdread.pc
t/data/usr/lib/pkgconfig/pango.pc
t/data/usr/lib/pkgconfig/libsoup-2.4.pc
t/data/usr/lib/pkgconfig/librsvg-2.0.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
