use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Plack::Middleware::Debug::Template',
    AUTHOR           => q{Matthew Somerville <matthew@mysociety.org>},
    VERSION_FROM     => 'lib/Plack/Middleware/Debug/Template.pm',
    ABSTRACT_FROM    => 'lib/Plack/Middleware/Debug/Template.pm',
    LICENSE          => 'gpl_3,artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Class::Method::Modifiers' => 0,
        'Plack::Middleware::Debug' => 0,
        'Text::MicroTemplate' => 0,
        'Time::HiRes' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Plack-Middleware-Debug-Template-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/mysociety/Plack-Middleware-Debug-Template',
            bugtracker => 'https://github.com/mysociety/Plack-Middleware-Debug-Template/issues',
        },
    },
);
