use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Wireless::802_11::WPA::CLI',
    AUTHOR              => 'Zane C. Bowers-Hadley <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/Net/Wireless/802_11/WPA/CLI.pm',
    ABSTRACT_FROM       => 'lib/Net/Wireless/802_11/WPA/CLI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Error::Helper'=>0,
		'String::ShellQuote'=>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Wireless-802_11-WPA-CLI-*' },
	);
