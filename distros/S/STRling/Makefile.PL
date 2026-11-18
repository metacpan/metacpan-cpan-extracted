use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'STRling',
    AUTHOR           => 'STRling Team',
    VERSION_FROM     => 'lib/STRling.pm',
    ABSTRACT_FROM    => 'lib/STRling.pm',
    LICENSE          => 'apache_2_0',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'JSON::PP'   => '0',
    },
    PREREQ_PM => {
        'FFI::Platypus' => '2.10',
        'JSON::PP'      => '4.00',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'STRling-*' },
);
