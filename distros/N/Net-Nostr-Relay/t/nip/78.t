use strictures 2;
use Test2::V0 -no_srand => 1;
use Net::Nostr::Relay;
use Net::Nostr::Negentropy;
use lib 't/lib';
use TestFixtures qw(free_port relay_peer make_key_from_hex signed_event);

my $owner = make_key_from_hex('1' x 64);
my $other = make_key_from_hex('2' x 64);
for my $kind (78, 30078) {
    subtest "kind $kind is private over the wire" => sub {
        my $port = free_port();
        my $url = "ws://127.0.0.1:$port";
        my $relay = Net::Nostr::Relay->new(relay_url => $url);
        $relay->start('127.0.0.1', $port);
        my ($anonymous, $alice, $bob) = map { relay_peer($url) } 1..3;
        ok $alice->authenticate($owner)->[2], 'owner authenticates';
        ok $bob->authenticate($other)->[2], 'other identity authenticates';
        my $event = signed_event($owner, kind => $kind, tags => [['d','settings']]);
        for my $peer ($anonymous, $bob) {
            my $ok = $peer->request(['EVENT', $event->to_hash], 'OK', $event->id);
            ok !$ok->[2], 'publication requires event owner';
            like $ok->[3], qr/^auth-required:/, 'retryable authentication error';
        }
        $event = signed_event($owner, kind => $kind, tags => [['d','settings']], content => 'new live value');
        for my $peer ($anonymous, $alice, $bob) {
            $peer->request(['REQ','live',{kinds => [$kind], limit => 0}], 'EOSE','live');
            is $peer->take_events, [], 'zero limit returns no stored events';
        }
        ok $alice->request(['EVENT',$event->to_hash], 'OK',$event->id)->[2], 'owner publication accepted';
        is scalar @{$alice->take_events}, 1, 'live event reaches owner';
        is $anonymous->take_events, [], 'no anonymous live delivery';
        is $bob->take_events, [], 'no other-owner live delivery';
        for my $case ([$anonymous,0], [$bob,0], [$alice,1]) {
            my ($peer,$count) = @$case;
            $peer->request(['REQ','stored',{kinds => [$kind]}], 'EOSE','stored');
            is scalar @{$peer->take_events}, $count, 'stored visibility follows owner';
            my $reply = $peer->request(['COUNT','count',{kinds => [$kind],limit => 0}], 'COUNT','count');
            is $reply->[2]{count}, $count, 'COUNT ignores limit but respects privacy';
            my $ne = Net::Nostr::Negentropy->new;
            $ne->seal;
            my $neg = $peer->request(['NEG-OPEN','neg',{kinds => [$kind]},$ne->initiate], 'NEG-MSG','neg');
            my ($next,$have,$need) = $ne->reconcile($neg->[2]);
            is $need, ($count ? [$event->id] : []), 'negentropy exposes only visible IDs';
        }
        ok $bob->authenticate($owner)->[2], 'a connection may authenticate a second identity';
        $bob->request(['REQ','second',{kinds => [$kind]}], 'EOSE','second');
        is scalar @{$bob->take_events}, 1, 'second authenticated identity gains its own access';
        $_->close for ($anonymous,$alice,$bob);
        $relay->stop;
    };
}

subtest 'hidden rows do not consume a visible filter limit' => sub {
    my $port = free_port();
    my $url = "ws://127.0.0.1:$port";
    my $relay = Net::Nostr::Relay->new(relay_url => $url);
    $relay->inject_event(signed_event($other,kind => 78,created_at => 2000));
    my $visible = signed_event($owner,kind => 1,created_at => 1000);
    $relay->inject_event($visible);
    $relay->start('127.0.0.1',$port);
    my $peer = relay_peer($url);
    $peer->request(['REQ','mixed',{limit => 1}], 'EOSE','mixed');
    is [map { $_->[2]{id} } @{$peer->take_events}], [$visible->id], 'public row fills the limit';
    $peer->close;
    $relay->stop;
};
done_testing;
