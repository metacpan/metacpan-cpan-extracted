use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Interface::Wireless::FreeBSD',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/Net/Interface/Wireless/FreeBSD.pm',
    ABSTRACT_FROM       => 'lib/Net/Interface/Wireless/FreeBSD.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Interface-Wireless-FreeBSD-*' },
);
