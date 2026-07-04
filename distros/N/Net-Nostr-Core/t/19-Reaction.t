use strictures 2;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use TestFixtures qw(make_event);
use JSON ();

use Net::Nostr::Reaction;

my $pubkey = 'a' x 64;
my $other_pubkey = 'b' x 64;
my $relay = 'wss://relay.example.com';

my $note = make_event(
    id         => 'c' x 64,
    kind       => 1,
    pubkey     => $other_pubkey,
    created_at => 1000,
    content    => 'hello',
    tags       => [],
    sig        => 'd' x 128,
);

# --- SYNOPSIS examples ---

subtest 'POD SYNOPSIS: like a note (default +)' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
    );
    is $reaction->kind, 7, 'kind 7';
    is $reaction->content, '+', 'default content +';
};

subtest 'POD SYNOPSIS: dislike' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
        content   => '-',
    );
    is $reaction->content, '-', 'content is -';
};

subtest 'POD SYNOPSIS: emoji reaction' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
        content   => "\x{1F44D}",
    );
    is $reaction->content, "\x{1F44D}", 'emoji content';
};

subtest 'POD SYNOPSIS: custom emoji reaction (NIP-30)' => sub {
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $pubkey,
        relay_url => $relay,
        content   => ':soapbox:',
        emoji     => ['soapbox', 'https://gleasonator.com/emoji/Gleasonator/soapbox.png'],
    );
    is $reaction->content, ':soapbox:', 'custom emoji content';
    my @emoji = grep { $_->[0] eq 'emoji' } @{$reaction->tags};
    is $emoji[0], ['emoji', 'soapbox', 'https://gleasonator.com/emoji/Gleasonator/soapbox.png'], 'emoji tag';
};

subtest 'POD SYNOPSIS: react_external' => sub {
    my $reaction = Net::Nostr::Reaction->react_external(
        pubkey  => $pubkey,
        content => "\x{2B50}",
        tags    => [
            ['k', 'web'],
            ['i', 'https://example.com'],
        ],
    );
    is $reaction->kind, 17, 'kind 17';
    is $reaction->content, "\x{2B50}", 'star content';
};

subtest 'POD SYNOPSIS: from_event with is_like' => sub {
    my $event = make_event(
        id         => '1' x 64,
        kind       => 7,
        pubkey     => $pubkey,
        created_at => 3000,
        content    => '+',
        tags       => [['e', $note->id, $relay, $note->pubkey], ['p', $note->pubkey, $relay]],
        sig        => '2' x 128,
    );

    my $info = Net::Nostr::Reaction->from_event($event);
    if ($info) {
        my $result = $info->is_like ? "Liked" : $info->content;
        is $result, "Liked", 'is_like returns Liked';
    } else {
        fail 'from_event should return an object';
    }
};

subtest 'POD SYNOPSIS: validate' => sub {
    my $event = make_event(
        id         => '3' x 64,
        kind       => 7,
        pubkey     => $pubkey,
        created_at => 4000,
        content    => '+',
        tags       => [['e', $note->id]],
        sig        => '4' x 128,
    );
    ok eval { Net::Nostr::Reaction->validate($event) }, 'validate succeeds';
};

# --- react() method POD ---

subtest 'POD react: croaks without event' => sub {
    eval { Net::Nostr::Reaction->react(pubkey => $pubkey, relay_url => $relay) };
    like $@, qr/event/, 'croaks';
};

subtest 'POD react: croaks without pubkey' => sub {
    eval { Net::Nostr::Reaction->react(event => $note, relay_url => $relay) };
    like $@, qr/pubkey/, 'croaks';
};

subtest 'POD react: croaks without relay_url' => sub {
    eval { Net::Nostr::Reaction->react(event => $note, pubkey => $pubkey) };
    like $@, qr/relay_url/, 'croaks';
};

# --- react_external() POD ---

subtest 'POD react_external: croaks without pubkey' => sub {
    eval { Net::Nostr::Reaction->react_external(content => '+', tags => [['k', 'web']]) };
    like $@, qr/pubkey/, 'croaks';
};

subtest 'POD react_external: croaks without content' => sub {
    eval { Net::Nostr::Reaction->react_external(pubkey => $pubkey, tags => [['k', 'web']]) };
    like $@, qr/content/, 'croaks';
};

subtest 'POD react_external: croaks without tags' => sub {
    eval { Net::Nostr::Reaction->react_external(pubkey => $pubkey, content => '+') };
    like $@, qr/tags/, 'croaks';
};

# --- validate() POD ---

subtest 'POD validate: eval pattern' => sub {
    eval { Net::Nostr::Reaction->validate($note) };
    ok $@, 'Invalid reaction sets $@';
    like $@, qr/kind 7 or 17/, 'error message';
};

# --- is_like / is_dislike POD ---

subtest 'POD is_like: true for +' => sub {
    my $info = Net::Nostr::Reaction->new(content => '+');
    ok $info->is_like, '+ is like';
};

subtest 'POD is_dislike: true for -' => sub {
    my $info = Net::Nostr::Reaction->new(content => '-');
    ok $info->is_dislike, '- is dislike';
};

# --- Accessor POD examples ---

subtest 'POD accessor: event_id' => sub {
    my $info = Net::Nostr::Reaction->new(event_id => 'abc123');
    is $info->event_id, 'abc123', 'event_id';
};

subtest 'POD accessor: relay_url' => sub {
    my $info = Net::Nostr::Reaction->new(relay_url => $relay);
    is $info->relay_url, $relay, 'relay_url';
};

subtest 'POD accessor: author_pubkey' => sub {
    my $info = Net::Nostr::Reaction->new(author_pubkey => $other_pubkey);
    is $info->author_pubkey, $other_pubkey, 'author_pubkey';
};

subtest 'POD accessor: content' => sub {
    my $info = Net::Nostr::Reaction->new(content => '+');
    is $info->content, '+', 'content';
};

subtest 'POD accessor: reacted_kind' => sub {
    my $info = Net::Nostr::Reaction->new(reacted_kind => '1');
    is $info->reacted_kind, '1', 'reacted_kind';
};

subtest 'POD accessor: event_coordinate' => sub {
    my $info = Net::Nostr::Reaction->new(event_coordinate => "30023:${other_pubkey}:my-article");
    is $info->event_coordinate, "30023:${other_pubkey}:my-article", 'event_coordinate';
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $info = Net::Nostr::Reaction->new(
        event_id => 'aa' x 32,
        content  => '+',
    );
    is $info->event_id, 'aa' x 32;
    is $info->content, '+';
};

subtest 'new() rejects unknown arguments' => sub {
    eval { Net::Nostr::Reaction->new(event_id => 'aa' x 32, bogus => 'value') };
    like($@, qr/unknown.+bogus/i, 'unknown argument rejected');
};

done_testing;
