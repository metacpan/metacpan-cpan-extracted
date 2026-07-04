#!/usr/bin/perl

# NIP-22: Comment
# https://github.com/nostr-protocol/nips/blob/master/22.md

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Comment;

my $alice_pk = 'a' x 64;
my $bob_pk   = 'b' x 64;
my $carol_pk = 'c' x 64;

my $event_id_1 = '1' x 64;
my $event_id_2 = '2' x 64;

###############################################################################
# "It uses kind:1111 with plaintext .content"
###############################################################################

subtest 'comment creates kind 1111 event with plaintext content' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event   => $target,
        pubkey  => $bob_pk,
        content => 'Great file!',
    );
    is $comment->kind, 1111, 'kind is 1111';
    is $comment->content, 'Great file!', 'plaintext content preserved';
    is $comment->pubkey, $bob_pk, 'pubkey set';
};

###############################################################################
# "Comments MUST point to the root scope using uppercase tag names (E, A, I)"
# "Comments MUST point to the parent item with lowercase ones (e, a, i)"
###############################################################################

subtest 'comment on regular event: E/e tags for root and parent' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event     => $target,
        pubkey    => $bob_pk,
        content   => 'Great file!',
        relay_url => 'wss://example.relay',
    );

    my @E_tags = grep { $_->[0] eq 'E' } @{$comment->tags};
    is scalar @E_tags, 1, 'one E tag for root';
    is $E_tags[0][1], $event_id_1, 'E tag has event id';
    is $E_tags[0][2], 'wss://example.relay', 'E tag has relay hint';
    is $E_tags[0][3], $alice_pk, 'E tag has root author pubkey';

    my @e_tags = grep { $_->[0] eq 'e' } @{$comment->tags};
    is scalar @e_tags, 1, 'one e tag for parent';
    is $e_tags[0][1], $event_id_1, 'e tag same as root for top-level';
    is $e_tags[0][2], 'wss://example.relay', 'e tag has relay hint';
    is $e_tags[0][3], $alice_pk, 'e tag has parent author pubkey';
};

subtest 'comment on addressable event: A/a tags plus e tag' => sub {
    my $blog_post = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 30023,
        content => '', tags => [['d', 'my-article']],
    );
    my $comment = Net::Nostr::Comment->comment(
        event     => $blog_post,
        pubkey    => $bob_pk,
        content   => 'Great blog post!',
        relay_url => 'wss://example.relay',
    );

    my $coord = "30023:${alice_pk}:my-article";

    my @A_tags = grep { $_->[0] eq 'A' } @{$comment->tags};
    is scalar @A_tags, 1, 'one A tag for root';
    is $A_tags[0][1], $coord, 'A tag has event coordinate';
    is $A_tags[0][2], 'wss://example.relay', 'A tag has relay hint';

    my @a_tags = grep { $_->[0] eq 'a' } @{$comment->tags};
    is scalar @a_tags, 1, 'one a tag for parent';
    is $a_tags[0][1], $coord, 'a tag same as root for top-level';

    # "when the parent event is replaceable or addressable, also include an e tag"
    my @e_tags = grep { $_->[0] eq 'e' } @{$comment->tags};
    is scalar @e_tags, 1, 'e tag included for addressable event';
    is $e_tags[0][1], $event_id_1, 'e tag has event id';
    is $e_tags[0][2], 'wss://example.relay', 'e tag has relay hint';
};

subtest 'comment on replaceable event includes e tag' => sub {
    my $replaceable = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 10002, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event     => $replaceable,
        pubkey    => $bob_pk,
        content   => 'Nice list!',
        relay_url => 'wss://r.com',
    );

    # Replaceable events use E/e tags (not A/a)
    my @E_tags = grep { $_->[0] eq 'E' } @{$comment->tags};
    is scalar @E_tags, 1, 'E tag for root';

    # Also include e tag since it's replaceable
    my @e_tags = grep { $_->[0] eq 'e' } @{$comment->tags};
    is scalar @e_tags, 1, 'e tag included for replaceable event';
    is $e_tags[0][1], $event_id_1, 'e tag has event id';
};

subtest 'comment on external identifier: I/i tags' => sub {
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'https://abc.com/articles/1',
        kind       => 'web',
        pubkey     => $bob_pk,
        content    => 'Nice article!',
    );

    is $comment->kind, 1111, 'kind is 1111';

    my @I_tags = grep { $_->[0] eq 'I' } @{$comment->tags};
    is scalar @I_tags, 1, 'one I tag';
    is $I_tags[0][1], 'https://abc.com/articles/1', 'I tag value';

    my @i_tags = grep { $_->[0] eq 'i' } @{$comment->tags};
    is scalar @i_tags, 1, 'one i tag';
    is $i_tags[0][1], 'https://abc.com/articles/1', 'i tag same for top-level';
};

subtest 'external identifier with hint' => sub {
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'podcast:item:guid:abc-123',
        kind       => 'podcast:item:guid',
        pubkey     => $bob_pk,
        content    => 'Great episode!',
        hint       => 'https://fountain.fm/episode/abc',
    );

    my @I_tags = grep { $_->[0] eq 'I' } @{$comment->tags};
    is $I_tags[0][2], 'https://fountain.fm/episode/abc', 'I tag has hint';

    my @i_tags = grep { $_->[0] eq 'i' } @{$comment->tags};
    is $i_tags[0][2], 'https://fountain.fm/episode/abc', 'i tag has hint';
};

###############################################################################
# "Tags K and k MUST be present to define the event kind"
###############################################################################

subtest 'K and k tags for event comment' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event => $target, pubkey => $bob_pk, content => 'Great!',
    );

    my @K_tags = grep { $_->[0] eq 'K' } @{$comment->tags};
    is scalar @K_tags, 1, 'one K tag';
    is $K_tags[0][1], '1063', 'K tag has root kind as string';

    my @k_tags = grep { $_->[0] eq 'k' } @{$comment->tags};
    is scalar @k_tags, 1, 'one k tag';
    is $k_tags[0][1], '1063', 'k tag same as root for top-level';
};

subtest 'K and k tags for external identifier' => sub {
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'https://example.com', kind => 'web',
        pubkey => $bob_pk, content => 'Nice!',
    );

    my @K_tags = grep { $_->[0] eq 'K' } @{$comment->tags};
    is $K_tags[0][1], 'web', 'K tag is "web"';

    my @k_tags = grep { $_->[0] eq 'k' } @{$comment->tags};
    is $k_tags[0][1], 'web', 'k tag is "web"';
};

###############################################################################
# "Comments MUST point to the authors when one is available"
# "P for the root scope and p for the author of the parent item"
###############################################################################

subtest 'P and p tags for nostr event comment' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event     => $target,
        pubkey    => $bob_pk,
        content   => 'Great!',
        relay_url => 'wss://r.com',
    );

    my @P_tags = grep { $_->[0] eq 'P' } @{$comment->tags};
    is scalar @P_tags, 1, 'one P tag';
    is $P_tags[0][1], $alice_pk, 'P tag has root author pubkey';
    is $P_tags[0][2], 'wss://r.com', 'P tag has relay hint';

    my @p_tags = grep { $_->[0] eq 'p' } @{$comment->tags};
    is scalar @p_tags, 1, 'one p tag';
    is $p_tags[0][1], $alice_pk, 'p tag has parent author (same for top-level)';
    is $p_tags[0][2], 'wss://r.com', 'p tag has relay hint';
};

subtest 'no P or p tags for external identifier comment' => sub {
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'https://example.com', kind => 'web',
        pubkey => $bob_pk, content => 'Nice!',
    );

    my @P_tags = grep { $_->[0] eq 'P' } @{$comment->tags};
    is scalar @P_tags, 0, 'no P tag for external identifier';

    my @p_tags = grep { $_->[0] eq 'p' } @{$comment->tags};
    is scalar @p_tags, 0, 'no p tag for external identifier';
};

###############################################################################
# Reply to comments
###############################################################################

subtest 'reply preserves root scope, sets parent to comment' => sub {
    my $parent_comment = make_event(
        id => $event_id_2, pubkey => $bob_pk, kind => 1111,
        content => 'Great file!',
        tags => [
            ['E', $event_id_1, 'wss://r.com', $alice_pk],
            ['K', '1063'],
            ['P', $alice_pk],
            ['e', $event_id_1, 'wss://r.com', $alice_pk],
            ['k', '1063'],
            ['p', $alice_pk],
        ],
    );

    my $reply = Net::Nostr::Comment->reply(
        to        => $parent_comment,
        pubkey    => $carol_pk,
        content   => 'I agree!',
        relay_url => 'wss://r.com',
    );

    is $reply->kind, 1111, 'reply is kind 1111';

    # Root scope preserved
    my @E_tags = grep { $_->[0] eq 'E' } @{$reply->tags};
    is $E_tags[0][1], $event_id_1, 'E tag preserved from parent';
    is $E_tags[0][3], $alice_pk, 'E tag pubkey preserved';

    my @K_tags = grep { $_->[0] eq 'K' } @{$reply->tags};
    is $K_tags[0][1], '1063', 'K tag preserved';

    my @P_tags = grep { $_->[0] eq 'P' } @{$reply->tags};
    is $P_tags[0][1], $alice_pk, 'P tag preserved';

    # Parent points to the comment
    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is $e_tags[0][1], $event_id_2, 'e tag points to parent comment';
    is $e_tags[0][3], $bob_pk, 'e tag has parent comment author pubkey';

    my @k_tags = grep { $_->[0] eq 'k' } @{$reply->tags};
    is $k_tags[0][1], '1111', 'k tag is 1111 (parent is a comment)';

    my @p_tags = grep { $_->[0] eq 'p' } @{$reply->tags};
    is $p_tags[0][1], $bob_pk, 'p tag is parent comment author';
    is $p_tags[0][2], 'wss://r.com', 'p tag has relay hint';
};

subtest 'reply to external identifier comment' => sub {
    my $podcast_comment = make_event(
        id => $event_id_2, pubkey => $bob_pk, kind => 1111,
        content => 'Great episode!',
        tags => [
            ['I', 'podcast:item:guid:abc-123', 'https://fountain.fm/ep/1'],
            ['K', 'podcast:item:guid'],
            ['i', 'podcast:item:guid:abc-123', 'https://fountain.fm/ep/1'],
            ['k', 'podcast:item:guid'],
        ],
    );

    my $reply = Net::Nostr::Comment->reply(
        to        => $podcast_comment,
        pubkey    => $carol_pk,
        content   => 'I agree!',
        relay_url => 'wss://r.com',
    );

    # Root scope preserved (I tag)
    my @I_tags = grep { $_->[0] eq 'I' } @{$reply->tags};
    is $I_tags[0][1], 'podcast:item:guid:abc-123', 'I tag preserved';

    my @K_tags = grep { $_->[0] eq 'K' } @{$reply->tags};
    is $K_tags[0][1], 'podcast:item:guid', 'K tag preserved';

    # No P tag (external identifier has no nostr author)
    my @P_tags = grep { $_->[0] eq 'P' } @{$reply->tags};
    is scalar @P_tags, 0, 'no P tag for external root';

    # Parent points to the comment (e tag)
    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is $e_tags[0][1], $event_id_2, 'e tag points to comment';

    my @k_tags = grep { $_->[0] eq 'k' } @{$reply->tags};
    is $k_tags[0][1], '1111', 'k tag is 1111';

    my @p_tags = grep { $_->[0] eq 'p' } @{$reply->tags};
    is $p_tags[0][1], $bob_pk, 'p tag is comment author';
};

subtest 'reply to A-rooted comment' => sub {
    my $parent_comment = make_event(
        id => $event_id_2, pubkey => $bob_pk, kind => 1111,
        content => 'Great post!',
        tags => [
            ['A', "30023:${alice_pk}:slug", 'wss://r.com'],
            ['K', '30023'],
            ['P', $alice_pk],
            ['a', "30023:${alice_pk}:slug", 'wss://r.com'],
            ['e', $event_id_1, 'wss://r.com'],
            ['k', '30023'],
            ['p', $alice_pk],
        ],
    );

    my $reply = Net::Nostr::Comment->reply(
        to        => $parent_comment,
        pubkey    => $carol_pk,
        content   => 'Agreed!',
        relay_url => 'wss://r.com',
    );

    my @A_tags = grep { $_->[0] eq 'A' } @{$reply->tags};
    is $A_tags[0][1], "30023:${alice_pk}:slug", 'A tag preserved';

    my @K_tags = grep { $_->[0] eq 'K' } @{$reply->tags};
    is $K_tags[0][1], '30023', 'K tag preserved';

    my @P_tags = grep { $_->[0] eq 'P' } @{$reply->tags};
    is $P_tags[0][1], $alice_pk, 'P tag preserved';

    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is $e_tags[0][1], $event_id_2, 'e tag points to parent comment';

    my @k_tags = grep { $_->[0] eq 'k' } @{$reply->tags};
    is $k_tags[0][1], '1111', 'k tag is 1111';
};

###############################################################################
# "q tags MAY be used when citing events in the .content with NIP-21"
###############################################################################

subtest 'q tags supported via quotes parameter' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $cited_id = '3' x 64;
    my $comment = Net::Nostr::Comment->comment(
        event   => $target,
        pubkey  => $bob_pk,
        content => 'Check this nostr:nevent1...',
        quotes  => [{ id => $cited_id, relay_url => 'wss://r.com', pubkey => $carol_pk }],
    );

    my @q_tags = grep { $_->[0] eq 'q' } @{$comment->tags};
    is scalar @q_tags, 1, 'q tag present';
    is $q_tags[0][1], $cited_id, 'q tag event id';
    is $q_tags[0][2], 'wss://r.com', 'q tag relay';
    is $q_tags[0][3], $carol_pk, 'q tag pubkey';
};

subtest 'q tags default to none (opt-in)' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event => $target, pubkey => $bob_pk, content => 'No quotes',
    );

    my @q_tags = grep { $_->[0] eq 'q' } @{$comment->tags};
    is scalar @q_tags, 0, 'no q tags by default';
};

subtest 'q tags supported on reply' => sub {
    my $parent = make_event(
        id => $event_id_2, pubkey => $bob_pk, kind => 1111,
        content => 'x', tags => [
            ['E', $event_id_1, '', $alice_pk], ['K', '1063'],
            ['P', $alice_pk],
            ['e', $event_id_1, '', $alice_pk], ['k', '1063'],
            ['p', $alice_pk],
        ],
    );
    my $cited_id = '3' x 64;
    my $reply = Net::Nostr::Comment->reply(
        to      => $parent,
        pubkey  => $carol_pk,
        content => 'See nostr:nevent1...',
        quotes  => [{ id => $cited_id, relay_url => 'wss://r.com', pubkey => $alice_pk }],
    );

    my @q_tags = grep { $_->[0] eq 'q' } @{$reply->tags};
    is scalar @q_tags, 1, 'q tag on reply';
    is $q_tags[0][1], $cited_id, 'q tag event id';
    is $q_tags[0][2], 'wss://r.com', 'q tag relay';
    is $q_tags[0][3], $alice_pk, 'q tag pubkey';
};

###############################################################################
# "p tags SHOULD be used when mentioning pubkeys in the .content with NIP-21"
###############################################################################

subtest 'mentions parameter adds additional p tags' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event    => $target,
        pubkey   => $bob_pk,
        content  => 'Hey nostr:npub1... check this',
        mentions => [$carol_pk],
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$comment->tags};
    # Should have parent author p tag + mention p tag
    ok scalar @p_tags >= 2, 'at least 2 p tags';
    ok((grep { $_->[1] eq $carol_pk } @p_tags), 'mentioned pubkey in p tags');
    ok((grep { $_->[1] eq $alice_pk } @p_tags), 'parent author still in p tags');
};

subtest 'mentions default to none' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event => $target, pubkey => $bob_pk, content => 'No mentions',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$comment->tags};
    is scalar @p_tags, 1, 'only parent author p tag';
};

subtest 'mentions supported on reply' => sub {
    my $parent = make_event(
        id => $event_id_2, pubkey => $bob_pk, kind => 1111,
        content => 'x', tags => [
            ['E', $event_id_1, '', $alice_pk], ['K', '1063'],
            ['P', $alice_pk],
            ['e', $event_id_1, '', $alice_pk], ['k', '1063'],
            ['p', $alice_pk],
        ],
    );
    my $reply = Net::Nostr::Comment->reply(
        to       => $parent,
        pubkey   => $carol_pk,
        content  => 'Hey nostr:npub1...',
        mentions => [$alice_pk],
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$reply->tags};
    ok scalar @p_tags >= 2, 'at least 2 p tags on reply';
    ok((grep { $_->[1] eq $alice_pk } @p_tags), 'mentioned pubkey in p tags');
    ok((grep { $_->[1] eq $bob_pk } @p_tags), 'parent comment author still in p tags');
};

###############################################################################
# "Comments MUST NOT be used to reply to kind 1 notes"
###############################################################################

subtest 'comment rejects kind 1 events' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1, content => 'hello',
    );

    like dies { Net::Nostr::Comment->comment(
        event => $note, pubkey => $bob_pk, content => 'reply',
    ) }, qr/kind 1/i, 'croaks on kind 1 event';
};

###############################################################################
# Validation
###############################################################################

subtest 'validate accepts valid E-rooted comment' => sub {
    my $valid = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'Great!',
        tags => [
            ['E', $event_id_1, '', $alice_pk],
            ['K', '1063'],
            ['P', $alice_pk],
            ['e', $event_id_1, '', $alice_pk],
            ['k', '1063'],
            ['p', $alice_pk],
        ],
    );
    ok lives { Net::Nostr::Comment->validate($valid) }, 'valid comment passes';
};

subtest 'validate accepts valid A-rooted comment' => sub {
    my $valid = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'Great!',
        tags => [
            ['A', "30023:${alice_pk}:slug", 'wss://r.com'],
            ['K', '30023'],
            ['P', $alice_pk],
            ['a', "30023:${alice_pk}:slug", 'wss://r.com'],
            ['k', '30023'],
            ['p', $alice_pk],
        ],
    );
    ok lives { Net::Nostr::Comment->validate($valid) }, 'A-rooted comment passes';
};

subtest 'validate accepts valid I-rooted comment' => sub {
    my $valid = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'Nice!',
        tags => [
            ['I', 'https://example.com'],
            ['K', 'web'],
            ['i', 'https://example.com'],
            ['k', 'web'],
        ],
    );
    ok lives { Net::Nostr::Comment->validate($valid) }, 'I-rooted comment passes';
};

subtest 'validate rejects non-1111 kind' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 1, content => 'hello',
        tags => [
            ['E', $event_id_1, '', $alice_pk],
            ['K', '1'],
            ['e', $event_id_1, '', $alice_pk],
            ['k', '1'],
        ],
    );
    like dies { Net::Nostr::Comment->validate($bad) }, qr/1111/, 'rejects non-1111';
};

subtest 'validate rejects missing K tag' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'hello',
        tags => [
            ['E', $event_id_1, '', $alice_pk],
            ['e', $event_id_1, '', $alice_pk],
            ['k', '1063'],
        ],
    );
    like dies { Net::Nostr::Comment->validate($bad) }, qr/K/i, 'rejects missing K';
};

subtest 'validate rejects missing k tag' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'hello',
        tags => [
            ['E', $event_id_1, '', $alice_pk],
            ['K', '1063'],
            ['e', $event_id_1, '', $alice_pk],
        ],
    );
    like dies { Net::Nostr::Comment->validate($bad) }, qr/k/i, 'rejects missing k';
};

subtest 'validate rejects missing root scope tag (E/A/I)' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'hello',
        tags => [
            ['K', '1063'],
            ['e', $event_id_1, '', $alice_pk],
            ['k', '1063'],
        ],
    );
    like dies { Net::Nostr::Comment->validate($bad) }, qr/root/i, 'rejects missing root';
};

subtest 'validate rejects missing parent scope tag (e/a/i)' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'hello',
        tags => [
            ['E', $event_id_1, '', $alice_pk],
            ['K', '1063'],
            ['k', '1063'],
        ],
    );
    like dies { Net::Nostr::Comment->validate($bad) }, qr/parent/i, 'rejects missing parent';
};

###############################################################################
# from_event
###############################################################################

subtest 'from_event parses E-rooted comment' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'Great!',
        tags => [
            ['E', $event_id_1, 'wss://r.com', $alice_pk],
            ['K', '1063'],
            ['P', $alice_pk, 'wss://r.com'],
            ['e', $event_id_1, 'wss://r.com', $alice_pk],
            ['k', '1063'],
            ['p', $alice_pk, 'wss://r.com'],
        ],
    );

    my $info = Net::Nostr::Comment->from_event($event);
    ok defined $info, 'parsed successfully';
    is $info->root_tag_name, 'E', 'root tag name';
    is $info->root_value, $event_id_1, 'root value';
    is $info->root_relay, 'wss://r.com', 'root relay';
    is $info->root_kind, '1063', 'root kind';
    is $info->root_pubkey, $alice_pk, 'root pubkey from P tag';
    is $info->parent_tag_name, 'e', 'parent tag name';
    is $info->parent_value, $event_id_1, 'parent value';
    is $info->parent_relay, 'wss://r.com', 'parent relay';
    is $info->parent_kind, '1063', 'parent kind';
    is $info->parent_pubkey, $alice_pk, 'parent pubkey from p tag';
};

subtest 'from_event parses A-rooted comment' => sub {
    my $coord = "30023:${alice_pk}:slug";
    my $event = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'Great!',
        tags => [
            ['A', $coord, 'wss://r.com'],
            ['K', '30023'],
            ['P', $alice_pk],
            ['a', $coord, 'wss://r.com'],
            ['k', '30023'],
            ['p', $alice_pk],
        ],
    );

    my $info = Net::Nostr::Comment->from_event($event);
    is $info->root_tag_name, 'A', 'root tag name';
    is $info->root_value, $coord, 'root value is coordinate';
    is $info->root_kind, '30023', 'root kind';
};

subtest 'from_event parses I-rooted comment' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'Nice!',
        tags => [
            ['I', 'https://example.com'],
            ['K', 'web'],
            ['i', 'https://example.com'],
            ['k', 'web'],
        ],
    );

    my $info = Net::Nostr::Comment->from_event($event);
    is $info->root_tag_name, 'I', 'root tag name';
    is $info->root_value, 'https://example.com', 'root value';
    is $info->root_kind, 'web', 'root kind';
    is $info->root_pubkey, undef, 'no root pubkey for external';
    is $info->parent_tag_name, 'i', 'parent tag name';
    is $info->parent_pubkey, undef, 'no parent pubkey for external';
};

subtest 'from_event returns undef for non-comment' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'hello', tags => [],
    );
    my $info = Net::Nostr::Comment->from_event($event);
    is $info, undef, 'undef for non-1111 event';
};

###############################################################################
# Spec examples as test vectors
###############################################################################

subtest 'Spec example 1: comment on blog post' => sub {
    my $blog_pk = '3c9849383bdea883b0bd16fece1ed36d37e37cdde3ce43b17ea4e9192ec11289';
    my $blog_id = '5b4fc7fed15672fefe65d2426f67197b71ccc82aa0cc8a9e94f683eb78e07651';
    my $coord   = "30023:${blog_pk}:f9347ca7";

    my $blog = make_event(
        id => $blog_id, pubkey => $blog_pk, kind => 30023,
        content => '', tags => [['d', 'f9347ca7']],
    );

    my $comment = Net::Nostr::Comment->comment(
        event     => $blog,
        pubkey    => $bob_pk,
        content   => 'Great blog post!',
        relay_url => 'wss://example.relay',
    );

    is $comment->kind, 1111, 'kind 1111';
    is $comment->content, 'Great blog post!', 'content';

    my @A = grep { $_->[0] eq 'A' } @{$comment->tags};
    is $A[0][1], $coord, 'A tag: coordinate';
    is $A[0][2], 'wss://example.relay', 'A tag: relay';

    my @K = grep { $_->[0] eq 'K' } @{$comment->tags};
    is $K[0][1], '30023', 'K tag';

    my @P = grep { $_->[0] eq 'P' } @{$comment->tags};
    is $P[0][1], $blog_pk, 'P tag: root author';

    my @a = grep { $_->[0] eq 'a' } @{$comment->tags};
    is $a[0][1], $coord, 'a tag: coordinate';

    my @e = grep { $_->[0] eq 'e' } @{$comment->tags};
    is $e[0][1], $blog_id, 'e tag: addressable event id';
    is $e[0][2], 'wss://example.relay', 'e tag: relay';

    my @k = grep { $_->[0] eq 'k' } @{$comment->tags};
    is $k[0][1], '30023', 'k tag';

    my @p = grep { $_->[0] eq 'p' } @{$comment->tags};
    is $p[0][1], $blog_pk, 'p tag: parent author';
};

subtest 'Spec example 2: comment on NIP-94 file' => sub {
    my $file_pk = '3721e07b079525289877c366ccab47112bdff3d1b44758ca333feb2dbbbbe5bb';
    my $file_id = '768ac8720cdeb59227cf95e98b66560ef03d8bc9a90d721779e76e68fb42f5e6';

    my $file_event = make_event(
        id => $file_id, pubkey => $file_pk, kind => 1063, content => '',
    );

    my $comment = Net::Nostr::Comment->comment(
        event     => $file_event,
        pubkey    => $bob_pk,
        content   => 'Great file!',
        relay_url => 'wss://example.relay',
    );

    my @E = grep { $_->[0] eq 'E' } @{$comment->tags};
    is $E[0][1], $file_id, 'E tag: event id';
    is $E[0][2], 'wss://example.relay', 'E tag: relay';
    is $E[0][3], $file_pk, 'E tag: author pubkey';

    my @K = grep { $_->[0] eq 'K' } @{$comment->tags};
    is $K[0][1], '1063', 'K tag';

    my @P = grep { $_->[0] eq 'P' } @{$comment->tags};
    is $P[0][1], $file_pk, 'P tag';

    my @e = grep { $_->[0] eq 'e' } @{$comment->tags};
    is $e[0][1], $file_id, 'e tag: same as root for top-level';
    is $e[0][3], $file_pk, 'e tag: pubkey';

    my @k = grep { $_->[0] eq 'k' } @{$comment->tags};
    is $k[0][1], '1063', 'k tag';

    my @p = grep { $_->[0] eq 'p' } @{$comment->tags};
    is $p[0][1], $file_pk, 'p tag';
};

subtest 'Spec example 3: reply to a comment (validate structure)' => sub {
    # Spec shows a reply where root is a NIP-94 file event
    my $root_pk    = 'fd913cd6fa9edb8405750cd02a8bbe16e158b8676c0e69fdc27436cc4a54cc9a';
    my $root_id    = '768ac8720cdeb59227cf95e98b66560ef03d8bc9a90d721779e76e68fb42f5e6';
    my $comment_pk = '93ef2ebaaf9554661f33e79949007900bbc535d239a4c801c33a4d67d3e7f546';
    my $comment_id = '5c83da77af1dec6d7289834998ad7aafbd9e2191396d75ec3cc27f5a77226f36';

    # Feed the spec example directly to validate
    my $reply = make_event(
        pubkey => $carol_pk, kind => 1111,
        content => 'This is a reply to "Great file!"',
        tags => [
            ['E', $root_id, 'wss://example.relay', $root_pk],
            ['K', '1063'],
            ['P', $root_pk],
            ['e', $comment_id, 'wss://example.relay', $comment_pk],
            ['k', '1111'],
            ['p', $comment_pk],
        ],
    );
    ok lives { Net::Nostr::Comment->validate($reply) }, 'spec example 3 validates';

    my $info = Net::Nostr::Comment->from_event($reply);
    is $info->root_kind, '1063', 'root kind is file event';
    is $info->parent_kind, '1111', 'parent kind is comment';
    is $info->parent_pubkey, $comment_pk, 'parent is comment author';
};

subtest 'Spec example 3: reply via API' => sub {
    my $root_pk    = 'fd913cd6fa9edb8405750cd02a8bbe16e158b8676c0e69fdc27436cc4a54cc9a';
    my $root_id    = '768ac8720cdeb59227cf95e98b66560ef03d8bc9a90d721779e76e68fb42f5e6';
    my $comment_pk = '93ef2ebaaf9554661f33e79949007900bbc535d239a4c801c33a4d67d3e7f546';
    my $comment_id = '5c83da77af1dec6d7289834998ad7aafbd9e2191396d75ec3cc27f5a77226f36';

    my $parent_comment = make_event(
        id => $comment_id, pubkey => $comment_pk, kind => 1111,
        content => 'Great file!',
        tags => [
            ['E', $root_id, 'wss://example.relay', $root_pk],
            ['K', '1063'],
            ['P', $root_pk],
            ['e', $root_id, 'wss://example.relay', $root_pk],
            ['k', '1063'],
            ['p', $root_pk],
        ],
    );

    my $reply = Net::Nostr::Comment->reply(
        to        => $parent_comment,
        pubkey    => $carol_pk,
        content   => 'This is a reply to "Great file!"',
        relay_url => 'wss://example.relay',
    );

    my @E = grep { $_->[0] eq 'E' } @{$reply->tags};
    is $E[0][1], $root_id, 'E tag preserved: root event id';
    is $E[0][3], $root_pk, 'E tag preserved: root pubkey';

    my @K = grep { $_->[0] eq 'K' } @{$reply->tags};
    is $K[0][1], '1063', 'K tag preserved';

    my @P = grep { $_->[0] eq 'P' } @{$reply->tags};
    is $P[0][1], $root_pk, 'P tag preserved';

    my @e = grep { $_->[0] eq 'e' } @{$reply->tags};
    is $e[0][1], $comment_id, 'e tag points to parent comment';
    is $e[0][3], $comment_pk, 'e tag has comment author pubkey';

    my @k = grep { $_->[0] eq 'k' } @{$reply->tags};
    is $k[0][1], '1111', 'k tag is 1111';

    my @p = grep { $_->[0] eq 'p' } @{$reply->tags};
    is $p[0][1], $comment_pk, 'p tag is comment author';
};

subtest 'Spec example 4: comment on URL' => sub {
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'https://abc.com/articles/1',
        kind       => 'web',
        pubkey     => $bob_pk,
        content    => 'Nice article!',
    );

    my @I = grep { $_->[0] eq 'I' } @{$comment->tags};
    is $I[0][1], 'https://abc.com/articles/1', 'I tag';

    my @K = grep { $_->[0] eq 'K' } @{$comment->tags};
    is $K[0][1], 'web', 'K tag';

    my @i = grep { $_->[0] eq 'i' } @{$comment->tags};
    is $i[0][1], 'https://abc.com/articles/1', 'i tag';

    my @k = grep { $_->[0] eq 'k' } @{$comment->tags};
    is $k[0][1], 'web', 'k tag';

    # No P/p for external
    is scalar(grep { $_->[0] eq 'P' } @{$comment->tags}), 0, 'no P tag';
    is scalar(grep { $_->[0] eq 'p' } @{$comment->tags}), 0, 'no p tag';
};

subtest 'Spec example 5: podcast comment' => sub {
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'podcast:item:guid:d98d189b-dc7b-45b1-8720-d4b98690f31f',
        kind       => 'podcast:item:guid',
        pubkey     => '252f10c83610ebca1a059c0bae8255eba2f95be4d1d7bcfa89d7248a82d9f111',
        content    => 'This was a great episode!',
        hint       => 'https://fountain.fm/episode/z1y9TMQRuqXl2awyrQxg',
    );

    my @I = grep { $_->[0] eq 'I' } @{$comment->tags};
    is $I[0][1], 'podcast:item:guid:d98d189b-dc7b-45b1-8720-d4b98690f31f', 'I tag';
    is $I[0][2], 'https://fountain.fm/episode/z1y9TMQRuqXl2awyrQxg', 'I tag hint';

    my @K = grep { $_->[0] eq 'K' } @{$comment->tags};
    is $K[0][1], 'podcast:item:guid', 'K tag';

    my @i = grep { $_->[0] eq 'i' } @{$comment->tags};
    is $i[0][1], 'podcast:item:guid:d98d189b-dc7b-45b1-8720-d4b98690f31f', 'i tag';
    is $i[0][2], 'https://fountain.fm/episode/z1y9TMQRuqXl2awyrQxg', 'i tag hint';

    my @k = grep { $_->[0] eq 'k' } @{$comment->tags};
    is $k[0][1], 'podcast:item:guid', 'k tag';
};

subtest 'Spec example 6: reply to podcast comment' => sub {
    my $podcast_pk = '252f10c83610ebca1a059c0bae8255eba2f95be4d1d7bcfa89d7248a82d9f111';
    my $podcast_comment_id = '80c48d992a38f9c445b943a9c9f1010b396676013443765750431a9004bdac05';

    my $podcast_comment = make_event(
        id => $podcast_comment_id, pubkey => $podcast_pk, kind => 1111,
        content => 'This was a great episode!',
        tags => [
            ['I', 'podcast:item:guid:d98d189b-dc7b-45b1-8720-d4b98690f31f', 'https://fountain.fm/episode/z1y9TMQRuqXl2awyrQxg'],
            ['K', 'podcast:item:guid'],
            ['i', 'podcast:item:guid:d98d189b-dc7b-45b1-8720-d4b98690f31f', 'https://fountain.fm/episode/z1y9TMQRuqXl2awyrQxg'],
            ['k', 'podcast:item:guid'],
        ],
    );

    my $reply = Net::Nostr::Comment->reply(
        to        => $podcast_comment,
        pubkey    => $carol_pk,
        content   => "I'm replying to the above comment.",
        relay_url => 'wss://example.relay',
    );

    # Root preserved
    my @I = grep { $_->[0] eq 'I' } @{$reply->tags};
    is $I[0][1], 'podcast:item:guid:d98d189b-dc7b-45b1-8720-d4b98690f31f', 'I tag preserved';

    my @K = grep { $_->[0] eq 'K' } @{$reply->tags};
    is $K[0][1], 'podcast:item:guid', 'K tag preserved';

    # Parent is the comment
    my @e = grep { $_->[0] eq 'e' } @{$reply->tags};
    is $e[0][1], $podcast_comment_id, 'e tag: comment id';
    is $e[0][3], $podcast_pk, 'e tag: comment author pubkey';

    my @k = grep { $_->[0] eq 'k' } @{$reply->tags};
    is $k[0][1], '1111', 'k tag: 1111';

    my @p = grep { $_->[0] eq 'p' } @{$reply->tags};
    is $p[0][1], $podcast_pk, 'p tag: comment author';
};

###############################################################################
# Edge cases
###############################################################################

subtest 'relay_url defaults to empty string' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event => $target, pubkey => $bob_pk, content => 'Nice!',
    );

    my @E = grep { $_->[0] eq 'E' } @{$comment->tags};
    is $E[0][2], '', 'E tag relay defaults to empty string';
};

subtest 'comment requires event or identifier' => sub {
    like dies { Net::Nostr::Comment->comment(
        pubkey => $bob_pk, content => 'hello',
    ) }, qr/event.*identifier/i, 'croaks without event or identifier';
};

subtest 'comment on identifier requires kind' => sub {
    like dies { Net::Nostr::Comment->comment(
        identifier => 'https://example.com',
        pubkey     => $bob_pk,
        content    => 'hello',
    ) }, qr/kind/i, 'croaks without kind for identifier';
};

subtest 'comment requires pubkey' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    like dies { Net::Nostr::Comment->comment(
        event => $target, content => 'hello',
    ) }, qr/pubkey/i, 'croaks without pubkey';
};

subtest 'comment requires content' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    like dies { Net::Nostr::Comment->comment(
        event => $target, pubkey => $bob_pk,
    ) }, qr/content/i, 'croaks without content';
};

subtest 'reply requires to' => sub {
    like dies { Net::Nostr::Comment->reply(
        pubkey => $bob_pk, content => 'hello',
    ) }, qr/to/i, 'croaks without to';
};

subtest 'reply requires pubkey' => sub {
    my $parent = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1111,
        content => 'x', tags => [['E', $event_id_2, ''], ['K', '1'], ['e', $event_id_2, ''], ['k', '1']],
    );
    like dies { Net::Nostr::Comment->reply(
        to => $parent, content => 'hello',
    ) }, qr/pubkey/i, 'croaks without pubkey';
};

subtest 'reply requires content' => sub {
    my $parent = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1111,
        content => 'x', tags => [['E', $event_id_2, ''], ['K', '1'], ['e', $event_id_2, ''], ['k', '1']],
    );
    like dies { Net::Nostr::Comment->reply(
        to => $parent, pubkey => $bob_pk,
    ) }, qr/content/i, 'croaks without content';
};

subtest 'extra args passed through to Event constructor' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event      => $target,
        pubkey     => $bob_pk,
        content    => 'Nice!',
        created_at => 1700000000,
    );
    is $comment->created_at, 1700000000, 'created_at passed through';
};

subtest 'comment rejects invalid mention pubkey' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    like(
        dies { Net::Nostr::Comment->comment(
            event    => $target,
            pubkey   => $bob_pk,
            content  => 'test',
            mentions => ['bad-pubkey'],
        ) },
        qr/mention pubkey must be 64-char lowercase hex/,
        'invalid mention pubkey rejected'
    );
};

subtest 'comment rejects invalid quote id' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    like(
        dies { Net::Nostr::Comment->comment(
            event   => $target,
            pubkey  => $bob_pk,
            content => 'test',
            quotes  => [{ id => 'not-hex' }],
        ) },
        qr/quote id must be 64-char lowercase hex/,
        'invalid quote id rejected'
    );
};

subtest 'comment rejects invalid quote pubkey' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    like(
        dies { Net::Nostr::Comment->comment(
            event   => $target,
            pubkey  => $bob_pk,
            content => 'test',
            quotes  => [{ id => $event_id_1, pubkey => 'bad' }],
        ) },
        qr/quote pubkey must be 64-char lowercase hex/,
        'invalid quote pubkey rejected'
    );
};

subtest 'comment rejects invalid pubkey' => sub {
    my $target = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1063, content => '',
    );
    like(
        dies { Net::Nostr::Comment->comment(
            event   => $target,
            pubkey  => 'bad-pubkey',
            content => 'test',
        ) },
        qr/pubkey must be 64-char lowercase hex/,
        'invalid pubkey rejected'
    );
};

subtest 'reply rejects invalid pubkey' => sub {
    my $parent = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1111, content => 'hi',
        tags => [['E', $event_id_1, '', $alice_pk], ['K', '1063'], ['e', $event_id_1]],
    );
    like(
        dies { Net::Nostr::Comment->reply(
            to      => $parent,
            pubkey  => 'bad-pubkey',
            content => 'test',
        ) },
        qr/pubkey must be 64-char lowercase hex/,
        'reply rejects invalid pubkey'
    );
};

done_testing;
