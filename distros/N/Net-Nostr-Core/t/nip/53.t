use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::LiveActivity;

my $PK  = 'a' x 64;
my $PK2 = 'b' x 64;
my $PK3 = 'c' x 64;

###############################################################################
# Live Streaming Event (kind 30311)
###############################################################################

subtest 'live_event: kind 30311' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'demo-stream',
    );
    is($event->kind, 30311, 'kind is 30311');
    ok($event->is_addressable, 'addressable');
};

# Spec: d tag with unique identifier
subtest 'live_event: d tag' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'demo-cf-stream',
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'demo-cf-stream', 'd tag');
};

# Spec: title tag
subtest 'live_event: title tag' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        title      => 'Adult Swim Metalocalypse',
    );
    my @t = grep { $_->[0] eq 'title' } @{$event->tags};
    is($t[0][1], 'Adult Swim Metalocalypse', 'title');
};

# Spec: summary tag
subtest 'live_event: summary tag' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        summary    => 'Live stream from IPTV-ORG collection',
    );
    my @s = grep { $_->[0] eq 'summary' } @{$event->tags};
    is($s[0][1], 'Live stream from IPTV-ORG collection', 'summary');
};

# Spec: image tag
subtest 'live_event: image tag' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        image      => 'https://i.imgur.com/CaKq6Mt.png',
    );
    my @i = grep { $_->[0] eq 'image' } @{$event->tags};
    is($i[0][1], 'https://i.imgur.com/CaKq6Mt.png', 'image');
};

# Spec: streaming tag
subtest 'live_event: streaming tag' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        streaming  => 'https://example.com/stream.m3u8',
    );
    my @s = grep { $_->[0] eq 'streaming' } @{$event->tags};
    is($s[0][1], 'https://example.com/stream.m3u8', 'streaming');
};

# Spec: recording tag
subtest 'live_event: recording tag' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        recording  => 'https://example.com/recording.mp4',
    );
    my @r = grep { $_->[0] eq 'recording' } @{$event->tags};
    is($r[0][1], 'https://example.com/recording.mp4', 'recording');
};

# Spec: starts and ends timestamps
subtest 'live_event: starts and ends tags' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        starts     => '1687182672',
        ends       => '1687186272',
    );
    my @s = grep { $_->[0] eq 'starts' } @{$event->tags};
    is($s[0][1], '1687182672', 'starts');
    my @e = grep { $_->[0] eq 'ends' } @{$event->tags};
    is($e[0][1], '1687186272', 'ends');
};

# Spec: status tag (planned, live, ended)
subtest 'live_event: status tag' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        status     => 'live',
    );
    my @s = grep { $_->[0] eq 'status' } @{$event->tags};
    is($s[0][1], 'live', 'status');
};

# Spec: current_participants and total_participants
subtest 'live_event: participant count tags' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey               => $PK,
        identifier           => 'x',
        current_participants => '100',
        total_participants   => '200',
    );
    my @cp = grep { $_->[0] eq 'current_participants' } @{$event->tags};
    is($cp[0][1], '100', 'current_participants');
    my @tp = grep { $_->[0] eq 'total_participants' } @{$event->tags};
    is($tp[0][1], '200', 'total_participants');
};

# Spec: t (hashtag) tags, multiple allowed
subtest 'live_event: hashtag tags' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        hashtags   => ['animation', 'iptv'],
    );
    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @t, 2, 'two hashtag tags');
    is($t[0][1], 'animation', 'first hashtag');
    is($t[1][1], 'iptv', 'second hashtag');
};

# Spec: p tags with relay, role, optional proof
subtest 'live_event: p tags with roles' => sub {
    my $proof = 'd' x 64;
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey       => $PK,
        identifier   => 'x',
        participants => [
            [$PK2, 'wss://provider1.com/', 'Host', $proof],
            [$PK3, 'wss://provider2.com/nostr', 'Speaker'],
        ],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 2, 'two p tags');
    is($p[0][1], $PK2, 'first p pubkey');
    is($p[0][2], 'wss://provider1.com/', 'first p relay');
    is($p[0][3], 'Host', 'first p role');
    is($p[0][4], $proof, 'first p proof');
    is($p[1][1], $PK3, 'second p pubkey');
    is($p[1][2], 'wss://provider2.com/nostr', 'second p relay');
    is($p[1][3], 'Speaker', 'second p role');
};

# Spec: p tag with empty relay
subtest 'live_event: p tag with empty relay' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey       => $PK,
        identifier   => 'x',
        participants => [
            [$PK2, '', 'Participant'],
        ],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][2], '', 'empty relay');
    is($p[0][3], 'Participant', 'role');
};

# Spec: relays tag
subtest 'live_event: relays tag' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        relays     => ['wss://one.com', 'wss://two.com'],
    );
    my @r = grep { $_->[0] eq 'relays' } @{$event->tags};
    is(scalar @r, 1, 'one relays tag');
    is($r[0][1], 'wss://one.com', 'first relay');
    is($r[0][2], 'wss://two.com', 'second relay');
};

# Spec: pinned tag for pinned live chat message
subtest 'live_event: pinned tag' => sub {
    my $event_id = 'e' x 64;
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        pinned     => [$event_id],
    );
    my @pin = grep { $_->[0] eq 'pinned' } @{$event->tags};
    is($pin[0][1], $event_id, 'pinned event id');
};

# Spec line 85: "pin one or more live chat messages"
subtest 'live_event: multiple pinned tags' => sub {
    my $id1 = 'e' x 64;
    my $id2 = 'f' x 64;
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
        pinned     => [$id1, $id2],
    );
    my @pin = grep { $_->[0] eq 'pinned' } @{$event->tags};
    is(scalar @pin, 2, 'two pinned tags');
    is($pin[0][1], $id1, 'first pinned');
    is($pin[1][1], $id2, 'second pinned');
};

# Spec: content is empty
subtest 'live_event: content defaults to empty' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
    );
    is($event->content, '', 'empty content');
};

# Spec: requires identifier
subtest 'live_event: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->live_event(pubkey => $PK)
        },
        qr/identifier/i,
        'requires identifier'
    );
};

# Spec example: live streaming
subtest 'live_event: spec example' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => '1597246ac22f7d1375041054f2a4986bd971d8d196d7997e48973263ac9879ec',
        identifier => 'demo-cf-stream',
        title      => 'Adult Swim Metalocalypse',
        summary    => 'Live stream from IPTV-ORG collection',
        streaming  => 'https://adultswim-vodlive.cdn.turner.com/live/metalocalypse/stream.m3u8',
        starts     => '1687182672',
        status     => 'live',
        hashtags   => ['animation', 'iptv'],
        image      => 'https://i.imgur.com/CaKq6Mt.png',
    );
    is($event->kind, 30311, 'kind');
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'demo-cf-stream', 'd');
    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is($title[0][1], 'Adult Swim Metalocalypse', 'title');
    my @streaming = grep { $_->[0] eq 'streaming' } @{$event->tags};
    is($streaming[0][1], 'https://adultswim-vodlive.cdn.turner.com/live/metalocalypse/stream.m3u8', 'streaming');
    my @status = grep { $_->[0] eq 'status' } @{$event->tags};
    is($status[0][1], 'live', 'status');
    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @t, 2, 'hashtag count');
    is($t[0][1], 'animation', 'first hashtag');
    is($t[1][1], 'iptv', 'second hashtag');
};

###############################################################################
# Live Chat Message (kind 1311)
###############################################################################

subtest 'chat_message: kind 1311' => sub {
    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey   => $PK,
        activity => "30311:${PK2}:demo",
        content  => 'Hello',
    );
    is($event->kind, 1311, 'kind is 1311');
    ok($event->is_regular, 'regular');
};

# Spec: MUST include a tag of the activity
subtest 'chat_message: a tag' => sub {
    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey   => $PK,
        activity => "30311:${PK2}:demo-cf-stream",
        content  => 'Zaps to live streams is beautiful.',
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "30311:${PK2}:demo-cf-stream", 'a tag');
};

# Spec: a tag with optional relay url and root marker
subtest 'chat_message: a tag with relay hint' => sub {
    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey     => $PK,
        activity   => "30311:${PK2}:demo",
        relay_hint => 'wss://relay.example.com',
        content    => 'Hello',
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][2], 'wss://relay.example.com', 'relay hint');
    is($a[0][3], 'root', 'root marker');
};

# Spec: e tag for reply
subtest 'chat_message: e tag for reply' => sub {
    my $parent_id = 'f' x 64;
    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey   => $PK,
        activity => "30311:${PK2}:demo",
        reply_to => $parent_id,
        content  => 'Reply',
    );
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e[0][1], $parent_id, 'e tag');
};

# Spec: requires activity
subtest 'chat_message: requires activity' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->chat_message(
                pubkey => $PK, content => 'x',
            )
        },
        qr/activity/i,
        'requires activity'
    );
};

# Spec example: live chat message (lines 115-127)
# Exact spec example: ["a", "30311:...:demo-cf-stream", "", "root"]
subtest 'chat_message: spec example' => sub {
    my $author = '1597246ac22f7d1375041054f2a4986bd971d8d196d7997e48973263ac9879ec';
    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey     => '3f770d65d3a764a9c5cb503ae123e62ec7598ad035d836e2a810f3877a745b24',
        activity   => "30311:${author}:demo-cf-stream",
        relay_hint => '',
        content    => 'Zaps to live streams is beautiful.',
    );
    is($event->kind, 1311, 'kind');
    is($event->content, 'Zaps to live streams is beautiful.', 'content');
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "30311:${author}:demo-cf-stream", 'a tag from spec');
    is($a[0][2], '', 'empty relay from spec');
    is($a[0][3], 'root', 'root marker from spec');
};

###############################################################################
# Meeting Space (kind 30312)
###############################################################################

subtest 'meeting_space: kind 30312' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'main-room',
        room         => 'Main Room',
        status       => 'open',
        service      => 'https://meet.example.com/room',
        participants => [[$PK2, 'wss://relay.com/', 'Host']],
    );
    is($event->kind, 30312, 'kind is 30312');
    ok($event->is_addressable, 'addressable');
};

# Spec: d tag (required)
subtest 'meeting_space: d tag' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'main-conference-room',
        room         => 'Hall',
        status       => 'open',
        service      => 'https://meet.example.com',
        participants => [[$PK2, '', 'Host']],
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'main-conference-room', 'd tag');
};

# Spec: room tag (required)
subtest 'meeting_space: room tag' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'x',
        room         => 'Main Conference Hall',
        status       => 'open',
        service      => 'https://meet.example.com',
        participants => [[$PK2, '', 'Host']],
    );
    my @r = grep { $_->[0] eq 'room' } @{$event->tags};
    is($r[0][1], 'Main Conference Hall', 'room');
};

# Spec: status (required: open, private, closed)
subtest 'meeting_space: status tag' => sub {
    for my $s (qw(open private closed)) {
        my $event = Net::Nostr::LiveActivity->meeting_space(
            pubkey       => $PK,
            identifier   => 'x',
            room         => 'R',
            status       => $s,
            service      => 'https://meet.example.com',
            participants => [[$PK2, '', 'Host']],
        );
        my @st = grep { $_->[0] eq 'status' } @{$event->tags};
        is($st[0][1], $s, "status $s");
    }
};

# Spec: service tag (required)
subtest 'meeting_space: service tag' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'x',
        room         => 'R',
        status       => 'open',
        service      => 'https://meet.example.com/room',
        participants => [[$PK2, '', 'Host']],
    );
    my @s = grep { $_->[0] eq 'service' } @{$event->tags};
    is($s[0][1], 'https://meet.example.com/room', 'service');
};

# Spec: endpoint tag (optional)
subtest 'meeting_space: endpoint tag' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'x',
        room         => 'R',
        status       => 'open',
        service      => 'https://meet.example.com',
        endpoint     => 'https://api.example.com/room',
        participants => [[$PK2, '', 'Host']],
    );
    my @e = grep { $_->[0] eq 'endpoint' } @{$event->tags};
    is($e[0][1], 'https://api.example.com/room', 'endpoint');
};

# Spec: summary, image optional
subtest 'meeting_space: summary and image' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'x',
        room         => 'R',
        status       => 'open',
        service      => 'https://meet.example.com',
        summary      => 'Our primary conference space',
        image        => 'https://example.com/room.jpg',
        participants => [[$PK2, '', 'Host']],
    );
    my @s = grep { $_->[0] eq 'summary' } @{$event->tags};
    is($s[0][1], 'Our primary conference space', 'summary');
    my @i = grep { $_->[0] eq 'image' } @{$event->tags};
    is($i[0][1], 'https://example.com/room.jpg', 'image');
};

# Spec: hashtags, relays optional
subtest 'meeting_space: hashtags and relays' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'x',
        room         => 'R',
        status       => 'open',
        service      => 'https://meet.example.com',
        hashtags     => ['conference'],
        relays       => ['wss://relay1.com', 'wss://relay2.com'],
        participants => [[$PK2, '', 'Host']],
    );
    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is($t[0][1], 'conference', 'hashtag');
    my @r = grep { $_->[0] eq 'relays' } @{$event->tags};
    is($r[0][1], 'wss://relay1.com', 'first relay');
    is($r[0][2], 'wss://relay2.com', 'second relay');
};

# Spec: p tags with roles
subtest 'meeting_space: p tags with roles' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'x',
        room         => 'R',
        status       => 'open',
        service      => 'https://meet.example.com',
        participants => [
            [$PK2, 'wss://relay.com/', 'Host'],
            [$PK3, 'wss://relay2.com/', 'Moderator'],
        ],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 2, 'two p tags');
    is($p[0][3], 'Host', 'first role');
    is($p[1][3], 'Moderator', 'second role');
};

# Spec: requires identifier, room, status, service, participants
subtest 'meeting_space: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_space(
                pubkey => $PK, room => 'R', status => 'open',
                service => 'x', participants => [[$PK2, '', 'Host']],
            )
        },
        qr/identifier/i,
        'requires identifier'
    );
};

subtest 'meeting_space: requires room' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_space(
                pubkey => $PK, identifier => 'x', status => 'open',
                service => 'x', participants => [[$PK2, '', 'Host']],
            )
        },
        qr/room/i,
        'requires room'
    );
};

subtest 'meeting_space: requires status' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_space(
                pubkey => $PK, identifier => 'x', room => 'R',
                service => 'x', participants => [[$PK2, '', 'Host']],
            )
        },
        qr/status/i,
        'requires status'
    );
};

subtest 'meeting_space: requires service' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_space(
                pubkey => $PK, identifier => 'x', room => 'R',
                status => 'open', participants => [[$PK2, '', 'Host']],
            )
        },
        qr/service/i,
        'requires service'
    );
};

subtest 'meeting_space: requires participants' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_space(
                pubkey => $PK, identifier => 'x', room => 'R',
                status => 'open', service => 'x',
            )
        },
        qr/participant/i,
        'requires participants'
    );
};

# Spec: content defaults to empty
subtest 'meeting_space: content defaults to empty' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'x',
        room         => 'R',
        status       => 'open',
        service      => 'https://meet.example.com',
        participants => [[$PK2, '', 'Host']],
    );
    is($event->content, '', 'empty content');
};

# Spec example: meeting space
subtest 'meeting_space: spec example' => sub {
    my $owner = 'f7234bd4c1394dda46d09f35bd384dd30cc552ad5541990f98844fb06676e9ca';
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'main-conference-room',
        room         => 'Main Conference Hall',
        summary      => 'Our primary conference space',
        image        => 'https://example.com/room.jpg',
        status       => 'open',
        service      => 'https://meet.example.com/room',
        endpoint     => 'https://api.example.com/room',
        hashtags     => ['conference'],
        participants => [
            [$owner, 'wss://nostr.example.com/', 'Owner'],
            ['14aeb' . ('0' x 59), 'wss://provider2.com/', 'Moderator'],
        ],
        relays       => ['wss://relay1.com', 'wss://relay2.com'],
    );
    is($event->kind, 30312, 'kind');
    my @room = grep { $_->[0] eq 'room' } @{$event->tags};
    is($room[0][1], 'Main Conference Hall', 'room');
    my @svc = grep { $_->[0] eq 'service' } @{$event->tags};
    is($svc[0][1], 'https://meet.example.com/room', 'service');
    my @ep = grep { $_->[0] eq 'endpoint' } @{$event->tags};
    is($ep[0][1], 'https://api.example.com/room', 'endpoint');
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p, 2, 'participant count');
    is($p[0][3], 'Owner', 'first role');
};

###############################################################################
# Meeting Room Event (kind 30313)
###############################################################################

subtest 'meeting_room: kind 30313' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $PK,
        identifier => 'annual-meeting',
        space_ref  => ["30312:${PK2}:main-room", 'wss://relay.com'],
        title      => 'Annual Meeting',
        starts     => '1676262123',
        status     => 'planned',
    );
    is($event->kind, 30313, 'kind is 30313');
    ok($event->is_addressable, 'addressable');
};

# Spec: d tag (required)
subtest 'meeting_room: d tag' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $PK,
        identifier => 'annual-meeting-2025',
        space_ref  => ["30312:${PK2}:room", 'wss://relay.com'],
        title      => 'Meeting',
        starts     => '1676262123',
        status     => 'planned',
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'annual-meeting-2025', 'd tag');
};

# Spec: a tag referencing parent 30312 space (required)
subtest 'meeting_room: a tag' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $PK,
        identifier => 'x',
        space_ref  => ["30312:${PK2}:main-conference-room", 'wss://nostr.example.com'],
        title      => 'Meeting',
        starts     => '1676262123',
        status     => 'planned',
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "30312:${PK2}:main-conference-room", 'a tag coord');
    is($a[0][2], 'wss://nostr.example.com', 'a tag relay');
};

# Spec: title (required)
subtest 'meeting_room: title tag' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $PK,
        identifier => 'x',
        space_ref  => ["30312:${PK2}:room", 'wss://relay.com'],
        title      => 'Annual Company Meeting 2025',
        starts     => '1676262123',
        status     => 'planned',
    );
    my @t = grep { $_->[0] eq 'title' } @{$event->tags};
    is($t[0][1], 'Annual Company Meeting 2025', 'title');
};

# Spec: starts (required), ends (optional)
subtest 'meeting_room: starts and ends' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $PK,
        identifier => 'x',
        space_ref  => ["30312:${PK2}:room", 'wss://relay.com'],
        title      => 'Meeting',
        starts     => '1676262123',
        ends       => '1676269323',
        status     => 'live',
    );
    my @s = grep { $_->[0] eq 'starts' } @{$event->tags};
    is($s[0][1], '1676262123', 'starts');
    my @e = grep { $_->[0] eq 'ends' } @{$event->tags};
    is($e[0][1], '1676269323', 'ends');
};

# Spec: status (required: planned, live, ended)
subtest 'meeting_room: status tag' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $PK,
        identifier => 'x',
        space_ref  => ["30312:${PK2}:room", 'wss://relay.com'],
        title      => 'Meeting',
        starts     => '1676262123',
        status     => 'live',
    );
    my @s = grep { $_->[0] eq 'status' } @{$event->tags};
    is($s[0][1], 'live', 'status');
};

# Spec: participant counts (optional)
subtest 'meeting_room: participant counts' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey               => $PK,
        identifier           => 'x',
        space_ref            => ["30312:${PK2}:room", 'wss://relay.com'],
        title                => 'Meeting',
        starts               => '1676262123',
        status               => 'live',
        total_participants   => '180',
        current_participants => '175',
    );
    my @tp = grep { $_->[0] eq 'total_participants' } @{$event->tags};
    is($tp[0][1], '180', 'total_participants');
    my @cp = grep { $_->[0] eq 'current_participants' } @{$event->tags};
    is($cp[0][1], '175', 'current_participants');
};

# Spec: summary, image, p tags optional
subtest 'meeting_room: optional tags' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey       => $PK,
        identifier   => 'x',
        space_ref    => ["30312:${PK2}:room", 'wss://relay.com'],
        title        => 'Meeting',
        starts       => '1676262123',
        status       => 'live',
        summary      => 'Yearly meeting',
        image        => 'https://example.com/meeting.jpg',
        participants => [[$PK3, 'wss://provider1.com/', 'Speaker']],
    );
    my @s = grep { $_->[0] eq 'summary' } @{$event->tags};
    is($s[0][1], 'Yearly meeting', 'summary');
    my @i = grep { $_->[0] eq 'image' } @{$event->tags};
    is($i[0][1], 'https://example.com/meeting.jpg', 'image');
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][3], 'Speaker', 'participant role');
};

# Spec: requires identifier, space_ref, title, starts, status
subtest 'meeting_room: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_room(
                pubkey => $PK, space_ref => ["30312:${PK2}:r", 'wss://r'],
                title => 'M', starts => '1', status => 'planned',
            )
        },
        qr/identifier/i,
        'requires identifier'
    );
};

subtest 'meeting_room: requires space_ref' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_room(
                pubkey => $PK, identifier => 'x',
                title => 'M', starts => '1', status => 'planned',
            )
        },
        qr/space_ref/i,
        'requires space_ref'
    );
};

subtest 'meeting_room: requires title' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_room(
                pubkey => $PK, identifier => 'x',
                space_ref => ["30312:${PK2}:r", 'wss://r'],
                starts => '1', status => 'planned',
            )
        },
        qr/title/i,
        'requires title'
    );
};

subtest 'meeting_room: requires starts' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_room(
                pubkey => $PK, identifier => 'x',
                space_ref => ["30312:${PK2}:r", 'wss://r'],
                title => 'M', status => 'planned',
            )
        },
        qr/starts/i,
        'requires starts'
    );
};

subtest 'meeting_room: requires status' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->meeting_room(
                pubkey => $PK, identifier => 'x',
                space_ref => ["30312:${PK2}:r", 'wss://r'],
                title => 'M', starts => '1',
            )
        },
        qr/status/i,
        'requires status'
    );
};

# Spec example: meeting room
subtest 'meeting_room: spec example' => sub {
    my $owner = 'f7234bd4c1394dda46d09f35bd384dd30cc552ad5541990f98844fb06676e9ca';
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey               => $PK,
        identifier           => 'annual-meeting-2025',
        space_ref            => ["30312:${owner}:main-conference-room", 'wss://nostr.example.com'],
        title                => 'Annual Company Meeting 2025',
        summary              => 'Yearly company-wide meeting',
        image                => 'https://example.com/meeting.jpg',
        starts               => '1676262123',
        ends                 => '1676269323',
        status               => 'live',
        total_participants   => '180',
        current_participants => '175',
        participants         => [['91cf9' . ('0' x 59), 'wss://provider1.com/', 'Speaker']],
    );
    is($event->kind, 30313, 'kind');
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "30312:${owner}:main-conference-room", 'a tag');
    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is($title[0][1], 'Annual Company Meeting 2025', 'title');
    my @starts = grep { $_->[0] eq 'starts' } @{$event->tags};
    is($starts[0][1], '1676262123', 'starts');
    my @status = grep { $_->[0] eq 'status' } @{$event->tags};
    is($status[0][1], 'live', 'status');
};

###############################################################################
# Room Presence (kind 10312)
###############################################################################

subtest 'room_presence: kind 10312' => sub {
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey   => $PK,
        activity => "30312:${PK2}:main-room",
    );
    is($event->kind, 10312, 'kind is 10312');
    ok($event->is_replaceable, 'replaceable');
};

# Spec: a tag always includes empty relay and "root" marker
subtest 'room_presence: a tag' => sub {
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey   => $PK,
        activity => "30312:${PK2}:main-room",
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "30312:${PK2}:main-room", 'a tag');
    is($a[0][2], '', 'empty relay');
    is($a[0][3], 'root', 'root marker');
};

# Spec: a tag with relay hint and "root" marker
subtest 'room_presence: a tag with relay hint' => sub {
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey     => $PK,
        activity   => "30312:${PK2}:main-room",
        relay_hint => 'wss://relay.example.com',
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][2], 'wss://relay.example.com', 'relay hint');
    is($a[0][3], 'root', 'root marker');
};

# Spec: hand tag (optional, raised flag)
subtest 'room_presence: hand tag' => sub {
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey   => $PK,
        activity => "30312:${PK2}:main-room",
        hand     => '1',
    );
    my @h = grep { $_->[0] eq 'hand' } @{$event->tags};
    is($h[0][1], '1', 'hand raised');
};

# Spec: hand tag omitted when not set
subtest 'room_presence: no hand tag by default' => sub {
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey   => $PK,
        activity => "30312:${PK2}:main-room",
    );
    my @h = grep { $_->[0] eq 'hand' } @{$event->tags};
    is(scalar @h, 0, 'no hand tag');
};

# Spec: requires activity
subtest 'room_presence: requires activity' => sub {
    like(
        dies {
            Net::Nostr::LiveActivity->room_presence(pubkey => $PK)
        },
        qr/activity/i,
        'requires activity'
    );
};

# Spec example
subtest 'room_presence: spec example' => sub {
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey     => $PK,
        activity   => "30312:${PK2}:main-room",
        relay_hint => 'wss://relay.com',
        hand       => '1',
    );
    is($event->kind, 10312, 'kind');
    ok($event->is_replaceable, 'replaceable');
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][3], 'root', 'root marker');
    my @h = grep { $_->[0] eq 'hand' } @{$event->tags};
    is($h[0][1], '1', 'hand');
};

###############################################################################
# from_event: round-trip parsing
###############################################################################

subtest 'from_event: live_event round-trip' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey               => $PK,
        identifier           => 'demo-stream',
        title                => 'Test Stream',
        summary              => 'A test',
        image                => 'https://example.com/img.png',
        streaming            => 'https://example.com/stream.m3u8',
        recording            => 'https://example.com/rec.mp4',
        starts               => '1687182672',
        ends                 => '1687186272',
        status               => 'live',
        current_participants => '50',
        total_participants   => '100',
        hashtags             => ['test', 'live'],
        participants         => [[$PK2, 'wss://relay.com/', 'Host']],
        relays               => ['wss://one.com'],
        pinned               => ['e' x 64],
    );
    my $parsed = Net::Nostr::LiveActivity->from_event($event);
    is($parsed->identifier, 'demo-stream', 'identifier');
    is($parsed->title, 'Test Stream', 'title');
    is($parsed->summary, 'A test', 'summary');
    is($parsed->image, 'https://example.com/img.png', 'image');
    is($parsed->streaming, 'https://example.com/stream.m3u8', 'streaming');
    is($parsed->recording, 'https://example.com/rec.mp4', 'recording');
    is($parsed->starts, '1687182672', 'starts');
    is($parsed->ends, '1687186272', 'ends');
    is($parsed->status, 'live', 'status');
    is($parsed->current_participants, '50', 'current_participants');
    is($parsed->total_participants, '100', 'total_participants');
    is($parsed->hashtags, ['test', 'live'], 'hashtags');
    is($parsed->participants->[0][0], $PK2, 'participant pubkey');
    is($parsed->participants->[0][2], 'Host', 'participant role');
    is($parsed->relays, ['wss://one.com'], 'relays');
    is($parsed->pinned->[0], 'e' x 64, 'pinned');
};

subtest 'from_event: chat_message round-trip' => sub {
    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey     => $PK,
        activity   => "30311:${PK2}:demo",
        relay_hint => 'wss://relay.com',
        reply_to   => 'f' x 64,
        content    => 'Hello!',
    );
    my $parsed = Net::Nostr::LiveActivity->from_event($event);
    is($parsed->activity, "30311:${PK2}:demo", 'activity');
    is($parsed->relay_hint, 'wss://relay.com', 'relay_hint');
    is($parsed->reply_to, 'f' x 64, 'reply_to');
};

subtest 'from_event: meeting_space round-trip' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'main-room',
        room         => 'Main Room',
        status       => 'open',
        service      => 'https://meet.example.com',
        endpoint     => 'https://api.example.com',
        participants => [[$PK2, 'wss://relay.com/', 'Host']],
    );
    my $parsed = Net::Nostr::LiveActivity->from_event($event);
    is($parsed->identifier, 'main-room', 'identifier');
    is($parsed->room, 'Main Room', 'room');
    is($parsed->status, 'open', 'status');
    is($parsed->service, 'https://meet.example.com', 'service');
    is($parsed->endpoint, 'https://api.example.com', 'endpoint');
    is($parsed->participants->[0][0], $PK2, 'participant');
};

subtest 'from_event: meeting_room round-trip' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $PK,
        identifier => 'mtg-1',
        space_ref  => ["30312:${PK2}:room", 'wss://relay.com'],
        title      => 'Meeting',
        starts     => '1676262123',
        ends       => '1676269323',
        status     => 'live',
    );
    my $parsed = Net::Nostr::LiveActivity->from_event($event);
    is($parsed->identifier, 'mtg-1', 'identifier');
    is($parsed->space_ref->[0], "30312:${PK2}:room", 'space_ref coord');
    is($parsed->space_ref->[1], 'wss://relay.com', 'space_ref relay');
    is($parsed->title, 'Meeting', 'title');
    is($parsed->starts, '1676262123', 'starts');
    is($parsed->ends, '1676269323', 'ends');
    is($parsed->status, 'live', 'status');
};

subtest 'from_event: room_presence round-trip' => sub {
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey     => $PK,
        activity   => "30312:${PK2}:room",
        relay_hint => 'wss://relay.com',
        hand       => '1',
    );
    my $parsed = Net::Nostr::LiveActivity->from_event($event);
    is($parsed->activity, "30312:${PK2}:room", 'activity');
    is($parsed->relay_hint, 'wss://relay.com', 'relay_hint');
    is($parsed->hand, '1', 'hand');
};

subtest 'from_event: returns undef for wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::LiveActivity->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid live_event' => sub {
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $PK,
        identifier => 'x',
    );
    ok(Net::Nostr::LiveActivity->validate($event), 'valid');
};

subtest 'validate: valid chat_message' => sub {
    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey   => $PK,
        activity => "30311:${PK2}:x",
        content  => 'hi',
    );
    ok(Net::Nostr::LiveActivity->validate($event), 'valid');
};

subtest 'validate: valid meeting_space' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $PK,
        identifier   => 'x',
        room         => 'R',
        status       => 'open',
        service      => 'https://x',
        participants => [[$PK2, '', 'Host']],
    );
    ok(Net::Nostr::LiveActivity->validate($event), 'valid');
};

subtest 'validate: valid meeting_room' => sub {
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $PK,
        identifier => 'x',
        space_ref  => ["30312:${PK2}:r", 'wss://r'],
        title      => 'M',
        starts     => '1',
        status     => 'planned',
    );
    ok(Net::Nostr::LiveActivity->validate($event), 'valid');
};

subtest 'validate: valid room_presence' => sub {
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey   => $PK,
        activity => "30312:${PK2}:r",
    );
    ok(Net::Nostr::LiveActivity->validate($event), 'valid');
};

subtest 'validate: rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/kind/i,
        'rejects wrong kind'
    );
};

# Spec: kind 30311 MUST have d tag
subtest 'validate: live_event requires d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30311, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/d.*tag/i,
        'rejects missing d tag'
    );
};

# Spec: kind 1311 MUST include a tag
subtest 'validate: chat_message requires a tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1311, content => 'hi', tags => [],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/a.*tag/i,
        'rejects missing a tag'
    );
};

# Spec: kind 30312 MUST have d, room, status, service, p tags
subtest 'validate: meeting_space requires d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30312, content => '',
        tags => [['room', 'R'], ['status', 'open'], ['service', 'x'], ['p', $PK2, '', 'Host']],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/d.*tag/i,
        'rejects missing d tag'
    );
};

subtest 'validate: meeting_space requires room tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30312, content => '',
        tags => [['d', 'x'], ['status', 'open'], ['service', 'x'], ['p', $PK2, '', 'Host']],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/room.*tag/i,
        'rejects missing room tag'
    );
};

subtest 'validate: meeting_space requires status tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30312, content => '',
        tags => [['d', 'x'], ['room', 'R'], ['service', 'x'], ['p', $PK2, '', 'Host']],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/status.*tag/i,
        'rejects missing status tag'
    );
};

subtest 'validate: meeting_space requires service tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30312, content => '',
        tags => [['d', 'x'], ['room', 'R'], ['status', 'open'], ['p', $PK2, '', 'Host']],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/service.*tag/i,
        'rejects missing service tag'
    );
};

subtest 'validate: meeting_space requires p tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30312, content => '',
        tags => [['d', 'x'], ['room', 'R'], ['status', 'open'], ['service', 'x']],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/p.*tag/i,
        'rejects missing p tag'
    );
};

# Spec: kind 30313 MUST have d, a, title, starts, status
subtest 'validate: meeting_room requires a tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30313, content => '',
        tags => [['d', 'x'], ['title', 'M'], ['starts', '1'], ['status', 'live']],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/a.*tag/i,
        'rejects missing a tag'
    );
};

subtest 'validate: meeting_room requires title tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30313, content => '',
        tags => [['d', 'x'], ['a', "30312:${PK2}:r", 'wss://r'], ['starts', '1'], ['status', 'live']],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/title.*tag/i,
        'rejects missing title tag'
    );
};

subtest 'validate: meeting_room requires starts tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30313, content => '',
        tags => [['d', 'x'], ['a', "30312:${PK2}:r", 'wss://r'], ['title', 'M'], ['status', 'live']],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/starts.*tag/i,
        'rejects missing starts tag'
    );
};

subtest 'validate: meeting_room requires status tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 30313, content => '',
        tags => [['d', 'x'], ['a', "30312:${PK2}:r", 'wss://r'], ['title', 'M'], ['starts', '1']],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/status.*tag/i,
        'rejects missing status tag'
    );
};

# Spec: kind 10312 MUST have a tag
subtest 'validate: room_presence requires a tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 10312, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::LiveActivity->validate($event) },
        qr/a.*tag/i,
        'rejects missing a tag'
    );
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
# from_event: short/malformed tags are safely skipped
###############################################################################

subtest 'from_event: short tags are skipped' => sub {
    my $event = Net::Nostr::Event->new(
        kind    => 30311,
        pubkey  => $PK,
        content => '',
        tags    => [
            ['d', 'stream-1'],
            ['title'],           # too short
            [],                  # empty
            ['status', 'live'],
            ['a'],               # too short for a tag
        ],
    );
    my $parsed = Net::Nostr::LiveActivity->from_event($event);
    is $parsed->identifier, 'stream-1', 'identifier parsed';
    is $parsed->title, undef, 'short title tag skipped';
    is $parsed->status, 'live', 'valid status tag parsed';
    is $parsed->activity, undef, 'short a tag skipped';
};

subtest 'from_event: a tag relay_hint needs bounds check' => sub {
    my $event = Net::Nostr::Event->new(
        kind    => 1311,
        pubkey  => $PK,
        content => 'hi',
        tags    => [
            ['a', "30311:${PK}:stream-1"],  # no relay hint element
        ],
    );
    my $parsed = Net::Nostr::LiveActivity->from_event($event);
    is $parsed->activity, "30311:${PK}:stream-1", 'activity parsed';
    is $parsed->relay_hint, undef, 'no relay_hint when a tag has only 2 elements';
};

done_testing;
