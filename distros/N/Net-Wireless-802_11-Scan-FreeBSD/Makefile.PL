use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Wireless::802_11::Scan::FreeBSD',
    AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
    VERSION_FROM     => 'lib/Net/Wireless/802_11/Scan/FreeBSD.pm',
    ABSTRACT_FROM    => 'lib/Net/Wireless/802_11/Scan/FreeBSD.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
	'String::ShellQuote' => '1.04',
    },
    PREREQ_PM => {
	'Error::Helper'=>'1.0.0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Wireless-802_11-Scan-FreeBSD-*' },
);
