use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Net::LDAP::AutoDNs',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Net/LDAP/AutoDNs.pm',
			  ABSTRACT_FROM       => 'lib/Net/LDAP/AutoDNs.pm',
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More' => 0,
							'Sys::Hostname'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Net-LDAP-AutoDNs-*' },
			  );
