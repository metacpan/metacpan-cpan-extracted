use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Event;
use Net::Nostr::Metadata;

my $PK = 'a' x 64;

###############################################################################
# POD example: create a profile metadata event
###############################################################################

subtest 'POD: create profile metadata' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey       => $PK,
        name         => 'alice',
        display_name => 'Alice in Wonderland',
        about        => 'Nostr enthusiast',
        picture      => 'https://example.com/avatar.jpg',
        website      => 'https://alice.example.com',
        banner       => 'https://example.com/banner.jpg',
        bot          => JSON::false,
        birthday     => { year => 1990, month => 6, day => 15 },
    );
    is($event->kind, 0, 'kind is 0');
};

###############################################################################
# POD example: parse metadata
###############################################################################

subtest 'POD: parse metadata' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey       => $PK,
        name         => 'alice',
        display_name => 'Alice in Wonderland',
    );
    my $meta = Net::Nostr::Metadata->from_event($event);
    is($meta->name, 'alice', 'name');
    is($meta->display_name, 'Alice in Wonderland', 'display_name');
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey => $PK,
        name   => 'alice',
    );
    ok(Net::Nostr::Metadata->validate($event), 'validate returns true');

    my $bad = Net::Nostr::Event->new(
        pubkey => $PK, kind => 0, content => 'not json', tags => [],
    );
    eval { Net::Nostr::Metadata->validate($bad) };
    ok($@, 'validate croaks on invalid');
};

###############################################################################
# POD example: tag helpers
###############################################################################

subtest 'POD: hashtag_tag' => sub {
    my $tag = Net::Nostr::Metadata->hashtag_tag('NoStr');
    is($tag, ['t', 'nostr'], 'hashtag lowercased');
};

subtest 'POD: url_tag' => sub {
    my $tag = Net::Nostr::Metadata->url_tag('https://example.com');
    is($tag, ['r', 'https://example.com'], 'url tag');
};

subtest 'POD: title_tag' => sub {
    my $tag = Net::Nostr::Metadata->title_tag('My Event');
    is($tag, ['title', 'My Event'], 'title tag');
};

subtest 'POD: external_id_tag' => sub {
    my $tag = Net::Nostr::Metadata->external_id_tag('github:torvalds');
    is($tag, ['i', 'github:torvalds'], 'external id tag');
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::Metadata->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::Metadata',
        qw(new to_event from_event validate
           hashtag_tag url_tag title_tag external_id_tag
           name display_name about picture website banner bot birthday));
};

###############################################################################
# Round-trip: to_event() -> from_event()
###############################################################################

subtest 'round-trip: to_event -> from_event' => sub {
    my $event = Net::Nostr::Metadata->to_event(
        pubkey  => $PK,
        name    => 'alice',
        about   => 'Nostr enthusiast',
        picture => 'https://example.com/avatar.jpg',
    );

    my $meta = Net::Nostr::Metadata->from_event($event);

    is($meta->name, 'alice', 'name preserved');
    is($meta->about, 'Nostr enthusiast', 'about preserved');
    is($meta->picture, 'https://example.com/avatar.jpg', 'picture preserved');
};

done_testing;
