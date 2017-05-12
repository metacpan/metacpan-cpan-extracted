use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MooX::ReturnModifiers',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/MooX/ReturnModifiers.pm',
    ABSTRACT_FROM    => 'lib/MooX/ReturnModifiers.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Exporter' => 0,
        'Moo' => "1.001001",
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Exporter' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooX-ReturnModifiers-*' },
);
