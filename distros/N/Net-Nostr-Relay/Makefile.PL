use strict;
use warnings;

use ExtUtils::MakeMaker;

my %runtime_requires = (
    'strictures'                  => 2,
    'AnyEvent'                    => 0,
    'AnyEvent::WebSocket::Server' => 0,
    'Class::Tiny'                 => 0,
    'CryptX'                      => 0,
    'Crypt::PK::ECC::Schnorr'     => 0,
    'JSON'                        => 0,
    'Net::Nostr::Core'            => 0,
);

my %test_requires = (
    'Test2::V0'                   => 0,
    'AnyEvent::WebSocket::Client' => 0,
    'IO::Socket::SSL'             => 0,
);

WriteMakefile(
    NAME             => 'Net::Nostr::Relay',
    DISTNAME         => 'Net-Nostr-Relay',
    AUTHOR           => 'Nicholas B. Hubbard <nicholashubbard@posteo.net>',
    ABSTRACT         => 'WebSocket relay server for the Nostr protocol',
    VERSION_FROM     => 'lib/Net/Nostr/Relay.pm',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    PREREQ_PM        => \%runtime_requires,
    TEST_REQUIRES    => \%test_requires,
    test => {
        TESTS => 't/*.t t/nip/*.t',
    },
    META_ADD => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                requires => {
                    perl => '5.016',
                    %runtime_requires,
                },
            },
            test => {
                requires => \%test_requires,
            },
        },
        resources => {
            repository => 'https://github.com/NicholasBHubbard/Net-Nostr',
            bugtracker => 'https://github.com/NicholasBHubbard/Net-Nostr/issues',
        },
    },
);
