use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'NetworkInfo::Discovery::Rendezvous',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/NetworkInfo/Discovery/Rendezvous.pm',
    ABSTRACT_FROM       => 'lib/NetworkInfo/Discovery/Rendezvous.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0,
        'NetworkInfo::Discovery' => '0.12', 
        'Net::Rendezvous' => '0.90', 
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'NetworkInfo-Discovery-Rendezvous-*' },
);
