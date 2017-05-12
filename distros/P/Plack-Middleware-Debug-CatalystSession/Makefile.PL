use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Plack::Middleware::Debug::CatalystSession',
    AUTHOR           => q{Thomas Kuyper <tkuyper@cpan.org>},
    VERSION_FROM     => 'lib/Plack/Middleware/Debug/CatalystSession.pm',
    ABSTRACT_FROM    => 'lib/Plack/Middleware/Debug/CatalystSession.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.94',
        'FindBin' => 0,
        'Catalyst::Test' => 0
    },
    PREREQ_PM => {
        'Catalyst' => '5.90050',
        'Catalyst::Plugin::Session' => 0,
        'Data::Dumper' => 0,
        'Class::Method::Modifiers' => 0,
        'HTML::Entities' => 0,
        'Plack::Middleware::Debug' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Plack-Middleware-Debug-CatalystSession-*' },
);
