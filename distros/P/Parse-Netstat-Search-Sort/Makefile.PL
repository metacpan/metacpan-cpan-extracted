use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME             => 'Parse::Netstat::Search::Sort',
			  AUTHOR           => q{Zame C. Bowers-Hadley <vvelox@vvelox.net>},
			  VERSION_FROM     => 'lib/Parse/Netstat/Search/Sort.pm',
			  ABSTRACT_FROM    => 'lib/Parse/Netstat/Search/Sort.pm',
			  LICENSE          => 'artistic_2',
			  PL_FILES         => {},
			  MIN_PERL_VERSION => '5.006',
			  CONFIGURE_REQUIRES => {
									 'ExtUtils::MakeMaker' => '0',
									 },
			  BUILD_REQUIRES => {
								 'Test::More' => '0',
								 },
			  PREREQ_PM => {
							'Error::Helper'=>'1.0.0',
							'Parse::Netstat'=>'0.14',
							'Parse::Netstat::Search'=>'0.0.0',
							'Net::IP'=>'1.26',
							},
			  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean => { FILES => 'Parse-Netstat-Search-Sort-*' },
			  );
