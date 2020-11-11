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
t/data/usr/lib/pkgconfig/xxf86vm.pc
t/data/usr/lib/pkgconfig/gdk-pixbuf-xlib-2.0.pc
t/data/usr/lib/pkgconfig/pangoxft.pc
t/data/usr/lib/pkgconfig/pygtk-2.0.pc
t/data/usr/lib/pkgconfig/xscrnsaver.pc
t/data/usr/lib/pkgconfig/libscconf.pc
t/data/usr/lib/pkgconfig/ortp.pc
t/data/usr/lib/pkgconfig/gmodule-export-2.0.pc
t/data/usr/lib/pkgconfig/xulrunner-nss.pc
t/data/usr/lib/pkgconfig/x11.pc
t/data/usr/lib/pkgconfig/dvdnav.pc
t/data/usr/lib/pkgconfig/cally-1.0.pc
t/data/usr/lib/pkgconfig/libsoup-gnome-2.4.pc
t/data/usr/lib/pkgconfig/evolution-data-server-1.2.pc
t/data/usr/lib/pkgconfig/libpulse-simple.pc
t/data/usr/lib/pkgconfig/libgphoto2_port.pc
t/data/usr/lib/pkgconfig/lcms.pc
t/data/usr/lib/pkgconfig/zzipwrap.pc
t/data/usr/lib/pkgconfig/libgnomeui-2.0.pc
t/data/usr/lib/pkgconfig/liblircclient0.pc
t/data/usr/lib/pkgconfig/orc-0.4.pc
t/data/usr/lib/pkgconfig/xrandr.pc
t/data/usr/lib/pkgconfig/alsaplayer.pc
t/data/usr/lib/pkgconfig/scrnsaverproto.pc
t/data/usr/lib/pkgconfig/camel-1.2.pc
t/data/usr/lib/pkgconfig/mono-lineeditor.pc
t/data/usr/lib/pkgconfig/xkbfile.pc
t/data/usr/lib/pkgconfig/libcurl.pc
t/data/usr/lib/pkgconfig/theoradec.pc
t/data/usr/lib/pkgconfig/devkit-power-gobject.pc
t/data/usr/lib/pkgconfig/jinglexmpp-0.3.pc
t/data/usr/lib/pkgconfig/gstreamer-video-0.10.pc
t/data/usr/lib/pkgconfig/liblzma.pc
t/data/usr/lib/pkgconfig/gio-2.0.pc
t/data/usr/lib/pkgconfig/gudev-1.0.pc
t/data/usr/lib/pkgconfig/webkit-1.0.pc
t/data/usr/lib/pkgconfig/libquicktime.pc
t/data/usr/lib/pkgconfig/libcdio_cdda.pc
t/data/usr/lib/pkgconfig/fontutil.pc
t/data/usr/lib/pkgconfig/cairo-pdf.pc
t/data/usr/lib/pkgconfig/speex.pc
t/data/usr/lib/pkgconfig/libpcre.pc
t/data/usr/lib/pkgconfig/cairomm-ft-1.0.pc
t/data/usr/lib/pkgconfig/imlib.pc
t/data/usr/lib/pkgconfig/fftw3f.pc
t/data/usr/lib/pkgconfig/dotnet35.pc
t/data/usr/lib/pkgconfig/deskbar-applet.pc
t/data/usr/lib/pkgconfig/cairomm-xlib-1.0.pc
t/data/usr/lib/pkgconfig/pm-utils.pc
t/data/usr/lib/pkgconfig/direct.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
