use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Joker::DMAPI',
    AUTHOR           => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM     => 'lib/Net/Joker/DMAPI.pm',
    ABSTRACT_FROM    => 'lib/Net/Joker/DMAPI.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Data::Censor'   => 0,
        'Data::Dump'     => 0,
        'DateTime'       => 0,
        'Hash::Merge'    => 0,
        'LWP::UserAgent' => 0,
        'Moo'          => 0,
        'MooX::Types::MooseLike::Base' => 0,
        URI              => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Joker-DMAPI-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/bigpresh/Net-Joker-DMAPI',
            bugtracker => 'https://github.com/bigpresh/Net-Joker-DMAPI/issues',
            homepage   => 'https://github.com/bigpresh/Net-Joker-DMAPI',
        },
    },
);
