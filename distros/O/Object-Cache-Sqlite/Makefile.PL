use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Object::Cache::Sqlite',
    AUTHOR           => 'Scott Baker <scott@perturb.org>',
    VERSION_FROM     => 'lib/Object/Cache/Sqlite.pm',
    ABSTRACT_FROM    => 'lib/Object/Cache/Sqlite.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test::More' => '0.96',
    },
    PREREQ_PM => {
        'DBI'               => '0',
        'DBD::SQLite'       => '0',
        'Cpanel::JSON::XS'  => '0',
        'Carp'              => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/scottchiefbaker/perl-Object-Cache-Sqlite.git',
                web  => 'https://github.com/scottchiefbaker/perl-Object-Cache-Sqlite',
            },
        },
    },
);
