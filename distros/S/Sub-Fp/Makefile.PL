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
        'strict'   => '1',
        'warnings' => '1',
        'Exporter' => '1',
    },
    PREREQ_PM => {
        'Test::Class' => '1',
        'Test::More'  => '1',
        'List::Util'  => '1',
        'Carp'        => '1',
        'POSIX'       => '1',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Sub-Fp-*' },
);
