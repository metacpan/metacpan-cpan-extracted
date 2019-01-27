use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Sub::Fp',
    AUTHOR           => q{Kristopher C. Paulsen <kristopherpaulsen+cpan@gmail.com>},
    VERSION_FROM     => 'lib/Sub/Fp.pm',
    ABSTRACT_FROM    => 'lib/Sub/Fp.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'strict'   => '0',
        'warnings' => '0',
        'Exporter' => '0',
    },
    PREREQ_PM => {
        'Test::Class' => '0',
        'Test::More'  => '0',
        'List::Util'  => '0',
        'Carp'        => '0',
        'POSIX'       => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Sub-Fp-*' },
);
