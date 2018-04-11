use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SMS::Send::Iletimerkezi',
    AUTHOR           => q{Engin Dumlu <engindumlu@gmail.com>},
    VERSION_FROM     => 'lib/SMS/Send/Iletimerkezi.pm',
    ABSTRACT_FROM    => 'lib/SMS/Send/Iletimerkezi.pm',
    LICENSE          => 'gpl_3',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        # "SMS::Send" => '0',
        # "XML::Writer" => '0',
        # "LWP::UserAgent" => '0',
        # "LWP::Protocol::https" => '0',
        # "Digest::SHA" => '0',
    },
    PREREQ_PM => {
        "SMS::Send" => 0.01,
        "XML::Writer" => 0.01,
        "LWP::UserAgent" => 0.01,
        "LWP::Protocol::https" => 0.01,
        "Digest::SHA" => 0.01,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SMS-Send-Iletimerkezi-*' },
    "test" => {
        "TESTS" => "t/*.t"
    },
    "TEST_REQUIRES" => {
        "Test::More" => "0.88",
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/roadrunner/sms-send-iletimerkezi',
            bugtracker => 'https://github.com/roadrunner/sms-send-iletimerkezi/issues',
        },
    },
);
