use strictures 2;
use Test2::V0 -no_srand => 1;
use Net::Nostr::Relay;
use lib 't/lib';
use TestFixtures qw(free_port relay_peer make_key_from_hex signed_event);

my $port = free_port();
my $url = "ws://127.0.0.1:$port";
my $relay = Net::Nostr::Relay->new(relay_url=>$url, default_limit=>1,max_limit=>2);
my $key = make_key_from_hex('1' x 64);
my $stored = signed_event($key, kind=>1);
my $other = signed_event($key, kind=>7);
$relay->inject_event($_) for ($stored,$other);
$relay->start('127.0.0.1',$port);
my $peer = relay_peer($url);
is $peer->request(['REQ','zero',{kinds=>[1],limit=>0}],'EOSE','zero'), ['EOSE','zero'],
    'zero-limit request gets legacy EOSE by default';
is $peer->take_events, [], 'no stored events';
$peer->request(['REQ','mixed',{kinds=>[1],limit=>0},{kinds=>[7]}],'EOSE','mixed');
is [map { $_->[2]{id} } @{$peer->take_events}], [$other->id], 'zero applies to its filter only';
my $live = signed_event($key,kind=>1,content=>'live');
$peer->request(['EVENT',$live->to_hash],'OK',$live->id);
is [sort map { $_->[1] } @{$peer->take_events}], ['mixed','zero'], 'both zero-limit filters deliver live';
$peer->close;
$relay->stop;
done_testing;
