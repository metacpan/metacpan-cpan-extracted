use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME             => 'Net::Connection::Match',
			  AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
			  VERSION_FROM     => 'lib/Net/Connection/Match.pm',
			  ABSTRACT_FROM    => 'lib/Net/Connection/Match.pm',
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
							'Net::CIDR'=>'0.20',
							'Net::Connection'=>'0.2.0',
							'Net::DNS'=>'1.20',
							'Proc::ProcessTable' => '0.59',
							'Error::Helper' => '1.0.0',
							},
			  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean => { FILES => 'Net-Connection-Match-*' },
			  );
