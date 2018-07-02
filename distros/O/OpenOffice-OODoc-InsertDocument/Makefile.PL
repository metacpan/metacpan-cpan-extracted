use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'OpenOffice::OODoc::InsertDocument',
    AUTHOR           => q{Theo van Hoesel <theo@mintlab.nl>},
    VERSION_FROM     => 'lib/OpenOffice/OODoc/InsertDocument.pm',
    ABSTRACT_FROM    => 'lib/OpenOffice/OODoc/InsertDocument.pm',
    LICENSE          => 'eupl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'           => 0,
    },
    BUILD_REQUIRES => {
        'Test::Most'                    => 0,
    },
    PREREQ_PM => {
        'OpenOffice::OODoc'             => 0,
        'List::Utils'                   => 0,
        'Readonly'                      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'OpenOffice-OODoc-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/mintlab/perl-openoffice-oodoc-insertdocument.git',
                web  => 'https://gitlab.com/mintlab/perl-openoffice-oodoc-insertdocument.git',
            },
        }})
     : ()
    ),
);
