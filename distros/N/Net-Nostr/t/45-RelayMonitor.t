use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::RelayMonitor;

my $PK = 'a' x 64;

###############################################################################
# POD example: discovery event
###############################################################################

subtest 'POD: build discovery event' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey       => $PK,
        relay_url    => 'wss://relay.example.com/',
        network      => 'clearnet',
        nips         => [1, 11, 42],
        rtt_open     => '150',
        requirements => ['!payment', 'auth'],
    );
    is($event->kind, 30166, 'kind is 30166');
    is($event->d_tag, 'wss://relay.example.com/', 'd tag is relay URL');

    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is($mon->relay_url, 'wss://relay.example.com/', 'relay_url round-trips');
    is($mon->network, 'clearnet', 'network round-trips');
    is($mon->rtt_open, '150', 'rtt_open round-trips');
};

###############################################################################
# POD example: announcement event
###############################################################################

subtest 'POD: build announcement event' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
        checks    => [qw(ws nip11 ssl dns)],
        timeouts  => [{ test => 'open', ms => '5000' }],
    );
    is($event->kind, 10166, 'kind is 10166');

    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is($mon->frequency, '3600', 'frequency round-trips');
    is($mon->checks, [qw(ws nip11 ssl dns)], 'checks round-trip');
};

###############################################################################
# POD example: parse from event
###############################################################################

subtest 'POD: from_event' => sub {
    use Net::Nostr::Event;
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30166, content => '',
        tags => [
            ['d', 'wss://relay.example.com/'],
            ['n', 'clearnet'],
            ['N', '1'],
            ['N', '11'],
        ],
    );
    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is($mon->relay_url, 'wss://relay.example.com/');
    is($mon->network, 'clearnet');
    is($mon->nips, ['1', '11']);
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: no args' => sub {
    my $mon = Net::Nostr::RelayMonitor->new;
    isa_ok($mon, 'Net::Nostr::RelayMonitor');
};

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::RelayMonitor->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://relay.example.com/',
    );
    ok(Net::Nostr::RelayMonitor->validate($event), 'validate returns true');

    my $bad = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30166, content => '', tags => [],
    );
    eval { Net::Nostr::RelayMonitor->validate($bad) };
    ok($@, 'validate croaks on invalid event');
};

###############################################################################
# exports
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::RelayMonitor',
        qw(new discovery_event announcement_event from_event validate
           relay_url network relay_type nips requirements topics kinds
           geohash languages rtt_open rtt_read rtt_write nip11
           frequency timeouts checks));
};

###############################################################################
# Builder validation
###############################################################################

subtest 'discovery_event: requires relay_url' => sub {
    like(dies { Net::Nostr::RelayMonitor->discovery_event(pubkey => $PK) },
        qr/relay_url/i, 'missing relay_url rejected');
};

subtest 'announcement_event: requires frequency' => sub {
    like(dies { Net::Nostr::RelayMonitor->announcement_event(pubkey => $PK) },
        qr/frequency/i, 'missing frequency rejected');
};

###############################################################################
# Discovery event: all optional fields round-trip
###############################################################################

subtest 'discovery event: all optional fields round-trip' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey       => $PK,
        relay_url    => 'wss://relay.example.com/',
        network      => 'clearnet',
        relay_type   => 'paid',
        geohash      => 'u33d8',
        nips         => [1, 11, 42, 50],
        requirements => ['!payment', 'auth'],
        topics       => ['bitcoin', 'nostr'],
        kinds        => [0, 1, 30023],
        languages    => ['en', 'de'],
        rtt_open     => '150',
        rtt_read     => '80',
        rtt_write    => '200',
        nip11        => '{"name":"test"}',
    );
    is($event->kind, 30166, 'kind 30166');
    is($event->content, '{"name":"test"}', 'nip11 in content');

    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is $mon->relay_url,    'wss://relay.example.com/', 'relay_url';
    is $mon->network,      'clearnet',                  'network';
    is $mon->relay_type,   'paid',                      'relay_type';
    is $mon->geohash,      'u33d8',                     'geohash';
    is $mon->nips,         [qw(1 11 42 50)],            'nips';
    is $mon->requirements, [qw(!payment auth)],         'requirements';
    is $mon->topics,       [qw(bitcoin nostr)],         'topics';
    is $mon->kinds,        [qw(0 1 30023)],             'kinds';
    is $mon->languages,    [qw(en de)],                 'languages';
    is $mon->rtt_open,     '150',                       'rtt_open';
    is $mon->rtt_read,     '80',                        'rtt_read';
    is $mon->rtt_write,    '200',                       'rtt_write';
    is $mon->nip11,        '{"name":"test"}',           'nip11';
};

###############################################################################
# Discovery event: minimal (no optional fields)
###############################################################################

subtest 'discovery event: minimal' => sub {
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey    => $PK,
        relay_url => 'wss://relay.example.com/',
    );
    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is $mon->relay_url, 'wss://relay.example.com/', 'relay_url parsed';
    is $mon->network,    undef, 'network defaults undef';
    is $mon->relay_type, undef, 'relay_type defaults undef';
    is $mon->nips,       [],    'nips defaults empty';
    is $mon->topics,     [],    'topics defaults empty';
    is $mon->languages,  [],    'languages defaults empty';
    is $mon->nip11,      undef, 'nip11 undef for empty content';
};

###############################################################################
# Announcement event: all optional fields round-trip
###############################################################################

subtest 'announcement event: all optional fields round-trip' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '3600',
        geohash   => 'u33d8',
        checks    => [qw(ws nip11 ssl dns geo)],
        timeouts  => [
            { ms => '3000' },
            { test => 'open',  ms => '5000' },
            { test => 'read',  ms => '2000' },
        ],
    );
    is($event->kind, 10166, 'kind 10166');

    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is $mon->frequency, '3600',  'frequency';
    is $mon->geohash,   'u33d8', 'geohash';
    is $mon->checks,    [qw(ws nip11 ssl dns geo)], 'checks';
    is scalar @{$mon->timeouts}, 3, 'three timeouts';
    is $mon->timeouts->[0]{ms}, '3000', 'global timeout ms';
    ok !exists $mon->timeouts->[0]{test}, 'global timeout has no test key';
    is $mon->timeouts->[1]{test}, 'open', 'typed timeout test';
    is $mon->timeouts->[1]{ms},   '5000', 'typed timeout ms';
};

###############################################################################
# Announcement event: minimal
###############################################################################

subtest 'announcement event: minimal' => sub {
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $PK,
        frequency => '60',
    );
    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is $mon->frequency, '60',  'frequency parsed';
    is $mon->checks,    [],    'checks defaults empty';
    is $mon->timeouts,  [],    'timeouts defaults empty';
    is $mon->geohash,   undef, 'geohash defaults undef';
};

###############################################################################
# from_event: unsupported kind returns undef
###############################################################################

subtest 'from_event: unsupported kind returns undef' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::RelayMonitor->from_event($event), undef, 'kind 1 returns undef');
};

###############################################################################
# validate: error paths
###############################################################################

subtest 'validate: rejects discovery without d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30166, content => '', tags => [],
    );
    like(dies { Net::Nostr::RelayMonitor->validate($event) },
        qr/d.*tag/i, 'missing d tag rejected');
};

subtest 'validate: rejects announcement without frequency tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 10166, content => '', tags => [],
    );
    like(dies { Net::Nostr::RelayMonitor->validate($event) },
        qr/frequency/i, 'missing frequency tag rejected');
};

subtest 'validate: rejects unsupported kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    like(dies { Net::Nostr::RelayMonitor->validate($event) },
        qr/kind/i, 'unsupported kind rejected');
};

###############################################################################
# from_event: discovery with nip11 content
###############################################################################

subtest 'from_event: discovery nip11 from content' => sub {
    my $nip11_json = '{"name":"Test Relay","description":"A test"}';
    my $event = Net::Nostr::Event->new(
        pubkey  => $PK,
        kind    => 30166,
        content => $nip11_json,
        tags    => [['d', 'wss://relay.example.com/']],
    );
    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is $mon->nip11, $nip11_json, 'nip11 from content';
};

subtest 'from_event: discovery empty content means no nip11' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PK,
        kind    => 30166,
        content => '',
        tags    => [['d', 'wss://relay.example.com/']],
    );
    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    is $mon->nip11, undef, 'empty content does not set nip11';
};

done_testing;
