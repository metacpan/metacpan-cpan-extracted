use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::InputValidation',
    AUTHOR           => q{Tobias Leich <froggs@cpan.org>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/InputValidation.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/InputValidation.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Mojolicious' => '0',
    },
    META_MERGE => {
        no_index => {
            package => [qw(
                IV_DATETIME IV_OBJECT IV_ARRAY IV_INT IV_FLOAT IV_WORD IV_ANY
            )],
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-InputValidation-*' },
);
