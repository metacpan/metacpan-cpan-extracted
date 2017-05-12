use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Net::IP::Lite',
	AUTHOR              => 'Alexey A. Komarov <alexkom@cpan.org>',
	VERSION_FROM        => 'lib/Net/IP/Lite.pm',
	ABSTRACT_FROM       => 'lib/Net/IP/Lite.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'perl') : ()),
	PL_FILES            => { },
	PREREQ_PM           => {
		'Test::More'      => '0',
		'Test::Exception' => '0'
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Net-IP-Lite-*' },
);
