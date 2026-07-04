use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::LiveActivity;

my $PK  = 'a' x 64;
my $PK2 = 'b' x 64;

###############################################################################
# POD example: live_event
###############################################################################

subtest 'POD: live_event' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'my-stream',
        title      => 'My Stream',
        status     => 'live',
    );
    is($event->kind, 30311, 'kind');
};

###############################################################################
# POD example: chat_message
###############################################################################

subtest 'POD: chat_message' => sub {
    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey   => $PK,
        activity => "30311:${PK2}:my-stream",
        content  => 'Hello!',
    );
    is($event->kind, 1311, 'kind');
};

###############################################################################
# POD example: meeting_space
###############################################################################

subtest 'POD: meeting_space' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'main-room',
        room         => 'Main Conference Hall',
        status       => 'open',
        service      => 'https://meet.example.com/room',
        participants => [[$PK2, 'wss://relay.com/', 'Host']],
    );
    is($event->kind, 30312, 'kind');
};

###############################################################################
# POD example: meeting_room
###############################################################################

subtest 'POD: meeting_room' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $PK,
        identifier => 'annual-meeting',
        space_ref  => ["30312:${PK2}:main-room", 'wss://relay.com'],
        title      => 'Annual Meeting',
        starts     => '1676262123',
        status     => 'planned',
    );
    is($event->kind, 30313, 'kind');
};

###############################################################################
# POD example: room_presence
###############################################################################

subtest 'POD: room_presence' => sub {
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey   => $PK,
        activity => "30312:${PK2}:main-room",
        hand     => '1',
    );
    is($event->kind, 10312, 'kind');
};

###############################################################################
# POD example: from_event
###############################################################################

subtest 'POD: from_event' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'test',
        title      => 'Test',
    );
    my $parsed = Net::Nostr::LiveActivity->from_event($event);
    is($parsed->identifier, 'test');
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'test',
    );
    ok(Net::Nostr::LiveActivity->validate($event), 'validate returns true');
};

###############################################################################
# POD example: new
###############################################################################

subtest 'POD: new' => sub {
    my $la = Net::Nostr::LiveActivity->new(
        identifier => 'my-stream',
        status     => 'live',
    );
    is($la->identifier, 'my-stream');
    is($la->status, 'live');
};

###############################################################################
# Constructor: unknown args rejected
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::LiveActivity->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::LiveActivity',
        qw(new live_event chat_message meeting_space meeting_room
           room_presence from_event validate
           identifier title summary image streaming recording
           starts ends status current_participants total_participants
           hashtags participants relays pinned
           activity relay_hint reply_to
           room service endpoint space_ref hand));
};

done_testing;
