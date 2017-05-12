use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Amazon::DirectConnect',
    AUTHOR           => q{Cameron Daniel <cameron.daniel@megaport.com>},
    VERSION_FROM     => 'lib/Net/Amazon/DirectConnect.pm',
    LICENSE          => 'open_source',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Net::Amazon::Signature::V4'    => 0.14,
        'JSON'                          => 0,
        'YAML::Tiny'                    => 1.0,
        'LWP::UserAgent'                => 6.0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Amazon-DirectConnect-*' },
);
