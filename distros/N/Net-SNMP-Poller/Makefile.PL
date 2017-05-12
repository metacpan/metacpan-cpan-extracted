use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::SNMP::Poller',
    AUTHOR           => q{Satoshi Yagi <satoshi.yagi@yahoo.com>},
    VERSION_FROM     => 'lib/Net/SNMP/Poller.pm',
    ABSTRACT_FROM    => 'lib/Net/SNMP/Poller.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Net::SNMP'              => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-SNMP-Poller-*' },
);
