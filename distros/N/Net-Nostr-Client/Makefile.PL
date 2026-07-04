use strict;
use warnings;

use ExtUtils::MakeMaker;

my %runtime_requires = (
    'strictures'                  => 2,
    'Class::Tiny'                 => 0,
    'AnyEvent'                    => 0,
    'AnyEvent::WebSocket::Client' => 0,
    'Net::Nostr::Core'            => 0,
);

my %test_requires = (
    'Test2::V0' => 0,
);

WriteMakefile(
    NAME             => 'Net::Nostr::Client',
    DISTNAME         => 'Net-Nostr-Client',
    AUTHOR           => 'Nicholas B. Hubbard <nicholashubbard@posteo.net>',
    ABSTRACT         => 'WebSocket client for Nostr relays',
    VERSION_FROM     => 'lib/Net/Nostr/Client.pm',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    PREREQ_PM        => \%runtime_requires,
    TEST_REQUIRES    => \%test_requires,
    test => {
        TESTS => 't/*.t',
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
