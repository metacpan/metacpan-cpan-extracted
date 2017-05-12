use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::Helper::Vars',
    AUTHOR           => q{Михаил Че <mche@cpan.org>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/Helper/Vars.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/Helper/Vars.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious'              => 6.00,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #clean => { FILES => 'Mojolicious-Plugin-Helper-Vars-*' },
);
