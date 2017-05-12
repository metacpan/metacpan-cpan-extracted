use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PDF::Cropmarks',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/PDF/Cropmarks.pm',
    ABSTRACT_FROM    => 'lib/PDF/Cropmarks.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
                       'Test::More' => 0,
    },
    PREREQ_PM => {
                  'PDF::API2' => 2.027,
                  'Moo' => 0,
                  'Type::Tiny' => 1,
                  'namespace::clean' => 0,
                 },
    EXE_FILES => [ 'bin/pdf-cropmarks.pl' ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PDF-Cropmarks-*' },
    META_MERGE => {
                   resources => {
                                 repository => 'https://github.com/melmothx/pdf-cropmarks-perl',
                                 homepage => 'http://amusewiki.org',
                                 x_IRC => 'irc://chat.freenode.net/#amusewiki',
                                 x_WebIRC => 'https://webchat.freenode.net/?channels=#amusewiki',
                                },
                  },

);
