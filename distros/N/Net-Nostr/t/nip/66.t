use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::RelayMonitor;

my $PK = 'a' x 64;

###############################################################################
# Relay Discovery Events (kind 30166)
###############################################################################

subtest 'discovery: kind 30166 addressable event' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
    );
    is($event->kind, 30166, 'kind is 30166');
    ok($event->is_addressable, 'kind 30166 is addressable');
};

subtest 'discovery: d tag MUST be relay URL' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
    );
    is($event->d_tag, 'wss://some.relay/', 'd tag is the relay URL');
};

subtest 'discovery: d tag MAY be hex pubkey for non-URL relays' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'bb' x 32,
    );
    is($event->d_tag, 'bb' x 32, 'd tag is hex pubkey');
};

subtest 'discovery: relay_url required' => sub {
    like(
        dies {
            Net::Nostr::RelayMonitor->discovery_event(pubkey => $PK)
        },
        qr/relay_url/i,
        'relay_url required'
    );
};

subtest 'discovery: content MAY include NIP-11 JSON' => sub {
    my $nip11 = '{"name":"My Relay","description":"A test relay"}';
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        nip11     => $nip11,
    );
    is($event->content, $nip11, 'content is NIP-11 JSON');
};

subtest 'discovery: content defaults to empty string' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
    );
    is($event->content, '', 'content defaults to empty');
};

###############################################################################
# Discovery: optional tags
###############################################################################

subtest 'discovery: rtt-open tag' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        rtt_open  => '234',
    );
    my ($tag) = grep { $_->[0] eq 'rtt-open' } @{$event->tags};
    is($tag->[1], '234', 'rtt-open in milliseconds');
};

subtest 'discovery: rtt-read tag' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        rtt_read  => '150',
    );
    my ($tag) = grep { $_->[0] eq 'rtt-read' } @{$event->tags};
    is($tag->[1], '150', 'rtt-read in milliseconds');
};

subtest 'discovery: rtt-write tag' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        rtt_write => '300',
    );
    my ($tag) = grep { $_->[0] eq 'rtt-write' } @{$event->tags};
    is($tag->[1], '300', 'rtt-write in milliseconds');
};

subtest 'discovery: n (network) tag' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        network   => 'clearnet',
    );
    my ($tag) = grep { $_->[0] eq 'n' } @{$event->tags};
    is($tag->[1], 'clearnet', 'network tag');
};

subtest 'discovery: network SHOULD be clearnet/tor/i2p/loki' => sub {
    for my $net (qw(clearnet tor i2p loki)) {
        my $event = Net::Nostr::RelayMonitor->discovery_event(
            pubkey    => $PK,
            relay_url => 'wss://some.relay/',
            network   => $net,
        );
        my ($tag) = grep { $_->[0] eq 'n' } @{$event->tags};
        is($tag->[1], $net, "network $net accepted");
    }
};

subtest 'discovery: T (relay type) tag' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey     => $PK,
        relay_url  => 'wss://some.relay/',
        relay_type => 'PrivateInbox',
    );
    my ($tag) = grep { $_->[0] eq 'T' } @{$event->tags};
    is($tag->[1], 'PrivateInbox', 'relay type PascalCase');
};

subtest 'discovery: N (NIPs) tags repeated' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        nips      => [40, 33],
    );
    my @tags = grep { $_->[0] eq 'N' } @{$event->tags};
    is(scalar @tags, 2, 'two N tags');
    is($tags[0][1], '40', 'first NIP');
    is($tags[1][1], '33', 'second NIP');
};

subtest 'discovery: R (requirements) tags with ! prefix for false' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey       => $PK,
        relay_url    => 'wss://some.relay/',
        requirements => ['!payment', 'auth'],
    );
    my @tags = grep { $_->[0] eq 'R' } @{$event->tags};
    is(scalar @tags, 2, 'two R tags');
    is($tags[0][1], '!payment', 'false requirement with ! prefix');
    is($tags[1][1], 'auth', 'true requirement');
};

subtest 'discovery: t (topic) tags repeated' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        topics    => ['nsfw', 'cats'],
    );
    my @tags = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @tags, 2, 'two t tags');
    is($tags[0][1], 'nsfw', 'first topic');
    is($tags[1][1], 'cats', 'second topic');
};

subtest 'discovery: k (kinds) tags repeated with ! prefix' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        kinds     => ['1', '30023', '!20000'],
    );
    my @tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is(scalar @tags, 3, 'three k tags');
    is($tags[0][1], '1', 'accepted kind');
    is($tags[1][1], '30023', 'accepted kind');
    is($tags[2][1], '!20000', 'unaccepted kind with ! prefix');
};

subtest 'discovery: g (geohash) tag' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        geohash   => 'ww8p1r4t8',
    );
    my ($tag) = grep { $_->[0] eq 'g' } @{$event->tags};
    is($tag->[1], 'ww8p1r4t8', 'geohash tag');
};

subtest 'discovery: l (language) tags' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        languages => ['en', 'ja'],
    );
    my @tags = grep { $_->[0] eq 'l' } @{$event->tags};
    is(scalar @tags, 2, 'two l tags');
    is($tags[0], ['l', 'en', 'ISO-639-1'], 'first language with namespace');
    is($tags[1], ['l', 'ja', 'ISO-639-1'], 'second language with namespace');
};

###############################################################################
# Discovery: spec JSON example
###############################################################################

subtest 'discovery: spec JSON example' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey       => $PK,
        relay_url    => 'wss://some.relay/',
        network      => 'clearnet',
        nips         => [40, 33],
        requirements => ['!payment', 'auth'],
        geohash      => 'ww8p1r4t8',
        languages    => ['en'],
        topics       => ['nsfw'],
        rtt_open     => '234',
    );
    is($event->kind, 30166, 'kind 30166');
    is($event->d_tag, 'wss://some.relay/', 'd tag');

    my %tags;
    for my $tag (@{$event->tags}) {
        push @{$tags{$tag->[0]}}, $tag;
    }
    is($tags{d}[0][1], 'wss://some.relay/');
    is($tags{n}[0][1], 'clearnet');
    is($tags{N}[0][1], '40');
    is($tags{N}[1][1], '33');
    is($tags{R}[0][1], '!payment');
    is($tags{R}[1][1], 'auth');
    is($tags{g}[0][1], 'ww8p1r4t8');
    is($tags{l}[0][1], 'en');
    is($tags{l}[0][2], 'ISO-639-1');
    is($tags{t}[0][1], 'nsfw');
    is($tags{'rtt-open'}[0][1], '234');
};

###############################################################################
# Discovery: multi-value tags MUST be repeated not combined
###############################################################################

subtest 'discovery: multi-value tags repeated not combined' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
        topics    => ['cats', 'dogs'],
    );
    my @t_tags = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @t_tags, 2, 'two separate t tags');
    is(scalar @{$t_tags[0]}, 2, 'first t tag has 2 elements');
    is(scalar @{$t_tags[1]}, 2, 'second t tag has 2 elements');
};

###############################################################################
# Discovery: from_event round-trip
###############################################################################

subtest 'discovery: from_event round-trip' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey       => $PK,
        relay_url    => 'wss://some.relay/',
        network      => 'clearnet',
        relay_type   => 'PrivateInbox',
        nips         => [40, 33],
        requirements => ['!payment', 'auth'],
        geohash      => 'ww8p1r4t8',
        languages    => ['en'],
        topics       => ['nsfw'],
        kinds        => ['1', '!20000'],
        rtt_open     => '234',
        rtt_read     => '150',
        rtt_write    => '300',
        nip11        => '{"name":"test"}',
    );

    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    ok($mon, 'from_event returns object');
    is($mon->relay_url, 'wss://some.relay/', 'relay_url');
    is($mon->network, 'clearnet', 'network');
    is($mon->relay_type, 'PrivateInbox', 'relay_type');
    is($mon->nips, ['40', '33'], 'nips');
    is($mon->requirements, ['!payment', 'auth'], 'requirements');
    is($mon->geohash, 'ww8p1r4t8', 'geohash');
    is($mon->languages, ['en'], 'languages');
    is($mon->topics, ['nsfw'], 'topics');
    is($mon->kinds, ['1', '!20000'], 'kinds');
    is($mon->rtt_open, '234', 'rtt_open');
    is($mon->rtt_read, '150', 'rtt_read');
    is($mon->rtt_write, '300', 'rtt_write');
    is($mon->nip11, '{"name":"test"}', 'nip11');
};

subtest 'discovery: from_event minimal' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://minimal.relay/',
    );
    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is($mon->relay_url, 'wss://minimal.relay/', 'relay_url');
    is($mon->network, undef, 'network undef');
    is($mon->rtt_open, undef, 'rtt_open undef');
    is($mon->nips, [], 'nips empty');
    is($mon->topics, [], 'topics empty');
};

subtest 'discovery: from_event returns undef for wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::RelayMonitor->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# Discovery: validate
###############################################################################

subtest 'discovery: validate valid event' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://some.relay/',
    );
    ok(Net::Nostr::RelayMonitor->validate($event), 'valid discovery event');
};

subtest 'discovery: validate rejects missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30166, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::RelayMonitor->validate($event) },
        qr/'d' tag/i,
        'rejects missing d tag'
    );
};

subtest 'discovery: validate rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '',
        tags => [['d', 'wss://relay/']],
    );
    like(
        dies { Net::Nostr::RelayMonitor->validate($event) },
        qr/kind/i,
        'rejects wrong kind'
    );
};

###############################################################################
# Relay Monitor Announcements (kind 10166)
###############################################################################

subtest 'announcement: kind 10166 replaceable event' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
    );
    is($event->kind, 10166, 'kind is 10166');
    ok($event->is_replaceable, 'kind 10166 is replaceable');
};

subtest 'announcement: frequency tag' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
    );
    my ($tag) = grep { $_->[0] eq 'frequency' } @{$event->tags};
    is($tag->[1], '3600', 'frequency in seconds');
};

subtest 'announcement: frequency required' => sub {
    like(
        dies {
            Net::Nostr::RelayMonitor->announcement_event(pubkey => $PK)
        },
        qr/frequency/i,
        'frequency required'
    );
};

subtest 'announcement: content is empty' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
    );
    is($event->content, '', 'content is empty');
};

###############################################################################
# Announcement: timeout tags
###############################################################################

subtest 'announcement: timeout tags with test type' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
        timeouts  => [
            { test => 'open',  ms => '5000' },
            { test => 'read',  ms => '3000' },
            { test => 'write', ms => '3000' },
            { test => 'nip11', ms => '3000' },
        ],
    );
    my @tags = grep { $_->[0] eq 'timeout' } @{$event->tags};
    is(scalar @tags, 4, 'four timeout tags');
    is($tags[0], ['timeout', 'open', '5000'], 'open timeout');
    is($tags[1], ['timeout', 'read', '3000'], 'read timeout');
    is($tags[2], ['timeout', 'write', '3000'], 'write timeout');
    is($tags[3], ['timeout', 'nip11', '3000'], 'nip11 timeout');
};

subtest 'announcement: timeout tag without test type (applies to all)' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
        timeouts  => [
            { ms => '5000' },
        ],
    );
    my @tags = grep { $_->[0] eq 'timeout' } @{$event->tags};
    is(scalar @tags, 1, 'one timeout tag');
    is($tags[0], ['timeout', '5000'], 'timeout without test type');
};

###############################################################################
# Announcement: c (checks) tags repeated
###############################################################################

subtest 'announcement: c (checks) tags' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
        checks    => [qw(ws nip11 ssl dns geo)],
    );
    my @tags = grep { $_->[0] eq 'c' } @{$event->tags};
    is(scalar @tags, 5, 'five c tags');
    is($tags[0][1], 'ws', 'first check');
    is($tags[4][1], 'geo', 'last check');
};

subtest 'announcement: g (geohash) tag' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
        geohash   => 'ww8p1r4t8',
    );
    my ($tag) = grep { $_->[0] eq 'g' } @{$event->tags};
    is($tag->[1], 'ww8p1r4t8', 'geohash');
};

###############################################################################
# Announcement: spec JSON example
###############################################################################

subtest 'announcement: spec JSON example' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
        timeouts  => [
            { test => 'open',  ms => '5000' },
            { test => 'read',  ms => '3000' },
            { test => 'write', ms => '3000' },
            { test => 'nip11', ms => '3000' },
        ],
        checks  => [qw(ws nip11 ssl dns geo)],
        geohash => 'ww8p1r4t8',
    );
    is($event->kind, 10166, 'kind 10166');
    is($event->content, '', 'empty content');

    my %tags;
    for my $tag (@{$event->tags}) {
        push @{$tags{$tag->[0]}}, $tag;
    }
    is($tags{timeout}[0], ['timeout', 'open', '5000']);
    is($tags{timeout}[1], ['timeout', 'read', '3000']);
    is($tags{timeout}[2], ['timeout', 'write', '3000']);
    is($tags{timeout}[3], ['timeout', 'nip11', '3000']);
    is($tags{frequency}[0][1], '3600');
    is($tags{c}[0][1], 'ws');
    is($tags{c}[1][1], 'nip11');
    is($tags{c}[2][1], 'ssl');
    is($tags{c}[3][1], 'dns');
    is($tags{c}[4][1], 'geo');
    is($tags{g}[0][1], 'ww8p1r4t8');
};

###############################################################################
# Announcement: from_event round-trip
###############################################################################

subtest 'announcement: from_event round-trip' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
        timeouts  => [
            { test => 'open',  ms => '5000' },
            { test => 'read',  ms => '3000' },
        ],
        checks  => [qw(ws nip11 ssl)],
        geohash => 'ww8p1r4t8',
    );

    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    ok($mon, 'from_event returns object');
    is($mon->frequency, '3600', 'frequency');
    is(
        $mon->timeouts,
        [{ test => 'open', ms => '5000' }, { test => 'read', ms => '3000' }],
        'timeouts'
    );
    is($mon->checks, [qw(ws nip11 ssl)], 'checks');
    is($mon->geohash, 'ww8p1r4t8', 'geohash');
};

subtest 'announcement: from_event timeout without test type' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 10166, content => '',
        tags => [
            ['frequency', '1800'],
            ['timeout', '5000'],
        ],
    );
    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is($mon->timeouts, [{ ms => '5000' }], 'timeout without test type');
};

subtest 'announcement: from_event minimal' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '7200',
    );
    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is($mon->frequency, '7200', 'frequency');
    is($mon->timeouts, [], 'no timeouts');
    is($mon->checks, [], 'no checks');
    is($mon->geohash, undef, 'no geohash');
};

###############################################################################
# Announcement: validate
###############################################################################

subtest 'announcement: validate valid event' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
    );
    ok(Net::Nostr::RelayMonitor->validate($event), 'valid announcement event');
};

subtest 'announcement: validate rejects missing frequency' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 10166, content => '',
        tags => [['c', 'ws']],
    );
    like(
        dies { Net::Nostr::RelayMonitor->validate($event) },
        qr/frequency/i,
        'rejects missing frequency'
    );
};

###############################################################################
# Validate rejects unsupported kinds
###############################################################################

subtest 'validate: rejects unsupported kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::RelayMonitor->validate($event) },
        qr/kind/i,
        'rejects kind 1'
    );
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::RelayMonitor->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# Risk Mitigation: not testable in code, but kind classification confirms
# that 30166 events are addressable (clients can query/filter them)
###############################################################################

subtest 'kind classification' => sub {
    my $disc = Net::Nostr::RelayMonitor->discovery_event(
        pubkey => $PK, relay_url => 'wss://r/',
    );
    ok($disc->is_addressable, '30166 is addressable');
    ok(!$disc->is_replaceable, '30166 not replaceable');

    my $ann = Net::Nostr::RelayMonitor->announcement_event(
        pubkey => $PK, frequency => '3600',
    );
    ok($ann->is_replaceable, '10166 is replaceable');
    ok(!$ann->is_addressable, '10166 not addressable');
};

subtest 'discovery: passes created_at through' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey     => $PK,
        relay_url  => 'wss://r/',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

subtest 'announcement: passes created_at through' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey     => $PK,
        frequency  => '3600',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

done_testing;
