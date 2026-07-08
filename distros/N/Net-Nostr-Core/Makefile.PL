use strict;
use warnings;

use ExtUtils::MakeMaker;

my %runtime_requires = (
    'strictures'               => 2,
    'JSON'                     => 0,
    'Class::Tiny'              => 0,
    'CryptX'                   => 0,
    'Crypt::PK::ECC::Schnorr'  => 0,
    'Crypt::ScryptKDF'         => 0,
    'Bitcoin::Crypto'          => 0,
    'Bitcoin::BIP39'           => 0,
    'URI'                      => 0,
);

my %test_requires = (
    'Test2::V0'      => 0,
    'Clone'          => 0,
    'AnyEvent'       => 0,
    'AnyEvent::HTTP' => 0,
);

WriteMakefile(
    NAME             => 'Net::Nostr::Core',
    DISTNAME         => 'Net-Nostr-Core',
    AUTHOR           => 'Nicholas B. Hubbard <nicholashubbard@posteo.net>',
    ABSTRACT         => 'Core tooling for the Nostr protocol',
    VERSION_FROM     => 'lib/Net/Nostr/Core.pm',
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
                recommends => {
                    'AnyEvent::HTTP' => 0,
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
