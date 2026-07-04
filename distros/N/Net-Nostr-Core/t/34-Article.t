#!/usr/bin/perl

# Unit tests for Net::Nostr::Article
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);
use JSON ();

use Net::Nostr::Article;
use Net::Nostr::Event;

my $pubkey = 'aa' x 32;

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: create article (kind 30023)' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey       => $pubkey,
        content      => "# My Article\n\nMarkdown content here.",
        identifier   => 'my-article',
        title        => 'My Article',
        summary      => 'A short summary.',
        image        => 'https://example.com/banner.png',
        published_at => 1296962229,
        hashtags     => ['nostr', 'blog'],
    );
    is($event->kind, 30023, 'kind 30023');
    is($event->content, "# My Article\n\nMarkdown content here.", 'content');
    is($event->pubkey, $pubkey, 'pubkey');
};

subtest 'SYNOPSIS: create draft (kind 30024)' => sub {
    my $draft = Net::Nostr::Article->draft(
        pubkey     => $pubkey,
        content    => "# WIP\n\nNot finished yet.",
        identifier => 'my-draft',
        title      => 'Work in Progress',
    );
    is($draft->kind, 30024, 'kind 30024');
};

subtest 'SYNOPSIS: from_event round-trip' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey       => $pubkey,
        content      => "# My Article\n\nMarkdown content here.",
        identifier   => 'my-article',
        title        => 'My Article',
        summary      => 'A short summary.',
        image        => 'https://example.com/banner.png',
        published_at => 1296962229,
        hashtags     => ['nostr', 'blog'],
    );
    my $info = Net::Nostr::Article->from_event($event);
    is($info->title, 'My Article', 'title');
    is($info->identifier, 'my-article', 'identifier');
    is($info->published_at, '1296962229', 'published_at');
};

subtest 'SYNOPSIS: to_naddr' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'text',
        identifier => 'my-article',
    );
    my $naddr = Net::Nostr::Article->to_naddr($event,
        relays => ['wss://relay.example.com'],
    );
    like($naddr, qr/^naddr1/, 'starts with naddr1');
};

subtest 'SYNOPSIS: validate' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'text',
        identifier => 'my-article',
    );
    ok(Net::Nostr::Article->validate($event), 'valid article');
};

###############################################################################
# new() constructor
###############################################################################

subtest 'new: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::Article->new(identifier => 'x', bogus => 'y') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

subtest 'new: hashtags defaults to []' => sub {
    my $info = Net::Nostr::Article->new(identifier => 'x');
    is($info->hashtags, [], 'defaults to empty arrayref');
};

subtest 'new: POD example' => sub {
    my $info = Net::Nostr::Article->new(
        identifier => 'my-article',
        title      => 'My Article',
        summary    => 'A brief overview.',
        image      => 'https://example.com/cover.jpg',
    );
    is($info->identifier, 'my-article', 'identifier');
    is($info->title, 'My Article', 'title');
    is($info->summary, 'A brief overview.', 'summary');
    is($info->image, 'https://example.com/cover.jpg', 'image');
};

###############################################################################
# article()
###############################################################################

subtest 'article: required args' => sub {
    like(
        dies { Net::Nostr::Article->article(content => 'x', identifier => 'x') },
        qr/requires 'pubkey'/,
        'missing pubkey'
    );
    like(
        dies { Net::Nostr::Article->article(pubkey => $pubkey, identifier => 'x') },
        qr/requires 'content'/,
        'missing content'
    );
    like(
        dies { Net::Nostr::Article->article(pubkey => $pubkey, content => 'x') },
        qr/requires 'identifier'/,
        'missing identifier'
    );
};

subtest 'article: kind is 30023' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'text',
        identifier => 'slug',
    );
    is($event->kind, 30023, 'kind');
};

subtest 'article: d tag from identifier' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'text',
        identifier => 'my-slug',
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is(scalar @d, 1, 'one d tag');
    is($d[0][1], 'my-slug', 'd tag value');
};

subtest 'article: all optional metadata tags' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey       => $pubkey,
        content      => 'text',
        identifier   => 'slug',
        title        => 'Title',
        image        => 'https://example.com/img.png',
        summary      => 'Summary text',
        published_at => 1696000000,
        hashtags     => ['perl', 'nostr'],
        extra_tags   => [['e', 'dd' x 32, 'wss://r.com']],
    );

    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is($title[0][1], 'Title', 'title tag');

    my @image = grep { $_->[0] eq 'image' } @{$event->tags};
    is($image[0][1], 'https://example.com/img.png', 'image tag');

    my @summary = grep { $_->[0] eq 'summary' } @{$event->tags};
    is($summary[0][1], 'Summary text', 'summary tag');

    my @pub = grep { $_->[0] eq 'published_at' } @{$event->tags};
    is($pub[0][1], '1696000000', 'published_at tag');

    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @t, 2, 'two t tags');
    is($t[0][1], 'perl', 'first hashtag');
    is($t[1][1], 'nostr', 'second hashtag');

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0][1], 'dd' x 32, 'extra e tag');
    is($e[0][2], 'wss://r.com', 'extra e tag relay');
};

subtest 'article: published_at is stringified' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey       => $pubkey,
        content      => 'text',
        identifier   => 'slug',
        published_at => 12345,
    );
    my @pub = grep { $_->[0] eq 'published_at' } @{$event->tags};
    is($pub[0][1], '12345', 'stringified');
    ok(!ref($pub[0][1]), 'not a reference, plain string');
};

subtest 'article: minimal (no optional tags)' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'just content',
        identifier => 'minimal',
    );
    is($event->kind, 30023, 'kind');
    is($event->content, 'just content', 'content');
    my @tags = @{$event->tags};
    is(scalar @tags, 1, 'only d tag');
    is($tags[0][0], 'd', 'd tag present');
};

subtest 'article: POD second example' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => 'aa' x 32,
        content    => "# Hello\n\nWorld.",
        identifier => 'hello-world',
        title      => 'Hello',
        hashtags   => ['greeting'],
    );
    is($event->kind, 30023, 'kind');
    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is($title[0][1], 'Hello', 'title');
    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is($t[0][1], 'greeting', 'hashtag');
};

###############################################################################
# draft()
###############################################################################

subtest 'draft: kind is 30024' => sub {
    my $event = Net::Nostr::Article->draft(
        pubkey     => $pubkey,
        content    => 'wip',
        identifier => 'draft-1',
    );
    is($event->kind, 30024, 'kind');
};

subtest 'draft: same structure as article' => sub {
    my $event = Net::Nostr::Article->draft(
        pubkey       => $pubkey,
        content      => 'wip',
        identifier   => 'draft-1',
        title        => 'Draft Title',
        image        => 'https://example.com/draft.jpg',
        summary      => 'Draft summary',
        published_at => 999,
        hashtags     => ['wip'],
    );
    is($event->kind, 30024, 'kind');

    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'draft-1', 'd tag');

    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is($title[0][1], 'Draft Title', 'title');

    my @pub = grep { $_->[0] eq 'published_at' } @{$event->tags};
    is($pub[0][1], '999', 'published_at stringified');
};

subtest 'draft: required args' => sub {
    like(
        dies { Net::Nostr::Article->draft(content => 'x', identifier => 'x') },
        qr/requires 'pubkey'/,
        'missing pubkey'
    );
    like(
        dies { Net::Nostr::Article->draft(pubkey => $pubkey, identifier => 'x') },
        qr/requires 'content'/,
        'missing content'
    );
    like(
        dies { Net::Nostr::Article->draft(pubkey => $pubkey, content => 'x') },
        qr/requires 'identifier'/,
        'missing identifier'
    );
};

###############################################################################
# from_event()
###############################################################################

subtest 'from_event: round-trip from article' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey       => $pubkey,
        content      => 'markdown',
        identifier   => 'rt-test',
        title        => 'RT Title',
        image        => 'https://example.com/rt.png',
        summary      => 'RT summary',
        published_at => 42,
        hashtags     => ['a', 'b'],
    );
    my $info = Net::Nostr::Article->from_event($event);
    is($info->identifier, 'rt-test', 'identifier');
    is($info->title, 'RT Title', 'title');
    is($info->image, 'https://example.com/rt.png', 'image');
    is($info->summary, 'RT summary', 'summary');
    is($info->published_at, '42', 'published_at');
    is($info->hashtags, ['a', 'b'], 'hashtags');
};

subtest 'from_event: round-trip from draft' => sub {
    my $event = Net::Nostr::Article->draft(
        pubkey     => $pubkey,
        content    => 'draft content',
        identifier => 'draft-rt',
        title      => 'Draft RT',
    );
    my $info = Net::Nostr::Article->from_event($event);
    is($info->identifier, 'draft-rt', 'identifier');
    is($info->title, 'Draft RT', 'title');
};

subtest 'from_event: returns undef for wrong kind' => sub {
    my $event = make_event(kind => 1);
    my $result = Net::Nostr::Article->from_event($event);
    is($result, undef, 'undef for kind 1');
};

subtest 'from_event: handles missing optional fields' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'bare',
        identifier => 'bare-article',
    );
    my $info = Net::Nostr::Article->from_event($event);
    is($info->identifier, 'bare-article', 'identifier present');
    is($info->title, undef, 'title undef');
    is($info->image, undef, 'image undef');
    is($info->summary, undef, 'summary undef');
    is($info->published_at, undef, 'published_at undef');
    is($info->hashtags, [], 'hashtags empty');
};

subtest 'from_event: POD accessor examples' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey       => $pubkey,
        content      => 'md',
        identifier   => 'my-article',
        title        => 'My Article',
        hashtags     => ['nostr', 'blog'],
    );
    my $info = Net::Nostr::Article->from_event($event);
    is($info->identifier, 'my-article', 'identifier');
    is($info->title, 'My Article', 'title');
    is($info->hashtags, ['nostr', 'blog'], 'hashtags');
};

###############################################################################
# validate()
###############################################################################

subtest 'validate: rejects wrong kind' => sub {
    my $event = make_event(kind => 1);
    like(
        dies { Net::Nostr::Article->validate($event) },
        qr/MUST be kind 30023 or 30024/,
        'rejects kind 1'
    );
};

subtest 'validate: rejects missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => $pubkey,
        content    => 'text',
        kind       => 30023,
        tags       => [],
        created_at => time(),
    );
    like(
        dies { Net::Nostr::Article->validate($event) },
        qr/MUST include a d tag/,
        'rejects missing d tag'
    );
};

subtest 'validate: accepts valid article' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'ok',
        identifier => 'valid',
    );
    ok(Net::Nostr::Article->validate($event), 'valid article');
};

subtest 'validate: accepts valid draft' => sub {
    my $event = Net::Nostr::Article->draft(
        pubkey     => $pubkey,
        content    => 'ok',
        identifier => 'valid-draft',
    );
    ok(Net::Nostr::Article->validate($event), 'valid draft');
};

subtest 'validate: POD eval example' => sub {
    my $event = make_event(kind => 1);
    eval { Net::Nostr::Article->validate($event) };
    ok($@, 'error set on invalid event');
};

###############################################################################
# to_naddr()
###############################################################################

subtest 'to_naddr: produces naddr1 string' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'text',
        identifier => 'naddr-test',
    );
    my $naddr = Net::Nostr::Article->to_naddr($event);
    like($naddr, qr/^naddr1/, 'starts with naddr1');
};

subtest 'to_naddr: with relays' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'text',
        identifier => 'naddr-relay',
    );
    my $naddr = Net::Nostr::Article->to_naddr($event,
        relays => ['wss://relay.com'],
    );
    like($naddr, qr/^naddr1/, 'starts with naddr1');
};

subtest 'to_naddr: POD example' => sub {
    my $event = Net::Nostr::Article->article(
        pubkey     => $pubkey,
        content    => 'text',
        identifier => 'test',
    );
    my $naddr = Net::Nostr::Article->to_naddr($event);
    like($naddr, qr/^naddr1/, 'naddr1 prefix');
};

done_testing;
