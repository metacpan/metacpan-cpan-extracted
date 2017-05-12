use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Semantics3',
    AUTHOR           => q{Sivamani Varun <varun@semantics3.com>},
    VERSION_FROM     => 'lib/Net/Semantics3.pm',
    ABSTRACT_FROM    => 'lib/Net/Semantics3.pm',
    LICENSE          => 'MIT_License',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moose'                 => '2.0602',
        'methods'               => 0,
        'LWP::UserAgent'        => 0,
        'LWP::Protocol::https'  => 0,
        'OAuth::Lite::Consumer' => 0,
        'HTTP::Request::Common' => 0,
        'MIME::Base64'          => 0,
        'URI::Escape'           => 0,
        'JSON::XS'              => 0,
        'Test::Exception'       => 0,
        'Throwable'             => 0,
        'namespace::clean'      => 0,
        'Data::Dumper'          => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Semantics3-*' },
);
