use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'OpenServices::SNMP::Plugin::CVE',
    AUTHOR           => q{Michael Fladischer <FladischerMichael@fladi.at>},
    VERSION_FROM     => 'lib/OpenServices/SNMP/Plugin/CVE.pm',
    ABSTRACT_FROM    => 'lib/OpenServices/SNMP/Plugin/CVE.pm',
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
        'NetSNMP::agent'    => 5,
        'NetSNMP::ASN'    => 5,
        'NetSNMP::OID'    => 5,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'OpenServices-SNMP-Plugin-CVE-*' },
);
