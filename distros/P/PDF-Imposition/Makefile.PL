use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PDF::Imposition',
    AUTHOR           => [
                         q{Marco Pessotto <melmothx@gmail.com>},
                         q{Daniel Drennan ElAwar <drennan@panix.com>},
                        ],
    VERSION_FROM     => 'lib/PDF/Imposition.pm',
    ABSTRACT_FROM    => 'lib/PDF/Imposition.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Try::Tiny' => 0,
    },
    PREREQ_PM => {
                  'PDF::API2' => 2.027,
                  'PDF::Cropmarks' => 0.11,
                  'Moo' => 0,
                  'Type::Tiny' => 1,
                  'namespace::clean' => 0,
                  # core modules
                  'File::Temp' => 0,
                  'File::Spec' => 0,
                  'File::Copy' => 0,
                  'Module::Load' => 0,
                  'File::Basename' => 0,
                  'Pod::Usage' => 0,
                 },
    EXE_FILES => [ 'bin/pdf-impose.pl' ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PDF-Imposition-*' },
    META_MERGE => {
                   resources => {
                                 repository => 'https://github.com/melmothx/pdf-imposition-perl',
                                 homepage => 'http://amusewiki.org',
                                 x_IRC => 'irc://chat.freenode.net/#amusewiki',
                                 x_WebIRC => 'https://webchat.freenode.net/?channels=#amusewiki',
                                },
                  },

);
