use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Blossom',
    DISTNAME         => 'Net-Blossom',
    VERSION_FROM     => 'lib/Net/Blossom.pm',
    ABSTRACT         => 'Perl client and protocol support for Blossom',
    AUTHOR           => 'Net::Blossom contributors',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'strictures' => '2',
    },
    PREREQ_PM        => {
        'CBOR::Free'        => '0.33',
        'Class::Tiny'       => '1.001',
        'JSON'              => '0',
        'Net::Nostr::Core'  => '0',
        'strictures'        => '2',
        'URI'               => '0',
    },
    test             => {
        TESTS => 't/*.t t/bud/*.t',
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
