use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::Badge;

my $PK = 'a' x 64;
my $PK2 = 'b' x 64;
my $PK3 = 'c' x 64;
my $EID = 'd' x 64;
my $EID2 = 'e' x 64;

###############################################################################
# Badge Definition (kind 30009, addressable)
###############################################################################

subtest 'badge definition: kind 30009' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
    );
    is($event->kind, 30009, 'kind is 30009');
    ok($event->is_addressable, 'kind 30009 is addressable');
};

subtest 'badge definition: d tag is unique identifier' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
    );
    is($event->d_tag, 'bravery', 'd tag is identifier');
};

subtest 'badge definition: identifier is required' => sub {
    like(
        dies { Net::Nostr::Badge->definition(pubkey => $PK) },
        qr/identifier/i,
        'identifier required'
    );
};

subtest 'badge definition: name tag (MAY)' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
        name       => 'Medal of Bravery',
    );
    my @name = grep { $_->[0] eq 'name' } @{$event->tags};
    is(scalar @name, 1, 'one name tag');
    is($name[0][1], 'Medal of Bravery', 'name tag value');
};

subtest 'badge definition: image tag with dimensions (MAY)' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
        image      => ['https://nostr.academy/awards/bravery.png', '1024x1024'],
    );
    my @img = grep { $_->[0] eq 'image' } @{$event->tags};
    is(scalar @img, 1, 'one image tag');
    is($img[0][1], 'https://nostr.academy/awards/bravery.png', 'image URL');
    is($img[0][2], '1024x1024', 'image dimensions');
};

subtest 'badge definition: image tag without dimensions' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
        image      => ['https://example.com/badge.png'],
    );
    my @img = grep { $_->[0] eq 'image' } @{$event->tags};
    is(scalar @{$img[0]}, 2, 'image tag has 2 elements (no dimensions)');
};

subtest 'badge definition: description tag (MAY)' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey      => $PK,
        identifier  => 'bravery',
        description => 'Awarded to users demonstrating bravery',
    );
    my @desc = grep { $_->[0] eq 'description' } @{$event->tags};
    is(scalar @desc, 1, 'one description tag');
    is($desc[0][1], 'Awarded to users demonstrating bravery', 'description value');
};

subtest 'badge definition: thumb tags (MAY)' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
        thumbs     => [
            ['https://nostr.academy/awards/bravery_256x256.png', '256x256'],
            ['https://nostr.academy/awards/bravery_64x64.png', '64x64'],
        ],
    );
    my @thumbs = grep { $_->[0] eq 'thumb' } @{$event->tags};
    is(scalar @thumbs, 2, 'two thumb tags');
    is($thumbs[0][1], 'https://nostr.academy/awards/bravery_256x256.png', 'first thumb URL');
    is($thumbs[0][2], '256x256', 'first thumb dimensions');
    is($thumbs[1][1], 'https://nostr.academy/awards/bravery_64x64.png', 'second thumb URL');
    is($thumbs[1][2], '64x64', 'second thumb dimensions');
};

subtest 'badge definition: thumb without dimensions' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
        thumbs     => [['https://example.com/thumb.png']],
    );
    my @thumbs = grep { $_->[0] eq 'thumb' } @{$event->tags};
    is(scalar @{$thumbs[0]}, 2, 'thumb tag has 2 elements (no dimensions)');
};

subtest 'badge definition: all optional tags together' => sub {
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
    my @tags = @{$event->tags};
    is($tags[0][0], 'd', 'd tag first');
    is($tags[0][1], 'bravery', 'd tag value');
    ok(scalar(grep { $_->[0] eq 'name' } @tags), 'has name');
    ok(scalar(grep { $_->[0] eq 'description' } @tags), 'has description');
    ok(scalar(grep { $_->[0] eq 'image' } @tags), 'has image');
    ok(scalar(grep { $_->[0] eq 'thumb' } @tags), 'has thumb');
};

subtest 'badge definition: minimal (d tag only)' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
    );
    my @tags = @{$event->tags};
    is(scalar @tags, 1, 'only d tag');
    is($tags[0][0], 'd', 'd tag');
    is($tags[0][1], 'bravery', 'd tag value');
};

subtest 'badge definition: can be updated (addressable)' => sub {
    my $v1 = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
        name       => 'Old Name',
    );
    my $v2 = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
        name       => 'New Name',
    );
    is($v1->d_tag, $v2->d_tag, 'same d_tag means same addressable coordinate');
    ok($v1->is_addressable && $v2->is_addressable, 'both addressable');
};

subtest 'badge definition: created_at passthrough' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Spec example: Badge Definition
###############################################################################

subtest 'spec example: badge definition' => sub {
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
    is($event->kind, 30009, 'kind 30009');
    is($event->d_tag, 'bravery', 'd tag');
    my @tags = @{$event->tags};
    is($tags[0], ['d', 'bravery'], 'd tag');
    is($tags[1], ['name', 'Medal of Bravery'], 'name tag');
    is($tags[2], ['description', 'Awarded to users demonstrating bravery'], 'description tag');
    is($tags[3], ['image', 'https://nostr.academy/awards/bravery.png', '1024x1024'], 'image tag');
    is($tags[4], ['thumb', 'https://nostr.academy/awards/bravery_256x256.png', '256x256'], 'thumb tag');
};

###############################################################################
# Badge Award (kind 8)
###############################################################################

subtest 'badge award: kind 8' => sub {
    my $event = Net::Nostr::Badge->award(
        pubkey    => $PK,
        badge     => "30009:$PK:bravery",
        awardees  => [[$PK2]],
    );
    is($event->kind, 8, 'kind is 8');
};

subtest 'badge award: a tag references kind 30009' => sub {
    my $event = Net::Nostr::Badge->award(
        pubkey    => $PK,
        badge     => "30009:$PK:bravery",
        awardees  => [[$PK2]],
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a, 1, 'one a tag');
    is($a[0][1], "30009:$PK:bravery", 'a tag references badge definition');
};

subtest 'badge award: single a tag required' => sub {
    like(
        dies { Net::Nostr::Badge->award(
            pubkey   => $PK,
            awardees => [[$PK2]],
        ) },
        qr/badge/i,
        'badge required'
    );
};

subtest 'badge award: one or more p tags for awardees' => sub {
    my $event = Net::Nostr::Badge->award(
        pubkey    => $PK,
        badge     => "30009:$PK:bravery",
        awardees  => [[$PK2, 'wss://relay'], [$PK3, 'wss://relay']],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 2, 'two p tags');
    is($p[0][1], $PK2, 'first awardee pubkey');
    is($p[0][2], 'wss://relay', 'first awardee relay');
    is($p[1][1], $PK3, 'second awardee pubkey');
};

subtest 'badge award: at least one awardee required' => sub {
    like(
        dies { Net::Nostr::Badge->award(
            pubkey => $PK,
            badge  => "30009:$PK:bravery",
            awardees => [],
        ) },
        qr/awardee/i,
        'at least one awardee required'
    );
};

subtest 'badge award: immutable (not replaceable or addressable)' => sub {
    my $event = Net::Nostr::Badge->award(
        pubkey    => $PK,
        badge     => "30009:$PK:bravery",
        awardees  => [[$PK2]],
    );
    ok(!$event->is_replaceable, 'not replaceable');
    ok(!$event->is_addressable, 'not addressable');
};

###############################################################################
# Spec example: Badge Award
###############################################################################

subtest 'spec example: badge award' => sub {
    my $event = Net::Nostr::Badge->award(
        pubkey    => $PK,
        badge     => "30009:${PK}:bravery",
        awardees  => [[$PK2, 'wss://relay'], [$PK3, 'wss://relay']],
    );
    is($event->kind, 8, 'kind 8');
    my @tags = @{$event->tags};
    is($tags[0], ['a', "30009:${PK}:bravery"], 'a tag');
    is($tags[1], ['p', $PK2, 'wss://relay'], 'first p tag');
    is($tags[2], ['p', $PK3, 'wss://relay'], 'second p tag');
};

###############################################################################
# Profile Badges (kind 10008, replaceable)
###############################################################################

subtest 'profile badges: kind 10008' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [
            { definition => "30009:$PK:bravery", award => $EID },
        ],
    );
    is($event->kind, 10008, 'kind is 10008');
    ok($event->is_replaceable, 'kind 10008 is replaceable');
};

subtest 'profile badges: ordered a/e tag pairs' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [
            { definition => "30009:$PK:bravery", award => $EID },
            { definition => "30009:$PK:honor", award => $EID2, award_relay => 'wss://nostr.academy' },
        ],
    );
    my @tags = @{$event->tags};
    is(scalar @tags, 4, '4 tags (2 pairs)');
    is($tags[0][0], 'a', 'first a');
    is($tags[0][1], "30009:$PK:bravery", 'first definition');
    is($tags[1][0], 'e', 'first e');
    is($tags[1][1], $EID, 'first award');
    is($tags[2][0], 'a', 'second a');
    is($tags[2][1], "30009:$PK:honor", 'second definition');
    is($tags[3][0], 'e', 'second e');
    is($tags[3][1], $EID2, 'second award');
    is($tags[3][2], 'wss://nostr.academy', 'second award relay');
};

subtest 'profile badges: may include badge set references' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [
            { definition => "30009:$PK:bravery", award => $EID },
        ],
        badge_sets => ["30008:$PK2:my-favorites"],
    );
    my @a_tags = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a_tags, 2, '2 a tags (1 badge + 1 set)');
    is($a_tags[1][1], "30008:$PK2:my-favorites", 'badge set a tag');
};

subtest 'profile badges: empty (no badges displayed)' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [],
    );
    is($event->kind, 10008, 'kind is 10008');
    is(scalar @{$event->tags}, 0, 'no tags');
};

###############################################################################
# Spec example: Profile Badges
###############################################################################

subtest 'spec example: profile badges' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [
            { definition => "30009:${PK}:bravery", award => $EID, award_relay => 'wss://nostr.academy' },
            { definition => "30009:${PK}:honor", award => $EID2, award_relay => 'wss://nostr.academy' },
        ],
    );
    is($event->kind, 10008, 'kind 10008');
    my @tags = @{$event->tags};
    is(scalar @tags, 4, '4 tags');
    is($tags[0], ['a', "30009:${PK}:bravery"], 'first a');
    is($tags[1], ['e', $EID, 'wss://nostr.academy'], 'first e');
    is($tags[2], ['a', "30009:${PK}:honor"], 'second a');
    is($tags[3], ['e', $EID2, 'wss://nostr.academy'], 'second e');
};

###############################################################################
# Badge Set (kind 30008, addressable)
###############################################################################

subtest 'badge set: kind 30008' => sub {
    my $event = Net::Nostr::Badge->badge_set(
        pubkey     => $PK2,
        identifier => 'my-favorites',
        badges     => [
            { definition => "30009:$PK:bravery", award => $EID },
        ],
    );
    is($event->kind, 30008, 'kind is 30008');
    ok($event->is_addressable, 'kind 30008 is addressable');
};

subtest 'badge set: d tag is identifier' => sub {
    my $event = Net::Nostr::Badge->badge_set(
        pubkey     => $PK2,
        identifier => 'my-favorites',
        badges     => [],
    );
    is($event->d_tag, 'my-favorites', 'd tag is identifier');
};

subtest 'badge set: identifier is required' => sub {
    like(
        dies { Net::Nostr::Badge->badge_set(
            pubkey => $PK2,
            badges => [],
        ) },
        qr/identifier/i,
        'identifier required'
    );
};

subtest 'badge set: ordered a/e tag pairs' => sub {
    my $event = Net::Nostr::Badge->badge_set(
        pubkey     => $PK2,
        identifier => 'my-favorites',
        badges     => [
            { definition => "30009:$PK:bravery", award => $EID },
            { definition => "30009:$PK:honor", award => $EID2 },
        ],
    );
    my @tags = @{$event->tags};
    # d tag + 2 a/e pairs = 5 tags
    is(scalar @tags, 5, '5 tags');
    is($tags[0][0], 'd', 'd tag first');
    is($tags[1][0], 'a', 'first a');
    is($tags[1][1], "30009:$PK:bravery", 'first definition');
    is($tags[2][0], 'e', 'first e');
    is($tags[2][1], $EID, 'first award');
    is($tags[3][0], 'a', 'second a');
    is($tags[4][0], 'e', 'second e');
};

###############################################################################
# from_event: parse Badge Definition
###############################################################################

subtest 'from_event: badge definition round-trip' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey      => $PK,
        identifier  => 'bravery',
        name        => 'Medal of Bravery',
        description => 'Awarded to brave users',
        image       => ['https://example.com/badge.png', '1024x1024'],
        thumbs      => [
            ['https://example.com/thumb_256.png', '256x256'],
            ['https://example.com/thumb_64.png', '64x64'],
        ],
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    ok($badge, 'from_event returns object');
    is($badge->identifier, 'bravery', 'identifier');
    is($badge->name, 'Medal of Bravery', 'name');
    is($badge->description, 'Awarded to brave users', 'description');
    is($badge->image, ['https://example.com/badge.png', '1024x1024'], 'image');
    is($badge->thumbs, [
        ['https://example.com/thumb_256.png', '256x256'],
        ['https://example.com/thumb_64.png', '64x64'],
    ], 'thumbs');
};

subtest 'from_event: badge definition minimal' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'minimal',
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    is($badge->identifier, 'minimal', 'identifier');
    is($badge->name, undef, 'no name');
    is($badge->description, undef, 'no description');
    is($badge->image, undef, 'no image');
    is($badge->thumbs, [], 'no thumbs');
};

###############################################################################
# from_event: parse Badge Award
###############################################################################

subtest 'from_event: badge award round-trip' => sub {
    my $event = Net::Nostr::Badge->award(
        pubkey    => $PK,
        badge     => "30009:$PK:bravery",
        awardees  => [[$PK2, 'wss://relay'], [$PK3]],
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    ok($badge, 'from_event returns object');
    is($badge->badge, "30009:$PK:bravery", 'badge coordinate');
    is($badge->awardees, [[$PK2, 'wss://relay'], [$PK3]], 'awardees');
};

###############################################################################
# from_event: parse Profile Badges
###############################################################################

subtest 'from_event: profile badges round-trip' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [
            { definition => "30009:$PK:bravery", award => $EID },
            { definition => "30009:$PK:honor", award => $EID2, award_relay => 'wss://relay' },
        ],
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    ok($badge, 'from_event returns object');
    is($badge->badges, [
        { definition => "30009:$PK:bravery", award => $EID },
        { definition => "30009:$PK:honor", award => $EID2, award_relay => 'wss://relay' },
    ], 'badges round-trip');
};

subtest 'from_event: profile badges empty' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [],
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    is($badge->badges, [], 'empty badges');
};

###############################################################################
# from_event: parse Badge Set
###############################################################################

subtest 'from_event: badge set round-trip' => sub {
    my $event = Net::Nostr::Badge->badge_set(
        pubkey     => $PK2,
        identifier => 'my-favorites',
        badges     => [
            { definition => "30009:$PK:bravery", award => $EID },
        ],
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    ok($badge, 'from_event returns object');
    is($badge->identifier, 'my-favorites', 'identifier');
    is($badge->badges, [
        { definition => "30009:$PK:bravery", award => $EID },
    ], 'badges round-trip');
};

###############################################################################
# from_event: unrecognized kind
###############################################################################

subtest 'from_event: returns undef for wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::Badge->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: badge definition' => sub {
    my $event = Net::Nostr::Badge->definition(
        pubkey     => $PK,
        identifier => 'bravery',
    );
    ok(Net::Nostr::Badge->validate($event), 'valid badge definition');
};

subtest 'validate: rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '',
        tags => [['d', 'bravery']],
    );
    like(
        dies { Net::Nostr::Badge->validate($event) },
        qr/kind/i,
        'rejects wrong kind'
    );
};

subtest 'validate: badge definition missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30009, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::Badge->validate($event) },
        qr/'d' tag/i,
        'rejects missing d tag'
    );
};

subtest 'validate: badge award' => sub {
    my $event = Net::Nostr::Badge->award(
        pubkey   => $PK,
        badge    => "30009:$PK:bravery",
        awardees => [[$PK2]],
    );
    ok(Net::Nostr::Badge->validate($event), 'valid badge award');
};

subtest 'validate: badge award missing a tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 8, content => '',
        tags => [['p', $PK2]],
    );
    like(
        dies { Net::Nostr::Badge->validate($event) },
        qr/'a' tag/i,
        'rejects missing a tag'
    );
};

subtest 'validate: badge award a tag must reference kind 30009' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 8, content => '',
        tags => [['a', "34550:$PK:community"], ['p', $PK2]],
    );
    like(
        dies { Net::Nostr::Badge->validate($event) },
        qr/30009/,
        'rejects a tag not referencing kind 30009'
    );
};

subtest 'validate: badge award missing p tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 8, content => '',
        tags => [['a', "30009:$PK:bravery"]],
    );
    like(
        dies { Net::Nostr::Badge->validate($event) },
        qr/'p' tag/i,
        'rejects missing p tag'
    );
};

subtest 'validate: profile badges' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [
            { definition => "30009:$PK:bravery", award => $EID },
        ],
    );
    ok(Net::Nostr::Badge->validate($event), 'valid profile badges');
};

subtest 'validate: profile badges empty is valid' => sub {
    my $event = Net::Nostr::Badge->profile_badges(
        pubkey => $PK2,
        badges => [],
    );
    ok(Net::Nostr::Badge->validate($event), 'empty profile badges valid');
};

subtest 'validate: badge set' => sub {
    my $event = Net::Nostr::Badge->badge_set(
        pubkey     => $PK2,
        identifier => 'my-favorites',
        badges     => [
            { definition => "30009:$PK:bravery", award => $EID },
        ],
    );
    ok(Net::Nostr::Badge->validate($event), 'valid badge set');
};

subtest 'validate: badge set missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30008, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::Badge->validate($event) },
        qr/'d' tag/i,
        'rejects missing d tag'
    );
};

###############################################################################
# Deprecated kind 30008 with d=profile_badges
###############################################################################

subtest 'deprecated: kind 30008 d=profile_badges treated as profile badges' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK2, kind => 30008, content => '',
        tags => [
            ['d', 'profile_badges'],
            ['a', "30009:$PK:bravery"],
            ['e', $EID],
        ],
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    ok($badge, 'parsed deprecated profile badges');
    is($badge->badges, [
        { definition => "30009:$PK:bravery", award => $EID },
    ], 'badges parsed from deprecated format');
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
# Profile badges: unpaired tags ignored
###############################################################################

subtest 'profile badges: unpaired a without e ignored' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK2, kind => 10008, content => '',
        tags => [
            ['a', "30009:$PK:bravery"],
            # missing e tag
            ['a', "30009:$PK:honor"],
            ['e', $EID],
        ],
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    # Only the second pair is valid
    is($badge->badges, [
        { definition => "30009:$PK:honor", award => $EID },
    ], 'unpaired a tag ignored');
};

subtest 'profile badges: unpaired e without preceding a ignored' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK2, kind => 10008, content => '',
        tags => [
            ['e', $EID],
            ['a', "30009:$PK:bravery"],
            ['e', $EID2],
        ],
    );
    my $badge = Net::Nostr::Badge->from_event($event);
    is($badge->badges, [
        { definition => "30009:$PK:bravery", award => $EID2 },
    ], 'unpaired e tag ignored');
};

done_testing;
