use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::Badge;

my $PK = 'a' x 64;
my $PK2 = 'b' x 64;
my $EID = 'd' x 64;

###############################################################################
# POD example: define a badge
###############################################################################

subtest 'POD: define a badge' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey      => $PK,
        identifier  => 'bravery',
        name        => 'Medal of Bravery',
        description => 'Awarded to users demonstrating bravery',
        image       => ['https://nostr.academy/awards/bravery.png', '1024x1024'],
        thumbs      => [
            ['https://nostr.academy/awards/bravery_256x256.png', '256x256'],
        ],
    );
    is($event->kind, 30009, 'kind is 30009');
    is($event->d_tag, 'bravery', 'd tag');
};

###############################################################################
# POD example: award a badge
###############################################################################

subtest 'POD: award a badge' => sub {
    my $event = Net::Nostr::Badge->award(
        pubkey   => $PK,
        badge    => "30009:${PK}:bravery",
        awardees => [[$PK2, 'wss://relay']],
    );
    is($event->kind, 8, 'kind is 8');
};

###############################################################################
# POD example: profile badges
###############################################################################

subtest 'POD: profile badges' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [
            { definition => "30009:${PK}:bravery", award => $EID },
        ],
    );
    is($event->kind, 10008, 'kind is 10008');
};

###############################################################################
# POD example: badge set
###############################################################################

subtest 'POD: badge set' => sub {
    my $event = Net::Nostr::Badge->badge_set(
        pubkey     => $PK2,
        identifier => 'my-favorites',
        badges     => [
            { definition => "30009:${PK}:bravery", award => $EID },
        ],
    );
    is($event->kind, 30008, 'kind is 30008');
    is($event->d_tag, 'my-favorites', 'd tag');
};

###############################################################################
# POD example: parse and validate
###############################################################################

subtest 'POD: from_event' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
        name       => 'Medal of Bravery',
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    is($badge->identifier, 'bravery', 'identifier');
    is($badge->name, 'Medal of Bravery', 'name');
};

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
    );
    ok(Net::Nostr::Badge->validate($event), 'validate returns true');

    my $bad = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30009, content => '', tags => [],
    );
    eval { Net::Nostr::Badge->validate($bad) };
    ok($@, 'validate croaks on invalid event');
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::Badge->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::Badge',
        qw(new definition award profile_badges badge_set from_event validate
           identifier name description image thumbs badge awardees badges badge_sets));
};

###############################################################################
# Round-trip: definition() -> from_event()
###############################################################################

subtest 'round-trip: definition -> from_event' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey      => $PK,
        identifier  => 'bravery',
        name        => 'Medal of Bravery',
        description => 'Awarded to users demonstrating bravery',
    );

    my $badge = Net::Nostr::Badge->from_event($event);

    is($badge->identifier, 'bravery', 'identifier preserved');
    is($badge->name, 'Medal of Bravery', 'name preserved');
    is($badge->description, 'Awarded to users demonstrating bravery', 'description preserved');
};

done_testing;
