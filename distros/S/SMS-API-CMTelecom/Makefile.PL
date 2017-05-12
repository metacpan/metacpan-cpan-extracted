use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SMS::API::CMTelecom',
    AUTHOR           => q{Dominic Sonntag <dominic@s5g.de>},
    VERSION_FROM     => 'lib/SMS/API/CMTelecom.pm',
    ABSTRACT_FROM    => 'lib/SMS/API/CMTelecom.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'          => 0,
        'Test::CheckManifest' => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Pod'           => 0,
        'SMS::Send'           => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent'       => 0,
        'LWP::Protocol::https' => 0,
        'JSON'                 => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SMS-API-CMTelecom-*' },
);
