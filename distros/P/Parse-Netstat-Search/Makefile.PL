use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME             => 'Parse::Netstat::Search',
			  AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
			  VERSION_FROM     => 'lib/Parse/Netstat/Search.pm',
			  ABSTRACT_FROM    => 'lib/Parse/Netstat/Search.pm',
			  LICENSE          => 'artistic_2',
			  PL_FILES         => {},
			  MIN_PERL_VERSION => '5.006',
			  CONFIGURE_REQUIRES => {
									 'ExtUtils::MakeMaker' => '0',
									 },
			  BUILD_REQUIRES => {
								 'Test::More' => '0',
								 'Net::CIDR' => '0',
								 'Parse::Netstat'=>'0.14',
								 'Error::Helper' => '1.0.0',
								 'Net::DNS' => '1.20',
								 },
			  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean => { FILES => 'Parse-Netstat-Search-*' },
			  );
