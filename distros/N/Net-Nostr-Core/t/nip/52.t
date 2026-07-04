use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::Calendar;

my $PK = 'a' x 64;

###############################################################################
# Date-Based Calendar Event (kind 31922)
###############################################################################

subtest 'date_event: kind 31922' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'vacation-2024',
        title      => 'Summer Vacation',
        start      => '2024-07-01',
    );
    is($event->kind, 31922, 'kind is 31922');
    ok($event->is_addressable, 'addressable');
};

# Spec: d tag (required)
subtest 'date_event: d tag' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'vacation-2024',
        title      => 'Summer Vacation',
        start      => '2024-07-01',
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'vacation-2024', 'd tag');
};

# Spec: title tag (required)
subtest 'date_event: title tag' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Summer Vacation',
        start      => '2024-07-01',
    );
    my @t = grep { $_->[0] eq 'title' } @{$event->tags};
    is($t[0][1], 'Summer Vacation', 'title tag');
};

# Spec: start tag (required) inclusive start date YYYY-MM-DD
subtest 'date_event: start tag' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
    );
    my @s = grep { $_->[0] eq 'start' } @{$event->tags};
    is($s[0][1], '2024-07-01', 'start date');
};

# Spec: end tag (optional) exclusive end date YYYY-MM-DD
subtest 'date_event: end tag' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
        end        => '2024-07-15',
    );
    my @e = grep { $_->[0] eq 'end' } @{$event->tags};
    is($e[0][1], '2024-07-15', 'end date');
};

subtest 'date_event: end omitted' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
    );
    my @e = grep { $_->[0] eq 'end' } @{$event->tags};
    is(scalar @e, 0, 'no end tag');
};

# Spec: content SHOULD be a description
subtest 'date_event: content is description' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
        content    => 'A fun vacation',
    );
    is($event->content, 'A fun vacation', 'content');
};

subtest 'date_event: content defaults to empty string' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
    );
    is($event->content, '', 'empty content');
};

###############################################################################
# Common optional tags for calendar events
###############################################################################

subtest 'date_event: summary tag (optional)' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
        summary    => 'Brief description',
    );
    my @s = grep { $_->[0] eq 'summary' } @{$event->tags};
    is($s[0][1], 'Brief description', 'summary');
};

subtest 'date_event: image tag (optional)' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
        image      => 'https://example.com/event.jpg',
    );
    my @i = grep { $_->[0] eq 'image' } @{$event->tags};
    is($i[0][1], 'https://example.com/event.jpg', 'image');
};

# Spec: location (optional, repeated)
subtest 'date_event: location tags (optional, repeated)' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
        locations  => ['123 Main St', 'https://meet.example.com/room'],
    );
    my @l = grep { $_->[0] eq 'location' } @{$event->tags};
    is(scalar @l, 2, 'two location tags');
    is($l[0][1], '123 Main St', 'first location');
    is($l[1][1], 'https://meet.example.com/room', 'second location');
};

# Spec: g tag (optional) geohash
subtest 'date_event: g tag (optional)' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
        geohash    => 'u4pruydqqvj',
    );
    my @g = grep { $_->[0] eq 'g' } @{$event->tags};
    is($g[0][1], 'u4pruydqqvj', 'geohash');
};

# Spec: p tag (optional, repeated) with relay and role
subtest 'date_event: p tags (optional, repeated)' => sub {
    my $pk2 = 'b' x 64;
    my $pk3 = 'c' x 64;
    my $event = Net::Nostr::Calendar->date_event(
        pubkey       => $PK,
        identifier   => 'test',
        title        => 'Test',
        start        => '2024-07-01',
        participants => [
            [$pk2, 'wss://relay.example.com', 'speaker'],
            [$pk3, '', 'attendee'],
        ],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 2, 'two p tags');
    is($p[0][1], $pk2, 'first participant pubkey');
    is($p[0][2], 'wss://relay.example.com', 'relay url');
    is($p[0][3], 'speaker', 'role');
    is($p[1][1], $pk3, 'second participant');
    is($p[1][3], 'attendee', 'role');
};

# Spec: t tag (optional, repeated) hashtag
subtest 'date_event: t tags (optional, repeated)' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
        hashtags   => ['vacation', 'summer'],
    );
    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @t, 2, 'two t tags');
    is($t[0][1], 'vacation', 'first hashtag');
};

# Spec: r tag (optional, repeated) references
subtest 'date_event: r tags (optional, repeated)' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
        references => ['https://example.com/details'],
    );
    my @r = grep { $_->[0] eq 'r' } @{$event->tags};
    is($r[0][1], 'https://example.com/details', 'r tag');
};

# Spec: a tag (repeated) reference to kind 31924 calendar
subtest 'date_event: a tags (calendar reference)' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
        calendars  => ["31924:${PK}:my-calendar"],
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "31924:${PK}:my-calendar", 'a tag');
};

# Spec: date-based spec example
subtest 'date_event: spec example' => sub {
    my $pk2 = 'b' x 64;
    my $pk3 = 'c' x 64;
    my $event = Net::Nostr::Calendar->date_event(
        pubkey       => $PK,
        identifier   => 'random-identifier',
        title        => 'title of calendar event',
        content      => 'description of calendar event',
        start        => '2024-07-01',
        end          => '2024-07-15',
        locations    => ['location'],
        geohash      => 'geohash',
        participants => [
            [$pk2, 'wss://relay.example.com', 'role'],
            [$pk3, 'wss://relay.example.com', 'role'],
        ],
    );
    is($event->kind, 31922, 'kind');
    is($event->content, 'description of calendar event', 'content');

    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'random-identifier', 'd');

    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is($title[0][1], 'title of calendar event', 'title');

    my @start = grep { $_->[0] eq 'start' } @{$event->tags};
    is($start[0][1], '2024-07-01', 'start');

    my @end = grep { $_->[0] eq 'end' } @{$event->tags};
    is($end[0][1], '2024-07-15', 'end');

    my @loc = grep { $_->[0] eq 'location' } @{$event->tags};
    is(scalar @loc, 1, 'location count');

    my @g = grep { $_->[0] eq 'g' } @{$event->tags};
    is($g[0][1], 'geohash', 'g');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 2, 'participant count');
};

###############################################################################
# Time-Based Calendar Event (kind 31923)
###############################################################################

subtest 'time_event: kind 31923' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'meeting-123',
        title      => 'Team Meeting',
        start      => 1700000000,
    );
    is($event->kind, 31923, 'kind is 31923');
    ok($event->is_addressable, 'addressable');
};

# Spec: start tag (required) unix timestamp
subtest 'time_event: start tag' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => 1700000000,
    );
    my @s = grep { $_->[0] eq 'start' } @{$event->tags};
    is($s[0][1], '1700000000', 'start timestamp');
};

# Spec: end tag (optional) unix timestamp
subtest 'time_event: end tag' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => 1700000000,
        end        => 1700003600,
    );
    my @e = grep { $_->[0] eq 'end' } @{$event->tags};
    is($e[0][1], '1700003600', 'end timestamp');
};

# Spec: start_tzid (optional) IANA Time Zone
subtest 'time_event: start_tzid tag' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => 1700000000,
        start_tzid => 'America/Costa_Rica',
    );
    my @tz = grep { $_->[0] eq 'start_tzid' } @{$event->tags};
    is($tz[0][1], 'America/Costa_Rica', 'start_tzid');
};

# Spec: end_tzid (optional) IANA Time Zone
subtest 'time_event: end_tzid tag' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => 1700000000,
        end        => 1700003600,
        end_tzid   => 'America/New_York',
    );
    my @tz = grep { $_->[0] eq 'end_tzid' } @{$event->tags};
    is($tz[0][1], 'America/New_York', 'end_tzid');
};

# Spec: D tag (required) day-granularity unix timestamp
subtest 'time_event: D tags' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => 1700000000,
        days       => [19675, 19676],
    );
    my @d_tags = grep { $_->[0] eq 'D' } @{$event->tags};
    is(scalar @d_tags, 2, 'two D tags');
    is($d_tags[0][1], '19675', 'first D');
    is($d_tags[1][1], '19676', 'second D');
};

# Spec: content is required but can be empty string
subtest 'time_event: content defaults to empty string' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => 1700000000,
    );
    is($event->content, '', 'empty content');
};

# Spec: time-based common optional tags work
subtest 'time_event: common optional tags' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Meeting',
        start      => 1700000000,
        summary    => 'Team sync',
        image      => 'https://example.com/meeting.jpg',
        locations  => ['Room 101'],
        geohash    => 'u4pruydqqvj',
        hashtags   => ['work'],
        references => ['https://example.com/agenda'],
    );
    my @s = grep { $_->[0] eq 'summary' } @{$event->tags};
    is($s[0][1], 'Team sync', 'summary');
    my @i = grep { $_->[0] eq 'image' } @{$event->tags};
    is($i[0][1], 'https://example.com/meeting.jpg', 'image');
    my @l = grep { $_->[0] eq 'location' } @{$event->tags};
    is($l[0][1], 'Room 101', 'location');
    my @g = grep { $_->[0] eq 'g' } @{$event->tags};
    is($g[0][1], 'u4pruydqqvj', 'geohash');
    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is($t[0][1], 'work', 'hashtag');
    my @r = grep { $_->[0] eq 'r' } @{$event->tags};
    is($r[0][1], 'https://example.com/agenda', 'reference');
};

# Spec: time-based spec example
subtest 'time_event: spec example' => sub {
    my $pk2 = 'b' x 64;
    my $pk3 = 'c' x 64;
    my $event = Net::Nostr::Calendar->time_event(
        pubkey       => $PK,
        identifier   => 'random-identifier',
        title        => 'title of calendar event',
        content      => 'description of calendar event',
        summary      => 'brief description of the calendar event',
        image        => 'string with image URI',
        start        => 1700000000,
        end          => 1700003600,
        days         => [82549],
        start_tzid   => 'America/Costa_Rica',
        end_tzid     => 'America/Costa_Rica',
        locations    => ['location'],
        geohash      => 'geohash',
        participants => [
            [$pk2, 'wss://relay.example.com', 'role'],
            [$pk3, 'wss://relay.example.com', 'role'],
        ],
    );

    is($event->kind, 31923, 'kind');
    is($event->content, 'description of calendar event', 'content');

    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'random-identifier', 'd');

    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is($title[0][1], 'title of calendar event', 'title');

    my @summary = grep { $_->[0] eq 'summary' } @{$event->tags};
    is($summary[0][1], 'brief description of the calendar event', 'summary');

    my @image = grep { $_->[0] eq 'image' } @{$event->tags};
    is($image[0][1], 'string with image URI', 'image');

    my @start = grep { $_->[0] eq 'start' } @{$event->tags};
    is($start[0][1], '1700000000', 'start');

    my @end_tag = grep { $_->[0] eq 'end' } @{$event->tags};
    is($end_tag[0][1], '1700003600', 'end');

    my @D = grep { $_->[0] eq 'D' } @{$event->tags};
    is($D[0][1], '82549', 'D');

    my @stz = grep { $_->[0] eq 'start_tzid' } @{$event->tags};
    is($stz[0][1], 'America/Costa_Rica', 'start_tzid');

    my @etz = grep { $_->[0] eq 'end_tzid' } @{$event->tags};
    is($etz[0][1], 'America/Costa_Rica', 'end_tzid');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 2, 'participant count');
};

###############################################################################
# Calendar (kind 31924)
###############################################################################

subtest 'calendar: kind 31924' => sub {
    my $event = Net::Nostr::Calendar->calendar(
        pubkey     => $PK,
        identifier => 'my-calendar',
        title      => 'Personal Calendar',
    );
    is($event->kind, 31924, 'kind is 31924');
    ok($event->is_addressable, 'addressable');
};

# Spec: d and title required
subtest 'calendar: d and title tags' => sub {
    my $event = Net::Nostr::Calendar->calendar(
        pubkey     => $PK,
        identifier => 'work-calendar',
        title      => 'Work Calendar',
        content    => 'My work calendar',
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'work-calendar', 'd tag');
    my @t = grep { $_->[0] eq 'title' } @{$event->tags};
    is($t[0][1], 'Work Calendar', 'title tag');
    is($event->content, 'My work calendar', 'content');
};

# Spec: a tags reference calendar events
subtest 'calendar: a tags referencing events' => sub {
    my $event = Net::Nostr::Calendar->calendar(
        pubkey     => $PK,
        identifier => 'my-cal',
        title      => 'Calendar',
        events     => [
            ["31922:${PK}:vacation-2024"],
            ["31923:${PK}:meeting-123", 'wss://relay.example.com'],
        ],
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a, 2, 'two a tags');
    is($a[0][1], "31922:${PK}:vacation-2024", 'first event ref');
    is($a[1][1], "31923:${PK}:meeting-123", 'second event ref');
    is($a[1][2], 'wss://relay.example.com', 'relay url');
};

# Spec: content is required but can be empty string
subtest 'calendar: content defaults to empty string' => sub {
    my $event = Net::Nostr::Calendar->calendar(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
    );
    is($event->content, '', 'empty content');
};

# Spec: calendar spec example
subtest 'calendar: spec example' => sub {
    my $event = Net::Nostr::Calendar->calendar(
        pubkey     => $PK,
        identifier => 'random-identifier',
        title      => 'calendar title',
        content    => 'description of calendar',
        events     => [
            ["31922:${PK}:d-identifier", 'wss://relay.example.com'],
            ["31923:${PK}:d-identifier", 'wss://relay.example.com'],
        ],
    );
    is($event->kind, 31924, 'kind');
    is($event->content, 'description of calendar', 'content');

    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'random-identifier', 'd');

    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is($title[0][1], 'calendar title', 'title');

    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a, 2, 'a tag count');
};

###############################################################################
# Calendar Event RSVP (kind 31925)
###############################################################################

subtest 'rsvp: kind 31925' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'rsvp-123',
        event_coord  => "31922:${PK}:vacation-2024",
        status       => 'accepted',
    );
    is($event->kind, 31925, 'kind is 31925');
    ok($event->is_addressable, 'addressable');
};

# Spec: a tag (required) coordinates to calendar event
subtest 'rsvp: a tag (required)' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'rsvp-123',
        event_coord  => "31922:${PK}:vacation-2024",
        status       => 'accepted',
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "31922:${PK}:vacation-2024", 'a tag');
};

# Spec: a tag with optional relay URL
subtest 'rsvp: a tag with relay' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey        => $PK,
        identifier    => 'rsvp-123',
        event_coord   => "31922:${PK}:vacation-2024",
        event_relay   => 'wss://relay.example.com',
        status        => 'accepted',
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][2], 'wss://relay.example.com', 'relay in a tag');
};

# Spec: e tag (optional) specific event revision
subtest 'rsvp: e tag (optional)' => sub {
    my $eid = 'b' x 64;
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'rsvp-123',
        event_coord  => "31922:${PK}:vacation-2024",
        event_id     => $eid,
        status       => 'accepted',
    );
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0][1], $eid, 'e tag');
};

# Spec: e tag with optional relay URL
subtest 'rsvp: e tag with relay' => sub {
    my $eid = 'b' x 64;
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'rsvp-123',
        event_coord  => "31922:${PK}:vacation-2024",
        event_id     => $eid,
        event_id_relay => 'wss://relay.example.com',
        status       => 'accepted',
    );
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0][2], 'wss://relay.example.com', 'relay in e tag');
};

# Spec: d tag (required)
subtest 'rsvp: d tag' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'rsvp-unique-id',
        event_coord  => "31922:${PK}:test",
        status       => 'accepted',
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'rsvp-unique-id', 'd tag');
};

# Spec: status tag (required) accepted/declined/tentative
subtest 'rsvp: status accepted' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'test',
        event_coord  => "31922:${PK}:test",
        status       => 'accepted',
    );
    my @s = grep { $_->[0] eq 'status' } @{$event->tags};
    is($s[0][1], 'accepted', 'accepted');
};

subtest 'rsvp: status declined' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'test',
        event_coord  => "31922:${PK}:test",
        status       => 'declined',
    );
    my @s = grep { $_->[0] eq 'status' } @{$event->tags};
    is($s[0][1], 'declined', 'declined');
};

subtest 'rsvp: status tentative' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'test',
        event_coord  => "31922:${PK}:test",
        status       => 'tentative',
    );
    my @s = grep { $_->[0] eq 'status' } @{$event->tags};
    is($s[0][1], 'tentative', 'tentative');
};

# Spec: fb tag (optional) free/busy
subtest 'rsvp: fb tag busy' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'test',
        event_coord  => "31922:${PK}:test",
        status       => 'accepted',
        fb           => 'busy',
    );
    my @fb = grep { $_->[0] eq 'fb' } @{$event->tags};
    is($fb[0][1], 'busy', 'fb busy');
};

subtest 'rsvp: fb tag free' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'test',
        event_coord  => "31922:${PK}:test",
        status       => 'accepted',
        fb           => 'free',
    );
    my @fb = grep { $_->[0] eq 'fb' } @{$event->tags};
    is($fb[0][1], 'free', 'fb free');
};

subtest 'rsvp: fb tag omitted when status declined' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'test',
        event_coord  => "31922:${PK}:test",
        status       => 'declined',
        fb           => 'busy',
    );
    my @fb = grep { $_->[0] eq 'fb' } @{$event->tags};
    is(scalar @fb, 0, 'fb omitted when declined');
};

# Spec: p tag (optional) pubkey of calendar event author
subtest 'rsvp: p tag (optional)' => sub {
    my $author = 'b' x 64;
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey           => $PK,
        identifier       => 'test',
        event_coord      => "31922:${author}:test",
        status           => 'accepted',
        event_author     => $author,
        event_author_relay => 'wss://relay.example.com',
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][1], $author, 'author pubkey');
    is($p[0][2], 'wss://relay.example.com', 'author relay');
};

# Spec: content is optional free-form note
subtest 'rsvp: content' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'test',
        event_coord  => "31922:${PK}:test",
        status       => 'accepted',
        content      => 'Looking forward to it!',
    );
    is($event->content, 'Looking forward to it!', 'content');
};

subtest 'rsvp: content defaults to empty string' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'test',
        event_coord  => "31922:${PK}:test",
        status       => 'accepted',
    );
    is($event->content, '', 'empty content');
};

# Spec: RSVP spec example
subtest 'rsvp: spec example' => sub {
    my $eid = 'b' x 64;
    my $author = 'c' x 64;
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey             => $PK,
        identifier         => 'random-identifier',
        event_coord        => "31922:${author}:d-identifier",
        event_relay        => 'wss://relay.example.com',
        event_id           => $eid,
        event_id_relay     => 'wss://relay.example.com',
        status             => 'accepted',
        fb                 => 'busy',
        event_author       => $author,
        event_author_relay => 'wss://relay.example.com',
        content            => 'note',
    );

    is($event->kind, 31925, 'kind');
    is($event->content, 'note', 'content');

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0][1], $eid, 'e tag');

    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "31922:${author}:d-identifier", 'a tag');

    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'random-identifier', 'd');

    my @s = grep { $_->[0] eq 'status' } @{$event->tags};
    is($s[0][1], 'accepted', 'status');

    my @fb = grep { $_->[0] eq 'fb' } @{$event->tags};
    is($fb[0][1], 'busy', 'fb');

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][1], $author, 'p tag');
};

###############################################################################
# from_event: round-trip parsing
###############################################################################

subtest 'from_event: date event round-trip' => sub {
    my $pk2 = 'b' x 64;
    my $event = Net::Nostr::Calendar->date_event(
        pubkey       => $PK,
        identifier   => 'trip',
        title        => 'Road Trip',
        content      => 'Cross-country drive',
        start        => '2024-08-01',
        end          => '2024-08-15',
        summary      => 'A road trip',
        image        => 'https://example.com/trip.jpg',
        locations    => ['Highway 66'],
        geohash      => 'abc123',
        participants => [[$pk2, 'wss://relay.example.com', 'driver']],
        hashtags     => ['travel'],
        references   => ['https://example.com'],
        calendars    => ["31924:${PK}:personal"],
    );
    my $cal = Net::Nostr::Calendar->from_event($event);
    ok($cal, 'from_event returns object');
    is($cal->identifier, 'trip', 'identifier');
    is($cal->title, 'Road Trip', 'title');
    is($cal->description, 'Cross-country drive', 'description');
    is($cal->start, '2024-08-01', 'start');
    is($cal->end, '2024-08-15', 'end');
    is($cal->summary, 'A road trip', 'summary');
    is($cal->image, 'https://example.com/trip.jpg', 'image');
    is($cal->locations, ['Highway 66'], 'locations');
    is($cal->geohash, 'abc123', 'geohash');
    is(scalar @{$cal->participants}, 1, 'participants');
    is($cal->hashtags, ['travel'], 'hashtags');
    is($cal->references, ['https://example.com'], 'references');
};

subtest 'from_event: time event round-trip' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'meeting',
        title      => 'Standup',
        start      => 1700000000,
        end        => 1700003600,
        start_tzid => 'America/New_York',
        end_tzid   => 'America/Chicago',
        days       => [19675],
    );
    my $cal = Net::Nostr::Calendar->from_event($event);
    is($cal->start, '1700000000', 'start');
    is($cal->end, '1700003600', 'end');
    is($cal->start_tzid, 'America/New_York', 'start_tzid');
    is($cal->end_tzid, 'America/Chicago', 'end_tzid');
    is($cal->days, ['19675'], 'days');
};

subtest 'from_event: calendar round-trip' => sub {
    my $event = Net::Nostr::Calendar->calendar(
        pubkey     => $PK,
        identifier => 'personal',
        title      => 'Personal',
        content    => 'My calendar',
        events     => [
            ["31922:${PK}:vacation"],
        ],
    );
    my $cal = Net::Nostr::Calendar->from_event($event);
    is($cal->identifier, 'personal', 'identifier');
    is($cal->title, 'Personal', 'title');
    is($cal->description, 'My calendar', 'description');
    is(scalar @{$cal->calendar_events}, 1, 'events');
};

subtest 'from_event: rsvp round-trip' => sub {
    my $author = 'b' x 64;
    my $eid = 'c' x 64;
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'rsvp-1',
        event_coord  => "31922:${author}:test",
        event_id     => $eid,
        status       => 'tentative',
        fb           => 'free',
        event_author => $author,
        content      => 'Maybe',
    );
    my $cal = Net::Nostr::Calendar->from_event($event);
    is($cal->identifier, 'rsvp-1', 'identifier');
    is($cal->event_coord, "31922:${author}:test", 'event_coord');
    is($cal->event_id, $eid, 'event_id');
    is($cal->status, 'tentative', 'status');
    is($cal->fb, 'free', 'fb');
    is($cal->event_author, $author, 'event_author');
    is($cal->description, 'Maybe', 'description');
};

subtest 'from_event: returns undef for wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::Calendar->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid date event' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => '2024-07-01',
    );
    ok(Net::Nostr::Calendar->validate($event), 'valid');
};

subtest 'validate: valid time event' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
        start      => 1700000000,
        days       => [19675],
    );
    ok(Net::Nostr::Calendar->validate($event), 'valid');
};

subtest 'validate: valid calendar' => sub {
    my $event = Net::Nostr::Calendar->calendar(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
    );
    ok(Net::Nostr::Calendar->validate($event), 'valid');
};

subtest 'validate: valid rsvp' => sub {
    my $event = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'test',
        event_coord  => "31922:${PK}:test",
        status       => 'accepted',
    );
    ok(Net::Nostr::Calendar->validate($event), 'valid');
};

subtest 'validate: rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/kind/i,
        'rejects wrong kind'
    );
};

subtest 'validate: date event requires d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31922, content => '',
        tags => [['title', 'T'], ['start', '2024-01-01']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/d.*tag/i,
        'rejects missing d tag'
    );
};

subtest 'validate: date event requires title tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31922, content => '',
        tags => [['d', 'x'], ['start', '2024-01-01']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/title.*tag/i,
        'rejects missing title tag'
    );
};

subtest 'validate: date event requires start tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31922, content => '',
        tags => [['d', 'x'], ['title', 'T']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/start.*tag/i,
        'rejects missing start tag'
    );
};

subtest 'validate: time event requires start tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31923, content => '',
        tags => [['d', 'x'], ['title', 'T']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/start.*tag/i,
        'rejects missing start tag'
    );
};

subtest 'validate: calendar requires d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31924, content => '',
        tags => [['title', 'T']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/d.*tag/i,
        'rejects missing d tag'
    );
};

subtest 'validate: calendar requires title tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31924, content => '',
        tags => [['d', 'x']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/title.*tag/i,
        'rejects missing title tag'
    );
};

subtest 'validate: rsvp requires a tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31925, content => '',
        tags => [['d', 'x'], ['status', 'accepted']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/a.*tag/i,
        'rejects missing a tag'
    );
};

subtest 'validate: rsvp requires status tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31925, content => '',
        tags => [['d', 'x'], ['a', "31922:${PK}:test"]],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/status.*tag/i,
        'rejects missing status tag'
    );
};

# Spec: D tag required for kind 31923
subtest 'validate: time event requires D tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31923, content => '',
        tags => [['d', 'x'], ['title', 'T'], ['start', '1700000000']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/D.*tag/i,
        'rejects missing D tag'
    );
};

# Spec: start "Must be less than end, if it exists" (date-based)
subtest 'validate: date event start must be less than end' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31922, content => '',
        tags => [['d', 'x'], ['title', 'T'], ['start', '2024-07-15'], ['end', '2024-07-01']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/start.*end|end.*start/i,
        'rejects start >= end'
    );
};

subtest 'validate: date event start equal to end rejected' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31922, content => '',
        tags => [['d', 'x'], ['title', 'T'], ['start', '2024-07-01'], ['end', '2024-07-01']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/start.*end|end.*start/i,
        'rejects start == end'
    );
};

# Spec: start "Must be less than end, if it exists" (time-based)
subtest 'validate: time event start must be less than end' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31923, content => '',
        tags => [['d', 'x'], ['title', 'T'], ['start', '1700003600'], ['end', '1700000000'], ['D', '19675']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/start.*end|end.*start/i,
        'rejects start >= end'
    );
};

subtest 'validate: end tag absent passes (date)' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey => $PK, identifier => 'x', title => 'T', start => '2024-07-01',
    );
    ok(Net::Nostr::Calendar->validate($event), 'valid without end');
};

subtest 'validate: end tag absent passes (time)' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey => $PK, identifier => 'x', title => 'T',
        start => 1700000000, days => [19675],
    );
    ok(Net::Nostr::Calendar->validate($event), 'valid without end');
};

subtest 'rsvp: requires valid status' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31925, content => '',
        tags => [['d', 'x'], ['a', "31922:${PK}:test"], ['status', 'maybe']],
    );
    like(
        dies { Net::Nostr::Calendar->validate($event) },
        qr/status/i,
        'rejects invalid status'
    );
};

###############################################################################
# to_event: required fields
###############################################################################

subtest 'date_event: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::Calendar->date_event(
                pubkey => $PK, title => 'T', start => '2024-01-01',
            )
        },
        qr/identifier/i,
        'requires identifier'
    );
};

subtest 'date_event: requires title' => sub {
    like(
        dies {
            Net::Nostr::Calendar->date_event(
                pubkey => $PK, identifier => 'x', start => '2024-01-01',
            )
        },
        qr/title/i,
        'requires title'
    );
};

subtest 'date_event: requires start' => sub {
    like(
        dies {
            Net::Nostr::Calendar->date_event(
                pubkey => $PK, identifier => 'x', title => 'T',
            )
        },
        qr/start/i,
        'requires start'
    );
};

subtest 'rsvp: requires event_coord' => sub {
    like(
        dies {
            Net::Nostr::Calendar->rsvp(
                pubkey => $PK, identifier => 'x', status => 'accepted',
            )
        },
        qr/event_coord/i,
        'requires event_coord'
    );
};

subtest 'rsvp: requires status' => sub {
    like(
        dies {
            Net::Nostr::Calendar->rsvp(
                pubkey => $PK, identifier => 'x',
                event_coord => "31922:${PK}:test",
            )
        },
        qr/status/i,
        'requires status'
    );
};

subtest 'rsvp: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::Calendar->rsvp(
                pubkey => $PK, event_coord => "31922:${PK}:test",
                status => 'accepted',
            )
        },
        qr/identifier/i,
        'requires identifier'
    );
};

subtest 'time_event: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::Calendar->time_event(
                pubkey => $PK, title => 'T', start => 1700000000,
            )
        },
        qr/identifier/i,
        'requires identifier'
    );
};

subtest 'time_event: requires title' => sub {
    like(
        dies {
            Net::Nostr::Calendar->time_event(
                pubkey => $PK, identifier => 'x', start => 1700000000,
            )
        },
        qr/title/i,
        'requires title'
    );
};

subtest 'time_event: requires start' => sub {
    like(
        dies {
            Net::Nostr::Calendar->time_event(
                pubkey => $PK, identifier => 'x', title => 'T',
            )
        },
        qr/start/i,
        'requires start'
    );
};

subtest 'calendar: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::Calendar->calendar(
                pubkey => $PK, title => 'T',
            )
        },
        qr/identifier/i,
        'requires identifier'
    );
};

subtest 'calendar: requires title' => sub {
    like(
        dies {
            Net::Nostr::Calendar->calendar(
                pubkey => $PK, identifier => 'x',
            )
        },
        qr/title/i,
        'requires title'
    );
};

###############################################################################
# Deprecated: name tag
###############################################################################

subtest 'from_event: deprecated name mapped to title' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31922, content => '',
        tags => [['d', 'x'], ['name', 'Old Title'], ['start', '2024-01-01']],
    );
    my $cal = Net::Nostr::Calendar->from_event($event);
    is($cal->title, 'Old Title', 'name mapped to title');
};

subtest 'from_event: title takes precedence over name' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 31922, content => '',
        tags => [['d', 'x'], ['title', 'New Title'], ['name', 'Old'], ['start', '2024-01-01']],
    );
    my $cal = Net::Nostr::Calendar->from_event($event);
    is($cal->title, 'New Title', 'title wins');
};

###############################################################################
# Constructor: unknown args rejected
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::Calendar->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

done_testing;
