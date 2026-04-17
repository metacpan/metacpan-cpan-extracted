use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::Nostr',
    DISTNAME     => 'Net-Nostr',
    AUTHOR       => 'Nicholas B. Hubbard <nicholashubbard@posteo.net>',
    ABSTRACT     => 'Client and relay library for the Nostr protocol',
    VERSION_FROM => 'lib/Net/Nostr.pm',
    LICENSE      => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    PREREQ_PM    => {
        'strictures'                    => 2,
        'AnyEvent'                      => 0,
        'AnyEvent::WebSocket::Client'   => 0,
        'AnyEvent::WebSocket::Server'   => 0,
        'AnyEvent::HTTP'                => 0,
        'CryptX'                        => 0,
        'Crypt::PK::ECC::Schnorr'      => 0,
        'Crypt::ScryptKDF'             => 0,
        'JSON'                          => 0,
        'Class::Tiny'                   => 0,
        'Bitcoin::Crypto'               => 0,
        'Bitcoin::BIP39'                => 0,
    },
    TEST_REQUIRES => {
        'Test2::V0'  => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
        'Clone'      => 0,
        'IO::Socket::SSL'     => 0,
    },
    META_MERGE => {
        resources   => {
            repository  => 'https://github.com/NicholasBHubbard/Net-Nostr',
            bugtracker  => 'https://github.com/NicholasBHubbard/Net-Nostr/issues',
        },
    },
);
