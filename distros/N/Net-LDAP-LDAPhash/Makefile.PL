use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Net::LDAP::LDAPhash',
			  AUTHOR              => 'Zane C. Bowers-Hadley <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Net/LDAP/LDAPhash.pm',
			  ABSTRACT_FROM       => 'lib/Net/LDAP/LDAPhash.pm',
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Net::LDAP' => 0,
							'Test::More' => 0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Net-LDAP-LDAPhash-*' },
			  );
