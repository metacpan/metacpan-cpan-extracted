use strictures 2;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use TestFixtures qw(make_event);
use JSON ();

use Net::Nostr::Repost;

my $JSON = JSON->new->utf8;
my $pubkey = 'a' x 64;
my $other_pubkey = 'b' x 64;
my $relay = 'wss://relay.example.com';

# Build test events
my $note = make_event(
    id         => 'c' x 64,
    kind       => 1,
    pubkey     => $other_pubkey,
    created_at => 1000,
    content    => 'hello',
    tags       => [],
    sig        => 'd' x 128,
);

my $article = make_event(
    id         => 'e' x 64,
    kind       => 30023,
    pubkey     => $other_pubkey,
    created_at => 2000,
    content    => 'long form',
    tags       => [['d', 'my-article']],
    sig        => 'f' x 128,
);

# --- SYNOPSIS examples ---

subtest 'POD SYNOPSIS: repost a kind 1 text note (creates kind 6)' => sub {
    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    is $repost->kind, 6, 'kind 6 for kind 1 repost';
    isa_ok $repost, 'Net::Nostr::Event';
};

subtest 'POD SYNOPSIS: repost any other event (creates kind 16)' => sub {
    my $repost = Net::Nostr::Repost->repost(
        event     => $article,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    is $repost->kind, 16, 'kind 16 for non-kind-1 repost';
    isa_ok $repost, 'Net::Nostr::Event';
};

subtest 'POD SYNOPSIS: quote repost (adds q tag)' => sub {
    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
        quote     => 1,
    );
    my @q = grep { $_->[0] eq 'q' } @{$repost->tags};
    is scalar @q, 1, 'has q tag';
    is $q[0][1], $note->id, 'q tag has event id';
};

subtest 'POD SYNOPSIS: parse repost structure from an event' => sub {
    # Build a kind 6 repost event to parse
    my $repost_event = make_event(
        id         => '1' x 64,
        kind       => 6,
        pubkey     => $pubkey,
        created_at => 3000,
        content    => $JSON->encode($note->to_hash),
        tags       => [['e', $note->id, $relay], ['p', $note->pubkey]],
        sig        => '2' x 128,
    );

    my $info = Net::Nostr::Repost->from_event($repost_event);
    if ($info) {
        is $info->event_id, $note->id, 'Reposted event: event_id';
        is $info->relay_url, $relay, 'From relay: relay_url';
        if ($info->embedded_event) {
            is $info->embedded_event->content, 'hello', 'Content: embedded content';
        } else {
            fail 'embedded_event should be defined';
        }
    } else {
        fail 'from_event should return an object';
    }
};

subtest 'POD SYNOPSIS: validate a repost event' => sub {
    my $valid = make_event(
        id         => '3' x 64,
        kind       => 6,
        pubkey     => $pubkey,
        created_at => 4000,
        content    => '',
        tags       => [['e', $note->id, $relay]],
        sig        => '4' x 128,
    );
    my $ok = eval { Net::Nostr::Repost->validate($valid) };
    ok $ok, 'validate returns true for valid repost';
};

# --- repost() method POD ---

subtest 'POD repost: content override' => sub {
    my $event = Net::Nostr::Repost->repost(
        event      => $note,
        pubkey     => $pubkey,
        relay_url  => $relay,
        content    => '',
    );
    is $event->content, '', 'empty content override';
};

subtest 'POD repost: created_at passthrough' => sub {
    my $event = Net::Nostr::Repost->repost(
        event      => $note,
        pubkey     => $pubkey,
        relay_url  => $relay,
        created_at => 99999,
    );
    is $event->created_at, 99999, 'created_at passed through';
};

subtest 'POD repost: croaks if event missing' => sub {
    eval { Net::Nostr::Repost->repost(pubkey => $pubkey, relay_url => $relay) };
    like $@, qr/event/, 'croaks without event';
};

subtest 'POD repost: croaks if pubkey missing' => sub {
    eval { Net::Nostr::Repost->repost(event => $note, relay_url => $relay) };
    like $@, qr/pubkey/, 'croaks without pubkey';
};

subtest 'POD repost: croaks if relay_url missing' => sub {
    eval { Net::Nostr::Repost->repost(event => $note, pubkey => $pubkey) };
    like $@, qr/relay_url/, 'croaks without relay_url';
};

# --- from_event() POD ---

subtest 'POD from_event: accessors' => sub {
    my $repost_event = make_event(
        id         => '5' x 64,
        kind       => 6,
        pubkey     => $pubkey,
        created_at => 5000,
        content    => $JSON->encode($note->to_hash),
        tags       => [['e', $note->id, $relay], ['p', $note->pubkey]],
        sig        => '6' x 128,
    );

    my $info = Net::Nostr::Repost->from_event($repost_event);
    is $info->event_id, $note->id, 'event_id accessor';
    is $info->embedded_event->content, 'hello', 'embedded_event->content';
};

subtest 'POD from_event: undef for non-repost' => sub {
    my $regular = make_event(
        id         => '7' x 64,
        kind       => 1,
        pubkey     => $pubkey,
        created_at => 6000,
        content    => 'not a repost',
        tags       => [],
        sig        => '8' x 128,
    );
    my $info = Net::Nostr::Repost->from_event($regular);
    is $info, undef, 'undef for non-repost kind';
};

# --- validate() POD ---

subtest 'POD validate: eval pattern' => sub {
    my $bad = make_event(
        id         => '9' x 64,
        kind       => 1,
        pubkey     => $pubkey,
        created_at => 7000,
        content    => '',
        tags       => [],
        sig        => 'a' x 128,
    );
    eval { Net::Nostr::Repost->validate($bad) };
    ok $@, 'Invalid repost sets $@';
    like $@, qr/kind 6 or 16/, 'error mentions kind requirement';
};

# --- Accessor POD examples ---

subtest 'POD accessor: event_id' => sub {
    my $info = Net::Nostr::Repost->new(event_id => 'abc123');
    my $id = $info->event_id;
    is $id, 'abc123', 'event_id accessor';
};

subtest 'POD accessor: relay_url' => sub {
    my $info = Net::Nostr::Repost->new(relay_url => $relay);
    my $url = $info->relay_url;
    is $url, $relay, 'relay_url accessor';
};

subtest 'POD accessor: author_pubkey' => sub {
    my $info = Net::Nostr::Repost->new(author_pubkey => $other_pubkey);
    my $pk = $info->author_pubkey;
    is $pk, $other_pubkey, 'author_pubkey accessor';
};

subtest 'POD accessor: reposted_kind' => sub {
    my $info = Net::Nostr::Repost->new(reposted_kind => '30023');
    my $kind = $info->reposted_kind;
    is $kind, '30023', 'reposted_kind accessor';
};

subtest 'POD accessor: event_coordinate' => sub {
    my $coord_val = "30023:${other_pubkey}:my-article";
    my $info = Net::Nostr::Repost->new(event_coordinate => $coord_val);
    my $coord = $info->event_coordinate;
    is $coord, $coord_val, 'event_coordinate accessor';
};

subtest 'POD accessor: embedded_event' => sub {
    my $inner = make_event(
        id => 'c' x 64, kind => 1, pubkey => $other_pubkey,
        created_at => 1000, content => 'test', tags => [], sig => 'd' x 128,
    );
    my $info = Net::Nostr::Repost->new(embedded_event => $inner);
    my $event = $info->embedded_event;
    isa_ok $event, 'Net::Nostr::Event';
    is $event->content, 'test', 'embedded_event content';
};

subtest 'POD accessor: quote_event_id' => sub {
    my $info = Net::Nostr::Repost->new(quote_event_id => 'c' x 64);
    my $qid = $info->quote_event_id;
    is $qid, 'c' x 64, 'quote_event_id accessor';
};

subtest 'POD from_event: quote repost round-trip' => sub {
    my $quote_repost = make_event(
        id         => 'a1' x 32,
        kind       => 6,
        pubkey     => $pubkey,
        created_at => 8000,
        content    => $JSON->encode($note->to_hash),
        tags       => [
            ['e', $note->id, $relay],
            ['p', $note->pubkey],
            ['q', $note->id, $relay, $note->pubkey],
        ],
        sig        => 'b1' x 64,
    );

    my $info = Net::Nostr::Repost->from_event($quote_repost);
    is $info->quote_event_id, $note->id, 'quote_event_id parsed from q tag';
};

subtest 'POD from_event: non-quote has no quote_event_id' => sub {
    my $plain = make_event(
        id         => 'c1' x 32,
        kind       => 6,
        pubkey     => $pubkey,
        created_at => 9000,
        content    => $JSON->encode($note->to_hash),
        tags       => [['e', $note->id, $relay], ['p', $note->pubkey]],
        sig        => 'd1' x 64,
    );

    my $info = Net::Nostr::Repost->from_event($plain);
    is $info->quote_event_id, undef, 'no quote_event_id for non-quote repost';
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $info = Net::Nostr::Repost->new(
        event_id  => 'aa' x 32,
        relay_url => 'wss://relay.example.com',
    );
    is $info->event_id, 'aa' x 32;
    is $info->relay_url, 'wss://relay.example.com';
};

subtest 'new() rejects unknown arguments' => sub {
    eval { Net::Nostr::Repost->new(event_id => 'aa' x 32, bogus => 'value') };
    like($@, qr/unknown.+bogus/i, 'unknown argument rejected');
};

done_testing;
