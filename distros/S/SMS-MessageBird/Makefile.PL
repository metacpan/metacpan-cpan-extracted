use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SMS::MessageBird',
    AUTHOR           => q{James Ronan <james@ronanweb.co.uk>},
    VERSION_FROM     => 'lib/SMS/MessageBird.pm',
    ABSTRACT_FROM    => 'lib/SMS/MessageBird.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Encode'         => 0,
        'JSON'           => 0,
        'LWP::UserAgent' => 0,
        'LWP::Protocol::https' => 0,
        'URI'                  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SMS-MessageBird-*' },
);
