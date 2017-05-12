use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Net::DNS::RR::SRV::Helper',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Net/DNS/RR/SRV/Helper.pm',
			  ABSTRACT_FROM       => 'lib/Net/DNS/RR/SRV/Helper.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More' => 0,
							'Net::DNS::RR::SRV'=>0,
							'Sort::Naturally'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Net-DNS-RR-SRV-Helper-*' },
			  );
