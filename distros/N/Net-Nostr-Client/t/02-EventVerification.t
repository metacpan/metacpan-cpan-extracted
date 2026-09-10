#!/usr/bin/perl

use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();
use Net::Nostr::Event;
use Net::Nostr::Key;

use lib 't/lib';
use TestFixtures qw(make_signed_event client_connection);

my $json = JSON->new->utf8;
my $event = make_signed_event(
    content => "hello \x{1F600}\n\"quoted\"",
    tags => [['t', "\x{2603}"]],
);

subtest 'signed event reaches the callback unchanged' => sub {
    my ($client, $conn) = client_connection();
    my @received;
    $client->on(event => sub { push @received, [$_[0], $_[1]->to_hash] });

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $conn->receive($json->encode(['EVENT', 'verified', $event->to_hash]));

    is \@received, [['verified', $event->to_hash]],
        'subscription ID and all event fields survive the wire round-trip';
    is \@warnings, [], 'valid event produces no warning';
};

my $other_key = Net::Nostr::Key->new;
my @invalid = (
    ['tampered content', { %{$event->to_hash}, content => 'tampered' }, qr/id does not match event hash/],
    ['incorrect ID', { %{$event->to_hash}, id => '0' x 64 }, qr/id does not match event hash/],
    ['invalid signature', { %{$event->to_hash}, sig => '0' x 128 }, qr/signature is invalid/],
    ['signature from another key', {
        %{$event->to_hash}, sig => unpack('H*', $other_key->schnorr_sign($event->id)),
    }, qr/signature is invalid/],
    ['invalid curve public key', Net::Nostr::Event->new(
        pubkey => 'f' x 64, kind => 1, content => 'invalid public key',
        created_at => 1000, tags => [], sig => $event->sig,
    )->to_hash, qr/invalid event from relay:/],
);

for my $case (@invalid) {
    my ($name, $hash, $reason) = @$case;
    subtest "$name is dropped without disrupting later messages" => sub {
        my ($client, $conn) = client_connection();
        my @received;
        $client->on(event => sub { push @received, ['EVENT', $_[0], $_[1]->to_hash] });
        $client->on(eose => sub { push @received, ['EOSE', $_[0]] });

        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        ok lives {
            $conn->receive($json->encode(['EVENT', 'verified', $hash]));
        }, 'verification failure does not escape the receive handler';

        is \@received, [], 'invalid event never reaches the callback';
        is scalar @warnings, 1, 'one warning for the invalid event';
        like $warnings[0], qr/^invalid event from relay:/, 'warning identifies rejected relay event';
        like $warnings[0], $reason, 'warning includes the verification failure';
        ok $client->is_connected, 'connection remains open';

        $conn->receive($json->encode(['EVENT', 'verified', $event->to_hash]));
        $conn->receive($json->encode(['EOSE', 'verified']));
        is \@received, [
            ['EVENT', 'verified', $event->to_hash], ['EOSE', 'verified'],
        ], 'valid event and EOSE still arrive on the same connection';
        is scalar @warnings, 1, 'later valid messages produce no additional warnings';
    };
}

done_testing;
