use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Sys::Dev::LDAP::Populate',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Sys/Dev/LDAP/Populate.pm',
			  ABSTRACT_FROM       => 'lib/Sys/Dev/LDAP/Populate.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More'=>0,
							'Sys::Hostname'=>0,
							'Net::LDAP::AutoDNs'=>"0.2.1",
							'Net::LDAP::AutoServer'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Sys-Dev-LDAP-Populate-*' },
			  );
