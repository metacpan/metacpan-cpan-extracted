use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SMS::Send::MessageBird',
    AUTHOR           => q{James Ronan <james@ronanweb.co.uk>},
    VERSION_FROM     => 'lib/SMS/Send/MessageBird.pm',
    ABSTRACT_FROM    => 'lib/SMS/Send/MessageBird.pm',
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
        'SMS::Send::Driver' => 0,
        'SMS::MessageBird'  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SMS-Send-MessageBird-*' },
);
