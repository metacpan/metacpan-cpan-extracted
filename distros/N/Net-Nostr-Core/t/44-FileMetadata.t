use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::FileMetadata;

my $PK = 'a' x 64;

###############################################################################
# POD example: build and parse file metadata event
###############################################################################

subtest 'POD: build file metadata event' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey  => $PK,
        content => 'A scenic photo',
        url     => 'https://example.com/photo.jpg',
        m       => 'image/jpeg',
        x       => 'aa' x 32,
        ox      => 'bb' x 32,
        dim     => '1920x1080',
        alt     => 'A scenic photo',
        blurhash => 'eVF$^OI',
        fallback => ['https://alt.example.com/photo.jpg'],
    );
    is($event->kind, 1063, 'kind is 1063');

    my $fm = Net::Nostr::FileMetadata->from_event($event);
    is($fm->url, 'https://example.com/photo.jpg', 'url round-trips');
    is($fm->m, 'image/jpeg', 'm round-trips');
    is($fm->dim, '1920x1080', 'dim round-trips');
    is($fm->alt, 'A scenic photo', 'alt round-trips');
};

###############################################################################
# POD example: parse from event
###############################################################################

subtest 'POD: parse from event' => sub {
    use Net::Nostr::Event;
    my $event = Net::Nostr::Event->new(
        pubkey  => $PK,
        kind    => 1063,
        content => 'my file',
        tags    => [
            ['url', 'https://example.com/file.pdf'],
            ['m', 'application/pdf'],
            ['x', 'aa' x 32],
            ['ox', 'bb' x 32],
            ['size', '102400'],
        ],
    );
    my $fm = Net::Nostr::FileMetadata->from_event($event);
    is($fm->url, 'https://example.com/file.pdf');
    is($fm->m, 'application/pdf');
    is($fm->size, '102400');
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: no args' => sub {
    my $fm = Net::Nostr::FileMetadata->new;
    isa_ok($fm, 'Net::Nostr::FileMetadata');
};

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::FileMetadata->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# exports
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::FileMetadata',
        qw(new to_event from_event validate
           url m x ox size dim magnet i blurhash
           thumb thumb_hash image image_hash
           summary alt fallback service));
};

done_testing;
