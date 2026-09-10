use strictures 2;
use Test2::V0 -no_srand => 1;
use Net::Nostr::Relay;
use Net::Nostr::Group;
use lib 't/lib';
use TestFixtures qw(free_port relay_peer make_key_from_hex signed_event);

ok eval { require Net::Nostr::RelayGroups; 1 }, 'group policy module loads';
unless (Net::Nostr::RelayGroups->can('new')) { done_testing; exit }
my $master = make_key_from_hex('3' x 64);
my $alice = make_key_from_hex('1' x 64);
my $bob = make_key_from_hex('2' x 64);
for my $args ({}, {key=>{}}, {key=>$master,max_pins=>-1}, {key=>$master,max_pins=>[]}, {key=>$master,typo=>1}) {
    ok dies { Net::Nostr::RelayGroups->new(%$args) }, 'strict policy constructor';
}
like dies { Net::Nostr::Relay->new(groups=>{}) }, qr/groups/, 'relay validates policy';
my $port = free_port();
my $url = "ws://127.0.0.1:$port";
my $policy = Net::Nostr::RelayGroups->new(key=>$master,max_pins=>2);
my $relay = Net::Nostr::Relay->new(relay_url=>$url,groups=>$policy);
is $relay->relay_info->extensions->{nip29}, {subgroups=>JSON::true}, 'advertises subgroup policy';
is $relay->relay_info->self, $master->pubkey_hex, 'advertises signing key';
$relay->start('127.0.0.1',$port);
my $peer = relay_peer($url);
my $counter = 0;
my $publish = sub {
    my ($key,$kind,$id,@tags) = @_;
    my $event = signed_event($key,kind=>$kind,tags=>[['h',$id],@tags],content=>'' . ++$counter);
    return ($peer->request(['EVENT',$event->to_hash],'OK',$event->id), $event);
};
my $metadata = sub {
    my ($id) = @_;
    my $event = $relay->store->find_addressable($master->pubkey_hex,39000,$id);
    return $event ? Net::Nostr::Group->metadata_from_event($event) : undef;
};
my $accept = sub {
    my ($key,$kind,$id,@tags) = @_;
    my ($reply,$event) = $publish->($key,$kind,$id,@tags);
    ok $reply->[2], "$kind for $id accepted: $reply->[3]";
    return $event;
};
my $reject = sub {
    my ($pattern,$key,$kind,$id,@tags) = @_;
    my ($reply,$event) = $publish->($key,$kind,$id,@tags);
    ok !$reply->[2], "$kind for $id rejected";
    like $reply->[3], $pattern, 'useful protocol error';
    ok !$relay->store->get_by_id($event->id), 'rejection did not store moderation event';
};

subtest 'subgroup lifecycle follows the spec and rejects invalid trees atomically' => sub {
    $accept->($alice,9007,$_) for qw(tech social nostr chat);
    $accept->($alice,9002,'nostr',['name','Nostr'],['parent','tech']);
    is $metadata->('tech')->{children}, ['nostr'], 'old parent records its child';
    $accept->($alice,9002,'nostr',['name','Nostr'],['parent','social']);
    is $metadata->('nostr')->{parent}, 'social', 'spec example reparenting';
    is $metadata->('tech')->{children} || [], [], 'removed from old parent';
    is $metadata->('social')->{children}, ['nostr'], 'added to new parent';
    $reject->(qr/parent|cycle/,$alice,9002,'nostr',['parent','nostr']);
    $reject->(qr/cycle/,$alice,9002,'social',['parent','nostr'],['child','nostr']);
    $reject->(qr/parent/,$alice,9002,'nostr',['parent','missing']);
    $reject->(qr/parent/,$alice,9002,'nostr',['parent','tech'],['parent','social']);
    is $metadata->('nostr')->{parent}, 'social', 'invalid edits leave tree unchanged';
    $accept->($alice,9002,'chat',['parent','social']);
    $reject->(qr/child/,$alice,9002,'social',['name','incomplete']);
    $reject->(qr/child/,$alice,9002,'social',['child','nostr']);
    $reject->(qr/child/,$alice,9002,'social',['child',"chat\0nostr"]);
    $reject->(qr/child/,$alice,9002,'social',['child','nostr'],['child','chat'],['child','missing']);
    $accept->($alice,9002,'social',['child','chat'],['child','nostr'],['banner','https://pizza.com/banner.png']);
    is $metadata->('social')->{children}, ['chat','nostr'], 'complete child list can be reordered';
    $accept->($alice,9002,'nostr',['name','Nostr']);
    ok !exists($metadata->('nostr')->{parent}), 'absent parent promotes to root';
    is $metadata->('social')->{children}, ['chat'], 'promotion updates former parent';
    $accept->($alice,9008,'social');
    ok !defined($metadata->('social')), 'parent deleted';
    ok !exists($metadata->('chat')->{parent}), 'remaining child becomes root';
    for my $event (@{$relay->store->query([Net::Nostr::Filter->new(kinds=>[39000,39001,39002,39003,39005])])}) {
        is $event->pubkey, $master->pubkey_hex, 'metadata signed by relay self key';
        ok lives { $event->validate }, 'generated metadata signature valid';
    }
};

subtest 'group administration and membership do not inherit' => sub {
    $accept->($bob,9007,'other');
    $reject->(qr/admin/,$alice,9002,'nostr',['parent','other']);
    $accept->($alice,9000,'tech',['p',$bob->pubkey_hex,'admin']);
    $accept->($alice,9002,'nostr',['parent','tech']);
    $reject->(qr/admin/,$bob,9002,'nostr',['name','parent admin cannot edit child']);
    $accept->($bob,1,'tech');
    $reject->(qr/member/,$bob,1,'nostr');
    $accept->($alice,9000,'nostr',['p',$bob->pubkey_hex]);
    $accept->($bob,1,'nostr');
    $accept->($alice,9001,'tech',['p',$bob->pubkey_hex]);
    $accept->($bob,1,'nostr');
    $reject->(qr/member/,$bob,1,'tech');
    $reject->(qr/admin/,$bob,9010,'nostr');
};

subtest 'pins mirror the entire accepted ordered list including clears and limits' => sub {
    my $id = 'a'x64;
    my $address = '30023:'.$alice->pubkey_hex.':post';
    for my $pins ([['e',$id],['a',$address]], [['a',$address],['e',$id]], []) {
        $accept->($alice,9010,'nostr',@$pins);
        my $event = $relay->store->find_addressable($master->pubkey_hex,39005,'nostr');
        is(Net::Nostr::Group->pins_from_event($event)->{pins}, $pins, 'stored relay list mirrors update');
    }
    $reject->(qr/pin/,$alice,9010,'nostr',['e',$id],['e','b'x64],['e','c'x64]);
    $reject->(qr/pin/,$alice,9010,'nostr',['a','bad']);
    is(Net::Nostr::Group->pins_from_event($relay->store->find_addressable($master->pubkey_hex,39005,'nostr'))->{pins}, [],
        'rejected pin edit leaves the old list');
};

subtest 'private and hidden groups apply to stored and live reads' => sub {
    $accept->($alice,9002,'nostr',['private'],['hidden'],['restricted']);
    my $event = $accept->($alice,1,'nostr');
    $peer->request(['REQ','private',{'#h'=>['nostr']}],'EOSE','private');
    is $peer->take_events, [], 'anonymous stored reads hidden';
    $peer->request(['REQ','metadata',{kinds=>[39000],'#d'=>['nostr']}],'EOSE','metadata');
    is $peer->take_events, [], 'hidden metadata omitted';
    $accept->($alice,1,'nostr');
    is $peer->take_events, [], 'anonymous live reads hidden';
    ok $peer->authenticate($alice)->[2], 'member authenticates for reads';
    $peer->request(['REQ','private',{'#h'=>['nostr']}],'EOSE','private');
    ok scalar @{$peer->take_events}, 'member receives stored history';
    $accept->($alice,1,'nostr');
    ok scalar @{$peer->take_events}, 'member receives live events';
};

subtest 'joins, leaves, invites, and timeline references use group-local state' => sub {
    $accept->($alice,9007,'joining');
    $accept->($bob,9021,'joining');
    $reject->(qr/^duplicate:/,$bob,9021,'joining');
    $accept->($bob,9022,'joining');
    $reject->(qr/member/,$bob,1,'joining');
    $accept->($alice,9002,'joining',['closed'],['restricted']);
    $reject->(qr/closed|invite/,$bob,9021,'joining');
    $accept->($alice,9009,'joining',['code','welcome']);
    $accept->($bob,9021,'joining',['code','welcome']);
    my $earlier = $accept->($alice,1,'joining');
    $accept->($bob,1,'joining',['previous',substr($earlier->id,0,8)]);
    my $public_note=signed_event($alice,kind=>1,content=>'seen elsewhere on this relay');
    ok $peer->request(['EVENT',$public_note->to_hash],'OK',$public_note->id)->[2],'public relay event stored';
    $accept->($bob,1,'joining',['previous',substr($public_note->id,0,8)]);
    $reject->(qr/previous/,$bob,1,'joining',['previous','bad']);
    $reject->(qr/previous/,$bob,1,'joining',['previous','00000000']);
    my $old = signed_event($alice,kind=>1,tags=>[['h','joining']],created_at=>time-86400);
    ok !$peer->request(['EVENT',$old->to_hash],'OK',$old->id)->[2], 'late group publication rejected';
};

subtest 'group metadata publication cannot bypass moderation checks' => sub {
    my $fake = signed_event($bob,kind=>39000,tags=>[['d','nostr']]);
    my $reply = $peer->request(['EVENT',$fake->to_hash],'OK',$fake->id);
    ok !$reply->[2], 'non-relay metadata rejected';
    my $tampered = signed_event($master,kind=>39000,tags=>[['d','nostr'],['parent','nostr']]);
    ok !$peer->request(['EVENT',$tampered->to_hash],'OK',$tampered->id)->[2], 'wire metadata cannot bypass tree policy';
};

subtest 'pin limits default to unlimited and zero permits only clearing' => sub {
    my $unlimited=Net::Nostr::RelayGroups->new(key=>$master);
    my $none=Net::Nostr::RelayGroups->new(key=>$master,max_pins=>0);
    my $update=signed_event($alice,kind=>9010,tags=>[['h','nostr'],map { ['e',$_ x 64] } qw(a b c)]);
    my $plan=$unlimited->prepare($update,$relay->store);
    my @pin_events=grep { $_->kind==39005 } @{$plan->{events}};
    is scalar @{Net::Nostr::Group->pins_from_event($pin_events[0])->{pins}},3,'unlimited default permits three pins';
    like dies { $none->prepare($update,$relay->store) },qr/max_pins/,'zero rejects non-empty pins';
    ok lives { $none->prepare(signed_event($alice,kind=>9010,tags=>[['h','nostr']]),$relay->store) },'zero permits clearing';
    is(Net::Nostr::Group->pins_from_event($relay->store->find_addressable($master->pubkey_hex,39005,'nostr'))->{pins},[],
        'preparing a plan does not mutate the store');
};

subtest 'membership revocation invalidates private negentropy snapshots' => sub {
    my $bob_peer=relay_peer($url);
    ok $bob_peer->authenticate($bob)->[2], 'member authenticates';
    $accept->($alice,9002,'joining',['private'],['restricted']);
    my $ne=Net::Nostr::Negentropy->new;
    $ne->seal;
    $bob_peer->request(['NEG-OPEN','revoke',{'#h'=>['joining']},$ne->initiate],'NEG-MSG','revoke');
    $accept->($alice,9001,'joining',['p',$bob->pubkey_hex]);
    # Previously negotiated sets must not keep serving IDs after removal.
    my $reply=$bob_peer->request(['NEG-MSG','revoke',$ne->initiate],'NEG-ERR','revoke');
    like $reply->[2],qr/^closed:/,'snapshot closed after group authorization changed';
    my $count=$bob_peer->request(['COUNT','hidden',{'#h'=>['joining']}],'COUNT','hidden');
    is $count->[2]{count},0,'removed member cannot count private history';
    $bob_peer->close;
};
subtest 'review: metadata and membership payloads reject malformed values atomically' => sub {
    $accept->($alice,9007,'strict');
    for my $tags ([['name']], [['name','one'],['name','two']], [['private','yes']],
        [['private'],['public']], [['closed'],['open']], [['supported_kinds','text']],
        [['supported_kinds','65536']]) {
        $reject->(qr/invalid:/,$alice,9002,'strict',@$tags);
    }
    $reject->(qr/invalid:/,$alice,9000,'strict',['p',$bob->pubkey_hex,'admin','']);
    $reject->(qr/invalid:/,$alice,9001,'strict',['p',$bob->pubkey_hex,'extra']);
    $reject->(qr/invalid:/,$bob,9021,'strict',['code']);
    $reject->(qr/invalid:/,$bob,9021,'strict',['code','a'],['code','b']);
    $accept->($alice,9002,'strict',['supported_kinds','9','11']);
    $accept->($alice,9,'strict');
    $reject->(qr/kind/,$alice,1,'strict');
    $accept->($alice,9002,'strict',['supported_kinds']);
    $reject->(qr/kind/,$alice,9,'strict');
};

subtest 'review: policy defaults, flag reversals, deletion, and invalid actions' => sub {
    is(Net::Nostr::Relay->new->groups,undef,'group policy is opt-in');
    $accept->($alice,9007,'policy');
    my $meta=$metadata->('policy');
    ok $meta->{restricted},'default writes require membership';
    ok !$meta->{private} && !$meta->{closed} && !$meta->{hidden},'default reads, joining, and metadata are public';
    $accept->($alice,9002,'policy',['private'],['hidden'],['closed'],['restricted']);
    $accept->($alice,9002,'policy',['name','retains flags']);
    $meta=$metadata->('policy');
    ok $meta->{private} && $meta->{hidden} && $meta->{closed} && $meta->{restricted},'omitted flags retained';
    $accept->($alice,9002,'policy',['public'],['visible'],['open'],['unrestricted']);
    $meta=$metadata->('policy');
    ok !$meta->{private} && !$meta->{hidden} && !$meta->{closed} && !$meta->{restricted},'opposing flags clear all restrictions';
    my $note=$accept->($bob,1,'policy');
    my $anonymous=relay_peer($url);
    $anonymous->request(['REQ','public-policy',{ids=>[$note->id]}],'EOSE','public-policy');
    is scalar @{$anonymous->take_events},1,'public history becomes readable without authentication';
    $anonymous->request(['REQ','visible-policy',{kinds=>[39000],'#d'=>['policy']}],'EOSE','visible-policy');
    is scalar @{$anonymous->take_events},1,'visible metadata is readable without authentication';
    $anonymous->close;
    $accept->($bob,9021,'policy');
    $reject->(qr/admin/,$bob,9005,'policy',['e',$note->id]);
    $reject->(qr/target/,$alice,9005,'nostr',['e',$note->id]);
    $reject->(qr/reference/,$alice,9005,'policy',['e','bad']);
    $accept->($alice,9005,'policy',['e',$note->id]);
    ok !$relay->store->get_by_id($note->id),'admin deletion removes the selected group event';
    $reject->(qr/unsupported/,$alice,9003,'policy');
    $reject->(qr/unsupported/,$alice,9002,'policy',['livekit']);
    my $own=$accept->($alice,1,'policy');
    $reject->(qr/previous/,$alice,1,'policy',['previous',substr($own->id,0,8)]);
    my $future=signed_event($alice,kind=>1,created_at=>time+3600,tags=>[['h','policy']]);
    ok !$peer->request(['EVENT',$future->to_hash],'OK',$future->id)->[2],'future group publication rejected';
    my $missing=signed_event($alice,kind=>9002);
    my $reply=$peer->request(['EVENT',$missing->to_hash],'OK',$missing->id);
    ok !$reply->[2],'group action without h tag rejected';
    like $reply->[3],qr/h tag/,'missing group has useful error';
};

subtest 'review: canonical membership history includes creators and rapid changes' => sub {
    my $timestamp=time+60;
    my $send = sub {
        my ($key,$kind,@tags)=@_;
        my $event=signed_event($key,kind=>$kind,created_at=>$timestamp,
            content=>'membership review '.++$counter,tags=>[['h','history'],@tags]);
        ok $peer->request(['EVENT',$event->to_hash],'OK',$event->id)->[2], 'membership action accepted';
    };
    my $history = sub {
        my ($key)=@_;
        return $relay->store->query([Net::Nostr::Filter->new(kinds=>[9000,9001],
            '#h'=>['history'],'#p'=>[$key->pubkey_hex])]);
    };
    $send->($alice,9007);
    my $creator=$history->($alice);
    is scalar @$creator,1,'creator has a canonical put-user event';
    if (@$creator) {
        is $creator->[0]->tags,[['h','history'],['p',$alice->pubkey_hex,'admin']], 'creator role can be reconstructed';
    }
    my $previous=$timestamp;
    for my $step ([$bob,9021,9000],[$bob,9022,9001],[$bob,9021,9000],
        [$alice,9001,9001,['p',$bob->pubkey_hex]],[$alice,9000,9000,['p',$bob->pubkey_hex]]) {
        my ($key,$kind,$expected,@tags)=@$step;
        $send->($key,$kind,@tags);
        my $events=$history->($bob);
        is $events->[0]->kind,$expected,'newest membership event reflects current membership';
        is $events->[0]->pubkey,$master->pubkey_hex,'relay emits canonical membership transition';
        ok $events->[0]->created_at>$previous,'canonical membership timestamps strictly advance';
        $previous=$events->[0]->created_at;
    }
    my @canonical=grep {$_->pubkey eq $master->pubkey_hex} @{$history->($bob)};
    is scalar @canonical,5,'no rapid transition is lost as a duplicate event';
};

$peer->close;
$relay->stop;
done_testing;
