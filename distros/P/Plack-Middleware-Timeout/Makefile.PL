use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Plack::Middleware::Timeout',
    VERSION_FROM => 'lib/Plack/Middleware/Timeout.pm',
    PREREQ_PM    => {
        'Scope::Guard' => 0,
        Plack          => 0,
        'Time::HiRes'  => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'    => 0,
        'HTTP::Message' => 0,
    },
    ABSTRACT => 'Timeout long running requests',
    AUTHOR   => 'Tomasz Czepiel <tjmc@cpan.org>',
    LICENSE  => 'perl',
);
