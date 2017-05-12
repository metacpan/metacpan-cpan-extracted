use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Plugtools::Plugins::HomeOU',
			  AUTHOR              => 'Zane C. Bowers <Zane C. Bowers>',
			  VERSION_FROM        => 'lib/Plugtools/Plugins/HomeOU.pm',
			  ABSTRACT_FROM       => 'lib/Plugtools/Plugins/HomeOU.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More'=>0,
							'Plugtools'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Plugtools-Plugins-HomeOU-*' },
			  );
