use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'NetworkInfo::Discovery::Nmap',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/NetworkInfo/Discovery/Nmap.pm',
    ABSTRACT_FROM       => 'lib/NetworkInfo/Discovery/Nmap.pm',
    PREREQ_PM => {
        'Carp' => 0,
        'NetworkInfo::Discovery' => '0.12', 
        'Nmap::Scanner' => '0.7', 
        'Sys::Hostname' => 0,
        'Test::More' => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'NetworkInfo-Discovery-Nmap-*' },
);
