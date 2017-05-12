use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Net::LDAP::AutoServer',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Net/LDAP/AutoServer.pm',
			  ABSTRACT_FROM       => 'lib/Net/LDAP/AutoServer.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More'=>0,
							'Sys::Hostname'=>0,
							'Net::LDAP'=>0,
							'Net::DNS'=>0,
							'Net::DNS::RR::SRV::Helper'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Net-LDAP-AutoServer-*' },
			  );
