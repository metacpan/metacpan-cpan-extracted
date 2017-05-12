# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

use inc::Module::Install;

name('Ogg-Vorbis-Decoder');
license('perl');
perl_version('5.005');
all_from('Decoder.pm');

if ($^O =~ /win32/i) {

	cc_lib_links(qw(ogg_static vorbis_static vorbisfile_static));

} else {

	cc_lib_links(qw(ogg vorbis vorbisfile));
	cc_optimize_flags('-Wall');
}

auto_install();
WriteAll();
