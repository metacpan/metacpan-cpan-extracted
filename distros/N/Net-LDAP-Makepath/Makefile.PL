use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Net::LDAP::Makepath',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Net/LDAP/Makepath.pm',
			  ABSTRACT_FROM       => 'lib/Net/LDAP/Makepath.pm',
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More' => 0,
							'Net::LDAP::Entry' => 0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Net-LDAP-Makepath-*' },
			  );
