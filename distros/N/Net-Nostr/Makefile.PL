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
    PREREQ_PM    => {
        'strictures'                    => 2,
        'AnyEvent'                      => 0,
        'AnyEvent::WebSocket::Client'   => 0,
        'AnyEvent::WebSocket::Server'   => 0,
        'AnyEvent::Socket'              => 0,
        'Crypt::KeyDerivation'          => 0,
        'Crypt::Mac::HMAC'             => 0,
        'Crypt::PK::ECC'               => 0,
        'Crypt::PK::ECC::Schnorr'      => 0,
        'Crypt::PRNG'                   => 0,
        'Crypt::Stream::ChaCha'        => 0,
        'Digest::SHA'                   => 0,
        'JSON'                          => 0,
        'Class::Tiny'                   => 0,
        'Bitcoin::Crypto::Bech32'       => 0,
    },
    TEST_REQUIRES => {
        'Test2::V0'  => 0,
        'Test::Pod'  => 0,
        'Clone'      => 0,
    },
    META_MERGE => {
        resources   => {
            repository  => 'https://github.com/NicholasBHubbard/Net-Nostr',
            bugtracker  => 'https://github.com/NicholasBHubbard/Net-Nostr/issues',
        },
    },
);
