#!/usr/bin/perl

# NIP-36 conformance tests: Sensitive Content / Content Warning

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;

my $PUBKEY = 'aa' x 32;

###############################################################################
# content-warning tag — basic usage
###############################################################################

subtest 'content_warning: tag with reason' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'sensitive content',
        tags    => [['content-warning', 'spoiler']],
    );
    is($event->content_warning, 'spoiler', 'reason extracted');
};

subtest 'content_warning: tag without reason' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'sensitive content',
        tags    => [['content-warning']],
    );
    is($event->content_warning, '', 'empty string when no reason');
};

subtest 'content_warning: no tag returns undef' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'normal content',
        tags    => [],
    );
    is($event->content_warning, undef, 'undef when no tag');
};

###############################################################################
# has_content_warning — boolean check
###############################################################################

subtest 'has_content_warning: true when tag present' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'sensitive',
        tags    => [['content-warning', 'reason']],
    );
    ok($event->has_content_warning, 'true with reason');
};

subtest 'has_content_warning: true when tag present without reason' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'sensitive',
        tags    => [['content-warning']],
    );
    ok($event->has_content_warning, 'true without reason');
};

subtest 'has_content_warning: false when no tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'normal',
        tags    => [],
    );
    ok(!$event->has_content_warning, 'false');
};

###############################################################################
# Spec example — exact JSON from NIP-36
###############################################################################

subtest 'spec example: content-warning with L/l labels' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => $PUBKEY,
        created_at => 1000000000,
        kind       => 1,
        tags       => [
            ['t', 'hastag'],
            ['L', 'content-warning'],
            ['l', 'reason', 'content-warning'],
            ['L', 'social.nos.ontology'],
            ['l', 'NS-nud', 'social.nos.ontology'],
            ['content-warning', '<optional reason>'],
        ],
        content => "sensitive content with #hastag\n",
    );

    is($event->content_warning, '<optional reason>', 'content-warning reason');
    ok($event->has_content_warning, 'has content warning');

    # L and l tags present for NIP-32 labeling
    my @L = grep { $_->[0] eq 'L' } @{$event->tags};
    is(scalar @L, 2, 'two L tags');
    is($L[0][1], 'content-warning', 'L tag content-warning namespace');
    is($L[1][1], 'social.nos.ontology', 'L tag ontology namespace');

    my @l = grep { $_->[0] eq 'l' } @{$event->tags};
    is(scalar @l, 2, 'two l tags');
    is($l[0], ['l', 'reason', 'content-warning'], 'l tag with reason');
    is($l[1], ['l', 'NS-nud', 'social.nos.ontology'], 'l tag with ontology');
};

###############################################################################
# content-warning tag: reason is optional (spec says "[reason]: optional")
###############################################################################

subtest 'reason is optional per spec' => sub {
    my $with = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'x',
        tags => [['content-warning', 'violence']],
    );
    is($with->content_warning, 'violence', 'with reason');

    my $without = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'x',
        tags => [['content-warning']],
    );
    is($without->content_warning, '', 'without reason');
    ok($without->has_content_warning, 'still has warning');
};

###############################################################################
# L and l tags MAY be used (NIP-32 labeling)
###############################################################################

subtest 'L and l tags for content-warning namespace' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY, kind => 1, content => 'x',
        tags    => [
            ['L', 'content-warning'],
            ['l', 'spoiler', 'content-warning'],
            ['content-warning', 'spoiler'],
        ],
    );
    ok($event->has_content_warning, 'has content warning');

    my @l = grep { $_->[0] eq 'l' && $_->[2] eq 'content-warning' } @{$event->tags};
    is($l[0][1], 'spoiler', 'label value');
};

###############################################################################
# content-warning on different event kinds
###############################################################################

subtest 'content-warning on kind 1 (text note)' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'x',
        tags => [['content-warning', 'spoiler']],
    );
    ok($event->has_content_warning, 'kind 1');
};

subtest 'content-warning on kind 30023 (article)' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30023, content => 'article',
        tags => [['d', 'a'], ['content-warning', 'graphic']],
    );
    ok($event->has_content_warning, 'kind 30023');
    is($event->content_warning, 'graphic', 'reason on article');
};

###############################################################################
# content_warning_tag helper — build the tag
###############################################################################

subtest 'content_warning_tag: with reason' => sub {
    my $tag = Net::Nostr::Event->content_warning_tag('nudity');
    is($tag, ['content-warning', 'nudity'], 'tag with reason');
};

subtest 'content_warning_tag: without reason' => sub {
    my $tag = Net::Nostr::Event->content_warning_tag();
    is($tag, ['content-warning'], 'tag without reason');
};

subtest 'content_warning_tag: used in event construction' => sub {
    my $tag = Net::Nostr::Event->content_warning_tag('spoiler');
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'spoiler content',
        tags    => [$tag],
    );
    is($event->content_warning, 'spoiler', 'round-trip via tag helper');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'content-warning with empty string reason' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'x',
        tags => [['content-warning', '']],
    );
    is($event->content_warning, '', 'empty string reason');
    ok($event->has_content_warning, 'still has warning');
};

subtest 'multiple content-warning tags: first wins' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'x',
        tags => [
            ['content-warning', 'first'],
            ['content-warning', 'second'],
        ],
    );
    is($event->content_warning, 'first', 'first tag wins');
};

subtest 'content-warning among other tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'x',
        tags => [
            ['t', 'nostr'],
            ['p', 'bb' x 32],
            ['content-warning', 'nsfw'],
            ['e', 'cc' x 32],
        ],
    );
    is($event->content_warning, 'nsfw', 'found among other tags');
};

done_testing;
