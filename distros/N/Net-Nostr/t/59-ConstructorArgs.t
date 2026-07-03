#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;
use Crypt::PK::ECC;

use Net::Nostr::_ConstructorArgs ();
use Net::Nostr::Blossom;
use Net::Nostr::Client;
use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::FollowList;
use Net::Nostr::Key;
use Net::Nostr::List;
use Net::Nostr::Message;
use Net::Nostr::Negentropy;
use Net::Nostr::Relay;
use Net::Nostr::RelayInfo;
use Net::Nostr::RelayList;
use Net::Nostr::RelayStore;
use Net::Nostr::RemoteSigning;
use Net::Nostr::WalletConnect;
use Net::Nostr::Zap;

my $CRYPTPKECC = Crypt::PK::ECC->new->generate_key('secp256k1');

subtest 'normalizer accepts flat hashes and hash references' => sub {
    is({Net::Nostr::_ConstructorArgs::normalize(foo => 1)}, {foo => 1}, 'flat hash');
    is({Net::Nostr::_ConstructorArgs::normalize({foo => 1})}, {foo => 1}, 'hash reference');
    is({Net::Nostr::_ConstructorArgs::normalize()}, {}, 'empty argument list');
    like(dies { Net::Nostr::_ConstructorArgs::normalize('foo') },
        qr/hash or hash reference/, 'odd flat list rejected');
};

subtest 'representative constructors accept hash references' => sub {
    my $event = Net::Nostr::Event->new({
        pubkey     => 'a' x 64,
        kind       => 1,
        content    => 'hello',
        created_at => 1,
    });

    my @cases = (
        ['Net::Nostr::Blossom->new',    sub { Net::Nostr::Blossom->new({}) },                         'Net::Nostr::Blossom'],
        ['Net::Nostr::Client->new',     sub { Net::Nostr::Client->new({}) },                          'Net::Nostr::Client'],
        ['Net::Nostr::Event->new',      sub { $event },                                               'Net::Nostr::Event'],
        ['Net::Nostr::Filter->new',     sub { Net::Nostr::Filter->new({kinds => [1]}) },              'Net::Nostr::Filter'],
        ['Net::Nostr::FollowList->new', sub { Net::Nostr::FollowList->new({}) },                      'Net::Nostr::FollowList'],
        ['Net::Nostr::Key->new',        sub { Net::Nostr::Key->new({pubkey => \$CRYPTPKECC->export_key_der('public')}) }, 'Net::Nostr::Key'],
        ['Net::Nostr::List->new',       sub { Net::Nostr::List->new({kind => 30000}) },               'Net::Nostr::List'],
        ['Net::Nostr::Message->new',    sub { Net::Nostr::Message->new({type => 'NOTICE', message => 'notice'}) }, 'Net::Nostr::Message'],
        ['Net::Nostr::Negentropy->new', sub { Net::Nostr::Negentropy->new({frame_size_limit => 1024}) }, 'Net::Nostr::Negentropy'],
        ['Net::Nostr::Relay->new',      sub { Net::Nostr::Relay->new({verify_signatures => 0}) },     'Net::Nostr::Relay'],
        ['Net::Nostr::RelayInfo->new',  sub { Net::Nostr::RelayInfo->new({name => 'relay'}) },        'Net::Nostr::RelayInfo'],
        ['Net::Nostr::RelayList->new',  sub { Net::Nostr::RelayList->new({}) },                       'Net::Nostr::RelayList'],
        ['Net::Nostr::RelayStore->new', sub { Net::Nostr::RelayStore->new({max_events => 1}) },       'Net::Nostr::RelayStore'],
        ['Net::Nostr::Zap->new_request', sub {
            Net::Nostr::Zap->new_request({p => 'b' x 64, relays => ['wss://relay.example.com']});
        }, 'Net::Nostr::Zap'],
        ['Net::Nostr::Zap->new_receipt', sub {
            Net::Nostr::Zap->new_receipt({p => 'b' x 64, bolt11 => 'lnbc1test', description => '{}'});
        }, 'Net::Nostr::Zap'],
    );

    for my $case (@cases) {
        my ($name, $build, $isa) = @$case;
        my $object = $build->();
        isa_ok($object, [$isa], $name);
    }
};

subtest 'private inner constructors accept hash references' => sub {
    my @cases = (
        ['Net::Nostr::RemoteSigning::BunkerConnection->new', sub {
            Net::Nostr::RemoteSigning::BunkerConnection->new({
                remote_signer_pubkey => 'a' x 64,
                secret               => 'secret',
                relays               => ['wss://relay.example.com'],
            });
        }, 'Net::Nostr::RemoteSigning::BunkerConnection'],
        ['Net::Nostr::RemoteSigning::NostrConnect->new', sub {
            Net::Nostr::RemoteSigning::NostrConnect->new({
                client_pubkey => 'a' x 64,
                secret        => 'secret',
                relays        => ['wss://relay.example.com'],
            });
        }, 'Net::Nostr::RemoteSigning::NostrConnect'],
        ['Net::Nostr::RemoteSigning::Request->new', sub {
            Net::Nostr::RemoteSigning::Request->new({
                id     => 'req-1',
                method => 'sign_event',
                params => ['{}'],
            });
        }, 'Net::Nostr::RemoteSigning::Request'],
        ['Net::Nostr::RemoteSigning::Response->new', sub {
            Net::Nostr::RemoteSigning::Response->new({id => 'req-1', result => 'ok'});
        }, 'Net::Nostr::RemoteSigning::Response'],
        ['Net::Nostr::WalletConnect::Connection->new', sub {
            Net::Nostr::WalletConnect::Connection->new({
                wallet_pubkey => 'a' x 64,
                secret        => 'secret',
                relays        => ['wss://relay.example.com'],
            });
        }, 'Net::Nostr::WalletConnect::Connection'],
        ['Net::Nostr::WalletConnect::Info->new', sub {
            Net::Nostr::WalletConnect::Info->new({
                capabilities       => ['pay_invoice'],
                encryption         => ['nip44_v2'],
                notification_types => ['payment_received'],
            });
        }, 'Net::Nostr::WalletConnect::Info'],
        ['Net::Nostr::WalletConnect::Response->new', sub {
            Net::Nostr::WalletConnect::Response->new({result_type => 'pay_invoice', result => {}});
        }, 'Net::Nostr::WalletConnect::Response'],
        ['Net::Nostr::WalletConnect::Notification->new', sub {
            Net::Nostr::WalletConnect::Notification->new({
                notification_type => 'payment_received',
                notification      => {},
            });
        }, 'Net::Nostr::WalletConnect::Notification'],
    );

    for my $case (@cases) {
        my ($name, $build, $isa) = @$case;
        my $object = $build->();
        isa_ok($object, [$isa], $name);
    }
};

done_testing;
