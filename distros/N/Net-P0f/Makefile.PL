use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'Net::P0f',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Net/P0f.pm',
    ABSTRACT_FROM       => 'lib/Net/P0f.pm',
    PREREQ_PM => {
        'Net::Pcap' => '0.05',
        'Test::More' => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-P0f-*' },
);
