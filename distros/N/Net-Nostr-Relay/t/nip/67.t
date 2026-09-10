use strictures 2;
use Test2::V0 -no_srand => 1;
use Net::Nostr::Relay;
use Net::Nostr::RelayInfo;
use lib 't/lib';
use TestFixtures qw(free_port relay_peer make_key_from_hex signed_event);

for my $bad (undef, -1, 2, [], {}) {
    like dies { Net::Nostr::Relay->new(eose_hints => $bad) }, qr/eose_hints/, 'hint option is strictly boolean';
}
subtest 'optional completeness and auth hints over the wire' => sub {
    my $port = free_port();
    my $url = "ws://127.0.0.1:$port";
    my $relay;
    ok lives { $relay = Net::Nostr::Relay->new(relay_url => $url, eose_hints => 1,
        max_limit => 2, default_limit => 1, relay_info => Net::Nostr::RelayInfo->new(supported_nips => [1,42])) },
        'hint emission can be enabled';
    return unless $relay;
    ok((grep { $_ == 67 } @{$relay->relay_info->supported_nips}), 'NIP-11 advertises hints');
    my $key = make_key_from_hex('1' x 64);
    my @events = map { signed_event($key,kind => 1,created_at => $_,content => "note $_") } (1000,2000,3000);
    $relay->inject_event($_) for @events;
    $relay->start('127.0.0.1',$port);
    my $peer = relay_peer($url);
    ok length($peer->{challenge}), 'AUTH challenge received before requests and auth hints';
    for my $case ([{kinds=>[1]},['more'],1], [{kinds=>[1],limit=>99},['more'],2],
                  [{kinds=>[1],until=>2000,limit=>2},['finish'],2],
                  [{kinds=>[1],until=>1},['finish'],0], [{kinds=>[78]},['auth','finish'],0]) {
        my ($filter,$hints,$count) = @$case;
        my $eose = $peer->request(['REQ','s',$filter],'EOSE','s');
        is $eose->[2], $hints, 'hint describes authorized stored results';
        is scalar @{$peer->take_events}, $count, 'expected stored result count';
    }
    my $tied = signed_event($key,kind=>1,created_at=>3000,content=>'tied');
    my $union=$peer->request(['REQ','union',
        {kinds=>[1],ids=>[$events[0]->id,$events[1]->id],limit=>1},
        {kinds=>[1],ids=>[$events[0]->id],limit=>1}],'EOSE','union');
    is $union->[2],['finish'],'overlapping limited filters can collectively finish their full union';
    is [sort map {$_->[2]{id}} @{$peer->take_events}], [sort($events[0]->id,$events[1]->id)],
        'overlapping filters deliver each visible event once';
    $relay->inject_event($tied);
    my $eose = $peer->request(['REQ','ties',{kinds=>[1]}],'EOSE','ties');
    is scalar @{$peer->take_events}, 2, 'boundary timestamp ties included together';
    is $eose->[2], ['more'], 'older rows still remain';
    $peer->request(['REQ','s',{kinds=>[1],limit=>0}],'EOSE','s');
    is $peer->take_events, [], 'explicit zero is preserved';
    my $live = signed_event($key,kind=>1,created_at=>4000);
    ok $peer->request(['EVENT',$live->to_hash],'OK',$live->id)->[2], 'publish after EOSE';
    ok((grep { $_->[1] eq 's' && $_->[2]{id} eq $live->id } @{$peer->take_events}), 'live delivery survives EOSE');
    $peer->close;
    $relay->stop;
};
done_testing;
