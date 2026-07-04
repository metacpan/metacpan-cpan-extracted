#!/usr/bin/perl

# Unit tests for Net::Nostr::ClassifiedListing
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::ClassifiedListing;
use Net::Nostr::Event;

my $pubkey = 'aa' x 32;

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: create a classified listing' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey       => $pubkey,
        content      => "# Vintage Guitar\n\nGreat condition, barely played.",
        identifier   => 'vintage-guitar',
        title        => 'Vintage Guitar',
        summary      => 'A beautiful vintage guitar in great condition',
        published_at => 1296962229,
        location     => 'NYC',
        price        => ['500', 'USD'],
        status       => 'active',
        hashtags     => ['music', 'instruments'],
        images       => [
            ['https://example.com/guitar1.jpg', '800x600'],
            ['https://example.com/guitar2.jpg'],
        ],
    );
    is($event->kind, 30402, 'kind 30402');
    is($event->d_tag, 'vintage-guitar', 'd tag');
};

subtest 'SYNOPSIS: create a draft' => sub {
    my $draft = Net::Nostr::ClassifiedListing->draft(
        pubkey     => $pubkey,
        content    => "# WIP Listing\n\nNot ready yet.",
        identifier => 'my-draft',
        title      => 'Work in Progress',
    );
    is($draft->kind, 30403, 'kind 30403');
};

subtest 'SYNOPSIS: recurring price' => sub {
    my $rental = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $pubkey,
        content    => "Apartment for rent.",
        identifier => 'apartment-rent',
        title      => '2BR Apartment',
        price      => ['1500', 'USD', 'month'],
        location   => 'Brooklyn',
    );
    my @price = grep { $_->[0] eq 'price' } @{$rental->tags};
    is($price[0], ['price', '1500', 'USD', 'month'], 'recurring price tag');
};

subtest 'SYNOPSIS: parse listing metadata' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey       => $pubkey,
        content      => "# Vintage Guitar\n\nGreat condition.",
        identifier   => 'vintage-guitar',
        title        => 'Vintage Guitar',
        location     => 'NYC',
        price        => ['500', 'USD'],
    );

    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    is($info->title, 'Vintage Guitar', 'title');
    is($info->location, 'NYC', 'location');
    is($info->price->[0], '500', 'price amount');
    is($info->price->[1], 'USD', 'price currency');
};

subtest 'SYNOPSIS: generate naddr' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 30402, content => 'Test.',
        created_at => 1000, tags => [['d', 'test']],
    );
    my $naddr = Net::Nostr::ClassifiedListing->to_naddr($event,
        relays => ['wss://relay.example.com'],
    );
    like($naddr, qr/^naddr1/, 'naddr generated');
};

subtest 'SYNOPSIS: validate' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 30402, content => 'Test.',
        created_at => 1000, tags => [['d', 'test']],
    );
    ok(Net::Nostr::ClassifiedListing->validate($event), 'valid listing');
};

###############################################################################
# listing() POD examples
###############################################################################

subtest 'listing: price examples from POD' => sub {
    # One-time: $50 USD
    my $e1 = Net::Nostr::ClassifiedListing->listing(
        pubkey => $pubkey, content => 'x', identifier => 'p1',
        price => ['50', 'USD'],
    );
    my @p1 = grep { $_->[0] eq 'price' } @{$e1->tags};
    is($p1[0], ['price', '50', 'USD'], '$50 USD one-time');

    # Recurring: €15/month
    my $e2 = Net::Nostr::ClassifiedListing->listing(
        pubkey => $pubkey, content => 'x', identifier => 'p2',
        price => ['15', 'EUR', 'month'],
    );
    my @p2 = grep { $_->[0] eq 'price' } @{$e2->tags};
    is($p2[0], ['price', '15', 'EUR', 'month'], '15 EUR/month');
};

subtest 'listing: images examples from POD' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey => $pubkey, content => 'x', identifier => 'img',
        images => [
            ['https://example.com/photo.jpg', '800x600'],
            ['https://example.com/detail.jpg'],
        ],
    );
    my @imgs = grep { $_->[0] eq 'image' } @{$event->tags};
    is(scalar @imgs, 2, 'two image tags');
    is($imgs[0], ['image', 'https://example.com/photo.jpg', '800x600'], 'first with dimensions');
    is($imgs[1], ['image', 'https://example.com/detail.jpg'], 'second without');
};

###############################################################################
# from_event() POD examples
###############################################################################

subtest 'from_event: POD example' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 30402, content => 'Test.',
        created_at => 1000,
        tags => [
            ['d', 'my-listing'],
            ['title', 'Vintage Guitar'],
            ['price', '500', 'USD'],
        ],
    );

    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    is($info->identifier, 'my-listing', 'identifier');
    is($info->title, 'Vintage Guitar', 'title or undef');
    is($info->price->[1], 'USD', 'price currency') if $info->price;
};

###############################################################################
# validate() POD example
###############################################################################

subtest 'validate: POD eval example' => sub {
    my $bad = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 1, content => 'not a listing',
        created_at => 1000, tags => [],
    );
    eval { Net::Nostr::ClassifiedListing->validate($bad) };
    like($@, qr/30402|30403/, 'Invalid listing caught');
};

###############################################################################
# Accessor POD examples
###############################################################################

subtest 'accessor: price arrayref formats' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 30402, content => 'x',
        created_at => 1000,
        tags => [['d', 'a'], ['price', '100', 'USD']],
    );
    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    is($info->price, ['100', 'USD'], 'price without frequency');

    my $event2 = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 30402, content => 'x',
        created_at => 1000,
        tags => [['d', 'b'], ['price', '15', 'EUR', 'month']],
    );
    my $info2 = Net::Nostr::ClassifiedListing->from_event($event2);
    is($info2->price, ['15', 'EUR', 'month'], 'price with frequency');
};

subtest 'accessor: images arrayref of arrayrefs' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 30402, content => 'x',
        created_at => 1000,
        tags => [['d', 'a'], ['image', 'https://example.com/a.jpg', '256x256'], ['image', 'https://example.com/b.jpg']],
    );
    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    is($info->images, [['https://example.com/a.jpg', '256x256'], ['https://example.com/b.jpg']], 'images with and without dimensions');
};

subtest 'accessor: hashtags arrayref' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 30402, content => 'x',
        created_at => 1000,
        tags => [['d', 'a'], ['t', 'electronics'], ['t', 'gadgets']],
    );
    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    is($info->hashtags, ['electronics', 'gadgets'], 'hashtags from t tags');
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $info = Net::Nostr::ClassifiedListing->new(
        identifier => 'my-listing',
        title      => 'Guitar',
        price      => '500 USD',
        location   => 'NYC',
    );
    is $info->identifier, 'my-listing';
    is $info->title, 'Guitar';
    is $info->price, '500 USD';
    is $info->location, 'NYC';
    is $info->hashtags, [];
    is $info->images, [];
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::ClassifiedListing->new(
            identifier => 'my-listing',
            title      => 'Guitar',
            bogus      => 'value',
        ) },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

done_testing;
