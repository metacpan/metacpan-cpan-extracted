use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Net::Wireless::802_11::WPA::CLI::Helper',
	AUTHOR              => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM        => 'lib/Net/Wireless/802_11/WPA/CLI/Helper.pm',
	ABSTRACT_FROM       => 'lib/Net/Wireless/802_11/WPA/CLI/Helper.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
	 ? ('LICENSE'=> 'perl')
	 : ()),
	PL_FILES            => {},
	PREREQ_PM => {
		'Test::More' => 0,
		'Error::Helper'=>0,
		'Net::Wireless::802_11::WPA::CLI'=>0,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Net-Wireless-802_11-WPA-CLI-Helper-*' },
	);
