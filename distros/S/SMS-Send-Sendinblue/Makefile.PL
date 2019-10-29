use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SMS::Send::Sendinblue',
    AUTHOR           => q{Julian Maurice <julian.maurice@biblibre.com>},
    VERSION_FROM     => 'lib/SMS/Send/Sendinblue.pm',
    ABSTRACT_FROM    => 'lib/SMS/Send/Sendinblue.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Carp' => '0',
        'HTTP::Headers' => '0',
        'JSON' => '0',
        'LWP::UserAgent' => '0',
        'SMS::Send::Driver' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SMS-Send-Sendinblue-*' },
);
