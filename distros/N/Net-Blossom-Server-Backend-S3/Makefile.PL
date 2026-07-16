use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Blossom::Server::Backend::S3',
    DISTNAME         => 'Net-Blossom-Server-Backend-S3',
    VERSION_FROM     => 'lib/Net/Blossom/Server/Backend/S3.pm',
    ABSTRACT         => 'S3-compatible storage backend for Net::Blossom::Server',
    AUTHOR           => 'Net::Blossom contributors',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'strictures' => '2',
    },
    PREREQ_PM        => {
        'Class::Tiny'          => '1.001',
        'Crypt::PRNG'          => '0',
        'Net::Amazon::S3'      => '0.992',
        'Net::Blossom'         => '0.001001',
        'Net::Blossom::Server' => '0.001002',
        'strictures'           => '2',
        'URI'                  => '0',
    },
    TEST_REQUIRES    => {
        'DBD::SQLite' => '0',
        'DBI'         => '0',
        'HTTP::Message' => '0',
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
