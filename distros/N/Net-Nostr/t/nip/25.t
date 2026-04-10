use strictures 2;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use TestFixtures qw(make_event);
use JSON ();

use Net::Nostr::Event;
use Net::Nostr::Reaction;

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
    content    => 'hello world',
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

# --- kind 7 basics ---

subtest 'reaction is a kind 7 event' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    is $reaction->kind, 7, 'kind 7';
    isa_ok $reaction, 'Net::Nostr::Event';
};

# --- content ---

subtest 'content defaults to +' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    is $reaction->content, '+', 'default content is +';
};

subtest 'content can be set to -' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
        content   => '-',
    );
    is $reaction->content, '-', 'content is -';
};

subtest 'content can be set to emoji' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
        content   => "\x{1F44D}",
    );
    is $reaction->content, "\x{1F44D}", 'content is thumbs up emoji';
};

subtest 'empty string content treated as like' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
        content   => '',
    );
    is $reaction->content, '', 'empty string content allowed';
};

# --- e tag ---

subtest 'MUST include e tag with event id' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @e = grep { $_->[0] eq 'e' } @{$reaction->tags};
    is scalar @e, 1, 'one e tag';
    is $e[0][1], $note->id, 'e tag has event id';
};

subtest 'e tag SHOULD include relay hint' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @e = grep { $_->[0] eq 'e' } @{$reaction->tags};
    is $e[0][2], $relay, 'e tag has relay hint';
};

subtest 'e tag SHOULD include pubkey hint' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @e = grep { $_->[0] eq 'e' } @{$reaction->tags};
    is $e[0][3], $note->pubkey, 'e tag has pubkey hint';
};

# --- p tag ---

subtest 'SHOULD include p tag with event pubkey' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @p = grep { $_->[0] eq 'p' } @{$reaction->tags};
    is scalar @p, 1, 'one p tag';
    is $p[0][1], $note->pubkey, 'p tag has event pubkey';
};

subtest 'p tag SHOULD include relay hint' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @p = grep { $_->[0] eq 'p' } @{$reaction->tags};
    is $p[0][2], $relay, 'p tag has relay hint';
};

# --- k tag ---

subtest 'MAY include k tag with stringified kind' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @k = grep { $_->[0] eq 'k' } @{$reaction->tags};
    is scalar @k, 1, 'one k tag';
    is $k[0][1], '1', 'k tag has stringified kind';
};

# --- a tag for addressable events ---

subtest 'SHOULD include a tag for addressable events' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $article,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @a = grep { $_->[0] eq 'a' } @{$reaction->tags};
    is scalar @a, 1, 'one a tag';
    is $a[0][1], "30023:${other_pubkey}:my-article", 'a tag has event coordinate';
};

subtest 'a tag SHOULD include relay and pubkey hints' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $article,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @a = grep { $_->[0] eq 'a' } @{$reaction->tags};
    is $a[0][2], $relay, 'a tag has relay hint';
    is $a[0][3], $article->pubkey, 'a tag has pubkey hint';
};

subtest 'no a tag for non-addressable events' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @a = grep { $_->[0] eq 'a' } @{$reaction->tags};
    is scalar @a, 0, 'no a tag for kind 1';
};

subtest 'addressable reaction also includes e tag' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $article,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    my @e = grep { $_->[0] eq 'e' } @{$reaction->tags};
    is scalar @e, 1, 'e tag present alongside a tag';
    is $e[0][1], $article->id, 'e tag has event id';
};

# --- spec example ---

subtest 'spec example: make_like_event equivalent' => sub {
    my $liked = $note;
    my $hint  = $relay;

    my $reaction = Net::Nostr::Reaction->react(
        event     => $liked,
        pubkey    => $pubkey,
        relay_url => $hint,
        content   => '+',
    );

    is $reaction->kind, 7, 'kind 7';
    is $reaction->content, '+', 'content is +';

    my @tags = @{$reaction->tags};
    # e tag: ["e", liked.id, hint, liked.pubkey]
    my @e = grep { $_->[0] eq 'e' } @tags;
    is $e[0], ['e', $liked->id, $hint, $liked->pubkey], 'e tag matches spec example';
    # p tag: ["p", liked.pubkey, hint]
    my @p = grep { $_->[0] eq 'p' } @tags;
    is $p[0], ['p', $liked->pubkey, $hint], 'p tag matches spec example';
    # k tag: ["k", String(liked.kind)]
    my @k = grep { $_->[0] eq 'k' } @tags;
    is $k[0], ['k', '1'], 'k tag matches spec example';
};

# --- external content reactions (kind 17) ---

subtest 'external reaction is kind 17' => sub {
    my $reaction = Net::Nostr::Reaction->react_external(
        pubkey  => $pubkey,
        content => "\x{2B50}",
        tags    => [
            ['k', 'web'],
            ['i', 'https://example.com'],
        ],
    );
    is $reaction->kind, 17, 'kind 17';
    is $reaction->content, "\x{2B50}", 'content is star emoji';
};

subtest 'external reaction: spec website example' => sub {
    my $reaction = Net::Nostr::Reaction->react_external(
        pubkey  => $pubkey,
        content => "\x{2B50}",
        tags    => [
            ['k', 'web'],
            ['i', 'https://example.com'],
        ],
    );
    my @k = grep { $_->[0] eq 'k' } @{$reaction->tags};
    my @i = grep { $_->[0] eq 'i' } @{$reaction->tags};
    is $k[0], ['k', 'web'], 'k tag for website';
    is $i[0], ['i', 'https://example.com'], 'i tag for URL';
};

subtest 'external reaction: spec podcast example' => sub {
    my $reaction = Net::Nostr::Reaction->react_external(
        pubkey  => $pubkey,
        content => '+',
        tags    => [
            ['k', 'podcast:guid'],
            ['i', 'podcast:guid:917393e3-1b1e-5cef-ace4-edaa54e1f810', 'https://fountain.fm/show/QRT0l2EfrKXNGDlRrmjL'],
            ['k', 'podcast:item:guid'],
            ['i', 'podcast:item:guid:PC20-229', 'https://fountain.fm/episode/DQqBg5sD3qFGMCZoSuLF'],
        ],
    );
    is $reaction->kind, 17, 'kind 17';
    my @k = grep { $_->[0] eq 'k' } @{$reaction->tags};
    my @i = grep { $_->[0] eq 'i' } @{$reaction->tags};
    is scalar @k, 2, 'two k tags';
    is scalar @i, 2, 'two i tags';
    is $k[0], ['k', 'podcast:guid'], 'first k tag';
    is $i[0], ['i', 'podcast:guid:917393e3-1b1e-5cef-ace4-edaa54e1f810', 'https://fountain.fm/show/QRT0l2EfrKXNGDlRrmjL'], 'first i tag with hint';
};

subtest 'external reaction requires content' => sub {
    eval {
        Net::Nostr::Reaction->react_external(
            pubkey => $pubkey,
            tags   => [['k', 'web'], ['i', 'https://example.com']],
        );
    };
    like $@, qr/content/, 'croaks without content';
};

subtest 'external reaction requires tags' => sub {
    eval {
        Net::Nostr::Reaction->react_external(
            pubkey  => $pubkey,
            content => '+',
        );
    };
    like $@, qr/tags/, 'croaks without tags';
};

# --- custom emoji reaction (NIP-30) ---

subtest 'custom emoji reaction with emoji tag' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
        content   => ':soapbox:',
        emoji     => ['soapbox', 'https://gleasonator.com/emoji/Gleasonator/soapbox.png'],
    );
    is $reaction->content, ':soapbox:', 'content is :soapbox:';
    my @emoji = grep { $_->[0] eq 'emoji' } @{$reaction->tags};
    is scalar @emoji, 1, 'one emoji tag';
    is $emoji[0], ['emoji', 'soapbox', 'https://gleasonator.com/emoji/Gleasonator/soapbox.png'], 'emoji tag matches spec';
};

# --- from_event ---

subtest 'from_event parses kind 7 reaction' => sub {
    my $event = make_event(
        id         => '1' x 64,
        kind       => 7,
        pubkey     => $pubkey,
        created_at => 3000,
        content    => '+',
        tags       => [
            ['e', $note->id, $relay, $note->pubkey],
            ['p', $note->pubkey, $relay],
            ['k', '1'],
        ],
        sig        => '2' x 128,
    );

    my $info = Net::Nostr::Reaction->from_event($event);
    ok $info, 'parsed successfully';
    is $info->event_id, $note->id, 'event_id';
    is $info->relay_url, $relay, 'relay_url';
    is $info->author_pubkey, $note->pubkey, 'author_pubkey';
    is $info->content, '+', 'content';
    is $info->reacted_kind, '1', 'reacted_kind';
    ok $info->is_like, 'is_like for +';
    ok !$info->is_dislike, 'not is_dislike';
};

subtest 'from_event parses kind 17 external reaction' => sub {
    my $event = make_event(
        id         => '3' x 64,
        kind       => 17,
        pubkey     => $pubkey,
        created_at => 4000,
        content    => '+',
        tags       => [
            ['k', 'web'],
            ['i', 'https://example.com'],
        ],
        sig        => '4' x 128,
    );

    my $info = Net::Nostr::Reaction->from_event($event);
    ok $info, 'parsed kind 17';
    is $info->content, '+', 'content';
    is $info->reacted_kind, 'web', 'reacted_kind from k tag';
};

subtest 'from_event returns undef for non-reaction' => sub {
    my $info = Net::Nostr::Reaction->from_event($note);
    is $info, undef, 'undef for kind 1';
};

subtest 'from_event parses a tag for addressable event' => sub {
    my $event = make_event(
        id         => '5' x 64,
        kind       => 7,
        pubkey     => $pubkey,
        created_at => 5000,
        content    => '+',
        tags       => [
            ['e', $article->id, $relay, $article->pubkey],
            ['p', $article->pubkey, $relay],
            ['k', '30023'],
            ['a', "30023:${other_pubkey}:my-article", $relay, $article->pubkey],
        ],
        sig        => '6' x 128,
    );

    my $info = Net::Nostr::Reaction->from_event($event);
    is $info->event_coordinate, "30023:${other_pubkey}:my-article", 'event_coordinate from a tag';
};

# --- is_like / is_dislike ---

subtest 'is_like for + content' => sub {
    my $info = Net::Nostr::Reaction->new(content => '+');
    ok $info->is_like, '+ is like';
};

subtest 'is_like for empty content' => sub {
    my $info = Net::Nostr::Reaction->new(content => '');
    ok $info->is_like, 'empty is like';
};

subtest 'is_dislike for - content' => sub {
    my $info = Net::Nostr::Reaction->new(content => '-');
    ok $info->is_dislike, '- is dislike';
    ok !$info->is_like, '- is not like';
};

subtest 'emoji is not like or dislike' => sub {
    my $info = Net::Nostr::Reaction->new(content => "\x{1F44D}");
    ok !$info->is_like, 'emoji is not like';
    ok !$info->is_dislike, 'emoji is not dislike';
};

subtest 'custom emoji is not like or dislike' => sub {
    my $info = Net::Nostr::Reaction->new(content => ':soapbox:');
    ok !$info->is_like, 'custom emoji is not like';
    ok !$info->is_dislike, 'custom emoji is not dislike';
};

# --- validate ---

subtest 'validate accepts valid kind 7 reaction' => sub {
    my $event = make_event(
        id         => '7' x 64,
        kind       => 7,
        pubkey     => $pubkey,
        created_at => 6000,
        content    => '+',
        tags       => [['e', $note->id]],
        sig        => '8' x 128,
    );
    ok eval { Net::Nostr::Reaction->validate($event) }, 'valid kind 7';
};

subtest 'validate accepts valid kind 17 reaction' => sub {
    my $event = make_event(
        id         => '9' x 64,
        kind       => 17,
        pubkey     => $pubkey,
        created_at => 7000,
        content    => '+',
        tags       => [['k', 'web'], ['i', 'https://example.com']],
        sig        => 'a' x 128,
    );
    ok eval { Net::Nostr::Reaction->validate($event) }, 'valid kind 17';
};

subtest 'validate rejects non-reaction kind' => sub {
    eval { Net::Nostr::Reaction->validate($note) };
    like $@, qr/kind 7 or 17/, 'rejects kind 1';
};

subtest 'validate rejects kind 7 without e tag' => sub {
    my $event = make_event(
        id         => 'b' x 64,
        kind       => 7,
        pubkey     => $pubkey,
        created_at => 8000,
        content    => '+',
        tags       => [['p', $other_pubkey]],
        sig        => 'c' x 128,
    );
    eval { Net::Nostr::Reaction->validate($event) };
    like $@, qr/e tag/, 'rejects missing e tag';
};

subtest 'validate rejects kind 17 without k and i tags' => sub {
    my $event = make_event(
        id         => 'd' x 64,
        kind       => 17,
        pubkey     => $pubkey,
        created_at => 9000,
        content    => '+',
        tags       => [],
        sig        => 'e' x 128,
    );
    eval { Net::Nostr::Reaction->validate($event) };
    like $@, qr/k.*tag|i.*tag/, 'rejects missing k/i tags';
};

# --- required args ---

subtest 'react requires event' => sub {
    eval { Net::Nostr::Reaction->react(pubkey => $pubkey, relay_url => $relay) };
    like $@, qr/event/, 'croaks without event';
};

subtest 'react requires pubkey' => sub {
    eval { Net::Nostr::Reaction->react(event => $note, relay_url => $relay) };
    like $@, qr/pubkey/, 'croaks without pubkey';
};

subtest 'react requires relay_url' => sub {
    eval { Net::Nostr::Reaction->react(event => $note, pubkey => $pubkey) };
    like $@, qr/relay_url/, 'croaks without relay_url';
};

# --- passthrough ---

subtest 'extra args passed through to Event constructor' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event      => $note,
        pubkey     => $pubkey,
        relay_url  => $relay,
        created_at => 42000,
    );
    is $reaction->created_at, 42000, 'created_at passed through';
};

# --- kind 7 is regular event ---

subtest 'from_event with multiple e tags uses last e tag as target' => sub {
    my $decoy_id = '0' x 64;
    my $event = make_event(
        id         => 'a1' x 32,
        kind       => 7,
        pubkey     => $pubkey,
        created_at => 10000,
        content    => '+',
        tags       => [
            ['e', $decoy_id, 'wss://other.relay'],
            ['e', $note->id, $relay, $note->pubkey],
        ],
        sig        => 'b1' x 64,
    );

    my $info = Net::Nostr::Reaction->from_event($event);
    is $info->event_id, $note->id, 'target event_id is from last e tag';
    is $info->relay_url, $relay, 'relay_url from last e tag';
};

subtest 'from_event with multiple p tags uses last p tag as target' => sub {
    my $decoy_pk = '0' x 64;
    my $event = make_event(
        id         => 'c1' x 32,
        kind       => 7,
        pubkey     => $pubkey,
        created_at => 11000,
        content    => '+',
        tags       => [
            ['e', $note->id, $relay, $note->pubkey],
            ['p', $decoy_pk, 'wss://other.relay'],
            ['p', $note->pubkey, $relay],
        ],
        sig        => 'd1' x 64,
    );

    my $info = Net::Nostr::Reaction->from_event($event);
    is $info->author_pubkey, $note->pubkey, 'target author_pubkey is from last p tag';
};

subtest 'single emoji tag constraint' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
        content   => ':soapbox:',
        emoji     => ['soapbox', 'https://gleasonator.com/emoji/Gleasonator/soapbox.png'],
    );
    my @emoji = grep { $_->[0] eq 'emoji' } @{$reaction->tags};
    is scalar @emoji, 1, 'exactly one emoji tag';
};

subtest 'kind 7 is a regular event' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    ok $reaction->is_regular, 'kind 7 is regular';
    ok !$reaction->is_replaceable, 'kind 7 is not replaceable';
    ok !$reaction->is_ephemeral, 'kind 7 is not ephemeral';
    ok !$reaction->is_addressable, 'kind 7 is not addressable';
};

# --- hex validation ---

subtest 'react validates event has valid hex id and pubkey' => sub {
    # Event.pm now validates id/pubkey at construction, so react's
    # validation is defense-in-depth. Verify by confirming a valid
    # event works and invalid events can't even be constructed.
    my $target = make_event(kind => 1, content => 'test');
    my $reaction = eval {
        Net::Nostr::Reaction->react(
            event => $target, pubkey => $pubkey, relay_url => $relay,
        );
    };
    ok($reaction, 'react accepts valid event');

    eval {
        Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'test',
            id => 'bad',
        );
    };
    like($@, qr/id must be 64-char lowercase hex/, 'cannot construct event with bad id');
};

###############################################################################
# from_event: short/malformed tags are safely skipped
###############################################################################

subtest 'from_event: short tags are skipped' => sub {
    my $event = make_event(
        kind    => 7,
        pubkey  => $pubkey,
        content => '+',
        tags    => [
            ['e'],               # too short
            [],                  # empty
            ['e', 'c' x 64],    # valid but no relay/author hint
            ['p', $other_pubkey],
            ['k'],               # too short
        ],
    );
    my $info = Net::Nostr::Reaction->from_event($event);
    is $info->event_id, 'c' x 64, 'event_id from valid e tag';
    is $info->relay_url, '', 'relay_url empty when e tag has no relay element';
    is $info->author_pubkey, $other_pubkey, 'author_pubkey from p tag';
    is $info->reacted_kind, undef, 'short k tag skipped';
};

subtest 'from_event: e tag with only 2 elements has no author_pubkey from e' => sub {
    my $event = make_event(
        kind    => 7,
        pubkey  => $pubkey,
        content => '+',
        tags    => [
            ['e', 'c' x 64, 'wss://relay.example.com'],  # no [3] pubkey
        ],
    );
    my $info = Net::Nostr::Reaction->from_event($event);
    is $info->event_id, 'c' x 64, 'event_id parsed';
    is $info->relay_url, 'wss://relay.example.com', 'relay_url parsed';
    is $info->author_pubkey, undef, 'no author_pubkey when e tag has only 3 elements';
};

done_testing;
