use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Event;
use Net::Nostr::Metadata;

my $PK = 'a' x 64;
my $JSON = JSON->new->utf8->canonical;

###############################################################################
# Kind 0 metadata event
###############################################################################

subtest 'metadata: kind 0' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'alice',
    );
    is($event->kind, 0, 'kind is 0');
    ok($event->is_replaceable, 'kind 0 is replaceable');
};

###############################################################################
# NIP-01 base fields: name, about, picture
###############################################################################

subtest 'metadata: name field' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'alice',
    );
    my $data = $JSON->decode($event->content);
    is($data->{name}, 'alice', 'name in content JSON');
};

subtest 'metadata: about field' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'alice',
        about  => 'Nostr enthusiast',
    );
    my $data = $JSON->decode($event->content);
    is($data->{about}, 'Nostr enthusiast', 'about in content JSON');
};

subtest 'metadata: picture field' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey  => $PK,
        name    => 'alice',
        picture => 'https://example.com/avatar.jpg',
    );
    my $data = $JSON->decode($event->content);
    is($data->{picture}, 'https://example.com/avatar.jpg', 'picture in content JSON');
};

###############################################################################
# NIP-24 extra fields
###############################################################################

subtest 'metadata: display_name field' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey       => $PK,
        name         => 'alice',
        display_name => 'Alice in Wonderland',
    );
    my $data = $JSON->decode($event->content);
    is($data->{display_name}, 'Alice in Wonderland', 'display_name in content JSON');
};

subtest 'metadata: website field' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey  => $PK,
        name    => 'alice',
        website => 'https://alice.example.com',
    );
    my $data = $JSON->decode($event->content);
    is($data->{website}, 'https://alice.example.com', 'website in content JSON');
};

subtest 'metadata: banner field' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'alice',
        banner => 'https://example.com/banner.jpg',
    );
    my $data = $JSON->decode($event->content);
    is($data->{banner}, 'https://example.com/banner.jpg', 'banner in content JSON');
};

subtest 'metadata: bot field' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'newsbot',
        bot    => JSON::true,
    );
    my $data = $JSON->decode($event->content);
    is($data->{bot}, JSON::true, 'bot is true in content JSON');
};

subtest 'metadata: bot false' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'alice',
        bot    => JSON::false,
    );
    my $data = $JSON->decode($event->content);
    is($data->{bot}, JSON::false, 'bot is false in content JSON');
};

subtest 'metadata: birthday field' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey   => $PK,
        name     => 'alice',
        birthday => { year => 1990, month => 6, day => 15 },
    );
    my $data = $JSON->decode($event->content);
    is($data->{birthday}, { year => 1990, month => 6, day => 15 },
        'birthday object in content JSON');
};

subtest 'metadata: birthday with partial fields (each MAY be omitted)' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey   => $PK,
        name     => 'alice',
        birthday => { month => 6, day => 15 },
    );
    my $data = $JSON->decode($event->content);
    is($data->{birthday}, { month => 6, day => 15 },
        'birthday without year');

    $event = Net::Nostr::Metadata->to_event(
        pubkey   => $PK,
        name     => 'alice',
        birthday => { year => 1990 },
    );
    $data = $JSON->decode($event->content);
    is($data->{birthday}, { year => 1990 }, 'birthday year only');
};

subtest 'metadata: all NIP-24 fields together' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey       => $PK,
        name         => 'alice',
        display_name => 'Alice',
        about        => 'Hello',
        picture      => 'https://example.com/pic.jpg',
        website      => 'https://alice.example.com',
        banner       => 'https://example.com/banner.jpg',
        bot          => JSON::false,
        birthday     => { year => 1990, month => 6, day => 15 },
    );
    my $data = $JSON->decode($event->content);
    is($data->{name}, 'alice', 'name');
    is($data->{display_name}, 'Alice', 'display_name');
    is($data->{about}, 'Hello', 'about');
    is($data->{picture}, 'https://example.com/pic.jpg', 'picture');
    is($data->{website}, 'https://alice.example.com', 'website');
    is($data->{banner}, 'https://example.com/banner.jpg', 'banner');
    is($data->{bot}, JSON::false, 'bot');
    is($data->{birthday}, { year => 1990, month => 6, day => 15 }, 'birthday');
};

subtest 'metadata: omitted fields not included in JSON' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'alice',
    );
    my $data = $JSON->decode($event->content);
    is([sort keys %$data], ['name'], 'only name in JSON');
};

###############################################################################
# name should always be set
###############################################################################

subtest 'metadata: name should always be set' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey       => $PK,
        name         => 'alice',
        display_name => 'Alice in Wonderland',
    );
    my $data = $JSON->decode($event->content);
    ok(exists $data->{name}, 'name present even when display_name is set');
};

###############################################################################
# from_event: round-trip parsing
###############################################################################

subtest 'from_event: round-trip all fields' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey       => $PK,
        name         => 'alice',
        display_name => 'Alice',
        about        => 'Hello world',
        picture      => 'https://example.com/pic.jpg',
        website      => 'https://alice.example.com',
        banner       => 'https://example.com/banner.jpg',
        bot          => JSON::true,
        birthday     => { year => 1990, month => 6, day => 15 },
    );
    my $meta = Net::Nostr::Metadata->from_event($event);
    ok($meta, 'from_event returns object');
    is($meta->name, 'alice', 'name');
    is($meta->display_name, 'Alice', 'display_name');
    is($meta->about, 'Hello world', 'about');
    is($meta->picture, 'https://example.com/pic.jpg', 'picture');
    is($meta->website, 'https://alice.example.com', 'website');
    is($meta->banner, 'https://example.com/banner.jpg', 'banner');
    is($meta->bot, JSON::true, 'bot');
    is($meta->birthday, { year => 1990, month => 6, day => 15 }, 'birthday');
};

subtest 'from_event: minimal' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'alice',
    );
    my $meta = Net::Nostr::Metadata->from_event($event);
    is($meta->name, 'alice', 'name');
    is($meta->display_name, undef, 'no display_name');
    is($meta->about, undef, 'no about');
    is($meta->picture, undef, 'no picture');
    is($meta->website, undef, 'no website');
    is($meta->banner, undef, 'no banner');
    is($meta->bot, undef, 'no bot');
    is($meta->birthday, undef, 'no birthday');
};

subtest 'from_event: returns undef for wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '{}', tags => [],
    );
    is(Net::Nostr::Metadata->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# Deprecated fields: displayName -> display_name, username -> name
###############################################################################

subtest 'from_event: deprecated displayName mapped to display_name' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 0, tags => [],
        content => $JSON->encode({ name => 'alice', displayName => 'Alice Display' }),
    );
    my $meta = Net::Nostr::Metadata->from_event($event);
    is($meta->display_name, 'Alice Display', 'displayName mapped to display_name');
};

subtest 'from_event: display_name takes precedence over displayName' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 0, tags => [],
        content => $JSON->encode({
            name         => 'alice',
            display_name => 'Correct',
            displayName  => 'Deprecated',
        }),
    );
    my $meta = Net::Nostr::Metadata->from_event($event);
    is($meta->display_name, 'Correct', 'display_name wins over displayName');
};

subtest 'from_event: deprecated username mapped to name' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 0, tags => [],
        content => $JSON->encode({ username => 'alice_old' }),
    );
    my $meta = Net::Nostr::Metadata->from_event($event);
    is($meta->name, 'alice_old', 'username mapped to name');
};

subtest 'from_event: name takes precedence over username' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 0, tags => [],
        content => $JSON->encode({ name => 'alice', username => 'alice_old' }),
    );
    my $meta = Net::Nostr::Metadata->from_event($event);
    is($meta->name, 'alice', 'name wins over username');
};

###############################################################################
# to_event does NOT emit deprecated fields
###############################################################################

subtest 'to_event: does not emit displayName or username' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey       => $PK,
        name         => 'alice',
        display_name => 'Alice',
    );
    my $data = $JSON->decode($event->content);
    ok(!exists $data->{displayName}, 'no displayName');
    ok(!exists $data->{username}, 'no username');
};

###############################################################################
# Kind 3 deprecated relay content (NIP-65 should be used instead)
###############################################################################

subtest 'kind 3: deprecated relay content documented' => sub {
    # NIP-24 says kind 3 relay JSON in content is deprecated; NIP-65 should
    # be used instead.  We simply verify that a kind 3 event with relay
    # content is still a valid event (we don't strip it).
    my $relay_json = $JSON->encode({
        'wss://relay.example.com' => { read => JSON::true, write => JSON::true },
    });
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 3, content => $relay_json, tags => [],
    );
    is($event->kind, 3, 'kind 3 with relay content is valid');
};

###############################################################################
# Standard tags: t (hashtag) MUST be lowercase
###############################################################################

subtest 'tags: t tag (hashtag) value MUST be lowercase' => sub {
    my $event = Net::Nostr::Metadata->hashtag_tag('nostr');
    is($event, ['t', 'nostr'], 'lowercase hashtag');
};

subtest 'tags: t tag lowercases input' => sub {
    my $tag = Net::Nostr::Metadata->hashtag_tag('NoStr');
    is($tag->[1], 'nostr', 'input lowercased');
};

###############################################################################
# Standard tags: r (web URL)
###############################################################################

subtest 'tags: r tag (web URL)' => sub {
    my $tag = Net::Nostr::Metadata->url_tag('https://example.com');
    is($tag, ['r', 'https://example.com'], 'r tag');
};

###############################################################################
# Standard tags: title
###############################################################################

subtest 'tags: title tag' => sub {
    my $tag = Net::Nostr::Metadata->title_tag('My Event');
    is($tag, ['title', 'My Event'], 'title tag');
};

###############################################################################
# Standard tags: i (external ID)
###############################################################################

subtest 'tags: i tag (external ID)' => sub {
    my $tag = Net::Nostr::Metadata->external_id_tag('github:torvalds');
    is($tag, ['i', 'github:torvalds'], 'i tag');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid metadata event' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'alice',
    );
    ok(Net::Nostr::Metadata->validate($event), 'valid metadata');
};

subtest 'validate: rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '{}', tags => [],
    );
    like(
        dies { Net::Nostr::Metadata->validate($event) },
        qr/kind/i,
        'rejects wrong kind'
    );
};

subtest 'validate: rejects non-JSON content' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 0, content => 'not json', tags => [],
    );
    like(
        dies { Net::Nostr::Metadata->validate($event) },
        qr/content/i,
        'rejects non-JSON content'
    );
};

###############################################################################
# created_at passthrough
###############################################################################

subtest 'created_at passthrough' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey     => $PK,
        name       => 'alice',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::Metadata->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# from_event: handles unknown fields gracefully
###############################################################################

subtest 'from_event: unknown fields in JSON ignored' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 0, tags => [],
        content => $JSON->encode({ name => 'alice', nip05 => 'alice@example.com', lud16 => 'alice@ln.example.com' }),
    );
    my $meta = Net::Nostr::Metadata->from_event($event);
    is($meta->name, 'alice', 'known field parsed');
    # Unknown fields silently ignored (other NIPs define them)
};

###############################################################################
# Empty content
###############################################################################

subtest 'from_event: empty JSON object' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 0, tags => [], content => '{}',
    );
    my $meta = Net::Nostr::Metadata->from_event($event);
    ok($meta, 'parsed empty metadata');
    is($meta->name, undef, 'no name');
};

done_testing;
