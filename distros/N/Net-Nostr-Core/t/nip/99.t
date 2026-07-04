#!/usr/bin/perl

# NIP-99: Classified Listings
# https://github.com/nostr-protocol/nips/blob/master/99.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Event;
use Net::Nostr::ClassifiedListing;

my $JSON = JSON->new->utf8;

my $PUBKEY  = 'aa' x 32;
my $PUBKEY2 = 'bb' x 32;

###############################################################################
# "kind:30402: an addressable event to describe classified listings"
###############################################################################

subtest 'listing: creates kind 30402 event' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => "A thing for sale.",
        identifier => 'my-listing',
    );
    is($event->kind, 30402, 'kind is 30402');
    ok($event->is_addressable, 'listing is addressable');
    is($event->d_tag, 'my-listing', 'd tag matches identifier');
};

###############################################################################
# "kind:30403 has the same structure as kind:30402 and is used to save
#  draft or inactive classified listings"
###############################################################################

subtest 'draft: creates kind 30403 event' => sub {
    my $event = Net::Nostr::ClassifiedListing->draft(
        pubkey     => $PUBKEY,
        content    => "Draft listing.",
        identifier => 'my-draft',
    );
    is($event->kind, 30403, 'kind is 30403');
    ok($event->is_addressable, 'draft is addressable');
    is($event->d_tag, 'my-draft', 'd tag matches identifier');
};

subtest 'draft has same structure as listing' => sub {
    my $event = Net::Nostr::ClassifiedListing->draft(
        pubkey       => $PUBKEY,
        content      => "# Draft Listing",
        identifier   => 'my-draft',
        title        => 'Draft Title',
        summary      => 'Draft summary.',
        published_at => 1296962229,
        location     => 'LA',
        price        => ['50', 'USD'],
        status       => 'active',
        hashtags     => ['draft'],
        images       => [['https://example.com/img.png']],
    );

    is($event->kind, 30403, 'kind is 30403');
    is($event->d_tag, 'my-draft', 'd tag');

    my %tags;
    for my $tag (@{$event->tags}) {
        push @{$tags{$tag->[0]}}, $tag;
    }
    is($tags{title}[0][1], 'Draft Title', 'title tag on draft');
    is($tags{summary}[0][1], 'Draft summary.', 'summary tag on draft');
    is($tags{location}[0][1], 'LA', 'location tag on draft');
    is($tags{price}[0], ['price', '50', 'USD'], 'price tag on draft');
    is($tags{status}[0][1], 'active', 'status tag on draft');
};

subtest 'listing requires pubkey, content, identifier' => sub {
    like(dies { Net::Nostr::ClassifiedListing->listing(content => 'x', identifier => 'y') },
        qr/pubkey/, 'missing pubkey');
    like(dies { Net::Nostr::ClassifiedListing->listing(pubkey => $PUBKEY, identifier => 'y') },
        qr/content/, 'missing content');
    like(dies { Net::Nostr::ClassifiedListing->listing(pubkey => $PUBKEY, content => 'x') },
        qr/identifier/, 'missing identifier');
};

###############################################################################
# "The .content field should be a description of what is being offered"
# "These events should be a string in Markdown syntax."
###############################################################################

subtest 'content is preserved as-is (markdown)' => sub {
    my $md = "# Item for Sale\n\nThis is a **great** item.\n\nContact me for details.";
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => $md,
        identifier => 'md-test',
    );
    is($event->content, $md, 'markdown content preserved exactly');
};

###############################################################################
# "The .pubkey field of these events are treated as the party creating
#  the listing"
###############################################################################

subtest 'pubkey is the listing author' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'My listing.',
        identifier => 'author-test',
    );
    is($event->pubkey, $PUBKEY, 'pubkey is the listing author');
};

###############################################################################
# Metadata tags: title, summary, published_at, location, price, status
# "The following tags ... are standardized and SHOULD be included"
###############################################################################

subtest 'metadata tags: title, summary, published_at, location' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey       => $PUBKEY,
        content      => 'Description.',
        identifier   => 'meta-test',
        title        => 'Lorem Ipsum',
        summary      => 'More lorem ipsum that is a little more than the title',
        published_at => 1296962229,
        location     => 'NYC',
    );

    my %tags;
    for my $tag (@{$event->tags}) {
        $tags{$tag->[0]} = $tag->[1];
    }

    is($tags{title}, 'Lorem Ipsum', 'title tag');
    is($tags{summary}, 'More lorem ipsum that is a little more than the title', 'summary tag');
    is($tags{published_at}, '1296962229', 'published_at tag (stringified)');
    is($tags{location}, 'NYC', 'location tag');
};

subtest 'metadata tags are optional' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Minimal.',
        identifier => 'minimal',
    );

    my @tag_names = map { $_->[0] } @{$event->tags};
    ok(!grep({ $_ eq 'title' } @tag_names), 'no title tag when not set');
    ok(!grep({ $_ eq 'summary' } @tag_names), 'no summary tag when not set');
    ok(!grep({ $_ eq 'published_at' } @tag_names), 'no published_at when not set');
    ok(!grep({ $_ eq 'location' } @tag_names), 'no location tag when not set');
    ok(!grep({ $_ eq 'price' } @tag_names), 'no price tag when not set');
    ok(!grep({ $_ eq 'status' } @tag_names), 'no status tag when not set');
    ok(!grep({ $_ eq 'image' } @tag_names), 'no image tag when not set');
};

###############################################################################
# "price" tag: ["price", "<number>", "<currency>", "<frequency>"]
# $50 one-time: ["price", "50", "USD"]
# €15 per month: ["price", "15", "EUR", "month"]
# £50,000 per year: ["price", "50000", "GBP", "year"]
###############################################################################

subtest 'price tag: one-time payment (no frequency)' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'For sale.',
        identifier => 'price-1',
        price      => ['50', 'USD'],
    );

    my @price = grep { $_->[0] eq 'price' } @{$event->tags};
    is(scalar @price, 1, 'one price tag');
    is($price[0], ['price', '50', 'USD'], 'price tag: $50 USD');
};

subtest 'price tag: recurring payment with frequency' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Monthly subscription.',
        identifier => 'price-2',
        price      => ['15', 'EUR', 'month'],
    );

    my @price = grep { $_->[0] eq 'price' } @{$event->tags};
    is($price[0], ['price', '15', 'EUR', 'month'], 'price tag: 15 EUR/month');
};

subtest 'price tag: large amount with frequency' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Annual salary.',
        identifier => 'price-3',
        price      => ['50000', 'GBP', 'year'],
    );

    my @price = grep { $_->[0] eq 'price' } @{$event->tags};
    is($price[0], ['price', '50000', 'GBP', 'year'], 'price tag: 50000 GBP/year');
};

###############################################################################
# "status" tag: "active" or "sold"
###############################################################################

subtest 'status tag: active' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'For sale.',
        identifier => 'status-1',
        status     => 'active',
    );

    my @status = grep { $_->[0] eq 'status' } @{$event->tags};
    is($status[0][1], 'active', 'status tag is active');
};

subtest 'status tag: sold' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'No longer available.',
        identifier => 'status-2',
        status     => 'sold',
    );

    my @status = grep { $_->[0] eq 'status' } @{$event->tags};
    is($status[0][1], 'sold', 'status tag is sold');
};

###############################################################################
# "for tags/hashtags ... the t tag should be used"
###############################################################################

subtest 'hashtags via t tags' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Electronics for sale.',
        identifier => 'hash-test',
        hashtags   => ['electronics', 'gadgets'],
    );

    my @t_tags = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @t_tags, 2, 'two t tags');
    is($t_tags[0][1], 'electronics', 'first hashtag');
    is($t_tags[1][1], 'gadgets', 'second hashtag');
};

###############################################################################
# "clients SHOULD use image tags as described in NIP-58"
# Image tags: ["image", "url", "dimensions"] where dimensions is optional
###############################################################################

subtest 'image tags: single image without dimensions' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Listing with image.',
        identifier => 'img-1',
        images     => [['https://example.com/photo.jpg']],
    );

    my @img = grep { $_->[0] eq 'image' } @{$event->tags};
    is(scalar @img, 1, 'one image tag');
    is($img[0], ['image', 'https://example.com/photo.jpg'], 'image tag without dimensions');
};

subtest 'image tags: with dimensions (NIP-58 style)' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Listing with sized image.',
        identifier => 'img-2',
        images     => [['https://example.com/photo.jpg', '256x256']],
    );

    my @img = grep { $_->[0] eq 'image' } @{$event->tags};
    is($img[0], ['image', 'https://example.com/photo.jpg', '256x256'], 'image tag with dimensions');
};

subtest 'image tags: multiple images' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Listing with multiple images.',
        identifier => 'img-3',
        images     => [
            ['https://example.com/photo1.jpg', '800x600'],
            ['https://example.com/photo2.jpg'],
            ['https://example.com/photo3.jpg', '1024x768'],
        ],
    );

    my @img = grep { $_->[0] eq 'image' } @{$event->tags};
    is(scalar @img, 3, 'three image tags');
    is($img[0], ['image', 'https://example.com/photo1.jpg', '800x600'], 'first image');
    is($img[1], ['image', 'https://example.com/photo2.jpg'], 'second image (no dimensions)');
    is($img[2], ['image', 'https://example.com/photo3.jpg', '1024x768'], 'third image');
};

###############################################################################
# "g" tag: geohash for more precise location
###############################################################################

subtest 'geohash via g tag (extra_tags)' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Local item.',
        identifier => 'geo-test',
        extra_tags => [['g', 'dr5regw']],
    );

    my @g = grep { $_->[0] eq 'g' } @{$event->tags};
    is($g[0][1], 'dr5regw', 'g tag for geohash');
};

###############################################################################
# Spec example event
###############################################################################

subtest 'spec example event' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey       => $PUBKEY,
        content      => "Lorem [ipsum][nostr:nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9] dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nRead more at nostr:naddr1qqzkjurnw4ksz9thwden5te0wfjkccte9ehx7um5wghx7un8qgs2d90kkcq3nk2jry62dyf50k0h36rhpdtd594my40w9pkal876jxgrqsqqqa28pccpzu.",
        identifier   => 'lorem-ipsum',
        title        => 'Lorem Ipsum',
        published_at => 1296962229,
        location     => 'NYC',
        price        => ['100', 'USD'],
        hashtags     => ['electronics'],
        images       => [['https://url.to.img', '256x256']],
        summary      => 'More lorem ipsum that is a little more than the title',
        extra_tags   => [
            ['e', 'b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87', 'wss://relay.example.com'],
            ['a', '30023:a695f6b60119d9521934a691347d9f78e8770b56da16bb255ee286ddf9fda919:ipsum', 'wss://relay.nostr.org'],
        ],
        created_at => 1675642635,
    );

    is($event->kind, 30402, 'kind 30402');
    is($event->d_tag, 'lorem-ipsum', 'd tag');
    is($event->created_at, 1675642635, 'created_at');

    my %first_tag;
    for my $tag (@{$event->tags}) {
        $first_tag{$tag->[0]} //= $tag;
    }
    is($first_tag{title}[1], 'Lorem Ipsum', 'title tag');
    is($first_tag{published_at}[1], '1296962229', 'published_at tag');
    is($first_tag{t}[1], 'electronics', 't tag');
    is($first_tag{image}, ['image', 'https://url.to.img', '256x256'], 'image tag');
    is($first_tag{summary}[1], 'More lorem ipsum that is a little more than the title', 'summary tag');
    is($first_tag{location}[1], 'NYC', 'location tag');
    is($first_tag{price}, ['price', '100', 'USD'], 'price tag');
    is($first_tag{e}[1], 'b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87', 'e tag');
    is($first_tag{a}[1], '30023:a695f6b60119d9521934a691347d9f78e8770b56da16bb255ee286ddf9fda919:ipsum', 'a tag');

    like($event->content, qr/nostr:nevent1/, 'content has nevent reference');
    like($event->content, qr/nostr:naddr1/, 'content has naddr reference');
};

###############################################################################
# from_event: parse listing metadata from an event
###############################################################################

subtest 'from_event: parses kind 30402' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => $PUBKEY,
        kind       => 30402,
        content    => '# Item for Sale',
        created_at => 1675642635,
        tags       => [
            ['d', 'test-id'],
            ['title', 'Test Listing'],
            ['summary', 'A test summary.'],
            ['published_at', '1296962229'],
            ['location', 'NYC'],
            ['price', '100', 'USD'],
            ['status', 'active'],
            ['image', 'https://example.com/img.png', '256x256'],
            ['t', 'electronics'],
            ['t', 'gadgets'],
        ],
    );

    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    ok(defined $info, 'parsed successfully');
    is($info->identifier, 'test-id', 'identifier');
    is($info->title, 'Test Listing', 'title');
    is($info->summary, 'A test summary.', 'summary');
    is($info->published_at, '1296962229', 'published_at');
    is($info->location, 'NYC', 'location');
    is($info->price, ['100', 'USD'], 'price');
    is($info->status, 'active', 'status');
    is($info->images, [['https://example.com/img.png', '256x256']], 'images');
    is($info->hashtags, ['electronics', 'gadgets'], 'hashtags');
};

subtest 'from_event: parses kind 30403 drafts' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => $PUBKEY,
        kind       => 30403,
        content    => '# Draft',
        created_at => 1000,
        tags       => [['d', 'draft-1'], ['title', 'Draft Title']],
    );

    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    ok(defined $info, 'draft parsed');
    is($info->identifier, 'draft-1', 'identifier');
    is($info->title, 'Draft Title', 'title');
};

subtest 'from_event: returns undef for non-listing kinds' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'note', created_at => 1000,
        tags => [],
    );
    is(Net::Nostr::ClassifiedListing->from_event($event), undef, 'kind 1 returns undef');
};

subtest 'from_event: handles missing optional metadata' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30402, content => 'Minimal.',
        created_at => 1000, tags => [['d', 'min']],
    );

    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    is($info->identifier, 'min', 'identifier');
    is($info->title, undef, 'title is undef');
    is($info->summary, undef, 'summary is undef');
    is($info->published_at, undef, 'published_at is undef');
    is($info->location, undef, 'location is undef');
    is($info->price, undef, 'price is undef');
    is($info->status, undef, 'status is undef');
    is($info->images, [], 'images is empty array');
    is($info->hashtags, [], 'hashtags is empty array');
};

subtest 'from_event: price with frequency' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30402, content => 'Subscription.',
        created_at => 1000,
        tags => [['d', 'sub'], ['price', '15', 'EUR', 'month']],
    );

    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    is($info->price, ['15', 'EUR', 'month'], 'price with frequency');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid listing' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30402, content => 'Test.',
        created_at => 1000, tags => [['d', 'test']],
    );
    ok(Net::Nostr::ClassifiedListing->validate($event), 'valid listing passes');
};

subtest 'validate: valid draft' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30403, content => 'Draft.',
        created_at => 1000, tags => [['d', 'draft']],
    );
    ok(Net::Nostr::ClassifiedListing->validate($event), 'valid draft passes');
};

subtest 'validate: wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'note',
        created_at => 1000, tags => [['d', 'x']],
    );
    like(dies { Net::Nostr::ClassifiedListing->validate($event) },
        qr/30402|30403/, 'wrong kind rejected');
};

subtest 'validate: missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30402, content => 'Test.',
        created_at => 1000, tags => [],
    );
    like(dies { Net::Nostr::ClassifiedListing->validate($event) },
        qr/d tag/, 'missing d tag rejected');
};

###############################################################################
# to_naddr: addressable event linking
###############################################################################

subtest 'to_naddr: generates naddr for listing' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30402, content => 'Test.',
        created_at => 1000, tags => [['d', 'my-listing']],
    );

    my $naddr = Net::Nostr::ClassifiedListing->to_naddr($event);
    like($naddr, qr/^naddr1/, 'starts with naddr1');

    require Net::Nostr::Bech32;
    my $decoded = Net::Nostr::Bech32::decode_naddr($naddr);
    is($decoded->{identifier}, 'my-listing', 'identifier in naddr');
    is($decoded->{pubkey}, $PUBKEY, 'pubkey in naddr');
    is($decoded->{kind}, 30402, 'kind in naddr');
};

subtest 'to_naddr: with relay hints' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30402, content => 'Test.',
        created_at => 1000, tags => [['d', 'test']],
    );

    my $naddr = Net::Nostr::ClassifiedListing->to_naddr($event, relays => ['wss://relay.com']);

    require Net::Nostr::Bech32;
    my $decoded = Net::Nostr::Bech32::decode_naddr($naddr);
    is($decoded->{relays}, ['wss://relay.com'], 'relay hint encoded');
};

###############################################################################
# extra_tags are appended
###############################################################################

subtest 'extra_tags are appended' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
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
# created_at passthrough
###############################################################################

subtest 'created_at can be set' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Updated.',
        identifier => 'updated',
        created_at => 1675642635,
    );
    is($event->created_at, 1675642635, 'created_at passed through');
};

###############################################################################
# Edge: price with crypto currency codes
###############################################################################

subtest 'price with crypto currency codes (btc, eth)' => sub {
    my $btc = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Accepting bitcoin.',
        identifier => 'btc-price',
        price      => ['0.005', 'btc'],
    );

    my @bp = grep { $_->[0] eq 'price' } @{$btc->tags};
    is($bp[0], ['price', '0.005', 'btc'], 'price with btc currency');

    my $eth = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $PUBKEY,
        content    => 'Accepting ether.',
        identifier => 'eth-price',
        price      => ['1.5', 'eth'],
    );

    my @ep = grep { $_->[0] eq 'price' } @{$eth->tags};
    is($ep[0], ['price', '1.5', 'eth'], 'price with eth currency');
};

###############################################################################
# Round-trip: spec example event through from_event
###############################################################################

subtest 'round-trip: spec example event' => sub {
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey       => $PUBKEY,
        content      => "Lorem ipsum dolor sit amet.",
        identifier   => 'lorem-ipsum',
        title        => 'Lorem Ipsum',
        published_at => 1296962229,
        location     => 'NYC',
        price        => ['100', 'USD'],
        hashtags     => ['electronics'],
        images       => [['https://url.to.img', '256x256']],
        summary      => 'More lorem ipsum that is a little more than the title',
        status       => 'active',
    );

    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    is($info->identifier, 'lorem-ipsum', 'identifier round-trips');
    is($info->title, 'Lorem Ipsum', 'title round-trips');
    is($info->published_at, '1296962229', 'published_at round-trips');
    is($info->location, 'NYC', 'location round-trips');
    is($info->price, ['100', 'USD'], 'price round-trips');
    is($info->summary, 'More lorem ipsum that is a little more than the title', 'summary round-trips');
    is($info->status, 'active', 'status round-trips');
    is($info->images, [['https://url.to.img', '256x256']], 'images round-trips');
    is($info->hashtags, ['electronics'], 'hashtags round-trips');
};

###############################################################################
# from_event: multiple images round-trip
###############################################################################

subtest 'from_event: multiple images round-trip' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 30402, content => 'Multi-image listing.',
        created_at => 1000,
        tags => [
            ['d', 'multi-img'],
            ['image', 'https://example.com/a.jpg', '800x600'],
            ['image', 'https://example.com/b.jpg'],
            ['image', 'https://example.com/c.jpg', '1024x768'],
        ],
    );

    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    is($info->images, [
        ['https://example.com/a.jpg', '800x600'],
        ['https://example.com/b.jpg'],
        ['https://example.com/c.jpg', '1024x768'],
    ], 'multiple images with mixed dimensions preserved');
};

done_testing;
