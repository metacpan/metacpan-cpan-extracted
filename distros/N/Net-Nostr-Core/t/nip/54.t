#!/usr/bin/perl

# NIP-54: Wiki
# https://github.com/nostr-protocol/nips/blob/master/54.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Event;
use Net::Nostr::Wiki;

my $PK  = 'a' x 64;
my $PK2 = 'b' x 64;
my $EID = 'e' x 64;

###############################################################################
# "kind:30818 (an addressable event) for descriptions of particular subjects"
###############################################################################

subtest 'article: creates kind 30818 event' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'wiki',
        content    => 'A wiki is a hypertext publication collaboratively edited.',
    );
    is($event->kind, 30818, 'kind is 30818');
    ok($event->is_addressable, 'article is addressable');
    is($event->d_tag, 'wiki', 'd tag matches identifier');
    is($event->content, 'A wiki is a hypertext publication collaboratively edited.');
};

###############################################################################
# Spec example: article
# "Articles are identified by lowercase, normalized d tags."
###############################################################################

subtest 'article: spec example' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'wiki',
        title      => 'Wiki',
        content    => 'A wiki is a hypertext publication collaboratively edited and managed by its own audience.',
    );
    is($event->kind, 30818, 'kind');
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'wiki', 'd tag');
    my @t = grep { $_->[0] eq 'title' } @{$event->tags};
    is($t[0][1], 'Wiki', 'title tag');
    is($event->content, 'A wiki is a hypertext publication collaboratively edited and managed by its own audience.');
};

subtest 'article: requires pubkey, identifier, content' => sub {
    like(dies { Net::Nostr::Wiki->article(identifier => 'x', content => 'x') },
        qr/pubkey/, 'missing pubkey');
    like(dies { Net::Nostr::Wiki->article(pubkey => $PK, content => 'x') },
        qr/identifier/, 'missing identifier');
    like(dies { Net::Nostr::Wiki->article(pubkey => $PK, identifier => 'x') },
        qr/content/, 'missing content');
};

###############################################################################
# d tag normalization rules
###############################################################################

subtest 'normalize_dtag: lowercase' => sub {
    is(Net::Nostr::Wiki->normalize_dtag('Wiki'), 'wiki');
    is(Net::Nostr::Wiki->normalize_dtag('HELLO'), 'hello');
};

subtest 'normalize_dtag: whitespace to dash' => sub {
    is(Net::Nostr::Wiki->normalize_dtag('Wiki Article'), 'wiki-article');
    is(Net::Nostr::Wiki->normalize_dtag("tab\there"), 'tab-here');
};

subtest 'normalize_dtag: punctuation removed' => sub {
    is(Net::Nostr::Wiki->normalize_dtag("What's Up?"), 'whats-up');
};

subtest 'normalize_dtag: consecutive dashes collapsed' => sub {
    is(Net::Nostr::Wiki->normalize_dtag('a--b'), 'a-b');
    is(Net::Nostr::Wiki->normalize_dtag('a---b'), 'a-b');
};

subtest 'normalize_dtag: leading/trailing dashes removed' => sub {
    is(Net::Nostr::Wiki->normalize_dtag('-hello-'), 'hello');
    is(Net::Nostr::Wiki->normalize_dtag('  Hello  World  '), 'hello-world');
};

subtest 'normalize_dtag: non-ASCII preserved' => sub {
    is(Net::Nostr::Wiki->normalize_dtag("\x{30A6}\x{30A3}\x{30AD}\x{30DA}\x{30C7}\x{30A3}\x{30A2}"),
       "\x{30A6}\x{30A3}\x{30AD}\x{30DA}\x{30C7}\x{30A3}\x{30A2}", 'Japanese preserved');
};

subtest 'normalize_dtag: non-ASCII lowercased' => sub {
    is(Net::Nostr::Wiki->normalize_dtag("\x{D1}o\x{F1}o"), "\x{F1}o\x{F1}o", 'Spanish lowercased');
    is(Net::Nostr::Wiki->normalize_dtag("\x{41C}\x{43E}\x{441}\x{43A}\x{432}\x{430}"),
       "\x{43C}\x{43E}\x{441}\x{43A}\x{432}\x{430}", 'Russian lowercased');
};

subtest 'normalize_dtag: numbers preserved' => sub {
    is(Net::Nostr::Wiki->normalize_dtag('Article 1'), 'article-1');
};

subtest 'normalize_dtag: spec examples' => sub {
    is(Net::Nostr::Wiki->normalize_dtag('Wiki Article'), 'wiki-article');
    is(Net::Nostr::Wiki->normalize_dtag("What's Up?"), 'whats-up');
    is(Net::Nostr::Wiki->normalize_dtag('  Hello  World  '), 'hello-world');
    is(Net::Nostr::Wiki->normalize_dtag('Article 1'), 'article-1');
    is(Net::Nostr::Wiki->normalize_dtag("\x{30A6}\x{30A3}\x{30AD}\x{30DA}\x{30C7}\x{30A3}\x{30A2}"),
       "\x{30A6}\x{30A3}\x{30AD}\x{30DA}\x{30C7}\x{30A3}\x{30A2}", 'Japanese');
    is(Net::Nostr::Wiki->normalize_dtag("\x{D1}o\x{F1}o"), "\x{F1}o\x{F1}o", 'Spanish');
    is(Net::Nostr::Wiki->normalize_dtag("\x{41C}\x{43E}\x{441}\x{43A}\x{432}\x{430}"),
       "\x{43C}\x{43E}\x{441}\x{43A}\x{432}\x{430}", 'Russian');
    is(Net::Nostr::Wiki->normalize_dtag("\x{65E5}\x{672C}\x{8A9E} Article"),
       "\x{65E5}\x{672C}\x{8A9E}-article", 'mixed scripts');
};

###############################################################################
# "Articles are identified by lowercase, normalized d tags."
# Builder should auto-normalize the d tag
###############################################################################

subtest 'article: d tag is auto-normalized' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'Wiki Article',
        content    => 'Content.',
    );
    is($event->d_tag, 'wiki-article', 'd tag is normalized');
};

###############################################################################
# Optional extra tags: title, summary
###############################################################################

subtest 'article: optional title tag' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'wiki',
        content    => 'Content.',
        title      => 'Wiki',
    );
    my @t = grep { $_->[0] eq 'title' } @{$event->tags};
    is(scalar @t, 1, 'one title tag');
    is($t[0][1], 'Wiki');
};

subtest 'article: optional summary tag' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'wiki',
        content    => 'Content.',
        summary    => 'A summary.',
    );
    my @t = grep { $_->[0] eq 'summary' } @{$event->tags};
    is(scalar @t, 1, 'one summary tag');
    is($t[0][1], 'A summary.');
};

###############################################################################
# "a and e: for referencing the original event a wiki article was forked from"
###############################################################################

subtest 'article: fork tags' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'bitcoin-copy',
        content    => 'Forked content.',
        fork_a     => ["30818:${PK2}:bitcoin", 'wss://relay.com'],
        fork_e     => [$EID, 'wss://relay.com'],
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a, 1, 'one a tag');
    is($a[0][1], "30818:${PK2}:bitcoin");
    is($a[0][2], 'wss://relay.com');
    is($a[0][3], 'fork', 'a tag has fork marker');

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e, 1, 'one e tag');
    is($e[0][1], $EID);
    is($e[0][2], 'wss://relay.com');
    is($e[0][3], 'fork', 'e tag has fork marker');
};

###############################################################################
# "Wiki-events can tag other wiki-events with a defer marker"
###############################################################################

subtest 'article: defer tags' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'bitcoin',
        content    => 'Content.',
        defer_a    => ["30818:${PK2}:bitcoin", 'wss://relay.com'],
        defer_e    => [$EID, 'wss://relay.com'],
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][3], 'defer', 'a tag has defer marker');

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0][3], 'defer', 'e tag has defer marker');
};

###############################################################################
# "both a and e tags SHOULD be used" for fork/defer
###############################################################################

subtest 'article: fork with only a tag' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'x',
        content    => 'Content.',
        fork_a     => ["30818:${PK2}:x", 'wss://relay.com'],
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a, 1, 'a tag present');
    is($a[0][3], 'fork');
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e, 0, 'no e tag');
};

subtest 'article: defer with only a tag' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'x',
        content    => 'Content.',
        defer_a    => ["30818:${PK2}:x", 'wss://relay.com'],
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][3], 'defer');
};

###############################################################################
# Merge Requests: kind 818
# "Event kind:818 represents a request to merge from a forked article
#  into the source."
###############################################################################

subtest 'merge_request: creates kind 818 event' => sub {
    my $source_id = 'f' x 64;
    my $event = Net::Nostr::Wiki->merge_request(
        pubkey      => $PK,
        target      => "30818:${PK2}:bitcoin",
        target_relay => 'wss://relay.com',
        source      => $source_id,
        source_relay => 'wss://relay.com',
        destination => $PK2,
        content     => 'I added information about the block size limit',
    );
    is($event->kind, 818, 'kind is 818');
    ok(!$event->is_addressable, 'not addressable');
};

subtest 'merge_request: spec example' => sub {
    my $version_id = 'd' x 64;
    my $source_id  = 'f' x 64;
    my $event = Net::Nostr::Wiki->merge_request(
        pubkey       => $PK,
        target       => "30818:${PK2}:bitcoin",
        target_relay => 'wss://relay.com',
        base_version => $version_id,
        base_relay   => 'wss://relay.com',
        source       => $source_id,
        source_relay => 'wss://relay.com',
        destination  => $PK2,
        content      => 'I added information about the block size limit',
    );
    is($event->kind, 818);

    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a, 1, 'one a tag');
    is($a[0][1], "30818:${PK2}:bitcoin");
    is($a[0][2], 'wss://relay.com');

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e, 2, 'two e tags');
    # base version e tag (no marker)
    is($e[0][1], $version_id, 'base version id');
    is($e[0][2], 'wss://relay.com', 'base version relay');
    # source e tag with "source" marker
    is($e[1][1], $source_id, 'source id');
    is($e[1][2], 'wss://relay.com', 'source relay');
    is($e[1][3], 'source', 'source marker');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 1, 'one p tag');
    is($p[0][1], $PK2, 'destination pubkey');

    is($event->content, 'I added information about the block size limit');
};

subtest 'merge_request: requires target, source, destination' => sub {
    my $sid = 'f' x 64;
    like(dies { Net::Nostr::Wiki->merge_request(
        pubkey => $PK, source => $sid, destination => $PK2,
        source_relay => 'wss://r.com',
    ) }, qr/target/, 'missing target');
    like(dies { Net::Nostr::Wiki->merge_request(
        pubkey => $PK, target => "30818:${PK2}:x", destination => $PK2,
    ) }, qr/source/, 'missing source');
    like(dies { Net::Nostr::Wiki->merge_request(
        pubkey => $PK, target => "30818:${PK2}:x", source => $sid,
        source_relay => 'wss://r.com',
    ) }, qr/destination/, 'missing destination');
};

subtest 'merge_request: base_version is optional' => sub {
    my $source_id = 'f' x 64;
    my $event = Net::Nostr::Wiki->merge_request(
        pubkey       => $PK,
        target       => "30818:${PK2}:bitcoin",
        source       => $source_id,
        source_relay => 'wss://relay.com',
        destination  => $PK2,
    );
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e, 1, 'only source e tag');
    is($e[0][3], 'source');
};

subtest 'merge_request: content defaults to empty' => sub {
    my $source_id = 'f' x 64;
    my $event = Net::Nostr::Wiki->merge_request(
        pubkey       => $PK,
        target       => "30818:${PK2}:bitcoin",
        source       => $source_id,
        source_relay => 'wss://relay.com',
        destination  => $PK2,
    );
    is($event->content, '');
};

###############################################################################
# Redirects: kind 30819
# "kind:30819 is also defined to stand for 'wiki redirects'"
###############################################################################

subtest 'redirect: creates kind 30819 event' => sub {
    my $event = Net::Nostr::Wiki->redirect(
        pubkey     => $PK,
        identifier => 'btc',
        target     => "30818:${PK2}:bitcoin",
    );
    is($event->kind, 30819, 'kind is 30819');
    ok($event->is_addressable, 'redirect is addressable');
};

subtest 'redirect: spec example' => sub {
    my $event = Net::Nostr::Wiki->redirect(
        pubkey       => $PK,
        identifier   => 'btc',
        target       => "30818:${PK2}:bitcoin",
        target_relay => 'wss://relay.com',
    );
    is($event->kind, 30819);
    is($event->d_tag, 'btc');

    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a, 1, 'one a tag');
    is($a[0][1], "30818:${PK2}:bitcoin");
    is($a[0][2], 'wss://relay.com');

    is($event->content, '', 'content is empty');
};

subtest 'redirect: d tag is auto-normalized' => sub {
    my $event = Net::Nostr::Wiki->redirect(
        pubkey     => $PK,
        identifier => 'BTC Coin',
        target     => "30818:${PK2}:bitcoin",
    );
    is($event->d_tag, 'btc-coin', 'd tag normalized');
};

subtest 'redirect: requires pubkey, identifier, target' => sub {
    like(dies { Net::Nostr::Wiki->redirect(identifier => 'x', target => 'y') },
        qr/pubkey/, 'missing pubkey');
    like(dies { Net::Nostr::Wiki->redirect(pubkey => $PK, target => 'y') },
        qr/identifier/, 'missing identifier');
    like(dies { Net::Nostr::Wiki->redirect(pubkey => $PK, identifier => 'x') },
        qr/target/, 'missing target');
};

###############################################################################
# from_event: parse all three kinds
###############################################################################

subtest 'from_event: wiki article' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'bitcoin',
        title      => 'Bitcoin',
        summary    => 'A cryptocurrency.',
        content    => 'Bitcoin is money.',
        fork_a     => ["30818:${PK2}:bitcoin", 'wss://relay.com'],
        fork_e     => [$EID, 'wss://relay.com'],
    );
    my $parsed = Net::Nostr::Wiki->from_event($event);
    is($parsed->identifier, 'bitcoin');
    is($parsed->title, 'Bitcoin');
    is($parsed->summary, 'A cryptocurrency.');
    is($parsed->fork_a->[0], "30818:${PK2}:bitcoin");
    is($parsed->fork_a->[1], 'wss://relay.com');
    is($parsed->fork_e->[0], $EID);
    is($parsed->fork_e->[1], 'wss://relay.com');
};

subtest 'from_event: defer tags parsed' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'x',
        content    => 'c',
        defer_a    => ["30818:${PK2}:x", 'wss://relay.com'],
        defer_e    => [$EID, 'wss://relay.com'],
    );
    my $parsed = Net::Nostr::Wiki->from_event($event);
    is($parsed->defer_a->[0], "30818:${PK2}:x");
    is($parsed->defer_e->[0], $EID);
};

subtest 'from_event: merge request' => sub {
    my $source_id = 'f' x 64;
    my $base_id   = 'd' x 64;
    my $event = Net::Nostr::Wiki->merge_request(
        pubkey       => $PK,
        target       => "30818:${PK2}:bitcoin",
        target_relay => 'wss://relay.com',
        base_version => $base_id,
        base_relay   => 'wss://relay.com',
        source       => $source_id,
        source_relay => 'wss://relay2.com',
        destination  => $PK2,
        content      => 'Merge me',
    );
    my $parsed = Net::Nostr::Wiki->from_event($event);
    is($parsed->target, "30818:${PK2}:bitcoin");
    is($parsed->target_relay, 'wss://relay.com');
    is($parsed->base_version, $base_id);
    is($parsed->base_relay, 'wss://relay.com');
    is($parsed->source, $source_id);
    is($parsed->source_relay, 'wss://relay2.com');
    is($parsed->destination, $PK2);
};

subtest 'from_event: redirect' => sub {
    my $event = Net::Nostr::Wiki->redirect(
        pubkey       => $PK,
        identifier   => 'btc',
        target       => "30818:${PK2}:bitcoin",
        target_relay => 'wss://relay.com',
    );
    my $parsed = Net::Nostr::Wiki->from_event($event);
    is($parsed->identifier, 'btc');
    is($parsed->target, "30818:${PK2}:bitcoin");
    is($parsed->target_relay, 'wss://relay.com');
};

subtest 'from_event: returns undef for unrecognized kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => 'hi', tags => [],
    );
    is(Net::Nostr::Wiki->from_event($event), undef);
};

###############################################################################
# validate
###############################################################################

subtest 'validate: article (30818)' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey => $PK, identifier => 'x', content => 'c',
    );
    ok(Net::Nostr::Wiki->validate($event), 'valid article');
};

subtest 'validate: article missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30818, content => 'c', tags => [],
    );
    like(dies { Net::Nostr::Wiki->validate($event) }, qr/d.*tag/i);
};

subtest 'validate: merge request (818)' => sub {
    my $sid = 'f' x 64;
    my $event = Net::Nostr::Wiki->merge_request(
        pubkey => $PK, target => "30818:${PK2}:x",
        source => $sid, source_relay => 'wss://r.com', destination => $PK2,
    );
    ok(Net::Nostr::Wiki->validate($event), 'valid merge request');
};

subtest 'validate: merge request missing a tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 818, content => '',
        tags => [['p', $PK2], ['e', $EID, '', 'source']],
    );
    like(dies { Net::Nostr::Wiki->validate($event) }, qr/a.*tag/i);
};

subtest 'validate: merge request missing p tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 818, content => '',
        tags => [['a', "30818:${PK2}:x"], ['e', $EID, '', 'source']],
    );
    like(dies { Net::Nostr::Wiki->validate($event) }, qr/p.*tag/i);
};

subtest 'validate: merge request missing source e tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 818, content => '',
        tags => [['a', "30818:${PK2}:x"], ['p', $PK2], ['e', $EID]],
    );
    like(dies { Net::Nostr::Wiki->validate($event) }, qr/source/i);
};

subtest 'validate: redirect (30819)' => sub {
    my $event = Net::Nostr::Wiki->redirect(
        pubkey => $PK, identifier => 'btc', target => "30818:${PK2}:bitcoin",
    );
    ok(Net::Nostr::Wiki->validate($event), 'valid redirect');
};

subtest 'validate: redirect missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30819, content => '',
        tags => [['a', "30818:${PK2}:bitcoin"]],
    );
    like(dies { Net::Nostr::Wiki->validate($event) }, qr/d.*tag/i);
};

subtest 'validate: redirect missing a tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30819, content => '',
        tags => [['d', 'btc']],
    );
    like(dies { Net::Nostr::Wiki->validate($event) }, qr/a.*tag/i);
};

subtest 'validate: wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    like(dies { Net::Nostr::Wiki->validate($event) }, qr/kind/i);
};

###############################################################################
# resolve_wikilinks: NIP-54 content link resolution
# "When a reference can't be found for a reference-style link, it should
#  link to the wiki article with that name instead (wikilink behavior)."
###############################################################################

subtest 'resolve_wikilinks: basic wikilink' => sub {
    my $result = Net::Nostr::Wiki->resolve_wikilinks('[cryptocurrency][]');
    like($result, qr/\[cryptocurrency\]\(nostr:30818:cryptocurrency\)/);
};

subtest 'resolve_wikilinks: wikilink normalization' => sub {
    my $result = Net::Nostr::Wiki->resolve_wikilinks('[proof of work][]');
    like($result, qr/\[proof of work\]\(nostr:30818:proof-of-work\)/);
};

subtest 'resolve_wikilinks: explicit reference link' => sub {
    my $result = Net::Nostr::Wiki->resolve_wikilinks(
        "[lightning network][Lightning Network]"
    );
    like($result, qr/\[lightning network\]\(nostr:30818:lightning-network\)/);
};

subtest 'resolve_wikilinks: defined reference is preserved' => sub {
    my $content = <<'DJOT';
[Satoshi Nakamoto][]

[Satoshi Nakamoto]: nostr:npub1satoshi
DJOT
    my $result = Net::Nostr::Wiki->resolve_wikilinks($content);
    like($result, qr/\[Satoshi Nakamoto\]\[\]/,
        'defined reference kept as-is');
};

subtest 'resolve_wikilinks: non-Latin wikilink' => sub {
    my $result = Net::Nostr::Wiki->resolve_wikilinks(
        "[\x{30D3}\x{30C3}\x{30C8}\x{30B3}\x{30A4}\x{30F3}][]"
    );
    like($result, qr/\(nostr:30818:\x{30D3}\x{30C3}\x{30C8}\x{30B3}\x{30A4}\x{30F3}\)/,
        'Japanese wikilink');
};

subtest 'resolve_wikilinks: non-Latin explicit ref with space' => sub {
    my $result = Net::Nostr::Wiki->resolve_wikilinks(
        "[Japanese Article][\x{65E5}\x{672C}\x{8A9E} \x{8A18}\x{4E8B}]"
    );
    like($result, qr/\[Japanese Article\]\(nostr:30818:\x{65E5}\x{672C}\x{8A9E}-\x{8A18}\x{4E8B}\)/,
        'non-Latin explicit ref normalized with dash');
};

subtest 'resolve_wikilinks: Cyrillic wikilink lowercased' => sub {
    my $result = Net::Nostr::Wiki->resolve_wikilinks(
        "[\x{411}\x{438}\x{442}\x{43A}\x{43E}\x{439}\x{43D}][]"
    );
    like($result, qr/\(nostr:30818:\x{431}\x{438}\x{442}\x{43A}\x{43E}\x{439}\x{43D}\)/,
        'Cyrillic lowercased');
};

subtest 'resolve_wikilinks: mixed defined and undefined refs' => sub {
    my $content = <<'DJOT';
Bitcoin is a [cryptocurrency][] invented by [Satoshi Nakamoto][].

See also: [proof of work][] and [lightning network][Lightning Network].

[Satoshi Nakamoto]: nostr:npub1satoshi
DJOT
    my $result = Net::Nostr::Wiki->resolve_wikilinks($content);
    like($result, qr/\[cryptocurrency\]\(nostr:30818:cryptocurrency\)/,
        'undefined ref becomes wikilink');
    like($result, qr/\[Satoshi Nakamoto\]\[\]/,
        'defined ref preserved');
    like($result, qr/\[proof of work\]\(nostr:30818:proof-of-work\)/,
        'undefined ref normalized');
    like($result, qr/\[lightning network\]\(nostr:30818:lightning-network\)/,
        'explicit ref target normalized');
};

###############################################################################
# Round-trip: build -> from_event -> check accessors
###############################################################################

subtest 'round-trip: article' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'Wiki Article',
        title      => 'Wiki Article',
        summary    => 'About wikis.',
        content    => 'Content here.',
    );
    my $parsed = Net::Nostr::Wiki->from_event($event);
    is($parsed->identifier, 'wiki-article', 'identifier normalized');
    is($parsed->title, 'Wiki Article');
    is($parsed->summary, 'About wikis.');
};

subtest 'round-trip: redirect' => sub {
    my $event = Net::Nostr::Wiki->redirect(
        pubkey       => $PK,
        identifier   => 'BTC',
        target       => "30818:${PK2}:bitcoin",
        target_relay => 'wss://relay.com',
    );
    my $parsed = Net::Nostr::Wiki->from_event($event);
    is($parsed->identifier, 'btc');
    is($parsed->target, "30818:${PK2}:bitcoin");
    is($parsed->target_relay, 'wss://relay.com');
};

###############################################################################
# NIP-51 kind 10102: wiki relay list
# "lists of relays can be created with the kind 10102"
# This is just documentation awareness - the kind is created via List module
###############################################################################

subtest 'wiki relay list kind constant' => sub {
    is(Net::Nostr::Wiki::WIKI_RELAY_LIST_KIND, 10102,
        'WIKI_RELAY_LIST_KIND is 10102');
};

done_testing;
