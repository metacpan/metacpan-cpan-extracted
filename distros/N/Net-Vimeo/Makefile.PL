use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Vimeo',
    AUTHOR           => q{Mirela Iclodean <imirela@cpan.org>},
    VERSION_FROM     => 'lib/Net/Vimeo.pm',
    ABSTRACT_FROM    => 'lib/Net/Vimeo.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'Carp'                  => 0,
        'Clone'                 => 0,
        'Digest::SHA'           => 0,
        'Encode'                => 0,
        'HTTP::Request'         => 0,
        'HTTP::Request::Common' => 0, 
        'JSON'                  => 2.90,
        'LWP::UserAgent'        => 0.32,
        'Moose'                 => 0,
        'Moose::Role'           => 0,
        'namespace::autoclean'  => 0,
        'Net::OAuth'            => 0.28,
        'Types::Standard'       => 0.044,
        'URI'                   => 1.60,
        'URI::Escape'           => 3.31,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Vimeo-*' },
);
