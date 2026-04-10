use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::AppData;

my $PK = 'a' x 64;

###############################################################################
# Kind 30078 addressable event
###############################################################################

subtest 'kind 30078 is addressable' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey => $PK,
        d_tag  => 'myapp-settings',
    );
    is($event->kind, 30078, 'kind is 30078');
    ok($event->is_addressable, 'kind 30078 is addressable');
};

###############################################################################
# d tag contains app name / context reference
###############################################################################

subtest 'd tag is app name / context' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey => $PK,
        d_tag  => 'myapp-settings',
    );
    is($event->d_tag, 'myapp-settings', 'd tag is app identifier');
};

subtest 'd tag can be any arbitrary string' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey => $PK,
        d_tag  => 'com.example.app/user-prefs/v2',
    );
    is($event->d_tag, 'com.example.app/user-prefs/v2', 'arbitrary d tag');
};

subtest 'd_tag is required' => sub {
    like(
        dies { Net::Nostr::AppData->to_event(pubkey => $PK) },
        qr/d_tag/i,
        'd_tag required'
    );
};

###############################################################################
# content can be anything
###############################################################################

subtest 'content can be arbitrary JSON' => sub {
    my $json = '{"theme":"dark","fontSize":14}';
    my $event = Net::Nostr::AppData->to_event(
        pubkey  => $PK,
        d_tag   => 'settings',
        content => $json,
    );
    is($event->content, $json, 'content is arbitrary JSON');
};

subtest 'content can be plain text' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey  => $PK,
        d_tag   => 'notes',
        content => 'just some text',
    );
    is($event->content, 'just some text', 'content is plain text');
};

subtest 'content defaults to empty string' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey => $PK,
        d_tag  => 'empty',
    );
    is($event->content, '', 'content defaults to empty');
};

###############################################################################
# tags can be anything
###############################################################################

subtest 'extra tags passed through' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey     => $PK,
        d_tag      => 'myapp',
        extra_tags => [['x', 'custom'], ['y', '1', '2']],
    );
    my @tags = @{$event->tags};
    # d tag + 2 extra
    is(scalar @tags, 3, '3 tags total');
    is($tags[1], ['x', 'custom'], 'first extra tag');
    is($tags[2], ['y', '1', '2'], 'second extra tag');
};

###############################################################################
# from_event round-trip
###############################################################################

subtest 'from_event round-trip' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey     => $PK,
        d_tag      => 'myapp-settings',
        content    => '{"theme":"dark"}',
        extra_tags => [['version', '2']],
    );

    my $ad = Net::Nostr::AppData->from_event($event);
    ok($ad, 'from_event returns object');
    is($ad->d_tag, 'myapp-settings', 'd_tag round-trips');
    is($ad->content, '{"theme":"dark"}', 'content round-trips');
    is($ad->extra_tags, [['version', '2']], 'extra_tags round-trips');
};

subtest 'from_event minimal' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey => $PK,
        d_tag  => 'minimal',
    );
    my $ad = Net::Nostr::AppData->from_event($event);
    is($ad->d_tag, 'minimal', 'd_tag');
    is($ad->content, '', 'content empty');
    is($ad->extra_tags, [], 'no extra tags');
};

subtest 'from_event returns undef for wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::AppData->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# validate
###############################################################################

subtest 'validate valid event' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey => $PK,
        d_tag  => 'myapp',
    );
    ok(Net::Nostr::AppData->validate($event), 'valid app data event');
};

subtest 'validate rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '',
        tags => [['d', 'myapp']],
    );
    like(
        dies { Net::Nostr::AppData->validate($event) },
        qr/kind/i,
        'rejects wrong kind'
    );
};

subtest 'validate rejects missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30078, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::AppData->validate($event) },
        qr/'d' tag/i,
        'rejects missing d tag'
    );
};

###############################################################################
# Use cases from spec
###############################################################################

subtest 'use case: user personal settings' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey  => $PK,
        d_tag   => 'com.example.client/settings',
        content => '{"theme":"dark","lang":"en"}',
    );
    is($event->kind, 30078);
    is($event->d_tag, 'com.example.client/settings');
    is($event->content, '{"theme":"dark","lang":"en"}');
};

subtest 'use case: app dynamic parameters' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey  => $PK,
        d_tag   => 'com.example.client/config',
        content => '{"apiEndpoint":"https://api.example.com/v2"}',
    );
    my $ad = Net::Nostr::AppData->from_event($event);
    is($ad->d_tag, 'com.example.client/config');
    is($ad->content, '{"apiEndpoint":"https://api.example.com/v2"}');
};

subtest 'use case: personal private data as database' => sub {
    my $encrypted = 'nonce:abc123:ciphertext:deadbeef';
    my $event = Net::Nostr::AppData->to_event(
        pubkey  => $PK,
        d_tag   => 'com.example.diary/entries',
        content => $encrypted,
    );
    my $ad = Net::Nostr::AppData->from_event($event);
    is($ad->d_tag, 'com.example.diary/entries');
    is($ad->content, $encrypted, 'encrypted content round-trips');
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::AppData->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# created_at passthrough
###############################################################################

subtest 'created_at passthrough' => sub {
    my $event = Net::Nostr::AppData->to_event(
        pubkey     => $PK,
        d_tag      => 'myapp',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

done_testing;
