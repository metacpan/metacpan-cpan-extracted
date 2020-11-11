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
t/data/usr/lib/pkgconfig/utouch-frame.pc
t/data/usr/lib/pkgconfig/xrender.pc
t/data/usr/lib/pkgconfig/pyvte.pc
t/data/usr/lib/pkgconfig/poppler.pc
t/data/usr/lib/pkgconfig/devmapper.pc
t/data/usr/lib/pkgconfig/gmodule.pc
t/data/usr/lib/pkgconfig/autoopts.pc
t/data/usr/lib/pkgconfig/poppler-cairo.pc
t/data/usr/lib/pkgconfig/cairo-ft.pc
t/data/usr/lib/pkgconfig/gnutls-extra.pc
t/data/usr/lib/pkgconfig/libmpeg2convert.pc
t/data/usr/lib/pkgconfig/gdk-x11-2.0.pc
t/data/usr/lib/pkgconfig/ogg.pc
t/data/usr/lib/pkgconfig/sqlite3.pc
t/data/usr/lib/pkgconfig/libraw1394.pc
t/data/usr/lib/pkgconfig/libnotify.pc
t/data/usr/lib/pkgconfig/atk.pc
t/data/usr/lib/pkgconfig/jinglexmllite-0.3.pc
t/data/usr/lib/pkgconfig/libgcj10.pc
t/data/usr/lib/pkgconfig/talloc.pc
t/data/usr/lib/pkgconfig/libarchive.pc
t/data/usr/lib/pkgconfig/glitz.pc
t/data/usr/lib/pkgconfig/rarian.pc
t/data/usr/lib/pkgconfig/gstreamer-check-0.10.pc
t/data/usr/lib/pkgconfig/gtk+-x11-2.0.pc
t/data/usr/lib/pkgconfig/libexchange-storage-1.2.pc
t/data/usr/lib/pkgconfig/QtDesignerComponents.pc
t/data/usr/lib/pkgconfig/xulrunner-nspr.pc
t/data/usr/lib/pkgconfig/avahi-client.pc
t/data/usr/lib/pkgconfig/cairo-tee.pc
t/data/usr/lib/pkgconfig/cairomm-svg-1.0.pc
t/data/usr/lib/pkgconfig/libecal-1.2.pc
t/data/usr/lib/pkgconfig/libIDL.pc
t/data/usr/lib/pkgconfig/glitz-glx.pc
t/data/usr/lib/pkgconfig/xres.pc
t/data/usr/lib/pkgconfig/gupnp-igd-1.0.pc
t/data/usr/lib/pkgconfig/gdk-pixbuf-2.0.pc
t/data/usr/lib/pkgconfig/xcomposite.pc
t/data/usr/lib/pkgconfig/libdts.pc
t/data/usr/lib/pkgconfig/QtGui.pc
t/data/usr/lib/pkgconfig/dbus-1.pc
t/data/usr/lib/pkgconfig/camel-provider-1.2.pc
t/data/usr/lib/pkgconfig/cairomm-pdf-1.0.pc
t/data/usr/lib/pkgconfig/caca.pc
t/data/usr/lib/pkgconfig/gnome-pilot-2.0.pc
t/data/usr/lib/pkgconfig/gtk+-2.0.pc
t/data/usr/lib/pkgconfig/libgtop-2.0.pc
t/data/usr/lib/pkgconfig/xorg-evdev.pc
t/data/usr/lib/pkgconfig/libvbucket.pc
t/data/usr/lib/pkgconfig/bonobo-activation-2.0.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
