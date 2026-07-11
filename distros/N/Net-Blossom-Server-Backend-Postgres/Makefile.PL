use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Blossom::Server::Backend::Postgres',
    DISTNAME         => 'Net-Blossom-Server-Backend-Postgres',
    VERSION_FROM     => 'lib/Net/Blossom/Server/Backend/Postgres.pm',
    ABSTRACT         => 'Postgres storage backend for Net::Blossom::Server',
    AUTHOR           => 'Net::Blossom contributors',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'strictures' => '2',
    },
    PREREQ_PM        => {
        'DBD::Pg'              => '0',
        'DBI'                  => '0',
        'Net::Blossom'         => '0.001000',
        'Net::Blossom::Server' => '0.001000',
        'strictures'           => '2',
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
