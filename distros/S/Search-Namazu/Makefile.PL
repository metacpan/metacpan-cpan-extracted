#
# Makefile.PL for Search::Namazu
#
# $Id: Makefile.PL 267 2006-06-09 05:43:51Z knok $
#

use ExtUtils::MakeMaker;

my $cflags = `nmz-config --cflags`;
my $libs = `nmz-config --libs`;

WriteMakefile(
	      'NAME' => 'Search::Namazu',
	      'VERSION_FROM' => 'Namazu.pm',
	      'INC' => $cflags,
	      'LIBS' => $libs,
	      'clean' => {'FILES' => "t/index"}
);
