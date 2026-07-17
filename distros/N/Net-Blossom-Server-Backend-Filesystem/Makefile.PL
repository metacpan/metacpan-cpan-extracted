use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Blossom::Server::Backend::Filesystem',
    DISTNAME         => 'Net-Blossom-Server-Backend-Filesystem',
    VERSION_FROM     => 'lib/Net/Blossom/Server/Backend/Filesystem.pm',
    ABSTRACT         => 'Filesystem storage backend for Net::Blossom::Server',
    AUTHOR           => 'Net::Blossom contributors',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'strictures' => '2',
    },
    PREREQ_PM        => {
        'Class::Tiny'          => '1.001',
        'Crypt::PRNG'          => '0',
        'File::Sync'           => '0.11',
        'Net::Blossom'         => '0.001001',
        'Net::Blossom::Server' => '0.001003',
        'strictures'           => '2',
    },
    TEST_REQUIRES    => {
        'DBD::SQLite' => '0',
        'DBI'         => '0',
        'Net::Blossom::Server::Backend::SQLite' => '0.001002',
        'Test::More'  => '0',
    },
    test             => {
        TESTS => 't/*.t',
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        prereqs     => {
            develop => {
                requires => {
                    'Pod::Coverage' => '0.23',
                    'Test::Pod' => '1.52',
                },
            },
        },
        resources   => {
            bugtracker => {
                web => 'https://github.com/NicholasBHubbard/Net-Blossom/issues',
            },
            homepage => 'https://github.com/NicholasBHubbard/Net-Blossom',
            repository => {
                type => 'git',
                url  => 'https://github.com/NicholasBHubbard/Net-Blossom.git',
                web  => 'https://github.com/NicholasBHubbard/Net-Blossom',
            },
        },
    },
);
