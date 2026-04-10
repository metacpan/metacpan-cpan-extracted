#!/usr/bin/perl

# NIP-23: Long-form Content
# https://github.com/nostr-protocol/nips/blob/master/23.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Event;
use Net::Nostr::Article;

my $PUBKEY  = 'aa' x 32;
my $PUBKEY2 = 'bb' x 32;

###############################################################################
# "kind:30023 (an addressable event) for long-form text content"
# "kind:30024 has the same structure as kind:30023 and is used to save
#  long form drafts"
###############################################################################

subtest 'article: creates kind 30023 event' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $PUBKEY,
        content    => "# Hello\n\nThis is an article.",
        identifier => 'hello-world',
    );
    is($event->kind, 30023, 'kind is 30023');
    ok($event->is_addressable, 'article is addressable');
    is($event->d_tag, 'hello-world', 'd tag matches identifier');
};

subtest 'draft: creates kind 30024 event' => sub {
    my $event = Net::Nostr::Article->draft(
        pubkey     => $PUBKEY,
        content    => "# WIP\n\nNot ready yet.",
        identifier => 'my-draft',
    );
    is($event->kind, 30024, 'kind is 30024');
    ok($event->is_addressable, 'draft is addressable');
    is($event->d_tag, 'my-draft', 'd tag matches identifier');
};

subtest 'article requires pubkey, content, identifier' => sub {
    like(dies { Net::Nostr::Article->article(content => 'x', identifier => 'y') },
        qr/pubkey/, 'missing pubkey');
    like(dies { Net::Nostr::Article->article(pubkey => $PUBKEY, identifier => 'y') },
        qr/content/, 'missing content');
    like(dies { Net::Nostr::Article->article(pubkey => $PUBKEY, content => 'x') },
        qr/identifier/, 'missing identifier');
};

###############################################################################
# "Metadata fields can be added as tags"
# "title", "image", "summary", "published_at"
###############################################################################

subtest 'metadata tags: title, image, summary, published_at' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey       => $PUBKEY,
        content      => 'Article body.',
        identifier   => 'test-meta',
        title        => 'My Article',
        image        => 'https://example.com/img.png',
        summary      => 'A short summary.',
        published_at => 1296962229,
    );

    my %tags;
    for my $tag (@{$event->tags}) {
        $tags{$tag->[0]} = $tag->[1];
    }

    is($tags{title}, 'My Article', 'title tag');
    is($tags{image}, 'https://example.com/img.png', 'image tag');
    is($tags{summary}, 'A short summary.', 'summary tag');
    is($tags{published_at}, '1296962229', 'published_at tag (stringified)');
};

subtest 'metadata tags are optional' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $PUBKEY,
        content    => 'Minimal.',
        identifier => 'minimal',
    );

    my @tag_names = map { $_->[0] } @{$event->tags};
    ok(!grep({ $_ eq 'title' } @tag_names), 'no title tag when not set');
    ok(!grep({ $_ eq 'image' } @tag_names), 'no image tag when not set');
    ok(!grep({ $_ eq 'summary' } @tag_names), 'no summary tag when not set');
    ok(!grep({ $_ eq 'published_at' } @tag_names), 'no published_at when not set');
};

###############################################################################
# "for tags/hashtags ... the t tag should be used"
###############################################################################

subtest 'hashtags via t tags' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $PUBKEY,
        content    => 'Article about nostr.',
        identifier => 'nostr-article',
        hashtags   => ['nostr', 'protocol'],
    );

    my @t_tags = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @t_tags, 2, 'two t tags');
    is($t_tags[0][1], 'nostr', 'first hashtag');
    is($t_tags[1][1], 'protocol', 'second hashtag');
};

###############################################################################
# "they should include a d tag with an identifier for the article"
###############################################################################

subtest 'd tag is always present' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $PUBKEY,
        content    => 'Test.',
        identifier => 'my-id',
    );
    is($event->d_tag, 'my-id', 'd tag is set');

    my @d_tags = grep { $_->[0] eq 'd' } @{$event->tags};
    is(scalar @d_tags, 1, 'exactly one d tag');
};

subtest 'empty identifier is allowed (replaceable events)' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $PUBKEY,
        content    => 'Test.',
        identifier => '',
    );
    is($event->d_tag, '', 'd tag is empty string');
};

###############################################################################
# "For the date of the last update the .created_at field should be used"
###############################################################################

subtest 'created_at can be set for last update' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $PUBKEY,
        content    => 'Updated content.',
        identifier => 'updated',
        created_at => 1675642635,
    );
    is($event->created_at, 1675642635, 'created_at passed through');
};

###############################################################################
# Spec example event
# kind 30023, content with nostr: references, tags: d, title, published_at,
# t, e, a
###############################################################################

subtest 'spec example event' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey       => $PUBKEY,
        content      => "Lorem [ipsum][nostr:nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9] dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nRead more at nostr:naddr1qqzkjurnw4ksz9thwden5te0wfjkccte9ehx7um5wghx7un8qgs2d90kkcq3nk2jry62dyf50k0h36rhpdtd594my40w9pkal876jxgrqsqqqa28pccpzu.",
        identifier   => 'lorem-ipsum',
        title        => 'Lorem Ipsum',
        published_at => 1296962229,
        hashtags     => ['placeholder'],
        extra_tags   => [
            ['e', 'b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87', 'wss://relay.example.com'],
            ['a', "30023:a695f6b60119d9521934a691347d9f78e8770b56da16bb255ee286ddf9fda919:ipsum", 'wss://relay.nostr.org'],
        ],
        created_at => 1675642635,
    );

    is($event->kind, 30023, 'kind 30023');
    is($event->d_tag, 'lorem-ipsum', 'd tag');
    is($event->created_at, 1675642635, 'created_at');

    my %first_tag;
    for my $tag (@{$event->tags}) {
        $first_tag{$tag->[0]} //= $tag->[1];
    }
    is($first_tag{title}, 'Lorem Ipsum', 'title tag');
    is($first_tag{published_at}, '1296962229', 'published_at tag');
    is($first_tag{t}, 'placeholder', 't tag');
    is($first_tag{e}, 'b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87', 'e tag');
    is($first_tag{a}, '30023:a695f6b60119d9521934a691347d9f78e8770b56da16bb255ee286ddf9fda919:ipsum', 'a tag');

    # Verify content contains nostr: references
    like($event->content, qr/nostr:nevent1/, 'content has nevent reference');
    like($event->content, qr/nostr:naddr1/, 'content has naddr reference');
};

###############################################################################
# from_event: parse article metadata from an event
###############################################################################

subtest 'from_event: parses kind 30023' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => $PUBKEY,
        kind       => 30023,
        content    => '# Test Article',
        created_at => 1675642635,
        tags       => [
            ['d', 'test-id'],
            ['title', 'Test Title'],
            ['image', 'https://example.com/img.png'],
            ['summary', 'A test summary.'],
            ['published_at', '1296962229'],
            ['t', 'nostr'],
            ['t', 'test'],
        ],
    );

    my $info = Net::Nostr::Article->from_event($event);
    ok(defined $info, 'parsed successfully');
    is($info->identifier, 'test-id', 'identifier');
    is($info->title, 'Test Title', 'title');
    is($info->image, 'https://example.com/img.png', 'image');
    is($info->summary, 'A test summary.', 'summary');
    is($info->published_at, '1296962229', 'published_at');
    is($info->hashtags, ['nostr', 'test'], 'hashtags');
};

subtest 'from_event: parses kind 30024 drafts' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => $PUBKEY,
        kind       => 30024,
        content    => '# Draft',
        created_at => 1000,
        tags       => [['d', 'draft-1']],
    );

    my $info = Net::Nostr::Article->from_event($event);
    ok(defined $info, 'draft parsed');
    is($info->identifier, 'draft-1', 'identifier');
};

subtest 'from_event: returns undef for non-article kinds' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'note', created_at => 1000,
        tags => [],
    );
    is(Net::Nostr::Article->from_event($event), undef, 'kind 1 returns undef');
};

subtest 'from_event: handles missing optional metadata' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30023, content => 'Minimal.',
        created_at => 1000, tags => [['d', 'min']],
    );

    my $info = Net::Nostr::Article->from_event($event);
    is($info->identifier, 'min', 'identifier');
    is($info->title, undef, 'title is undef');
    is($info->image, undef, 'image is undef');
    is($info->summary, undef, 'summary is undef');
    is($info->published_at, undef, 'published_at is undef');
    is($info->hashtags, [], 'hashtags is empty array');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid article' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30023, content => 'Test.',
        created_at => 1000, tags => [['d', 'test']],
    );
    ok(Net::Nostr::Article->validate($event), 'valid article passes');
};

subtest 'validate: valid draft' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30024, content => 'Draft.',
        created_at => 1000, tags => [['d', 'draft']],
    );
    ok(Net::Nostr::Article->validate($event), 'valid draft passes');
};

subtest 'validate: wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'note',
        created_at => 1000, tags => [['d', 'x']],
    );
    like(dies { Net::Nostr::Article->validate($event) }, qr/30023|30024/, 'wrong kind rejected');
};

subtest 'validate: missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30023, content => 'Test.',
        created_at => 1000, tags => [],
    );
    like(dies { Net::Nostr::Article->validate($event) }, qr/d tag/, 'missing d tag rejected');
};

###############################################################################
# "The article may be linked to using the NIP-19 naddr code"
###############################################################################

subtest 'to_naddr: generates naddr for article' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30023, content => 'Test.',
        created_at => 1000, tags => [['d', 'my-article']],
    );

    my $naddr = Net::Nostr::Article->to_naddr($event);
    like($naddr, qr/^naddr1/, 'starts with naddr1');

    require Net::Nostr::Bech32;
    my $decoded = Net::Nostr::Bech32::decode_naddr($naddr);
    is($decoded->{identifier}, 'my-article', 'identifier in naddr');
    is($decoded->{pubkey}, $PUBKEY, 'pubkey in naddr');
    is($decoded->{kind}, 30023, 'kind in naddr');
};

subtest 'to_naddr: with relay hints' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30023, content => 'Test.',
        created_at => 1000, tags => [['d', 'test']],
    );

    my $naddr = Net::Nostr::Article->to_naddr($event, relays => ['wss://relay.com']);

    require Net::Nostr::Bech32;
    my $decoded = Net::Nostr::Bech32::decode_naddr($naddr);
    is($decoded->{relays}, ['wss://relay.com'], 'relay hint encoded');
};

###############################################################################
# "Replies to kind 30023 MUST use NIP-22 kind 1111 comments"
###############################################################################

subtest 'replies use NIP-22 comments' => sub {
    require Net::Nostr::Comment;

    my $article = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30023, content => 'Article.',
        created_at => 1000, tags => [['d', 'article-1']],
    );

    my $comment = Net::Nostr::Comment->comment(
        event     => $article,
        pubkey    => $PUBKEY2,
        content   => 'Great article!',
        relay_url => 'wss://relay.example.com',
    );

    is($comment->kind, 1111, 'reply is kind 1111');

    # Should have A tag with article coordinate (addressable event)
    my @a_tags = grep { $_->[0] eq 'A' } @{$comment->tags};
    ok(scalar @a_tags, 'has A tag for addressable root');
    like($a_tags[0][1], qr/^30023:/, 'A tag has article coordinate');
};

###############################################################################
# "kind:30024 has the same structure as kind:30023"
###############################################################################

subtest 'draft has same structure as article' => sub {
    my $draft = Net::Nostr::Article->draft(
        pubkey       => $PUBKEY,
        content      => '# Draft Article',
        identifier   => 'my-draft',
        title        => 'Draft Title',
        summary      => 'Draft summary.',
        hashtags     => ['draft'],
        published_at => 1296962229,
    );

    is($draft->kind, 30024, 'kind is 30024');
    is($draft->d_tag, 'my-draft', 'd tag');

    my %tags;
    for my $tag (@{$draft->tags}) {
        push @{$tags{$tag->[0]}}, $tag->[1];
    }
    is($tags{title}[0], 'Draft Title', 'title tag on draft');
    is($tags{summary}[0], 'Draft summary.', 'summary tag on draft');
    is($tags{t}[0], 'draft', 't tag on draft');
    is($tags{published_at}[0], '1296962229', 'published_at on draft');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'content is preserved as-is (markdown)' => sub {
    my $md = "# Title\n\nParagraph one.\n\nParagraph two with **bold**.";
    my $event = Net::Nostr::Article->article(
        pubkey     => $PUBKEY,
        content    => $md,
        identifier => 'md-test',
    );
    is($event->content, $md, 'markdown content preserved exactly');
};

subtest 'extra_tags are appended' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $PUBKEY,
        content    => 'Test.',
        identifier => 'extra',
        extra_tags => [
            ['e', 'ff' x 32, 'wss://relay.com'],
            ['p', $PUBKEY2],
        ],
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @e_tags, 1, 'e tag from extra_tags');
    is(scalar @p_tags, 1, 'p tag from extra_tags');
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $info = Net::Nostr::Article->new(
        identifier => 'my-article',
        title      => 'My Article',
        summary    => 'A brief overview.',
        image      => 'https://example.com/cover.jpg',
    );
    is $info->identifier, 'my-article';
    is $info->title, 'My Article';
    is $info->summary, 'A brief overview.';
    is $info->image, 'https://example.com/cover.jpg';
    is $info->hashtags, [];
};

subtest 'Article->new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Article->new(bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# from_event: short/malformed tags are safely skipped
###############################################################################

subtest 'from_event: short tags are skipped' => sub {
    my $event = Net::Nostr::Event->new(
        kind    => 30023,
        pubkey  => $PUBKEY,
        content => 'content',
        tags    => [
            ['d', 'my-article'],
            ['title'],           # too short, skipped
            [],                  # empty, skipped
            ['t', 'nostr'],
            ['summary'],         # too short, skipped
        ],
    );
    my $info = Net::Nostr::Article->from_event($event);
    is $info->identifier, 'my-article', 'identifier parsed';
    is $info->title, undef, 'short title tag skipped';
    is $info->summary, undef, 'short summary tag skipped';
    is $info->hashtags, ['nostr'], 'valid t tag parsed';
};

done_testing;
