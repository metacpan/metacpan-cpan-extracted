use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'POD::Walker',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/POD/Walker.pm',
			  ABSTRACT_FROM       => 'lib/POD/Walker.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'Script::isAperlScript'=>0,
							'Pod::Html'=>0,
							'Pod::LaTeX'=>0,
							'Pod::Man'=>0,
							'Pod::Text'=>0,
							'File::Copy'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'POD-Walker-*' },
			  );
