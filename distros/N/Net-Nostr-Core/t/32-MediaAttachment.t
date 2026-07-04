#!/usr/bin/perl

# Unit tests for Net::Nostr::MediaAttachment
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::MediaAttachment;
use Net::Nostr::Event;

my $pubkey  = 'aa' x 32;
my $sha256  = 'bb' x 32;

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: build an imeta tag' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url      => 'https://example.com/photo.jpg',
        m        => 'image/jpeg',
        dim      => '1920x1080',
        alt      => 'A scenic photo',
        blurhash => 'eVF$^OI',
        fallback => ['https://alt.example.com/photo.jpg'],
    );
    is($tag->[0], 'imeta', 'imeta tag');
};

subtest 'SYNOPSIS: attach to event' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url => 'https://example.com/photo.jpg',
        m   => 'image/jpeg',
    );
    my $event = Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1,
        content => 'Check this out https://example.com/photo.jpg',
        tags    => [$tag],
    );
    is($event->kind, 1, 'kind');
};

subtest 'SYNOPSIS: parse imeta from event' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url => 'https://example.com/photo.jpg',
        m   => 'image/jpeg',
        dim => '1920x1080',
        alt => 'A scenic photo',
    );
    my $event = Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1,
        content => 'https://example.com/photo.jpg',
        tags    => [$tag],
    );
    my @attachments = Net::Nostr::MediaAttachment->from_event($event);
    for my $att (@attachments) {
        is($att->url, 'https://example.com/photo.jpg', 'url');
        is($att->m, 'image/jpeg', 'mime');
        is($att->dim, '1920x1080', 'dim');
        is($att->alt, 'A scenic photo', 'alt');
    }
};

subtest 'SYNOPSIS: for_url' => sub {
    my $url = 'https://example.com/photo.jpg';
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url => $url,
        m   => 'image/jpeg',
    );
    my $event = Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1,
        content => $url,
        tags    => [$tag],
    );
    my $info = Net::Nostr::MediaAttachment->for_url($event, $url);
    is($info->url, $url, 'found by url');
};

###############################################################################
# imeta_tag() POD example
###############################################################################

subtest 'imeta_tag: POD example' => sub {
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url      => 'https://example.com/photo.jpg',
        m        => 'image/jpeg',
        dim      => '1920x1080',
        alt      => 'Description',
        x        => $sha256,
        fallback => ['https://alt1.com/photo.jpg'],
    );
    is($tag->[0], 'imeta', 'tag name');
    ok(grep { $_ eq "x $sha256" } @$tag, 'hash entry');
};

###############################################################################
# from_tag() POD example
###############################################################################

subtest 'from_tag: POD example' => sub {
    my $tag = ['imeta', 'url https://example.com/img.jpg', 'm image/jpeg'];
    my $info = Net::Nostr::MediaAttachment->from_tag($tag);
    is($info->url, 'https://example.com/img.jpg', 'url');
    is($info->m, 'image/jpeg', 'mime');
};

###############################################################################
# from_event() POD example
###############################################################################

subtest 'from_event: POD example' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1,
        content => 'https://example.com/img.jpg',
        tags    => [['imeta', 'url https://example.com/img.jpg', 'm image/jpeg']],
    );
    my @attachments = Net::Nostr::MediaAttachment->from_event($event);
    is(scalar @attachments, 1, 'one attachment');
};

###############################################################################
# for_url() POD example
###############################################################################

subtest 'for_url: POD example' => sub {
    my $url = 'https://example.com/img.jpg';
    my $event = Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1,
        content => $url,
        tags    => [['imeta', "url $url", 'm image/jpeg']],
    );
    my $info = Net::Nostr::MediaAttachment->for_url($event, $url);
    ok(defined $info, 'found');
    is($info->url, $url, 'correct url');
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $att = Net::Nostr::MediaAttachment->new(
        url      => 'https://example.com/photo.jpg',
        m        => 'image/jpeg',
        dim      => '1920x1080',
        fallback => ['https://alt.example.com/photo.jpg'],
    );
    is $att->url, 'https://example.com/photo.jpg';
    is $att->m, 'image/jpeg';
    is $att->dim, '1920x1080';
    is $att->fallback, ['https://alt.example.com/photo.jpg'];
    is $att->fields, {};
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::MediaAttachment->new(
            url   => 'https://example.com/photo.jpg',
            m     => 'image/jpeg',
            bogus => 'value',
        ) },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

done_testing;
