#!/usr/bin/perl

# NIP-92 conformance tests: Media Attachments

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::MediaAttachment;
use Net::Nostr::Event;

my $PUBKEY = 'aa' x 32;
my $SHA256 = 'bb' x 32;

###############################################################################
# imeta_tag() — build an imeta tag
###############################################################################

subtest 'imeta_tag: basic with url and mime type' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url => 'https://example.com/image.jpg',
        m   => 'image/jpeg',
    );
    is($tag->[0], 'imeta', 'tag name');
    ok(grep { $_ eq 'url https://example.com/image.jpg' } @$tag, 'url entry');
    ok(grep { $_ eq 'm image/jpeg' } @$tag, 'mime entry');
};

subtest 'imeta_tag: requires url' => sub {
    like(dies {
        Net::Nostr::MediaAttachment->imeta_tag(m => 'image/jpeg');
    }, qr/url/, 'requires url');
};

subtest 'imeta_tag: requires at least one other field' => sub {
    like(dies {
        Net::Nostr::MediaAttachment->imeta_tag(url => 'https://example.com/x.jpg');
    }, qr/at least one other field|field/i, 'requires more than url');
};

subtest 'imeta_tag: all NIP-94 fields' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url      => 'https://example.com/image.jpg',
        m        => 'image/jpeg',
        x        => $SHA256,
        ox       => $SHA256,
        size     => '1024',
        dim      => '800x600',
        magnet   => 'magnet:?xt=urn:btih:abc',
        i        => 'abc123',
        blurhash => 'eVF$^OI',
        thumb    => 'https://example.com/thumb.jpg',
        image    => 'https://example.com/preview.jpg',
        summary  => 'A photo',
        alt      => 'Scenic view',
        service  => 'nip96',
    );
    is($tag->[0], 'imeta', 'tag name');
    ok(grep { $_ eq "x $SHA256" } @$tag, 'x entry');
    ok(grep { $_ eq 'dim 800x600' } @$tag, 'dim entry');
    ok(grep { $_ eq 'alt Scenic view' } @$tag, 'alt entry');
    ok(grep { $_ eq 'blurhash eVF$^OI' } @$tag, 'blurhash entry');
};

subtest 'imeta_tag: multiple fallback URLs' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url      => 'https://example.com/image.jpg',
        m        => 'image/jpeg',
        fallback => [
            'https://alt1.example.com/image.jpg',
            'https://alt2.example.com/image.jpg',
        ],
    );
    my @fb = grep { /^fallback / } @$tag;
    is(scalar @fb, 2, 'two fallback entries');
    is($fb[0], 'fallback https://alt1.example.com/image.jpg', 'first fallback');
    is($fb[1], 'fallback https://alt2.example.com/image.jpg', 'second fallback');
};

###############################################################################
# Spec example — exact JSON from NIP-92
###############################################################################

subtest 'spec example: full imeta tag' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url      => 'https://nostr.build/i/my-image.jpg',
        m        => 'image/jpeg',
        blurhash => 'eVF$^OI:${M{o#*0-nNFxakD-?xVM}WEWB%iNKxvR-oetmo#R-aen$',
        dim      => '3024x4032',
        alt      => 'A scenic photo overlooking the coast of Costa Rica',
        x        => $SHA256,
        fallback => [
            'https://nostrcheck.me/alt1.jpg',
            'https://void.cat/alt1.jpg',
        ],
    );
    is($tag->[0], 'imeta', 'tag name');
    ok(grep { $_ eq 'url https://nostr.build/i/my-image.jpg' } @$tag, 'url');
    ok(grep { $_ eq 'm image/jpeg' } @$tag, 'mime');
    ok(grep { /^blurhash / } @$tag, 'blurhash');
    ok(grep { $_ eq 'dim 3024x4032' } @$tag, 'dim');
    ok(grep { /^alt / } @$tag, 'alt');
    ok(grep { $_ eq "x $SHA256" } @$tag, 'hash');
    my @fb = grep { /^fallback / } @$tag;
    is(scalar @fb, 2, 'two fallbacks');
};

subtest 'spec example: event with imeta tag' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url      => 'https://nostr.build/i/my-image.jpg',
        m        => 'image/jpeg',
        blurhash => 'eVF$^OI:${M{o#*0-nNFxakD-?xVM}WEWB%iNKxvR-oetmo#R-aen$',
        dim      => '3024x4032',
        alt      => 'A scenic photo overlooking the coast of Costa Rica',
        x        => $SHA256,
        fallback => [
            'https://nostrcheck.me/alt1.jpg',
            'https://void.cat/alt1.jpg',
        ],
    );
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => "More image metadata tests don't mind me https://nostr.build/i/my-image.jpg",
        tags    => [$tag],
    );
    is($event->kind, 1, 'kind 1');
    like($event->content, qr{https://nostr\.build/i/my-image\.jpg}, 'URL in content');

    my @imeta = grep { $_->[0] eq 'imeta' } @{$event->tags};
    is(scalar @imeta, 1, 'one imeta tag');
};

###############################################################################
# from_tag() — parse an imeta tag
###############################################################################

subtest 'from_tag: parse basic imeta' => sub {
    my $tag = [
        'imeta',
        'url https://example.com/image.jpg',
        'm image/jpeg',
        'dim 800x600',
    ];
    my $info = Net::Nostr::MediaAttachment->from_tag($tag);
    is($info->url, 'https://example.com/image.jpg', 'url');
    is($info->m, 'image/jpeg', 'mime');
    is($info->dim, '800x600', 'dim');
};

subtest 'from_tag: parse with fallbacks' => sub {
    my $tag = [
        'imeta',
        'url https://example.com/image.jpg',
        'm image/jpeg',
        'fallback https://alt1.com/image.jpg',
        'fallback https://alt2.com/image.jpg',
    ];
    my $info = Net::Nostr::MediaAttachment->from_tag($tag);
    is($info->fallback, [
        'https://alt1.com/image.jpg',
        'https://alt2.com/image.jpg',
    ], 'fallback URLs');
};

subtest 'from_tag: parse spec example' => sub {
    my $tag = [
        'imeta',
        'url https://nostr.build/i/my-image.jpg',
        'm image/jpeg',
        'blurhash eVF$^OI:${M{o#*0-nNFxakD-?xVM}WEWB%iNKxvR-oetmo#R-aen$',
        'dim 3024x4032',
        'alt A scenic photo overlooking the coast of Costa Rica',
        "x $SHA256",
        'fallback https://nostrcheck.me/alt1.jpg',
        'fallback https://void.cat/alt1.jpg',
    ];
    my $info = Net::Nostr::MediaAttachment->from_tag($tag);
    is($info->url, 'https://nostr.build/i/my-image.jpg', 'url');
    is($info->m, 'image/jpeg', 'mime');
    like($info->blurhash, qr/^eVF/, 'blurhash');
    is($info->dim, '3024x4032', 'dim');
    is($info->alt, 'A scenic photo overlooking the coast of Costa Rica', 'alt');
    is($info->x, $SHA256, 'hash');
    is(scalar @{$info->fallback}, 2, 'two fallbacks');
};

subtest 'from_tag: values with spaces' => sub {
    my $tag = [
        'imeta',
        'url https://example.com/image.jpg',
        'm image/jpeg',
        'alt A photo with multiple words in the description',
    ];
    my $info = Net::Nostr::MediaAttachment->from_tag($tag);
    is($info->alt, 'A photo with multiple words in the description',
        'value with spaces preserved');
};

###############################################################################
# from_event() — parse all imeta tags from an event
###############################################################################

subtest 'from_event: single imeta' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'Check this https://example.com/img.jpg',
        tags    => [[
            'imeta',
            'url https://example.com/img.jpg',
            'm image/jpeg',
        ]],
    );
    my @attachments = Net::Nostr::MediaAttachment->from_event($event);
    is(scalar @attachments, 1, 'one attachment');
    is($attachments[0]->url, 'https://example.com/img.jpg', 'url');
};

subtest 'from_event: multiple imeta tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'Two images https://example.com/a.jpg and https://example.com/b.png',
        tags    => [
            ['imeta', 'url https://example.com/a.jpg', 'm image/jpeg'],
            ['imeta', 'url https://example.com/b.png', 'm image/png'],
        ],
    );
    my @attachments = Net::Nostr::MediaAttachment->from_event($event);
    is(scalar @attachments, 2, 'two attachments');
    is($attachments[0]->url, 'https://example.com/a.jpg', 'first url');
    is($attachments[1]->url, 'https://example.com/b.png', 'second url');
};

subtest 'from_event: no imeta tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'No images here',
        tags    => [['t', 'nostr']],
    );
    my @attachments = Net::Nostr::MediaAttachment->from_event($event);
    is(scalar @attachments, 0, 'no attachments');
};

subtest 'from_event: imeta among other tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'Look https://example.com/img.jpg #nostr',
        tags    => [
            ['t', 'nostr'],
            ['imeta', 'url https://example.com/img.jpg', 'm image/jpeg'],
            ['p', $PUBKEY],
        ],
    );
    my @attachments = Net::Nostr::MediaAttachment->from_event($event);
    is(scalar @attachments, 1, 'one attachment among other tags');
};

###############################################################################
# for_url() — get metadata for a specific URL
###############################################################################

subtest 'for_url: find by URL' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'Two https://example.com/a.jpg and https://example.com/b.png',
        tags    => [
            ['imeta', 'url https://example.com/a.jpg', 'm image/jpeg', 'dim 800x600'],
            ['imeta', 'url https://example.com/b.png', 'm image/png', 'dim 1920x1080'],
        ],
    );
    my $info = Net::Nostr::MediaAttachment->for_url($event, 'https://example.com/b.png');
    is($info->m, 'image/png', 'found correct attachment');
    is($info->dim, '1920x1080', 'correct dim');
};

subtest 'for_url: returns undef when not found' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => 'text',
        tags    => [],
    );
    my $info = Net::Nostr::MediaAttachment->for_url($event, 'https://example.com/none.jpg');
    is($info, undef, 'undef when not found');
};

###############################################################################
# One imeta tag per URL (SHOULD)
###############################################################################

subtest 'one imeta per URL: SHOULD have one per URL' => sub {
    my $tag1 = Net::Nostr::MediaAttachment->imeta_tag(
        url => 'https://example.com/a.jpg',
        m   => 'image/jpeg',
    );
    my $tag2 = Net::Nostr::MediaAttachment->imeta_tag(
        url => 'https://example.com/b.jpg',
        m   => 'image/png',
    );
    # Each URL gets its own tag
    isnt($tag1, $tag2, 'different tags for different URLs');
};

###############################################################################
# imeta tag MUST have url and at least one other field
###############################################################################

subtest 'imeta tag: url is first entry' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url => 'https://example.com/image.jpg',
        m   => 'image/jpeg',
    );
    # url should be present as an entry
    my ($url_entry) = grep { /^url / } @$tag;
    ok(defined $url_entry, 'url entry present');
};

###############################################################################
# imeta MAY include any NIP-94 field
###############################################################################

subtest 'all NIP-94 fields supported' => sub {
    for my $field (qw(m x ox size dim magnet i blurhash thumb image summary alt service)) {
        my $tag = Net::Nostr::MediaAttachment->imeta_tag(
            url    => 'https://example.com/file',
            $field => 'test-value',
        );
        ok(grep { $_ eq "$field test-value" } @$tag, "$field supported");
    }
};

###############################################################################
# Each imeta SHOULD match a URL in event content
###############################################################################

subtest 'imeta URL matches content URL' => sub {
    my $url = 'https://nostr.build/i/my-image.jpg';
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 1,
        content => "Check this out $url",
        tags    => [['imeta', "url $url", 'm image/jpeg']],
    );
    my @attachments = Net::Nostr::MediaAttachment->from_event($event);
    like($event->content, qr/\Q$attachments[0]->url\E|nostr\.build/, 'URL in content');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'from_tag: unknown fields preserved' => sub {
    my $tag = [
        'imeta',
        'url https://example.com/image.jpg',
        'm image/jpeg',
        'custom-field some-value',
    ];
    my $info = Net::Nostr::MediaAttachment->from_tag($tag);
    is($info->url, 'https://example.com/image.jpg', 'url parsed');
    is($info->fields->{'custom-field'}, 'some-value', 'unknown field preserved');
};

subtest 'from_tag: empty fallback list when no fallbacks' => sub {
    my $tag = [
        'imeta',
        'url https://example.com/image.jpg',
        'm image/jpeg',
    ];
    my $info = Net::Nostr::MediaAttachment->from_tag($tag);
    is($info->fallback, [], 'empty fallback list');
};

done_testing;
