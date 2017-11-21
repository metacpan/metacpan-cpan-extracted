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
t/data/usr/lib/pkgconfig/QtXmlPatterns.pc
t/data/usr/lib/pkgconfig/randrproto.pc
t/data/usr/lib/pkgconfig/rarian.pc
t/data/usr/lib/pkgconfig/recordproto.pc
t/data/usr/lib/pkgconfig/renderproto.pc
t/data/usr/lib/pkgconfig/resourceproto.pc
t/data/usr/lib/pkgconfig/sane-backends.pc
t/data/usr/lib/pkgconfig/schroedinger-1.0.pc
t/data/usr/lib/pkgconfig/scrnsaverproto.pc
t/data/usr/lib/pkgconfig/sdl.pc
t/data/usr/lib/pkgconfig/SDL_image.pc
t/data/usr/lib/pkgconfig/shout.pc
t/data/usr/lib/pkgconfig/sigc++-2.0.pc
t/data/usr/lib/pkgconfig/silc.pc
t/data/usr/lib/pkgconfig/silcclient.pc
t/data/usr/lib/pkgconfig/slang.pc
t/data/usr/lib/pkgconfig/sm.pc
t/data/usr/lib/pkgconfig/sndfile.pc
t/data/usr/lib/pkgconfig/sofia-sip-ua.pc
t/data/usr/lib/pkgconfig/speex.pc
t/data/usr/lib/pkgconfig/speexdsp.pc
t/data/usr/lib/pkgconfig/sqlite3.pc
t/data/usr/lib/pkgconfig/system.web.extensions.design_1.0.pc
t/data/usr/lib/pkgconfig/system.web.extensions_1.0.pc
t/data/usr/lib/pkgconfig/system.web.mvc.pc
t/data/usr/lib/pkgconfig/taglib.pc
t/data/usr/lib/pkgconfig/talloc.pc
t/data/usr/lib/pkgconfig/theora.pc
t/data/usr/lib/pkgconfig/theoradec.pc
t/data/usr/lib/pkgconfig/theoraenc.pc
t/data/usr/lib/pkgconfig/thunar-vfs-1.pc
t/data/usr/lib/pkgconfig/thunarx-1.pc
t/data/usr/lib/pkgconfig/tracker.pc
t/data/usr/lib/pkgconfig/trapproto.pc
t/data/usr/lib/pkgconfig/tre.pc
t/data/usr/lib/pkgconfig/unique-1.0.pc
t/data/usr/lib/pkgconfig/upower-glib.pc
t/data/usr/lib/pkgconfig/utouch-evemu.pc
t/data/usr/lib/pkgconfig/utouch-frame.pc
t/data/usr/lib/pkgconfig/utouch-grail.pc
t/data/usr/lib/pkgconfig/uuid.pc
t/data/usr/lib/pkgconfig/valgrind.pc
t/data/usr/lib/pkgconfig/videoproto.pc
t/data/usr/lib/pkgconfig/vorbis.pc
t/data/usr/lib/pkgconfig/vorbisenc.pc
t/data/usr/lib/pkgconfig/vorbisfile.pc
t/data/usr/lib/pkgconfig/vte.pc
t/data/usr/lib/pkgconfig/wavpack.pc
t/data/usr/lib/pkgconfig/wcf.pc
t/data/usr/lib/pkgconfig/webkit-1.0.pc
)];

PkgConfigTest::run_exists_test($flist, __FILE__);
PkgConfigTest::run_flags_test($flist, __FILE__);
done_testing();
