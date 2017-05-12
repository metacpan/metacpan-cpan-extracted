use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Net::OAuth::Yahoo',
    AUTHOR        => q{Satoshi Yagi <satoshi.yagi@yahoo.com>},
    VERSION_FROM  => 'lib/Net/OAuth/Yahoo.pm',
    ABSTRACT_FROM => 'lib/Net/OAuth/Yahoo.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'           => 0,
        'LWP::UserAgent'       => 0,
        'Data::Dumper'         => 0,
        'Net::OAuth'           => 0,
        'URI::Escape'          => 0,
        'WWW::Mechanize'       => 0,
        'YAML::Syck'           => 0,
        'Crypt::SSLeay'        => 0,
        'LWP::Protocol::https' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net-OAuth-Yahoo-*' },
);
