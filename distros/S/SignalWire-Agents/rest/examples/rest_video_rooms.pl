#!/usr/bin/env perl
# Example: Video rooms for team standup and conference streaming.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents::REST::SignalWireClient;

my $client = SignalWire::Agents::REST::SignalWireClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token   => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host    => $ENV{SIGNALWIRE_SPACE}      // die("Set SIGNALWIRE_SPACE\n"),
);

sub safe {
    my ($label, $fn) = @_;
    my $result = eval { $fn->() };
    if ($@) {
        print "  $label: failed ($@)\n";
        return undef;
    }
    print "  $label: OK\n";
    return $result;
}

# --- Video Rooms ---

# 1. Create a video room
print "Creating video room...\n";
my $room = $client->video->rooms->create(
    name         => 'daily-standup',
    display_name => 'Daily Standup',
    max_members  => 10,
    layout       => 'grid-responsive',
);
my $room_id = $room->{id};
print "  Created room: $room_id\n";

# 2. List video rooms
print "\nListing video rooms...\n";
my $rooms = safe('List rooms', sub { $client->video->rooms->list });
if ($rooms) {
    my @data = @{ $rooms->{data} // [] };
    for my $r (@data[0 .. ($#data < 4 ? $#data : 4)]) {
        print "  - $r->{id}: " . ($r->{name} // 'unnamed') . "\n";
    }
}

# 3. Generate a join token
print "\nGenerating room token...\n";
safe('Room token', sub {
    my $token = $client->video->room_tokens->create(
        room_name   => 'daily-standup',
        user_name   => 'alice',
        permissions => ['room.self.audio_mute', 'room.self.video_mute'],
    );
    my $t = $token->{token} // '';
    print "  Token: " . substr($t, 0, 40) . "...\n" if $t;
});

# --- Sessions ---

# 4. List room sessions
print "\nListing room sessions...\n";
my $sessions = safe('List sessions', sub { $client->video->room_sessions->list });
if ($sessions) {
    my @data = @{ $sessions->{data} // [] };
    for my $s (@data[0 .. ($#data < 2 ? $#data : 2)]) {
        print "  - Session $s->{id}: " . ($s->{status} // 'unknown') . "\n";
    }
}

# 5. Get session details
if ($sessions && $sessions->{data} && @{ $sessions->{data} }) {
    my $first = $sessions->{data}[0];
    if ($first->{id}) {
        my $sid = $first->{id};
        safe('Session detail', sub {
            my $detail = $client->video->room_sessions->get($sid);
            print "  Session: " . ($detail->{name} // 'N/A')
                . " (" . ($detail->{status} // 'N/A') . ")\n";
        });
        safe('Session members', sub {
            my $members = $client->video->room_sessions->list_members($sid);
            print "  Members: " . scalar(@{ $members->{data} // [] }) . "\n";
        });
        safe('Session events', sub {
            my $events = $client->video->room_sessions->list_events($sid);
            print "  Events: " . scalar(@{ $events->{data} // [] }) . "\n";
        });
        safe('Session recordings', sub {
            my $recs = $client->video->room_sessions->list_recordings($sid);
            print "  Recordings: " . scalar(@{ $recs->{data} // [] }) . "\n";
        });
    }
}

# --- Room Recordings ---

# 6. List room recordings
print "\nListing room recordings...\n";
my $room_recs = safe('List recordings', sub { $client->video->room_recordings->list });
if ($room_recs) {
    my @data = @{ $room_recs->{data} // [] };
    for my $rr (@data[0 .. ($#data < 2 ? $#data : 2)]) {
        print "  - Recording $rr->{id}: " . ($rr->{duration} // 'N/A') . "s\n";
    }

    if (@data && $data[0]{id}) {
        safe('Get recording', sub {
            my $rec_detail = $client->video->room_recordings->get($data[0]{id});
            print "  Recording detail: " . ($rec_detail->{duration} // 'N/A') . "s\n";
        });
        safe('Recording events', sub {
            my $rec_events = $client->video->room_recordings->list_events($data[0]{id});
            print "  Recording events: " . scalar(@{ $rec_events->{data} // [] }) . "\n";
        });
    }
}

# --- Video Conferences ---

# 7. Create a video conference
print "\nCreating video conference...\n";
my $conf_id;
my $conf = safe('Create conference', sub {
    $client->video->conferences->create(
        name         => 'all-hands-stream',
        display_name => 'All Hands Meeting',
    );
});
$conf_id = $conf ? $conf->{id} : undef;

# 8. List conference tokens
if ($conf_id) {
    print "\nListing conference tokens...\n";
    safe('Conference tokens', sub {
        my $tokens = $client->video->conferences->list_conference_tokens($conf_id);
        for my $t (@{ $tokens->{data} // [] }) {
            print "  - Token: " . ($t->{id} // 'unknown') . "\n";
        }
    });
}

# 9. Create a stream
my $stream_id;
if ($conf_id) {
    print "\nCreating stream on conference...\n";
    my $stream = safe('Create stream', sub {
        $client->video->conferences->create_stream(
            $conf_id, url => 'rtmp://live.example.com/stream-key',
        );
    });
    $stream_id = $stream ? $stream->{id} : undef;
}

# 10. Get and update stream
if ($stream_id) {
    print "\nManaging stream $stream_id...\n";
    safe('Get stream', sub {
        my $s_detail = $client->video->streams->get($stream_id);
        print "  Stream URL: " . ($s_detail->{url} // 'N/A') . "\n";
    });
    safe('Update stream', sub {
        $client->video->streams->update($stream_id, url => 'rtmp://backup.example.com/stream-key');
    });
}

# 11. Clean up
print "\nCleaning up...\n";
safe('Delete stream',     sub { $client->video->streams->delete($stream_id) })       if $stream_id;
safe('Delete conference', sub { $client->video->conferences->delete($conf_id) })      if $conf_id;
$client->video->rooms->delete($room_id);
print "  Deleted room $room_id\n";
