use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::PT::Test',
    AUTHOR           => q{Paul Taylor <pftylr@gmail.com>},
    VERSION_FROM     => 'lib/Net/PT/Test.pm',
    ABSTRACT_FROM    => 'lib/Net/PT/Test.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Module::Signature' => 0,
    },
    PREREQ_PM => {
        'Carp' => 0,
        'CryptX' => '0.017',
        'JSON' => 0,
        'Mozilla::CA' => 0,
        'MIME::Base64' => '3.11',
        'Math::Random::Secure' => '0.05',
        'REST::Client' => 0,
        'Time::HiRes' => 0,
        'URI::Encode' => 0,
        'ExtUtils::MakeMaker' => 0,
        'Test::More' => 0,
        'Module::Signature' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-PT-Test-*' }
);
