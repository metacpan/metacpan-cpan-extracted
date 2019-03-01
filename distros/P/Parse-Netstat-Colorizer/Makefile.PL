use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME             => 'Parse::Netstat::Colorizer',
			  AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
			  VERSION_FROM     => 'lib/Parse/Netstat/Colorizer.pm',
			  ABSTRACT_FROM    => 'lib/Parse/Netstat/Colorizer.pm',
			  LICENSE          => 'artistic_2',
			  PL_FILES         => {},
			  MIN_PERL_VERSION => '5.006',
			  INST_SCRIPT => 'bin',
			  CONFIGURE_REQUIRES => {
									 'ExtUtils::MakeMaker' => '0',
									 },
			  BUILD_REQUIRES => {
								 'Test::More' => '0',
								 },
			  PREREQ_PM => {
							'Parse::Netstat'=>'0.14',
							'Error::Helper'=>'1.0.0',
							'Parse::Netstat::Search'=>'0.1.1',
							'Parse::Netstat::Search::Sort'=>'0.0.0',
							'Term::ANSIColor'=>'0.0.0',
							'Text::Table'=>'0.0.0',
							'Getopt::Long'=>'0.0.0',
							},
			  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean => { FILES => 'Parse-Netstat-Colorizer-*' },
			  );
