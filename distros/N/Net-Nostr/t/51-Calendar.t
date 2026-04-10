use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Calendar;

my $PK = 'a' x 64;

###############################################################################
# POD example: date_event
###############################################################################

subtest 'POD: date_event' => sub {
    my $friend_pk = 'b' x 64;
    my $event = Net::Nostr::Calendar->date_event(
        pubkey       => $PK,
        identifier   => 'vacation-2024',
        title        => 'Summer Vacation',
        content      => 'Two weeks off',
        start        => '2024-07-01',
        end          => '2024-07-15',
        locations    => ['Beach Resort'],
        participants => [[$friend_pk, 'wss://relay', 'attendee']],
    );
    is($event->kind, 31922, 'kind');
    my ($d) = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d->[1], 'vacation-2024', 'd tag');
};

###############################################################################
# POD example: time_event
###############################################################################

subtest 'POD: time_event' => sub {
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $PK,
        identifier => 'standup',
        title      => 'Daily Standup',
        start      => 1700000000,
        end        => 1700003600,
        start_tzid => 'America/New_York',
        days       => [19675],
    );
    is($event->kind, 31923, 'kind');
};

###############################################################################
# POD example: calendar
###############################################################################

subtest 'POD: calendar' => sub {
    my $cal = Net::Nostr::Calendar->calendar(
        pubkey     => $PK,
        identifier => 'personal',
        title      => 'Personal Calendar',
        events     => [
            ["31922:${PK}:vacation-2024", 'wss://relay'],
        ],
    );
    is($cal->kind, 31924, 'kind');
};

###############################################################################
# POD example: rsvp
###############################################################################

subtest 'POD: rsvp' => sub {
    my $organizer_pk = 'c' x 64;
    my $rsvp = Net::Nostr::Calendar->rsvp(
        pubkey       => $PK,
        identifier   => 'rsvp-1',
        event_coord  => "31922:${organizer_pk}:vacation-2024",
        status       => 'accepted',
        fb           => 'busy',
    );
    is($rsvp->kind, 31925, 'kind');
};

###############################################################################
# POD example: from_event
###############################################################################

subtest 'POD: from_event' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test Event',
        start      => '2024-01-01',
    );
    my $parsed = Net::Nostr::Calendar->from_event($event);
    is($parsed->title, 'Test Event');
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test Event',
        start      => '2024-01-01',
    );
    ok(Net::Nostr::Calendar->validate($event), 'validate returns true');
};

###############################################################################
# POD example: new
###############################################################################

subtest 'POD: new' => sub {
    my $cal = Net::Nostr::Calendar->new(
        identifier => 'meeting',
        title      => 'Team Meeting',
    );
    is($cal->identifier, 'meeting');
    is($cal->title, 'Team Meeting');
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

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::Calendar',
        qw(new date_event time_event calendar rsvp from_event validate
           identifier title description start end summary image locations
           geohash participants hashtags references calendars calendar_events
           start_tzid end_tzid days event_coord event_id status fb
           event_author));
};

###############################################################################
# Round-trip: date_event() -> from_event()
###############################################################################

subtest 'round-trip: date_event -> from_event' => sub {
    my $event = Net::Nostr::Calendar->date_event(
        pubkey     => $PK,
        identifier => 'vacation-2024',
        title      => 'Summer Vacation',
        start      => '2024-07-01',
    );

    my $parsed = Net::Nostr::Calendar->from_event($event);

    is($parsed->title, 'Summer Vacation', 'title preserved');
    is($parsed->identifier, 'vacation-2024', 'identifier preserved');
    is($parsed->start, '2024-07-01', 'start preserved');
};

done_testing;
