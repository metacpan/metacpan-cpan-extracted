use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Nginx::Log::Entry',
    AUTHOR           => q{David Farrell <davidnmfarrell@gmail.com>},
    VERSION_FROM     => 'lib/Nginx/Log/Entry.pm',
    ABSTRACT_FROM    => 'lib/Nginx/Log/Entry.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Nginx::ParseLog'       => 1.01,
        'Time::Piece'           => 0,
        'HTTP::BrowserDetect'   => 1.55,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Nginx-Log-Entry-*' },
);
