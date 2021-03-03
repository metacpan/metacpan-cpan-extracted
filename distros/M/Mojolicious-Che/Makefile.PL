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
        'Mojolicious'  => 9.02,
        'Mojo::Log::Che' => 0.01,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
          repository => {
            type => 'git',
            url => 'git://github.com/mche/Mojolicious-Che.git',
            web => 'https://github.com/mche/Mojolicious-Che',
          },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #clean => { FILES => 'Mojolicious-Che-*' },
);
