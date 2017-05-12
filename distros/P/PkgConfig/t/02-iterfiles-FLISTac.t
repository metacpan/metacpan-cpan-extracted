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
t/data/usr/lib/pkgconfig/caca++.pc
t/data/usr/lib/pkgconfig/tracker.pc
t/data/usr/lib/pkgconfig/xinerama.pc
t/data/usr/lib/pkgconfig/libxml++-2.6.pc
t/data/usr/lib/pkgconfig/libpulse-simple.pc
t/data/usr/lib/pkgconfig/libgcj.pc
t/data/usr/lib/pkgconfig/libpcre.pc
t/data/usr/lib/pkgconfig/dbus-glib-1.pc
t/data/usr/lib/pkgconfig/mozilla-plugin.pc
t/data/usr/lib/pkgconfig/hal-storage.pc
t/data/usr/lib/pkgconfig/libxul-embedding-unstable.pc
t/data/usr/lib/pkgconfig/cairo-fc.pc
t/data/usr/lib/pkgconfig/xrandr.pc
t/data/usr/lib/pkgconfig/silc.pc
t/data/usr/lib/pkgconfig/camel-provider-1.2.pc
t/data/usr/lib/pkgconfig/libgnomeui-2.0.pc
t/data/usr/lib/pkgconfig/pciaccess.pc
t/data/usr/lib/pkgconfig/libv4lconvert.pc
t/data/usr/lib/pkgconfig/mozilla-gtkmozembed.pc
t/data/usr/lib/pkgconfig/jinglexmpp-0.3.pc
t/data/usr/lib/pkgconfig/cairo.pc
t/data/usr/lib/pkgconfig/esound.pc
t/data/usr/lib/pkgconfig/gstreamer-audio-0.10.pc
t/data/usr/lib/pkgconfig/pm-utils.pc
t/data/usr/lib/pkgconfig/freetype2.pc
t/data/usr/lib/pkgconfig/QtAssistantClient.pc
t/data/usr/lib/pkgconfig/gupnp-igd-1.0.pc
t/data/usr/lib/pkgconfig/libcurl.pc
t/data/usr/lib/pkgconfig/opencore-amrwb.pc
t/data/usr/lib/pkgconfig/libgnome-menu.pc
t/data/usr/lib/pkgconfig/libIDL.pc
t/data/usr/lib/pkgconfig/libarchive.pc
t/data/usr/lib/pkgconfig/libexslt.pc
t/data/usr/lib/pkgconfig/pygtk-2.0.pc
t/data/usr/lib/pkgconfig/fftw3f.pc
t/data/usr/lib/pkgconfig/gio-2.0.pc
t/data/usr/lib/pkgconfig/libdts.pc
t/data/usr/lib/pkgconfig/evieproto.pc
t/data/usr/lib/pkgconfig/jinglesession-0.3.pc
t/data/usr/lib/pkgconfig/xft.pc
t/data/usr/lib/pkgconfig/gconf-2.0.pc
t/data/usr/lib/pkgconfig/bonobo-activation-2.0.pc
t/data/usr/lib/pkgconfig/zzipwrap.pc
t/data/usr/lib/pkgconfig/rarian.pc
t/data/usr/lib/pkgconfig/xau.pc
t/data/usr/lib/pkgconfig/cairo-gobject.pc
t/data/usr/lib/pkgconfig/libiec61883.pc
t/data/usr/lib/pkgconfig/ogg.pc
t/data/usr/lib/pkgconfig/xxf86misc.pc
t/data/usr/lib/pkgconfig/gdk-pixbuf-2.0.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
