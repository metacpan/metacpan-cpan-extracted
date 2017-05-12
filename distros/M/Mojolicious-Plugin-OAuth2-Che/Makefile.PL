use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::OAuth2::Che',
    AUTHOR           => q{Михаил Че (Mikhail Che) <mche[-at-]cpan.org>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/OAuth2/Che.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/OAuth2/Che.pm',
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
        'Mojolicious'=>6.00,
        'Mojolicious::Plugin::OAuth2'=>1.29,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ###clean => { FILES => 'Mojolicious-Plugin-OAuth2-Che-*' },
);
