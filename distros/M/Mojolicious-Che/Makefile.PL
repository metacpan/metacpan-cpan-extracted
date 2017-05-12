use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Che',
    AUTHOR           => q{Михаил Че <mche@cpan.org>},
    VERSION_FROM     => 'lib/Mojolicious/Che.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Che.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious'              => 7.00,
        'Mojo::Log::Che' => 0.01,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #clean => { FILES => 'Mojolicious-Che-*' },
);
