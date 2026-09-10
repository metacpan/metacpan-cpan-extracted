use strictures 2;
use Test2::V0 -no_srand => 1;
use Net::Nostr::Event;
use lib 't/lib';
use TestFixtures qw(make_event pod_code);

ok eval { require Net::Nostr::PaymentTargets; 1 }, 'payment targets module loads';
unless (Net::Nostr::PaymentTargets->can('new')) { done_testing; exit }
my $pubkey = 'afc93622eb4d79c0fb75e56e0c14553f7214b0a466abeba14cb38968c6755e6a';
my $targets = [
    ['bitcoin','bc1qxq66e0t8d7ugdecwnmv58e90tpry23nc84pg9k'],
    ['nano','nano_1dctqbmqxfppo9pswbm6kg9d4s4mbraqn8i4m7ob9gnzz91aurmuho48jx3c'],
    ['unknowntype','l7tbta5b9xze6ckkfc99uohzxd009b0r'],
];
subtest 'NIP-A3 example and both round trips' => sub {
    my $list = Net::Nostr::PaymentTargets->new(targets=>$targets);
    my $event = $list->to_event(pubkey=>$pubkey,created_at=>1000);
    is $event->kind, 10133, 'replaceable payment target kind';
    ok $event->is_replaceable, 'standard NIP-01 replacement';
    is $event->content, '', 'empty content by default';
    is $event->tags, [map { ['payto', @$_] } @$targets], 'exact spec tags';
    my $parsed = Net::Nostr::PaymentTargets->from_event($event);
    is $parsed->targets, $targets, 'object round trip';
    is $parsed->to_event(pubkey=>$pubkey,created_at=>1000)->to_hash, $event->to_hash, 'event round trip';
    is $parsed->uris, ["bitcoin:$targets->[0][1]", "payto://nano/$targets->[1][1]",
        "payto://unknowntype/$targets->[2][1]"], 'exact URI examples';
    my $empty = Net::Nostr::PaymentTargets->new(targets=>[]);
    is $empty->uris, [], 'empty list clears payment targets';
};
subtest 'unknown types, reserved characters, and defensive copies' => sub {
    my $input = [['future-type.2',"alice/\x{2603}?amount=10#fragment"]];
    my $list = Net::Nostr::PaymentTargets->new(targets=>$input);
    $input->[0][1]='changed';
    $list->targets->[0][1]='also changed';
    is $list->uris, ['payto://future-type.2/alice%2F%E2%98%83%3Famount%3D10%23fragment'],
        'address cannot inject URI options or fragments';
    for my $type (qw(bip352 bip353 bitcoin cashme ethereum lightning litecoin monero nano paypal revolut solana venmo zcash)) {
        my $value = Net::Nostr::PaymentTargets->new(targets=>[[$type,'account']]);
        like $value->uris->[0], qr/^(?:payto:\/\/\Q$type\E\/|\Q$type\E:)account$/, 'common type accepted';
    }
    my $event = make_event(kind=>10133,content=>'future metadata',tags=>[['alt','payment targets'],['payto','nano','account']]);
    my $parsed = Net::Nostr::PaymentTargets->from_event($event);
    is $parsed->to_event(pubkey=>$event->pubkey,created_at=>$event->created_at)->tags, $event->tags, 'other tags preserve their positions';
    is $parsed->to_event(pubkey=>$event->pubkey)->content, 'future metadata', 'content preserved';
};
subtest 'strict builders and untrusted event parsing' => sub {
    for my $targets (undef, {}, [['bitcoin']], [['bitcoin','a','extra']], [['Bitcoin','a']],
        [['','a']], [['bad/type','a']], [['type','']], [['type',undef]], [['type',{}]], [['type',"a\n"]]) {
        like dies { Net::Nostr::PaymentTargets->new(targets=>$targets) }, qr/target|type|address/, 'invalid targets rejected';
        next unless ref($targets) eq 'ARRAY';
        my $event = eval { make_event(kind=>10133,tags=>[map { ['payto',@$_] } @$targets]) };
        next unless $event;
        like dies { Net::Nostr::PaymentTargets->from_event($event) }, qr/target|type|address/, 'wire target rejected';
    }
    like dies { Net::Nostr::PaymentTargets->new }, qr/targets/, 'targets required';
    like dies { Net::Nostr::PaymentTargets->new(targets=>[],typo=>1) }, qr/unknown/, 'unknown options rejected';
    like dies { Net::Nostr::PaymentTargets->from_event(make_event(kind=>1)) }, qr/10133/, 'wrong kind rejected';
    like dies { Net::Nostr::PaymentTargets->from_event({kind=>10133}) }, qr/Event/, 'wrong input type rejected';
    like dies { Net::Nostr::PaymentTargets->new(targets=>[])->to_event }, qr/pubkey/, 'publication requires author';
};
subtest 'review: exact PaymentTargets SYNOPSIS executes and duplicates survive' => sub {
    my $code=pod_code('lib/Net/Nostr/PaymentTargets.pm','SYNOPSIS');
    my $links;
    ok lives { $links=eval $code . "\n" . '$links'; die $@ if $@ }, 'actual SYNOPSIS executes';
    is scalar @$links,3,'SYNOPSIS produces three links' if $links;
    my $list=Net::Nostr::PaymentTargets->new(targets=>[['nano','account'],['nano','account']]);
    is(Net::Nostr::PaymentTargets->from_event($list->to_event(pubkey=>$pubkey))->targets,
        $list->targets,'duplicate targets survive event round trip');
};

done_testing;
